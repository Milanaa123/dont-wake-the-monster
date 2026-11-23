--!strict
-- Shared, server-owned co-op objective during the monster's awake phase.
-- Rescue the runaway creatures while dodging the boss for an extra reward.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local World = require(script.Parent:WaitForChild("World"))

local Rescue = {}
local random = Random.new()
local models: {Model} = {}
local active = false
local goal = 0
local rescued = 0
local completed = false
local participants: {[Player]: number} = {}

local RESCUE_COINS = 8
local TEAM_BONUS = 30
local generation = 0
local targets: {[number]: {name: string, position: Vector3, helper: number, expires: number}} = {}
local SIGNAL_SECONDS = 8

function Rescue.release(player: Player)
    for _, target in pairs(targets) do
        if target.helper == player.UserId then
            target.helper = 0
            target.expires = 0
        end
    end
end

function Rescue.signal(player: Player, round: any, id: any): boolean
    if not active or completed or round ~= generation or typeof(id) ~= "number"
        or not (id >= 1 and id <= goal and id % 1 == 0) then return false end
    local target = targets[id]
    local now = os.clock()
    if not target or target.expires > now then return false end
    local character = player.Character
    local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
    if not humanoid or humanoid.Health <= 0 then return false end
    for _, other in pairs(targets) do
        if other.helper == player.UserId and other.expires > now then return false end
    end
    target.helper = player.UserId
    target.expires = now + SIGNAL_SECONDS
    return true
end

function Rescue.status()
    local remaining = {}
    local now = os.clock()
    for id = 1, goal do
        local target = targets[id]
        if target then
            table.insert(remaining, {id = id, name = target.name, position = target.position,
                helper = if target.expires > now then target.helper else 0})
        end
    end
    return {
        round = generation,
        targets = remaining,
        active = active,
        rescued = rescued,
        goal = goal,
        completed = completed,
        bonus = TEAM_BONUS,
    }
end

function Rescue.participated(player: Player): boolean
    return (participants[player] or 0) > 0
end

function Rescue.completed(): boolean
    return completed
end

function Rescue.start(onRescue: (Player, boolean, number) -> (), allowed: (Player) -> boolean)
    for _, model in ipairs(models) do
        if model.Parent then model:Destroy() end
    end
    table.clear(models)
    table.clear(targets)
    table.clear(participants)
    generation += 1
    local round = generation
    rescued = 0
    active = true
    completed = false

    local currentPlayers = #Players:GetPlayers()
    goal = math.clamp(2 + math.floor(currentPlayers / 3), 2, 5)
    local phaseOffset = random:NextNumber(0, math.pi * 2)

    for i = 1, goal do
        local variant = Config.Pets[random:NextInteger(1, #Config.Pets)]
        local angle = phaseOffset + (i - 1) * math.pi * 2 / goal
        local radius = random:NextNumber(31, 62)
        -- Top of main island is approximately 7 studs; keep prompts reachable.
        local position = Vector3.new(math.cos(angle) * radius, 12.5, math.sin(angle) * radius)
        local pet = World.makePet(variant.name .. "_runaway_" .. i, variant.color, variant.ear == "pointy")
        pet.Name = "RescueRunaway_" .. i
        pet:PivotTo(CFrame.new(position) * CFrame.Angles(0, angle, 0))
        table.insert(models, pet)

        local primary = pet.PrimaryPart
        if primary then
            targets[i] = {name = variant.name, position = primary.Position, helper = 0, expires = 0}
            local prompt = Instance.new("ProximityPrompt")
            prompt.Name = "Rescue"
            prompt.ActionText = "SAVE ME!"
            prompt.ObjectText = "Lost " .. variant.name
            prompt.KeyboardKeyCode = Enum.KeyCode.E
            prompt.HoldDuration = 0.15
            prompt.MaxActivationDistance = 13
            prompt.RequiresLineOfSight = false
            prompt.Parent = primary

            local used = false
            prompt.Triggered:Connect(function(player: Player)
                if not active or round ~= generation or completed or used or not allowed(player) then return end
                local character = player.Character
                local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
                if not root or not root:IsA("BasePart") then return end
                if (root.Position - primary.Position).Magnitude > 16 then return end
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if not humanoid or humanoid.Health <= 0 then return end

                used = true
                targets[i] = nil
                prompt.Enabled = false
                participants[player] = (participants[player] or 0) + 1
                rescued += 1
                local justCompleted = rescued >= goal and not completed
                if justCompleted then completed = true end
                World.burst(primary.Position, variant.color, 14, 11)
                if pet.Parent then pet:Destroy() end
                onRescue(player, justCompleted, RESCUE_COINS)
            end)
        end
    end
end

function Rescue.finish()
    active = false
    for _, model in ipairs(models) do
        if model.Parent then model:Destroy() end
    end
    table.clear(models)
    table.clear(targets)
    -- Keep participants until the next Rescue.start so reward resolution can run first.
end

return Rescue
