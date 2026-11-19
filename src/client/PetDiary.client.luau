--!strict
-- Mobile-first pet diary. All values are reported by the server; no client stats can be edited.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("MonsterRemote") :: RemoteEvent
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local WHITE = Color3.fromRGB(255, 251, 245)
local DARK = Color3.fromRGB(67, 50, 94)
local PINK = Color3.fromRGB(255, 202, 222)
local LILAC = Color3.fromRGB(223, 204, 255)
local MINT = Color3.fromRGB(204, 241, 209)
local currentCollection: any = nil
local currentStats: any = nil

local function corner(target: Instance, radius: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = target
end
local function text(parent: Instance, title: string, size: number, position: UDim2, height: number, bold: boolean?): TextLabel
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Position = position
    l.Size = UDim2.new(1, -28, 0, height)
    l.Text = title
    l.TextColor3 = DARK
    l.TextSize = size
    l.Font = if bold then Enum.Font.GothamBlack else Enum.Font.GothamMedium
    l.TextWrapped = true
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end
local function button(parent: Instance, name: string, caption: string, background: Color3): TextButton
    local b = Instance.new("TextButton")
    b.Name = name
    b.Text = caption
    b.Font = Enum.Font.GothamBlack
    b.TextColor3 = DARK
    b.TextScaled = true
    b.BackgroundColor3 = background
    b.BorderSizePixel = 0
    b.Parent = parent
    corner(b, 12)
    local limit = Instance.new("UITextSizeConstraint")
    limit.MinTextSize = 10
    limit.MaxTextSize = 17
    limit.Parent = b
    return b
end

local gui = Instance.new("ScreenGui")
gui.Name = "PetDiary"
gui.ResetOnSpawn = false
gui.DisplayOrder = 11
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
local open = button(gui, "OpenDiary", "💗 PET DIARY", PINK)
open.AnchorPoint = Vector2.new(1, 0)
open.Position = UDim2.new(1, -12, 0, 241)
open.Size = UDim2.fromOffset(152, 43)

local backdrop = Instance.new("Frame")
backdrop.Name = "DiaryBackdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(32, 25, 52)
backdrop.BackgroundTransparency = 0.32
backdrop.BorderSizePixel = 0
backdrop.Active = true
backdrop.Visible = false
backdrop.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "DiaryPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.94, 0, 0.85, 0)
panel.BackgroundColor3 = WHITE
panel.BorderSizePixel = 0
panel.Parent = backdrop
corner(panel, 20)
local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MaxSize = Vector2.new(510, 700)
sizeLimit.MinSize = Vector2.new(260, 300)
sizeLimit.Parent = panel

local title = text(panel, "💗 MY PET'S SECRET DIARY", 19, UDim2.fromOffset(14, 10), 35, true)
title.TextScaled = true
local sizeGuard = Instance.new("UITextSizeConstraint")
sizeGuard.MinTextSize = 12
sizeGuard.MaxTextSize = 19
sizeGuard.Parent = title

local close = button(panel, "Close", "✕", PINK)
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -12, 0, 10)
close.Size = UDim2.fromOffset(40, 37)
local hint = text(panel, "Every creature is a unique individual 💖", 12, UDim2.fromOffset(15, 50), 30)

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "DiaryContents"
scroll.Position = UDim2.new(0, 12, 0, 87)
scroll.Size = UDim2.new(1, -24, 1, -176)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.CanvasSize = UDim2.fromScale(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.ScrollBarThickness = 5
scroll.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll
local pad = Instance.new("UIPadding")
pad.PaddingBottom = UDim.new(0, 12)
pad.Parent = scroll

local actionBar = Instance.new("Frame")
actionBar.Name = "FriendshipActions"
actionBar.BackgroundTransparency = 1
actionBar.Position = UDim2.new(0, 12, 1, -78)
actionBar.Size = UDim2.new(1, -24, 0, 66)
actionBar.Parent = panel
local actions = {
    {key = "Pet", label = "🤲 PET", color = PINK},
    {key = "Play", label = "🎾 PLAY", color = MINT},
    {key = "Comfort", label = "🫂 SOOTHE", color = LILAC},
}
for index, item in ipairs(actions) do
    local b = button(actionBar, item.key, item.label, item.color)
    b.Size = UDim2.new(1 / 3, -7, 0, 44)
    b.Position = UDim2.new((index - 1) / 3, 5, 0, 0)
    b.MouseButton1Click:Connect(function()
        remote:FireServer("PetInteract", item.key)
    end)
end

local feedback = text(actionBar, "Get close to your pet before interacting!", 11, UDim2.new(0, 6, 0, 45), 20)
feedback.Size = UDim2.new(1, -12, 0, 20)
feedback.TextXAlignment = Enum.TextXAlignment.Center

local function panelRow(height: number, color: Color3): Frame
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = color
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, -6, 0, height)
    frame.Parent = scroll
    corner(frame, 13)
    return frame
end

local function indicator(parent: Instance, index: number, label: string, value: number, color: Color3)
    local base = text(parent, label .. "  " .. value .. "%", 12, UDim2.new(0, 9, 0, index * 33 + 3), 21, true)
    base.Size = UDim2.new(1, -18, 0, 20)
    local track = Instance.new("Frame")
    track.Position = UDim2.new(0, 9, 0, index * 33 + 24)
    track.Size = UDim2.new(1, -18, 0, 8)
    track.BackgroundColor3 = Color3.fromRGB(225, 221, 224)
    track.BorderSizePixel = 0
    track.Parent = parent
    corner(track, 5)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(math.clamp(value / 100, 0, 1), 1)
    fill.BackgroundColor3 = color
    fill.BorderSizePixel = 0
    fill.Parent = track
    corner(fill, 5)
end

local function addInfoRow(caption: string, detail: string, bg: Color3)
    local frame = panelRow(58, bg)
    local h = text(frame, caption, 15, UDim2.fromOffset(12, 3), 24, true)
    h.Size = UDim2.new(1, -24, 0, 24)
    local d = text(frame, detail, 12, UDim2.fromOffset(12, 28), 25)
    d.Size = UDim2.new(1, -24, 0, 25)
end

local function render()
    if not backdrop.Visible then return end
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    if not currentCollection or not currentCollection.petProfiles then
        addInfoRow("Waiting for your animal...", "Collect a pet and try again.", LILAC)
        return
    end
    local id = currentCollection.equipped
    local pet = Config.Pets[id]
    local profile = currentCollection.petProfiles[tostring(id)]
    if not pet or not profile then
        addInfoRow("No active pet", "Open MY PETS and equip your companion.", LILAC)
        return
    end
    hint.Text = "🐾 " .. pet.name .. "   •   " .. (pet.description or "a tiny chaos creature") .. "   •   " .. profile.mood
    addInfoRow("👑 " .. profile.temperament .. " CHARACTER", "Habit: " .. profile.habit .. "   •   Fear: " .. profile.fear, LILAC)
    addInfoRow("🍬 SECRET FOOD TASTES", "Loves " .. profile.favoriteFood .. "   •   Dislikes " .. profile.dislikedFood, PINK)
    addInfoRow("💞 " .. (profile.bondStage or "FRIENDSHIP"), "Loves: " .. profile.affection .. "   •   Mood: " .. profile.mood, MINT)
    local meter = panelRow(156, Color3.fromRGB(250, 237, 230))
    indicator(meter, 0, "💖 FRIENDSHIP", profile.bond, Color3.fromRGB(255, 110, 149))
    indicator(meter, 1, "😊 HAPPINESS", profile.happiness, Color3.fromRGB(244, 191, 88))
    indicator(meter, 2, "⚡ ENERGY", profile.energy, Color3.fromRGB(116, 207, 181))
    indicator(meter, 3, "🍎 HUNGER", profile.hunger, Color3.fromRGB(194, 148, 244))
    local genes = panelRow(195, Color3.fromRGB(239, 238, 253))
    local name = text(genes, "🌈 PERSONALITY TRAITS (PERMANENT)", 15, UDim2.fromOffset(12, 5), 27, true)
    name.Size = UDim2.new(1, -24, 0, 27)
    local keys = {
        {"kindness", "Kindness"}, {"curiosity", "Curiosity"}, {"courage", "Courage"},
        {"mischief", "Mischief"}, {"sociability", "Sociability"}, {"sensitivity", "Sensitivity"},
    }
    for i, pair in ipairs(keys) do
        local gene = text(genes, pair[2] .. ": " .. (profile.traits and profile.traits[pair[1]] or "?"), 13, UDim2.fromOffset(12, 27 + (i - 1) * 27), 25)
        gene.Size = UDim2.new(1, -24, 0, 25)
    end
end

local function setOpen(active: boolean)
    backdrop.Visible = active
    open.Visible = not active
    if active then
        remote:FireServer("Sync")
        render()
    end
end

open.MouseButton1Click:Connect(function() setOpen(true) end)
close.MouseButton1Click:Connect(function() setOpen(false) end)
UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.B then setOpen(not backdrop.Visible) end
    if input.KeyCode == Enum.KeyCode.Escape and backdrop.Visible then setOpen(false) end
end)
remote.OnClientEvent:Connect(function(event: any)
    if typeof(event) ~= "table" then return end
    if event.type == "collection" then
        currentCollection = event
        render()
    elseif event.type == "stats" then
        currentStats = event
        if backdrop.Visible then render() end
    elseif event.type == "petFeeling" then
        feedback.Text = tostring(event.text or "")
    end
end)
