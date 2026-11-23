--!strict
-- Resolve private imported artwork first, then the geometry shipped in the place.
local ServerStorage = game:GetService("ServerStorage")

local Geometry = require(script.Parent.OrchardGeometry)
local Bridge = {}
local ROOT_NAME = "DWTM_ArtLibrary"

local staged = false
local function stageImportedPacks()
    if staged then return end
    staged = true
    -- Studio Importer (File > Import) can insert the three original GLB packs
    -- into Workspace. On Play, move those verified mesh assets to ServerStorage.
    -- Does not need a plugin, API key, or any new permissions.
    local known = {
        {pack = "DWTM_Pets_30", folder = "Pets", prefix = "Pet_"},
        {pack = "DWTM_Crops_30x3", folder = "Crops", prefix = "Crop_"},
        {pack = "DWTM_World_8", folder = "World", prefix = "Environment_"},
        {pack = "DWTM_Gardener_Avatar_15", folder = "Avatar", prefix = "Avatar_"},
    }
    local root = ServerStorage:FindFirstChild(ROOT_NAME)
    for _, item in ipairs(known) do
        for _, container in ipairs(workspace:GetChildren()) do
            if string.sub(container.Name, 1, #item.pack) == item.pack then
                local found = {}
                if container:IsA("MeshPart") then
                    table.insert(found, container)
                end
                for _, descendant in ipairs(container:GetDescendants()) do
                    if descendant:IsA("MeshPart") and
                        string.sub(descendant.Name, 1, #item.prefix) == item.prefix then
                        table.insert(found, descendant)
                    end
                end
                if #found > 0 then
                    if not root then
                        root = Instance.new("Folder")
                        root.Name = ROOT_NAME
                        root.Parent = ServerStorage
                    end
                    local folder = root:FindFirstChild(item.folder)
                    if not folder then
                        folder = Instance.new("Folder")
                        folder.Name = item.folder
                        folder.Parent = root
                    end
                    for _, mesh in ipairs(found) do
                        if string.sub(mesh.Name, 1, #item.prefix) == item.prefix then
                            mesh.Anchored = true
                            mesh.CanCollide = false
                            mesh.CanTouch = false
                            mesh.CanQuery = false
                            mesh.Parent = folder
                        end
                    end
                    if container.Parent == workspace then container:Destroy() end
                end
            end
        end
    end
end

local function findMesh(groupName: string, assetName: string): MeshPart?
    stageImportedPacks()
    local root = ServerStorage:FindFirstChild(ROOT_NAME)
    local group = if root then root:FindFirstChild(groupName) else nil
    local obj = if group then group:FindFirstChild(assetName,true) else nil
    if obj and obj:IsA("MeshPart") then return obj end
    if obj and obj:IsA("Model") then
        local mesh = obj:FindFirstChildWhichIsA("MeshPart",true)
        if mesh then return mesh end
    end
    return Geometry.cached(assetName)
end

function Bridge.prepare(owner: Instance, group: string, keys: {string}, ready: () -> (), failed: (() -> ())?)
    task.defer(function()
        for _, key in ipairs(keys) do
            if not owner.Parent then return end
            if not findMesh(group,key) and not Geometry.load(key) then
                if failed and owner.Parent then failed() end
                return
            end
        end
        if owner.Parent then ready() end
    end)
end

local function makeVisual(source: MeshPart, parent: Instance, name: string,
    pivot: CFrame, height: number): MeshPart?
    if not source.Archivable then return nil end
    local mesh = source:Clone()
    mesh.Name = name
    mesh.Anchored = true
    mesh.CanCollide = false
    mesh.CanTouch = false
    mesh.CanQuery = false
    mesh.CastShadow = true

    -- Sanity bounds: avoid importer meter/stud scale mistakes taking over
    -- the island or producing a near-invisible animal.
    if mesh.Size.X < 0.001 or mesh.Size.Y < 0.001 or mesh.Size.Z < 0.001 then
        mesh:Destroy()
        return nil
    end
    local full = source:GetAttribute("ArtSize") or mesh.Size
    local sourceSpan = if name == "ImportedWaterPond" then math.max(full.X, full.Z)
        else full.Y
    local ratio = height / math.max(sourceSpan, 0.001)
    mesh.Size = mesh.Size * ratio
    Geometry.mount(mesh,pivot,ratio)
    mesh:SetAttribute("VisualOffset",(mesh:GetAttribute("PieceCenter") or Vector3.zero)*ratio)
    if mesh:FindFirstChildWhichIsA("Motor6D",true) then mesh:AddTag("OrchardRig") end
    mesh.Parent = parent
    return mesh
end

-- Place a ground-hugging asset by its horizontal span, keeping the authored aspect.
function Bridge.ground(owner: Instance, key: string, frame: CFrame, span: number, replaced: Instance?)
    local group=if key:sub(1,5)=="Crop_" then "Crops" else "World"
    Bridge.prepare(owner,group,{key},function()
        local source=findMesh(group,key)
        if not source then return end
        local height=span*source.Size.Y/math.max(source.Size.X,source.Size.Z)
        local mesh=makeVisual(source,owner,key,frame*CFrame.new(0,height/2,0),height)
        if mesh and replaced and replaced.Parent then replaced:Destroy() end
    end)
end

-- Two stretches of paving lead around the berry border to the cottage steps.
-- Keep the open spawn and the centre lane free of raised decorations.
function Bridge.decorateWalkway(scenery: Instance)
    if scenery:FindFirstChild("OrchardWalkway") then return end
    local beds=Instance.new("Folder")
    beds.Name="OrchardWalkway"
    beds.Parent=scenery
    for i=1,16 do
        local side=if i%2==0 then 1 else -1
        local ground=Vector3.new(side*(15+(i%4)*4.6),7.18,54+math.floor(i/2)*4.8)
        Bridge.ground(beds,"Environment_MeadowVerge",
            CFrame.new(ground)*CFrame.Angles(0,i*.82,0),6.2+(i%3)*.7,nil)
    end
    for i,point in ipairs({Vector3.new(9,7.16,90),Vector3.new(15,7.16,94.5),
            Vector3.new(26.4,7.16,89),Vector3.new(33.7,7.16,83.2)}) do
        Bridge.ground(beds,"Environment_MeadowVerge",CFrame.new(point)*CFrame.Angles(0,i*1.7,0),5.2,nil)
    end
    local function pave(a: Vector3, b: Vector3)
        local delta=b-a
        local yaw=math.atan2(delta.X,delta.Z)
        Bridge.ground(beds,"Environment_StonePath",
            CFrame.new((a+b)*.5)*CFrame.Angles(0,yaw,0),delta.Magnitude,nil)
    end
    local bend=Vector3.new(22,7.14,92)
    pave(Vector3.new(5.4,7.14,86.5),bend)
    pave(bend,Vector3.new(35.4,7.14,78.4))
end

function Bridge.water(character: Model)
    local hand=character:FindFirstChild("RightHand")
    local source=findMesh("World","Environment_WateringCan")
    if not hand or not hand:IsA("BasePart") or not source then return end
    local old=character:FindFirstChild("HeldWateringCan")
    if old then old:Destroy() end
    local can=source:Clone()
    can.Name="HeldWateringCan"
    can.Size=source.Size*1.4
    can.Anchored=false
    can.CanCollide=false
    can.CanQuery=false
    can.CanTouch=false
    can.Massless=true
    can.CFrame=hand.CFrame*CFrame.new(0,-.36,-.19)*CFrame.Angles(-.48,0,0)
    local weld=Instance.new("WeldConstraint")
    weld.Part0,weld.Part1=hand,can
    weld.Parent=can
    local nozzle=Instance.new("Attachment")
    nozzle.Position=Vector3.new(0,can.Size.Y*.09,-can.Size.Z*.49)
    nozzle.Parent=can
    local drops=Instance.new("ParticleEmitter")
    drops.Rate=0
    drops.Color=ColorSequence.new(Color3.fromRGB(164,216,217))
    drops.Transparency=NumberSequence.new(.22,.91)
    drops.Size=NumberSequence.new(.065,.032)
    drops.Lifetime=NumberRange.new(.19,.36)
    drops.EmissionDirection=Enum.NormalId.Front
    drops.Acceleration=Vector3.new(0,-25,0)
    drops.Speed=NumberRange.new(2.4,3.3)
    drops.SpreadAngle=Vector2.new(9,9)
    drops.Parent=nozzle
    can.Parent=character
    task.delay(.29,function() if can.Parent then drops:Emit(12) end end)
    game:GetService("Debris"):AddItem(can,1.03)
end

-- The 15 original mesh parts are attached to R15's existing moving bones.
-- Roblox's native Humanoid/Animate script keeps all walk/run/jump animations.
-- We never replace player control, physics or the standard character rig.
function Bridge.applyGardenerAvatar(character: Model): boolean
    if character:GetAttribute("DWTMStorybookAvatar") == true then
        for _,child in ipairs(character:GetDescendants()) do
            if child:IsA("BasePart") and child.Parent and child.Parent:IsA("Accessory") then child.Transparency=1 end
            if child:IsA("Decal") and child.Parent==character:FindFirstChild("Head") then child.Transparency=1 end
        end
        return true
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R15 then return false end
    local names = {
        "Head", "UpperTorso", "LowerTorso",
        "LeftUpperArm", "LeftLowerArm", "LeftHand",
        "RightUpperArm", "RightLowerArm", "RightHand",
        "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
        "RightUpperLeg", "RightLowerLeg", "RightFoot",
    }
    local keys = {}
    for _, name in ipairs(names) do table.insert(keys,"Avatar_"..name) end
    for _, key in ipairs(keys) do
        if not findMesh("Avatar",key) then
            if not character:GetAttribute("GardenerLoading") then
                character:SetAttribute("GardenerLoading",true)
                Bridge.prepare(character,"Avatar",keys,function()
                    character:SetAttribute("GardenerLoading",nil)
                    Bridge.applyGardenerAvatar(character)
                end,function() character:SetAttribute("GardenerLoading",nil) end)
            end
            return false
        end
    end
    local planned = {}
    -- The appearance must be complete; avoid half-colored / half-imported avatars.
    for _, name in ipairs(names) do
        local limb = character:FindFirstChild(name)
        local source = findMesh("Avatar", "Avatar_" .. name)
        if not limb or not limb:IsA("BasePart") or not source
            or source.Size.Y < 0.001 then
            return false
        end
        table.insert(planned, {name = name, limb = limb, source = source})
    end
    local costume = Instance.new("Folder")
    costume.Name = "StorybookGardener"
    costume.Parent = character
    for _, record in ipairs(planned) do
        local limb = record.limb :: BasePart
        local original = record.source :: MeshPart
        local mesh = original:Clone()
        mesh.Name = "Garden" .. record.name
        mesh.Massless = true
        mesh.Anchored = false
        mesh.CanCollide = false
        mesh.CanTouch = false
        mesh.CanQuery = false
        mesh.CastShadow = true
        local scale = limb.Size.Y / math.max(original.Size.Y, 0.001)
        local lift=0
        if record.name == "Head" then
            local chest=character:FindFirstChild("UpperTorso") :: BasePart
            scale=math.max(scale*1.20,chest.Size.X*1.07/original.Size.X)
            lift=(original.Size.Y*scale-limb.Size.Y)*.43
        end
        mesh.Size = original.Size * scale
        mesh.CFrame = limb.CFrame*CFrame.new(0,lift,0)
        mesh.Parent = costume
        local weld = Instance.new("WeldConstraint")
        weld.Name = "AnimatedR15Attachment"
        weld.Part0 = limb
        weld.Part1 = mesh
        weld.Parent = mesh
    end
    -- Only after all 15 moving parts are attached do we hide default geometry.
    for _, record in ipairs(planned) do
        (record.limb :: BasePart).Transparency = 1
    end
    for _, item in ipairs(character:GetDescendants()) do
        if item:IsA("Decal") and item.Parent and item.Parent.Name == "Head" then
            item.Transparency = 1
        elseif item:IsA("BasePart") and item.Parent and item.Parent:IsA("Accessory") then
            item.Transparency = 1
        end
    end
    local oldOutfit = character:FindFirstChild("NativeGardenOutfit")
    if oldOutfit then oldOutfit:Destroy() end
    character:SetAttribute("DWTMStorybookAvatar", true)
    return true
end

function Bridge.applySleepingMonster(boss: Model): MeshPart?
    local source = findMesh("World", "Environment_SleepingMonster")
    if not source then return nil end
    local height = 52
    local mesh = makeVisual(source, boss, "ImportedSleepingMonster",
        boss:GetPivot() * CFrame.new(0,10+height/2-29,0), height)
    if not mesh then return nil end
    mesh:SetAttribute("BossRest",boss:GetPivot():ToObjectSpace(mesh.CFrame))
    for _, obj in ipairs(boss:GetDescendants()) do
        if obj:IsA("BasePart") and obj ~= mesh and not obj:IsDescendantOf(mesh) then
            if mesh:HasTag("OrchardRig") and obj~=boss.PrimaryPart then
                obj:Destroy()
            else
                obj.Transparency = 1
            end
        end
    end
    return mesh
end

function Bridge.applyOrchardTree(parent: Instance, index: number, ground: Vector3): boolean
    local source = findMesh("World", "Environment_OrangeTree")
    if not source then return false end
    local tall = 17 + (index % 3) * 1.1
    local visual = makeVisual(source, parent, "ImportedOrangeTree_" .. tostring(index),
        CFrame.new(ground + Vector3.new(0, tall / 2, 0))
            * CFrame.Angles(0, math.rad(index * 41), 0), tall)
    if visual then
        visual:SetAttribute("CottageArt", true)
        return true
    end
    return false
end

function Bridge.applyPet(pet: Model, species: string): boolean
    if pet:FindFirstChild("ImportedCharacterMesh") then return true end
    local source = findMesh("Pets", "Pet_" .. species)
    if not pet.PrimaryPart then return false end
    if not source then
        Bridge.prepare(pet,"Pets",{"Pet_"..species},function() Bridge.applyPet(pet,species) end)
        return false
    end
    local root = pet.PrimaryPart
    local visual = makeVisual(source, pet, "ImportedCharacterMesh", root.CFrame, 4.1)
    if not visual then return false end
    -- The legacy blob art is removed once the real mesh has been cloned.
    -- Retain the movement root, name tag and sound; avoid replicating dozens
    -- of hidden old parts to phones.
    for _, obj in ipairs(pet:GetDescendants()) do
        if obj:IsA("BasePart") and obj ~= visual and obj ~= root and not obj:IsDescendantOf(visual)
            and not obj:FindFirstAncestor("PersonalityAccessory") then
            obj:Destroy()
        end
    end
    pet:SetAttribute("NativeSpeciesStyled",false)
    root.Transparency = 1
    root.CastShadow = false
    return true
end

function Bridge.applyCrop(visual: Model, center: Vector3,
    seedType: string, stage: number): boolean
    if stage < 1 then return false end
    local name = "Crop_" .. seedType .. "_S" .. tostring(stage)
    local source = findMesh("Crops", name)
    if not source then
        Bridge.prepare(visual,"Crops",{name},function()
            if visual:FindFirstChild("ImportedCropMesh") then return end
            if Bridge.applyCrop(visual,center,seedType,stage) then
                for _, item in ipairs(visual:GetChildren()) do
                    if item:IsA("BasePart") and item.Name ~= "ImportedCropMesh"
                        and not string.match(item.Name,"^MutatedSparkle_") then item:Destroy() end
                end
            end
        end)
        return false
    end
    local targetHeight = if stage == 1 then 1.25 elseif stage == 2 then 2.35 else 3.65
    -- Fit the entire rosette or vine inside its own 8.2-stud plot.
    local width = math.max(source.Size.X,source.Size.Z)
    local fitHeight = math.min(targetHeight,7.3*source.Size.Y/width)
    local mesh = makeVisual(source, visual, "ImportedCropMesh",
        CFrame.new(center + Vector3.new(0,fitHeight/2+.25,0)),fitHeight)
    return mesh ~= nil
end

-- Rich opening composition: layered strawberry beds, melon vines and wheat
-- on one side of the central footpath. All meshes are cosmetic, static and
-- nonqueryable. This does not modify any player-owned garden or economy data.
function Bridge.decorateEntrance(world: Instance): number
    local berry = findMesh("Crops", "Crop_Berry_S3")
    local melon = findMesh("Crops", "Crop_LavaMelon_S3")
    local wheat = findMesh("Crops", "Crop_WhisperWheat_S3")
    if not berry or not melon or not wheat then return 0 end
    local garden = Instance.new("Folder")
    garden.Name = "ImportedReferenceStyleEntranceGarden"
    garden.Parent = world
    local count = 0
    local function place(source: MeshPart, name: string, p: Vector3,
        scaleHeight: number, yaw: number)
        scaleHeight = math.min(scaleHeight,4.7*source.Size.Y/math.max(source.Size.X,source.Size.Z))
        local mesh = makeVisual(source, garden, name,
            CFrame.new(p + Vector3.new(0, scaleHeight * 0.5, 0))
                * CFrame.Angles(0, yaw, 0), scaleHeight)
        if mesh then
            mesh:SetAttribute("DecorativeOnly", true)
            count += 1
        end
    end
    -- Central x in [-8,8] stays completely open for the spawn walkway.
    for row = 1, 3 do
        for col = 1, 3 do
            local x = -30 + col * 4.0
            local z = 67 + row * 4.65
            place(berry, "StrawberryPatch_" .. row .. "_" .. col,
                Vector3.new(x, 7.18, z), 3.4, (row+col)*0.67)
        end
    end
    for i = 1, 2 do
        local x = -27 + i * 6.8
        place(melon, "VineWatermelon_" .. i, Vector3.new(x, 7.06, 89.0),
            3.10, i * 1.23)
    end
    for i = 1, 7 do
        local x = -27 + (i % 3) * 3.1
        local z = 63 + math.floor((i-1)/3) * 4.1
        place(wheat, "WheatBorder_" .. i, Vector3.new(x, 7.06, z),
            3.4 + (i%2)*0.25, i * 0.27)
    end
    for i, key in ipairs({"Carrot","Tomato","Corn"}) do
        local crop = findMesh("Crops","Crop_"..key.."_S3")
        if crop then
            for j=0,2 do
                place(crop,key.."Border"..j,Vector3.new(-10.7-j*4.8,7.22,87+i*3.5),
                    if key=="Corn" then 4.4 else 2.9,.48*(i+j))
            end
        end
    end
    -- A second, lighter planting on the cottage side balances the camera.
    for i = 1, 4 do
        local z = 68 + i * 4.7
        place(berry, "OrchardBerries_" .. i,
            Vector3.new(18.5, 7.16, z), 2.65, i * 0.6)
    end
    return count
end

function Bridge.applySetDress(parent: Instance): number
    stageImportedPacks()
    local applied = 0
    local environment = parent:FindFirstChild("CottageGardenEnvironment", true)
    if not environment then return 0 end

    local placement = {
        {"GardenCottage", "CozyOrchardCottage", Vector3.new(37, 13.5, 88), 13},
        {"WaterPond", "ShadedOrchardPond", Vector3.new(54, 6.98, 91), 14},
        {"GardenerToucan", "OriginalGardenHelper", Vector3.new(-16.5, 9.6, 71), 5.2},
        {"BloomingHedge", "OriginalFlowerHedge", Vector3.new(49, 9.0, 80), 4.0},
    }
    for _, record in ipairs(placement) do
        local source = findMesh("World", "Environment_" .. record[1])
        if source then
            local done = environment:FindFirstChild("Imported" .. record[1])
            if done then applied += 1 continue end
            local previous = environment:FindFirstChild(record[2])
            local frame = CFrame.new(record[3])
            if record[1] == "WaterPond" then
                local size = source:GetAttribute("ArtSize") or source.Size
                frame *= CFrame.new(0, size.Y * .5 * record[4] / math.max(size.X,size.Z), 0)
            end
            local mesh = makeVisual(source, environment, "Imported" .. record[1], frame, record[4])
            if mesh then
                if previous then previous:Destroy() end
                if record[1] == "WaterPond" then workspace:SetAttribute("GardenPondCenter",mesh.CFrame.Position) end
                applied += 1
                if record[1] == "GardenCottage" then
                    -- Decorative cottage is closed: players should not walk
                    -- through a house just because its 3D mesh is cosmetic.
                    local collision = Instance.new("Part")
                    collision.Name = "CottageInvisibleWalls"
                    collision.Size = Vector3.new(14, 8.5, 12)
                    collision.CFrame = CFrame.new(37, 11.25, 88)
                    collision.Transparency = 1
                    collision.Anchored = true
                    collision.CanCollide = true
                    collision.CanQuery = false
                    collision.CanTouch = false
                    collision.Parent = environment
                end
            end
        end
    end
    -- Full imported world packs need the foreground citrus and wooden fences
    -- too. The older bridge only placed the cottage, pond, toucan and hedge,
    -- so the trees and fence vanished whenever the native fallback switched off.
    if applied == 4 then
        local citrus = findMesh("World", "Environment_OrangeTree")
        local fence = findMesh("World", "Environment_WoodFence")
        if citrus and fence then
            local orchard = {
                Vector3.new(14, 7.15, 68),
                Vector3.new(44, 7.15, 70),
                Vector3.new(-36, 7.15, 67.5),
            }
            for index, ground in ipairs(orchard) do
                local height = 17.2 + index * 0.8
                local name = "ImportedHeroCitrus_" .. index
                if environment:FindFirstChild(name) then continue end
                local tree = makeVisual(citrus, environment, name,
                    CFrame.new(ground + Vector3.new(0, height / 2, 0))
                        * CFrame.Angles(0, math.rad(index * 59), 0), height)
                if not tree then applied = 3 end
            end
            for _, x in ipairs({-33, -26, -19, 21, 28, 35}) do
                local name = "ImportedGardenFence_" .. tostring(x)
                if environment:FindFirstChild(name) then continue end
                local rail = makeVisual(fence, environment, name,
                    CFrame.new(x, 8.55, 62), 2.6)
                if not rail then applied = 3 end
            end
        else
            -- Keep the native citrus/fence backdrop if the owner's
            -- import has not included those two named meshes yet.
            applied = 3
        end
    end
    return applied
end

return Bridge
