"""Original stylized species-specific GLB pet sculpts (reference-friendly v2).
This module generates geometry, not AI pictures and not a Roblox rendering.
Coordinates: Y up / faces toward -Z. All characters fit a common import pivot.
"""
from math import sin, cos, pi

SPECIES = {
  "Pip":"kitten","Zuzu":"kitten","Mochi":"lamb","Pickle":"frog",
  "Bloop":"axolotl","Nugget":"chick","Tofu":"lamb","Wobble":"bear",
  "Spark":"fox","Gloop":"axolotl","Luma":"lamb","Snorf":"dog",
  "Floofle":"bunny","Quibble":"crab","Fizzle":"salamander",
  "Puddle":"axolotl","Sprig":"deer","Twinkle":"butterfly",
  "Mallow":"bear","Pebble":"turtle","Noodle":"ferret",
  "Swoop":"owl","Rumble":"dinosaur","Doodle":"sprite",
  "Crumble":"cookie","Squiggle":"octopus","Glimmer":"unicorn",
  "Splat":"frog","Puffin":"puffin","Echo":"bat",
}

def sculpt_species(name, base, second, S):
    from pet_detail_sculpts import (
        sculpt_bunny_ears, sculpt_fluffy_collarette, sculpt_kitten_face,
        sculpt_sticker_personality,
    )
    g=S("Pet_"+name)
    k=SPECIES[name]
    def side_joint(label,side,pivot,parent="Body"):
        g.joint(label+("L" if side<0 else "R"),pivot,parent)
    def leg(side,z):
        side_joint("Fore" if z<0 else "Hind",side,(side*.60,.62,z))
    def ell(mat,center,radii,seg=14,rings=8):
        g.blob(mat,center,radii,seg,rings,0.008)
    def tube(mat,points,r):
        g.tube(mat,points,r,8)
    def lf(mat,root,tip,w,curve=.07):
        g.leaf(mat,root,tip,w,curve,5,3)
    def foot(side,z,x=.65,y=.26,scale=1,mat=None):
        ell(mat or base,(side*x,y,z),(.28*scale,.21*scale,.39*scale))
    def face(cx,cy,cz,rx=1.02,ry=.88,rz=.67,eyes=.45,blush=True,smile=True,
             nose=True,eye_scale=.22):
        # The sticker references use soft, uninterrupted plush faces and
        # SMALL black bead eyes. Former concentric white eyeballs made every
        # creature resemble a toy frog rather than a baby animal.
        ell(base,(cx,cy,cz),(rx,ry,rz),20,13)
        for side in (-1,1):
            ex=cx+side*eyes
            ey=cy+.095*ry
            # Place each eye on the ellipsoid's FRONT surface, taking its
            # horizontal position into account (not a floating flat plane).
            faceDepth=rz*(1-(eyes/rx)**2-(.095)**2)**.5
            ez=cz-faceDepth-.022
            dot=.116*(eye_scale/.22)
            ell("eye",(ex,ey,ez),(dot,dot*1.24,.053),12,8)
            ell("shine",(ex-side*.036,ey+.045,ez-.05),
                (.027,.031,.017),8,5)
            if blush:
                bx=rx*.71
                blushDepth=rz*(1-(bx/rx)**2-(.17)**2)**.5
                ell("blush",(cx+side*bx,cy-.17*ry,
                    cz-blushDepth-.018),(.172,.091,.033),10,6)
        if nose:
            # Previously this was inside the head mesh, so faces appeared
            # to lack noses. Push a small matte nose outside the surface.
            ell("chocolate",(cx,cy-.205*ry,cz-rz*.98-.035),
                (.092,.061,.047),10,6)
        if smile:
            z=cz-rz*.95-.025
            tube("chocolate",[(cx-.137,cy-.31*ry,z+.01),
                (cx,cy-.365*ry,z-.016),
                (cx+.137,cy-.31*ry,z+.01)],[.016,.019,.016])
    def ear(side,basept,tip,length=.32,color=None):
        # 3D tapered ear with a thin inset leaf.
        g.tube(color or base,[basept,tuple((p+q)/2 for p,q in zip(basept,tip)),tip],
               [length,length*.66,.018],10)
        inset_root=(basept[0],basept[1]+.22,basept[2]-.14)
        inset_tip=(tip[0],tip[1]-.10,tip[2]-.05)
        lf("pink",inset_root,inset_tip,length*.54)
    def coat_patch(color,center,radii):ell(color,center,radii,13,8)
    if k in ("kitten","fox","dog","bunny","ferret","bear","lamb","deer","unicorn",
             "salamander","dinosaur","cookie"):
        # Body length, leg length, head placement intentionally differ by family.
        bodyshape = {
          "kitten":((0,.82,.38),(.85,.60,1.27)),
          "fox":((0,.85,.39),(.73,.56,1.32)),
          "dog":((0,.88,.36),(.93,.67,1.25)),
          "bunny":((0,.73,.45),(.83,.70,.95)),
          "ferret":((0,.72,.69),(.69,.50,1.75)),
          "bear":((0,1.02,.45),(1.11,.87,1.15)),
          "lamb":((0,1.01,.48),(1.12,.81,1.22)),
          "deer":((0,1.40,.55),(.64,.60,1.19)),
          "unicorn":((0,1.36,.52),(.79,.68,1.36)),
          "salamander":((0,.66,.62),(.65,.41,1.55)),
          "dinosaur":((0,1.10,.67),(1.00,.87,1.45)),
          "cookie":((0,.93,.46),(1.06,.88,1.00)),
        }
        (bc,br)=bodyshape[k];ell(base,bc,br,19,12)
        chestbase = (bc[0],bc[1]-.22,bc[2]-br[2]*.60)
        if k not in ("salamander","dinosaur"):
            coat_patch("ivory",chestbase,(br[0]*.66,br[1]*.65,.22))
        for side in (-1,1):
            if k in ("deer","unicorn"):
                for z in (-.30,1.24):
                    leg(side,z)
                    g.tube(base,[(side*.48,1.19,z),(side*.52,.64,z-.03),
                                (side*.54,.16,z-.08)],[.20,.17,.10],9)
                    foot(side,z-.08,.54,.11,.72,"chocolate")
            elif k not in ("salamander","dinosaur"):
                for z in (-.25,1.18):
                    leg(side,z)
                    ell(base,(side*(.56 if k=="ferret" else .68),.38,z),
                        (.26,.38,.33),12,7)
                    foot(side,z-.14,.66,.18,.99,"ivory" if k in ("lamb","bunny") else second)
            else:
                for z in (-.39,1.48):
                    leg(side,z)
                    foot(side,z,.64,.20,.83)
        g.joint("Body",(0,0,0))
        headprops = {
          "kitten":((0,1.74,-.58),1.02,.87,.80,.45),
          "fox":((0,1.78,-.65),.92,.83,.78,.43),
          "dog":((0,1.77,-.61),1.04,.87,.83,.43),
          "bunny":((0,1.72,-.57),.91,.83,.77,.40),
          "ferret":((0,1.49,-.83),.76,.66,.71,.33),
          "bear":((0,1.95,-.44),1.06,.90,.78,.44),
          "lamb":((0,1.91,-.56),.93,.83,.72,.38),
          "deer":((0,2.26,-.61),.72,.75,.77,.33),
          "unicorn":((0,2.25,-.70),.84,.83,.88,.35),
          "salamander":((0,1.20,-.82),1.01,.55,.69,.43),
          "dinosaur":((0,2.02,-.69),1.03,.85,.83,.45),
          "cookie":((0,1.89,-.49),.94,.80,.69,.42),
        }
        (hc,rx,ry,rz,es)=headprops[k]
        g.joint("Head",(0,hc[1]-ry*.62,hc[2]+rz*.32))
        face(*hc,rx,ry,rz,es,smile=k!="kitten",
            nose=k not in ("salamander","dinosaur","kitten"))
        if k in ("kitten","fox"):
            if k=="kitten":
                sculpt_kitten_face(g, base, second)
            for side in (-1,1):
                if k=="fox":
                    tip=(side*1.11,3.06,-.55)
                    ear(side,(side*.72,2.29,-.48),tip,.32)
                for t in range(3):
                    y=1.58+t*.105
                    # Fine matte whiskers should read as whiskers, not
                    # floating white blades crossing the whole face.
                    tube("chocolate",[(side*.34,y,-1.42),
                        (side*.74,y-.035,-1.49),
                        (side*1.09,y+(t-1)*.07,-1.40)],
                        [.010,.007,.003])
            # Fox gets a broad white mask; kitten has two individually
            # sculpted muzzle lobes already and should not get a third
            # bulbous oval pasted across its nose and mouth.
            if k=="fox":
                # Soft white chin and pointed cheek tufts instead of two
                # overlapping round masks stuck onto a red fox head.
                ell("ivory",(0,1.40,-1.37),(.37,.18,.18),14,8)
                for side in (-1,1):
                    lf("ivory",(side*.37,1.46,-1.26),
                       (side*.88,1.21,-1.17),.17,.032)
            g.joint("Tail",(0,.85,1.35))
            tube(base,[(.24,.82,1.39),(.58,1.05,1.87),
                (.87,1.69,2.02),(.76,2.16,2.09)],[.27,.29,.22,.06])
            if k=="fox":
                # Cream tip follows the articulated tail, not the head.
                for j in range(5):
                    a=j*2*pi/5
                    lf("ivory",(.76,2.01,2.05),
                       (.75+sin(a)*.20,2.29+cos(a)*.20,2.16),
                       .16,.02)
                g.joint("Head",g.joints["Head"][1])
        elif k=="dog":
            for side in (-1,1):
                ell(second,(side*.99,2.08,-.26),(.38,.70,.34),15,10)
            ell("ivory",(0,1.42,-1.53),(.62,.37,.36))
            ell("black",(0,1.59,-1.84),(.21,.15,.13))
            g.joint("Tail",(0,.85,1.35))
            tube(base,[(0,.88,1.55),(.4,1.20,1.93),(.7,1.30,2.07)],
                [.25,.17,.06])
            g.joint("Head",g.joints["Head"][1])
            if name=="Snorf":
                for side in (-1,1):
                    ell("chocolate",(side*.77,1.80,-1.17),(.27,.22,.08),12,7)
                ell("chocolate",(0,1.55,-1.68),(.28,.16,.10))
                # A tiny tongue below the nose gives the dog a unique
                # playful smile without a flat facial expression decal.
                ell("rose",(0,1.29,-1.78),(.10,.13,.045),10,6)
        elif k=="bunny":
            sculpt_bunny_ears(g, base)
            ell("white",(0,.96,1.46),(.38,.39,.40))
            # The rabbit's face stays a single soft plush surface; the
            # original giant cheek balls hid the small sticker-style mouth.
            for side in (-1,1):
                ell("blush",(side*.57,1.34,-1.20),(.17,.085,.032),9,6)
        elif k=="ferret":
            for side in (-1,1):
                ell(second,(side*.63,1.94,-.64),(.32,.38,.31),12,7)
                ell("ivory",(side*.26,1.23,-1.48),(.31,.21,.29))
            g.joint("Tail",(0,.85,1.35))
            tube(base,[(0,.71,2.06),(.22,.78,2.58),(.62,1.11,2.71)],[.22,.21,.10])
        elif k in ("lamb","bear","cookie"):
            for side in (-1,1):
                if k=="bear":
                    ell(base,(side*.75,2.54,-.39),(.39,.38,.31),15,9)
                    ell("blush",(side*.82,2.59,-.66),(.22,.18,.10))
                else:
                    ell(second,(side*.96,2.28,-.27),(.38,.37,.41))
            if k=="lamb":
                sculpt_fluffy_collarette(g, 1.50, -.95, "ivory", 11)
                for i in range(9):
                    a=i*2*pi/9
                    ell("cream",(sin(a)*.77,2.55+cos(a)*.17,-.31+cos(a)*.27),
                        (.37,.35,.36),11,7)
                for z in (-.08,.37,.85,1.24):
                    for side in (-1,1):
                        ell("cream",(side*.77,1.58,z),(.35,.33,.39),11,7)
            if k=="cookie":
                for i in range(8):
                    a=i*2*pi/8
                    ell("chocolate",(sin(a)*.80,1.14+cos(a)*.63,1.08),
                        (.15,.10,.13),10,6)
                ell("straw",(0,2.61,-.49),(.63,.16,.68),13,7)
        elif k in ("deer","unicorn"):
            for side in (-1,1):
                ear(side,(side*.57,2.63,-.43),(side*1.02,3.18,-.42),.23)
            ell("ivory",(0,1.98,-1.47),(.40,.32,.41))
            g.joint("Tail",(0,.85,1.35))
            tube(second,[(0,1.48,1.7),(.10,1.17,2.1),(.18,.94,2.38)],
                [.30,.21,.07])
            g.joint("Head",g.joints["Head"][1])
            if k=="deer":
                for side in (-1,1):
                    tube("bark",[(side*.37,2.85,-.36),(side*.52,3.42,-.37),
                        (side*.82,3.81,-.34)],[.10,.08,.02])
                    tube("bark",[(side*.49,3.30,-.38),(side*.95,3.47,-.38)],[.06,.015])
                for i in range(7):
                    a=i*2*pi/7
                    ell("cream",(sin(a)*.45,1.93, .67+cos(a)*.58),
                        (.12,.07,.14),10,6)
            else:
                tube("gold",[(0,2.95,-1.03),(0,3.47,-1.18),(0,3.81,-1.31)],
                     [.21,.13,.012])
                for i in range(5):
                    ell("pink" if i%2 else "lilac",
                        (.52,2.75-i*.17,-.17+i*.24),(.37,.23,.35),11,7)
        elif k in ("salamander","dinosaur"):
            g.joint("Tail",(0,.85,1.35))
            tube(base,[(0,.87,1.77),(0,.66,2.27),(0,.43,2.86),(0,.34,3.21)],
                 [.43,.36,.23,.017])
            for i in range(5):
                z=.22+i*.43
                lf("leaflight" if k=="dinosaur" else "gold",
                   (0,1.79,z),(0,2.36-i*.10,z+.08),.27)
            if k=="salamander":
                for side in (-1,1):
                    ell("gold",(side*.38,1.48,-1.38),(.16,.10,.10))
        g.joint("Head",g.joints["Head"][1])
        # different hats, masks, gradients painted as geometry.
        if name=="Zuzu":
            for i in range(3):
                ell("gold",(-.55+i*.24,2.52,-.49+i*.03),(.14,.24,.16))
        elif name=="Doodle":
            ell("lilac",(0,2.65,-.49),(.65,.12,.54))
        elif name=="Mallow":
            ell("cream",(0,2.76,-.42),(.79,.24,.73))
        elif name=="Luma":
            ell("gold",(0,2.69,-.48),(.18,.16,.19))
        elif name=="Crumble":
            for i in range(3):
                ell("brown",(-.45+i*.45,2.36,-.85),(.13,.14,.08))
    elif k in ("frog","axolotl","turtle","chick","owl","puffin","butterfly",
               "crab","octopus","bat","sprite"):
        if k=="frog":
            ell(base,(0,.78,.21),(1.20,.70,1.08),20,13)
            ell("ivory",(0,.42,-.48),(.80,.29,.56),17,10)
            for side in (-1,1):
                g.joint("Body",(0,0,0))
                # Raised round frog eye sockets are a species feature.
                # The pupils themselves must be small storybook beads.
                ell(base,(side*.62,1.36,-.56),(.44,.42,.44),14,9)
                ell("eye",(side*.65,1.42,-.94),(.135,.155,.064),12,8)
                ell("shine",(side*.60,1.48,-1.001),(.036,.039,.016),8,5)
                for z in (-.4,.81):
                    leg(side,z)
                    ell(base,(side*1.02,.26,z),(.55,.24,.44),14,8)
                    for j in range(3):
                        ell("leaflight",(side*(1.24+j*.18),.12,z-.3+j*.16),
                            (.22,.10,.24),10,6)
            g.joint("Body",(0,0,0))
            # Short smile centred on the snout, not a heavy black stripe
            # stretching from one side of the body to the other.
            tube("chocolate",[(-.23,.62,-.98),(0,.575,-1.095),(.23,.62,-.98)],
                 [.019,.020,.019])
        elif k=="axolotl":
            ell(base,(0,.71,.50),(.73,.51,1.54),18,12)
            face(0,1.36,-.73,1.14,.62,.70,.47,nose=False)
            for side in (-1,1):
                side_joint("Gill",side,(side*1.04,1.5,-.50))
                for j in range(3):
                    yy=1.85-j*.36
                    pts=[(side*1.04,yy,-.50),(side*1.58,yy+.16,-.44),
                         (side*1.86,yy+.10,-.38)]
                    tube("pink",pts,[.13,.10,.025])
                    for q in range(3):
                        lf("rose",pts[1],(side*(1.53+q*.12),yy+.20+q*.14,-.39),.11)
                for z in (-.3,1.26):
                    leg(side,z)
                    foot(side,z,.60,.20,.63)
            g.joint("Tail",(0,.88,1.69))
            lf("pink",(0,.88,1.69),(0,1.04,2.75),.44)
        elif k=="turtle":
            ell(base,(0,.46,.68),(.84,.36,1.02),19,12)
            # Lower, more compact carapace: the baby turtle's little face
            # should lead the silhouette rather than vanish under a giant
            # dark green ball. Pattern is bound to the same original body rig.
            ell("leafdeep",(0,.95,.78),(1.13,.70,1.18),23,14)
            ell(second,(0,1.52,.78),(.82,.15,.88),16,9)
            for i in range(8):
                a=i*2*pi/8
                ell("leaflight",(sin(a)*.70,1.53,.78+cos(a)*.74),
                    (.25,.065,.27),11,7)
            g.joint("Head",(0,.84,-.64))
            face(0,.95,-1.10,.64,.55,.65,.29)
            for side in (-1,1):
                for z in (-.22,1.10):
                    leg(side,z)
                    ell(base,(side*1.05,.24,z),(.47,.24,.37),14,8)
            g.joint("Body",(0,0,0))
            ell("ivory",(0,.55,1.90),(.25,.25,.38))
        elif k in ("chick","owl","puffin"):
            palette = "cream" if k=="owl" else base
            ell(base,(0,1.07,.28),(.99,1.14,.92),21,14)
            for side in (-1,1):
                if k=="owl":
                    ell("cream",(side*.47,1.48,-.74),(.48,.62,.23),15,10)
                side_joint("Wing",side,(side*.78,1.49,.24))
                ell(second,(side*.91,1.11,.24),(.39,.66,.58),15,10)
                g.joint("Body",(0,0,0))
                ell("eye",(side*.37,1.46,-.936),(.126,.154,.070),12,8)
                ell("shine",(side*.325,1.515,-1.003),(.031,.036,.015),8,5)
                tube("orange",[(side*.45,.24,.14),(side*.45,.04,-.11)],
                     [.12,.08])
            # A tiny triangulated beak has a recognizable chick silhouette
            # without the oversized carrot-like tube from the old model.
            beak_top=(0,1.20,-.95)
            beak_left=(-.16,1.095,-1.02)
            beak_right=(.16,1.095,-1.02)
            beak_tip=(0,1.015,-1.26)
            g.tri("orange",beak_top,beak_left,beak_tip)
            g.tri("orange",beak_top,beak_tip,beak_right)
            g.tri("ochre",beak_left,beak_right,beak_tip)
            g.tri("ochre",beak_top,beak_right,beak_left)
            if k=="chick":
                for i in range(3):
                    lf("straw",(-.20+i*.20,2.14,.16),(-.32+i*.29,2.67,.12),.17)
            if k=="owl":
                for side in (-1,1):
                    lf(base,(side*.60,1.94,-.10),(side*.84,2.51,-.11),.22)
            if k=="puffin":
                ell("ivory",(0,1.01,-.72),(.61,.66,.22))
                ell("orange",(0,1.08,-1.26),(.34,.23,.34),12,7)
        elif k=="butterfly":
            ell(base,(0,1.43,.17),(.34,.85,.32),18,11)
            for side in (-1,1):
                side_joint("Wing",side,(side*.13,1.62,.19))
                for sign,scale in ((1,1),(-1,.66)):
                    mat="pink" if sign==1 else "lilac"
                    a=(side*.13,1.62,.19)
                    b=(side*(1.74 if sign==1 else 1.42),
                        2.79 if sign==1 else .71, .40)
                    lf(mat,a,b,.91*scale,.24)
                    ell("gold",(side*1.21,2.11 if sign==1 else .89,.40),
                        (.22,.18,.11),12,7)
                g.joint("Body",(0,0,0))
                tube("chocolate",[(side*.10,2.12,-.13),
                    (side*.38,2.66,-.15)],[.055,.025])
            face(0,1.64,-.20,.48,.49,.39,.20,nose=False,smile=False)
        elif k=="crab":
            ell(base,(0,.72,.21),(1.43,.61,1.02),22,13)
            ell(second,(0,.93,-.33),(1.07,.29,.68),17,9)
            for side in (-1,1):
                side_joint("Claw",side,(side*.82,.65,-.41))
                tube(base,[(side*.82,.65,-.41),(side*1.47,.75,-.64),
                    (side*2.04,.85,-.90)],[.24,.20,.12])
                ell(second,(side*2.09,.92,-1.04),(.50,.43,.52),16,11)
                for j in range(3):
                    y=.53-j*.07
                    tube(base,[(side*1.04,y,j*.36),(side*1.56,y-.21,.5+j*.42),
                        (side*1.83,.16,.63+j*.42)],[.13,.11,.04])
                g.joint("Body",(0,0,0))
                tube(base,[(side*.51,1.16,-.52),(side*.52,1.67,-.70)],
                     [.13,.09])
                ell("eye",(side*.53,1.77,-.77),(.25,.25,.22),13,8)
                ell("shine",(side*.47,1.88,-.97),(.07,.07,.03),9,6)
            tube("chocolate",[(-.29,.63,-.80),(0,.59,-.88),(.29,.63,-.80)],
                 [.025,.025,.025])
        elif k=="octopus":
            ell(base,(0,1.05,.28),(1.18,1.06,1.03),23,14)
            for i in range(8):
                a=i*2*pi/8
                g.joint("Tendril"+str(i),(sin(a)*.58,.45,cos(a)*.60))
                tube(base,[(sin(a)*.58,.45,cos(a)*.60),
                    (sin(a)*1.44,.29,cos(a)*1.37),
                    (sin(a)*1.81,.50,cos(a)*1.76)],[.25,.18,.048])
                for j in range(2):
                    ell("pink",(sin(a)*(1+j*.21),.12,cos(a)*(.98+j*.19)),
                        (.12,.05,.12),8,5)
            g.joint("Body",(0,0,0))
            for side in (-1,1):
                ell("eye",(side*.44,1.35,-.72),(.20,.26,.10))
                ell("shine",(side*.36,1.47,-.82),(.065,.067,.028),9,6)
                ell("blush",(side*.86,1.02,-.52),(.22,.12,.07),10,6)
        elif k=="bat":
            ell(base,(0,1.17,.30),(.80,1.05,.71),20,13)
            face(0,1.82,-.29,.80,.67,.67,.31)
            for side in (-1,1):
                g.joint("Body",(0,0,0))
                ear(side,(side*.50,2.29,-.28),(side*.79,3.19,-.32),.27)
                side_joint("Wing",side,(side*.58,1.45,.14))
                for layer in range(3):
                    lf("violet" if layer==0 else second,
                       (side*.67,1.59,.32),
                       (side*(2.70-layer*.35),2.15-layer*.43,.64),
                       .66-layer*.14,.20)
            g.joint("Body",(0,0,0))
            for side in (-1,1):
                foot(side,.46,.50,.17,.56)
        elif k=="sprite":
            ell(base,(0,1.34,.32),(.81,.91,.79),19,12)
            face(0,1.86,-.41,.83,.73,.69,.37,nose=False)
            for side in (-1,1):
                side_joint("Wing",side,(side*.72,1.55,.15))
                lf("lilac",(side*.72,1.55,.15),(side*1.71,2.31,.17),.41,.25)
            g.joint("Body",(0,0,0))
            for i in range(6):
                a=i*2*pi/6
                ell("gold",(sin(a)*1.08,1.82+cos(a)*.82,.12),
                    (.12,.12,.12),10,6)
    # Translate the supplied sticker art direction into original 3D shapes,
    # but retain existing species, unique personalities and articulated joints.
    sculpt_sticker_personality(g, name, k)
    from storybook_family_sculpts import add_family_details
    add_family_details(g, name, k, base, second)
    if "Head" in g.joints:
        g.joint("Head",g.joints["Head"][1])
    else:
        g.joint("Body",(0,0,0))
    # No recycled animal with a different name: special variants get original details.
    if name in ("Wobble","Mochi"):
        ell("gold",(0,2.53,-.46),(.31,.22,.32),11,7)
    if name=="Gloop":
        for i in range(4):
            ell("cream",(sin(i*1.4)*.56,1.85,cos(i*.9)*.58),(.13,.10,.13),10,6)
    if name=="Noodle":
        for side in (-1,1):
            lf("ivory",(side*.73,1.91,-.66),(side*1.14,2.48,-.47),.24)
    if name=="Echo":
        ell("cream",(0,1.04,-.48),(.37,.35,.17))
    if name=="Spark":
        lf("gold",(0,2.37,-.41),(.15,2.92,-.35),.19)
    return g
