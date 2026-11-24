"""Check contacts on the den's raised dais using posed, packed vertices."""
import json
import math
from pathlib import Path
import struct
import sys

from package_studio import unpack


bank = json.loads(Path("assets/OrchardGeometry.model.json").read_text())
record = next(row for row in bank["children"] if row["name"] == "Environment_SleepingMonster")
spec = json.loads(record["properties"]["Value"])
scale = 52 / spec["size"][1]
points = {}
for section in spec["parts"]:
    data = unpack(section["data"])
    count = struct.unpack_from("<I", data)[0]
    vertices = struct.iter_unpack("<3h3b2H", data[8:8 + 13 * count])
    points[section["name"]] = [tuple(n / 2048 for n in vertex[:3]) for vertex in vertices]


def bounds(part, vertices):
    x, y, z, xx, xy, xz, yx, yy, yz, zx, zy, zz = part["cframe"]
    low, high = math.inf, -math.inf
    for a, b, c in vertices:
        px = (x + xx*a + xy*b + xz*c) * scale
        py = (y + yx*a + yy*b + yz*c) * scale + 26
        pz = (z + zx*a + zy*b + zz*c) * scale
        # The island surface is three studs below the circular dais.
        floor = -3 if px*px + pz*pz > 30**2 else 0
        low = min(low, py - floor)
        high = max(high, py)
    return low, high


def inspect(pose):
    name = pose["label"]
    extents = {
        key: bounds(pose["parts"][key], vertices)
        for key, vertices in points.items() if not pose["parts"][key].get("hidden")
    }
    assert min(low for low, _ in extents.values()) >= -.08, (name, extents)
    for foot in ("LegL", "LegR"):
        assert abs(extents[foot][0]) < .08, (name, foot, extents[foot])
    return extents


still, movement = [json.loads(Path(path).read_text()) for path in sys.argv[1:]]
states = {pose["label"]: inspect(pose) for pose in still}
assert len(movement) == 54
for pose in movement:
    inspect(pose)
sleep, stir, awake = (states[key] for key in ("Asleep", "Stirring", "Awake"))
assert sleep["Head"][1] + 10 < awake["Head"][1]
assert sleep["Head"][1] < stir["Head"][1] < awake["Head"][1]
assert stir["ArmL"][0] > sleep["ArmL"][0] + 8 and stir["ArmR"][0] < 3
print(f'PASS: both hind feet touch the dais across {len(movement)} transition frames; '
      f'crown height above dais {sleep["Head"][1]:.1f} / {stir["Head"][1]:.1f} / {awake["Head"][1]:.1f} studs')
