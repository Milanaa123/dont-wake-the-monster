--!strict
-- Mobile seed album + self-guided exploration. Actual pickup is ProximityPrompt
-- on a server-created world object; this UI never grants seeds by clicking.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("MonsterRemote") :: RemoteEvent
local X = require(ReplicatedStorage:WaitForChild("ExpeditionConfig"))
local G = require(ReplicatedStorage:WaitForChild("GardenConfig"))

local WHITE = Color3.fromRGB(255, 250, 239)
local INK = Color3.fromRGB(61, 57, 90)
local BLUSH = Color3.fromRGB(252, 220, 205)
local LEAF = Color3.fromRGB(199, 238, 189)
local MUTED = Color3.fromRGB(107, 105, 120)
local state: any = nil
local tracked: any = nil
local marker: Highlight? = nil
local currentWeather = "Sunny"

local function round(target: Instance, px: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, px)
    c.Parent = target
end
local function label(parent: Instance, value: string, size: number, bold: boolean?): TextLabel
    local t = Instance.new("TextLabel")
    t.Size = UDim2.fromScale(1, 1)
    t.BackgroundTransparency = 1
    t.Text = value
    t.TextWrapped = true
    t.Font = if bold then Enum.Font.GothamBlack else Enum.Font.GothamMedium
    t.TextColor3 = INK
    t.TextSize = size
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = parent
    return t
end
local function button(parent: Instance, value: string, color: Color3): TextButton
    local b = Instance.new("TextButton")
    b.Text = value
    b.TextScaled = true
    b.TextColor3 = INK
    b.Font = Enum.Font.GothamBlack
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Parent = parent
    round(b, 12)
    local max = Instance.new("UITextSizeConstraint")
    max.MinTextSize = 10
    max.MaxTextSize = 15
    max.Parent = b
    return b
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedExplorer"
gui.DisplayOrder = 12
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
local open = button(gui, "🧭 FIND SEEDS", LEAF)
open.Position = UDim2.fromOffset(12, 292)
open.Size = UDim2.fromOffset(152, 43)
local tracker = Instance.new("TextLabel")
tracker.Name = "TrackedSeed"
tracker.AnchorPoint = Vector2.new(0.5, 0)
tracker.Position = UDim2.new(0.5, 0, 0, 270)
tracker.Size = UDim2.new(0.8, 0, 0, 40)
tracker.BackgroundColor3 = Color3.fromRGB(241, 245, 214)
tracker.BackgroundTransparency = 0.14
tracker.TextColor3 = INK
tracker.Text = ""
tracker.TextScaled = true
tracker.Font = Enum.Font.GothamBlack
tracker.Visible = false
tracker.Parent = gui
round(tracker, 12)
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(460, 40)
limit.Parent = tracker

local overlay = Instance.new("Frame")
overlay.Name = "ExplorerOverlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.fromRGB(37, 34, 58)
overlay.BackgroundTransparency = 0.28
overlay.BorderSizePixel = 0
overlay.Active = true
overlay.Visible = false
overlay.Parent = gui
local panel = Instance.new("Frame")
panel.Name = "ExplorerPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.94, 0, 0.87, 0)
panel.BackgroundColor3 = WHITE
panel.BorderSizePixel = 0
panel.Parent = overlay
round(panel, 22)
local cap = Instance.new("UISizeConstraint")
cap.MaxSize = Vector2.new(580, 690)
cap.MinSize = Vector2.new(255, 300)
cap.Parent = panel

local title = label(panel, "🌱 SEED HUNTER'S JOURNAL", 19, true)
title.Position = UDim2.new(0, 16, 0, 8)
title.Size = UDim2.new(1, -76, 0, 32)
title.TextScaled = true
local close = button(panel, "✕", BLUSH)
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -13, 0, 10)
close.Size = UDim2.fromOffset(42, 35)
local status = label(panel, "Explore and follow the glowing seed markers.", 12)
status.Position = UDim2.new(0, 14, 0, 48)
status.Size = UDim2.new(1, -28, 0, 48)

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "ExplorerList"
scroll.Position = UDim2.new(0, 12, 0, 103)
scroll.Size = UDim2.new(1, -24, 1, -117)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.fromScale(0, 0)
scroll.ScrollBarThickness = 4
scroll.Parent = panel
local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 8)
list.Parent = scroll
local inset = Instance.new("UIPadding")
inset.PaddingBottom = UDim.new(0, 11)
inset.Parent = scroll

local function row(height: number, bg: Color3): Frame
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -5, 0, height)
    card.BorderSizePixel = 0
    card.BackgroundColor3 = bg
    card.Parent = scroll
    round(card, 12)
    return card
end

local function clearHighlight()
    if marker then marker:Destroy() end
    marker = nil
end

local function track(node: any)
    tracked = node
    clearHighlight()
    overlay.Visible = false
    open.Visible = true
    tracker.Visible = true
    local island = workspace:FindFirstChild("MonsterIsland")
    if island then
        local match = island:FindFirstChild("SeedCache_" .. node.id, true)
        if match and match:IsA("BasePart") then
            marker = Instance.new("Highlight")
            marker.Adornee = match
            marker.FillColor = Color3.fromRGB(255, 232, 117)
            marker.OutlineColor = Color3.fromRGB(255, 255, 255)
            marker.FillTransparency = 0.4
            marker.OutlineTransparency = 0.1
            marker.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            marker.Parent = gui
        end
    end
end

local function draw()
    if not overlay.Visible then return end
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    local foundCount = 0
    local mutationCount = 0
    if state then
        for _ in pairs(state.seedAlbum or {}) do foundCount += 1 end
        for _ in pairs(state.mutationAlbum or {}) do mutationCount += 1 end
    end
    local weather = X.Weather[currentWeather]
    status.Text = (if weather then weather.icon .. " " .. weather.name else "☀️ Sunshine") ..
        " • " .. foundCount .. "/28 SEEDS • " .. mutationCount .. "/4 MUTATIONS\n" ..
        "COMMUNITY FESTIVAL: " .. (if state then state.festivalFinds or 0 else 0) ..
        "/" .. X.FestivalGoal .. "  • DAILY: " ..
        (if state then state.forageToday or 0 else 0) .. "/5 (+45 coins)"

    local hint = row(70, Color3.fromRGB(232, 242, 219))
    local t = label(hint, "🧭 Follow a golden highlight to a seed cache, walk close and HOLD FIND SEEDS. Each cache regrows after 4 minutes. Rare odds: 7% before curiosity bonuses.", 12)
    t.Position = UDim2.fromOffset(9, 3)
    t.Size = UDim2.new(1, -18, 1, -6)

    for _, zoneId in ipairs(X.ZoneOrder) do
        local zone = X.Zones[zoneId]
        local header = row(60, Color3.fromRGB(242, 228, 239))
        local name = label(header, zone.icon .. " " .. zone.name .. "\n" .. zone.hint, 15, true)
        name.Position = UDim2.fromOffset(10, 4)
        name.Size = UDim2.new(1, -20, 1, -8)
        for _, node in ipairs(zone.nodes) do
            local card = row(54, Color3.fromRGB(245, 246, 229))
            local last = if state and state.hunt then state.hunt.visited[node.id] else nil
            local left = if type(last) == "number" then math.max(0, X.NodeCooldown - (os.time() - last)) else 0
            local desc = label(card, "🌱 " .. node.label .. (if left == 0 then "  •  READY" else "  •  REGROWS " .. left .. "s"), 12, true)
            desc.Position = UDim2.fromOffset(9, 4)
            desc.Size = UDim2.new(0.60, -12, 1, -8)
            local goto = button(card, if left > 0 then "TRACK AGAIN" else "TRACK", LEAF)
            goto.Position = UDim2.new(0.62, 0, 0, 8)
            goto.Size = UDim2.new(0.36, -7, 0, 38)
            goto.MouseButton1Click:Connect(function() track(node) end)
        end
    end
    local album = row(72, Color3.fromRGB(226, 240, 249))
    local labelAlbum = label(album, "📔 SEED ALBUM: " .. foundCount .. " unique wild seeds discovered\n✨ MUTATIONS: " .. mutationCount .. "/4 — Golden, Dewy, Moonlit, Giggly", 13, true)
    labelAlbum.Position = UDim2.fromOffset(10, 5)
    labelAlbum.Size = UDim2.new(1, -20, 1, -10)
    for _, key in ipairs(G.Order) do
        if G.Crops[key].kind == "ordinary" then
            local entry = row(34, Color3.fromRGB(244, 239, 228))
            local seen = state and state.seedAlbum and state.seedAlbum[key]
            local t = label(entry, (if seen then "✅ " .. G.Crops[key].icon .. " " .. G.Crops[key].name else "🔒 Undiscovered wild seed"), 12)
            t.Position = UDim2.fromOffset(9, 2)
            t.Size = UDim2.new(1, -18, 1, -4)
        end
    end
end

local function toggle(active: boolean)
    overlay.Visible = active
    open.Visible = not active
    if active then draw() end
end
open.MouseButton1Click:Connect(function() toggle(true) end)
close.MouseButton1Click:Connect(function() toggle(false) end)
UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
    if not processed and input.KeyCode == Enum.KeyCode.J then toggle(not overlay.Visible) end
    if not processed and input.KeyCode == Enum.KeyCode.Escape and overlay.Visible then toggle(false) end
end)
remote.OnClientEvent:Connect(function(payload: any)
    if typeof(payload) ~= "table" then return end
    if payload.type == "garden" then
        state = payload
        currentWeather = payload.weather or currentWeather
        draw()
    elseif payload.type == "state" then
        currentWeather = payload.weather or currentWeather
    elseif payload.type == "seedFound" then
        if tracked and payload.seed then
            tracker.Text = if payload.discovered then "✨ NEW SEED! " .. payload.text else payload.text
        end
    end
end)
task.spawn(function()
    while gui.Parent do
        task.wait(1.5)
        if tracked then
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if root and root:IsA("BasePart") then
                local distance = (root.Position - Vector3.new(tracked.x, 10, tracked.z)).Magnitude
                tracker.Text = string.format("🧭 %s  •  %d studs away", tracked.label, math.floor(distance))
            end
        end
    end
end)
task.delay(1.6, function() remote:FireServer("Sync") end)
