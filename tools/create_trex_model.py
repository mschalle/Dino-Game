"""Original smooth juvenile T. rex. Blender 5.x, no third-party geometry/textures.

Run from the project root: F:\\Blender\\blender.exe -b --python tools/create_trex_model.py
All design coordinates are Godot (X right, Y up, -Z forward); G converts once
to Blender Z-up. Applied mesh transforms and an identity rig survive glTF skinning.
"""
import math
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/models/dinosaurs"
TEXTURES = OUT / "trex_textures"
SOURCE = ROOT / "art_source"
for directory in (OUT, TEXTURES, SOURCE):
    directory.mkdir(exist_ok=True, parents=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete()
scene = bpy.context.scene
scene.render.fps = 30
scene.render.engine = "CYCLES"
scene.cycles.samples = 8
scene.cycles.device = "CPU"


def G(p):
    return Vector((p[0], -p[2], p[1]))


def activate(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def apply(obj, modifier):
    activate(obj)
    bpy.ops.object.modifier_apply(modifier=modifier.name)


def smooth(obj):
    for polygon in obj.data.polygons:
        polygon.use_smooth = True


def ellipsoid(name, center, radii, segments=32, rings=20):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=G(center))
    obj = bpy.context.object
    obj.name = name
    obj.scale = (radii[0], radii[2], radii[1])
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    smooth(obj)
    return obj


def catmull(p0, p1, p2, p3, t):
    return 0.5 * ((2 * p1) + (-p0 + p2) * t + (2*p0 - 5*p1 + 4*p2 - p3)*t*t + (-p0 + 3*p1 - 3*p2 + p3)*t*t*t)


def loft(name, sections, sides=24, steps=4, axis="z"):
    # z, center_y, half_width, half_height; cubic sections give curved silhouettes.
    rings = []
    for i in range(len(sections)-1):
        controls = [Vector(sections[max(0, min(len(sections)-1, j))]) for j in (i-1, i, i+1, i+2)]
        for k in range(steps):
            rings.append(catmull(*controls, k / steps))
    rings.append(Vector(sections[-1]))
    verts, faces = [], []
    for longitudinal, center, width, height in rings:
        for j in range(sides):
            angle = math.tau * j / sides
            x = max(.002, width)*math.cos(angle)
            radial = max(.002, height)*math.sin(angle)
            point = (x, center+radial, longitudinal) if axis == "z" else (x, longitudinal, center+radial)
            verts.append(G(point))
    for i in range(len(rings)-1):
        for j in range(sides):
            a = i*sides+j
            b = i*sides+(j+1)%sides
            faces.append((a, b, b+sides, a+sides))
    faces.extend([tuple(reversed(range(sides))), tuple((len(rings)-1)*sides+j for j in range(sides))])
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    scene.collection.objects.link(obj)
    activate(obj)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    smooth(obj)
    return obj


def join(objects, name):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    obj = objects[0]
    obj.name = name
    return obj


def bone_weight(obj, weights_for_point):
    for vertex in obj.data.vertices:
        x, z, y = vertex.co
        weights = weights_for_point((x, y, -z))
        total = sum(weights.values())
        for name, weight in weights.items():
            if weight <= 0:
                continue
            group = obj.vertex_groups.get(name) or obj.vertex_groups.new(name=name)
            group.add([vertex.index], weight / total, "REPLACE")


def blend(a, b, t):
    t = max(0., min(1., t))
    return {a: 1-t, b: t}


# Continuous torso, powerful hips, curved neck and tapering counterbalance tail.
trunk = loft("BodySculpt", [(1.05,1.25,.22,.24),(.64,1.35,.53,.49),(.10,1.45,.56,.54),
    (-.52,1.52,.45,.43),(-.95,1.67,.31,.31),(-1.25,1.86,.28,.32),(-1.57,1.98,.29,.28)], 40)
tail = loft("TailSculpt", [(.55,1.36,.35,.32),(1.15,1.35,.29,.27),(1.85,1.27,.20,.19),
    (2.55,1.18,.115,.12),(3.12,1.14,.045,.052),(3.60,1.18,.003,.004)],32)
skull = loft("SkullSculpt", [(-1.35,2.02,.17,.21),(-1.60,2.045,.34,.265),(-1.89,2.035,.31,.24),
    (-2.17,2.015,.255,.205),(-2.48,2.01,.23,.19),(-2.59,2.01,.08,.13)],40)
body = join([trunk, tail, skull,
    ellipsoid("Hip.L",(-.34,1.32,.45),(.32,.46,.36)),
    ellipsoid("Hip.R",(.34,1.32,.45),(.32,.46,.36))], "BodySculpt")
remesh = body.modifiers.new("Continuous sculpt surface", "REMESH")
remesh.mode = "VOXEL"
remesh.voxel_size = .044
remesh.use_smooth_shade = True
apply(body, remesh)
relax = body.modifiers.new("Soften sculpt intersections", "SMOOTH")
relax.factor = 1.2
relax.iterations = 5
apply(body, relax)
body.data.calc_loop_triangles()
decimate = body.modifiers.new("Game surface budget", "DECIMATE")
decimate.ratio = min(1., 12500/max(1,len(body.data.loop_triangles)))
apply(body, decimate)
smooth(body)


def trunk_weights(p):
    x,y,z = p
    if z > .75:
        if z < 1.4: return blend("Spine", "Tail01", (z-.75)/.65)
        if z < 2.15: return blend("Tail01", "Tail02", (z-1.4)/.75)
        return blend("Tail02", "Tail03", (z-2.15)/.80)
    if z < -1.55: return {"Head":1}
    if z < -1.20: return blend("Neck", "Head", (-z-1.20)/.35)
    if z < -.65: return blend("Spine", "Neck", (-z-.65)/.55)
    return {"Spine":1}


bone_weight(body,trunk_weights)
skin_parts = [body]
jaw = loft("LowerJaw",[(-1.51,1.82,.23,.09),(-1.77,1.73,.275,.10),(-2.13,1.73,.205,.075),
    (-2.46,1.75,.18,.07),(-2.54,1.76,.07,.05)],32)
bone_weight(jaw, lambda p:{"Jaw":1})
skin_parts.append(jaw)
for side, suffix in [(-1,"L"),(1,"R")]:
    leg = loft("Leg."+suffix, [(1.50,.43,.14,.17),(1.30,.39,.25,.31),(1.03,.20,.23,.27),
        (.79,-.08,.16,.17),(.55,.055,.11,.115),(.29,.20,.085,.085),(.19,.18,.065,.06)],24,4,axis="y")
    # Legs were lofted around X=0; shift out before attaching to the pelvis.
    for v in leg.data.vertices: v.co.x += .48*side
    def leg_weights(p, s=suffix):
        return blend("Shin."+s,"Thigh."+s,(p[1]-.62)/.28)
    bone_weight(leg,leg_weights)
    skin_parts.append(leg)
    foot = ellipsoid("Foot."+suffix,(.48*side,.13,-.04),(.16,.11,.28))
    bone_weight(foot,lambda p,s=suffix:{"Foot."+s:1})
    skin_parts.append(foot)
    for digit in range(3):
        toe = ellipsoid("Toe",(.48*side+(digit-1)*.115,.09,-.30),(.061,.064,.24),24,12)
        bone_weight(toe,lambda p,s=suffix:{"Foot."+s:1})
        skin_parts.append(toe)
    arm = ellipsoid("Arm."+suffix,(.40*side,1.40,-.77),(.087,.19,.09))
    forearm = ellipsoid("Forearm."+suffix,(.42*side,1.26,-.86),(.065,.08,.15))
    for obj in (arm,forearm):
        bone_weight(obj,lambda p,s=suffix:{"Arm."+s:1})
        skin_parts.append(obj)
    # Raised brow frames the smaller, predator-like eye without a toy sphere socket.
    brow = ellipsoid("Brow",(.298*side,2.178,-1.70),(.069,.041,.115))
    bone_weight(brow,lambda p:{"Head":1})
    skin_parts.append(brow)
skin = join(skin_parts,"TRexSkin")
smooth(skin)
activate(skin)
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.uv.smart_project(angle_limit=math.radians(70),island_margin=.018)
bpy.ops.object.mode_set(mode="OBJECT")


def material(name,color,roughness):
    mat=bpy.data.materials.new(name)
    mat.use_nodes=True
    mat.diffuse_color=(*color,1)
    bsdf=mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value=(*color,1)
    bsdf.inputs["Roughness"].default_value=roughness
    return mat


# Bake actual portable image maps; Blender procedural nodes alone do not export.
mat=material("Body",(.14,.105,.065),.78)
skin.data.materials.clear()
skin.data.materials.append(mat)
nodes,links=mat.node_tree.nodes,mat.node_tree.links
bsdf=nodes.get("Principled BSDF")
position=nodes.new("ShaderNodeNewGeometry")
noise=nodes.new("ShaderNodeTexNoise")
noise.inputs["Scale"].default_value=4.2
noise.inputs["Detail"].default_value=4
links.new(position.outputs["Position"],noise.inputs["Vector"])
ramp=nodes.new("ShaderNodeValToRGB")
ramp.color_ramp.elements[0].position=.22
ramp.color_ramp.elements[0].color=(.038,.047,.033,1)
ramp.color_ramp.elements[1].position=.77
ramp.color_ramp.elements[1].color=(.245,.184,.098,1)
links.new(noise.outputs["Fac"],ramp.inputs[0])
separate=nodes.new("ShaderNodeSeparateXYZ")
links.new(position.outputs["Normal"],separate.inputs[0])
belly=nodes.new("ShaderNodeMapRange")
links.new(separate.outputs["Z"],belly.inputs["Value"])
belly.inputs["From Min"].default_value=-.18
belly.inputs["From Max"].default_value=-.85
mix=nodes.new("ShaderNodeMixRGB")
links.new(belly.outputs[0],mix.inputs[0])
links.new(ramp.outputs[0],mix.inputs[1])
mix.inputs[2].default_value=(.33,.257,.157,1)
links.new(mix.outputs[0],bsdf.inputs["Base Color"])
cells=nodes.new("ShaderNodeTexVoronoi")
cells.feature="DISTANCE_TO_EDGE"
cells.inputs["Scale"].default_value=100
links.new(position.outputs["Position"],cells.inputs["Vector"])
scale_ramp=nodes.new("ShaderNodeValToRGB")
scale_ramp.color_ramp.elements[0].position=.015
scale_ramp.color_ramp.elements[1].position=.09
links.new(cells.outputs["Distance"],scale_ramp.inputs[0])
bump=nodes.new("ShaderNodeBump")
bump.inputs["Strength"].default_value=.42
bump.inputs["Distance"].default_value=.014
links.new(scale_ramp.outputs[0],bump.inputs["Height"])
links.new(bump.outputs["Normal"],bsdf.inputs["Normal"])

maps={}
scene.render.bake.use_pass_direct=False
scene.render.bake.use_pass_indirect=False
scene.render.bake.use_pass_color=True
scene.render.bake.margin=12
for map_name,bake_type in [("base_color","DIFFUSE"),("normal","NORMAL"),("roughness","ROUGHNESS"),("ao","AO")]:
    image=bpy.data.images.new("trex_"+map_name,width=2048,height=2048,alpha=False)
    if map_name!="base_color": image.colorspace_settings.name="Non-Color"
    target=nodes.new("ShaderNodeTexImage")
    target.image=image
    nodes.active=target
    activate(skin)
    print("Baking",map_name,flush=True)
    bpy.ops.object.bake(type=bake_type)
    image.filepath_raw=str(TEXTURES/("trex_"+map_name+".png"))
    image.file_format="PNG"
    image.save()
    maps[map_name]=image
    nodes.remove(target)
# The exported material contains only standard glTF PBR nodes.
nodes.clear()
output=nodes.new("ShaderNodeOutputMaterial")
bsdf=nodes.new("ShaderNodeBsdfPrincipled")
links.new(bsdf.outputs[0],output.inputs["Surface"])
for map_name,input_name in [("base_color","Base Color"),("roughness","Roughness")]:
    tex=nodes.new("ShaderNodeTexImage")
    tex.image=maps[map_name]
    links.new(tex.outputs["Color"],bsdf.inputs[input_name])
normal_tex=nodes.new("ShaderNodeTexImage")
normal_tex.image=maps["normal"]
normal=nodes.new("ShaderNodeNormalMap")
normal.inputs["Strength"].default_value=.65
links.new(normal_tex.outputs["Color"],normal.inputs["Color"])
links.new(normal.outputs["Normal"],bsdf.inputs["Normal"])
occlusion_group=bpy.data.node_groups.new("glTF Material Output","ShaderNodeTree")
occlusion_group.interface.new_socket(name="Occlusion",in_out="INPUT",socket_type="NodeSocketFloat")
occlusion=nodes.new("ShaderNodeGroup")
occlusion.node_tree=occlusion_group
ao_tex=nodes.new("ShaderNodeTexImage")
ao_tex.image=maps["ao"]
links.new(ao_tex.outputs["Color"],occlusion.inputs["Occlusion"])

accent=material("Accent",(.095,.073,.044),.85)
eyes=material("Eyes",(.26,.125,.024),.25)
teeth=material("Teeth",(.67,.60,.43),.4)
claws=material("Claws",(.032,.024,.018),.52)
mouth=material("Mouth",(.075,.024,.022),.63)
details=[]


def detail(obj,mat,bone):
    obj.data.materials.append(mat)
    bone_weight(obj,lambda p:{bone:1})
    details.append(obj)
    return obj


def spike(name,base,tip,radius,mat,bone):
    start,end=G(base),G(tip)
    bpy.ops.mesh.primitive_cone_add(vertices=16,radius1=radius,radius2=.003,depth=(end-start).length,location=(start+end)*.5)
    obj=bpy.context.object
    obj.name=name
    obj.rotation_mode="QUATERNION"
    obj.rotation_quaternion=(end-start).to_track_quat("Z","Y")
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    smooth(obj)
    return detail(obj,mat,bone)


for side,suffix in [(-1,"L"),(1,"R")]:
    detail(ellipsoid("Eye."+suffix,(.318*side,2.13,-1.72),(.055,.05,.056),32,20),eyes,"Head")
    detail(ellipsoid("Pupil."+suffix,(.366*side,2.132,-1.733),(.009,.029,.022),24,16),claws,"Head")
    detail(ellipsoid("Nostril."+suffix,(.195*side,2.045,-2.39),(.018,.017,.033),24,12),claws,"Head")
    for i in range(9):
        z=-1.83-i*.074
        x=side*(.265-i*.010)
        spike("UpperTooth",(x,1.825,z),(x,1.73-(.012 if i<5 else 0),z-.012),.021,teeth,"Head")
        spike("LowerTooth",(x*.9,1.79,z),(x*.9,1.849,z-.012),.015,teeth,"Jaw")
    for digit in range(3):
        x=.48*side+(digit-1)*.115
        spike("Claw",(x,.092,-.47),(x,.063,-.66),.043,claws,"Foot."+suffix)
    for digit in range(2):
        x=.42*side+side*digit*.065
        spike("Finger",(x,1.27,-.94),(x,1.22,-1.085),.023,claws,"Arm."+suffix)
detail(ellipsoid("MouthCavity",(0,1.79,-2.025),(.22,.022,.42),32,16),mouth,"Head")
detail(ellipsoid("Tongue",(0,1.81,-2.015),(.14,.017,.30),32,16),mouth,"Jaw")
for i in range(10):
    # Low rounded scales along the spine, no triangular decorative plates.
    z=.0+i*.21
    y=1.98 if z<.4 else 1.87-(z-.4)*.25
    obj=ellipsoid("DorsalScale",(0,y,z),(.036,.023,.05),16,10)
    detail(obj,accent,"Spine" if z<.8 else ("Tail01" if z<1.6 else "Tail02"))
mesh=join([skin]+details,"TRexBody")
mesh.data.calc_loop_triangles()
final_budget=mesh.modifiers.new("LOD0 triangle budget","DECIMATE")
final_budget.ratio=min(1.,33000/len(mesh.data.loop_triangles))
apply(mesh,final_budget)
smooth(mesh)

# Production coordinate convention: Blender Z-up; all object transforms identity.
bpy.ops.object.armature_add(enter_editmode=True,location=(0,0,0))
rig=bpy.context.object
rig.name="TRexRig"
rig.data.edit_bones.remove(rig.data.edit_bones[0])
bone_specs={}


def bone(name,head,tail,parent=None):
    b=rig.data.edit_bones.new(name)
    b.head,b.tail=G(head),G(tail)
    # Local X is the lateral hinge axis for jaw and sagittal leg rotations.
    b.align_roll(Vector((1,0,0)))
    if parent: b.parent=rig.data.edit_bones[parent]
    bone_specs[name]=(G(head),G(tail),parent)


bone("Root",(0,0,0),(0,.35,0))
bone("Spine",(0,1.32,.40),(0,1.54,-.58),"Root")
bone("Neck",(0,1.54,-.58),(0,1.98,-1.40),"Spine")
bone("Head",(0,1.98,-1.40),(0,1.99,-2.48),"Neck")
bone("Jaw",(0,1.81,-1.49),(0,1.75,-2.48),"Head")
bone("Tail01",(0,1.35,.70),(0,1.29,1.55),"Spine")
bone("Tail02",(0,1.29,1.55),(0,1.18,2.45),"Tail01")
bone("Tail03",(0,1.18,2.45),(0,1.18,3.58),"Tail02")
for side,s in [(-1,"L"),(1,"R")]:
    bone("Thigh."+s,(.48*side,1.32,.35),(.48*side,.78,-.10),"Root")
    bone("Shin."+s,(.48*side,.78,-.10),(.48*side,.26,.20),"Thigh."+s)
    bone("Foot."+s,(.48*side,.26,.20),(.48*side,.09,-.35),"Shin."+s)
    bone("Arm."+s,(.40*side,1.49,-.70),(.42*side,1.26,-.89),"Spine")
bpy.ops.object.mode_set(mode="OBJECT")
mesh.parent=rig
mesh.matrix_parent_inverse=Matrix.Identity(4)
modifier=mesh.modifiers.new("Skeletal deformation","ARMATURE")
modifier.object=rig
rig.animation_data_create()


def rotate_world(name,axis,angle):
    b=rig.pose.bones[name]
    rest=rig.data.bones[name].matrix_local.to_quaternion()
    from mathutils import Quaternion
    local=rest.inverted() @ Quaternion(axis,angle) @ rest
    b.rotation_quaternion=local


def set_direction(name,direction):
    b=rig.pose.bones[name]
    rest=rig.data.bones[name].matrix_local.to_quaternion()
    original=bone_specs[name][1]-bone_specs[name][0]
    world_rotation=original.rotation_difference(direction) @ rest
    parent=b.parent
    if parent:
        local_rest=(parent.bone.matrix_local.inverted() @ b.bone.matrix_local).to_quaternion()
        b.rotation_quaternion=local_rest.inverted() @ parent.matrix.to_quaternion().inverted() @ world_rotation
    else:
        b.rotation_quaternion=rest.inverted() @ world_rotation
    bpy.context.view_layer.update()


def leg_pose(side,suffix,phase,stride,lift):
    # Analytical two-link IK: stance foot moves backwards linearly, swing clears
    # the ground and returns forward. Export bakes ordinary bone transforms.
    cycle=(phase/math.tau)%1
    if cycle<.60:
        z=-stride/2+stride*cycle/.60
        up=0
    else:
        t=(cycle-.60)/.40
        ease=t*t*(3-2*t)
        z=stride/2-stride*ease
        up=lift*math.sin(math.pi*t)
    hip=G((.48*side,1.32,.35))
    ankle=G((.48*side,.26+up,.10+z))
    a=(bone_specs["Thigh."+suffix][1]-hip).length
    b=(bone_specs["Shin."+suffix][1]-bone_specs["Shin."+suffix][0]).length
    delta=ankle-hip
    distance=min(delta.length,a+b-.001)
    forward=delta.normalized()
    mid=(a*a-b*b+distance*distance)/(2*distance)
    radius=math.sqrt(max(0,a*a-mid*mid))
    pole=G((0,0,-1))
    across=(pole-forward*pole.dot(forward)).normalized()
    knee=hip+forward*mid+across*radius
    set_direction("Thigh."+suffix,knee-hip)
    set_direction("Shin."+suffix,ankle-knee)
    set_direction("Foot."+suffix,bone_specs["Foot."+suffix][1]-bone_specs["Foot."+suffix][0])


clips={"Idle":90,"Walk":36,"Run":24,"Attack":24,"Eat":45,"Hit":22,"Stagger":32,"Defeat":60,"Roar":60,"PowerBite":32}
for name,end in clips.items():
    action=bpy.data.actions.new(name)
    action.use_fake_user=True
    rig.animation_data.action=action
    for frame in range(1,end+1):
        scene.frame_set(frame)
        t=(frame-1)/(end-1)
        wave=math.sin(math.tau*t)
        pulse=math.sin(math.pi*t)**2
        for b in rig.pose.bones:
            b.rotation_mode="QUATERNION"
            b.rotation_quaternion=(1,0,0,0)
            b.location=(0,0,0)
            b.scale=(1,1,1)
        if name in ("Idle","Walk","Run"):
            rotate_world("Neck",(1,0,0),wave*.018)
            rig.pose.bones["Spine"].scale=(1+wave*.009,1,1+wave*.012)
            for i,bn in enumerate(("Tail01","Tail02","Tail03")):
                rotate_world(bn,(0,0,1),math.sin(math.tau*t-i*.55)*(.035 if name=="Idle" else .075))
            if name!="Idle":
                for side,s,phase in [(-1,"L",0),(1,"R",math.pi)]:
                    leg_pose(side,s,math.tau*t+phase,.82 if name=="Walk" else 1.03,.17 if name=="Walk" else .28)
        else:
            if name in ("Attack","PowerBite"):
                strike=math.sin(math.pi*min(1,t/.72))**2
                rotate_world("Neck",(1,0,0),-.25*strike)
                rotate_world("Head",(1,0,0),-.16*strike)
                rotate_world("Jaw",(1,0,0),-.48*math.sin(math.pi*min(1,t/.55))**2)
                rotate_world("Spine",(1,0,0),-.065*strike)
            elif name=="Eat":
                rotate_world("Neck",(1,0,0),-.4*pulse)
                rotate_world("Head",(1,0,0),-.28*pulse)
                rotate_world("Jaw",(1,0,0),-.22*pulse*(.55+.45*math.sin(t*math.tau*3)))
            elif name=="Roar":
                rotate_world("Neck",(1,0,0),.24*pulse)
                rotate_world("Head",(1,0,0),.14*pulse)
                rotate_world("Jaw",(1,0,0),-.65*pulse)
            elif name in ("Hit","Stagger"):
                rotate_world("Spine",(0,1,0),.13*pulse)
                rotate_world("Neck",(0,0,1),.16*pulse)
            elif name=="Defeat":
                settle=t*t*(3-2*t)
                rotate_world("Spine",(0,1,0),1.0*settle)
                rotate_world("Neck",(1,0,0),-.25*settle)
                rig.pose.bones["Spine"].location.z=-.50*settle
        for b in rig.pose.bones:
            for channel in ("rotation_quaternion","location","scale"):
                b.keyframe_insert(channel,frame=frame,group=b.name)
    print("Authored action",name,flush=True)
rig.animation_data.action=None
for b in rig.pose.bones:
    b.rotation_quaternion=(1,0,0,0)
    b.location=(0,0,0)
    b.scale=(1,1,1)
scene.frame_set(1)
bpy.context.view_layer.update()
mesh.data.calc_loop_triangles()
triangle_count=len(mesh.data.loop_triangles)
print("TRex triangles",triangle_count,flush=True)
assert 25000 <= triangle_count <= 35000, triangle_count
assert all(abs(v-1)<1e-5 for v in mesh.scale)
assert len(mesh.vertex_groups)>10
activate(rig)
mesh.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUT/"t_rex_hero.glb"),export_format="GLB",use_selection=True,
    export_yup=True,export_animations=True,export_animation_mode="ACTIONS",export_force_sampling=True,
    export_skins=True,export_apply=False,export_materials="EXPORT",export_extras=True)
for image in maps.values(): image.pack()
scene.render.engine="CYCLES"
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/"t_rex_hero.blend"))
print("T. rex export complete",flush=True)
