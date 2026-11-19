--!strict
-- Mobile garden: six plots, 12 seeds, deterministic recipes, bait and fertilizer.
-- Robux-only products are visibly disabled until product IDs and server receipts exist.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local G = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local remote = ReplicatedStorage:WaitForChild("MonsterRemote") :: RemoteEvent
local INK = Color3.fromRGB(55, 57, 74)
local GREEN = Color3.fromRGB(93, 177, 119)
local LILAC = Color3.fromRGB(161, 129, 211)
local CREAM = Color3.fromRGB(254, 252, 241)
local MINT = Color3.fromRGB(228, 250, 222)
local MUTED = Color3.fromRGB(109, 110, 126)
local state: any = nil
local latestAt = 0
local coins = 0
local tab = "Plots"
local seedIndex = 1
local fertilizerKey = "Compost"
local plotTimers: {[number]: TextLabel} = {}

local function round(obj: Instance, radius: number)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = obj
end
local function outline(obj: Instance, color: Color3)
    local border = Instance.new("UIStroke")
    border.Color = color
    border.Thickness = 1.5
    border.Transparency = 0.25
    border.Parent = obj
end
local function text(parent: Instance, caption: string, size: number, color: Color3, bold: boolean?): TextLabel
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = caption
    label.TextColor3 = color
    label.TextSize = size
    label.Font = if bold then Enum.Font.GothamBlack else Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Parent = parent
    return label
end
local function button(parent: Instance, caption: string, color: Color3): TextButton
    local b = Instance.new("TextButton")
    b.Text = caption
    b.Font = Enum.Font.GothamBold
    b.TextScaled = true
    b.TextColor3 = INK
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Parent = parent
    round(b, 11)
    local lim = Instance.new("UITextSizeConstraint")
    lim.MinTextSize = 9
    lim.MaxTextSize = 15
    lim.Parent = b
    return b
end
local function copyMap(t: any, key: string): number
    if typeof(t) ~= "table" then return 0 end
    local value = t[key]
    return if type(value) == "number" then value else 0
end
local function ownsSeed(key: string): number
    if not state then return 0 end
    return copyMap(state.seeds, key)
end
local function cropInventory(key: string): number
    if not state then return 0 end
    return copyMap(state.crops, key)
end
local function productInventory(key: string, fertilizer: boolean): number
    if not state then return 0 end
    return copyMap(if fertilizer then state.fertilizer else state.crafted, key)
end
local function secondsLeft(plot: any): number
    if typeof(plot) ~= "table" or not state then return 0 end
    local now = (state.serverTime or os.time()) + (os.clock() - latestAt)
    return math.max(0, math.ceil(plot.readyAt - now))
end

local gui = Instance.new("ScreenGui")
gui.Name = "GardenGui"
gui.DisplayOrder = 9
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local open = button(gui, "🌿 MY GARDEN (G)", MINT)
open.Name = "GardenOpen"
open.Position = UDim2.new(1, -164, 0, 191)
open.Size = UDim2.fromOffset(152, 42)
outline(open, GREEN)

local overlay = Instance.new("Frame")
overlay.Name = "GardenOverlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.fromRGB(29, 36, 42)
overlay.BackgroundTransparency = 0.3
overlay.Active = true
overlay.Visible = false
overlay.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "GardenPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.95, 0, 0.88, 0)
panel.BackgroundColor3 = CREAM
panel.BorderSizePixel = 0
panel.Parent = overlay
round(panel, 22)
outline(panel, GREEN)
local constrain = Instance.new("UISizeConstraint")
constrain.MaxSize = Vector2.new(650, 750)
constrain.MinSize = Vector2.new(260, 310)
constrain.Parent = panel

local title = text(panel, "🌼 MY CHAOS GARDEN", 21, GREEN, true)
title.Position = UDim2.new(0, 17, 0, 11)
title.Size = UDim2.new(1, -80, 0, 34)
title.TextScaled = true
local titleLimit = Instance.new("UITextSizeConstraint")
titleLimit.MaxTextSize = 21
titleLimit.MinTextSize = 12
titleLimit.Parent = title
local close = button(panel, "✕", Color3.fromRGB(255, 188, 189))
close.Position = UDim2.new(1, -52, 0, 11)
close.Size = UDim2.fromOffset(39, 38)

local status = text(panel, "Loading the greenhouse...", 12, MUTED, false)
status.Position = UDim2.new(0, 17, 0, 49)
status.Size = UDim2.new(1, -30, 0, 22)

local tabRow = Instance.new("Frame")
tabRow.BackgroundTransparency = 1
tabRow.Position = UDim2.new(0, 12, 0, 78)
tabRow.Size = UDim2.new(1, -24, 0, 41)
tabRow.Parent = panel
local tabs = {}
for i, info in ipairs({
    {key = "Plots", label = "🌱 PLOTS"},
    {key = "Seeds", label = "🛒 SEEDS"},
    {key = "Craft", label = "🧪 CRAFT"},
}) do
    local b = button(tabRow, info.label, MINT)
    b.Position = UDim2.new((i - 1) / 3, 3, 0, 0)
    b.Size = UDim2.new(1 / 3, -7, 1, 0)
    tabs[info.key] = b
    b.MouseButton1Click:Connect(function()
        tab = info.key
        -- render() declared below, called through local callback set below
        if tabs._render then tabs._render() end
    end)
end

local content = Instance.new("ScrollingFrame")
content.Name = "GardenContent"
content.Position = UDim2.new(0, 12, 0, 130)
content.Size = UDim2.new(1, -24, 1, -145)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 5
content.ScrollBarImageColor3 = GREEN
content.CanvasSize = UDim2.fromScale(0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.Parent = panel
local lay = Instance.new("UIListLayout")
lay.SortOrder = Enum.SortOrder.LayoutOrder
lay.Padding = UDim.new(0, 8)
lay.Parent = content
local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 3)
pad.PaddingBottom = UDim.new(0, 10)
pad.PaddingLeft = UDim.new(0, 3)
pad.PaddingRight = UDim.new(0, 6)
pad.Parent = content

local function row(height: number, color: Color3?): Frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -6, 0, height)
    frame.BackgroundColor3 = color or MINT
    frame.BorderSizePixel = 0
    frame.Parent = content
    round(frame, 13)
    return frame
end

local function clearRows()
    table.clear(plotTimers)
    for _, item in ipairs(content:GetChildren()) do
        if item:IsA("Frame") then item:Destroy() end
    end
end

local function topHint(message: string)
    local box = row(62, Color3.fromRGB(239, 235, 253))
    local label = text(box, message, 13, INK, true)
    label.Position = UDim2.new(0, 12, 0, 6)
    label.Size = UDim2.new(1, -24, 1, -12)
    return box
end

local function drawPlots()
    local seed = G.Order[seedIndex]
    local header = row(104, Color3.fromRGB(230, 246, 221))
    local hint = text(header, "SELECT SEED FOR EMPTY PLOTS", 12, MUTED, true)
    hint.Position = UDim2.new(0, 11, 0, 3)
    hint.Size = UDim2.new(1, -24, 0, 23)
    local chosen = G.Crops[seed]
    local selector = button(header, "◀  " .. chosen.icon .. " " .. chosen.name .. "  ×" .. ownsSeed(seed) .. "  ▶", Color3.fromRGB(255, 235, 155))
    selector.Position = UDim2.new(0, 9, 0, 27)
    selector.Size = UDim2.new(1, -18, 0, 32)
    selector.MouseButton1Click:Connect(function()
        repeat
            seedIndex = (seedIndex % #G.Order) + 1
        until G.Crops[G.Order[seedIndex]].kind ~= "premium" or ownsSeed(G.Order[seedIndex]) > 0
        tabs._render()
    end)
    local visit = button(header, "📍 VISIT MY PHYSICAL GARDEN", Color3.fromRGB(184, 226, 247))
    visit.Position = UDim2.new(0, 9, 0, 65)
    visit.Size = UDim2.new(1, -18, 0, 32)
    visit.MouseButton1Click:Connect(function()
        remote:FireServer("GardenVisit")
        overlay.Visible = false
        open.Visible = true
    end)

    local fertilizer = row(69, Color3.fromRGB(241, 235, 251))
    local available = productInventory(fertilizerKey, true)
    local selectorFert = button(fertilizer, "FERTILIZER: " .. fertilizerKey .. "  ×" .. available .. "  ↻", Color3.fromRGB(213, 191, 249))
    selectorFert.Position = UDim2.new(0, 8, 0, 9)
    selectorFert.Size = UDim2.new(1, -16, 0, 48)
    selectorFert.MouseButton1Click:Connect(function()
        if fertilizerKey == "Compost" then
            fertilizerKey = "Starlight"
        elseif fertilizerKey == "Starlight" then
            fertilizerKey = "AuroraDust"
        else
            fertilizerKey = "Compost"
        end
        tabs._render()
    end)

    for i = 1, G.PLOT_COUNT do
        local p = if state then state.plots[i] else false
        local card = row(80, if p then Color3.fromRGB(237, 250, 230) else Color3.fromRGB(242, 238, 230))
        local crop = if typeof(p) == "table" then G.Crops[p.seed] else nil
        local plotText = text(card, "PLOT " .. i .. "   " .. (if crop then crop.icon .. " " .. crop.name else "Empty"), 14, INK, true)
        plotText.Position = UDim2.new(0, 11, 0, 5)
        plotText.Size = UDim2.new(0.56, 0, 0, 27)
        local countdown = text(card, if crop then "Growing..." else "Ready for planting", 12, MUTED, false)
        countdown.Position = UDim2.new(0, 11, 0, 34)
        countdown.Size = UDim2.new(0.56, 0, 0, 36)
        plotTimers[i] = countdown
        local action = button(card, if crop then "HARVEST" else "PLANT", if crop then Color3.fromRGB(255, 218, 145) else Color3.fromRGB(171, 236, 181))
        action.Position = UDim2.new(0.58, 0, 0, 7)
        action.Size = UDim2.new(0.4, -9, 0, 32)
        action.MouseButton1Click:Connect(function()
            if crop then
                remote:FireServer("GardenHarvest", i)
            else
                remote:FireServer("GardenPlant", {plot = i, seed = G.Order[seedIndex]})
            end
        end)
        if crop then
            local fert = button(card, if p.fertilized then "FERTILIZED ✓" else "USE FERTILIZER", Color3.fromRGB(200, 235, 245))
            fert.Position = UDim2.new(0.58, 0, 0, 43)
            fert.Size = UDim2.new(0.4, -9, 0, 29)
            fert.Active = not p.fertilized
            fert.AutoButtonColor = not p.fertilized
            fert.MouseButton1Click:Connect(function()
                if not p.fertilized then
                    remote:FireServer("GardenFertilize", {plot = i, fertilizer = fertilizerKey})
                end
            end)
        end
    end
end

local function drawSeeds()
    topHint("🌱 Buy packets of 3 ordinary seeds using game coins. Premium items are NOT on sale yet.")
    for _, seed in ipairs(G.Order) do
        local crop = G.Crops[seed]
        local premium = crop.kind == "premium"
        local frame = row(74, if premium then Color3.fromRGB(243, 230, 252) else MINT)
        local titleRow = text(frame, crop.icon .. " " .. crop.name, 15, INK, true)
        titleRow.Position = UDim2.new(0, 10, 0, 6)
        titleRow.Size = UDim2.new(0.58, 0, 0, 26)
        local detail = text(frame, (if premium then "✨ Premium design • no payment" else "+" .. G.SEED_PACK_SIZE .. " seeds / " .. crop.coins .. " coins") .. " • bag: " .. ownsSeed(seed), 11, MUTED, false)
        detail.Position = UDim2.new(0, 10, 0, 34)
        detail.Size = UDim2.new(0.57, 0, 0, 32)
        local buy = button(frame, if premium then "COMING SOON" else "BUY " .. crop.coins .. " 🪙", if premium then Color3.fromRGB(219, 209, 228) else Color3.fromRGB(255, 219, 139))
        buy.Position = UDim2.new(0.6, 0, 0.5, -18)
        buy.Size = UDim2.new(0.38, -8, 0, 36)
        buy.Active = not premium
        buy.AutoButtonColor = not premium
        buy.MouseButton1Click:Connect(function()
            if not premium then remote:FireServer("GardenBuySeed", seed) end
        end)
    end
    local premiumFert = row(74, Color3.fromRGB(243, 230, 252))
    local fertTitle = text(premiumFert, "✨ Aurora Dust Fertilizer", 15, INK, true)
    fertTitle.Position = UDim2.new(0, 10, 0, 5)
    fertTitle.Size = UDim2.new(0.58, 0, 0, 28)
    local fertDetail = text(premiumFert, "80% faster remaining growth • stock: " .. productInventory("AuroraDust", true), 11, MUTED, false)
    fertDetail.Position = UDim2.new(0, 10, 0, 32)
    fertDetail.Size = UDim2.new(0.58, 0, 0, 33)
    local comingSoon = button(premiumFert, "COMING SOON", Color3.fromRGB(219, 209, 228))
    comingSoon.Position = UDim2.new(0.6, 0, 0.5, -18)
    comingSoon.Size = UDim2.new(0.38, -8, 0, 36)
    comingSoon.Active = false
    comingSoon.AutoButtonColor = false
end

local function drawCraft()
    topHint("🧪 Grow crops → harvest ingredients → craft special pet food, wild-creature lures and fertilizer.")
    local summary = row(91, Color3.fromRGB(246, 236, 218))
    local inventory = {}
    for _, seed in ipairs(G.Order) do
        local n = cropInventory(seed)
        if n > 0 then table.insert(inventory, G.Crops[seed].icon .. tostring(n)) end
    end
    local cropSummary = text(summary, "HARVEST: " .. (if #inventory > 0 then table.concat(inventory, "   ") else "Nothing harvested yet"), 12, INK, true)
    cropSummary.Position = UDim2.new(0, 9, 0, 7)
    cropSummary.Size = UDim2.new(1, -18, 0, 72)

    for _, key in ipairs(G.RecipeOrder) do
        local recipe = G.Recipes[key]
        local frame = row(111, MINT)
        local heading = text(frame, recipe.icon .. " " .. recipe.name .. "  (×" .. recipe.produces .. ")", 14, INK, true)
        heading.Position = UDim2.new(0, 10, 0, 5)
        heading.Size = UDim2.new(1, -18, 0, 27)
        local ingredients = {}
        local canCraft = true
        for _, seed in ipairs(G.Order) do
            local needed = recipe.ingredients[seed]
            if needed then
                local have = cropInventory(seed)
                table.insert(ingredients, needed .. "× " .. G.Crops[seed].icon .. G.Crops[seed].name .. " (" .. have .. ")")
                if have < needed then canCraft = false end
            end
        end
        local detail = text(frame, table.concat(ingredients, " + "), 11, MUTED, false)
        detail.Position = UDim2.new(0, 10, 0, 34)
        detail.Size = UDim2.new(1, -18, 0, 26)
        local amount = productInventory(key, recipe.type == "fertilizer")
        local craft = button(frame, "CRAFT", if canCraft then Color3.fromRGB(255, 219, 145) else Color3.fromRGB(227, 221, 213))
        craft.Position = UDim2.new(0, 10, 0, 66)
        craft.Size = UDim2.new(0.47, -10, 0, 36)
        craft.MouseButton1Click:Connect(function()
            remote:FireServer("GardenCraft", key)
        end)
        local consume = button(frame, (if recipe.type == "fertilizer" then "STOCK" else "USE") .. " ×" .. amount, Color3.fromRGB(188, 236, 221))
        consume.Position = UDim2.new(0.51, 0, 0, 66)
        consume.Size = UDim2.new(0.48, -10, 0, 36)
        local enabled = recipe.type ~= "fertilizer" and amount > 0
        consume.Active = enabled
        consume.AutoButtonColor = enabled
        consume.MouseButton1Click:Connect(function()
            if recipe.type == "feed" and amount > 0 then remote:FireServer("GardenFeed", key) end
            if recipe.type == "lure" and amount > 0 then remote:FireServer("GardenLure", key) end
        end)
    end
end

local function render()
    if not state then
        status.Text = "Garden loading...   🪙 " .. coins
    else
        status.Text = "🪙 " .. coins .. "  •  " .. (if state.saving then "PROGRESS SAVES" else "SAVE OFFLINE") .. "  •  " .. (if state.slot > 0 then "PRIVATE GARDEN #" .. state.slot else "VIRTUAL GARDEN")
    end
    for key, b in pairs(tabs) do
        if typeof(b) == "Instance" and b:IsA("TextButton") then
            b.BackgroundColor3 = if key == tab then Color3.fromRGB(152, 228, 169) else Color3.fromRGB(229, 228, 223)
        end
    end
    if not overlay.Visible then return end
    clearRows()
    if tab == "Plots" then drawPlots()
    elseif tab == "Seeds" then drawSeeds()
    else drawCraft() end
end
tabs._render = render

local function setOpen(isOpen: boolean)
    overlay.Visible = isOpen
    open.Visible = not isOpen
    render()
end
open.MouseButton1Click:Connect(function() setOpen(true) end)
close.MouseButton1Click:Connect(function() setOpen(false) end)
UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.G then
        setOpen(not overlay.Visible)
    elseif input.KeyCode == Enum.KeyCode.Escape and overlay.Visible then
        setOpen(false)
    end
end)
remote.OnClientEvent:Connect(function(event: any)
    if typeof(event) ~= "table" then return end
    if event.type == "garden" then
        state = event
        latestAt = os.clock()
        render()
    elseif event.type == "stats" then
        coins = event.coins or coins
        render()
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if overlay.Visible and tab == "Plots" and state then
            for index, label in pairs(plotTimers) do
                local p = state.plots[index]
                if typeof(p) == "table" then
                    local sec = secondsLeft(p)
                    label.Text = if sec <= 0 then "✨ READY TO HARVEST!" else "Growing " .. math.floor(sec / 60) .. "m " .. (sec % 60) .. "s left"
                else
                    label.Text = "Tap PLANT to sow a seed"
                end
            end
        end
    end
end)
task.delay(1.9, function() remote:FireServer("Sync") end)
