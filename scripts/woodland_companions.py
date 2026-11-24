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


def fleece_locks(rows, phase):
    """Distribute overlapping wool locks in staggered rows around the coat."""
    locks=[]
    for row,(latitude,count) in enumerate(rows):
        for i in range(count):
            angle=phase+2*pi*(i+.46*(row%2))/count+.075*sin(i*2.7+row)
            lat=latitude+.073*cos(2.3*i+row+phase)
            locks.append((cos(lat)*cos(angle),sin(lat),cos(lat)*sin(angle),
                          1+.13*sin(3*i+row+phase)))
    return locks


def wool_relief(u,v,w,locks):
    # A soft maximum rounds the trough where two neighbouring locks meet.
    # A fast squared chord distance gives each lock a broad shoulder.
    largest=second=0
    for x,y,z,size in locks:
        q=max(0,1-(1-u*x-v*y-w*z)*4.5/size)
        weight=q*q
        if weight>largest:
            largest,second=weight,largest
        elif weight>second:
            second=weight
    return .5*(largest+second+sqrt((largest-second)**2+.035**2))


def lamb(g, name, skin):
    phase={"Mochi":.24,"Tofu":1.06,"Luma":1.86}[name]
    g.joint("Body",(0,0,0))
    coat=fleece_locks(((-1.23,3),(-.62,7),(.02,9),(.66,7),(1.28,3)),phase)
    def fleece(a,t):
        lat=(t-.5)*pi
        u,v,w=cos(lat)*cos(a),sin(lat),cos(lat)*sin(a)
        lock=wool_relief(u,v,w,coat)
        return ((.84+.21*lock)*u,.86+(.56+.21*lock)*v,
                .28+(.96+.21*lock)*w)
    turned_skin(g,fleece,lambda i,j:"ivory" if j<3 else "cream",(0,.86,.28),40,16)
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
    cy,cz=1.66,-.62
    crown=fleece_locks(((-.93,5),(-.28,8),(.35,9),(.93,6),(1.52,1)),phase+.36)
    face_bands=6
    bands=19
    def head(a,t):
        # Front-to-back rings follow the wool/face boundary. The sloping rim
        # frames both cheeks and leaves the chin open above the bow.
        top=max(0,sin(a))
        hem=1.24-.57*top**1.3+.46*max(0,-sin(a))+.095*cos(7*a+phase+.50*sin(3*a))
        progress=t*bands
        if progress<=face_bands:
            angle=hem*progress/face_bands
            pile=0
        else:
            f=(progress-face_bands)/(bands-face_bands)
            angle=hem+(pi-hem)*f
            pile=min(1,f/.16)
            pile=pile*pile*(3-2*pile)
        u,v,w=sin(angle)*cos(a),sin(angle)*sin(a),-cos(angle)
        relief=pile*(.042+.226*wool_relief(u,v,w,crown))
        return ((.84*(1-.085*v)+relief)*u,cy+(.67+1.06*relief)*v,
                cz+(.65+relief)*w)
    turned_skin(g,head,lambda i,j:skin if j<face_bands else "cream",
                (0,cy,cz),44,bands)
    def front(x,y):
        v=(y-cy)/.67
        return cz-.65*sqrt(max(.001,1-v*v-(x/(.84*(1-.085*v)))**2))
    bead_eyes(g,front,.316,1.69,.098,.118)
    for s in (-1,1):
        face_patch(g,"blush",front,s*.52,1.545,.117,.061)
        smile=[(s*x,y,front(s*x,y)-.016) for x,y in
               ((0,1.532),(.033,1.492),(.085,1.484),(.129,1.514))]
        g.tube("chocolate",smile,[.012,.014,.014,.007],6)
    g.blob("nose",(0,1.556,front(0,1.556)-.007),(.071,.042,.037),12,7)

    for s,suffix in ((-1,"L"),(1,"R")):
        length={"Tofu":.66,"Luma":.47,"Mochi":.55}[name]
        spread={"Tofu":.46,"Luma":.64,"Mochi":.53}[name]
        g.joint("Ear"+suffix,(s*.70,1.98,-.59),"Head")
        def ear(a,t):
            # A thick root folds away from the fleece; the rounded ear tip
            # hangs in front of the shoulder. The inner shell faces forward.
            bulge=max(0,sin(pi*t))**.64
            x=.69+spread*t+.095*sin(pi*t)
            y=1.99-length*t+.085*sin(pi*t)
            width=(.128+.087*t)*bulge
            return (s*(x+width*cos(a)),y+width*.72*cos(a),
                    -.57-.17*t+.12*bulge*sin(a)+.048*bulge*cos(a)**2)
        turned_skin(g,ear,lambda i,j:"pink" if 10<=i<=16 and 2<=j<=8 else skin,
                    (s*.94,1.76,-.65),18,11)
    g.joint("Head",g.joints["Head"][1])
    if name in ("Mochi","Luma"):
        a=(.34 if name=="Mochi" else .65)*pi
        t=8.5/bands
        anchor=head(a,t)
        along=norm(sub(head(a+.01,t),head(a-.01,t)))
        outward=norm(cross(along,sub(head(a,t+.002),head(a,t-.002))))
        if outward[2]>0:
            outward=tuple(-n for n in outward)
        up=norm(cross(outward,along))
        def pin(x,y,depth):
            return tuple(p+x*h+y*k+depth*n for p,h,k,n in zip(anchor,along,up,outward))
        if name=="Mochi":
            for j in range(5):
                petal=2*pi*j/5
                g.blob("ivory",pin(.075*cos(petal),.075*sin(petal),.025),(.068,.061,.051),9,5)
            g.blob("gold",pin(0,0,.061),(.054,.052,.050),10,6)
        else:
            corners=[]
            for j in range(10):
                angle=j*pi/5+pi/2
                r=.134 if j%2==0 else .065
                corners.append(pin(r*cos(angle),r*sin(angle),.024))
            for j,p in enumerate(corners):
                g.tri("gold",pin(0,0,.055),p,corners[(j+1)%10],outward,outward,outward)
    g.joint("Body",(0,0,0))
    # Each loop opens toward its folded outer edge. The knot sits below the chin.
    for side in (-1,1):
        def ribbon(a,t):
            fullness=sin(pi*t)**.56
            height=(.065+.12*t)*fullness
            ridge=(.046+.05*t)*fullness
            return (side*(.035+.255*t),.765+.065*t+height*cos(a),
                    -.94+.061*t+ridge*sin(a)+.028*fullness*cos(2*a))
        turned_skin(g,ribbon,lambda i,j:"rose",(side*.15,.79,-.91),12,6)
    g.blob("gold",(0,.78,-.96),(.073,.067,.063),10,7)


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


def garden_bird(g, species):
    puffin = species == "puffin"
    mantle = "slate" if puffin else "gold"
    g.joint("Body",(0,0,0))

    # Centre the radial fan on the breast. Its outermost ivory ring follows
    # the lower belly and meets the coloured back without a second shell.
    def breast(a,t):
        seam = 1.18-.16*sin(a)
        r = seam*2*t if t < .5 else seam+(pi-seam)*(2*t-1)
        v = sin(a)*sin(r)
        width = (.79 if puffin else .77)*(1-.13*v)
        return (width*cos(a)*sin(r),.87+.71*v,.18-.74*cos(r)-.12*v)
    turned_skin(g,breast,lambda i,j: ("ivory" if puffin else "cream") if j<7 else mantle,
                (0,.87,.18),32,14)

    for side,suffix in ((-1,"L"),(1,"R")):
        x = side*.32
        g.joint("Hind"+suffix,(x,.34,.07))
        g.tube("ochre",[(x,.36,.07),(x,.15,.035)], [.083,.076],10)
        if puffin:
            def paddle(a,t):
                r=sin(pi*t)
                # Three toe crests stretch the front edge of one webbed foot.
                forward=max(0,-sin(a))
                lobes=.088*cos(8*(a+pi/2))*forward**3
                return (x+.236*r*cos(a),.132-.089*cos(pi*t),
                        -.048+(.265+lobes)*r*sin(a))
            turned_skin(g,paddle,lambda i,j:"orange",(x,.132,-.048),32,8)
        else:
            for toe in (-1,0,1):
                g.tube("ochre",[(x,.15,.04),(x+toe*.081,.096,-.12),
                       (x+toe*.16,.071,-.27+.06*abs(toe))],[.057,.051,.023],9)

        g.joint("Wing"+suffix,(side*.635,1.19,.10))
        def wing(a,t):
            arch=sin(pi*t)
            span=arch*(1.27-.52*t)
            x=side*(.60+.19*arch+(.15 if puffin else .23)*t)
            y=1.26-(.73 if puffin else .56)*t
            z=.05+(.66 if puffin else .38)*t
            return (x+side*.19*span*cos(a),y+.09*span*sin(a),z+.34*span*sin(a))
        turned_skin(g,wing,lambda i,j:("ink" if puffin else "straw") if j>=9 else mantle,
                    (side*.80,.96,.25),18,12)

    g.joint("Tail",(0,.71,.69))
    rounded_sections(g,mantle,[(0,.57,.73,.093,.08),(0,.73,.79,.21,.23),
        (.032,.88,.95,.19,.225),(.063,.99,1.10,.136,.16),
        (.082,1.075,1.20,.023,.031)],16)

    cy,cz=(1.63,-.17) if puffin else (1.54,-.21)
    w,h,d=(.879,.704,.67) if puffin else (.84,.69,.647)
    g.joint("Head",(0,1.22,-.105))
    def hood(a,t):
        # Broad side cheeks with a widow's peak above the beak.
        seam=1.18+.11*cos(2*a)-.50*max(0,sin(a))**3*exp(-(cos(a)/.38)**2)
        r=seam*2*t if t<.5 else seam+(pi-seam)*(2*t-1)
        v=sin(a)*sin(r)
        return (w*(1-.079*v)*cos(a)*sin(r),cy+h*v,cz-d*cos(r))
    def front(x,y):
        v=(y-cy)/h
        return cz-d*sqrt(max(.001,1-v*v-(x/(w*(1-.079*v)))**2))
    turned_skin(g,hood,lambda i,j:("cream" if j<9 else "slate") if puffin else "gold",
                (0,cy,cz),40,18)
    bead_eyes(g,front,.33,cy+.045,.104 if puffin else .087,.127 if puffin else .102)
    for s in (-1,1):
        face_patch(g,"blush",front,s*.485,cy-.10,.113,.051)

    # Each cross-section is perpendicular to the length of the bill. A curved
    # orange culmen and thinner lower mandible meet at a narrow warm gape.
    def bill(a,t):
        width=(.214 if puffin else .151)*sin(pi*t)**.75
        height=(.167 if puffin else .096)*sin(pi*t)
        return (width*cos(a),cy-.065-.078*t+height*sin(a)*(1 if sin(a)>0 else .55),
                cz-d+.066-(.406 if puffin else .30)*t)
    def bill_tone(i,j):
        if i in (0,9): return "ochre"
        if puffin and j in (3,4): return "gold"
        return "orange"
    turned_skin(g,bill,bill_tone,(0,cy-.10,cz-d-.09),20,13)

    if not puffin:
        for i in range(2):
            x=.036-.14*i
            rounded_sections(g,"gold",[(x,2.09,.003,.128,.134),
                (x+.012,2.20+.035*i,.003,.135,.143),
                (x+.052,2.32+.072*i,.023,.086,.09),
                (x+.122,2.39+.069*i,.075,.018,.022)],14)
        # Nugget's daisy pin follows her head during nods and feeding.
        x,y=-.40,1.92
        z=front(x,y)-.014
        for i in range(5):
            a=2*pi*i/5
            px,py=x+.085*cos(a),y+.082*sin(a)
            g.blob("ivory",(px,py,front(px,py)-.019),
                   (.067,.067,.035),10,6)
        g.blob("orange",(x,y,z-.037),(.052,.052,.035),10,6)
