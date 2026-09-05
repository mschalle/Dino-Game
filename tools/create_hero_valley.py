import bpy
import math
import os

OUT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets", "environment", "hero_valley.glb"))
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)

def mat(name, color, roughness=0.9):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1.0)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    return m

grass = mat("Valley Grass", (0.22, 0.34, 0.12))
soil = mat("Exposed Soil", (0.28, 0.16, 0.08))
rock = mat("Ridge Rock", (0.25, 0.24, 0.21))
wet = mat("Wetland Silt", (0.16, 0.28, 0.24))

size = 60.0
# Match the current collision grid until the shared heightfield milestone lands.
steps = 30
verts = []
faces = []
materials = []
for z_i in range(steps + 1):
    z = -size / 2.0 + size * z_i / steps
    for x_i in range(steps + 1):
        x = -size / 2.0 + size * x_i / steps
        height = 2.0 * math.exp(-((x + 13.0) ** 2 + (z - 11.0) ** 2) / 85.0)
        height += 4.0 * math.exp(-((x - 14.0) ** 2 + (z + 12.0) ** 2) / 70.0)
        height += 6.0 * math.exp(-(x ** 2 + (z + 18.0) ** 2) / 62.0)
        height += 3.5 * math.exp(-((x - 17.0) ** 2 + (z - 17.0) ** 2) / 95.0)
        height -= 1.4 * math.exp(-((x - 19.0) ** 2 + (z + 4.0) ** 2) / 32.0)
        # Blender Z-up -> glTF/Godot Y-up maps (x, -z, height) to (x, height, z).
        verts.append((x, -z, height))
for z_i in range(steps):
    for x_i in range(steps):
        a = z_i * (steps + 1) + x_i
        # Explicit diagonals match the Godot collision mesh; faces point upward.
        faces.extend([(a, a + steps + 2, a + 1), (a, a + steps + 1, a + steps + 2)])
        center_x = -size / 2.0 + size * (x_i + 0.5) / steps
        center_z = -size / 2.0 + size * (z_i + 0.5) / steps
        if center_z > 8.0 and center_x < -3.0:
            materials.extend([3, 3])
        elif abs(center_x - 13.0) < 11.0 and center_z < 1.0:
            materials.extend([2, 2])
        elif abs(center_x) + abs(center_z) > 40.0:
            materials.extend([1, 1])
        else:
            materials.extend([0, 0])

mesh = bpy.data.meshes.new("HeroValleyTerrain")
mesh.from_pydata(verts, [], faces)
for material in (grass, soil, rock, wet):
    mesh.materials.append(material)
mesh.update()
obj = bpy.data.objects.new("HeroValleyTerrain", mesh)
bpy.context.collection.objects.link(obj)
for poly, material_index in zip(mesh.polygons, materials):
    poly.material_index = material_index
obj["collision_source"] = "terrain_surface"
obj["navigation_slope_degrees"] = 35.0
obj["navigation_agent_radius"] = 0.8
bpy.context.view_layer.objects.active = obj
obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True)
print(OUT)
