"""Botanical sculpts for seed varieties with distinct growth habits."""
from math import sin, cos, pi
from orchard_sculpt import leaflet, loft


def variety(g, name, stage):
    scale=(.44,.72,1.)[stage-1]
    def leaf(at,a,length,width,mat="leaf"):
        g.leaf(mat,at,(at[0]+length*cos(a),at[1]+length*.23,at[2]+length*sin(a)),width,.11)
    def stalk(points,width,mat="leafdeep"):
        g.tube(mat,points,[width*(1-i/(2*len(points))) for i in range(len(points))],7)
    if name=="GlowPumpkin":
        for i in range(2+stage):
            a=i*2.39996
            p=(scale*cos(a),.07,scale*sin(a))
            stalk([(0,.10,0),(p[0]*.56,.18,p[2]*.63),p],.048)
            leaf(p,a+.55,.65*scale,.32*scale)
            if stage==1 or (stage==2 and i>1): continue
            r=(.40+.09*(i%2))*scale
            def point(j,k):
                t=k*pi/9
                b=j*2*pi/32
                rad=r*sin(t)*(1+.085*cos(b*8))
                return (p[0]+rad*cos(b),.06+r*.79*(1+cos(t)),p[2]+rad*sin(b))
            for j in range(32):
                for k in range(9):
                    g.quad("orange" if j%4 else "ochre",point(j,k),point(j+1,k),point(j+1,k+1),point(j,k+1))
            stalk([(p[0],.06+1.55*r,p[2]),(p[0]+.08,.17+1.55*r,p[2]-.06)],.069,"bark")
    elif name=="BubbleCabbage":
        # Concentric, pleated leaves curve up towards a compact central head.
        for i in range(7+stage*4):
            a=i*2.39996
            t=i/(7+stage*4)
            run=(1.17-.78*t)*scale
            width=(.53-.20*t)*scale
            grid=[]
            for j in range(7):
                u=j/6
                row=[]
                for k in range(5):
                    v=(k-2)/2
                    lateral=v*width*sin(pi*u)**.65
                    radial=run*u*(1-.35*t*u)
                    y=.06+scale*((.42+t*.78)*u+.26*sin(pi*u)-.16*v*v*sin(pi*u)+.043*cos(10*u+3*v))
                    row.append((cos(a)*radial-sin(a)*lateral,y,sin(a)*radial+cos(a)*lateral))
                grid.append(row)
            for j in range(6):
                for k in range(4):
                    g.quad("mint" if t>.6 else "leaflight" if i%3==0 else "leaf",
                           grid[j][k],grid[j+1][k],grid[j+1][k+1],grid[j][k+1])
    elif name in ("HoneyPear","CaramelApple","ThunderPlum"):
        stalk([(0,0,0),(.08,.62*scale,0),(-.06,1.6*scale,.08)],.12*scale,"wood")
        for i in range(3+stage):
            a=i*2.39996
            tip=(.87*scale*cos(a),(1.32+i*.09)*scale,.83*scale*sin(a))
            stalk([(0,.68*scale,0),(tip[0]*.6,tip[1]-.22,tip[2]*.6),tip],.065*scale,"bark")
            for j in range(4): leaf(tip,a+j*1.59,.55*scale,.19*scale,"leaflight" if j%3==0 else "leaf")
            if stage<2: continue
            x,y,z=tip
            r=(.29 if stage==3 else .17)
            y-=r*1.1
            if name=="HoneyPear":
                loft(g,"gold",[(x,y-r,z,.07*r,.06*r),(x,y-.64*r,z,.76*r,.75*r),
                    (x,y-.26*r,z,1.02*r,.96*r),(x,y+.22*r,z,.86*r,.78*r),
                    (x,y+.78*r,z,.41*r,.38*r),(x+.03,y+r,z,.19*r,.18*r)],14)
            else:
                g.blob("brick" if name=="CaramelApple" else "violet",(x,y,z),
                       (r,r*(.86 if name=="CaramelApple" else 1.18),r*.90),14,8)
            stalk([(x,y+.84*r,z),(x+.04,tip[1]+.03,z)],.031,"bark")
    elif name in ("JellyCactus","Dragonfruit"):
        for i in range(2+stage):
            a=i*2.39996
            x,z=cos(a)*.64*scale,sin(a)*.64*scale
            top=(.73+i*.12)*scale
            g.tube("mint" if name=="JellyCactus" else "leaf",[(0,.05,0),(x*.68,top*.58,z*.68),
                   (x,top,z),(x+.06,top+.08,z)],[.09,.25*scale,.17*scale,.027],6 if name=="Dragonfruit" else 12)
            for j in range(4):
                b=j*pi/2+a
                q=(x*.78+.15*scale*cos(b),top*.76,z*.78+.15*scale*sin(b))
                g.leaf("cream",q,(q[0]+.09*cos(b),q[1]+.08,q[2]+.09*sin(b)),.014,.005)
            if stage<2: continue
            r=.29*scale
            g.blob("rose" if name=="Dragonfruit" else "berry",(x,top+.05,z),(r,r*1.3,r*.92),14,8)
            for j in range(9):
                b=j*2.39996
                start=(x+r*.85*cos(b),top+.05+r*(j/9-.5),z+r*.85*sin(b))
                g.leaf("leaflight" if name=="Dragonfruit" else "pink",start,
                       (start[0]+r*.24*cos(b),start[1]+r*.64,start[2]+r*.24*sin(b)),r*.28,.04)
    elif name in ("CrystalMint","Peppermint"):
        for i in range(2+stage):
            a=i*2.39996
            x,z=scale*.66*cos(a),scale*.66*sin(a)
            h=(1+.14*(i%2))*scale
            stalk([(x,.03,z),(x+.04,h,z)],.041)
            for k in range(2+stage):
                y=h*(.24+.13*k)
                for side in (0,pi):
                    leaflet(g,(x,y,z),a+k*pi/2+side,(.57-.05*k)*scale,.22*scale,
                            "mint" if name=="CrystalMint" else "leaf")
            if stage==3:
                for j in range(5):
                    g.tube("sky" if name=="CrystalMint" else "rose",
                           [(x,h,z),(x+.07*cos(j),h+.10,z+.07*sin(j)),(x+.09*cos(j),h+.24,z+.09*sin(j))],
                           [.054,.060,.004],5)
    elif name in ("GummyGrape","Jellybean"):
        for i in range(2+stage):
            a=i*2.39996
            x,z=.65*scale*cos(a),.65*scale*sin(a)
            y=(1.24+.14*(i%2))*scale
            stalk([(0,.05,0),(x*.61,y*.52,z*.61),(x,y,z)],.06)
            for j in range(3): leaf((x,y,z),a+j*2.1,.58*scale,.29*scale)
            if stage<2: continue
            if name=="GummyGrape":
                for row in range(4):
                    for j in range(4-row):
                        b=j*2*pi/(4-row)+row*.54
                        r=(3-row)*.060*scale
                        g.blob("violet" if (j+row)%2 else "lilac",
                               (x+r*cos(b),y-.17-row*.16*scale,z+r*sin(b)),(.14*scale,)*3,10,6)
            else:
                for j in (-1,1):
                    g.tube("pink" if j==1 else "mint",[(x,y,z),(x+j*.19,y-.21,z),
                           (x+j*.26,y-.44,z+.04),(x+j*.17,y-.60,z+.06)],
                           [.035,.12*scale,.13*scale,.028],10)
    else:
        return False
    return True
