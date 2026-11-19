--!strict
-- Procedural prototype art: no externally licensed assets or mesh dependencies.
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local CottageStyle = require(script.Parent:WaitForChild("CottageGardenStyle"))

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
    -- Cottage palette: muted greens and gently varied sunlit leaves.
    local treeColors = {
        Color3.fromRGB(107, 165, 93),
        Color3.fromRGB(149, 195, 104),
        Color3.fromRGB(188, 214, 121),
    }
    local treeColor = treeColors[index % #treeColors + 1]
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
    CottageStyle.applyLighting()

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
    for i = 1, 14 do
        local a = (i / 14) * math.pi * 2
        local r = rng:NextNumber(72, 104)
        lollipopTree(i, Vector3.new(math.cos(a) * r, 7, math.sin(a) * r))
    end
    for i = 1, 12 do
        local a = rng:NextNumber(0, math.pi * 2)
        local r = rng:NextNumber(44, 101)
        local pos = Vector3.new(math.cos(a) * r, 7, math.sin(a) * r)
        mushroom(pos, colors[i % #colors + 1], rng:NextNumber(0.8, 1.8))
    end
    for i = 1, 7 do
        local a = rng:NextNumber(0, math.pi * 2)
        local r = rng:NextNumber(43, 106)
        local base = Vector3.new(math.cos(a) * r, 8, math.sin(a) * r)
        local crystal = orb(scenery, "GlowCrystal", base + Vector3.new(0, 3.5, 0), Vector3.new(3, 7, 3), colors[(i % #colors) + 1], Enum.Material.Neon)
        crystal.CFrame = crystal.CFrame * CFrame.Angles(0, 0, math.rad(18))
    end
    for i = 1, 12 do
        local a = rng:NextNumber(0, math.pi * 2)
        local r = rng:NextNumber(125, 240)
        local height = rng:NextNumber(25, 85)
        local center = Vector3.new(math.cos(a) * r, height, math.sin(a) * r)
        for j = 1, 3 do
            orb(scenery, "SkyMarshmallow", center + Vector3.new(j * 5, j % 2 * 2, 0), Vector3.new(16, 8, 13), Color3.fromRGB(255, 246, 254))
        end
    end

    CottageStyle.decorateWorld(scenery)

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
    orb(pet, "Smile", Vector3.new(0, -1.13, -1.85), Vector3.new(1.18, 0.25, 0.28), Color3.fromRGB(92, 53, 92))
    for _, x in ipairs({-1.75, 1.75}) do
        orb(pet, "RosyCheek", Vector3.new(x, -0.67, -1.57), Vector3.new(0.7, 0.5, 0.27), Color3.fromRGB(255, 156, 177))
        orb(pet, "TinyFoot", Vector3.new(x * 0.7, -1.86, -0.9), Vector3.new(1.25, 0.7, 1.45), color)
    end
    orb(pet, "PuffTail", Vector3.new(0, -0.2, 2.05), Vector3.new(1.8, 1.8, 1.8), color)
    local species = (string.match(name, "^[^_]+") or name):gsub("^Wild", "")
    if species == "Pip" or species == "Zuzu" then
        -- Two explicitly feline companions. The SAME cat species can have
        -- entirely different personalities per player.
        for _, side in ipairs({-1, 1}) do
            for n = 1, 3 do
                local whisker = part(pet, "KittenWhisker", Vector3.new(1.15, 0.10, 0.10),
                    CFrame.new(side * 1.94, -0.55 + (n - 2) * 0.24, -1.51) * CFrame.Angles(0, 0, math.rad(side * (n - 2) * 9)),
                    Color3.fromRGB(251, 245, 239))
                whisker.CanCollide = false
            end
        end
        orb(pet, "CatTail", Vector3.new(1.9, 0.35, 2.35), Vector3.new(1, 3.0, 1), color)
        orb(pet, "TailTip", Vector3.new(1.9, 1.75, 2.35), Vector3.new(1.3, 1.3, 1.3), PINK)
    elseif species == "Nugget" then
        for _, x in ipairs({-1, 1}) do
            local wing = orb(pet, "FluffyWing", Vector3.new(x * 2.6, 0.2, 0.3), Vector3.new(1.5, 2.4, 1.2), Color3.fromRGB(255, 245, 196))
            wing.CFrame = wing.CFrame * CFrame.Angles(0, 0, math.rad(x * 24))
        end
    elseif species == "Spark" then
        local crystal = orb(pet, "SparkCrown", Vector3.new(0, 3.1, 0), Vector3.new(1.55, 2.3, 1.5), YELLOW, Enum.Material.Neon)
        crystal.CFrame = crystal.CFrame * CFrame.Angles(0, 0, math.rad(22))
    elseif species == "Pickle" then
        orb(pet, "LeafSprout", Vector3.new(-0.6, 3.1, 0), Vector3.new(1.75, 0.62, 1.05), MINT)
        orb(pet, "LeafSprout", Vector3.new(0.6, 3.4, 0), Vector3.new(1.75, 0.62, 1.05), MINT)
    elseif species == "Mochi" or species == "Tofu" then
        for _, x in ipairs({-1.1, 0, 1.1}) do
            orb(pet, "CloudTuft", Vector3.new(x, 2.25, -0.2), Vector3.new(1.8, 1.5, 1.8), Color3.fromRGB(255, 253, 244))
        end
    elseif species == "Bloop" or species == "Gloop" then
        for _, x in ipairs({-1.7, 1.7}) do
            orb(pet, "JellySpot", Vector3.new(x, 0.85, -1.38), Vector3.new(0.6, 0.65, 0.28), BLUE, Enum.Material.Neon)
        end
    elseif species == "Wobble" then
        local halo = part(pet, "WobbleHalo", Vector3.new(0.4, 5.2, 5.2), CFrame.new(0, 3.1, 0) * CFrame.Angles(0, 0, math.rad(90)), PURPLE, Enum.Material.Neon, Enum.PartType.Cylinder)
        halo.Transparency = 0.32
    elseif species == "Luma" then
        orb(pet, "FluffyCloud", Vector3.new(0, 2.5, 0), Vector3.new(4, 1.5, 3), Color3.fromRGB(255, 248, 251))
        orb(pet, "StarCharm", Vector3.new(0, 3.45, -0.8), Vector3.new(1.4, 1.7, 1), YELLOW, Enum.Material.Neon)
    elseif species == "Snorf" then
        orb(pet, "BigSnout", Vector3.new(0, -0.5, -2.35), Vector3.new(2.2, 1.3, 1.3), Color3.fromRGB(241, 203, 159))
        for _, x in ipairs({-1, 1}) do orb(pet, "FloppyEar", Vector3.new(x * 2.1, 2, 0), Vector3.new(1.4, 2.8, 1.6), color) end
    elseif species == "Floofle" then
        for _, x in ipairs({-1, 1}) do
            orb(pet, "BunnyEar", Vector3.new(x * 1.3, 3.4, 0), Vector3.new(1.4, 4.2, 1.1), color)
            orb(pet, "BuckTooth", Vector3.new(x * 0.4, -1, -2.1), Vector3.new(0.65, 0.8, 0.5), Color3.fromRGB(255, 254, 248))
        end
    elseif species == "Quibble" then
        for _, x in ipairs({-1, 1}) do
            orb(pet, "CrabClaw", Vector3.new(x * 3.2, -0.2, -0.5), Vector3.new(2.1, 2.4, 2.1), color)
            orb(pet, "EyeStalk", Vector3.new(x * 1.15, 2.8, -0.7), Vector3.new(0.8, 2.8, 0.8), color)
        end
    elseif species == "Fizzle" then
        for i = 1, 4 do
            local spike = orb(pet, "FireSpike", Vector3.new(0, 2.5 + i * 0.35, -1.6 + i * 0.8), Vector3.new(1.1, 1.8, 1), Color3.fromRGB(255, 224 - i * 24, 87), Enum.Material.Neon)
            spike.CFrame *= CFrame.Angles(0, 0, math.rad(i * 12))
        end
    elseif species == "Puddle" then
        for _, x in ipairs({-1, 1}) do
            for i = 1, 3 do
                orb(pet, "AxolotlGill", Vector3.new(x * (2.4 + i * 0.2), 1.8 - i * 0.85, -0.4), Vector3.new(1.5, 0.7, 0.9), Color3.fromRGB(255, 174, 195))
            end
        end
    elseif species == "Sprig" then
        for _, x in ipairs({-1, 1}) do
            local horn = orb(pet, "LittleAntler", Vector3.new(x * 1.5, 3.7, 0), Vector3.new(0.6, 3.2, 0.6), Color3.fromRGB(169, 123, 92))
            horn.CFrame *= CFrame.Angles(0, 0, math.rad(x * 20))
            orb(pet, "LeafCrown", Vector3.new(x * 1.7, 4.5, 0), Vector3.new(1.4, 0.7, 1), MINT)
        end
    elseif species == "Twinkle" then
        for _, x in ipairs({-1, 1}) do
            orb(pet, "ButterflyWingTop", Vector3.new(x * 3.2, 1.2, 1.7), Vector3.new(3, 3.9, 0.7), Color3.fromRGB(247, 185, 253))
            orb(pet, "ButterflyWingBottom", Vector3.new(x * 2.9, -0.8, 1.8), Vector3.new(2, 2.4, 0.7), Color3.fromRGB(167, 220, 254))
        end
    elseif species == "Mallow" then
        orb(pet, "MarshmallowHat", Vector3.new(0, 2.75, 0), Vector3.new(3.5, 1.5, 3.5), Color3.fromRGB(255, 251, 238))
        orb(pet, "HeartNose", Vector3.new(0, -0.4, -2.5), Vector3.new(0.9, 0.65, 0.6), PINK)
    elseif species == "Pebble" then
        orb(pet, "TurtleShell", Vector3.new(0, 0.7, 2.0), Vector3.new(4.7, 3.8, 2.5), Color3.fromRGB(92, 174, 120))
        for _, x in ipairs({-1, 1}) do orb(pet, "ShellSpot", Vector3.new(x * 1.3, 1.7, 3.0), Vector3.new(1.3, 1.3, 0.6), MINT) end
    elseif species == "Noodle" then
        for _, x in ipairs({-1, 1}) do
            orb(pet, "LongFloppyEar", Vector3.new(x * 2.5, 2.1, -0.6), Vector3.new(1.1, 4.8, 1.2), color)
            orb(pet, "Whisker", Vector3.new(x * 1.6, -0.5, -2.2), Vector3.new(1.4, 0.15, 0.2), Color3.fromRGB(255, 249, 230))
        end
    elseif species == "Swoop" then
        for _, x in ipairs({-1, 1}) do
            orb(pet, "OwlFaceDisc", Vector3.new(x * 1.1, 0.6, -1.95), Vector3.new(2.3, 2.5, 0.55), Color3.fromRGB(251, 231, 255))
            orb(pet, "OwlFeather", Vector3.new(x * 1.8, 2.9, 0), Vector3.new(0.85, 2.2, 1), color)
        end
        orb(pet, "Beak", Vector3.new(0, -0.25, -2.4), Vector3.new(1, 1.4, 0.85), YELLOW)
    elseif species == "Rumble" then
        for i = 1, 5 do
            orb(pet, "DinoSpike", Vector3.new(0, 2.3, -2.1 + i), Vector3.new(1.4, 1.3, 1.5), Color3.fromRGB(121, 201, 133))
        end
    elseif species == "Doodle" then
        for i = 1, 5 do
            local theta = i * math.pi * 2 / 5
            orb(pet, "InkDot", Vector3.new(math.cos(theta) * 3, 1 + math.sin(theta) * 2.8, 0), Vector3.new(0.65, 0.65, 0.65), Color3.fromRGB(82, 77, 138))
        end
    elseif species == "Crumble" then
        for i = 1, 6 do
            local theta = i * math.pi * 2 / 6
            orb(pet, "ChocolateChip", Vector3.new(math.cos(theta) * 1.45, math.sin(theta) * 1.4, -1.88), Vector3.new(0.65, 0.7, 0.35), Color3.fromRGB(128, 81, 65))
        end
    elseif species == "Squiggle" then
        for i = 1, 6 do
            local theta = i * math.pi * 2 / 6
            orb(pet, "SquidArm", Vector3.new(math.cos(theta) * 2, -2, math.sin(theta) * 2), Vector3.new(0.8, 2.2, 0.8), color)
        end
    elseif species == "Glimmer" then
        local horn = orb(pet, "UnicornHorn", Vector3.new(0, 3.6, -0.6), Vector3.new(1, 3.3, 1), Color3.fromRGB(255, 238, 138), Enum.Material.Neon)
        horn.CFrame *= CFrame.Angles(math.rad(-22), 0, 0)
        for _, x in ipairs({-1, 1}) do orb(pet, "RainbowMane", Vector3.new(x * 1.2, 2.1, 0.8), Vector3.new(2, 1.3, 1.5), Color3.fromRGB(235, 178, 254)) end
    elseif species == "Splat" then
        for _, x in ipairs({-1, 1}) do
            orb(pet, "FrogEyebulge", Vector3.new(x * 1.3, 2.2, -1.1), Vector3.new(2, 2, 1.8), color)
            orb(pet, "FrogFoot", Vector3.new(x * 2, -1.95, -1), Vector3.new(2, 0.7, 2), color)
        end
    elseif species == "Puffin" then
        for _, x in ipairs({-1, 1}) do orb(pet, "PuffinWing", Vector3.new(x * 2.5, 0.1, 0), Vector3.new(1.5, 3, 1.9), Color3.fromRGB(255, 245, 218)) end
        orb(pet, "OrangeBeak", Vector3.new(0, -0.5, -2.65), Vector3.new(1.5, 1.1, 1.4), Color3.fromRGB(255, 165, 94))
    elseif species == "Echo" then
        for _, x in ipairs({-1, 1}) do
            local wing = orb(pet, "BatWing", Vector3.new(x * 3.1, 0.7, 1), Vector3.new(3, 2.6, 0.75), Color3.fromRGB(94, 79, 174))
            wing.CFrame *= CFrame.Angles(0, 0, math.rad(x * 24))
            orb(pet, "Fang", Vector3.new(x * 0.6, -1.1, -2.17), Vector3.new(0.45, 0.95, 0.45), Color3.fromRGB(254, 254, 248))
        end
    end
    local tag = Instance.new("BillboardGui")
    tag.Name = "PetNameTag"
    tag.Size = UDim2.fromOffset(140, 36)
    tag.StudsOffset = Vector3.new(0, 3.7, 0)
    tag.MaxDistance = 85
    tag.AlwaysOnTop = true
    tag.Parent = body
    local tagText = Instance.new("TextLabel")
    tagText.Size = UDim2.fromScale(1, 1)
    tagText.BackgroundTransparency = 1
    tagText.Text = species
    tagText.TextScaled = true
    tagText.TextColor3 = Color3.fromRGB(255, 255, 255)
    tagText.TextStrokeColor3 = Color3.fromRGB(76, 49, 99)
    tagText.TextStrokeTransparency = 0.15
    tagText.Font = Enum.Font.GothamBlack
    tagText.Parent = tag
    local light = Instance.new("PointLight")
    light.Range = 11
    light.Brightness = 0.4
    light.Color = color
    light.Parent = body
    return pet
end

function World.tintPet(pet: Model, tint: Color3)
    for _, item in ipairs(pet:GetDescendants()) do
        if item:IsA("BasePart") and (item.Name == "SquishyBody" or item.Name == "Ear") then
            item.Color = tint
        end
    end
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

-- Server-created personal farm zones. A player sees their six physical plots on the island.
local farmModels: {[number]: Model} = {}
local farmCenters: {[number]: CFrame} = {}

function World.createGarden(userId: number, ownerName: string, slot: number): boolean
    if slot < 1 or slot > 12 then return false end
    if farmModels[userId] then farmModels[userId]:Destroy() end
    local angle = (slot - 1) / 12 * math.pi * 2
    local origin = Vector3.new(math.cos(angle) * 61, 8.3, math.sin(angle) * 61)
    local center = CFrame.lookAt(origin, Vector3.new(0, 8.3, 0))
    local model = Instance.new("Model")
    model.Name = "Farm_" .. tostring(userId)
    model.Parent = scenery
    farmModels[userId] = model
    farmCenters[userId] = center
    local base = part(model, "GardenPlatform", Vector3.new(28, 0.8, 32), center, Color3.fromRGB(247, 213, 160), Enum.Material.WoodPlanks)
    base.CanCollide = true
    part(model, "GreenGrass", Vector3.new(26, 0.4, 30), center * CFrame.new(0, 0.5, 0), Color3.fromRGB(166, 234, 156), Enum.Material.Grass)
    local labelPosition = (center * CFrame.new(0, 2.2, 12)).Position
    billboard(model, "🌼 " .. string.sub(ownerName, 1, 16) .. "'S GARDEN", labelPosition, 260)

    for index = 1, 9 do
        local col = (index - 1) % 3
        local row = math.floor((index - 1) / 3)
        local plot = Instance.new("Model")
        plot.Name = "Plot_" .. index
        plot.Parent = model
        plot:SetAttribute("StageKey", "EMPTY")
        plot:SetAttribute("PlotIndex", index)
        local place = center * CFrame.new((col - 1) * 8.2, 0.9, (row - 1) * 8.4)
        plot:SetAttribute("PosX", place.Position.X)
        plot:SetAttribute("PosY", place.Position.Y)
        plot:SetAttribute("PosZ", place.Position.Z)
        local bed = part(plot, "WoodFrame", Vector3.new(7.9, 0.8, 7.9), place, Color3.fromRGB(187, 121, 93), Enum.Material.Wood)
        bed.CanCollide = true
        local soil = part(plot, "SoftSoil", Vector3.new(6.9, 0.25, 6.9), place * CFrame.new(0, 0.54, 0), Color3.fromRGB(142, 97, 92), Enum.Material.Ground)
        soil.CanCollide = true
        local mini = part(plot, "NumberAnchor", Vector3.new(0.2, 0.2, 0.2), place * CFrame.new(0, 1.6, -2.9), Color3.new(1, 1, 1))
        mini.Transparency = 1
        local tag = Instance.new("BillboardGui")
        tag.Size = UDim2.fromOffset(84, 24)
        tag.MaxDistance = 75
        tag.AlwaysOnTop = true
        tag.Parent = mini
        local t = Instance.new("TextLabel")
        t.Size = UDim2.fromScale(1, 1)
        t.BackgroundColor3 = Color3.fromRGB(255, 252, 224)
        t.BackgroundTransparency = 0.1
        t.TextColor3 = Color3.fromRGB(69, 43, 64)
        t.Text = "PLOT " .. index
        t.TextScaled = true
        t.Font = Enum.Font.GothamBlack
        t.Parent = tag
        local rounded = Instance.new("UICorner")
        rounded.CornerRadius = UDim.new(0, 7)
        rounded.Parent = t
    end
    CottageStyle.decorateFarm(model, center)
    return true
end

function World.removeGarden(userId: number)
    if farmModels[userId] then farmModels[userId]:Destroy() end
    farmModels[userId] = nil
    farmCenters[userId] = nil
end

function World.gardenSpawn(userId: number): Vector3?
    local center = farmCenters[userId]
    if not center then return nil end
    return (center * CFrame.new(0, 4, 13)).Position
end

function World.updateGarden(userId: number, garden: any, cropConfig: any)
    local model = farmModels[userId]
    if not model then return end
    local now = os.time()
    for index = 1, cropConfig.PLOT_COUNT do
        local plot = model:FindFirstChild("Plot_" .. index)
        if not plot or not plot:IsA("Model") then continue end
        local p = garden.plots[index]
        local stage = 0
        if p then
            local total = math.max(1, p.readyAt - p.plantedAt)
            local ratio = math.clamp((now - p.plantedAt) / total, 0, 1)
            stage = if now >= p.readyAt then 3 elseif ratio > 0.48 then 2 else 1
        end
        local stageKey = if p then p.seed .. "_" .. stage .. "_" .. (p.mutation or "normal") else "EMPTY"
        if plot:GetAttribute("StageKey") == stageKey then continue end
        plot:SetAttribute("StageKey", stageKey)
        local previous = plot:FindFirstChild("PlantVisual")
        if previous then previous:Destroy() end
        if p and cropConfig.Crops[p.seed] then
            local visual = Instance.new("Model")
            visual.Name = "PlantVisual"
            visual.Parent = plot
            local center = Vector3.new(plot:GetAttribute("PosX"), plot:GetAttribute("PosY"), plot:GetAttribute("PosZ"))
            local crop = cropConfig.Crops[p.seed]
            local height = 1.2 + stage * 1.0
            part(visual, "Stem", Vector3.new(0.65, height, 0.65), CFrame.new(center + Vector3.new(0, 0.8 + height / 2, 0)), Color3.fromRGB(84, 173, 100))
            for side = -1, 1, 2 do
                local leaf = orb(visual, "Leaf", center + Vector3.new(side * 1.0, 0.8 + height * 0.6, 0), Vector3.new(2.2, 0.45, 1.1), Color3.fromRGB(98, 203, 118))
                leaf.CFrame = leaf.CFrame * CFrame.Angles(0, 0, math.rad(side * 23))
            end
            local size = 0.75 + stage * 0.65
            local head = center + Vector3.new(0, height + 0.8, 0)
            local glow = if stage == 3 then Enum.Material.Neon else Enum.Material.SmoothPlastic
            local seedType = p.seed
            local isBloom = seedType == "Sunflower" or seedType == "Starbloom" or seedType == "MoonLotus" or seedType == "CloudCotton"
            local isMushroom = seedType == "Moonshroom" or seedType == "NeonMushroom"
            local isStalk = seedType == "Corn" or seedType == "WhisperWheat" or seedType == "CandyCane" or seedType == "StardustRice"
            local isCactus = seedType == "JellyCactus" or seedType == "BubbleCabbage" or seedType == "CrystalMint"
            if isBloom then
                orb(visual, "FlowerHeart", head, Vector3.new(size * 1.4, size * 1.4, size), crop.color, glow)
                for i = 1, 6 do
                    local theta = i / 6 * math.pi * 2
                    orb(visual, "Petal", head + Vector3.new(math.cos(theta) * size * 1.15, math.sin(theta) * size * 1.15, 0), Vector3.new(size * 1.15, size * 1.2, size * 0.6), crop.color, glow)
                end
            elseif isMushroom then
                orb(visual, "MushroomCap", head, Vector3.new(size * 3.5, size * 1.3, size * 3.4), crop.color, glow)
                for i = 1, 4 do
                    local theta = i * math.pi * 0.5
                    orb(visual, "MushroomDots", head + Vector3.new(math.cos(theta) * size, size * 0.45, math.sin(theta) * size), Vector3.new(size * 0.45, size * 0.4, size * 0.45), Color3.fromRGB(255, 247, 224))
                end
            elseif isStalk then
                for i = 1, 3 do
                    orb(visual, "Grain", head + Vector3.new(math.sin(i * 2) * 0.7, i * size * 0.65, 0), Vector3.new(size * 1.1, size * 1.4, size * 0.9), crop.color, glow)
                end
            elseif isCactus then
                orb(visual, "CactusHeart", head, Vector3.new(size * 1.8, size * 2.3, size * 1.6), crop.color, glow)
                for _, side in ipairs({-1, 1}) do
                    orb(visual, "CactusBud", head + Vector3.new(side * 1.5 * size, size * 0.4, 0), Vector3.new(size, size * 0.9, size), crop.color)
                end
            else
                orb(visual, "HarvestFruit", head, Vector3.new(size * 2, size * 1.5, size * 2), crop.color, glow)
                if seedType == "GummyGrape" or seedType == "Jellybean" or seedType == "FrostBerry" or seedType == "Berry" then
                    for i = 1, 3 do
                        orb(visual, "FruitCluster", head + Vector3.new((i - 2) * size, -size * 0.6, size * 0.8), Vector3.new(size * 0.9, size * 1.1, size * 0.9), crop.color, glow)
                    end
                end
            end
            CottageStyle.decorateCrop(visual, center, seedType, stage)
            if p.mutation then
                local variations = {
                    Golden = Color3.fromRGB(255, 224, 107),
                    Dewy = Color3.fromRGB(133, 225, 255),
                    Moonlit = Color3.fromRGB(202, 165, 255),
                    Giggly = Color3.fromRGB(255, 152, 209),
                }
                local tint = variations[p.mutation] or crop.color
                for n = 1, 5 do
                    local a = n * math.pi * 2 / 5
                    local bubble = orb(visual, "MutatedSparkle_" .. p.mutation,
                        head + Vector3.new(math.cos(a) * (size + 1.1), math.sin(a) * (size + 1.2), 0),
                        Vector3.new(0.64, 0.64, 0.64), tint, Enum.Material.Neon)
                    bubble.CanCollide = false
                end
            end
            if stage == 3 then
                orb(visual, "HarvestGlow", center + Vector3.new(0, height + 2.4, 0), Vector3.new(0.8, 0.8, 0.8), Color3.fromRGB(255, 248, 187), Enum.Material.Neon)
            end
        end
    end
end

local MOOD_LABELS = {
    Happy = "😊 HAPPY", Calm = "😌 CALM", Grumpy = "😾 GRUMPY",
    Excited = "🤩 EXCITED", Shy = "🥺 SHY", Scared = "😱 SCARED",
    Sleepy = "😴 SLEEPY", Hungry = "🍎 HUNGRY", Curious = "🧐 CURIOUS",
}

function World.stylePersonality(pet: Model, personality: any)
    local root = pet.PrimaryPart
    if not root then return end
    if pet:FindFirstChild("PersonalityAccessory") then return end
    local folder = Instance.new("Folder")
    folder.Name = "PersonalityAccessory"
    folder.Parent = pet
    local t = personality.temperament
    if t == "Grumpy" or t == "Mischievous" or t == "Wild" then
        for _, side in ipairs({-1, 1}) do
            local horn = orb(folder, "TinyAttitudeHorn", Vector3.new(side * 1.15, 2.8, -0.4),
                Vector3.new(0.8, 1.7, 0.8), if t == "Grumpy" then Color3.fromRGB(255, 105, 131) else Color3.fromRGB(183, 137, 249))
            horn.CFrame *= CFrame.Angles(0, 0, math.rad(side * 23))
        end
    elseif t == "Kind" or t == "Clingy" or t == "Shy" then
        orb(folder, "HeartCharm", Vector3.new(0.65, 2.65, -1.1), Vector3.new(1.5, 1.4, 0.5), PINK, Enum.Material.Neon)
    elseif t == "Brave" or t == "Proud" then
        orb(folder, "TinyCrown", Vector3.new(0, 3, -0.3), Vector3.new(2.4, 0.6, 1.2), YELLOW, Enum.Material.Neon)
        orb(folder, "CrownGem", Vector3.new(0, 3.45, -0.72), Vector3.new(0.8, 0.8, 0.5), BLUE, Enum.Material.Neon)
    elseif t == "Curious" or t == "Playful" then
        orb(folder, "CuriosityOrb", Vector3.new(-1.35, 2.7, -0.65), Vector3.new(1.15, 1.15, 1.15), MINT, Enum.Material.Neon)
    elseif t == "Sleepy" or t == "Dreamer" then
        orb(folder, "DreamBubble", Vector3.new(1.65, 2.9, 0), Vector3.new(1.3, 1.3, 1.3), BLUE, Enum.Material.Glass)
    else
        orb(folder, "DramaStar", Vector3.new(0, 3.2, -0.3), Vector3.new(1.4, 1.4, 1.4), YELLOW, Enum.Material.Neon)
    end
    local moodGui = Instance.new("BillboardGui")
    moodGui.Name = "MoodBubble"
    moodGui.Size = UDim2.fromOffset(176, 44)
    moodGui.StudsOffset = Vector3.new(0, 5.1, 0)
    moodGui.MaxDistance = 82
    moodGui.AlwaysOnTop = true
    moodGui.Parent = root
    local label = Instance.new("TextLabel")
    label.Name = "MoodText"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(255, 249, 238)
    label.BackgroundTransparency = 0.15
    label.TextColor3 = Color3.fromRGB(79, 55, 104)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBlack
    label.Parent = moodGui
    local round = Instance.new("UICorner")
    round.CornerRadius = UDim.new(0, 14)
    round.Parent = label
    World.emotePet(pet, "Happy", personality.habit)
end

-- Configurable sound. Upload the project's original purr WAV in Creator Dashboard
-- and set Config.PurrSoundId. No third-party or unlicensed audio asset is used.
function World.setPurr(pet: Model, level: number, soundId: number?)
    local root = pet.PrimaryPart
    if not root then return end
    local existing = root:FindFirstChild("SoftPurrLoop")
    local valid = type(soundId) == "number" and soundId > 0 and soundId == math.floor(soundId)
    if not valid then
        if existing and existing:IsA("Sound") then existing:Stop() end
        return
    end
    local sound: Sound
    if existing and existing:IsA("Sound") then
        sound = existing
    else
        sound = Instance.new("Sound")
        sound.Name = "SoftPurrLoop"
        sound.Looped = true
        sound.RollOffMaxDistance = 64
        sound.RollOffMinDistance = 3
        sound.RollOffMode = Enum.RollOffMode.InverseTapered
        sound.SoundId = "rbxassetid://" .. tostring(soundId)
        sound.Volume = 0
        sound.Parent = root
    end
    level = math.clamp(level, 0, 1)
    sound.Volume = 0.05 + level * 0.77
    sound.PlaybackSpeed = 0.82 + level * 0.29
    if level <= 0.001 then
        sound:Stop()
    elseif not sound.IsPlaying then
        sound:Play()
    end
end

function World.carryPose(pet: Model, root: BasePart, t: number): CFrame
    -- Visual cuddling pose, not an equipped Tool. Server continuously positions
    -- the anchored, non-colliding companion in the avatar's arms.
    local cuddle = root.CFrame * CFrame.new(0, 1.0 + math.sin(t * 2.5) * 0.09, -3)
    return cuddle * CFrame.Angles(math.rad(-13), math.rad(math.sin(t * 1.2) * 7), math.rad(-8))
end

function World.emotePet(pet: Model, mood: string, action: string?)
    local root = pet.PrimaryPart
    if not root then return end
    local gui = root:FindFirstChild("MoodBubble")
    if not gui then return end
    local label = gui:FindFirstChild("MoodText")
    if label and label:IsA("TextLabel") then
        local m = MOOD_LABELS[mood] or mood
        label.Text = m .. (if action then " • " .. string.upper(action) else "")
        label.TextColor3 = if mood == "Grumpy" then Color3.fromRGB(195, 68, 94)
            elseif mood == "Scared" then Color3.fromRGB(113, 91, 210)
            elseif mood == "Happy" or mood == "Excited" then Color3.fromRGB(79, 159, 97)
            else Color3.fromRGB(79, 55, 104)
    end
end

return World
