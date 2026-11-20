--!strict
-- Original, lightweight cosmetic geometry for recognizable storybook animals.
-- The existing pet's PrimaryPart, behavior, ownership, collision and economy stay unchanged.
-- Every detail uses a small anchored, non-colliding Roblox Part, not copied assets.
local Art = {}

local IVORY = Color3.fromRGB(255, 248, 230)
local WHITE = Color3.fromRGB(255, 252, 245)
local PINK = Color3.fromRGB(246, 167, 174)
local CHESTNUT = Color3.fromRGB(141, 103, 75)
local INK = Color3.fromRGB(72, 57, 68)
local GOLD = Color3.fromRGB(246, 211, 117)

local function oval(parent: Instance, name: string, position: Vector3, size: Vector3, tint: Color3): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Shape = Enum.PartType.Ball
    p.Size = size
    p.CFrame = CFrame.new(position)
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Material = Enum.Material.SmoothPlastic
    p.Color = tint
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function ribbon(parent: Instance, name: string, pos: Vector3, size: Vector3, tint: Color3, rotation: number)
    local p = oval(parent, name, pos, size, tint)
    p.CFrame *= CFrame.Angles(0, 0, math.rad(rotation))
    return p
end

local function kitten(parent: Instance, color: Color3)
    local cream = color:Lerp(IVORY, 0.83)
    local stripe = color:Lerp(CHESTNUT, 0.55)
    oval(parent, "CatBib", Vector3.new(0, -1.25, -1.47), Vector3.new(1.85, 1.65, 0.32), cream)
    for _, side in ipairs({-1, 1}) do
        oval(parent, "CatMuzzle", Vector3.new(side * 0.42, -0.74, -2.18), Vector3.new(0.94, 0.72, 0.53), cream)
        ribbon(parent, "TabbyCheekStripe", Vector3.new(side * 1.52, 0.1, -1.57),
            Vector3.new(0.26, 0.72, 0.12), stripe, side * -28)
        oval(parent, "VelvetInnerEar", Vector3.new(side * 1.46, 2.36, -0.57),
            Vector3.new(0.61, 1.26, 0.2), PINK)
        for i = 1, 2 do
            oval(parent, "TinyToe", Vector3.new(side * (0.74 + i * 0.22), -2.02, -1.63),
                Vector3.new(0.15, 0.12, 0.24), cream)
        end
    end
    ribbon(parent, "ForeheadStripe", Vector3.new(0, 1.29, -1.9), Vector3.new(0.32, 0.72, 0.2), stripe, 0)
    oval(parent, "TinyCatNose", Vector3.new(0, -0.62, -2.48), Vector3.new(0.45, 0.32, 0.22), PINK)
    -- Small back stripes are visible from the elevated garden camera.
    for i = 1, 3 do
        oval(parent, "BackTabbySpot", Vector3.new(0, 1.81, -1 + i * 0.78),
            Vector3.new(0.46, 0.12, 0.48), stripe)
    end
end

local function bunny(parent: Instance, color: Color3)
    local blush = Color3.fromRGB(255, 193, 202)
    for _, side in ipairs({-1, 1}) do
        oval(parent, "BunnyEarLining", Vector3.new(side * 1.3, 3.56, -0.61),
            Vector3.new(0.69, 3.1, 0.19), blush)
        oval(parent, "BunnyMuzzle", Vector3.new(side * 0.47, -0.65, -2.18),
            Vector3.new(0.98, 0.7, 0.52), WHITE)
        oval(parent, "BunnyFrontFoot", Vector3.new(side * 1.18, -2.04, -1.65),
            Vector3.new(1.25, 0.46, 1.16), color:Lerp(WHITE, 0.32))
    end
    oval(parent, "CottonTail", Vector3.new(0, -0.6, 2.43), Vector3.new(1.75, 1.75, 1.7), WHITE)
    oval(parent, "BunnyNose", Vector3.new(0, -0.58, -2.48), Vector3.new(0.4, 0.28, 0.22), PINK)
end

local function puppy(parent: Instance, color: Color3)
    local muzzle = Color3.fromRGB(247, 221, 193)
    oval(parent, "PuppyChest", Vector3.new(0, -1.21, -1.5), Vector3.new(2.6, 1.7, 0.35), muzzle)
    for _, side in ipairs({-1, 1}) do
        local ear = ribbon(parent, "PuppyVelvetEar", Vector3.new(side * 2.05, 1.75, -0.56),
            Vector3.new(1.17, 2.2, 0.52), color:Lerp(CHESTNUT, 0.35), side * 25)
        ear.CastShadow = false
        oval(parent, "PuppyJowl", Vector3.new(side * 0.55, -0.9, -2.65),
            Vector3.new(1.1, 0.8, 0.46), muzzle)
        oval(parent, "PuppyEyebrow", Vector3.new(side * 1.12, 1.5, -2.11),
            Vector3.new(0.82, 0.22, 0.2), color:Lerp(CHESTNUT, 0.52))
    end
    oval(parent, "PuppyNose", Vector3.new(0, -0.53, -2.88), Vector3.new(0.7, 0.48, 0.32), INK)
    oval(parent, "PuppyCollar", Vector3.new(0, -0.99, -1.59), Vector3.new(2.7, 0.29, 0.48), GOLD)
end

local function deer(parent: Instance, color: Color3)
    oval(parent, "DeerChest", Vector3.new(0, -1.05, -1.62),
        Vector3.new(1.8, 1.65, 0.45), IVORY)
    oval(parent, "DeerMuzzle", Vector3.new(0, -0.54, -2.25),
        Vector3.new(1.65, 1.06, 0.69), IVORY)
    oval(parent, "DeerNose", Vector3.new(0, -0.53, -2.67),
        Vector3.new(0.48, 0.33, 0.24), INK)
    for _, side in ipairs({-1, 1}) do
        oval(parent, "FawnInnerEar", Vector3.new(side * 2.01, 1.95, -0.61),
            Vector3.new(0.94, 0.62, 0.22), PINK)
        for j = 1, 3 do
            oval(parent, "DeerFreckle", Vector3.new(side * (0.75 + j * 0.36), 1.35, -0.96 + j * 0.51),
                Vector3.new(0.35, 0.16, 0.38), IVORY)
        end
        oval(parent, "DeerHoof", Vector3.new(side * 1.17, -2.08, -1.1),
            Vector3.new(0.83, 0.4, 0.98), CHESTNUT)
        ribbon(parent, "BranchingAntler", Vector3.new(side * 2.03, 4.3, -0.2),
            Vector3.new(0.33, 1.5, 0.34), CHESTNUT, side * 40)
    end
    oval(parent, "DeerTail", Vector3.new(0, -0.65, 2.36), Vector3.new(1.07, 1.18, 1.2), IVORY)
end

local function axolotl(parent: Instance, color: Color3)
    local rose = Color3.fromRGB(248, 152, 185)
    oval(parent, "AxolotlBelly", Vector3.new(0, -1.15, -1.48),
        Vector3.new(2.4, 1.5, 0.34), color:Lerp(WHITE, 0.47))
    for _, side in ipairs({-1, 1}) do
        for i = 1, 3 do
            local gill = ribbon(parent, "FeatheryGill", Vector3.new(side * (2.34 + 0.22 * i), 1.75 - 0.76 * i, -0.65),
                Vector3.new(1.2, 0.35, 0.58), rose, side * (i - 2) * 17)
            gill.CastShadow = false
        end
        oval(parent, "AxolotlGillSpot", Vector3.new(side * 1.55, 0.9, -1.56),
            Vector3.new(0.35, 0.42, 0.24), rose)
    end
    oval(parent, "AxolotlTailFin", Vector3.new(0, -0.15, 2.37),
        Vector3.new(1.1, 1.86, 2.6), color:Lerp(rose, 0.55))
end

local function owl(parent: Instance, color: Color3)
    for _, side in ipairs({-1, 1}) do
        oval(parent, "OwlHeartFace", Vector3.new(side * 1.03, 0.47, -2.14),
            Vector3.new(2.09, 2.22, 0.24), IVORY)
        oval(parent, "OwlEyebrow", Vector3.new(side * 1.04, 1.5, -2.32),
            Vector3.new(1.3, 0.2, 0.2), color:Lerp(CHESTNUT, 0.4))
        oval(parent, "SoftFeatherWing", Vector3.new(side * 2.27, -0.31, 0.3),
            Vector3.new(1.16, 2.53, 1.48), color:Lerp(IVORY, 0.32))
    end
end

-- A handful of recognizable secondary silhouettes, built once per pet.
local function chick(parent: Instance, color: Color3)
    oval(parent, "ChickBib", Vector3.new(0, -0.98, -1.79),
        Vector3.new(2.05, 1.52, 0.42), color:Lerp(WHITE, 0.75))
    oval(parent, "ChickBeak", Vector3.new(0, -0.42, -2.49),
        Vector3.new(0.73, 0.44, 0.68), GOLD)
    for _, side in ipairs({-1, 1}) do
        oval(parent, "ChickFeatherWing", Vector3.new(side * 2.25, -0.25, 0.36),
            Vector3.new(1.12, 1.76, 1.25), color:Lerp(WHITE, 0.46))
        oval(parent, "ChickOrangeFoot", Vector3.new(side * 1.14, -2.05, -1.19),
            Vector3.new(1.12, 0.35, 1.38), GOLD)
    end
    oval(parent, "ChickTopTuft", Vector3.new(0, 2.17, -0.37),
        Vector3.new(0.79, 1.24, 0.86), color)
end

local function turtle(parent: Instance, color: Color3)
    local shell = Color3.fromRGB(94, 155, 113)
    oval(parent, "TurtleChest", Vector3.new(0, -0.82, -1.79),
        Vector3.new(2.1, 1.24, 0.48), IVORY)
    oval(parent, "TurtleShellBack", Vector3.new(0, 0.87, 2.12),
        Vector3.new(4.56, 3.18, 2.44), shell)
    for _, side in ipairs({-1, 1}) do
        for i = 1, 2 do
            oval(parent, "ShellScute", Vector3.new(side * (0.68 + i * 0.47), 1.62, 3.02 - i * 0.1),
                Vector3.new(0.83, 0.76, 0.17), color:Lerp(GOLD, 0.28))
        end
        oval(parent, "TurtleFlatFlipper", Vector3.new(side * 1.78, -1.82, -0.73),
            Vector3.new(1.36, 0.46, 1.77), color)
    end
end

local function frog(parent: Instance, color: Color3)
    oval(parent, "FrogCreamBelly", Vector3.new(0, -1.10, -1.71),
        Vector3.new(2.24, 1.63, 0.39), color:Lerp(IVORY, 0.8))
    for _, side in ipairs({-1, 1}) do
        oval(parent, "FrogEyelid", Vector3.new(side * 1.26, 2.52, -1.7),
            Vector3.new(1.78, 0.36, 0.52), color)
        for toe = 1, 3 do
            oval(parent, "FrogToe", Vector3.new(side * (1.48 + toe * 0.24), -2.1, -1.30 - toe * 0.12),
                Vector3.new(0.45, 0.23, 0.43), color)
        end
    end
end

local function butterfly(parent: Instance, color: Color3)
    for _, side in ipairs({-1, 1}) do
        oval(parent, "ButterflyWingEye", Vector3.new(side * 3.22, 1.28, 2.08),
            Vector3.new(1.1, 1.38, 0.28), PINK)
        oval(parent, "LowerWingHeart", Vector3.new(side * 2.90, -0.89, 2.13),
            Vector3.new(0.77, 0.98, 0.28), IVORY)
        ribbon(parent, "ButterflyFeelers", Vector3.new(side * 0.64, 3.23, -1.11),
            Vector3.new(0.18, 1.65, 0.17), INK, side * 25)
    end
    oval(parent, "ButterflyChest", Vector3.new(0, -0.37, -1.93),
        Vector3.new(0.86, 2.53, 0.65), color:Lerp(IVORY, 0.64))
end

local function crab(parent: Instance, color: Color3)
    oval(parent, "CrabMuzzle", Vector3.new(0, -0.83, -1.92),
        Vector3.new(1.92, 0.92, 0.48), IVORY)
    for _, side in ipairs({-1, 1}) do
        oval(parent, "CrabClawTip", Vector3.new(side * 3.48, 0.5, -1.08),
            Vector3.new(1.29, 1.37, 1.11), color:Lerp(PINK, 0.3))
        for i = 1, 2 do
            ribbon(parent, "CrabSideLeg", Vector3.new(side * (2.1 + 0.6 * i), -1.42, 0.57 * i),
                Vector3.new(1.42, 0.32, 0.4), color, side * 21)
        end
    end
end

local function dinosaur(parent: Instance, color: Color3)
    oval(parent, "DinosaurBelly", Vector3.new(0, -0.98, -1.73),
        Vector3.new(2.19, 1.76, 0.42), IVORY)
    oval(parent, "DinosaurMuzzle", Vector3.new(0, -0.75, -2.29),
        Vector3.new(1.48, 0.81, 0.93), color:Lerp(IVORY, 0.36))
    for i = 1, 4 do
        oval(parent, "DinosaurBackPlate", Vector3.new(0, 2.22 - i * 0.14, -0.5 + i * 0.84),
            Vector3.new(1.2, 1.44, 0.61), color:Lerp(GOLD, 0.28))
    end
end

local function bird(parent: Instance, color: Color3)
    oval(parent, "BirdChest", Vector3.new(0, -0.86, -1.78),
        Vector3.new(2.1, 1.58, 0.42), IVORY)
    oval(parent, "BirdBeak", Vector3.new(0, -0.51, -2.59),
        Vector3.new(1.04, 0.62, 0.99), GOLD)
    for _, side in ipairs({-1, 1}) do
        oval(parent, "FeatherLayer", Vector3.new(side * 2.25, -0.38, 0.56),
            Vector3.new(0.95, 1.73, 1.57), color:Lerp(IVORY, 0.55))
        oval(parent, "BirdFoot", Vector3.new(side * 1.11, -2.01, -1.36),
            Vector3.new(0.9, 0.33, 0.93), GOLD)
    end
end

local function bat(parent: Instance, color: Color3)
    for _, side in ipairs({-1, 1}) do
        oval(parent, "BatEarPink", Vector3.new(side * 1.44, 2.34, -0.72),
            Vector3.new(0.61, 1.17, 0.26), PINK)
        oval(parent, "BatMembraneHighlight", Vector3.new(side * 3.18, 0.4, 1.53),
            Vector3.new(2.03, 1.47, 0.19), color:Lerp(PINK, 0.48))
    end
    oval(parent, "BatChest", Vector3.new(0, -1.12, -1.71),
        Vector3.new(1.88, 1.51, 0.45), IVORY)
end

local function unicorn(parent: Instance, color: Color3)
    oval(parent, "UnicornFace", Vector3.new(0, -0.67, -1.93),
        Vector3.new(1.96, 1.21, 0.52), IVORY)
    oval(parent, "UnicornMuzzle", Vector3.new(0, -1.03, -2.47),
        Vector3.new(1.27, 0.67, 0.81), color:Lerp(IVORY, 0.65))
    for _, side in ipairs({-1, 1}) do
        oval(parent, "UnicornMane", Vector3.new(side * 1.48, 1.55, 0.96),
            Vector3.new(1.22, 1.96, 1.22), if side < 0 then PINK else GOLD)
    end
end

local function bear(parent: Instance, color: Color3)
    oval(parent, "BearMuzzle", Vector3.new(0, -0.65, -2.21),
        Vector3.new(1.63, 1.04, 0.69), IVORY)
    oval(parent, "BearNose", Vector3.new(0, -0.44, -2.62),
        Vector3.new(0.56, 0.36, 0.23), INK)
    for _, side in ipairs({-1, 1}) do
        oval(parent, "BearEarInner", Vector3.new(side * 1.56, 2.22, -0.58),
            Vector3.new(0.84, 0.81, 0.25), color:Lerp(PINK, 0.51))
    end
end

function Art.decorate(pet: Model, species: string, color: Color3)
    if not pet.PrimaryPart or pet:FindFirstChild("StorybookDetails") then return end
    local details = Instance.new("Folder")
    details.Name = "StorybookDetails"
    details.Parent = pet

    -- Micro-highlights make the existing eyes read as glossy, lively eyes
    -- without a camera-facing billboard, a per-frame update, or texture assets.
    for _, side in ipairs({-1, 1}) do
        oval(details, "EyeSpark", Vector3.new(side * 1.03, 0.82, -2.39),
            Vector3.new(0.24, 0.29, 0.13), WHITE)
    end

    if species == "Pip" or species == "Zuzu" then
        kitten(details, color)
    elseif species == "Floofle" then
        bunny(details, color)
    elseif species == "Snorf" then
        puppy(details, color)
    elseif species == "Sprig" then
        deer(details, color)
    elseif species == "Puddle" then
        axolotl(details, color)
    elseif species == "Swoop" then
        owl(details, color)
    elseif species == "Nugget" then
        chick(details, color)
    elseif species == "Pebble" then
        turtle(details, color)
    elseif species == "Splat" then
        frog(details, color)
    elseif species == "Twinkle" then
        butterfly(details, color)
    elseif species == "Quibble" then
        crab(details, color)
    elseif species == "Rumble" then
        dinosaur(details, color)
    elseif species == "Puffin" then
        bird(details, color)
    elseif species == "Echo" then
        bat(details, color)
    elseif species == "Glimmer" then
        unicorn(details, color)
    elseif species == "Mallow" then
        bear(details, color)
    end
end

return Art
