--!strict
-- Dense, asymmetrical painted foliage for the reference garden.
-- Engine-native WedgeParts are deliberately used so the actual .rbxlx shows
-- the garden on a fresh account WITHOUT creator-uploaded MeshIds.
-- Scene dressing is static, non-colliding and capped for low-end devices.
local Detail = {}

local DARK = Color3.fromRGB(62, 121, 72)
local GREEN = Color3.fromRGB(91, 156, 83)
local LIGHT = Color3.fromRGB(166, 204, 105)
local LIME = Color3.fromRGB(192, 216, 125)
local SOIL = Color3.fromRGB(122, 91, 66)
local GOLD = Color3.fromRGB(243, 209, 151)
local IVORY = Color3.fromRGB(255, 244, 210)
local ROSE = Color3.fromRGB(254, 188, 183)

local LIMIT = 410
local used = 0

local function part(parent: Instance, name: string, at: CFrame,
    size: Vector3, color: Color3, kind: Enum.PartType?): Part?
    if used >= LIMIT then return nil end
    used += 1
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = at
    p.Color = color
    p.Material = Enum.Material.SmoothPlastic
    p.Shape = kind or Enum.PartType.Block
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.Anchored = true
    p.CastShadow = false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function foliageBlade(parent: Instance, origin: Vector3,
    direction: Vector3, width: number, height: number, tint: Color3)
    if used >= LIMIT then return end
    local tip = origin + direction
    local mid = (origin + tip) * 0.5
    local blade = Instance.new("WedgePart")
    blade.Name = "PaintedAngularLeaf"
    blade.Material = Enum.Material.SmoothPlastic
    blade.Color = tint
    blade.Anchored = true
    blade.CanCollide = false
    blade.CanTouch = false
    blade.CanQuery = false
    blade.CastShadow = false
    blade.Size = Vector3.new(width, height, direction.Magnitude)
    blade.CFrame = CFrame.lookAt(mid, tip) * CFrame.Angles(0, 0, math.rad(6))
    blade.Parent = parent
    used += 1
end

local function grass(parent: Instance, ground: Vector3, seed: number)
    local a = seed * 2.39996
    for j = 1, 3 do
        local theta = a + j * 2.0944
        local dir = Vector3.new(math.sin(theta) * .47,
            .65 + .18 * math.sin(seed+j), math.cos(theta) * .45)
        foliageBlade(parent, ground, dir, .13,
            .08, if j==1 then LIGHT else GREEN)
    end
end

local function tinyDaisy(parent: Instance, ground: Vector3, seed: number)
    local stem = ground + Vector3.new(0, .46, 0)
    part(parent, "FlowerStem", CFrame.new(ground + Vector3.new(0, .22, 0)),
        Vector3.new(.075,.45,.075), DARK)
    for j = 1, 4 do
        local a = j * math.pi/2 + seed*.27
        local center = stem + Vector3.new(math.sin(a)*.20, 0, math.cos(a)*.20)
        part(parent,"Petal",CFrame.new(center),Vector3.new(.30,.08,.21),
            if seed%3==0 then ROSE else IVORY,Enum.PartType.Ball)
    end
    part(parent,"FlowerHeart",CFrame.new(stem + Vector3.new(0,.06,0)),
        Vector3.new(.18,.11,.18),GOLD,Enum.PartType.Ball)
end

local function orchardLeaves(parent: Instance, origin: Vector3, seed: number)
    -- Angular, overlapping cards break up the old uniform spherical canopy.
    -- Silhouettes point outwards, with front-facing highlights as in the supplied
    -- painterly reference. Fruit and branches remain real 3D objects below.
    for i = 1, 54 do
        local a = i * 2.399963 + seed*.09
        local r = 2.25 + (i%5)*.23
        local radial = Vector3.new(math.sin(a)*r, 0, math.cos(a)*r)
        local y = 5.80 + (i%9)*.36
        local place = origin + radial + Vector3.new(0,y,0)
        local outward = Vector3.new(math.sin(a)*.42,
            math.cos(i*1.7)*.27, math.cos(a)*.45)
        foliageBlade(parent, place, outward, .34+(i%3)*.14, .085,
            if i%5==0 then LIME elseif i%3==0 then LIGHT
            elseif i%2==0 then GREEN else DARK)
    end
end

local function groundDetails(parent: Instance)
    -- A readable central path must stay free; reserve a 10-stud-wide corridor.
    -- Scatter very small elements at the crop/stone edge, not on interaction
    -- prompts or crop plots. The source image has dappled groundcover.
    local r = Random.new(20261120)
    for i = 1, 33 do
        local side = if i%2==0 then -1 else 1
        local x = side * r:NextNumber(10.8, 16.7)
        local z = r:NextNumber(44, 96)
        local p = Vector3.new(x, 7.26, z)
        if i%6==0 then
            tinyDaisy(parent, p, i)
        else
            grass(parent,p,i)
        end
        if i%3==0 then
            local patch = part(parent,"CloverLightPatch",
                CFrame.new(p+Vector3.new(0,-.06,0)) *
                    CFrame.Angles(0,math.rad(i*17),0),
                Vector3.new(.61,.045,.48),
                if i%2==0 then GREEN else LIGHT,Enum.PartType.Ball)
            if patch then patch.Transparency = .08 end
        end
    end
end

local function berryLeafPass(parent: Instance)
    -- Additional leaf silhouettes make the otherwise spherical strawberries
    -- read as actual low garden bushes from the high three-quarter camera.
    for row = 1, 3 do
        for col = 1, 3 do
            local center = Vector3.new(-30+col*4.15,7.17,67+row*4.65)
            for j = 1, 9 do
                local a = j * 2.39996 + row*.14
                local rad = 1.6 + (j%3)*.33
                local root = center + Vector3.new(math.sin(a)*rad,
                    .49+(j%2)*.20, math.cos(a)*rad)
                foliageBlade(parent,root,
                    Vector3.new(math.sin(a)*.66,.09+(j%3)*.08,
                        math.cos(a)*.56), .36, .10,
                    if j%4==0 then LIGHT elseif j%2==0 then GREEN else DARK)
            end
        end
    end
end

function Detail.build(parent: Instance): Folder
    local existing = parent:FindFirstChild("ReferencePaintedFoliage")
    if existing then existing:Destroy() end
    used = 0
    local folder = Instance.new("Folder")
    folder.Name = "ReferencePaintedFoliage"
    folder.Parent = parent
    orchardLeaves(folder,Vector3.new(16.5,7.15,65),31)
    orchardLeaves(folder,Vector3.new(34,7.15,64),43)
    orchardLeaves(folder,Vector3.new(-34,7.15,59),57)
    berryLeafPass(folder)
    groundDetails(folder)
    folder:SetAttribute("Source","NativeRobloxParts_NoMeshIds")
    folder:SetAttribute("PartBudget",LIMIT)
    folder:SetAttribute("PartCount",used)
    return folder
end

return Detail
