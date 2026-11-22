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
        centerColor="bark"  # warm honey-brown, not an oversized black disk
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
            g.blob("chocolate",(x+cos(a)*r,y+sin(a)*r,z-.255),
                   (.027*maturity,.027*maturity,.013*maturity),7,4)
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


def strawberry(g, center, size, pigment, ripe):
    """Pendulous receptacle with inset crown and seeds seated on its own profile."""
    from generate_reference_glb import norm
    x,y,z=center
    profile=((-.36,.025),(-.28,.13),(-.15,.22),(.03,.29),(.16,.30),
             (.245,.25),(.28,.16),(.245,.032))
    sides=14

    def point(level, radius, angle):
        return (x+size*radius*cos(angle),y+size*level,z+size*radius*sin(angle))

    def corner(ring,index):
        height,r=profile[ring]
        angle=2*pi*index/sides
        low,high=profile[max(0,ring-1)],profile[min(len(profile)-1,ring+1)]
        dy,dr=high[0]-low[0],high[1]-low[1]
        return point(height,r,angle),norm((dy*cos(angle),-dr,dy*sin(angle)))

    for ring in range(len(profile)-1):
        for i in range(sides):
            corners=[corner(k,j) for k,j in ((ring,i),(ring+1,i),(ring+1,i+1),(ring,i+1))]
            points,normals=zip(*corners)
            g.quad(pigment,*points,vertex_normals=normals)
    for ring in (0,len(profile)-1):
        for i in range(sides):
            a,b=corner(ring,i)[0],corner(ring,i+1)[0]
            g.tri(pigment,point(profile[ring][0],0,0),*( (a,b) if ring==0 else (b,a) ))

    crown=point(.26,0,0)
    for i in range(6):
        angle=(i+.23)*2*pi/6
        g.leaf("leafdeep" if i%2 else "leaf",crown,point(.19,.29,angle),
               .080*size,.055*size,4,2)
    if ripe:
        for row,(height,count,band) in enumerate(((-.22,5,1),(-.08,7,2),(.07,9,3),(.19,8,4))):
            h0,r0=profile[band]
            h1,r1=profile[band+1]
            slope=(r1-r0)/(h1-h0)
            def rind(level,angle):
                return point(level,r0+slope*(level-h0)+.005,angle)
            for i in range(count):
                angle=(i+.5*(row%2))*2*pi/count
                top=rind(height+.030,angle)
                left=rind(height,angle-.073)
                right=rind(height,angle+.073)
                bottom=rind(height-.025,angle)
                g.quad("straw",top,right,bottom,left)


def strawberry_bed(g,name,stage):
    from orchard_sculpt import leaflet
    crowns=(1,3,5)[stage-1]
    scale=(.46,.76,1.)[stage-1]
    for i in range(crowns):
        angle=i*2.39996+.32
        dx,dz=cos(angle),sin(angle)
        radius=(0,.52,.85)[stage-1] if i else 0
        x,z=radius*dx,radius*dz
        root=(x,.04,z)
        if radius:
            g.tube("leafdeep",[(0,.06,0),(x*.5,.12,z*.44),root],
                   [.032,.025,.020],6)
        for j in range(4 if stage==3 else 3):
            a=angle+j*2*pi/(4 if stage==3 else 3)
            u,v=cos(a),sin(a)
            height=(.65+.10*sin(i+j*3))*scale
            tip=(x+.32*scale*u,height,z+.32*scale*v)
            g.tube("leafdeep",[root,(x+.10*scale*u,height*.67,z+.10*scale*v),tip],
                   [.032*scale,.025*scale,.018*scale],6)
            for k in (-1,0,1):
                leaflet(g,tip,a+.87*k,scale*(.55 if k==0 else .42),
                        scale*(.165 if k else .19),"leaflight" if (i+j)%3==0 else "leaf")
        if stage>=2:
            for j in range(2 if stage==3 and radius else 1):
                a=angle+(j-.5)*1.16
                u,v=cos(a),sin(a)
                s=(.69 if stage==2 else .91+.11*cos(i+j))
                fruit=(x+.55*u,.38*s+.075+.095*((i+j)%2),z+.55*v)
                g.tube("leafdeep",[root,(x+.23*u,.79*scale,z+.23*v),
                       (fruit[0]-.09*u,fruit[1]+.39*s,fruit[2]-.09*v),
                       (fruit[0],fruit[1]+.25*s,fruit[2])],
                       [.030*scale,.026*scale,.022*scale,.018*scale],6)
                pigment=("red" if name=="Berry" else "sky") if stage==3 else "pink"
                strawberry(g,fruit,s,pigment,stage==3)
        if stage>=2 and (stage==2 or i%2==0):
            bloom=(x-.24*dx,.86*scale,z-.24*dz)
            g.tube("leaf", [root,bloom],[.024*scale,.016*scale],6)
            for j in range(5):
                a=j*2*pi/5
                g.leaf("cream",bloom,(bloom[0]+.18*cos(a),bloom[1]+.030,
                       bloom[2]+.18*sin(a)),.085,.032,5,3)
            g.blob("gold",bloom,(.055,.047,.055),9,5)
