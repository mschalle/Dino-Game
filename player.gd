class_name PlayerDino
extends CharacterBody3D

signal energy_changed(value: float)

var profile: DinosaurProfile
var move_speed := 6.0
var sprint_speed := 9.0
var energy := 100.0
var max_energy := 100.0
var strength := 1
var growth_scale := 1.0
var facing := Vector3.FORWARD
var mouse_steering := false

var dash_cooldown := 0.0
var dash_timer := 0.0
var acceleration := 28.0
var deceleration := 36.0
var turn_acceleration := 38.0

var body_mesh: MeshInstance3D
var head_mesh: MeshInstance3D
var tail_mesh: MeshInstance3D
var leg_meshes: Array[MeshInstance3D] = []
var visual_time := 0.0
var body_rest_y := 0.0
var head_rest_y := 0.0
var tail_rest_rotation := Vector3.ZERO
var gravity := 24.0
var imported_model: Node3D
var imported_model_rest_y := 0.0
var imported_animation_player: AnimationPlayer
var imported_native_animations := false
var imported_action_timer := 0.0

func turn_with_mouse(amount: float) -> void:
	mouse_steering = true
	rotation.y = wrapf(rotation.y-amount,-PI,PI)
	facing = Vector3.FORWARD.rotated(Vector3.UP,rotation.y)

func configure(new_profile: DinosaurProfile) -> void:
	profile = new_profile
	move_speed = profile.move_speed
	sprint_speed = profile.sprint_speed
	strength = profile.base_strength
	max_energy = profile.max_energy
	energy = max_energy

func _ready() -> void:
	collision_mask |= 2 # Substantial jungle trunks; ground remains layer one.
	name = profile.display_name if profile != null else "Young T. rex"
	var collider := CollisionShape3D.new()
	collider.name = "BodyCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.6
	collider.shape = capsule
	collider.position.y = 0.8
	add_child(collider)
	floor_snap_length = 0.6
	floor_max_angle = deg_to_rad(35.0)
	_create_visuals()

func _physics_process(delta: float) -> void:
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	dash_timer = maxf(0.0, dash_timer - delta)
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input_vector.x, 0.0, input_vector.y)
	if mouse_steering:
		direction = direction.rotated(Vector3.UP,rotation.y)
	var world := get_tree().get_first_node_in_group("world_controller")
	var floor_y := global_position.y
	if world != null and world.has_method("_terrain_height_at"):
		floor_y = world._terrain_height_at(global_position.x, global_position.z)
	velocity.y = 0.0 if is_on_floor() else velocity.y - gravity * delta
	if dash_timer > 0.0:
		direction = facing
	var sprinting := Input.is_action_pressed("sprint") and energy > 0.0 and direction.length() > 0.0
	var speed := 18.0 if dash_timer > 0.0 else (sprint_speed if sprinting else move_speed)
	if sprinting:
		energy = maxf(0.0, energy - 26.0 * delta)
	else:
		energy = minf(max_energy, energy + 16.0 * delta)
	energy_changed.emit(energy)
	var current_horizontal := Vector2(velocity.x, velocity.z)
	var desired_horizontal := Vector2(direction.x, direction.z) * speed
	var response := deceleration
	if direction.length() > 0.0:
		response = turn_acceleration if current_horizontal.length() > 0.1 and current_horizontal.normalized().dot(desired_horizontal.normalized()) < 0.45 else acceleration
	current_horizontal = current_horizontal.move_toward(desired_horizontal, response * delta)
	velocity.x = current_horizontal.x
	velocity.z = current_horizontal.y
	if direction.length() > 0.0 and not mouse_steering:
		facing = direction.normalized()
		rotation.y = lerp_angle(rotation.y, atan2(-facing.x, -facing.z), minf(1.0, 7.0 * delta))
	move_and_slide()
	if global_position.y < floor_y - 3.0:
		global_position.y = floor_y + 0.05
		velocity.y = 0.0
	_animate_visuals(delta, Vector2(velocity.x, velocity.z).length() / maxf(move_speed, 0.01))

func try_dash(unlocked: bool) -> bool:
	if profile == null or not unlocked or dash_cooldown > 0.0 or energy < 20.0:
		return false
	dash_cooldown = 2.0
	dash_timer = 0.22
	energy -= 20.0
	return true

func grow_to(new_scale: float) -> void:
	growth_scale = new_scale
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE * growth_scale, 0.35).set_trans(Tween.TRANS_BACK)

func celebrate_bite() -> void:
	if imported_animation_player != null:
		_play_imported_action("Eat")
	if imported_model != null and not imported_native_animations:
		var eat_tween := create_tween()
		eat_tween.tween_property(imported_model, "rotation:x", -0.16, 0.10)
		eat_tween.tween_property(imported_model, "rotation:x", 0.0, 0.18)
	if head_mesh != null:
		var tween := create_tween()
		tween.tween_property(head_mesh, "position:z", -0.52, 0.08)
		tween.tween_property(head_mesh, "position:z", -0.33, 0.12)

func play_combat_animation(power_bite: bool) -> void:
	if imported_animation_player != null:
		_play_imported_action("PowerBite" if power_bite and imported_animation_player.has_animation("PowerBite") else "Attack")
	if imported_model != null and not imported_native_animations:
		var imported_tween := create_tween()
		imported_tween.tween_property(imported_model, "rotation:x", -0.24 if power_bite else -0.14, 0.08)
		imported_tween.tween_property(imported_model, "rotation:x", 0.0, 0.16)
		return
	var target_mesh := head_mesh
	if target_mesh == null:
		target_mesh = body_mesh
	if target_mesh != null:
		var original_scale := target_mesh.scale
		var tween := create_tween()
		tween.tween_property(target_mesh, "scale", original_scale * (1.12 if power_bite else 1.06), 0.08)
		tween.tween_property(target_mesh, "scale", original_scale, 0.14)

func _create_visuals() -> void:
	if _try_imported_model():
		return
	if profile != null and profile.id == "velociraptor":
		_create_raptor_visuals()
		return
	if profile != null and profile.id == "triceratops":
		_create_triceratops_visuals()
		return
	var green := _material(profile.body_color if profile != null else Color("#66bc5a"))
	var cream := _material(Color("#f7d27c"))
	body_mesh = MeshInstance3D.new()
	var body := CapsuleMesh.new()
	body.radius = 0.55
	body.height = 2.2
	body_mesh.mesh = body
	body_mesh.material_override = green
	body_mesh.rotation_degrees.z = 90.0
	body_mesh.position.y = 0.95
	add_child(body_mesh)

	head_mesh = MeshInstance3D.new()
	var head := BoxMesh.new()
	head.size = Vector3(0.9, 0.65, 1.05)
	head_mesh.mesh = head
	head_mesh.material_override = green
	head_mesh.position = Vector3(0.0, 1.28, -0.33)
	add_child(head_mesh)
	for x in [-0.23, 0.23]:
		var eye := MeshInstance3D.new()
		var eye_sphere := SphereMesh.new()
		eye_sphere.radius = 0.09
		eye_sphere.height = 0.18
		eye.mesh = eye_sphere
		eye.material_override = _material(Color("#2e3a36"))
		eye.position = Vector3(x, 1.43, -0.82)
		add_child(eye)

	tail_mesh = MeshInstance3D.new()
	var tail := CylinderMesh.new()
	tail.top_radius = 0.07
	tail.bottom_radius = 0.36
	tail.height = 2.2
	tail_mesh.mesh = tail
	tail_mesh.material_override = green
	tail_mesh.rotation_degrees.x = 90.0
	tail_mesh.position = Vector3(0.0, 0.9, 1.4)
	add_child(tail_mesh)
	for x in [-0.34, 0.34]:
		_add_leg(Vector3(x, 0.4, 0.38), cream, 0.16, 0.8)
	for x in [-0.34, 0.34]:
		_add_leg(Vector3(x, 0.4, -0.18), green, 0.13, 0.62)
	_finish_visual_setup()

func _imported_model_paths() -> Array[String]:
	if profile == null:
		return []
	var model_paths: Array[String] = []
	if profile.id == "t_rex":
		model_paths.append("res://assets/models/dinosaurs/t_rex_hero.glb")
		model_paths.append("res://assets/models/dinosaurs/t_rex.glb")
	elif profile.id == "velociraptor":
		model_paths.append("res://assets/models/dinosaurs/local_downloads/pbr_velociraptor_animated.glb")
		model_paths.append("res://assets/models/dinosaurs/velociraptor.glb")
	elif profile.id == "triceratops":
		model_paths.append("res://assets/models/dinosaurs/triceratops.glb")
	model_paths.append("res://assets/models/dinosaurs/%s.glb" % profile.id)
	return model_paths

func _try_imported_model() -> bool:
	for model_path in _imported_model_paths():
		if not ResourceLoader.exists(model_path):
			continue
		var model_scene := load(model_path) as PackedScene
		if model_scene == null:
			continue
		imported_model = model_scene.instantiate() as Node3D
		if imported_model == null:
			continue
		add_child(imported_model)
		imported_model.name = "ImportedDinosaurModel"
		if _visual_bounds(imported_model).size == Vector3.ZERO:
			imported_model.free()
			imported_model = null
			continue
		_normalize_imported_model()
		imported_model_rest_y = imported_model.position.y
		if not _try_native_imported_animation_player():
			_create_imported_animation_library()
		return true
	return false

func _normalize_imported_model() -> void:
	if imported_model.scene_file_path.ends_with("/pbr_velociraptor_animated.glb"):
		# Supplied rig faces +Z; the controller moves forward along -Z.
		imported_model.rotation.y += PI
	var bounds := _visual_bounds(imported_model)
	if bounds.size == Vector3.ZERO:
		return
	var target_height := 2.05 if profile != null and profile.id == "t_rex" else 1.6
	var scale_factor := target_height / maxf(bounds.size.y, 0.01)
	imported_model.scale *= scale_factor
	bounds = _visual_bounds(imported_model)
	# Bounds are in world space. Convert the desired ground-center point back into
	# the player's local space before offsetting the imported model. Subtracting
	# world coordinates here moved models away from players spawned off the origin.
	var parent_node := imported_model.get_parent() as Node3D
	if parent_node == null:
		return
	var ground_center_world := Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	var ground_center_local := parent_node.to_local(ground_center_world)
	imported_model.position -= ground_center_local
	if imported_model.scene_file_path.ends_with("/pbr_velociraptor_animated.glb"):
		# This converted rig's bind AABB understates its skinned Idle height.
		# Rendered skeleton measurement: 6.52425 m after generic normalization.
		# Fit the visible pose to the existing 1.6 m gameplay convention instead.
		var skin_fit := 1.6 / 6.52425
		imported_model.scale *= skin_fit
		imported_model.position *= skin_fit
		_prepare_raptor_materials(imported_model)

func _prepare_raptor_materials(node: Node) -> void:
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			var source := node.get_active_material(surface) as StandardMaterial3D
			if source != null:
				var material := source.duplicate() as StandardMaterial3D
				# Skin is dielectric; the download's metal response made it black
				# under the game's Compatibility lighting without reflection probes.
				material.metallic = 0.0
				material.metallic_texture = null
				material.roughness = maxf(material.roughness, 0.65)
				node.set_surface_override_material(surface, material)
	for child in node.get_children():
		_prepare_raptor_materials(child)

func _visual_bounds(node: Node) -> AABB:
	var has_bounds := false
	var bounds := AABB()
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			bounds = mesh_instance.global_transform * mesh_instance.get_aabb()
			has_bounds = true
	for child in node.get_children():
		var child_bounds := _visual_bounds(child)
		if child_bounds.size == Vector3.ZERO:
			continue
		if has_bounds:
			bounds = bounds.merge(child_bounds)
		else:
			bounds = child_bounds
			has_bounds = true
	if not has_bounds:
		return AABB()
	return bounds

func _try_native_imported_animation_player() -> bool:
	var native_player := _find_animation_player(imported_model)
	if native_player == null:
		return false
	if profile.id == "velociraptor" and imported_model.scene_file_path.ends_with("/pbr_velociraptor_animated.glb"):
		var aliases := {"Idle": "Raptor_Idle1_Anim", "Walk": "Raptor_Walk_Anim", "Run": "Raptor_Run1_Anim", "Attack": "Raptor_Bite1_Anim", "Eat": "Raptor_EatPrey_Ani", "Hit": "Raptor_Hit1_Anim", "Defeat": "Raptor_Death1_Anim", "Roar": "Raptor_Roar1_Anim"}
		var library := AnimationLibrary.new()
		for alias: String in aliases:
			for source_name in native_player.get_animation_list():
				if aliases[alias] in source_name:
					library.add_animation(alias, native_player.get_animation(source_name).duplicate())
					break
		# Preserve the source library and its skeletal tracks under their original names.
		if native_player.has_animation_library(""):
			var source_library := native_player.get_animation_library("")
			native_player.remove_animation_library("")
			native_player.add_animation_library("source", source_library)
		native_player.add_animation_library("", library)
	# The baseline rig supplies Attack and Roar; reuse its skeletal bite for
	# Power Bite rather than replacing every native clip with root motion.
	if profile.id == "t_rex" and not native_player.has_animation("PowerBite") and native_player.has_animation("Attack"):
		var library := native_player.get_animation_library("")
		if library != null:
			library.add_animation("PowerBite", native_player.get_animation("Attack").duplicate())
	for animation_name in _required_animation_names():
		if not native_player.has_animation(animation_name):
			return false
	imported_animation_player = native_player
	imported_native_animations = true
	for animation_name in _required_animation_names():
		var clip := imported_animation_player.get_animation(animation_name)
		clip.loop_mode = Animation.LOOP_LINEAR if animation_name in ["Idle", "Walk", "Run"] else Animation.LOOP_NONE
	imported_animation_player.playback_default_blend_time = 0.16
	imported_animation_player.play("Idle")
	return true

func _play_imported_action(animation_name: String) -> void:
	imported_animation_player.speed_scale = 1.0
	imported_animation_player.play(animation_name, 0.12)
	imported_action_timer = imported_animation_player.get_animation(animation_name).length

func play_reaction(animation_name: String) -> void:
	if imported_animation_player != null and imported_animation_player.has_animation(animation_name):
		_play_imported_action(animation_name)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _required_animation_names() -> Array[String]:
	var names: Array[String] = ["Idle", "Walk", "Run", "Attack", "Eat", "Hit", "Defeat"]
	if profile != null and profile.id == "t_rex":
		names.append("Roar")
		names.append("PowerBite")
	return names

func _create_imported_animation_library() -> void:
	imported_native_animations = false
	imported_animation_player = AnimationPlayer.new()
	imported_animation_player.name = "AnimationPlayer"
	var library := AnimationLibrary.new()
	for animation_name in _required_animation_names():
		var animation := Animation.new()
		animation.length = 0.8 if animation_name != "Idle" else 2.0
		animation.loop_mode = Animation.LOOP_LINEAR if animation_name in ["Idle", "Walk", "Run"] else Animation.LOOP_NONE
		var position_track := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(position_track, NodePath("ImportedDinosaurModel:position"))
		animation.track_insert_key(position_track, 0.0, imported_model.position)
		animation.track_insert_key(position_track, animation.length * 0.5, imported_model.position + Vector3(0.0, 0.06 if animation_name in ["Idle", "Walk", "Run"] else 0.0, 0.0))
		animation.track_insert_key(position_track, animation.length, imported_model.position)
		var rotation_track := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(rotation_track, NodePath("ImportedDinosaurModel:rotation"))
		var action_rotation := Vector3.ZERO
		if animation_name == "Attack":
			action_rotation.x = -0.24
		elif animation_name == "Eat":
			action_rotation.x = -0.16
		elif animation_name == "Hit":
			action_rotation.z = 0.18
		elif animation_name == "Defeat":
			action_rotation.z = 0.8
		animation.track_insert_key(rotation_track, 0.0, Vector3.ZERO)
		animation.track_insert_key(rotation_track, animation.length * 0.45, action_rotation)
		animation.track_insert_key(rotation_track, animation.length, Vector3.ZERO)
		library.add_animation(animation_name, animation)
	imported_animation_player.add_animation_library("", library)
	add_child(imported_animation_player)
	imported_animation_player.play("Idle")

func _create_raptor_visuals() -> void:
	var blue := _material(profile.body_color)
	var cream := _material(Color("#dceaff"))
	body_mesh = MeshInstance3D.new()
	var body := CapsuleMesh.new()
	body.radius = 0.36
	body.height = 1.65
	body_mesh.mesh = body
	body_mesh.material_override = blue
	body_mesh.rotation_degrees.z = 90.0
	body_mesh.position.y = 0.75
	add_child(body_mesh)
	head_mesh = MeshInstance3D.new()
	var head := SphereMesh.new()
	head.radius = 0.34
	head.height = 0.68
	head_mesh.mesh = head
	head_mesh.material_override = blue
	head_mesh.position = Vector3(0.0, 1.05, -0.55)
	add_child(head_mesh)
	tail_mesh = MeshInstance3D.new()
	var tail := CylinderMesh.new()
	tail.top_radius = 0.03
	tail.bottom_radius = 0.18
	tail.height = 2.5
	tail_mesh.mesh = tail
	tail_mesh.material_override = blue
	tail_mesh.rotation_degrees.x = 90.0
	tail_mesh.position = Vector3(0.0, 0.72, 1.7)
	add_child(tail_mesh)
	for x in [-0.23, 0.23]:
		_add_leg(Vector3(x, 0.42, 0.25), cream, 0.11, 0.9)
	for x in [-0.23, 0.23]:
		_add_leg(Vector3(x, 0.38, -0.28), blue, 0.09, 0.66)
	_finish_visual_setup()

func _create_triceratops_visuals() -> void:
	var coral := _material(profile.body_color)
	var horn := _material(Color("#fff2c9"))
	body_mesh = MeshInstance3D.new()
	var body := SphereMesh.new()
	body.radius = 0.72
	body.height = 1.45
	body_mesh.mesh = body
	body_mesh.material_override = coral
	body_mesh.position.y = 0.86
	body_mesh.scale = Vector3(1.15, 0.9, 1.45)
	add_child(body_mesh)
	head_mesh = MeshInstance3D.new()
	var head := SphereMesh.new()
	head.radius = 0.52
	head.height = 1.04
	head_mesh.mesh = head
	head_mesh.material_override = coral
	head_mesh.position = Vector3(0.0, 1.0, -0.78)
	add_child(head_mesh)
	for x in [-0.28, 0.28]:
		var horn_mesh := MeshInstance3D.new()
		var horn_shape := CylinderMesh.new()
		horn_shape.top_radius = 0.02
		horn_shape.bottom_radius = 0.11
		horn_shape.height = 0.65
		horn_mesh.mesh = horn_shape
		horn_mesh.material_override = horn
		horn_mesh.rotation_degrees.x = 90.0
		horn_mesh.position = Vector3(x, 1.1, -1.22)
		add_child(horn_mesh)
	for x in [-0.48, 0.48]:
		_add_leg(Vector3(x, 0.38, 0.35), coral, 0.18, 0.75)
	for x in [-0.48, 0.48]:
		_add_leg(Vector3(x, 0.38, -0.36), coral, 0.18, 0.75)
	tail_mesh = MeshInstance3D.new()
	var tail := CylinderMesh.new()
	tail.top_radius = 0.04
	tail.bottom_radius = 0.22
	tail.height = 1.35
	tail_mesh.mesh = tail
	tail_mesh.material_override = coral
	tail_mesh.rotation_degrees.x = 90.0
	tail_mesh.position = Vector3(0.0, 0.82, 1.3)
	add_child(tail_mesh)
	_finish_visual_setup()

func _add_leg(leg_position: Vector3, material: Material, radius: float, height: float) -> void:
	var leg := MeshInstance3D.new()
	var leg_mesh := CapsuleMesh.new()
	leg_mesh.radius = radius
	leg_mesh.height = height
	leg.mesh = leg_mesh
	leg.material_override = material
	leg.position = leg_position
	add_child(leg)
	leg_meshes.append(leg)

func _finish_visual_setup() -> void:
	body_rest_y = body_mesh.position.y
	head_rest_y = head_mesh.position.y
	tail_rest_rotation = tail_mesh.rotation

func _animate_visuals(delta: float, speed_ratio: float) -> void:
	if imported_model != null:
		imported_action_timer = maxf(0.0, imported_action_timer - delta)
		if not imported_native_animations:
			visual_time += delta * lerpf(2.0, 12.0, clampf(speed_ratio, 0.0, 1.0))
			var imported_bob := sin(visual_time) * (0.035 if speed_ratio > 0.08 else 0.012)
			imported_model.position.y = imported_model_rest_y + imported_bob
		if imported_animation_player != null:
			var desired_animation := "Run" if speed_ratio > 1.0 else ("Walk" if speed_ratio > 0.08 else "Idle")
			if imported_native_animations and profile.id == "t_rex":
				# Movement at the game's normal speed is a run for a juvenile.
				desired_animation = "Run" if speed_ratio > 0.65 else ("Walk" if speed_ratio > 0.04 else "Idle")
			if imported_action_timer <= 0.0:
				if imported_animation_player.current_animation != desired_animation:
					imported_animation_player.play(desired_animation, 0.16)
				var stride_speed := 2.4 if desired_animation == "Run" else 1.1
				imported_animation_player.speed_scale = clampf(speed_ratio * move_speed / (stride_speed * growth_scale), 0.5, 2.6) if imported_native_animations and profile.id == "t_rex" and desired_animation != "Idle" else 1.0
		return
	if body_mesh == null or head_mesh == null or tail_mesh == null:
		return
	visual_time += delta * lerpf(2.0, 12.0, clampf(speed_ratio, 0.0, 1.0))
	var moving := speed_ratio > 0.08
	var bob := sin(visual_time) * (0.045 if moving else 0.012)
	body_mesh.position.y = body_rest_y + bob
	head_mesh.position.y = head_rest_y + bob * 0.65
	tail_mesh.rotation = tail_rest_rotation + Vector3(0.0, sin(visual_time * 0.7) * (0.22 if moving else 0.06), 0.0)
	for index in leg_meshes.size():
		var swing := sin(visual_time + PI * float(index % 2)) * (0.38 if moving else 0.05)
		leg_meshes[index].rotation.x = swing

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	return material
