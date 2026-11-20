--!strict
-- Native crop breeze, cosmetic only. Moves a bounded subset of real Roblox
-- foliage in the playable .rbxlx when creator-owned GLBs are not installed.
-- Zero impact on growth timers, harvest prompts, collision or save data.
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

type WindLeaf = {
    source: BasePart,
    base: CFrame,
    seed: number,
    weight: number,
    group: string,
}

local leaves: {[BasePart]: WindLeaf} = {}
local MAX_GARDEN = 88
local MAX_SCENERY = 38
local gardenCount = 0
local sceneryCount = 0
local elapsed = 0

local function category(part: BasePart): string?
    local name = part.Name
    if name == "PaintedLeaf" then return "garden" end
    if name == "PaintedTaperedLeaf" or name == "PaintedAngularLeaf" or
        name == "CanopyJaggedLeaf" then
        return "scenery"
    end
    return nil
end

local function seedFor(part: BasePart): number
    local path = part:GetFullName()
    local seed = 91
    for i = 1, #path do
        seed = (seed * 31 + string.byte(path, i)) % 65521
    end
    return seed
end

local function track(instance: Instance)
    if not instance:IsA("BasePart") then return end
    if leaves[instance] then return end
    local group = category(instance)
    if not group then return end
    local seed = seedFor(instance)
    if seed % 4 == 0 then return end -- no need to animate every single leaf
    if group == "garden" then
        if gardenCount >= MAX_GARDEN then return end
        gardenCount += 1
    else
        if sceneryCount >= MAX_SCENERY then return end
        sceneryCount += 1
    end
    leaves[instance] = {
        source = instance,
        base = instance.CFrame,
        seed = seed,
        weight = if group == "garden" then 0.045 else 0.028,
        group = group,
    }
end

local function untrack(instance: Instance)
    if not instance:IsA("BasePart") then return end
    local info = leaves[instance]
    if not info then return end
    if info.group == "garden" then gardenCount -= 1
    else sceneryCount -= 1 end
    leaves[instance] = nil
end

local island = Workspace:WaitForChild("MonsterIsland", 30)
if island then
    for _, part in ipairs(island:GetDescendants()) do track(part) end
    island.DescendantAdded:Connect(track)
    island.DescendantRemoving:Connect(untrack)
end

RunService.RenderStepped:Connect(function(dt: number)
    elapsed += dt
    if elapsed < 1 / 15 then return end
    elapsed = 0
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local at = camera.CFrame.Position
    local now = Workspace.DistributedGameTime
    for part, leaf in pairs(leaves) do
        if not part.Parent then
            untrack(part)
            continue
        end
        local distance = (part.Position - at).Magnitude
        if distance > 80 then continue end
        local wave = math.sin(now * 1.28 + leaf.seed * 0.04)
        local micro = math.sin(now * 2.21 + leaf.seed * 0.12) * .18
        local tilt = (wave+micro) * leaf.weight
        part.CFrame = leaf.base * CFrame.Angles(tilt, tilt*.26, tilt*.7)
    end
end)
