extends PlayerDino

# Opt-in research candidate: real metre scale, never generic height normalization.
# Keep the existing production model path available until art acceptance.
const DIMENSIONS: Array[Vector2] = [Vector2(4.8,1.60),Vector2(6.4,2.20),Vector2(9.1,3.10),Vector2(12.3444,3.9624)]
var model_stage := 0
var candidate_loaded := false
var motion_profile: Dictionary = {}
var reversing := false

func _imported_model_paths() -> Array[String]:
	var candidates: Array[String] = ["res://assets/models/dinosaurs/researched/t_rex_stage_%d.glb" % model_stage]
	candidates.append_array(super._imported_model_paths())
	return candidates

func _normalize_imported_model() -> void:
	candidate_loaded = imported_model.scene_file_path.begins_with("res://assets/models/dinosaurs/researched/")
	if not candidate_loaded:
		super._normalize_imported_model()
	else:
		var source := _metadata_node(imported_model)
		motion_profile = source.get_meta("extras",{}) if source != null else {}

func _ready() -> void:
	super._ready()
	_fit_candidate_collision()

func grow_to(new_scale: float) -> void:
	# The unchanged session supplies these four legacy stage values.
	var values := [1.0,1.2,1.45,1.75]
	var next_stage := values.find(new_scale)
	if next_stage < 0 or not candidate_loaded:
		super.grow_to(new_scale)
		return
	model_stage = next_stage
	if imported_model != null:
		imported_model.free()
		imported_model = null
	imported_animation_player = null
	imported_native_animations = false
	imported_action_timer = 0.0
	if not _try_imported_model():
		candidate_loaded = false
		_create_visuals()
	if candidate_loaded:
		scale = Vector3.ONE
		growth_scale = DIMENSIONS[model_stage].x/DIMENSIONS[0].x
		_fit_candidate_collision()
	else:
		var collider := get_node("BodyCollision") as CollisionShape3D
		var capsule := collider.shape as CapsuleShape3D
		capsule.radius = 0.4
		capsule.height = 1.6
		collider.position.y = 0.8
		super.grow_to(new_scale)

func _fit_candidate_collision() -> void:
	if not candidate_loaded:
		return
	var collider := get_node("BodyCollision") as CollisionShape3D
	var capsule := collider.shape as CapsuleShape3D
	var hip := DIMENSIONS[model_stage].y
	capsule.radius = hip*0.17
	capsule.height = hip+0.25
	collider.position.y = capsule.height*0.5

func candidate_camera_height() -> float:
	return DIMENSIONS[model_stage].y*0.85 if candidate_loaded else 0.8+growth_scale*.22

func candidate_camera_distance() -> float:
	return DIMENSIONS[model_stage].x*1.05+3.0 if candidate_loaded else Vector2(4.4+growth_scale*.5,8.4+growth_scale*1.1).length()

func _animate_visuals(delta: float, speed_ratio: float) -> void:
	if not candidate_loaded:
		super._animate_visuals(delta,speed_ratio)
		return
	imported_action_timer = maxf(0.0,imported_action_timer-delta)
	if imported_animation_player == null or imported_action_timer>0.0:
		return
	if motion_profile.is_empty():
		return
	var speed := speed_ratio*move_speed
	var walk_speed := float(motion_profile.get("walk_stride_speed_mps",1.0))
	var clip := "Idle" if speed<.06 else ("Run" if speed>walk_speed*1.55 else "Walk")
	var reverse := mouse_steering and velocity.dot(facing)<-0.05
	if imported_animation_player.current_animation!=clip:
		imported_animation_player.play(clip,.22,1.0,reverse and clip!="Idle")
	if clip=="Idle":
		imported_animation_player.speed_scale = 1.0
		reversing = false
		return
	var stride_speed := float(motion_profile.get("walk_stride_speed_mps" if clip=="Walk" else "run_stride_speed_mps",1.0))
	if reverse and (not reversing or imported_animation_player.current_animation_position<=0.0):
		imported_animation_player.seek(imported_animation_player.get_animation(clip).length,true)
	imported_animation_player.speed_scale = ( -1.0 if reverse else 1.0 )*maxf(0.05,speed_ratio*move_speed/maxf(stride_speed,.01))
	reversing = reverse

func _metadata_node(node: Node) -> Node:
	if node.get_meta("extras",{}).has("research_version"):
		return node
	for child in node.get_children():
		var found := _metadata_node(child)
		if found != null:
			return found
	return null
