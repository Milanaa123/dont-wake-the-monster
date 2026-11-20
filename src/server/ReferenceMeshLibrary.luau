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
        {pack = "DWTM_World_6", folder = "World", prefix = "Environment_"},
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
            if mesh then applied += 1 end
        end
    end
    return applied
end

return Bridge
