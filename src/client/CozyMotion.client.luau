--!strict
-- Gentle camera-proximity cosmetic movement for original imported GLB art.
-- Runs only on the viewer. Server physics, mesh imports and gameplay stay untouched.
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

type AnimatedEntry = {
    mesh: MeshPart,
    base: CFrame,
    size: Vector3,
    kind: string,
    seed: number,
}
local animated: {[MeshPart]: AnimatedEntry} = {}
local viewDistance = 140
local elapsed = 0

local function kindFor(mesh: MeshPart): string?
    if mesh.Name == "ImportedCharacterMesh" then return "pet" end
    if mesh.Name == "ImportedSleepingMonster" then return "boss" end
    if mesh.Name == "ImportedGardenerToucan" then return "bird" end
    if string.find(mesh.Name, "ImportedOrangeTree_", 1, true) == 1 then return "tree" end
    if mesh:GetAttribute("DecorativeOnly") == true then return "plant" end
    if mesh.Name == "ImportedCropMesh" then return "plant" end
    return nil
end

local function track(descendant: Instance)
    if not descendant:IsA("MeshPart") then return end
    local kind = kindFor(descendant)
    if not kind then return end
    local seed = 0
    local identity = descendant:GetFullName()
    for i = 1, #identity do
        seed += string.byte(identity, i) * (i % 17 + 1)
    end
    seed += math.floor(descendant.Position.X * 7 + descendant.Position.Z * 13)
    animated[descendant] = {
        mesh = descendant,
        base = descendant.CFrame,
        size = descendant.Size,
        kind = kind,
        seed = seed % 137,
    }
end

local function untrack(descendant: Instance)
    if descendant:IsA("MeshPart") then
        animated[descendant] = nil
    end
end

local island = Workspace:WaitForChild("MonsterIsland", 30)
if island then
    for _, descendant in ipairs(island:GetDescendants()) do track(descendant) end
    island.DescendantAdded:Connect(track)
    island.DescendantRemoving:Connect(untrack)
end

-- Limit update to 30 FPS; far decorations don't spend work.
RunService.RenderStepped:Connect(function(dt: number)
    elapsed += dt
    if elapsed < 1 / 30 then return end
    local delta = elapsed
    elapsed = 0
    local now = Workspace.DistributedGameTime
    local camera = Workspace.CurrentCamera
    if not camera then return end

    for mesh, entry in pairs(animated) do
        if not mesh.Parent then
            animated[mesh] = nil
            continue
        end
        if (mesh.Position - camera.CFrame.Position).Magnitude > viewDistance then
            continue
        end
        local offsetTime = now + entry.seed * 0.31
        if entry.kind == "pet" then
            -- Each family has its own motion rhythm while remaining attached
            -- to the server-authoritative movement root.
            local parent = mesh.Parent
            local root = if parent and parent:IsA("Model") then parent.PrimaryPart else nil
            if root and root:IsA("BasePart") then
                local species = parent.Name:match("^[^_]+") or ""
                local isBird = species == "Swoop" or species == "Puffin"
                    or species == "Nugget" or species == "Twinkle"
                    or species == "Echo"
                local isCalm = species == "Pebble" or species == "Mallow"
                    or species == "Floofle"
                local rate = if isBird then 5.9 elseif isCalm then 1.85 else 3.35
                local amount = if isBird then 0.18 elseif isCalm then 0.05 else 0.09
                local bob = math.sin(offsetTime * rate) * amount
                local tilt = math.sin(offsetTime * rate * .74) *
                    (if isBird then .058 else if isCalm then .018 else .043)
                mesh.CFrame = root.CFrame * CFrame.new(0, bob, 0)
                    * CFrame.Angles(0, 0, tilt)
                local inhale = 1 + .012 * math.sin(offsetTime * 2.8)
                mesh.Size = entry.size * Vector3.new(inhale, 1 / inhale, inhale)
            end
        elseif entry.kind == "plant" then
            local tilt = math.sin(offsetTime * 1.27) * 0.018
            mesh.CFrame = entry.base * CFrame.Angles(tilt, 0, tilt * 0.44)
        elseif entry.kind == "tree" then
            local tilt = math.sin(offsetTime * 0.78) * 0.007
            mesh.CFrame = entry.base * CFrame.Angles(tilt * 0.62, 0, tilt)
        elseif entry.kind == "bird" then
            local bob = math.sin(offsetTime * 1.8) * 0.10
            local nod = math.sin(offsetTime * 1.5) * 0.06
            mesh.CFrame = entry.base * CFrame.new(0, bob, 0)
                * CFrame.Angles(nod, 0, 0)
        elseif entry.kind == "boss" and mesh.Transparency < 0.9 then
            local inhale = 1 + math.sin(offsetTime * 1.24) * 0.008
            mesh.Size = entry.size * inhale
            mesh.CFrame = entry.base * CFrame.new(0, math.sin(offsetTime * 1.24) * 0.10, 0)
        end
    end
end)
