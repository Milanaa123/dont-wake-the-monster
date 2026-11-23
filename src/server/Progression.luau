--!strict
-- Pure progression rules. Never trust a client-supplied coin total or ownership flag.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Garden = require(script.Parent:WaitForChild("Garden"))
local Personality = require(ReplicatedStorage:WaitForChild("PetPersonality"))

local Progression = {}
local MAX_COINS = 1000000000

local function saneInt(value: any, maximum: number): number
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then return 0 end
    return math.clamp(math.floor(value), 0, maximum)
end

local reactionIds: {[string]: boolean} = {}
for _, reaction in ipairs(Config.Reactions) do
    reactionIds[reaction.id] = true
end

function Progression.new()
    return {
        coins = 0,
        petIndex = 1,
        owned = {[1] = true},
        discovered = {},
        feedCount = 0,
        survivalCount = 0,
        questClaimed = {feeds = false, survivals = false, discoveries = false},
        dailyDay = -1,
        tutorialSeen = false,
        garden = Garden.new(),
        personalities = {},
    }
end

function Progression.load(profile: any, data: any)
    if type(data) ~= "table" then return end
    profile.coins = saneInt(data.coins, MAX_COINS)
    profile.garden = Garden.load(data.garden)
    local id = saneInt(data.petIndex, #Config.Pets)
    profile.petIndex = if id >= 1 then id else 1

    if type(data.owned) == "table" then
        for _, value in ipairs(data.owned) do
            local index = saneInt(value, #Config.Pets)
            if index >= 1 then profile.owned[index] = true end
        end
    end
    -- Old v1 accounts only stored equipped pet; never revoke their old companion.
    profile.owned[1] = true
    profile.owned[profile.petIndex] = true

    -- Migrate old collections without changing ownership or resetting progress.
    if type(data.personalities) == "table" then
        for i = 1, #Config.Pets do
            if profile.owned[i] then
                local raw = data.personalities[tostring(i)] or data.personalities[i]
                local pet = Config.Pets[i]
                local restored = Personality.restore(raw, pet.description or pet.name)
                if restored then profile.personalities[i] = restored end
            end
        end
    end

    if type(data.discovered) == "table" then
        for _, reactionId in ipairs(data.discovered) do
            if type(reactionId) == "string" and reactionIds[reactionId] then
                profile.discovered[reactionId] = true
            end
        end
    end

    profile.feedCount = saneInt(data.feedCount, 1000000)
    profile.survivalCount = saneInt(data.survivalCount, 1000000)
    profile.dailyDay = if data.dailyDay == nil then -1 else saneInt(data.dailyDay, 1000000)
    profile.tutorialSeen = data.tutorialSeen == true
    if type(data.questClaimed) == "table" then
        for quest in pairs(Config.QUEST_GOALS) do
            profile.questClaimed[quest] = data.questClaimed[quest] == true
        end
    end
end

function Progression.serialize(profile: any)
    local owned = {}
    for i = 1, #Config.Pets do
        if profile.owned[i] == true then table.insert(owned, i) end
    end
    local discovered = {}
    for _, reaction in ipairs(Config.Reactions) do
        if profile.discovered[reaction.id] == true then
            table.insert(discovered, reaction.id)
        end
    end
    local personalityData = {}
    for i = 1, #Config.Pets do
        if profile.owned[i] and profile.personalities[i] then
            personalityData[tostring(i)] = Personality.pack(profile.personalities[i])
        end
    end
    return {
        coins = saneInt(profile.coins, MAX_COINS),
        personalities = personalityData,
        petIndex = profile.petIndex,
        owned = owned,
        discovered = discovered,
        feedCount = profile.feedCount,
        survivalCount = profile.survivalCount,
        questClaimed = {
            feeds = profile.questClaimed.feeds,
            survivals = profile.questClaimed.survivals,
            discoveries = profile.questClaimed.discoveries,
        },
        dailyDay = profile.dailyDay,
        tutorialSeen = profile.tutorialSeen == true,
        garden = Garden.serialize(profile.garden),
    }
end

local function discoveryCount(profile: any): number
    local count = 0
    for id, value in pairs(profile.discovered) do
        if value == true and reactionIds[id] then count += 1 end
    end
    return count
end

local function questReward(profile: any, quest: string, current: number): number
    if profile.questClaimed[quest] or current < Config.QUEST_GOALS[quest] then return 0 end
    profile.questClaimed[quest] = true
    return Config.QUEST_REWARDS[quest]
end

function Progression.recordFeed(profile: any, reactionId: string): (number, {string})
    profile.feedCount += 1
    local bonus = 0
    local messages = {}
    if reactionIds[reactionId] and not profile.discovered[reactionId] then
        profile.discovered[reactionId] = true
        bonus += Config.DISCOVERY_REWARD
        table.insert(messages, "NEW DISCOVERY! +" .. Config.DISCOVERY_REWARD .. " coins")
    end
    local feedReward = questReward(profile, "feeds", profile.feedCount)
    if feedReward > 0 then
        bonus += feedReward
        table.insert(messages, "QUEST COMPLETE: FEED 5! +" .. feedReward)
    end
    local discoveryReward = questReward(profile, "discoveries", discoveryCount(profile))
    if discoveryReward > 0 then
        bonus += discoveryReward
        table.insert(messages, "QUEST COMPLETE: DISCOVER 4! +" .. discoveryReward)
    end
    return bonus, messages
end

function Progression.recordSurvival(profile: any): number
    profile.survivalCount += 1
    return questReward(profile, "survivals", profile.survivalCount)
end

function Progression.ensurePersonality(profile: any, petId: number, userId: number, freshSeed: number?): boolean
    if not Config.Pets[petId] or not profile.owned[petId] then return false end
    if profile.personalities[petId] then return false end
    local species = Config.Pets[petId].description or Config.Pets[petId].name
    local seed = freshSeed or Personality.seedFor(userId, petId)
    profile.personalities[petId] = Personality.generate(seed, species)
    return true
end

function Progression.catalog(profile: any)
    local owned = {}
    for i = 1, #Config.Pets do
        if profile.owned[i] then table.insert(owned, i) end
    end
    local currentDay = math.floor(os.time() / 86400)
    local petProfiles = {}
    for i = 1, #Config.Pets do
        local p = profile.personalities[i]
        if profile.owned[i] and p then
            petProfiles[tostring(i)] = {
                temperament = p.temperament,
                habit = p.habit,
                fear = p.fear,
                affection = p.affection,
                favoriteFood = if p.bond >= 25 then p.favoriteFood else "???",
                dislikedFood = if p.bond >= 25 then p.dislikedFood else "???",
                bondStage = Personality.bondStage(p),
                rescues = p.rescues,
                traits = table.clone(p.traits),
                happiness = p.happiness,
                energy = p.energy,
                hunger = p.hunger,
                bond = p.bond,
                mood = Personality.mood(p),
            }
        end
    end
    return {
        petProfiles = petProfiles,
        owned = owned,
        equipped = profile.petIndex,
        discovered = discoveryCount(profile),
        totalReactions = #Config.Reactions,
        feedCount = profile.feedCount,
        survivalCount = profile.survivalCount,
        questClaimed = {
            feeds = profile.questClaimed.feeds,
            survivals = profile.questClaimed.survivals,
            discoveries = profile.questClaimed.discoveries,
        },
        dailyReady = profile.dailyDay < currentDay,
        dailyReward = Config.DAILY_REWARD,
        tutorialSeen = profile.tutorialSeen == true,
    }
end

function Progression.buy(profile: any, rawId: any): (boolean, string)
    if type(rawId) ~= "number" or rawId ~= math.floor(rawId) then
        return false, "Invalid pet."
    end
    local pet = Config.Pets[rawId]
    if not pet then return false, "Unknown pet." end
    if profile.owned[rawId] then return false, "You already own " .. pet.name end
    if profile.coins < pet.price then return false, "Need " .. (pet.price - profile.coins) .. " more coins!" end
    profile.coins -= pet.price
    profile.owned[rawId] = true
    return true, "UNLOCKED " .. string.upper(pet.name) .. "!"
end

function Progression.equip(profile: any, rawId: any): (boolean, string)
    if type(rawId) ~= "number" or rawId ~= math.floor(rawId) or not Config.Pets[rawId] then
        return false, "Unknown pet."
    end
    if not profile.owned[rawId] then return false, "Unlock this pet first." end
    if profile.petIndex == rawId then return false, "Already equipped." end
    profile.petIndex = rawId
    return true, "EQUIPPED " .. string.upper(Config.Pets[rawId].name) .. "!"
end

function Progression.claimDaily(profile: any): (boolean, string)
    local today = math.floor(os.time() / 86400)
    if profile.dailyDay >= today then return false, "Daily treat already claimed. Come back tomorrow!" end
    profile.dailyDay = today
    return true, "DAILY TREAT! +" .. Config.DAILY_REWARD .. " COINS!"
end

return Progression
