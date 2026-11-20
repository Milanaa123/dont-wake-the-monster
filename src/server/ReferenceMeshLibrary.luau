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

local function findMesh(groupName: string, assetName: string): MeshPart?
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
    local ratio = height / math.max(mesh.Size.Y, 0.001)
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
    -- Hide only old decoration, not UI or our movement pivot. Keep the old
    -- movement root and the whole server-owned pet/character system intact.
    for _, obj in ipairs(pet:GetDescendants()) do
        if obj:IsA("BasePart") and obj ~= visual then
            obj.Transparency = 1
            obj.CastShadow = false
        end
    end
    return true
end

function Bridge.applyCrop(visual: Model, center: Vector3,
    seedType: string, stage: number): boolean
    if stage < 1 then return false end
    local name = "Crop_" .. seedType .. "_S" .. tostring(stage)
    local source = findMesh("Crops", name)
    if not source then return false end
    local mesh = makeVisual(source, visual, "ImportedCropMesh",
        CFrame.new(center + Vector3.new(0, 0.65, 0)), 3.7)
    return mesh ~= nil
end

function Bridge.applySetDress(parent: Instance): number
    local root = ServerStorage:FindFirstChild(ROOT_NAME)
    if not root then return 0 end
    local applied = 0
    local environment = parent:FindFirstChild("CottageGardenEnvironment", true)
    if not environment then return 0 end

    local placement = {
        {"GardenCottage", "CozyOrchardCottage", Vector3.new(37, 7, 88), 13},
        {"WaterPond", "ShadedOrchardPond", Vector3.new(54, 7, 91), 4},
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
