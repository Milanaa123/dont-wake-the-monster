--!strict
-- Reference-focused native garden for a playable, asset-free .rbxlx.
-- Real Roblox BaseParts/WedgeParts are created by the server. No image mocks,
-- MeshId, imported package, plugin or Roblox authentication required.
-- Imported mesh entrance art takes priority when available.
local NativeGarden = {}

local SOIL = Color3.fromRGB(123, 91, 65)
local DARK_SOIL = Color3.fromRGB(96, 75, 56)
local LEAF = Color3.fromRGB(82, 149, 79)
local LEAF_DEEP = Color3.fromRGB(55, 118, 72)
local LEAF_SUN = Color3.fromRGB(151, 190, 83)
local RED = Color3.fromRGB(234, 75, 75)
local RED_LIGHT = Color3.fromRGB(250, 112, 102)
local CREAM = Color3.fromRGB(255, 239, 203)
local MELON = Color3.fromRGB(171, 215, 85)
local MELON_PALE = Color3.fromRGB(214, 232, 133)
local RIND = Color3.fromRGB(81, 150, 78)
local WHEAT = Color3.fromRGB(250, 228, 157)
local GOLD = Color3.fromRGB(237, 189, 105)
local ORANGE = Color3.fromRGB(244, 146, 70)
local PINK = Color3.fromRGB(249, 192, 198)

local function piece(parent: Instance, name: string, at: CFrame, size: Vector3,
    color: Color3, shape: Enum.PartType?): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Shape = shape or Enum.PartType.Block
    p.Material = Enum.Material.SmoothPlastic
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = size.Y > 0.25
    p.Color = color
    p.Size = size
    p.CFrame = at
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function ball(parent: Instance, name: string, pos: Vector3,
    size: Vector3, tint: Color3): Part
    return piece(parent, name, CFrame.new(pos), size, tint, Enum.PartType.Ball)
end

local function stalk(parent: Instance, name: string, a: Vector3, b: Vector3,
    width: number, color: Color3)
    local v = b - a
    if v.Magnitude <= 0.02 then return end
    local mid = (a + b) * 0.5
    local part = piece(parent, name, CFrame.lookAt(mid, b),
        Vector3.new(width, width, v.Magnitude), color)
    part.CastShadow = false
end

local function leaf(parent: Instance, start: Vector3, tip: Vector3,
    width: number, tint: Color3)
    local line = tip - start
    if line.Magnitude < 0.1 then return end
    local mid = (start + tip) * 0.5 + Vector3.new(0, 0.05, 0)
    local l = Instance.new("WedgePart")
    l.Name = "PaintedTaperedLeaf"
    l.Size = Vector3.new(width, 0.11, line.Magnitude)
    l.Color = tint
    l.Material = Enum.Material.SmoothPlastic
    l.Anchored = true
    l.CanCollide = false
    l.CanTouch = false
    l.CanQuery = false
    l.CastShadow = false
    l.CFrame = CFrame.lookAt(mid, tip)
    l.Parent = parent
end

local function blossom(parent: Instance, point: Vector3, scale: number, pink: boolean)
    local color = if pink then PINK else CREAM
    for i = 1, 5 do
        local theta = i * math.pi * 2 / 5
        local petal = ball(parent, "MeadowPetal",
            point + Vector3.new(math.cos(theta) * 0.22 * scale, 0.02,
                math.sin(theta) * 0.22 * scale),
            Vector3.new(0.27, 0.09, 0.36) * scale, color)
        petal.CastShadow = false
    end
    ball(parent, "GoldenFlowerCenter", point + Vector3.new(0, 0.10, 0),
        Vector3.new(0.24, 0.13, 0.24) * scale, GOLD).CastShadow = false
end

local function strawberry(parent: Instance, center: Vector3, seed: number)
    local rng = Random.new(seed)
    -- The dark organic soil patch gives a readable grounding, as in the reference.
    local soil = ball(parent, "StrawberryEarth", center + Vector3.new(0, 0.12, 0),
        Vector3.new(5.9, 0.28, 5.3), SOIL)
    soil.Material = Enum.Material.Ground
    for i = 1, 6 do
        local theta = i * 2.39996
        local r = if i % 2 == 0 then 1.65 else 1.05
        local pos = center + Vector3.new(math.sin(theta)*r, 0.20,
            math.cos(theta)*r)
        local tip = pos + Vector3.new(math.sin(theta)*0.18,
            rng:NextNumber(0.85, 1.15), math.cos(theta)*0.18)
        stalk(parent, "BerryStem", pos, tip, 0.11, LEAF_DEEP)
        for j = 1, 3 do
            local a = theta + j * math.pi * 2 / 3
            leaf(parent, tip, tip + Vector3.new(math.cos(a)*1.02,
                rng:NextNumber(-0.12, 0.18), math.sin(a)*0.89),
                0.57, if j == 1 then LEAF_SUN else LEAF)
        end
        if i <= 5 then
            local berry = tip + Vector3.new(math.sin(theta)*0.36, -0.46,
                math.cos(theta)*0.39 - 0.05)
            stalk(parent, "BerryPeduncle", tip,
                berry + Vector3.new(0, 0.38, 0), 0.045, LEAF_DEEP)
            local fruit = ball(parent, "RipeRedStrawberry", berry,
                Vector3.new(0.68, 0.92, 0.72),
                if i%2==0 then RED_LIGHT else RED)
            fruit.CFrame *= CFrame.Angles(math.rad(9), theta, math.rad(5))
            for k = 1, 3 do
                local a = k * 2.094
                leaf(parent, berry + Vector3.new(0, 0.38, 0),
                    berry + Vector3.new(math.cos(a)*0.37, 0.38,
                        math.sin(a)*0.34), 0.17, LEAF_DEEP)
            end
            for k = 1, 2 do
                ball(parent, "BerrySeed",
                    berry + Vector3.new((k-1.5)*0.19, -0.03, -0.356),
                    Vector3.new(0.058, 0.105, 0.035), CREAM).CastShadow = false
            end
        end
    end
    if seed % 3 == 0 then
        blossom(parent, center + Vector3.new(0.26, 1.09, -0.21), 0.72, false)
    end
end

local function melon(parent: Instance, center: Vector3, seed: number)
    local rnd = Random.new(seed)
    local dirt = ball(parent, "WatermelonBed", center + Vector3.new(0, 0.13, 0),
        Vector3.new(6.4, 0.24, 5.8), SOIL)
    dirt.Material = Enum.Material.Ground
    for i = 1, 3 do
        local a = i * 2.39996
        local x = math.sin(a) * 1.25
        local z = math.cos(a) * 1.15
        stalk(parent, "MelonRunner", center+Vector3.new(0,.23,0),
            center+Vector3.new(x,.27,z),0.13, LEAF_DEEP)
        local fruitCenter = center + Vector3.new(x, 1.04, z)
        local fruit = ball(parent, "StripedWatermelon", fruitCenter,
            Vector3.new(1.83, 1.80, 1.69),
            if i%2==0 then MELON_PALE else MELON)
        fruit.CFrame *= CFrame.Angles(0, a, 0)
        -- Curved rind bands hug the melon instead of floating straight
        -- vertical rods on the front. Keep the detail to five short ribbons.
        for stripe = -2, 2 do
            local xOffset = stripe * 0.28
            local horizontal = math.sqrt(math.max(0.05, 1 - (xOffset / 0.915)^2))
            for segment = 1, 5 do
                local t = -1.1 + (segment - 0.5) * 0.44
                local y = math.sin(t) * 0.86
                local z = -math.cos(t) * 0.845 * horizontal
                local ribbon = ball(parent, "CurvedMelonRind",
                    fruitCenter + Vector3.new(xOffset, y, z - 0.014),
                    Vector3.new(0.095, 0.39, 0.065), RIND)
                ribbon.CFrame *= CFrame.Angles(t * 0.76, a * 0.07, math.rad(stripe * 3))
                ribbon.CastShadow = false
            end
        end
        -- A small five-lobed green crown ties the fruit to the vine.
        for leafIndex = 1, 5 do
            local theta = leafIndex * math.pi * 2 / 5
            leaf(parent, fruitCenter + Vector3.new(0, 0.83, 0),
                fruitCenter + Vector3.new(math.cos(theta)*0.53, 0.82,
                    math.sin(theta)*0.48), 0.24, LEAF_DEEP)
        end
        for j = 1, 3 do
            local angle = a + j*2.094
            leaf(parent, center + Vector3.new(x, .39, z),
                center + Vector3.new(x + math.sin(angle)*1.02,
                    0.51 + rnd:NextNumber(-.16, .2),
                    z + math.cos(angle)*.84), 0.57,
                if j == 1 then LEAF_SUN else LEAF)
        end
    end
end

local function wheat(parent: Instance, center: Vector3, seed: number)
    local rng = Random.new(seed)
    local soil = ball(parent, "WheatEarth", center + Vector3.new(0,.10,0),
        Vector3.new(4.4,.21,4.5), SOIL)
    soil.Material = Enum.Material.Ground
    for i = 1, 11 do
        local theta = i*2.39996
        local radius = 0.30 + (i%5)*.26
        local base = center + Vector3.new(math.sin(theta)*radius,.15,
            math.cos(theta)*radius)
        local top = base + Vector3.new(rng:NextNumber(-.34,.34),
            rng:NextNumber(3.0, 4.6), rng:NextNumber(-.18,.18))
        stalk(parent, "WheatGrassStem", base, top, 0.10, WHEAT)
        for j = 1, 3 do
            local y = j*.33
            local earCenter = top - Vector3.new(0,y,0)
            local ear = ball(parent, "WheatEar", earCenter,
                Vector3.new(.31,.53,.26), if i%2==0 then GOLD else WHEAT)
            ear.CFrame *= CFrame.Angles(0, theta, .17)
        end
        leaf(parent, base+Vector3.new(0,.38,0),
            base+Vector3.new(math.sin(theta+1)*.52, 1.34,
                math.cos(theta+1)*.46),.22,LEAF_SUN)
    end
end

local function carrots(parent: Instance, center: Vector3, seed: number)
    local ground = ball(parent, "CarrotDarkEarth", center+Vector3.new(0,.09,0),
        Vector3.new(5.6,.19,4.5), DARK_SOIL)
    ground.Material = Enum.Material.Ground
    for i = 1, 7 do
        local a = i*2.39996
        local r = 0.32 + (i%3)*.64
        local p = center+Vector3.new(math.sin(a)*r,.45,math.cos(a)*r)
        local root = ball(parent, "MatureOrangeCarrot",p,
            Vector3.new(.65,.91,.62), ORANGE)
        root.CFrame *= CFrame.Angles(0,a,math.rad(-6))
        for j = 1, 4 do
            local b = a + j * math.pi*.5
            leaf(parent,p+Vector3.new(0,.43,0),
                p+Vector3.new(math.sin(b)*.58,1.32,math.cos(b)*.53),
                .23, if j%2==0 then LEAF_SUN else LEAF)
        end
    end
end

function NativeGarden.build(parent: Instance): Folder
    local old = parent:FindFirstChild("ReferenceNativeGarden")
    if old then old:Destroy() end
    local garden = Instance.new("Folder")
    garden.Name = "ReferenceNativeGarden"
    garden.Parent = parent

    -- All beds are outside x [-9,9] so character movement remains unobstructed.
    for row=1,3 do
        for col=1,3 do
            strawberry(garden,Vector3.new(-30+col*4.15,7.17,67+row*4.65),
                row*1703+col*23)
        end
    end
    -- Exactly one compact vine cluster already carries three ripe melons.
    melon(garden, Vector3.new(-21.7, 7.12, 89.0), 501)
    for i=1,3 do
        wheat(garden,Vector3.new(-26+(i%2)*4.6,7.15,63+math.floor((i-1)/2)*6.2),
            111+i)
    end
    for i=1,3 do
        carrots(garden,Vector3.new(-31+i*4.8,7.15,95.0),i)
    end
    -- Flowers and ground greenery soften edges but never obscure the walkway.
    for i=1,31 do
        local a = i*2.39996
        local x = if i%2==0 then -10.8-math.abs(math.sin(a))*2.1
            else 10.9+math.abs(math.cos(a))*2.4
        local z=42+(i%15)*4.0
        local center=Vector3.new(x,7.24,z)
        if i%4~=0 then
            blossom(garden,center, if i%5==0 then 1.3 else .8,i%3==0)
        else
            for l=1,3 do
                local t=a+l*2.094
                leaf(garden,center,center+Vector3.new(math.cos(t)*.7,
                    .28,math.sin(t)*.58),.31,
                    if l%2==0 then LEAF_SUN else LEAF)
            end
        end
    end
    -- Ground-cover layer: tiny clover groups and warm soil pebbles break up
    -- large empty patches without creating physical obstacles or expensive
    -- terrain textures. Deterministic layout for consistent screenshots.
    local details = Random.new(291104)
    for i = 1, 78 do
        local side = if i % 2 == 0 then -1 else 1
        local x = side * details:NextNumber(12.7, 35.0)
        local z = details:NextNumber(58, 101)
        local at = Vector3.new(x, 7.23, z)
        if i % 3 == 0 then
            local pebble = ball(garden, "GardenSoilPebble",
                at, Vector3.new(details:NextNumber(.24,.49),.12,
                    details:NextNumber(.24,.49)),
                if i % 2 == 0 then SOIL else DARK_SOIL)
            pebble.CastShadow = false
        else
            for j = 1, 3 do
                local a = j * math.pi * 2 / 3 + i * .73
                local clover = ball(garden, "TinyCloverLeaf",
                    at + Vector3.new(math.cos(a)*.18,.03,math.sin(a)*.18),
                    Vector3.new(.29,.07,.23),
                    if j == 1 then LEAF_SUN else LEAF)
                clover.CastShadow = false
            end
        end
    end
    garden:SetAttribute("ArtSource", "NativeGeometryNoExternalAssets")
    return garden
end

return NativeGarden
