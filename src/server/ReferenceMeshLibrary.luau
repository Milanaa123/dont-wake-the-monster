--!strict
-- Optional production mesh art bridge. The original GLB art library is generated
-- by scripts/generate_reference_glb.py, imported into Studio by its owner,
-- then staged under ServerStorage/DWTM_ArtLibrary.
--
-- IMPORTANT: A GitHub file cannot produce an authorized Roblox MeshId by itself.
-- If models are absent, gameplay falls back to its existing procedural artwork.
local ServerStorage = game:GetService("ServerStorage")

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
    if not root then return nil end
    local group = root:FindFirstChild(groupName)
    if not group then return nil end
    local obj = group:FindFirstChild(assetName, true)
    if obj and obj:IsA("MeshPart") then return obj end
    if obj and obj:IsA("Model") then
        return obj:FindFirstChildWhichIsA("MeshPart", true)
    end
    return nil
end

local function makeVisual(source: MeshPart, parent: Instance, name: string,
    pivot: CFrame, height: number): MeshPart?
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
    local sourceSpan = if name == "ImportedWaterPond" then math.max(mesh.Size.X, mesh.Size.Z)
        else mesh.Size.Y
    local ratio = height / math.max(sourceSpan, 0.001)
    mesh.Size = mesh.Size * ratio
    mesh.CFrame = pivot
    mesh.Parent = parent
    return mesh
end

-- The 15 original mesh parts are attached to R15's existing moving bones.
-- Roblox's native Humanoid/Animate script keeps all walk/run/jump animations.
-- We never replace player control, physics or the standard character rig.
function Bridge.applyGardenerAvatar(character: Model): boolean
    if character:GetAttribute("DWTMStorybookAvatar") == true then return true end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R15 then return false end
    local names = {
        "Head", "UpperTorso", "LowerTorso",
        "LeftUpperArm", "LeftLowerArm", "LeftHand",
        "RightUpperArm", "RightLowerArm", "RightHand",
        "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
        "RightUpperLeg", "RightLowerLeg", "RightFoot",
    }
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
        if record.name == "Head" then scale *= 1.20 end
        mesh.Size = original.Size * scale
        mesh.CFrame = limb.CFrame
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
    character:SetAttribute("DWTMStorybookAvatar", true)
    return true
end

function Bridge.applySleepingMonster(boss: Model): MeshPart?
    local source = findMesh("World", "Environment_SleepingMonster")
    if not source then return nil end
    local height = 52
    local mesh = makeVisual(source, boss, "ImportedSleepingMonster",
        CFrame.new(0, 8 + height / 2, 0), height)
    if not mesh then return nil end
    for _, obj in ipairs(boss:GetDescendants()) do
        if obj:IsA("BasePart") and obj ~= mesh then
            obj.Transparency = 1
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
    if not source or not pet.PrimaryPart then return false end
    local root = pet.PrimaryPart
    local visual = makeVisual(source, pet, "ImportedCharacterMesh", root.CFrame, 4.1)
    if not visual then return false end
    -- The legacy blob art is removed once the real mesh has been cloned.
    -- Retain the movement root, name tag and sound; avoid replicating dozens
    -- of hidden old parts to phones.
    for _, obj in ipairs(pet:GetDescendants()) do
        if obj:IsA("BasePart") and obj ~= visual and obj ~= root then
            obj:Destroy()
        end
    end
    root.Transparency = 1
    root.CastShadow = false
    return true
end

function Bridge.applyCrop(visual: Model, center: Vector3,
    seedType: string, stage: number): boolean
    if stage < 1 then return false end
    local name = "Crop_" .. seedType .. "_S" .. tostring(stage)
    local source = findMesh("Crops", name)
    if not source then return false end
    local targetHeight = if stage == 1 then 1.25 elseif stage == 2 then 2.35 else 3.65
    local mesh = makeVisual(source, visual, "ImportedCropMesh",
        CFrame.new(center + Vector3.new(0, targetHeight / 2 + 0.10, 0)), targetHeight)
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
    local root = ServerStorage:FindFirstChild(ROOT_NAME)
    if not root then return 0 end
    local applied = 0
    local environment = parent:FindFirstChild("CottageGardenEnvironment", true)
    if not environment then return 0 end

    local placement = {
        {"GardenCottage", "CozyOrchardCottage", Vector3.new(37, 13.5, 88), 13},
        {"WaterPond", "ShadedOrchardPond", Vector3.new(54, 7.25, 91), 14},
        {"GardenerToucan", "OriginalGardenHelper", Vector3.new(32, 9.6, 78), 5.2},
        {"BloomingHedge", "OriginalFlowerHedge", Vector3.new(49, 9.0, 80), 4.0},
    }
    for _, record in ipairs(placement) do
        local source = findMesh("World", "Environment_" .. record[1])
        if source then
            local previous = environment:FindFirstChild(record[2])
            if previous then previous:Destroy() end
            local mesh = makeVisual(source, environment, "Imported" .. record[1],
                CFrame.new(record[3]), record[4])
            if mesh then
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
                Vector3.new(16.5, 7.15, 65),
                Vector3.new(34, 7.15, 64),
                Vector3.new(-34, 7.15, 59),
            }
            for index, ground in ipairs(orchard) do
                local height = 17.2 + index * 0.8
                makeVisual(citrus, environment, "ImportedHeroCitrus_" .. index,
                    CFrame.new(ground + Vector3.new(0, height / 2, 0))
                        * CFrame.Angles(0, math.rad(index * 59), 0), height)
            end
            for _, x in ipairs({-33, -26, -19, 21, 28, 35}) do
                makeVisual(fence, environment, "ImportedGardenFence_" .. tostring(x),
                    CFrame.new(x, 8.55, 62), 2.6)
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
