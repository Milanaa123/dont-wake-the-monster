"""Bake source sculpts to the Rojo place. --studio additionally makes native mesh files for offline Studio."""
import argparse
import base64
import ctypes
import ctypes.util
import json
import math
from pathlib import Path
import struct
import zlib

from creature_shapes_v2 import sculpt_species
from crop_shapes_v2 import sculpt_crop
from gardener_avatar_v1 import create_gardener_pack
from generate_reference_glb import Sculpt, MAT, PET_SPECS, CROP_NAMES, _palette_png
from world_shapes_v2 import ASSET_NAMES, sculpt_world

ROOT = Path(__file__).resolve().parents[1]
KEYS = sorted(MAT)
VERTEX = struct.Struct('<3h3b2H')
lib = ctypes.CDLL(ctypes.util.find_library('zstd') or 'libzstd.so.1')
lib.ZSTD_compressBound.restype = ctypes.c_size_t
lib.ZSTD_compress.restype = ctypes.c_size_t


def pack(data):
    out = ctypes.create_string_buffer(lib.ZSTD_compressBound(len(data)))
    size = lib.ZSTD_compress(out, len(out), bytes(data), len(data), 12)
    assert not lib.ZSTD_isError(size)
    return base64.b64encode(out.raw[:size]).decode()


class GameSculpt(Sculpt):
    def __init__(self, name):
        super().__init__(name)
        self.parts = {'Body': self.data}

    def joint(self, name, pivot, parent='Body'):
        super().joint(name, pivot, parent)
        if name not in self.parts:
            self.parts[name] = Sculpt(name).data
        self.data = self.parts[name]

    def blob(self, mat, at, radii, seg=15, rings=9, ruffle=0):
        # Reserve silhouette resolution for larger forms; kernels and stitches are tiny on screen.
        detail = .53 if max(radii) < .24 else .76
        super().blob(mat, at, radii, max(5,round(seg*detail)),max(3,round(rings*detail)),ruffle)

    def leaf(self, mat, root, tip, width, curve=.2, steps=7, slices=4):
        super().leaf(mat, root, tip, width, curve, min(steps,4), min(slices,2))


def bounds(points):
    axes=list(zip(*points))
    lo=[min(a) for a in axes]
    hi=[max(a) for a in axes]
    return [round((a+b)/2,6) for a,b in zip(lo,hi)], [round(b-a,6) for a,b in zip(lo,hi)]


def encode_part(materials, full_center, full_size):
    center,size=bounds(p for points,_ in materials.values() for p in points)
    vertices,faces,lookup=[],[],{}
    for mat,(points,normals) in materials.items():
        for i in range(0,len(points),3):
            face=[]
            for p,n in zip(points[i:i+3],normals[i:i+3]):
                xyz=tuple(round((a-b)*2048) for a,b in zip(p,center))
                normal=tuple(round(127*max(-1,min(1,c))) for c in n)
                t=(p[1]-full_center[1])/max(full_size[1],.001)+.5
                # Planar swatch coordinates retain pigment grain across each piece.
                u=(KEYS.index(mat)+.50+.34*math.sin(p[0]*2.7+p[2]*1.2))/len(KEYS)
                v=.94-.88*t
                vertex=(*xyz,*normal,round(u*65535),round(v*65535))
                if vertex not in lookup:
                    lookup[vertex]=len(vertices)
                    vertices.append(vertex)
                face.append(lookup[vertex])
            a,b,c=(vertices[j][:3] for j in face)
            ab=[x-y for x,y in zip(a,b)]
            ac=[x-y for x,y in zip(a,c)]
            if any(ab[k]*ac[(k+1)%3] != ac[k]*ab[(k+1)%3] for k in range(3)):
                faces.append(face)
    data=struct.pack('<II',len(vertices),len(faces))
    data+=b''.join(VERTEX.pack(*v) for v in vertices)
    data+=b''.join(struct.pack('<3H',*f) for f in faces)
    assert faces and len(vertices)<65536
    return center,size,data,vertices,faces


def native_mesh(path,vertices,faces):
    # The packed game asset is left byte-for-byte reproducible. The Studio
    # kit's .mesh files are compacted separately to discard vertex entries
    # left behind when zero-area triangles were removed by encode_part().
    # Original Codex kit: 15,558 unreferenced vertices, all 6,993 zero
    # normals were among the unused vertices. No visible face is changed.
    referenced=sorted({i for face in faces for i in face})
    assert referenced and max(referenced)<len(vertices)
    if len(referenced)!=len(vertices):
        remap={old:new for new,old in enumerate(referenced)}
        vertices=[vertices[old] for old in referenced]
        faces=[[remap[old] for old in face] for face in faces]
    assert all(any(v[3:6]) for v in vertices), "Invalid normal in Studio mesh"
    # Roblox version 2, 36-byte vertex records (position, normal, UV, tangent).
    with path.open('wb') as f:
        f.write(b'version 2.00\n'+struct.pack('<HBBII',12,36,12,len(vertices),len(faces)))
        for x,y,z,nx,ny,nz,u,v in vertices:
            f.write(struct.pack('<8f4b',x/2048,y/2048,z/2048,nx/127,ny/127,nz/127,
                                u/65535,v/65535,0,0,0,0))
        for face in faces:
            f.write(struct.pack('<3I',*face))


def all_models():
    for name,_,base,second in PET_SPECS:
        yield sculpt_species(name,base,second,GameSculpt)
    for name in CROP_NAMES:
        for stage in (1,2,3):
            yield sculpt_crop(name,stage,GameSculpt)
    for name in ASSET_NAMES:
        yield sculpt_world(name,GameSculpt)
    from orchard_sculpt import loam,verge,watering_can
    yield loam(GameSculpt)
    yield verge(GameSculpt)
    yield watering_can(GameSculpt)
    yield from create_gardener_pack(GameSculpt)


def string_value(name,value):
    return {'className':'StringValue','name':name,'properties':{'Value':value}}


def bake(studio=None):
    nodes=[]
    directory=None
    if studio:
        directory=studio/'content'/'dwtm_orchard'
        directory.mkdir(parents=True,exist_ok=True)
        (directory/'pigments.png').write_bytes(_palette_png(KEYS))
    # Reuse exactly the GLB pigment atlas in both runtime and local file mode.
    atlas=_palette_png(KEYS)
    width,height=struct.unpack_from('>II',atlas,16)
    assert atlas[37:41]==b'IDAT'
    rgb=zlib.decompress(atlas[41:41+struct.unpack_from('>I',atlas,33)[0]])
    rgba=bytearray()
    for y in range(height):
        row=y*(1+width*3)
        assert rgb[row]==0
        for x in range(width):
            i=row+1+3*x
            rgba.extend(rgb[i:i+3]+b'\xff')
    nodes.append(string_value('Pigments',json.dumps([width,height,pack(rgba)])))
    meshes=triangles=0
    for model in all_models():
        overall,span=bounds(p for m in model.parts.values() for points,_ in m.values() for p in points)
        pieces=[]
        for name,materials in model.parts.items():
            if not materials: continue
            center,size,data,verts,faces=encode_part(materials,overall,span)
            parent,pivot=model.joints.get(name,('Body',(0,0,0)))
            pieces.append(dict(name=name,parent=parent,pivot=pivot,center=center,size=size,data=pack(data)))
            if directory:
                native_mesh(directory/(model.name+'_'+name+'.mesh'),verts,faces)
            meshes+=1
            triangles+=len(faces)
        nodes.append(string_value(model.name,json.dumps(dict(center=overall,size=span,parts=pieces),separators=(',',':'))))
    (ROOT/'assets'/'OrchardGeometry.model.json').write_text(json.dumps({'className':'Folder','children':nodes},separators=(',',':'))+'\n')
    print(f'{len(nodes)-1} assets, {meshes} indexed mesh sections, {triangles:,} triangles')


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--studio',type=Path)
    bake(parser.parse_args().studio)
