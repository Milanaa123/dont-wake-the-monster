--!strict
-- Server-only, deterministic gardening rules.
-- Recipe ingredients are defined in ServerScriptService/RecipeCatalog and
-- only recipes actually discovered by this player are sent to the client.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local G = require(ReplicatedStorage:WaitForChild("GardenConfig"))
local Catalog = require(script.Parent:WaitForChild("RecipeCatalog"))
local Garden = {}

local function clampCount(value: any): number
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then return 0 end
    return math.clamp(math.floor(value), 0, G.MAX_STACK)
end

local function plotNumber(value: any): number?
    if type(value) ~= "number" or value ~= math.floor(value) or value < 1 or value > G.PLOT_COUNT then return nil end
    return value
end

local function validSeed(value: any): boolean
    return type(value) == "string" and G.Crops[value] ~= nil
end

local function recipeOutput(g: any, id: string)
    local recipe = Catalog.Recipes[id]
    if recipe.type == "fertilizer" then return g.fertilizer end
    return g.crafted
end

local function matchesRecipe(ingredients: {[string]: number}, counts: {[string]: number}): boolean
    for key, count in pairs(ingredients) do
        if counts[key] ~= count then return false end
    end
    for key, count in pairs(counts) do
        if ingredients[key] ~= count then return false end
    end
    return true
end

local function availableCrops(g: any, counts: {[string]: number}): boolean
    for key, count in pairs(counts) do
        if not validSeed(key) or count < 1 or (g.crops[key] or 0) < count then return false end
    end
    return true
end

local function subtract(g: any, counts: {[string]: number})
    for key, count in pairs(counts) do g.crops[key] -= count end
end

local function addProduct(g: any, id: string): (boolean, string)
    local recipe = Catalog.Recipes[id]
    local target = recipeOutput(g, id)
    if (target[id] or 0) > G.MAX_STACK - recipe.produces then
        return false, "Your crafted storage is full"
    end
    target[id] = (target[id] or 0) + recipe.produces
    return true, "CRAFTED " .. recipe.produces .. "× " .. recipe.name
end

function Garden.new()
    local plots = {}
    for i = 1, G.PLOT_COUNT do plots[i] = false end
    local seeds = {}
    for key, count in pairs(G.DEFAULT_SEEDS) do seeds[key] = count end
    return {
        plots = plots,
        seeds = seeds,
        crops = {},
        crafted = {},
        fertilizer = {Compost = 1},
        known = {},
        experiments = 0,
        flops = 0,
    }
end

function Garden.load(raw: any)
    local g = Garden.new()
    if type(raw) ~= "table" then return g end
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
                    allowed = Catalog.Recipes[key] ~= nil and Catalog.Recipes[key].type ~= "fertilizer"
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
    -- Existing v0.3 players had a visible recipe list. After upgrading, the
    -- book intentionally starts empty unless discoveries were saved in v0.4.
    if type(raw.knownRecipes) == "table" then
        for _, key in ipairs(raw.knownRecipes) do
            if type(key) == "string" and Catalog.Recipes[key] and key ~= "MysterySlop" then
                g.known[key] = true
            end
        end
    end
    g.experiments = clampCount(raw.experiments)
    g.flops = clampCount(raw.flops)
    return g
end

function Garden.serialize(g: any)
    local plots = {}
    for i = 1, G.PLOT_COUNT do
        local p = g.plots[i]
        plots[i] = if p then {seed = p.seed, plantedAt = p.plantedAt, readyAt = p.readyAt, fertilized = p.fertilized} else false
    end
    local knownRecipes = {}
    for _, id in ipairs(Catalog.Order) do
        if g.known[id] then table.insert(knownRecipes, id) end
    end
    return {
        plots = plots,
        seeds = table.clone(g.seeds),
        crops = table.clone(g.crops),
        crafted = table.clone(g.crafted),
        fertilizer = table.clone(g.fertilizer),
        knownRecipes = knownRecipes,
        experiments = math.min(G.MAX_STACK, g.experiments),
        flops = math.min(G.MAX_STACK, g.flops),
    }
end

function Garden.snapshot(g: any)
    local result = Garden.serialize(g)
    -- Only transmit recipe ingredients that the player has ACTUALLY discovered.
    -- Other ingredient combinations never leave the server.
    local book = {}
    for _, id in ipairs(Catalog.Order) do
        if g.known[id] then
            local recipe = Catalog.Recipes[id]
            table.insert(book, {
                id = id,
                name = recipe.name,
                icon = recipe.icon,
                produces = recipe.produces,
                ingredients = table.clone(recipe.ingredients),
                type = recipe.type,
            })
        end
    end
    local products = {}
    for id, count in pairs(g.crafted) do
        if count > 0 and Catalog.Recipes[id] then
            local recipe = Catalog.Recipes[id]
            table.insert(products, {id = id, name = recipe.name, icon = recipe.icon, type = recipe.type, amount = count})
        end
    end
    table.sort(products, function(a, b) return a.name < b.name end)
    result.book = book
    result.products = products
    result.knownRecipes = nil -- do not expose internal saved format to the UI
    result.totalRecipes = #Catalog.Order
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
    if (g.crops[p.seed] or 0) > G.MAX_STACK - amount then return false, "Crop storage is full" end
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

-- The client submits 2-3 crop IDs ONLY; the server resolves an exact recipe.
-- Failures cost the ingredients, but ALWAYS create a funny Oops Soup, so
-- experimentation provides something useful instead of an empty punishment.
function Garden.experiment(g: any, slots: any): (boolean, string, string?, boolean)
    if type(slots) ~= "table" then return false, "Select 2 or 3 crops to mix", nil, false end
    local count = #slots
    if count < 2 or count > 3 then return false, "Mix 2 or 3 ingredients", nil, false end
    for key in pairs(slots) do
        if type(key) ~= "number" or key < 1 or key > count or key ~= math.floor(key) then
            return false, "Invalid mixing ingredients", nil, false
        end
    end
    local counts: {[string]: number} = {}
    for i = 1, count do
        local key = slots[i]
        if not validSeed(key) then return false, "Unknown ingredient", nil, false end
        counts[key] = (counts[key] or 0) + 1
    end
    if not availableCrops(g, counts) then return false, "Harvest the selected ingredients first!", nil, false end
    local matched = "MysterySlop"
    for _, id in ipairs(Catalog.Order) do
        if matchesRecipe(Catalog.Recipes[id].ingredients, counts) then
            matched = id
            break
        end
    end
    local recipe = Catalog.Recipes[matched]
    local output = recipeOutput(g, matched)
    if (output[matched] or 0) > G.MAX_STACK - recipe.produces then
        return false, "Crafted inventory is full!", nil, false
    end
    subtract(g, counts)
    g.experiments = math.min(G.MAX_STACK, g.experiments + 1)
    output[matched] = (output[matched] or 0) + recipe.produces
    if matched == "MysterySlop" then
        g.flops = math.min(G.MAX_STACK, g.flops + 1)
        return true, "OH NO! Your mixture turned into OOPS SOUP! Feed it to your pet!", matched, false
    end
    if not g.known[matched] then
        g.known[matched] = true
        return true, "NEW RECIPE DISCOVERED: " .. recipe.name .. "! Added to your book!", matched, true
    end
    return true, "You made " .. recipe.produces .. "× " .. recipe.name .. " again!", matched, false
end

function Garden.craft(g: any, id: any): (boolean, string)
    if type(id) ~= "string" or not Catalog.Recipes[id] or not g.known[id] then
        return false, "Discover the recipe through mixing first!"
    end
    local recipe = Catalog.Recipes[id]
    local output = recipeOutput(g, id)
    if (output[id] or 0) > G.MAX_STACK - recipe.produces then return false, "Crafting storage full" end
    if not availableCrops(g, recipe.ingredients) then return false, "Not enough harvested ingredients!" end
    subtract(g, recipe.ingredients)
    return addProduct(g, id)
end

function Garden.consume(g: any, id: any, wantedType: string): (boolean, string)
    if type(id) ~= "string" or not Catalog.Recipes[id] or Catalog.Recipes[id].type ~= wantedType then
        return false, "Invalid crafted item"
    end
    if (g.crafted[id] or 0) < 1 then return false, "Craft this first!" end
    g.crafted[id] -= 1
    return true, Catalog.Recipes[id].name
end

return Garden
