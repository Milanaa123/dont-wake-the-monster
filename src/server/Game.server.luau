--!strict
-- Server-authoritative vertical slice. Clients request actions; the server decides rewards, chaos and knockback.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local World = require(script.Parent:WaitForChild("World"))

World.build()
local remote = Instance.new("RemoteEvent")
remote.Name = "MonsterRemote"
remote.Parent = ReplicatedStorage

local store = DataStoreService:GetDataStore(Config.DATASTORE_NAME)
local rng = Random.new()
local noise = 0
local phase = "SLEEP"
local secondsLeft = Config.SLEEP_MAX_SECONDS
local profiles: {[Player]: any} = {}
local totalActions = 0
local wakeCount = 0

local function notice(message: string, color: Color3?)
    remote:FireAllClients({type = "notice", text = message, color = color or Color3.fromRGB(255, 255, 255)})
end

local function sendStats(player: Player)
    local profile = profiles[player]
    if profile then
        remote:FireClient(player, {type = "stats", coins = profile.coins, pet = Config.Pets[profile.petIndex].name})
    end
end

local function sendState(player: Player?)
    local update = {type = "state", phase = phase, noise = noise, maxNoise = Config.NOISE_MAX, time = secondsLeft, wakes = wakeCount}
    if player then
        remote:FireClient(player, update)
    else
        remote:FireAllClients(update)
    end
end

local function rootFor(player: Player): BasePart?
    local char = player.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then return root end
    return nil
end

local function knock(root: BasePart, center: Vector3, strength: number)
    local delta = root.Position - center
    local flat = Vector3.new(delta.X, 0, delta.Z)
    local away = if flat.Magnitude > 0.01 then flat.Unit else Vector3.new(0, 0, 1)
    root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + away * strength + Vector3.new(0, 22, 0)
end

local function nearbyKnock(center: Vector3, radius: number, strength: number)
    for _, player in ipairs(Players:GetPlayers()) do
        local root = rootFor(player)
        if root and (root.Position - center).Magnitude < radius then
            knock(root, center, strength)
            remote:FireClient(player, {type = "shake", amount = 0.65})
        end
    end
end

local function addCoins(player: Player, amount: number)
    local profile = profiles[player]
    if not profile then return end
    profile.coins += math.max(0, math.floor(amount))
    if profile.loaded then profile.dirty = true end
    sendStats(player)
end

local function save(player: Player)
    local profile = profiles[player]
    if not profile or not profile.loaded or not profile.dirty then return end
    local coins = profile.coins
    local petIndex = profile.petIndex
    local ok, err = pcall(function()
        store:UpdateAsync("player_" .. player.UserId, function(previous: any)
            local previousCoins = if type(previous) == "table" and type(previous.coins) == "number" then previous.coins else 0
            -- In this prototype coins only increase; max protects against simultaneous/stale server overwrites.
            return {coins = math.max(previousCoins, coins), petIndex = petIndex}
        end)
    end)
    if ok then
        profile.dirty = false
    else
        warn("DWTM: data save failed for " .. player.UserId .. ": " .. tostring(err))
    end
end

local function movePetNearPlayer(player: Player)
    local profile = profiles[player]
    local root = rootFor(player)
    if not profile or not root or not profile.pet or not profile.pet.Parent then return end
    profile.pet:PivotTo(CFrame.new(root.Position + Vector3.new(4, 4, -3)))
end

local function onPlayerAdded(player: Player)
    local profile = {
        coins = 0,
        petIndex = rng:NextInteger(1, #Config.Pets),
        lastFeed = -100,
        lastFood = "",
        loaded = false,
        dirty = false,
        effectUntil = 0,
        effect = "",
        pet = nil,
    }
    profiles[player] = profile

    local ok, result = pcall(function()
        return store:GetAsync("player_" .. player.UserId)
    end)
    if ok then
        profile.loaded = true
        if type(result) == "table" then
            if type(result.coins) == "number" then
                profile.coins = math.max(0, math.floor(result.coins))
            end
            if type(result.petIndex) == "number" then
                profile.petIndex = math.clamp(math.floor(result.petIndex), 1, #Config.Pets)
            end
        end
    else
        warn("DWTM: data load unavailable for " .. player.UserId .. ". Progress is session-only.")
    end
    if profiles[player] ~= profile then return end

    local petDefinition = Config.Pets[profile.petIndex]
    profile.pet = World.makePet(petDefinition.name .. "_" .. player.UserId, petDefinition.color, petDefinition.ear == "pointy")
    movePetNearPlayer(player)

    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        movePetNearPlayer(player)
    end)
    sendStats(player)
    sendState(player)
    remote:FireClient(player, {type = "notice", text = "Meet " .. petDefinition.name .. "! Feed it. Nothing can go wrong... right?", color = Color3.fromRGB(252, 205, 255)})
end

local function onPlayerRemoving(player: Player)
    save(player)
    local profile = profiles[player]
    if profile and profile.pet then profile.pet:Destroy() end
    profiles[player] = nil
end

local function weightedReaction(food: string, previousFood: string)
    local total = 0
    local weights = {}
    for index, reaction in ipairs(Config.Reactions) do
        local weight = reaction.weight
        if food == "Candy" and (reaction.id == "Confetti" or reaction.id == "Clone" or reaction.id == "Giant") then weight *= 2 end
        if food == "Pepper" and (reaction.id == "Sneeze" or reaction.id == "Spin" or reaction.id == "Hiccup") then weight *= 2 end
        if food == "Bubble" and (reaction.id == "Cloud" or reaction.id == "Mini" or reaction.id == "Bounce") then weight *= 2 end
        if food == "Star" and (reaction.id == "Rainbow" or reaction.id == "Disco" or reaction.id == "Meteor") then weight *= 2 end
        if food == previousFood and (reaction.id == "Clone" or reaction.id == "Giant") then weight += 4 end
        total += weight
        weights[index] = total
    end
    local roll = rng:NextNumber(0, total)
    for i, upper in ipairs(weights) do
        if roll <= upper then return Config.Reactions[i] end
    end
    return Config.Reactions[#Config.Reactions]
end

local function petEffect(profile: any, reaction: any, food: string)
    local pet = profile.pet
    if not pet or not pet.Parent or not pet.PrimaryPart then return end
    local pos = pet.PrimaryPart.Position
    local foodColor = Config.Foods[food].color
    local id = reaction.id
    profile.effect = id
    profile.effectUntil = os.clock() + 3.2
    pet:ScaleTo(1)

    if id == "Giant" then
        pet:ScaleTo(2.4)
        World.burst(pos, foodColor, 17, 14)
    elseif id == "Mini" then
        pet:ScaleTo(0.5)
        World.burst(pos, Color3.fromRGB(255, 255, 255), 10)
    elseif id == "Clone" then
        for i = 1, 2 do
            local clone = pet:Clone()
            clone.Name = "TemporaryClone"
            clone.Parent = workspace:WaitForChild("MonsterIsland")
            clone:PivotTo(pet:GetPivot() * CFrame.new(i * 5 - 7, 0, 4))
            Debris:AddItem(clone, 3)
        end
        World.burst(pos, Color3.fromRGB(255, 226, 121), 15)
    elseif id == "Sneeze" then
        World.wave(pos, 21, Color3.fromRGB(130, 238, 255))
        nearbyKnock(pos, 22, 28)
    elseif id == "Meteor" then
        local blob = Instance.new("Part")
        blob.Name = "JellyMeteor"
        blob.Shape = Enum.PartType.Ball
        blob.Color = foodColor
        blob.Material = Enum.Material.Neon
        blob.Size = Vector3.new(11, 11, 11)
        blob.Anchored = true
        blob.CanCollide = false
        blob.Position = pos + Vector3.new(0, 35, 0)
        blob.Parent = workspace:WaitForChild("MonsterIsland")
        TweenService:Create(blob, TweenInfo.new(0.85, Enum.EasingStyle.Bounce), {Position = pos + Vector3.new(0, 4, 0)}):Play()
        task.delay(0.9, function()
            if blob.Parent then
                World.burst(blob.Position, foodColor, 25, 17)
                blob:Destroy()
            end
        end)
        Debris:AddItem(blob, 2)
    else
        local count = if id == "Disco" then 28 elseif id == "Confetti" then 24 else 12
        World.burst(pos, foodColor, count, if id == "Cloud" then 19 else 11)
        if id == "Hiccup" then
            World.wave(pos, 12, foodColor)
            nearbyKnock(pos, 14, 12)
        end
    end
end

local function feed(player: Player, food: any)
    local profile = profiles[player]
    if not profile or typeof(food) ~= "string" then return end
    local foodInfo = Config.Foods[food]
    if not foodInfo then return end
    if phase ~= "SLEEP" then
        remote:FireClient(player, {type = "notice", text = "The monster is awake! DODGE!", color = Color3.fromRGB(255, 174, 96)})
        return
    end
    local now = os.clock()
    if now - profile.lastFeed < Config.FEED_COOLDOWN then return end
    local root = rootFor(player)
    if not root or not profile.pet or not profile.pet.PrimaryPart then return end
    if (root.Position - profile.pet.PrimaryPart.Position).Magnitude > Config.FEED_DISTANCE then
        remote:FireClient(player, {type = "notice", text = "Get closer to your pet!", color = Color3.fromRGB(255, 220, 142)})
        return
    end

    profile.lastFeed = now
    local reaction = weightedReaction(food, profile.lastFood)
    local combo = profile.lastFood == food and rng:NextNumber() < 0.24
    profile.lastFood = food
    totalActions += 1

    petEffect(profile, reaction, food)
    local earnedNoise = foodInfo.noise + reaction.noise + (if combo then 7 else 0)
    noise = math.min(Config.NOISE_MAX, noise + earnedNoise)
    addCoins(player, Config.FEED_REWARD + (if combo then 3 else 0))
    local text = player.DisplayName .. "'s " .. Config.Pets[profile.petIndex].name .. ": " .. reaction.title
    if combo then text ..= " + COMBO!" end
    notice(text, foodInfo.color)
    sendState()
end

remote.OnServerEvent:Connect(function(player: Player, command: any, arg: any)
    if command == "Feed" then
        feed(player, arg)
    elseif command == "Sync" then
        sendState(player)
        sendStats(player)
    end
end)

local function monsterAction()
    local choice = rng:NextInteger(1, 4)
    if choice == 1 then
        notice("GIGGLES STOMPS! JUMP AWAY!", Color3.fromRGB(255, 113, 146))
        local spot = Vector3.new(rng:NextNumber(-35, 35), 9, rng:NextNumber(-35, 35))
        World.wave(spot, 30, Color3.fromRGB(255, 116, 178))
        task.delay(0.8, function() nearbyKnock(spot, 28, 55) end)
    elseif choice == 2 then
        notice("GIANT SNEEZE! HOLD ON!", Color3.fromRGB(136, 229, 255))
        World.wave(Vector3.new(0, 14, 0), 88, Color3.fromRGB(122, 213, 255))
        task.delay(0.9, function() nearbyKnock(Vector3.new(0, 12, 0), 86, 72) end)
    elseif choice == 3 then
        notice("THE SKY IS RAINING JELLY!", Color3.fromRGB(255, 223, 114))
        for _ = 1, 3 do
            local spot = Vector3.new(rng:NextNumber(-70, 70), 11, rng:NextNumber(-70, 70))
            World.burst(spot, Color3.fromRGB(252, rng:NextInteger(130, 240), 192), 12, 12)
        end
    else
        notice("MONSTER FART TORNADO! RUN!", Color3.fromRGB(183, 244, 154))
        local spot = Vector3.new(rng:NextNumber(-40, 40), 12, rng:NextNumber(-40, 40))
        World.wave(spot, 38, Color3.fromRGB(175, 255, 152))
        task.delay(0.8, function() nearbyKnock(spot, 38, 38) end)
    end
end

local function surpriseWeather()
    local choice = rng:NextInteger(1, 6)
    if choice == 1 then
        notice("SUGAR RAIN! IT'S RAINING SPRINKLES!", Color3.fromRGB(255, 164, 205))
        for i = 1, 5 do
            local position = Vector3.new(rng:NextNumber(-60, 60), 15, rng:NextNumber(-60, 60))
            World.burst(position, Config.Foods.Candy.color, 12, 17)
        end
        noise = math.min(Config.NOISE_MAX, noise + 5)
    elseif choice == 2 then
        notice("GIGGLES SNORES LIKE A TRACTOR!", Color3.fromRGB(200, 177, 255))
        World.wave(Vector3.new(0, 11, 0), 65, Color3.fromRGB(200, 177, 255))
        noise = math.min(Config.NOISE_MAX, noise + 11)
    elseif choice == 3 then
        notice("EVERY PET: CONGA LINE!!!", Color3.fromRGB(153, 238, 212))
        for _, profile in pairs(profiles) do
            profile.effect = "Spin"
            profile.effectUntil = os.clock() + 4.5
        end
    elseif choice == 4 then
        notice("THE FLOOR JUST BURPED. WHY?!", Color3.fromRGB(255, 216, 120))
        World.wave(Vector3.new(0, 8, 0), 100, Color3.fromRGB(255, 237, 167))
        nearbyKnock(Vector3.new(0, 4, 0), 115, 14)
        noise = math.min(Config.NOISE_MAX, noise + 7)
    elseif choice == 5 then
        notice("MINI PET PARADE! LOOK AT THEM!", Color3.fromRGB(131, 220, 255))
        for _, profile in pairs(profiles) do
            if profile.pet and profile.pet.Parent then
                profile.pet:ScaleTo(0.52)
                profile.effect = "Mini"
                profile.effectUntil = os.clock() + 5
            end
        end
    else
        notice("A JELLYFISH CLOUD JUST PASSED BY...", Color3.fromRGB(255, 196, 243))
        for i = 1, 4 do
            local theta = (i / 4) * math.pi * 2
            local position = Vector3.new(math.cos(theta) * 35, 20, math.sin(theta) * 35)
            World.burst(position, Color3.fromRGB(175, 226, 255), 15, 20)
        end
    end
end

local function startWake()
    phase = "AWAKE"
    noise = Config.NOISE_MAX
    secondsLeft = Config.WAKE_SECONDS
    wakeCount += 1
    World.setMonsterAwake(true)
    notice("OH NO!!! YOU WOKE GIGGLES! SURVIVE!", Color3.fromRGB(255, 113, 145))
    World.wave(Vector3.new(0, 11, 0), 90, Color3.fromRGB(255, 104, 156))
    sendState()
end

local function endWake()
    phase = "COOLDOWN"
    noise = 0
    secondsLeft = Config.COOLDOWN_SECONDS
    World.setMonsterAwake(false)
    for _, player in ipairs(Players:GetPlayers()) do
        if profiles[player] and rootFor(player) then
            addCoins(player, Config.SURVIVAL_REWARD)
        end
    end
    notice("WE SURVIVED! +35 COINS! Giggles is sleepy again...", Color3.fromRGB(150, 255, 204))
    sendState()
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(onPlayerAdded, player)
end

local lastHeartbeat = 0
RunService.Heartbeat:Connect(function(dt: number)
    lastHeartbeat += dt
    if lastHeartbeat < 1 / 18 then return end
    lastHeartbeat = 0
    local t = os.clock()
    for player, profile in pairs(profiles) do
        local root = rootFor(player)
        local pet = profile.pet
        if root and root.Position.Y < -18 then
            root.CFrame = CFrame.new(0, 16, 74)
            root.AssemblyLinearVelocity = Vector3.zero
        end
        if root and pet and pet.Parent and pet.PrimaryPart then
            local wobble = math.sin(t * 3 + player.UserId) * 0.65
            local side = root.CFrame.RightVector * 4.8
            local behind = -root.CFrame.LookVector * 3.5
            local target = root.Position + side + behind + Vector3.new(0, 3.2 + wobble, 0)
            if (pet.PrimaryPart.Position - target).Magnitude > 60 then
                pet:PivotTo(CFrame.new(target))
            else
                local facing = CFrame.lookAt(target, root.Position + Vector3.new(0, 2, 0))
                if profile.effect == "Spin" and profile.effectUntil > t then
                    facing *= CFrame.Angles(0, t * 11, 0)
                elseif profile.effect == "Bounce" and profile.effectUntil > t then
                    facing += Vector3.new(0, math.abs(math.sin(t * 9)) * 3, 0)
                end
                pet:PivotTo(pet:GetPivot():Lerp(facing, 0.15))
            end
            if profile.effectUntil <= t and profile.effect ~= "" then
                profile.effect = ""
                pet:ScaleTo(1)
            end
        end
    end
end)

task.spawn(function()
    local actionCooldown = 0
    local surpriseCooldown = rng:NextInteger(17, 29)
    while true do
        task.wait(1)
        secondsLeft = math.max(0, secondsLeft - 1)
        if phase == "SLEEP" then
            surpriseCooldown -= 1
            if surpriseCooldown <= 0 and noise < Config.NOISE_MAX then
                surpriseWeather()
                surpriseCooldown = rng:NextInteger(19, 33)
            end
            if noise >= Config.NOISE_MAX or secondsLeft <= 0 then
                startWake()
            end
        elseif phase == "AWAKE" then
            actionCooldown -= 1
            if actionCooldown <= 0 and secondsLeft > 2 then
                monsterAction()
                actionCooldown = rng:NextInteger(4, 6)
            end
            if secondsLeft <= 0 then
                endWake()
            end
        elseif phase == "COOLDOWN" then
            if secondsLeft <= 0 then
                phase = "SLEEP"
                secondsLeft = Config.SLEEP_MAX_SECONDS
                notice("Shhh... Giggles is sleeping. Feed your pets!", Color3.fromRGB(180, 255, 222))
            end
        end
        sendState()
    end
end)

task.spawn(function()
    while true do
        task.wait(90)
        for player in pairs(profiles) do save(player) end
    end
end)

game:BindToClose(function()
    for player in pairs(profiles) do
        save(player)
    end
end)
