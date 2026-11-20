--!strict
-- Short, readable onboarding: clarify the main loop in the first few seconds.
-- No modal is forced after pressing PLAY; use ? to reopen.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("MonsterRemote") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "HowToPlayGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 30
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local dark = Color3.fromRGB(60, 43, 89)
local light = Color3.fromRGB(255, 250, 240)
local soft = Color3.fromRGB(231, 219, 255)

local function corner(parent: Instance, radius: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
end

local function line(parent: Instance, caption: string, at: UDim2, height: number, fontSize: number, bold: boolean): TextLabel
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = caption
    label.TextWrapped = true
    label.TextScaled = false
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Font = if bold then Enum.Font.GothamBlack else Enum.Font.GothamMedium
    label.TextSize = fontSize
    label.TextColor3 = dark
    label.Size = UDim2.new(1, -32, 0, height)
    label.Position = at
    label.Parent = parent
    return label
end

local help = Instance.new("TextButton")
help.Name = "ReopenTutorial"
help.AnchorPoint = Vector2.new(1, 1)
help.Position = UDim2.new(1, -13, 1, -243)
help.Size = UDim2.fromOffset(45, 43)
help.BackgroundColor3 = Color3.fromRGB(242, 228, 255)
help.TextColor3 = dark
help.Font = Enum.Font.GothamBlack
help.TextSize = 26
help.Text = "?"
help.Parent = gui
corner(help, 14)

local shade = Instance.new("Frame")
shade.Name = "TutorialShade"
shade.BackgroundColor3 = Color3.fromRGB(32, 23, 58)
shade.BackgroundTransparency = 0.25
shade.Size = UDim2.fromScale(1, 1)
shade.BorderSizePixel = 0
shade.Active = true
shade.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "TutorialCard"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.92, 0, 0, 444)
panel.BackgroundColor3 = light
panel.BorderSizePixel = 0
panel.Parent = shade
corner(panel, 22)

local bounds = Instance.new("UISizeConstraint")
bounds.MaxSize = Vector2.new(500, 444)
bounds.Parent = panel

line(panel, "👾 DON'T WAKE THE MONSTER!", UDim2.fromOffset(16, 12), 36, 20, true)
line(panel, "A cute island. A sleepy giant. Terrible decisions.", UDim2.fromOffset(16, 49), 38, 14, false)

local steps = {
    {heading = "1  🧭  HUNT SEEDS", detail = "Open FIND SEEDS, track a glowing cache in the forest and hold its SEARCH prompt."},
    {heading = "2  🌱  GROW & EXPERIMENT", detail = "Plant discoveries in MY GARDEN. Weather and your pet can transform crops! Mix secret recipes."},
    {heading = "3  🐱  FEED & CUDDLE", detail = "Feed wild snacks or hold PET to stroke your animal. Even a happy kitten's purr makes noise!"},
    {heading = "4  🚨  RESCUE & SURVIVE", detail = "When Giggles wakes, dodge attacks, save runaway pets and earn coins for your collection."},
}
for i, step in ipairs(steps) do
    local block = Instance.new("Frame")
    block.Name = "Step" .. i
    block.Size = UDim2.new(1, -30, 0, 68)
    block.Position = UDim2.new(0, 15, 0, 90 + (i - 1) * 72)
    block.BackgroundColor3 = if i % 2 == 1 then soft else Color3.fromRGB(227, 248, 227)
    block.BorderSizePixel = 0
    block.Parent = panel
    corner(block, 12)
    local title = line(block, step.heading, UDim2.fromOffset(8, 2), 25, 14, true)
    title.TextXAlignment = Enum.TextXAlignment.Left
    local detail = line(block, step.detail, UDim2.fromOffset(8, 27), 37, 12, false)
    detail.TextXAlignment = Enum.TextXAlignment.Left
end

local play = Instance.new("TextButton")
play.Name = "StartPlaying"
play.Size = UDim2.new(1, -30, 0, 48)
play.Position = UDim2.new(0, 15, 1, -56)
play.BackgroundColor3 = Color3.fromRGB(161, 235, 183)
play.BorderSizePixel = 0
play.Font = Enum.Font.GothamBlack
play.TextColor3 = dark
play.TextSize = 18
play.Text = "LET'S MAKE CHAOS! ✨"
play.Parent = panel
corner(play, 13)

local function setOpen(open: boolean)
    shade.Visible = open
    help.Visible = not open
end

local resolvedFirstJoin = false
local tutorialSeen = false

play.MouseButton1Click:Connect(function()
    setOpen(false)
    if not tutorialSeen then
        tutorialSeen = true
        remote:FireServer("TutorialDismiss")
    end
end)

remote.OnClientEvent:Connect(function(event: any)
    if type(event) ~= "table" or event.type ~= "collection" then return end
    tutorialSeen = event.tutorialSeen == true or tutorialSeen
    if not resolvedFirstJoin then
        resolvedFirstJoin = true
        if not tutorialSeen then setOpen(true) end
    end
end)

-- On very fast joins the server may send the initial snapshot before this
-- LocalScript connects. Explicitly request one so the first-time guide
-- appears reliably while existing players are not interrupted.
task.delay(2.6, function()
    if not resolvedFirstJoin then remote:FireServer("Sync") end
end)
help.MouseButton1Click:Connect(function()
    setOpen(true)
end)
UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
    if not processed and input.KeyCode == Enum.KeyCode.H then
        setOpen(not shade.Visible)
    end
end)
setOpen(false)
