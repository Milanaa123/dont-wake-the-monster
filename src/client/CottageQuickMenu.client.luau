--!strict
-- Keeps the first mobile garden view clear: secondary menus collapse behind
-- one genuine working button. Original buttons and click handlers are reused.
-- Desktop retains native layout. No decorative / inert controls.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remote = ReplicatedStorage:WaitForChild("MonsterRemote") :: RemoteEvent

local targets = {
    {"CollectionGui", "OpenCollection"},
    {"CollectionGui", "DailyTreat"},
    {"GardenGui", "GardenOpen"},
    {"SeedExplorer", "OpenSeedExplorer"},
    {"PetDiary", "OpenDiary"},
    {"CottageCameraGui", "CameraMode"},
    {"AudioSettings", "MusicToggle"},
    {"AudioSettings", "EffectsToggle"},
    {"HowToPlayGui", "ReopenTutorial"},
}

type ControlState = {
    control: GuiButton,
    pos: UDim2,
    anchor: Vector2,
    size: UDim2,
}
local originals: {[GuiButton]: ControlState} = {}
local watched: {[GuiButton]: boolean} = {}
local expanded = false
local chasing = false
local compact = false

local root = Instance.new("ScreenGui")
root.Name = "CottageQuickMenu"
root.ResetOnSpawn = false
root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
root.DisplayOrder = 21
root.Parent = playerGui

local button = Instance.new("TextButton")
button.Name = "QuickMenuToggle"
button.Position = UDim2.fromOffset(12, 191)
button.Size = UDim2.fromOffset(136, 43)
button.BackgroundColor3 = Color3.fromRGB(255, 246, 221)
button.TextColor3 = Color3.fromRGB(75, 70, 64)
button.Font = Enum.Font.GothamBlack
button.TextScaled = true
button.Text = "🌼 MENU"
button.AutoButtonColor = true
button.BorderSizePixel = 0
button.Parent = root
local round = Instance.new("UICorner")
round.CornerRadius = UDim.new(0, 13)
round.Parent = button
local outline = Instance.new("UIStroke")
outline.Color = Color3.fromRGB(180, 155, 128)
outline.Transparency = .36
outline.Thickness = 1.3
outline.Parent = button
local textSize = Instance.new("UITextSizeConstraint")
textSize.MinTextSize = 11
textSize.MaxTextSize = 16
textSize.Parent = button

local function viewport(): Vector2
    local camera = Workspace.CurrentCamera
    return if camera then camera.ViewportSize else Vector2.new(800, 600)
end

local function refresh()
    local frame = viewport()
    compact = UserInputService.TouchEnabled or frame.X < 760
    local top=math.clamp(math.floor(frame.Y*.24),75,191)
    local firstRow=top+48
    local rows=math.max(1,math.floor((frame.Y-firstRow-54)/40))
    local columns=math.ceil(#targets/rows)
    local width=math.clamp(math.floor((frame.X-30)/columns)-5,80,155)
    button.Position=UDim2.fromOffset(12,top)
    button.Visible = compact and not chasing
    button.Text = if expanded then "✕ CLOSE MENU" else "🌼 MENU"

    for index, match in ipairs(targets) do
        local gui = playerGui:FindFirstChild(match[1])
        local control = if gui then gui:FindFirstChild(match[2],true) else nil
        if control and control:IsA("GuiButton") then
            if not originals[control] then
                originals[control] = {
                    control = control,
                    pos = control.Position,
                    anchor = control.AnchorPoint,
                    size = control.Size,
                }
            end
            local original = originals[control]
            if compact then
                control.AnchorPoint = Vector2.new(0, 0)
                control.Position = UDim2.fromOffset(12+math.floor((index-1)/rows)*(width+5),firstRow+(index-1)%rows*40)
                control.Size = UDim2.fromOffset(width,36)
                control.Visible = expanded and not chasing
                if not watched[control] then
                    watched[control] = true
                    control.Activated:Connect(function()
                        expanded = false
                        refresh()
                    end)
                end
            else
                control.AnchorPoint = original.anchor
                control.Position = original.pos
                control.Size = original.size
                control.Visible = true
            end
        end
    end
end

button.Activated:Connect(function()
    if chasing then return end
    expanded = not expanded
    refresh()
end)

remote.OnClientEvent:Connect(function(payload: any)
    if type(payload) ~= "table" or payload.type ~= "state" then return end
    local newChasing = payload.phase == "AWAKE"
    if newChasing ~= chasing then
        chasing = newChasing
        if chasing then expanded = false end
        refresh()
    end
end)

playerGui.DescendantAdded:Connect(function(added: Instance)
    if not added:IsA("GuiButton") then return end
    task.defer(refresh)
end)

local camera = Workspace.CurrentCamera
if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh) end
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    local newCamera = Workspace.CurrentCamera
    if newCamera then
        newCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
    end
    refresh()
end)

task.defer(refresh)
task.delay(1.0, refresh)
task.delay(3.0, refresh)
