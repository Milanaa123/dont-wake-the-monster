"""Reference-aware original leafy farm crops. Real GLB geometry, not an image."""
from math import sin,cos,pi
import random

def sculpt_crop(name, stage, S):
    g=S("Crop_"+name+"_S"+str(stage))
    from orchard_varieties import variety
    if variety(g,name,stage): return g
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
        sides=12
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
                count = (5,7,8,5)[row]
                for j in range(count):
                    a=(j+.5*(row%2))*2*pi/count
                    x=cx+sin(a)*(rad+.004)*s
                    z=cz-cos(a)*(rad+.004)*s
                    y=cy+yr*s
                    w=.012*s
                    g.quad("straw",(x,y+.023*s,z),(x+w*cos(a),y,z+w*sin(a)),
                           (x,y-.019*s,z),(x-w*cos(a),y,z-w*sin(a)))
    def melon(p,r,mat):
        from orchard_sculpt import melon_rind
        melon_rind(g,p,r,mat)
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
        # The reference shows a full leafy carpet with red fruit hanging
        # between overlapping trifoliate crowns, not a few isolated berries.
        n=7 if stage==3 else 5 if stage==2 else 3
        for i in range(n):
            a=i*2.39996
            ox=sin(a)*1.11; oz=cos(a)*1.00
            p=(ox,.15,oz)
            top=(ox*.96,(.58+(.18 if i%2 else 0))*h,oz*.94)
            stem(p,top,.064)
            from orchard_sculpt import leaflet
            for j in range(3):
                axis=a+j*2*pi/3
                base=(top[0]+sin(axis)*.18*h,top[1]+.10*h,top[2]+cos(axis)*.18*h)
                stem(top,base,.026*h)
                for k in (-1,0,1):
                    leaflet(g,base,pi/2-axis+k*.76,(.52 if k else .7)*h,.20*h,
                            lit if (i+j+k)%4==0 else leaf)
            if stage>=2:
                # Two naturally staggered ripe berries on selected runners
                # form a much denser patch without an expensive extra rosette.
                berries=2 if stage==3 and i%4==0 else 1
                for j in range(berries):
                    fruit=(ox*.95+sin(a+1+j*.74)*(.33+.11*j),
                           (.30+(.12 if i%2 else 0)-.09*j)*h,
                           oz*.94-.22-.22*j)
                    stem(top,(fruit[0],fruit[1]+.14*h,fruit[2]),.027)
                    # A young berry is visibly pale; only the final stage
                    # has the saturated color and its individual yellow seeds.
                    ripened=stage==3
                    fruit_color=("red" if name=="Berry" else "sky") if ripened else "pink"
                    strawberry_shape(fruit,h*(.90 if j else 1),
                        fruit_color,ripened)
                    cap(fruit,h*(.90 if j else 1))
                if stage==2 and i%2==0:
                    # Intermediate plant still blossoms while fruit sets.
                    flower((top[0]-.15,top[1]+.06,top[2]-.17),
                           scale=.45)
                elif stage==3 and i%7==0:
                    flower((top[0]-.15,top[1]+.06,top[2]-.17),
                           scale=.43)
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
            # Low, curling runners physically join the fruit to the bed.
            # Small spirals and lobed leaves are the recognizable watermelon
            # silhouette: they remain real editable triangles, not a decal.
            for j in range(3):
                b=a+j*2*pi/3
                lf(lit if j%2 else leaf,p,
                    (p[0]+sin(b)*.77,p[1]+.22*h,p[2]+cos(b)*.69),
                    .45*h)
                if stage>=2 and j<2:
                    bx=p[0]+sin(b)*.37*h
                    bz=p[2]+cos(b)*.38*h
                    turns=[]
                    for k in range(6):
                        t=k/5
                        spiral=b+(2.5*pi*t if j==0 else -2.5*pi*t)
                        turns.append((bx+.14*h*t*cos(spiral),
                            p[1]+(.16+.10*sin(pi*t))*h,
                            bz+.14*h*t*sin(spiral)))
                    g.tube("leafdeep",turns,
                           [.023*h,.021*h,.018*h,.015*h,.011*h,.006*h],5)
            if stage>=2 and (stage==3 or i==1):
                q=(p[0],(.51 if stage==3 else .39)*h,
                   p[2])
                radius=(.69 if stage==3 else .49)*h
                melon(q,radius,"leaflight" if name=="LavaMelon" else "mint")
                # Broad, lobed leaf crown belongs to the physical melon;
                # this follows the stalk rather than floating over the rind.
                if stage==3:
                    crown=(q[0],q[1]+radius*.87,q[2])
                    for j in range(5):
                        b=j*2*pi/5+a*.23
                        lf(lit if j%2==0 else leaf,crown,
                           (crown[0]+sin(b)*.56*h,crown[1]+.08*h,
                            crown[2]+cos(b)*.49*h),.24*h)
            elif stage==1 or i==0:
                # Yellow blossoms appear before fruit, making the crop
                # progression readable even at small mobile camera scale.
                flower((p[0],(.36+.08*(i%2))*h,p[2]),
                       "dandelion",.45 if stage==1 else .5)
    elif typ=="root":
        count=7 if stage==3 else 3
        root_col="orange" if name=="Carrot" else "pink" if name=="RainbowRadish" else "cream"
        for i in range(count):
            a=i*2.39996
            p=(sin(a)*.85,.14,cos(a)*.73)
            if stage>=2:
                # exposed broad carrot shoulder, root taper below ground
                g.tube(root_col,[(p[0],.60*h,p[2]),
                    (p[0],.18,p[2]),(p[0],-.24*h,p[2])],
                    [.23*h,.19*h,.019],10)
            for j in range(7 if stage==3 else 3):
                b=j*2*pi/5+a
                top=(p[0]+sin(b)*.48*h,.82*h+(j%2)*.16*h,
                     p[2]+cos(b)*.43*h)
                stem((p[0],.25,p[2]),top,.039)
                for k in range(2):
                    lf(lit if k else leaf,top,
                        (top[0]+sin(b+k)*.23*h,top[1]+.27*h,
                         top[2]+cos(b+k)*.21*h),.17*h)
    elif typ=="grain":
        # The reference has a dense pale wheat cluster with slight height
        # variation, not a small row of seven sticks.
        # Cob kernels carry much denser geometry than wheat ears.
        # Preserve the original seven-stalk corn budget for mobile clients.
        n=(7 if name=="Corn" else 10) if stage==3 else 5 if stage==2 else 3
        for i in range(n):
            a=i*2.39996
            p=(sin(a)*.95,.05,cos(a)*.95)
            height=(1.05+(.33 if i%3 else 0))*h+ .27
            top=(p[0],height*2.0,p[2])
            # Golden straw and airy, delicate awns for mature wheat.
            # Dark green stems and oversized seed ellipsoids looked unlike
            # the pale vertical wheat in the supplied farm reference.
            wheat=name=="WhisperWheat"
            stem(p,top,.036 if wheat else .052,"straw" if wheat else "leafdeep")
            lf("straw" if wheat else leaf,(p[0],height*.52,p[2]),
                (p[0]+sin(a)*.65,height*1.15,
                 p[2]+cos(a)*.57),.17 if wheat else .21)
            if stage>=2:
                if name=="Corn":
                    ear=(p[0]+sin(a)*.11,height*1.32,
                         p[2]+cos(a)*.12)
                    ell("dandelion",ear,(.23*h,.62*h,.20*h),12,8)
                    for row in range(6):
                        t=(row+.5)/6
                        for kernel in range(5):
                            b=kernel*2*pi/5+.18*(row%2)
                            rr=sin(pi*t)**.55
                            ell("straw" if (row+kernel)%4==0 else "gold",
                                (ear[0]+.22*h*rr*sin(b),ear[1]+(t-.5)*1.10*h,
                                 ear[2]+.20*h*rr*cos(b)),(.065*h,.067*h,.064*h),5,3)
                    for b in (a-1.0,a+1.0):
                        lf(leaf,(p[0],height*.77,p[2]),
                            (p[0]+sin(b)*.43,height*1.58,
                             p[2]+cos(b)*.43),.22)
                elif name=="WhisperWheat":
                    # Two opposing rows of pointed, curved seed husks and
                    # slender awns create the recognizable delicate wheat ear,
                    # far closer to the reference than bulky green cylinders.
                    for tier in range(8):
                        y=height*1.30+tier*.15*h
                        taper=(1-.066*tier)
                        for side in (-1,1):
                            root=(p[0],y,p[2])
                            end=(p[0]+side*.19*h*taper,
                                 y+.31*h*taper,
                                 p[2]+cos(a+tier*.31)*.062*h)
                            lf("ivory" if (tier+i)%7==0 else "straw",
                               root,end,.073*h*taper,.032)
                            stem(end,(end[0]+side*.075*h,
                                      end[1]+.23*h,
                                      end[2]+sin(a)*.035*h),.008*h,"straw")
                    stem((p[0],height*1.30,p[2]),
                         (p[0]+sin(a)*.035,height*2.03,p[2]),
                         .028*h,"straw")
                else:
                    for awn in (-1,1):
                        for j in range(4):
                            y=height*1.42+j*.21*h
                            stem((p[0],y,p[2]),(p[0]+awn*.23*h,y+.50*h,
                                 p[2]+cos(a)*.13*h),.012*h,"straw")
                    for j in range(5):
                        y=height*1.41+j*.19*h
                        ell("gold",(p[0]+sin(a+j)*.11*h,y,
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
                    # Green immature tomatoes, then soft ripe red fruits,
                    # so the player's garden visually communicates progress.
                    col=("leaflight" if stage==2 and name=="Tomato" else
                         "red" if name=="Tomato" else
                         "orange" if name=="Pepper" else "lilac")
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
                from storybook_crop_blooms import blossom
                blossom(g,name,(top[0],top[1],top[2]-.08),1.50*h)
            else:
                # A green unopened bud is visually distinct from a bloom.
                ell(leaf,(top[0],top[1],top[2]),(.24,.29,.23),11,7)
    elif typ=="mushroom":
        for i in range(5 if stage==3 else 3):
            a=i*2.39996
            p=(sin(a)*.94,.05,cos(a)*.89)
            cap_at=(p[0],(.55+(.22 if i%2 else 0))*h,p[2])
            stem(p,cap_at,.22,"ivory")
            if stage>=2:
                from storybook_crop_blooms import mushroom
                mushroom(g,name,cap_at,.44*h,h)
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
