"""Shared authored detail sculpts for the headline kitten and bunny companions.

These are actual triangulated 3-D surfaces in the same scene as the gameplay
pet. No image generation, paper concept art, borrowed assets or extra
MeshPart instances. Coordinates match the existing Y-up / -Z-forward rig.
"""
from math import cos, pi, sin


def sculpt_kitten_face(g, base, second):
    """Feline ears, muzzle, cheek ruff and facial expression without orb spam."""
    from orchard_sculpt import loft

    # Proper triangular pinnae: broad at the skull and pointed at their tips.
    # The interior is a shallow pink leaf surface, not a solid pink cylinder.
    for side in (-1, 1):
        loft(g, base, [
            (side*.70, 2.25, -.51, .33, .28),
            (side*.87, 2.59, -.51, .36, .21),
            (side*1.05, 2.97, -.50, .20, .13),
            (side*1.11, 3.27, -.49, .026, .027),
        ], sides=12)
        g.leaf("rose" if base == "pink" else "pink",
               (side*.83, 2.57, -.76),
               (side*1.10, 3.15, -.62), .205, .045, 6, 3)
        # Fine cream ear guard fur points towards the viewer.
        for j in range(3):
            start=(side*(.80 + j*.10), 2.51+j*.105, -.76)
            tip=(side*(1.03+j*.12), 2.64+j*.13, -.78)
            g.leaf("ivory", start, tip, .062, .021, 3, 2)

    # Two sculpted muzzle lobes instead of a generic big oval balloon.
    for side in (-1, 1):
        g.blob("ivory", (side*.19, 1.40, -1.40),
               (.235, .145, .132), 13, 8)
        # No black brow ridges: at game-camera scale they looked angry.
        # Tiny bead eyes already give the soft, friendly sticker expression.
        # Cheek ruff has pointed individual clumps, not sphere tufts.
        for j in range(2):
            y=1.42+j*.13
            basept=(side*.74, y, -1.16)
            tip=(side*(.94 + .03*j), y+.035*(j-1), -1.16)
            g.leaf("ivory", basept, tip, .075, .022, 4, 2)

    g.blob("rose", (0, 1.49, -1.535), (.083,.058,.052), 11, 7)
    # Lower central cleft and a small smile follow the two muzzle lobes.
    g.tube("chocolate", [
        (0, 1.449, -1.54),
        (0, 1.390, -1.545),
        (-.088, 1.362, -1.52),
    ], [.018,.018,.009], 6)
    g.tube("chocolate", [
        (0, 1.390, -1.545),
        (.088, 1.362, -1.52),
    ], [.018,.008], 6)

    # Soft top-of-head tufts emphasize a swept feline fur silhouette.
    for i in range(5):
        x=(i-2)*.17
        g.leaf(second if i%2 else base,
               (x, 2.49, -.65),
               (x+(i-2)*.055,2.71+(.065 if i%2 else 0),-.67),
               .085, .032, 4, 2)


def _rounded_sections(g, pigment, rings, sides=20):
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


def seated_rabbit(g, fur):
    """A compact pear-shaped lap rabbit, with paws wrapped around its carrot."""
    g.joint("Body",(0,0,0))
    _rounded_sections(g,fur,[(0,.10,.19,.39,.37),(0,.25,.22,.65,.55),
                       (0,.58,.22,.78,.65),(0,.95,.14,.68,.54),
                       (0,1.28,-.02,.49,.40),(0,1.49,-.10,.33,.26)])
    g.joint("Tail",(0,.58,.69))
    _rounded_sections(g,"white",[(0,.42,.74,.13,.12),(.02,.55,.86,.25,.24),
                      (.03,.75,.91,.30,.27),(.04,.94,.89,.22,.19),
                      (.02,1.05,.84,.06,.06)],14)
    for side,suffix in ((-1,"L"),(1,"R")):
        g.joint("Hind"+suffix, (side*.46,.47,.19))
        _rounded_sections(g,fur,[(side*.58,.065,-.08,.20,.31),
                          (side*.60,.14,-.07,.27,.40),(side*.62,.29,.02,.30,.41),
                          (side*.57,.48,.14,.26,.32),(side*.49,.59,.19,.12,.19)],16)
        g.joint("Fore"+suffix,(side*.48,1.14,-.15))
        _rounded_sections(g,fur,[(side*.23,.63,-.62,.09,.09),(side*.26,.71,-.64,.15,.15),
                          (side*.36,.85,-.55,.18,.17),(side*.47,1.03,-.34,.17,.16),
                          (side*.46,1.17,-.20,.12,.13)],14)
    g.joint("Head",(0,1.36,-.10))
    _rounded_sections(g,fur,[(0,1.22,-.27,.35,.31),(0,1.35,-.29,.70,.51),
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
        _rounded_sections(g,fur,rings,18)
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
    _rounded_sections(g,"orange",[(.07,.40,-.76,.019,.018),(.035,.57,-.74,.093,.09),
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
    if species=="kitten":
        # Curved collar, dangling tiny bell and tiny cheek spots.
        g.joint("Head",g.joints["Head"][1])
        g.tube("rose",[(-.58,1.24,-1.04),(-.39,1.16,-1.17),
                        (0,1.12,-1.24),(.39,1.16,-1.17),(.58,1.24,-1.04)],
               [.062,.069,.074,.069,.062],7)
        g.blob("gold",(0,1.06,-1.32),(.15,.15,.105),10,6)
        g.tube("chocolate",[(-.055,1.01,-1.421),(.04,1.01,-1.421)],
               [.014,.014],5)
        for side in (-1,1):
            g.blob("blush",(side*.73,1.43,-1.16),(.15,.075,.039),9,5)
    elif species=="lamb":
        # Pastel bow on the white fluffy collar, not an imported decal.
        g.joint("Body",(0,0,0))
        for side in (-1,1):
            g.blob("rose",(side*.23,1.47,-1.28),(.27,.18,.10),11,7)
        g.blob("gold",(0,1.47,-1.36),(.105,.10,.085),10,6)
        for side in (-1,1):
            g.leaf("pink",(side*.07,1.42,-1.28),
                   (side*.18,1.13,-1.27),.09,.025,4,2)
    elif species=="dog":
        g.joint("Head",g.joints["Head"][1])
        # Triangular kerchief follows the throat down under the muzzle.
        g.leaf("brick",(-.55,1.19,-1.17),(.55,1.19,-1.17),.25,.07,5,2)
        g.leaf("brick",(0,1.21,-1.18),(0,.72,-1.18),.35,.065,5,2)
        g.blob("gold",(0,1.09,-1.26),(.09,.09,.05),9,5)
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
