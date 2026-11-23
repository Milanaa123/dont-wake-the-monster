-- Run the modules from the CI-built place. Prompt delivery, players and time
-- are controlled by the harness so the same stale callback can be delivered twice.
local fs=require("@lune/fs")
local r=require("@lune/roblox")
local luau=require("@lune/luau")
local args=require("@lune/process").args
local place=r.deserializePlace(fs.readFile(args[1]))
local server=place:GetService("ServerScriptService")
local Round=luau.load(server.WakeRound.Source)()
assert(Round.mode(1)=="Listen" and Round.mode(2)=="Chase" and Round.mode(3)=="Garden" and Round.mode(4)=="Listen")
local member={enteredWake=1}
assert(Round.takeResult(member,1,false) and not Round.takeResult(member,1,true))
assert(not Round.takeResult({},1,false),"Late arrival must earn its place by rescuing")
assert(Round.takeResult({},1,true) and not Round.takeResult(member,2,false))
assert(Round.comfort(1,60,0)==0 and Round.comfort(20,10,90)<Round.comfort(20,90,0))

local prompts={}
local root={Position=r.Vector3.zero,IsA=function(_,class) return class=="BasePart" end}
local hum={Health=100}
local character={FindFirstChild=function() return root end,FindFirstChildOfClass=function() return hum end}
local a,b={Character=character},{Character=character}
local players={GetPlayers=function() return {a,b} end}
local requires={Config={Pets={{name="Pip",ear="pointy",color=r.Color3.new()}}}, World={
    burst=function() end,
    makePet=function()
        return {Parent=true,PrimaryPart={Position=r.Vector3.zero},PivotTo=function() end,
            Destroy=function(self) self.Parent=nil end}
    end,
}}
local folder={WaitForChild=function(_,name) return name end}
local env={game={GetService=function(_,name) return if name=="Players" then players else folder end},
    require=function(key) return requires[key] end,script={Parent=folder},Vector3=r.Vector3,CFrame=r.CFrame,
    Enum=r.Enum,Random={new=function() return {NextInteger=function(_,n) return n end,
        NextNumber=function(_,x,y) return (x+y)/2 end} end},
    Instance={new=function(class)
        assert(class=="ProximityPrompt")
        local p={Triggered={Connect=function(_,cb) table.insert(prompts,cb) end}}
        return p
    end}}
local rescue=luau.load(server.RescueObjective.Source,{environment=env,injectGlobals=true})()
local coins,completion={},0
local function grant(who,done,reward)
    coins[who]=(coins[who] or 0)+reward
    if done then completion+=1 end
end
rescue.start(grant,function() return true end)
assert(rescue.status().goal==2 and #prompts==2)
local first,second=prompts[1],prompts[2]
root.Position=r.Vector3.new(50,0,0)
first(a)
root.Position=r.Vector3.zero
hum.Health=0
first(a)
assert(not coins[a])
hum.Health=100
first(a)
first(b)
assert(coins[a]==8 and not coins[b] and rescue.participated(a))
second(b)
second(a)
assert(coins[b]==8 and completion==1 and rescue.completed() and rescue.status().rescued==2)
rescue.finish()
rescue.start(grant,function(who) return who==b end)
second(a)
prompts[3](a)
assert(rescue.status().rescued==0)
prompts[3](b)
local stale=prompts[4]
rescue.finish()
rescue.start(grant,function() return true end)
stale(a)
assert(rescue.status().rescued==0 and not rescue.participated(b) and coins[b]==16)
print("PASS: built-place two-player rescue, distance, health, duplicate, stale prompt, admission, settlement, comfort, scenario order")
