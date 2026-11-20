--!strict
-- Native Roblox R15 chibi gardener outfit. Renders without any external asset IDs.
-- Keeps standard R15 Motor6Ds, animation, collision, physics and mobile control.
-- The imported original Avatar_ GLB parts always take priority.
local NativeAvatar = {}

local HAIR = Color3.fromRGB(100, 73, 53)
local HAIR_LIGHT = Color3.fromRGB(121, 86, 62)
local SKIN = Color3.fromRGB(255, 215, 179)
local CHEEK = Color3.fromRGB(245, 164, 162)
local EYE = Color3.fromRGB(67, 56, 49)
local WHITE = Color3.fromRGB(255, 249, 225)
local DENIM = Color3.fromRGB(134, 183, 220)
local DENIM_DARK = Color3.fromRGB(88, 149, 191)
local SUNFLOWER = Color3.fromRGB(251, 206, 100)

local function attach(folder: Folder, limb: BasePart, name: string,
    relative: CFrame, size: Vector3, color: Color3,
    shape: Enum.PartType?): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Shape = shape or Enum.PartType.Ball
    part.Size = size
    part.Material = Enum.Material.SmoothPlastic
    part.Color = color
    part.Anchored = false
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    part.CastShadow = true
    part.CFrame = limb.CFrame * relative
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = folder
    local weld = Instance.new("WeldConstraint")
    weld.Name = "ChibiR15Weld"
    weld.Part0 = limb
    weld.Part1 = part
    weld.Parent = part
    return part
end

local function bobHair(folder: Folder, head: BasePart)
    local a = function(name: string, x: number, y: number, z: number,
        sx: number, sy: number, sz: number, color: Color3)
        return attach(folder,head,name,CFrame.new(x,y,z),
            Vector3.new(sx,sy,sz),color)
    end
    a("HairBack",0,.04,.24,1.89,1.95,1.53,HAIR)
    a("ChibiFace",0,-.11,-.21,1.63,1.63,1.39,SKIN)
    -- Short bob fringe with directional locks, a distinct silhouette.
    a("HairCrown",0,.73,.12,1.80,.46,1.45,HAIR)
    for i = 1, 6 do
        local x = -.68+(i-1)*.27
        a("SweptHairLock_"..i,x,.58,-.66,.35,
            if i%2==0 then .52 else .41,.32,
            if i%3==0 then HAIR_LIGHT else HAIR)
    end
    for sign = -1,1,2 do
        a("SoftBobSide",sign*.81,-.19,-.02,.35,1.10,.84,HAIR)
        a("BobCurl",sign*.81,-.66,.12,.33,.43,.67,HAIR_LIGHT)
    end
    for sign = -1,1,2 do
        a("ClosedDollEye",sign*.32,-.08,-.92,.15,.23,.075,EYE)
        a("LittleEyeShine",sign*.29,-.02,-.987,.045,.063,.023,WHITE)
        a("RosyCheek",sign*.57,-.33,-.80,.25,.13,.05,CHEEK)
    end
    a("LittleNose",0,-.30,-.927,.095,.065,.038,
        Color3.fromRGB(227,168,145))
    a("GentleSmile",0,-.46,-.91,.27,.065,.045,EYE)
    for flower = 1,2 do
        local cx = if flower==1 then .68 else .91
        local cy = if flower==1 then .69 else .45
        local cz = -.75
        local scale = if flower==1 then 1 else .74
        for petal=1,5 do
            local th=petal*math.pi*2/5
            a("HairDaisyPetal",cx+math.cos(th)*.19*scale,
                cy+math.sin(th)*.19*scale,cz,
                .23*scale,.29*scale,.09,WHITE)
        end
        a("GoldenDaisyCenter",cx,cy,cz-.055,.18*scale,.18*scale,
            .09,SUNFLOWER)
    end
end

local function skinLimb(folder: Folder, limb: BasePart,
    name: string, color: Color3, multiplier: number)
    return attach(folder,limb,name,CFrame.identity,limb.Size * multiplier,color)
end

function NativeAvatar.apply(character: Model): boolean
    if character:GetAttribute("DWTMNativeGardenAvatar") == true then
        return true
    end
    -- Never overwrite a custom imported chibi avatar.
    if character:GetAttribute("DWTMStorybookAvatar") == true then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R15 then return false end
    local names = {
        "Head", "UpperTorso", "LowerTorso",
        "LeftUpperArm", "LeftLowerArm", "LeftHand",
        "RightUpperArm", "RightLowerArm", "RightHand",
        "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
        "RightUpperLeg", "RightLowerLeg", "RightFoot"
    }
    local bones: {[string]: BasePart} = {}
    for _, n in ipairs(names) do
        local obj=character:FindFirstChild(n)
        if not obj or not obj:IsA("BasePart") then return false end
        bones[n]=obj
    end
    local old = character:FindFirstChild("NativeGardenOutfit")
    if old then old:Destroy() end
    local folder = Instance.new("Folder")
    folder.Name = "NativeGardenOutfit"
    folder.Parent = character

    bobHair(folder,bones.Head)
    local upper=bones.UpperTorso
    skinLimb(folder,upper,"WhiteGardenBlouse",WHITE,1.12)
    attach(folder,upper,"BlueOverallsBib",CFrame.new(0,-.13,-.47),
        Vector3.new(.86,.89,.15),DENIM)
    for sign=-1,1,2 do
        attach(folder,upper,"OverallsSuspender",CFrame.new(sign*.38,.41,-.49),
            Vector3.new(.16,.66,.16),DENIM_DARK)
        attach(folder,upper,"OverallButton",CFrame.new(sign*.36,.25,-.61),
            Vector3.new(.12,.12,.05),SUNFLOWER)
    end
    attach(folder,upper,"OverallPocket",CFrame.new(0,-.39,-.57),
        Vector3.new(.38,.24,.055),DENIM_DARK)
    skinLimb(folder,bones.LowerTorso,"BlueOverallShorts",DENIM,1.10)
    for _, side in ipairs({"Left","Right"}) do
        local upArm=bones[side.."UpperArm"]
        local lowArm=bones[side.."LowerArm"]
        local hand=bones[side.."Hand"]
        local upLeg=bones[side.."UpperLeg"]
        local lowLeg=bones[side.."LowerLeg"]
        local foot=bones[side.."Foot"]
        skinLimb(folder,upArm,"PuffedBlouseSleeve",WHITE,1.19)
        attach(folder,upArm,"SleeveTrim",
            CFrame.new(0,-upArm.Size.Y*.36,0),
            Vector3.new(upArm.Size.X*1.05,.15,upArm.Size.Z*1.08),WHITE)
        skinLimb(folder,lowArm,"GardenBareArm",SKIN,.96)
        skinLimb(folder,hand,"LittleGardenHand",SKIN,1.08)
        skinLimb(folder,upLeg,"OverallsShortLeg",DENIM,1.10)
        skinLimb(folder,lowLeg,"SkinLeg",SKIN,.96)
        attach(folder,lowLeg,"WhiteSocks",CFrame.new(0,-lowLeg.Size.Y*.34,0),
            Vector3.new(lowLeg.Size.X*.99,lowLeg.Size.Y*.23,
                lowLeg.Size.Z*.99),WHITE)
        skinLimb(folder,foot,"SunflowerShoes",SUNFLOWER,1.20)
        attach(folder,foot,"ShoeWhiteToe",CFrame.new(0,.075,-foot.Size.Z*.33),
            Vector3.new(foot.Size.X*.82,.09,foot.Size.Z*.42),WHITE)
    end

    -- Verify all graphics are mounted before hiding the default Roblox body.
    if #folder:GetChildren() < 28 then
        folder:Destroy()
        return false
    end
    for _, limb in pairs(bones) do
        limb.Transparency=1
        limb.CastShadow=false
    end
    for _, item in ipairs(character:GetDescendants()) do
        if item:IsA("Decal") and item.Parent==bones.Head then
            item.Transparency=1
        elseif item:IsA("BasePart") and item.Parent and
            item.Parent:IsA("Accessory") then
            item.Transparency=1
        end
    end
    character:SetAttribute("DWTMNativeGardenAvatar",true)
    return true
end

return NativeAvatar
