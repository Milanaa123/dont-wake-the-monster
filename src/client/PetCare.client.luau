--!strict
-- Pet care: tap to pick up and HOLD to stroke (touch, mouse, R key).
-- Holding input generates keepalive heartbeats; the server controls all noise and effects.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("MonsterRemote") :: RemoteEvent

local INK = Color3.fromRGB(70, 48, 92)
local WHITE = Color3.fromRGB(255, 251, 241)
local PINK = Color3.fromRGB(255, 177, 202)
local GREEN = Color3.fromRGB(191, 243, 186)
local PURPLE = Color3.fromRGB(213, 186, 255)

local function corner(target: Instance, radius: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = target
end
local function border(target: Instance, color: Color3)
    local s = Instance.new("UIStroke")
    s.Thickness = 2
    s.Color = color
    s.Transparency = 0.25
    s.Parent = target
end
local function text(parent: Instance, caption: string, height: number, size: number, bold: boolean): TextLabel
    local label = Instance.new("TextLabel")
    label.Name = "CareLabel"
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -12, 0, height)
    label.Font = if bold then Enum.Font.GothamBlack else Enum.Font.GothamMedium
    label.Text = caption
    label.TextSize = size
    label.TextColor3 = INK
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Parent = parent
    return label
end
local function button(parent: Instance, caption: string, tint: Color3): TextButton
    local b = Instance.new("TextButton")
    b.Text = caption
    b.TextScaled = true
    b.Font = Enum.Font.GothamBlack
    b.TextColor3 = INK
    b.AutoButtonColor = true
    b.BackgroundColor3 = tint
    b.BorderSizePixel = 0
    b.Parent = parent
    corner(b, 12)
    local limit = Instance.new("UITextSizeConstraint")
    limit.MaxTextSize = 16
    limit.MinTextSize = 11
    limit.Parent = b
    return b
end

local gui = Instance.new("ScreenGui")
gui.Name = "PetCareControls"
gui.ResetOnSpawn = false
gui.DisplayOrder = 8
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.Name = "CarePanel"
card.AnchorPoint = Vector2.new(1, 1)
card.Position = UDim2.new(1, -12, 1, -244)
card.Size = UDim2.fromOffset(174, 154)
card.BackgroundColor3 = WHITE
card.BackgroundTransparency = 0.045
card.BorderSizePixel = 0
card.Parent = gui
corner(card, 18)
border(card, Color3.fromRGB(228, 196, 255))

local heading = text(card, "🐾 CUDDLE CORNER", 24, 13, true)
heading.Position = UDim2.fromOffset(6, 4)
local carry = button(card, "🤲 PICK UP", GREEN)
carry.Name = "Carry"
carry.Position = UDim2.fromOffset(8, 32)
carry.Size = UDim2.new(1, -16, 0, 39)
local stroke = button(card, "💗 HOLD TO PET", PINK)
stroke.Name = "PetHold"
stroke.Position = UDim2.fromOffset(8, 77)
stroke.Size = UDim2.new(1, -16, 0, 39)

local meter = Instance.new("Frame")
meter.Name = "PurrMeterBack"
meter.Position = UDim2.fromOffset(9, 126)
meter.Size = UDim2.new(1, -18, 0, 14)
meter.BackgroundColor3 = Color3.fromRGB(235, 229, 240)
meter.BorderSizePixel = 0
meter.Parent = card
corner(meter, 7)
local fill = Instance.new("Frame")
fill.Name = "PurrFill"
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = PURPLE
fill.BorderSizePixel = 0
fill.Parent = meter
corner(fill, 7)

local meterText = text(card, "Hold longer • surprise inside!", 15, 10, false)
meterText.Position = UDim2.fromOffset(6, 139)
local state = {carrying = false, petting = false, purr = 0, cat = false}
local held = false
local activeTouch: InputObject? = nil

local function start()
    if held then return end
    held = true
    remote:FireServer("StartPetting")
    stroke.BackgroundColor3 = Color3.fromRGB(255, 117, 165)
    stroke.Text = "💞 STROKING... RELEASE"
end
local function stop()
    if not held then return end
    held = false
    activeTouch = nil
    remote:FireServer("StopPetting")
    stroke.BackgroundColor3 = PINK
    stroke.Text = "💗 HOLD TO PET"
end

stroke.InputBegan:Connect(function(input: InputObject)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        if input.UserInputType == Enum.UserInputType.Touch then activeTouch = input end
        start()
    end
end)
stroke.InputEnded:Connect(function(input: InputObject)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input == activeTouch then stop() end
end)
UserInputService.InputEnded:Connect(function(input: InputObject)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input == activeTouch or input.KeyCode == Enum.KeyCode.R then
        stop()
    end
end)
UserInputService.WindowFocusReleased:Connect(stop)
UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
    if not processed and input.KeyCode == Enum.KeyCode.R then start() end
    if not processed and input.KeyCode == Enum.KeyCode.C then remote:FireServer("ToggleCarry") end
end)

carry.MouseButton1Click:Connect(function() remote:FireServer("ToggleCarry") end)

remote.OnClientEvent:Connect(function(payload: any)
    if typeof(payload) ~= "table" or payload.type ~= "petCare" then return end
    state = payload
    carry.Text = if state.carrying then "👐 PUT DOWN" else "🤲 PICK UP"
    carry.BackgroundColor3 = if state.carrying then PURPLE else GREEN
    local purr = math.clamp(payload.purr or 0, 0, 1)
    TweenService:Create(fill, TweenInfo.new(0.32), {Size = UDim2.fromScale(purr, 1)}):Play()
    if state.cat and purr > 0.015 then
        meterText.Text = if purr > 0.74 then "🚨 TOO LOUD! SHHH!" else string.format("😻 PURRR...  %d%%", math.floor(purr * 100))
        fill.BackgroundColor3 = if purr > 0.74 then Color3.fromRGB(255, 113, 113) else PINK
    else
        meterText.Text = if state.cat then "💤 Stroking may wake Giggles!" else "💕 Your pet loves attention!"
        fill.BackgroundColor3 = PURPLE
    end
    if not state.petting and held then
        -- The server can cancel a hold on a sudden cat reaction or boss wake.
        -- Don't keep painting the hold UI as active.
        held = false
        activeTouch = nil
        stroke.BackgroundColor3 = PINK
        stroke.Text = "💗 HOLD TO PET"
    end
end)

-- Keepalives are deliberately slow and checked by the server. An abandoned
-- button press cannot generate infinite purr/noise on an unattended session.
task.spawn(function()
    while gui.Parent do
        task.wait(1.4)
        if held then remote:FireServer("PettingPulse") end
    end
end)
