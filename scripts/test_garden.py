#!/usr/bin/env python3
"""Run actual Garden.lua logic via official Luau CLI with minimal Color3 stubs.

These tests verify deterministic garden rules; they do NOT run Roblox networking,
DataStore, physics or GUI. Usage: python3 scripts/test_garden.py /path/to/luau
"""
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
exe = sys.argv[1] if len(sys.argv) > 1 else "luau"
config = (root / "src/shared/GardenConfig.luau").read_text()
rules = (root / "src/server/Garden.luau").read_text()
config = config.replace("return G\n", "", 1)
rules = rules.replace('local ReplicatedStorage = game:GetService("ReplicatedStorage")\n', "", 1)
rules = rules.replace('local G = require(ReplicatedStorage:WaitForChild("GardenConfig"))\n', "", 1)
rules = rules.replace("return Garden\n", "", 1)
assert "return G" not in config, "test harness couldn't strip module return"
assert "return Garden" not in rules, "test harness couldn't strip module return"
suite = r"""
local g = Garden.new()
assert(g.seeds.Berry == 5 and g.seeds.Carrot == 3, "starter pack")
assert(#G.Order == 12 and #G.RecipeOrder == 8, "catalog completeness")
local ordinary = 0
for _, key in ipairs(G.Order) do
    local c = G.Crops[key]
    assert(c.seconds > 0 and c.yield >= 2)
    if c.kind ~= "premium" then ordinary += 1 end
end
assert(ordinary == 10)
for _, item in pairs(G.PremiumProducts) do
    assert(item.productId == 0, "real payment accidentally enabled")
end

local ok, message = Garden.plant(g, 1, "Berry")
assert(ok and g.seeds.Berry == 4, "planting reduces seed stock")
ok, message = Garden.plant(g, 1, "Berry")
assert(not ok, "one plant per plot")
ok, message = Garden.harvest(g, 1)
assert(not ok, "can't harvest unripe crop")
ok, message = Garden.fertilize(g, 1, "Compost")
assert(ok and g.fertilizer.Compost == 0 and g.plots[1].fertilized, "fertilize once")
ok, message = Garden.fertilize(g, 1, "Compost")
assert(not ok, "can't double fertilize")
g.plots[1].readyAt = os.time() - 1
ok, message = Garden.harvest(g, 1)
assert(ok and g.crops.Berry == G.Crops.Berry.yield, "harvest fixed amount")
assert(g.plots[1] == false)

ok, message, price = Garden.buySeed(g, 99, "Pepper")
assert(ok and price == G.Crops.Pepper.coins and g.seeds.Pepper == 3, "coin seed pack")
ok, message = Garden.buySeed(g, 0, "Starbloom")
assert(not ok, "premium seed cannot be bought with coins")
ok, message = Garden.plant(g, 2, "AuroraMelon")
assert(not ok, "unowned premium seed cannot be planted")

g.crops.Tomato = 4
ok, message = Garden.craft(g, "BerryMash")
assert(ok and g.crafted.BerryMash == 2, "craft deterministic pet food")
ok, message = Garden.consume(g, "BerryMash", "feed")
assert(ok and g.crafted.BerryMash == 1, "consume one food")
ok, message = Garden.consume(g, "BerryMash", "lure")
assert(not ok and g.crafted.BerryMash == 1, "wrong type cannot consume")
g.crops.Corn = 2
g.crops.Sunflower = 1
ok, message = Garden.craft(g, "SillyLure")
assert(ok and g.crafted.SillyLure == 1, "craft wild creature bait")
ok, message = Garden.consume(g, "SillyLure", "lure")
assert(ok, "use bait")

local saved = Garden.serialize(g)
local restored = Garden.load(saved)
assert(restored.crafted.BerryMash == 1, "crafted inventory persists")
assert(restored.seeds.Pepper == 3, "seeds persist")
assert(restored.crops.Berry == 1, "crops persist after recipe")
assert(restored.plots[1] == false, "empty plot persists")

local tampered = Garden.load({seeds={Berry=math.huge, Fake=1000}, crops={Berry=0/0}, plots={{seed="Fake", plantedAt=1,readyAt=2}}})
assert(tampered.seeds.Berry == 0 and tampered.seeds.Fake == nil, "invalid values are sanitized")
assert(tampered.crops.Berry == 0 and not tampered.plots[1], "bad crop data is rejected")
print("PASS: 12 crops, premium disabled, planting, fertilizer, harvesting, coins, crafting, lures, persistence and input validation")
"""
# Roblox-specific color values aren't relevant to these logic tests.
source = "Color3 = {fromRGB = function(r, g, b) return {r, g, b} end}\n" + config + "\n" + rules + "\n" + suite
with tempfile.TemporaryDirectory() as temp:
    path = Path(temp) / "garden_spec.luau"
    path.write_text(source, encoding="utf-8")
    p = subprocess.run([exe, str(path)], capture_output=True, text=True, timeout=30)
    if p.stdout:
        print(p.stdout, end="")
    if p.stderr:
        print(p.stderr, file=sys.stderr, end="")
    sys.exit(p.returncode)
