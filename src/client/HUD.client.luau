--!strict
-- Responsive, self-contained Roblox GUI. Playable with touch or keyboard 1–4.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local remote = ReplicatedStorage:WaitForChild("MonsterRemote") :: RemoteEvent
local gui = Instance.new("ScreenGui")
gui.Name = "MonsterHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local DARK = Color3.fromRGB(53, 46, 88)
local LAVENDER = Color3.fromRGB(108, 80, 171)
local CREAM = Color3.fromRGB(255, 252, 244)
local function round(parent: Instance, radius: number)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
end

local function stroke(parent: Instance, color: Color3, thickness: number)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness
    s.Transparency = 0.16
    s.Parent = parent
end

local function label(parent: Instance, text: string, font: Enum.Font, size: number, color: Color3): TextLabel
    local t = Instance.new("TextLabel")
    t.Name = "Text"
    t.BackgroundTransparency = 1
    t.Font = font
    t.Text = text
    t.TextSize = size
    t.TextColor3 = color
    t.TextWrapped = true
    t.TextXAlignment = Enum.TextXAlignment.Center
    t.TextYAlignment = Enum.TextYAlignment.Center
    t.Parent = parent
    return t
end

local header = Instance.new("Frame")
header.Name = "StatusCard"
header.AnchorPoint = Vector2.new(0.5, 0)
header.Position = UDim2.new(0.5, 0, 0, 10)
header.Size = UDim2.new(0.94, 0, 0, 112)
header.BackgroundColor3 = CREAM
header.BorderSizePixel = 0
header.Parent = gui
round(header, 20)
stroke(header, Color3.fromRGB(238, 211, 255), 2)
local headerLimit = Instance.new("UISizeConstraint")
headerLimit.MaxSize = Vector2.new(650, 112)
headerLimit.Parent = header

local title = label(header, "😴 DON'T WAKE THE MONSTER!", Enum.Font.GothamBlack, 21, DARK)
title.Position = UDim2.new(0.03, 0, 0, 4)
title.Size = UDim2.new(0.94, 0, 0, 27)
local titleLimit = Instance.new("UITextSizeConstraint")
titleLimit.MinTextSize = 12
titleLimit.MaxTextSize = 22
titleLimit.Parent = title
title.TextScaled = true

local phaseText = label(header, "SHHH... GIGGLES IS SLEEPING", Enum.Font.GothamBold, 13, LAVENDER)
phaseText.Position = UDim2.new(0.04, 0, 0, 31)
phaseText.Size = UDim2.new(0.76, 0, 0, 20)
phaseText.TextXAlignment = Enum.TextXAlignment.Left
phaseText.TextScaled = true
local phaseLimit = Instance.new("UITextSizeConstraint")
phaseLimit.MinTextSize = 10
phaseLimit.MaxTextSize = 15
phaseLimit.Parent = phaseText

local timer = label(header, "01:50", Enum.Font.GothamBlack, 18, DARK)
timer.Position = UDim2.new(0.79, 0, 0, 31)
timer.Size = UDim2.new(0.17, 0, 0, 20)

local barBack = Instance.new("Frame")
barBack.Name = "NoiseTrack"
barBack.Position = UDim2.new(0.04, 0, 0, 60)
barBack.Size = UDim2.new(0.92, 0, 0, 23)
barBack.BackgroundColor3 = Color3.fromRGB(235, 229, 245)
barBack.BorderSizePixel = 0
barBack.ClipsDescendants = true
barBack.Parent = header
round(barBack, 12)

local barFill = Instance.new("Frame")
barFill.Name = "NoiseFill"
barFill.Size = UDim2.fromScale(0, 1)
barFill.BackgroundColor3 = Color3.fromRGB(255, 133, 176)
barFill.BorderSizePixel = 0
barFill.Parent = barBack
round(barFill, 12)
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new(Color3.fromRGB(123, 218, 249), Color3.fromRGB(255, 91, 155))
gradient.Parent = barFill

local noiseCaption = label(header, "NOISE 0 / 100    •    every action makes chaos!", Enum.Font.GothamBold, 11, DARK)
noiseCaption.Position = UDim2.new(0.04, 0, 0, 87)
noiseCaption.Size = UDim2.new(0.92, 0, 0, 18)

local stats = Instance.new("Frame")
stats.Name = "Stats"
stats.AnchorPoint = Vector2.new(0, 0)
stats.Position = UDim2.new(0, 12, 0, 132)
stats.Size = UDim2.new(0, 184, 0, 48)
stats.BackgroundColor3 = Color3.fromRGB(255, 249, 212)
stats.BorderSizePixel = 0
stats.Parent = gui
round(stats, 15)
stroke(stats, Color3.fromRGB(255, 222, 128), 2)
local statsLabel = label(stats, "🪙 0   •   PET: ???", Enum.Font.GothamBlack, 13, DARK)
statsLabel.Size = UDim2.fromScale(1, 1)

local health = Instance.new("Frame")
health.Name = "SurvivalHearts"
health.AnchorPoint = Vector2.new(1, 0)
health.Position = UDim2.new(1, -12, 0, 132)
health.Size = UDim2.fromOffset(122, 48)
health.BackgroundColor3 = Color3.fromRGB(255, 235, 238)
health.BorderSizePixel = 0
health.Visible = false
health.Parent = gui
round(health, 15)
stroke(health, Color3.fromRGB(255, 162, 182), 2)
local healthLabel = label(health, "❤️❤️❤️", Enum.Font.GothamBlack, 20, DARK)
healthLabel.Size = UDim2.fromScale(1, 1)

local banner = Instance.new("TextLabel")
banner.Name = "ChaosBanner"
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 294)
banner.Size = UDim2.new(0.94, 0, 0, 58)
banner.BackgroundColor3 = DARK
banner.BackgroundTransparency = 0.14
banner.TextColor3 = Color3.fromRGB(255, 247, 200)
banner.Font = Enum.Font.GothamBlack
banner.TextScaled = true
banner.TextWrapped = true
banner.TextStrokeTransparency = 0.5
banner.Text = ""
banner.Visible = false
banner.Parent = gui
round(banner, 18)
local bannerLimit = Instance.new("UISizeConstraint")
bannerLimit.MaxSize = Vector2.new(650, 58)
bannerLimit.Parent = banner
local bannerFont = Instance.new("UITextSizeConstraint")
bannerFont.MinTextSize = 13
bannerFont.MaxTextSize = 23
bannerFont.Parent = banner

local rescueCard = Instance.new("Frame")
rescueCard.Name = "CoopRescueChallenge"
rescueCard.AnchorPoint = Vector2.new(0.5, 1)
rescueCard.Position = UDim2.new(0.5, 0, 1, -193)
rescueCard.Size = UDim2.new(0.9, 0, 0, 48)
rescueCard.BackgroundColor3 = Color3.fromRGB(232, 250, 216)
rescueCard.BorderSizePixel = 0
rescueCard.Visible = false
rescueCard.Parent = gui
round(rescueCard, 15)
stroke(rescueCard, Color3.fromRGB(128, 212, 150), 2)
local rescueLimit = Instance.new("UISizeConstraint")
rescueLimit.MaxSize = Vector2.new(570, 48)
rescueLimit.Parent = rescueCard
local rescueLabel = label(rescueCard, "🐾 SAVE THE LOST PETS! 0/3", Enum.Font.GothamBlack, 18, DARK)
rescueLabel.Size = UDim2.new(1, -12, 1, -4)
rescueLabel.Position = UDim2.fromOffset(6, 2)
rescueLabel.TextScaled = true
local rescueTextLimit = Instance.new("UITextSizeConstraint")
rescueTextLimit.MinTextSize = 12
rescueTextLimit.MaxTextSize = 18
rescueTextLimit.Parent = rescueLabel

local foodPanel = Instance.new("Frame")
foodPanel.Name = "FeedControls"
foodPanel.AnchorPoint = Vector2.new(0.5, 1)
foodPanel.Position = UDim2.new(0.5, 0, 1, -14)
foodPanel.Size = UDim2.new(0.94, 0, 0, 168)
foodPanel.BackgroundColor3 = Color3.fromRGB(255, 251, 246)
foodPanel.BackgroundTransparency = 0.04
foodPanel.BorderSizePixel = 0
foodPanel.Parent = gui
round(foodPanel, 20)
stroke(foodPanel, Color3.fromRGB(229, 210, 255), 2)
local panelLimit = Instance.new("UISizeConstraint")
panelLimit.MaxSize = Vector2.new(590, 168)
panelLimit.Parent = foodPanel

local prompt = label(foodPanel, "FEED YOUR PET... IF YOU DARE 👀", Enum.Font.GothamBlack, 16, DARK)
prompt.Position = UDim2.new(0.02, 0, 0, 5)
prompt.Size = UDim2.new(0.96, 0, 0, 25)

local subtitle = label(foodPanel, "Tap food • discover surprises • 1–4 on keyboard", Enum.Font.GothamMedium, 11, LAVENDER)
subtitle.Position = UDim2.new(0.02, 0, 0, 28)
subtitle.Size = UDim2.new(0.96, 0, 0, 19)

local layout = Instance.new("Frame")
layout.Name = "Buttons"
layout.Position = UDim2.new(0.03, 0, 0, 53)
layout.Size = UDim2.new(0.94, 0, 0, 105)
layout.BackgroundTransparency = 1
layout.Parent = foodPanel
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.485, 0, 0, 47)
grid.CellPadding = UDim2.new(0.03, 0, 0, 7)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = layout

local buttonOrder = {"Candy", "Pepper", "Bubble", "Star"}
local buttons: {[string]: TextButton} = {}
local pressedAt = 0
local function clickFood(food: string)
    local now = os.clock()
    if now - pressedAt < 0.12 then return end
    pressedAt = now
    remote:FireServer("Feed", food)
    local button = buttons[food]
    if button then
        TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Back), {Rotation = -3}):Play()
        task.delay(0.14, function()
            if button and button.Parent then TweenService:Create(button, TweenInfo.new(0.25, Enum.EasingStyle.Elastic), {Rotation = 0}):Play() end
        end)
    end
end

for index, food in ipairs(buttonOrder) do
    local data = Config.Foods[food]
    local b = Instance.new("TextButton")
    b.Name = food
    b.LayoutOrder = index
    b.Text = tostring(index) .. "   " .. data.label
    b.Font = Enum.Font.GothamBlack
    b.TextScaled = true
    b.TextColor3 = DARK
    b.BackgroundColor3 = data.color
    b.BorderSizePixel = 0
    b.AutoButtonColor = true
    b.Parent = layout
    round(b, 14)
    stroke(b, Color3.fromRGB(255, 255, 255), 2)
    local textLimit = Instance.new("UITextSizeConstraint")
    textLimit.MinTextSize = 11
    textLimit.MaxTextSize = 19
    textLimit.Parent = b
    b.MouseButton1Click:Connect(function() clickFood(food) end)
    buttons[food] = b
end

UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
    if processed then return end
    local keyToFood = {
        [Enum.KeyCode.One] = "Candy",
        [Enum.KeyCode.Two] = "Pepper",
        [Enum.KeyCode.Three] = "Bubble",
        [Enum.KeyCode.Four] = "Star",
    }
    local food = keyToFood[input.KeyCode]
    if food then clickFood(food) end
end)

local noticeToken = 0
local function showNotice(message: string, color: Color3?)
    noticeToken += 1
    local token = noticeToken
    banner.Text = message
    banner.TextColor3 = color or Color3.fromRGB(255, 247, 200)
    banner.Visible = true
    banner.TextTransparency = 0
    banner.BackgroundTransparency = 0.14
    banner.Rotation = -2
    TweenService:Create(banner, TweenInfo.new(0.24, Enum.EasingStyle.Back), {Rotation = 0}):Play()
    task.delay(3, function()
        if token ~= noticeToken or not banner.Parent then return end
        local tween = TweenService:Create(banner, TweenInfo.new(0.5), {TextTransparency = 1, BackgroundTransparency = 1})
        tween:Play()
        tween.Completed:Wait()
        if token == noticeToken then banner.Visible = false end
    end)
end

local function countdown(seconds: number): string
    local value = math.max(0, math.floor(seconds))
    return string.format("%02d:%02d", math.floor(value / 60), value % 60)
end

local capture=Instance.new("TextButton")
capture.Name="RescueCapture"
capture.Text="📷 Save a rescue photo"
capture.Size=UDim2.fromOffset(174,38)
capture.Position=UDim2.new(.5,0,0,130)
capture.AnchorPoint=Vector2.new(.5,0)
capture.BackgroundColor3=CREAM
capture.TextColor3=DARK
capture.Font=Enum.Font.GothamBold
capture.Visible=false
capture.Parent=gui
round(capture,12)
local captureRound=0
local function offerPhoto(roundId: number)
    if roundId<=captureRound then return end
    captureRound=roundId
    capture.Visible=true
    task.delay(8,function()
        if captureRound==roundId then capture.Visible=false end
    end)
end
capture.Activated:Connect(function()
    capture.Visible=false
    local ok=pcall(function()
        local service=game:GetService("CaptureService")
        service:CaptureScreenshot(function(id)
            local prompted=pcall(function()
                service:PromptSaveCapturesToGallery({id},function() end)
            end)
            if not prompted then showNotice("Photo saving is unavailable on this device.",CREAM) end
        end)
    end)
    if not ok then showNotice("Photo capture is unavailable on this device.",CREAM) end
end)

local lureButton=Instance.new("TextButton")
lureButton.Name="RescueLure"
lureButton.Size=UDim2.fromOffset(188,40)
lureButton.AnchorPoint=Vector2.new(.5,1)
lureButton.Position=UDim2.new(.5,0,1,-82)
lureButton.BackgroundColor3=CREAM
lureButton.Font=Enum.Font.GothamBold
lureButton.TextColor3=DARK
lureButton.Visible=false
lureButton.Parent=gui
round(lureButton,12)
local lureId: string?=nil
local mayThrow=false
local out=false
local function updateLure()
    lureButton.Visible=mayThrow and not out and lureId~=nil
end
lureButton.Activated:Connect(function()
    if lureId then remote:FireServer("GardenLure",lureId) end
end)

remote.OnClientEvent:Connect(function(event: any)
    if type(event) ~= "table" then return end
    if event.type == "state" then
        local fraction = math.clamp((event.noise or 0) / (event.maxNoise or 100), 0, 1)
        TweenService:Create(barFill, TweenInfo.new(0.32, Enum.EasingStyle.Sine), {Size = UDim2.fromScale(fraction, 1)}):Play()
        noiseCaption.Text = string.format("NOISE %d / %d   •   MORE CHAOS!", event.noise or 0, event.maxNoise or 100)
        timer.Text = countdown(event.time or 0)
        health.Visible = event.phase == "AWAKE"
        mayThrow=health.Visible and event.lureReady==true
        updateLure()
        -- Keep the playfield visible while dodging attacks: feeding is disabled
        -- by the server during a chase, so the giant food control panel hides.
        -- All four feed controls return automatically when the monster sleeps.
        foodPanel.Visible = event.phase == "SLEEP"
        rescueCard.Position = if event.phase == "AWAKE"
            then UDim2.new(0.5, 0, 1, -24)
            else UDim2.new(0.5, 0, 1, -193)
        local rescue = event.rescue
        rescueCard.Visible = event.phase == "AWAKE" and typeof(rescue) == "table" and rescue.active == true
        if typeof(rescue) == "table" then
            if rescue.completed then
                rescueLabel.Text = "🎉 ALL SAVED! +30 COINS FOR SURVIVING HEROES"
                rescueCard.BackgroundColor3 = Color3.fromRGB(181, 245, 188)
            else
                local ribbon=if event.wakeMode=="Garden" then "Garden Keeper • help finish the rescue"
                    elseif event.wakeMode=="Listen" then "Quiet Steps • rescue without a bonk"
                    else "Trail Runner • draw Giggles away for 3 seconds"
                rescueLabel.Text = string.format("🐾 SAVE THE LOST PETS   %d / %d   •   +%d BONUS\n%s",
                    rescue.rescued or 0,rescue.goal or 2,rescue.bonus or 30,ribbon)
                rescueCard.BackgroundColor3 = Color3.fromRGB(232, 250, 216)
            end
        end
        for _, foodButton in pairs(buttons) do
            foodButton.Active = event.phase == "SLEEP"
            foodButton.AutoButtonColor = event.phase == "SLEEP"
        end
        if event.phase == "AWAKE" then
            title.Text = "🚨 GIGGLES IS AWAKE! RUN!"
            phaseText.Text = if event.wakeMode=="Listen" then "LISTENING • LEAVE THE BLUE RING"
                elseif event.wakeMode=="Garden" then "JELLY SHOWER • DODGE THE GOLD RINGS"
                else "CHASE • RUN OUTSIDE THE STRIKE MARKS"
            title.TextColor3 = Color3.fromRGB(243, 70, 107)
            prompt.Text = "SAVE THE LOST PETS!"
        elseif event.phase == "COOLDOWN" then
            title.Text = "💤 PHEW... NAP TIME!"
            phaseText.Text = "YOUR COINS ARE ON THE WAY"
            title.TextColor3 = DARK
            prompt.Text = "REST A MOMENT..."
        else
            title.Text = "😴 DON'T WAKE THE MONSTER!"
            phaseText.Text = "SHHH... GIGGLES IS SLEEPING"
            title.TextColor3 = DARK
            prompt.Text = "FEED YOUR PET... IF YOU DARE 👀"
        end
    elseif event.type=="garden" then
        local stock=event.crafted or {}
        lureId=if (stock.SillyLure or 0)>0 then "SillyLure" elseif (stock.GlowLure or 0)>0 then "GlowLure" else nil
        lureButton.Text=if lureId=="GlowLure" then "Throw a Glow Lure" else "Throw a Silly Lure"
        updateLure()
    elseif event.type=="callWarning" then
        showNotice(event.text,CREAM)
    elseif event.type=="rescueMoment" then
        offerPhoto(event.round)
    elseif event.type == "stats" then
        statsLabel.Text = string.format("🪙 %d   •   PET: %s", event.coins or 0, event.pet or "???")
        out=event.knockedOut==true
        updateLure()
        local count = math.clamp(event.hearts or 3, 0, 3)
        healthLabel.Text = if event.knockedOut then "💫 BONKED!" else string.rep("❤️", count) .. string.rep("🖤", 3 - count)
    elseif event.type == "petFeeling" then
        showNotice(tostring(event.text or ""), Color3.fromRGB(255, 209, 231))
    elseif event.type == "questToast" then
        showNotice(tostring(event.text or ""), Color3.fromRGB(175, 255, 205))
    elseif event.type == "notice" then
        showNotice(tostring(event.text or ""), event.color)
    elseif event.type == "shake" then
        -- Small HUD shake only, never override the camera on mobile.
        local original = foodPanel.Position
        foodPanel.Position = original + UDim2.fromOffset(5, 0)
        TweenService:Create(foodPanel, TweenInfo.new(0.18, Enum.EasingStyle.Back), {Position = original}):Play()
    end
end)

remote:FireServer("Sync")
showNotice("WELCOME! TRY A SNACK 🍬🌶️🫧⭐", Color3.fromRGB(255, 227, 132))
