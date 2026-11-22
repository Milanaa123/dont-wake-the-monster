"""Shared authored detail sculpts for the headline kitten and bunny companions.

These are actual triangulated 3-D surfaces in the same scene as the gameplay
pet. No image generation, paper concept art, borrowed assets or extra
MeshPart instances. Coordinates match the existing Y-up / -Z-forward rig.
"""
from math import cos, pi, sin


def kitten(g, name, coat, cream):
    """A round-faced kitten with a shaped bib and an uninterrupted two-tone coat."""
    from math import exp, sqrt
    from generate_reference_glb import cross, norm, sub
    from orchard_sculpt import rounded_sections
    fire=name=="Zuzu"
    g.joint("Body",(0,0,0))
    rounded_sections(g,coat,[(0,.12,.25,.35,.36),(0,.22,.26,.57,.58),
        (0,.51,.29,.71,.72),(0,.79,.28,.70,.70),(0,1.04,.16,.57,.57),
        (0,1.28,-.02,.43,.40),(0,1.40,-.10,.29,.24)],22)
    for side,suffix in ((-1,"L"),(1,"R")):
        for fore in (True,False):
            x=side*(.41 if fore else .59)
            z=-.41 if fore else .42
            g.joint(("Fore" if fore else "Hind")+suffix,(x,.67,z+.12))
            rounded_sections(g,(cream,cream,coat,coat,coat),[(x,.05,z-.055,.135,.191),(x,.13,z-.06,.218,.274),
                (x,.27,z-.035,.23,.27),(x,.43,z+.055,.197,.207),
                (x*.94,.62,z+.13,.175,.175),(x*.79,.79,z+.15,.093,.083)],16)

    g.joint("Tail",(0,.54,.79))
    if fire:
        path=[(0,.54,.79),(.32,.68,1.01),(.68,.97,1.12),(.91,1.34,1.12),
              (1.01,1.68,1.07),(.96,1.91,1.01),(.80,2.00,.99),(.70,1.96,.97)]
    else:
        path=[(0,.54,.79),(.36,.44,.97),(.76,.35,.98),(1.05,.31,.79),
              (1.17,.35,.51),(1.14,.42,.27),(1.01,.48,.13),(.89,.47,.10)]
    rows=[]
    for i,p in enumerate(path):
        along=norm(sub(path[min(i+1,len(path)-1)],path[max(i-1,0)]))
        side_axis=norm(cross(along,(0,1,0)))
        up=cross(along,side_axis)
        r=(.18,.205,.194,.165,.147,.133,.105,.040)[i]
        row=[]
        for j in range(14):
            a=2*pi*j/14
            n=tuple(u*cos(a)+v*sin(a) for u,v in zip(side_axis,up))
            row.append((tuple(c+r*v for c,v in zip(p,n)),n))
        rows.append(row)
    for i,(lo,hi) in enumerate(zip(rows,rows[1:])):
        mat=cream if i>=5 else ("gold" if fire else "rose") if i==3 else coat
        for j in range(14):
            k=(j+1)%14
            pts,ns=zip(lo[j],lo[k],hi[k],hi[j])
            g.quad(mat,*pts,vertex_normals=ns)
    for j in range(14):
        g.tri(cream,path[-1],rows[-1][j][0],rows[-1][(j+1)%14][0])

    g.joint("Head",(0,1.22,-.15))
    def surface(a,lat):
        y=sin(lat)
        return (1.00*cos(lat)*sin(a)*(1-.14*y),1.79+.77*y,
                -.25-.755*cos(lat)*cos(a)*(1-.035*y))
    def surface_normal(a,lat):
        if abs(lat)>1.5707: return (0,1 if lat>0 else -1,0)
        tangent=sub(surface(a+.001,lat),surface(a-.001,lat))
        rise=sub(surface(a,lat+.001),surface(a,lat-.001))
        return norm(cross(rise,tangent))
    def corner(i,j):
        a=2*pi*i/36
        # Warp a shared latitude to give the nose blaze a clean edge across
        # the cheeks, even in profile. Zuzu's marking sweeps the other way.
        shift=-.23 if fire else .15
        angle=(a-shift+pi)%(2*pi)-pi
        seam=-.29+.92*exp(-(angle/.43)**2)+.08*sin(3*a)
        lat=(-pi/2+(seam+pi/2)*j/8 if j<=8 else seam+(pi/2-seam)*(j-8)/10)
        return surface(a,lat),surface_normal(a,lat)
    for j in range(18):
        for i in range(36):
            indices=[(i,j),(i,j+1),(i+1,j+1),(i+1,j)]
            if j==0: indices.pop(3)
            if j==17: indices.pop(2)
            points,normals=zip(*(corner(k,l) for k,l in indices))
            mat=cream if j<8 else coat
            if len(points)==3: g.tri(mat,*points,*normals)
            else: g.quad(mat,*points,vertex_normals=normals)

    # Inset pink bowl and rounded backs share the ear margin. The tip leans
    # slightly away from the nose, with both bases embedded below the crown.
    for side,suffix in ((-1,"L"),(1,"R")):
        g.joint("Ear"+suffix,(side*.64,2.29,-.14),"Head")
        tip=3.14+(.085 if fire and side==1 else 0)
        outline=[(.24,2.14),(.34,2.38),(.49,2.58),(.73,2.85),(.94,tip-.045),
                 (1.015,tip),(1.045,tip-.075),(1.055,2.80),(1.010,2.55),(.96,2.37),
                 (.81,2.18),(.60,2.10)]
        center=(.73,2.53)
        def rim(scale,z):
            return [(side*(center[0]+scale*(x-center[0])),center[1]+scale*(y-center[1]),
                     z+.13*(y-2.46)) for x,y in outline]
        back,edge,lip,bowl=rim(.68,.105),rim(1,-.23),rim(.76,-.34),rim(.52,-.31)
        def ear_face(mat,vertices):
            ordered=vertices if side==1 else vertices[::-1]
            if len(ordered)==3: g.tri(mat,*ordered)
            else: g.quad(mat,*ordered)
        for j in range(len(edge)):
            k=(j+1)%len(edge)
            ear_face(coat,[(side*center[0],center[1],.18),back[k],back[j]])
            for row,next_row,mat in ((back,edge,coat),(edge,lip,coat),(lip,bowl,"blush")):
                ear_face(mat,[row[j],row[k],next_row[k],next_row[j]])
            ear_face("pink",[(side*center[0],center[1],-.272),bowl[j],bowl[k]])

    g.joint("Head",g.joints["Head"][1])
    def front(x,y):
        v=(y-1.79)/.77
        return -.25-.755*(1-.035*v)*sqrt(max(.001,1-v*v-(x/(1-.14*v))**2))
    for s in (-1,1):
        x=s*.40
        z=front(x,1.78)
        g.blob("eye",(x,1.78,z-.011),(.085,.102,.052),13,8)
        g.blob("shine",(x-.024,1.813,z-.055),(.024,.026,.013),8,5)
        cheek=(s*.64,1.61)
        g.blob("blush",(*cheek,front(*cheek)-.009),(.122,.066,.035),12,7)
        for i in range(2):
            p=(s*.57,1.59+i*.092)
            g.tube("chocolate",[(*p,front(*p)-.018),
                   (s*.83,p[1]-.017,-.83),(s*1.075,p[1]+(i-.5)*.084,-.735)],
                   [.012,.009,.003],6)
        smile=[(s*x,y,front(s*x,y)-.013) for x,y in
               ((0,1.594),(.035,1.554),(.086,1.55),(.145,1.59))]
        g.tube("chocolate",smile,[.014,.017,.014,.006],7)
    g.blob("rose",(0,1.626,front(0,1.626)-.019),(.068,.043,.035),11,7)
    g.joint("Body",(0,0,0))
    collar=[(-.45,1.05,-.34),(-.30,.99,-.49),(0,.956,-.55),
            (.30,.99,-.49),(.45,1.05,-.34)]
    g.tube("brick" if fire else "rose",collar,[.045,.055,.065,.055,.045],9)
    g.blob("gold",(0,.869,-.589),(.12,.124,.09),13,8)
    g.tube("chocolate",[(-.059,.85,-.667),(0,.838,-.678),(.059,.85,-.667)],
           [.009,.013,.009],6)


def seated_rabbit(g, fur):
    """A compact pear-shaped lap rabbit, with paws wrapped around its carrot."""
    from orchard_sculpt import rounded_sections
    g.joint("Body",(0,0,0))
    rounded_sections(g,fur,[(0,.10,.19,.39,.37),(0,.25,.22,.65,.55),
                       (0,.58,.22,.78,.65),(0,.95,.14,.68,.54),
                       (0,1.28,-.02,.49,.40),(0,1.49,-.10,.33,.26)])
    g.joint("Tail",(0,.58,.69))
    rounded_sections(g,"white",[(0,.42,.74,.13,.12),(.02,.55,.86,.25,.24),
                      (.03,.75,.91,.30,.27),(.04,.94,.89,.22,.19),
                      (.02,1.05,.84,.06,.06)],14)
    for side,suffix in ((-1,"L"),(1,"R")):
        g.joint("Hind"+suffix, (side*.46,.47,.19))
        rounded_sections(g,fur,[(side*.58,.065,-.08,.20,.31),
                          (side*.60,.14,-.07,.27,.40),(side*.62,.29,.02,.30,.41),
                          (side*.57,.48,.14,.26,.32),(side*.49,.59,.19,.12,.19)],16)
        g.joint("Fore"+suffix,(side*.48,1.14,-.15))
        rounded_sections(g,fur,[(side*.23,.63,-.62,.09,.09),(side*.26,.71,-.64,.15,.15),
                          (side*.36,.85,-.55,.18,.17),(side*.47,1.03,-.34,.17,.16),
                          (side*.46,1.17,-.20,.12,.13)],14)
    g.joint("Head",(0,1.36,-.10))
    rounded_sections(g,fur,[(0,1.22,-.27,.35,.31),(0,1.35,-.29,.70,.51),
                    (0,1.57,-.30,.95,.68),(0,1.84,-.28,1.00,.73),
                    (0,2.11,-.23,.93,.68),(0,2.35,-.19,.75,.53),
                    (0,2.51,-.15,.46,.34),(0,2.56,-.14,.15,.13)],28)
    for side in (-1,1):
        g.blob("eye",(side*.37,1.84,-.951),(.092,.115,.065),13,8)
        g.blob("shine",(side*.37-.025,1.877,-1.004),(.024,.027,.018),8,5)
        g.blob("blush",(side*.66,1.64,-.815),(.134,.069,.055),12,7)
        g.tube("chocolate",[(0,1.669,-.998),(side*.046,1.62,-.981),
               (side*.097,1.622,-.976),(side*.139,1.66,-.979)],
               [.012,.014,.013,.007],7)
    g.blob("rose",(0,1.70,-.992),(.073,.05,.035),11,7)
    for side,suffix in ((-1,"L"),(1,"R")):
        root=side*.45
        g.joint("Ear"+suffix,(root,2.34,-.17),"Head")
        heights=(2.28,2.49,2.76,3.11,3.50,3.83,4.08,4.22,4.27)
        widths=(.14,.21,.248,.267,.25,.22,.17,.10,.024)
        rings=[]
        for i,(height,width) in enumerate(zip(heights,widths)):
            t=(height-2.28)/1.99
            lean=(.46 if side<0 else .28)*t+.06*sin(pi*t)
            rings.append((root+side*lean,height-.16*t*(side<0),-.16+.09*t-.105*t*t,
                          width,.09+.055*sin(pi*t) if i<len(widths)-1 else .025))
        rounded_sections(g,fur,rings,18)
        # Inset follows the forward arc of the same elliptical sections.
        rows=[]
        for i in range(1,len(rings)-1):
            x,y,z,rx,rz=rings[i]
            spread=.86*sin(pi*(i-.8)/(len(rings)-2.5))**.55
            rows.append([(x+rx*sin(a*spread),y,z-rz*cos(a*spread)-.009)
                         for a in (-1,-.5,0,.5,1)])
        for a,b in zip(rows,rows[1:]):
            for j in range(4):
                g.quad("pink",a[j],b[j],b[j+1],a[j+1])
    g.joint("Body",(0,0,0))
    rounded_sections(g,"orange",[(.07,.40,-.76,.019,.018),(.035,.57,-.74,.093,.09),
                      (0,.83,-.73,.164,.15),(-.02,.99,-.71,.17,.155),
                      (-.03,1.08,-.69,.10,.095)],14)
    for i in range(4):
        a=i*2*pi/4+.3
        g.leaf("leaf" if i%2 else "leaflight",(-.03,1.06,-.69),
               (-.03+.20*cos(a),1.23+.06*(i%2),-.67+.14*sin(a)),.07,.05,5,2)


def sculpt_fluffy_collarette(g, root_y, root_z, tone, count=11):
    """Low triangle-count tapered fur/feather silhouette below the chin."""
    for i in range(count):
        angle = 2*pi*i/count
        x=cos(angle)*.57
        z=root_z+sin(angle)*.15
        g.leaf(tone,
               (x,root_y,z),
               (x*1.18,root_y-.32-(i%3)*.07,z-.14),
               .12+(i%3)*.019,.055,4,2)


def sculpt_sticker_personality(g, name, species):
    """Original miniature *3-D* props that make pet silhouettes read at mobile size.

    The user's examples are 2-D graphic references; these props translate their
    soft cheek shapes and recognizable character details into actual meshes.
    Keep these details tiny so all pets remain under the existing triangle budget.
    """
    if species=="lamb":
        # Pastel bow on the white fluffy collar, not an imported decal.
        g.joint("Body",(0,0,0))
        for side in (-1,1):
            g.blob("rose",(side*.23,1.47,-1.28),(.27,.18,.10),11,7)
        g.blob("gold",(0,1.47,-1.36),(.105,.10,.085),10,6)
        for side in (-1,1):
            g.leaf("pink",(side*.07,1.42,-1.28),
                   (side*.18,1.13,-1.27),.09,.025,4,2)
    elif species=="fox":
        g.joint("Head",g.joints["Head"][1])
        g.tube("leafdeep",[(-.48,1.25,-1.0),(0,1.14,-1.12),(.49,1.24,-1.0)],
               [.085,.093,.085],7)
        g.leaf("leaflight",(.15,1.19,-1.1),(.38,.77,-1.08),.18,.05,5,2)
        g.leaf("ivory",(.73,1.34,-1.15),(1.02,1.41,-1.13),.16,.06,4,2)
    elif species=="chick":
        g.joint("Body",(0,0,0))
        for side in (-1,1):
            g.blob("blush",(side*.56,1.29,-.59),(.16,.10,.045),9,6)
        # Small flower pin on the head, with a matte golden centre.
        pos=(.30,2.18,-.39)
        for i in range(5):
            a=2*pi*i/5
            g.leaf("ivory",pos,
                   (pos[0]+.17*cos(a),pos[1]+.18*sin(a),pos[2]-.035),
                   .08,.025,4,2)
        g.blob("gold",(pos[0],pos[1],pos[2]-.06),(.065,.06,.04),8,5)
    elif species=="axolotl":
        # The axolotl uses a single body mesh and gill joints, not a Head joint.
        g.joint("Body",(0,0,0))
        for side in (-1,1):
            g.blob("blush",(side*.80,1.19,-1.26),(.20,.095,.05),10,6)


def pug_puppy(g, coat, cream):
    """Compact pug puppy with a continuous piebald head, folded ears and curled tail."""
    from math import sqrt
    from generate_reference_glb import norm,cross
    from orchard_sculpt import rounded_sections

    g.joint("Body",(0,0,0))
    rounded_sections(g,cream,[(0,.22,.32,.42,.52),(0,.36,.34,.63,.77),
                     (0,.64,.35,.76,.97),(0,.90,.32,.73,.90),
                     (0,1.14,.21,.56,.67),(0,1.29,.07,.31,.38)])
    for side,suffix in ((-1,"L"),(1,"R")):
        for fore in (True,False):
            z=-.27 if fore else .86
            g.joint(("Fore" if fore else "Hind")+suffix,(side*.48,.67,z))
            rounded_sections(g,cream,[(side*.52,.045,z-.10,.16,.23),
                (side*.54,.12,z-.11,.22,.30),(side*.54,.25,z-.07,.23,.30),
                (side*.52,.45,z+.015,.16,.18),(side*.47,.65,z,.18,.21),
                (side*.39,.76,z+.02,.12,.15),(side*.35,.81,z+.03,.05,.07)],14)
    g.joint("Tail",(0,.79,1.09))
    g.tube(coat,[(0,.79,1.06),(.12,.87,1.33),(.26,1.10,1.48),
                 (.33,1.32,1.49)],[.18,.19,.17,.135],12)
    g.tube(cream,[(.33,1.32,1.49),(.35,1.46,1.39),(.32,1.50,1.24),(.28,1.43,1.13),(.25,1.33,1.15)],
           [.135,.115,.094,.070,.025],12)

    g.joint("Head",(0,1.09,-.19))
    # The first five latitude bands form an asymmetric ear/eye marking.
    # Both colours meet at exactly the same vertices along its wavy border.
    pole=norm((.72,.31,-.78))
    tangent=norm(cross(pole,(0,1,0)))
    tangent2=cross(pole,tangent)
    def head_vertex(i,j):
        a=2*pi*i/32
        lat=pi*j/18
        lat+=.11*sin(lat)*(sin(a+.3)+.38*sin(3*a-.8))
        u,v,w=[p*cos(lat)+sin(lat)*(t*cos(a)+q*sin(a))
               for p,t,q in zip(pole,tangent,tangent2)]
        return ((.93*u*(1-.095*v),1.59+.79*v,-.46+.73*w),
                norm((u/.93,(v+.095*u*u)/.79,w/.73)))
    for j in range(18):
        for i in range(32):
            coords=[(i,j),(i+1,j),(i+1,j+1),(i,j+1)]
            if j==0: coords.pop(1)
            if j==17: coords.pop(2)
            positions,normals=zip(*(head_vertex(a,b) for a,b in coords))
            mat=coat if j<5 else cream
            if len(coords)==3: g.tri(mat,*positions,*normals)
            else: g.quad(mat,*positions,vertex_normals=normals)

    for side,suffix in ((-1,"L"),(1,"R")):
        g.joint("Head",g.joints["Head"][1])
        x=side*.385
        y=1.67
        v=(y-1.59)/.79
        depth=-.46-.73*sqrt(1-v*v-(x/(.93*(1-.095*v)))**2)
        g.blob("eye",(x,y,depth-.013),(.092,.109,.06),13,8)
        g.blob("shine",(x-.026,y+.037,depth-.064),(.023,.028,.018),8,5)
        g.blob("blush",(side*.62,1.46,-1.002),(.132,.071,.044),11,7)
        g.joint("Ear"+suffix,(side*.70,1.99,-.35),"Head")
        rounded_sections(g,"brown",[(side*.94,1.34,-.44,.08,.11),
                    (side*.99,1.43,-.41,.21,.21),(side*1.00,1.59,-.37,.265,.29),
                    (side*.96,1.76,-.30,.25,.32),(side*.89,1.91,-.28,.22,.29),
                    (side*.75,2.06,-.30,.18,.22),(side*.69,2.11,-.30,.08,.10)],18)
    g.joint("Head",g.joints["Head"][1])
    g.blob("rose",(0,1.285,-1.162),(.103,.105,.062),12,8)
    for side in (-1,1):
        g.blob("cream",(side*.12,1.43,-1.125),(.198,.13,.129),14,8)
    g.blob("nose",(0,1.504,-1.239),(.113,.075,.064),13,8)
    # Neck scarf lies against the chest and swings with the body.
    g.joint("Body",(0,0,0))
    g.tube("brick",[(-.54,1.08,-.34),(-.34,1.01,-.50),(0,.97,-.57),
           (.34,1.01,-.50),(.54,1.08,-.34)],[.065,.066,.069,.066,.065],8)
    hem=[(-.365,1.0,-.53),(0,.96,-.595),(.365,1.0,-.53),
         (.22,.77,-.627),(.015,.59,-.645),(-.19,.73,-.63)]
    fold=(.035,.82,-.674)
    for j,p in enumerate(hem):
        g.tri("brick",fold,hem[(j+1)%len(hem)],p)
    g.blob("gold",(.04,.84,-.671),(.037,.039,.019),8,5)
