--!strict
-- Optional three-quarter camera: evokes a cozy garden game without locking players
-- into it during the monster chase. Button and V key switch to Roblox camera.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local enabled = true
local viewFov = 53
local normalFov = 70
local cameraOffset = Vector3.new(30, 40, 34)
local currentFocus: Vector3? = nil

local gui = Instance.new("ScreenGui")
gui.Name = "CottageCameraGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 4
gui.Parent = player:WaitForChild("PlayerGui")

local toggle = Instance.new("TextButton")
toggle.Name = "CameraMode"
toggle.AnchorPoint = Vector2.new(1, 0)
toggle.Position = UDim2.new(1, -12, 0, 372)
toggle.Size = UDim2.fromOffset(152, 42)
toggle.BackgroundColor3 = Color3.fromRGB(245, 237, 206)
toggle.BorderSizePixel = 0
toggle.TextColor3 = Color3.fromRGB(67, 67, 63)
toggle.Font = Enum.Font.GothamBlack
toggle.TextScaled = true
toggle.Text = "🍃 GARDEN VIEW"
toggle.Parent = gui
local c = Instance.new("UICorner")
c.CornerRadius = UDim.new(0, 13)
c.Parent = toggle
local limit = Instance.new("UITextSizeConstraint")
limit.MinTextSize = 11
limit.MaxTextSize = 15
limit.Parent = toggle

local function setMode(nextValue: boolean)
    enabled = nextValue
    currentFocus = nil
    toggle.Text = if enabled then "🍃 GARDEN VIEW (V)" else "🎮 FOLLOW VIEW (V)"
    local camera = workspace.CurrentCamera
    if not camera then return end
    if enabled then
        -- The scriptable view is rendered locally and never affects server physics.
        normalFov = if camera.CameraType ~= Enum.CameraType.Scriptable then camera.FieldOfView else normalFov
        camera.CameraType = Enum.CameraType.Scriptable
        camera.FieldOfView = viewFov
    else
        camera.CameraType = Enum.CameraType.Custom
        camera.FieldOfView = normalFov
        local character = player.Character
        local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
        if humanoid then camera.CameraSubject = humanoid end
    end
end

local function render(delta: number)
    if not enabled then return end
    local camera = workspace.CurrentCamera
    local character = player.Character
    local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
    if not camera or not root or not root:IsA("BasePart") then return end

    local target = root.Position + Vector3.new(0, 3, 0)
    local smoothing = math.clamp(1 - math.exp(-delta * 7.2), 0, 1)
    currentFocus = if currentFocus then currentFocus:Lerp(target, smoothing) else target
    local focus = currentFocus :: Vector3
    local desired = CFrame.lookAt(focus + cameraOffset, focus)
    camera.CameraType = Enum.CameraType.Scriptable
    camera.FieldOfView = viewFov
    camera.CFrame = camera.CFrame:Lerp(desired, smoothing)
    camera.Focus = CFrame.new(focus)
end

toggle.MouseButton1Click:Connect(function()
    setMode(not enabled)
end)
UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
    if not processed and input.KeyCode == Enum.KeyCode.V then
        setMode(not enabled)
    end
end)

RunService:BindToRenderStep("CottageGardenCamera", Enum.RenderPriority.Camera.Value + 1, render)
setMode(true)
