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
        tube("bark",[(0,0,0),(.08,1.54,0),(-.08,3.11,0),(0,3.61,0)],
            [.40,.35,.25,.17])
        # broad irregular painterly canopy, layered light/warm green clumps.
        for i in range(14):
            a=2*pi*i/14
            x=cos(a)*(1.27+(i%3)*.18)
            z=sin(a)*(1.24+(i%4)*.13)
            y=3.59+(i%5)*.29
            if i%3==0:
                tube("bark",[(0,2.72,0),(x*.63,3.19,z*.64),
                    (x*.88,y-.27,z*.79)],[.16,.12,.08])
            b("leaflight" if i%3==0 else "leaf",
              (x,y,z),(.93,1.02,.96),15,9)
        for i in range(13):
            a=i*2.39996
            x=sin(a)*1.73;z=cos(a)*1.60
            p=(x,3.39+(i%5)*.34,z-.53)
            b("orange",p,(.29,.31,.29),13,8)
            lf("leafdeep",(x, p[1]+.30,p[2]),
                (x+.35,p[1]+.38,p[2]),.16)
        for i in range(6):
            a=i*2*pi/6
            lf("leafdeep",(0,.30,0),
               (sin(a)*.66,.73,cos(a)*.61),.24)
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
        # Original little garden helper: recognizable bill and a light-blue cap.
        b("ink",(0,1.02,.15),(.71,1.05,.61),19,13)
        b("ink",(0,2.02,-.23),(.76,.76,.71),20,12)
        b("ivory",(0,.94,-.45),(.48,.67,.18),14,9)
        for side in (-1,1):
            b("chocolate",(side*.39,2.18,-.80),(.20,.24,.07),14,8)
            b("gold",(side*.39,2.18,-.86),(.075,.12,.05),11,7)
            lf("ink",(side*.63,1.42,.35),
               (side*.99,.94,.80),.29)
        # beak: tapered orange bill attached to face and projecting forward
        tube("straw",[(0,1.97,-.73),(.24,1.96,-1.28),
                      (.46,1.84,-1.87)],[.40,.32,.09])
        b("blue",(0,2.71,-.28),(.87,.24,.78),20,9)
        b("blue",(0,2.50,-.87),(.76,.115,.38),17,7)
        for side in (-1,1):
            tube("orange",[(side*.40,.20,.32),
                           (side*.40,.04,.05)],[.11,.07])
        b("white",(.18,2.79,-.77),(.14,.045,.09),10,5)
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
