"""Original storybook fruit trees used as 3D crops in the real Roblox place.

Three distinct, compact dwarf-tree shapes, matching the garden's soft
botanical proportions. Y-up; authored mesh geometry only, no images.
Stages: flowering seedling, green juvenile fruit, ripe colored harvest.
"""
from math import cos, pi, sin
from orchard_sculpt import loft


def sculpt_dwarf_fruit_tree(g, name, stage):
    assert name in ("HoneyPear", "CaramelApple", "ThunderPlum")
    assert stage in (1, 2, 3)
    scale = (.44, .72, 1.0)[stage - 1]

    def branch(points, r):
        g.tube("bark", points, [r, r * .72, r * .29], 7)

    def petal(mat, a, b, width):
        g.leaf(mat, a, b, width, .055 * scale, 5, 3)

    # Slight organic bend, not a vertical tree made from a single cylinder.
    g.tube("wood", [(0, .05, 0), (.08 * scale, .58 * scale, .04 * scale),
          (-.04 * scale, 1.12 * scale, .07 * scale),
          (.06 * scale, 1.55 * scale, -.06 * scale)],
          [.18 * scale, .15 * scale, .115 * scale, .075 * scale], 9)
    n = 3 + stage
    for i in range(n):
        a = i * 2.3999632297
        h = (1.17 + (i % 3) * .105) * scale
        x, z = 1.00 * scale * cos(a), .84 * scale * sin(a)
        shoulder = (.31 * x, .76 * scale, .27 * z)
        crown = (x, h, z)
        branch([(0, .60 * scale, 0), shoulder, crown], .087 * scale)
        # Nested, naturally asymmetrical leaf fans produce a fuller canopy
        # without repeating spherical green lumps in the old generator.
        for k in range(7):
            b = a + (k - 3) * .66
            lift = (.08 if k % 2 else -.10) * scale
            start = (x - .23 * scale * cos(b), h + lift,
                     z - .23 * scale * sin(b))
            tip = (x + (.30 + .06 * (k % 3)) * scale * cos(b),
                   h + (.20 + .09 * (k % 2)) * scale,
                   z + (.32 + .055 * (k % 3)) * scale * sin(b))
            petal("leaflight" if (k + i) % 4 == 0 else
                  "leafdeep" if (k + i) % 7 == 0 else "leaf",
                  start, tip, .19 * scale)
        if stage == 1:
            # Opening blossoms establish a distinct first stage; no fruit.
            for j in range(2):
                p = (x + (.18 if j else -.13) * scale,
                     h + (.04 + .14 * j) * scale,
                     z - .20 * scale)
                for k in range(5):
                    b = 2 * pi * k / 5
                    petal("ivory" if j else "cream", p,
                          (p[0] + .11 * scale * cos(b),
                           p[1] + .11 * scale * sin(b),
                           p[2] - .03 * scale), .06 * scale)
                g.blob("gold", (p[0], p[1], p[2] - .045 * scale),
                       (.041 * scale, .039 * scale, .023 * scale), 8, 5)
            continue

        # Hanging fruit points towards the player (-Z) to keep it legible.
        x, y, z = (x + .07 * scale * cos(a), h - .19 * scale,
                   z - .24 * scale)
        r = (.16 if stage == 2 else .29) * scale
        fruit_color = ("leaflight" if stage == 2 else
                       "gold" if name == "HoneyPear" else
                       "red" if name == "CaramelApple" else "violet")
        if name == "HoneyPear":
            loft(g, fruit_color, [
                (x, y-r, z, .045*r, .045*r),
                (x, y-.66*r, z, .75*r, .75*r),
                (x, y-.25*r, z, 1.02*r, .97*r),
                (x, y+.23*r, z, .82*r, .80*r),
                (x, y+.78*r, z, .40*r, .38*r),
                (x, y+r, z, .04*r, .04*r),
            ], 13)
        else:
            # Apple has shallow top/bottom dimples; plum is taller.
            g.blob(fruit_color, (x, y, z),
                   (r, r*(.87 if name=="CaramelApple" else 1.21),
                    r*.92), 15, 9)
            if name=="CaramelApple" and stage==3:
                g.blob("ochre", (x,y-r*.78,z-r*.24),
                       (r*.20,r*.12,r*.065),8,5)
        branch_start = (x, y + r*.75, z)
        g.tube("bark", [branch_start, (x + .035*scale, h + .04*scale, z)],
               [.028 * scale, .016 * scale], 6)
        # One calyx + leaf makes even small fruits recognisable as crops.
        petal("leafdeep", branch_start,
              (x+.25*scale*cos(a+.8), y+r*1.30,
               z+.13*scale*sin(a+.8)), .13*scale)

    # The ground-level silhouette connects the plant to the seed bed.
    for i in range(5):
        a=2*pi*i/5
        petal("leafdeep",(0,.20*scale,0),
              (.43*scale*cos(a),.39*scale,.43*scale*sin(a)),.12*scale)
