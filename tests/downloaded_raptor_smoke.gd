extends SceneTree

var failures := 0

class FallbackRaptor extends PlayerDino:
	func _imported_model_paths() -> Array[String]:
		return ["res://assets/models/dinosaurs/missing_local_raptor.glb", "res://assets/models/dinosaurs/velociraptor.glb"]

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func skin_bounds(node: Node) -> AABB:
	var result := AABB()
	if node is Skeleton3D:
		var head: int = node.find_bone("Head_09")
		var tail: int = node.find_bone("Tail_1_074")
		if head >= 0 and tail >= 0:
			var head_position: Vector3 = node.global_transform * node.get_bone_global_pose(head).origin
			var tail_position: Vector3 = node.global_transform * node.get_bone_global_pose(tail).origin
			check(head_position.z < tail_position.z, "Head faces controller forward")
	if node is MeshInstance3D and node.skin != null:
		result = node.global_transform * node.bake_mesh_from_current_skeleton_pose().get_aabb()
	for child in node.get_children():
		var child_bounds := skin_bounds(child)
		if child_bounds.size != Vector3.ZERO:
			result = child_bounds if result.size == Vector3.ZERO else result.merge(child_bounds)
	return result

func _run() -> void:
	var actor := PlayerDino.new()
	actor.configure(DinosaurProfiles.velociraptor())
	root.add_child(actor)
	actor.set_physics_process(false)
	check(actor.imported_model.scene_file_path.ends_with("/pbr_velociraptor_animated.glb"), "Downloaded raptor selected")
	check(actor.imported_native_animations, "Uses native skeletal animation")
	var camera := Camera3D.new()
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = .7
	root.add_child(environment)
	root.add_child(camera)
	camera.position = Vector3(3, 2, -4)
	camera.look_at(Vector3(0, .8, 0))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -30, 0)
	root.add_child(sun)
	for clip in actor._required_animation_names():
		var animation := actor.imported_animation_player.get_animation(clip)
		check(animation.get_track_count() > 10, clip + " retains skeletal tracks")
		actor.play_reaction(clip)
		for frame in 20:
			await process_frame
	actor.imported_animation_player.play("Idle", 0)
	actor.imported_animation_player.advance(0)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var visible_bounds := skin_bounds(actor)
		print("Raptor visible bounds: ", visible_bounds)
		check(visible_bounds.size.y > 1.2 and visible_bounds.size.y < 2.0, "Animated mesh retains gameplay scale")
		check(absf(visible_bounds.position.y) < .25, "Animated toes stay near ground")
		check(root.get_texture().get_image().save_png("res://.validation/downloaded_raptor_game.png") == OK, "Capture saved")
	actor.grow_to(1.5)
	await create_timer(.5).timeout
	check(actor.scale.is_equal_approx(Vector3.ONE * 1.5), "Growth preserved")
	actor.free()
	var fallback := FallbackRaptor.new()
	fallback.configure(DinosaurProfiles.velociraptor())
	root.add_child(fallback)
	check(fallback.imported_model.scene_file_path.ends_with("/velociraptor.glb"), "Missing download uses baseline")
	check(fallback.imported_native_animations, "Baseline keeps native animation")
	fallback.free()
	camera.free()
	environment.free()
	sun.free()
	var game = load("res://Main.tscn").instantiate()
	game.save_system = SaveSystem.new("res://.validation/raptor_test_save.json")
	game.save_system.save_data()
	root.add_child(game)
	game._start_run(DinosaurProfiles.velociraptor(), "adventure")
	for frame in 20:
		await physics_frame
	var start: Vector3 = game.player.global_position
	Input.action_press("move_forward")
	for frame in 60:
		await physics_frame
	Input.action_release("move_forward")
	check(game.player.global_position.distance_to(start) > 2, "Raptor Adventure movement")
	game.player.play_combat_animation(false)
	check(game.player.imported_animation_player.current_animation == "Attack", "Native bite in Adventure")
	check(game.player.try_dash(true), "Raptor dash preserved")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://.validation/raptor_adventure.png") == OK, "Adventure capture saved")
	print("Downloaded raptor: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
