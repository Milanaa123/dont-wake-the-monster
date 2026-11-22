"""Original owl, lamb and turtle surfaces. Coordinates are Y-up, facing -Z."""
from math import cos, exp, hypot, pi, sin, sqrt

from generate_reference_glb import cross, norm, sub
from orchard_sculpt import rounded_sections


def turned_skin(g, point, pigment, center, sides, bands):
    """Join a closed family of deformed rings, with smooth normals across pigment seams."""
    rows = []
    for j in range(bands + 1):
        row = []
        t = j / bands
        for i in range(sides):
            a = 2*pi*i/sides
            p = point(a,t)
            radial = sub(p,center)
            if j in (0,bands):
                normal = norm(radial)
            else:
                around = sub(point(a+.001,t),point(a-.001,t))
                along = sub(point(a,t+.0002),point(a,t-.0002))
                normal = norm(cross(around,along))
                if sum(v*w for v,w in zip(normal,radial)) < 0:
                    normal = tuple(-v for v in normal)
            row.append((p,normal))
        rows.append(row)
    for j,(lower,upper) in enumerate(zip(rows,rows[1:])):
        for i in range(sides):
            k = (i+1)%sides
            corners = [lower[i],lower[k],upper[k],upper[i]]
            if j == 0:
                corners.pop(1)
            if j == bands-1:
                corners.pop(2)
            points,normals = zip(*corners)
            mat = pigment(i,j)
            if len(corners)==3:
                g.tri(mat,*points,*normals)
            else:
                g.quad(mat,*points,vertex_normals=normals)


def bead_eyes(g, depth, spacing, y, width, height):
    """Both pupils and their catchlights share one blinking section on the head."""
    g.joint("Blink",(0,y,depth(0,y)),"Head")
    for side in (-1,1):
        x = side*spacing
        z = depth(x,y)
        g.blob("eye",(x,y,z-.012),(width,height,.058),16,9)
        g.blob("shine",(x-width*.30,y+height*.34,z-.062),
               (width*.25,height*.22,.014),9,5)
    g.joint("Head",g.joints["Head"][1])


def face_patch(g, mat, depth, x, y, width, height):
    """Shallow oval following the changing depth of the cheek."""
    middle=(x,y,depth(x,y)-.018)
    edge=[]
    for i in range(18):
        a=2*pi*i/18
        xx,yy=x+width*cos(a),y+height*sin(a)
        edge.append((xx,yy,depth(xx,yy)-.009))
    for i,p in enumerate(edge):
        g.tri(mat,middle,edge[(i+1)%len(edge)],p)


def owlet(g):
    g.joint("Body",(0,0,0))
    rounded_sections(g,("fur","lavender","lavender","lavender","lavender","lavender"),
        [(0,.17,.17,.29,.32),(0,.27,.17,.52,.51),(0,.54,.16,.71,.62),
         (0,.84,.13,.77,.69),(0,1.11,.07,.69,.61),(0,1.32,.02,.53,.46),
         (0,1.40,-.03,.30,.28)],24)
    for i in range(5):
        x=(i%3-1)*.23 if i<3 else (i-3.5)*.27
        y=.78 if i<3 else .58
        z=.14-.65*sqrt(1-(x/.72)**2)
        g.tube("ivory",[(x-.060,y,z),(x,y-.052,z-.009),(x+.059,y,z)],
               [.013,.021,.011],7)
    for side,suffix in ((-1,"L"),(1,"R")):
        g.joint("Hind"+suffix,(side*.29,.31,.05))
        g.tube("ochre",[(side*.29,.32,.04),(side*.30,.13,-.020)],
               [.077,.063],9)
        for toe in (-1,0,1):
            x=side*.30
            g.tube("ochre",[(x,.13,-.02),(x+toe*.072,.083,-.112),
                            (x+toe*.13,.072,-.228+.036*abs(toe))],
                   [.052,.046,.022],8)
        g.joint("Wing"+suffix,(side*.61,1.20,.095))
        rounded_sections(g,"fur",[(side*.68,.38,.42,.036,.055),
            (side*.76,.49,.39,.099,.18),(side*.79,.71,.30,.17,.33),
            (side*.76,.96,.20,.208,.39),(side*.69,1.15,.12,.17,.30),
            (side*.63,1.26,.10,.068,.14)],18)
        for j in range(3):
            z=.04+j*.145
            g.tube("lavender",[(side*.942,.91,z),(side*.955,.83,z+.041),
                (side*.939,.78,z+.085)],[.014,.019,.007],6)

    g.joint("Head",(0,1.20,-.11))
    cy,cz=1.64,-.21
    def mask(a,t):
        # One surface runs from the centre of the face around the back of the skull.
        # Warping two adjacent rings gives the facial disc its soft heart-shaped cleft.
        boundary=1.10+.10*cos(2*a)-.38*max(0,sin(a))**4*exp(-(cos(a)/.26)**2)
        if t<=.5:
            r=2*t*boundary
        else:
            r=boundary+(pi-boundary)*(2*t-1)
        u,v,w=cos(a)*sin(r),sin(a)*sin(r),cos(r)
        return (1.01*u*(1-.055*v),cy+.78*v,cz-.71*w)
    def front(x,y):
        v=(y-cy)/.78
        return cz-.71*sqrt(max(.001,1-v*v-(x/(1.01*(1-.055*v)))**2))
    turned_skin(g,mask,lambda i,j:"cream" if j<9 else "ivory" if j==9 else
                "tan" if j==10 else "lavender",(0,cy,cz),40,20)
    for s in (-1,1):
        rounded_sections(g,"lavender",[(s*.57,2.06,-.11,.20,.19),
            (s*.65,2.22,-.075,.19,.15),(s*.76,2.38,-.04,.13,.105),
            (s*.85,2.51+.045*(s<0),.012,.056,.05),
            (s*.89,2.56+.045*(s<0),.031,.014,.012)],13)
        face_patch(g,"blush",front,s*.62,1.50,.117,.057)
    bead_eyes(g,front,.36,1.72,.135,.157)
    rounded_sections(g,("ochre","ochre","gold","gold"),[(0,1.391,-.966,.017,.024),
        (0,1.445,-.979,.068,.065),(0,1.51,-.968,.111,.085),
        (0,1.554,-.933,.10,.077),(0,1.58,-.901,.042,.043)],14)


def lamb(g, name, skin):
    phase={"Mochi":.24,"Tofu":1.06,"Luma":1.86}[name]
    g.joint("Body",(0,0,0))
    # The fleece is a connected volume. Three staggered curl bands broaden the
    # haunches and give the belly a scalloped silhouette even in a side view.
    def fleece(a,t):
        lat=(t-.5)*pi
        v=sin(lat)
        ring=cos(lat)
        curl=(.5+.5*cos(8*a+1.30*sin(3*lat)+phase))*(.5+.5*cos(7*lat-.70*cos(3*a)))
        width=(.94+.117*curl)*ring
        return (width*cos(a),.87+.69*v+.028*ring*cos(6*a+phase),
                .32+(1.055+.115*curl)*ring*sin(a))
    turned_skin(g,fleece,lambda i,j:"ivory" if j<4 else "cream",(0,.87,.32),48,18)
    for side,suffix in ((-1,"L"),(1,"R")):
        for fore in (True,False):
            x,z=side*(.43 if fore else .53),(-.31 if fore else .88)
            g.joint(("Fore" if fore else "Hind")+suffix,(x,.65,z))
            rounded_sections(g,("brown","brown",skin,skin,skin),[
                (x,.055,z-.055,.101,.137),(x,.102,z-.074,.154,.172),
                (x,.201,z-.055,.156,.165),(x,.33,z-.018,.13,.133),
                (x,.53,z,.17,.16),(x*.90,.69,z+.045,.113,.127)],15)
    g.joint("Tail",(0,1.00,1.22))
    rounded_sections(g,"cream",[(0,.73,1.30,.075,.09),(0,.80,1.37,.165,.17),
         (.03,.94,1.37,.209,.198),(.04,1.08,1.28,.15,.17),(.02,1.14,1.21,.07,.10)],15)
    g.joint("Head",(0,1.30,-.40))
    cy,cz=1.68,-.62
    def head(a,t):
        lat=(t-.5)*pi
        v=sin(lat)
        return (.85*(1-.10*v)*cos(lat)*cos(a),cy+.67*v,cz+.66*cos(lat)*sin(a))
    turned_skin(g,head,lambda i,j:skin,(0,cy,cz),32,15)
    def front(x,y):
        v=(y-cy)/.67
        return cz-.66*sqrt(max(.001,1-v*v-(x/(.85*(1-.10*v)))**2))
    bead_eyes(g,front,.326,1.67,.088,.109)
    for s in (-1,1):
        face_patch(g,"blush",front,s*.52,1.545,.117,.061)
        smile=[(s*x,y,front(s*x,y)-.016) for x,y in
               ((0,1.532),(.033,1.492),(.085,1.484),(.129,1.514))]
        g.tube("chocolate",smile,[.012,.014,.014,.007],6)
    g.blob("nose",(0,1.556,front(0,1.556)-.007),(.071,.042,.037),12,7)

    for s,suffix in ((-1,"L"),(1,"R")):
        drop=.10 if name=="Tofu" else -.06 if name=="Luma" else .01
        g.joint("Ear"+suffix,(s*.62,1.94,-.46),"Head")
        # The ear folds down and away from the scalp. Pink stays on its inner shell.
        def ear(a,t):
            bend=sin(pi*t)
            x=s*(.57+.56*t+.083*bend)
            y=2.02-(.24+drop)*t-.16*t*t+.075*bend
            z=-.43-.12*t
            return (x+s*.055*bend*cos(a), y+.167*bend*cos(a), z+.133*bend*sin(a))
        turned_skin(g,ear,lambda i,j:"pink" if 9<=i<15 and 2<=j<9 else skin,
                    (s*.84,1.85,-.48),18,11)
    g.joint("Head",g.joints["Head"][1])
    # The crown is a low dome with a rolled fringe. Its varying hem crosses
    # the forehead and meets the ear roots, so no separate beads are needed.
    def bonnet(a,t):
        v=sin((t-.5)*pi)
        ring=cos((t-.5)*pi)
        wave=cos(7*a+phase+1.1*v+.26*sin(3*a))
        breadth=ring*(1+.108*wave*(1-v*v))
        return (.879*breadth*cos(a),2.16+.358*v+
                (-.119*wave-.080*max(0,-sin(a)))*ring, -.56+.73*breadth*sin(a))
    turned_skin(g,bonnet,lambda i,j:"ivory" if j<3 else "cream",(0,2.16,-.56),48,15)
    if name in ("Mochi","Luma"):
        # A small golden blossom for Mochi, a raised five-point star for Luma.
        x=.39 if name=="Mochi" else -.37
        y,z=2.275,-1.18
        if name=="Mochi":
            for j in range(5):
                a=2*pi*j/5
                g.blob("ivory",(x+.071*cos(a),y+.071*sin(a),z),(.063,.061,.032),9,5)
            g.blob("gold",(x,y,z-.031),(.054,.052,.031),10,6)
        else:
            corners=[(x+cos(i*pi/5+pi/2)*(.122 if i%2==0 else .063),
                      y+sin(i*pi/5+pi/2)*(.122 if i%2==0 else .063),z) for i in range(10)]
            for j,p in enumerate(corners):
                g.tri("gold",(x,y,z-.044),corners[(j+1)%10],p)
    g.joint("Body",(0,0,0))
    for s in (-1,1):
        rounded_sections(g,"rose",[(s*.16,.873,-.739,.052,.043),
            (s*.19,.931,-.755,.119,.068),(s*.16,1.001,-.75,.123,.07),
            (s*.19,1.070,-.727,.069,.046)],12)
    g.blob("gold",(0,.97,-.788),(.066,.067,.049),10,7)


def shell(g):
    """Cut fitted scutes from one curved carapace, sharing the floor of each seam."""
    sites=[(0,-.51),(0,0),(0,.51)]
    sites += [(s*x,z) for s in (-1,1) for x,z in ((.38,-.52),(.53,-.12),(.48,.30),(.32,.60))]
    sites += [(.91*cos(2*pi*i/16),.91*sin(2*pi*i/16)) for i in range(16)]
    rim=[(cos(2*pi*i/64),sin(2*pi*i/64)) for i in range(64)]
    def project(u,v,lift):
        r=hypot(u,v)
        f=sin(r*pi/2)/r if r else pi/2
        p=(1.03*u*f,.59+.84*cos(r*pi/2),.51+1.10*v*f)
        n=norm((p[0]/1.03**2,(p[1]-.59)/.84**2,(p[2]-.51)/1.10**2))
        return tuple(p[k]+lift*n[k] for k in range(3)),n
    for index,(x,z) in enumerate(sites):
        poly=rim
        for a,b in sites:
            if (a,b)==(x,z): continue
            def dist(p):
                return (p[0]-(a+x)*.5)*(a-x)+(p[1]-(b+z)*.5)*(b-z)
            clipped=[]
            for prev,curr in zip(poly[-1:]+poly[:-1],poly):
                d,e=dist(prev),dist(curr)
                if (d<0)!=(e<0):
                    t=d/(d-e)
                    clipped.append(tuple(p+(q-p)*t for p,q in zip(prev,curr)))
                if e<0: clipped.append(curr)
            poly=clipped
        edge=[]
        for prev,curr in zip(poly,poly[1:]+poly[:1]):
            steps=max(1,round(hypot(curr[0]-prev[0],curr[1]-prev[1])/.11))
            edge.extend(tuple(p+(q-p)*j/steps for p,q in zip(prev,curr)) for j in range(steps))
        tone=("sage","leaf","moss","leaflight")[index%4] if index<11 else ("sage","leaf")[index%2]
        crown,cn=project(x,z,.028)
        rings=[[project(x+(u-x)*f,z+(v-z)*f,h) for u,v in edge]
               for f,h in ((.48,.025),(.87,.016),(.95,.005),(1,0))]
        for j in range(len(edge)):
            k=(j+1)%len(edge)
            p,n=rings[0][j]; q,m=rings[0][k]
            g.tri(tone,crown,p,q,cn,n,m)
            for i,(inner,outer) in enumerate(zip(rings,rings[1:])):
                pts,ns=zip(inner[j],outer[j],outer[k],inner[k])
                g.quad("leafdeep" if i==2 else tone,*pts,vertex_normals=ns)
    rounded_sections(g,("ivory","straw","sage"),[(0,.29,.48,.59,.72),
        (0,.42,.50,.93,.99),(0,.535,.51,1.04,1.11),(0,.59,.51,1.03,1.10)],64)


def turtle(g):
    g.joint("Body",(0,0,0))
    shell(g)
    for s,suffix in ((-1,"L"),(1,"R")):
        for fore in (True,False):
            z=-.15 if fore else 1.13
            g.joint(("Fore" if fore else "Hind")+suffix,(s*.69,.47,z))
            rounded_sections(g,"lime",[(s*.91,.064,z-.085,.16,.17),
                (s*.94,.107,z-.099,.224,.246),(s*.91,.218,z-.048,.23,.254),
                (s*.82,.351,z,.186,.205),(s*.67,.485,z+.045,.148,.155)],15)
    g.joint("Tail",(0,.45,1.49))
    g.tube("lime",[(0,.46,1.43),(.023,.41,1.64),(.092,.44,1.85),(.14,.51,1.94)],
           [.16,.14,.077,.012],12)
    g.joint("Head",(0,.60,-.36))
    cy,cz=.91,-.81
    def head(a,t):
        v=sin((t-.5)*pi)
        r=cos((t-.5)*pi)
        return (.76*(1-.07*v)*r*cos(a),cy+.65*v,cz+.60*r*sin(a))
    turned_skin(g,head,lambda i,j:"ivory" if j<5 else "lime",(0,cy,cz),32,16)
    def front(x,y):
        v=(y-cy)/.65
        return cz-.60*sqrt(max(.001,1-v*v-(x/(.76*(1-.07*v)))**2))
    bead_eyes(g,front,.315,1.03,.094,.119)
    for s in (-1,1):
        face_patch(g,"blush",front,s*.46,.884,.104,.053)
        smile=[(s*x,y,front(s*x,y)-.019) for x,y in
               ((0,.866),(.062,.850),(.121,.870),(.148,.897))]
        g.tube("chocolate",smile,[.012,.015,.014,.007],7)
