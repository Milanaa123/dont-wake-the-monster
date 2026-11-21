"""Authored silhouettes for Giggles and the foreground food crops (Y up, -Z forward)."""
from math import cos, sin, pi, sqrt


def loft(g, mat, rings, sides=20):
    """Horizontal elliptical sections. Each ring supplies x, y, z, radius X/Z."""
    points = [[(x + rx*cos(i*2*pi/sides), y, z + rz*sin(i*2*pi/sides))
               for i in range(sides)] for x, y, z, rx, rz in rings]
    for a, b in zip(points, points[1:]):
        for i in range(sides):
            j = (i+1) % sides
            g.quad(mat, a[i], b[i], b[j], a[j])
    for edge, lower in ((points[0], True), (points[-1], False)):
        middle = tuple(sum(p[k] for p in edge)/sides for k in range(3))
        for i in range(sides):
            a,b = edge[i],edge[(i+1)%sides]
            g.tri(mat, middle, a if lower else b, b if lower else a)


def monster(S):
    g = S("Environment_SleepingMonster")
    # The pear-shaped thorax broadens at the haunches and pinches at the neck.
    loft(g, "fur", [(0,.32,.34,.92,.88),(0,.58,.47,1.47,1.14),
         (0,1.16,.40,1.68,1.26),(0,1.85,.28,1.57,1.12),
         (0,2.46,.11,1.39,.96),(0,2.80,-.02,1.08,.81),
         (0,2.91,-.10,.65,.61)])
    for i in range(17):
        a = .13 + i*.165
        x, z = 1.38*cos(a), .15-1.01*sin(a)
        y = 2.36+.16*abs(cos(a))
        g.leaf("sage" if i%3 else "moss", (x,y,z), (x*1.09,y-.44-(i%3)*.09,z-.13), .21,.09,5,3)
    g.joint("Head", (0,2.62,-.15))
    loft(g,"fur",[(0,2.42,-.35,.71,.60),(0,2.56,-.49,1.11,.82),
         (0,2.89,-.51,1.42,1.02),(0,3.35,-.44,1.48,1.04),
         (0,3.77,-.32,1.24,.92),(0,4.01,-.21,.91,.76),(0,4.13,-.16,.53,.49)])
    for s in (-1,1):
        # Pinna and inner shell follow different tapered cross sections.
        loft(g,"fur",[(s*.88,3.64,-.18,.37,.32),(s*1.09,3.89,-.14,.33,.26),
             (s*1.25,4.18,-.12,.23,.20),(s*1.27,4.36,-.14,.075,.09)],14)
        g.leaf("blush",(s*.98,3.77,-.42),(s*1.30,4.27,-.25),.17,.045,5,3)
        g.blob("cream",(s*.38,2.90,-1.38),(.53,.31,.32),14,8)
        for j in range(3):
            g.tube("bark",[(s*.44,2.88+j*.05,-1.62),(s*.77,2.91+j*.04,-1.63),
                           (s*.99,2.94+j*.06,-1.55)],[.014,.011,.004],5)
    g.blob("nose",(0,3.05,-1.64),(.25,.14,.14),16,9)
    for i in range(7):
        a=i*.59
        g.leaf("sage" if i%2 else "leafdeep",(cos(a)*.56,3.98,-.21),
               (cos(a)*.91,4.26+sin(a)*.13,-.53+sin(a)*.38),.19,.055,5,3)
    for s, suffix in ((-1,"L"),(1,"R")):
        g.joint("Eye"+suffix,(s*.68,3.32,-1.39),"Head")
        g.blob("eye",(s*.68,3.32,-1.39),(.145,.202,.087),14,9)
        g.blob("shine",(s*.655,3.40,-1.465),(.046,.049,.018),9,6)
        g.joint("Lid"+suffix,(s*.68,3.32,-1.40),"Head")
        g.tube("nose",[(s*.49,3.34,-1.49),(s*.61,3.30,-1.51),(s*.75,3.29,-1.50),
                    (s*.87,3.34,-1.45)],[.023,.035,.032,.016],7)
        g.joint("Arm"+suffix,(s*1.21,2.34,-.12))
        loft(g,"fur",[(s*1.37,.96,-.54,.25,.26),(s*1.49,1.11,-.49,.38,.38),
             (s*1.57,1.51,-.26,.34,.35),(s*1.49,2.06,-.12,.38,.37),
             (s*1.25,2.40,-.04,.32,.30)],16)
        for j in (-1,0,1):
            g.leaf("ivory",(s*1.39+j*.115,1.12,-.81),(s*1.39+j*.11,1.0,-.86),.043,.02)
        g.joint("Leg"+suffix,(s*.87,.89,.26))
        loft(g,"footfur",[(s*.92,.04,-.26,.49,.54),(s*.94,.13,-.31,.57,.65),
             (s*.93,.36,-.21,.53,.60),(s*.90,.66,.08,.41,.42),
             (s*.86,1.0,.22,.37,.34)],16)
    g.joint("Tail",(0,.78,1.31))
    g.tube("fur",[(0,.78,1.14),(.20,.65,1.71),(.48,.80,2.17),(.66,1.05,2.39),
            (.79,1.24,2.49)],[.38,.42,.34,.23,.07],14)
    return g


def melon_rind(g, center, radius, light):
    # The stripes share vertices with the rind and encircle the whole fruit.
    x,y,z=center
    panels, bands = 32, 12
    def point(i,j):
        t = pi*j/bands
        a = 2*pi*i/panels + .066*sin(4*t+i*.76)*sin(t)
        return (x+radius*1.14*sin(t)*cos(a), y+radius*.88*cos(t),
                z+radius*.95*sin(t)*sin(a))
    for j in range(bands):
        for i in range(panels):
            mat = "rind" if i%4==0 else "rindedge" if i%8==1 else light
            quad=(point(i,j),point(i+1,j),point(i+1,j+1),point(i,j+1))
            ns=[((v[0]-x)/1.14**2,(v[1]-y)/.88**2,(v[2]-z)/.95**2) for v in quad]
            ns=[tuple(k/sqrt(sum(n*n for n in v)) for k in v) for v in ns]
            g.quad(mat,*quad,vertex_normals=ns)
    g.tube("leafdeep",[(x,y+radius*.86,z),(x+.10*radius,y+radius*1.02,z),
           (x+.25*radius,y+radius*1.08,z-.06*radius)],[.052*radius,.043*radius,.02*radius],6)
    pts=[]
    for i in range(17):
        a=i*pi/6
        pts.append((x+.24*radius+radius*.12*sin(a),y+radius*(1.07+i*.006),
                    z+radius*(.09*cos(a)-.12-i*.015)))
    g.tube("leaf",pts,[radius*.016]*len(pts),5)


def leaflet(g, root, angle, length, width, mat):
    # Folded midrib and toothed leaf margins of a strawberry leaflet.
    direction=(cos(angle),sin(angle))
    rows=[]
    for i, fraction in enumerate((0,.14,.24,.34,.44,.54,.64,.74,.84,.92,1)):
        breadth=sin(pi*fraction)**.74*width*(.78 if i%2==0 else 1)
        x=root[0]+direction[0]*length*fraction
        z=root[2]+direction[1]*length*fraction
        y=root[1]+length*(.24*sin(pi*fraction)-.08*fraction)
        rows.append([(x-direction[1]*breadth,y-.08*breadth,z+direction[0]*breadth),
                     (x,y+.13*breadth,z),
                     (x+direction[1]*breadth,y-.10*breadth,z-direction[0]*breadth)])
    for a,b in zip(rows,rows[1:]):
        g.quad(mat,a[0],b[0],b[1],a[1])
        g.quad(mat,a[1],b[1],b[2],a[2])
    g.tube("leafvein",[r[1] for r in rows[1:9:2]],[.010,.009,.006,.003],4)


def verge(S):
    import random
    rng=random.Random(1603)
    g=S("Environment_MeadowVerge")
    for i in range(36):
        a=rng.random()*2*pi
        r=rng.random()**.5
        x,z=2.6*r*cos(a),1.34*r*sin(a)
        for j in range(4):
            b=a+j*1.52
            h=rng.uniform(.18,.66)
            width=rng.uniform(.055,.115)
            g.leaf("grasslit" if j==1 else "leafdeep" if j==3 else "leaf",
                   (x,.008,z),(x+.41*h*cos(b),h,z+.68*h*sin(b)),width,.07,3,2)
        if i%4==0:
            top=(x,.38+r*.09,z)
            g.tube("leafdeep",[(x,0,z),top],[.020,.014],5)
            for j in range(5):
                b=j*2*pi/5
                g.leaf("ivory",top,(x+.14*cos(b),top[1]+.035,z+.14*sin(b)),.061,.025,4,2)
            g.blob("gold",top,(.048,.044,.045),7,4)
    return g


def loam(S):
    import random
    rng=random.Random(718)
    g=S("Environment_LoamBed")
    rings=[]
    samples=28
    rim=[rng.uniform(.90,1.04) for _ in range(samples)]
    for k,r in enumerate((.03,.33,.66,.86,1)):
        ring=[]
        for i in range(samples):
            a=i*2*pi/samples
            x=cos(a)
            z=sin(a)
            # A soft superellipse leaves enough space between adjacent beds.
            ring.append((3.53*r*rim[i]*abs(x)**.72*(1 if x>=0 else -1),
                        (.21,.23,.19,.12,.018)[k]+.025*sin(3*a+k),
                        3.42*r*rim[i]*abs(z)**.75*(1 if z>=0 else -1)))
        rings.append(ring)
    for k,(a,b) in enumerate(zip(rings,rings[1:])):
        for i in range(samples):
            j=(i+1)%samples
            g.quad("loam" if k<2 else "loamedge" if k==3 else "soil",a[i],a[j],b[j],b[i])
    for i in range(samples):
        g.tri("loam",(0,.22,0),rings[0][(i+1)%samples],rings[0][i])
    for i in range(43):
        a=i*2.39996
        r=rng.uniform(.70,.94)
        x,z=3.45*r*cos(a),3.35*r*sin(a)
        length=rng.uniform(.07,.19)
        g.blob("clod" if i%3 else "loamedge",(x,.15,z),(length,.05+rng.random()*.045,.08),7,4)
    return g


def watering_can(S):
    g=S("Environment_WateringCan")
    # Rolled enamel body, recessed filling opening, loop handle and flared rose.
    loft(g,"blue",[(0,.04,0,.37,.31),(0,.10,0,.46,.36),
         (0,.58,0,.43,.34),(0,.73,0,.35,.28)],20)
    def hoop(y,rx,rz,color):
        pts=[(rx*cos(i*pi/12),y,rz*sin(i*pi/12)) for i in range(25)]
        g.tube(color,pts,[.022]*25,5)
    hoop(.09,.45,.35,"sky")
    hoop(.73,.35,.28,"sky")
    g.blob("slate",(0,.734,0),(.26,.011,.20),16,5)
    g.tube("sky",[(0,.50,.25),(0,.72,.38),(0,.98,.32),(0,1.07,.10),
           (0,1.04,-.11),(0,.89,-.22),(0,.70,-.23)],[.049]*7,8)
    g.tube("blue",[(0,.24,-.24),(0,.34,-.52),(0,.51,-.72),(0,.62,-.91)],
           [.15,.10,.083,.075],12)
    g.tube("sky",[(0,.60,-.87),(0,.66,-.97),(0,.68,-1.03)],[.08,.17,.172],14)
    for i in range(9):
        a=i*2*pi/9
        g.blob("slate",(.10*cos(a),.68+.085*sin(a),-1.037),(.013,.013,.011),6,4)
    for side in (-1,1):
        g.leaf("cream",(side*.43,.26,-.11),(side*.43,.52,.10),.073,.018,4,2)
    return g
