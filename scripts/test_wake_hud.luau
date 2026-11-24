-- Exercise the shipped HUD and first-minute guide against the same snapshots.
-- Signals and GUI properties are in memory. This does not test screen layout.
local r=require("@lune/roblox")
local luau=require("@lune/luau")
local fs=require("@lune/fs")
local file=assert(require("@lune/process").args[1])
local place=r.deserializePlace(fs.readFile(file))
local shared=place:GetService("ReplicatedStorage")
local client=place:GetService("StarterPlayer").StarterPlayerScripts
local function signal()
    local callbacks={}
    return {Connect=function(_,cb) table.insert(callbacks,cb) end,
        fire=function(...) for _,cb in callbacks do cb(...) end end}
end
local objects={}
local function makeGui(class)
    local item={Name=class,Destroying=signal(),MouseButton1Click=signal(),Activated=signal()}
    table.insert(objects,item)
    return item
end
local function named(name)
    for _,obj in objects do if obj.Name==name then return obj end end
    error("Missing GUI "..name)
end
local function displays(copy)
    for _,obj in objects do if obj.Text==copy then return true end end
    return false
end
local root=r.Instance.new("Part")
root.Name="HumanoidRootPart"
root.Position=r.Vector3.zero
local character=r.Instance.new("Model")
root.Parent=character
local island=r.Instance.new("Folder")
local world={CurrentCamera={CFrame=r.CFrame.identity},FindFirstChild=function(_,key)
    if key=="MonsterIsland" then return island end
end}
local commands={}
local remote={OnClientEvent=signal(),FireServer=function(_,...) table.insert(commands,{...}) end}
local clock=signal()
local player={UserId=7,Character=character,WaitForChild=function() return {} end}
local config=luau.load(shared.Config.Source,{environment={Color3=r.Color3},injectGlobals=true})()
local route=luau.load(shared.RescueRoute.Source)()
local services={ReplicatedStorage={WaitForChild=function(_,key) return if key=="MonsterRemote" then remote else key end},
    Players={LocalPlayer=player},UserInputService={InputBegan=signal()},RunService={Heartbeat=clock},
    TweenService={Create=function() return {Play=function() end} end}}
local env={game={GetService=function(_,key) return assert(services[key],key) end},workspace=world,
    require=function(key) return if key=="Config" then config else route end,
    Instance={new=makeGui},Enum=r.Enum,Vector2=r.Vector2,Color3=r.Color3,UDim=r.UDim,
    UDim2=r.UDim2,ColorSequence=r.ColorSequence,TweenInfo={new=function() return {} end}}
for _,scriptName in {"HUD","FirstMinuteGuide"} do
    luau.load(client[scriptName].Source,{environment=env,injectGlobals=true})()
end
assert(#commands==1 and commands[1][1]=="Sync")
local send=remote.OnClientEvent.fire
send({type="collection",feedCount=1,survivalCount=0})
send({type="garden",plots={}})
local guide=named("NextObjective")
send({type="state",phase="SLEEP",time=38,noise=94,maxNoise=100})
assert(guide.Visible)
send({type="state",phase="SLEEP",time=37,warning="Noise",wakeIn=4,noise=100,maxNoise=100})
assert(not guide.Visible and displays("00:04") and displays("SOOTHE YOUR PET TO QUIET THE GARDEN"))
send({type="state",phase="SLEEP",time=36,noise=94,maxNoise=100})
assert(guide.Visible and displays("00:36"))
send({type="state",phase="SLEEP",time=3,warning="Timer",wakeIn=3})
assert(not guide.Visible and displays("NAP ALMOST OVER • GET READY TO RESCUE"))

local pet=r.Instance.new("Model")
pet.Name="RescueRunaway_1"
pet:SetAttribute("RescueRound",10)
local rescue={active=true,round=10,rescued=0,goal=2,targets={{id=1,name="Pip",position=r.Vector3.new(0,0,-24),helper=0}}}
send({type="state",phase="AWAKE",rescue=rescue,time=30})
local outline=named("SelectedLostPet")
local assist=named("SignalTeammates")
assert(not guide.Visible and not named("FeedControls").Visible)
assert(not outline.Enabled and displays("↑ Pip · 24 studs · Lost pet"))
pet.Parent=island
clock.fire(.16)
assert(outline.Enabled and outline.Adornee==pet and assist.Visible)
assist.Activated.fire()
assert(commands[2][1]=="RescueSignal" and commands[2][2].round==10 and commands[2][2].id==1)
send({type="stats",knockedOut=true,hearts=0})
assert(not outline.Enabled and not assist.Visible)
send({type="stats",knockedOut=false,hearts=3})
assert(outline.Enabled)
rescue.completed=true
send({type="state",phase="AWAKE",rescue=rescue,time=12})
assert(not outline.Enabled and not assist.Visible and outline.Adornee==nil)
send({type="state",phase="COOLDOWN",time=10})
assert(not named("CoopRescueChallenge").Visible and not outline.Enabled)
print("PASS: actual client handles noise, soothing, nap deadline, streamed rescue marker, team signal and knockout")
