--!strict
-- A coherent, original hand-shaped crop language for the photographed cottage-garden mood.
-- Cosmetic only: the server's growth, mutations, yield, purchases and hit detection stay untouched.
-- All art is deterministic and uses non-colliding, non-queryable, anchored parts.
local CropArt = {}

local GREEN = Color3.fromRGB(96, 158, 88)
local LEAF = Color3.fromRGB(122, 177, 93)
local LEAF_LIT = Color3.fromRGB(167, 205, 110)
local DARK = Color3.fromRGB(69, 120, 72)
local EARTH = Color3.fromRGB(137, 103, 76)
local STRAW = Color3.fromRGB(239, 206, 127)
local CREAM = Color3.fromRGB(253, 238, 197)
local RED = Color3.fromRGB(233, 81, 79)
local ORANGE = Color3.fromRGB(243, 148, 67)
local PINK = Color3.fromRGB(246, 173, 194)
local MINT = Color3.fromRGB(153, 212, 175)

local function piece(parent: Instance, name: string, pos: Vector3,
    size: Vector3, color: Color3, material: Enum.Material?): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Shape = Enum.PartType.Ball
    p.CFrame = CFrame.new(pos)
    p.Material = material or Enum.Material.SmoothPlastic
    p.Color = color
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = size.Magnitude > 2.5
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function stem(parent: Instance, name: string, from: Vector3,
    to: Vector3, width: number, color: Color3)
    local displacement = to - from
    local p = Instance.new("Part")
    p.Name = name
    p.Size = Vector3.new(width, width, displacement.Magnitude)
    p.CFrame = CFrame.lookAt((from + to) * 0.5, to)
    p.Material = Enum.Material.SmoothPlastic
    p.Color = color
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Parent = parent
    return p
end

local function leaf(parent: Instance, pos: Vector3, length: number,
    width: number, angle: number, tint: Color3)
    -- An angular tapered, slightly lifted leaf rather than another ball:
    -- matches the pointed foliage language in the supplied garden reference.
    local p = Instance.new("WedgePart")
    p.Name = "PaintedLeaf"
    p.Size = Vector3.new(width, 0.15, length)
    p.CFrame = CFrame.new(pos) *
        CFrame.Angles(math.rad(-12), math.rad(angle), math.rad(5))
    p.Color = tint
    p.Material = Enum.Material.SmoothPlastic
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Parent = parent
    return p
end

local function plantBase(parent: Instance, pos: Vector3, scale: number, leaves: number)
    for i = 1, leaves do
        local a = 2.39996 * i
        leaf(parent, pos + Vector3.new(math.cos(a) * 0.57 * scale, 0.14 * scale, math.sin(a) * 0.55 * scale),
            1.25 * scale, 0.73 * scale, math.deg(a), if i % 2 == 0 then LEAF_LIT else GREEN)
    end
end

local function littleSeeds(parent: Instance, center: Vector3, scale: number)
    -- Five small seed dimples follow the berry's front curvature.
    for i = 1, 5 do
        local col = (i - 1) % 3 - 1
        local row = math.floor((i - 1) / 3)
        local x = col * .25 * scale
        local y = (row == 0 and .10 or -.23) * scale
        local z = -.52 * scale + math.abs(col) * .07 * scale
        piece(parent, "StrawberrySeed", center + Vector3.new(x, y, z),
            Vector3.new(.12, .15, .07) * scale, CREAM)
    end
end

local function strawberry(parent: Instance, origin: Vector3, s: number, stage: number, tint: Color3)
    for i = 1, 3 do
        local x = (i - 2) * 1.43 * s
        local z = (i % 2 == 0 and 0.68 or -0.56) * s
        local base = origin + Vector3.new(x, 0, z)
        plantBase(parent, base, s, if stage == 3 then 5 else 3)
        local top = base + Vector3.new(0, 1.23 * s, 0)
        stem(parent, "BerryStem", base, top, 0.17 * s, DARK)
        for j = 1, (if stage == 3 then 5 else 3) do
            local a = j * 2.39996 + i * 0.37
            leaf(parent, top + Vector3.new(math.cos(a) * 0.66 * s,
                (j%2)*0.12*s, math.sin(a) * 0.64 * s),
                (if j%3==0 then 1.62 else 1.38) * s, 0.88 * s,
                math.deg(a), if j % 3 == 0 then LEAF_LIT else LEAF)
        end
        if stage >= 2 then
            local r = if stage == 2 then 0.49 else 0.69
            for berryIndex = 1, (if stage == 3 then 2 else 1) do
                local facing = if berryIndex == 1 then -1 else 1
                local fruit = base + Vector3.new(
                    facing * (0.65 + (i%2)*0.13) * s,
                    (if berryIndex == 1 then 0.70 else 0.54) * s,
                    (-0.34 - (berryIndex-1)*0.24) * s)
                stem(parent, "HangingBerry", top,
                    fruit + Vector3.new(0, r * s * 0.46, 0), 0.076 * s, DARK)
                local bright = if i%2==0 then RED else tint
                local fruitShape = piece(parent, "HeartShapedBerry", fruit,
                    Vector3.new(1.05, 1.24, 1.0) * r * s,
                    if stage == 2 then PINK else bright)
                fruitShape.CFrame *= CFrame.Angles(0,math.rad(i*27),math.rad((berryIndex-1)*8))
                -- Five serrated sepals make the strawberry silhouette legible.
                for sepal = 1, 5 do
                    local a = sepal * math.pi * 2 / 5
                    leaf(parent, fruit + Vector3.new(math.cos(a) * .23 * r * s,
                        .68 * r * s, math.sin(a) * .23 * r * s),
                        .69 * r * s, .28 * r * s, math.deg(a), DARK)
                end
                if stage == 3 then littleSeeds(parent, fruit, r * s) end
            end
        end
    end
end

local function stripedMelon(parent: Instance, center: Vector3, scale: number, tint: Color3)
    -- Curved rind bands are sampled against the surface of an ellipsoid.
    -- A segmented painted ribbon reads as a real watermelon from the
    -- three-quarter camera, unlike five vertical sticks floating out front.
    local body = piece(parent, "GardenWatermelon",
        center, Vector3.new(2.7, 2.14, 2.62) * scale, tint)
    body.CastShadow = true
    for stripe = -2, 2 do
        local x = stripe * .37 * scale
        for segment = 1, 3 do
            local yUnit = (segment - 2) * .48
            local xUnit = x / (1.35 * scale)
            local depth = math.sqrt(math.max(.06, 1 - xUnit*xUnit - yUnit*yUnit))
            local z = -1.31 * scale * depth - .035
            local p = piece(parent, "CurvedMelonStripe",
                center + Vector3.new(x, yUnit * 1.07 * scale, z),
                Vector3.new(.19, .49, .08) * scale, DARK)
            p.CFrame *= CFrame.Angles(math.rad((segment - 2) * 34),
                0, math.rad(stripe * 5))
            p.CastShadow = false
        end
    end
    local crown = center + Vector3.new(.17 * scale, 1.04 * scale, .09 * scale)
    for i = 1, 5 do
        local a = i * math.pi * 2 / 5
        leaf(parent, crown + Vector3.new(math.cos(a)*.17*scale, 0,
            math.sin(a)*.17*scale), .70*scale, .28*scale,
            math.deg(a), if i % 2 == 0 then LEAF_LIT else DARK)
    end
    piece(parent, "MelonTail", crown + Vector3.new(0, .19 * scale, 0),
        Vector3.new(.20, .38, .22) * scale, DARK)
end

local function melon(parent: Instance, origin: Vector3, s: number, stage: number, tint: Color3)
    for i = 1, 4 do
        local a = 2.39996 * i
        local start = origin + Vector3.new(math.cos(a) * 0.25 * s, 0, math.sin(a) * 0.25 * s)
        leaf(parent, start + Vector3.new(math.cos(a) * 0.89 * s, 0.2 * s, math.sin(a) * 0.86 * s),
            1.8 * s, 1.23 * s, math.deg(a), if i % 2 == 0 then LEAF_LIT else GREEN)
    end
    if stage >= 2 then
        stripedMelon(parent, origin + Vector3.new(-0.91 * s, 0.92 * s, -0.52 * s),
            (if stage == 2 then 0.59 else 0.9) * s, tint)
        if stage == 3 then
            stripedMelon(parent, origin + Vector3.new(1.18 * s, 0.85 * s, 0.91 * s), 0.68 * s, tint)
            stripedMelon(parent, origin + Vector3.new(0.15 * s, 0.66 * s, 1.18 * s), 0.52 * s, tint)
        end
    end
end

local function carrot(parent: Instance, origin: Vector3, s: number, stage: number)
    for i = 1, 3 do
        local angle = i * 2.39996
        local loc = origin + Vector3.new(math.cos(angle) * 1.14 * s, 0, math.sin(angle) * 1.15 * s)
        local rootHeight = if stage == 1 then 0.34 else if stage == 2 then 0.7 else 1.18
        piece(parent, "CarrotRoot", loc + Vector3.new(0, rootHeight * 0.34 * s, 0),
            Vector3.new(0.84, rootHeight, 0.84) * s, ORANGE)
        for j = 1, 3 do
            local a = j * 2.094
            stem(parent, "CarrotStem", loc + Vector3.new(0, rootHeight * 0.72 * s, 0),
                loc + Vector3.new(math.cos(a) * 0.48 * s, (rootHeight + 0.86) * s, math.sin(a) * 0.48 * s),
                0.12 * s, DARK)
            leaf(parent, loc + Vector3.new(math.cos(a) * 0.6 * s, (rootHeight + 0.84) * s, math.sin(a) * 0.6 * s),
                0.92 * s, 0.5 * s, math.deg(a), GREEN)
        end
    end
end

local function grain(parent: Instance, origin: Vector3, s: number, stage: number, kind: string, tint: Color3)
    for i = 1, 4 do
        local a = i * 2.39996
        local pos = origin + Vector3.new(math.cos(a) * 1.23 * s, 0, math.sin(a) * 1.23 * s)
        local h = (if stage == 1 then 0.95 elseif stage == 2 then 1.65 else 2.65) * s
        stem(parent, "WheatStalk", pos, pos + Vector3.new(0, h, 0), 0.13 * s, DARK)
        leaf(parent, pos + Vector3.new(0.35 * s, h * 0.35, 0), 1.16 * s, 0.46 * s, 15, GREEN)
        if stage >= 2 then
            if kind == "Corn" then
                piece(parent, "CornCob", pos + Vector3.new(0.12 * s, h * 0.73, -0.12 * s),
                    Vector3.new(0.82, 1.45, 0.79) * s, tint)
                leaf(parent, pos + Vector3.new(0.6 * s, h * 0.48, 0), 1.16 * s, 0.5 * s, 40, GREEN)
            else
                -- A tapered wheat ear: paired small spikelets, directional
                -- long awns and a visible straw-colored spike. This avoids
                -- the old three round yellow beads perched on each stalk.
                local golden = if kind == "WhisperWheat" then STRAW else tint
                local tipY = h * .94
                for j = 1, 4 do
                    local y = tipY + j * .24 * s
                    local width = (.21 - j * .025) * s
                    for side = -1, 1, 2 do
                        local grain = piece(parent, "WheatSpikelet",
                            pos + Vector3.new(side * width * .55, y,
                                side * .06 * s),
                            Vector3.new(.25, .41, .26) * s, golden)
                        grain.CFrame *= CFrame.Angles(0, 0,
                            math.rad(side * (16 + j * 5)))
                    end
                end
                for awn = -1, 1, 2 do
                    leaf(parent, pos + Vector3.new(awn * .24 * s,
                        tipY + 1.04 * s, 0),
                        .65 * s, .13 * s, awn * 19, golden)
                end
            end
        end
    end
end

local function bushFruit(parent: Instance, origin: Vector3, s: number, stage: number,
    kind: string, tint: Color3)
    for i = 1, 3 do
        local a = i * 2.39996
        local p = origin + Vector3.new(math.cos(a) * 0.85 * s, 0, math.sin(a) * 0.79 * s)
        local tip = p + Vector3.new(0, 1.66 * s, 0)
        stem(parent, "BushStem", p, tip, 0.19 * s, DARK)
        plantBase(parent, p + Vector3.new(0, 0.84 * s, 0), s, 4)
        if stage >= 2 then
            for j = 1, 2 do
                local off = if j == 1 then -0.6 else 0.65
                local fruit = tip + Vector3.new(off * s, -0.58 * s, -0.31 * s)
                if kind == "Pepper" then
                    piece(parent, "HangingPepper", fruit, Vector3.new(0.61, 1.35, 0.57) * s, tint)
                elseif kind == "GummyGrape" or kind == "Jellybean" then
                    piece(parent, "FruitBunch", fruit, Vector3.new(0.79, 0.96, 0.75) * s, tint)
                else
                    piece(parent, "RipeTomato", fruit, Vector3.new(0.92, 0.91, 0.90) * s, tint)
                end
                leaf(parent, fruit + Vector3.new(0, 0.48 * s, 0), 0.65 * s, 0.42 * s, j * 68, DARK)
            end
        end
    end
end

local function flowering(parent: Instance, origin: Vector3, s: number,
    stage: number, kind: string, tint: Color3)
    local count = if stage == 3 then 3 else 2
    for i = 1, count do
        local a = i * 2.39996
        local base = origin + Vector3.new(math.cos(a) * 1.18 * s, 0, math.sin(a) * 1.15 * s)
        local h = (if stage == 1 then 0.83 elseif stage == 2 then 1.55 else 2.5) * s
        local top = base + Vector3.new(0, h, 0)
        stem(parent, "FlowerStem", base, top, 0.2 * s, DARK)
        leaf(parent, base + Vector3.new(0.39 * s, h * 0.46, 0), 1.32 * s, 0.66 * s, 25, GREEN)
        if stage >= 2 then
            local petalTint = if kind == "Sunflower" then STRAW else tint
            local r = (if stage == 2 then 0.5 else 0.72) * s
            for j = 1, 6 do
                local petalAngle = j * math.pi / 3
                local p = piece(parent, "FlowerPetal",
                    top + Vector3.new(math.cos(petalAngle) * 0.66 * r, math.sin(petalAngle) * 0.65 * r, -0.18 * r),
                    Vector3.new(0.86, 0.62, 0.25) * r, petalTint)
                p.CFrame *= CFrame.Angles(0, 0, petalAngle)
            end
            piece(parent, "FlowerHeart", top + Vector3.new(0, 0, -0.37 * r),
                Vector3.new(0.82, 0.82, 0.34) * r, if kind == "Sunflower" then EARTH else CREAM)
        end
    end
end

local function mushrooms(parent: Instance, origin: Vector3, s: number, stage: number, tint: Color3)
    for i = 1, 3 do
        local a = i * 2.39996
        local pos = origin + Vector3.new(math.cos(a) * 1.10 * s, 0, math.sin(a) * 1.15 * s)
        local h = (if stage == 1 then 0.35 elseif stage == 2 then 0.75 else 1.20) * s
        stem(parent, "MushroomStalk", pos, pos + Vector3.new(0, h, 0), 0.38 * s, CREAM)
        if stage >= 2 then
            local top = pos + Vector3.new(0, h, 0)
            piece(parent, "VelvetMushroomCap", top, Vector3.new(1.60, 0.70, 1.55) * s, tint)
            for j = 1, 3 do
                local b = j * 2.094
                piece(parent, "MushroomDot", top + Vector3.new(math.cos(b) * 0.39 * s, 0.36 * s, math.sin(b) * 0.3 * s),
                    Vector3.new(0.19, 0.13, 0.19) * s, CREAM)
            end
        end
    end
end

local function fantasy(parent: Instance, origin: Vector3, s: number, stage: number, kind: string, tint: Color3)
    -- Explicitly non-real-world crops retain a playful, legible silhouette.
    local tall = (if stage == 1 then 0.95 elseif stage == 2 then 1.65 else 2.50) * s
    for i = 1, 3 do
        local a = i * 2.39996
        local base = origin + Vector3.new(math.cos(a) * 1.12 * s, 0, math.sin(a) * 1.12 * s)
        local tip = base + Vector3.new(0, tall, 0)
        stem(parent, "FantasyCropStem", base, tip, 0.20 * s, DARK)
        plantBase(parent, base + Vector3.new(0, tall * 0.43, 0), s, 3)
        if stage >= 2 then
            if kind == "JellyCactus" or kind == "CrystalMint" or kind == "BubbleCabbage" then
                piece(parent, "FantasySucculent", tip, Vector3.new(1.12, 1.32, 1.07) * s, tint)
                leaf(parent, tip + Vector3.new(0, 0.58 * s, 0), 0.86 * s, 0.7 * s, i * 31, LEAF_LIT)
            else
                piece(parent, "FantasyFruit", tip, Vector3.new(1.16, 1.11, 1.08) * s, tint)
                piece(parent, "FantasyFruitGlint", tip + Vector3.new(-0.24 * s, 0.3 * s, -0.48 * s),
                    Vector3.new(0.22, 0.34, 0.11) * s, CREAM)
            end
        end
    end
end

function CropArt.draw(parent: Instance, center: Vector3,
    seedType: string, stage: number, color: Color3)
    if stage < 1 then return end
    local s = if stage == 1 then 0.54 elseif stage == 2 then 0.78 else 0.94
    local origin = center + Vector3.new(0, 0.72, 0)

    if seedType == "Berry" or seedType == "FrostBerry" then
        strawberry(parent, origin, s, stage, if seedType == "Berry" then RED else color)
    elseif seedType == "LavaMelon" or seedType == "AuroraMelon" then
        melon(parent, origin, s, stage, if seedType == "LavaMelon" then Color3.fromRGB(150, 189, 91) else color)
    elseif seedType == "Carrot" or seedType == "RainbowRadish" or seedType == "MarshmallowRoot" then
        carrot(parent, origin, s, stage)
    elseif seedType == "Corn" or seedType == "WhisperWheat" or seedType == "StardustRice" or seedType == "CandyCane" then
        grain(parent, origin, s, stage, seedType, color)
    elseif seedType == "Tomato" or seedType == "Pepper" or seedType == "GummyGrape" or seedType == "Jellybean" then
        bushFruit(parent, origin, s, stage, seedType, color)
    elseif seedType == "Sunflower" or seedType == "MoonLotus" or seedType == "Starbloom" or seedType == "CloudCotton" then
        flowering(parent, origin, s, stage, seedType, color)
    elseif seedType == "Moonshroom" or seedType == "NeonMushroom" then
        mushrooms(parent, origin, s, stage, color)
    else
        fantasy(parent, origin, s, stage, seedType, color)
    end
end

return CropArt
