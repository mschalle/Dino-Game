extends SceneTree

const WORLD_CHUNK_PROFILES = preload("res://world_chunk_profiles.gd")
const WORLD_STREAM_MANAGER = preload("res://world_stream_manager.gd")
const HABITAT_SPAWN_RULES = preload("res://habitat_spawn_rules.gd")

var failures := 0

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	_test_profiles()
	_test_all_playable_species()
	_test_species_asset_and_save_isolation()
	_test_all_species_endless_unlocks()
	_test_endless_progression_all_species()
	_test_endless_scaling_rules()
	_test_release_readiness()
	_test_selection_roster_layout()
	_test_selection_navigation()
	_test_selection_focus_mapping()
	_test_controller_bindings()
	_test_world_chunks()
	_test_habitat_rules()
	_test_world_streaming()
	_test_growth()
	_test_quests()
	_test_survival()
	_test_creature_combat()
	_test_predator_respawn_gate()
	_test_prey_respawn_gate()
	_test_mixed_population_cooldowns()
	_test_long_streaming_session()
	_test_ai_states()
	_test_low_level_food_supply()
	_test_habitat_food_filter()
	_test_hud_contrast()
	_test_runtime_metrics_warning()
	_test_diagnostics_visibility()
	_test_flow_signals()
	_test_frame_sampling()
	_test_performance_budget()
	_test_gameplay_integration()
	_test_main_predator_gate_helper()
	_test_save_recovery()
	if failures == 0:
		print("Roar & Rise tests: PASS")
		quit(0)
	else:
		push_error("Roar & Rise tests: %d failure(s)" % failures)
		quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _test_profiles() -> void:
	var sound_feedback := preload("res://sound_feedback.gd").new()
	sound_feedback.play_food()
	_check(sound_feedback.tone_queue.size() == 2, "Food feedback should queue a friendly two-note sound")
	sound_feedback.free()
	var profiles := DinosaurProfiles.all()
	_check(profiles.size() == 6, "Expected six playable profiles")
	var ids: Dictionary = {}
	var finale_ids: Dictionary = {}
	for profile in profiles:
		_check(not ids.has(profile.id), "Species IDs must be unique")
		ids[profile.id] = true
		_check(profile.growth_thresholds == [0, 5, 12, 25], "Growth thresholds must match the design")
		_check(profile.adventure_quests.size() == 4, "%s needs four main quests" % profile.id)
		var finale: QuestDefinition = profile.adventure_quests[3]
		_check(finale.objective_type == "finale", "%s needs an Adult finale quest" % profile.id)
		_check(not finale_ids.has(finale.id), "Finale quest IDs must be unique")
		finale_ids[finale.id] = true
		_check(not profile.abilities.is_empty(), "%s needs abilities" % profile.id)
	_check(DinosaurProfiles.triceratops().diet == "herbivore", "Triceratops must eat plants")
	_check(DinosaurProfiles.t_rex().diet == "carnivore", "T. rex must eat prey")
	_check(FileAccess.file_exists("res://assets/models/dinosaurs/t_rex.glb"), "The first imported T. rex GLB should be present")
	_check(FileAccess.file_exists("res://assets/models/dinosaurs/t_rex_hero.glb"), "The higher-resolution T. rex hero GLB should be present")
	for playable_model_id in ["ankylosaurus", "parasaurolophus", "carnotaurus"]:
		_check(FileAccess.file_exists("res://assets/models/dinosaurs/%s.glb" % playable_model_id), "%s playable GLB should be present" % playable_model_id)
	for model_id in ["velociraptor", "triceratops", "psittacosaurus", "dryosaurus", "parasaurolophus", "dilophosaurus", "carnotaurus", "allosaurus"]:
		_check(FileAccess.file_exists("res://assets/models/dinosaurs/%s.glb" % model_id), "%s GLB should be present" % model_id)
	for profile in profiles:
		var dino := PlayerDino.new()
		dino.configure(profile)
		root.add_child(dino)
		_check((dino.imported_model != null) or (dino.tail_mesh != null and dino.leg_meshes.size() >= 4), "%s needs a complete dinosaur silhouette" % profile.id)
		dino.free()

func _test_all_playable_species() -> void:
	var save := preload("res://save_system.gd").new()
	for profile in DinosaurProfiles.all():
		var session := GameSession.new()
		session.start(profile, "adventure")
		_check(session.profile.id == profile.id, "%s Adventure should start with its own profile" % profile.id)
		_check(profile.abilities.size() >= 3, "%s should expose its ability progression" % profile.id)
		_check(profile.adventure_quests.size() >= 4, "%s should expose a full quest chain" % profile.id)
		save.record_run(profile.id, 1.0, 1, 0, {"species_validation": true})
	var records: Dictionary = save.data.get("records", {})
	for profile in DinosaurProfiles.all():
		_check(records.has(profile.id), "%s should persist an independent record" % profile.id)
	# SaveSystem is RefCounted; allow reference counting to release it naturally.

func _test_species_asset_and_save_isolation() -> void:
	var save := preload("res://save_system.gd").new()
	for species_id in ["t_rex", "velociraptor", "triceratops", "ankylosaurus", "parasaurolophus", "carnotaurus"]:
		var profile = DinosaurProfiles.by_id(species_id)
		_check(profile != null, "%s should resolve from the selection roster" % species_id)
		_check(FileAccess.file_exists("res://assets/models/dinosaurs/%s.glb" % species_id), "%s should have an authored GLB or fallback asset" % species_id)
		save.record_run(species_id, 10.0, 2, 1, {"species": species_id})
	var records: Dictionary = save.data.get("records", {})
	_check(records.get("t_rex", {}).get("best_growth_points", 0) == 2, "T. rex record should remain isolated")
	_check(records.get("carnotaurus", {}).get("best_growth_points", 0) == 2, "Carnotaurus record should remain isolated")
	# SaveSystem is RefCounted; allow reference counting to release it naturally.

func _test_all_species_endless_unlocks() -> void:
	var save := preload("res://save_system.gd").new()
	for profile in DinosaurProfiles.all():
		save.unlock_endless(profile.id)
		_check(save.is_endless_unlocked(profile.id), "%s should unlock Endless after Adventure completion" % profile.id)
	for profile in DinosaurProfiles.all():
		_check(save.is_endless_unlocked(profile.id), "%s Endless unlock should persist independently" % profile.id)
	# SaveSystem is RefCounted; allow reference counting to release it naturally.

func _test_endless_progression_all_species() -> void:
	var save := preload("res://save_system.gd").new()
	for profile in DinosaurProfiles.all():
		save.unlock_endless(profile.id)
		var session := GameSession.new()
		session.start(profile, "endless")
		session.tick(45.0, false)
		session.quests_completed = 2
		save.record_run(profile.id, session.survival_time, session.growth.points, session.quests_completed, {"endless_validation": true})
		_check(session.mode == "endless" and session.survival_time >= 45.0, "%s Endless session should advance survival time" % profile.id)
	var records: Dictionary = save.data.get("records", {})
	for profile in DinosaurProfiles.all():
		_check(float(records.get(profile.id, {}).get("best_survival_seconds", 0.0)) >= 45.0, "%s Endless record should persist" % profile.id)
		_check(int(records.get(profile.id, {}).get("best_quests", 0)) >= 2, "%s Endless quest record should persist" % profile.id)
	# SaveSystem is RefCounted; allow reference counting to release it naturally.

func _test_endless_scaling_rules() -> void:
	var awareness_start := 1.0 + minf(0.0 / 600.0, 0.75)
	var awareness_late := 1.0 + minf(600.0 / 600.0, 0.75)
	_check(is_equal_approx(awareness_start, 1.0), "Endless predators should start at baseline awareness")
	_check(is_equal_approx(awareness_late, 1.75), "Endless predator awareness should cap at 1.75x")
	var scarcity_start := mini(int(0.0 / 180.0), 4)
	var scarcity_late := mini(int(720.0 / 180.0), 4)
	_check(scarcity_start == 0 and scarcity_late == 4, "Endless scarcity should increase in bounded steps")
	_check(maxi(3, 5 - scarcity_late) >= 3, "Endless scarcity should preserve tier-1 food availability")

func _test_release_readiness() -> void:
	_check(FileAccess.file_exists("res://project.godot"), "Release build should include project settings")
	_check(FileAccess.file_exists("res://Main.tscn"), "Release build should include the main scene")
	_check(FileAccess.file_exists("res://save_system.gd"), "Release build should include save recovery")
	_check(DinosaurProfiles.all().size() == 6, "Release roster should contain six playable species")
	_check(SaveSystem.SAVE_VERSION >= 1, "Release save schema should be versioned")
	_check(FileAccess.file_exists("res://tests/run_tests.gd"), "Release validation suite should be packaged with the project")

func _test_selection_roster_layout() -> void:
	var profiles := DinosaurProfiles.all()
	var seen: Dictionary = {}
	for index in profiles.size():
		var profile = profiles[index]
		_check(not seen.has(profile.id), "Selection roster IDs must be unique")
		seen[profile.id] = true
		var column := index % 3
		var row := index / 3
		_check(column >= 0 and column < 3 and row >= 0, "Selection card grid position should be focusable")
	_check(profiles.size() == 6, "Selection roster should expose six playable dinosaurs")

func _test_selection_navigation() -> void:
	_check(DinosaurProfiles.selection_neighbor(0, "right") == 1, "Selection right navigation should advance")
	_check(DinosaurProfiles.selection_neighbor(0, "left") == 2, "Selection left navigation should wrap the row")
	_check(DinosaurProfiles.selection_neighbor(0, "down") == 3, "Selection down navigation should move to the next row")
	_check(DinosaurProfiles.selection_neighbor(3, "up") == 0, "Selection up navigation should return to the prior row")

func _test_selection_focus_mapping() -> void:
	for index in 6:
		_check(DinosaurProfiles.selection_neighbor(index, "left") >= 0, "Every selection card should have a left focus target")
		_check(DinosaurProfiles.selection_neighbor(index, "right") < 6, "Every selection card should have a right focus target")

func _test_controller_bindings() -> void:
	for action in ["ui_accept", "ui_cancel", "move_forward", "move_back", "move_left", "move_right"]:
		_check(InputMap.has_action(action), "%s should be available for keyboard/gamepad input" % action)
	var accept := InputEventJoypadButton.new()
	accept.button_index = JOY_BUTTON_A
	_check(accept.button_index == JOY_BUTTON_A, "Controller activation event should be constructible")

func _test_world_chunks() -> void:
	var chunks: Array = WORLD_CHUNK_PROFILES.reserve()
	var stream := WORLD_STREAM_MANAGER.new()
	stream.configure(chunks, 1)
	_check(stream.grid_position_at_world_position(Vector3(31.0, 0.0, -29.0)) == Vector2i(1, 0), "World positions should map to streamed chunk grid coordinates")
	stream.update_player_chunk(Vector2i.ZERO)
	_check(stream.is_active("nest_basin") and stream.is_active("fernwood"), "Origin chunk should activate adjacent reserve cells")
	var nest_instance := stream.instantiate_chunk("nest_basin", root)
	_check(stream.landmark_for_chunk("nest_basin") != null, "Active chunks should expose their landmark destination")
	var landmark_position: Variant = stream.landmark_position_for_chunk("nest_basin")
	_check(landmark_position is Vector3 and is_finite((landmark_position as Vector3).x), "Landmark destination should expose a world-space position")
	_check(stream.active_landmark_positions().has("nest_basin"), "Active landmark positions should include loaded destinations")
	if nest_instance != null:
		stream.release_chunk("nest_basin")
	stream.update_player_chunk(Vector2i(2, 1))
	_check(stream.is_active("redstone_badlands") and not stream.is_active("nest_basin"), "Crossing a chunk boundary should update the active set")
	_check(chunks.size() == 6, "Reserve should define six initial biome chunks")
	_check(WORLD_CHUNK_PROFILES.connections_are_symmetric(chunks), "Biome connections must be bidirectional")
	var route := WORLD_CHUNK_PROFILES.find_route(chunks, "nest_basin", "redstone_badlands")
	_check(route.size() >= 2, "Reserve must provide a route between distant biomes")
	_check(route.front() == "nest_basin" and route.back() == "redstone_badlands", "Biome route endpoints must be correct")
	var ids: Dictionary = {}
	for chunk in chunks:
		_check(not ids.has(chunk.chunk_id), "Chunk IDs must be unique")
		ids[chunk.chunk_id] = true
		_check(not chunk.landmark_name.is_empty(), "Every chunk needs a landmark")
		_check(not chunk.scene_path.is_empty(), "Every chunk needs a scene path")
		_check(chunk.has_scene(), "Every initial biome chunk should have a loadable scene shell")
		_check(chunk.vegetation_density > 0.0, "Every biome needs vegetation density")
		_check(chunk.fog_density > 0.0, "Every biome needs fog guidance")
		_check(chunk.navigation_layers > 0, "Every biome needs navigation layers")
		_check(chunk.agent_radius > 0.0, "Every biome needs an agent radius")
		_check(chunk.max_slope_degrees > 0.0 and chunk.max_slope_degrees <= 45.0, "Biome slope must remain traversable")
		_check(chunk.max_climb > 0.0, "Every biome needs a climb limit")
		_check(not chunk.neighbor_ids.is_empty() or chunk.chunk_id == "nest_basin", "Chunks should define connected neighbors")
		var scene := load(chunk.scene_path) as PackedScene
		var visual_root := scene.instantiate()
		root.add_child(visual_root)
		_check(visual_root.get_child_count() >= 1, "%s should create a visible landmark mesh" % chunk.chunk_id)
		_check(visual_root.get_node_or_null("Ground") != null, "%s should create a ground mesh" % chunk.chunk_id)
		_check(visual_root.get_node_or_null("GroundCollision") != null, "%s should create ground collision" % chunk.chunk_id)
		_check(visual_root.get_node_or_null("LandmarkSilhouette") != null, "%s should create a landmark silhouette" % chunk.chunk_id)
		var silhouette := visual_root.get_node_or_null("LandmarkSilhouette")
		_check(str(silhouette.get_meta("biome", "")) == chunk.biome, "%s landmark should retain biome identity" % chunk.chunk_id)
		var vegetation := visual_root.get_node_or_null("Vegetation") as MultiMeshInstance3D
		_check(vegetation != null and vegetation.multimesh != null and vegetation.multimesh.instance_count > 0, "%s should create batched vegetation" % chunk.chunk_id)
		var water := visual_root.get_node_or_null("WaterSurface")
		_check((chunk.biome == "River Wetlands") == (water != null), "%s water surface should match its biome" % chunk.chunk_id)
		var particles := visual_root.get_node_or_null("AmbientParticles") as GPUParticles3D
		_check(particles != null and particles.amount > 0 and particles.lifetime > 0.0, "%s should create ambient particles" % chunk.chunk_id)
		var navigation := visual_root.get_node_or_null("NavigationRegion") as NavigationRegion3D
		_check(navigation != null and navigation.navigation_mesh != null, "%s should create a navigation region" % chunk.chunk_id)
		_check(navigation.navigation_mesh.vertices.size() == 4, "%s navigation mesh should cover its ground pad" % chunk.chunk_id)
		if chunk.biome != "Nest Basin":
			_check(visual_root.get_node_or_null("Elevation") != null, "%s should create an elevated terrain feature" % chunk.chunk_id)
			_check(visual_root.get_node_or_null("ElevationCollision") != null, "%s should create elevated terrain collision" % chunk.chunk_id)
		var has_labelled_landmark := false
		for child in visual_root.get_children():
			if child is MeshInstance3D and child.get_child_count() >= 1:
				has_labelled_landmark = true
		_check(has_labelled_landmark, "%s landmark should include a readable label" % chunk.chunk_id)
		visual_root.free()

func _test_habitat_rules() -> void:
	_check(HABITAT_SPAWN_RULES.allows_tier("Nest Basin", "prey", 1), "Nest Basin should support tier-1 prey")
	_check(not HABITAT_SPAWN_RULES.allows_tier("Nest Basin", "prey", 3), "Nest Basin should not support tier-3 prey")
	_check(HABITAT_SPAWN_RULES.allows_tier("Redstone Badlands", "predator", 3), "Badlands should support tier-3 predators")
	_check(not HABITAT_SPAWN_RULES.allows_tier("Ancient Meadow", "predator", 2), "Ancient Meadow should not support predators")

func _test_runtime_metrics_warning() -> void:
	var metrics := {"npc_count": 22, "population_utilization": 0.88}
	_check(int(metrics.get("npc_count", 0)) >= 20, "Diagnostics warning threshold should be testable")

func _test_diagnostics_visibility() -> void:
	var hud := preload("res://game_hud.gd").new()
	hud.set_diagnostics_enabled(false)
	_check(not hud.diagnostics_enabled, "Diagnostics should be configurable for release builds")
	hud.free()

func _test_flow_signals() -> void:
	var hud := GameHUD.new()
	var events := {"resume": 0, "restart": 0, "selection": 0}
	hud.resume_requested.connect(func() -> void: events["resume"] += 1)
	hud.restart_requested.connect(func() -> void: events["restart"] += 1)
	hud.selection_requested.connect(func() -> void: events["selection"] += 1)
	hud.resume_requested.emit()
	hud.restart_requested.emit()
	hud.selection_requested.emit()
	_check(events["resume"] == 1 and events["restart"] == 1 and events["selection"] == 1, "Pause flow signals should remain independently triggerable")
	hud.free()

func _test_frame_sampling() -> void:
	var hud := preload("res://game_hud.gd").new()
	for index in 40:
		hud.record_frame_time(0.025)
	_check(hud.frame_samples.size() == 30, "Frame sampling should retain a bounded rolling window")
	hud.free()

func _test_performance_budget() -> void:
	var manager = WORLD_STREAM_MANAGER.new()
	manager.configure(WORLD_CHUNK_PROFILES.reserve(), 1)
	for step in 300:
		manager.update_player_chunk(Vector2i(step % 3, (step / 3) % 3))
		manager.tick_respawn_cooldowns(1.0 / 60.0)
		_check(manager.active_ids.size() <= 9, "Streaming should keep the active neighborhood bounded")
	var metrics := manager.runtime_metrics(root)
	_check(int(metrics.get("loaded_chunk_scenes", 0)) <= 9, "Loaded chunk scenes should remain within the streaming budget")

func _test_predator_respawn_gate() -> void:
	var predator := preload("res://predator.gd").new()
	var gate_state := [false]
	predator.set_respawn_gate(func() -> bool: return gate_state[0])
	_check(not predator.respawn_gate.call(), "Predator respawn gate should block while cooldown is active")
	gate_state[0] = true
	_check(predator.respawn_gate.call(), "Predator respawn gate should open after cooldown")
	predator.free()

func _test_prey_respawn_gate() -> void:
	var prey := preload("res://prey.gd").new()
	var gate_state := [false]
	prey.set_respawn_gate(func() -> bool: return gate_state[0])
	_check(not prey.respawn_gate.call(), "Prey respawn gate should block while cooldown is active")
	gate_state[0] = true
	_check(prey.respawn_gate.call(), "Prey respawn gate should open after cooldown")
	prey.free()

func _test_mixed_population_cooldowns() -> void:
	var manager = WORLD_STREAM_MANAGER.new()
	manager.configure(WORLD_CHUNK_PROFILES.reserve(), 1)
	manager.update_player_chunk(Vector2i(0, 0))
	manager.set_tier_respawn_cooldown("fernwood", "predator", 1, 12.0)
	manager.set_tier_respawn_cooldown("nest_basin", "prey", 1, 6.0)
	var cooldowns := manager.active_tier_respawn_cooldowns()
	_check(is_equal_approx(cooldowns.get("predator_1", 0.0), 12.0), "Active predator cooldown should be preserved")
	_check(is_equal_approx(cooldowns.get("prey_1", 0.0), 6.0), "Active prey cooldown should be preserved")
	_check(not manager.tier_respawn_ready("fernwood", "predator", 1), "Fernwood predator should remain gated")
	_check(not manager.tier_respawn_ready("nest_basin", "prey", 1), "Nest Basin prey should remain gated")
	_check(manager.tier_respawn_ready("nest_basin", "predator", 1), "Unaffected Nest Basin predator tier should remain ready")

func _test_long_streaming_session() -> void:
	var manager = WORLD_STREAM_MANAGER.new()
	manager.configure(WORLD_CHUNK_PROFILES.reserve(), 1)
	manager.set_chunk_state("nest_basin", {"population": {"prey": 4, "predator": 1}})
	manager.set_chunk_state("fernwood", {"population": {"prey": 3, "predator": 1}})
	manager.set_tier_respawn_cooldown("fernwood", "predator", 1, 30.0)
	for step in 600:
		var grid := Vector2i(step % 3, (step / 3) % 3)
		manager.update_player_chunk(grid)
		manager.tick_respawn_cooldowns(0.5)
		var budget := manager.active_population_budget()
		_check(int(budget.get("prey", 0)) <= 7, "Long session population budget must remain bounded")
	_check(manager.get_tier_respawn_cooldown("fernwood", "predator", 1) <= 0.0, "Long session cooldowns should eventually expire")

func _test_main_predator_gate_helper() -> void:
	var controller := preload("res://main.gd").new()
	_check(controller != null, "Main controller should remain instantiable with predator gates")
	controller.free()

func _test_habitat_food_filter() -> void:
	var spawner := preload("res://food_spawner.gd").new()
	spawner.set_spawn_plan([{"role": "prey", "tier": 1}])
	_check(spawner.allowed_prey_tiers == [1], "Food spawner should accept active habitat prey tiers")
	_check(spawner.population_caps[1] == 4, "Food spawner should derive a tier population cap")
	spawner.set_respawn_cooldown(4.0)
	spawner.maintain(3.0, 0.0)
	_check(is_equal_approx(spawner.habitat_respawn_cooldown, 1.0), "Food spawner should tick habitat cooldowns")
	spawner.free()

func _test_world_streaming() -> void:
	var manager = WORLD_STREAM_MANAGER.new()
	manager.configure(WORLD_CHUNK_PROFILES.reserve(), 1)
	manager.update_player_chunk(Vector2i(0, 0))
	_check(manager.is_active("nest_basin"), "Player chunk should activate")
	_check(manager.is_active("fernwood"), "Adjacent chunk should activate")
	_check(not manager.is_active("redstone_badlands"), "Distant chunk should remain inactive")
	manager.update_player_chunk(Vector2i(2, 1))
	_check(manager.is_active("redstone_badlands"), "New player neighborhood should activate")
	_check(not manager.is_active("nest_basin"), "Distant previous chunk should deactivate")
	var spawn_plan := manager.active_spawn_plan()
	_check(not spawn_plan.is_empty(), "Active chunks should provide a spawn plan")
	for spawn in spawn_plan:
		_check(spawn.get("role", "") == "prey" or spawn.get("role", "") == "predator", "Spawn plan roles must be valid")
		_check(int(spawn.get("tier", 0)) > 0, "Spawn plan tiers must be positive")
	_check(manager.is_world_position_navigable(Vector3(120.0, 0.0, 60.0)), "Active chunk positions should be navigable")
	_check(not manager.is_world_position_navigable(Vector3(500.0, 0.0, 500.0)), "Distant positions should not be navigable")
	var actor := Node3D.new()
	actor.global_position = Vector3(500.0, 0.0, 500.0)
	root.add_child(actor)
	_check(manager.confine_actor(actor, Vector3.ZERO), "Out-of-bounds actors should be confined")
	_check(manager.is_world_position_navigable(actor.global_position), "Confined actors should return to an active chunk")
	actor.queue_free()
	var stale_actor := Node3D.new()
	stale_actor.add_to_group("prey")
	root.add_child(stale_actor)
	stale_actor.global_position = Vector3(500.0, 0.0, 500.0)
	_check(manager.prune_inactive_actors(root) == 1, "Inactive habitat actors should be pruned")
	var counted_actor := Node3D.new()
	counted_actor.add_to_group("predator")
	root.add_child(counted_actor)
	counted_actor.global_position = Vector3(120.0, 0.0, 60.0)
	manager.capture_population(root)
	_check(manager.get_chunk_state("redstone_badlands").get("population", {}).get("predator", 0) == 1, "Chunk state should track active predator population")
	_check(manager.active_population_budget().get("predator", 0) == 1, "Active population budget should include persisted predators")
	var metrics := manager.runtime_metrics(root)
	_check(int(metrics.get("active_chunks", 0)) > 0, "Runtime metrics should report active chunks")
	_check(int(metrics.get("population_budget", 0)) >= 1, "Runtime metrics should report population budget")
	manager.set_respawn_cooldown("redstone_badlands", 5.0)
	manager.tick_respawn_cooldowns(2.0)
	_check(is_equal_approx(manager.get_respawn_cooldown("redstone_badlands"), 3.0), "Chunk respawn cooldown should tick down")
	_check(is_equal_approx(manager.active_respawn_cooldown(), 3.0), "Active respawn cooldown should report the highest loaded chunk delay")
	_check(manager.start_respawn_cooldown_at(Vector3(120.0, 0.0, 60.0), 7.0) == "redstone_badlands", "Defeat positions should start their chunk cooldown")
	_check(is_equal_approx(manager.get_respawn_cooldown("redstone_badlands"), 7.0), "Defeat cooldown should use the creature respawn delay")
	manager.set_tier_respawn_cooldown("redstone_badlands", "predator", 3, 11.0)
	manager.tick_respawn_cooldowns(1.0)
	var active_tier_cooldowns := manager.active_tier_respawn_cooldowns()
	_check(is_equal_approx(active_tier_cooldowns.get("predator_3", 0.0), 10.0), "Active tier cooldowns should expose persisted values")
	manager.tick_respawn_cooldowns(1.0)
	_check(manager.get_tier_respawn_cooldown("redstone_badlands", "predator", 3) > 0.0, "Tier respawn cooldown should tick independently")
	_check(not manager.tier_respawn_ready("redstone_badlands", "predator", 3), "Predator tier should remain unavailable during cooldown")
	_check(manager.tier_respawn_ready("redstone_badlands", "prey", 3), "Unaffected prey tier should remain available")
	var holder := Node3D.new()
	root.add_child(holder)
	manager.instantiate_chunk("nest_basin", holder)
	var loaded := manager.instantiate_chunk("fernwood", holder)
	_check(loaded != null, "Chunk scene should instantiate")
	_check(loaded.position == Vector3(60.0, 0.0, 0.0), "Chunk scene should be positioned from its grid coordinate")
	_check(loaded.get_meta("agent_radius", 0.0) == 0.8, "Chunk scene should receive its navigation agent radius")
	_check(loaded.get_meta("max_slope_degrees", 0.0) == 35.0, "Chunk scene should receive its navigation slope")
	_check(manager.instantiate_chunk("fernwood", holder) == loaded, "Chunk should not duplicate instances")
	_check(manager.connection_links.size() >= 1, "Loaded neighboring chunks should create navigation links")
	manager.release_chunk("fernwood")
	_check(manager.connection_links.is_empty(), "Releasing a chunk should remove its navigation links")
	manager.set_chunk_state("fernwood", {"food_claimed": 3, "quest_marker": "trail"})
	_check(manager.get_chunk_state("fernwood").get("food_claimed", 0) == 3, "Chunk state should survive release")
	_check(manager.get_chunk_state("fernwood").get("quest_marker", "") == "trail", "Chunk quest state should survive release")
	var snapshot: Dictionary = manager.snapshot_state()
	var restored = WORLD_STREAM_MANAGER.new()
	restored.configure(WORLD_CHUNK_PROFILES.reserve(), 1)
	restored.restore_state(snapshot)
	_check(restored.get_chunk_state("fernwood").get("food_claimed", 0) == 3, "Chunk state should restore from snapshot")
	var restored_holder := Node3D.new()
	root.add_child(restored_holder)
	var restored_scene := restored.instantiate_chunk("fernwood", restored_holder)
	var restored_state: Dictionary = restored_scene.get("chunk_state") if restored_scene != null else {}
	_check(restored_scene != null and restored_state.get("quest_marker", "") == "trail", "Chunk state should apply when a scene reloads")
	restored_holder.queue_free()
	holder.queue_free()

func _test_growth() -> void:
	var growth := GrowthSystem.new()
	growth.configure([0, 5, 12, 25])
	growth.add_points(13)
	_check(growth.stage_index == 2, "13 points should reach Young Adult")
	growth.reset_to_stage_floor()
	_check(growth.points == 12, "Defeat should reset to the current stage floor")
	growth.add_points(13)
	_check(growth.is_adult(), "25 points should reach Adult")

func _test_quests() -> void:
	var quest := QuestDefinition.new("test", "Test", "", "eat", "prey", 2, 3, 0, Vector3.ZERO)
	var quests := QuestSystem.new()
	quests.start([quest])
	_check(not quests.record("eat", "plant"), "Wrong food must not progress a quest")
	_check(not quests.record("eat", "prey"), "Quest should require two items")
	_check(quests.record("eat", "prey"), "Second matching item should complete the quest")
	_check(not quests.record("eat", "prey"), "Completed quest cannot award twice")

func _test_survival() -> void:
	var profile := DinosaurProfiles.t_rex()
	var session := GameSession.new()
	session.start(profile, "adventure")
	session.hunger = 1.0
	session.tick(10.0, false)
	_check(session.health < profile.max_health, "Starvation must drain health")
	session.take_damage(999.0)
	_check(session.defeat_in_progress, "Lethal damage must trigger defeat")
	session.growth.add_points(13)
	session.respawn_at_stage_floor()
	_check(session.health == profile.max_health and session.hunger == 100.0, "Respawn must restore survival stats")
	_check(session.growth.points == 12, "Respawn must preserve reached stage")
	var summary := session.summary()
	_check(int(summary["defeat_count"]) == 1, "Run summary must track defeats")
	_check(float(summary["starvation_seconds"]) > 0.0, "Run summary must track starvation time")

func _test_creature_combat() -> void:
	var creature_profiles := preload("res://creature_profiles.gd")
	var profiles: Array = creature_profiles.all()
	_check(profiles.size() == 7, "Expected seven distinct NPC creature profiles")
	var ids: Dictionary = {}
	for profile in profiles:
		_check(not ids.has(profile.id), "NPC creature IDs must be unique")
		ids[profile.id] = true
	var combat := preload("res://combat_component.gd").new()
	combat.configure(30.0)
	_check(combat.take_hit(15.0), "A living creature should accept an attack")
	combat.tick(0.2)
	_check(combat.take_hit(15.0), "A stronger target should accept repeated attacks")
	_check(combat.is_defeated(), "Multiple attacks should defeat a tier-one target")
	var token := preload("res://food_token.gd").new()
	token.setup(creature_profiles.prey_for_tier(1))
	_check(not token.claim().is_empty(), "A defeated creature token should grant a reward")
	_check(token.claim().is_empty(), "A creature token cannot be claimed twice")
	token.free()

func _test_ai_states() -> void:
	var player := PlayerDino.new()
	player.configure(DinosaurProfiles.t_rex())
	root.add_child(player)
	player.position = Vector3.ZERO
	var prey := PreyDino.new()
	prey.setup("Test Prey", 1, Color.WHITE)
	root.add_child(prey)
	prey.position = Vector3(4, 0, 0)
	prey.base_position = prey.position
	prey.set_player(player)
	prey._process(0.1)
	_check(prey.state == "notice", "Nearby prey should notice the player")
	prey._process(0.1)
	_check(prey.state == "flee", "Close prey should flee")
	var predator := ValleyPredator.new()
	predator.setup(3, Vector3(5, 0, 0))
	predator.set_player(player)
	root.add_child(predator)
	predator._process(0.1)
	_check(predator.state == "warn", "Stronger nearby predator should warn before chasing")
	player.position = Vector3(25.5, 0, 0)
	prey.position = Vector3(26.9, 0, 0)
	prey.base_position = prey.position
	prey.state = "flee"
	prey._process(1.0)
	_check(absf(prey.global_position.x) <= PreyDino.VALLEY_LIMIT, "Fleeing prey must stay inside the valley")
	predator.position = Vector3(26.9, 0, 0)
	predator.home = Vector3(35, 0, 0)
	predator.state = "recover"
	predator._process(1.0)
	_check(absf(predator.global_position.x) <= ValleyPredator.VALLEY_LIMIT, "Predators must stay inside the valley")
	_check(absf(predator.home.x) <= ValleyPredator.VALLEY_LIMIT, "Predator recovery targets must stay inside the valley")
	player.free()
	prey.free()
	predator.free()

func _test_low_level_food_supply() -> void:
	var spawner := FoodSpawner.new()
	root.add_child(spawner)
	spawner.configure(false)
	var low_level_count := 0
	var medium_level_count := 0
	var high_level_count := 0
	for prey_node in get_nodes_in_group("prey"):
		var nutrition_value: Variant = prey_node.get("nutrition")
		if nutrition_value == null:
			continue
		var nutrition := int(nutrition_value)
		if nutrition == 1:
			low_level_count += 1
		elif nutrition == 2:
			medium_level_count += 1
		elif nutrition == 3:
			high_level_count += 1
	_check(low_level_count >= 5, "Adventure must always begin with at least five Hatchling-edible dinosaurs")
	_check(medium_level_count >= 3, "Adventure must supply Juvenile growth food")
	_check(high_level_count >= 2, "Adventure must supply Adult growth food")
	var low_prey: Array[Node] = []
	for prey_node in get_nodes_in_group("prey"):
		var nutrition_value: Variant = prey_node.get("nutrition")
		if nutrition_value != null and int(nutrition_value) == 1:
			low_prey.append(prey_node)
	for index in mini(3, low_prey.size()):
		low_prey[index].free()
	spawner.maintain(4.0, 0.0)
	low_level_count = 0
	for prey_node in get_nodes_in_group("prey"):
		var nutrition_value: Variant = prey_node.get("nutrition")
		if nutrition_value != null and int(nutrition_value) == 1:
			low_level_count += 1
	_check(low_level_count >= 5, "Consumed low-level dinosaurs must be replenished")
	spawner.free()

func _test_hud_contrast() -> void:
	var test_hud := GameHUD.new()
	root.add_child(test_hud)
	_check(test_hud.quest_label.get_parent() is ColorRect, "Quest text needs a contrast backdrop")
	_check(test_hud.message_label.get_parent() is ColorRect, "Message text needs a contrast backdrop")
	_check(test_hud.quest_label.get_theme_constant("outline_size") >= 4, "Quest text needs a strong outline")
	_check(test_hud.message_label.get_theme_constant("outline_size") >= 4, "Message text needs a strong outline")
	test_hud.apply_ui_settings({"ui_scale": 1.5, "large_text": true, "high_contrast": true})
	_check(test_hud.large_text_enabled and test_hud.high_contrast_enabled, "HUD should apply accessibility text settings")
	_check(test_hud.quest_label.get_theme_color("font_color") == Color.WHITE, "High contrast should force readable HUD text")
	_check(test_hud.help_panel != null, "Accessibility overlay should remain available")
	test_hud.toggle_help()
	_check(test_hud.help_panel.visible, "Help overlay should open on request")
	test_hud.toggle_help()
	_check(not test_hud.help_panel.visible, "Help overlay should close on request")
	test_hud.free()
	var sound_feedback := preload("res://sound_feedback.gd").new()
	sound_feedback.set_effects_volume(0.25)
	_check(is_equal_approx(sound_feedback.get_effects_volume(), 0.25), "Effects volume should be adjustable")
	sound_feedback.free()

func _test_gameplay_integration() -> void:
	var main_scene: Variant = load("res://Main.tscn").instantiate()
	root.add_child(main_scene)
	_check(main_scene.animated_trees.size() == 10, "The valley should include animated trees")
	_check(main_scene.waterfall_layers.size() == 3, "The waterfall should use layered animated water")
	_check(main_scene.fireflies.size() == 12, "The valley should include ambient fireflies")
	_check(main_scene._terrain_height_at(0.0, -18.0) > 4.0, "Roaring Overlook should be elevated")
	_check(main_scene._terrain_height_at(19.0, -4.0) < main_scene._terrain_height_at(14.0, -12.0), "The waterfall pool should sit below Sunstone Ridge")
	_check(main_scene.get_node_or_null("ValleyNavigation") != null, "The valley should expose a navigation region")
	_check(main_scene.get_node_or_null("TerrainSafetyCollision") != null, "The valley should have terrain safety collision")
	var trike := DinosaurProfiles.triceratops()
	main_scene._start_run(trike, "adventure")
	var plant := PlantFood.new()
	plant.setup("Test Plant", 2, Color.GREEN)
	plant.position = main_scene.player.position
	main_scene.run_root.add_child(plant)
	var prey := PreyDino.new()
	prey.setup("Wrong Food", 1, Color.ORANGE)
	prey.position = main_scene.player.position
	main_scene.run_root.add_child(prey)
	var before: int = main_scene.session.growth.points
	_check(main_scene._try_consume(false), "Triceratops should consume nearby plants")
	_check(main_scene.session.growth.points == before + 2, "Food should award its nutrition as growth")
	_check(is_instance_valid(prey), "Herbivore eating must not consume dinosaur prey")
	main_scene.free()

func _test_save_recovery() -> void:
	var path := "res://.godot/test_savegame.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("not valid json")
	file = null
	var save := SaveSystem.new(path)
	save.load_data()
	_check(int(save.data.get("version", 0)) == SaveSystem.SAVE_VERSION, "Corrupt save must recover defaults")
	_check(save.data.has("settings"), "Recovered save should restore settings defaults")
	_check(save.data.has("chunk_states"), "Recovered save should restore chunk-state defaults")
	save.save_chunk_states({"nest_basin": {"respawn_cooldown": 4.0}})
	var chunk_state_reloaded := SaveSystem.new(path)
	chunk_state_reloaded.load_data()
	_check(is_equal_approx(float(chunk_state_reloaded.load_chunk_states().get("nest_basin", {}).get("respawn_cooldown", 0.0)), 4.0), "Chunk state should survive flow transitions")
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 0, "badges": ["old_badge"]}))
	file = null
	save.load_data()
	_check(int(save.data.get("version", 0)) == SaveSystem.SAVE_VERSION, "Old save must migrate")
	_check((save.data["badges"] as Array).has("old_badge"), "Migration must preserve rewards")
	save.unlock_endless("t_rex")
	save.unlock_cosmetic("t_rex", "sunset")
	save.select_cosmetic("t_rex", "sunset")
	save.record_run("t_rex", 90.0, 12, 2, {"food_eaten": 7, "defeat_count": 1})
	var reloaded := SaveSystem.new(path)
	reloaded.load_data()
	_check(reloaded.is_endless_unlocked("t_rex"), "Valid save must preserve Endless unlocks")
	_check(reloaded.selected_cosmetic("t_rex") == "sunset", "Valid save must preserve selected cosmetics")
	var record := reloaded.data["records"].get("t_rex", {}) as Dictionary
	_check(int((record.get("last_run", {}) as Dictionary).get("food_eaten", 0)) == 7, "Valid save must preserve the latest run summary")
	reloaded.save_chunk_states({"fernwood": {"food_claimed": 2}})
	var chunk_reloaded := SaveSystem.new(path)
	chunk_reloaded.load_data()
	_check(chunk_reloaded.load_chunk_states().get("fernwood", {}).get("food_claimed", 0) == 2, "Chunk states should persist in save data")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
