--!strict
-- Client-only expressive idle animation for original native Roblox pets.
-- Works in the .rbxlx even if the owner has NOT imported GLB meshes.
-- Does not move the server-owned primary part or affect game mechanics.
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

type Piece = {
    part: BasePart,
    offset: CFrame,
    side: number,
    rate: number,
    degree: number,
}
type Pet = {
    model: Model,
    root: BasePart,
    parts: {Piece},
    seed: number,
}

local pets: {[Model]: Pet} = {}
local tracked: {[Model]: boolean} = {}
local lastFrame = 0
local MAX_DISTANCE = 100
local MAX_PARTS_PER_PET = 7

-- Every species has movement different from its neighbors. The animation is
-- deliberately gentle and smooth, matching a slow, pastoral gardening game.
local motions: {[string]: {number}} = {
    FluffyRisingTail = {2.1, 12},
    LongCurvedTail = {2.5, 9},
    DinosaurThickTail = {1.7, 6},
    CottonTail = {1.9, 5},
    BunnyEarLining = {2.1, 8},
    FloppyMoonEar = {2.0, 10},
    SoftSpanielEar = {1.8, 8},
    CurvedWhisker = {2.4, 4},
    FeatheredWing = {3.3, 12},
    Wing = {3.8, 14},
    WaterGills = {2.6, 8},
    GillsFrill = {2.4, 7},
    CurvingOctopusArm = {1.8, 11},
    CrabPinkClaw = {2.1, 6},
    TurtleShell = {0.8, 2},
    RoundedEar = {1.7, 4},
    LittleAntler = {0.8, 2},
    SpriteFloatingFlare = {2.9, 9},
}

local function stableSeed(name: string): number
    local value = 0
    for i = 1, #name do
        value = (value * 17 + string.byte(name, i)) % 997
    end
    return value
end

local function build(model: Model)
    local root = model.PrimaryPart
    if not root or not root:IsA("BasePart") or
        model:GetAttribute("NativeSpeciesStyled") ~= true then
        return
    end
    local seed = stableSeed(model.Name)
    local pieces: {Piece} = {}
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("BasePart") and child ~= root then
            local motion = motions[child.Name]
            if motion then
                table.insert(pieces, {
                    part = child,
                    offset = root.CFrame:ToObjectSpace(child.CFrame),
                    side = if child.Position.X < root.Position.X then -1 else 1,
                    rate = motion[1],
                    degree = motion[2],
                })
                if #pieces >= MAX_PARTS_PER_PET then break end
            end
        end
    end
    if #pieces > 0 then
        pets[model] = {model = model, root = root, parts = pieces, seed = seed}
    end
end

local function watch(instance: Instance)
    if not instance:IsA("Model") then return end
    if tracked[instance] then return end
    -- Only actual owned pet models acquire this attribute. Farm Models,
    -- boss and player rigs will never be animated by this cosmetic pass.
    if instance:GetAttribute("NativeSpeciesStyled") == true then
        tracked[instance] = true
        build(instance)
    else
        instance:GetAttributeChangedSignal("NativeSpeciesStyled"):Connect(function()
            if instance:GetAttribute("NativeSpeciesStyled") == true then
                tracked[instance] = true
                build(instance)
            end
        end)
    end
end

local island = Workspace:WaitForChild("MonsterIsland", 30)
if island then
    for _, instance in ipairs(island:GetChildren()) do watch(instance) end
    island.ChildAdded:Connect(watch)
    island.ChildRemoved:Connect(function(instance)
        if instance:IsA("Model") then
            pets[instance] = nil
            tracked[instance] = nil
        end
    end)
end

RunService.RenderStepped:Connect(function(dt: number)
    lastFrame += dt
    if lastFrame < 1 / 20 then return end
    lastFrame = 0
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local time = Workspace.DistributedGameTime
    for model, entry in pairs(pets) do
        if not model.Parent or not entry.root.Parent then
            pets[model] = nil
            tracked[model] = nil
            continue
        end
        if (entry.root.Position - camera.CFrame.Position).Magnitude > MAX_DISTANCE then
            continue
        end
        local rootCF = entry.root.CFrame
        for index, piece in ipairs(entry.parts) do
            if not piece.part.Parent then continue end
            local wave = math.sin(time * piece.rate + entry.seed * .19 + index * .73)
            local swing = math.rad(piece.degree) * wave
            local sway = CFrame.Angles(swing * .18,
                swing * .36 * piece.side,
                swing * piece.side)
            piece.part.CFrame = rootCF * piece.offset * sway
        end
    end
end)
