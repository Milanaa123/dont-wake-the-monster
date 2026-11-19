--!strict
-- Pure server-owned farming state. All input is validated on the server.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local G = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local Garden = {}

local function clampCount(value: any): number
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then return 0 end
    return math.clamp(math.floor(value), 0, G.MAX_STACK)
end

local function plotNumber(value: any): number?
    if type(value) ~= "number" or value ~= math.floor(value) or value < 1 or value > G.PLOT_COUNT then return nil end
    return value
end

local function validSeed(key: any): boolean
    return type(key) == "string" and G.Crops[key] ~= nil
end

function Garden.new()
    local plots = {}
    for i = 1, G.PLOT_COUNT do plots[i] = false end
    local seeds = {}
    for key, count in pairs(G.DEFAULT_SEEDS) do seeds[key] = count end
    return {plots = plots, seeds = seeds, crops = {}, crafted = {}, fertilizer = {Compost = 1}}
end

function Garden.load(raw: any)
    local g = Garden.new()
    if type(raw) ~= "table" then return g end
    -- The first save overrides starting seeds only when previous seed data exists.
    for _, field in ipairs({"seeds", "crops", "crafted", "fertilizer"}) do
        if type(raw[field]) == "table" then
            if field == "seeds" then g.seeds = {} end
            for key, value in pairs(raw[field]) do
                local allowed = false
                if field == "seeds" or field == "crops" then
                    allowed = validSeed(key)
                elseif field == "fertilizer" then
                    allowed = G.Fertilizers[key] ~= nil
                else
                    allowed = G.Recipes[key] ~= nil and G.Recipes[key].type ~= "fertilizer"
                end
                if allowed then g[field][key] = clampCount(value) end
            end
        end
    end
    if type(raw.plots) == "table" then
        for i = 1, G.PLOT_COUNT do
            local p = raw.plots[i]
            if type(p) == "table" and validSeed(p.seed) then
                local plantTime = if type(p.plantedAt) == "number" then math.floor(p.plantedAt) else 0
                local readyTime = if type(p.readyAt) == "number" then math.floor(p.readyAt) else 0
                local now = os.time()
                if plantTime >= 0 and plantTime <= now + 60 and readyTime >= plantTime and readyTime <= now + 86400 * 4 then
                    g.plots[i] = {seed = p.seed, plantedAt = plantTime, readyAt = readyTime, fertilized = p.fertilized == true}
                end
            end
        end
    end
    return g
end

function Garden.serialize(g: any)
    local plots = {}
    for i = 1, G.PLOT_COUNT do
        local p = g.plots[i]
        plots[i] = if p then {seed = p.seed, plantedAt = p.plantedAt, readyAt = p.readyAt, fertilized = p.fertilized} else false
    end
    return {plots = plots, seeds = table.clone(g.seeds), crops = table.clone(g.crops), crafted = table.clone(g.crafted), fertilizer = table.clone(g.fertilizer)}
end

function Garden.snapshot(g: any)
    local result = Garden.serialize(g)
    result.serverTime = os.time()
    return result
end

function Garden.buySeed(g: any, coins: number, key: any): (boolean, string, number)
    if not validSeed(key) then return false, "Unknown seed", 0 end
    local crop = G.Crops[key]
    if crop.kind == "premium" then
        return false, "Premium seed not for sale yet. No payment taken.", 0
    end
    if coins < crop.coins then return false, "Need " .. (crop.coins - coins) .. " more coins!", 0 end
    if (g.seeds[key] or 0) > G.MAX_STACK - G.SEED_PACK_SIZE then return false, "Seed storage is full", 0 end
    g.seeds[key] = (g.seeds[key] or 0) + G.SEED_PACK_SIZE
    return true, "+3 " .. crop.name .. " seeds", crop.coins
end

function Garden.plant(g: any, index: any, key: any): (boolean, string)
    local n = plotNumber(index)
    if not n or not validSeed(key) then return false, "Invalid plot or seed" end
    if g.plots[n] then return false, "Harvest this plot first!" end
    if (g.seeds[key] or 0) < 1 then return false, "No seeds. Buy or craft more!" end
    local now = os.time()
    g.seeds[key] -= 1
    g.plots[n] = {seed = key, plantedAt = now, readyAt = now + G.Crops[key].seconds, fertilized = false}
    return true, G.Crops[key].name .. " is growing!"
end

function Garden.harvest(g: any, index: any): (boolean, string)
    local n = plotNumber(index)
    if not n then return false, "Invalid garden plot" end
    local p = g.plots[n]
    if not p then return false, "This plot is empty" end
    if os.time() < p.readyAt then
        return false, "Not ripe! " .. math.max(1, p.readyAt - os.time()) .. " seconds left"
    end
    local amount = G.Crops[p.seed].yield
    if (g.crops[p.seed] or 0) > G.MAX_STACK - amount then
        return false, "Crop storage is full"
    end
    g.crops[p.seed] = (g.crops[p.seed] or 0) + amount
    g.plots[n] = false
    return true, "+" .. amount .. " " .. G.Crops[p.seed].name
end

function Garden.fertilize(g: any, index: any, key: any): (boolean, string)
    local n = plotNumber(index)
    if not n or type(key) ~= "string" or not G.Fertilizers[key] then return false, "Invalid fertilizer or plot" end
    local p = g.plots[n]
    if not p then return false, "Plant something first!" end
    if p.fertilized then return false, "Already fertilized!" end
    if (g.fertilizer[key] or 0) < 1 then return false, "Craft this fertilizer first!" end
    local remaining = math.max(0, p.readyAt - os.time())
    if remaining < 1 then return false, "Already ripe; harvest it!" end
    g.fertilizer[key] -= 1
    p.readyAt = os.time() + math.max(1, math.floor(remaining * G.Fertilizers[key].modifier))
    p.fertilized = true
    return true, G.Fertilizers[key].name .. " sped up growth!"
end

function Garden.craft(g: any, id: any): (boolean, string)
    if type(id) ~= "string" or not G.Recipes[id] then return false, "Unknown recipe" end
    local recipe = G.Recipes[id]
    local output = if recipe.type == "fertilizer" then g.fertilizer else g.crafted
    if (output[id] or 0) > G.MAX_STACK - recipe.produces then return false, "Crafting storage full" end
    for ingredient, amount in pairs(recipe.ingredients) do
        if (g.crops[ingredient] or 0) < amount then
            return false, "Need " .. amount .. " " .. G.Crops[ingredient].name
        end
    end
    for ingredient, amount in pairs(recipe.ingredients) do g.crops[ingredient] -= amount end
    output[id] = (output[id] or 0) + recipe.produces
    return true, "CRAFTED " .. recipe.produces .. "x " .. recipe.name
end

function Garden.consume(g: any, id: any, wantedType: string): (boolean, string)
    if type(id) ~= "string" or not G.Recipes[id] or G.Recipes[id].type ~= wantedType then return false, "Invalid crafted item" end
    if (g.crafted[id] or 0) < 1 then return false, "Craft this first!" end
    g.crafted[id] -= 1
    return true, G.Recipes[id].name
end

return Garden
