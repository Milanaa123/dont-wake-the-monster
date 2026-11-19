--!strict
-- Procedural prototype art: no externally licensed assets or mesh dependencies.
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local World = {}
local scenery: Folder
local monster: Model
local monsterEyes: {BasePart} = {}
local monsterMouth: BasePart

local PINK = Color3.fromRGB(255, 153, 204)
local BLUE = Color3.fromRGB(121, 220, 255)
local MINT = Color3.fromRGB(142, 239, 196)
local YELLOW = Color3.fromRGB(255, 227, 133)
local PURPLE = Color3.fromRGB(192, 165, 255)

local function part(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.Shape = shape or Enum.PartType.Block
    p.Anchored = true
    p.CanCollide = false
    p.CastShadow = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function orb(parent: Instance, name: string, position: Vector3, size: Vector3, color: Color3, material: Enum.Material?): Part
    return part(parent, name, size, CFrame.new(position), color, material, Enum.PartType.Ball)
end

local function platform(parent: Instance, name: string, position: Vector3, radius: number, thickness: number, color: Color3): Part
    local p = part(parent, name, Vector3.new(thickness, radius * 2, radius * 2), CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)), color, Enum.Material.Grass, Enum.PartType.Cylinder)
    p.CanCollide = true
    return p
end

local function billboard(parent: Instance, label: string, position: Vector3, width: number)
    local anchor = part(parent, "SignAnchor", Vector3.new(1, 1, 1), CFrame.new(position), Color3.new(1, 1, 1))
    anchor.Transparency = 1
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.fromOffset(width, 95)
    gui.StudsOffset = Vector3.new(0, 4, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 190
    gui.Parent = anchor
    local t = Instance.new("TextLabel")
    t.Size = UDim2.fromScale(1, 1)
    t.BackgroundTransparency = 1
    t.Text = label
    t.TextScaled = true
    t.Font = Enum.Font.GothamBlack
    t.TextStrokeTransparency = 0.35
    t.TextStrokeColor3 = Color3.fromRGB(58, 39, 86)
    t.TextColor3 = Color3.fromRGB(255, 255, 255)
    t.Parent = gui
end

local function lollipopTree(index: number, position: Vector3)
    local hue = (index * 0.145) % 1
    local treeColor = Color3.fromHSV(hue, 0.38, 1)
    local height = 11 + index % 5
    local trunk = part(scenery, "CandyTreeTrunk", Vector3.new(3, height, 3), CFrame.new(position + Vector3.new(0, height / 2, 0)), Color3.fromRGB(180, 123, 116))
    trunk.CanCollide = false
    orb(scenery, "FluffyCanopy", position + Vector3.new(0, height + 3, 0), Vector3.new(15, 13, 15), treeColor)
    orb(scenery, "CloudyLeaf", position + Vector3.new(5, height + 3, 0), Vector3.new(10, 9, 10), treeColor)
end

local function mushroom(position: Vector3, color: Color3, scale: number)
    part(scenery, "MushroomStem", Vector3.new(scale * 1.1, scale * 3.2, scale * 1.1), CFrame.new(position + Vector3.new(0, scale * 1.6, 0)), Color3.fromRGB(255, 245, 221))
    orb(scenery, "MushroomCap", position + Vector3.new(0, scale * 3.4, 0), Vector3.new(scale * 5, scale * 2, scale * 5), color)
    for i = 1, 5 do
        local theta = i * math.pi * 2 / 5
        orb(scenery, "Spot", position + Vector3.new(math.cos(theta) * scale * 1.5, scale * 4.3, math.sin(theta) * scale * 1.5), Vector3.new(scale * 0.6, scale * 0.32, scale * 0.6), Color3.fromRGB(255, 253, 245))
    end
end

function World.build()
    local existing = workspace:FindFirstChild("MonsterIsland")
    if existing then existing:Destroy() end
    scenery = Instance.new("Folder")
    scenery.Name = "MonsterIsland"
    scenery.Parent = workspace

    Lighting.ClockTime = 15.4
    Lighting.Brightness = 2.5
    Lighting.Ambient = Color3.fromRGB(171, 172, 220)
    Lighting.OutdoorAmbient = Color3.fromRGB(182, 191, 233)
    Lighting.FogColor = Color3.fromRGB(188, 222, 255)
    Lighting.FogEnd = 650
    Lighting.GlobalShadows = true

    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
    atmosphere.Density = 0.23
    atmosphere.Color = Color3.fromRGB(208, 229, 255)
    atmosphere.Decay = Color3.fromRGB(255, 199, 217)
    atmosphere.Parent = Lighting

    local water = part(scenery, "CottonCandySea", Vector3.new(1700, 4, 1700), CFrame.new(0, -26, 0), Color3.fromRGB(127, 211, 255), Enum.Material.Glass)
    water.Transparency = 0.36

    platform(scenery, "MainIsland", Vector3.new(0, 0, 0), 118, 14, Color3.fromRGB(159, 230, 172))
    platform(scenery, "MainEdge", Vector3.new(0, -8, 0), 113, 8, Color3.fromRGB(255, 194, 173))
    platform(scenery, "UpperEarth", Vector3.new(0, -16, 0), 88, 9, Color3.fromRGB(193, 163, 237))
    platform(scenery, "MonsterPlatform", Vector3.new(0, 8, 0), 30, 4, Color3.fromRGB(255, 229, 169))

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "SafeSpawn"
    spawn.Size = Vector3.new(15, 1, 15)
    spawn.CFrame = CFrame.new(0, 9, 74)
    spawn.Material = Enum.Material.Neon
    spawn.Color = BLUE
    spawn.Transparency = 0.25
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.CanCollide = true
    spawn.Duration = 0
    spawn.Parent = scenery
    billboard(scenery, "DON'T WAKE THE MONSTER!", Vector3.new(0, 21, 93), 540)
    billboard(scenery, "FEED YOUR PET • MAKE CHAOS • SURVIVE", Vector3.new(0, 15, 63), 470)

    local rng = Random.new(82041) -- stable decorative layout
    local colors = {PINK, BLUE, MINT, YELLOW, PURPLE}
    for i = 1, 23 do
        local a = (i / 23) * math.pi * 2
        local r = rng:NextNumber(72, 104)
        lollipopTree(i, Vector3.new(math.cos(a) * r, 7, math.sin(a) * r))
    end
    for i = 1, 30 do
        local a = rng:NextNumber(0, math.pi * 2)
        local r = rng:NextNumber(44, 101)
        local pos = Vector3.new(math.cos(a) * r, 7, math.sin(a) * r)
        mushroom(pos, colors[i % #colors + 1], rng:NextNumber(0.8, 1.8))
    end
    for i = 1, 17 do
        local a = rng:NextNumber(0, math.pi * 2)
        local r = rng:NextNumber(43, 106)
        local base = Vector3.new(math.cos(a) * r, 8, math.sin(a) * r)
        local crystal = orb(scenery, "GlowCrystal", base + Vector3.new(0, 3.5, 0), Vector3.new(3, 7, 3), colors[(i % #colors) + 1], Enum.Material.Neon)
        crystal.CFrame = crystal.CFrame * CFrame.Angles(0, 0, math.rad(18))
    end
    for i = 1, 18 do
        local a = rng:NextNumber(0, math.pi * 2)
        local r = rng:NextNumber(125, 240)
        local height = rng:NextNumber(25, 85)
        local center = Vector3.new(math.cos(a) * r, height, math.sin(a) * r)
        for j = 1, 3 do
            orb(scenery, "SkyMarshmallow", center + Vector3.new(j * 5, j % 2 * 2, 0), Vector3.new(16, 8, 13), Color3.fromRGB(255, 246, 254))
        end
    end

    monster = Instance.new("Model")
    monster.Name = "GigglesTheGiant"
    monster.Parent = scenery
    local body = orb(monster, "Tummy", Vector3.new(0, 29, 0), Vector3.new(33, 30, 28), PURPLE)
    monster.PrimaryPart = body
    orb(monster, "Head", Vector3.new(0, 47, -4), Vector3.new(29, 25, 25), PURPLE)
    orb(monster, "LeftEar", Vector3.new(-12, 59, -4), Vector3.new(10, 17, 9), PINK)
    orb(monster, "RightEar", Vector3.new(12, 59, -4), Vector3.new(10, 17, 9), PINK)
    orb(monster, "BellyPatch", Vector3.new(0, 29, -13), Vector3.new(20, 19, 3), PINK)
    orb(monster, "LeftFoot", Vector3.new(-12, 16, -8), Vector3.new(12, 8, 14), PURPLE)
    orb(monster, "RightFoot", Vector3.new(12, 16, -8), Vector3.new(12, 8, 14), PURPLE)
    orb(monster, "LeftArm", Vector3.new(-20, 34, 0), Vector3.new(12, 17, 12), PURPLE)
    orb(monster, "RightArm", Vector3.new(20, 34, 0), Vector3.new(12, 17, 12), PURPLE)
    for _, x in ipairs({-7, 7}) do
        orb(monster, "EyeWhite", Vector3.new(x, 49, -15.3), Vector3.new(6, 6.3, 2.2), Color3.fromRGB(250, 250, 255))
        local iris = orb(monster, "SleepyEye", Vector3.new(x, 48.5, -16.8), Vector3.new(3, 3.2, 1.4), Color3.fromRGB(57, 47, 91))
        table.insert(monsterEyes, iris)
    end
    monsterMouth = orb(monster, "Mouth", Vector3.new(0, 41, -16), Vector3.new(8, 2, 1.4), Color3.fromRGB(75, 42, 90))
    local halo = orb(monster, "GlowingNose", Vector3.new(0, 45, -17), Vector3.new(3, 2, 1.7), PINK, Enum.Material.Neon)
    halo.CanCollide = false

    return scenery
end

function World.setMonsterAwake(awake: boolean)
    for _, eye in ipairs(monsterEyes) do
        if eye.Parent then
            TweenService:Create(eye, TweenInfo.new(0.35), {Size = awake and Vector3.new(4.2, 5.5, 1.7) or Vector3.new(3, 3.2, 1.4), Color = awake and Color3.fromRGB(255, 65, 124) or Color3.fromRGB(57, 47, 91)}):Play()
        end
    end
    if monsterMouth and monsterMouth.Parent then
        TweenService:Create(monsterMouth, TweenInfo.new(0.4), {Size = awake and Vector3.new(11, 10, 2) or Vector3.new(8, 2, 1.4)}):Play()
    end
end

function World.makePet(name: string, color: Color3, pointy: boolean): Model
    local pet = Instance.new("Model")
    pet.Name = name
    pet.Parent = scenery
    local body = orb(pet, "SquishyBody", Vector3.new(0, 0, 0), Vector3.new(4.4, 4, 4), color)
    body.CanCollide = false
    pet.PrimaryPart = body
    for _, x in ipairs({-1.15, 1.15}) do
        orb(pet, "EyeWhite", Vector3.new(x, 0.5, -1.85), Vector3.new(1.35, 1.65, 0.6), Color3.fromRGB(255, 255, 255))
        orb(pet, "Pupil", Vector3.new(x, 0.35, -2.23), Vector3.new(0.64, 0.9, 0.25), Color3.fromRGB(48, 35, 74))
        orb(pet, "Ear", Vector3.new(x * 1.25, 2.15, 0), pointy and Vector3.new(1.15, 2.4, 1.1) or Vector3.new(1.8, 1.6, 1.3), color)
    end
    orb(pet, "Nose", Vector3.new(0, -0.55, -2.04), Vector3.new(0.55, 0.4, 0.4), PINK)
    local light = Instance.new("PointLight")
    light.Range = 11
    light.Brightness = 0.4
    light.Color = color
    light.Parent = body
    return pet
end

function World.burst(position: Vector3, color: Color3, count: number, reach: number?)
    local rng = Random.new()
    local maxReach = reach or 11
    for i = 1, math.min(count, 32) do
        local d = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(0.1, 1), rng:NextNumber(-1, 1)).Unit
        local start = position + Vector3.new(0, 2, 0)
        local b = orb(scenery, "Burst", start, Vector3.new(0.6, 0.6, 0.6) * rng:NextNumber(0.8, 2), color, Enum.Material.Neon)
        b.CanCollide = false
        local goal = start + d * rng:NextNumber(maxReach * 0.4, maxReach)
        TweenService:Create(b, TweenInfo.new(rng:NextNumber(0.7, 1.35), Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = goal, Transparency = 1, Size = Vector3.new(0.1, 0.1, 0.1)}):Play()
        Debris:AddItem(b, 1.6)
    end
end

function World.wave(position: Vector3, radius: number, color: Color3)
    local b = orb(scenery, "Shockwave", position, Vector3.new(4, 1.2, 4), color, Enum.Material.Neon)
    b.Transparency = 0.3
    TweenService:Create(b, TweenInfo.new(1.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = Vector3.new(radius * 2, 1.2, radius * 2), Transparency = 1}):Play()
    Debris:AddItem(b, 1.45)
end

return World
