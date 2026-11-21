--!strict
-- Layer tool-free interactions over the Animator's current R15 pose. Remove
-- our previous offset before it evaluates the next idle/walk/run track.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local offsets: {[Motor6D]: CFrame} = {}
local actors: {[Model]: any} = {}

local function watch(player: Player)
    local function attach(character: Model)
        actors[character]={joints={},blend=0,carry=0,pet=0,nextScan=0}
    end
    player.CharacterAdded:Connect(attach)
    player.CharacterRemoving:Connect(function(character) actors[character]=nil end)
    if player.Character then attach(player.Character) end
end
Players.PlayerAdded:Connect(watch)
for _,player in ipairs(Players:GetPlayers()) do watch(player) end

RunService.PreAnimation:Connect(function()
    for motor,offset in pairs(offsets) do
        if motor.Parent then motor.Transform=motor.Transform*offset:Inverse() end
    end
    table.clear(offsets)
end)

RunService.PreSimulation:Connect(function(dt)
    local now=workspace:GetServerTimeNow()
    local camera=workspace.CurrentCamera
    if not camera then return end
    for character,actor in pairs(actors) do
        local root=character:FindFirstChild("HumanoidRootPart")
        if not root or not root:IsA("BasePart") or (root.Position-camera.CFrame.Position).Magnitude>100 then continue end
        local mode=character:GetAttribute("GardenCare")
        local t=now-(character:GetAttribute("GestureAt") or -10)
        local reach=if t>=0 and t<1.1 then math.sin(math.pi*t/1.1)^2 else 0
        local blend=1-math.exp(-dt*10)
        actor.carry+=((if mode=="Carry" then 1 else 0)-actor.carry)*blend
        actor.pet+=((if mode=="Pet" then 1 else 0)-actor.pet)*blend
        if reach+actor.carry+actor.pet<.001 then continue end
        if now>=actor.nextScan then
            table.clear(actor.joints)
            for _,j in ipairs(character:GetDescendants()) do
                if j:IsA("Motor6D") and j.Part1 then actor.joints[j.Name]=j end
            end
            actor.nextScan=now+2
        end
        local harvest=character:GetAttribute("GardenGesture")=="GardenHarvest"
        local stroke=(.76+.24*math.sin(now*5))*actor.pet
        local function pose(name: string,x: number,y: number,z: number)
            local j=actor.joints[name]
            if j and j.Parent then
                local delta=CFrame.Angles(x,y,z)
                j.Transform*=delta
                offsets[j]=delta
            end
        end
        pose("Waist",-.32*reach-.15*stroke,0,0)
        pose("Neck",-.15*reach+.08*actor.carry,0,.06*actor.pet)
        pose("RightShoulder",.92*reach+.76*actor.carry+.88*stroke,-.12*reach,.21*actor.carry)
        pose("LeftShoulder",(if harvest then .67 else .20)*reach+.76*actor.carry,0,-.21*actor.carry)
        pose("RightElbow",.67*actor.carry+.32*stroke+.32*reach,0,0)
        pose("LeftElbow",.67*actor.carry+.26*reach,0,0)
        pose("RightHip",.23*reach,0,0)
        pose("RightKnee",-.32*reach,0,0)
    end
end)
