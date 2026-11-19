--!strict
-- A free-coin traveling seed merchant. Deterministic server rotation:
-- same four offers for everyone, no paid random rolls or hidden loot boxes.
local G = require(script.Parent:WaitForChild("GardenConfig"))
local Shop = {}
Shop.IntervalSeconds = 12 * 60
Shop.OfferCount = 4
Shop.PackSize = 2

function Shop.rotation(now: number): number
    return math.max(0, math.floor(now / Shop.IntervalSeconds))
end

function Shop.offers(now: number)
    local rotation = Shop.rotation(now)
    local ordinary = {}
    for _, key in ipairs(G.Order) do
        if G.Crops[key].kind == "ordinary" then table.insert(ordinary, key) end
    end
    local offers = {}
    -- Coprime step traverses all 28 ordinary crops without duplicate slots.
    for slot = 1, Shop.OfferCount do
        local index = ((rotation * 5 + (slot - 1) * 9) % #ordinary) + 1
        local key = ordinary[index]
        local crop = G.Crops[key]
        local price = math.max(5, math.floor(crop.coins * 0.62))
        table.insert(offers, {slot = slot, seed = key, price = price, count = Shop.PackSize, name = crop.name, icon = crop.icon})
    end
    return offers
end

function Shop.snapshot(now: number, bought: any)
    local rotation = Shop.rotation(now)
    local claimed = {}
    if type(bought) == "table" and bought.rotation == rotation and type(bought.slots) == "table" then
        for i = 1, Shop.OfferCount do claimed[i] = bought.slots[i] == true end
    end
    return {rotation = rotation, nextRestock = (rotation + 1) * Shop.IntervalSeconds, offers = Shop.offers(now), claimed = claimed}
end

function Shop.buy(g: any, coins: number, slot: any, now: number): (boolean, string, number)
    if type(slot) ~= "number" or slot ~= math.floor(slot) or slot < 1 or slot > Shop.OfferCount then
        return false, "Invalid merchant offer", 0
    end
    local current = Shop.snapshot(now, g.merchant)
    local offer = current.offers[slot]
    if current.claimed[slot] then return false, "Already bought this offer. Wait for the next restock!", 0 end
    if coins < offer.price then return false, "Not enough coins for the traveling merchant", 0 end
    if (g.seeds[offer.seed] or 0) > G.MAX_STACK - Shop.PackSize then return false, "Seed bag is full", 0 end
    if not g.merchant or g.merchant.rotation ~= current.rotation then
        g.merchant = {rotation = current.rotation, slots = {}}
    end
    g.merchant.slots[slot] = true
    g.seeds[offer.seed] = (g.seeds[offer.seed] or 0) + Shop.PackSize
    return true, "TRAVELING MERCHANT: +" .. Shop.PackSize .. " " .. offer.name .. " seeds!", offer.price
end

return Shop
