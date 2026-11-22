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


def tomato_vine(g, stage):
    """Single rooted vine with compound leaves and hanging fruit trusses."""
    from generate_reference_glb import cross, norm, sub

    def blade(root, angle, length, width, drop, pigment):
        u,v=cos(angle),sin(angle)
        rows=[]
        for t,w in ((0,.03),(.23,.67),(.31,.48),(.49,1),(.57,.69),
                    (.73,.81),(.82,.44),(1,.018)):
            x=root[0]+u*length*t
            y=root[1]+length*.20*sin(pi*t)+drop*t
            z=root[2]+v*length*t
            w*=width
            rows.append([(x-w*v,y-.24*w,z+w*u),(x,y+.17*w,z),
                         (x+w*v,y-.31*w,z-w*u)])
        for lo,hi in zip(rows,rows[1:]):
            for k in (0,1):
                g.quad(pigment,lo[k],hi[k],hi[k+1],lo[k+1])

    def spray(root, angle, scale, light):
        u,v=cos(angle),sin(angle)
        x,y,z=root
        nodes=[(x+u*scale*t,y+scale*(.22*sin(pi*t)-.08*t),z+v*scale*t)
               for t in (0,.32,.62,1)]
        g.tube("leafdeep",nodes,[scale*w for w in (.034,.028,.017,.008)],6)
        for j in (1,2):
            for side in (-1,1):
                blade(nodes[j],angle+side*(1.02 if j==1 else .88),
                      scale*(.54 if j==1 else .43),scale*.18,-scale*.14,
                      "leaflight" if light and side==1 else "leaf")
        blade(nodes[3],angle+.10,scale*.49,scale*.21,-scale*.17,
              "leaflight" if light else "leaf")

    def flower(center, angle, scale):
        x,y,z=center
        for i in range(5):
            a=angle+2*pi*i/5
            g.leaf("dandelion",center,(x+.15*scale*cos(a),
                   y+.11*scale*sin(a)+.035*scale,z+.12*scale*sin(a)),
                   .048*scale,.028*scale,4,2)
        g.blob("gold",(x,y+.025*scale,z-.015*scale),(.043*scale,)*3,8,4)

    def fruit(center,radius,pigment,phase):
        # A recessed stem scar and shallow radial ribs form a beefsteak tomato.
        # The shoulder rises above the stalk insertion. Normals follow that fold.
        profile=[(-.78,.035),(-.74,.38),(-.54,.75),(-.18,.98),
                 (.19,1.02),(.48,.84),(.62,.55),(.58,.28),(.49,.045)]
        def surface(j,a):
            h,r=profile[j]
            shoulder=(h+.8)/1.45
            lobe=cos(5*a+phase)
            reach=radius*r*(1+.075*lobe*(.4+.6*shoulder))
            return (center[0]+reach*cos(a),center[1]+radius*(h+.054*lobe*r*shoulder),
                    center[2]+reach*sin(a))
        sides=20
        rows=[]
        for j in range(len(profile)):
            row=[]
            for i in range(sides):
                a=i*2*pi/sides
                rise=sub(surface(min(j+1,len(profile)-1),a),surface(max(j-1,0),a))
                tangent=sub(surface(j,a+.015),surface(j,a-.015))
                row.append((surface(j,a),norm(cross(rise,tangent))))
            rows.append(row)
        for lo,hi in zip(rows,rows[1:]):
            for i in range(sides):
                k=(i+1)%sides
                points,normals=zip(lo[i],hi[i],hi[k],lo[k])
                g.quad(pigment,*points,vertex_normals=normals)
        for j in (0,-1):
            middle=(center[0],center[1]+radius*profile[j][0],center[2])
            for i in range(sides):
                a,b=rows[j][i][0],rows[j][(i+1)%sides][0]
                g.tri(pigment,middle,*( (a,b) if j==0 else (b,a) ))
        x,y,z=center
        scar=(x,y+.58*radius,z)
        for i in range(6):
            a=phase+2*pi*i/6
            g.leaf("leafdeep",scar,(x+.83*radius*cos(a),y+.51*radius,
                   z+.83*radius*sin(a)),.14*radius,.15*radius,4,2)
        return scar

    height=(.52,1.38,2.06)[stage-1]
    def spine(t):
        return (.12*sin(t*5)*height,height*t,.09*sin(t*3)*height)
    g.tube("leafdeep",[spine(t) for t in (0,.20,.42,.66,.84,1)],
           [height*w for w in (.045,.041,.036,.030,.022,.010)],8)
    if stage==1:
        for side in (-1,1):
            g.leaf("leaflight",spine(.39),(side*.31,.27,side*.10),.105,.045,5,3)
        spray(spine(.72),-1.11,.29,False)
        spray(spine(.94),2.03,.26,True)
        return

    # Staked fruit is visible below the leaf fans. One loop holds the leader.
    stake=(-.19,0,.12)
    g.tube("bark",[stake,(stake[0],height*1.02,stake[2]),
           (stake[0],height*1.07,stake[2])],[.050,.049,.012],7)
    x,y,z=spine(.62)
    g.tube("straw",[(x+.042,y,z),(x,y,z-.056),(-.22,y+.03,.070),
           (-.23,y+.05,.147),(-.16,y+.04,.17),(x+.042,y,z)], [.015]*6,5)
    for j in range(5 if stage==2 else 8):
        t=.25+.72*j/(4 if stage==2 else 7)
        spray(spine(t),j*2.39996+.13,(.55 if stage==2 else 1.02)*(1-.18*t),j%3==0)
    for j in range(2 if stage==2 else 4):
        a=-1.28+j*2.39996
        u,v=cos(a),sin(a)
        root=spine(.47+.14*j)
        reach=.43 if stage==2 else .78
        x,y,z=root
        fork=(x+reach*.69*u,y+.13,z+reach*.69*v)
        tip=(x+reach*u,y+.09,z+reach*v)
        g.tube("leafdeep",[root,fork,tip],[.041,.029,.018],7)
        for k in range(1 if stage==2 else 2):
            offset=(-.24 if k==0 else .32)*(1 if stage==3 else .65)
            radius=(.16 if stage==2 else .255+.041*((j+k)%2))
            center=(tip[0]-v*offset+u*.11*k,tip[1]-.29-radius*.45-.14*k,
                    tip[2]+u*offset+v*.11*k)
            scar=fruit(center,radius,"leaflight" if stage==2 else "red",a+.41*k)
            bend=(scar[0]-.028*u,scar[1]+.095,scar[2]-.028*v)
            shoulder=((tip[0]+bend[0])*.5,tip[1]-.045,(tip[2]+bend[2])*.5)
            g.tube("leafdeep",[tip,shoulder,bend,scar],[.021,.019,.017,.014],6)
        if stage==2 or j%2==1:
            bloom=(fork[0]-.19*v,fork[1]+.13,fork[2]+.19*u)
            g.tube("leaf",[fork,bloom],[.017,.010],5)
            flower(bloom,a,.8 if stage==2 else 1)
