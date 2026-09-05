import bpy
import math
import os

OUTPUT = os.path.abspath("assets/models/dinosaurs/t_rex_hero.glb")
os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)

def material(name, color, emission=False):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.85
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*color, 1.0)
        bsdf.inputs["Emission Strength"].default_value = 1.5
    return mat

body_mat = material("Body", (0.30, 0.62, 0.22))
accent_mat = material("Accent", (0.92, 0.70, 0.27))
eye_mat = material("Eyes", (0.03, 0.04, 0.02), True)
root = bpy.data.objects.new("YoungTRex", None)
bpy.context.collection.objects.link(root)

def parent(obj):
    obj.parent = root
    return obj

def ico(name, location, scale, mat):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return parent(obj)

def cube(name, location, scale, mat):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    # Small bevels keep the hero silhouette rounded while retaining a low-poly style.
    bevel = obj.modifiers.new("Hero bevel", "BEVEL")
    bevel.width = 0.035
    bevel.segments = 2
    return parent(obj)

def cone(name, location, radius1, radius2, depth, mat, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=radius1, radius2=radius2, depth=depth, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    bevel = obj.modifiers.new("Hero bevel", "BEVEL")
    bevel.width = 0.025
    bevel.segments = 2
    return parent(obj)

ico("Body", (0, 0.95, 0), (0.75, 0.65, 1.15), body_mat)
ico("Chest", (0, 1.10, -0.65), (0.62, 0.62, 0.70), accent_mat)
cube("Head", (0, 1.45, -1.12), (0.62, 0.45, 0.68), body_mat)
cube("Snout", (0, 1.28, -1.65), (0.48, 0.28, 0.52), accent_mat)
cone("Tail", (0, 0.95, 1.45), 0.42, 0.04, 2.7, body_mat, (math.pi / 2, 0, 0))
for side in (-1, 1):
    ico("Eye", (side * 0.34, 1.62, -1.58), (0.09, 0.09, 0.09), eye_mat)
    cone("Leg", (side * 0.42, 0.43, -0.10), 0.18, 0.12, 0.75, body_mat)
    ico("Foot", (side * 0.42, 0.12, -0.30), (0.24, 0.12, 0.35), accent_mat)
    cone("Arm", (side * 0.48, 0.95, -0.75), 0.10, 0.05, 0.48, body_mat, (0, side * 0.35, 0))
for side in (-1, 1):
    cone("Tooth", (side * 0.22, 1.12, -1.98), 0.055, 0.0, 0.18, eye_mat)

# Rounded dorsal plates give the hero silhouette a readable ridge at gameplay distance.
for index in range(5):
    ico("DorsalPlate", (0, 1.55 - index * 0.08, 0.35 + index * 0.35), (0.18, 0.28, 0.12), accent_mat)

def action(name, frames, data_path, values):
    # Blender 5.x uses the new layered Action API; animation clips are added
    # in the dedicated rig pass after the shared model silhouette is approved.
    return

action("Idle", [1, 20, 40], "location.z", [0.0, 0.04, 0.0])
action("Walk", [1, 10, 20], "location.z", [0.0, 0.08, 0.0])
action("Run", [1, 6, 12], "location.z", [0.0, 0.12, 0.0])
action("Attack", [1, 8, 16], "rotation_euler[1]", [0.0, -0.22, 0.0])
action("Eat", [1, 8, 16], "rotation_euler[0]", [0.0, 0.18, 0.0])
action("Hit", [1, 6, 12], "rotation_euler[2]", [0.0, 0.12, 0.0])
action("Defeat", [1, 12, 24], "rotation_euler[0]", [0.0, 0.35, 0.7])

bpy.ops.object.select_all(action="SELECT")
bpy.context.view_layer.objects.active = root
bpy.ops.export_scene.gltf(filepath=OUTPUT, export_format="GLB", export_animations=True, export_materials="EXPORT")
print("Exported", OUTPUT)
