--!strict
-- Cozy three-quarter camera for gardening, normal follow view for dangerous chases.
-- Gameplay mode changes are driven by the server's existing phase messages.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("MonsterRemote") :: RemoteEvent
local preferredGarden = true
local lastPhase = "SLEEP"
local appliedGarden = false
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
toggle.Position = UDim2.fromOffset(12, 342)
toggle.Size = UDim2.fromOffset(152, 42)
toggle.BackgroundColor3 = Color3.fromRGB(245, 237, 206)
toggle.BorderSizePixel = 0
toggle.TextColor3 = Color3.fromRGB(67, 67, 63)
toggle.Font = Enum.Font.GothamBlack
toggle.TextScaled = true
toggle.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 13)
corner.Parent = toggle
local limit = Instance.new("UITextSizeConstraint")
limit.MinTextSize = 11
limit.MaxTextSize = 15
limit.Parent = toggle

local function applyMode()
    local camera = workspace.CurrentCamera
    local shouldGarden = preferredGarden and lastPhase ~= "AWAKE"
    toggle.Active = lastPhase ~= "AWAKE"
    toggle.AutoButtonColor = lastPhase ~= "AWAKE"
    toggle.Text = if lastPhase == "AWAKE" then "🏃 CHASE VIEW"
        elseif shouldGarden then "🍃 GARDEN VIEW (V)" else "🎮 FOLLOW VIEW (V)"
    if not camera then
        appliedGarden = shouldGarden
        return
    end
    if appliedGarden == shouldGarden and camera.CameraType == (if shouldGarden then Enum.CameraType.Scriptable else Enum.CameraType.Custom) then
        return
    end
    if shouldGarden then
        if camera.CameraType ~= Enum.CameraType.Scriptable then
            normalFov = camera.FieldOfView
        end
        currentFocus = nil
        camera.CameraType = Enum.CameraType.Scriptable
        camera.FieldOfView = viewFov
    else
        currentFocus = nil
        camera.CameraType = Enum.CameraType.Custom
        camera.FieldOfView = normalFov
        local character = player.Character
        local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
        if humanoid then camera.CameraSubject = humanoid end
    end
    appliedGarden = shouldGarden
end

local function togglePreferred()
    if lastPhase == "AWAKE" then return end
    preferredGarden = not preferredGarden
    applyMode()
end

toggle.MouseButton1Click:Connect(togglePreferred)
UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
    if not processed and input.KeyCode == Enum.KeyCode.V then
        togglePreferred()
    end
end)

remote.OnClientEvent:Connect(function(event: any)
    if type(event) ~= "table" or event.type ~= "state" then return end
    if type(event.phase) ~= "string" or event.phase == lastPhase then return end
    lastPhase = event.phase
    -- Close camera angle is unsuitable for survival rounds: return standard
    -- Roblox mobile/gamepad/keyboard camera control until the chase is over.
    applyMode()
end)

local function render(delta: number)
    if not appliedGarden then return end
    local camera = workspace.CurrentCamera
    local character = player.Character
    local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
    if not camera or not root or not root:IsA("BasePart") then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local lookAhead = if humanoid then humanoid.MoveDirection * 3.4 else Vector3.zero
    local target = root.Position + Vector3.new(0, 3, 0) + lookAhead
    local smoothing = math.clamp(1 - math.exp(-delta * 7.2), 0, 1)
    currentFocus = if currentFocus then currentFocus:Lerp(target, smoothing) else target
    local focus = currentFocus :: Vector3
    local desired = CFrame.lookAt(focus + cameraOffset, focus)
    camera.CameraType = Enum.CameraType.Scriptable
    camera.FieldOfView = viewFov
    camera.CFrame = camera.CFrame:Lerp(desired, smoothing)
    camera.Focus = CFrame.new(focus)
end

player.CharacterAdded:Connect(function()
    task.defer(applyMode)
end)
RunService:BindToRenderStep("CottageGardenCamera", Enum.RenderPriority.Camera.Value + 1, render)
applyMode()
