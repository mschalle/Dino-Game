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
steps = 48
verts = []
faces = []
materials = []
for z_i in range(steps + 1):
    z = -size / 2.0 + size * z_i / steps
    for x_i in range(steps + 1):
        x = -size / 2.0 + size * x_i / steps
        ridge = 4.5 * math.exp(-((x - 13.0) ** 2 + (z + 10.0) ** 2) / 180.0)
        overlook = 3.0 * math.exp(-((x + 18.0) ** 2 + (z - 17.0) ** 2) / 120.0)
        wetland = -1.0 * math.exp(-((x + 10.0) ** 2 + (z - 12.0) ** 2) / 100.0)
        basin = 0.35 * math.sin(x * 0.22) * math.cos(z * 0.18)
        verts.append((x, ridge + overlook + wetland + basin, z))
for z_i in range(steps):
    for x_i in range(steps):
        a = z_i * (steps + 1) + x_i
        faces.append((a, a + 1, a + steps + 2, a + steps + 1))
        center_x = -size / 2.0 + size * (x_i + 0.5) / steps
        center_z = -size / 2.0 + size * (z_i + 0.5) / steps
        if center_z > 8.0 and center_x < -3.0:
            materials.append(3)
        elif abs(center_x - 13.0) < 11.0 and center_z < 1.0:
            materials.append(2)
        elif abs(center_x) + abs(center_z) > 40.0:
            materials.append(1)
        else:
            materials.append(0)

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
