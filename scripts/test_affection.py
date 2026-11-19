#!/usr/bin/env python3
"""Execute the real pure Luau cat-petting/overstimulation rules in CI."""
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
executable = sys.argv[1] if len(sys.argv) > 1 else "luau"
source = (root / "src/shared/PetAffection.luau").read_text(encoding="utf8")
assert source.strip().endswith("return Affection")
source = source.rsplit("return Affection", 1)[0]

test = r"""
assert(Affection.isCat("pastel kitten"))
assert(Affection.isCat("Fire Cat"))
assert(not Affection.isCat("little turtle"))
assert(not Affection.isCat(nil))
assert(Affection.PetDistance <= 25)
local p = {
    temperament = "Kind", happiness = 89, bond = 93, energy = 84,
    hunger = 20, affection = "HeadPats",
    traits = {kindness = 90, sensitivity = 8, courage = 50, mischief = 12},
}
local session = Affection.newSession(p, true, 1)
assert(session.enjoys and session.cat, "happy cat enjoys strokes")
local totalNoise, peak, lastPurr = 0, 0, 0
for i = 1, 40 do
    local result = Affection.step(p, session, 0.5, 1)
    totalNoise += result.noise
    peak = math.max(peak, result.purr)
    assert(result.purr >= lastPurr, "contented cat should gradually purr louder")
    lastPurr = result.purr
    if result.done then break end
end
assert(peak > 0.7, "gentle long petting builds a loud purr")
assert(totalNoise >= 15, "loud cat purr should contribute substantial monster noise")
assert(p.bond > 93 and p.happiness > 89, "petting strengthens friendship")
local other = {
    temperament = "Grumpy", happiness = 40, bond = 0, energy = 60, hunger = 42,
    affection = "Games", traits = {kindness = 18, sensitivity = 100},
}
local angry = Affection.newSession(other, true, 0)
local hadOverstimulation = false
for i = 1, 45 do
    local result = Affection.step(other, angry, 0.5, 0)
    if result.done and (result.event == "Swat" or result.event == "Hiss" or result.event == "Zoomies") then
        hadOverstimulation = true
        break
    end
end
assert(hadOverstimulation, "impatient grumpy cat can suddenly swat")
local gentle = {
    temperament = "Kind", happiness = 76, bond = 47, energy = 85, hunger = 30,
    affection = "HeadPats", traits = {kindness = 60, sensitivity = 20},
}
local dog = Affection.newSession(gentle, false, 0.4)
local maxPurr, noise = 0, 0
for i = 1, 18 do
    local result = Affection.step(gentle, dog, 0.5, 0.7)
    maxPurr = math.max(maxPurr, result.purr)
    noise += result.noise
end
assert(maxPurr == 0 and noise == 0, "non-cats receive care but do not magically purr")
assert(gentle.happiness > 76, "non-cat care still matters")
local done = Affection.newSession(p, true, 1)
done.elapsed = Affection.MaxSessionSeconds - 0.2
local result = Affection.step(p, done, 0.5, 0.7)
assert(result.done and result.event == "NeedsRest", "bounded hold duration")
print("PASS: cat/non-cat distinction, continuous petting, crescendo noise, irritation, love and session limits")
"""
with tempfile.TemporaryDirectory() as directory:
    path = Path(directory) / "affection_spec.luau"
    path.write_text(source + "\n" + test, encoding="utf8")
    result = subprocess.run([executable, str(path)], capture_output=True, text=True, timeout=35)
    if result.stdout: print(result.stdout, end="")
    if result.stderr: print(result.stderr, file=sys.stderr, end="")
    sys.exit(result.returncode)
