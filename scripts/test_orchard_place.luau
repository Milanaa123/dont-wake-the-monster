-- Execute the shipped art bridge with Lune's Roblox instance model. Local file
-- mode exercises the same clone, sizing, hierarchy and weld code used in Studio.
local r=require("@lune/roblox")
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local serde=require("@lune/serde")
local process=require("@lune/process")
local file=assert(process.args[1],"Expected the Studio kit place")
local place=r.deserializePlace(fs.readFile(file))
local storage=place:GetService("ServerStorage")
local scripts=place:GetService("ServerScriptService")
local world=place:GetService("Workspace")
local replicated=place:GetService("ReplicatedStorage")
local rack=storage.StudioMeshFiles
local tasks={}
local scheduled={defer=function(fn) table.insert(tasks,fn) end}
local function drain()
    while #tasks>0 do table.remove(tasks,1)() end
end
local services={
    ServerStorage=storage, ReplicatedStorage=replicated, Lighting=place:GetService("Lighting"), AssetService={}, EncodingService={},
    HttpService={JSONDecode=function(_,v) return serde.decode("json",v) end},
    RunService={IsStudio=function() return true end},
}
local game={GetService=function(_,k) return assert(services[k],k) end}
r.implementMethod("Instance","WaitForChild",function(self,name) return assert(self:FindFirstChild(name),name) end)
r.implementMethod("BindableEvent","Fire",function() end)
local modules={}
local function load(module)
    local env={game=game,script=module,workspace=world,Instance=r.Instance,Enum=r.Enum,
        Vector2=r.Vector2,Vector3=r.Vector3,CFrame=r.CFrame,Color3=r.Color3,UDim2=r.UDim2,
        task=scheduled,require=function(m) return assert(modules[m.Name],m.Name) end}
    local result=luau.load(module.Source,{environment=env,injectGlobals=true,debugName=module.Name})()
    modules[module.Name]=result
    return result
end
local geometry=load(scripts.OrchardGeometry)
local bridge=load(scripts.ReferenceMeshLibrary)
local audio=load(replicated.AudioSource)
local n,sections=0,0
for _,record in storage.OrchardGeometry:GetChildren() do
    if record.Name=="Pigments" then continue end
    local template=assert(geometry.load(record.Name),record.Name)
    assert(template==geometry.load(record.Name),"cache miss")
    local info=serde.decode("json",record.Value)
    n+=1
    for _,part in info.parts do
        local source=rack[record.Name.."_"..part.name]
        assert(source.MeshContent.Uri:match("%.mesh$") and source.TextureContent.Uri:match("/pigments%.png$"))
        local member=if part.name=="Body" then template else template[part.name]
        assert(member:IsA("MeshPart") and member.Size.Magnitude>.01 and member.DoubleSided)
        sections+=1
    end
    if #info.parts>1 then
        local clone=template:Clone()
        local frame=r.CFrame.new(3,19,7)*r.CFrame.Angles(0,.6,0)
        geometry.mount(clone,frame,1.37)
        for _,child in clone:GetChildren() do
            local m=child:FindFirstChildOfClass("Motor6D")
            assert(m and m.Part1==child and not child.Anchored and m.Part0)
            local a,b=m.Part0.CFrame*m.C0,m.Part1.CFrame*m.C1
            assert((a.Position-b.Position).Magnitude<.001,"unconnected joint "..record.Name.."/"..child.Name)
        end
        clone:Destroy()
    end
end
assert(n==146 and sections==#rack:GetChildren())
assert(audio.resolve(0,"HarvestPop"):match("/HarvestPop%.wav$"))
assert(audio.resolve(123,"HarvestPop")=="rbxassetid://123")
local island=r.Instance.new("Folder")
island.Parent=world
local env=r.Instance.new("Folder")
env.Name="CottageGardenEnvironment"
env.Parent=island
local nativePond=r.Instance.new("Model")
nativePond.Name="ShadedOrchardPond"
nativePond.Parent=env
local pondTemplate=geometry.cached("Environment_WaterPond")
pondTemplate.Archivable=false
assert(bridge.applySetDress(island)==3 and nativePond.Parent==env)
pondTemplate.Archivable=true
assert(bridge.applySetDress(island)==4 and nativePond.Parent==nil)
local childCount=#env:GetChildren()
assert(bridge.applySetDress(island)==4 and #env:GetChildren()==childCount,"Duplicated orchard scenery on retry")
local pond=env.ImportedWaterPond
assert(math.abs(pond.CFrame.Position.Y-pond.Size.Y*.5-6.98)<.002 and not pond.CanCollide,
    "Pond bank should meet the island, even when reeds grow taller")
local frame=load(replicated.GardenCameraFrame)
local origin=r.Vector3.new(48,10,91)
local center=world:GetAttribute("GardenPondCenter")
assert(center==pond.CFrame.Position)
local frames={}
local function xyz(v) return {v.X,v.Y,v.Z} end
for name,viewport in {portrait={480,854},landscape={854,480}} do
    local aspect=viewport[1]/viewport[2]
    local focus,offset,fov=frame.at(origin,r.Vector3.zero,aspect,center)
    local oldFocus,oldOffset,oldFov=frame.at(origin,r.Vector3.zero,aspect,nil)
    local walking=frame.at(origin,r.Vector3.new(1,0,0),aspect,center)
    assert(offset==oldOffset and fov==oldFov and fov==(if name=="portrait" then 52 else 48))
    assert((focus-oldFocus).Magnitude<=8.001 and walking.Y==focus.Y)
    local far=r.Vector3.new(0,10,85)
    assert(frame.at(far,r.Vector3.zero,aspect,center)==frame.at(far,r.Vector3.zero,aspect,nil))
    local cam=r.CFrame.lookAt(focus+offset,focus)
    local function inside(worldPoint)
        local p=cam:PointToObjectSpace(worldPoint)
        local halfHeight=-p.Z*math.tan(math.rad(fov/2))
        return math.abs(p.Y)<halfHeight and math.abs(p.X)<halfHeight*aspect
    end
    assert(inside(origin),"Player left the pond view")
    for _,sx in {-1,1} do
        for _,sz in {-1,1} do
            local corner=pond.CFrame.Position+r.Vector3.new(sx*pond.Size.X*.5,-pond.Size.Y*.4,sz*pond.Size.Z*.5)
            assert(inside(corner),"Pond bank cropped in "..name)
        end
    end
    frames[name]={resolution=viewport,focus=xyz(focus),offset=xyz(offset),verticalFov=fov}
end
if process.args[3] then fs.writeFile(process.args[3],serde.encode("json",frames,true)) end
print("PASS: pond survives failed replacement, retries keep one orchard, and both garden camera frames include the bank")
assert(bridge.decorateEntrance(island)==31)
bridge.decorateWalkway(island)
drain()
assert(#island.OrchardWalkway:GetChildren()==22)
bridge.decorateWalkway(island)
drain()
assert(#island.OrchardWalkway:GetChildren()==22)
-- Capture the transforms of the actual entrance instances for Blender review.
-- This runs before the temporary specimens for the crop and pet tests are added.
if process.args[2] then
    local layout={}
    for _,mesh in island:GetDescendants() do
        if mesh:IsA("MeshPart") then
            local key=assert(mesh.MeshContent.Uri:match("/([^/]+)_Body%.mesh$"),mesh.Name)
            assert(storage.OrchardGeometry:FindFirstChild(key),key)
            table.insert(layout,{
                name=mesh.Name,asset=key,size={mesh.Size.X,mesh.Size.Y,mesh.Size.Z},
                cframe={mesh.CFrame:GetComponents()},
            })
        end
    end
    assert(#layout==66,"Expected 31 plantings, 13 scenery instances and 22 walkway meshes")
    table.sort(layout,function(a,b) return a.name<b.name end)
    fs.writeFile(process.args[2],serde.encode("json",layout,true))
end
local count=0
for _,record in storage.OrchardGeometry:GetChildren() do
    local seed,stage=record.Name:match("^Crop_(.+)_S(%d)$")
    if seed then
        local plot=r.Instance.new("Model")
        plot.Parent=island
        assert(bridge.applyCrop(plot,r.Vector3.new(2,7,3),seed,tonumber(stage)))
        local mesh=plot.ImportedCropMesh
        assert(math.max(mesh.Size.X,mesh.Size.Z)<=7.301 and not mesh.CanQuery and not mesh.CanCollide)
        count+=1
        plot:Destroy()
    end
end
assert(count==90)
local pet=r.Instance.new("Model")
pet.Parent=island
local root=r.Instance.new("Part")
root.Parent=pet
pet.PrimaryPart=root
local old=r.Instance.new("Part")
old.Parent=pet
assert(bridge.applyPet(pet,"Pip"))
assert(old.Parent==nil and root.Transparency==1 and pet.ImportedCharacterMesh:HasTag("OrchardRig"))
assert(pet.ImportedCharacterMesh.Head.Head.Part0==pet.ImportedCharacterMesh)
local outfit=r.Instance.new("Model")
outfit.Parent=world
local humanoid=r.Instance.new("Humanoid")
humanoid.RigType=r.Enum.HumanoidRigType.R15
humanoid.Parent=outfit
for _,record in storage.OrchardGeometry:GetChildren() do
    local limb=record.Name:match("^Avatar_(.+)")
    if limb then
        local part=r.Instance.new("Part")
        part.Name=limb
        part.Parent=outfit
    end
end
assert(bridge.applyGardenerAvatar(outfit) and #outfit.StorybookGardener:GetChildren()==15)
assert(bridge.applyGardenerAvatar(outfit) and #outfit.StorybookGardener:GetChildren()==15)
for _,piece in outfit.StorybookGardener:GetChildren() do
    assert(piece.AnimatedR15Attachment.Part1==piece and piece.AnimatedR15Attachment.Part0.Parent==outfit)
end
drain()
print(string.format("PASS: parsed Studio place, mounted %d assets / %d mesh sections, checked all rigid bind poses, 90 crop bounds, 31 entrance plants, pet rig and 15 moving R15 attachments",n,sections))

-- Step the shipped client against the mounted Motor6Ds in the built place.
-- Only the engine clock, streaming signals and camera are supplied by this harness.
local function signal()
    local event={}
    function event:Connect(callback)
        self.callback=callback
        return {Disconnect=function() self.callback=nil end}
    end
    return event
end

local roots={}
local function fixture(key,modelName)
    local model=r.Instance.new("Model")
    model.Name=modelName
    model.Parent=island
    local body=geometry.load(key):Clone()
    geometry.mount(body,r.CFrame.new(),1)
    body.Parent=model
    local root={
        Name=key,Parent=model,Position=r.Vector3.zero,
        DescendantAdded=signal(),DescendantRemoving=signal(),
        IsA=function(_,class) return class=="BasePart" end,
        GetDescendants=function() return body:GetDescendants() end,
    }
    table.insert(roots,root)
    return model,body
end

local _,idleBody=fixture("Pet_Floofle","Floofle")
local responding,activeBody=fixture("Pet_Floofle","Floofle")
local bossModel,bossBody=fixture("Environment_SleepingMonster","GigglesTheGiant")
local _,sleepingBody=fixture("Environment_SleepingMonster","GigglesTheGiant")
local owlet,owlBody=fixture("Pet_Swoop","Swoop")
local openEyes=owlBody.Blink.Size
assert(owlBody.Blink.Blink.Part0==owlBody.Head)
local lamb,lambBody=fixture("Pet_Tofu","RescueRunaway_2")
local comparison,comparisonBody=fixture("Pet_Tofu","RescueRunaway_2")
lamb:SetAttribute("PetSpecies","Tofu")
comparison:SetAttribute("PetSpecies","Tofu")
local frameEvent=signal()
local tags={
    GetTagged=function(_,tag) return if tag=="OrchardRig" then roots else {} end,
    GetInstanceAddedSignal=signal,GetInstanceRemovedSignal=signal,
}
local clock=10
local rigScript=place:GetService("StarterPlayer").StarterPlayerScripts.OrchardRigMotion
local env={
    game={GetService=function(_,name)
        if name=="RunService" then return {PreSimulation=frameEvent} end
        assert(name=="CollectionService")
        return tags
    end},
    os={clock=function() return clock end},
    workspace={CurrentCamera={CFrame=r.CFrame.new(0,1,5)},GetServerTimeNow=function() return clock end},
    UserSettings=function() return {GetService=function() return {SavedQualityLevel={Value=3}} end} end,
    Vector2=r.Vector2,Vector3=r.Vector3,CFrame=r.CFrame,
}
luau.load(rigScript.Source,{environment=env,injectGlobals=true,debugName=rigScript.Name})()
local function step(frames)
    for _=1,frames do
        clock+=1/15
        frameEvent.callback()
    end
end
local function poseDifference(first,second,joint)
    local a=first[joint][joint].Transform
    local b=second[joint][joint].Transform
    return (a.LookVector-b.LookVector).Magnitude+(a.UpVector-b.UpVector).Magnitude
end
local function difference(joint)
    return poseDifference(activeBody,idleBody,joint)
end
-- Lune does not simulate Motor6D physics. Resolve the shipped joint hierarchy
-- for an offline mesh review, including each part's animated eye size.
local function capturePose(poses,body,key,label,path)
    if not path then return end
    local parts={}
    local function frame(part)
        local joint=part:FindFirstChildOfClass("Motor6D")
        if not joint then return part.CFrame end
        return frame(joint.Part0)*joint.C0*joint.Transform*joint.C1:Inverse()
    end
    local function record(name,part)
        local eyelid=name:match("^Lid") or name:match("^Eye")
        parts[name]={cframe={frame(part):GetComponents()},size=xyz(part.Size),
            hidden=if eyelid then part.LocalTransparencyModifier>=.99 else nil}
    end
    record("Body",body)
    for _,part in body:GetChildren() do
        if part:IsA("MeshPart") then record(part.Name,part) end
    end
    table.insert(poses,{label=label,asset=key,parts=parts})
end
local poses={}
local bossPoses={}
local function captureLamb(label)
    capturePose(poses,lambBody,"Pet_Tofu",label,process.args[4])
end
local function captureBoss(label)
    capturePose(bossPoses,bossBody,"Environment_SleepingMonster",label,process.args[5])
end
step(3)
assert(difference("Head")<.0001)
responding:SetAttribute("FedAt",clock)
step(6)
assert(difference("Head")>.025 and difference("ForeL")>.02 and difference("EarR")>.018,
    "Accepted feed must move the face, forepaws and ears")
step(15)
assert(difference("Head")<.0001,"A finished feed should return to the ongoing idle pose")
responding:SetAttribute("MotionMode","Pet")
step(20)
assert(difference("Head")>.20 and difference("EarL")>.10,"Petting pose missing")
responding:SetAttribute("MotionMode","Nap")
step(20)
assert(difference("Head")>.30 and difference("EarR")>.25,"Napping pose missing")
assert(bossBody.EyeL.LocalTransparencyModifier>.99 and bossBody.LidL.LocalTransparencyModifier<.01)
captureBoss("Asleep")
bossModel:SetAttribute("Stirring",true)
step(16)
assert(poseDifference(bossBody,sleepingBody,"Head")>.15 and poseDifference(bossBody,sleepingBody,"ArmL")>.4)
assert(bossBody.EyeL.LocalTransparencyModifier>.99 and bossBody.LidL.LocalTransparencyModifier<.01)
captureBoss("Stirring")
bossModel:SetAttribute("Stirring",false)
step(20)
assert(poseDifference(bossBody,sleepingBody,"Head")<.001 and poseDifference(bossBody,sleepingBody,"ArmL")<.001)
bossModel:SetAttribute("Awake",true)
step(23)
assert(bossBody.EyeL.LocalTransparencyModifier<.01 and bossBody.LidL.LocalTransparencyModifier>.99)
captureBoss("Awake")
if process.args[5] then fs.writeFile(process.args[5],serde.encode("json",bossPoses,true)) end
print("PASS: mounted boss stirs with eyes closed, settles when soothed, then opens eyes on waking")
print("PASS: shipped client drives feed, recovery, petting, nap and boss eyelids on mounted joints at low quality")

captureLamb("Idle")
lamb:SetAttribute("FedAt",clock)
step(2)
captureLamb("LeadingEar")
local function lambDifference(joint)
    return poseDifference(lambBody,comparisonBody,joint)
end
assert(lambDifference("EarL")>lambDifference("EarR")+.08,"Leading ear should lift first")
step(4)
captureLamb("FollowingEar")
assert(lambDifference("EarR")>lambDifference("EarL")+.10,"Trailing ear should follow")
step(15)
assert(lambDifference("EarL")<.0001 and lambDifference("EarR")<.0001,"Ears should settle")
lamb:SetAttribute("MotionMode","Pet")
step(18)
captureLamb("Stroke")
assert(lambDifference("Head")>.3 and lambDifference("EarR")>.2,"Lamb should lean into a stroke")
lamb:SetAttribute("MotionMode","Follow")
step(20)
assert(lambDifference("Head")<.001,"Ending a stroke should release the head")
if process.args[4] then fs.writeFile(process.args[4],serde.encode("json",poses,true)) end
print("PASS: both ears of a renamed rescue lamb follow the feed in sequence, settle and respond to petting")

owlet:SetAttribute("MotionMode","Nap")
step(20)
assert(owlBody.Blink.Size.Y<openEyes.Y*.16,"Sleep should close both eyes")
assert(owlBody.Blink.Size.X==openEyes.X and owlBody.Blink.Size.Z==openEyes.Z)
owlet:SetAttribute("MotionMode","Follow")
step(20)
local minHeight,maxHeight=math.huge,0
for _=1,90 do
    step(1)
    minHeight=math.min(minHeight,owlBody.Blink.Size.Y)
    maxHeight=math.max(maxHeight,owlBody.Blink.Size.Y)
end
assert(minHeight<openEyes.Y*.35 and maxHeight>openEyes.Y*.99,"Awake owlet must reopen and blink")
print("PASS: owlet sleeps, wakes and blinks on its mounted face")

local cottage=load(scripts.CottageGardenStyle)
local farm=r.Instance.new("Model")
farm.Parent=island
local bed=r.Instance.new("Model")
bed.Name="Plot_1"
bed.Parent=farm
cottage.styleEntrance(farm,r.CFrame.new(),"Cottage")
drain()
local shelter=farm.EntranceDecor.Environment_GardenCottage
assert(not shelter.CanCollide and not shelter.CanQuery)
cottage.styleEntrance(farm,r.CFrame.new(),"Cottage")
drain()
assert(farm.EntranceDecor.Environment_GardenCottage==shelter)
cottage.styleEntrance(farm,r.CFrame.new(),"Blossom")
drain()
assert(#farm.EntranceDecor:GetChildren()==2 and shelter.Parent==nil)
cottage.styleEntrance(farm,r.CFrame.new(),"Meadow")
assert(not farm:FindFirstChild("EntranceDecor") and farm.Plot_1==bed)
print("PASS: live garden style swap reuses original mesh templates, preserves beds and removes stale decorations")
