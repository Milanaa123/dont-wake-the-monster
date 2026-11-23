--!strict
-- Permanent cosmetic ownership stays with Roblox. The grant is a boolean and
-- repeated delivery never increments inventory, coins or crop yields.
local Cosmetic = {Enabled=false, PassId=0}

function Cosmetic.owns(market: any, userId: number, enabled: boolean, passId: number): boolean?
    if not enabled or passId<=0 then return false end
    local ok,result=pcall(function() return market:UserOwnsGamePassAsync(userId,passId) end)
    if not ok then return nil end
    return result==true
end

return Cosmetic
