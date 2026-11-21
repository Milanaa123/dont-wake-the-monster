"""Distinct original 3D shapes for carrot, radish and marshmallow-root crops.

All plants preserve three playable growth stages and their original game
seed names. No flat sprites or third-party geometry.
"""
from math import cos, pi, sin
from orchard_sculpt import loft


def root_bed(g, name, stage):
    assert name in ("Carrot", "RainbowRadish", "MarshmallowRoot")
    assert stage in (1,2,3)
    scale=(.49,.72,1.)[stage-1]
    count=(2,3,5)[stage-1]
    if name=="RainbowRadish" and stage==3:
        count=4
    for i in range(count):
        a=i*2.39996323
        x=.74*scale*cos(a)
        z=.71*scale*sin(a)
        leaf_tip_y=(.84+.10*(i%2))*scale
        # Broad leafy crowns are readable from above and varied by species.
        stalk=(x,.29*scale,z)
        if stage>=2:
            shoulder_y=.47*scale
            if name=="Carrot":
                # Orange tapered cone, shoulder visible above the soil bed.
                g.tube("orange",[
                    (x,shoulder_y+.12*scale,z),
                    (x,shoulder_y-.17*scale,z),
                    (x,-.10*scale,z)
                ], [.235*scale,.17*scale,.018*scale],12)
                g.blob("ochre",(x,shoulder_y+.08*scale,z-.19*scale),
                       (.034*scale,.08*scale,.018*scale),7,5)
            elif name=="RainbowRadish":
                # A chunky rosy radish is distinct from a pointed carrot:
                # rounded swelling and a thin ivory taproot.
                loft(g,"pink",[
                    (x,.17*scale,z,.04*scale,.04*scale),
                    (x,.26*scale,z,.17*scale,.17*scale),
                    (x,.44*scale,z,.26*scale,.25*scale),
                    (x,.61*scale,z,.18*scale,.19*scale),
                    (x,.67*scale,z,.03*scale,.03*scale)
                ],13)
                g.tube("ivory",[(x,.17*scale,z),
                    (x,.035*scale,z),(x,-.15*scale,z)],
                    [.084*scale,.044*scale,.009*scale],7)
            else:
                # A distinct upright vanilla-colored marshmallow root with
                # a faint rose rim, not a recolored carrot cylinder.
                loft(g,"cream",[
                    (x,.035*scale,z,.024*scale,.024*scale),
                    (x,.13*scale,z,.17*scale,.16*scale),
                    (x,.37*scale,z,.235*scale,.22*scale),
                    (x,.60*scale,z,.20*scale,.18*scale),
                    (x,.70*scale,z,.075*scale,.07*scale),
                ],12)
                g.blob("rose",(x,.61*scale,z-.12*scale),
                       (.19*scale,.053*scale,.052*scale),10,5)
        # A ring of fresh shoots on the seedling and full leafy tops later.
        fans=(3 if stage==1 else 5 if stage==2 else 7)
        for j in range(fans):
            b=a+j*2*pi/fans
            sprout=(x,(.32+.035*(j%2))*scale,z)
            middle=(x+.11*scale*cos(b),leaf_tip_y*.70,
                    z+.11*scale*sin(b))
            tip=(x+(.34+.055*(j%3))*scale*cos(b),
                 leaf_tip_y+(.10 if j%3==0 else -.04)*scale,
                 z+(.33+.045*(j%3))*scale*sin(b))
            g.tube("leafdeep",[sprout,middle,tip],
                   [.033*scale,.020*scale,.006*scale],5)
            # Radishes have broad rounded leaves; carrot fronds are light
            # feathery; fairy marshmallow-roots have mint pointed leaves.
            width=(.21 if name=="RainbowRadish" else
                   .11 if name=="Carrot" else .17)*scale
            mat=("mint" if name=="MarshmallowRoot" else
                 "leaflight" if j%3==0 else "leaf")
            g.leaf(mat,middle,tip,width,.095*scale,5,3)
            if name=="Carrot" and stage>=2:
                # A second little leaflet gives airy, fern-like carrot greens.
                tip2=(middle[0]+cos(b+.72)*.28*scale,
                      middle[1]+.18*scale,
                      middle[2]+sin(b+.72)*.26*scale)
                g.leaf("leaflight" if j%2 else "leaf",
                       middle,tip2,.074*scale,.045,4,2)
        if stage==1:
            # Tiny cotyledons show that there is no ripe root yet.
            for k in (-1,1):
                g.leaf("leaflight",stalk,
                       (x+k*.22*scale,.50*scale,z-.09*scale),
                       .11*scale,.04,4,2)
