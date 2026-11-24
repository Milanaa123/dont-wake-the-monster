#!/usr/bin/env python3
"""Offline GLB integrity/visual-readiness gate. Not a Roblox Studio runtime test."""
from __future__ import annotations
import json, pathlib, struct, math

ROOT = pathlib.Path("dist/visual-library")
MANIFEST = ROOT/"manifest.json"
R15 = [
 "Head","UpperTorso","LowerTorso",
 "LeftUpperArm","LeftLowerArm","LeftHand",
 "RightUpperArm","RightLowerArm","RightHand",
 "LeftUpperLeg","LeftLowerLeg","LeftFoot",
 "RightUpperLeg","RightLowerLeg","RightFoot"
]
EXPECT = {
    "DWTM_Pets_30.glb":30,
    "DWTM_Crops_30x3.glb":90,
    "DWTM_World_8.glb":8,
    "DWTM_Gardener_Avatar_15.glb":15,
}
def inspect(path: pathlib.Path):
    raw=path.read_bytes()
    assert len(raw)>=28, f"Empty GLB: {path}"
    magic,version,length=struct.unpack_from("<4sII",raw)
    assert (magic,version,length)==(b"glTF",2,len(raw)), f"Corrupt GLB header: {path}"
    length_json,kind=struct.unpack_from("<I4s",raw,12)
    assert kind==b"JSON" and length_json>64
    data=json.loads(raw[20:20+length_json])
    assert data["scene"]==0 and len(data["scenes"])==1
    assert len(data["images"])==2 and len(data["textures"])==2
    assert data["images"][0]["mimeType"]=="image/png"
    assert data["images"][1]["mimeType"]=="image/png"
    assert data["materials"][0]["pbrMetallicRoughness"]["metallicRoughnessTexture"]["index"]==1
    # Embedded texture blobs must have valid PNG signatures after export.
    for picture in data["images"]:
        view=data["bufferViews"][picture["bufferView"]]
        bin_start=20+length_json+8
        start=bin_start+view["byteOffset"]
        assert raw[start:start+8]==b"\x89PNG\r\n\x1a\n", "Corrupt embedded PBR texture"
    assert len(data["meshes"])==EXPECT[path.name]
    result={}
    for mesh in data["meshes"]:
        name=mesh["name"]
        assert name not in result, f"Duplicate 3D model: {name}"
        assert len(mesh["primitives"])==1, f"One imported MeshPart expected: {name}"
        prim=mesh["primitives"][0]
        assert prim["mode"]==4 and "TEXCOORD_0" in prim["attributes"]
        assert prim["material"]==0
        pos=data["accessors"][prim["attributes"]["POSITION"]]
        indices=data["accessors"][prim["indices"]]
        assert 0<pos["count"]<=indices["count"]
        def records(accessor,fmt):
            view=data["bufferViews"][accessor["bufferView"]]
            start=bin_start+view.get("byteOffset",0)+accessor.get("byteOffset",0)
            size=struct.calcsize(fmt)*accessor["count"]
            assert size<=view["byteLength"]
            return list(struct.iter_unpack(fmt,raw[start:start+size]))
        vertices=records(pos,"<3f")
        normal=data["accessors"][prim["attributes"]["NORMAL"]]
        uv=data["accessors"][prim["attributes"]["TEXCOORD_0"]]
        assert pos["count"]==normal["count"]==uv["count"]
        assert all(.998<sum(k*k for k in n)<1.002 for n in records(normal,"<3f")), name
        texcoords=records(uv,"<2f")
        assert all(0<=u<=1 and 0<=v<=1 for u,v in texcoords),name
        if name=="Environment_WaterPond":
            from generate_reference_glb import MAT
            water=sorted(MAT).index("water")
            depths=[v for u,v in texcoords if int(u*len(MAT))==water]
            assert min(depths)<.22 and max(depths)>.90, "Missing GLB water depth gradient"
        face_indices=[v[0] for v in records(indices,{5123:"<H",5125:"<I"}[indices["componentType"]])]
        assert set(face_indices)==set(range(len(vertices))),name
        for i in range(0,len(face_indices),3):
            a,b,c=(vertices[k] for k in face_indices[i:i+3])
            ab=[v-u for u,v in zip(a,b)]
            ac=[v-u for u,v in zip(a,c)]
            assert any(ab[k]*ac[(k+1)%3]!=ac[k]*ab[(k+1)%3] for k in range(3)),name
        assert indices["count"]%3==0 and indices["count"]>=180
        assert pos["count"]<36000, f"Unexpected high asset complexity: {name}"
        bounds=[hi-lo for lo,hi in zip(pos["min"],pos["max"])]
        assert all(math.isfinite(x) and x>.0001 for x in bounds), f"Invalid AABB: {name}"
        triangles=indices["count"]//3
        if name=="Environment_GardenCottage": assert triangles<12000
        else: assert triangles<9000, f"Polygon budget exceeded: {name} => {triangles}"
        result[name]={"triangles":triangles,"size":bounds}
    return result

def main():
    d=json.loads(MANIFEST.read_text(encoding="utf8"))
    assert len(d["pets"])==30 and len(set(d["pets"]))==30
    assert len(d["crops"])==90 and len(d["environment"])==8 and len(d["avatar"])==15
    assert set(d["avatar"])=={"Avatar_"+v for v in R15}
    byfile={}
    for p in d["packs"]:
        assert p["file"] in EXPECT
        byfile[p["file"]]=inspect(ROOT/p["file"])
        assert p["meshes"]==EXPECT[p["file"]]
        assert sum(x["triangles"] for x in byfile[p["file"]].values())==p["triangles"]
    assert set(byfile)==set(EXPECT)
    assert set(byfile["DWTM_Pets_30.glb"])==set(d["pets"])
    assert set(byfile["DWTM_Crops_30x3.glb"])==set(d["crops"])
    assert set(byfile["DWTM_World_8.glb"])==set(d["environment"])
    assert set(byfile["DWTM_Gardener_Avatar_15.glb"])==set(d["avatar"])
    for species in ("Berry","Carrot","LavaMelon","WhisperWheat"):
        for stage in (1,2,3):
            assert "Crop_"+species+"_S"+str(stage) in byfile["DWTM_Crops_30x3.glb"]
    assert byfile["DWTM_Gardener_Avatar_15.glb"]["Avatar_Head"]["size"][1]>1.5
    total=sum(v["triangles"] for pack in byfile.values() for v in pack.values())
    print(f"PASS: {sum(EXPECT.values())} GLB meshes; {total:,} authored triangles")
    print("PASS: distinct R15 art, 3 growth stages, single textured primitive per importable asset")
    print("CAUTION: Studio import, player camera, animation and mobile runtime still require an in-engine test")
if __name__=="__main__":
    main()
