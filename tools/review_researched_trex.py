"""Render and measure an authored candidate in an isolated Blender process."""
import argparse
import json
import math
import sys
from pathlib import Path
import bpy
from mathutils import Vector

parser=argparse.ArgumentParser()
parser.add_argument("--stage",type=int,default=0)
parser.add_argument("--video",action="store_true")
args=parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
root=Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(root/"art_source/researched_trex"/("t_rex_stage_%d.blend"%args.stage)))
scene=bpy.context.scene
rig=bpy.data.objects["TRexRig"]
mesh=bpy.data.objects["TRexBody"]
height=max(v.co.z for v in mesh.data.vertices)
length=max(v.co.y for v in mesh.data.vertices)-min(v.co.y for v in mesh.data.vertices)
failures=[]
report={"stage":args.stage,"clips":{},"failures":failures}

def sample(action,frame):
    rig.animation_data.action=action
    scene.frame_set(frame)
    bpy.context.view_layer.update()
    return {b.name:b.matrix.copy() for b in rig.pose.bones}

for name in ("Idle","Walk","Run"):
    action=bpy.data.actions[name]
    first,last=map(int,action.frame_range)
    a,b=sample(action,first),sample(action,last)
    discontinuity=max(abs(a[n][r][c]-b[n][r][c]) for n in a for r in range(4) for c in range(4))
    record={"loop_matrix_error":discontinuity}
    if discontinuity>.001: failures.append(name+" loop discontinuity")
    if name!="Idle":
        speed=rig["walk_stride_speed_mps" if name=="Walk" else "run_stride_speed_mps"]
        for side,offset in (("L",0.),("R",.5)):
            segments=[[]]
            for frame in range(first,last+1):
                phase=((frame-first)/(last-first)+offset)%1.
                if .05<phase<.55:
                    bones=sample(action,frame)
                    segments[-1].append((frame,bones["Foot."+side].translation.copy()))
                elif segments[-1]:
                    segments.append([])
            usable=[positions for positions in segments if len(positions)>1]
            if usable:
                drift=max(abs((p.y-positions[0][1].y)+speed*(f-positions[0][0])/30) for positions in usable for f,p in positions)
                vertical=max(abs(p.z-positions[0][1].z) for positions in usable for _,p in positions)
                record[side+"_stance_drift_m"]=drift
                record[side+"_stance_vertical_m"]=vertical
                if drift>.04 or vertical>.03: failures.append(name+" "+side+" planted-foot drift")
    report["clips"][name]=record

# Inspect skinning across all action frames, not just named tracks.
max_extent=0.
for name in ("Walk","Run","Attack","PowerBite","Eat","Hit","Defeat","Roar","TurnLeft","TurnRight"):
    action=bpy.data.actions[name]
    start,end=map(int,action.frame_range)
    for f in range(start,end+1,3):
        sample(action,f)
        evaluated=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get())
        bounds=[Vector(p) for p in evaluated.bound_box]
        extent=(max(p.y for p in bounds)-min(p.y for p in bounds))
        max_extent=max(max_extent,extent)
        if extent>length*1.5: failures.append(name+" excessive deformed extent")
report["max_posed_length_m"]=max_extent

scene.render.engine="CYCLES"
scene.cycles.samples=16
scene.cycles.device="CPU"
scene.render.resolution_x=1100
scene.render.resolution_y=700
scene.render.resolution_percentage=100
scene.world.color=(.2,.2,.2)
bpy.ops.mesh.primitive_plane_add(size=200)
floor=bpy.context.object
floor.name="ReviewFloor"
mat=bpy.data.materials.new("ReviewFloorMaterial")
mat.diffuse_color=(.16,.18,.17,1)
floor.data.materials.append(mat)
for pos,power,size in [((3,-4,7),600,5),((-4,1,4),300,4),((1,5,6),700,3)]:
    bpy.ops.object.light_add(type="AREA",location=Vector(pos)*height/2.5)
    light=bpy.context.object
    light.data.energy=power*(height/2.5)**2
    light.data.shape="DISK"
    light.data.size=size*height/2.5
    light.rotation_euler=(Vector((0,0,height*.5))-light.location).to_track_quat("-Z","Y").to_euler()
bpy.ops.object.camera_add()
camera=bpy.context.object
scene.camera=camera
camera.data.type="ORTHO"
camera.data.ortho_scale=length*1.18
target=Vector((0,-length*.1,height*.50))
for label,direction in [("side",Vector((1,0,.12))),("front",Vector((.35,1,.12))),("threequarter",Vector((1,1,.35)))]:
    sample(bpy.data.actions["Idle"],1)
    camera.location=target+direction.normalized()*length*2
    camera.rotation_euler=(target-camera.location).to_track_quat("-Z","Y").to_euler()
    scene.render.filepath=str(root/".validation"/("research_trex_%d_%s.png"%(args.stage,label)))
    bpy.ops.render.render(write_still=True)
report_path=root/".validation"/("research_trex_%d_motion.json"%args.stage)
report_path.write_text(json.dumps(report,indent=2))
print(json.dumps(report),flush=True)
if failures: raise RuntimeError("Candidate motion gate failed: "+str(failures))

if args.video:
    # Two actual walking cycles. Root and tracking camera travel together so
    # stance contact can be reviewed against stationary metre marks.
    rig.animation_data.action=None
    track=rig.animation_data.nla_tracks.new()
    strip=track.strips.new("WalkReview",1,bpy.data.actions["Walk"])
    strip.repeat=2.0
    speed=rig["walk_stride_speed_mps"]
    rig.driver_add("location",1).driver.expression="(frame-1)*%.9f/30"%speed
    camera.location=target+Vector((1,.35,.12)).normalized()*length*2
    camera.rotation_euler=(target-camera.location).to_track_quat("-Z","Y").to_euler()
    camera.driver_add("location",1).driver.expression="%.9f+(frame-1)*%.9f/30"%(camera.location.y,speed)
    for marker in range(-16,25):
        bpy.ops.mesh.primitive_cube_add(size=1,location=(0,marker,-.008))
        line=bpy.context.object
        line.scale=(5,.015,.01)
        line.data.materials.append(mat)
    scene.render.resolution_x=960
    scene.render.resolution_y=540
    scene.cycles.samples=4
    scene.frame_start=1
    scene.frame_end=73
    scene.render.image_settings.media_type="VIDEO"
    scene.render.image_settings.file_format="FFMPEG"
    scene.render.ffmpeg.format="MPEG4"
    scene.render.ffmpeg.codec="H264"
    scene.render.filepath=str(root/".validation"/("research_trex_%d_walk.mp4"%args.stage))
    bpy.ops.render.render(animation=True)
