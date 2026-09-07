"""Generate five recognizable, rigged low-poly dinosaurs and export Godot GLBs.

Run with Blender 4.4+:
  blender --background --factory-startup --python tools/generate_5_dinosaurs.py -- \
    --output-dir assets/models/dinosaurs
"""

import argparse
import math
import os
import sys

import bpy
from mathutils import Matrix, Vector


CLIPS = ("Idle", "Walk", "Run", "Attack", "Eat", "Hit", "Defeat")
SPECIES = {
    "t_rex": {"body": (0.28, 0.48, 0.20), "accent": (0.62, 0.72, 0.25), "kind": "biped", "ability": "Roar"},
    "triceratops": {"body": (0.48, 0.36, 0.22), "accent": (0.86, 0.68, 0.32), "kind": "quad", "ability": "HornPush"},
    "velociraptor": {"body": (0.22, 0.42, 0.52), "accent": (0.86, 0.62, 0.20), "kind": "biped", "ability": "Dash"},
    "stegosaurus": {"body": (0.38, 0.52, 0.25), "accent": (0.82, 0.42, 0.20), "kind": "quad", "ability": "TailSweep"},
    "ankylosaurus": {"body": (0.30, 0.42, 0.20), "accent": (0.68, 0.58, 0.28), "kind": "quad", "ability": "TailSwing"},
}


def args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", default=os.path.join(os.path.dirname(__file__), "..", "assets", "models", "dinosaurs"))
    return parser.parse_args(sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else [])


def material(name, color, emission=False):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1.0)
    shader.inputs["Roughness"].default_value = 0.82
    if emission:
        shader.inputs["Emission Color"].default_value = (*color, 1.0)
        shader.inputs["Emission Strength"].default_value = 0.8
    return mat


def activate(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def remove_previous_output():
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    for obj in list(bpy.data.objects):
        if obj.get("roar_rise_generated", False):
            bpy.data.objects.remove(obj, do_unlink=True)


def add_ellipsoid(name, location, scale, mat, bone, parts, subdivisions=1):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisions, radius=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    obj.vertex_groups.new(name=bone).add(range(len(obj.data.vertices)), 1.0, "REPLACE")
    obj["roar_rise_generated"] = True
    parts.append(obj)
    return obj


def add_cone(name, start, end, radius, mat, bone, parts, vertices=8):
    start, end = Vector(start), Vector(end)
    direction = end - start
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius, radius2=radius * 0.12,
                                    depth=direction.length, location=(start + end) * 0.5)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(direction.normalized())
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    obj.data.materials.append(mat)
    obj.vertex_groups.new(name=bone).add(range(len(obj.data.vertices)), 1.0, "REPLACE")
    obj["roar_rise_generated"] = True
    parts.append(obj)
    return obj


def create_rig(species, quadruped):
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    rig = bpy.context.object
    rig.name = f"{species}_Rig"
    rig["roar_rise_generated"] = True
    rig.data.edit_bones.remove(rig.data.edit_bones[0])

    def bone(name, head, tail, parent=None):
        item = rig.data.edit_bones.new(name)
        item.head, item.tail = head, tail
        if parent:
            item.parent = rig.data.edit_bones[parent]

    bone("Root", (0, 0, 0.1), (0, 0, 0.65))
    bone("Spine", (0, 0, 0.65), (0, -0.65, 1.15), "Root")
    bone("Neck", (0, -0.65, 1.15), (0, -1.12, 1.42), "Spine")
    bone("Head", (0, -1.12, 1.42), (0, -1.72, 1.38), "Neck")
    bone("Jaw", (0, -1.20, 1.31), (0, -1.72, 1.24), "Head")
    bone("Tail01", (0, 0.42, 0.92), (0, 1.25, 0.78), "Spine")
    bone("Tail02", (0, 1.25, 0.78), (0, 2.20, 0.60), "Tail01")
    for side, suffix in ((-1, "L"), (1, "R")):
        x = 0.38 * side
        if quadruped:
            bone(f"Foreleg.{suffix}", (x, -0.62, 0.78), (x, -0.68, 0.08), "Spine")
        else:
            bone(f"Arm.{suffix}", (x * 0.72, -0.74, 1.16), (x * 0.90, -1.02, 0.91), "Spine")
        bone(f"Leg.{suffix}", (x, 0.28, 0.76), (x, 0.20, 0.08), "Root")
    bpy.ops.object.mode_set(mode="OBJECT")
    return rig


def build_mesh(species, config, rig):
    body = material(f"{species}_Body", config["body"])
    accent = material(f"{species}_Accent", config["accent"])
    eyes = material(f"{species}_Eyes", (0.025, 0.02, 0.012), True)
    parts = []
    quad = config["kind"] == "quad"
    body_scale = (0.72, 1.15, 0.67) if quad else (0.62, 1.03, 0.74)
    add_ellipsoid("Body", (0, 0, 1.0), body_scale, body, "Spine", parts, 2)
    add_ellipsoid("Head", (0, -1.30, 1.46), (0.45, 0.55, 0.40), body, "Head", parts, 1)
    add_ellipsoid("Snout", (0, -1.72, 1.34), (0.34, 0.38, 0.23), accent, "Head", parts, 1)
    add_cone("TailA", (0, 0.66, 1.00), (0, 1.48, 0.75), 0.34, body, "Tail01", parts)
    add_cone("TailB", (0, 1.42, 0.75), (0, 2.45, 0.52), 0.20, body, "Tail02", parts)
    for side, suffix in ((-1, "L"), (1, "R")):
        add_ellipsoid("Eye", (0.32 * side, -1.58, 1.58), (0.065, 0.07, 0.065), eyes, "Head", parts)
        add_cone("HindLeg", (0.39 * side, 0.30, 0.72), (0.42 * side, 0.24, 0.06), 0.17, body, f"Leg.{suffix}", parts)
        add_ellipsoid("Foot", (0.42 * side, 0.05, 0.08), (0.19, 0.35, 0.10), accent, f"Leg.{suffix}", parts)
        limb = f"Foreleg.{suffix}" if quad else f"Arm.{suffix}"
        start = (0.38 * side, -0.62, 0.78) if quad else (0.27 * side, -0.72, 1.18)
        end = (0.40 * side, -0.70, 0.07) if quad else (0.37 * side, -1.04, 0.89)
        add_cone("Forelimb", start, end, 0.13 if quad else 0.075, body, limb, parts)

    if species == "triceratops":
        add_ellipsoid("Frill", (0, -1.02, 1.55), (0.70, 0.18, 0.64), accent, "Head", parts, 2)
        for side in (-1, 1):
            add_cone("BrowHorn", (0.27 * side, -1.55, 1.60), (0.30 * side, -2.05, 1.78), 0.09, accent, "Head", parts)
        add_cone("NoseHorn", (0, -1.91, 1.42), (0, -2.15, 1.57), 0.075, accent, "Head", parts)
    elif species == "stegosaurus":
        for index in range(7):
            y = 0.72 - index * 0.28
            height = 0.42 - abs(index - 3) * 0.045
            add_cone("Plate", (0, y, 1.52), (0, y, 1.52 + height), 0.20, accent, "Spine", parts, 5)
        for side in (-1, 1):
            add_cone("TailSpike", (0.10 * side, 1.95, 0.62), (0.44 * side, 2.46, 0.82), 0.07, accent, "Tail02", parts)
    elif species == "ankylosaurus":
        for row in range(3):
            for side in (-1, 0, 1):
                add_ellipsoid("Armor", (side * 0.34, 0.42 - row * 0.42, 1.58), (0.18, 0.24, 0.10), accent, "Spine", parts)
        add_ellipsoid("TailClub", (0, 2.48, 0.54), (0.38, 0.44, 0.30), accent, "Tail02", parts, 2)
    elif species == "velociraptor":
        for side in (-1, 1):
            suffix = "L" if side == -1 else "R"
            add_cone("SickleClaw", (0.42 * side, -0.12, 0.12), (0.42 * side, -0.42, 0.22), 0.055, accent, f"Leg.{suffix}", parts)
    elif species == "t_rex":
        for side in (-1, 1):
            add_cone("Brow", (0.24 * side, -1.54, 1.69), (0.25 * side, -1.72, 1.72), 0.07, accent, "Head", parts)

    activate(parts[0])
    for part in parts[1:]:
        part.select_set(True)
    bpy.ops.object.join()
    mesh = bpy.context.object
    mesh.name = f"{species}_Mesh"
    mesh.parent = rig
    mesh.matrix_parent_inverse = Matrix.Identity(4)
    modifier = mesh.modifiers.new("Armature", "ARMATURE")
    modifier.object = rig
    return mesh


def animate(rig, ability):
    rig.animation_data_create()
    durations = {"Idle": 48, "Walk": 32, "Run": 22, "Attack": 20, "Eat": 34, "Hit": 16, "Defeat": 40, ability: 34}
    for clip, end in durations.items():
        action = bpy.data.actions.new(f"{rig.name}_{clip}")
        action.use_fake_user = True
        rig.animation_data.action = action
        for frame in (1, end // 2, end):
            phase = (frame - 1) / max(1, end - 1)
            wave = math.sin(phase * math.tau)
            pulse = math.sin(phase * math.pi)
            for pose_bone in rig.pose.bones:
                pose_bone.rotation_mode = "XYZ"
                pose_bone.rotation_euler = (0, 0, 0)
                pose_bone.location = (0, 0, 0)
            if clip in ("Idle", "Walk", "Run"):
                amount = 0.04 if clip == "Idle" else (0.30 if clip == "Walk" else 0.48)
                rig.pose.bones["Tail01"].rotation_euler.z = wave * amount * 0.45
                rig.pose.bones["Tail02"].rotation_euler.z = wave * amount
                for suffix, direction in (("L", 1), ("R", -1)):
                    rig.pose.bones[f"Leg.{suffix}"].rotation_euler.x = wave * amount * direction
            elif clip in ("Attack", ability):
                rig.pose.bones["Head"].rotation_euler.x = -0.38 * pulse
                rig.pose.bones["Jaw"].rotation_euler.x = 0.42 * pulse
                rig.pose.bones["Tail01"].rotation_euler.z = 0.35 * pulse
            elif clip == "Eat":
                rig.pose.bones["Neck"].rotation_euler.x = 0.55 * pulse
                rig.pose.bones["Jaw"].rotation_euler.x = 0.30 * pulse
            elif clip == "Hit":
                rig.pose.bones["Spine"].rotation_euler.z = 0.24 * pulse
            elif clip == "Defeat":
                rig.pose.bones["Root"].rotation_euler.y = 1.15 * phase
                rig.pose.bones["Root"].location.z = -0.35 * phase
            for pose_bone in rig.pose.bones:
                pose_bone.keyframe_insert("rotation_euler", frame=frame, group=pose_bone.name)
                pose_bone.keyframe_insert("location", frame=frame, group=pose_bone.name)
        rig.animation_data.action = None
        track = rig.animation_data.nla_tracks.new()
        track.name = clip
        strip = track.strips.new(clip, 1, action)
        strip.name = clip


def build_and_export(species, config, output_dir, display_offset):
    rig = create_rig(species, config["kind"] == "quad")
    mesh = build_mesh(species, config, rig)
    animate(rig, config["ability"])
    activate(rig)
    mesh.select_set(True)
    path = os.path.join(output_dir, f"{species}.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_yup=True,
                              export_animations=True, export_animation_mode="NLA_TRACKS",
                              export_force_sampling=True, export_skins=True, export_materials="EXPORT")
    rig.location.x = display_offset
    return path


def main():
    options = args()
    output_dir = os.path.abspath(options.output_dir)
    os.makedirs(output_dir, exist_ok=True)
    remove_previous_output()
    paths = []
    for index, (species, config) in enumerate(SPECIES.items()):
        paths.append(build_and_export(species, config, output_dir, (index - 2) * 4.5))
    print(f"Generated {len(paths)} rigged dinosaur GLBs in {output_dir}")
    for path in paths:
        print(path)


if __name__ == "__main__":
    main()
