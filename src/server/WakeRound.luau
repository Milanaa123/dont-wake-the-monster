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

function Round.comfort(noise: number, sensitivity: number, bond: number): number
    local relief = 2 + math.floor((100-sensitivity)/35) + math.floor(bond/40)
    return math.max(0, noise-relief)
end

return Round
