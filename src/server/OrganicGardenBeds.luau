--!strict
-- Original organic farm geometry designed around the reference composition.
-- All nine plots remain in their original positions and still use the
-- existing Garden data, growth timers and server-owned ProximityPrompts.
-- No imported models, texture IDs or generated images.
local Beds = {}

local BROWN = Color3.fromRGB(142, 105, 78)
local DARK = Color3.fromRGB(103, 76, 59)
local LIGHT = Color3.fromRGB(177, 132, 91)
local SAND = Color3.fromRGB(205, 182, 137)
local GREEN = Color3.fromRGB(105, 156, 84)
local GREEN_LIT = Color3.fromRGB(177, 207, 120)
local IVORY = Color3.fromRGB(255, 243, 201)
local PINK = Color3.fromRGB(249, 198, 197)

local function shape(parent: Instance, name: string, at: CFrame,
    size: Vector3, color: Color3, material: Enum.Material,
    kind: Enum.PartType?): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = at
    p.Color = color
    p.Material = material
    p.Shape = kind or Enum.PartType.Ball
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

local function leaf(parent: Instance, name: string, origin: CFrame,
    x: number, z: number, angle: number, color: Color3, scale: number)
    local q = origin * CFrame.new(x, 0.03, z)
        * CFrame.Angles(0, angle, math.rad(-9))
    shape(parent, name, q, Vector3.new(.35 * scale, .095, .63 * scale),
        color, Enum.Material.SmoothPlastic)
end

local function blossom(parent: Instance, basis: CFrame,
    x: number, z: number, scale: number, pink: boolean)
    local c = if pink then PINK else IVORY
    for j = 1, 5 do
        local a = j * math.pi * 2 / 5
        shape(parent, "MeadowFlowerPetal",
            basis * CFrame.new(x + math.cos(a) * .19 * scale,
                .11, z + math.sin(a) * .18 * scale),
            Vector3.new(.23 * scale, .075, .29 * scale),
            c, Enum.Material.SmoothPlastic)
    end
    shape(parent, "MeadowFlowerHeart",
        basis * CFrame.new(x, .18, z),
        Vector3.new(.23 * scale, .10, .23 * scale),
        Color3.fromRGB(245, 216, 108), Enum.Material.SmoothPlastic)
end

function Beds.decorateLawn(parent: Model, center: CFrame)
    -- One small shared set of worn-earth footsteps defines the entrance,
    -- instead of a giant wood platform or hard nine-square chessboard.
    local rng = Random.new(495812)
    for n = 1, 13 do
        local z = 15.4 - n * 2.5
        local x = math.sin(n * 1.14) * 0.43
        local tint = if n % 3 == 0 then SAND else Color3.fromRGB(220, 190, 145)
        shape(parent, "PaintedFootpath",
            center * CFrame.new(x, .735, z) * CFrame.Angles(0, math.rad(n * 23), 0),
            Vector3.new(4.3 + (n % 3) * .5, .13, 2.65),
            tint, Enum.Material.Sand)
    end
    for n = 1, 14 do
        local side = if n % 2 == 0 then 1 else -1
        local x = side * rng:NextNumber(11.1, 12.4)
        local z = rng:NextNumber(-11.8, 12.5)
        if n % 4 == 0 then
            blossom(parent, center * CFrame.new(0, .70, 0),
                x, z, rng:NextNumber(.52, .8), n % 3 == 0)
        else
            for j = 1, 3 do
                local a = j * math.pi * 2 / 3
                leaf(parent, "PaintedCloverLeaf",
                    center * CFrame.new(0, .72, 0),
                    x + math.sin(a) * .18, z + math.cos(a) * .18,
                    a, if j % 2 == 0 then GREEN_LIT else GREEN, .88)
            end
        end
    end
end

function Beds.decoratePlot(parent: Model, place: CFrame,
    plotIndex: number): Part
    local rng = Random.new(5713 + plotIndex * 67)

    -- Overlapping, low-profile sculpted brown earth forms a single bed.
    -- Every piece remains cosmetic; the existing grass platform is the
    -- reliable physics surface for avatars, pets and mobile controls.
    local base = shape(parent, "SoftSoil",
        place * CFrame.new(0, .04, 0),
        Vector3.new(7.45, .51, 7.38),
        BROWN, Enum.Material.Ground)
    shape(parent, "PaintedDarkLoam",
        place * CFrame.new(-.23, .05, -.17),
        Vector3.new(6.6, .43, 6.3),
        DARK, Enum.Material.Ground)
    shape(parent, "PaintedWarmTopsoil",
        place * CFrame.new(.22, .085, .08),
        Vector3.new(6.0, .37, 6.15),
        LIGHT, Enum.Material.Ground)
    -- Low shoulders soften the edges as the turf blends into the soil.
    -- Never build raised square wood rails in the walking area.
    for i = 1, 6 do
        local a = i * math.pi * 2 / 6 + plotIndex * .11
        local radial = rng:NextNumber(2.65, 3.18)
        local dx, dz = math.cos(a) * radial, math.sin(a) * radial
        local tint = if i % 3 == 0 then BROWN elseif i % 2 == 0 then DARK else LIGHT
        shape(parent, "LooseSoilPebble",
            place * CFrame.new(dx, .16, dz)
                * CFrame.Angles(0, a * .65, 0),
            Vector3.new(rng:NextNumber(.35, .7), .19,
                rng:NextNumber(.38, .67)),
            tint, Enum.Material.Ground)
    end
    for j = 1, 3 do
        local a = j * math.pi * 2 / 3 + plotIndex * .39
        local x = math.cos(a) * 3.36
        local z = math.sin(a) * 3.38
        leaf(parent, "SeedbedClover", place, x, z, a,
            if j % 2 == 0 then GREEN else GREEN_LIT, 1.04)
    end
    return base
end

return Beds
