--!strict
-- Tactile, warm farm feedback for actual server-approved crop interactions.
-- Original geometry: painted leaves, petals and a restrained dust puff.
-- No neon spheres, marketplace assets, or hard collisions.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local GardenFX = {}
local FOLIAGE = Color3.fromRGB(94, 156, 88)
local FOLIAGE_LIT = Color3.fromRGB(183, 205, 118)
local PALE_FLOWER = Color3.fromRGB(255, 244, 212)
local SOIL = Color3.fromRGB(179, 133, 97)
local lifetime = 1.35

local function shard(parent: Instance, at: Vector3, tint: Color3,
    size: Vector3, direction: Vector3, spin: number)
    local p = Instance.new("WedgePart")
    p.Name = "GardenLeafConfetti"
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Material = Enum.Material.SmoothPlastic
    p.Size = size
    p.Color = tint
    p.Transparency = 0.07
    p.CFrame = CFrame.new(at) * CFrame.Angles(0, spin, -0.19)
    p.Parent = parent
    TweenService:Create(p, TweenInfo.new(lifetime, Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out), {
        CFrame = CFrame.new(at + direction) * CFrame.Angles(
            math.rad(95), spin + math.rad(190), math.rad(28)),
        Transparency = 1,
        Size = Vector3.new(size.X * 0.38, size.Y, size.Z * 0.46),
    }):Play()
    Debris:AddItem(p, lifetime + 0.15)
end

function GardenFX.play(parent: Instance, position: Vector3,
    isHarvest: boolean, fruitColor: Color3?)
    local total = if isHarvest then 13 else 8
    local color = fruitColor or FOLIAGE
    for i = 1, total do
        local angle = (i / total) * math.pi * 2 + (i % 3) * 0.12
        local radius = if isHarvest then 2.7 else 1.45
        local lift = if isHarvest then 2.5 else 1.3
        local tint = if i % 5 == 0 then PALE_FLOWER
            elseif i % 3 == 0 then FOLIAGE_LIT
            elseif i % 2 == 0 then FOLIAGE
            elseif isHarvest then color else SOIL
        local start = position + Vector3.new(
            math.cos(angle) * 0.36, 0.34 + (i % 3) * 0.11,
            math.sin(angle) * 0.36)
        local movement = Vector3.new(
            math.cos(angle) * radius, lift + (i % 3) * 0.25,
            math.sin(angle) * radius)
        shard(parent, start, tint,
            Vector3.new(0.31 + (i % 3) * 0.07, 0.045, 0.61),
            movement, angle)
    end
end

return GardenFX
