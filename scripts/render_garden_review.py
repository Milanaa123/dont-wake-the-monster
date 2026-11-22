"""Render the packed Roblox meshes and atlas for the garden art comparison.

From the repository root:
    blender -b -P scripts/render_garden_review.py -- assets/OrchardGeometry.model.json dist/review

Use the same script and a previous bake to compare silhouettes under identical lighting.
Coordinates convert from Roblox Y-up and negative-Z forward to Blender Z-up.
"""
import bpy, sys, json, struct
from pathlib import Path
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).resolve().parent))
from package_studio import unpack,png
path, destination=sys.argv[sys.argv.index("--")+1:]
bank={e["name"]:json.loads(e["properties"]["Value"]) for e in json.loads(Path(path).read_text())["children"]}
out=Path(destination).resolve()
out.mkdir(exist_ok=True,parents=True)
atlas=out/"atlas.png"
w,h,rgba=bank["Pigments"]
atlas.write_bytes(png(w,h,unpack(rgba)))
for asset, focus, direction, scale in [
    ("Pet_Floofle",(0,-.1,2.0),(3.5,-9,2.8),5.80),
    ("Pet_Pickle",(0,-.04,1.04),(3.35,-9,3.25),4.22),
    ("Crop_Berry_S3",(0,0,.40),(4,-8,5.2),4.15),
    ("Environment_GardenCottage",(0,-.69,2.0),(5.8,-10,4.4),9.0),
    ("Crop_Berry_S1",(0,0,.40),(4,-8,5.2),4.15),
    ("Crop_Berry_S2",(0,0,.40),(4,-8,5.2),4.15),
    ("Pet_Splat",(0,-.04,1.04),(-4,-9,3.6),4.22)]:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene=bpy.context.scene
    scene.render.engine="CYCLES"
    scene.cycles.samples=28
    scene.cycles.use_denoising=False
    scene.render.resolution_x,scene.render.resolution_y=480,400
    scene.render.resolution_percentage=100
    scene.world=bpy.data.worlds.new("Soft daylight")
    scene.world.use_nodes=True
    scene.world.node_tree.nodes["Background"].inputs[0].default_value=(.77,.83,1,1)
    scene.world.node_tree.nodes["Background"].inputs[1].default_value=.51
    mat=bpy.data.materials.new("Packed pigments")
    mat.use_nodes=True
    nodes=mat.node_tree.nodes
    img=nodes.new("ShaderNodeTexImage")
    img.image=bpy.data.images.load(str(atlas))
    mat.node_tree.links.new(img.outputs["Color"],nodes["Principled BSDF"].inputs["Base Color"])
    for section in bank[asset]["parts"]:
        raw=unpack(section["data"])
        nv,nf=struct.unpack_from("<II",raw)
        end=8+nv*13
        verts=list(struct.iter_unpack("<3h3b2H",raw[8:end]))
        faces=list(struct.iter_unpack("<3H",raw[end:]))
        cx,cy,cz=section["center"]
        mesh=bpy.data.meshes.new(section["name"])
        mesh.from_pydata([(-cx-v[0]/2048,cz+v[2]/2048,cy+v[1]/2048) for v in verts],[],faces)
        mesh.update()
        uv=mesh.uv_layers.new()
        for loop in mesh.loops:
            u,v=verts[loop.vertex_index][-2:]
            uv.data[loop.index].uv=(u/65535,1-v/65535)
        mesh.polygons.foreach_set("use_smooth",[True]*nf)
        mesh.normals_split_custom_set_from_vertices([Vector((-v[3],v[5],v[4])).normalized() for v in verts])
        obj=bpy.data.objects.new(section["name"],mesh)
        scene.collection.objects.link(obj)
        mesh.materials.append(mat)
    low=bank[asset]["center"][1]-bank[asset]["size"][1]/2
    bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,low-.006))
    floor=bpy.data.materials.new("Linen")
    floor.diffuse_color=(.66,.60,.49,1)
    bpy.context.object.data.materials.append(floor)
    target=Vector(focus)
    for pos,power,size in [((-4,-5,8),750,5),((3,4,6),420,4)]:
        bpy.ops.object.light_add(type="AREA",location=pos)
        light=bpy.context.object
        light.rotation_euler=(target-light.location).to_track_quat("-Z","Y").to_euler()
        light.data.energy=power
        light.data.shape="DISK"
        light.data.size=size
    bpy.ops.object.camera_add(location=target+Vector(direction))
    cam=bpy.context.object
    cam.rotation_euler=(-Vector(direction)).to_track_quat("-Z","Y").to_euler()
    cam.data.type="ORTHO"
    cam.data.ortho_scale=scale
    scene.camera=cam
    scene.render.filepath=str(out/(asset+".png"))
    bpy.ops.render.render(write_still=True)
