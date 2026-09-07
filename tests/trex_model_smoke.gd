extends SceneTree

# Rendered skin validation. Rest AABBs and clip-name checks do not prove that
# the mesh stays assembled when a skeleton moves.
var failures := 0
var actor: PlayerDino

class HeroBenchmark extends PlayerDino:
	func _imported_model_paths() -> Array[String]:
		return ["res://assets/models/dinosaurs/t_rex_hero.glb"]

class MissingHero extends PlayerDino:
	func _imported_model_paths() -> Array[String]:
		return ["res://assets/models/dinosaurs/missing_hero_for_test.glb", "res://assets/models/dinosaurs/t_rex.glb"]

class MissingAllModels extends PlayerDino:
	func _imported_model_paths() -> Array[String]:
		return ["res://assets/models/dinosaurs/missing_model_for_test.glb"]

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and node.skin != null:
		return node
	for child in node.get_children():
		var result := _find_mesh(child)
		if result != null:
			return result
	return null

func _sample(clip: String, fraction: float) -> ArrayMesh:
	var animator := actor.imported_animation_player
	animator.play(clip, 0.0)
	animator.seek(animator.get_animation(clip).length * fraction, true)
	animator.pause()
	await process_frame
	await RenderingServer.frame_post_draw
	return _find_mesh(actor).bake_mesh_from_current_skeleton_pose()

func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://.validation/" + filename) == OK, "T. rex capture should save")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("T. rex skin smoke requires a rendered Godot run")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://.validation")
	root.size = Vector2i(1280, 720)
	var stage := Node3D.new()
	root.add_child(stage)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("263138")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("bac8cf")
	world.environment.ambient_light_energy = 0.6
	world.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	stage.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -35, 0)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	stage.add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	ground.mesh = plane
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color("414b45")
	ground_mat.roughness = 1.0
	ground.material_override = ground_mat
	stage.add_child(ground)
	actor = HeroBenchmark.new()
	actor.configure(DinosaurProfiles.t_rex())
	stage.add_child(actor)
	actor.set_physics_process(false)
	check(actor.imported_native_animations, "T. rex must use its imported skeletal animations")
	var skinned_mesh := _find_mesh(actor)
	check(skinned_mesh != null, "Visible hero mesh must have a skin")
	if skinned_mesh == null:
		stage.free()
		quit(1)
		return
	var body_material_found := false
	for surface in skinned_mesh.mesh.get_surface_count():
		var material := skinned_mesh.get_active_material(surface) as BaseMaterial3D
		if material != null and material.resource_name == "Body":
			body_material_found = true
			check(material.albedo_texture != null and material.albedo_texture.get_width() == 2048, "Body must use the 2K base-color map")
			check(material.normal_enabled and material.normal_texture != null, "Body must use the baked skin normal map")
			check(material.roughness_texture != null and material.ao_enabled and material.ao_texture != null, "Body must use roughness and occlusion maps")
	check(body_material_found, "Hero must expose its textured Body material")
	var camera := Camera3D.new()
	camera.fov = 48
	stage.add_child(camera)
	camera.position = Vector3(5, 2.7, -6.4)
	camera.look_at(Vector3(0, 1.05, .1))
	camera.current = true
	await process_frame
	var idle := await _sample("Idle", 0.0)
	var resting := skinned_mesh.global_transform * idle.get_aabb()
	check(resting.size.y > 1.8 and resting.size.y < 2.3, "Juvenile must be about two metres high in the actual skinned pose")
	check(resting.size.z > resting.size.y * 1.8, "Head to tail must run horizontally along Z")
	check(absf(resting.position.y) < 0.1, "Juvenile toes must meet the ground")
	await _capture("trex_juvenile.png")
	for clip in actor._required_animation_names():
		var first := await _sample(clip, 0.0)
		var middle := await _sample(clip, 0.45)
		var a: PackedVector3Array = first.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var b: PackedVector3Array = middle.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var max_motion := 0.0
		for vertex in a.size():
			max_motion = maxf(max_motion, a[vertex].distance_to(b[vertex]))
		check(max_motion > 0.005, "%s must deform visible vertices, not merely contain bone tracks" % clip)
		var posed := skinned_mesh.global_transform * middle.get_aabb()
		check(posed.size.length() < resting.size.length() * 1.6, "%s must not explode the skin" % clip)
		print("T. rex %s visible motion: %.3f m" % [clip, max_motion])
		if clip in ["Walk", "Run", "Roar", "PowerBite"]:
			await _capture("trex_%s.png" % clip.to_lower())
	await _sample("Idle", 0.0)
	actor.grow_to(1.75)
	for frame in 30:
		await process_frame
	var adult_mesh := await _sample("Idle", 0.0)
	var adult := skinned_mesh.global_transform * adult_mesh.get_aabb()
	check(absf(adult.size.y / resting.size.y - 1.75) < 0.02, "Growth must enlarge the whole skinned dinosaur")
	check(absf(adult.position.y) < 0.15, "Adult toes must remain at ground level")
	camera.position *= 1.75
	camera.look_at(Vector3(0, 1.85, .17))
	await _capture("trex_adult.png")
	for fallback in [MissingHero.new(), MissingAllModels.new()]:
		fallback.configure(DinosaurProfiles.t_rex())
		fallback.position = Vector3(12, 2, -8)
		stage.add_child(fallback)
		if fallback is MissingHero:
			check(fallback.imported_model != null, "Missing hero must load the older GLB")
		else:
			check(fallback.imported_model == null and fallback.body_mesh != null, "Missing GLBs must build the procedural dinosaur")
		fallback.free()
	stage.free()
	await process_frame
	print("T. rex rendered skin smoke: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
