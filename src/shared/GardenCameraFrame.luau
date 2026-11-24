--!strict
local Frame = {}

function Frame.at(root: Vector3, move: Vector3, aspect: number, pond: Vector3?): (Vector3, Vector3, number)
    local focus = root + Vector3.new(-5.7, 3.3, -5.2) + move * 3.4
    if pond then
        local distance = Vector3.new(pond.X - root.X, 0, pond.Z - root.Z).Magnitude
        local near = math.clamp((18 - distance) / 10, 0, 1)
        -- Ease into the bank view while approaching. Keep the player in frame
        -- and preserve movement look-ahead when passing on the cottage path.
        local weight = near * near * (3 - 2 * near) * (1 - .65 * move.Magnitude)
        local offset = Vector3.new(pond.X - focus.X, 0, pond.Z - focus.Z)
        if offset.Magnitude > .001 then
            focus += offset.Unit * math.min(offset.Magnitude, 8) * weight
        end
    end
    local scale = if aspect < .8 then 1.28 elseif aspect < 1.15 then 1.09 else 1
    return focus, Vector3.new(16, 22, 23) * scale, if aspect < .8 then 52 else 48
end

return Frame
