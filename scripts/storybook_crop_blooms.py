"""Actual 3-D blossoms and mushrooms for the game-ready crop sculpt pipeline.

The player-provided kawaii animal pictures inform the same matte, rounded
storybook material language. Each species retains botanical identity and
three recognizable growth stages. This does NOT generate sticker images.
"""
from math import cos, pi, sin


def blossom(g, crop, center, maturity):
    x,y,z=center
    radius=.40*maturity
    if crop=="Sunflower":
        petals=12
        petalColor="dandelion"
        centerColor="chocolate"
        tipRadius=.61*maturity
        width=.19*maturity
    elif crop=="MoonLotus":
        petals=9
        petalColor="ivory"
        centerColor="gold"
        tipRadius=.55*maturity
        width=.23*maturity
    elif crop=="Starbloom":
        petals=7
        petalColor="pink"
        centerColor="cream"
        tipRadius=.57*maturity
        width=.20*maturity
    else:  # CloudCotton: short real branches of fluffy cotton, not a flower clone.
        petals=0
        petalColor="cream"
        centerColor="gold"
        tipRadius=.4*maturity
        width=.13*maturity

    if crop=="CloudCotton":
        g.blob("ivory",(x,y,z-.11),(.30*maturity,.28*maturity,.18*maturity),12,7)
        for i in range(7):
            a=2*pi*i/7
            g.blob("cream",
                   (x+.24*maturity*cos(a),
                    y+.20*maturity*sin(a),z-.12),
                   (.15*maturity,.15*maturity,.13*maturity),10,6)
        for i in (-1,1):
            g.leaf("leaflight",(x,y-.24*maturity,z),
                   (x+i*.37*maturity,y-.35*maturity,z+.02),
                   .14*maturity,.025,4,2)
        return

    # Flowers face the default angled player camera. Raised curved petals
    # and individual matte center volumes make a real 3-D rosette.
    for i in range(petals):
        a=2*pi*i/petals
        root=(x+cos(a)*radius*.22,y+sin(a)*radius*.22,z-.045)
        tip=(x+cos(a)*tipRadius,
             y+sin(a)*tipRadius,
             z-.14-(.035*maturity if i%2==0 else 0))
        g.leaf(petalColor if i%4 else "cream" if crop=="MoonLotus" else "gold",
               root,tip,width,.08*maturity,6,3)
    g.blob(centerColor,(x,y,z-.15),
           (.245*maturity,.245*maturity,.11*maturity),16,9)
    if crop=="Sunflower":
        # Distinct seeds on the disk, no excessive tiny triangles.
        for i in range(10):
            a=2*pi*i/10
            r=.145*maturity*(.7 if i%2 else 1.)
            g.blob("ochre",(x+cos(a)*r,y+sin(a)*r,z-.255),
                   (.029*maturity,.029*maturity,.018*maturity),7,4)
    elif crop=="Starbloom":
        g.blob("gold",(x,y,z-.27),(.082*maturity,.075*maturity,.025*maturity),10,6)


def mushroom(g, crop, stalk, radius, height):
    """Bell cap, ivory gills and rounded spots; matches the stem pivot."""
    from orchard_sculpt import loft
    x,y,z=stalk
    mat="lilac" if crop=="Moonshroom" else "blue"
    cap_height=.25*height
    r=radius
    loft(g,mat,[
        (x,y-.055*height,z,.80*r,.80*r),
        (x,y+.015*height,z,1.08*r,1.02*r),
        (x,y+.13*height,z,.89*r,.88*r),
        (x,y+.26*height,z,.42*r,.42*r),
        (x,y+.31*height,z,.035*r,.035*r),
    ],16)
    # Interior cream gill section is visible at grazing camera angles.
    loft(g,"ivory",[
        (x,y-.06*height,z,.13*r,.13*r),
        (x,y-.045*height,z,.84*r,.84*r),
        (x,y+.005*height,z,1.03*r,1.03*r),
    ],14)
    # Irregularly distributed pale cap spots are anchored above the cap.
    for i in range(5):
        a=2*pi*i/5+(.16 if crop=="Moonshroom" else 0)
        xx=x+.62*r*cos(a)
        zz=z+.61*r*sin(a)
        g.blob("cream",(xx,y+.23*height,zz),
               (.07*r,.037*height,.07*r),9,5)
