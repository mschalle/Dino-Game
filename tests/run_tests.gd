extends SceneTree

const WORLD_CHUNK_PROFILES = preload("res://world_chunk_profiles.gd")
const WORLD_STREAM_MANAGER = preload("res://world_stream_manager.gd")
const HABITAT_SPAWN_RULES = preload("res://habitat_spawn_rules.gd")

var failures := 0

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	_test_profiles()
	_test_world_chunks()
	_test_habitat_rules()
	_test_world_streaming()
	_test_growth()
	_test_quests()
	_test_survival()
	_test_creature_combat()
	_test_ai_states()
	_test_low_level_food_supply()
	_test_habitat_food_filter()
	_test_hud_contrast()
	_test_gameplay_integration()
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

func _test_world_chunks() -> void:
	var chunks: Array = WORLD_CHUNK_PROFILES.reserve()
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
	manager.set_respawn_cooldown("redstone_badlands", 5.0)
	manager.tick_respawn_cooldowns(2.0)
	_check(is_equal_approx(manager.get_respawn_cooldown("redstone_badlands"), 3.0), "Chunk respawn cooldown should tick down")
	_check(is_equal_approx(manager.active_respawn_cooldown(), 3.0), "Active respawn cooldown should report the highest loaded chunk delay")
	_check(manager.start_respawn_cooldown_at(Vector3(120.0, 0.0, 60.0), 7.0) == "redstone_badlands", "Defeat positions should start their chunk cooldown")
	_check(is_equal_approx(manager.get_respawn_cooldown("redstone_badlands"), 7.0), "Defeat cooldown should use the creature respawn delay")
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
		var nutrition := int(prey_node.get("nutrition"))
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
		if int(prey_node.get("nutrition")) == 1:
			low_prey.append(prey_node)
	for index in mini(3, low_prey.size()):
		low_prey[index].free()
	spawner.maintain(4.0, 0.0)
	low_level_count = 0
	for prey_node in get_nodes_in_group("prey"):
		if int(prey_node.get("nutrition")) == 1:
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
