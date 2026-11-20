--!strict
-- Original reference-style ground composition for the *actual playable* map.
-- Material/lighting details use native Roblox geometry, not screenshots or
-- uploaded images. Fixed seed and strict cap keep repeated joins identical.
local Ground = {}

local SOIL_DARK = Color3.fromRGB(89, 75, 52)
local EARTH = Color3.fromRGB(138, 105, 70)
local CLOVER = Color3.fromRGB(84, 145, 80)
local MOSS = Color3.fromRGB(106, 163, 80)
local SUNLIT = Color3.fromRGB(174, 198, 98)
local PETAL = Color3.fromRGB(255, 243, 220)
local GOLD = Color3.fromRGB(252, 216, 133)
local MAX_PARTS = 190

local function oval(parent: Instance, name: string, position: Vector3,
    size: Vector3, color: Color3, transparency: number, orientation: number): Part
    local item=Instance.new("Part")
    item.Name=name
    item.Anchored=true
    item.CanCollide=false
    item.CanTouch=false
    item.CanQuery=false
    item.CastShadow=false
    item.Shape=Enum.PartType.Ball
    item.Material=Enum.Material.SmoothPlastic
    item.Size=size
    item.Color=color
    item.Transparency=transparency
    item.CFrame=CFrame.new(position)*CFrame.Angles(0,orientation,0)
    item.TopSurface=Enum.SurfaceType.Smooth
    item.BottomSurface=Enum.SurfaceType.Smooth
    item.Parent=parent
    return item
end

function Ground.build(world: Instance): Folder
    local previous=world:FindFirstChild("SunlitGardenGround")
    if previous then previous:Destroy() end
    local folder=Instance.new("Folder")
    folder.Name="SunlitGardenGround"
    folder.Parent=world
    local random=Random.new(20261121)
    local created=0
    local function place(name: string, position: Vector3, size: Vector3,
        color: Color3, transparency: number, orientation: number)
        if created>=MAX_PARTS then return end
        oval(folder,name,position,size,color,transparency,orientation)
        created+=1
    end

    -- Deep olive contact shadows underneath the reference orchard.
    -- These are soft silhouettes, not physical colliders/decals.
    for _, center in ipairs({
        Vector3.new(16.5,7.16,65), Vector3.new(34,7.16,64),
        Vector3.new(-34,7.16,59),
    }) do
        place("OrchardContactShade",center+Vector3.new(0,.15,0),
            Vector3.new(11.2,.075,7.1),SOIL_DARK,.74,.43)
        for i=1,6 do
            local a=i*2.399963
            local x=math.cos(a)*random:NextNumber(1.8,5.6)
            local z=math.sin(a)*random:NextNumber(1.5,3.8)
            place("BrokenLeafShadow",center+Vector3.new(x,.18,z),
                Vector3.new(random:NextNumber(.65,1.9),.048,
                    random:NextNumber(.7,1.5)),
                CLOVER,.80,a)
        end
    end

    -- Between planted strawberry crowns, show the warm, dark soil that
    -- gives the reference its rich layering.
    for row=1,3 do
        for col=1,3 do
            local center=Vector3.new(-30+col*4.15,7.17,67+row*4.65)
            for j=1,3 do
                local a=j*2.094+row*.35
                local p=center+Vector3.new(math.sin(a)*1.05,.165,
                    math.cos(a)*.85)
                place("StrawberryRootSoil",p,
                    Vector3.new(random:NextNumber(1.2,1.9),.055,
                        random:NextNumber(.75,1.35)),
                    SOIL_DARK,.58,a)
            end
        end
    end

    -- Loose overlapping foliage and mottled grass around the garden, but
    -- leave the central walking lane, doors and interaction prompts open.
    for i=1,54 do
        local a=i*2.399963
        local side=if i%2==0 then -1 else 1
        local x=side*random:NextNumber(11.5,36)
        local z=random:NextNumber(43,105)
        local p=Vector3.new(x,7.26,z)
        local color=if i%5==0 then SUNLIT
            elseif i%3==0 then CLOVER else MOSS
        place("MeadowPaintedGround",p,
            Vector3.new(random:NextNumber(.90,2.9),.045,
                random:NextNumber(.55,1.55)),color,.56,a)
        if i%4==0 then
            for j=1,3 do
                local d=a+j*2.0944
                place("TinyCloverLeaf",p+Vector3.new(
                    math.cos(d)*.25,.055,math.sin(d)*.22),
                    Vector3.new(.29,.048,.22),SUNLIT,.19,d)
            end
        end
    end

    -- Near-ground scattered stones and pale blossom flecks prevent a
    -- perfectly even computer-generated path texture.
    for i=1,34 do
        local a=i*2.399963
        local side=if i%2==0 then -1 else 1
        local p=Vector3.new(side*random:NextNumber(11.2,20),
            7.32,random:NextNumber(52,101))
        if i%3==0 then
            place("BlossomOnThePath",p,
                Vector3.new(.23,.027,.17),PETAL,.18,a)
            place("BloomPollen",p+Vector3.new(.11,.012,.02),
                Vector3.new(.065,.015,.06),GOLD,.08,a)
        else
            place("WarmSoilPebble",p,
                Vector3.new(random:NextNumber(.22,.56),.11,
                    random:NextNumber(.26,.60)),EARTH,.22,a)
        end
    end

    folder:SetAttribute("VisualStyle","SunlitPaintedGarden")
    folder:SetAttribute("MaxNativeParts",MAX_PARTS)
    folder:SetAttribute("ActualNativeParts",created)
    return folder
end

return Ground
