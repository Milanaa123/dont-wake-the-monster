#!/usr/bin/env python3
"""Execute actual Luau gardening + server-secret discovery logic in the Luau CLI.

These are deterministic gameplay rule tests only, NOT full Roblox Studio tests.
Usage: python3 scripts/test_garden.py /path/to/luau
"""
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
exe = sys.argv[1] if len(sys.argv) > 1 else "luau"
config = (root / "src/shared/GardenConfig.luau").read_text(encoding="utf-8")
exploration_config = (root / "src/shared/ExpeditionConfig.luau").read_text(encoding="utf-8")
hunt = (root / "src/server/SeedHunt.luau").read_text(encoding="utf-8")
catalog = (root / "src/server/RecipeCatalog.luau").read_text(encoding="utf-8")
merchant = (root / "src/shared/SeedMerchant.luau").read_text(encoding="utf-8")
rules = (root / "src/server/Garden.luau").read_text(encoding="utf-8")
assert config.endswith("return G\n")
assert exploration_config.endswith("return X\n")
assert hunt.endswith("return Hunt\n")
assert catalog.endswith("return Catalog\n")
assert rules.endswith("return Garden\n")
assert merchant.endswith("return Shop\n")
merchant = merchant.replace('local G = require(script.Parent:WaitForChild("GardenConfig"))\n', "", 1)
merchant = merchant.removesuffix("return Shop\n")
config = config.removesuffix("return G\n")
exploration_config = exploration_config.removesuffix("return X\n")
hunt = hunt.replace('local ReplicatedStorage = game:GetService("ReplicatedStorage")\n', "", 1)
hunt = hunt.replace('local X = require(ReplicatedStorage:WaitForChild("ExpeditionConfig"))\n', "", 1)
hunt = hunt.replace('local G = require(ReplicatedStorage:WaitForChild("GardenConfig"))\n', "", 1)
hunt = hunt.removesuffix("return Hunt\n")
catalog = catalog.removesuffix("return Catalog\n")
rules = rules.replace('local ReplicatedStorage = game:GetService("ReplicatedStorage")\n', "", 1)
rules = rules.replace('local G = require(ReplicatedStorage:WaitForChild("GardenConfig"))\n', "", 1)
rules = rules.replace('local SeedMerchant = require(ReplicatedStorage:WaitForChild("SeedMerchant"))\n', "local SeedMerchant = Shop\n", 1)
rules = rules.replace('local Catalog = require(script.Parent:WaitForChild("RecipeCatalog"))\n', "", 1)
rules = rules.replace('local Hunt = require(script.Parent:WaitForChild("SeedHunt"))\n', "", 1)
rules = rules.replace('local X = require(ReplicatedStorage:WaitForChild("ExpeditionConfig"))\n', "", 1)
rules = rules.removesuffix("return Garden\n")

suite = r"""
local g = Garden.new()
local guest={}
local open=false
local host={GetAttribute=function(_,key) return key=="GardenOpen" and open end}
local slots={[guest]=1,[host]=2}
local visitors={GetPlayerByUserId=function(_,id) return if id==42 then host else nil end}
assert(Garden.visitOwner(guest,nil,visitors,slots)==guest)
assert(not Garden.visitOwner(guest,42,visitors,slots))
open=true
assert(Garden.visitOwner(guest,42,visitors,slots)==host)
assert(not Garden.visitOwner(guest,43,visitors,slots) and not Garden.visitOwner(guest,"42",visitors,slots))
slots[host]=nil
assert(not Garden.visitOwner(guest,42,visitors,slots))
assert(g.style=="Meadow" and Garden.load({style="unknown"}).style=="Meadow")
assert(not Garden.setStyle(g,{}))
assert(Garden.setStyle(g,"Cottage") and not Garden.setStyle(g,"Cottage"))
local styled=Garden.load(Garden.serialize(g))
assert(styled.style=="Cottage" and Garden.snapshot(styled).style=="Cottage")
assert(styled.seeds.Berry==g.seeds.Berry and not styled.plots[1])
assert(g.seeds.Berry == 5 and g.seeds.Carrot == 3, "starter seeds")
assert(G.PLOT_COUNT == 9, "nine beds")
assert(#G.Order == 30 and #Catalog.Order == 26, "expanded catalogs")
assert(G.Recipes == nil and G.RecipeOrder == nil, "recipe secrets leaked to client config")
assert(#Garden.snapshot(g).book == 0, "recipe book must start EMPTY")
local ordinary = 0
for _, key in ipairs(G.Order) do
    local crop = G.Crops[key]
    assert(crop.seconds > 0 and crop.yield >= 2, "valid growth metadata")
    if crop.kind == "ordinary" then ordinary += 1 end
end
assert(ordinary == 28, "28 earnable plants")
for _, item in pairs(G.PremiumProducts) do
    assert(item.productId == 0, "real Robux product accidentally enabled")
end

-- Every secret combination must be 2 or 3 units, and unique.
local signatures = {}
for _, id in ipairs(Catalog.Order) do
    local recipe = Catalog.Recipes[id]
    local total = 0
    local parts = {}
    for key, count in pairs(recipe.ingredients) do
        assert(G.Crops[key] ~= nil, "unknown crop in recipe")
        total += count
        table.insert(parts, key .. ":" .. count)
    end
    table.sort(parts)
    assert(total == 2 or total == 3, "recipe can't be made with 2-3 ingredient slots")
    local signature = table.concat(parts, "|")
    assert(signatures[signature] == nil, "duplicate secret recipe combination")
    signatures[signature] = id
end

local ok, message = Garden.plant(g, 1, "Berry")
assert(ok and g.seeds.Berry == 4, "plant one seed")
ok, message = Garden.plant(g, 1, "Berry")
assert(not ok, "can't replant occupied plot")
ok, message = Garden.harvest(g, 1)
assert(not ok, "no premature harvest")
ok, message = Garden.fertilize(g, 1, "Compost")
assert(ok and g.fertilizer.Compost == 0 and g.plots[1].fertilized, "fertilizer applies once")
ok, message = Garden.fertilize(g, 1, "Compost")
assert(not ok, "can't fertilize twice")
g.plots[1].readyAt = os.time() - 1
ok, message = Garden.harvest(g, 1)
assert(ok and g.crops.Berry == 3 and g.plots[1] == false, "harvest yield")

ok, message = Garden.buySeed(g, 999, "ThunderPlum")
assert(ok and g.seeds.ThunderPlum == 3, "new seed packets work")
ok, message = Garden.buySeed(g, 999, "Starbloom")
assert(not ok, "premium seeds are disabled")
ok, message = Garden.plant(g, 2, "AuroraMelon")
assert(not ok, "can't plant unowned premium seed")

-- Hidden recipe cannot be crafted by sending ID alone.
g.crops.Tomato = 4
ok, message = Garden.craft(g, "BerryMash")
assert(not ok, "server must reject undiscovered recipe")

-- Exact ingredient combination reveals the recipe and creates 2 feeds.
local created, resultId, newDiscovery
ok, message, resultId, newDiscovery = Garden.experiment(g, {"Berry", "Tomato", "Berry"})
assert(ok and resultId == "BerryMash" and newDiscovery, "mixer should discover BerryMash")
assert(g.crafted.BerryMash == 2 and g.crops.Berry == 1, "craft cost and yield")
local snapshot = Garden.snapshot(g)
assert(#snapshot.book == 1 and snapshot.book[1].id == "BerryMash", "book gets ONLY discovered recipe")
assert(snapshot.book[1].ingredients.Berry == 2 and snapshot.book[1].ingredients.Tomato == 1)
assert(snapshot.totalRecipes == 26 and snapshot.knownRecipes == nil, "safe public snapshot")
assert(#snapshot.products == 1, "crafted food visible in inventory")

-- Failed experiments consume the inputs but create a silly edible product.
ok, message, resultId, newDiscovery = Garden.experiment(g, {"Berry", "Tomato"})
assert(ok and resultId == "MysterySlop" and not newDiscovery, "failed experiment creates Oops Soup")
assert(g.crafted.MysterySlop == 1 and #Garden.snapshot(g).book == 1, "failure doesn't unlock secret")
ok, message = Garden.consume(g, "MysterySlop", "feed")
assert(ok and g.crafted.MysterySlop == 0, "Oops Soup is edible")

-- Known formula can be used with a single button once enough crops are owned.
g.crops.Berry = 3
ok, message = Garden.craft(g, "BerryMash")
assert(ok and g.crafted.BerryMash == 4, "known recipe can be repeated")
ok, message = Garden.consume(g, "BerryMash", "lure")
assert(not ok and g.crafted.BerryMash == 4, "type validation")
ok, message = Garden.consume(g, "BerryMash", "feed")
assert(ok and g.crafted.BerryMash == 3, "consume prepared food")

-- New bait must also be DISCOVERED, never start unlocked.
g.crops.Corn = 2
g.crops.Sunflower = 1
ok, message = Garden.craft(g, "SillyLure")
assert(not ok, "hidden bait cannot be made by ID")
ok, message, resultId, newDiscovery = Garden.experiment(g, {"Corn", "Sunflower", "Corn"})
assert(ok and resultId == "SillyLure" and newDiscovery, "discover creature bait")
ok, message = Garden.consume(g, "SillyLure", "lure")
assert(ok, "bait can be used")
assert(#Garden.snapshot(g).book == 2, "book shows only discovered recipes")

-- Save/load discovered pages, harvested crops and created products.
local serialized = Garden.serialize(g)
local restored = Garden.load(serialized)
assert(restored.known.BerryMash and restored.known.SillyLure, "recipe book persists across sessions")
assert(#Garden.snapshot(restored).book == 2, "known book restored")
assert(restored.crafted.BerryMash == 3, "prepared food count persists")
assert(restored.seeds.ThunderPlum == 3 and restored.plots[1] == false)
local malicious = Garden.load({
    seeds = {Berry = math.huge, Fake = 1000},
    crops = {Berry = 0/0},
    knownRecipes = {"Fake", "MysterySlop", "MoonCandy"},
    crafted = {ImaginarySnack = 99},
})
assert(malicious.seeds.Berry == 0 and malicious.seeds.Fake == nil, "sanitize seed stock")
assert(malicious.crops.Berry == 0 and malicious.crafted.ImaginarySnack == nil, "sanitize inventory")
assert(malicious.known.MoonCandy and not malicious.known.MysterySlop, "valid stored discoveries only")

local bad
bad, message = Garden.experiment(g, {"Fake", "Berry"})
assert(not bad, "unknown ingredients rejected")
bad, message = Garden.experiment(g, {"Berry", "Berry", "Berry", "Berry"})
assert(not bad, "4 ingredient exploit rejected")
bad, message = Garden.experiment(g, {"ThunderPlum", "ThunderPlum"})
assert(not bad, "unowned harvested ingredient rejected")
print("PASS: 30 crops, 26 secret recipes, empty book, discovery, failed mixes, repeat crafting, 30-plant support, saves and exploits")
-- Real SeedHunt rules, including free rare seeds, cooldowns, albums and weather.
local searchable = {}
local count = 0
for _, zoneId in ipairs(X.ZoneOrder) do
    for _, node in ipairs(X.Zones[zoneId].nodes) do
        assert(not searchable[node.id], "seed cache IDs unique")
        searchable[node.id] = true
        count += 1
        for _, loot in ipairs(node.loot) do
            assert(G.Crops[loot] and G.Crops[loot].kind == "ordinary", "wild caches never contain paid seeds")
        end
    end
end
assert(count == 9 and #X.ZoneOrder == 3, "nine caches in three locations")
local h = Hunt.new()
local now = os.time()
local received, message, seedId, tier, first = Hunt.collect(h, g.seeds, "meadow_1", 0.99, 0, now)
assert(received and tier == "rare" and seedId == "HoneyPear" and first, "rare free seed search")
received, message = Hunt.collect(h, g.seeds, "meadow_1", 0.99, 0, now)
assert(not received, "personal cooldown blocks repeated searches")
received, message = Hunt.collect(h, g.seeds, "meadow_1", 0.1, 0, now + X.NodeCooldown)
assert(received, "cache restores after expected cooldown")
received, message, seedId, tier = Hunt.collect(h, g.seeds, "ruins_1", 0.98, 0, now)
assert(received and seedId == "LavaMelon" and tier == "rare", "28th wild seed is obtainable")
assert(not Hunt.claimQuest(h, now), "five finds required to claim quest")
for _, id in ipairs({"marsh_1", "marsh_2"}) do
    received = Hunt.collect(h, g.seeds, id, 0.2, 0, now)
    assert(received, "valid zone can be searched")
end
received = Hunt.collect(h, g.seeds, "meadow_3", 0.2, 0, now)
assert(received and h.questFinds == 5, "daily explorer count reaches goal")
assert(Hunt.claimQuest(h, now) and not Hunt.claimQuest(h, now), "daily reward is one-time")
local restoredH = Hunt.load(Hunt.snapshot(h))
assert(restoredH.discovered.HoneyPear and restoredH.discovered.LavaMelon, "rare finds persist")
assert(restoredH.totalFinds == h.totalFinds, "forage totals persist")
local denied = Hunt.collect(h, g.seeds, "madeup-node", 0.8, 0, now)
assert(not denied, "fake node rejected")
local grow = Garden.new()
local planted = Garden.plant(grow, 1, "Berry")
assert(planted)
local affected = Garden.weather(grow, "MoonFog", function() return 0.1 end)
assert(affected == 1 and grow.plots[1].mutation == "Moonlit", "weather creates mutation")
affected = Garden.weather(grow, "MoonFog", function() return 1 end)
assert(affected == 0, "re-applying same weather does not duplicate a boost")
local boosted, tip = Garden.assist(grow, 1, 90)
assert(boosted and grow.plots[1].assistUsed, "curious pet speeds plant growth")
boosted = Garden.assist(grow, 1, 90)
assert(not boosted, "one assist per crop")
grow.plots[1].readyAt = os.time() - 1
local harvested = Garden.harvest(grow, 1)
assert(harvested and grow.crops.Berry == G.Crops.Berry.yield * X.MutationBonus, "fixed mutated harvest bonus")
assert(grow.hunt.mutations.Moonlit, "mutation recorded in album")
local restoredGarden = Garden.load(Garden.serialize(grow))
assert(restoredGarden.hunt.mutations.Moonlit, "mutation collection persists")
assert(restoredGarden.crops.Berry == grow.crops.Berry, "mutated crop stock persists")
assert(not Garden.harvest(restoredGarden, 1), "empty plot cannot pay a second time")
restoredGarden.seeds.Carrot = 1
assert(Garden.plant(restoredGarden, 1, "Carrot"), "a harvested and reloaded bed accepts a different crop")
assert(restoredGarden.plots[1].mutation == nil and not restoredGarden.plots[1].assistUsed, "a new crop starts clean")
assert(not Garden.harvest(restoredGarden, 1), "new crop has its own growth clock")
print("PASS: forest discovery, nine cache cooldowns, free rare seeds, 28-plant book, weather mutations and pet tending")

"""
source = (
    "Color3 = {fromRGB = function(r,g,b) return {r,g,b} end}\n"
    + config + "\n" + exploration_config + "\n" + catalog + "\n"
    + hunt + "\n" + merchant + "\n" + rules + "\n" + suite
)
with tempfile.TemporaryDirectory() as tmp:
    script = Path(tmp) / "garden_spec.luau"
    script.write_text(source, encoding="utf-8")
    p = subprocess.run([exe, str(script)], capture_output=True, text=True, timeout=45)
    if p.stdout:
        print(p.stdout, end="")
    if p.stderr:
        print(p.stderr, file=sys.stderr, end="")
    sys.exit(p.returncode)
