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
        # Front and rear gables meet the roof underside. Build outward faces
        # on both ends so the upper storey also reads from the orchard side.
        half, length, eave, peak=2.40,2.15,2.72,4.22
        for side in (-1,1):
            wall=[(side*half,.08,-length),(side*half,eave,-length),
                  (side*half,eave,length),(side*half,.08,length)]
            g.quad("cream",*(wall if side==1 else wall[::-1]))
            z=side*length
            face=[(-half,.08,z),(half,.08,z),(half,eave,z),(-half,eave,z)]
            g.quad("ivory",*(face if side==1 else face[::-1]))
            gable=[(-half,eave,z),(half,eave,z),(0,peak,z)]
            g.tri("cream",*(gable if side==1 else gable[::-1]))
            for x in (-2.25,2.25):
                beam("wood",[(x,.08,z*1.01),(x,2.82,z*1.01)],.105)

        def wall_flower(at, pink, scale):
            # Five folded, broad petals face the garden path. Their curved
            # edges read in silhouette without tessellating a full leaf grid.
            x,y,z=at
            for i in range(5):
                a=i*2*pi/5
                u,v=cos(a),sin(a)
                def petal_point(along,across,depth):
                    return (x+scale*(along*u-across*v),y+scale*(along*v+across*u),z+scale*depth)
                outline=[petal_point(t,w,d) for t,w,d in (
                    (.015,0,0),(.08,-.052,-.025),(.15,-.06,-.055),
                    (.19,-.028,-.060),(.19,.028,-.060),(.15,.06,-.055),(.08,.052,-.025))]
                fold=petal_point(.11,0,-.068)
                for j,edge in enumerate(outline):
                    g.tri("pink" if pink else "cream",fold,outline[(j+1)%len(outline)],edge)
            g.blob("gold",(x,y,z-.030*scale),(.046*scale,.046*scale,.034*scale),8,4)
        from orchard_sculpt import loft
        for side in (-1,1):
            x=side*2.43
            pane=[(x,1.05,-.77),(x,2.12,-.77),(x,2.12,.77),(x,1.05,.77)]
            g.quad("gold",*(pane if side==1 else pane[::-1]))
            for a,bp in zip(pane,pane[1:]+pane[:1]):
                beam("bark",[a,bp],.070)
            beam("wood",[(x,1.05,0),(x,2.12,0)],.052)
            beam("wood",[(x,1.64,-.77),(x,1.64,.77)],.045)
            for j in (-1,0,1):
                z=j*.54
                loft(g,"brick",[(side*2.62,.79,z,.14,.19),(side*2.62,1.01,z,.22,.25),
                     (side*2.62,1.07,z,.22,.25)],10)
                for k in range(5):
                    a=k*2*pi/5
                    lf("leaflight" if k%2 else "leaf",(side*2.62,1.02,z),
                       (side*(2.66+.19*cos(a)),1.26+.11*sin(a),z+.23*sin(a)),.078,.05)
                wall_flower((side*2.76,1.22,z-.04),pink=j==0,scale=.68)

        # Each course laps the one below. The rounded, cambered tile noses
        # project beyond the eaves and cast a scalloped shadow onto the wall.
        for side in (-1,1):
            def roof(run,z,lift=0):
                return (side*run,4.39-.62*run+lift,z)
            backing=[roof(.0,-2.53),roof(.0,2.53),roof(2.83,2.53),roof(2.83,-2.53)]
            g.quad("brick",*(backing if side==1 else backing[::-1]))
            for row in range(5):
                start=row*.56
                for col in range(8):
                    z0=max(-2.55,-2.55+(col-.5*(row%2))*.73)
                    z1=min(2.55,-2.55+(col+1-.5*(row%2))*.73)
                    if z1<=z0: continue
                    strip=[]
                    for i in range(7):
                        t=i/6
                        z=z0+(z1-z0)*t
                        bow=sin(pi*t)
                        strip.append((roof(start,z,.06+.022*bow),
                                      roof(start+.57+.13*bow,z,.12+.042*bow),
                                      roof(start+.57+.13*bow,z,.045+.032*bow)))
                    tone=("brick","rose","brick","blush")[(3*row+col)%4]
                    for a,c in zip(strip,strip[1:]):
                        top=[a[0],c[0],c[1],a[1]]
                        lip=[a[1],c[1],c[2],a[2]]
                        g.quad(tone,*(top if side==1 else top[::-1]))
                        g.quad("brick",*(lip if side==1 else lip[::-1]))
            beam("wood",[roof(0,-2.55,-.035),roof(2.84,-2.55,-.035)],.088)
        beam("brick",[(0,4.43,-2.57),(0,4.43,2.57)],.115)

        # Front door planks are cut to the same semicircle as the timber jamb.
        radius=.62
        spring=1.43
        for j in range(7):
            x0=-radius+j*2*radius/7
            x1=x0+2*radius/7-.012
            def door_y(x):
                return spring+max(0,radius**2-x**2)**.5
            g.quad("wood" if j%3==0 else "bark",(x0,.08,-2.22),
                   (x0,door_y(x0),-2.22),(x1,door_y(x1),-2.22),(x1,.08,-2.22))
        arch=[(-radius,.08,-2.25)]
        for j in range(17):
            a=pi*(1-j/16)
            arch.append((radius*cos(a),spring+radius*sin(a),-2.25))
        arch.append((radius,.08,-2.25))
        beam("brown",arch,.078)
        attic=(0,3.16,-2.19)
        b("gold",attic,(.365,.39,.048),18,10)
        rim=[(.38*cos(i*pi/12),3.16+.40*sin(i*pi/12),-2.239) for i in range(25)]
        beam("wood",rim,.049)
        beam("wood",[(0,2.78,-2.255),(0,3.54,-2.255)],.035)
        beam("wood",[(-.35,3.16,-2.255),(.35,3.16,-2.255)],.035)
        for side in (-1,1):
            b("gold",(side*1.58,1.67,-2.23),(.46,.52,.07),15,8)
            beam("wood",[(side*1.58,1.18,-2.34),
                         (side*1.58,2.15,-2.34)],.045)
            beam("wood",[(side*1.15,1.66,-2.35),
                         (side*2.00,1.66,-2.35)],.045)
            b("brick",(side*2.03,.39,-2.73),(.35,.34,.32),12,7)
            for j in range(4):
                a=j*pi/2
                wall_flower((side*2.02+sin(a)*.23,.67+cos(a)*.20,-2.75),
                        pink=j%2==0,scale=.60)
        b("gold",(.42,1.18,-2.31),(.09,.10,.10),9,6)
        loft(g,"brick",[(1.29,3.32,.88,.36,.32),(1.29,4.68,.88,.32,.29),
             (1.29,4.73,.88,.41,.37),(1.29,4.88,.88,.41,.37)],8)
        b("chocolate",(1.29,4.889,.88),(.25,.014,.22),12,4)
        for i in range(7):
            p=(-.42+i*.41,.07,-3.04-i*.36)
            b("stone",p,(.42,.11,.33),13,7)
        vine=[(-1.02,.16,-2.33),(-1.16,.72,-2.34),(-.95,1.41,-2.35),
              (-.94,2.07,-2.35),(-.66,2.49,-2.34),(-.22,2.62,-2.31)]
        g.tube("leafdeep",vine,[.052,.046,.04,.031,.025,.013],7)
        for j,(a,bp) in enumerate(zip(vine,vine[1:])):
            for k in range(4):
                t=k/4
                x,y,z=(u*(1-t)+v*t for u,v in zip(a,bp))
                sign=1 if k%2 else -1
                lf("leaf" if (k+j)%3 else "leaflight",(x,y,z),
                   (x+sign*.25,y-.095+.10*(k%2),z-.16),.117,.060)
            if j%2: wall_flower((a[0],a[1]+.10,-2.50),True,.86)
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
        from orchard_sculpt import monster
        return monster(S)
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
