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
local lastReaction = ""
local lastNoise = 0
local visitSurvivals: number? = nil
local feedCount = 0
local survivalCount = 0
local experimentCount = 0
local planted = false
local harvested = false
local phase = "SLEEP"
local warning = false
local stage = ""
local finished = false

local function refresh()
    if not collectionKnown or not gardenKnown or phase == "AWAKE" or warning then
        panel.Visible = false
        return
    end
    -- Established players should not see a repetitive tutorial after every
    -- respawn or join; this is an introductory experience, not a daily quest.
    if (visitSurvivals or 0)>0 or experimentCount > 0 or finished then
        panel.Visible = false
        return
    end
    local nextStage, titleText, message
    if phase=="COOLDOWN" and survivalCount==0 then
        nextStage,titleText="recover","Giggles is heading back to bed"
        message="In the next round, stay outside the marked rings and hold SAVE ME beside a lost pet."
    elseif feedCount == 0 then
        nextStage, titleText = "feed", "Meet your pet. Giggles is sleeping nearby."
        message = "Tap a snack below and watch your companion."
    elseif survivalCount==0 then
        nextStage = "noise"..lastReaction..tostring(lastNoise)
        titleText = if lastReaction~="" then lastReaction.."   +"..lastNoise.." noise" else "Every snack can stir Giggles"
        message = "Try SOOTHE to quiet your pet, or feed again. When Giggles wakes, look for SAVE ME."
    elseif not planted and not harvested then
        nextStage, titleText = "plant", "🌱  You survived! Plant your first seed"
        message = "Walk to your garden and tap PLANT on an empty bed."
    elseif not harvested then
        nextStage, titleText = "harvest", "🍓  Watch your crop grow"
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
        feedCount = math.max(0, tonumber(event.feedCount) or 0)
        survivalCount = math.max(0, tonumber(event.survivalCount) or 0)
        if visitSurvivals==nil then visitSurvivals=survivalCount end
    elseif event.type=="feedNoise" then
        lastNoise=event.amount
        lastReaction=event.reaction
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
        warning = event.warning ~= nil
        phase = if type(event.phase) == "string" then event.phase else phase
    else
        return
    end
    refresh()
end)
