"""Normalize the glTF skin hierarchy via Blender without modifying the source."""
import argparse
import sys
import bpy

parser = argparse.ArgumentParser()
parser.add_argument('--source', required=True)
parser.add_argument('--output', required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=args.source)
bpy.ops.export_scene.gltf(filepath=args.output, export_format='GLB',
                          export_animations=True, export_animation_mode='ACTIONS')
