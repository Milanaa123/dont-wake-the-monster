"""Compact, recognizable 3-D sweet corn and pepper plants for Roblox.

Replaces two crops that previously shared the generic wheat/tomato sculpts.
Designed for a softly rounded storybook garden, not a flat image atlas.
"""
from math import cos, pi, sin


def sweetcorn(g, stage):
    assert stage in (1, 2, 3)
    from orchard_sculpt import loft
    scale=(.48,.75,1.)[stage-1]
    stalks=(2,3,4)[stage-1]
    for i in range(stalks):
        a=i*2.39996323
        x=.57*scale*cos(a)
        z=.57*scale*sin(a)
        h=(1.34+(i%3)*.15)*scale
        # Stepped tapered stems: the dense broad leaves define the plant.
        g.tube("leafdeep",[(x,.04,z),(x+.02,h*.56,z),
               (x+.075,h,z-.04)], [.091*scale,.072*scale,.027*scale],7)
        for j in range(5 if stage==3 else 4 if stage==2 else 3):
            angle=a+j*2.4
            y=h*(.25+.14*j)
            length=(.75+.09*(j%2))*scale
            start=(x,y,z)
            tip=(x+cos(angle)*length,
                 y+.28*scale+.09*scale*(j%2),
                 z+sin(angle)*length*.84)
            g.leaf("leaflight" if j%4==0 else "leaf",start,tip,
                   .24*scale,.08*scale,6,3)
        if stage==1 or i==3:
            continue
        # A young ear is green with folded husks. A ripe cob is golden and
        # exposes small raised kernels, bounded to the mobile triangle budget.
        cx=x+(.22 if i%2==0 else -.22)*scale
        cy=h*.60
        cz=z-.20*scale
        r=.175*scale
        color="leaflight" if stage==2 else "dandelion"
        loft(g,color,[
            (cx,cy-.38*scale,cz,.025*r,.025*r),
            (cx,cy-.31*scale,cz,.70*r,.70*r),
            (cx,cy-.09*scale,cz,1.02*r,.97*r),
            (cx,cy+.15*scale,cz,.94*r,.91*r),
            (cx,cy+.35*scale,cz,.59*r,.57*r),
            (cx,cy+.43*scale,cz,.045*r,.045*r),
        ],12)
        # Long pointed sheath hugs the cob and reveals the center.
        for side in (-1,1):
            g.leaf("leafdeep" if i%2 else "leaf",
                   (cx+side*.12*scale,cy-.31*scale,cz+.04*scale),
                   (cx+side*.19*scale,cy+.24*scale,cz+.13*scale),
                   .14*scale,.035*scale,5,2)
        if stage==3:
            # Simple raised, matte kernels (6 x 7) instead of hundreds of
            # spherical balls. All fit the same compact harvested ear.
            for tier in range(7):
                yy=cy+(-.28+.095*tier)*scale
                taper=sin(pi*(tier+1)/9)**.6
                for column in range(6):
                    b=2*pi*(column+.5*(tier%2))/6
                    rr=r*.99*taper
                    g.blob("gold" if (tier+column)%5 else "straw",
                           (cx+cos(b)*rr,yy,cz+sin(b)*rr),
                           (.047*scale,.050*scale,.047*scale),5,3)
            # Distinct curly corn silk extends over the upper husk.
            g.tube("straw",[
                (cx,cy+.42*scale,cz),
                (cx+.075*scale,cy+.56*scale,cz-.05*scale),
                (cx+.12*scale,cy+.61*scale,cz-.09*scale)
            ],[.019*scale,.012*scale,.003*scale],5)


def bell_pepper(g, stage):
    assert stage in (1,2,3)
    scale=(.50,.76,1.)[stage-1]
    stems=(2,3,4)[stage-1]
    for i in range(stems):
        a=i*2.39996323
        x=.67*scale*cos(a)
        z=.62*scale*sin(a)
        height=(1.18+(i%2)*.18)*scale
        stem=[(x,.06,z),(x+.04*scale,height*.58,z-.03*scale),
              (x+.09*scale,height,z-.11*scale)]
        g.tube("leafdeep",stem,[.085*scale,.068*scale,.033*scale],7)
        for j in range(4):
            b=a+j*pi/2
            start=(x+.03*scale,height*(.42+.12*(j%2)),z)
            tip=(x+.03*scale+cos(b)*(.66+.10*(j%2))*scale,
                 start[1]+.21*scale,
                 z+sin(b)*.63*scale)
            g.leaf("leaflight" if j==0 else "leaf",start,tip,
                   .235*scale,.08*scale,6,3)
        if stage==1:
            # Unopened seedlings carry small cream blossoms, not peppers.
            center=(x,height+.06*scale,z-.12*scale)
            for j in range(5):
                b=2*pi*j/5
                g.leaf("cream",center,
                       (center[0]+cos(b)*.13*scale,
                        center[1]+sin(b)*.14*scale,
                        center[2]-.04*scale),
                       .065*scale,.018,4,2)
            g.blob("gold",(center[0],center[1],center[2]-.05*scale),
                   (.045*scale,.044*scale,.028*scale),8,5)
            continue
        # Bell peppers are fluted and hanging; the four-lobe contour makes
        # the ripe crop immediately different from a tomato's round fruit.
        cx=x+.15*scale*cos(a)
        cy=height*.59
        cz=z-.31*scale
        h=.31*scale
        rings=[
            ( .87*h,.055*scale),
            ( .64*h,.18*scale),
            ( .23*h,.275*scale),
            (-.42*h,.278*scale),
            (-.86*h,.21*scale),
            (-1.08*h,.075*scale),
        ]
        sides=16
        shade="orange" if stage==3 else "leaflight"
        for band in range(len(rings)-1):
            for sector in range(sides):
                a0=2*pi*sector/sides
                a1=2*pi*(sector+1)/sides
                def vertex(level, angle):
                    dy,rr=rings[level]
                    radial=rr*(1+.10*cos(4*angle))
                    return (cx+radial*cos(angle),cy+dy,
                            cz+radial*sin(angle))
                g.quad(shade,
                       vertex(band,a0),vertex(band,a1),
                       vertex(band+1,a1),vertex(band+1,a0))
        # Star-shaped calyx on top of each pepper.
        cap_center=(cx,cy+.87*h,cz)
        for j in range(5):
            b=2*pi*j/5
            g.leaf("leafdeep",cap_center,
                   (cx+.22*scale*cos(b),cy+.82*h,
                    cz+.22*scale*sin(b)),.068*scale,.015,4,2)
        g.tube("leafdeep",[(cx,cy+.85*h,cz),
               (cx+.05*scale,height*.89,cz+.07*scale)],
               [.035*scale,.016*scale],6)
