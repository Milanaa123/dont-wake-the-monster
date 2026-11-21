--!strict
-- Materialize packed, authored meshes on demand. Opaque DataModel content is
-- replicated to clients; an EditableMesh object reference alone cannot replicate.
local AssetService = game:GetService("AssetService")
local EncodingService = game:GetService("EncodingService")
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local data = ServerStorage:WaitForChild("OrchardGeometry")
local localFiles = if RunService:IsStudio() then ServerStorage:FindFirstChild("StudioMeshFiles") else nil

local Art = {}
local templates: {[string]: MeshPart} = {}
local pending: {[string]: BindableEvent} = {}
local retryAt: {[string]: number} = {}
local building = 0
local space = Instance.new("BindableEvent")
local texture: Content? = nil
local textureBusy = false
local textureReady = Instance.new("BindableEvent")
local textureRetry = 0

local function unpackBytes(encoded: string): buffer
    return EncodingService:DecompressBuffer(EncodingService:Base64Decode(buffer.fromstring(encoded)),
        Enum.CompressionAlgorithm.Zstd)
end

local function replicate(editable: any): Content
    local result, content = AssetService:CreateDataModelContentAsync(Content.fromObject(editable))
    assert(result == Enum.CreateContentResult.Success, tostring(result))
    return content
end

local function pigments(): Content
    while textureBusy do textureReady.Event:Wait() end
    if texture then return texture end
    assert(os.clock() >= textureRetry, "Mesh/image APIs unavailable")
    textureBusy = true
    local img: EditableImage? = nil
    local ok, result = pcall(function()
        local raw = HttpService:JSONDecode((data:FindFirstChild("Pigments") :: StringValue).Value)
        local size = Vector2.new(raw[1], raw[2])
        local image = assert(AssetService:CreateEditableImage({Size = size}), "Image memory budget")
        img = image
        image:WritePixelsBuffer(Vector2.zero, size, unpackBytes(raw[3]))
        return replicate(image)
    end)
    if img then (img :: EditableImage):Destroy() end
    if ok then texture = result else textureRetry = os.clock() + 60 end
    textureBusy = false
    textureReady:Fire()
    assert(ok, tostring(result))
    return result
end

local function surface(encoded: string, atlas: Content): MeshPart
    local bytes = unpackBytes(encoded)
    local count = buffer.readu32(bytes, 0)
    local triangles = buffer.readu32(bytes, 4)
    assert(8 + count*13 + triangles*6 == buffer.len(bytes), "Invalid mesh record")
    local geometry = assert(AssetService:CreateEditableMesh(), "Mesh memory budget")
    local ok, result = pcall(function()
        local vertices, normals, uvs = table.create(count), table.create(count), table.create(count)
        local pos = 8
        for i = 1, count do
            vertices[i] = geometry:AddVertex(Vector3.new(buffer.readi16(bytes,pos),
                buffer.readi16(bytes,pos+2),buffer.readi16(bytes,pos+4))/2048)
            normals[i] = geometry:AddNormal(Vector3.new(buffer.readi8(bytes,pos+6),
                buffer.readi8(bytes,pos+7),buffer.readi8(bytes,pos+8)).Unit)
            uvs[i] = geometry:AddUV(Vector2.new(buffer.readu16(bytes,pos+9),
                buffer.readu16(bytes,pos+11))/65535)
            pos += 13
        end
        for _ = 1, triangles do
            local a,b,c = buffer.readu16(bytes,pos)+1, buffer.readu16(bytes,pos+2)+1, buffer.readu16(bytes,pos+4)+1
            local f = geometry:AddTriangle(vertices[a],vertices[b],vertices[c])
            geometry:SetFaceNormals(f,{normals[a],normals[b],normals[c]})
            geometry:SetFaceUVs(f,{uvs[a],uvs[b],uvs[c]})
            pos += 6
        end
        local uri = replicate(geometry)
        local mesh = AssetService:CreateMeshPartAsync(uri,{CollisionFidelity=Enum.CollisionFidelity.Box})
        mesh.TextureContent = atlas
        return mesh
    end)
    geometry:Destroy()
    assert(ok,tostring(result))
    return result
end

local function vector(v: {number}): Vector3
    return Vector3.new(v[1],v[2],v[3])
end

local function assemble(key: string, record: StringValue): MeshPart
    local spec = HttpService:JSONDecode(record.Value)
    local root: MeshPart? = nil
    local atlas = if localFiles then nil else pigments()
    local ok, problem = pcall(function()
        for _, part in ipairs(spec.parts) do
            local mesh: MeshPart
            if localFiles then
                local file = localFiles:FindFirstChild(key .. "_" .. part.name)
                assert(file and file:IsA("MeshPart"), key .. "/" .. part.name)
                mesh = file:Clone()
            else
                mesh = surface(part.data, atlas :: Content)
            end
            mesh.Anchored = true
            mesh.CanCollide = false
            mesh.CanTouch = false
            mesh.CanQuery = false
            mesh.Massless = true
            mesh.DoubleSided = true
            mesh.Color = Color3.new(1,1,1)
            mesh.Material = Enum.Material.SmoothPlastic
            mesh.Size = vector(part.size):Max(Vector3.one * .001)
            mesh:SetAttribute("PieceCenter",vector(part.center)-vector(spec.center))
            if part.name == "Body" then
                root = mesh
                mesh.Name = key
                mesh:SetAttribute("ArtSize",vector(spec.size))
            else
                assert(root)
                mesh.Name = part.name
                mesh:SetAttribute("JointParent",part.parent)
                mesh:SetAttribute("JointPivot",vector(part.pivot)-vector(spec.center))
                mesh.Parent = root
            end
        end
    end)
    if not ok then
        if root then (root :: MeshPart):Destroy() end
        error(tostring(problem))
    end
    return assert(root)
end

-- Called from cosmetic tasks. Concurrent requests share one construction.
function Art.load(key: string): MeshPart?
    if templates[key] then return templates[key] end
    local busy = pending[key]
    if busy then
        busy.Event:Wait()
        return templates[key]
    end
    if os.clock() < (retryAt[key] or 0) or (not localFiles and os.clock() < textureRetry) then return nil end
    local record = data:FindFirstChild(key)
    if not record or not record:IsA("StringValue") then return nil end
    local event = Instance.new("BindableEvent")
    pending[key] = event
    while building>=2 do space.Event:Wait() end
    building+=1
    local ok, result = pcall(assemble,key,record)
    building-=1
    space:Fire()
    if ok then templates[key] = result else
        retryAt[key] = os.clock()+60
        warn("DWTM artwork " .. key .. ": " .. tostring(result))
    end
    pending[key] = nil
    event:Fire()
    task.defer(function() event:Destroy() end)
    return templates[key]
end

function Art.cached(key: string): MeshPart?
    if localFiles and not templates[key] then return Art.load(key) end
    return templates[key]
end

-- Align sections about authored pivots, retaining the API- and gameplay-owned root.
function Art.mount(mesh: MeshPart, frame: CFrame, scale: number)
    local base = mesh:GetAttribute("PieceCenter") or Vector3.zero
    mesh.CFrame = frame * CFrame.new(base*scale)
    local members: {[string]: MeshPart} = {Body=mesh}
    for _, child in ipairs(mesh:GetChildren()) do
        if child:IsA("MeshPart") and child:GetAttribute("JointParent") then
            members[child.Name] = child
            child.Size *= scale
            child.CFrame = frame * CFrame.new(child:GetAttribute("PieceCenter")*scale)
        end
    end
    for id, child in pairs(members) do
        if id == "Body" then continue end
        local parent = members[child:GetAttribute("JointParent")]
        local pivot = frame * CFrame.new(child:GetAttribute("JointPivot")*scale)
        local joint = Instance.new("Motor6D")
        joint.Name = id
        joint.Part0, joint.Part1 = parent, child
        joint.C0 = parent.CFrame:ToObjectSpace(pivot)
        joint.C1 = child.CFrame:ToObjectSpace(pivot)
        joint.Parent = child
        child.Anchored = false
    end
end

return Art
