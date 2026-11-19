#!/usr/bin/env python3
"""Run the actual merchant Luau module with a representative free-crop catalog."""
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
binary = sys.argv[1] if len(sys.argv) > 1 else "luau"
source = (root / "src/shared/SeedMerchant.luau").read_text()
assert source.rstrip().endswith("return Shop")
source = source.rsplit("return Shop", 1)[0]
original = 'local G = require(script.Parent:WaitForChild("GardenConfig"))'
assert original in source
catalog = """local G = {Order = {}, Crops = {}, MAX_STACK = 500}
for i = 1, 28 do
    local id = "Plant" .. tostring(i)
    table.insert(G.Order, id)
    G.Crops[id] = {name = id, coins = i * 12, icon = "P", kind = "ordinary"}
end
G.Crops.Premium = {name = "Premium", coins = 0, kind = "premium"}
table.insert(G.Order, "Premium")"""
source = source.replace(original, catalog)
test = r"""
assert(Shop.IntervalSeconds == 720 and Shop.OfferCount == 4)
local time = 1750000000
local current = Shop.rotation(time)
local offers = Shop.offers(time)
assert(#offers == 4)
local seen = {}
for _, o in ipairs(offers) do
    assert(o.price >= 5 and o.count == 2 and o.slot >= 1 and o.slot <= 4)
    assert(not seen[o.seed], "merchant must not repeat seed in same rotation")
    assert(G.Crops[o.seed].kind == "ordinary", "never sell premium for coins")
    seen[o.seed] = true
end
local snapshot = Shop.snapshot(time, {rotation = -1, slots = {}})
assert(snapshot.rotation == current and snapshot.nextRestock > time)
local g = {seeds = {}, merchant = {rotation = -1, slots = {}}}
local ok, message, price = Shop.buy(g, 9999, 1, time)
assert(ok and price == offers[1].price and g.seeds[offers[1].seed] == 2)
local second = Shop.buy(g, 9999, 1, time)
assert(not second, "one purchase per offer per rotation")
assert(Shop.snapshot(time, g.merchant).claimed[1] == true)
local nextTime = (current + 1) * Shop.IntervalSeconds
local nextSnapshot = Shop.snapshot(nextTime, g.merchant)
assert(nextSnapshot.claimed[1] ~= true, "restock should unlock new offers")
local canBuy = Shop.buy(g, 9999, 1, nextTime)
assert(canBuy, "new rotation should allow fresh purchase")
local invalid = Shop.buy(g, 9999, "1", nextTime)
assert(not invalid, "reject spoofed string slot")
local invalid2 = Shop.buy(g, 9999, 1.5, nextTime)
assert(not invalid2, "reject fractional slot")
local poor = Shop.buy({seeds = {}, merchant = {rotation = -1, slots = {}}}, 0, 2, nextTime)
assert(not poor, "must check player coins")
local capped = {seeds = {[Shop.offers(nextTime)[2].seed] = 499}, merchant = {rotation = -1, slots = {}}}
local full = Shop.buy(capped, 9999, 2, nextTime)
assert(not full, "no overflow")
local found = {}
for rotation = 0, 60 do
    for _, offer in ipairs(Shop.offers(rotation * Shop.IntervalSeconds)) do found[offer.seed] = true end
end
local varieties = 0
for _ in pairs(found) do varieties += 1 end
assert(varieties >= 20, "rotating merchant should offer broad plant diversity")
print("PASS: deterministic merchant, 4 unique offers, 12m restock, 20+ seeds, no paid plants, secure purchase and saved limits")
"""
with tempfile.TemporaryDirectory() as tmp:
    path = Path(tmp) / "merchant_test.luau"
    path.write_text(source + "\n" + test)
    result = subprocess.run([binary, str(path)], capture_output=True, text=True, timeout=30)
    if result.stdout: print(result.stdout, end="")
    if result.stderr: print(result.stderr, end="", file=sys.stderr)
    sys.exit(result.returncode)
