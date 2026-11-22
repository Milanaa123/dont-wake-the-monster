--!strict
-- Motor transforms are local to each bind pose. The server owns root movement
-- and interaction state. The artistic rig never drives collision or rewards.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local settings = UserSettings():GetService("UserGameSettings")
local rigs: {[BasePart]: any} = {}

local function track(root: Instance)
    if not root:IsA("BasePart") then return end
    local model = root.Parent
    if not model or not model:IsA("Model") then return end
    local joints = {}
    for _, child in ipairs(root:GetDescendants()) do
        if child:IsA("Motor6D") and child.Part1 then joints[child.Name] = child end
    end
    local seed=0
    for i=1,#model.Name do seed=(seed*31+string.byte(model.Name,i))%367 end
    local added=root.DescendantAdded:Connect(function(item)
        if item:IsA("Motor6D") then joints[item.Name]=item end
    end)
    local removed=root.DescendantRemoving:Connect(function(item)
        if joints[item.Name]==item then joints[item.Name]=nil end
    end)
    rigs[root] = {model=model,joints=joints,added=added,removed=removed,prev=root.Position,phase=seed*.37,
        travel=0,rest=0,hold=0,stroke=0,wake=0,last=os.clock(),seed=seed}
end

CollectionService:GetInstanceAddedSignal("OrchardRig"):Connect(track)
CollectionService:GetInstanceRemovedSignal("OrchardRig"):Connect(function(root)
    local rig=rigs[root :: BasePart]
    if rig then rig.added:Disconnect() rig.removed:Disconnect() end
    rigs[root :: BasePart]=nil
end)
for _,root in ipairs(CollectionService:GetTagged("OrchardRig")) do track(root) end

RunService.PreSimulation:Connect(function()
    local camera=workspace.CurrentCamera
    if not camera then return end
    local quality=settings.SavedQualityLevel.Value
    local low=quality>0 and quality<=3
    local now=os.clock()
    for root,r in pairs(rigs) do
        local distance=(root.Position-camera.CFrame.Position).Magnitude
        local dt=now-r.last
        if distance>(if low then 110 else 175) then
            r.prev=root.Position
            r.last=now
            continue
        end
        if dt < (if low or distance>70 then 1/20 else 1/45) then continue end
        local delta=root.Position-r.prev
        local speed=math.min(24,Vector2.new(delta.X,delta.Z).Magnitude/math.max(dt,.001))
        r.prev=root.Position
        r.last=now
        dt=math.min(dt,.12)
        local blend=1-math.exp(-dt*7)
        local model=r.model
        local mode=model:GetAttribute("MotionMode")
        local boss=model.Name=="GigglesTheGiant"
        local function fade(value: number, target: number): number
            return value+(target-value)*blend
        end
        r.travel=fade(r.travel,if mode=="Carry" or mode=="Nap" or boss then 0 else math.clamp(speed/8,0,1))
        r.rest=fade(r.rest,if mode=="Nap" then 1 else 0)
        r.hold=fade(r.hold,if mode=="Carry" then 1 else 0)
        r.stroke=fade(r.stroke,if mode=="Pet" then 1 else 0)
        r.wake=fade(r.wake,if model:GetAttribute("Awake") then 1 else 0)
        r.phase+=dt*(2.2+math.min(speed,17)*.61)
        local beat=math.sin(r.phase)
        local breath=math.sin(now*(if boss then 1.13 else 1.92)+r.seed)
        local nibble=0
        local fedAt=model:GetAttribute("FedAt")
        if type(fedAt)=="number" then
            local age=workspace:GetServerTimeNow()-fedAt
            if age>=0 and age<1.2 then
                nibble=math.sin(math.pi*age/1.2)^2 * (.60+.40*math.sin(age*16))
            end
        end
        local attack=0
        if boss then
            local stamp=model:GetAttribute("AttackAt")
            if type(stamp)=="number" then
                local t=workspace:GetServerTimeNow()-stamp
                if t>=0 and t<1.3 then attack=math.sin(math.pi*t/1.3)^2 end
            end
        end
        for name,joint in pairs(r.joints) do
            if not joint.Part1 then continue end
            local side=if name:sub(-1)=="L" then -1 else 1
            local x,y,z=0,0,0
            if name=="Head" then
                x=.055*breath+.09*r.travel*math.cos(r.phase*2)+.45*r.rest-.17*r.stroke+.22*nibble
                y=.10*math.sin(now*.94+r.seed)*(1-r.travel)+.28*r.stroke
                z=.08*r.hold
                if boss then x=.26*(1-r.wake)+.045*breath-.31*attack end
            elseif name:match("^Ear") then
                x=.035*breath+.09*math.cos(r.phase*2-.48)*r.travel+.38*r.rest-.16*r.stroke
                z=side*(.035*breath+.12*nibble+.09*r.hold)
            elseif name:match("^Fore") or name:match("^Hind") then
                local pair=if name:match("^Fore") then 1 else -1
                x=beat*side*pair*r.travel*.67+pair*(r.rest*.60+r.hold*.37)
                if pair==1 then x-=.17*nibble end
            elseif name=="Tail" then
                y=math.sin(now*(2.1+1.8*r.stroke)+r.seed)*(.17+.25*r.stroke)+.12*beat*r.travel+.24*nibble
                x=.13*r.hold-.25*r.rest
            elseif name:match("^Wing") or name:match("^Gill") or name:match("^Claw") then
                z=side*(.13*breath+(.22+.38*r.travel)*beat*(1-r.rest)-.28*r.hold+.18*nibble)
            elseif name:match("^Tendril") then
                x=.15*math.sin(r.phase+(tonumber(name:sub(8)) or 0)*.82)
            elseif name:match("^Arm") then
                x=.13*breath-.30*r.wake-.87*attack
                z=side*(.08*breath+.10*r.wake+.18*attack)
            elseif name:match("^Leg") then
                x=-.18*(1-r.wake)+side*.15*attack
                if model:GetAttribute("Walking") then x+=side*.26*math.sin(now*3.4) end
            elseif name:match("^Eye") then
                joint.Part1.LocalTransparencyModifier=1-r.wake
            elseif name:match("^Lid") then
                joint.Part1.LocalTransparencyModifier=r.wake
            end
            joint.Transform=CFrame.Angles(x,y,z)
        end
    end
end)
