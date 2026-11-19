--!strict
-- Pure progression rules for actual, spatially verified seed pickups.
-- The World script provides physical cache positions and the server verifies distance.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local X = require(ReplicatedStorage:WaitForChild("ExpeditionConfig"))
local G = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local Hunt = {}
local byId = {}
for _, zoneId in ipairs(X.ZoneOrder) do
    local zone = X.Zones[zoneId]
    for _, node in ipairs(zone.nodes) do
        assert(not byId[node.id], "Duplicate seed cache id")
        byId[node.id] = {node = node, zone = zoneId}
    end
end

function Hunt.node(id: any): any?
    return if type(id) == "string" then byId[id] else nil
end

function Hunt.new()
    return {visited = {}, discovered = {}, mutations = {}, totalFinds = 0, questDay = -1, questFinds = 0, questClaimed = false}
end

function Hunt.load(raw: any)
    local s = Hunt.new()
    if type(raw) ~= "table" then return s end
    if type(raw.visited) == "table" then
        for id, time in pairs(raw.visited) do
            if Hunt.node(id) and type(time) == "number" and time == math.floor(time)
                and time >= 0 and time <= os.time() + 60 then
                s.visited[id] = time
            end
        end
    end
    if type(raw.discovered) == "table" then
        for key, flag in pairs(raw.discovered) do
            if G.Crops[key] and G.Crops[key].kind == "ordinary" and flag == true then s.discovered[key] = true end
        end
    end
    if type(raw.mutations) == "table" then
        for _, name in ipairs({"Golden", "Dewy", "Moonlit", "Giggly"}) do
            if raw.mutations[name] == true then s.mutations[name] = true end
        end
    end
    if type(raw.totalFinds) == "number" and raw.totalFinds == math.floor(raw.totalFinds) then
        s.totalFinds = math.clamp(raw.totalFinds, 0, 1000000)
    end
    if type(raw.questDay) == "number" and raw.questDay == math.floor(raw.questDay) then
        s.questDay = math.clamp(raw.questDay, -1, 1000000)
    end
    if type(raw.questFinds) == "number" and raw.questFinds == math.floor(raw.questFinds) then
        s.questFinds = math.clamp(raw.questFinds, 0, X.PersonalDailyQuest)
    end
    s.questClaimed = raw.questClaimed == true
    return s
end

function Hunt.snapshot(h: any)
    return {
        visited = table.clone(h.visited),
        discovered = table.clone(h.discovered),
        mutations = table.clone(h.mutations),
        totalFinds = h.totalFinds,
        questDay = h.questDay,
        questFinds = h.questFinds,
        questClaimed = h.questClaimed,
    }
end

function Hunt.collect(h: any, seeds: any, nodeId: any, roll: number, assist: number, now: number): (boolean, string, string?, string?, boolean)
    local found = Hunt.node(nodeId)
    if not found then return false, "Unknown seed cache", nil, nil, false end
    if type(roll) ~= "number" or roll ~= roll or roll < 0 or roll > 1 then return false, "Invalid seed roll", nil, nil, false end
    if type(assist) ~= "number" or assist ~= assist then return false, "Invalid pet boost", nil, nil, false end
    local last = h.visited[nodeId] or -1000000
    if now < last + X.NodeCooldown then return false, "Cache regrowing! Come back soon.", nil, nil, false end
    -- Curious companions can improve odds, but can never mint paid seeds.
    local adjusted = math.clamp(roll + math.clamp(assist, 0, 0.08), 0, 0.9999999)
    local rarity = if adjusted < 0.65 then "common" elseif adjusted < 0.93 then "uncommon" else "rare"
    local index = if rarity == "common" then 1 elseif rarity == "uncommon" then 2 else 3
    local seed = if index == 3 and found.node.loot[4] and adjusted >= 0.965 then found.node.loot[4] else found.node.loot[index]
    if not G.Crops[seed] or G.Crops[seed].kind ~= "ordinary" then return false, "Invalid loot table", nil, nil, false end
    local number = if rarity == "common" then 2 else 1
    if (seeds[seed] or 0) > X.SeedCap - number then return false, "Seed bag full for this plant", nil, nil, false end
    seeds[seed] = (seeds[seed] or 0) + number
    h.visited[nodeId] = now
    h.totalFinds += 1
    local discovered = h.discovered[seed] ~= true
    h.discovered[seed] = true
    local day = math.floor(now / 86400)
    if h.questDay ~= day then
        h.questDay = day
        h.questFinds = 0
        h.questClaimed = false
    end
    h.questFinds = math.min(X.PersonalDailyQuest, h.questFinds + 1)
    return true, "+" .. number .. " " .. G.Crops[seed].name .. " seeds! (" .. rarity .. ")", seed, rarity, discovered
end

function Hunt.claimQuest(h: any, now: number): boolean
    if h.questDay ~= math.floor(now / 86400) then return false end
    if h.questFinds < X.PersonalDailyQuest or h.questClaimed then return false end
    h.questClaimed = true
    return true
end

function Hunt.mutatePlot(p: any, weather: string, roll: number, now: number): boolean
    local w = X.Weather[weather]
    if not w or not p or type(p) ~= "table" then return false end
    if now >= p.readyAt then return false end
    local changed = false
    if not p.weatherBoosted then
        p.readyAt = now + math.max(1, math.floor((p.readyAt - now) * w.speed))
        p.weatherBoosted = true
        changed = true
    end
    if not p.mutation and roll < w.chance then
        p.mutation = w.mutation
        changed = true
    end
    return changed
end

return Hunt
