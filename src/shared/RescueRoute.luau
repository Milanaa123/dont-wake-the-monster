--!strict
local Route = {}
export type Target = {id: number, name: string, position: Vector3, helper: number}

function Route.choose(targets: {Target}, userId: number, origin: Vector3): Target?
    local choice: Target? = nil
    local bestGroup, bestDistance = math.huge, math.huge
    for _, target in ipairs(targets) do
        local group = if target.helper == userId then 0 elseif target.helper == 0 then 1 else 2
        local distance = (target.position - origin).Magnitude
        if group < bestGroup or (group == bestGroup and distance < bestDistance) then
            choice, bestGroup, bestDistance = target, group, distance
        end
    end
    return choice
end

-- A streamed-in model must belong to the same round as its target snapshot.
function Route.modelFor(island: Instance?, round: number, id: number): Model?
    local model = if island then island:FindFirstChild("RescueRunaway_" .. id) else nil
    if model and model:IsA("Model") and model:GetAttribute("RescueRound") == round then return model end
    return nil
end

local arrows = {"↑","↗","→","↘","↓","↙","←","↖"}
function Route.arrow(delta: Vector3, cameraRight: Vector3): string
    -- Horizontal motion stays readable even when the camera points straight down.
    local right = delta.X * cameraRight.X + delta.Z * cameraRight.Z
    local ahead = delta.X * cameraRight.Z - delta.Z * cameraRight.X
    return arrows[math.floor(math.atan2(right, ahead) / (math.pi / 4) + .5) % 8 + 1]
end

return Route
