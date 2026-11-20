--!strict
-- Server-authoritative vertical slice. Clients request actions; the server decides rewards, chaos and knockback.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local AnalyticsService = game:GetService("AnalyticsService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Personality = require(ReplicatedStorage:WaitForChild("PetPersonality"))
local Affection = require(ReplicatedStorage:WaitForChild("PetAffection"))
local World = require(script.Parent:WaitForChild("World"))
local ArtLibrary = require(script.Parent:WaitForChild("ReferenceMeshLibrary"))
local NativeAvatar = require(script.Parent:WaitForChild("NativeGardenerAvatar"))
local Progression = require(script.Parent:WaitForChild("Progression"))
local ProfileStore = require(script.Parent:WaitForChild("ProfileStore"))
local Garden = require(script.Parent:WaitForChild("Garden"))
local GardenActionVFX = require(script.Parent:WaitForChild("GardenActionVFX"))
local RecipeCatalog = require(script.Parent:WaitForChild("RecipeCatalog"))
local RescueObjective = require(script.Parent:WaitForChild("RescueObjective"))
local GardenConfig = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local SeedMerchant = require(ReplicatedStorage:WaitForChild("SeedMerchant"))
local X = require(ReplicatedStorage:WaitForChild("ExpeditionConfig"))
local SeedHunt = require(script.Parent:WaitForChild("SeedHunt"))
local ForestWorld = require(script.Parent:WaitForChild("ForestWorld"))

World.build()
local remote = Instance.new("RemoteEvent")
remote.Name = "MonsterRemote"
remote.Parent = ReplicatedStorage

local persistence = ProfileStore.new(DataStoreService, Config.DATASTORE_NAME, Progression.serialize)
local rng = Random.new()
local noise = 0
local phase = "SLEEP"
local secondsLeft = Config.SLEEP_MAX_SECONDS
local profiles: {[Player]: any} = {}
local loading: {[Player]: boolean} = {}
local closingProfiles: {[Player]: any} = {}
local shuttingDown = false
local totalActions = 0
local wakeCount = 0
local farmSlots: {[number]: Player} = {}
local farmOfPlayer: {[Player]: number} = {}
local currentWeather = "Sunny"
local weatherEndsAt = os.time() + 95
local festivalFinds = 0
local festivalPlayers: {[Player]: boolean} = {}

-- Official Roblox custom analytics; only meaningful in a published experience.
-- Do not attach PII and never trust client-supplied event names/values.
local function metric(player: Player, eventName: string, value: number?)
    if RunService:IsStudio() then return end
    task.spawn(function()
        local ok, err = pcall(function()
            AnalyticsService:LogCustomEvent(player, eventName, value or 1)
        end)
        if not ok then warn("Analytics temporarily unavailable: " .. tostring(err)) end
    end)
end

local function onceMetric(player: Player, profile: any, eventName: string)
    if profile.metricFlags[eventName] then return end
    profile.metricFlags[eventName] = true
    metric(player, eventName)
end

local function notice(message: string, color: Color3?)
    remote:FireAllClients({type = "notice", text = message, color = color or Color3.fromRGB(255, 255, 255)})
end

local function sendStats(player: Player)
    local profile = profiles[player]
    if profile then
        local p = profile.personalities[profile.petIndex]
        remote:FireClient(player, {type = "stats", coins = profile.coins, pet = Config.Pets[profile.petIndex].name, hearts = profile.hearts, knockedOut = profile.knockedOut, petMood = if p then Personality.mood(p, phase == "AWAKE") else "Calm", petTemperament = if p then p.temperament else "Unknown"})
    end
end

local function sendCollection(player: Player)
    local profile = profiles[player]
    if not profile then return end
    local catalog = Progression.catalog(profile)
    catalog.type = "collection"
    remote:FireClient(player, catalog)
end

local function sendGarden(player: Player)
    local profile = profiles[player]
    if not profile then return end
    local snapshot = Garden.snapshot(profile.garden)
    snapshot.type = "garden"
    snapshot.slot = farmOfPlayer[player] or 0
    snapshot.saving = profile.loaded
    snapshot.weather = currentWeather
    snapshot.weatherEndsAt = weatherEndsAt
    snapshot.festivalFinds = festivalFinds
    snapshot.festivalGoal = X.FestivalGoal
    remote:FireClient(player, snapshot)
end

local function sendState(player: Player?)
    local update = {type = "state", phase = phase, noise = noise, maxNoise = Config.NOISE_MAX, time = secondsLeft, wakes = wakeCount, rescue = RescueObjective.status(), weather = currentWeather, festivalFinds = festivalFinds, festivalGoal = X.FestivalGoal}
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

local function monsterStrike(center: Vector3, radius: number, strength: number, jumpAvoids: boolean)
    if phase ~= "AWAKE" then return end
    for _, player in ipairs(Players:GetPlayers()) do
        local profile = profiles[player]
        local root = rootFor(player)
        if profile and root and not profile.knockedOut and (root.Position - center).Magnitude <= radius then
            if jumpAvoids and root.Position.Y > 15 then continue end
            if os.clock() - profile.lastHit < 2.5 then continue end
            profile.lastHit = os.clock()
            profile.hearts = math.max(0, profile.hearts - 1)
            knock(root, center, strength)
            remote:FireClient(player, {type = "shake", amount = 1})
            sendStats(player)
            if profile.hearts <= 0 then
                profile.knockedOut = true
                remote:FireClient(player, {type = "notice", text = "OOPS! YOU GOT BONKED! Watch until next round.", color = Color3.fromRGB(255, 150, 158)})
                task.delay(0.2, function()
                    if root.Parent and profiles[player] == profile then
                        root.CFrame = CFrame.new(0, 17, 74)
                        root.AssemblyLinearVelocity = Vector3.zero
                    end
                end)
            else
                remote:FireClient(player, {type = "notice", text = "BONK! " .. profile.hearts .. " hearts left!", color = Color3.fromRGB(255, 150, 158)})
            end
        end
    end
end

local function addCoins(player: Player, amount: number)
    local profile = profiles[player]
    if not profile then return end
    profile.coins += math.max(0, math.floor(amount))
    if profile.loaded then
        profile.dirty = true
        profile.revision += 1
    end
    sendStats(player)
end

local function save(player: Player)
    local profile = profiles[player]
    if profile then persistence:save(player.UserId, profile) end
end

local function movePetNearPlayer(player: Player)
    local profile = profiles[player]
    local root = rootFor(player)
    if not profile or not root or not profile.pet or not profile.pet.Parent then return end
    profile.pet:PivotTo(CFrame.new(root.Position + Vector3.new(4, 4, -3)))
end

local function careUpdate(player: Player)
    local profile = profiles[player]
    if not profile then return end
    local petInfo = Config.Pets[profile.petIndex]
    remote:FireClient(player, {
        type = "petCare",
        petting = profile.petting,
        carrying = profile.carrying,
        cat = Affection.isCat(petInfo.description or ""),
        purr = profile.purr,
        purrSoundConfigured = type(Config.PurrSoundId) == "number" and Config.PurrSoundId > 0,
    })
end

local function stopPetting(player: Player, profile: any)
    if not profile.petting and profile.purr <= 0 then return end
    profile.petting = false
    profile.pettingSession = nil
    profile.purr = 0
    profile.purrStage = 0
    if profile.pet then World.setPurr(profile.pet, 0, Config.PurrSoundId) end
    if profiles[player] == profile then careUpdate(player) end
end

local function startPetting(player: Player)
    local profile = profiles[player]
    if not profile or profile.petting or phase ~= "SLEEP" then return end
    local now = os.clock()
    if now - profile.lastStrokingStart < 1.4 then return end
    local root = rootFor(player)
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 or not profile.pet or not profile.pet.PrimaryPart then return end
    if (root.Position - profile.pet.PrimaryPart.Position).Magnitude > Affection.PetDistance then
        remote:FireClient(player, {type = "petFeeling", text = "Come closer to your animal before petting."})
        return
    end
    local personality = profile.personalities[profile.petIndex]
    if not personality then return end
    profile.lastStrokingStart = now
    profile.lastCarePulse = now
    profile.petting = true
    profile.purr = 0
    local petInfo = Config.Pets[profile.petIndex]
    local cat = Affection.isCat(petInfo.description or "")
    profile.pettingSession = Affection.newSession(personality, cat, rng:NextNumber())
    World.emotePet(profile.pet, Personality.mood(personality), if cat then "Gentle strokes" else "Cuddles")
    careUpdate(player)
end

local function keepPetting(player: Player)
    local profile = profiles[player]
    if not profile or not profile.petting then return end
    local now = os.clock()
    if now - profile.lastCarePulse >= 0.65 then
        profile.lastCarePulse = now
    end
end

local function toggleCarry(player: Player)
    local profile = profiles[player]
    if not profile then return end
    local now = os.clock()
    if now - profile.lastCarryChange < 0.65 then return end
    profile.lastCarryChange = now
    if profile.carrying then
        profile.carrying = false
        remote:FireClient(player, {type = "petFeeling", text = "Your little friend is back on its paws."})
        careUpdate(player)
        return
    end
    local root = rootFor(player)
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 or not profile.pet or not profile.pet.PrimaryPart then return end
    if (root.Position - profile.pet.PrimaryPart.Position).Magnitude > Affection.CarryDistance then return end
    local personality = profile.personalities[profile.petIndex]
    if not personality then return end
    local reluctance = if personality.temperament == "Grumpy" then 0.24
        elseif personality.temperament == "Shy" then 0.16
        elseif personality.temperament == "Wild" then 0.18 else 0.03
    reluctance = math.max(0.01, reluctance - personality.bond / 550)
    if rng:NextNumber() < reluctance then
        remote:FireClient(player, {type = "petFeeling", text = "NOT NOW! Your pet wriggled free of the cuddle!"})
        World.emotePet(profile.pet, "Grumpy", "No hugs")
        return
    end
    profile.carrying = true
    World.emotePet(profile.pet, Personality.mood(personality), "In arms")
    remote:FireClient(player, {type = "petFeeling", text = "You picked up " .. Config.Pets[profile.petIndex].name .. "! Hold STROKE to pet."})
    careUpdate(player)
end

local function onPlayerAdded(player: Player)
    if shuttingDown or loading[player] or profiles[player] then return end
    loading[player] = true
    local profile = Progression.new()
    profile.metricFlags = {}
    profile.lastFeed = -100
    profile.lastSync = -100
    profile.lastShopAction = -100
    profile.lastDailyRequest = -100
    profile.lastGardenAction = -100
    profile.lastPetGardenAssist = -100
    profile.lastLure = -100
    profile.lastGardenVisit = -100
    profile.lastFood = ""
    profile.lastPetInteraction = -100
    profile.lastCarryChange = -100
    profile.lastStrokingStart = -100
    profile.lastCarePulse = -100
    profile.petting = false
    profile.carrying = false
    profile.pettingSession = nil
    profile.purr = 0
    profile.purrStage = 0
    profile.idleAction = "Cuddles"
    profile.loaded = false
    profile.dirty = false
    profile.revision = 0
    profile.effectUntil = 0
    profile.effect = ""
    profile.pet = nil
    profile.hearts = 3
    profile.knockedOut = false
    profile.lastHit = -100
    local ok, result = persistence:load(player.UserId)
    if ok then
        profile.loaded = true
        Progression.load(profile, result)
    else
        warn("DWTM: data load unavailable for " .. player.UserId .. ". Progress is session-only.")
    end
    loading[player] = nil
    if shuttingDown or player.Parent ~= Players then return end
    -- Publish only fully loaded state. Remotes/timers cannot mutate a temporary
    -- starter garden while GetAsync yields and then overwrite or lose progress.
    profiles[player] = profile
    onceMetric(player, profile, "JoinedGame")
    task.delay(600, function()
        if profiles[player] == profile then metric(player, "StayedTenMinutes") end
    end)
    for petId in pairs(profile.owned) do
        if Progression.ensurePersonality(profile, petId, player.UserId) then
            if profile.loaded then profile.dirty = true end
            profile.revision += 1
        end
    end

    local petDefinition = Config.Pets[profile.petIndex]
    profile.pet = World.makePet(petDefinition.name .. "_" .. player.UserId, petDefinition.color, petDefinition.ear == "pointy")
    World.stylePersonality(profile.pet, profile.personalities[profile.petIndex])
    World.emotePet(profile.pet, Personality.mood(profile.personalities[profile.petIndex]), "Hello")
    movePetNearPlayer(player)
    for slot = 1, GardenConfig.SLOT_COUNT do
        if not farmSlots[slot] then
            farmSlots[slot] = player
            farmOfPlayer[player] = slot
            World.createGarden(player.UserId, player.DisplayName, slot)
            World.updateGarden(player.UserId, profile.garden, GardenConfig)
            break
        end
    end

    local function characterReady(character: Model)
        local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
        if humanoid and humanoid:IsA("Humanoid") then
            humanoid.Died:Connect(function()
                profile.carrying = false
                profile.petting = false
                profile.pettingSession = nil
                profile.purr = 0
                if profile.pet then World.setPurr(profile.pet, 0, Config.PurrSoundId) end
                careUpdate(player)
                if phase == "AWAKE" and profiles[player] == profile and player.Character == character then
                    profile.knockedOut = true
                    profile.hearts = 0
                    sendStats(player)
                    remote:FireClient(player, {type = "notice", text = "OH NO! YOU'RE OUT UNTIL THE NEXT ROUND!", color = Color3.fromRGB(255, 161, 170)})
                end
            end)
        end
        task.wait(1.0)
        if player.Character == character then
            -- Display chibi gardener only when all creator-owned imported mesh
            -- components exist; otherwise leave Roblox avatar untouched.
            if not ArtLibrary.applyGardenerAvatar(character) then
                NativeAvatar.apply(character)
            end
            movePetNearPlayer(player)
        end
    end
    player.CharacterAdded:Connect(function(character: Model)
        task.spawn(characterReady, character)
    end)
    -- Roblox can finish avatar appearance after CharacterAdded. Retry only
    -- when the final outfit is ready, without replacing the Humanoid rig.
    player.CharacterAppearanceLoaded:Connect(function(character: Model)
        if player.Character == character then
            if not ArtLibrary.applyGardenerAvatar(character) then
                NativeAvatar.apply(character)
            end
        end
    end)
    if player.Character then
        task.spawn(characterReady, player.Character)
    end
    sendStats(player)
    sendCollection(player)
    sendGarden(player)
    sendState(player)
    careUpdate(player)
    remote:FireClient(player, {type = "notice", text = "Meet " .. petDefinition.name .. "! Feed it. Nothing can go wrong... right?", color = Color3.fromRGB(252, 205, 255)})
end

local function onPlayerRemoving(player: Player)
    local profile = profiles[player]
    if not profile then return end
    closingProfiles[player] = profile
    profiles[player] = nil
    if profile then stopPetting(player, profile) end
    if profile and profile.pet then profile.pet:Destroy() end
    World.removeGarden(player.UserId)
    local slot = farmOfPlayer[player]
    if slot then farmSlots[slot] = nil end
    farmOfPlayer[player] = nil
    persistence:save(player.UserId, profile)
    closingProfiles[player] = nil
end

local function notifyBondMilestone(player: Player, profile: any, previous: string)
    local p = profile.personalities[profile.petIndex]
    if not p then return end
    local current = Personality.bondStage(p)
    if previous ~= current then
        task.delay(1.6, function()
            if profiles[player] == profile then
                remote:FireClient(player, {type = "petFeeling", text = "💖 " .. Config.Pets[profile.petIndex].name .. " friendship level: " .. current .. "!"})
                if profile.pet and profile.pet.PrimaryPart then
                    World.burst(profile.pet.PrimaryPart.Position, Color3.fromRGB(255, 163, 198), 16, 12)
                end
            end
        end)
    end
end

local function weightedReaction(food: string, previousFood: string, petIndex: number, personality: any)
    local total = 0
    local weights = {}
    local quirk = Config.Pets[petIndex].quirk
    local favorites = {
        Trickster = {Clone = true, Spin = true, Hiccup = true},
        Dreamer = {Mini = true, Cloud = true, Rainbow = true},
        Bouncer = {Bounce = true, Giant = true, Sneeze = true},
        Sparkle = {Confetti = true, Disco = true, Rainbow = true},
        Storm = {Meteor = true, Sneeze = true, Hiccup = true},
        Gremlin = {Giant = true, Clone = true, Meteor = true},
    }
    for index, reaction in ipairs(Config.Reactions) do
        local weight = reaction.weight
        if favorites[quirk] and favorites[quirk][reaction.id] then weight *= 1.6 end
        if personality then weight *= Personality.reactionMultiplier(personality, reaction.id) end
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
    World.tintPet(pet, Config.Pets[profile.petIndex].color)

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
    elseif id == "Rainbow" or id == "Disco" then
        local expiry = profile.effectUntil
        task.spawn(function()
            for step = 1, 17 do
                if profile.effectUntil ~= expiry or not pet.Parent then break end
                local hue = (step * (if id == "Disco" then 0.23 else 0.08)) % 1
                local tint = Color3.fromHSV(hue, 0.55, 1)
                World.tintPet(pet, tint)
                if step % 4 == 0 and pet.PrimaryPart then
                    World.burst(pet.PrimaryPart.Position, tint, 6, 8)
                end
                task.wait(if id == "Disco" then 0.14 else 0.19)
            end
        end)
    elseif id == "Cloud" then
        local bubbleParent = workspace:WaitForChild("MonsterIsland")
        for i = 1, 9 do
            local bubble = Instance.new("Part")
            bubble.Name = "FloatingBubble"
            bubble.Shape = Enum.PartType.Ball
            bubble.Size = Vector3.new(2.5, 2.5, 2.5) * rng:NextNumber(0.7, 1.7)
            bubble.Material = Enum.Material.Glass
            bubble.Color = Color3.fromRGB(174, 239, 255)
            bubble.Transparency = 0.35
            bubble.Anchored = true
            bubble.CanCollide = false
            bubble.Position = pos + Vector3.new(rng:NextNumber(-5, 5), rng:NextNumber(0, 3), rng:NextNumber(-5, 5))
            bubble.Parent = bubbleParent
            TweenService:Create(bubble, TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Position = bubble.Position + Vector3.new(0, rng:NextNumber(12, 20), 0),
                Transparency = 1,
                Size = Vector3.new(0.3, 0.3, 0.3),
            }):Play()
            Debris:AddItem(bubble, 3)
        end
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
        if id == "Confetti" then
            for i = 1, 5 do
                World.burst(pos, Color3.fromHSV(i / 5, 0.5, 1), 7, 12)
            end
        else
            World.burst(pos, foodColor, 15, 11)
        end
        if id == "Hiccup" then
            World.wave(pos, 12, foodColor)
            nearbyKnock(pos, 14, 12)
        end
    end
end

local function feed(player: Player, food: any, craftedId: string?)
    local profile = profiles[player]
    if not profile or typeof(food) ~= "string" then return end
    local foodInfo = Config.Foods[food]
    if craftedId then
        local recipe = RecipeCatalog.Recipes[craftedId]
        if not recipe or recipe.type ~= "feed" or recipe.baseFood ~= food then return end
    end
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

    if craftedId then
        local ok, message = Garden.consume(profile.garden, craftedId, "feed")
        if not ok then
            remote:FireClient(player, {type = "notice", text = message, color = Color3.fromRGB(255, 190, 130)})
            return
        end
        profile.dirty = profile.loaded
        profile.revision += 1
        sendGarden(player)
    end
    profile.lastFeed = now
    onceMetric(player, profile, "FirstPetFed")
    local activePersonality = profile.personalities[profile.petIndex]
    local reaction = weightedReaction(food, profile.lastFood, profile.petIndex, activePersonality)
    local earlierStage = Personality.bondStage(activePersonality)
    local emotionText, personalityNoise = Personality.feed(activePersonality, food)
    notifyBondMilestone(player, profile, earlierStage)
    if profile.loaded then profile.dirty = true end
    profile.revision += 1
    local combo = profile.lastFood == food and rng:NextNumber() < 0.24
    profile.lastFood = food
    totalActions += 1

    petEffect(profile, reaction, food)
    World.emotePet(profile.pet, Personality.mood(activePersonality), if personalityNoise > 0 then "Yuck" else "Nom")
    local earnedNoise = math.max(0, foodInfo.noise + reaction.noise + personalityNoise + (if combo then 7 else 0))
    if craftedId then
        earnedNoise += RecipeCatalog.Recipes[craftedId].extraNoise
        if profile.pet and profile.pet.PrimaryPart then
            World.burst(profile.pet.PrimaryPart.Position, GardenConfig.Crops.Berry.color, 12, 11)
        end
    end
    noise = math.min(Config.NOISE_MAX, noise + earnedNoise)
    local bonus, discoveries = Progression.recordFeed(profile, reaction.id)
    addCoins(player, Config.FEED_REWARD + (if combo then 3 else 0) + bonus)
    sendCollection(player)
    local text = player.DisplayName .. "'s " .. Config.Pets[profile.petIndex].name .. ": " .. reaction.title
    if combo then
        text ..= " + COMBO!"
        remote:FireAllClients({type = "soundCue", cue = "Boing"})
    end
    if craftedId then text ..= " (GARDEN RECIPE!)" end
    notice(text, foodInfo.color)
    remote:FireClient(player, {type = "petFeeling", text = Config.Pets[profile.petIndex].name .. ": " .. emotionText})
    sendStats(player)
    sendState()
    if #discoveries > 0 then
        local message = table.concat(discoveries, " | ")
        task.delay(1.15, function()
            if profiles[player] == profile then
                remote:FireClient(player, {type = "questToast", text = message})
            end
        end)
    end
end

local function switchPet(player: Player, rawId: any, isPurchase: boolean)
    local profile = profiles[player]
    if not profile then return end
    if not profile.loaded then
        remote:FireClient(player, {type = "notice", text = "Saving is unavailable. Pet purchases are temporarily disabled.", color = Color3.fromRGB(255, 184, 125)})
        return
    end
    local ok, message
    if isPurchase then
        ok, message = Progression.buy(profile, rawId)
    else
        ok, message = Progression.equip(profile, rawId)
    end
    if ok then
        if isPurchase then
            Progression.ensurePersonality(profile, rawId, player.UserId, rng:NextInteger(1, 2147483645))
        end
        profile.dirty = true
        profile.revision += 1
        -- Buying does not auto-equip: avoids charging again when a user just switches pets.
        if not isPurchase then
            stopPetting(player, profile)
            profile.carrying = false
            if profile.pet then profile.pet:Destroy() end
            local definition = Config.Pets[profile.petIndex]
            profile.pet = World.makePet(definition.name .. "_" .. player.UserId, definition.color, definition.ear == "pointy")
            World.stylePersonality(profile.pet, profile.personalities[profile.petIndex])
            World.emotePet(profile.pet, Personality.mood(profile.personalities[profile.petIndex]), "Hello")
            movePetNearPlayer(player)
            careUpdate(player)
        end
        sendStats(player)
        sendCollection(player)
    end
    remote:FireClient(player, {type = "notice", text = message, color = if ok then Color3.fromRGB(162, 255, 201) else Color3.fromRGB(255, 182, 151)})
end

local function interactWithPet(player: Player, rawAction: any)
    if typeof(rawAction) ~= "string" or (rawAction ~= "Pet" and rawAction ~= "Play" and rawAction ~= "Comfort") then return end
    local profile = profiles[player]
    if not profile or phase == "AWAKE" then return end
    local now = os.clock()
    if now - profile.lastPetInteraction < 3.5 then return end
    local root = rootFor(player)
    if not root or not profile.pet or not profile.pet.PrimaryPart then return end
    if (root.Position - profile.pet.PrimaryPart.Position).Magnitude > Config.FEED_DISTANCE then
        remote:FireClient(player, {type = "petFeeling", text = "Come closer to your pet!"})
        return
    end
    profile.lastPetInteraction = now
    local p = profile.personalities[profile.petIndex]
    if not p then return end
    local earlierStage = Personality.bondStage(p)
    local success, message = Personality.interact(p, rawAction)
    if success then
        notifyBondMilestone(player, profile, earlierStage)
        if profile.loaded then profile.dirty = true end
        profile.revision += 1
        profile.idleAction = if rawAction == "Play" then "Jumps" elseif rawAction == "Pet" then "Cuddles" else "Naps"
        World.emotePet(profile.pet, Personality.mood(p), profile.idleAction)
        if rawAction == "Play" and p.traits.mischief > 60 then
            noise = math.min(Config.NOISE_MAX, noise + 3)
            World.burst(profile.pet.PrimaryPart.Position, Color3.fromRGB(254, 201, 121), 9, 8)
            sendState()
        elseif rawAction == "Comfort" then
            World.burst(profile.pet.PrimaryPart.Position, Color3.fromRGB(215, 175, 255), 8, 7)
        end
        sendStats(player)
        sendCollection(player)
    end
    remote:FireClient(player, {type = "petFeeling", text = Config.Pets[profile.petIndex].name .. ": " .. message})
end

local function gardenAction(player: Player, command: string, arg: any)
    local profile = profiles[player]
    if not profile then return false end
    -- The shop/menu cannot be used to hide from Giggles or mutate the
    -- persistent garden after the player has been knocked out.
    if phase == "AWAKE" or profile.knockedOut then
        remote:FireClient(player, {type = "notice",
            text = "Survive the chase first! Your garden will still be here."})
        return false
    end
    local now = os.clock()
    if now - profile.lastGardenAction < 0.23 then return end
    profile.lastGardenAction = now
    local g = profile.garden
    local ok, message, price
    local newlyDiscovered = false
    local harvestedMutation = false
    local harvestedSeed: string? = nil
    if command == "GardenHarvest" and typeof(arg) == "number" and arg == math.floor(arg)
        and arg >= 1 and arg <= GardenConfig.PLOT_COUNT then
        local plot = g.plots[arg]
        harvestedMutation = plot and plot.mutation ~= nil or false
        harvestedSeed = if plot then plot.seed else nil
    end
    if command == "GardenMerchantBuy" then
        if not profile.loaded then
            remote:FireClient(player, {type = "notice", text = "Saving is offline. Merchant purchases are paused."})
            return
        end
        ok, message, price = SeedMerchant.buy(g, profile.coins, arg, os.time())
        if ok then profile.coins -= price end
    elseif command == "GardenBuySeed" then
        if not profile.loaded then
            remote:FireClient(player, {type = "notice", text = "Saving is offline. Seed purchases are paused.", color = Color3.fromRGB(255, 193, 130)})
            return
        end
        ok, message, price = Garden.buySeed(g, profile.coins, arg)
        if ok then profile.coins -= price end
    elseif command == "GardenPlant" then
        if typeof(arg) ~= "table" then return end
        ok, message = Garden.plant(g, arg.plot, arg.seed)
        if ok then Garden.weather(g, currentWeather, function() return rng:NextNumber() end) end
    elseif command == "GardenHarvest" then
        ok, message = Garden.harvest(g, arg)
    elseif command == "GardenFertilize" then
        if typeof(arg) ~= "table" then return end
        ok, message = Garden.fertilize(g, arg.plot, arg.fertilizer)
    elseif command == "GardenCraft" then
        ok, message = Garden.craft(g, arg)
    elseif command == "GardenAssist" then
        local root = rootFor(player)
        local home = World.gardenSpawn(player.UserId)
        local personality = profile.personalities[profile.petIndex]
        if not root or not home or not personality then return end
        if (root.Position - home).Magnitude > 31 then
            ok, message = false, "Visit your garden to ask your pet for help!"
        elseif now - profile.lastPetGardenAssist < 9 then
            ok, message = false, "Your pet needs a short break!"
        else
            ok, message = Garden.assist(g, arg, personality.traits.curiosity)
            if ok then
                profile.lastPetGardenAssist = now
                if profile.pet and profile.pet.PrimaryPart then
                    World.burst(profile.pet.PrimaryPart.Position, Color3.fromRGB(183, 246, 170), 12, 12)
                    World.emotePet(profile.pet, Personality.mood(personality), "Helpful gardener")
                end
            end
        end
    elseif command == "GardenExperiment" then
        local resultId
        ok, message, resultId, newlyDiscovered = Garden.experiment(g, arg)
    else
        return
    end
    if ok then
        if command == "GardenPlant" then onceMetric(player, profile, "FirstSeedPlanted") end
        if newlyDiscovered then metric(player, "SecretRecipeFound") end
        if profile.loaded then profile.dirty = true end
        profile.revision += 1
        World.updateGarden(player.UserId, g, GardenConfig)
        sendGarden(player)
        if command == "GardenPlant" or command == "GardenHarvest" then
            local plotIndex = if command == "GardenPlant" then arg.plot else arg
            if typeof(plotIndex) == "number" then
                local spot = World.plotPosition(player.UserId, plotIndex)
                if spot then
                    local seedId = if command == "GardenHarvest" then harvestedSeed else arg.seed
                    local def = if typeof(seedId) == "string" then GardenConfig.Crops[seedId] else nil
                    GardenActionVFX.play(workspace, spot, command == "GardenHarvest",
                        if def then def.color else nil)
                end
            end
        end
        if newlyDiscovered then
            addCoins(player, 15)
            local root = rootFor(player)
            if root then World.burst(root.Position + Vector3.new(0, 3, 0), Color3.fromRGB(255, 222, 145), 22, 14) end
        end
        sendStats(player)
        if command == "GardenHarvest" then
            remote:FireClient(player, {type = "soundCue", cue = if harvestedMutation then "MutationSparkle" else "HarvestPop"})
            if phase == "SLEEP" and harvestedSeed then
                -- Unpredictable but harmless harvest surprises: crops are safe in
                -- inventory even when the monster wakes. No pay-to-win outcomes.
                local pet = profile.personalities[profile.petIndex]
                local mischief = if pet then pet.traits.mischief / 100 else 0
                local chance = 0.12 + mischief * 0.1
                if harvestedSeed == "WhisperWheat" or harvestedSeed == "GlowPumpkin"
                    or harvestedSeed == "ThunderPlum" or harvestedSeed == "Pepper" then
                    chance += 0.2
                end
                if rng:NextNumber() < chance then
                    local reactions = {
                        {text = "THE WHEAT STARTED SINGING OPERA!", cue = "ComedySting", noise = 7},
                        {text = "A PUMPKIN JUST LAUGHED AT YOUR CAT!", cue = "SuspiciousMeow", noise = 6},
                        {text = "YOUR PET SNEEZED INTO THE VEGETABLES!", cue = "RecordScratch", noise = 9},
                        {text = "THE HARVEST MADE A TINY DRAMATIC SCENE!", cue = "TinyViolin", noise = 4},
                    }
                    local incident = reactions[rng:NextInteger(1, #reactions)]
                    noise = math.min(Config.NOISE_MAX, noise + incident.noise)
                    local root = rootFor(player)
                    if root then World.burst(root.Position + Vector3.new(0, 2, 0), GardenConfig.Crops[harvestedSeed].color, 15, 10) end
                    notice(incident.text, Color3.fromRGB(255, 216, 150))
                    remote:FireAllClients({type = "soundCue", cue = incident.cue})
                    sendState()
                end
            end
        elseif newlyDiscovered then
            remote:FireClient(player, {type = "soundCue", cue = "RareDiscovery"})
        elseif command == "GardenMerchantBuy" then
            remote:FireClient(player, {type = "soundCue", cue = "ComedySting"})
        elseif command == "GardenAssist" then
            remote:FireClient(player, {type = "soundCue", cue = "WeatherChime"})
        end
    end
    remote:FireClient(player, {type = if newlyDiscovered then "questToast" else "notice", text = message, color = if ok then Color3.fromRGB(164, 255, 186) else Color3.fromRGB(255, 196, 143)})
    return ok == true
end

-- Playable farming at the actual 3D soil beds. Roblox ProximityPrompt
-- supplies keyboard, gamepad and touch interaction without needing a menu.
-- No client-provided plot coordinates, inventory or owner IDs are trusted.
World.setGardenPromptHandler(function(player: Player, ownerId: number, index: number)
    if player.UserId ~= ownerId then
        remote:FireClient(player, {type = "notice", text = "This is another gardener's plot!"})
        return
    end
    local profile = profiles[player]
    if not profile or typeof(index) ~= "number" or index ~= math.floor(index)
        or index < 1 or index > GardenConfig.PLOT_COUNT then return end
    local root = rootFor(player)
    local spot = World.plotPosition(ownerId, index)
    if not root or not spot or (root.Position - spot).Magnitude > 11 then return end
    local character = player.Character
    local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
    if not humanoid or humanoid.Health <= 0 or profile.knockedOut then return end
    if phase == "AWAKE" then
        remote:FireClient(player, {type = "notice", text = "Run! Giggles is awake. Gardening can wait!"})
        return
    end
    local plot = profile.garden.plots[index]
    if plot then
        if os.time() >= plot.readyAt then
            gardenAction(player, "GardenHarvest", index)
        else
            local remaining = math.max(1, plot.readyAt - os.time())
            remote:FireClient(player, {
                type = "notice",
                text = GardenConfig.Crops[plot.seed].name .. " is growing — " ..
                    tostring(remaining) .. " seconds until harvest!",
            })
        end
        return
    end
    local chosen: string? = nil
    for _, seed in ipairs(GardenConfig.Order) do
        if (profile.garden.seeds[seed] or 0) > 0 then
            chosen = seed
            break
        end
    end
    if chosen then
        gardenAction(player, "GardenPlant", {plot = index, seed = chosen})
    else
        remote:FireClient(player, {
            type = "notice",
            text = "No seeds left. Open Garden to buy or collect more seeds!",
        })
    end
end)

local function useLure(player: Player, id: any)
    local profile = profiles[player]
    if not profile or typeof(id) ~= "string" then return end
    local lure = RecipeCatalog.Recipes[id]
    if not lure or lure.type ~= "lure" then return end
    if phase ~= "SLEEP" then
        remote:FireClient(player, {type = "notice", text = "Wait until the monster sleeps!", color = Color3.fromRGB(255, 202, 156)})
        return
    end
    if os.clock() - profile.lastLure < 10 then return end
    local root = rootFor(player)
    if not root then return end
    local ok, message = Garden.consume(profile.garden, id, "lure")
    if not ok then
        remote:FireClient(player, {type = "notice", text = message, color = Color3.fromRGB(255, 182, 136)})
        return
    end
    profile.lastLure = os.clock()
    if profile.loaded then profile.dirty = true end
    profile.revision += 1
    local effects = {
        SillyLure = {visitors = 1, noise = 11, coins = 8},
        MonsterLure = {visitors = 3, noise = 28, coins = 20},
        GlowLure = {visitors = 2, noise = 14, coins = 12},
        CloudLure = {visitors = 2, noise = 17, coins = 13},
        ThunderLure = {visitors = 4, noise = 32, coins = 25},
        RainbowLure = {visitors = 3, noise = 24, coins = 18},
    }
    local effect = effects[id]
    if not effect then return end
    local center = root.Position + root.CFrame.LookVector * 9
    World.burst(center, Color3.fromHSV(rng:NextNumber(), 0.56, 1), if effect.visitors > 2 then 26 else 17, 14)
    noise = math.min(Config.NOISE_MAX, noise + effect.noise)
    local visitors = effect.visitors
    for i = 1, visitors do
        local definition = Config.Pets[rng:NextInteger(1, #Config.Pets)]
        local visitor = World.makePet("Wild" .. definition.name .. "_" .. i, definition.color, definition.ear == "pointy")
        visitor.Name = "WildVisitor"
        visitor:PivotTo(CFrame.new(center + Vector3.new(i * 4 - visitors * 2, 4, -2)))
        Debris:AddItem(visitor, 8)
    end
    addCoins(player, effect.coins)
    sendGarden(player)
    sendState()
    notice(player.DisplayName .. " used " .. message .. "! WILD VISITORS!", Color3.fromRGB(192, 255, 150))
end

-- The seed forest does not rely on trust in client coordinates. Players must
-- walk to the physical cache and hold its built-in ProximityPrompt.
local function gatherSeed(player: Player, id: string)
    if phase ~= "SLEEP" then
        remote:FireClient(player, {type = "notice", text = "Explore when Giggles is sleeping!", color = Color3.fromRGB(255, 184, 134)})
        return
    end
    local profile = profiles[player]
    local found = SeedHunt.node(id)
    local root = rootFor(player)
    if not profile or not found or not root then return end
    local c = found.node
    if (root.Position - Vector3.new(c.x, 9.8, c.z)).Magnitude > 16 then return end
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    local pet = profile.personalities[profile.petIndex]
    local assist = if pet then math.max(0, (pet.traits.curiosity - 50) / 1000) else 0
    local ok, message, seedKey, rarity, discovered = SeedHunt.collect(profile.garden.hunt, profile.garden.seeds, id, rng:NextNumber(), assist, os.time())
    if not ok then
        remote:FireClient(player, {type = "notice", text = message, color = Color3.fromRGB(255, 207, 142)})
        return
    end
    if profile.loaded then profile.dirty = true end
    profile.revision += 1
    onceMetric(player, profile, "FirstSeedLocated")
    if rarity == "rare" then metric(player, "RareSeedLocated") end
    festivalFinds += 1
    festivalPlayers[player] = true
    World.burst(root.Position + Vector3.new(0, 3, 0), GardenConfig.Crops[seedKey].color, if rarity == "rare" then 25 else 12, 12)
    remote:FireClient(player, {type = "seedFound", text = message, rarity = rarity, discovered = discovered, seed = seedKey})
    remote:FireClient(player, {type = "soundCue", cue = if rarity == "rare" then "RareDiscovery" else "SeedFind"})
    if discovered then addCoins(player, 12) end
    if SeedHunt.claimQuest(profile.garden.hunt, os.time()) then
        addCoins(player, 45)
        remote:FireClient(player, {type = "questToast", text = "EXPLORER QUEST! +45 COINS!"})
    end
    if festivalFinds >= X.FestivalGoal then
        ForestWorld.festival()
        notice("SEED FESTIVAL! THE WHOLE ISLAND FOUND ENOUGH SEEDS!", Color3.fromRGB(255, 230, 134))
        remote:FireAllClients({type = "soundCue", cue = "Festival"})
        for participating in pairs(festivalPlayers) do
            if profiles[participating] then addCoins(participating, X.FestivalRewardCoins) end
        end
        festivalFinds = 0
        table.clear(festivalPlayers)
    end
    sendGarden(player)
    sendState()
end

ForestWorld.build(workspace:WaitForChild("MonsterIsland"), gatherSeed)
ForestWorld.weather(currentWeather)

local function changeWeather()
    local nextId = X.WeatherOrder[rng:NextInteger(1, #X.WeatherOrder)]
    if nextId == currentWeather then
        nextId = X.WeatherOrder[(table.find(X.WeatherOrder, nextId) % #X.WeatherOrder) + 1]
    end
    currentWeather = nextId
    weatherEndsAt = os.time() + 100
    local weather = X.Weather[currentWeather]
    ForestWorld.weather(currentWeather)
    local affected = 0
    for player, profile in pairs(profiles) do
        local changed = Garden.weather(profile.garden, currentWeather, function()
            return rng:NextNumber()
        end)
        if changed > 0 then
            affected += changed
            if profile.loaded then profile.dirty = true end
            profile.revision += 1
            World.updateGarden(player.UserId, profile.garden, GardenConfig)
        end
        sendGarden(player)
    end
    noise = math.min(Config.NOISE_MAX, noise + weather.noise)
    notice(weather.icon .. " " .. weather.name .. "! " .. affected .. " growing plants affected!", weather.color)
    remote:FireAllClients({type = "soundCue", cue = if currentWeather == "GiggleStorm" then "SillyStorm" else "WeatherChime"})
    sendState()
end

remote.OnServerEvent:Connect(function(player: Player, command: any, arg: any)
    local profile = profiles[player]
    if shuttingDown or not profile or typeof(command) ~= "string" then return end
    if command == "Feed" then
        feed(player, arg)
    elseif command == "StartPetting" then
        startPetting(player)
    elseif command == "StopPetting" then
        stopPetting(player, profile)
    elseif command == "PettingPulse" then
        keepPetting(player)
    elseif command == "ToggleCarry" then
        toggleCarry(player)
    elseif command == "PetInteract" then
        interactWithPet(player, arg)
    elseif command == "GardenFeed" then
        if typeof(arg) ~= "string" then return end
        local recipe = RecipeCatalog.Recipes[arg]
        if recipe and recipe.type == "feed" then
            feed(player, recipe.baseFood, arg)
        end
    elseif command == "GardenMerchantBuy" or command == "GardenBuySeed" or command == "GardenPlant" or command == "GardenHarvest"
       or command == "GardenFertilize" or command == "GardenCraft" or command == "GardenExperiment"
       or command == "GardenAssist" then
        gardenAction(player, command, arg)
    elseif command == "GardenLure" then
        useLure(player, arg)
    elseif command == "GardenVisit" then
        if phase == "AWAKE" then
            remote:FireClient(player, {type = "notice", text = "No teleporting away from Giggles! SURVIVE!", color = Color3.fromRGB(255, 178, 135)})
            return
        end
        if os.clock() - profile.lastGardenVisit < 2 then return end
        profile.lastGardenVisit = os.clock()
        local spot = World.gardenSpawn(player.UserId)
        local root = rootFor(player)
        if spot and root then
            root.CFrame = CFrame.new(spot)
            root.AssemblyLinearVelocity = Vector3.zero
        end
    elseif command == "BuyPet" or command == "EquipPet" then
        if os.clock() - profile.lastShopAction < 0.35 then return end
        profile.lastShopAction = os.clock()
        switchPet(player, arg, command == "BuyPet")
    elseif command == "TutorialDismiss" then
        if profile.tutorialSeen then return end
        profile.tutorialSeen = true
        if profile.loaded then
            profile.dirty = true
            profile.revision += 1
        end
        sendCollection(player)
    elseif command == "ClaimDaily" then
        if os.clock() - profile.lastDailyRequest < 1 then return end
        profile.lastDailyRequest = os.clock()
        if not profile.loaded then
            remote:FireClient(player, {type = "notice", text = "Daily reward unavailable: saving is offline.", color = Color3.fromRGB(255, 180, 153)})
            return
        end
        local ok, message = Progression.claimDaily(profile)
        if ok then
            addCoins(player, Config.DAILY_REWARD)
            sendCollection(player)
        end
        remote:FireClient(player, {type = "notice", text = message, color = if ok then Color3.fromRGB(154, 255, 207) else Color3.fromRGB(255, 216, 147)})
    elseif command == "Sync" then
        if os.clock() - profile.lastSync < 0.8 then return end
        profile.lastSync = os.clock()
        sendState(player)
        sendStats(player)
        sendCollection(player)
        sendGarden(player)
        careUpdate(player)
    end
end)

local function monsterAction()
    local choice = rng:NextInteger(1, 4)
    if choice == 1 then
        notice("GIGGLES STOMPS! JUMP AWAY!", Color3.fromRGB(255, 113, 146))
        local spot = Vector3.new(rng:NextNumber(-35, 35), 9, rng:NextNumber(-35, 35))
        World.wave(spot, 30, Color3.fromRGB(255, 116, 178))
        task.delay(0.8, function() monsterStrike(spot, 28, 55, true) end)
    elseif choice == 2 then
        notice("GIANT SNEEZE! HOLD ON!", Color3.fromRGB(136, 229, 255))
        World.wave(Vector3.new(0, 14, 0), 60, Color3.fromRGB(122, 213, 255))
        task.delay(0.9, function() monsterStrike(Vector3.new(0, 12, 0), 58, 55, false) end)
    elseif choice == 3 then
        notice("THE SKY IS RAINING JELLY!", Color3.fromRGB(255, 223, 114))
        for _ = 1, 3 do
            local spot = Vector3.new(rng:NextNumber(-70, 70), 11, rng:NextNumber(-70, 70))
            World.burst(spot, Color3.fromRGB(252, rng:NextInteger(130, 240), 192), 12, 12)
            World.wave(spot, 14, Color3.fromRGB(255, 214, 130))
            task.delay(0.7, function() monsterStrike(spot, 12, 24, false) end)
        end
    else
        notice("MONSTER FART TORNADO! RUN!", Color3.fromRGB(183, 244, 154))
        local spot = Vector3.new(rng:NextNumber(-40, 40), 12, rng:NextNumber(-40, 40))
        World.wave(spot, 38, Color3.fromRGB(175, 255, 152))
        task.delay(0.8, function() monsterStrike(spot, 38, 38, false) end)
    end
end

local function surpriseWeather()
    local choice = rng:NextInteger(1, 6)
    if choice == 4 or choice == 5 then remote:FireAllClients({type = "soundCue", cue = "RecordScratch"}) end
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
    for player, profile in pairs(profiles) do
        stopPetting(player, profile)
        -- Chase mode must not leave a mobile player holding an animal
        -- with no visible button to put it down.
        if profile.carrying then
            profile.carrying = false
            careUpdate(player)
        end
        profile.hearts = 3
        profile.knockedOut = false
        profile.lastHit = -100
        local p = profile.personalities[profile.petIndex]
        if p and profile.pet then
            profile.idleAction = Personality.idle(p, true)
            World.emotePet(profile.pet, Personality.mood(p, true), profile.idleAction)
        end
        sendStats(player)
    end
    World.setMonsterAwake(true)
    remote:FireAllClients({type = "soundCue", cue = "MonsterWake"})
    notice("OH NO!!! YOU WOKE GIGGLES! SURVIVE!", Color3.fromRGB(255, 113, 145))
    World.wave(Vector3.new(0, 11, 0), 90, Color3.fromRGB(255, 104, 156))
    RescueObjective.start(function(player: Player, justCompleted: boolean, reward: number)
        addCoins(player, reward)
        if justCompleted then
            notice("TEAM CHALLENGE COMPLETE! ALL LOST PETS ARE SAFE!", Color3.fromRGB(160, 255, 203))
            World.burst(Vector3.new(0, 52, 0), Color3.fromRGB(255, 232, 122), 30, 32)
        else
            remote:FireClient(player, {type = "questToast", text = "PET RESCUED! +" .. reward .. " COINS!"})
        end
        sendState()
    end, function(player: Player): boolean
        local profile = profiles[player]
        return phase == "AWAKE" and profile ~= nil and not profile.knockedOut
    end)
    notice("SAVE THE RUNAWAY PETS! Follow their HELP prompts!", Color3.fromRGB(255, 232, 151))
    sendState()
end

local function endWake()
    phase = "COOLDOWN"
    noise = 0
    secondsLeft = Config.COOLDOWN_SECONDS
    World.setMonsterAwake(false)
    remote:FireAllClients({type = "soundCue", cue = "Victory"})
    local teamCompleted = RescueObjective.completed()
    for _, player in ipairs(Players:GetPlayers()) do
        local profile = profiles[player]
        if profile then
            if rootFor(player) and not profile.knockedOut then
                local bonus = Progression.recordSurvival(profile)
                local rescueBonus = if teamCompleted and RescueObjective.participated(player) then RescueObjective.status().bonus else 0
                addCoins(player, Config.SURVIVAL_REWARD + bonus + rescueBonus)
                onceMetric(player, profile, "FirstBossSurvived")
                if rescueBonus > 0 then
                    remote:FireClient(player, {type = "questToast", text = "CO-OP HERO! +" .. rescueBonus .. " BONUS COINS!"})
                end
                if bonus > 0 then
                    task.delay(1.2, function()
                        if profiles[player] == profile then
                            remote:FireClient(player, {type = "questToast", text = "SURVIVAL QUEST COMPLETE! +" .. bonus .. " coins"})
                        end
                    end)
                end
            else
                addCoins(player, 8) -- consolation so new players can still progress
            end
            profile.hearts = 3
            profile.knockedOut = false
            sendStats(player)
            sendCollection(player)
        end
    end
    RescueObjective.finish()
    notice(if teamCompleted then "GIGGLES IS ASLEEP! HEROES SAVED THE PETS!" else "GIGGLES IS ASLEEP! NEXT TIME, RESCUE THE RUNAWAYS!", Color3.fromRGB(150, 255, 204))
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
            if phase == "AWAKE" and not profile.knockedOut then
                profile.knockedOut = true
                profile.hearts = 0
                sendStats(player)
                remote:FireClient(player, {type = "notice", text = "SPLASH! OUT FOR THIS ROUND!", color = Color3.fromRGB(152, 230, 255)})
            end
            root.CFrame = CFrame.new(0, 16, 85)
            root.AssemblyLinearVelocity = Vector3.zero
        end
        if root and pet and pet.Parent and pet.PrimaryPart then
            if profile.carrying then
                pet:PivotTo(pet:GetPivot():Lerp(World.carryPose(pet, root, t), 0.32))
                continue
            end
            local wobble = math.sin(t * 3 + player.UserId) * 0.65
            local side = root.CFrame.RightVector * 4.8
            local behind = -root.CFrame.LookVector * 3.5
            local personality = profile.personalities[profile.petIndex]
            local habit = profile.idleAction
            if personality and habit == "Hides" then
                side *= 0.45
                behind *= 1.8
            elseif habit == "Cuddles" then
                side *= 0.5
                behind *= 0.55
            end
            local bob = if habit == "Jumps" then math.abs(math.sin(t * 7)) * 2.2 elseif habit == "Naps" then wobble * 0.15 else wobble
            local target = root.Position + side + behind + Vector3.new(0, 3.2 + bob, 0)
            if (pet.PrimaryPart.Position - target).Magnitude > 60 then
                pet:PivotTo(CFrame.new(target))
            else
                local facing = CFrame.lookAt(target, root.Position + Vector3.new(0, 2, 0))
                if profile.effect == "Spin" and profile.effectUntil > t then
                    facing *= CFrame.Angles(0, t * 11, 0)
                elseif personality and (habit == "Dances" or habit == "ChasesTail") and profile.effectUntil < t then
                    facing *= CFrame.Angles(0, math.sin(t * 4) * 0.65, 0)
                elseif profile.effect == "Bounce" and profile.effectUntil > t then
                    facing += Vector3.new(0, math.abs(math.sin(t * 9)) * 3, 0)
                end
                pet:PivotTo(pet:GetPivot():Lerp(facing, 0.15))
            end
            if profile.effectUntil <= t and profile.effect ~= "" then
                profile.effect = ""
                pet:ScaleTo(1)
                World.tintPet(pet, Config.Pets[profile.petIndex].color)
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(3)
        if os.time() >= weatherEndsAt then changeWeather() end
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

-- Garden incidents tie the peaceful farming loop to the main chaos meter.
-- Cosmetic-only plants: never delete a player's crops during a surprise event.
task.spawn(function()
    while true do
        task.wait(56)
        if phase ~= "SLEEP" then continue end
        local eligible = {}
        for player, profile in pairs(profiles) do
            if rootFor(player) then
                for _, plot in ipairs(profile.garden.plots) do
                    if plot and GardenConfig.Crops[plot.seed] then
                        table.insert(eligible, {player = player, profile = profile, plot = plot})
                        break
                    end
                end
            end
        end
        if #eligible == 0 then continue end
        local chosen = eligible[rng:NextInteger(1, #eligible)]
        local home = World.gardenSpawn(chosen.player.UserId)
        if not home then continue end
        local id = rng:NextInteger(1, 5)
        local emotion = chosen.profile.personalities[chosen.profile.petIndex]
        local name = GardenConfig.Crops[chosen.plot.seed].name
        local announcement
        local incidentNoise
        if id == 1 then
            announcement, incidentNoise = name .. " started SINGING OPERA! Cover your ears!", 9
        elseif id == 2 then
            announcement, incidentNoise = chosen.player.DisplayName .. "'s veggies did a DANCE BATTLE!", 7
        elseif id == 3 then
            announcement, incidentNoise = "A GIANT CARROT JUST SNEEZED IN THE GARDEN!", 11
        elseif id == 4 then
            announcement, incidentNoise = "A watermelon yelled MEOW! Even the cats look confused!", 8
        else
            announcement, incidentNoise = "THE SUNFLOWERS ARE GOSSIPING ABOUT GIGGLES!", 6
        end
        if emotion and emotion.temperament == "Mischievous" then incidentNoise += 3 end
        notice("🌿 " .. announcement, Color3.fromRGB(229, 218, 141))
        World.burst(home + Vector3.new(0, 2, 0), GardenConfig.Crops[chosen.plot.seed].color, 22, 14)
        World.wave(home, 14, Color3.fromRGB(255, 215, 157))
        noise = math.min(Config.NOISE_MAX, noise + incidentNoise)
        remote:FireAllClients({type = "soundCue", cue = if id == 1 or id == 4 then "SillyStorm" else "Boing"})
        sendState()
    end
end)

task.spawn(function()
    while true do
        task.wait(8)
        for player, profile in pairs(profiles) do
            World.updateGarden(player.UserId, profile.garden, GardenConfig)
            sendGarden(player)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(Affection.TickSeconds)
        for player, profile in pairs(profiles) do
            if not profile.petting then continue end
            local t = os.clock()
            local root = rootFor(player)
            local character = player.Character
            local hum = if character then character:FindFirstChildOfClass("Humanoid") else nil
            local pet = profile.pet
            local session = profile.pettingSession
            if not root or not hum or hum.Health <= 0 or not pet or not pet.PrimaryPart
                or not session or phase ~= "SLEEP"
                or t - profile.lastCarePulse > Affection.KeepaliveSeconds
                or (root.Position - pet.PrimaryPart.Position).Magnitude > Affection.PetDistance then
                stopPetting(player, profile)
                continue
            end
            local personality = profile.personalities[profile.petIndex]
            if not personality then stopPetting(player, profile) continue end
            local oldBond = Personality.bondStage(personality)
            local outcome = Affection.step(personality, session, Affection.TickSeconds, rng:NextNumber())
            noise = math.min(Config.NOISE_MAX, noise + outcome.noise)
            profile.purr = outcome.purr
            if profile.loaded then profile.dirty = true end
            profile.revision += 1
            World.setPurr(pet, outcome.purr, Config.PurrSoundId)
            local stage = math.floor(outcome.purr * 5 + 0.01)
            if stage ~= profile.purrStage then
                profile.purrStage = stage
                if session.cat and stage >= 1 then
                    World.emotePet(pet, "Happy", "PURR " .. string.rep("♥", stage))
                    if stage >= 3 then
                        World.burst(pet.PrimaryPart.Position, Color3.fromRGB(255, 200, 223), 6, 7)
                    end
                else
                    World.emotePet(pet, Personality.mood(personality), "Pet me")
                end
            end
            if outcome.event == "Purring" then
                notice(player.DisplayName .. "'s kitty started PURRING... shhh!", Color3.fromRGB(255, 191, 219))
            elseif outcome.event == "Purrquake" then
                notice("PURR-QUAKE! That cat is LOUD!", Color3.fromRGB(255, 143, 187))
                remote:FireAllClients({type = "soundCue", cue = "Boing"})
                World.wave(pet.PrimaryPart.Position, 9, Color3.fromRGB(255, 177, 210))
            elseif outcome.event == "Swat" or outcome.event == "Hiss" or outcome.event == "Zoomies" or outcome.event == "Hides" then
                notice(Config.Pets[profile.petIndex].name .. " says NO MORE PETTING! " .. string.upper(outcome.event) .. "!", Color3.fromRGB(255, 180, 122))
                remote:FireAllClients({type = "soundCue", cue = "SuspiciousMeow"})
                World.burst(pet.PrimaryPart.Position, Color3.fromRGB(251, 171, 142), 12, 9)
                profile.carrying = false
                profile.idleAction = if outcome.event == "Zoomies" then "Jumps" elseif outcome.event == "Hides" then "Hides" else "MakesFaces"
            elseif outcome.event == "NeedsRest" then
                remote:FireClient(player, {type = "petFeeling", text = "Your pet needs a little break from cuddles."})
            end
            notifyBondMilestone(player, profile, oldBond)
            if outcome.done then
                stopPetting(player, profile)
            else
                careUpdate(player)
            end
            if outcome.noise > 0 then sendState() end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(25)
        for player, profile in pairs(profiles) do
            local p = profile.personalities[profile.petIndex]
            if p then
                profile.idleAction = Personality.tick(p, phase == "AWAKE")
                if profile.loaded then profile.dirty = true end
                profile.revision += 1
                if profile.pet and profile.pet.Parent then
                    World.emotePet(profile.pet, Personality.mood(p, phase == "AWAKE"), profile.idleAction)
                end
                sendStats(player)
                sendCollection(player)
            end
        end
        if phase == "SLEEP" then
            -- At most one social incident every 25 seconds, no reward farming.
            local active = Players:GetPlayers()
            local socialDone = false
            for first = 1, #active do
                if socialDone then break end
                local pa = active[first]
                local a = profiles[pa]
                local ra = rootFor(pa)
                if not a or not ra or not a.pet or not a.pet.PrimaryPart then continue end
                for second = first + 1, #active do
                    local pb = active[second]
                    local b = profiles[pb]
                    local rb = rootFor(pb)
                    if not b or not rb or not b.pet or not b.pet.PrimaryPart then continue end
                    if (ra.Position - rb.Position).Magnitude > 28 then continue end
                    local petA = a.personalities[a.petIndex]
                    local petB = b.personalities[b.petIndex]
                    if not petA or not petB then continue end
                    local encounter = Personality.meet(petA, petB)
                    a.revision += 1
                    b.revision += 1
                    if a.loaded then a.dirty = true end
                    if b.loaded then b.dirty = true end
                    World.emotePet(a.pet, Personality.mood(petA), encounter.kind)
                    World.emotePet(b.pet, Personality.mood(petB), encounter.kind)
                    local middle = (ra.Position + rb.Position) / 2 + Vector3.new(0, 3, 0)
                    World.burst(middle, Config.Pets[a.petIndex].color, 12, 12)
                    noise = math.min(Config.NOISE_MAX, noise + encounter.noise)
                    notice(Config.Pets[a.petIndex].name .. " & " .. Config.Pets[b.petIndex].name .. " " .. encounter.title, Color3.fromRGB(255, 210, 145))
                    if encounter.kind == "Prank" or encounter.kind == "DramaDuel" then
                        remote:FireAllClients({type = "soundCue", cue = "RecordScratch"})
                    elseif encounter.kind == "Singing" or encounter.kind == "DanceOff" then
                        remote:FireAllClients({type = "soundCue", cue = "ComedySting"})
                    elseif encounter.kind == "NapTogether" then
                        remote:FireAllClients({type = "soundCue", cue = "TinyViolin"})
                    end
                    sendStats(pa)
                    sendStats(pb)
                    sendCollection(pa)
                    sendCollection(pb)
                    sendState()
                    socialDone = true
                    break
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(90)
        for player in pairs(profiles) do save(player) end
    end
end)

game:BindToClose(function()
    shuttingDown = true
    for player in pairs(profiles) do
        task.spawn(onPlayerRemoving, player)
    end
    -- Save different players concurrently within Roblox's shutdown window.
    local deadline = os.clock() + 25
    while (next(profiles) or next(closingProfiles)) and os.clock() < deadline do
        task.wait(0.05)
    end
end)
