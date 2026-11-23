--!strict
-- Original, asset-free cottage-garden environment inspired by the player's mood reference.
-- No image assets, external meshes, or copied game/world materials are used.
-- Detail pieces are anchored, non-collidable, and created once by the server.
local Lighting = game:GetService("Lighting")

local Art=require(script.Parent.ReferenceMeshLibrary)
local Cottage = {}
local LEAF_DARK = Color3.fromRGB(83, 145, 86)
local LEAF = Color3.fromRGB(127, 183, 94)
local LEAF_LIGHT = Color3.fromRGB(185, 213, 109)
local CREAM = Color3.fromRGB(246, 221, 167)
local WOOD = Color3.fromRGB(192, 141, 104)
local PATH = Color3.fromRGB(207, 169, 122)
local SOIL = Color3.fromRGB(136, 93, 74)
local WHITE = Color3.fromRGB(255, 248, 212)
local ORANGE = Color3.fromRGB(255, 167, 70)
local RED = Color3.fromRGB(236, 85, 87)

local function part(parent: Instance, name: string, position: Vector3, size: Vector3,
    color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Position = position
    p.Size = size
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.Material = material or Enum.Material.SmoothPlastic
    p.Color = color
    p.Shape = shape or Enum.PartType.Block
    p.CastShadow = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function ball(parent: Instance, name: string, position: Vector3, size: Vector3, color: Color3): Part
    return part(parent, name, position, size, color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
end

local function beam(parent: Instance, name: string, a: Vector3, b: Vector3, thickness: number, color: Color3)
    local midpoint = (a + b) * 0.5
    local bar = part(parent, name, midpoint, Vector3.new(thickness, thickness, (b - a).Magnitude), color, Enum.Material.Wood)
    bar.CFrame = CFrame.lookAt(midpoint, b)
    return bar
end

local function pebble(parent: Instance, pos: Vector3, size: number)
    local p = ball(parent, "WarmPebble", pos, Vector3.new(size, size * 0.21, size * 0.8), CREAM)
    p.Material = Enum.Material.Sand
end

local function flower(parent: Instance, pos: Vector3, tint: Color3, scale: number)
    local leaf = ball(parent, "FlowerLeaves", pos + Vector3.new(0, 0.25 * scale, 0),
        Vector3.new(1.4, 0.37, 1.1) * scale, LEAF_DARK)
    leaf.CastShadow = false
    local stalk = part(parent, "FlowerStem", pos + Vector3.new(0, 0.68 * scale, 0),
        Vector3.new(0.2, 1.1, 0.2) * scale, LEAF_DARK)
    stalk.CastShadow = false
    for i = 1, 5 do
        local angle = i * 2 * math.pi / 5
        ball(parent, "Petal", pos + Vector3.new(math.cos(angle) * 0.46, 1.35, math.sin(angle) * 0.46) * scale,
            Vector3.new(0.68, 0.27, 0.65) * scale, tint).CastShadow = false
    end
    ball(parent, "FlowerCenter", pos + Vector3.new(0, 1.35 * scale, 0),
        Vector3.new(0.65, 0.29, 0.65) * scale, ORANGE).CastShadow = false
end

local function lowPolyBush(parent: Instance, pos: Vector3, radius: number, rng: Random)
    local primary = ball(parent, "CottageBush", pos + Vector3.new(0, radius * 0.5, 0),
        Vector3.new(radius * 2, radius * 1.2, radius * 1.6), LEAF)
    primary.CFrame *= CFrame.Angles(0, rng:NextNumber(0, math.pi), 0)
    local p = ball(parent, "LeafHighlight", pos + Vector3.new(radius * 0.35, radius * 0.97, 0),
        Vector3.new(radius * 1.35, radius * 0.78, radius * 1.25), LEAF_LIGHT)
    p.CanTouch = false
end

local function fruitTree(parent: Instance, pos: Vector3, index: number, rng: Random)
    local tall = rng:NextNumber(13, 19)
    local trunk = part(parent, "OrchardTrunk", pos + Vector3.new(0, tall * 0.51, 0),
        Vector3.new(2.2, tall, 2.2), WOOD, Enum.Material.Wood)
    trunk.Shape = Enum.PartType.Cylinder
    trunk.CFrame *= CFrame.Angles(0, 0, math.rad(90))
    local colors = {LEAF, LEAF_DARK, LEAF_LIGHT}
    local canopy = pos + Vector3.new(0, tall + 2, 0)
    ball(parent, "OrchardCanopy", canopy, Vector3.new(16, 13, 15), colors[index % 3 + 1])
    for i = 1, 4 do
        local a = i * 1.5708 + index * 0.4
        local off = Vector3.new(math.cos(a) * 5.5, rng:NextNumber(-1.4, 2.3), math.sin(a) * 5.5)
        ball(parent, "FoliageCluster", canopy + off, Vector3.new(9.8, 9.4, 10.8), colors[(i + index) % 3 + 1])
    end
    for i = 1, 6 do
        local a = i * 2.399 + index
        local r = rng:NextNumber(3.2, 7)
        local fruit = ball(parent, "GoldenOrange", canopy + Vector3.new(math.cos(a) * r, rng:NextNumber(-5, 1), math.sin(a) * r),
            Vector3.new(2.1, 2.1, 2.1), ORANGE)
        fruit.CastShadow = false
        -- A leaf pair and a small sunlit stem read as real citrus from the camera.
        local tip = fruit.Position + Vector3.new(0, 1.14, 0)
        ball(parent, "OrangeLeaf", tip + Vector3.new(0.53, 0.11, 0),
            Vector3.new(1.19, 0.22, 0.51), LEAF_DARK).CastShadow = false
        ball(parent, "OrangeLeafHighlight", tip + Vector3.new(-0.38, 0.13, 0.04),
            Vector3.new(0.9, 0.19, 0.46), LEAF_LIGHT).CastShadow = false
    end
end

local function wildBerryBush(parent: Instance, pos: Vector3, rng: Random)
    lowPolyBush(parent, pos, rng:NextNumber(2.3, 3.5), rng)
    for i = 1, 5 do
        local a = i * 2.399
        local fruit = ball(parent, "WildStrawberry",
            pos + Vector3.new(math.cos(a) * 2, rng:NextNumber(0.8, 2.3), math.sin(a) * 1.6),
            Vector3.new(1.55, 1.6, 1.4), RED)
        fruit.CastShadow = false
        ball(parent, "StrawberryCalyx", fruit.Position + Vector3.new(0, 0.78, 0),
            Vector3.new(1.25, 0.19, 1.22), LEAF_DARK).CastShadow = false
        for seed = 1, 2 do
            ball(parent, "StrawberrySeed", fruit.Position + Vector3.new((seed - 1.5) * 0.64, -0.03, -0.69),
                Vector3.new(0.13, 0.19, 0.1), CREAM).CastShadow = false
        end
    end
end

local function wheatClump(parent: Instance, pos: Vector3, scale: number)
    for i = 1, 4 do
        local a = i * 2.4
        local x = math.cos(a) * 0.95
        local z = math.sin(a) * 0.95
        local tip = pos + Vector3.new(x, 5.2 * scale, z)
        beam(parent, "WheatStalk", pos + Vector3.new(x, 0, z), tip, 0.18 * scale, Color3.fromRGB(201, 182, 116))
        for k = 1, 3 do
            ball(parent, "GoldenWheat", tip + Vector3.new((k - 2) * 0.18, k * 0.47 * scale, 0),
                Vector3.new(0.75, 1.3, 0.65) * scale, CREAM).CastShadow = false
        end
    end
end

local function melonPatch(parent: Instance, pos: Vector3)
    local melon = ball(parent, "SunlitMelon", pos + Vector3.new(0, 1.2, 0),
        Vector3.new(5.3, 4.1, 5.0), Color3.fromRGB(177, 203, 83))
    melon.Material = Enum.Material.SmoothPlastic
    for i = 1, 3 do
        local a = i * 2.094
        local stripe = ball(parent, "MelonRind", pos + Vector3.new(math.cos(a) * 1.2, 2.35, math.sin(a) * 1.2),
            Vector3.new(2.6, 0.44, 1.3), LEAF_DARK)
        stripe.CFrame *= CFrame.Angles(0, a, math.rad(15))
    end
    for i = 1, 4 do
        local a = i * math.pi / 2
        local leaf = ball(parent, "MelonLeaf", pos + Vector3.new(math.cos(a) * 3.7, 0.26, math.sin(a) * 3.7),
            Vector3.new(3.6, 0.36, 2.1), LEAF)
        leaf.CFrame *= CFrame.Angles(0, a, 0)
    end
end

function Cottage.applyLighting()
    Lighting.ClockTime = 16.1
    Lighting.Brightness = 2.1
    Lighting.ExposureCompensation = -0.07
    Lighting.Ambient = Color3.fromRGB(126, 128, 117)
    Lighting.OutdoorAmbient = Color3.fromRGB(170, 177, 149)
    Lighting.EnvironmentDiffuseScale = 0.4
    Lighting.EnvironmentSpecularScale = 0.32
    Lighting.ShadowSoftness = 0.38
    Lighting.GlobalShadows = true

    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
    atmosphere.Name = "CottageAtmosphere"
    atmosphere.Color = Color3.fromRGB(251, 225, 176)
    atmosphere.Decay = Color3.fromRGB(187, 204, 165)
    atmosphere.Density = 0.17
    atmosphere.Haze = 0.95
    atmosphere.Glare = 0.22
    atmosphere.Offset = 0.05
    atmosphere.Parent = Lighting

    local function effect(class: string, name: string): Instance
        local existing = Lighting:FindFirstChild(name)
        if existing then return existing end
        local created = Instance.new(class)
        created.Name = name
        created.Parent = Lighting
        return created
    end

    local grade = effect("ColorCorrectionEffect", "CottageColorGrade") :: ColorCorrectionEffect
    grade.Brightness = 0.025
    grade.Contrast = 0.065
    grade.Saturation = -0.065
    grade.TintColor = Color3.fromRGB(255, 248, 224)

    local bloom = effect("BloomEffect", "CottageGentleBloom") :: BloomEffect
    bloom.Intensity = 0.14
    bloom.Size = 18
    bloom.Threshold = 1.8

    local rays = effect("SunRaysEffect", "CottageSunbeams") :: SunRaysEffect
    rays.Intensity = 0.035
    rays.Spread = 0.78
end

-- Small original stage set behind the spawn-side garden, designed to avoid
-- the central monster arena and the three seed-hunt biome centres.
local function storybookCottage(parent: Instance)
    local model = Instance.new("Model")
    model.Name = "CozyOrchardCottage"
    model.Parent = parent
    local x, y, z = 37, 7, 88
    local wall = part(model, "HoneyCottageWalls", Vector3.new(x, y + 4.4, z),
        Vector3.new(14.5, 9.0, 12.5), Color3.fromRGB(226, 185, 138), Enum.Material.WoodPlanks)
    wall.CanCollide = true
    local footing = part(model, "CottageStoneBase", Vector3.new(x, y + 0.2, z),
        Vector3.new(15.3, 0.6, 13.2), Color3.fromRGB(193, 173, 143), Enum.Material.Slate)
    footing.CanCollide = true
    for _, side in ipairs({-1, 1}) do
        local roof = part(model, "BlueSlateRoof", Vector3.new(x + side * 3.9, y + 10.1, z),
            Vector3.new(8.7, 0.82, 15.2), Color3.fromRGB(122, 136, 157), Enum.Material.Slate)
        roof.CFrame *= CFrame.Angles(0, 0, math.rad(side * 25))
        roof.CanCollide = true
        local eave = part(model, "CottageWhiteEave", Vector3.new(x + side * 6.9, y + 8.1, z),
            Vector3.new(1.0, 0.48, 15.7), CREAM, Enum.Material.Wood)
        eave.CanCollide = true
    end
    -- Exterior door is a decorative facade; it is not presented as interactive.
    local door = part(model, "WarmOakDoor", Vector3.new(x, y + 3.1, z - 6.39),
        Vector3.new(3.0, 6.1, 0.3), Color3.fromRGB(137, 97, 75), Enum.Material.WoodPlanks)
    door.CanCollide = true
    ball(model, "DoorKnob", Vector3.new(x + 1.05, y + 3.25, z - 6.64),
        Vector3.new(0.28, 0.28, 0.24), CREAM)
    for _, side in ipairs({-1, 1}) do
        local glass = part(model, "LanternWindow", Vector3.new(x + side * 4.2, y + 5.1, z - 6.39),
            Vector3.new(2.6, 2.8, 0.32), Color3.fromRGB(253, 220, 151), Enum.Material.Glass)
        glass.Transparency = 0.18
        for _, height in ipairs({3.55, 6.68}) do
            part(model, "WindowFrame", Vector3.new(x + side * 4.2, y + height, z - 6.59),
                Vector3.new(3.2, 0.34, 0.40), CREAM, Enum.Material.Wood)
        end
        part(model, "WindowCrossbar", Vector3.new(x + side * 4.2, y + 5.1, z - 6.64),
            Vector3.new(0.28, 3.1, 0.4), CREAM, Enum.Material.Wood)
        local potCenter = Vector3.new(x + side * 5.4, y + 0.7, z - 8)
        local pot = part(model, "CottageFlowerPot", potCenter,
            Vector3.new(1.45, 1.2, 1.4), Color3.fromRGB(183, 107, 83),
            Enum.Material.Brick, Enum.PartType.Cylinder)
        pot.CFrame *= CFrame.Angles(0, 0, math.rad(90))
        flower(model, potCenter + Vector3.new(0, 0.64, 0),
            if side == 1 then WHITE else Color3.fromRGB(248, 181, 197), 0.71)
    end
    part(model, "CottageChimney", Vector3.new(x + 4.5, y + 12, z + 2.6),
        Vector3.new(2.4, 5.4, 2.4), Color3.fromRGB(187, 137, 116), Enum.Material.Brick)
    for i = 1, 4 do
        local p = Vector3.new(x - 2.5 + i * 1.15, 7.26, z - 9.5 - i * 1.2)
        local steppingStone = ball(model, "CottageWalkway", p, Vector3.new(3.4, 0.16, 3.6), PATH)
        steppingStone.Material = Enum.Material.Sand
    end
end

local function orchardPond(parent: Instance)
    local model = Instance.new("Model")
    model.Name = "ShadedOrchardPond"
    model.Parent = parent
    local center = Vector3.new(54, 7.2, 91)
    local shore = ball(model, "PondSandyShore", center,
        Vector3.new(14.4, 0.21, 10.8), Color3.fromRGB(191, 184, 139))
    shore.Material = Enum.Material.Sand
    local water = ball(model, "PondSurface", center + Vector3.new(0, 0.18, 0),
        Vector3.new(11.9, 0.16, 8.3), Color3.fromRGB(131, 186, 185))
    water.Material = Enum.Material.Glass
    water.Transparency = 0.20
    water.CastShadow = false
    for i = 1, 9 do
        local a = i * 2 * math.pi / 9
        local pos = center + Vector3.new(math.cos(a) * 6.9, 0.12, math.sin(a) * 5.0)
        pebble(model, pos, 0.9)
        if i % 3 == 0 then
            flower(model, pos + Vector3.new(0.6, 0.02, 0), WHITE, 0.55)
        end
    end
    for i = 1, 3 do
        local a = i * 2.094
        local pad = ball(model, "WaterLilyPad",
            center + Vector3.new(math.cos(a) * 3, 0.31, math.sin(a) * 2.2),
            Vector3.new(1.9, 0.12, 1.7), LEAF_DARK)
        pad.CastShadow = false
    end
end

function Cottage.decorateWorld(world: Instance)
    local folder = Instance.new("Folder")
    folder.Name = "CottageGardenEnvironment"
    folder.Parent = world
    local rng = Random.new(45721)
    -- Ground level of the existing island = 7; no surprise colliders.
    for z = 34, 67, 6 do
        local stone = ball(folder, "WarmGardenPath", Vector3.new(rng:NextNumber(-0.35, 0.35), 7.15, z),
            Vector3.new(rng:NextNumber(10.5, 12), 0.24, rng:NextNumber(7.1, 8.2)), PATH)
        stone.Material = Enum.Material.Sand
        stone.CFrame *= CFrame.Angles(0, rng:NextNumber(-0.045, 0.045), 0)
    end
    -- Branches to personal gardens keep the center visually clear for the boss.
    for k = 1, 12 do
        local a = (k - 1) / 12 * math.pi * 2
        for radius = 34, 51, 8 do
            local pos = Vector3.new(math.cos(a) * radius, 7.14, math.sin(a) * radius)
            local p = ball(folder, "PathToGardens", pos, Vector3.new(7.5, 0.18, 8.7), Color3.fromRGB(220, 184, 138))
            p.Material = Enum.Material.Sand
            p.CFrame *= CFrame.Angles(0, -a, 0)
        end
    end
    local function patch(key: string, pos: Vector3, width: number): Folder
        local detail=Instance.new("Folder")
        detail.Name="FieldDetails"
        detail.Parent=folder
        Art.ground(folder,key,CFrame.new(pos)*CFrame.Angles(0,pos.X*.13,0),width,detail)
        return detail
    end
    -- Dense-looking but deliberately bounded original orchard.
    for i = 1, 11 do
        local a = (i / 11) * math.pi * 2 + 0.17
        local r = rng:NextNumber(91, 102)
        local treePos = Vector3.new(math.cos(a) * r, 7, math.sin(a) * r)
        if (treePos - Vector3.new(37, 7, 88)).Magnitude > 21
            and (treePos - Vector3.new(54, 7, 91)).Magnitude > 14 then
            fruitTree(patch("Environment_OrangeTree",treePos,13+i%3), treePos, i, rng)
        end
    end
    for i = 1, 21 do
        local a = rng:NextNumber(0, math.pi * 2)
        local r = rng:NextNumber(80, 104)
        local pos=Vector3.new(math.cos(a)*r,7,math.sin(a)*r)
        wildBerryBush(patch("Crop_Berry_S3",pos,4.8),pos,rng)
    end
    for i = 1, 12 do
        local a = (i / 12) * math.pi * 2
        local r = rng:NextNumber(84, 101)
        local pos=Vector3.new(math.cos(a)*r,7,math.sin(a)*r)
        wheatClump(patch("Crop_WhisperWheat_S3",pos,3.4),pos,rng:NextNumber(.8,1.2))
    end
    for _, p in ipairs({
        Vector3.new(-85, 7, 10), Vector3.new(91, 7, -2),
        Vector3.new(-48, 7, -73), Vector3.new(42, 7, 82),
    }) do
        melonPatch(patch("Crop_LavaMelon_S3",p,6.1),p)
    end
    for i = 1, 23 do
        local a = rng:NextNumber(0, math.pi * 2)
        local r = rng:NextNumber(85, 108)
        local pos = Vector3.new(math.cos(a) * r, 7, math.sin(a) * r)
        flower(folder, pos, if i % 3 == 0 then WHITE elseif i % 3 == 1 then
            Color3.fromRGB(251, 204, 202) else Color3.fromRGB(255, 235, 145), rng:NextNumber(0.7, 1.2))
    end
    -- Irregular overlapping shapes give the bare island ground small patches
    -- of painterly grass and clover without introducing textures or colliders.
    for i = 1, 52 do
        local a = rng:NextNumber(0, math.pi * 2)
        local r = if i % 2 == 0 then rng:NextNumber(36, 44) else rng:NextNumber(96, 106)
        local pos = Vector3.new(math.cos(a) * r, 7.2, math.sin(a) * r)
        local shade = if i % 3 == 0 then LEAF_LIGHT elseif i % 3 == 1 then LEAF else LEAF_DARK
        local patch = ball(folder, "MeadowGrassPatch", pos,
            Vector3.new(rng:NextNumber(2.2, 4.8), 0.15, rng:NextNumber(1.7, 3.5)), shade)
        patch.CastShadow = false
        if i % 3 ~= 0 then
            for leafIndex = 1, 3 do
                local theta = leafIndex * 2.094
                local leafCenter = pos + Vector3.new(math.cos(theta) * 0.42, 0.14, math.sin(theta) * 0.38)
                local clover = ball(folder, "CloverLeaf", leafCenter, Vector3.new(0.62, 0.12, 0.48), LEAF_LIGHT)
                clover.CastShadow = false
            end
        end
    end
    storybookCottage(folder)
    orchardPond(folder)
    for i = 1, 19 do
        local a = rng:NextNumber(0, math.pi * 2)
        local r = rng:NextNumber(78, 110)
        pebble(folder, Vector3.new(math.cos(a) * r, 7.14, math.sin(a) * r), rng:NextNumber(0.8, 1.8))
    end
end

function Cottage.styleEntrance(farm: Model, center: CFrame, style: string)
    if farm:GetAttribute("GardenStyle")==style then return end
    farm:SetAttribute("GardenStyle",style)
    local previous=farm:FindFirstChild("EntranceDecor")
    if previous then previous:Destroy() end
    local paint=if style=="Blossom" then Color3.fromRGB(181,138,158)
        elseif style=="Cottage" then Color3.fromRGB(136,157,132) else WOOD
    for _,piece in farm:GetChildren() do
        if piece:IsA("BasePart") and (piece.Name=="WarmWoodFence" or piece.Name=="BackFence" or piece.Name=="FencePost") then
            piece.Color=paint
        end
    end
    if style=="Meadow" then return end
    local decor=Instance.new("Folder")
    decor.Name="EntranceDecor"
    decor.Parent=farm
    if style=="Cottage" then
        Art.ground(decor,"Environment_GardenCottage",center*CFrame.new(-5,.72,13.8),4.0,nil)
        Art.ground(decor,"Environment_StonePath",center*CFrame.new(3.9,.73,13.8)*CFrame.Angles(0,math.pi/2,0),4.5,nil)
    else
        for _,side in {-1,1} do
            Art.ground(decor,"Environment_BloomingHedge",center*CFrame.new(side*5,.72,13.8),4.0,nil)
        end
    end
end

function Cottage.decorateFarm(parent: Instance, center: CFrame)
    -- Natural wood fence on sides/back, open entrance for easy traversal.
    for _, x in ipairs({-13.4, 13.4}) do
        for _, z in ipairs({-14, 0, 14}) do
            local pos = (center * CFrame.new(x, 2.0, z)).Position
            part(parent, "FencePost", pos, Vector3.new(0.85, 4.2, 0.85), WOOD, Enum.Material.Wood)
        end
        for _, height in ipairs({1.5, 2.8}) do
            beam(parent, "WarmWoodFence", (center * CFrame.new(x, height, -14)).Position,
                (center * CFrame.new(x, height, 14)).Position, 0.52, WOOD)
        end
    end
    for _, y in ipairs({1.5, 2.8}) do
        beam(parent, "BackFence", (center * CFrame.new(-13.4, y, -14)).Position,
            (center * CFrame.new(13.4, y, -14)).Position, 0.52, WOOD)
    end
    local rng = Random.new(7326)
    for i = 1, 4 do
        local x = if i % 2 == 0 then -12 else 12
        local z = -11 + i * 4
        local position = (center * CFrame.new(x, 0.75, z)).Position
        flower(parent, position, if i % 2 == 0 then WHITE else Color3.fromRGB(248, 176, 181), 0.62)
    end
    local p = (center * CFrame.new(-11.5, 0.6, 15)).Position
    lowPolyBush(parent, p, 1.6, rng)

    -- Harvest corner: warm wooden basket full of apples and strawberries.
    local basketCenter = (center * CFrame.new(10.1, 1.0, 13.0)).Position
    local basket = part(parent, "HarvestBasket", basketCenter, Vector3.new(3.4, 1.3, 2.6),
        Color3.fromRGB(176, 118, 81), Enum.Material.Wood, Enum.PartType.Cylinder)
    basket.CFrame *= CFrame.Angles(0, 0, math.rad(90))
    for i = 1, 5 do
        local angle = i * 2.399
        local fruitCenter = basketCenter + Vector3.new(math.cos(angle) * 1.06, 0.74, math.sin(angle) * 0.76)
        ball(parent, "PickedStrawberry", fruitCenter, Vector3.new(0.93, 0.98, 0.92),
            if i % 2 == 0 then Color3.fromRGB(248, 105, 108) else Color3.fromRGB(255, 178, 83))
        ball(parent, "FruitLeaf", fruitCenter + Vector3.new(0, 0.48, 0), Vector3.new(0.93, 0.2, 0.76), LEAF_DARK)
    end

    -- Toy-sized enamel watering can, a natural place to orient the player.
    local canFolder=Instance.new("Folder")
    canFolder.Name="WateringCanDetails"
    canFolder.Parent=parent
    local canCenter = (center * CFrame.new(-9.9, 1.35, 12.5)).Position
    ball(canFolder, "WateringCan", canCenter, Vector3.new(2.5, 1.9, 1.8), Color3.fromRGB(159, 198, 215))
    local spoutEnd = canCenter + (center.RightVector * -2.0) + Vector3.new(0, 0.55, 0)
    beam(canFolder, "WateringSpout", canCenter, spoutEnd, 0.38, Color3.fromRGB(121, 166, 196))
    ball(canFolder, "WateringRose", spoutEnd, Vector3.new(0.78, 0.27, 0.78), Color3.fromRGB(222, 230, 211))

    Art.ground(parent,"Environment_WateringCan",center*CFrame.new(-9.9,.73,12.5),2.9,canFolder)

    -- Low detail density: twelve tiny meadow daisies and pebbles around the beds.
    for i = 1, 12 do
        local angle = (i / 12) * 2 * math.pi
        local x = if i % 2 == 0 then rng:NextNumber(-11.6, 11.6) else (if i % 3 == 0 then -12.5 else 12.5)
        local z = if i % 2 == 0 then (if i % 4 == 0 then -13.9 else 14.6) else rng:NextNumber(-13, 13)
        local flowerCenter = (center * CFrame.new(x, 0.75, z)).Position
        if i % 4 == 0 then
            pebble(parent, flowerCenter, rng:NextNumber(0.6, 1.2))
        else
            flower(parent, flowerCenter,
                if i % 3 == 0 then WHITE elseif i % 3 == 1 then Color3.fromRGB(255, 215, 205)
                else Color3.fromRGB(245, 233, 156), 0.48)
        end
    end
end

-- Additional plant language, not separate crops or growth mechanics.
-- Called only when the existing World.updateGarden stage changes.
function Cottage.decorateCrop(parent: Instance, position: Vector3, seedType: string, stage: number)
    if stage < 2 then return end
    if seedType == "Berry" or seedType == "FrostBerry" then
        for i = 1, 4 do
            local a = i * 2.4
            local pos = position + Vector3.new(math.cos(a) * 1.7, 2.0 + stage * 0.7, math.sin(a) * 1.5)
            local berryColor = if seedType == "FrostBerry" then Color3.fromRGB(139, 205, 250) else RED
            ball(parent, "BerryRedCluster", pos, Vector3.new(1.0, 1.2, 1.0), berryColor)
            ball(parent, "LeafCap", pos + Vector3.new(0, 0.65, 0),
                Vector3.new(1.5, 0.25, 1.2), LEAF_DARK)
            for seed = 1, 2 do
                ball(parent, "BerrySeed", pos + Vector3.new((seed - 1.5) * 0.44, 0.03, -0.49),
                    Vector3.new(0.12, 0.16, 0.1), CREAM).CastShadow = false
            end
        end
    elseif seedType == "Tomato" or seedType == "Pepper" then
        for i = 1, 3 do
            local a = i * 2.094
            ball(parent, "RipeTomato", position + Vector3.new(math.cos(a) * 1.5, 2.3 + stage * 0.65, math.sin(a) * 1.5),
                Vector3.new(1.6, 1.6, 1.5), RED)
        end
    elseif seedType == "Carrot" then
        for i = 1, 3 do
            local a = i * 2.094
            local root = position + Vector3.new(math.cos(a) * 1.4, 1.0, math.sin(a) * 1.4)
            ball(parent, "CarrotRoot", root, Vector3.new(1.1, 1.9, 1.1), ORANGE)
            for leaf = 1, 2 do
                local tip = root + Vector3.new((leaf - 1.5) * 0.55, 1.23, 0)
                local greens = ball(parent, "CarrotFeather", tip, Vector3.new(0.42, 1.3, 0.7), LEAF_DARK)
                greens.CFrame *= CFrame.Angles(0, 0, math.rad((leaf - 1.5) * 37))
            end
        end
    elseif seedType == "Watermelon" or seedType == "HoneyMelon" then
        ball(parent, "StripedGardenMelon", position + Vector3.new(0.7, 1.05, 0),
            Vector3.new(3.2, 2.3, 3.0), LEAF)
        ball(parent, "MelonHighlight", position + Vector3.new(0.7, 2.12, 0),
            Vector3.new(1.7, 0.2, 1.1), LEAF_DARK)
        -- Simple contrasting rind marks, intentionally not texture-dependent.
        for stripe = -1, 1 do
            local rind = ball(parent, "MelonRindStripe",
                position + Vector3.new(0.7 + stripe * 0.85, 1.63, -1.05),
                Vector3.new(0.3, 1.34, 0.22), LEAF_DARK)
            rind.CFrame *= CFrame.Angles(0, 0, math.rad(stripe * 18))
        end
    end
end

return Cottage
