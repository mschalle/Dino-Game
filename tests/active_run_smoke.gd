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

func _count_visible_meshes(node: Node) -> Dictionary:
	var counts := {"total": 0, "visible": 0}
	if node is MeshInstance3D:
		counts["total"] += 1
		if node.is_visible_in_tree():
			counts["visible"] += 1
	for child in node.get_children():
		var child_counts := _count_visible_meshes(child)
		for key in counts:
			counts[key] += child_counts[key]
	return counts

func _run() -> void:
	var game = load("res://Main.tscn").instantiate()
	# Never load or write the player's real progress during validation.
	DirAccess.make_dir_recursive_absolute("res://.validation")
	game.save_system = SaveSystem.new("res://.validation/active_run_save.json")
	game.save_system.save_data()
	root.add_child(game)
	var nest: Node3D = game.chunk_instances["nest_basin"]
	check(nest.get_node("Ground").mesh is ArrayMesh, "Adventure must use the heightfield pilot")
	check(game.get_node_or_null("AuthoredHeroValley") == null and game.get_node_or_null("LegacyValleyGround") == null,
		"Legacy hero surfaces must not overlap streamed Nest Basin")
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
	var before_reverse: Vector3 = game.player.global_position
	Input.action_press("move_left")
	for frame in 30:
		await physics_frame
	Input.action_release("move_left")
	var after_reverse: Vector3 = game.player.global_position
	check(before_reverse.distance_to(after_reverse) < 8.0 and game.player.velocity.length() < 12.0, "Direction changes should stay bounded without snapping or teleporting")
	check(game.session.survival_time > 1.0, "Session clock must advance during gameplay")
	check(game.player.get_node_or_null("BodyCollision") != null and game.player.is_on_floor(), "Player must walk on real terrain collision")
	game._create_eggs(Vector3(-5, 0, -16))
	for egg in game.quest_props:
		check(absf(egg.position.y - game._terrain_height_at(egg.position.x, egg.position.z) - 0.38) < 0.001, "Quest eggs must be grounded on the ridge")
	# A real obstruction must shorten the arm; clearing it must restore the view.
	var wall := StaticBody3D.new()
	var wall_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(8, 8, 0.5)
	wall_shape.shape = box
	wall.add_child(wall_shape)
	game.run_root.add_child(wall)
	wall.global_position = game.player.global_position + Vector3(0, 3, 4)
	for frame in 10:
		await physics_frame
	check(game.camera_arm.get_hit_length() < 5.0, "Camera arm must retract in front of an obstruction")
	wall.free()
	for frame in 120:
		await physics_frame
	check(game.camera_arm.get_hit_length() > 8.0, "Camera arm must recover after the obstruction clears")
	var player_bounds: AABB = game.player._visual_bounds(game.player.imported_model)
	var player_center := player_bounds.get_center()
	var player_screen: Vector2 = game.camera.unproject_position(player_center)
	var mesh_counts := _count_visible_meshes(game.player.imported_model)
	print("T. rex live silhouette: %s; visible meshes: %d" % [player_bounds.size, mesh_counts["visible"]])
	check(player_bounds.size.y >= 1.8, "T. rex visual must retain juvenile height during an active run")
	check(maxf(player_bounds.size.x, player_bounds.size.z) >= player_bounds.size.y * 1.5,
		"T. rex must retain its full head-to-tail silhouette during an active run")
	check(Vector2(player_center.x - game.player.global_position.x, player_center.z - game.player.global_position.z).length() < 1.0,
		"T. rex visual must remain centered on the moving player")
	check(not game.camera.is_position_behind(player_center), "T. rex visual must remain in front of the gameplay camera")
	check(Rect2(Vector2(0, 270), Vector2(1280, 330)).has_point(player_screen), "T. rex must be framed in the unobstructed gameplay area")
	check(mesh_counts["visible"] > 0, "T. rex mesh instances must be visible in the scene tree")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		var capture_error := root.get_texture().get_image().save_png("res://.validation/active_run.png")
		check(capture_error == OK, "Rendered smoke screenshot must save successfully")
	check(not game.predators.is_empty(), "Smoke run must contain active predators")
	for creature in game.predators:
		check(creature.receive_attack(1.0, game.player.global_position), "Predator must accept a combat impact")
	game.player.play_combat_animation(true)
	check(game.player.imported_animation_player.current_animation == "PowerBite", "Power Bite must trigger the native jaw action")
	game.player.play_reaction("Roar")
	check(game.player.imported_animation_player.current_animation == "Roar", "Roar must trigger its skeletal action")
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
	game.session.growth.add_points(14)
	game._use_special_ability()
	check(game.player.imported_animation_player.current_animation == "Roar", "Unlocked Valley Roar must animate from the real ability handler")
	game._on_predator_attack(1.0)
	check(game.player.imported_animation_player.current_animation == "Hit", "Predator damage must play the hit reaction")
	var stage_floor: int = game.session.growth.thresholds[game.session.growth.stage_index]
	game.session.take_damage(10000.0)
	check(game.session.defeat_in_progress and not game.game_active, "Defeat must pause gameplay while its animation is visible")
	check(game.player.imported_animation_player.current_animation == "Defeat", "Defeat must play before returning to the nest")
	for frame in 65:
		await physics_frame
	check(game.game_active and not game.session.defeat_in_progress, "Animated defeat must restore a playable run")
	check(game.session.growth.points == stage_floor, "Animated defeat must still reset only current-stage growth")
	check(game.player.is_physics_processing(), "Player controls must return after defeat")
	game.session.take_damage(10000.0)
	game._restart_run()
	var replacement_session: GameSession = game.session
	for frame in 65:
		await physics_frame
	check(game.session == replacement_session and game.session.defeat_count == 0 and game.game_active,
		"A pending defeat animation must not respawn or modify a restarted run")
	game.free()
	await process_frame
	print("Active run smoke: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
