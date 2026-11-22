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
            for i in range(5):
                for k in (-1,0):
                    v=[point(i/5,k),point((i+1)/5,k),point((i+1)/5,k+1),point(i/5,k+1)]
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


def garden_pond(g):
    sides=72
    def shore(a,f,y):
        r=(1+.079*cos(3*a+.75)+.043*sin(5*a-.23))*f
        return (3.05*r*cos(a)+.13*f*sin(a),y,2.22*r*sin(a))
    rows=[]
    for f,y in ((.55,.111),(.78,.111),(.879,.113),(.932,.138),(.979,.207),(1,.176),(1.025,-.03)):
        rows.append([shore(i*2*pi/sides,f,y) for i in range(sides)])
    for i in range(sides):
        k=(i+1)%sides
        g.tri("water",(0,.111,0),rows[0][k],rows[0][i])
        for mat,inner,outer in zip(("water","turquoise","water","stone","sage","moss"),rows,rows[1:]):
            g.quad(mat,inner[i],inner[k],outer[k],outer[i])
        g.tri("loam",(0,-.03,0),rows[-1][i],rows[-1][k])

    for j,(angle,width,height) in enumerate(((.17,.38,.28),(.41,.24,.19),(.62,.23,.16),
            (1.65,.34,.23),(1.87,.46,.29),(2.15,.28,.18),(2.69,.23,.14),
            (3.45,.38,.23),(3.71,.26,.15),(4.92,.29,.17),(5.15,.20,.13))):
        x,_,z=shore(angle,.95,.12)
        cuts=10
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
                g.quad("stone" if j%4 else "slate",row[i],upper[i],upper[k],row[k])
        for i in range(cuts):
            g.tri("stone" if j%4 else "slate",(x,.146+height,z),rings[-1][(i+1)%cuts],rings[-1][i])

    for x,z,r,a,mat in ((-1.35,-.64,.46,-.92,"leaf"),(-.69,-1.06,.40,1.16,"sage"),
             (-1.94,-.04,.33,-.40,"leafdeep"),(1.18,.65,.53,-1.13,"leaf"),
             (.50,.97,.32,.64,"sage"),(1.56,-.81,.28,2.52,"leaflight")):
        lily_pad(g,x,z,r,a,mat)
    water_lily(g,-1.28,-.29,.89,.27)
    water_lily(g,.81,.39,.62,1.78)
    for j,a in enumerate((.92,1.16,2.82,3.04)):
        x,_,z=shore(a,.938,.14)
        for i in range(7):
            turn=i*2.40+j
            start=(x+.063*cos(turn),.155,z+.063*sin(turn))
            tip=(x+.32*cos(turn),.55+.34*(.5+.5*sin(i*2.13+j)),z+.30*sin(turn))
            g.leaf("leafdeep" if i%2 else "leaflight",start,tip,.041,.092,6,3)
        for i in range(2):
            u=x+.14*i; v=z-.09*i
            top=(u+.09,.94+.22*sin(j+i),v+.07)
            g.tube("moss",[(u,.15,v),(u+.01,.54,v),top],[.026,.021,.012],7)
            g.tube("brown",[(top[0]-.015,top[1]-.17,top[2]),top,
                   (top[0]+.006,top[1]+.056,top[2])],[.037,.041,.019],8)
