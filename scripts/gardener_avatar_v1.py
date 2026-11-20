"""Original chibi gardener for Roblox R15. Each named mesh maps to one moving body part.

Purpose: original art based on overall cozy garden style, not a copy of any character.
All assets are real 3D geometry with normals, UV atlas and no external source meshes.
Y-up, face -Z. Each sculpt is local to an R15 part pivot, so engine animations remain.
"""
from math import sin,cos,pi

R15_PARTS=[
 "Head","UpperTorso","LowerTorso",
 "LeftUpperArm","LeftLowerArm","LeftHand",
 "RightUpperArm","RightLowerArm","RightHand",
 "LeftUpperLeg","LeftLowerLeg","LeftFoot",
 "RightUpperLeg","RightLowerLeg","RightFoot"
]

def sculpt_chibi_part(part,S):
    g=S("Avatar_"+part)
    def blob(mat,at,size,seg=17,rings=11):
        g.blob(mat,at,size,seg,rings,.012)
    def line(mat,pts,wide):
        g.tube(mat,pts,[wide]*len(pts),7)
    def leaf(mat,a,b,w):
        g.leaf(mat,a,b,w,.08,5,3)
    def flower(at,scale=1):
        for j in range(5):
            a=2*pi*j/5
            leaf("cream",at,(at[0]+cos(a)*.18*scale,
                              at[1]+sin(a)*.18*scale,at[2]-.03),.09*scale)
        blob("gold",(at[0],at[1],at[2]-.08*scale),
             (.07*scale,.075*scale,.05*scale),11,7)
    if part=="Head":
        # Back hair is volumetric and slightly larger than the head.
        blob("chocolate",(0,.05,.27),(.92,.99,.78),22,14)
        # Low round head with visible muzzle cheeks, not a realistic face.
        blob("peach",(0,-.07,-.21),(.82,.79,.70),23,15)
        # Cartoon bob locks on both cheeks.
        for side in (-1,1):
            blob("chocolate",(side*.77,-.18,.00),(.30,.68,.50),15,10)
            blob("brown",(side*.85,-.36,-.33),(.19,.37,.26),13,9)
        # Curved bangs and top layer.
        for i in range(6):
            x=-.65+i*.26
            blob("chocolate",(x,.60,-.58),
                 (.21,.28+(i%2)*.12,.24),11,8)
        blob("chocolate",(0,.78,.13),(.80,.25,.67),16,9)
        # Slightly rounded, not protruding facial features.
        for side in (-1,1):
            blob("black",(side*.32,-.02,-.895),(.098,.145,.062),13,9)
            blob("shine",(side*.29,.04,-.953),(.034,.048,.019),9,6)
            blob("blush",(side*.55,-.24,-.77),(.17,.09,.045),12,7)
            line("chocolate",[(side*.22,.28,-.852),(side*.39,.25,-.840)],.022)
        blob("orange",(0,-.21,-.903),(.066,.042,.035),10,6)
        line("chocolate",[(-.14,-.37,-.846),(0,-.42,-.879),(.14,-.37,-.848)],.028)
        # Two cream five-petal hair flowers on the right side.
        flower((.67,.63,-.72),1.14)
        flower((.84,.42,-.65),.78)
    elif part=="UpperTorso":
        # Cream-white puff-sleeved tee and blue suspender bib.
        blob("ivory",(0,0,.0),(.76,.63,.52),19,12)
        blob("sky",(0,-.12,-.455),(.50,.43,.12),17,9)
        for side in (-1,1):
            line("sky",[(side*.48,.51,-.44),(side*.46,.13,-.54),
                        (side*.34,-.25,-.54)],.115)
            blob("ivory",(side*.70,.35,0),(.28,.34,.43),13,9)
            blob("gold",(side*.39,.28,-.582),(.08,.075,.06),11,6)
        # Central seam and little pocket.
        line("blue",[(0,-.28,-.571),(0,-.51,-.55)],.026)
        blob("sky",(0,-.38,-.565),(.19,.12,.036),13,7)
    elif part=="LowerTorso":
        blob("sky",(0,.03,0),(.76,.55,.50),19,12)
        blob("blue",(0,-.38,-.045),(.76,.14,.47),16,8)
        for side in (-1,1):
            blob("sky",(side*.33,-.42,-.10),(.31,.22,.47),14,8)
        blob("ivory",(0,-.48,-.53),(.20,.035,.035),10,5)
    elif "UpperArm" in part:
        # Short white puff sleeves are a recognisable part of the reference.
        blob("ivory",(0,.16,0),(.33,.47,.36),17,11)
        blob("peach",(0,-.36,.0),(.25,.23,.26),13,9)
        line("white",[(-.12,-.17,-.29),(.10,-.16,-.29)],.040)
    elif "LowerArm" in part:
        blob("peach",(0,0,0),(.24,.44,.235),16,11)
        blob("ivory",(0,.40,0),(.25,.08,.25),11,7)
    elif "Hand" in part:
        blob("peach",(0,0,0),(.25,.28,.19),14,10)
        for j in range(3):
            x=(j-1)*.115
            blob("peach",(x,-.185,-.10),(.08,.145,.10),10,7)
    elif "UpperLeg" in part:
        blob("sky",(0,.15,0),(.37,.54,.36),17,11)
        blob("blue",(0,-.22,0),(.38,.15,.37),14,8)
        blob("peach",(0,-.44,0),(.28,.20,.28),13,8)
    elif "LowerLeg" in part:
        blob("peach",(0,.04,0),(.27,.56,.26),17,11)
        blob("ivory",(0,-.33,-.025),(.30,.22,.27),14,8)
        blob("gold",(0,-.50,0),(.30,.12,.28),13,7)
    elif "Foot" in part:
        blob("gold",(0,-.03,-.13),(.34,.20,.52),16,10)
        blob("ivory",(0,.15,-.15),(.27,.07,.37),13,8)
        line("straw",[(-.25,-.16,-.38),(.25,-.16,-.38)],.035)
    else:
        raise ValueError("Unexpected R15 part: "+part)
    return g

def create_gardener_pack(S):
    return [sculpt_chibi_part(p,S) for p in R15_PARTS]
