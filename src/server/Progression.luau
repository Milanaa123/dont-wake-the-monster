--!strict
-- Pure progression rules. Never trust a client-supplied coin total or ownership flag.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

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
    }
end

function Progression.load(profile: any, data: any)
    if type(data) ~= "table" then return end
    profile.coins = saneInt(data.coins, MAX_COINS)
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
    return {
        coins = saneInt(profile.coins, MAX_COINS),
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

function Progression.catalog(profile: any)
    local owned = {}
    for i = 1, #Config.Pets do
        if profile.owned[i] then table.insert(owned, i) end
    end
    local currentDay = math.floor(os.time() / 86400)
    return {
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
