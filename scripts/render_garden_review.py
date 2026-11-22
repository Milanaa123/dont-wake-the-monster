"""Render packed Roblox meshes in Blender without starting Studio.

After baking the library, run from the repository root:
    blender -b -P scripts/render_garden_review.py -- assets/OrchardGeometry.model.json dist/review Pet_Pip
    blender -b -P scripts/render_garden_review.py -- assets/OrchardGeometry.model.json dist/review --layout entrance-layout.json

The optional layout comes from the Lune built-place test (entrance-layout CI artifact).
"""

import argparse
import json
import struct
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0,str(Path(__file__).resolve().parent))
from package_studio import png, unpack

SHOTS = [
    ("Pet_Swoop",(0,.05,1.27),(3,-9,2.8),3.65),
    ("Pet_Mochi",(0,.07,1.42),(4,-9,3.1),4.25),
    ("Pet_Tofu",(0,.07,1.42),(4,-9,3.1),4.25),
    ("Pet_Luma",(0,.07,1.42),(4,-9,3.1),4.25),
    ("Pet_Pebble",(0,.15,.92),(5,-8,4.8),4.36),
    ("Environment_WaterPond",(0,0,.19),(4,-7,6.7),7.9),
    ("Pet_Pip",(0,.13,1.53),(4,-9,2.9),4.40),
    ("Pet_Zuzu",(0,.13,1.53),(-4,-9,2.9),4.40),
    ("Crop_Tomato_S1",(0,0,1.06),(4,-9,4.6),3.28),
    ("Crop_Tomato_S2",(0,0,1.06),(4,-9,4.6),3.28),
    ("Crop_Tomato_S3",(0,0,1.06),(4,-9,4.6),3.28),
    ("Environment_OrangeTree",(0,0,2.55),(4,-9,2.1),7.55),
    ("Environment_StonePath",(0,5,.11),(4,-6,8),12.40),
    ("Pet_Snorf",(0,.10,1.22),(4,-9,3.1),3.85),
    ("Environment_SleepingMonster",(0,.08,2.06),(3.5,-10,3.15),5.95),
    ("Pet_Floofle",(0,-.1,2.0),(3.5,-9,2.8),5.80),
    ("Pet_Pickle",(0,-.04,1.04),(3.35,-9,3.25),4.22),
    ("Crop_Berry_S3",(0,0,.40),(4,-8,5.2),4.15),
    ("Environment_GardenCottage",(0,-.69,2.0),(5.8,-10,4.4),9.0),
    ("Crop_Berry_S1",(0,0,.40),(4,-8,5.2),4.15),
    ("Crop_Berry_S2",(0,0,.40),(4,-8,5.2),4.15),
    ("Pet_Splat",(0,-.04,1.04),(-4,-9,3.6),4.22)]

# Roblox Y-up, -Z forward -> Blender Z-up, -Y forward.
BASIS=Matrix(((-1,0,0,0),(0,0,1,0),(0,1,0,0),(0,0,0,1)))


def setup_scene(atlas, resolution):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene=bpy.context.scene
    scene.render.engine="CYCLES"
    scene.cycles.samples=28
    scene.cycles.use_denoising=False
    scene.render.resolution_x,scene.render.resolution_y=resolution
    scene.render.resolution_percentage=100
    scene.world=bpy.data.worlds.new("Soft daylight")
    scene.world.use_nodes=True
    sky=scene.world.node_tree.nodes["Background"]
    sky.inputs[0].default_value=(.77,.83,1,1)
    sky.inputs[1].default_value=.51
    mat=bpy.data.materials.new("Packed pigments")
    mat.use_nodes=True
    img=mat.node_tree.nodes.new("ShaderNodeTexImage")
    img.image=bpy.data.images.load(str(atlas))
    mat.node_tree.links.new(img.outputs["Color"],mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"])
    return scene,mat


def decode_section(section, mat):
    raw=unpack(section["data"])
    nv,nf=struct.unpack_from("<II",raw)
    end=8+nv*13
    verts=list(struct.iter_unpack("<3h3b2H",raw[8:end]))
    faces=list(struct.iter_unpack("<3H",raw[end:]))
    mesh=bpy.data.meshes.new(section["name"])
    mesh.from_pydata([(-v[0]/2048,v[2]/2048,v[1]/2048) for v in verts],[],faces)
    mesh.update()
    uv=mesh.uv_layers.new()
    for loop in mesh.loops:
        u,v=verts[loop.vertex_index][-2:]
        uv.data[loop.index].uv=(u/65535,1-v/65535)
    mesh.polygons.foreach_set("use_smooth",[True]*nf)
    mesh.normals_split_custom_set_from_vertices([Vector((-v[3],v[5],v[4])).normalized() for v in verts])
    mesh.materials.append(mat)
    return mesh


def place_mesh(scene, name, mesh, transform):
    obj=bpy.data.objects.new(name,mesh)
    scene.collection.objects.link(obj)
    obj.matrix_world=transform
    return obj


def photograph(scene, path, focus, direction, scale, floor_z, light_scale=1):
    # The neutral floor only receives shadows. It is distinct from the shipped terrain.
    target=Vector(focus)
    bpy.ops.mesh.primitive_plane_add(size=max(200,scale*4),location=(target.x,target.y,floor_z-.006))
    floor=bpy.data.materials.new("Linen")
    floor.diffuse_color=(.66,.60,.49,1)
    bpy.context.object.data.materials.append(floor)
    for pos,power,size in [((-4,-5,8),750,5),((3,4,6),420,4)]:
        location=pos if light_scale==1 else target+Vector(pos)*light_scale
        bpy.ops.object.light_add(type="AREA",location=location)
        light=bpy.context.object
        light.rotation_euler=(target-light.location).to_track_quat("-Z","Y").to_euler()
        light.data.energy=power*light_scale**2
        light.data.shape="DISK"
        light.data.size=size*light_scale
    bpy.ops.object.camera_add(location=target+Vector(direction))
    cam=bpy.context.object
    cam.rotation_euler=(-Vector(direction)).to_track_quat("-Z","Y").to_euler()
    cam.data.type="ORTHO"
    cam.data.ortho_scale=scale
    cam.data.clip_end=max(1000,scale*8)
    scene.camera=cam
    scene.render.filepath=str(path)
    bpy.ops.render.render(write_still=True)


def render_entrance(layout, bank, atlas, out):
    scene,mat=setup_scene(atlas,(1440,880))
    meshes={}
    corners=[]
    for item in layout:
        key=item["asset"]
        section,=bank[key]["parts"]
        assert section["name"]=="Body",key
        if key not in meshes:
            meshes[key]=decode_section(section,mat)
        # Preserve the section-local origin, scale and rigid transform used by the place.
        values=item["cframe"]
        assert len(values)==12
        rotation=Matrix((values[3:6],values[6:9],values[9:12])).to_4x4()
        scale=Matrix.Diagonal([actual/authored for actual,authored in zip(item["size"],section["size"])]+[1])
        transform=BASIS @ Matrix.Translation(values[:3]) @ rotation @ scale @ BASIS.inverted()
        obj=place_mesh(scene,item["name"],meshes[key],transform)
        corners.extend(transform @ Vector(p) for p in obj.bound_box)
    direction=Vector((.39,-.92,.72)).normalized()
    view=(-direction).to_track_quat("-Z","Y")
    view_points=[view.inverted() @ p for p in corners]
    low=Vector([min(p[i] for p in view_points) for i in range(3)])
    high=Vector([max(p[i] for p in view_points) for i in range(3)])
    focus=view @ ((low+high)*.5)
    span=max(high.x-low.x,(high.y-low.y)*scene.render.resolution_x/scene.render.resolution_y)*1.075
    photograph(scene,out/"GardenEntrance.png",focus,direction*span*1.2,span,
               min(p.z for p in corners),light_scale=13)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("bank",type=Path)
    parser.add_argument("output",type=Path)
    parser.add_argument("assets",nargs="*")
    parser.add_argument("--layout",type=Path)
    args=parser.parse_args(sys.argv[sys.argv.index("--")+1:])
    bank={e["name"]:json.loads(e["properties"]["Value"]) for e in json.loads(args.bank.read_text())["children"]}
    out=args.output.resolve()
    out.mkdir(exist_ok=True,parents=True)
    atlas=out/"atlas.png"
    w,h,rgba=bank["Pigments"]
    atlas.write_bytes(png(w,h,unpack(rgba)))
    if args.layout:
        render_entrance(json.loads(args.layout.read_text()),bank,atlas,out)
        return
    for asset,focus,direction,scale in SHOTS:
        if args.assets and asset not in args.assets:
            continue
        scene,mat=setup_scene(atlas,(480,400))
        for section in bank[asset]["parts"]:
            if asset=="Environment_SleepingMonster" and section["name"] in ("EyeL","EyeR"):
                continue
            x,y,z=section["center"]
            place_mesh(scene,section["name"],decode_section(section,mat),Matrix.Translation((-x,z,y)))
        floor_z=bank[asset]["center"][1]-bank[asset]["size"][1]/2
        photograph(scene,out/(asset+".png"),focus,direction,scale,floor_z)


if __name__=="__main__":
    main()
