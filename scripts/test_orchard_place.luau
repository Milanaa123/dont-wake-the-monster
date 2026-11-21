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
    ServerStorage=storage, ReplicatedStorage=replicated, AssetService={}, EncodingService={},
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
assert(bridge.applySetDress(island)==4)
assert(bridge.decorateEntrance(island)==31)
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
