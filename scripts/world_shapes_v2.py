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
        from orchard_sculpt import rounded_sections
        rng=random.Random(4129)
        rounded_sections(g,"bark",[(0,.025,0,.57,.49),(.035,.25,.04,.405,.35),
            (.14,.76,.08,.32,.285),(.17,1.42,.10,.29,.26),
            (.02,2.05,.03,.265,.23),(-.19,2.60,-.04,.22,.195),
            (-.31,3.13,-.06,.13,.12)],16)
        for j in range(6):
            a=j*2*pi/6+.14
            u,v=cos(a),sin(a)
            g.tube("bark",[(.07,.56,.04),(.32*u,.17,.29*v),
                   (.66*u,.085,.58*v),(.86*u,.038,.80*v)],[.19,.15,.079,.018],9)

        def citrus_leaf(root,a,length,width,drop,pigment):
            u,v=cos(a),sin(a)
            rows=[]
            for t,breadth in ((0,.06),(.27,.72),(.56,1),(.78,.77),(1,.055)):
                x,y,z=root
                x+=length*t*u
                z+=length*t*v
                y+=.14*length*sin(pi*t)+drop*t
                w=width*breadth
                rows.append([(x-v*w,y-.25*w,z+u*w),(x,y+.21*w,z),
                             (x+v*w,y-.37*w,z-u*w)])
            for first,next_row in zip(rows,rows[1:]):
                for k in (0,1):
                    g.quad(pigment,first[k],next_row[k],next_row[k+1],first[k+1])

        # Vary the branch heights and leave windows through the lower crown.
        # Short sprays fan from each terminal instead of pointing out of one sphere.
        for i in range(8):
            a=i*2.399963+.35
            u,v=cos(a),sin(a)
            tier=i//4
            reach=1.34-.40*tier+.17*sin(i)
            cx,cz=reach*u,reach*v
            cy=3.24+.91*tier+.21*sin(3*i)
            branch=(-.06,1.45+.20*(i%3)+.48*tier,.04)
            tube("bark",[branch,(.38*cx,cy-.96,.38*cz),(.73*cx,cy-.59,.73*cz),
                 (cx,cy-.16,cz)],[.21-.04*tier,.17,.105,.049])
            # A low scalloped cushion seals interior gaps between the leaves.
            layers=[]
            for j,(r,h) in enumerate(((.18,-.46),(.75,-.31),(1.0,.02),(.91,.34),
                                      (.56,.57),(.12,.68))):
                row=[]
                for k in range(16):
                    azimuth=2*pi*k/16
                    lobe=1+.078*cos(5*azimuth+.44*i)+.046*sin(3*azimuth+.64*j)
                    row.append((cx+1.11*r*lobe*cos(azimuth),cy+h+.067*r*sin(3*azimuth+i),
                                cz+1.02*r*lobe*sin(azimuth)))
                layers.append(row)
            for j,(lo,hi) in enumerate(zip(layers,layers[1:])):
                for k in range(16):
                    nxt=(k+1)%16
                    g.quad("leafdeep" if j<2 else "leaf",lo[k],hi[k],hi[nxt],lo[nxt])
            for k in range(16):
                g.tri("leaf",(cx,cy+.69,cz),layers[-1][(k+1)%16],layers[-1][k])
                g.tri("leafdeep",(cx,cy-.47,cz),layers[0][k],layers[0][(k+1)%16])
            for j in range(11):
                azimuth=j*2.39996+.31*i
                ty=((j+.5)/11)*1.47-.55
                ring=(1-ty*ty)**.5
                root=(cx+.99*ring*cos(azimuth),cy+.56*ty+.055,cz+.91*ring*sin(azimuth))
                for k in (-1,1):
                    citrus_leaf(root,azimuth+.62*k+rng.uniform(-.22,.22),
                        rng.uniform(.38,.67),rng.uniform(.13,.19),rng.uniform(-.33,.055),
                        ("leaf","leaflight","lime","leaf")[(i+j+(k>0))%4])
            if i%2==0:
                flower=(cx+1.02*cos(a+.5),cy+.16,cz+.98*sin(a+.5))
                x,y,z=flower
                for j in range(5):
                    angle=j*2*pi/5
                    g.leaf("cream",flower,(x+.16*cos(angle),y+.105*sin(angle)+.041,
                           z+.11*sin(angle)),.070,.037,3,2)
                g.blob("gold",(x,y+.033,z),(.042,.042,.042),7,4)
            for j in range(2 if i%3 else 3):
                angle=a+(j-.55)*1.43
                u,v=cos(angle),sin(angle)
                x,z=cx+.83*u,cz+.78*v
                y=cy-.42+.14*sin(i+2*j)
                radius=.27+.052*((i+j)%3)
                stem=(x,y+radius*.94,z)
                g.tube("leafdeep",[(x-.22*u,y+radius+.26,z-.22*v),stem],
                       [.041,.029],7)
                g.blob("orange",(x,y,z),(radius,radius*.92,radius),11,6)
                citrus_leaf(stem,angle+.77,.34,.095,-.085,"leafdeep")
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
        rng=random.Random(211)
        for i in range(9):
            x=.23*sin(i*.82)
            z=i*1.24
            rim=[]
            yaw=rng.uniform(-.35,.35)
            for j in range(9):
                a=j*2*pi/9+yaw
                r=rng.uniform(.85,1.14)
                rim.append((1.01*r*cos(a),.60*r*sin(a)))
            rows=[[(x+dx*scale,height+.018*cos(j*2+i),z+dz*scale)
                   for j,(dx,dz) in enumerate(rim)] for scale,height in
                  ((.84,.022),(1,.069),(.92,.164),(.68,.195))]
            for k,(lo,hi) in enumerate(zip(rows,rows[1:])):
                for j in range(len(rim)):
                    n=(j+1)%len(rim)
                    g.quad("loamedge" if k==0 else "stone",lo[j],hi[j],hi[n],lo[n])
            for j in range(len(rim)):
                g.tri("stone",(x+.08,.20,z-.08),rows[-1][(j+1)%9],rows[-1][j])
                g.tri("loamedge",(x,.014,z),rows[0][j],rows[0][(j+1)%9])
            if i%2==0:
                side=1 if i%4==0 else -1
                tuft=(x+side*.78,.07,z+.35)
                for k in range(5):
                    a=k*2.39996
                    lf("leaflight" if k%2 else "leaf",tuft,
                       (tuft[0]+.22*cos(a),.23+.10*sin(k),tuft[2]+.24*sin(a)),.058,.075)
    elif name=="WaterPond":
        from pond_sculpt import garden_pond
        garden_pond(g)
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
