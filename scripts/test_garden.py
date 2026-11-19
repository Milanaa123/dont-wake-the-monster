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
catalog = (root / "src/server/RecipeCatalog.luau").read_text(encoding="utf-8")
rules = (root / "src/server/Garden.luau").read_text(encoding="utf-8")
assert config.endswith("return G\n")
assert catalog.endswith("return Catalog\n")
assert rules.endswith("return Garden\n")
config = config.removesuffix("return G\n")
catalog = catalog.removesuffix("return Catalog\n")
rules = rules.replace('local ReplicatedStorage = game:GetService("ReplicatedStorage")\n', "", 1)
rules = rules.replace('local G = require(ReplicatedStorage:WaitForChild("GardenConfig"))\n', "", 1)
rules = rules.replace('local Catalog = require(script.Parent:WaitForChild("RecipeCatalog"))\n', "", 1)
rules = rules.removesuffix("return Garden\n")

suite = r"""
local g = Garden.new()
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
"""
source = (
    "Color3 = {fromRGB = function(r,g,b) return {r,g,b} end}\n"
    + config + "\n" + catalog + "\n" + rules + "\n" + suite
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
