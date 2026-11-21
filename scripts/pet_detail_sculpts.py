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


def sculpt_sticker_personality(g, name, species):
    """Original miniature *3-D* props that make pet silhouettes read at mobile size.

    The user's examples are 2-D graphic references; these props translate their
    soft cheek shapes and recognizable character details into actual meshes.
    Keep these details tiny so all pets remain under the existing triangle budget.
    """
    if species=="kitten":
        # Curved collar, dangling tiny bell and tiny cheek spots.
        g.joint("Head",g.joints["Head"][1])
        g.tube("rose",[(-.58,1.24,-1.04),(-.39,1.16,-1.17),
                        (0,1.12,-1.24),(.39,1.16,-1.17),(.58,1.24,-1.04)],
               [.062,.069,.074,.069,.062],7)
        g.blob("gold",(0,1.06,-1.32),(.15,.15,.105),10,6)
        g.tube("chocolate",[(-.055,1.01,-1.421),(.04,1.01,-1.421)],
               [.014,.014],5)
        for side in (-1,1):
            g.blob("blush",(side*.73,1.43,-1.16),(.15,.075,.039),9,5)
    elif name=="Floofle":
        # A small tapered carrot between the rabbit's front paws.
        g.joint("Body",(0,0,0))
        from orchard_sculpt import loft
        loft(g,"orange",[(0,.63,-1.10,.015,.016),
                         (0,.74,-1.12,.095,.09),
                         (0,.97,-1.15,.13,.12),
                         (0,1.16,-1.18,.105,.10),
                         (0,1.19,-1.18,.026,.02)],12)
        for i in range(3):
            a=2*pi*i/3
            g.leaf("leaflight",(0,1.18,-1.18),
                   (sin(a)*.23,1.47,-1.16+cos(a)*.13),.082,.055,5,2)
        for side in (-1,1):
            g.blob("ivory",(side*.22,.76,-1.19),(.19,.18,.17),11,7)
    elif species=="lamb":
        # Pastel bow on the white fluffy collar, not an imported decal.
        g.joint("Body",(0,0,0))
        for side in (-1,1):
            g.blob("rose",(side*.23,1.47,-1.28),(.27,.18,.10),11,7)
        g.blob("gold",(0,1.47,-1.36),(.105,.10,.085),10,6)
        for side in (-1,1):
            g.leaf("pink",(side*.07,1.42,-1.28),
                   (side*.18,1.13,-1.27),.09,.025,4,2)
    elif species=="frog":
        g.joint("Body",(0,0,0))
        for side in (-1,1):
            g.blob("blush",(side*.71,.77,-.72),(.195,.115,.068),11,7)
            # Three shallow toe nubs instead of cartoon paddle spheres.
            for toe in range(3):
                g.blob("leaflight",(side*(1.19+toe*.15),.11,
                       -.60+toe*.17),(.13,.082,.12),8,5)
    elif species=="dog":
        g.joint("Head",g.joints["Head"][1])
        # Triangular kerchief follows the throat down under the muzzle.
        g.leaf("brick",(-.55,1.19,-1.17),(.55,1.19,-1.17),.25,.07,5,2)
        g.leaf("brick",(0,1.21,-1.18),(0,.72,-1.18),.35,.065,5,2)
        g.blob("gold",(0,1.09,-1.26),(.09,.09,.05),9,5)
    elif species=="fox":
        g.joint("Head",g.joints["Head"][1])
        g.tube("leafdeep",[(-.48,1.25,-1.0),(0,1.14,-1.12),(.49,1.24,-1.0)],
               [.085,.093,.085],7)
        g.leaf("leaflight",(.15,1.19,-1.1),(.38,.77,-1.08),.18,.05,5,2)
        g.leaf("ivory",(.73,1.34,-1.15),(1.02,1.41,-1.13),.16,.06,4,2)
    elif species=="chick":
        g.joint("Body",(0,0,0))
        for side in (-1,1):
            g.blob("blush",(side*.56,1.29,-.59),(.16,.10,.045),9,6)
        # Small flower pin on the head, with a matte golden centre.
        pos=(.30,2.18,-.39)
        for i in range(5):
            a=2*pi*i/5
            g.leaf("ivory",pos,
                   (pos[0]+.17*cos(a),pos[1]+.18*sin(a),pos[2]-.035),
                   .08,.025,4,2)
        g.blob("gold",(pos[0],pos[1],pos[2]-.06),(.065,.06,.04),8,5)
    elif species=="axolotl":
        g.joint("Head",g.joints["Head"][1])
        for side in (-1,1):
            g.blob("blush",(side*.80,1.19,-1.26),(.20,.095,.05),10,6)
