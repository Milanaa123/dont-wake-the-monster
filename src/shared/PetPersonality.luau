--!strict
-- Procedural personalities. A species does not determine a pet's personality.
-- Pure Luau for CLI unit tests; every persistent value is server-owned.
local Personality = {}

Personality.Temperaments = {
    "Kind", "Grumpy", "Playful", "Mischievous", "Shy", "Brave",
    "Curious", "Sleepy", "Dramatic", "Clingy", "Proud", "Wild",
}
Personality.Habits = {
    "Cuddles", "Dances", "CollectsShiny", "Naps", "Hides", "Jumps",
    "MakesFaces", "Hums", "ChasesTail", "StealsSnacks", "Daydreams", "Sneezes",
}
Personality.Fears = {
    "Thunder", "Darkness", "Crowds", "SuddenNoise", "BigMonsters", "Water", "None",
}
Personality.Affection = {"HeadPats", "Cuddles", "Dancing", "Games", "Food", "QuietTime", "Praise"}
Personality.Foods = {"Candy", "Pepper", "Bubble", "Star"}
Personality.Moods = {"Happy", "Calm", "Grumpy", "Excited", "Shy", "Scared", "Sleepy", "Hungry", "Curious"}

local LIMIT = 2147483647
local function sane(value: any, default: number): number
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then return default end
    return math.clamp(math.floor(value), 0, 100)
end

-- Exact integer arithmetic: products remain < 2^53, reproducible in Luau.
local function generator(rawSeed: number)
    local seed = math.max(1, math.floor(math.abs(rawSeed)) % (LIMIT - 1))
    return function(max: number): number
        seed = (seed * 48271) % LIMIT
        return seed % max + 1
    end
end

local function has(items: {string}, key: any): boolean
    if type(key) ~= "string" then return false end
    for _, value in ipairs(items) do
        if value == key then return true end
    end
    return false
end

function Personality.seedFor(userId: number, petIndex: number): number
    return math.max(1, (math.floor(math.abs(userId)) * 73 + petIndex * 7919 + 524287) % (LIMIT - 1))
end

function Personality.generate(seed: number, species: string?)
    local normalizedSeed = math.max(1, math.floor(math.abs(seed)) % (LIMIT - 1))
    local roll = generator(normalizedSeed)
    local temperament = Personality.Temperaments[roll(#Personality.Temperaments)]
    local habit = Personality.Habits[roll(#Personality.Habits)]
    local fear = Personality.Fears[roll(#Personality.Fears)]
    local favoriteIndex = roll(#Personality.Foods)
    local dislikedIndex = (favoriteIndex + roll(#Personality.Foods - 1) - 1) % #Personality.Foods + 1
    local traits = {
        kindness = 22 + roll(70),
        curiosity = 12 + roll(80),
        courage = 12 + roll(80),
        mischief = 12 + roll(80),
        sociability = 12 + roll(80),
        sensitivity = 12 + roll(80),
    }
    -- Give temperaments a statistical signature, not fixed compulsory behavior.
    local hints = {
        Kind = {"kindness", 22}, Grumpy = {"sensitivity", 23},
        Playful = {"curiosity", 24}, Mischievous = {"mischief", 25},
        Shy = {"sociability", -23}, Brave = {"courage", 26},
        Curious = {"curiosity", 26}, Sleepy = {"mischief", -18},
        Dramatic = {"sensitivity", 25}, Clingy = {"kindness", 14},
        Proud = {"sociability", -12}, Wild = {"mischief", 20},
    }
    local hint = hints[temperament]
    if hint then traits[hint[1]] = math.clamp(traits[hint[1]] + hint[2], 1, 100) end
    return {
        seed = normalizedSeed,
        temperament = temperament,
        habit = habit,
        fear = fear,
        favoriteFood = Personality.Foods[favoriteIndex],
        dislikedFood = Personality.Foods[dislikedIndex],
        affection = Personality.Affection[roll(#Personality.Affection)],
        traits = traits,
        happiness = 65 + roll(20),
        energy = 55 + roll(33),
        hunger = 27 + roll(25),
        bond = 5 + roll(15),
        interactions = 0,
        species = if type(species) == "string" then string.sub(species, 1, 35) else "",
    }
end

function Personality.restore(raw: any, species: string?): any?
    if type(raw) ~= "table" or type(raw.seed) ~= "number" then return nil end
    local seed = raw.seed
    if seed ~= math.floor(seed) or seed < 1 or seed >= LIMIT then return nil end
    local p = Personality.generate(seed, species)
    -- Immutable identity traits derive from seed: never trust client/save edits.
    p.happiness = sane(raw.happiness, p.happiness)
    p.energy = sane(raw.energy, p.energy)
    p.hunger = sane(raw.hunger, p.hunger)
    p.bond = sane(raw.bond, p.bond)
    if type(raw.interactions) == "number" and raw.interactions == math.floor(raw.interactions) then
        p.interactions = math.clamp(raw.interactions, 0, 1000000)
    end
    return p
end

function Personality.pack(p: any)
    return {
        seed = p.seed,
        happiness = sane(p.happiness, 60),
        energy = sane(p.energy, 60),
        hunger = sane(p.hunger, 40),
        bond = sane(p.bond, 10),
        interactions = math.clamp(math.floor(p.interactions or 0), 0, 1000000),
    }
end

function Personality.mood(p: any, monsterAwake: boolean?): string
    if monsterAwake and p.fear == "BigMonsters" and p.traits.courage < 75 then return "Scared" end
    if p.hunger >= 77 then return "Hungry" end
    if p.energy <= 22 then return "Sleepy" end
    if p.happiness < 31 then return "Grumpy" end
    if p.temperament == "Shy" and p.bond < 38 then return "Shy" end
    if p.happiness >= 86 and p.energy >= 56 then return "Excited" end
    if p.temperament == "Curious" and p.energy >= 44 then return "Curious" end
    if p.happiness >= 65 then return "Happy" end
    return "Calm"
end

function Personality.feed(p: any, food: string): (string, number)
    if not has(Personality.Foods, food) then return "Unknown snack", 0 end
    local liked = food == p.favoriteFood
    local hated = food == p.dislikedFood
    local reaction = if liked then "LOVES THIS SNACK!" elseif hated then "YUCK! NOT MY FAVORITE!" else "NOM NOM!"
    local affection = if liked then 5 elseif hated then -3 else 2
    p.hunger = math.max(0, p.hunger - (if liked then 24 else 15))
    p.happiness = math.clamp(p.happiness + (if liked then 12 elseif hated then -13 else 4), 0, 100)
    p.energy = math.clamp(p.energy + (if food == "Pepper" then 7 else 2), 0, 100)
    p.bond = math.clamp(p.bond + math.max(0, affection), 0, 100)
    p.interactions += 1
    return reaction, if liked then -3 elseif hated then 8 else 0
end

function Personality.interact(p: any, action: string): (boolean, string)
    if action ~= "Pet" and action ~= "Play" and action ~= "Comfort" then return false, "Unknown interaction" end
    if action == "Play" and p.energy < 12 then
        return false, "Too sleepy to play! Give your friend a rest."
    end
    local grumpy = p.temperament == "Grumpy" and p.bond < 20
    local shy = p.temperament == "Shy" and p.bond < 30
    if action == "Pet" then
        p.happiness = math.clamp(p.happiness + (if grumpy then 2 else 10), 0, 100)
        p.bond = math.clamp(p.bond + (if grumpy then 1 else 4), 0, 100)
        p.energy = math.clamp(p.energy - 1, 0, 100)
        p.interactions += 1
        return true, if grumpy then "HMPH! One tiny pat. Don't get used to it!" elseif shy then "Eek! A shy little head boop!" else "PURR PURR! Best friends!"
    elseif action == "Play" then
        p.happiness = math.clamp(p.happiness + (if p.temperament == "Playful" then 16 else 9), 0, 100)
        p.bond = math.clamp(p.bond + 5, 0, 100)
        p.energy = math.max(0, p.energy - (if p.temperament == "Wild" then 17 else 12))
        p.hunger = math.min(100, p.hunger + 6)
        p.interactions += 1
        return true, if p.temperament == "Sleepy" then "A sleepy little wiggle!" else "ZOOMIES! Catch me if you can!"
    end
    p.happiness = math.clamp(p.happiness + 8, 0, 100)
    p.bond = math.clamp(p.bond + (if p.temperament == "Shy" then 7 else 4), 0, 100)
    p.energy = math.clamp(p.energy + 9, 0, 100)
    p.interactions += 1
    return true, if p.fear == "BigMonsters" then "Safe in your arms. No scary giants!" else "Soothed with gentle cuddles."
end

function Personality.idle(p: any, monsterAwake: boolean?): string
    if monsterAwake and p.traits.courage <= 40 then return "Hides" end
    if p.hunger >= 78 then return "Begging" end
    if p.energy <= 23 then return "Naps" end
    if p.temperament == "Grumpy" and p.happiness < 65 then return "MakesFaces" end
    if p.temperament == "Clingy" and p.bond >= 45 then return "Cuddles" end
    if p.temperament == "Wild" and p.energy > 65 then return "Jumps" end
    return p.habit
end

function Personality.tick(p: any, monsterAwake: boolean?): string
    local m = Personality.mood(p, monsterAwake)
    p.hunger = math.min(100, p.hunger + 2)
    p.energy = math.clamp(p.energy + (if m == "Sleepy" then 10 elseif monsterAwake then -5 else 2), 0, 100)
    if p.hunger > 80 then p.happiness = math.max(0, p.happiness - 2) end
    if monsterAwake and p.fear == "BigMonsters" then p.happiness = math.max(0, p.happiness - 3) end
    return Personality.idle(p, monsterAwake)
end

local favored = {
    Kind = {"Confetti", "Cloud", "Rainbow"}, Grumpy = {"Sneeze", "Hiccup", "Meteor"},
    Playful = {"Bounce", "Disco", "Spin"}, Mischievous = {"Clone", "Spin", "Giant"},
    Shy = {"Mini", "Cloud", "Rainbow"}, Brave = {"Giant", "Meteor", "Bounce"},
    Curious = {"Clone", "Rainbow", "Confetti"}, Sleepy = {"Mini", "Cloud", "Hiccup"},
    Dramatic = {"Sneeze", "Disco", "Meteor"}, Clingy = {"Cloud", "Confetti", "Clone"},
    Proud = {"Giant", "Disco", "Rainbow"}, Wild = {"Bounce", "Meteor", "Spin"},
}
function Personality.reactionMultiplier(p: any, reactionId: string): number
    local mult = 1
    for _, id in ipairs(favored[p.temperament] or {}) do
        if id == reactionId then mult *= 2.2 end
    end
    if p.traits.mischief > 70 and (reactionId == "Clone" or reactionId == "Spin") then mult *= 1.3 end
    if p.traits.courage < 35 and reactionId == "Mini" then mult *= 1.35 end
    if p.energy < 25 and reactionId == "Cloud" then mult *= 1.4 end
    return mult
end

return Personality
