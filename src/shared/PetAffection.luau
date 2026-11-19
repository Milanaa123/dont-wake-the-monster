--!strict
-- Pure, deterministic petting rules. The SERVER owns active sessions and noise.
-- For cats, repeated pleasant strokes raise purr intensity until the sound itself
-- may wake Giggles. Grumpy or overstimulated cats may swat, hiss, or run away.
local Affection = {}

Affection.CarryDistance = 22
Affection.PetDistance = 22
Affection.MaxSessionSeconds = 30
Affection.KeepaliveSeconds = 4
Affection.TickSeconds = 0.5

function Affection.isCat(species: any): boolean
    if type(species) ~= "string" then return false end
    local name = string.lower(species)
    return string.find(name, "kitten", 1, true) ~= nil
        or string.find(name, "cat", 1, true) ~= nil
end

local function clamp(value: number): number
    return math.clamp(value, 0, 100)
end

function Affection.newSession(p: any, cat: boolean, roll: number)
    local temperament = p.temperament
    local happiness = p.happiness
    local affection = p.affection == "HeadPats" or p.affection == "Cuddles"
    local patience = 6 + (p.bond / 100) * 7 + (p.traits.kindness / 100) * 5
    if temperament == "Grumpy" then patience -= 4 end
    if temperament == "Shy" then patience -= 1.6 end
    if temperament == "Clingy" then patience += 4 end
    if affection then patience += 3 end
    patience += math.clamp(roll, 0, 1) * 5
    local enjoys = happiness >= 34 and p.hunger < 92 and (p.bond >= 24 or temperament ~= "Grumpy")
    if p.energy <= 10 then enjoys = false end
    return {
        cat = cat,
        elapsed = 0,
        purr = 0,
        patience = math.clamp(patience, 3, 26),
        enjoys = enjoys,
        noiseFraction = 0,
        reacted = false,
        done = false,
    }
end

-- Rolls passed in by the server RNG; no client-supplied chance values.
-- Every return has {noise, purr, event, done, intensity}.
function Affection.step(p: any, session: any, dt: number, roll: number)
    if session.done then return {noise = 0, purr = session.purr, event = "Done", done = true, intensity = 0} end
    dt = math.clamp(dt, 0, Affection.TickSeconds)
    session.elapsed += dt
    local event = ""
    if session.elapsed >= Affection.MaxSessionSeconds then
        session.done = true
        return {noise = 0, purr = session.purr, event = "NeedsRest", done = true, intensity = 0}
    end

    local kindness = (p.traits.kindness or 50) / 100
    local sensitivity = (p.traits.sensitivity or 50) / 100
    local temperament = p.temperament
    local enjoys = session.enjoys and p.happiness > 17
    local rate = (0.045 + kindness * 0.03 + (p.bond / 100) * 0.045) * dt
    if temperament == "Clingy" then rate *= 1.5 end
    if temperament == "Grumpy" then rate *= 0.75 end

    if enjoys then
        p.happiness = clamp(p.happiness + 1.05 * dt)
        p.bond = clamp(p.bond + 0.34 * dt)
        if session.cat then
            session.purr = math.clamp(session.purr + rate, 0, 1)
        end
    else
        session.purr = math.max(0, session.purr - 0.09 * dt)
    end

    -- Affection is not guaranteed: an impatient cat can suddenly change its mind.
    -- The threshold is time-dependent and clamped so very long strokes are risky.
    if session.cat and session.elapsed > session.patience then
        local irritation = math.clamp(
            0.025 + sensitivity * 0.16 + (if temperament == "Grumpy" then 0.15 else 0)
                + (if temperament == "Mischievous" then 0.07 else 0)
                + (if enjoys then -0.055 else 0.15), 0.008, 0.4
        )
        if roll < irritation * dt then
            session.done = true
            session.purr = 0
            p.happiness = clamp(p.happiness - 5)
            local outcome = if temperament == "Mischievous" then "Zoomies"
                elseif temperament == "Shy" then "Hides"
                elseif roll < irritation * dt / 2 then "Swat" else "Hiss"
            return {noise = if outcome == "Hiss" then 4 else 7, purr = 0, event = outcome, done = true, intensity = 0}
        end
    end

    local soundLevel = session.cat and session.purr or 0
    local noiseRate = if session.cat and enjoys then (soundLevel * soundLevel * 11 + soundLevel * 1.2) else 0
    -- Converts continuous volume to integer global noise while preserving sub-tick fractions.
    session.noiseFraction += noiseRate * dt
    local noise = math.floor(session.noiseFraction)
    session.noiseFraction -= noise
    if session.cat and soundLevel >= 0.38 and not session.reacted then
        session.reacted = true
        event = "Purring"
    elseif session.cat and soundLevel >= 0.85 and roll < 0.07 * dt then
        event = "Purrquake"
        noise += 7
    end
    return {noise = noise, purr = soundLevel, event = event, done = false, intensity = soundLevel}
end

return Affection
