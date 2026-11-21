--!strict
-- Playable, non-modal first-minute guidance. This listens only to server
-- snapshots, never guesses that an action succeeded from button taps.
-- It disappears for returning players and during the monster chase.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("MonsterRemote") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "FirstMinuteGuide"
gui.ResetOnSpawn = false
gui.DisplayOrder = 3
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "NextObjective"
panel.AnchorPoint = Vector2.new(.5, 1)
panel.Position = UDim2.new(.5, 0, 1, -206)
panel.Size = UDim2.new(.90, 0, 0, 64)
panel.BackgroundColor3 = Color3.fromRGB(255, 250, 229)
panel.BackgroundTransparency = .05
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
local maxSize = Instance.new("UISizeConstraint")
maxSize.MaxSize = Vector2.new(480, 64)
maxSize.Parent = panel
local rounded = Instance.new("UICorner")
rounded.CornerRadius = UDim.new(0, 16)
rounded.Parent = panel
local outline = Instance.new("UIStroke")
outline.Color = Color3.fromRGB(163, 194, 125)
outline.Thickness = 2
outline.Transparency = .16
outline.Parent = panel

local heading = Instance.new("TextLabel")
heading.Name = "Objective"
heading.BackgroundTransparency = 1
heading.Position = UDim2.new(0, 12, 0, 6)
heading.Size = UDim2.new(1, -24, 0, 26)
heading.TextXAlignment = Enum.TextXAlignment.Left
heading.TextSize = 16
heading.TextColor3 = Color3.fromRGB(66, 84, 59)
heading.Font = Enum.Font.GothamBold
heading.Text = ""
heading.Parent = panel
local minMax = Instance.new("UITextSizeConstraint")
minMax.MaxTextSize = 16
minMax.MinTextSize = 11
minMax.Parent = heading

local hint = Instance.new("TextLabel")
hint.Name = "HelpfulTip"
hint.BackgroundTransparency = 1
hint.Position = UDim2.new(0, 12, 0, 34)
hint.Size = UDim2.new(1, -24, 0, 23)
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.TextWrapped = true
hint.TextSize = 12
hint.Font = Enum.Font.GothamMedium
hint.TextColor3 = Color3.fromRGB(111, 101, 76)
hint.Text = ""
hint.Parent = panel

local collectionKnown = false
local gardenKnown = false
local tutorialSeen = false
local feedCount = 0
local survivalCount = 0
local experimentCount = 0
local planted = false
local harvested = false
local phase = "SLEEP"
local stage = ""
local finished = false

local function refresh()
    if not collectionKnown or not gardenKnown or not tutorialSeen or phase == "AWAKE" then
        panel.Visible = false
        return
    end
    -- Established players should not see a repetitive tutorial after every
    -- respawn or join; this is an introductory experience, not a daily quest.
    if survivalCount > 0 or experimentCount > 0 or feedCount >= 4 or finished then
        panel.Visible = false
        return
    end
    local nextStage, titleText, message
    if feedCount == 0 then
        nextStage, titleText = "feed", "1 / 3  🍬  Feed your little companion"
        message = "Tap any food below. Every pet has its own reactions!"
    elseif not planted and not harvested then
        nextStage, titleText = "plant", "2 / 3  🌱  Plant your first seed"
        message = "Walk to your garden and tap PLANT on an empty bed."
    elseif not harvested then
        nextStage, titleText = "harvest", "3 / 3  🍓  Watch your crop grow"
        message = "Return to a ripe plant and tap HARVEST for ingredients."
    else
        finished = true
        panel.Visible = false
        return
    end
    if stage ~= nextStage then
        stage = nextStage
        heading.Text = titleText
        hint.Text = message
        panel.BackgroundTransparency = 1
        panel.Visible = true
        TweenService:Create(panel, TweenInfo.new(.35, Enum.EasingStyle.Quad),
            {BackgroundTransparency = .05}):Play()
    else
        panel.Visible = true
    end
end

remote.OnClientEvent:Connect(function(event: any)
    if type(event) ~= "table" or type(event.type) ~= "string" then return end
    if event.type == "collection" then
        collectionKnown = true
        tutorialSeen = event.tutorialSeen == true
        feedCount = math.max(0, tonumber(event.feedCount) or 0)
        survivalCount = math.max(0, tonumber(event.survivalCount) or 0)
    elseif event.type == "garden" then
        gardenKnown = true
        experimentCount = math.max(0, tonumber(event.experiments) or 0)
        if type(event.plots) == "table" then
            for _, plot in ipairs(event.plots) do
                if type(plot) == "table" and type(plot.seed) == "string" then
                    planted = true
                    break
                end
            end
        end
        if type(event.crops) == "table" then
            for _, amount in pairs(event.crops) do
                if type(amount) == "number" and amount > 0 then
                    harvested = true
                    break
                end
            end
        end
    elseif event.type == "state" then
        phase = if type(event.phase) == "string" then event.phase else phase
    else
        return
    end
    refresh()
end)
