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


def rounded_sections(g, pigment, rings, sides=20):
    """Smooth elliptical sections, including the lean of each section centre."""
    from generate_reference_glb import norm, cross, sub
    def point(ring, angle):
        x,y,z,rx,rz=ring
        return x+rx*cos(angle),y,z+rz*sin(angle)
    for j in range(len(rings)-1):
        for i in range(sides):
            positions,normals=[],[]
            for k,col in ((j,i),(j+1,i),(j+1,i+1),(j,i+1)):
                ring=rings[k]
                angle=col*2*pi/sides
                positions.append(point(ring,angle))
                up=sub(point(rings[min(k+1,len(rings)-1)],angle),
                       point(rings[max(k-1,0)],angle))
                tangent=(-ring[3]*sin(angle),0,ring[4]*cos(angle))
                normals.append(norm(cross(up,tangent)))
            g.quad(pigment,*positions,vertex_normals=normals)
    for k in (0,-1):
        for i in range(sides):
            a,b=(point(rings[k],c*2*pi/sides) for c in (i,i+1))
            g.tri(pigment,rings[k][:3],*( (a,b) if k==0 else (b,a) ))


def monster(S):
    g=S("Environment_SleepingMonster")
    g.joint("Body",(0,0,0))
    rounded_sections(g,"fur",[(0,.28,.34,.91,.79),(0,.47,.40,1.39,1.10),
        (0,.87,.35,1.68,1.24),(0,1.38,.26,1.71,1.27),(0,1.90,.22,1.58,1.16),
        (0,2.30,.12,1.24,.94),(0,2.49,.04,.88,.73)],28)
    g.joint("Head",(0,2.11,-.15))
    rounded_sections(g,"fur",[(0,1.94,-.41,.79,.67),(0,2.05,-.47,1.19,.83),
        (0,2.29,-.49,1.52,1.01),(0,2.62,-.45,1.65,1.13),
        (0,2.97,-.39,1.63,1.12),(0,3.33,-.33,1.47,.99),
        (0,3.57,-.27,1.18,.84),(0,3.73,-.21,.79,.58),
        (0,3.81,-.19,.36,.30)],32)

    for s in (-1,1):
        # Slightly turning ivory horns share a broad root with the moss cap.
        rounded_sections(g,"ivory",[(s*.98,3.42,-.18,.285,.25),
            (s*1.04,3.61,-.17,.275,.24),(s*1.12,3.81,-.15,.233,.20),
            (s*1.17,4.00,-.13,.164,.15),(s*1.18,4.15,-.16,.085,.085),
            (s*1.15,4.23,-.21,.020,.023)],18)
    # A continuous moss canopy. Vary its hem rather than intersecting an
    # oversized sphere with the face. Broad drooping leaf tips break its rim.
    profile=[(2.97,1.63,-.39,1.12),(3.33,1.47,-.33,.99),
             (3.57,1.18,-.27,.84),(3.73,.79,-.21,.58),
             (3.81,.36,-.19,.30),(3.88,.02,-.19,.02)]
    def on_crown(angle,y,lift):
        for lo,hi in zip(profile,profile[1:]):
            if y<=hi[0]:
                t=(y-lo[0])/(hi[0]-lo[0])
                rx,cz,rz=(a+t*(b-a) for a,b in zip(lo[1:],hi[1:]))
                return ((rx+lift)*cos(angle),y+.028,cz+(rz+lift)*sin(angle))
        raise ValueError("Outside the crown profile")

    sectors=42
    def moss_point(i,j):
        angle=2*pi*i/sectors
        hem=3.40-.071*cos(9*angle+.35*sin(3*angle))
        height=(3.88,3.81,3.73,3.57,hem)[j]
        return on_crown(angle,height,.032)
    for j in range(4):
        for i in range(sectors):
            g.quad("sage",moss_point(i,j),moss_point(i+1,j),
                   moss_point(i+1,j+1),moss_point(i,j+1))
    for i in range(sectors):
        g.tri("sage",(0,3.908,-.19),moss_point(i+1,0),moss_point(i,0))
    for i in range(15):
        angle=2*pi*i/15
        rows=[]
        for j,(height,width) in enumerate(((3.71,.040),(3.59,.108),(3.46,.145),
                                          (3.33,.127),(3.23,.089),(3.18,.024))):
            yy=height+.055*cos(3*angle)*(j/5)
            aa=angle+.077*(j/5)**2
            rows.append([on_crown(aa+side*width,yy,.055+.041*(1-abs(side)))
                         for side in (-1,0,1)])
        for top,bottom in zip(rows,rows[1:]):
            for k in (0,1):
                g.quad("leaflight" if i%4==0 else "leaf",top[k],top[k+1],
                       bottom[k+1],bottom[k])
    for i in range(7):
        angle=i*2.39996+.46
        x,y,z=on_crown(angle,3.72+.08*cos(i),.068)
        center=(x,y+.019,z)
        for j in range(5):
            a=j*2*pi/5+.37*i
            g.leaf("cream" if i%3 else "pink",center,
                   (x+.16*cos(a),y+.075,z+.16*sin(a)),.072,.044,4,2)
        g.blob("gold",(x,y+.061,z),(.044,.046,.044),8,5)
    # Closed lids follow the head depth across the full arc of each cheek.
    def face_z(x):
        return -.45-1.13*sqrt(1-(x/1.65)**2)
    for s,suffix in ((-1,"L"),(1,"R")):
        x=s*.66
        z=face_z(x)
        pivot=(x,2.72,z)
        g.joint("Eye"+suffix,pivot,"Head")
        g.blob("eye",(x,2.72,z-.012),(.117,.158,.080),15,9)
        g.blob("shine",(x-.029,2.768,z-.08),(.027,.031,.014),9,5)
        g.joint("Lid"+suffix,pivot,"Head")
        lid=[]
        for j in range(9):
            t=(j-4)/4
            xx=x+.226*t
            lid.append((xx,2.735-.085*(1-t*t),face_z(xx)-.027))
        g.tube("nose",lid,[.014+.018*sin(pi*j/8) for j in range(9)],7)
        g.joint("Head",g.joints["Head"][1])
        # A shallow cheek follows the sloping face at both ends.
        cheek=[]
        for j in range(12):
            a=j*pi/6
            xx=s*1.03+.15*cos(a)
            cheek.append((xx,2.49+.075*sin(a),face_z(xx)+.013))
        middle=(s*1.03,2.49,face_z(s*1.03)-.025)
        for j in range(12):
            g.tri("blush",middle,cheek[(j+1)%12],cheek[j])
        g.joint("Arm"+suffix,(s*1.28,1.93,-.22))
        rounded_sections(g,"fur",[(s*1.44,.39,-.73,.27,.32),
            (s*1.49,.51,-.76,.47,.50),(s*1.51,.78,-.67,.49,.51),
            (s*1.55,1.12,-.48,.40,.41),(s*1.48,1.53,-.33,.36,.36),
            (s*1.33,1.93,-.25,.31,.29),(s*1.22,2.09,-.22,.17,.17)],22)
        for j in (-1,0,1):
            g.blob("ivory",(s*1.46+j*.21,.52,-1.16+.075*abs(j)),
                   (.087,.080,.102),10,6)
        g.joint("Leg"+suffix,(s*.83,.79,.30))
        rounded_sections(g,"footfur",[(s*.89,.045,-.22,.40,.52),
            (s*.91,.13,-.23,.53,.64),(s*.91,.33,-.18,.54,.61),
            (s*.89,.55,.03,.42,.46),(s*.83,.80,.24,.33,.32)],20)
    g.joint("Head",g.joints["Head"][1])
    for s in (-1,1):
        g.blob("nose",(s*.093,2.52,-1.566),(.033,.029,.026),9,5)
    g.tube("nose",[(-.15,2.36,-1.528),(-.085,2.315,-1.525),(0,2.31,-1.524),
           (.090,2.32,-1.525),(.15,2.365,-1.529)],[.013,.020,.021,.018,.012],7)
    g.joint("Tail",(0,.71,1.21))
    g.tube("fur",[(0,.74,1.07),(.21,.60,1.64),(.50,.65,1.98),
        (.72,.82,2.19),(.83,.95,2.22)],[.35,.39,.29,.155,.045],14)
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
