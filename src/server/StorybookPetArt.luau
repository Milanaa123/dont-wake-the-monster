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
    end
end

return Art
