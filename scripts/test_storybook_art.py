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
assert "orange" in pets["Puffin"].data, "Puffin tapered orange bill missing"
assert "blush" in pets["Puffin"].data, "Puffin soft cheeks missing"
assert "cream" in pets["Swoop"].data, "Owl facial feather tufts missing"
assert "Tail" in pets["Spark"].joints, "Fox should retain an articulated tail"
assert "ivory" in pets["Spark"].data, "Fox cheek and tail tips missing"
assert "rose" in pets["Snorf"].data, "Dog's little pink tongue disappeared"
for creature in ("Pickle","Nugget","Swoop","Puffin"):
    assert "eye" in pets[creature].data, (
        f"{creature}: tiny black pupils missing from chibi face"
    )

# Check the part ownership used by the Roblox bake, where a misplaced call
# to joint() can leave a face or a toe behind when the character moves.
from bake_orchard import GameSculpt
for name,_,base,second in PET_SPECS:
    if name in ("Swoop","Mochi","Tofu","Luma","Pebble"):
        rig=sculpt_species(name,base,second,GameSculpt)
        assert rig.joints["Blink"][0]=="Head" and set(rig.parts["Blink"])=={"eye","shine"}
        assert "blush" in rig.parts["Head"]
        if name=="Swoop":
            assert {"WingL","WingR","HindL","HindR"} <= rig.parts.keys()
        elif name=="Pebble":
            assert {"leafdeep","sage","moss","straw"} <= rig.parts["Body"].keys()
        else:
            assert all(rig.joints[j][0]=="Head" for j in ("EarL","EarR"))
            assert "brown" in rig.parts["ForeR"] and "cream" in rig.parts["Body"]
    if name not in ("Floofle","Snorf","Pickle","Splat","Pip","Zuzu"):
        continue
    rig=sculpt_species(name,base,second,GameSculpt)
    assert "eye" in rig.parts["Head"]
    assert "blush" in rig.parts["Head"]
    assert all("eye" not in part for joint,part in rig.parts.items() if joint!="Head")
    if name=="Floofle":
        assert rig.joints["Tail"][0]=="Body" and "white" in rig.parts["Tail"]
        for ear in ("EarL","EarR"):
            assert rig.joints[ear][0]=="Head" and "pink" in rig.parts[ear]
    elif name in ("Pip","Zuzu"):
        assert "gold" in rig.parts["Body"] and "chocolate" in rig.parts["Head"]
        assert rig.joints["Tail"][0]=="Body"
        for ear in ("EarL","EarR"):
            assert rig.joints[ear][0]=="Head" and "pink" in rig.parts[ear]
    elif name=="Snorf":
        assert "tan" in rig.parts["Head"] and "ivory" in rig.parts["Head"]
        for ear in ("EarL","EarR"):
            assert rig.joints[ear][0]=="Head" and "brown" in rig.parts[ear]
    else:
        for limb in ("ForeL","ForeR","HindL","HindR"):
            assert rig.joints[limb][0]=="Body" and "leaflight" in rig.parts[limb]

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
# Reversed receptacle walls still pass index and finite-normal checks.
# Test each triangle in isolation on the same berry profile used by the bed.
from storybook_crop_blooms import strawberry
single_berry=Sculpt("BerryProfile")
strawberry(single_berry,(0,0,0),1,"red",True)
positions=single_berry.data["red"][0]
for i in range(0,len(positions),3):
    a,b,c=positions[i:i+3]
    if max(a[1],b[1],c[1])>.16 or min(a[1],b[1],c[1])<-.35:
        continue  # Recessed crown and end caps have different normal directions.
    ab=[v-u for u,v in zip(a,b)]
    ac=[v-u for u,v in zip(a,c)]
    nx=ab[1]*ac[2]-ab[2]*ac[1]
    nz=ab[0]*ac[1]-ab[1]*ac[0]
    assert nx*(a[0]+b[0]+c[0])+nz*(a[2]+b[2]+c[2])>0, "Inverted berry wall"
for crop in ("Berry","FrostBerry"):
    extents=[bounds(crops[crop,stage]) for stage in (1,2,3)]
    widths=[axes[0][1]-axes[0][0] for axes in extents]
    assert widths[0]<widths[1]<widths[2], f"{crop}: growth must expand the crown"
for melon in ("LavaMelon", "AuroraMelon"):
    assert "dandelion" in crops[melon,1].data, (
        f"{melon}: yellow blossoms missing from seedlings"
    )
    assert "leafdeep" in crops[melon,2].data, (
        f"{melon}: mature winding green vine missing"
    )
    assert crops[melon,3].count() > crops[melon,1].count(), (
        f"{melon}: ripening should add visible striped fruit geometry"
    )
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

# Distinct storybook root vegetables: no mature root color on a sprout,
# recognizable color and tapered botanical geometry when harvestable.
for crop, color in (
    ("Carrot", "orange"),
    ("RainbowRadish", "pink"),
    ("MarshmallowRoot", "cream"),
):
    assert color not in crops[crop,1].data, (
        f"{crop}: a seedling already appears harvestable"
    )
    assert color in crops[crop,3].data, (
        f"{crop}: harvestable root lacks its recognizable pigment"
    )
    assert "leafdeep" in crops[crop,2].data
    assert crops[crop,3].count() > crops[crop,1].count()

# Corn must look like *corn*, with ripened golden kernels and husks,
# instead of inheriting the pale wheat ear that used to share its generator.
assert "gold" not in crops["Corn",1].data
assert "gold" not in crops["Corn",2].data
assert "gold" in crops["Corn",3].data
assert "straw" in crops["Corn",3].data
assert "leafdeep" in crops["Corn",2].data
assert crops["Corn",3].count()>crops["Corn",1].count()

# Hanging, scalloped bell peppers go green -> ripe orange; the old tomato
# branch made the two crops almost indistinguishable when viewed from above.
assert "orange" not in crops["Pepper",1].data
assert "orange" not in crops["Pepper",2].data
assert "leaflight" in crops["Pepper",2].data
assert "orange" in crops["Pepper",3].data
assert crops["Pepper",3].count()>crops["Pepper",1].count()

# A tomato progresses from cotyledons to tied, flowering trusses to red fruit.
for stage in (1,2):
    assert "red" not in crops["Tomato",stage].data
assert "straw" not in crops["Tomato",1].data
assert {"straw","dandelion"}.issubset(crops["Tomato",2].data)
assert "red" in crops["Tomato",3].data
assert bounds(crops["Tomato",1])[1][1]<bounds(crops["Tomato",2])[1][1]<bounds(crops["Tomato",3])[1][1]

print(
    f"PASS: {len(pets)} original articulated baby-animal meshes and "
    f"{len(crops)} botanical growth assets; shape identity, readable 3D "
    "muzzle/ears/shells, plant maturity, finite geometry and <9000 "
    "triangles/asset verified."
)
print("CAUTION: style fidelity still requires visual inspection in Roblox.")
