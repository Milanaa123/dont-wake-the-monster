"""Original plush-storybook sculpt layers for the existing 30 pet species.

The user supplied flat animal-sticker pictures as art direction; these are
three-dimensional, animated-rig compatible surfaces, not sticker image planes.
Only sculpted mesh primitives are emitted, with tiny bounded polygon costs.
All coordinates use local Y-up, -Z-forward coordinates of existing pets.
"""
from math import cos, pi, sin


def add_family_details(g, name, species, base, secondary):
    def body():
        g.joint("Body", (0, 0, 0))

    def head():
        if "Head" in g.joints:
            g.joint("Head", g.joints["Head"][1])
        else:
            body()

    def blob(mat, center, radii, slices=11, rings=6):
        g.blob(mat, center, radii, slices, rings)

    def vine(mat, points, radii):
        g.tube(mat, points, radii, 6)

    def leaf(mat, start, end, width):
        g.leaf(mat, start, end, width, .035, 4, 2)

    if species == "bear":
        head()
        # Small pale plush muzzle and smile attached to the moving head.
        blob("cream", (0, 1.65, -1.23), (.29, .17, .09), 15, 8)
        blob("chocolate", (0, 1.73, -1.325), (.097, .065, .045))
        for side in (-1, 1):
            blob("blush", (side*.79, 1.88, -1.05), (.153,.087,.033))
            blob("pink", (side*.80, 2.57, -.665), (.18,.13,.040))
        # A tiny jar of honey makes the bear distinctive in the silhouette.
        body()
        if name == "Wobble":
            from orchard_sculpt import loft
            loft(g, "bark", [
                (0,.33,-1.13,.30,.24),
                (0,.45,-1.15,.35,.27),
                (0,.84,-1.16,.34,.25),
                (0,.94,-1.16,.28,.20)
            ], 13)
            blob("gold", (0,.95,-1.16), (.30,.075,.22), 12,6)
            for side in (-1,1):
                blob(base, (side*.34,.69,-1.20), (.17,.23,.17), 10,6)

    elif species in ("chick", "puffin"):
        body()
        # Round, wing-sized bibs and visibly padded toes for the baby birds.
        if species=="puffin":
            blob("ivory",(0,1.10,-.69),(.56,.65,.16),16,9)
        for side in (-1,1):
            for toe in range(3):
                x=side*.43+(toe-1)*.12
                blob("gold" if species=="chick" else "orange",
                     (x,.075,-.19),(.087,.069,.16),8,5)

    elif species == "deer":
        body()
        # High-contrast fawn freckles along both flanks, intentionally
        # staggered and low-poly so the pattern survives on small screens.
        for side in (-1,1):
            for i in range(4):
                x=side*(.46+.055*(i%2))
                y=1.47+.10*(i%2)
                z=.21+i*.31
                blob("cream",(x,y,z),(.085,.065,.092),8,5)
        head()
        blob("ivory",(0,2.08,-1.32),(.19,.22,.058),10,6)

    elif species == "ferret":
        head()
        # Dark face mask is recognisable for a ferret even at phone scale.
        for side in (-1,1):
            blob(secondary,(side*.35,1.56,-1.44),(.28,.23,.053),11,6)
        body()
        # Cream throat bib is smaller than the chin so it doesn't turn into
        # another large featureless sphere.
        leaf("ivory",(0,1.08,-.63),(0,.54,-.90),.29)

    elif species == "dinosaur":
        body()
        # Soft sculpted belly patch and tiny triangular dorsal plates.
        blob("cream",(0,.91,-.86),(.55,.57,.14),15,8)
        for i in range(6):
            z=.04+i*.33
            leaf("leaflight",(0,1.72-i*.12,z),
                 (0,2.17-i*.14,z+.13),.22)

    elif species=="octopus":
        body()
        for side in (-1,1):
            blob("blush",(side*.84,1.04,-.55),(.15,.08,.04),9,5)
        # A soft cream head glint replaces sharp graphic stickers.
        blob("cream",(-.27,1.80,-.55),(.11,.045,.035),8,5)

    elif species=="unicorn":
        head()
        # A few matte locks around the horn keep the silhouette expressive.
        for j in range(3):
            x=(j-1)*.31
            leaf("lilac",(x,2.83,-.48),
                 (x+.12,2.54,-1.08),.18)

    elif species=="crab":
        body()
        for side in (-1,1):
            blob("blush",(side*.81,.78,-.63),(.15,.08,.036),9,5)

    elif species=="butterfly":
        body()
        for side in (-1,1):
            # Spots stay on their wing joint and follow flapping animation.
            g.joint("Wing"+("L" if side<0 else "R"),
                    (side*.13,1.62,.19),"Body")
            blob("ivory",(side*.95,2.11,.22),(.17,.13,.032),10,6)
            blob("gold",(side*1.18,1.91,.24),(.095,.09,.027),8,5)
        body()


def pond_frog(g, name, skin):
    """A seated frog. Its brow lobes, cheeks and chin share one head surface."""
    from generate_reference_glb import cross, norm, sub
    from orchard_sculpt import loft

    g.joint("Body", (0, 0, 0))
    loft(g, skin, [(0,.12,.33,.43,.44), (0,.23,.38,.65,.65),
                   (0,.54,.34,.78,.72), (0,.88,.26,.69,.60),
                   (0,1.12,.12,.48,.43)], 20)
    g.blob("cream", (0,.57,-.20), (.54,.42,.26), 16,9)
    for side, suffix in ((-1,"L"), (1,"R")):
        g.joint("Hind"+suffix, (side*.55,.55,.59))
        loft(g, skin, [(side*.76,.105,.58,.26,.36), (side*.82,.22,.56,.34,.48),
                       (side*.78,.43,.64,.35,.43), (side*.66,.60,.65,.25,.34),
                       (side*.58,.70,.58,.09,.13)], 14)
        g.joint("Fore"+suffix, (side*.54,.71,-.16))
        g.tube(skin, [(side*.54,.73,-.17), (side*.64,.53,-.26),
                      (side*.66,.31,-.35), (side*.59,.145,-.51)],
               [.105,.13,.105,.095], 10)
        for fore in (False, True):
            g.joint(("Fore" if fore else "Hind")+suffix,
                    (side*.54,.71,-.16) if fore else (side*.55,.55,.59))
            x,z=(.59,-.54) if fore else (.90,.31)
            g.blob(skin,(side*x,.135,z),(.18,.083,.20),12,7)
            for digit in (-1,0,1):
                tip=(side*(x+digit*.145),.083,z-.29+.06*abs(digit))
                g.tube(skin,[(side*(x+.07*digit),.13,z-.08),tip],[.057,.037],7)
                g.blob("leaflight",tip,(.061,.036,.070),9,5)

    g.joint("Head",(0,.95,-.11))
    def surface(a, latitude):
        from math import exp
        u,v=cos(latitude)*sin(a),sin(latitude)
        w=cos(latitude)*cos(a)
        brow=exp(-((abs(u)-.56)/.26)**2)*max(0,v)**1.4
        return (1.07*u*(1-.08*v), 1.39+.59*v+.30*brow, -.14-.68*w)

    def normal(a, latitude):
        step=.001
        tangent=sub(surface(a+step,latitude),surface(a-step,latitude))
        rise=sub(surface(a,latitude+step),surface(a,latitude-step))
        return norm(cross(rise,tangent))

    sides,bands=32,16
    for j in range(bands):
        for i in range(sides):
            coords=[(2*pi*k/sides, -pi/2+pi*l/bands)
                    for k,l in ((i,j),(i,j+1),(i+1,j+1),(i+1,j))]
            # Close both poles with a fan, preserving outward smooth normals.
            if j==0: coords.pop(3)
            if j==bands-1: coords.pop(2)
            points=[surface(a,b) for a,b in coords]
            normals=[(0,-1,0) if b<-1.57 else (0,1,0) if b>1.57 else normal(a,b)
                     for a,b in coords]
            if len(points)==3:
                g.tri(skin,*points,*normals)
            else:
                g.quad(skin,*points,vertex_normals=normals)

    def patch(mat,a,b,rx,ry,depth):
        # An oval cap mapped onto the head surface. Its outer rim touches skin.
        vertices=[]
        for ring in (0,.65,1):
            row=[]
            for i in range(16):
                angle=2*pi*i/16
                aa,bb=a+rx*ring*cos(angle), b+ry*ring*sin(angle)
                p,n=surface(aa,bb),normal(aa,bb)
                row.append(tuple(c+t*(.006+depth*(1-ring*ring)) for c,t in zip(p,n)))
            vertices.append(row)
        for i in range(16):
            k=(i+1)%16
            g.tri(mat,vertices[0][0],vertices[1][k],vertices[1][i])
            g.quad(mat,vertices[1][i],vertices[1][k],vertices[2][k],vertices[2][i])

    for side in (-1,1):
        patch("eye",side*.66,.53,.115,.205,.045)
        x,y,z=surface(side*.66-.03,.60)
        n=normal(side*.66-.03,.60)
        g.blob("shine",tuple(c+.053*t for c,t in zip((x,y,z),n)),(.025,.028,.017),9,6)
        patch("blush",side*.81,-.025,.19,.13,.008)
    mouth=[]
    for i in range(13):
        t=(i-6)/6
        a,b=.235*t,-.16-.065*sin(pi*abs(t))+.03*abs(t)
        p,n=surface(a,b),normal(a,b)
        mouth.append(tuple(c+.012*k for c,k in zip(p,n)))
    g.tube("chocolate",mouth,[.010+.009*sin(pi*i/12) for i in range(13)],7)
    if name=="Pickle":
        g.tube("leafdeep",[(0,1.95,-.06),(.015,2.06,-.04),(.04,2.16,-.01)],
               [.032,.025,.016],7)
        g.leaf("leaf",(.027,2.12,-.025),(-.23,2.26,-.035),.085,.05,6,3)
        g.leaf("leaflight",(.035,2.14,-.02),(.27,2.33,.03),.10,.055,6,3)
    else:
        for side in (-1,1):
            for a,b in ((1.85,.55),(2.18,.48),(2.48,.63)):
                patch("mint",side*a,b,.13,.095,.006)
