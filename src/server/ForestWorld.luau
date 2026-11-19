--!strict
-- Three original 3D expeditions, with real ProximityPrompts and fixed locations.
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local X = require(ReplicatedStorage:WaitForChild("ExpeditionConfig"))
local ForestWorld = {}
local zoneFolder: Folder?
local pollen: {BasePart} = {}

local function shape(parent: Instance, name: string, pos: Vector3, size: Vector3, tint: Color3, material: Enum.Material?, ball: boolean?): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Position = pos
    p.Size = size
    p.Shape = if ball then Enum.PartType.Ball else Enum.PartType.Block
    p.Color = tint
    p.Material = material or Enum.Material.SmoothPlastic
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.Parent = parent
    return p
end

local function sign(parent: Instance, anchor: BasePart, caption: string, width: number)
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = anchor
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(width, 65)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
    billboard.MaxDistance = 135
    billboard.Parent = parent
    local t = Instance.new("TextLabel")
    t.Size = UDim2.fromScale(1, 1)
    t.Text = caption
    t.TextWrapped = true
    t.TextScaled = true
    t.TextColor3 = Color3.fromRGB(78, 65, 97)
    t.BackgroundColor3 = Color3.fromRGB(255, 249, 224)
    t.BackgroundTransparency = 0.22
    t.Font = Enum.Font.GothamBlack
    t.Parent = billboard
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 14)
    c.Parent = t
end

local function decorate(parent: Instance, zoneId: string, center: Vector3, color: Color3)
    local rng = Random.new(5539 + #zoneId * 37)
    local gate = shape(parent, "TrailHead", center + Vector3.new(0, 0.15, 0), Vector3.new(12, 0.35, 12), Color3.fromRGB(225, 191, 149), Enum.Material.Sand)
    sign(parent, gate, X.Zones[zoneId].icon .. " " .. X.Zones[zoneId].name, 285)
    for i = 1, 9 do
        local angle = i * 2.399
        local r = rng:NextNumber(12, 26)
        local p = center + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
        if Vector3.new(p.X,0,p.Z).Magnitude < 108 then
            shape(parent, "StorybookTreeTrunk", p + Vector3.new(0, 2.5, 0), Vector3.new(1.5, 5, 1.5), Color3.fromRGB(166, 123, 94), Enum.Material.Wood)
            for leaf = 1, 4 do
                local a = leaf * math.pi * 0.5
                shape(parent, "RoundedTreeCrown", p + Vector3.new(math.cos(a) * 2.5, 6.7 + math.sin(a), math.sin(a) * 2.5), Vector3.new(5.2, 4.6, 5.2), color, Enum.Material.Grass, true)
            end
            if zoneId == "Marsh" then
                shape(parent, "MoonMushroom", p + Vector3.new(2.8, 1.3, 0), Vector3.new(2.2, 1.2, 2.2), Color3.fromRGB(166, 197, 255), Enum.Material.Neon, true)
            elseif zoneId == "Ruins" then
                local stone = shape(parent, "ForgottenStone", p + Vector3.new(-3.6, 1.8, 0), Vector3.new(2.2, 3.6, 2.2), Color3.fromRGB(193, 175, 185), Enum.Material.Slate)
                stone.Orientation = Vector3.new(0, i * 26, i % 3 * 7)
            else
                shape(parent, "HoneyBlossom", p + Vector3.new(2.5, 0.9, 0), Vector3.new(1.9, 1.5, 1.9), Color3.fromRGB(255, 238, 156), Enum.Material.Neon, true)
            end
        end
    end
    -- Storybook floor details: petal trails and little stone footsteps guide
    -- explorers toward the seed caches without adding any invisible barriers.
    for i = 1, 18 do
        local a = i * 2.399963
        local distance = 5 + (i % 6) * 2.5
        local spot = center + Vector3.new(math.cos(a) * distance, 0.28, math.sin(a) * distance)
        if i % 3 == 0 then
            local stone = shape(parent, "MossySteppingStone", spot, Vector3.new(2.4, 0.42, 1.7),
                Color3.fromRGB(211, 202, 180), Enum.Material.Slate, true)
            stone.Orientation = Vector3.new(0, i * 27, 0)
        else
            local flower = shape(parent, "StorybookFlower", spot + Vector3.new(0, 0.32, 0),
                Vector3.new(0.78, 0.72, 0.78),
                if i % 2 == 0 then Color3.fromRGB(255, 229, 188) else Color3.fromRGB(255, 195, 221),
                Enum.Material.SmoothPlastic, true)
            flower.CanQuery = false
            shape(parent, "FlowerCenter", spot + Vector3.new(0, 0.65, 0),
                Vector3.new(0.34, 0.26, 0.34), Color3.fromRGB(255, 235, 141), Enum.Material.SmoothPlastic, true)
        end
    end
    for i = 1, 5 do
        local a = i * 2.4
        local spot = center + Vector3.new(math.cos(a) * 11, 10 + i % 3, math.sin(a) * 11)
        local orb = shape(parent, "FloatingPollen", spot, Vector3.new(1.2, 1.2, 1.2), color, Enum.Material.Neon, true)
        orb.Transparency = 0.36
        table.insert(pollen, orb)
    end
end

function ForestWorld.build(parent: Instance, onGather: (Player, string) -> ())
    if zoneFolder then zoneFolder:Destroy() end
    zoneFolder = Instance.new("Folder")
    zoneFolder.Name = "SeedHuntingForest"
    zoneFolder.Parent = parent
    table.clear(pollen)
    local centers = {
        Meadow = Vector3.new(-86, 7.6, -21),
        Marsh = Vector3.new(88, 7.6, -13),
        Ruins = Vector3.new(0, 7.6, -89),
    }
    for _, zoneId in ipairs(X.ZoneOrder) do
        local zone = X.Zones[zoneId]
        local area = Instance.new("Folder")
        area.Name = zone.name
        area.Parent = zoneFolder
        decorate(area, zoneId, centers[zoneId], zone.color)
        for _, node in ipairs(zone.nodes) do
            local base = Vector3.new(node.x, 8.7, node.z)
            shape(area, "WarmWoodStump", base, Vector3.new(4.3, 1.1, 4.3), Color3.fromRGB(168, 115, 91), Enum.Material.Wood, true)
            local seed = shape(area, "SeedCache_" .. node.id, base + Vector3.new(0, 2.9, 0), Vector3.new(2.3, 2.5, 2.3), zone.color, Enum.Material.Neon, true)
            seed.Transparency = 0.07
            local prompt = Instance.new("ProximityPrompt")
            prompt.Name = "SearchSeeds"
            prompt.ObjectText = node.label
            prompt.ActionText = "FIND SEEDS"
            prompt.HoldDuration = 1.1
            prompt.KeyboardKeyCode = Enum.KeyCode.E
            prompt.MaxActivationDistance = 12
            prompt.RequiresLineOfSight = false
            prompt.Parent = seed
            prompt.Triggered:Connect(function(player: Player) onGather(player, node.id) end)
            sign(area, seed, "🌱 " .. node.label, 170)
            -- Visible petals around the seed pod make the objective recognizable
            -- even when billboard labels are too small on a phone.
            for petal = 1, 5 do
                local angle = petal * math.pi * 2 / 5
                local tip = base + Vector3.new(math.cos(angle) * 1.5, 2.45, math.sin(angle) * 1.5)
                local leaf = shape(area, "SeedPodPetal", tip, Vector3.new(1.1, 0.36, 1.7),
                    Color3.fromRGB(179, 239, 175), Enum.Material.SmoothPlastic, true)
                leaf.Orientation = Vector3.new(0, math.deg(angle), -16)
            end
            for k = 1, 3 do
                local angle = k / 3 * math.pi * 2
                shape(area, "LeafCluster", base + Vector3.new(math.cos(angle) * 2.2, 1.5, math.sin(angle) * 2.2), Vector3.new(1.6, 0.8, 1.6), Color3.fromRGB(113, 203, 137), nil, true)
            end
        end
    end
end

function ForestWorld.weather(weather: string)
    local entry = X.Weather[weather]
    if not entry then return end
    local effect = Lighting:FindFirstChild("ExpeditionWeatherTint")
    if not effect then
        effect = Instance.new("ColorCorrectionEffect")
        effect.Name = "ExpeditionWeatherTint"
        effect.Parent = Lighting
    end
    TweenService:Create(effect :: ColorCorrectionEffect, TweenInfo.new(2.6), {
        TintColor = entry.color,
        Contrast = if weather == "GiggleStorm" then 0.055 else 0.01,
        Saturation = if weather == "MoonFog" then -0.1 else 0.015,
    }):Play()
    for _, spot in ipairs(pollen) do
        if spot.Parent then
            TweenService:Create(spot, TweenInfo.new(1.1), {Color = entry.color, Transparency = if weather == "MoonFog" then 0.08 else 0.4}):Play()
        end
    end
end

function ForestWorld.festival()
    for _, spot in ipairs(pollen) do
        if spot.Parent then
            TweenService:Create(spot, TweenInfo.new(0.8, Enum.EasingStyle.Back), {Size = Vector3.new(3, 3, 3), Color = Color3.fromRGB(255, 226, 137)}):Play()
            task.delay(2.5, function()
                if spot.Parent then TweenService:Create(spot, TweenInfo.new(0.9), {Size = Vector3.new(1.2, 1.2, 1.2)}):Play() end
            end)
        end
    end
end

return ForestWorld
