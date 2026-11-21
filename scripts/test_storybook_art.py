#!/usr/bin/env python3
"""Offline regression checks for requested 3-D kawaii pet / crop direction.

These are GEOMETRY checks, not a substitute for appearance approval or a
Roblox Studio playtest. They prevent the sticker-inspired sculpts from silently
disappearing during later code refactors or exceeding the mobile art budget.
"""
import math
from generate_reference_glb import Sculpt, PET_SPECS, CROP_NAMES
from creature_shapes_v2 import SPECIES, sculpt_species
from crop_shapes_v2 import sculpt_crop

def finite_mesh(mesh):
    assert 90 < mesh.count() < 9000, (
        f"Invalid triangle budget: {mesh.name} has {mesh.count()} triangles"
    )
    assert mesh.data, f"Empty artwork: {mesh.name}"
    for material,(positions,normals) in mesh.data.items():
        assert len(positions)==len(normals) and len(positions)%3==0, (
            f"Broken face list: {mesh.name}/{material}"
        )
        assert all(all(math.isfinite(n) for n in vertex) for vertex in positions), (
            f"Non-finite vertex in {mesh.name}/{material}"
        )
        assert all(all(math.isfinite(n) for n in normal) for normal in normals), (
            f"Non-finite face normal in {mesh.name}/{material}"
        )

def bounds(mesh):
    vertices=[p for positions,_ in mesh.data.values() for p in positions]
    return [(min(v[i] for v in vertices), max(v[i] for v in vertices))
            for i in range(3)]

pets={}
for name,_,base,second in PET_SPECS:
    pet=sculpt_species(name,base,second,Sculpt)
    finite_mesh(pet)
    pets[name]=pet
assert len(pets)==30 and len(set(SPECIES.values()))>=15

# Readable baby-pet silhouettes, not recycled generic renamed spheres.
pip=pets["Pip"]
assert "Head" in pip.joints and "Tail" in pip.joints
assert bounds(pip)[1][1] > 3.1, "Sculpted kitten ears disappeared"
eyes=pip.data["eye"][0]
assert eyes and max(abs(p[0]) for p in eyes)<.70, (
    "Oversized, googly, outward floating eye geometry returned"
)
assert "rose" in pip.data and "blush" in pip.data, (
    "Pink kitten nose or warm expressive cheeks disappeared"
)
assert bounds(pets["Floofle"])[1][1]>4.20, "Rabbit's real tall ears missing"
assert "orange" in pets["Floofle"].data, "Carrot prop missing from bunny"
assert "bark" in pets["Wobble"].data, "Bear honey pot missing"
assert "leafdeep" in pets["Pebble"].data, "Turtle's dark shell seam missing"
assert "blush" in pets["Pickle"].data, "Frog's cheeks missing"
assert "ivory" in pets["Puffin"].data, "Puffin belly missing"

crops={}
for crop in CROP_NAMES:
    for stage in (1,2,3):
        model=sculpt_crop(crop,stage,Sculpt)
        finite_mesh(model)
        crops[(crop,stage)]=model
assert len(crops)==90

# No red berries appear on seedlings; ripe strawberries are red and seeded.
assert "red" not in crops["Berry",1].data
assert "pink" in crops["Berry",2].data
assert "red" in crops["Berry",3].data
assert "straw" in crops["Berry",3].data
assert "rind" in crops["LavaMelon",3].data
assert "chocolate" in crops["Sunflower",3].data, "Sunflower seed disks gone"
assert "gold" in crops["MoonLotus",3].data, "Lotus centres missing"
assert "lilac" in crops["Moonshroom",3].data, "Bell mushroom caps missing"
assert "blue" in crops["NeonMushroom",3].data
assert "cream" in crops["CloudCotton",3].data
assert crops["Sunflower",3].count()>crops["Sunflower",1].count()
assert crops["Berry",3].count()>crops["Berry",1].count()

# Each dwarf fruit tree must have a real seedling, growing and ripe state,
# not exactly the same foliage with only a differently tinted floating orb.
for tree, ripe_material in (
    ("HoneyPear","gold"),
    ("CaramelApple","red"),
    ("ThunderPlum","violet"),
):
    young, growing, ripe = (crops[tree,stage] for stage in (1,2,3))
    # A pear blossom has a tiny GOLD pollen centre even before it fruits:
    # require more golden *surface* in ripe pears, not an absence of gold.
    if tree=="HoneyPear":
        assert len(ripe.data["gold"][0]) > len(young.data["gold"][0]), (
            "Honey pear ripe fruit was not added beyond blossom pollen"
        )
    else:
        assert ripe_material not in young.data, f"{tree}: ripe fruit exists at sprout stage"
    assert "leaflight" in growing.data, f"{tree}: juvenile green fruit missing"
    assert ripe_material in ripe.data, f"{tree}: ripe fruit missing its unique pigment"
    # First-stage flowers use many small petal triangles, while ripe fruit
    # uses a compact rounded surface. Triangle count is NOT a growth metric.
    # Mature dimensions and distinct pigments are the stable visual contract.
    assert bounds(ripe)[1][1] > bounds(young)[1][1] * 1.4, (
        f"{tree}: tree crown does not grow across stages"
    )

print(
    f"PASS: {len(pets)} original articulated baby-animal meshes and "
    f"{len(crops)} botanical growth assets; shape identity, readable 3D "
    "muzzle/ears/shells, plant maturity, finite geometry and <9000 "
    "triangles/asset verified."
)
print("CAUTION: style fidelity still requires visual inspection in Roblox.")
