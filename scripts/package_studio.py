"""Make a private Windows Studio kit from the actual Rojo XML place and its packed art."""
import argparse
import base64
import ctypes
import ctypes.util
import hashlib
import json
from pathlib import Path
import shutil
import struct
import xml.etree.ElementTree as ET
import zipfile
import zlib

ROOT=Path(__file__).resolve().parents[1]


def unpack(text):
    blob=base64.b64decode(text,validate=True)
    lib=ctypes.CDLL(ctypes.util.find_library('zstd'))
    lib.ZSTD_getFrameContentSize.restype=ctypes.c_ulonglong
    size=lib.ZSTD_getFrameContentSize(blob,len(blob))
    assert 0<size<8*1024*1024
    dest=ctypes.create_string_buffer(size)
    lib.ZSTD_decompress.restype=ctypes.c_size_t
    assert lib.ZSTD_decompress(dest,size,blob,len(blob))==size
    return dest.raw


def png(width,height,rgba):
    def chunk(tag,data):
        return struct.pack('>I',len(data))+tag+data+struct.pack('>I',zlib.crc32(tag+data))
    rows=b''.join(b'\x00'+rgba[y*4*width:(y+1)*4*width] for y in range(height))
    return (b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',width,height,8,6,0,0,0))
            +chunk(b'IDAT',zlib.compress(rows,9))+chunk(b'IEND',b''))


def item(parent,kind,name):
    instance=ET.SubElement(parent,'Item',{'class':kind,'referent':'DWTM_'+name})
    props=ET.SubElement(instance,'Properties')
    ET.SubElement(props,'string',name='Name').text=name
    return instance,props


def content(props,name,uri):
    prop=ET.SubElement(props,'Content',name=name)
    ET.SubElement(prop,'url').text=uri


def package(place,directory):
    from bake_orchard import native_mesh,VERTEX
    tree=ET.parse(place)
    storage=tree.find('./Item[@class="ServerStorage"]')
    replicated=tree.find('./Item[@class="ReplicatedStorage"]')
    assert storage is not None and replicated is not None
    rack,_=item(storage,'Folder','StudioMeshFiles')
    bank=next(f for f in storage.findall('Item') if f.findtext('./Properties/string[@name="Name"]')=='OrchardGeometry')
    identifier=hashlib.sha256(ET.tostring(bank)).hexdigest()[:12]
    namespace='dwtm_orchard_'+identifier
    files=directory/'content'/namespace
    files.mkdir(exist_ok=True,parents=True)
    _,marker=item(replicated,'StringValue','StudioContentFolder')
    ET.SubElement(marker,'string',name='Value').text=namespace
    for entry in bank.findall('Item'):
        name=entry.findtext('./Properties/string[@name="Name"]')
        record=json.loads(entry.findtext('./Properties/string[@name="Value"]'))
        if name=='Pigments':
            w,h,payload=record
            (files/'pigments.png').write_bytes(png(w,h,unpack(payload)))
            continue
        for piece in record['parts']:
            key=name+'_'+piece['name']
            raw=unpack(piece['data'])
            nv,nf=struct.unpack_from('<II',raw)
            offset=8+nv*VERTEX.size
            assert offset+12*nf//2==len(raw)
            verts=list(VERTEX.iter_unpack(raw[8:offset]))
            faces=list(struct.iter_unpack('<3H',raw[offset:]))
            native_mesh(files/(key+'.mesh'),verts,faces)
            _,props=item(rack,'MeshPart',key)
            content(props,'MeshId','rbxasset://'+namespace+'/'+key+'.mesh')
            content(props,'TextureID','rbxasset://'+namespace+'/pigments.png')
            for field in ('InitialSize','size'):
                vec=ET.SubElement(props,'Vector3',name=field)
                for axis,v in zip('XYZ',piece['size']):
                    ET.SubElement(vec,axis).text=str(max(v,.001))
            ET.SubElement(props,'bool',name='DoubleSided').text='true'
            ET.SubElement(props,'bool',name='Anchored').text='true'
            ET.SubElement(props,'bool',name='CanCollide').text='false'
    for wav in sorted((ROOT/'assets/audio').glob('*.wav')):
        shutil.copyfile(wav,files/wav.name)
    dest=directory/'DontWakeTheMonster-Studio.rbxlx'
    tree.write(dest,encoding='utf-8',xml_declaration=False)
    shutil.copyfile(ROOT/'scripts/open_studio_kit.ps1',directory/'Open-Studio.ps1')
    shutil.copyfile(ROOT/'docs/STUDIO_KIT_RU.md',directory/'README.md')
    archive=directory.with_suffix('.zip')
    with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=7) as zipped:
        for f in sorted([dest,directory/'Open-Studio.ps1',directory/'README.md',*files.iterdir()]):
            zipped.write(f,f.relative_to(directory))
    return archive


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('place',type=Path)
    parser.add_argument('directory',type=Path)
    args=parser.parse_args()
    print(package(args.place,args.directory))
