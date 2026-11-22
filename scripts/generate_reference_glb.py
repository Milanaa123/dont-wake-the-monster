#!/usr/bin/env python3
"""Generate an original importable stylized 3D art library for Roblox Studio.
Pure stdlib, reproducible. GLB materials/geometries are original, not AI pictures,
not copied mesh assets. This is a real mesh library, but NOT a Studio playtest.
"""
from __future__ import annotations
import json, math, struct, pathlib, hashlib
from collections import defaultdict

OUT = pathlib.Path("dist/visual-library")
OUT.mkdir(parents=True, exist_ok=True)
PI = math.pi
MAT = {
    "ochre":"CB874B","loam":"946C4D","loamedge":"926F4F","clod":"775D43","grasslit":"C1D779",
    "fur":"8E849E","footfur":"71677D","sage":"A6BF82","moss":"748E63",
    "hairlit":"85634F","nose":"564550","rind":"4F853E","rindedge":"92B94D","leafvein":"ADCB79",
    "cream":"FFF7E7","ivory":"F9E8D0","ink":"4A3845","eye":"251F32",
    "shine":"FFFFFF","blush":"F2A6AA","blush2":"E989A5","straw":"E6C473",
    "orange":"F2A74D","red":"E75C61","berry":"D84F60","pink":"F7B4C4",
    "mint":"8FCD9C","leaf":"82AF66","leaflight":"B7D58A","leafdeep":"538A60",
    "bark":"B27F59","wood":"BD936E","soil":"986D4F","brick":"BE8877",
    "stone":"B7AA9D","slate":"788BA4","water":"8DC8C7","gold":"F6D67B",
    "lavender":"B49AD3","lilac":"D6BEED","rose":"E6AFCA","sky":"B4D5E2",
    "brown":"9E7658","chocolate":"704F45","tan":"D9AA78","white":"F9F8EE",
    "peach":"F2C6A2","lime":"A5CF8C","violet":"A08FC4","turquoise":"8CC9BD",
    "blue":"7DB5D5","dandelion":"F6D977","black":"36343D",
}
def rgb(hexvalue):
    return [int(hexvalue[i:i+2],16)/255 for i in (0,2,4)]
def norm(v):
    s=math.sqrt(sum(x*x for x in v)) or 1
    return tuple(x/s for x in v)
def sub(a,b): return tuple(x-y for x,y in zip(a,b))
def add(a,b): return tuple(x+y for x,y in zip(a,b))
def mul(a,k): return tuple(x*k for x in a)
def cross(a,b): return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def lerp(a,b,t): return add(mul(a,1-t),mul(b,t))
class Sculpt:
    def __init__(self,name):
        self.name=name
        self.joints={}
        self.data=defaultdict(lambda:[[],[]])
    def joint(self,name,pivot,parent="Body"):
        self.joints[name]=(parent,pivot)
    def tri(self,m,a,b,c,na=None,nb=None,nc=None):
        n=norm(cross(sub(b,a),sub(c,a)))
        if na and sum(x*y for x,y in zip(n,na)) < 0:
            b,c,nb,nc = c,b,nc,nb
            n=tuple(-v for v in n)
        self.data[m][0].extend((a,b,c))
        self.data[m][1].extend((na or n,nb or n,nc or n))
    def quad(self,m,a,b,c,d,vertex_normals=None):
        if vertex_normals is None:
            self.tri(m,a,b,c);self.tri(m,a,c,d)
        else:
            na,nb,nc,nd=vertex_normals
            self.tri(m,a,b,c,na,nb,nc)
            self.tri(m,a,c,d,na,nc,nd)
    def blob(self,m,at,radii,seg=15,rings=9,ruffle=0):
        # Continuous sculpted surface with slightly irregular section, not a Roblox ball.
        cx,cy,cz=at; sx,sy,sz=radii
        for j in range(rings):
            e0=-PI/2+PI*j/rings;e1=-PI/2+PI*(j+1)/rings
            for i in range(seg):
                a0=2*PI*i/seg;a1=2*PI*(i+1)/seg
                def vertex(e,a):
                    f=1+ruffle*math.sin(a*5+e*4)
                    return (cx+sx*math.cos(e)*math.cos(a)*f,
                            cy+sy*math.sin(e),
                            cz+sz*math.cos(e)*math.sin(a)*f)
                v=(vertex(e0,a0),vertex(e0,a1),vertex(e1,a1),vertex(e1,a0))
                ns=[norm(((p[0]-cx)/(sx*sx),(p[1]-cy)/(sy*sy),(p[2]-cz)/(sz*sz))) for p in v]
                self.quad(m,*v,vertex_normals=ns)
    def leaf(self,m,root,tip,width,curve=0.2,steps=7,slices=4):
        direction=sub(tip,root); horiz=norm((-direction[2],0,direction[0]))
        if sum(abs(x) for x in horiz)<0.01:horiz=(1,0,0)
        for i in range(steps):
            for j in range(slices):
                def pt(ii,jj):
                    t=ii/steps;u=-1+2*jj/slices
                    wid=math.sin(t*PI)**0.72*width*(1-0.2*t)
                    base=lerp(root,tip,t)
                    return add(add(base,mul(horiz,u*wid)),(0,curve*(1-u*u)*math.sin(PI*t),0))
                a,b,c,d=pt(i,j),pt(i,j+1),pt(i+1,j+1),pt(i+1,j)
                # All GLB primitives use doubleSided=true, so drawing the
                # reverse face again wastes triangles and causes z-fighting.
                self.quad(m,a,b,c,d)
    def tube(self,m,points,radii,sides=8):
        if len(points)<2: return
        for i in range(len(points)-1):
            t0=norm(sub(points[min(i+1,len(points)-1)],points[max(0,i-1)]))
            t1=norm(sub(points[min(i+2,len(points)-1)],points[i]))
            def ring(p,t,r):
                r1=norm(cross(t,(0,0,1)))
                if sum(abs(x) for x in r1)<0.1: r1=norm(cross(t,(1,0,0)))
                r2=norm(cross(t,r1))
                return [add(p,add(mul(r1,math.cos(a)*r),mul(r2,math.sin(a)*r)))
                        for a in [2*PI*j/sides for j in range(sides)]]
            a=ring(points[i],t0,radii[i]);b=ring(points[i+1],t1,radii[i+1])
            for j in range(sides):
                pa,pb,pc,pd=a[j],a[(j+1)%sides],b[(j+1)%sides],b[j]
                na=norm(sub(pa,points[i]));nb=norm(sub(pb,points[i]))
                nc=norm(sub(pc,points[i+1]));nd=norm(sub(pd,points[i+1]))
                self.quad(m,pa,pb,pc,pd,vertex_normals=(na,nb,nc,nd))
    def beam(self,m,start,end,width):
        self.tube(m,[start,end],[width,width],6)
    def petal(self,m,center,direction,length,width):
        self.leaf(m,center,add(center,mul(norm(direction),length)),width,0.07)
    def count(self):return sum(len(v[0])//3 for v in self.data.values())

def make_pet(name,kind,base,secondary):
    g=Sculpt("Pet_"+name)
    g.blob(base,(0,1.02,0.4),(0.98,0.73,1.12),19,12,0.015)
    if kind not in ("butterfly","crab"):
        for side in (-1,1):
            for z in (-0.43,0.88):
                g.blob(base,(side*0.67,0.43,z),(0.34,0.46,0.39),12,7)
                g.blob(secondary,(side*0.68,0.21,z-0.10),(0.33,0.17,0.38),12,7)
    g.blob(base,(0,1.74,-0.54),(1.07,0.94,0.82),23,14,0.018)
    g.blob(secondary,(0,1.04,-0.47),(0.61,0.49,0.27),15,9)
    for side in (-1,1):
        g.blob("cream",(side*0.37,1.52,-1.23),(0.38,0.28,0.21),12,8)
        g.blob("eye",(side*0.43,1.95,-1.277),(0.22,0.30,0.085),15,10)
        g.blob("shine",(side*0.35,2.07,-1.348),(0.078,0.10,0.035),10,6)
        g.blob("blush",(side*0.79,1.55,-1.11),(0.18,0.12,0.06),10,7)
    g.blob("brown",(0,1.40,-1.42),(0.16,0.12,0.09),12,7)
    g.tube("chocolate",[(0,1.37,-1.38),(0,1.26,-1.43),(0.15,1.20,-1.42)],[.038,.038,.015],6)
    if kind in ("cat","fox","dog","deer","unicorn","bunny","bat"):
        for side in (-1,1):
            if kind in ("bunny",):
                g.tube(base,[(side*0.64,2.37,-0.38),(side*0.83,3.46,-0.40),(side*0.72,4.03,-0.38)],[0.37,0.30,0.13],11)
                g.leaf("pink",(side*0.79,2.82,-0.70),(side*0.77,3.89,-0.62),0.16)
            elif kind in ("dog",):
                g.blob(secondary,(side*1.03,2.10,-0.30),(0.36,0.63,0.26),13,8)
            else:
                g.tube(base,[(side*0.72,2.24,-0.38),(side*1.03,2.90,-0.36),(side*1.20,3.19,-0.34)],[0.36,0.27,0.05],10)
                g.leaf("blush",(side*0.84,2.65,-0.63),(side*1.17,3.12,-0.56),0.17)
        if kind in ("cat","fox"):
            for side in (-1,1):
                for j in range(3):
                    g.beam("cream",(side*0.35,1.36+j*.12,-1.39),(side*1.15,1.27+j*.16,-1.40),0.025)
    if kind in ("cat","fox"):
        g.tube(base,[(0.22,1.23,1.43),(0.71,1.47,1.93),(0.96,2.01,2.01),(0.79,2.34,1.92)],[.28,.25,.22,.10],11)
    elif kind in ("dog","bunny","deer","lamb","bear"):
        g.blob("cream",(0,1.16,1.52),(0.42,0.43,0.41),14,9)
    elif kind=="axolotl":
        for side in (-1,1):
            for j in range(3):
                yy=2.30-j*.43
                g.tube("pink",[(side*0.92,yy,-.38),(side*1.42,yy+.16,-.34),(side*1.74,yy+.05,-.32)],[.18,.15,.04],8)
        g.leaf("pink",(0,1.4,1.03),(0,1.02,2.64),0.46)
    elif kind in ("owl","chick","puffin","bat","butterfly"):
        for side in (-1,1):
            if kind=="butterfly":
                for k in (-1,1):
                    g.leaf("pink" if k==1 else "lavender",
                        (side*.88,1.66,.2),(side*2.0,2.5+k*.45,.35),0.92,0.13)
            else:
                g.leaf(secondary,(side*.85,1.47,.25),(side*1.44,0.91,0.96),0.42,0.08)
        if kind in ("chick","owl","puffin"):
            g.tube("orange",[(0,1.6,-1.38),(0,1.44,-1.64),(0,1.36,-1.56)],[.22,.18,.03],8)
    elif kind=="turtle":
        g.blob("leafdeep",(0,1.33,0.90),(1.15,0.94,1.17),21,13)
        for a in [i*2*PI/6 for i in range(6)]:
            g.blob("leaflight",(math.cos(a)*.69,1.93,0.9+math.sin(a)*.69),(.34,.07,.36),10,6)
    elif kind=="frog":
        for side in (-1,1):
            g.blob(base,(side*.49,2.31,-.96),(.37,.34,.33),12,8)
            g.blob("eye",(side*.51,2.42,-1.27),(.17,.19,.06),10,6)
    elif kind=="crab":
        for side in (-1,1):
            g.tube(base,[(side*.76,1.06,.3),(side*1.42,1.23,-.27),(side*1.83,1.10,-.72)],[.24,.21,.12],8)
            g.blob(secondary,(side*1.87,1.17,-.90),(.45,.40,.49),11,7)
            for i in range(2):
                g.beam(base,(side*.80,.57,.5+i*.45),(side*1.71,.25,.8+i*.45),.10)
    elif kind=="deer":
        for side in (-1,1):
            g.tube("bark",[(side*.50,2.40,-.36),(side*.53,3.20,-.33),(side*.82,3.68,-.35)],[.14,.12,.07],8)
            g.tube("bark",[(side*.52,3.10,-.35),(side*.96,3.31,-.34)],[.10,.04],8)
        for a in [i*2*PI/7 for i in range(7)]:
            g.blob("cream",(math.cos(a)*.73,1.66,0.9+math.sin(a)*.72),(.14,.09,.16),9,6)
    elif kind=="unicorn":
        g.tube("gold",[(0,2.54,-1.05),(0,3.28,-1.13)],[.27,.018],11)
        for i in range(5):
            g.blob("lilac",(.44,2.37-i*.21,.37+i*.15),(.42,.36,.42),11,7)
    elif kind=="dino":
        for i in range(5):
            g.leaf("leaflight",(0,1.65,.0+i*.37),(0,2.42-i*.11,.0+i*.37),.29)
    elif kind=="lamb":
        for i in range(9):
            a=i*2*PI/9
            g.blob("cream",(math.cos(a)*.78,2.35,math.sin(a)*.46-.48),(.38,.38,.38),11,8)
    elif kind=="bear":
        for side in (-1,1):
            g.blob(base,(side*.82,2.48,-.42),(.38,.4,.31),12,8)
            g.blob("pink",(side*.88,2.50,-.73),(.22,.22,.08),10,6)
    elif kind=="dino":
        pass
    return g

PET_SPECS=[
("Pip","cat","pink","cream"),("Zuzu","cat","rose","ivory"),
("Mochi","lamb","sky","ivory"),("Pickle","frog","mint","leaflight"),
("Bloop","axolotl","lilac","pink"),("Nugget","chick","straw","cream"),
("Tofu","lamb","ivory","white"),("Wobble","bear","blue","lavender"),
("Spark","fox","gold","ivory"),("Gloop","axolotl","turquoise","sky"),
("Luma","lamb","pink","cream"),("Snorf","dog","tan","ivory"),
("Floofle","bunny","ivory","pink"),("Quibble","crab","blush","orange"),
("Fizzle","dino","orange","straw"),("Puddle","axolotl","pink","ivory"),
("Sprig","deer","tan","ivory"),("Twinkle","butterfly","lilac","violet"),
("Mallow","bear","pink","cream"),("Pebble","turtle","mint","leafdeep"),
("Noodle","bunny","tan","ivory"),("Swoop","owl","brown","cream"),
("Rumble","dino","leaf","mint"),("Doodle","fox","lavender","cream"),
("Crumble","bear","tan","ivory"),("Squiggle","axolotl","violet","pink"),
("Glimmer","unicorn","ivory","lilac"),("Splat","frog","mint","lime"),
("Puffin","puffin","chocolate","ivory"),("Echo","bat","lavender","violet")
]
CROP_NAMES=[
"Berry","Carrot","Corn","Tomato","Pepper","Sunflower","Moonshroom",
"CrystalMint","Dragonfruit","Jellybean","GlowPumpkin","HoneyPear",
"CandyCane","CloudCotton","FrostBerry","RainbowRadish","BubbleCabbage",
"LavaMelon","WhisperWheat","GummyGrape","JellyCactus","NeonMushroom",
"StardustRice","Peppermint","CaramelApple","MoonLotus","ThunderPlum",
"MarshmallowRoot","Starbloom","AuroraMelon"
]
def crop_type(name):
    if name in ("Berry","FrostBerry"):return "strawberry"
    if name in ("Carrot","RainbowRadish","MarshmallowRoot"):return "root"
    if name in ("Corn","WhisperWheat","StardustRice","CandyCane"):return "grain"
    if name in ("LavaMelon","AuroraMelon"):return "melon"
    if name in ("Tomato","Pepper","GummyGrape","Jellybean"):return "tomato"
    if name in ("Moonshroom","NeonMushroom"):return "mushroom"
    if name in ("Sunflower","Starbloom","MoonLotus","CloudCotton"):return "flower"
    return "fantasy"
def make_crop(name,stage):
    g=Sculpt("Crop_"+name+"_S"+str(stage))
    s=0.42+stage*.22
    typ=crop_type(name)
    count=3 if stage<3 else 5
    for i in range(count):
        a=i*2.399963
        pos=(math.cos(a)*.84*s,0,math.sin(a)*.84*s)
        for j in range(3):
            b=a+j*2*PI/3
            g.leaf("leaf" if j%2 else "leaflight",add(pos,(0,.35*s,0)),
               add(pos,(math.cos(b)*1.12*s,.48*s,math.sin(b)*1.12*s)),.33*s)
        stem_top=add(pos,(0,(1.1 if typ not in ("grain","flower") else 2.0)*s,0))
        g.tube("leafdeep",[pos,stem_top],[.10*s,.06*s],7)
        if stage>=2:
            f=.58 if stage==2 else 1
            if typ=="strawberry":
                for k in range(2):
                    fruit=add(stem_top,(math.cos(a+k*1.2)*.35*s,-.38*s,math.sin(a+k*1.2)*.35*s))
                    g.blob("red" if name=="Berry" else "sky",fruit,
                        (.30*s*f,.37*s*f,.29*s*f),15,10)
                    g.leaf("leafdeep",add(fruit,(0,.31*s*f,0)),add(fruit,(.29*s,.36*s*f,0)),.10*s)
                    for n in range(3):
                        g.blob("cream",add(fruit,((n-1)*.14*s,-.04*s,-.275*s)),
                            (.035*s,.07*s,.025*s),7,4)
            elif typ=="root":
                root=add(pos,(0,.20*s,0))
                g.tube("orange" if name=="Carrot" else "pink",
                    [root,add(root,(0,-.62*s*f,0))],[.28*s,.045*s],10)
            elif typ=="grain":
                for j in range(5):
                    y=(1.28+j*.20)*s
                    g.blob("straw" if name!="Corn" else "gold",
                        add(pos,(math.sin(j*2.7)*.1*s,y,0)),(.12*s*f,.24*s*f,.15*s*f),10,6)
            elif typ=="melon":
                center=add(pos,(0,.28*s,0))
                g.blob("leaf" if name=="LavaMelon" else "mint",
                    center,(.72*s*f,.57*s*f,.76*s*f),22,13)
                for k in range(-2,3):
                    theta=k*.33
                    pts=[add(center,(math.sin(theta)*.68*s*f*(1-t*t),
                                    t*.56*s*f,-math.cos(theta)*.70*s*f*(1-t*t)))
                          for t in (-.85,-.42,0,.42,.85)]
                    g.tube("leafdeep",pts,[.032*s]*len(pts),6)
            elif typ=="tomato":
                for k in range(2):
                    fruit=add(stem_top,((k-.5)*.68*s,-.42*s,-.22*s))
                    g.blob("orange" if name=="Pepper" else "red",
                           fruit,(.30*s*f,.34*s*f,.30*s*f),15,10)
                    g.leaf("leafdeep",add(fruit,(0,.31*s*f,0)),
                           add(fruit,(.24*s,.35*s*f,0)),.13*s)
            elif typ=="mushroom":
                top=add(pos,(0,.77*s*f,0))
                g.tube("ivory",[pos,top],[.22*s,.18*s],9)
                g.blob("lilac" if name=="Moonshroom" else "blue",
                    top,(.58*s*f,.29*s*f,.54*s*f),18,10)
                for k in range(3):
                    t=k*2*PI/3
                    g.blob("cream",add(top,(math.cos(t)*.34*s,.25*s*f,
                                               math.sin(t)*.31*s)),(.09*s,.045*s,.09*s),9,6)
            elif typ=="flower":
                for k in range(7):
                    b=k*2*PI/7
                    g.petal("dandelion" if name=="Sunflower" else "pink",
                        stem_top,(math.cos(b),math.sin(b),-.10),.50*s*f,.20*s*f)
                g.blob("brown" if name=="Sunflower" else "gold",
                     add(stem_top,(0,0,-.1*s)),(.21*s*f,.21*s*f,.13*s*f),13,8)
            else:
                g.blob("lilac" if name in ("ThunderPlum","Dragonfruit") else "mint",
                    stem_top,(.40*s*f,.48*s*f,.36*s*f),17,11)
                g.leaf("gold",add(stem_top,(0,.34*s*f,0)),
                    add(stem_top,(.25*s,.60*s*f,0)),.12*s)
    return g

def make_env(key):
    g=Sculpt("Environment_"+key)
    if key=="OrangeTree":
        g.tube("bark",[(0,0,0),(.04,2.5,0),(-.1,4.0,0)],[.38,.34,.20],12)
        for i in range(11):
            a=2*PI*i/11; r=1.55+(i%3)*.34
            pos=(math.cos(a)*r,3.8+(i%5)*.37,math.sin(a)*r)
            g.blob("leaflight" if i%3==0 else "leaf",pos,(1.05,.93,1.05),19,13,.065)
            if i%2==0:
                g.blob("orange",add(pos,(0,-.52,-.71)),(.24,.26,.24),15,9)
                g.leaf("leafdeep",add(pos,(0,-.28,-.70)),add(pos,(.27,-.22,-.72)),.14)
    elif key=="WoodFence":
        for x in (-2.8,0,2.8):
            g.tube("wood",[(x,0,0),(x,1.8,0)],[.18,.18],8)
        for y in (.7,1.36):
            g.tube("bark",[(-2.9,y,0),(2.9,y,0)],[.12,.12],6)
    elif key=="GardenCottage":
        # Each roof facet is a continuous original triangulated surface.
        for x in (-2.2,2.2):
            for z in (-2.3,2.3):
                g.beam("wood",(x,0,z),(x,2.7,z),.15)
        g.quad("cream",(-2.4,.25,-2.45),(2.4,.25,-2.45),(2.4,2.8,-2.45),(-2.4,2.8,-2.45))
        g.quad("cream",(-2.4,.25,2.45),(-2.4,2.8,2.45),(2.4,2.8,2.45),(2.4,.25,2.45))
        g.quad("wood",(-2.4,0,-2.4),(-2.4,0,2.4),(-2.4,2.75,2.4),(-2.4,2.75,-2.4))
        g.quad("wood",(2.4,0,-2.4),(2.4,2.75,-2.4),(2.4,2.75,2.4),(2.4,0,2.4))
        for side in (-1,1):
            g.quad("slate",(0,4.37,-2.75),(0,4.37,2.75),
                 (side*2.86,2.58,2.75),(side*2.86,2.58,-2.75))
        g.quad("bark",(-.67,.02,-2.47),(.67,.02,-2.47),(.67,2.15,-2.47),(-.67,2.15,-2.47))
        for x in (-1.61,1.61):
            g.quad("gold",(x-.38,1.45,-2.49),(x+.38,1.45,-2.49),
                 (x+.38,2.24,-2.49),(x-.38,2.24,-2.49))
            g.beam("wood",(x,1.43,-2.5),(x,2.24,-2.5),.065)
        for i in range(16):
            a=2*PI*i/16
            p=(math.cos(a)*2.35,.55,math.sin(a)*2.42)
            g.blob("pink" if i%2 else "cream",p,(.18,.18,.18),10,6)
    elif key=="StonePath":
        for i in range(7):
            x=.14*math.sin(i);z=i*1.65
            g.blob("stone",(x,.04,z),(1.14,.13,.82),19,7,.04)
    elif key=="WaterPond":
        g.blob("stone",(0,0,0),(2.80,.18,2.0),29,8,.05)
        g.blob("water",(0,.16,0),(2.57,.04,1.77),29,8)
        for i in range(8):
            a=2*PI*i/8
            g.blob("stone",(math.cos(a)*2.46,.22,math.sin(a)*1.63),(.40,.26,.35),14,8,.04)
        for i in range(3):
            a=i*2*PI/3
            g.blob("leafdeep",(math.cos(a)*1.15,.25,math.sin(a)*.75),(.38,.03,.34),13,5)
    elif key=="SleepingMonster":
        g.blob("lavender",(0,1.9,.6),(2.7,2.45,2.95),28,18,.035)
        g.blob("lilac",(0,3.5,-.8),(2.2,2.05,1.89),27,17,.02)
        for side in (-1,1):
            g.blob("rose",(side*1.17,4.00,-2.08),(.53,.37,.16),13,8)
            g.blob("violet",(side*.74,3.78,-2.49),(.40,.12,.08),15,6)
            g.blob("pink",(side*2.42,5.37,-.93),(.66,1.04,.46),16,11)
            g.blob("lavender",(side*2.32,.81,-1.4),(1.0,.64,1.33),19,11)
        for i in range(11):
            a=i*PI/10
            g.blob("leaf" if i%2==0 else "leaflight",
                (math.cos(a)*1.92,5.11+math.sin(a)*.21,-.82),
                (.53,.38,.56),13,9)
        g.blob("rose",(0,3.18,-2.61),(.37,.26,.12),12,8)
    return g

def _palette_png(keys, cell=16):
    # Original procedural watercolor-style atlas, generated by code.
    # Each 16x32 swatch has subtle vertical lighting and pigment texture.
    import zlib
    width = len(keys) * cell
    height = 32
    rows = []
    for y in range(height):
        row = bytearray()
        for key in keys:
            base = rgb(MAT[key])
            for x in range(cell):
                shade = 0.91 + 0.19 * (1 - y / (height - 1))
                grain = 0.025 * math.sin(x * 0.9 + y * 1.31 + len(key) * 4)
                grain += 0.012 * math.sin(x * 2.15 - y * 0.63)
                if key in ("eye","black","ink","chocolate"):
                    shade = 0.99 + grain * .3
                else:
                    shade += grain
                c = [max(0,min(255,round(v * 255 * shade))) for v in base]
                row.extend(bytes(c))
        rows.append(b"\x00" + bytes(row))
    payload = b"".join(rows)
    def chunk(tag, data):
        return (struct.pack(">I", len(data)) + tag + data
                + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff))
    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(payload, 9))
            + chunk(b"IEND", b""))

def _roughness_png(keys, cell=16):
    # glTF metallic-roughness map: G=roughness, B=metalness. Soft leaves,
    # matte soil and gently glossy ripened fruit share the same UV palette.
    import zlib
    overrides = {
        "red":.35,"berry":.35,"orange":.38,"pink":.58,
        "gold":.53,"dandelion":.64,"water":.24,
        "eye":.18,"black":.28,"shine":.16,"slate":.77,
        "leaf":.76,"leafdeep":.83,"leaflight":.72,
        "lime":.67,"mint":.69,"cream":.80,"ivory":.81,
        "soil":.96,"bark":.89,"wood":.86,"brown":.86,
        "chocolate":.85,"stone":.88,
    }
    width=len(keys)*cell
    height=32
    rows=[]
    for y in range(height):
        scan=bytearray()
        for key in keys:
            base=overrides.get(key,.78)
            for x in range(cell):
                stipple=.018*math.sin(x*.73+y*1.11+len(key))
                rough=max(.12,min(.98,base+stipple))
                scan.extend((255,round(255*rough),0))
        rows.append(b"\x00"+bytes(scan))
    payload=b"".join(rows)
    def chunk(tag,data):
        return struct.pack(">I",len(data))+tag+data+struct.pack(">I",zlib.crc32(tag+data)&0xffffffff)
    return (b"\x89PNG\r\n\x1a\n"+
        chunk(b"IHDR",struct.pack(">IIBBBBB",width,height,8,2,0,0,0))+
        chunk(b"IDAT",zlib.compress(payload,9))+chunk(b"IEND",b""))

def glb_write(items,filename):
    # Each named asset = ONE MeshPart with texture atlas, not multiple colored
    # MeshParts. Preserves recognizable colors in Roblox's glTF Importer.
    keys = sorted(MAT)
    index_of = {k:i for i,k in enumerate(keys)}
    palette = _palette_png(keys)
    roughness = _roughness_png(keys)
    tex_width = len(keys)*16
    doc = {
        "asset":{"version":"2.0","generator":"DWTM original textured 3D mesh library"},
        "scene":0,"scenes":[{"nodes":[]}],"nodes":[],"meshes":[],
        "materials":[{
            "name":"DWTM_PaintedSurface",
            "pbrMetallicRoughness":{"baseColorFactor":[1,1,1,1],
                "baseColorTexture":{"index":0,"texCoord":0},
                "metallicRoughnessTexture":{"index":1,"texCoord":0},
                "metallicFactor":0.0,"roughnessFactor":1.0},
            "doubleSided":True
        }],
        "textures":[{"sampler":0,"source":0},{"sampler":0,"source":1}],
        "samplers":[{"magFilter":9728,"minFilter":9728,"wrapS":33071,"wrapT":33071}],
        "images":[],
        "buffers":[{"byteLength":0}],"bufferViews":[],"accessors":[]
    }
    blob=bytearray()
    def store(raw,target=None):
        while len(blob)%4:blob.append(0)
        off=len(blob);blob.extend(raw)
        idx=len(doc["bufferViews"])
        bv={"buffer":0,"byteOffset":off,"byteLength":len(raw)}
        if target is not None:bv["target"]=target
        doc["bufferViews"].append(bv)
        return idx
    image_view=store(palette)
    doc["images"].append({"name":"DWTM_Original_Color_Palette",
                           "mimeType":"image/png","bufferView":image_view})
    roughness_view=store(roughness)
    doc["images"].append({"name":"DWTM_Painted_PBR_Roughness",
                           "mimeType":"image/png","bufferView":roughness_view})
    def access(view,count,typ,ctype,lo=None,hi=None):
        idx=len(doc["accessors"])
        a={"bufferView":view,"componentType":ctype,"count":count,"type":typ}
        if lo is not None:a["min"]=lo;a["max"]=hi
        doc["accessors"].append(a)
        return idx
    vec3=struct.Struct("<3f")
    vec2=struct.Struct("<2f")
    triangles=0
    for asset in items:
        positions=bytearray()
        normals=bytearray()
        texcoords=bytearray()
        indexes=[]
        lookup={}
        points=[p for coordinates,_ in asset.data.values() for p in coordinates]
        bottom=min(p[1] for p in points)
        height=max(max(p[1] for p in points)-bottom,.001)
        lo=[math.inf]*3
        hi=[-math.inf]*3
        for mat,(coords,directions) in asset.data.items():
            u=(index_of[mat]*16+8)/tex_width
            for i in range(0,len(coords),3):
                # Test the coordinates the importer actually receives. At a pole,
                # independent double-precision inputs may become the same float32.
                triangle=[vec3.pack(*p) for p in coords[i:i+3]]
                a,b,c=[vec3.unpack(p) for p in triangle]
                ab,ac=sub(b,a),sub(c,a)
                area=cross(ab,ac)
                edge_sq=max(sum(n*n for n in ab),sum(n*n for n in ac))
                if sum(n*n for n in area)<=edge_sq**2*1e-14:
                    continue
                for j,pos in enumerate(triangle):
                    point=vec3.unpack(pos)
                    normal=directions[i+j]
                    if not any(normal):
                        normal=norm(area)
                    nrm=vec3.pack(*normal)
                    uv=vec2.pack(u,max(.02,min(.98,(point[1]-bottom)/height)))
                    key=(pos,nrm,uv)
                    index=lookup.get(key)
                    if index is None:
                        index=lookup[key]=len(lookup)
                        positions.extend(pos)
                        normals.extend(nrm)
                        texcoords.extend(uv)
                        for axis,v in enumerate(point):
                            lo[axis]=min(lo[axis],v)
                            hi[axis]=max(hi[axis],v)
                    indexes.append(index)
        count=len(lookup)
        assert count and indexes
        # Shared positions can retain different normals or UVs at hard edges and
        # pigment boundaries. Only complete identical vertex records are welded.
        pos=store(positions,34962)
        nrm=store(normals,34962)
        uvs_buffer=store(texcoords,34962)
        component,fmt=(5123,"H") if count<=65535 else (5125,"I")
        indices=store(struct.pack(f"<{len(indexes)}{fmt}",*indexes),34963)
        ap=access(pos,count,"VEC3",5126,lo,hi)
        an=access(nrm,count,"VEC3",5126)
        au=access(uvs_buffer,count,"VEC2",5126)
        ai=access(indices,len(indexes),"SCALAR",component)
        triangles+=len(indexes)//3
        doc["meshes"].append({
            "name":asset.name,
            "primitives":[{
                "attributes":{"POSITION":ap,"NORMAL":an,"TEXCOORD_0":au},
                "indices":ai,"material":0,"mode":4
            }]
        })
        doc["nodes"].append({"name":asset.name,"mesh":len(doc["meshes"])-1})
        doc["scenes"][0]["nodes"].append(len(doc["nodes"])-1)
    while len(blob)%4:blob.append(0)
    doc["buffers"][0]["byteLength"]=len(blob)
    js=json.dumps(doc,separators=(",",":"),ensure_ascii=False).encode("utf-8")
    while len(js)%4:js+=b" "
    data=bytearray()
    data.extend(struct.pack("<4sII",b"glTF",2,12+8+len(js)+8+len(blob)))
    data.extend(struct.pack("<I4s",len(js),b"JSON"));data.extend(js)
    data.extend(struct.pack("<I4s",len(blob),b"BIN\x00"));data.extend(blob)
    dest=OUT/filename
    dest.write_bytes(data)
    assert dest.read_bytes()[:4]==b"glTF"
    return {"file":filename,"bytes":len(data),
      "meshes":len(items),"triangles":triangles,
      "sha256":hashlib.sha256(data).hexdigest()}

def main():
    from creature_shapes_v2 import sculpt_species
    pets=[sculpt_species(name,base,secondary,Sculpt) for name,kind,base,secondary in PET_SPECS]
    from crop_shapes_v2 import sculpt_crop
    crops=[sculpt_crop(k,st,Sculpt) for k in CROP_NAMES for st in (1,2,3)]
    from world_shapes_v2 import sculpt_world,ASSET_NAMES
    env=[sculpt_world(k,Sculpt) for k in ASSET_NAMES]
    from gardener_avatar_v1 import create_gardener_pack
    avatar=create_gardener_pack(Sculpt)
    assert len(pets)==30 and len(crops)==90 and len(env)==8 and len(avatar)==15
    assert len(set(a.name for a in pets)) == 30
    for a in pets+crops+env+avatar:
        assert a.count()>=60, (a.name,a.count())
        # The single hero cottage uses more polygons than reusable crop/animal props.
        limit = 12000 if a.name == "Environment_GardenCottage" else 9000
        assert a.count() < limit, (a.name,a.count(),limit)
    summary=[glb_write(pets,"DWTM_Pets_30.glb"),
             glb_write(crops,"DWTM_Crops_30x3.glb"),
             glb_write(env,"DWTM_World_8.glb"),
             glb_write(avatar,"DWTM_Gardener_Avatar_15.glb")]
    (OUT/"manifest.json").write_text(json.dumps({
        "version":"2026-11-20","art_pass":"cozy-garden-shapes-v2", "coordinate_system":"glTF Y-up",
        "pets":[a.name for a in pets],"crops":[a.name for a in crops],
        "environment":[a.name for a in env],
        "avatar":[a.name for a in avatar],"packs":summary},indent=2),encoding="utf-8")
    print(json.dumps(summary,indent=2))
if __name__=="__main__":main()
