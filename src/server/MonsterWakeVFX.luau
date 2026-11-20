--!strict
-- Original Roblox Studio VFX for the monster's wake-up moment.
-- Uses native ParticleEmitters, curved Beams, Lighting, TweenService and Debris.
-- No externally uploaded textures or paid marketplace assets required.
-- This is a genuine runtime effect; quality must still be evaluated in Studio.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")

local VFX = {}
local TAU = math.pi * 2
local BLUSH = Color3.fromRGB(255, 166, 185)
local APRICOT = Color3.fromRGB(255, 215, 161)
local WISTERIA = Color3.fromRGB(171, 144, 230)
local LILAC = Color3.fromRGB(220, 190, 255)

local function hiddenAnchor(parent: Instance, position: Vector3): Part
    local p = Instance.new("Part")
    p.Name = "WakeFX_Anchor"
    p.Size = Vector3.new(0.2, 0.2, 0.2)
    p.CFrame = CFrame.new(position)
    p.Anchored = true
    p.Transparency = 1
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Parent = parent
    return p
end

local function ease(duration: number, target: Instance, properties: {[string]: any})
    TweenService:Create(target, TweenInfo.new(duration, Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out), properties):Play()
end

local function motes(parent: Instance, position: Vector3, count: number,
    tint: Color3, upward: boolean)
    local p = hiddenAnchor(parent, position)
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "WakeFX_Stardust"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, APRICOT),
        ColorSequenceKeypoint.new(0.4, tint),
        ColorSequenceKeypoint.new(1, LILAC),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.25),
        NumberSequenceKeypoint.new(0.25, 0.05),
        NumberSequenceKeypoint.new(0.75, 0.40),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.22),
        NumberSequenceKeypoint.new(0.25, 1.2),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Speed = NumberRange.new(12, 30)
    emitter.Drag = 2.8
    emitter.Rate = 0
    emitter.Lifetime = NumberRange.new(0.75, 1.5)
    emitter.Rotation = NumberRange.new(0, 360)
    emitter.RotSpeed = NumberRange.new(-100, 100)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Acceleration = if upward then Vector3.new(0, 19, 0)
        else Vector3.new(0, 2, 0)
    emitter.LightEmission = 0.45
    emitter.ZOffset = 0
    emitter.Parent = p
    emitter:Emit(count)
    Debris:AddItem(p, 3.3)
end

local function lightBloom(parent: Instance, position: Vector3, color: Color3)
    local source = hiddenAnchor(parent, position)
    local light = Instance.new("PointLight")
    light.Name = "WakeFX_Light"
    light.Color = color
    light.Shadows = false
    light.Range = 48
    light.Brightness = 0
    light.Parent = source
    ease(0.23, light, {Brightness = 2.8, Range = 75})
    task.delay(0.32, function()
        if light.Parent then ease(0.8, light, {Brightness = 0, Range = 20}) end
    end)
    Debris:AddItem(source, 1.8)
end

local function ribbon(parent: Instance, center: Vector3, angle: number,
    radius: number, length: number, height: number, color: Color3, index: number)
    local p = hiddenAnchor(parent, center)
    local a = Instance.new("Attachment")
    a.Name = "WakeFX_RibbonBegin"
    a.Position = Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
    a.Parent = p
    local b = Instance.new("Attachment")
    b.Name = "WakeFX_RibbonEnd"
    b.Position = Vector3.new(math.cos(angle + length) * radius,
        height + 2 + (index % 3) * 1.6, math.sin(angle + length) * radius)
    b.Parent = p
    local beam = Instance.new("Beam")
    beam.Name = "WakeFX_CurvedEnergyRibbon"
    beam.Attachment0 = a
    beam.Attachment1 = b
    beam.FaceCamera = true
    beam.LightEmission = 0.42
    beam.LightInfluence = 0
    beam.Segments = 14
    beam.CurveSize0 = 10 + (index % 3) * 4
    beam.CurveSize1 = -9
    beam.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, APRICOT),
        ColorSequenceKeypoint.new(0.48, color),
        ColorSequenceKeypoint.new(1, WISTERIA),
    })
    beam.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.08, 0.22),
        NumberSequenceKeypoint.new(0.5, 0.08),
        NumberSequenceKeypoint.new(0.92, 0.28),
        NumberSequenceKeypoint.new(1, 1),
    })
    beam.Width0 = 0.15
    beam.Width1 = 0.12
    beam.Parent = p
    ease(0.65, beam, {Width0 = 2.0, Width1 = 1.6})
    task.delay(0.67, function()
        if beam.Parent then
            ease(0.80, beam, {Width0 = 0, Width1 = 0})
        end
    end)
    Debris:AddItem(p, 1.65)
end

function VFX.groundPulse(parent: Instance, center: Vector3, radius: number)
    -- Expanding ring of softly glowing petal wisps. Beam count deliberately
    -- capped, all anchored/no collisions, auto-deleted for mobile.
    local count = 14
    for i = 1, count do
        local a = i * TAU / count
        local part = hiddenAnchor(parent, center + Vector3.new(math.cos(a)*3, 0, math.sin(a)*3))
        part.Name = "WakeFX_RingPetal"
        part.Shape = Enum.PartType.Ball
        part.Size = Vector3.new(3.7, 0.18, 2.6)
        part.Transparency = 0.45
        part.Material = Enum.Material.Neon
        part.Color = if i % 2 == 0 then APRICOT else BLUSH
        part.CFrame *= CFrame.Angles(0, a, 0)
        ease(1.10, part, {
            Position = center + Vector3.new(math.cos(a)*radius, 0, math.sin(a)*radius),
            Size = Vector3.new(6, 0.12, 4),
            Transparency = 1,
        })
        Debris:AddItem(part, 1.25)
    end
end

function VFX.wake(parent: Instance, center: Vector3)
    motes(parent, center + Vector3.new(0, 20, 0), 84, BLUSH, true)
    lightBloom(parent, center + Vector3.new(0, 29, 0), LILAC)
    for i = 1, 12 do
        local angle = i * TAU / 12
        ribbon(parent, center + Vector3.new(0, 6, 0), angle,
            19 + i % 4 * 3, 0.65, 4 + i % 3 * 2, BLUSH, i)
    end
    -- Second quieter pulse makes the change of phase legible without
    -- a full-screen flash or aggressive strobing.
    task.delay(0.38, function()
        if parent.Parent then
            motes(parent, center + Vector3.new(0, 8, 0), 38, WISTERIA, false)
        end
    end)
end

return VFX
