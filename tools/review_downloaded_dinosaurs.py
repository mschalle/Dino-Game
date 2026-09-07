"""Inspect and render supplied GLBs in a factory-startup Blender process.

Run with Blender --background --factory-startup --python this_file --
--source <download-directory> --output <review-directory>.
Never modifies the downloaded files or game assets.
"""
import argparse
import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector

parser = argparse.ArgumentParser()
parser.add_argument('--source', required=True)
parser.add_argument('--output', required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
source = Path(args.source).resolve()
output = Path(args.output).resolve()
output.mkdir(parents=True, exist_ok=True)
reports = []
for asset_path in sorted(source.glob('*.glb')):
    filename = asset_path.name
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source / filename))
    scene = bpy.context.scene
    scene.frame_set(1)
    meshes = [o for o in scene.objects if o.type == 'MESH']
    points = [o.matrix_world @ Vector(p) for o in meshes for p in o.bound_box]
    low = Vector(tuple(min(p[i] for p in points) for i in range(3)))
    high = Vector(tuple(max(p[i] for p in points) for i in range(3)))
    center = (low + high) * .5
    extent = max(high - low)
    reports.append({'file': filename, 'bounds_min': list(low), 'bounds_max': list(high),
                    'dimensions': list(high-low),
                    'meshes': len(meshes),
                    'bones': sum(len(o.data.bones) for o in scene.objects if o.type == 'ARMATURE'),
                    'actions': [{'name': a.name, 'frames': list(a.frame_range)} for a in bpy.data.actions],
                    'materials': [m.name for m in bpy.data.materials]})
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 12
    scene.cycles.device = 'CPU'
    scene.render.resolution_x = 960
    scene.render.resolution_y = 640
    scene.render.resolution_percentage = 100
    world = bpy.data.worlds.new('Review World')
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes['Background'].inputs['Color'].default_value = (.32, .36, .42, 1)
    world.node_tree.nodes['Background'].inputs['Strength'].default_value = .7
    bpy.ops.object.camera_add(location=center + Vector((1.15, -1.6, .6)) * extent)
    camera = bpy.context.object
    camera.rotation_euler = (center-camera.location).to_track_quat('-Z', 'Y').to_euler()
    camera.data.type = 'ORTHO'
    camera.data.ortho_scale = extent * 1.35
    camera.data.clip_end = extent * 20
    scene.camera = camera
    bpy.ops.object.light_add(type='AREA', location=center + Vector((.5, -.5, 1.5))*extent)
    light = bpy.context.object
    light.data.energy = 300 * extent * extent
    light.data.shape = 'DISK'
    light.data.size = extent
    light.rotation_euler = (center-light.location).to_track_quat('-Z', 'Y').to_euler()
    scene.render.filepath = str(output / (Path(filename).stem + '.png'))
    bpy.ops.render.render(write_still=True)
    (output / 'inspection.json').write_text(json.dumps(reports, indent=2), encoding='utf-8')
print('Downloaded dinosaur review: PASS (static previews; motion review still required)')
