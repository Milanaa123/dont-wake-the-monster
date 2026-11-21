"""Original plush-storybook sculpt layers for the existing 30 pet species.

The user supplied flat animal-sticker pictures as art direction; these are
three-dimensional, animated-rig compatible surfaces, not sticker image planes.
Only sculpted mesh primitives are emitted, with tiny bounded polygon costs.
All coordinates use local Y-up, -Z-forward coordinates of existing pets.
"""
from math import cos, pi, sin


def add_family_details(g, name, species, base, secondary):
    def body():
        g.joint("Body", (0, 0, 0))

    def head():
        if "Head" in g.joints:
            g.joint("Head", g.joints["Head"][1])
        else:
            body()

    def blob(mat, center, radii, slices=11, rings=6):
        g.blob(mat, center, radii, slices, rings)

    def vine(mat, points, radii):
        g.tube(mat, points, radii, 6)

    def leaf(mat, start, end, width):
        g.leaf(mat, start, end, width, .035, 4, 2)

    if species == "bear":
        head()
        # Small pale plush muzzle and smile attached to the moving head.
        blob("cream", (0, 1.67, -1.19), (.43, .31, .15), 15, 8)
        blob("chocolate", (0, 1.73, -1.36), (.118, .076, .047))
        for side in (-1, 1):
            blob("blush", (side*.79, 1.88, -1.05), (.153,.087,.033))
            blob("pink", (side*.80, 2.57, -.665), (.18,.13,.040))
        # A tiny jar of honey makes the bear distinctive in the silhouette.
        body()
        if name == "Wobble":
            from orchard_sculpt import loft
            loft(g, "bark", [
                (0,.33,-1.13,.30,.24),
                (0,.45,-1.15,.35,.27),
                (0,.84,-1.16,.34,.25),
                (0,.94,-1.16,.28,.20)
            ], 13)
            blob("gold", (0,.95,-1.16), (.30,.075,.22), 12,6)
            for side in (-1,1):
                blob(base, (side*.34,.69,-1.20), (.17,.23,.17), 10,6)

    elif species == "turtle":
        body()
        # A woven shell lip and softly engraved scute curves. Not separate
        # floating green bumps, and the dark rim gives mobile-scale contrast.
        rim=[]
        for i in range(25):
            a=2*pi*i/24
            rim.append((1.21*sin(a), .91+.085*cos(a*2),
                        .45+1.30*cos(a)))
        vine("leafdeep", rim, [.045]*len(rim))
        for j in range(6):
            a=2*pi*j/6
            bx=.74*sin(a)
            bz=.45+.80*cos(a)
            # Shell surface with a rounded top at y ~= 1.9.
            y=1.1+.99*(max(.05,1-(bx/1.28)**2-
                             ((bz-.45)/1.37)**2))**.5
            outline=[]
            for i in range(7):
                b=2*pi*i/6
                xx=bx+.19*sin(b)
                zz=bz+.22*cos(b)
                yy=1.1+.99*(max(.05,1-(xx/1.28)**2-
                                 ((zz-.45)/1.37)**2))**.5+.025
                outline.append((xx,yy,zz))
            vine("leafdeep",outline,[.023]*7)
        blob("cream",(0,.94,-1.61),(.32,.19,.15),12,6)

    elif species in ("chick", "owl", "puffin"):
        body()
        # Round, wing-sized bibs and visibly padded toes for the baby birds.
        if species=="puffin":
            blob("ivory",(0,1.10,-.69),(.56,.65,.16),16,9)
        elif species=="owl":
            for side in (-1,1):
                leaf("cream",(side*.12,1.92,-.57),
                     (side*.66,2.27,-.55),.17)
        for side in (-1,1):
            for toe in range(3):
                x=side*.43+(toe-1)*.12
                blob("gold" if species=="chick" else "orange",
                     (x,.075,-.19),(.087,.069,.16),8,5)

    elif species == "deer":
        body()
        # High-contrast fawn freckles along both flanks, intentionally
        # staggered and low-poly so the pattern survives on small screens.
        for side in (-1,1):
            for i in range(4):
                x=side*(.46+.055*(i%2))
                y=1.47+.10*(i%2)
                z=.21+i*.31
                blob("cream",(x,y,z),(.085,.065,.092),8,5)
        head()
        blob("ivory",(0,2.08,-1.32),(.19,.22,.058),10,6)

    elif species == "ferret":
        head()
        # Dark face mask is recognisable for a ferret even at phone scale.
        for side in (-1,1):
            blob(secondary,(side*.35,1.56,-1.44),(.28,.23,.053),11,6)
        body()
        # Cream throat bib is smaller than the chin so it doesn't turn into
        # another large featureless sphere.
        leaf("ivory",(0,1.08,-.63),(0,.54,-.90),.29)

    elif species == "dinosaur":
        body()
        # Soft sculpted belly patch and tiny triangular dorsal plates.
        blob("cream",(0,.91,-.86),(.55,.57,.14),15,8)
        for i in range(6):
            z=.04+i*.33
            leaf("leaflight",(0,1.72-i*.12,z),
                 (0,2.17-i*.14,z+.13),.22)

    elif species=="octopus":
        body()
        for side in (-1,1):
            blob("blush",(side*.84,1.04,-.55),(.15,.08,.04),9,5)
        # A soft cream head glint replaces sharp graphic stickers.
        blob("cream",(-.27,1.80,-.55),(.11,.045,.035),8,5)

    elif species=="unicorn":
        head()
        # A few matte locks around the horn keep the silhouette expressive.
        for j in range(3):
            x=(j-1)*.31
            leaf("lilac",(x,2.83,-.48),
                 (x+.12,2.54,-1.08),.18)

    elif species=="crab":
        body()
        for side in (-1,1):
            blob("blush",(side*.81,.78,-.63),(.15,.08,.036),9,5)

    elif species=="butterfly":
        body()
        for side in (-1,1):
            # Spots stay on their wing joint and follow flapping animation.
            g.joint("Wing"+("L" if side<0 else "R"),
                    (side*.13,1.62,.19),"Body")
            blob("ivory",(side*.95,2.11,.22),(.17,.13,.032),10,6)
            blob("gold",(side*1.18,1.91,.24),(.095,.09,.027),8,5)
        body()
