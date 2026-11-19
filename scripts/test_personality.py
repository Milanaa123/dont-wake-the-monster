#!/usr/bin/env python3
"""Execute the real pure-Luau pet personality module, without Roblox Studio.

This catches seeded identity drift, save/load corruption, tampered saves,
food preference and mood regressions. It is NOT a 3D/client/network playtest.
"""
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
compiler = sys.argv[1] if len(sys.argv) > 1 else "luau"
src = (root / "src/shared/PetPersonality.luau").read_text(encoding="utf-8")
assert src.rstrip().endswith("return Personality")
module_source = src.rsplit("return Personality", 1)[0]

suite = r"""
assert(#Personality.Temperaments == 12, "12 core temperaments")
assert(#Personality.Habits == 12, "12 habitual actions")
assert(#Personality.Fears == 7 and #Personality.Affection == 7, "fears and affection")
assert(#Personality.Foods == 4, "food preferences")

local seenTemperaments = {}
local seenHabits = {}
local seenFears = {}
local signatures = {}
for seed = 1, 1200 do
    local p = Personality.generate(seed, "pastel kitten")
    assert(p.favoriteFood ~= p.dislikedFood, "likes and dislikes cannot match")
    assert(p.seed >= 1 and p.seed < 2147483647, "seed valid")
    for _, name in ipairs({"kindness", "curiosity", "courage", "mischief", "sociability", "sensitivity"}) do
        assert(p.traits[name] >= 0 and p.traits[name] <= 100, "trait bounds")
    end
    seenTemperaments[p.temperament] = true
    seenHabits[p.habit] = true
    seenFears[p.fear] = true
    signatures[p.temperament .. "/" .. p.habit .. "/" .. p.fear .. "/" .. p.favoriteFood] = true
end
for _, name in ipairs(Personality.Temperaments) do assert(seenTemperaments[name], "Missing temperament: " .. name) end
for _, name in ipairs(Personality.Habits) do assert(seenHabits[name], "Missing habit: " .. name) end
for _, name in ipairs(Personality.Fears) do assert(seenFears[name], "Missing fear: " .. name) end
local variations = 0
for _ in pairs(signatures) do variations += 1 end
assert(variations > 150, "Too few independently varying character combinations")

local a = Personality.generate(15264, "pastel kitten")
local b = Personality.generate(15264, "pastel kitten")
assert(a.temperament == b.temperament and a.habit == b.habit, "same seed must reproduce identity")
assert(a.favoriteFood == b.favoriteFood and a.traits.courage == b.traits.courage, "same seed must reproduce tastes")
local c = Personality.generate(Personality.seedFor(45678, 1), "pastel kitten")
local d = Personality.generate(Personality.seedFor(67890, 1), "pastel kitten")
assert(c.seed ~= d.seed, "same cat across two owners should not have the same identity seed")

local packed = Personality.pack(a)
local restored = Personality.restore(packed, "pastel kitten")
assert(restored ~= nil and restored.temperament == a.temperament, "temperament survives rejoin")
assert(restored.habit == a.habit and restored.favoriteFood == a.favoriteFood, "habits/tastes survive rejoin")
assert(restored.traits.mischief == a.traits.mischief and restored.seed == a.seed, "genes survive rejoin")

local favorable = a.favoriteFood
local bad = a.dislikedFood
local before = a.bond
local reaction, noise = Personality.feed(a, favorable)
assert(a.bond > before and noise == -3 and reaction == "LOVES THIS SNACK!", "favorite snacks help bonding")
reaction, noise = Personality.feed(a, bad)
assert(noise == 8, "disliked snack makes extra noise")
local good, text = Personality.interact(a, "Pet")
assert(good and a.bond > before, "friendly interaction gains bond")
good, text = Personality.interact(a, "Play")
assert(good and a.energy < 100, "playing costs energy")
good, text = Personality.interact(a, "Comfort")
assert(good, "soothing works")
good, text = Personality.interact(a, "FakeAdminAction")
assert(not good, "invalid action must be rejected")
for i = 1, 50 do Personality.feed(a, favorable) end
assert(a.bond <= 100 and a.happiness <= 100 and a.hunger >= 0, "stats must stay bounded")

local tampered = Personality.restore({seed=15264, happiness=999999, energy=-100, hunger=0/0, bond=math.huge, interactions=999999999}, "pastel kitten")
assert(tampered ~= nil and tampered.happiness == 100 and tampered.energy == 0, "untrusted save is clamped")
assert(tampered.hunger >= 0 and tampered.hunger <= 100, "NaN hunger rejected")
assert(tampered.bond <= 100 and tampered.interactions <= 1000000, "bond and interactions clamped")
assert(Personality.restore({seed=-99}, "kitten") == nil, "invalid seed rejected")
assert(Personality.restore({seed="not-a-number"}, "kitten") == nil, "string seed rejected")

local distinctWeights = {}
for i = 1, 400 do
    local p = Personality.generate(i, "kitten")
    distinctWeights[Personality.reactionMultiplier(p, "Sneeze")] = true
end
local n = 0
for _ in pairs(distinctWeights) do n += 1 end
assert(n > 1, "unique character must influence reaction likelihoods")

local m = Personality.mood(a, false)
assert(type(m) == "string", "mood returned")
a.energy = 1
assert(Personality.mood(a, false) == "Sleepy", "low energy changes mood")
a.energy = 60
a.hunger = 90
assert(Personality.mood(a, false) == "Hungry", "hunger changes mood")
a.hunger = 30
local idle = Personality.tick(a, false)
assert(type(idle) == "string" and a.hunger >= 30, "idle behavior and needs")
print("PASS: 12 temperaments, 12 habits, 7 fears, food tastes, seeded cat individuality, traits, bonding, save migration, moods and reactions")
"""
with tempfile.TemporaryDirectory() as folder:
    script = Path(folder) / "personality_spec.luau"
    script.write_text(module_source + "\n" + suite, encoding="utf-8")
    run = subprocess.run([compiler, str(script)], capture_output=True, text=True, timeout=35)
    if run.stdout:
        print(run.stdout, end="")
    if run.stderr:
        print(run.stderr, file=sys.stderr, end="")
    sys.exit(run.returncode)
