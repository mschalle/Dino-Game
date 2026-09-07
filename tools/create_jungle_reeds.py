"""Original riverbank reed clump. Run Blender --background --python this-file."""
import bpy
import math
import random
from pathlib import Path

random.seed(72)
root = Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
image = bpy.data.images.new('OriginalReedVeins', width=128, height=128)
pixels = []
for y in range(128):
    for x in range(128):
        vein = 0.035 * math.sin(x * 0.8) + random.uniform(-0.015, 0.015)
        pixels.extend((0.21 + vein, 0.32 + vein, 0.115 + vein * 0.5, 1.0))
image.pixels = pixels
image.pack()
material = bpy.data.materials.new('ReedLeaves')
material.use_nodes = True
texture = material.node_tree.nodes.new('ShaderNodeTexImage')
texture.image = image
material.node_tree.links.new(texture.outputs['Color'], material.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
material.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value = 0.85
for index in range(11):
    angle = index * 2.4
    length = random.uniform(0.65, 1.15)
    radius = random.uniform(0.04, 0.22)
    vertices, faces = [], []
    for step in range(9):
        t = step / 8
        width = math.sin(math.pi * t) * 0.045 + 0.001
        bend = t * t * 0.32
        for side in [-1, 1]:
            vertices.append(((radius + bend) * math.cos(angle) - side * width * math.sin(angle),
                             (radius + bend) * math.sin(angle) + side * width * math.cos(angle),
                             length * t))
    for step in range(8):
        a = step * 2
        faces.append((a, a+1, a+3, a+2))
    mesh = bpy.data.meshes.new('ReedBlade')
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(material)
    obj = bpy.data.objects.new('Reed_%02d' % index, mesh)
    bpy.context.collection.objects.link(obj)
    uv = mesh.uv_layers.new()
    for polygon in mesh.polygons:
        polygon.use_smooth = True
        for loop_index in polygon.loop_indices:
            v = mesh.loops[loop_index].vertex_index
            uv.data[loop_index].uv = (float(v % 2), (v // 2) / 8)
bpy.ops.wm.save_as_mainfile(filepath=str(root / 'art_source' / 'jungle_reeds.blend'))
bpy.ops.export_scene.gltf(filepath=str(root / 'assets/environment/jungle_reeds.glb'), export_format='GLB')
print('Original jungle reeds exported')
