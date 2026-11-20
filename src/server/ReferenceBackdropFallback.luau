--!strict
-- Asset-free companion set dressing for the coherent farm opening: citrus
-- foliage, wood fences and an original black toucan wearing a pale-blue cap.
-- These are true Roblox geometry objects, not generated pictures.
local Dressing = {}
local ORANGE = Color3.fromRGB(255,177,75)
local LEAF = Color3.fromRGB(90,159,85)
local SUNNY = Color3.fromRGB(174,204,108)
local DARK = Color3.fromRGB(67,124,77)
local BARK = Color3.fromRGB(152,113,79)
local WOOD = Color3.fromRGB(211,170,125)
local BLACK = Color3.fromRGB(49,56,59)
local BLUE = Color3.fromRGB(151,185,230)
local PALE = Color3.fromRGB(208,215,215)
local GOLD = Color3.fromRGB(252,207,100)
local SHINE = Color3.fromRGB(254,246,228)

local function part(parent: Instance, name: string,
    frame: CFrame, size: Vector3, color: Color3,
    material: Enum.Material?, shape: Enum.PartType?): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = frame
    p.Shape = shape or Enum.PartType.Block
    p.Material = material or Enum.Material.SmoothPlastic
    p.Color = color
    p.CanCollide = false
    p.Anchored = true
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = size.Y > .17
    p.Parent = parent
    return p
end

local function ball(parent: Instance, name: string, p: Vector3,
    size: Vector3, color: Color3)
    return part(parent,name,CFrame.new(p),size,color,nil,Enum.PartType.Ball)
end

local function branch(parent: Instance, name: string, a: Vector3, b: Vector3,
    width: number, tint: Color3)
    local len = (b-a).Magnitude
    return part(parent,name,CFrame.lookAt((a+b)/2,b),
        Vector3.new(width,width,len),tint,Enum.Material.Wood)
end

local function orangeTree(parent: Instance, ground: Vector3, seed: number)
    local rng=Random.new(seed)
    local trunk = ground+Vector3.new(0,3.4,0)
    branch(parent,"OrangeTreeTrunk",ground,trunk,.88,BARK)
    for i=1,3 do
        local t=i*2.39996
        local tip = trunk+Vector3.new(math.cos(t)*2.6,1.8,math.sin(t)*2.4)
        branch(parent,"OrangeTreeBranch",ground+Vector3.new(0,2.1,0),
            tip,.29,BARK)
    end
    for i=1,11 do
        local a=i*2.39996
        local p=ground+Vector3.new(math.cos(a)*(2.4+(i%3)*.43),
            6.1+(i%4)*.44,math.sin(a)*(2.1+(i%2)*.34))
        ball(parent,"MossGreenCanopy",p,Vector3.new(3.1,2.9,2.85),
            if i%3==0 then SUNNY else LEAF)
        for j=1,2 do
            local theta=a+j*2.094
            local l = Instance.new("WedgePart")
            l.Name="CanopyJaggedLeaf"
            l.Size=Vector3.new(.70,.09,1.08)
            l.Color=if j==1 then DARK else SUNNY
            l.Material=Enum.Material.SmoothPlastic
            l.CFrame=CFrame.new(p + Vector3.new(math.sin(theta)*1.40,
                rng:NextNumber(-.65,.8),
                math.cos(theta)*1.18))*CFrame.Angles(0,theta,math.rad(-16))
            l.Anchored=true
            l.CanCollide=false
            l.CanTouch=false
            l.CanQuery=false
            l.CastShadow=false
            l.Parent=parent
        end
    end
    for i=1,10 do
        local a=i*2.39996
        local p=ground+Vector3.new(math.sin(a)*3.1,
            5.3+(i%4)*.5,math.cos(a)*2.7 - .46)
        ball(parent,"OrangeFruit",p,Vector3.new(.72,.75,.73),ORANGE)
        local shine=ball(parent,"FruitSunlight",p+Vector3.new(-.13,.16,-.29),
            Vector3.new(.16,.20,.07),SHINE)
        shine.CastShadow=false
        branch(parent,"CitrusPeduncle",p+Vector3.new(0,.32,0),
            p+Vector3.new(.1,.58,.07),.065,DARK)
    end
end

local function woodFence(parent: Instance, from: Vector3, to: Vector3, posts: number)
    for i=0,posts do
        local at=from:Lerp(to,i/posts)
        local upper=at+Vector3.new(0,2.05,0)
        branch(parent,"PicketFencePost",at,upper,.35,WOOD)
        ball(parent,"RoundFenceFinial",upper,Vector3.new(.40,.39,.40),WOOD)
    end
    for y=.72,1.53,.81 do
        branch(parent,"PastelWoodFenceRail",
            from+Vector3.new(0,y,0),to+Vector3.new(0,y,0),.24,WOOD)
    end
end

local function toucan(parent: Instance, ground: Vector3)
    local center=ground+Vector3.new(0,1.28,0)
    ball(parent,"ToucanBlackBody",center,
        Vector3.new(1.68,2.32,1.43),BLACK)
    ball(parent,"ToucanSoftChest",center+Vector3.new(0,-.27,-.65),
        Vector3.new(.98,1.36,.22),PALE)
    ball(parent,"ToucanRoundHead",center+Vector3.new(0,.96,-.38),
        Vector3.new(1.58,1.58,1.46),BLACK)
    for sign=-1,1,2 do
        local eye=center+Vector3.new(sign*.44,1.04,-1.10)
        ball(parent,"ToucanGoldenEyeRing",eye,
            Vector3.new(.30,.34,.13),GOLD)
        ball(parent,"ToucanPupil",eye+Vector3.new(0,0,-.09),
            Vector3.new(.14,.17,.09),BLACK)
        ball(parent,"ToucanWing",center+Vector3.new(sign*.73,-.24,.20),
            Vector3.new(.30,1.18,.85),BLACK)
        branch(parent,"ToucanPerchLeg",
            ground+Vector3.new(sign*.41,.09,.24),
            ground+Vector3.new(sign*.41,.46,.10),.14,GOLD)
    end
    -- Beak is thick, readable in three-quarter view, with a grey upper bill.
    local bill=ball(parent,"ToucanCurvedBeak",
        center+Vector3.new(.18,.86,-1.38),
        Vector3.new(1.13,.85,1.17),PALE)
    bill.CFrame *= CFrame.Angles(0,math.rad(-19),math.rad(10))
    ball(parent,"ToucanBeakTip",center+Vector3.new(.38,.67,-1.79),
        Vector3.new(.67,.44,.66),Color3.fromRGB(171,186,186))
    local cap=ball(parent,"ToucanBlueCap",
        center+Vector3.new(0,1.72,-.32),
        Vector3.new(1.61,.43,1.43),BLUE)
    cap.CFrame *= CFrame.Angles(math.rad(-8),0,0)
    ball(parent,"ToucanCapBrim",center+Vector3.new(0,1.54,-1.01),
        Vector3.new(1.23,.16,.65),BLUE)
    -- Yellow emblem on the cap instead of copying any brand logo.
    ball(parent,"UnbrandedCapEmblem",
        center+Vector3.new(.11,1.79,-1.02),
        Vector3.new(.21,.14,.07),SHINE).CastShadow=false
end

function Dressing.build(world: Instance): Folder
    local old=world:FindFirstChild("ReferenceNativeBackdrop")
    if old then old:Destroy() end
    local folder=Instance.new("Folder")
    folder.Name="ReferenceNativeBackdrop"
    folder.Parent=world
    -- Tall orange branches on the right/rear, open corridor in front.
    orangeTree(folder,Vector3.new(16.5,7.15,65),4122)
    orangeTree(folder,Vector3.new(34,7.15,64),4833)
    orangeTree(folder,Vector3.new(-34,7.15,59),6401)
    woodFence(folder,Vector3.new(-36,7.23,62),
        Vector3.new(-17,7.23,62),5)
    woodFence(folder,Vector3.new(17,7.23,62),
        Vector3.new(39,7.23,62),6)
    -- The toucan stands behind the first strawberry bed (not on the path).
    toucan(folder,Vector3.new(-17.7,7.14,66.0))
    folder:SetAttribute("ArtSource","NativeGeometryNoExternalAssets")
    return folder
end

return Dressing
