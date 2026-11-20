"""Reference-aware original leafy farm crops. Real GLB geometry, not an image."""
from math import sin,cos,pi
import random

def sculpt_crop(name, stage, S):
    g=S("Crop_"+name+"_S"+str(stage))
    rng=random.Random(sum((i+1)*ord(c) for i,c in enumerate(name))+stage*11)
    t=stage/3
    h={1:.55,2:.78,3:1.0}[stage]
    leaf_dark="leafdeep";leaf="leaf";lit="leaflight"
    def ell(mat,pos,r,seg=13,rings=8):
        g.blob(mat,pos,r,seg,rings,.012)
    def lf(mat,a,b,w,curve=.08):
        g.leaf(mat,a,b,w,curve,5,3)
    def stem(a,b,w=.08,mat="leafdeep"):
        g.tube(mat,[a,b],[w,w*.75],7)
    def ringLeaves(center,n,radius,height,width):
        for i in range(n):
            a=2*pi*i/n + .30
            v=(center[0]+sin(a)*radius,center[1]+height,center[2]+cos(a)*radius)
            lf(lit if i%3==0 else leaf,center,v,width,curve=.14)
    def flower(center,col="cream",scale=1):
        for i in range(5):
            a=2*pi*i/5
            lf(col,center,(center[0]+sin(a)*.33*scale,center[1]+cos(a)*.33*scale,
                      center[2]-.07),.14*scale,.04)
        ell("gold",(center[0],center[1],center[2]-.13),(.10*scale,.10*scale,.07))
    def cap(center,s):
        for j in range(5):
            a=j*2*pi/5
            lf("leafdeep",(center[0],center[1]+.20*s,center[2]),
               (center[0]+sin(a)*.38*s,center[1]+.13*s,
                center[2]+cos(a)*.35*s),.13*s)
    def strawberry_shape(p,s,mat,ripe):
        # A true tapered berry silhouette, not a red sphere. The tiny seed
        # marks are low-poly diamonds that follow the actual fruit surface.
        cx,cy,cz=p
        heights=[-.37,-.30,-.15,.10,.31,.37]
        radii=[.025,.19,.285,.31,.19,.025]
        sides=14
        for band in range(len(heights)-1):
            for j in range(sides):
                a=2*pi*j/sides
                b=2*pi*(j+1)/sides
                def v(k,angle):
                    return (cx+sin(angle)*radii[k]*s,
                            cy+heights[k]*s,
                            cz-cos(angle)*radii[k]*s)
                g.quad(mat,v(band,a),v(band,b),
                       v(band+1,b),v(band+1,a))
        if ripe:
            for row,yr in enumerate((-.22,-.04,.14,.26)):
                # The front-most small diamonds sit just outside the hull.
                hi=next(i for i in range(len(heights)-1)
                        if heights[i]<=yr<=heights[i+1])
                fraction=(yr-heights[hi])/(heights[hi+1]-heights[hi])
                rad=radii[hi]+(radii[hi+1]-radii[hi])*fraction
                for j in range(3):
                    xf=(j-1)*.56 + (row%2)*.15
                    x=cx+rad*s*xf
                    z=cz-rad*s*(1-xf*xf)**.5-.011*s
                    y=cy+yr*s
                    w=.022*s;hh=.037*s
                    g.tri("cream",(x,y+hh,z),(x-w,y,z),
                          (x,y-hh,z))
                    g.tri("cream",(x,y+hh,z),(x,y-hh,z),
                          (x+w,y,z))
    def melon(p,r,mat):
        ell(mat,p,(r*1.16,r*.92,r),19,11)
        # Banded rind, following the surface, including both ends.
        for i in range(-2,3):
            ang=i*.42
            pts=[]
            for j in range(7):
                a=pi*j/6
                wobble=ang+.055*sin(a*6+i*.8)
                pts.append((p[0]+sin(wobble)*r*1.16*sin(a),
                            p[1]+cos(a)*r*.915,
                            p[2]-cos(wobble)*r*.999*sin(a)))
            g.tube("leafdeep",pts,[.052*r]*7,5)
        cap((p[0],p[1]+r*.82,p[2]),r)
    # distinguish plant type by original reference silhouettes
    typ = (
      "berry" if name in ("Berry","FrostBerry") else
      "melon" if name in ("LavaMelon","AuroraMelon") else
      "root" if name in ("Carrot","RainbowRadish","MarshmallowRoot") else
      "grain" if name in ("Corn","WhisperWheat","StardustRice","CandyCane") else
      "tomato" if name in ("Tomato","Pepper","GummyGrape","Jellybean") else
      "flower" if name in ("Sunflower","MoonLotus","Starbloom","CloudCotton") else
      "mushroom" if name in ("Moonshroom","NeonMushroom") else "fantasy")
    if typ=="berry":
        # A spreading carpet of strawberry trifoliate leaves; fruit under the canopy.
        n=6 if stage==3 else 5 if stage==2 else 3
        for i in range(n):
            a=i*2.39996
            ox=sin(a)*1.11; oz=cos(a)*1.00
            p=(ox,.15,oz)
            top=(ox*.96,(.58+(.18 if i%2 else 0))*h,oz*.94)
            stem(p,top,.064)
            for j in range(5 if stage==3 else 3):
                b=a+j*2*pi/(5 if stage==3 else 3)
                lf(lit if j%3==0 else leaf,top,
                    (top[0]+sin(b)*.67*h,top[1]+.13*h,
                     top[2]+cos(b)*.61*h),.33*h)
            if stage>=2:
                fruit=(ox*.95+sin(a+1)*.33,(.30+(.12 if i%2 else 0))*h,oz*.94-.22)
                stem(top,(fruit[0],fruit[1]+.14*h,fruit[2]),.033)
                strawberry_shape(fruit,h,
                    "red" if name=="Berry" else "sky",stage==3)
                cap(fruit,h)
            elif i%2==1:
                flower((top[0],top[1]+.07,top[2]-.18),scale=.55)
        if stage == 3:
            for j in range(8):
                a=j*2*pi/8
                lf(lit if j%3==0 else leaf,
                   (0,.28,0),
                   (sin(a)*1.38,.60,cos(a)*1.21),.39)
        # winding runners joining rosettes
        for a in (0,1,2):
            ang=a*2*pi/3
            stem((0,.16,0),(sin(ang)*1.16,.18,cos(ang)*1.16),.055)
    elif typ=="melon":
        # Three round fruit on broad trailing vines, like the supplied garden.
        angles=[0,2.35,4.48]
        for i,a in enumerate(angles):
            p=(sin(a)*1.11,.11,cos(a)*1.05)
            stem((0,.18,0),p,.08)
            for j in range(3):
                b=a+j*2*pi/3
                lf(lit if j%2 else leaf,p,
                    (p[0]+sin(b)*.77,p[1]+.22*h,p[2]+cos(b)*.69),
                    .45*h)
            if stage>=2 and (stage==3 or i==1):
                q=(p[0],(.51 if stage==3 else .39)*h,
                   p[2])
                melon(q,(.69 if stage==3 else .49)*h,
                      "leaflight" if name=="LavaMelon" else "mint")
            elif i==0:
                flower((p[0],.38*h,p[2]),"dandelion",.5)
    elif typ=="root":
        count=5 if stage==3 else 3
        root_col="orange" if name=="Carrot" else "pink" if name=="RainbowRadish" else "cream"
        for i in range(count):
            a=i*2.39996
            p=(sin(a)*.85,.14,cos(a)*.73)
            if stage>=2:
                # exposed broad carrot shoulder, root taper below ground
                g.tube(root_col,[(p[0],.60*h,p[2]),
                    (p[0],.18,p[2]),(p[0],-.24*h,p[2])],
                    [.23*h,.19*h,.019],10)
            for j in range(5 if stage==3 else 3):
                b=j*2*pi/5+a
                top=(p[0]+sin(b)*.48*h,.82*h+(j%2)*.16*h,
                     p[2]+cos(b)*.43*h)
                stem((p[0],.25,p[2]),top,.039)
                for k in range(2):
                    lf(lit if k else leaf,top,
                        (top[0]+sin(b+k)*.23*h,top[1]+.27*h,
                         top[2]+cos(b+k)*.21*h),.17*h)
    elif typ=="grain":
        n=7 if stage==3 else 4
        for i in range(n):
            a=i*2.39996
            p=(sin(a)*.95,.05,cos(a)*.95)
            height=(1.05+(.33 if i%3 else 0))*h+ .27
            top=(p[0],height*2.0,p[2])
            stem(p,top,.052,"leafdeep")
            lf(leaf,(p[0],height*.52,p[2]),
                (p[0]+sin(a)*.65,height*1.15,
                 p[2]+cos(a)*.57),.21)
            if stage>=2:
                if name=="Corn":
                    ear=(p[0]+sin(a)*.11,height*1.32,
                         p[2]+cos(a)*.12)
                    ell("dandelion",ear,(.23*h,.62*h,.20*h),12,8)
                    for b in (a-1.0,a+1.0):
                        lf(leaf,(p[0],height*.77,p[2]),
                            (p[0]+sin(b)*.43,height*1.58,
                             p[2]+cos(b)*.43),.22)
                else:
                    for j in range(5):
                        y=height*1.41+j*.19*h
                        ell("straw" if name=="WhisperWheat" else "gold",
                            (p[0]+sin(a+j)*.11*h,y,
                             p[2]+cos(a+j)*.10*h),
                            (.13*h,.27*h,.13*h),10,7)
    elif typ=="tomato":
        # A branching fruit vine with hanging ripened bunches.
        n=5 if stage==3 else 3
        for i in range(n):
            a=i*2*pi/n
            root=(sin(a)*.56,.07,cos(a)*.52)
            top=(sin(a)*.92,1.55*h,cos(a)*.81)
            stem(root,top,.082)
            for k in range(3):
                b=a+k*2*pi/3
                lf(lit if k==0 else leaf,
                    (top[0],top[1]-.20*h,top[2]),
                    (top[0]+sin(b)*.62*h,top[1]+.12*h,
                     top[2]+cos(b)*.58*h),.27*h)
            if stage>=2:
                for k in range(2 if stage==3 else 1):
                    y=.65*h+k*.44*h
                    fruit=(top[0]+sin(a+k)*.31,y,
                            top[2]-.31+cos(a+k)*.12)
                    col="red" if name=="Tomato" else "orange" if name=="Pepper" else "lilac"
                    ell(col,fruit,(.28*h,.30*h if name!="Pepper" else .46*h,.30*h),14,9)
                    cap(fruit,h*.65)
            else:flower(top,scale=.48)
    elif typ=="flower":
        n=5 if stage==3 else 3
        col="dandelion" if name=="Sunflower" else "cream" if name=="CloudCotton" else "pink"
        for i in range(n):
            a=i*2.39996
            root=(sin(a)*.78,.08,cos(a)*.71)
            top=(root[0],(1.16+.20*(i%2))*h+ .52,root[2])
            stem(root,top,.072)
            for side in (-1,1):
                lf(leaf,(root[0],.43*h,root[2]),
                    (root[0]+sin(a+side)*.45*h,.89*h,
                     root[2]+cos(a+side)*.42*h),.22*h)
            if stage>=2:
                flower((top[0],top[1],top[2]-.08),col,1.58*h)
            else:
                ell(leaf,(top[0],top[1],top[2]),(.24,.29,.23),11,7)
    elif typ=="mushroom":
        for i in range(5 if stage==3 else 3):
            a=i*2.39996
            p=(sin(a)*.94,.05,cos(a)*.89)
            cap_at=(p[0],(.55+(.22 if i%2 else 0))*h,p[2])
            stem(p,cap_at,.22,"ivory")
            if stage>=2:
                ell("lilac" if name=="Moonshroom" else "blue",
                    cap_at,(.44*h,.24*h,.44*h),18,9)
                for j in range(4):
                    b=j*pi/2
                    ell("cream",
                        (cap_at[0]+sin(b)*.24*h,cap_at[1]+.20*h,
                         cap_at[2]+cos(b)*.22*h),
                        (.055*h,.042*h,.055*h),8,5)
            for k in range(2):
                b=a+k*pi/2
                lf(leaf,p,(p[0]+sin(b)*.43,p[1]+.16,
                           p[2]+cos(b)*.42),.19*h)
    else:
        # Fantastical varieties retain recognizable botanical structure.
        n=5 if stage==3 else 3
        for i in range(n):
            a=i*2.39996
            p=(sin(a)*.86,.09,cos(a)*.86)
            top=(p[0],(1.20+ .13*(i%2))*h,p[2])
            stem(p,top,.074)
            for j in range(4):
                b=a+j*pi/2
                lf(lit if j%2==0 else leaf,
                    (p[0],.42*h,p[2]),
                    (p[0]+sin(b)*.62*h,.80*h,
                     p[2]+cos(b)*.63*h),.27*h)
            if stage>=2:
                shape="lilac" if name in ("Dragonfruit","ThunderPlum","Starbloom") else "mint"
                ell(shape,top,(.40*h,.48*h,.36*h),15,9)
                cap(top,h)
            else:
                flower(top,scale=.4)
    return g
