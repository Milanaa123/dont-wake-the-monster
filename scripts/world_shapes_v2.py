"""Original, editable stylized farm world meshes inspired by soft cozy gardening.
No photo wrapping, image generation, or borrowed mesh assets.
"""
from math import sin,cos,pi
import random

ASSET_NAMES=("OrangeTree","WoodFence","GardenCottage","StonePath",
             "WaterPond","SleepingMonster","GardenerToucan","BloomingHedge")

def sculpt_world(name,S):
    g=S("Environment_"+name)
    def b(mat,p,r,s=14,rings=8):
        g.blob(mat,p,r,s,rings,.055 if mat in ("leaf","leaflight") else .006)
    def tube(mat,pts,r):
        g.tube(mat,pts,r,8)
    def beam(mat,pts,r):
        g.tube(mat,pts,[r]*len(pts),6)
    def lf(mat,a,pt,w,curve=.13):
        g.leaf(mat,a,pt,w,curve,6,4)
    def blossom(at,pink=False,scale=1):
        for j in range(5):
            a=j*2*pi/5
            lf("pink" if pink else "cream",at,
               (at[0]+sin(a)*.19*scale,at[1]+cos(a)*.18*scale,
                at[2]-.05*scale),.085*scale)
        b("gold",(at[0],at[1],at[2]-.08*scale),
          (.065*scale,.065*scale,.05*scale),9,6)
    if name=="OrangeTree":
        # Reference-style citrus: the crown is a mass of overlapping
        # irregular, angular leaves, not a pile of green ellipsoids.
        rng=random.Random(4129)
        tube("bark",[(0,0,0),(.06,1.60,0),(-.07,3.11,0),(.05,3.70,0)],
            [.37,.34,.24,.12])
        for i in range(6):
            a=2*pi*i/6
            x=cos(a)*1.68; z=sin(a)*1.62
            tube("bark",[(0,2.39,0),(x*.51,3.12,z*.47),
                (x*.90,3.83+(i%3)*.24,z*.86)],[.17,.12,.052])
        # Low-detail inner mass creates depth, cards form the detailed surface.
        for i in range(5):
            a=2*pi*i/5
            center=(cos(a)*.90,4.00+(i%3)*.19,sin(a)*.91)
            b("leafdeep" if i%2 else "leaf",
              center,(1.43,1.05,1.40),12,7)
        b("leaf",(0,4.50,.0),(1.63,1.05,1.62),14,8)
        # A fixed-seed cloud of individual leaf planes, facing many directions.
        # doubleSided material allows one surface per leaf at half the draw cost.
        for i in range(520):
            a = i*2.399963229728653
            ty=rng.uniform(-.87,.99)
            ring=(1-ty*ty)**.50
            radial=2.04+rng.uniform(-.31,.48)
            x=cos(a)*ring*radial
            z=sin(a)*ring*radial
            y=4.12+ty*1.43+rng.uniform(-.16,.16)
            leaflen=rng.uniform(.25,.62)
            leafw=rng.uniform(.12,.32)
            tilt=rng.uniform(-.55,.64)
            # Stable jagged silhouette and dappled colors, broad leaves in
            # the foreground, smaller clipped leaves behind fruit.
            dx=cos(a)*leaflen*.6
            dz=sin(a)*leaflen*.6
            root=(x-dx*.43,y-leaflen*.35,z-dz*.43)
            left=(x+sin(a)*leafw,y+tilt*.16,z-cos(a)*leafw)
            right=(x-sin(a)*leafw,y-tilt*.16,z+cos(a)*leafw)
            tip=(x+dx,y+leaflen*.47+tilt*.12,z+dz)
            col=("leaflight" if i%7==0 else
                 "leafdeep" if i%5==0 else
                 "lime" if i%9==0 else "leaf")
            g.tri(col,root,left,tip)
            g.tri(col,root,tip,right)
        # Large golden fruit must sit in front of foliage and read clearly
        # from the game camera. Each has a stalk and a little pointed leaf.
        for i in range(17):
            a=i*2.399963
            nx=sin(a)*1.69
            nz=cos(a)*1.73
            p=(nx,3.60+(i%5)*.37,nz-.60)
            b("orange",p,(.26+(i%3)*.025,.29,.26),13,8)
            tube("bark",[(p[0],p[1]+.26,p[2]),
                (p[0]+.06,p[1]+.45,p[2]+.07)],[.042,.028])
            lf("leafdeep",(p[0],p[1]+.35,p[2]),
                (p[0]+.36,p[1]+.46,p[2]-.03),.15)
        for i in range(8):
            a=i*2*pi/8
            lf("leafdeep",(0,.30,0),
               (sin(a)*.83,.78,cos(a)*.72),.24)
    elif name=="WoodFence":
        for x in (-2.60,0,2.60):
            beam("wood",[(x,0,0),(x,1.60,0)],.15)
            b("cream",(x,1.62,0),(.23,.12,.23),10,6)
        for y in (.64,1.20):
            beam("bark",[(-2.75,y,0),(2.75,y,0)],.095)
        for i in range(5):
            a=i*pi/5
            blossom((-.9+i*.42,.30,-.21),pink=i%2==0,scale=.6)
    elif name=="GardenCottage":
        # A tiny hand-built cottage with an arched door, tile roof, terrace,
        # lantern windows, pots, ivy and grounded front stones.
        def quad(m,a,c,d,e):g.quad(m,a,c,d,e)
        y0=.1; half=2.4; length=2.15
        for sx in (-1,1):
            quad("cream",(sx*half,y0,-length),
                 (sx*half,2.75,-length),
                 (sx*half,2.75,length),(sx*half,y0,length))
        for sz in (-1,1):
            quad("ivory",(-half,y0,sz*length),
                 (half,y0,sz*length),(half,2.75,sz*length),
                 (-half,2.75,sz*length))
        for side in (-1,1):
            quad("slate",(0,4.26,-2.51),(0,4.26,2.51),
                 (side*2.79,2.56,2.51),(side*2.79,2.56,-2.51))
            for n in range(6):
                sz=-2.35+n*.89
                beam("slate",[(0,4.22,sz),(side*2.79,2.54,sz)],.053)
        for x in (-2.25,2.25):
            for z in (-2.02,2.02):
                beam("wood",[(x,.09,z),(x,2.85,z)],.14)
        # visible front face along -Z
        quad("brown",(-.68,.07,-2.20),(.68,.07,-2.20),
             (.68,2.07,-2.20),(-.68,2.07,-2.20))
        for side in (-1,1):
            b("gold",(side*1.58,1.67,-2.23),(.46,.52,.07),15,8)
            beam("wood",[(side*1.58,1.18,-2.34),
                         (side*1.58,2.15,-2.34)],.045)
            beam("wood",[(side*1.15,1.66,-2.35),
                         (side*2.00,1.66,-2.35)],.045)
            b("brick",(side*2.03,.39,-2.73),(.35,.34,.32),12,7)
            for j in range(4):
                a=j*pi/2
                blossom((side*2.02+sin(a)*.23,.67+cos(a)*.20,-2.75),
                        pink=j%2==0,scale=.60)
        b("gold",(.42,1.18,-2.31),(.09,.10,.10),9,6)
        beam("brick",[(1.29,3.32,.88),(1.29,4.82,.88)],.42)
        for i in range(7):
            p=(-.42+i*.41,.07,-3.04-i*.36)
            b("stone",p,(.42,.11,.33),13,7)
        # greenery climbing around the arch and the roofline
        for i in range(8):
            a=i*pi/8
            p=(-1.11+sin(a)*.29,1.27+cos(a)*1.12,-2.37)
            b("leaflight" if i%2 else "leaf",p,(.28,.29,.27),11,7)
            if i%3==0: blossom((p[0],p[1]+.15,p[2]-.22),True,.70)
    elif name=="StonePath":
        for i in range(8):
            x=sin(i*1.31)*.17;z=i*1.45
            b("stone",(x,.03,z),(.90,.13,.73),16,8)
            if i%2==0:
                for j in range(3):
                    a=i+j*2.4
                    lf("leaflight",(x+.8,.13,z),
                       (x+.8+sin(a)*.34,.27,z+cos(a)*.31),.13)
    elif name=="WaterPond":
        b("stone",(0,0,0),(3.19,.16,2.48),28,7)
        b("water",(0,.11,0),(2.82,.08,2.14),26,6)
        for i in range(12):
            a=i*2*pi/12
            b("stone",(sin(a)*2.96,.18,cos(a)*2.20),
              (.38,.24,.40),11,7)
        for i in range(4):
            a=i*2*pi/4
            p=(sin(a)*1.32,.22,cos(a)*.93)
            b("leafdeep",p,(.47,.044,.43),14,6)
            if i%2==0:
                blossom((p[0]+.11,.30,p[2]-.27),pink=True,scale=.73)
    elif name=="SleepingMonster":
        b("lavender",(0,2.25,.42),(2.49,2.25,2.16),23,14)
        b("lilac",(0,3.95,-1.14),(2.26,2.03,1.88),24,14)
        b("rose",(0,2.18,-1.38),(1.45,1.52,.30),18,10)
        for side in (-1,1):
            b("lilac",(side*2.36,2.79,-.37),(.85,1.18,.98),17,10)
            b("lavender",(side*1.55,.72,-.77),(.93,.44,.98),15,10)
            lf("pink",(side*1.26,5.29,-1.08),
              (side*1.53,6.45,-1.13),.59)
            b("pink",(side*1.21,3.44,-2.79),(.42,.24,.12),12,7)
            beam("chocolate",[(side*.54,4.16,-2.86),
                              (side*1.29,4.12,-2.85)],.075)
        b("pink",(0,3.45,-2.89),(.29,.20,.14),12,7)
        tube("chocolate",[(-.32,3.14,-2.84),(0,3.05,-2.89),
                          (.32,3.14,-2.84)],[.042,.045,.037])
        for i in range(12):
            a=i*pi/11
            b("leaf" if i%3 else "leaflight",
              (cos(a)*1.52,5.73+sin(a)*.25,-1.22),
              (.40,.31,.44),11,7)
    elif name=="GardenerToucan":
        # Small black garden companion: blue cap, pale grey beak and a large
        # golden circular eyering like the user's styling reference.
        b("ink",(0,1.08,.14),(.72,1.02,.71),20,13)
        b("black",(0,1.98,-.20),(.78,.79,.75),21,14)
        b("chocolate",(0,.72,-.55),(.47,.57,.22),13,9)
        for side in (-1,1):
            # Eye rings are real narrow circular mesh tubes, not yellow dots.
            a = 0
            ring=[]
            for j in range(17):
                ang = j*2*pi/16
                ring.append((side*.43 + cos(ang)*.245,
                            2.18 + sin(ang)*.25,-.875))
            g.tube("gold",ring,[.065]*len(ring),6)
            b("ink",(side*.43,2.18,-.92),(.17,.18,.07),13,8)
            b("shine",(side*.37,2.26,-.984),(.05,.06,.018),10,6)
            lf("ink",(side*.62,1.49,.37),
               (side*1.06,.98,.84),.27)
            tube("orange",[(side*.39,.22,.32),
                           (side*.39,.035,.04)],[.10,.063])
        # Bulbous but tapered grey beak, with smooth curves and a subtle seam.
        tube("stone",[(0,1.88,-.68),(.10,1.86,-1.31),
                       (.23,1.73,-1.85)],[.43,.32,.11])
        tube("chocolate",[(.08,1.63,-1.21),
                           (.21,1.64,-1.73)],[.021,.013])
        # Curved blue cap, cream embroidered tiny leaf, and sunlit visor.
        b("blue",(0,2.67,-.25),(.83,.27,.79),20,9)
        b("sky",(0,2.49,-.85),(.70,.09,.39),17,7)
        lf("white",(.10,2.79,-.64),(.38,2.85,-.64),.12,.025)
        tube("ink",[(0,1.10,.72),(.21,.78,1.23),(.39,.55,1.57)],
             [.24,.15,.032])
    elif name=="BloomingHedge":
        rng=random.Random(19)
        for i in range(14):
            x=rng.uniform(-2.5,2.5);z=rng.uniform(-.55,.55)
            y=rng.uniform(.57,1.36)
            b("leaflight" if i%4==0 else "leaf",
              (x,y,z),(.72,.60,.73),13,8)
            if i%2==0:
                blossom((x,y+.40,z-.49),pink=i%3==0,scale=.98)
        for i in range(8):
            a=i*2*pi/8
            lf("leafdeep",(0,.27,0),
                (sin(a)*2.12,.63,cos(a)*.55),.31)
    return g
