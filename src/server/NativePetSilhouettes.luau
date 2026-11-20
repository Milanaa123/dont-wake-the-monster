--!strict
-- Reference-friendly species silhouettes for the *asset-free* playable place.
-- This does not replace imported high-resolution meshes or override pet stats.
local Species = {}
local IVORY = Color3.fromRGB(255,246,227)
local BLUSH = Color3.fromRGB(251,181,188)
local DARK = Color3.fromRGB(69,61,68)
local GOLD = Color3.fromRGB(249,207,114)
local LEAF = Color3.fromRGB(115,170,96)
local PEACH = Color3.fromRGB(231,161,112)
local PINK = Color3.fromRGB(249,168,201)

local family: {[string]: string} = {
    Pip="cat", Zuzu="cat", Mochi="lamb", Pickle="frog",
    Bloop="axolotl", Nugget="chick", Tofu="lamb", Wobble="bear",
    Spark="fox", Gloop="axolotl", Luma="lamb", Snorf="dog",
    Floofle="rabbit", Quibble="crab", Fizzle="dino",
    Puddle="axolotl", Sprig="deer", Twinkle="butterfly",
    Mallow="bear", Pebble="turtle", Noodle="ferret",
    Swoop="owl", Rumble="dino", Doodle="sprite",
    Crumble="bear", Squiggle="octopus", Glimmer="unicorn",
    Splat="frog", Puffin="puffin", Echo="bat",
}

local function sphere(model: Model, name: string, position: Vector3,
    size: Vector3, color: Color3): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Shape = Enum.PartType.Ball
    p.Size = size
    p.Position = position
    p.Color = color
    p.Material = Enum.Material.SmoothPlastic
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.Parent = model
    return p
end

local function line(model: Model, name: string,
    start: Vector3, finish: Vector3, width: number, color: Color3)
    local length = (finish-start).Magnitude
    if length < .05 then return end
    local p = Instance.new("Part")
    p.Name = name
    p.Size = Vector3.new(width,width,length)
    p.CFrame = CFrame.lookAt((start+finish)*.5,finish)
    p.Color = color
    p.Material = Enum.Material.SmoothPlastic
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Parent = model
end

function Species.apply(pet: Model, name: string, color: Color3): boolean
    local kind = family[name]
    if not kind or pet:GetAttribute("NativeSpeciesStyled") then return false end
    local root = pet.PrimaryPart
    if not root or not root:IsA("Part") then return false end
    local size: Vector3 = root.Size
    if kind=="frog" or kind=="crab" or kind=="turtle" or kind=="octopus" then
        size = Vector3.new(5.15,3.35,4.85)
    elseif kind=="chick" or kind=="owl" or kind=="puffin" then
        size = Vector3.new(3.45,4.4,3.35)
    elseif kind=="ferret" or kind=="axolotl" then
        size = Vector3.new(3.7,3.25,5.35)
    elseif kind=="deer" or kind=="unicorn" then
        size = Vector3.new(3.15,4.85,4.35)
    elseif kind=="butterfly" or kind=="bat" then
        size = Vector3.new(2.65,4.10,3.0)
    elseif kind=="dog" or kind=="bear" or kind=="lamb" then
        size = Vector3.new(4.65,4.15,4.45)
    elseif kind=="dino" then
        size = Vector3.new(4.25,4.1,5.1)
    elseif kind=="fox" then
        size = Vector3.new(3.6,3.7,5.3)
    end
    root.Size = size
    for _, obj in ipairs(pet:GetChildren()) do
        if obj:IsA("BasePart") then
            if obj.Name=="Ear" and kind~="cat" and kind~="fox" and kind~="unicorn" then
                obj.Transparency=1
            elseif obj.Name=="PuffTail" and kind~="rabbit" and kind~="bear" then
                obj.Transparency=1
            elseif obj.Name=="TinyFoot" and kind=="butterfly" then
                obj.Transparency=1
            end
        end
    end
    local s = function(label: string, p: Vector3, sz: Vector3, tint: Color3)
        return sphere(pet,label,p,sz,tint)
    end
    if kind=="cat" or kind=="fox" then
        for side=-1,1,2 do
            s("CreamMuzzle",Vector3.new(side*.44,-.38,-1.95),
                Vector3.new(.78,.56,.37),IVORY)
            for j=1,3 do
                line(pet,"CurvedWhisker",Vector3.new(side*.44,-.48+j*.14,-2.13),
                    Vector3.new(side*2.0,-.55+(j-2)*.35,-2.02),.045,IVORY)
            end
        end
        for i=1,3 do
            s("FluffyRisingTail",Vector3.new(.92+i*.27,-.35+i*.55,2.15+i*.28),
                Vector3.new(.85,.85,.89),
                if kind=="fox" and i==3 then IVORY else color)
        end
    elseif kind=="rabbit" then
        for side=-1,1,2 do
            s("FloppyMoonEar",Vector3.new(side*1.03,3.45,-.40),
                Vector3.new(.96,3.85,.52),color)
            s("SoftInnerEar",Vector3.new(side*1.03,3.53,-.76),
                Vector3.new(.51,2.89,.20),PINK)
            s("BunnyCheek",Vector3.new(side*.70,-.28,-1.93),
                Vector3.new(.84,.64,.50),IVORY)
        end
        s("CottonTail",Vector3.new(0,-.34,2.38),
            Vector3.new(1.25,1.18,1.2),IVORY)
    elseif kind=="ferret" then
        for side=-1,1,2 do
            s("FerretMask",Vector3.new(side*.56,.47,-2.28),
                Vector3.new(.80,.70,.25),IVORY)
            s("FerretPaw",Vector3.new(side*.79,-1.54,-1.62),
                Vector3.new(.68,.45,.74),IVORY)
        end
        s("LongCurvedTail",Vector3.new(1.1,.35,2.67),
            Vector3.new(.83,.86,1.75),color)
    elseif kind=="dog" then
        for side=-1,1,2 do
            s("SoftSpanielEar",Vector3.new(side*1.84,1.07,-.27),
                Vector3.new(1.09,2.55,.73),color:Lerp(DARK,.18))
            s("RoundPupMuzzle",Vector3.new(side*.40,-.62,-1.98),
                Vector3.new(.91,.70,.53),IVORY)
        end
        s("BigPuppyNose",Vector3.new(0,-.36,-2.43),
            Vector3.new(.48,.32,.32),DARK)
    elseif kind=="frog" then
        for side=-1,1,2 do
            s("Eyebulge",Vector3.new(side*1.35,1.91,-1.16),
                Vector3.new(1.15,1.15,1.12),color)
            s("FrogWhiteEye",Vector3.new(side*1.40,1.96,-1.71),
                Vector3.new(.65,.74,.21),IVORY)
            s("FrogPupil",Vector3.new(side*1.41,2.00,-1.87),
                Vector3.new(.32,.43,.14),DARK)
            s("SpreadFrogFoot",Vector3.new(side*1.85,-1.49,-1.08),
                Vector3.new(1.35,.34,1.02),color)
        end
        s("FrogBelly",Vector3.new(0,-.77,-1.9),
            Vector3.new(2.7,1.14,.37),IVORY)
    elseif kind=="axolotl" then
        for side=-1,1,2 do
            for j=1,3 do
                local y=1.49-j*.60
                s("WaterGills",Vector3.new(side*2.24,y,-.32),
                    Vector3.new(1.49,.43,.48),PINK)
                s("GillsFrill",Vector3.new(side*2.80,y+.18,-.39),
                    Vector3.new(.51,.50,.50),color:Lerp(PINK,.42))
            end
        end
        s("AxolotlTailFin",Vector3.new(0,-.25,2.45),
            Vector3.new(1.15,1.58,2.16),PINK)
    elseif kind=="chick" or kind=="owl" or kind=="puffin" then
        for side=-1,1,2 do
            local feather = s("FeatheredWing",Vector3.new(side*1.54,-.2,.30),
                Vector3.new(1.1,2.1,1.42),kind=="puffin" and DARK or color)
            feather.CFrame *= CFrame.Angles(0,0,math.rad(side*21))
            s("BirdEyePatch",Vector3.new(side*.72,.68,-1.68),
                Vector3.new(1.2,1.26,.18),kind=="owl" and IVORY or color)
        end
        local beak=s("CurvedGoldenBeak",Vector3.new(0,-.22,-1.96),
            Vector3.new(.72,.53,.94),GOLD)
        beak.CFrame *= CFrame.Angles(math.rad(-10),0,0)
        if kind=="chick" then
            for j=-1,1 do
                s("BabyChickTuft",Vector3.new(j*.38,2.35,.15),
                    Vector3.new(.38,.70,.46),color)
            end
        end
    elseif kind=="bear" or kind=="lamb" then
        for side=-1,1,2 do
            s("RoundedEar",Vector3.new(side*1.69,1.93,-.21),
                Vector3.new(.95,1.04,.83),color)
            s("EarInner",Vector3.new(side*1.72,1.93,-.67),
                Vector3.new(.53,.55,.23),BLUSH)
        end
        s("SoftCreamBelly",Vector3.new(0,-.66,-1.73),
            Vector3.new(2.42,1.96,.40),IVORY)
        if kind=="lamb" then
            for i=1,6 do
                local a=i*math.pi/3
                s("LittleWoolTuft",Vector3.new(math.cos(a)*1.20,1.83,
                    math.sin(a)*.7-.26),Vector3.new(.86,.87,.89),IVORY)
            end
        end
    elseif kind=="turtle" then
        s("TurtleShell",Vector3.new(0,.70,.59),
            Vector3.new(4.95,3.3,4.52),LEAF)
        for i=1,6 do
            local a=i*math.pi/3
            s("ShellScute",Vector3.new(math.sin(a)*1.38,1.96,
                .62+math.cos(a)*1.30),Vector3.new(1.02,.30,1.04),GOLD:Lerp(LEAF,.45))
        end
        s("TinyTurtleHead",Vector3.new(0,.35,-2.0),
            Vector3.new(2.56,2.02,2.18),color)
    elseif kind=="crab" then
        for side=-1,1,2 do
            s("CrabCrownEye",Vector3.new(side*1.0,1.89,-1.10),
                Vector3.new(.78,.85,.65),IVORY)
            s("CrabPupil",Vector3.new(side*1.0,1.94,-1.52),
                Vector3.new(.31,.37,.15),DARK)
            line(pet,"CrabClawArm",Vector3.new(side*1.75,-.44,-.12),
                Vector3.new(side*3.30,-.10,-1.18),.42,color)
            s("CrabPinkClaw",Vector3.new(side*3.38,-.06,-1.29),
                Vector3.new(1.34,1.18,1.32),color)
        end
    elseif kind=="octopus" then
        for i=1,8 do
            local a=i*math.pi/4
            local start=Vector3.new(math.sin(a)*.9,-1.16,
                math.cos(a)*1.1)
            local finish=Vector3.new(math.sin(a)*3.02,-2.18,
                math.cos(a)*2.85)
            line(pet,"CurvingOctopusArm",start,finish,.62,color)
            s("OctopusArmTip",finish,Vector3.new(.67,.58,.67),color)
        end
    elseif kind=="butterfly" or kind=="bat" then
        for side=-1,1,2 do
            local tint=if kind=="butterfly" then PINK else DARK:Lerp(color,.6)
            local wing=s("Wing",Vector3.new(side*2.35,.62,.56),
                Vector3.new(3.20,3.15,.31),tint)
            wing.CFrame *= CFrame.Angles(0,math.rad(side*12),
                math.rad(side*-13))
            if kind=="butterfly" then
                s("WingGoldDot",Vector3.new(side*3.20,.89,.36),
                    Vector3.new(.72,.74,.14),GOLD)
            end
        end
    elseif kind=="deer" or kind=="unicorn" then
        if kind=="deer" then
            for side=-1,1,2 do
                line(pet,"LittleAntler",Vector3.new(side*.75,2.1,-.20),
                    Vector3.new(side*1.28,3.53,-.13),.18,PEACH)
                line(pet,"AntlerBranch",Vector3.new(side*1.04,3.0,-.13),
                    Vector3.new(side*1.75,3.2,-.18),.14,PEACH)
            end
        else
            line(pet,"UnicornGoldenHorn",Vector3.new(0,2.0,-1.55),
                Vector3.new(0,3.75,-1.71),.40,GOLD)
        end
        s("LongNeckCreamCollar",Vector3.new(0,-.6,-1.7),
            Vector3.new(1.44,1.97,.38),IVORY)
    elseif kind=="dino" then
        for i=1,5 do
            local z=-1.4+i*.85
            s("DinosaurBackSpine",Vector3.new(0,2.01-i*.11,z),
                Vector3.new(.67,1.05,.91),LEAF)
        end
        s("DinosaurThickTail",Vector3.new(0,-.40,2.67),
            Vector3.new(1.37,1.26,2.0),color)
    elseif kind=="sprite" then
        for side=-1,1,2 do
            s("SpriteFloatingFlare",Vector3.new(side*1.86,.71,.50),
                Vector3.new(1.33,1.89,.47),PINK)
        end
        s("SpriteGoldCrown",Vector3.new(0,2.13,-.46),
            Vector3.new(1.50,.32,1.17),GOLD)
    end

    pet:SetAttribute("NativeSpeciesStyled",true)
    return true
end
return Species
