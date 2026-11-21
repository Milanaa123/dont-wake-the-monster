"""Shared authored detail sculpts for the headline kitten and bunny companions.

These are actual triangulated 3-D surfaces in the same scene as the gameplay
pet. No image generation, paper concept art, borrowed assets or extra
MeshPart instances. Coordinates match the existing Y-up / -Z-forward rig.
"""
from math import cos, pi, sin


def sculpt_kitten_face(g, base, second):
    """Feline ears, muzzle, cheek ruff and facial expression without orb spam."""
    from orchard_sculpt import loft

    # Proper triangular pinnae: broad at the skull and pointed at their tips.
    # The interior is a shallow pink leaf surface, not a solid pink cylinder.
    for side in (-1, 1):
        loft(g, base, [
            (side*.70, 2.25, -.51, .33, .28),
            (side*.87, 2.59, -.51, .36, .21),
            (side*1.05, 2.97, -.50, .20, .13),
            (side*1.11, 3.27, -.49, .026, .027),
        ], sides=12)
        g.leaf("rose" if base == "pink" else "pink",
               (side*.83, 2.57, -.76),
               (side*1.10, 3.15, -.62), .205, .045, 6, 3)
        # Fine cream ear guard fur points towards the viewer.
        for j in range(3):
            start=(side*(.80 + j*.10), 2.51+j*.105, -.76)
            tip=(side*(1.03+j*.12), 2.64+j*.13, -.78)
            g.leaf("ivory", start, tip, .062, .021, 3, 2)

    # Two sculpted muzzle lobes instead of a generic big oval balloon.
    for side in (-1, 1):
        g.blob("ivory", (side*.22, 1.43, -1.395),
               (.305, .225, .218), 13, 8)
        # Almond-like eye crease has actual width and volume.
        g.tube("chocolate", [
            (side*.23, 1.91, -1.360),
            (side*.44, 2.005, -1.388),
            (side*.67, 1.93, -1.325),
        ], [.024, .028, .014], 6)
        # Cheek ruff has pointed individual clumps, not sphere tufts.
        for j in range(4):
            y=1.37 + j*.13
            basept=(side*.75, y, -1.17)
            tip=(side*(1.07 + .07*(3-j)), y + .11*(j-1), -1.15)
            g.leaf(second if j%3==0 else "ivory", basept,
                   tip, .135-.012*j, .065, 5, 2)

    g.blob("rose", (0, 1.59, -1.575), (.107,.075,.085), 11, 7)
    # Lower central cleft and a small smile follow the two muzzle lobes.
    g.tube("chocolate", [
        (0, 1.525, -1.58),
        (0, 1.435, -1.594),
        (-.105, 1.395, -1.574),
    ], [.018,.018,.009], 6)
    g.tube("chocolate", [
        (0, 1.435, -1.594),
        (.108, 1.385, -1.574),
    ], [.018,.008], 6)

    # Soft top-of-head tufts emphasize a swept feline fur silhouette.
    for i in range(5):
        x=(i-2)*.17
        g.leaf(second if i%2 else base,
               (x, 2.49, -.65),
               (x+(i-2)*.055,2.71+(.065 if i%2 else 0),-.67),
               .085, .032, 4, 2)


def sculpt_bunny_ears(g, base):
    """Tapered rabbit ears with shaped inner membranes and natural asymmetry."""
    from orchard_sculpt import loft
    for side in (-1, 1):
        x=.49*side
        lean=.21 if side<0 else -.07
        loft(g, base, [
            (x, 2.25, -.40, .30, .24),
            (x+side*.10, 2.87, -.39, .34, .18),
            (x+side*.14+lean, 3.61, -.43, .28, .14),
            (x+side*.16+lean, 4.18, -.47, .11, .065),
            (x+side*.17+lean, 4.36, -.47, .013, .014),
        ], sides=11)
        g.leaf("pink",
               (x+side*.06, 2.84, -.635),
               (x+side*.16+lean, 4.13, -.59),
               .19, .045, 7, 3)
        # Smaller three-dimensional cream lobe on the head attachment.
        g.blob("cream", (x,2.39,-.39),(.30,.16,.27),10,6)


def sculpt_fluffy_collarette(g, root_y, root_z, tone, count=11):
    """Low triangle-count tapered fur/feather silhouette below the chin."""
    for i in range(count):
        angle = 2*pi*i/count
        x=cos(angle)*.57
        z=root_z+sin(angle)*.15
        g.leaf(tone,
               (x,root_y,z),
               (x*1.18,root_y-.32-(i%3)*.07,z-.14),
               .12+(i%3)*.019,.055,4,2)
