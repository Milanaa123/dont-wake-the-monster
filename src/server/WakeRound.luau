--!strict
-- Round membership belongs to a visit. A reconnect cannot inherit a departed
-- player's survival credit. A new arrival can still join by making a rescue.
local Round = {}
local modes = {"Listen", "Chase", "Garden"}

function Round.mode(number: number): string
    return modes[(number-1)%#modes+1]
end

function Round.takeResult(profile: any, round: number, helped: boolean): boolean
    if profile.settledWake == round then return false end
    if profile.enteredWake ~= round and not helped then return false end
    profile.settledWake = round
    return true
end

function Round.ribbon(mode: string, hearts: number, helped: boolean, tracked: number, teamSafe: boolean): string?
    if hearts<=0 then return nil end
    if mode=="Listen" and helped and hearts==3 then return "QuietSteps" end
    if mode=="Chase" and tracked>=3 then return "TrailRunner" end
    if mode=="Garden" and helped and teamSafe then return "GardenKeeper" end
    return nil
end

function Round.comfort(noise: number, sensitivity: number, bond: number): number
    local relief = 2 + math.floor((100-sensitivity)/35) + math.floor(bond/40)
    return math.max(0, noise-relief)
end

function Round.alarm(species: string, traits: any, roll: number): (string?,number)
    if species=="Snorf" and roll < (110-traits.courage)/180 then return "PuppyYip",6 end
    if (species=="Swoop" or species=="Nugget" or species=="Puffin") and roll<traits.sociability/160 then
        return "BirdEcho",4
    end
    return nil,0
end

-- Check the shared distraction timer and stock together. Every check runs on
-- the server without yielding, so simultaneous throws cannot debit two bags.
function Round.throwLure(decoy: any, garden: any, id: any, now: number, position: any, consume: any): boolean
    if id~="SillyLure" and id~="GlowLure" then return false end
    if now<decoy.readyAt then return false end
    if not consume(garden,id,"lure") then return false end
    decoy.position=position
    decoy.untilTime=now+5
    decoy.readyAt=now+12
    return true
end

return Round
