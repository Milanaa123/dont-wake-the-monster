--!strict
-- Free-to-play creature collection and quests; no Robux purchases in this prototype.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local remote = ReplicatedStorage:WaitForChild("MonsterRemote") :: RemoteEvent

local INK = Color3.fromRGB(62, 52, 91)
local PURPLE = Color3.fromRGB(127, 91, 194)
local CREAM = Color3.fromRGB(255, 250, 242)
local LIGHT = Color3.fromRGB(245, 236, 255)
local MUTED = Color3.fromRGB(104, 94, 126)

local catalog = {owned = {1}, equipped = 1, discovered = 0, totalReactions = #Config.Reactions, feedCount = 0, survivalCount = 0, questClaimed = {feeds = false, survivals = false, discoveries = false}, dailyReady = false}
local currentCoins = 0

local function rounded(target: Instance, radius: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = target
end

local function outline(target: Instance, color: Color3)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = 2
    s.Transparency = 0.28
    s.Parent = target
end

local function textLabel(parent: Instance, value: string, size: number, color: Color3, font: Enum.Font?): TextLabel
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Text = value
    t.Font = font or Enum.Font.GothamBold
    t.TextSize = size
    t.TextColor3 = color
    t.TextWrapped = true
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = parent
    return t
end

local gui = Instance.new("ScreenGui")
gui.Name = "CollectionGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 7
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local open = Instance.new("TextButton")
open.Name = "OpenCollection"
open.Position = UDim2.fromOffset(12, 191)
open.Size = UDim2.fromOffset(152, 42)
open.BackgroundColor3 = CREAM
open.TextColor3 = INK
open.Text = "🐾 MY PETS (P)"
open.Font = Enum.Font.GothamBlack
open.TextSize = 13
open.Parent = gui
rounded(open, 14)
outline(open, Color3.fromRGB(198, 170, 251))

local daily = Instance.new("TextButton")
daily.Name = "DailyTreat"
daily.Position = UDim2.fromOffset(12, 241)
daily.Size = UDim2.fromOffset(152, 39)
daily.BackgroundColor3 = Color3.fromRGB(255, 224, 147)
daily.TextColor3 = INK
daily.Font = Enum.Font.GothamBlack
daily.TextSize = 12
daily.Text = "🎁 DAILY TREAT"
daily.Parent = gui
rounded(daily, 14)
outline(daily, Color3.fromRGB(255, 186, 114))

local overlay = Instance.new("Frame")
overlay.Name = "CollectionOverlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.Position = UDim2.fromScale(0, 0)
overlay.BackgroundColor3 = Color3.fromRGB(35, 26, 62)
overlay.BackgroundTransparency = 0.3
overlay.BorderSizePixel = 0
overlay.Active = true
overlay.Visible = false
overlay.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "CollectionPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.94, 0, 0.86, 0)
panel.BackgroundColor3 = CREAM
panel.BorderSizePixel = 0
panel.Parent = overlay
rounded(panel, 24)
outline(panel, Color3.fromRGB(208, 187, 255))
local panelLimit = Instance.new("UISizeConstraint")
panelLimit.MaxSize = Vector2.new(580, 650)
panelLimit.MinSize = Vector2.new(260, 300)
panelLimit.Parent = panel

local title = textLabel(panel, "🐾 MY CHAOTIC CREATURES", 20, INK, Enum.Font.GothamBlack)
title.Position = UDim2.new(0, 18, 0, 13)
title.Size = UDim2.new(1, -83, 0, 30)
title.TextScaled = true
local titleLimit = Instance.new("UITextSizeConstraint")
titleLimit.MaxTextSize = 20
titleLimit.MinTextSize = 13
titleLimit.Parent = title

local close = Instance.new("TextButton")
close.Name = "Close"
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -15, 0, 10)
close.Size = UDim2.fromOffset(43, 38)
close.BackgroundColor3 = Color3.fromRGB(255, 184, 193)
close.Text = "✕"
close.TextSize = 24
close.TextColor3 = INK
close.Font = Enum.Font.GothamBlack
close.Parent = panel
rounded(close, 14)

local subtitle = textLabel(panel, "Collect new friends using COINS from chaos!", 12, MUTED)
subtitle.Position = UDim2.new(0, 18, 0, 48)
subtitle.Size = UDim2.new(1, -36, 0, 24)
subtitle.TextScaled = true
local subtitleLimit = Instance.new("UITextSizeConstraint")
subtitleLimit.MinTextSize = 10
subtitleLimit.MaxTextSize = 13
subtitleLimit.Parent = subtitle

local quests = Instance.new("Frame")
quests.Name = "Quests"
quests.Position = UDim2.new(0, 13, 0, 79)
quests.Size = UDim2.new(1, -26, 0, 100)
quests.BackgroundColor3 = LIGHT
quests.BorderSizePixel = 0
quests.Parent = panel
rounded(quests, 15)

local questTitle = textLabel(quests, "✨ STARTER QUESTS", 14, PURPLE, Enum.Font.GothamBlack)
questTitle.Position = UDim2.new(0, 12, 0, 3)
questTitle.Size = UDim2.new(1, -24, 0, 22)
local questFeed = textLabel(quests, "🍬 Feed pets: 0/5  →  +45 coins", 12, INK)
questFeed.Position = UDim2.new(0, 12, 0, 25)
questFeed.Size = UDim2.new(1, -24, 0, 22)
local questSurvive = textLabel(quests, "❤️ Survive rounds: 0/2  →  +80 coins", 12, INK)
questSurvive.Position = UDim2.new(0, 12, 0, 48)
questSurvive.Size = UDim2.new(1, -24, 0, 22)
local questDiscover = textLabel(quests, "🌈 Discover chaos: 0/4  →  +70 coins", 12, INK)
questDiscover.Position = UDim2.new(0, 12, 0, 71)
questDiscover.Size = UDim2.new(1, -24, 0, 22)

local collectionTitle = textLabel(panel, "YOUR PETS", 15, INK, Enum.Font.GothamBlack)
collectionTitle.Position = UDim2.new(0, 17, 0, 183)
collectionTitle.Size = UDim2.new(1, -34, 0, 27)

local list = Instance.new("ScrollingFrame")
list.Name = "PetList"
list.Position = UDim2.new(0, 12, 0, 212)
list.Size = UDim2.new(1, -24, 1, -223)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.ScrollBarImageColor3 = PURPLE
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.ScrollingDirection = Enum.ScrollingDirection.Y
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 4)
padding.PaddingBottom = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 4)
padding.PaddingRight = UDim.new(0, 7)
padding.Parent = list

local rowButtons: {[number]: TextButton} = {}
local function owned(id: number): boolean
    for _, value in ipairs(catalog.owned) do
        if value == id then return true end
    end
    return false
end

for id, pet in ipairs(Config.Pets) do
    local row = Instance.new("Frame")
    row.Name = pet.name
    row.LayoutOrder = id
    row.Size = UDim2.new(1, -4, 0, 62)
    row.BackgroundColor3 = LIGHT
    row.BorderSizePixel = 0
    row.Parent = list
    rounded(row, 14)

    local iconBack = Instance.new("Frame")
    iconBack.Position = UDim2.fromOffset(8, 8)
    iconBack.Size = UDim2.fromOffset(46, 46)
    iconBack.BackgroundColor3 = pet.color
    iconBack.BorderSizePixel = 0
    iconBack.Parent = row
    rounded(iconBack, 14)
    local icon = textLabel(iconBack, "◕ᴥ◕", 19, INK, Enum.Font.GothamBlack)
    icon.TextXAlignment = Enum.TextXAlignment.Center
    icon.Size = UDim2.fromScale(1, 1)

    local petName = textLabel(row, pet.name, 16, INK, Enum.Font.GothamBlack)
    petName.Position = UDim2.new(0, 62, 0, 7)
    petName.Size = UDim2.new(0.35, 0, 0, 23)
    petName.TextTruncate = Enum.TextTruncate.AtEnd

    local petPrice = textLabel(row, if id == 1 then "Starter buddy" else tostring(pet.price) .. " coins", 11, MUTED)
    petPrice.Position = UDim2.new(0, 62, 0, 32)
    petPrice.Size = UDim2.new(0.38, 0, 0, 20)

    local button = Instance.new("TextButton")
    button.Name = "Action"
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, -9, 0.5, 0)
    button.Size = UDim2.new(0.35, 0, 0, 41)
    button.BackgroundColor3 = Color3.fromRGB(255, 217, 147)
    button.BorderSizePixel = 0
    button.Text = "BUY"
    button.TextColor3 = INK
    button.Font = Enum.Font.GothamBlack
    button.TextScaled = true
    button.Parent = row
    rounded(button, 12)
    local limit = Instance.new("UITextSizeConstraint")
    limit.MinTextSize = 10
    limit.MaxTextSize = 14
    limit.Parent = button
    rowButtons[id] = button
    button.MouseButton1Click:Connect(function()
        if owned(id) then
            if catalog.equipped ~= id then remote:FireServer("EquipPet", id) end
        else
            remote:FireServer("BuyPet", id)
        end
    end)
end

local function render()
    collectionTitle.Text = string.format("YOUR PETS  %d/%d     •     CHAOS FOUND %d/%d", #catalog.owned, #Config.Pets, catalog.discovered, catalog.totalReactions)
    local done = catalog.questClaimed
    questFeed.Text = if done.feeds then "✅ FEED 5: COMPLETE!" else string.format("🍬 Feed pets: %d/5  →  +45 coins", math.min(catalog.feedCount, 5))
    questSurvive.Text = if done.survivals then "✅ SURVIVE 2: COMPLETE!" else string.format("❤️ Survive rounds: %d/2  →  +80 coins", math.min(catalog.survivalCount, 2))
    questDiscover.Text = if done.discoveries then "✅ DISCOVER 4: COMPLETE!" else string.format("🌈 Discover chaos: %d/4  →  +70 coins", math.min(catalog.discovered, 4))
    daily.Text = if catalog.dailyReady then "🎁 CLAIM +60 COINS" else "🎁 COME BACK TOMORROW"
    daily.BackgroundColor3 = if catalog.dailyReady then Color3.fromRGB(255, 224, 147) else Color3.fromRGB(227, 225, 225)
    for id, pet in ipairs(Config.Pets) do
        local b = rowButtons[id]
        if catalog.equipped == id then
            b.Text = "EQUIPPED ✓"
            b.BackgroundColor3 = Color3.fromRGB(170, 236, 187)
            b.Active = false
            b.AutoButtonColor = false
        elseif owned(id) then
            b.Text = "EQUIP"
            b.BackgroundColor3 = Color3.fromRGB(172, 226, 255)
            b.Active = true
            b.AutoButtonColor = true
        else
            b.Text = if currentCoins >= pet.price then "BUY " .. pet.price else "🔒 " .. pet.price
            b.BackgroundColor3 = if currentCoins >= pet.price then Color3.fromRGB(255, 222, 146) else Color3.fromRGB(219, 215, 229)
            b.Active = true -- server handles insufficient balance with feedback
            b.AutoButtonColor = true
        end
    end
end

local function setOpen(isOpen: boolean)
    overlay.Visible = isOpen
    open.Visible = not isOpen
    daily.Visible = not isOpen
    if isOpen then render() end
end
open.MouseButton1Click:Connect(function() setOpen(true) end)
close.MouseButton1Click:Connect(function() setOpen(false) end)
daily.MouseButton1Click:Connect(function()
    if catalog.dailyReady then remote:FireServer("ClaimDaily") end
end)

UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.P then
        setOpen(not overlay.Visible)
    elseif input.KeyCode == Enum.KeyCode.Escape and overlay.Visible then
        setOpen(false)
    end
end)

remote.OnClientEvent:Connect(function(event: any)
    if typeof(event) ~= "table" then return end
    if event.type == "collection" then
        catalog = event
        render()
    elseif event.type == "stats" then
        currentCoins = event.coins or 0
        render()
    end
end)

render()
task.delay(1.1, function()
    remote:FireServer("Sync")
end)
