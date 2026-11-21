#!/usr/bin/env python3
"""Validate *runtime-packed* 3D geometry, not only Studio .mesh previews.

The Roblox game uses the Zstd/base64 packed EditableMesh records in
assets/OrchardGeometry.model.json. A clean GLB or native mesh is not
sufficient evidence those runtime buffers are valid. This checker runs
after the sculpt bake and before Rojo builds a playable place.
"""
import json
import math
import struct
from pathlib import Path
from bake_orchard import VERTEX
from package_studio import unpack

ROOT=Path(__file__).resolve().parents[1]
path=ROOT/"assets/OrchardGeometry.model.json"
container=json.loads(path.read_text(encoding="utf-8"))
assert container["className"]=="Folder"
assets=container["children"]
total_vertices=0
total_triangles=0
total_sections=0

for record in assets:
    assert record["className"]=="StringValue"
    name=record["name"]
    metadata=json.loads(record["properties"]["Value"])
    if name=="Pigments":
        assert len(metadata)==3
        continue
    assert metadata["parts"], f"Missing runtime mesh sections for {name}"
    for part in metadata["parts"]:
        section=f"{name}/{part['name']}"
        raw=unpack(part["data"])
        assert len(raw)>8, f"Empty compressed runtime mesh: {section}"
        nv,nf=struct.unpack_from("<II",raw)
        assert 0<nv<65536 and nf>0, f"Unreasonable mesh size: {section}"
        vertex_end=8+nv*VERTEX.size
        assert len(raw)==vertex_end+nf*6, f"Truncated runtime mesh: {section}"
        vertices=list(VERTEX.iter_unpack(raw[8:vertex_end]))
        referenced=bytearray(nv)
        for idx,(a,b,c) in enumerate(struct.iter_unpack("<3H",raw[vertex_end:])):
            assert a<nv and b<nv and c<nv, f"Invalid triangle index: {section}/{idx}"
            assert a!=b and a!=c and b!=c, f"Collapsed runtime triangle: {section}/{idx}"
            for i in (a,b,c):
                referenced[i]=1
            pa=vertices[a][:3];pb=vertices[b][:3];pc=vertices[c][:3]
            ab=[pb[i]-pa[i] for i in range(3)]
            ac=[pc[i]-pa[i] for i in range(3)]
            cross=(ab[1]*ac[2]-ab[2]*ac[1],
                   ab[2]*ac[0]-ab[0]*ac[2],
                   ab[0]*ac[1]-ab[1]*ac[0])
            assert any(cross), f"Zero-area runtime triangle: {section}/{idx}"
        assert all(referenced), (
            f"Unreferenced runtime vertices found: {section}: "
            f"{nv-sum(referenced)} of {nv}"
        )
        for index,vertex in enumerate(vertices):
            nx,ny,nz=vertex[3:6]
            assert nx*nx+ny*ny+nz*nz>0, f"Zero-length normal: {section}/{index}"
            assert all(isinstance(x,int) for x in vertex), f"Invalid vertex: {section}/{index}"
            assert all(0<=value<=65535 for value in vertex[6:8]), (
                f"Invalid runtime UV: {section}/{index}"
            )
        total_vertices+=nv
        total_triangles+=nf
        total_sections+=1

assert total_sections>=300, f"Missing split mesh sections: {total_sections}"
assert total_vertices>100000, f"Unexpectedly small runtime art library: {total_vertices}"
print(
    f"PASS: {len(assets)-1} runtime assets, {total_sections} indexed sections, "
    f"{total_vertices:,} all-referenced vertices, {total_triangles:,} nondegenerate "
    "faces, no zero normals or corrupt UVs"
)
