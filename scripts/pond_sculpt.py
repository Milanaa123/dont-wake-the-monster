"""Water garden with a recessed shelf, split lily pads and cupped flowers."""
from math import cos, pi, sin
from generate_reference_glb import cross, norm, sub


def lily_pad(g, x, z, size, heading, pigment):
    rings=[]
    for f in (.16,.52,1):
        row=[]
        for i in range(27):
            a=heading+.19+(2*pi-.38)*i/26
            r=size*f*(1+.034*sin(5*a+heading))
            row.append((x+r*cos(a),.136+.035*f*f+.016*f*sin(3*a),z+.85*r*sin(a)))
        rings.append(row)
    base=(x,.136,z)
    up=(0,1,0)
    for i in range(26):
        g.tri(pigment,base,rings[0][i],rings[0][i+1],up,up,up)
        for lo,hi in zip(rings,rings[1:]):
            g.quad(pigment,lo[i],hi[i],hi[i+1],lo[i+1],vertex_normals=(up,)*4)
    for i in (4,9,14,19,24):
        pts=[(row[i][0],row[i][1]+.007,row[i][2]) for row in rings]
        g.tube("leafvein",pts,[.010,.009,.002],5)


def water_lily(g,x,z,size,phase):
    for tier,(petals,rise,reach,width) in enumerate(((9,.32,.55,.116),(7,.48,.41,.113),(6,.50,.26,.089))):
        for j in range(petals):
            a=phase+2*pi*j/petals+tier*.43
            radial=(cos(a),sin(a))
            def point(t,k):
                spread=width*(.035+sin(pi*t)**.75)*k
                r=.032+reach*t
                y=.164+size*(rise*t*t+.09*sin(pi*t)*k*k)
                return (x+size*(r*radial[0]-spread*radial[1]),y,
                        z+size*(r*radial[1]+spread*radial[0]))
            for i in range(4):
                for k in (-1,0):
                    v=[point(i/4,k),point((i+1)/4,k),point((i+1)/4,k+1),point(i/4,k+1)]
                    n=norm(cross(sub(v[2],v[0]),sub(v[1],v[0])))
                    if n[1]<0: n=tuple(-u for u in n)
                    pigment=("rose","pink","ivory")[tier]
                    g.quad(pigment,*v,vertex_normals=(n,)*4)
    g.blob("gold",(x,.168+size*.145,z),(.109*size,.105*size,.109*size),12,7)
    for i in range(7):
        a=i*2*pi/7
        g.tube("dandelion",[(x+.062*size*cos(a),.16+size*.15,z+.062*size*sin(a)),
               (x+.102*size*cos(a),.16+size*(.28+.025*sin(i)),z+.102*size*sin(a))],
               [.019*size,.015*size],6)


def bank_spring(g, x, z, angle):
    """A pocket spring in three shelves of weathered stone, facing the water."""
    def at(u, y, v):
        return (x+u*sin(angle)-v*cos(angle), .13+(y-.13)*.83, z-u*cos(angle)-v*sin(angle))

    # Each shelf has its own asymmetric outline and worn upper lip. The
    # receiving stone sits partly underwater where the sheet spreads out.
    for j,(cx,cz,w,d,bottom,top) in enumerate((
            (-.04,.03,.58,.39,.10,.49),(.07,-.09,.42,.29,.39,.69),
            (.09,.41,.32,.23,.11,.30),(-.44,.23,.27,.21,.12,.37))):
        rings=[]
        for f,h in ((.77,0),(1,.23),(.94,.78),(.69,1)):
            row=[]
            for i in range(12):
                a=2*pi*i/12
                edge=f*(1+.09*cos(3*a+.6*j)+.045*sin(5*a+j))
                u,v=w*edge*cos(a),d*edge*sin(a)
                row.append(at(cx+u,bottom+(top-bottom)*h+.037*u-.042*v,cz+v))
            rings.append(row)
        for low,high in zip(rings,rings[1:]):
            for i in range(12):
                k=(i+1)%12
                tone="slate" if j==2 else "stone"
                g.quad(tone,low[i],high[i],high[k],low[k],
                       vertex_normals=tuple(norm(sub(pt,at(cx,bottom-.09,cz))) for pt in
                                            (low[i],high[i],high[k],low[k])))
        for i in range(12):
            g.tri("sage" if j==1 and 4<=i<=8 else "stone", at(cx,top+.017,cz),
                  rings[-1][i],rings[-1][(i+1)%12],(0,1,0),(0,1,0),(0,1,0))

    # The sheet bends forward over two ledges. Its longitudinal ribs catch
    # the same light all the way from the lip to the broad, shallow outflow.
    # Ferns grow out of the gravel beside the lip. Paired leaflets get
    # narrower along each arched stem and keep the mouth of the spring visible.
    for u0,v0,lean in ((-.19,-.12,-.34),(.19,-.21,.24)):
        def stem(t):
            return at(u0+lean*t,.68+.30*sin(1.85*t),v0-.19*t)
        g.tube("moss",[stem(t) for t in (0,.33,.66,1)],[.014,.013,.009,.004],6)
        for k in range(4):
            t=.22+.19*k
            for side in (-1,1):
                reach=.12*(1-.62*t)
                tip=at(u0+lean*(t+.14)+side*reach*.35,.69+.30*sin(1.85*t)+.036,
                       v0-.19*t+side*reach)
                g.leaf("sage" if k==3 else "leaf",stem(t),tip,.029-.011*t,.023,3,2)
    profile=((-.15,.689,.027),(-.06,.716,.065),(.11,.707,.114),(.215,.660,.108),(.266,.492,.108),
             (.35,.481,.138),(.431,.437,.129),(.477,.321,.116),(.54,.314,.153),
             (.609,.270,.137),(.65,.166,.131),(.71,.137,.182),(.87,.129,.253))
    rows=[]
    for j,(v,y,w) in enumerate(profile):
        row=[]
        for i in range(9):
            t=(i-4)/4
            u=.07+.025*sin(v*6)+w*t
            row.append(at(u,y+.013*(1-t*t)+.006*cos(3*pi*t+.25*j),v))
        rows.append(row)
    normals=[]
    for j,row in enumerate(rows):
        line=[]
        for i in range(len(row)):
            along=sub(rows[min(j+1,len(rows)-1)][i],rows[max(j-1,0)][i])
            across=sub(row[min(i+1,len(row)-1)],row[max(0,i-1)])
            normal=norm(cross(along,across))
            if normal[1]<0: normal=tuple(-v for v in normal)
            line.append(normal)
        normals.append(line)
    for j,(upper,lower) in enumerate(zip(rows,rows[1:])):
        for i in range(8):
            mat="sky" if i in (1,6) and 1<=j<10 else "turquoise"
            a,b,c,d=upper[i],lower[i],lower[i+1],upper[i+1]
            g.quad(mat,a,b,c,d,vertex_normals=(normals[j][i],normals[j+1][i],
                   normals[j+1][i+1],normals[j][i+1]))
    for j,(v,span) in enumerate(((.82,.25),(1.0,.36),(1.17,.29))):
        for side in (-1,1):
            prev=None
            for i in range(9):
                t=i/8
                u=.062+side*span*(.13+.87*t)
                pos=v+.058*sin(pi*t)-.13*t*t
                width=.002+.012*sin(pi*t)
                row=[at(u,.138,pos+q*width) for q in (-1,1)]
                if prev:
                    g.quad("ivory" if j==0 else "sky",prev[0],row[0],row[1],prev[1],
                           vertex_normals=((0,1,0),)*4)
                prev=row


def garden_pond(g):
    sides=56
    def shore(a,f,y):
        r=(1+.079*cos(3*a+.75)+.043*sin(5*a-.23))*f
        return (3.05*r*cos(a)+.13*f*sin(a),y,2.22*r*sin(a))
    rows=[]
    for f,y in ((.32,.108),(.59,.110),(.78,.111),(.879,.113),(.932,.138),(.979,.207),(1,.176),(1.025,-.03)):
        row=[]
        for i in range(sides):
            a=i*2*pi/sides
            bank=max(0,(f-.88)/.145)
            spread=f+bank*(.032*sin(7*a)+.023*cos(11*a+.72))
            rise=bank*(.043*sin(5*a)+.029*sin(9*a+.6)) if f<1.025 else 0
            x,_,z=shore(a,spread,y+rise)
            wave=.009*sin(6*z+.8*cos(2*x))+.005*sin(5*x+2*z)
            row.append((x,y+rise+(wave if f<.9 else 0),z))
        rows.append(row)
    for i in range(sides):
        k=(i+1)%sides
        g.tri("water",(0,.111,0),rows[0][k],rows[0][i])
        for mat,inner,outer in zip(("water","water","water","turquoise","stone","sage","moss"),rows,rows[1:]):
            g.quad(mat,inner[i],inner[k],outer[k],outer[i])
        g.tri("loam",(0,-.03,0),rows[-1][i],rows[-1][k])

    for j,(angle,width,height) in enumerate(((.17,.38,.28),(.41,.24,.19),(.62,.23,.16),
            (1.57,.29,.20),(2.69,.23,.14),
            (3.45,.38,.23),(3.71,.26,.15),(4.92,.29,.17),(5.15,.20,.13))):
        x,_,z=shore(angle,.95,.12)
        cuts=12
        rings=[]
        for f,h in ((.78,-.03),(1,.04),(.94,.50),(.59,.88),(.24,1)):
            row=[]
            for i in range(cuts):
                a=2*pi*i/cuts
                w=width*f*(1+.13*cos(3*a+j)+.052*sin(5*a+.5))
                u,v=1.26*w*cos(a),.79*w*sin(a)
                row.append((x+u*cos(angle)-v*sin(angle),.146+height*h+.028*f*cos(a+j),
                            z+u*sin(angle)+v*cos(angle)))
            rings.append(row)
        for row,upper in zip(rings,rings[1:]):
            for i in range(cuts):
                k=(i+1)%cuts
                points=(row[i],upper[i],upper[k],row[k])
                normals=[norm(((p[0]-x)/width**2,(p[1]-.155)/height**2,(p[2]-z)/width**2))
                         for p in points]
                g.quad("stone" if j%4 else "slate",*points,vertex_normals=normals)
        for i in range(cuts):
            g.tri("stone" if j%4 else "slate",(x,.146+height,z),rings[-1][(i+1)%cuts],rings[-1][i])

    spring_x,_,spring_z=shore(1.87,.91,.12)
    bank_spring(g,spring_x,spring_z,1.87)

    for x,z,r,a,mat in ((-1.35,-.64,.46,-.92,"leaf"),(-.69,-1.06,.40,1.16,"sage"),
             (-1.94,-.04,.33,-.40,"leafdeep"),(1.18,.65,.53,-1.13,"leaf"),
             (.50,.97,.32,.64,"sage"),(1.56,-.81,.28,2.52,"leaflight")):
        lily_pad(g,x,z,r,a,mat)
    water_lily(g,-1.28,-.29,.89,.27)
    water_lily(g,.81,.39,.62,1.78)
    # Thin, open crescents leave quiet water between lilies. Each ring loses
    # width toward its ends and follows the shear of the wind across the basin.
    for x,z,r,a,span in ((-.59,-1.12,.60,3.75,1.38),(.82,.55,.73,.61,1.40),
                          (-1.71,.42,.45,.41,1.65),(-1.54,.49,.34,2.05,1.24),
                          (-1.54,.49,.47,2.17,1.12),(.37,-.74,.38,3.67,1.42)):
        previous=None
        for i in range(13):
            t=i/12
            h=a+span*t
            half=.0015+.015*sin(pi*t)
            row=[(x+(r+d)*cos(h),.132,z+.64*(r+d)*sin(h)) for d in (-half,half)]
            if previous:
                g.quad("sky",previous[0],row[0],row[1],previous[1],vertex_normals=((0,1,0),)*4)
            previous=row

    # Connected light paths at the shallow margin, like refracted sunlight.
    # Individual lanes fade at both ends so the pattern never outlines the pond.
    def light_thread(x,z,heading,length,bend,width):
        previous=None
        dx,dz=cos(heading),sin(heading)
        for i in range(9):
            t=i/8
            arc=bend*sin(pi*t)
            half=.0012+width*sin(pi*t)**.7
            mid=(x+dx*length*t-dz*arc,z+dz*length*t+dx*arc)
            row=[(mid[0]-dz*d,.1325,mid[1]+dx*d) for d in (-half,half)]
            if previous:
                g.quad("sky",previous[0],row[0],row[1],previous[1],vertex_normals=((0,1,0),)*4)
            previous=row
    for x,z,length,bend in ((.99,-1.25,.63,.056),(1.23,-1.38,.43,-.045),
                             (-1.75,.78,.44,.051),(-1.92,.63,.36,-.04),
                             (.02,1.46,.37,.03),(.24,1.36,.51,-.04)):
        light_thread(x,z,.15,length,bend,.009)
        light_thread(x+.35*length,z+.033,2.23,.15,-.019,.006)

    for j,a in enumerate((2.16,2.42,4.23,4.42,5.83,6.02)):
        x,_,z=shore(a,.984,.16)
        for i in range(7):
            ang=i*2.4+j
            tip=(x+.33*cos(ang),.26+.13*(i%3),z+.31*sin(ang))
            g.leaf(("moss","leaf","sage")[i%3],(x,.17,z),tip,.077,.103,4,2)
        for i in range(2):
            ang=j*2.26+i
            flower=(x+.13*cos(ang),.42+.092*i,z+.14*sin(ang))
            g.tube("moss",[(x,.17,z),flower],[.015,.009],5)
            for petal in range(5):
                turn=2*pi*petal/5+ang
                xx,yy,zz=flower
                tip=(xx+.092*cos(turn),yy+.037,zz+.092*sin(turn))
                g.leaf("ivory" if j%3 else "lilac",flower,tip,.039,.020,2,2)
            g.blob("gold",flower,(.031,.028,.031),7,4)

    for j,a in enumerate((.92,1.16,2.82,3.04)):
        x,_,z=shore(a,.938,.14)
        for i in range(7):
            turn=i*2.40+j
            start=(x+.063*cos(turn),.155,z+.063*sin(turn))
            tip=(x+.32*cos(turn),.55+.34*(.5+.5*sin(i*2.13+j)),z+.30*sin(turn))
            g.leaf("leafdeep" if i%2 else "leaflight",start,tip,.041,.092,4,2)
        for i in range(2):
            u=x+.14*i; v=z-.09*i
            top=(u+.09,.94+.22*sin(j+i),v+.07)
            g.tube("moss",[(u,.15,v),(u+.01,.54,v),top],[.026,.021,.012],7)
            g.tube("brown",[(top[0]-.015,top[1]-.17,top[2]),top,
                   (top[0]+.006,top[1]+.056,top[2])],[.037,.041,.019],8)
