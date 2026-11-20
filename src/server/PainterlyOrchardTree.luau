--!strict
-- Real Roblox geometry for the original orange orchard in the reference
-- color language. The mesh pack, if installed in Studio, still takes priority.
-- This replaces the four enormous "lollipop" spheres in the fallback scene.
-- One shared asset-free canopy per tree, bounded to <= 54 pieces.
local Orchard = {}

local BARK = Color3.fromRGB(148, 103, 76)
local BARK_LIT = Color3.fromRGB(190, 142, 103)
local DARK = Color3.fromRGB(83, 134, 76)
local MID = Color3.fromRGB(125, 176, 93)
local LIGHT = Color3.fromRGB(186, 209, 112)
local SUNLIGHT = Color3.fromRGB(215, 223, 136)
local ORANGE = Color3.fromRGB(250, 161, 66)
local ORANGE_LIT = Color3.fromRGB(255, 190, 86)

local function piece(parent: Instance, name: string, pos: Vector3,
    size: Vector3, color: Color3, shape: Enum.PartType?): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Position = pos
    p.Color = color
    p.Shape = shape or Enum.PartType.Ball
    p.Material = Enum.Material.SmoothPlastic
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function branch(parent: Instance, from: Vector3, to: Vector3,
    width: number, color: Color3)
    local p = piece(parent, "OrchardBranch",
        (from + to) / 2, Vector3.new(width, width, (to - from).Magnitude),
        color, Enum.PartType.Block)
    p.Material = Enum.Material.Wood
    p.CFrame = CFrame.lookAt((from + to) / 2, to)
    return p
end

function Orchard.build(parent: Instance, index: number, ground: Vector3): Model
    local rng = Random.new(91735 + index * 331)
    local tree = Instance.new("Model")
    tree.Name = "PaintedOrangeTree_" .. index
    tree.Parent = parent
    local tall = rng:NextNumber(12.2, 16.2)
    local crown = ground + Vector3.new(0, tall + 2.5, 0)
    local trunk = piece(tree, "BarkTrunk", ground + Vector3.new(0, tall * .51, 0),
        Vector3.new(1.65, tall, 1.65), BARK)
    trunk.Material = Enum.Material.Wood
    trunk.CastShadow = true

    local colors = {DARK, MID, LIGHT, SUNLIGHT}
    -- Multiple overlapping irregular leaf masses rather than a smooth sphere.
    for i = 1, 12 do
        local a = i * 2.39996 + index * .17
        local distance = (i % 5) * .69 + 2.3
        local p = crown + Vector3.new(math.cos(a) * distance,
            rng:NextNumber(-2.45, 2.45), math.sin(a) * distance)
        local cluster = piece(tree, "PaintedCanopyMass", p,
            Vector3.new(rng:NextNumber(5.0, 7.6),
                rng:NextNumber(4.5, 6.5), rng:NextNumber(5.3, 7.6)),
            colors[((i + index) % #colors) + 1])
        cluster.CastShadow = i % 3 == 0
        if i % 3 == 0 then
            branch(tree,
                ground + Vector3.new(0, tall * .76, 0),
                p - Vector3.new(0, 1.1, 0),
                rng:NextNumber(.53, .82), BARK_LIT)
        end
    end

    -- 16 angular leaves: irregular directional silhouette is more important
    -- in the three-quarter camera than dozens of tiny expensive leaves.
    for i = 1, 16 do
        local a = i * 2.39996 + index * .31
        local p = crown + Vector3.new(math.cos(a) * rng:NextNumber(3.3, 6.1),
            rng:NextNumber(-3.4, 4.3),
            math.sin(a) * rng:NextNumber(3.2, 6.2))
        local leaf = Instance.new("WedgePart")
        leaf.Name = "PaintedOrchardLeaf"
        leaf.Size = Vector3.new(rng:NextNumber(1.5, 2.5), .18,
            rng:NextNumber(2.6, 4.2))
        leaf.CFrame = CFrame.new(p) * CFrame.Angles(
            math.rad(rng:NextNumber(-34, 34)), a,
            math.rad(rng:NextNumber(-24, 24)))
        leaf.Color = if i % 3 == 0 then SUNLIGHT elseif i % 2 == 0 then LIGHT else MID
        leaf.Material = Enum.Material.SmoothPlastic
        leaf.Anchored = true
        leaf.CanCollide = false
        leaf.CanTouch = false
        leaf.CanQuery = false
        leaf.CastShadow = false
        leaf.Parent = tree
    end

    -- Citrus hangs from the outer canopy instead of floating outside it.
    for i = 1, 9 do
        local a = i * 2.39996 + index * .24
        local radius = rng:NextNumber(3.2, 5.9)
        local fruitPos = crown + Vector3.new(
            math.cos(a) * radius, rng:NextNumber(-3.4, 0.6),
            math.sin(a) * radius)
        local fruit = piece(tree, "RipeOrange", fruitPos,
            Vector3.new(1.55, 1.66, 1.53),
            if i % 3 == 0 then ORANGE_LIT else ORANGE)
        fruit.CastShadow = true
        -- Small paired dark/light sepals keep orange fruits visibly attached.
        for j = 1, 2 do
            local leaf = piece(tree, "OrangeSePal",
                fruitPos + Vector3.new(if j == 1 then -.23 else .25,
                    .78, 0), Vector3.new(.49, .10, .27),
                if j == 1 then DARK else MID)
            leaf.CFrame *= CFrame.Angles(0,
                math.rad(if j == 1 then -28 else 31), math.rad(12))
        end
    end

    tree:SetAttribute("NativeOrchardTree", true)
    tree:SetAttribute("DetailCountCap", 54)
    return tree
end

return Orchard
