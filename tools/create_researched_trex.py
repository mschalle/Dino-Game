"""Evidence-informed T. rex candidate; see docs/dinosaurs/t_rex.md.

Run in factory startup with --python-exit-code 1; see MODEL_PIPELINE.md.
All design coordinates are Godot (X right, Y up, -Z forward); G converts once
to Blender Z-up. Applied mesh transforms and an identity rig survive glTF skinning.
"""
import math
import argparse
import json
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--stage", type=int, choices=range(4), default=0)
parser.add_argument("--reuse-textures", action="store_true")
args = parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
STAGES = [(4.8,1.60,.60),(6.4,2.20,.82),(9.1,3.10,1.15),(12.3444,3.9624,1.50)]
LENGTH, HIP, SKULL = STAGES[args.stage]
MATURITY = args.stage/3.0
AXIAL = (LENGTH-SKULL)/4.95
OUT = ROOT / "assets/models/dinosaurs/researched"
TEXTURES = OUT / "trex_textures"
SOURCE = ROOT / "art_source/researched_trex"
for directory in (OUT, TEXTURES, SOURCE):
    directory.mkdir(exist_ok=True, parents=True)
# This script is only run in a factory-startup process; avoid clearing user scenes.
if bpy.data.filepath:
    raise RuntimeError("Run with --factory-startup, not inside an open art scene")
for obj in list(bpy.data.objects):
    if obj.name in ("Cube", "Camera", "Light"):
        bpy.data.objects.remove(obj, do_unlink=True)
scene = bpy.context.scene
scene.render.fps = 30
scene.render.engine = "CYCLES"
scene.cycles.samples = 8
scene.cycles.device = "CPU"


def anatomy(p):
    """Metre-space allometry; not a fitted biological growth curve."""
    x,y,z = p
    head_mix = max(0.,min(1.,(-z-1.10)/.45))
    head_mix = head_mix*head_mix*(3-2*head_mix)
    axial_z = z*AXIAL if z>=-1.35 else -1.35*AXIAL+(z+1.35)*SKULL/1.24
    body_width = .72+.20*MATURITY
    limb_width = .58+.06*MATURITY
    lateral = limb_width+(body_width-limb_width)*max(0.,min(1.,(y-.6)/.65))
    lateral = lateral*(1-head_mix)+(.57+.18*MATURITY)*head_mix
    body_y = (y-.02)*HIP/1.30 if y<=1.32 else HIP+(y-1.32)*HIP*.22
    head_y = HIP+.055*HIP+(y-2.01)*HIP*(.38+.12*MATURITY)
    return Vector((x*AXIAL*lateral,body_y*(1-head_mix)+head_y*head_mix,axial_z))


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


def loft(name, sections, sides=24, steps=4, axis="z", squareness=1.0):
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
            x = max(.002, width)*math.copysign(abs(math.cos(angle))**squareness,math.cos(angle))
            radial = max(.002, height)*math.copysign(abs(math.sin(angle))**squareness,math.sin(angle))
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
skull = loft("SkullSculpt", [(-1.35,2.02,.17,.21),(-1.60,2.045,.34,.265),(-1.82,2.035,.29,.225),
    (-2.04,2.02,.22,.19),(-2.27,2.00,.205,.175),(-2.48,1.985,.22,.15),(-2.59,1.98,.19,.13)],48,squareness=.68)
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
jaw = loft("LowerJaw",[(-1.48,1.855,.23,.10),(-1.73,1.805,.265,.105),(-2.04,1.800,.207,.085),
    (-2.30,1.810,.193,.072),(-2.50,1.825,.18,.062),(-2.57,1.835,.06,.045)],40)
bone_weight(jaw, lambda p:{"Jaw":1})
# Keep the jaw separate from the continuous body remesh for its hinge motion.
for side, suffix in [(-1,"L"),(1,"R")]:
    leg = loft("Leg."+suffix, [(1.50,.43,.14,.17),(1.30,.39,.25,.31),(1.03,.20,.23,.27),
        (.79,-.08,.16,.17),(.55,.055,.11,.115),(.29,.20,.085,.085),(.13,.15,.075,.07)],24,4,axis="y")
    # Legs were lofted around X=0; shift out before attaching to the pelvis.
    for v in leg.data.vertices: v.co.x += .48*side
    def leg_weights(p, s=suffix):
        return blend("Shin."+s,"Thigh."+s,(p[1]-.62)/.28)
    bone_weight(leg,leg_weights)
    skin_parts.append(leg)
    foot = ellipsoid("Foot."+suffix,(.48*side,.10,.035),(.125,.08,.18))
    bone_weight(foot,lambda p,s=suffix:{"Foot."+s:1})
    skin_parts.append(foot)
    for digit in range(3):
        toe = loft("Toe",[(.01,.09,.057,.054),(-.12,.078,.052,.045),(-.28,.075,.049,.045),
            (-.41,.068,.040,.037),(-.50,.060,.024,.028)],20,3)
        for v in toe.data.vertices: v.co.x+=.48*side+(digit-1)*.095
        bone_weight(toe,lambda p,s=suffix:{"Foot."+s:1})
        skin_parts.append(toe)
    arm = loft("Arm."+suffix,[(1.61,-.69,.11,.10),(1.47,-.73,.069,.068),
        (1.30,-.79,.050,.058),(1.27,-.88,.045,.070),(1.25,-.99,.029,.038)],24,4,axis="y")
    for v in arm.data.vertices: v.co.x+=.36*side
    for obj in (arm,):
        bone_weight(obj,lambda p,s=suffix:{"Arm."+s:1})
        skin_parts.append(obj)
    # Raised brow frames the smaller, predator-like eye without a toy sphere socket.
    brow = ellipsoid("Brow",(.298*side,2.178,-1.70),(.069,.041,.115))
    bone_weight(brow,lambda p:{"Head":1})
    skin_parts.append(brow)
skin = join(skin_parts,"TRexSkin")
# Fuse the shoulders, thighs and metatarsals into the organic skin surface.
# Jaw/eyes/teeth remain independent to preserve articulation and clean materials.
unify=skin.modifiers.new("Continuous anatomical skin","REMESH")
unify.mode="VOXEL"
unify.voxel_size=.021
unify.use_smooth_shade=True
apply(skin,unify)
relax=skin.modifiers.new("Joint transitions","SMOOTH")
relax.factor=.7
relax.iterations=3
apply(skin,relax)
skin.data.calc_loop_triangles()
budget=skin.modifiers.new("Continuous skin budget","DECIMATE")
budget.ratio=min(1.,28000/len(skin.data.loop_triangles))
apply(skin,budget)
skin.vertex_groups.clear()

def anatomical_weights(p):
    x,y,z=p
    side="R" if x>0 else "L"
    if y<1.35 and z>-.72 and z<.9 and abs(x)>.23:
        if y<.29: return {"Foot."+side:1}
        if y<.48: return blend("Foot."+side,"Shin."+side,(y-.29)/.19)
        if y<.85: return blend("Shin."+side,"Thigh."+side,(y-.60)/.25)
        if y<1.12: return {"Thigh."+side:1}
        return blend("Thigh."+side,"Spine",(y-1.12)/.23)
    if -.99<z<-.62 and y<1.51 and abs(x)>.27:
        return {"Arm."+side:1}
    return trunk_weights(p)

bone_weight(skin,anatomical_weights)
skin=join([skin,jaw],"TRexSkin")
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
ramp.color_ramp.elements[0].color=(.018,.026,.020,1)
ramp.color_ramp.elements[1].position=.77
ramp.color_ramp.elements[1].color=(.095,.105,.058,1)
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
mix.inputs[2].default_value=(.19,.16,.10,1)
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
bump.inputs["Strength"].default_value=.23
bump.inputs["Distance"].default_value=.004
links.new(scale_ramp.outputs[0],bump.inputs["Height"])
links.new(bump.outputs["Normal"],bsdf.inputs["Normal"])

maps={}
scene.render.bake.use_pass_direct=False
scene.render.bake.use_pass_indirect=False
scene.render.bake.use_pass_color=True
scene.render.bake.margin=12
for map_name,bake_type in [("base_color","DIFFUSE"),("normal","NORMAL"),("roughness","ROUGHNESS"),("ao","AO")]:
    if args.reuse_textures:
        image=bpy.data.images.load(str(TEXTURES/("trex_"+map_name+".png")),check_existing=True)
        if map_name!="base_color": image.colorspace_settings.name="Non-Color"
        maps[map_name]=image
        continue
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
        x=side*(.175-i*.007)
        spike("UpperTooth",(x,1.85,z),(x,1.77-(.012 if i<5 else 0),z-.012),.020,teeth,"Head")
        spike("LowerTooth",(x*.9,1.78,z),(x*.9,1.827,z-.012),.014,teeth,"Jaw")
    for digit in range(3):
        x=.48*side+(digit-1)*.095
        spike("Claw",(x,.092,-.47),(x,.063,-.66),.043,claws,"Foot."+suffix)
    for digit in range(2):
        x=.36*side+side*digit*.040
        spike("Finger",(x,1.25,-.98),(x,1.21,-1.09),.016,claws,"Arm."+suffix)
detail(ellipsoid("MouthCavity",(0,1.79,-2.025),(.22,.022,.42),32,16),mouth,"Head")
detail(ellipsoid("Tongue",(0,1.81,-2.015),(.14,.017,.30),32,16),mouth,"Jaw")
# Thin lip margins conceal the inward tooth rows at neutral rest.
for side in (-1,1):
    lip=loft("LabialMargin",[(-1.65,1.817,.26,.023),(-1.94,1.815,.24,.021),
        (-2.22,1.813,.21,.019),(-2.48,1.82,.22,.022)],40)
    # A flattened oval edge follows the full mouth perimeter; only add once.
    detail(lip,accent,"Head")
    break
mesh=join([skin]+details,"TRexBody")
mesh.data.calc_loop_triangles()
final_budget=mesh.modifiers.new("LOD0 triangle budget","DECIMATE")
final_budget.ratio=min(1.,33000/len(mesh.data.loop_triangles))
apply(mesh,final_budget)
smooth(mesh)

# UVs and topology are shared among stages; allometry changes the anatomy,
# and the rig receives the same mapping so skinning remains consistent.
for vertex in mesh.data.vertices:
    vertex.co=G(anatomy((vertex.co.x,vertex.co.z,-vertex.co.y)))
ground_offset=min(v.co.z for v in mesh.data.vertices)
for vertex in mesh.data.vertices:
    vertex.co.z-=ground_offset
length_correction=LENGTH/(max(v.co.y for v in mesh.data.vertices)-min(v.co.y for v in mesh.data.vertices))
for vertex in mesh.data.vertices:
    vertex.co.y*=length_correction

def anatomical_point(p):
    result=G(anatomy(p))
    result.z-=ground_offset
    result.y*=length_correction
    return result

# Production coordinate convention: Blender Z-up; all object transforms identity.
bpy.ops.object.armature_add(enter_editmode=True,location=(0,0,0))
rig=bpy.context.object
rig.name="TRexRig"
rig.data.edit_bones.remove(rig.data.edit_bones[0])
bone_specs={}


def bone(name,head,tail,parent=None):
    b=rig.data.edit_bones.new(name)
    b.head,b.tail=anatomical_point(head),anatomical_point(tail)
    # Local X is the lateral hinge axis for jaw and sagittal leg rotations.
    b.align_roll(Vector((1,0,0)))
    if parent: b.parent=rig.data.edit_bones[parent]
    bone_specs[name]=(anatomical_point(head),anatomical_point(tail),parent)


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
        # Hermite endpoints match the preceding/following stance velocity.
        z=stride/2-stride*ease+(t**3-2*t*t+t+t**3-t*t)*stride*.40/.60
        up=lift*math.sin(math.pi*t)**2
    hip=anatomical_point((.48*side,1.32,.35))
    ankle=anatomical_point((.48*side,.26+up,.20+z))
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


clips={"Idle":91,"Walk":37,"Run":25,"Attack":25,"Eat":46,"Hit":23,"Stagger":33,"Defeat":61,"Roar":61,"PowerBite":37,"TurnLeft":31,"TurnRight":31}
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
                    leg_pose(side,s,math.tau*t+phase,.70 if name=="Walk" else .90,.13 if name=="Walk" else .23)
        else:
            if name in ("Attack","PowerBite"):
                strike=math.sin(math.pi*min(1,t/(.82 if name=="PowerBite" else .62)))**2
                rotate_world("Neck",(1,0,0),(-.36 if name=="PowerBite" else -.20)*strike)
                rotate_world("Head",(1,0,0),-.16*strike)
                rotate_world("Jaw",(1,0,0),-.48*math.sin(math.pi*min(1,t/.55))**2)
                rotate_world("Spine",(1,0,0),(-.10 if name=="PowerBite" else -.045)*strike)
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
            elif name in ("TurnLeft","TurnRight"):
                sign=1 if name=="TurnLeft" else -1
                rotate_world("Spine",(0,0,1),sign*.065*pulse)
                rotate_world("Neck",(0,0,1),sign*.12*pulse)
                for i,bn in enumerate(("Tail01","Tail02","Tail03")):
                    rotate_world(bn,(0,0,1),-sign*(.08+i*.025)*pulse)
            elif name=="Defeat":
                settle=t*t*(3-2*t)
                rotate_world("Spine",(0,1,0),1.0*settle)
                rotate_world("Neck",(1,0,0),-.25*settle)
                rig.pose.bones["Spine"].location.z=-.50*AXIAL*settle
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
rig["research_version"]=1
rig["growth_stage"]=args.stage
rig["length_target_m"]=LENGTH
rig["hip_target_m"]=HIP
rig["walk_stride_speed_mps"] = .70*AXIAL*length_correction/(.60*1.2)
rig["run_stride_speed_mps"] = .90*AXIAL*length_correction/(.60*.8)
bpy.ops.export_scene.gltf(filepath=str(OUT/("t_rex_stage_%d.glb" % args.stage)),export_format="GLB",use_selection=True,
    export_yup=True,export_animations=True,export_animation_mode="ACTIONS",export_force_sampling=True,
    export_skins=True,export_apply=False,export_materials="EXPORT",export_extras=True)
for image in maps.values(): image.pack()
scene.render.engine="CYCLES"
report={"stage":args.stage,"triangles":triangle_count,"length_m":max(v.co.y for v in mesh.data.vertices)-min(v.co.y for v in mesh.data.vertices),
    "hip_m":bone_specs["Thigh.L"][0].z,"height_m":max(v.co.z for v in mesh.data.vertices),"ground_m":min(v.co.z for v in mesh.data.vertices),
    "clips":clips,"walk_speed_mps":rig["walk_stride_speed_mps"],"run_speed_mps":rig["run_stride_speed_mps"]}
(SOURCE/("stage_%d_measurements.json" % args.stage)).write_text(json.dumps(report,indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/("t_rex_stage_%d.blend" % args.stage)))
print(json.dumps(report),flush=True)
print("T. rex export complete",flush=True)
