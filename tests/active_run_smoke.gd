extends SceneTree

# Exercise real frame callbacks; synchronous state tests cannot catch frame failures.
var failures := 0

class FallbackPredator extends ValleyPredator:
	func _try_imported_model() -> bool:
		return false

class FallbackPrey extends PreyDino:
	func _try_imported_model() -> bool:
		return false

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func _run() -> void:
	var game = load("res://Main.tscn").instantiate()
	# Never load or write the player's real progress during validation.
	DirAccess.make_dir_recursive_absolute("res://.validation")
	game.save_system = SaveSystem.new("res://.validation/active_run_save.json")
	game.save_system.save_data()
	root.add_child(game)
	var authored: Node3D = game.get_node_or_null("AuthoredHeroValley")
	if authored != null:
		var max_height_error := 0.0
		for mesh_node in authored.find_children("*", "MeshInstance3D", true, false):
			for surface in mesh_node.mesh.get_surface_count():
				var vertices: PackedVector3Array = mesh_node.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
				for vertex in vertices:
					var point: Vector3 = mesh_node.global_transform * vertex
					max_height_error = maxf(max_height_error, absf(point.y - game._terrain_height_at(point.x, point.z)))
		check(max_height_error < 0.01, "Imported terrain must be Y-up and match collision height within 1cm")
		print("Imported terrain height error: %.5f m" % max_height_error)
	game._start_run(DinosaurProfiles.t_rex(), "adventure")
	for frame in 15:
		await physics_frame
	check(game.game_active and not paused, "Adventure must start unpaused")
	check(not game.hud.title_label.text.is_empty(), "HUD must update during a real running frame")
	var start: Vector3 = game.player.global_position
	Input.action_press("move_right")
	for frame in 120:
		await physics_frame
	Input.action_release("move_right")
	var distance := Vector2(game.player.global_position.x - start.x, game.player.global_position.z - start.z).length()
	print("Active run movement: %.2f metres" % distance)
	check(distance >= 5.0, "Player must travel at least five metres using movement input")
	check(game.session.survival_time > 1.0, "Session clock must advance during gameplay")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		var capture_error := root.get_texture().get_image().save_png("res://.validation/active_run.png")
		check(capture_error == OK, "Rendered smoke screenshot must save successfully")
	check(not game.predators.is_empty(), "Smoke run must contain active predators")
	for creature in game.predators:
		check(creature.receive_attack(1.0, game.player.global_position), "Predator must accept a combat impact")
	for frame in 30:
		await physics_frame
	# Check both asset-present and procedural-fallback paths independently.
	for actor in [FallbackPredator.new(), FallbackPrey.new()]:
		game.run_root.add_child(actor)
		var original_color: Color = actor.body_mesh.material_override.albedo_color
		actor.impact_timer = 0.2
		actor._animate_visuals(false)
		check(actor.body_mesh.material_override.albedo_color != original_color, "Impact must tint a 3D material")
		actor.impact_timer = 0.0
		actor._animate_visuals(false)
		check(actor.body_mesh.material_override.albedo_color == original_color, "Impact recovery must preserve the dinosaur's color")
		actor.free()
	for script_path in ["res://player.gd", "res://predator.gd", "res://prey.gd"]:
		var actor = load(script_path).new()
		actor.imported_model = Node3D.new()
		actor.imported_model.name = "ImportedDinosaurModel"
		actor.add_child(actor.imported_model)
		actor._create_imported_animation_library()
		var animator: AnimationPlayer = actor.imported_animation_player
		var animation_root := animator.get_node(animator.root_node)
		for clip in ["Idle", "Walk", "Run", "Attack", "Hit"]:
			var animation := animator.get_animation(clip)
			for track in animation.get_track_count():
				var target := NodePath(animation.track_get_path(track).get_concatenated_names())
				check(animation_root.get_node_or_null(target) == actor.imported_model, "%s %s track must resolve to its model" % [script_path, clip])
		actor.free()
	game.free()
	await process_frame
	print("Active run smoke: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
