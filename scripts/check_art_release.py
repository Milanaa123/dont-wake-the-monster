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
        assert pos["count"]==indices["count"]
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
