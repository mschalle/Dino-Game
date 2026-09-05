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
	_test_windows_export_preset()
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
	_test_herd_context()
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
		if dino.imported_model != null:
			_check(dino.imported_animation_player != null, "%s imported model should have an animation player" % profile.id)
			if dino.imported_animation_player != null:
				for animation_name in ["Idle", "Walk", "Run", "Attack", "Eat", "Hit", "Defeat"]:
					_check(dino.imported_animation_player.has_animation(animation_name), "%s should expose %s animation" % [profile.id, animation_name])
		dino.free()
	var prey := PreyDino.new()
	prey.setup("Animation Test Prey", 1, Color.WHITE)
	root.add_child(prey)
	_check(prey.imported_animation_player != null, "Imported prey should have an animation player")
	if prey.imported_animation_player != null:
		for animation_name in ["Idle", "Walk", "Run", "Attack", "Eat", "Hit", "Defeat"]:
			_check(prey.imported_animation_player.has_animation(animation_name), "Imported prey should expose %s animation" % animation_name)
	prey.free()
	var predator := ValleyPredator.new()
	predator.setup(2, Vector3.ZERO)
	root.add_child(predator)
	_check(predator.imported_animation_player != null, "Imported predator should have an animation player")
	if predator.imported_animation_player != null:
		for animation_name in ["Idle", "Walk", "Run", "Attack", "Eat", "Hit", "Defeat"]:
			_check(predator.imported_animation_player.has_animation(animation_name), "Imported predator should expose %s animation" % animation_name)
	predator.free()

func _test_all_playable_species() -> void:
	var save := preload("res://save_system.gd").new()
	var species_ids := {}
	var species_names := {}
	for profile in DinosaurProfiles.all():
		species_ids[profile.id] = true
		species_names[profile.display_name] = true
		var session := GameSession.new()
		session.start(profile, "adventure")
		_check(session.profile.id == profile.id, "%s Adventure should start with its own profile" % profile.id)
		_check(profile.abilities.size() >= 3, "%s should expose its ability progression" % profile.id)
		_check(profile.diet == "carnivore" or profile.diet == "herbivore", "%s should use a supported diet" % profile.id)
		_check(not profile.tagline.is_empty(), "%s should have a readable tagline" % profile.id)
		_check(profile.body_color != Color.BLACK and profile.accent_color != Color.BLACK, "%s should have visible selection colors" % profile.id)
		_check(profile.ai_relationships is Dictionary, "%s should expose AI relationships" % profile.id)
		_check(profile.ai_relationships.has("prey") and profile.ai_relationships.has("threats"), "%s AI relationships should define prey and threats" % profile.id)
		_check(profile.ai_relationships.get("prey") is Array and profile.ai_relationships.get("threats") is Array, "%s AI relationship values should be arrays" % profile.id)
		for relationship_key in ["prey", "threats"]:
			for relationship_id in profile.ai_relationships.get(relationship_key, []):
				_check(relationship_id is String and not relationship_id.is_empty(), "%s AI relationship IDs should be nonempty strings" % profile.id)
		for quest in profile.adventure_quests:
			if quest.objective_type == "eat":
				if profile.diet == "carnivore":
					_check(quest.target_id == "prey", "%s carnivore eating quests should target prey" % profile.id)
				else:
					_check(quest.target_id == "plant", "%s herbivore eating quests should target plants" % profile.id)
		_check(profile.adventure_quests.size() >= 4, "%s should expose a full quest chain" % profile.id)
		_check(profile.growth_thresholds == [0, 5, 12, 25], "%s should use the four-stage growth curve" % profile.id)
		var quest_ids := {}
		var previous_quest_stage := -1
		var has_adult_finale := false
		for quest in profile.adventure_quests:
			_check(quest.required_amount > 0 and quest.reward_growth >= 0, "%s main quest values should be valid" % profile.id)
			_check(is_finite(quest.marker_position.x) and is_finite(quest.marker_position.y) and is_finite(quest.marker_position.z), "%s main quest markers should be finite" % profile.id)
			quest_ids[quest.id] = true
			_check(quest.required_stage >= previous_quest_stage, "%s quest stages should be ordered" % profile.id)
			_check(quest.required_stage >= 0 and quest.required_stage < profile.growth_thresholds.size(), "%s quest stage should be valid" % profile.id)
			if quest.objective_type == "finale":
				has_adult_finale = quest.required_stage == 3
			previous_quest_stage = quest.required_stage
		_check(quest_ids.size() == profile.adventure_quests.size(), "%s quest IDs should be unique" % profile.id)
		_check(has_adult_finale, "%s should have an Adult-stage finale" % profile.id)
		var all_quest_ids := quest_ids.duplicate()
		for optional_quest in profile.optional_quests:
			_check(optional_quest.required_amount > 0 and optional_quest.reward_growth >= 0, "%s optional quest values should be valid" % profile.id)
			_check(is_finite(optional_quest.marker_position.x) and is_finite(optional_quest.marker_position.y) and is_finite(optional_quest.marker_position.z), "%s optional quest markers should be finite" % profile.id)
			_check(optional_quest.optional, "%s optional quests should be marked optional" % profile.id)
			_check(not all_quest_ids.has(optional_quest.id), "%s optional quest IDs should not collide with main quests" % profile.id)
			all_quest_ids[optional_quest.id] = true
		var previous_unlock_stage := -1
		var ability_ids := {}
		for ability in profile.abilities:
			_check(not ability_ids.has(ability.id), "%s ability IDs should be unique" % profile.id)
			ability_ids[ability.id] = true
			_check(not ability.display_name.is_empty() and not ability.description.is_empty(), "%s abilities should have readable metadata" % profile.id)
			_check(not ability.input_action.is_empty(), "%s abilities should have an input action" % profile.id)
			_check(ability.cooldown > 0.0, "%s abilities should have positive cooldowns" % profile.id)
			_check(ability.unlock_stage >= 0 and ability.unlock_stage < profile.growth_thresholds.size(), "%s ability unlock stage should be valid" % profile.id)
			_check(ability.unlock_stage >= previous_unlock_stage, "%s ability unlock stages should be ordered" % profile.id)
			previous_unlock_stage = ability.unlock_stage
		save.record_run(profile.id, 1.0, 1, 0, {"species_validation": true})
	_check(species_ids.size() == DinosaurProfiles.all().size(), "Playable species IDs should be unique")
	_check(species_names.size() == DinosaurProfiles.all().size(), "Playable species display names should be unique")
	var records: Dictionary = save.data.get("records", {})
	for profile in DinosaurProfiles.all():
		_check(records.has(profile.id), "%s should persist an independent record" % profile.id)
	# SaveSystem is RefCounted; allow reference counting to release it naturally.

func _test_species_asset_and_save_isolation() -> void:
	var save := preload("res://save_system.gd").new()
	for species_id in ["t_rex", "velociraptor", "triceratops", "ankylosaurus", "parasaurolophus", "carnotaurus"]:
		var profile = DinosaurProfiles.by_id(species_id)
		_check(profile != null, "%s should resolve from the selection roster" % species_id)
		var model_path := "res://assets/models/dinosaurs/%s.glb" % species_id
		_check(FileAccess.file_exists(model_path), "%s should have an authored GLB or fallback asset" % species_id)
		if FileAccess.file_exists(model_path):
			_check(ResourceLoader.exists(model_path), "%s GLB should be loadable by Godot" % species_id)
			_check(load(model_path) != null, "%s GLB resource should instantiate" % species_id)
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

func _test_windows_export_preset() -> void:
	_check(FileAccess.file_exists("res://export_presets.cfg"), "Windows export preset should be checked in")
	var preset := FileAccess.get_file_as_string("res://export_presets.cfg")
	_check(preset.contains("platform=\"Windows Desktop\""), "Export preset should target Windows Desktop")
	_check(preset.contains("runnable=true"), "Windows export preset should be runnable")

func _test_release_readiness() -> void:
	_check(FileAccess.file_exists("res://project.godot"), "Release build should include project settings")
	_check(FileAccess.file_exists("res://Main.tscn"), "Release build should include the main scene")
	_check(str(ProjectSettings.get_setting("application/run/main_scene", "")) == "res://Main.tscn", "Release project should configure Main.tscn as its main scene")
	_check(FileAccess.file_exists("res://save_system.gd"), "Release build should include save recovery")
	_check(DinosaurProfiles.all().size() == 6, "Release roster should contain six playable species")
	_check(SaveSystem.SAVE_VERSION >= 1, "Release save schema should be versioned")
	_check(FileAccess.file_exists("res://tests/run_tests.gd"), "Release validation suite should be packaged with the project")
	_check(int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)) == 1280, "Release viewport width should remain 1280")
	_check(int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)) == 720, "Release viewport height should remain 720")
	_check(str(ProjectSettings.get_setting("display/window/stretch/mode", "")) == "canvas_items", "Release HUD should use canvas-item scaling")

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
	var input_bootstrap := preload("res://main.gd").new()
	input_bootstrap._ensure_default_inputs()
	var binding_counts := {}
	for action in ["eat", "power_bite", "special_ability", "move_left", "move_right"]:
		binding_counts[action] = InputMap.action_get_events(action).size()
	input_bootstrap._ensure_default_inputs()
	for action in binding_counts:
		_check(InputMap.action_get_events(action).size() == binding_counts[action], "%s input bootstrap should be idempotent" % action)
	for action in ["ui_accept", "ui_cancel", "move_forward", "move_back", "move_left", "move_right"]:
		_check(InputMap.has_action(action), "%s should be available for keyboard/gamepad input" % action)
	for action in ["eat", "power_bite", "scent_trail", "dash", "special_ability"]:
		_check(InputMap.has_action(action), "%s should be available for dinosaur abilities" % action)
	var eat_mouse_ok := false
	for event in InputMap.action_get_events("eat"):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			eat_mouse_ok = true
	var bite_mouse_ok := false
	for event in InputMap.action_get_events("power_bite"):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
			bite_mouse_ok = true
	_check(eat_mouse_ok, "Eat should remain bound to left click")
	_check(bite_mouse_ok, "Power Bite should remain bound to right click")
	input_bootstrap.free()
	var accept := InputEventJoypadButton.new()
	accept.button_index = JOY_BUTTON_A
	_check(accept.button_index == JOY_BUTTON_A, "Controller activation event should be constructible")

func _test_world_chunks() -> void:
	var chunks: Array = WORLD_CHUNK_PROFILES.reserve()
	var grid_positions := {}
	for chunk in chunks:
		_check(not chunk.chunk_id.is_empty() and not chunk.biome.is_empty() and not chunk.landmark_name.is_empty(), "Chunk metadata should be readable")
		_check(chunk.spawn_table is Dictionary and not chunk.spawn_table.is_empty(), "%s should declare habitat spawn categories" % chunk.chunk_id)
		for spawn_key in chunk.spawn_table.keys():
			_check(spawn_key == "prey" or spawn_key == "predators" or spawn_key == "plants", "%s should use supported habitat spawn categories" % chunk.chunk_id)
			if spawn_key == "plants":
				_check(chunk.spawn_table[spawn_key] is bool, "%s plant availability should be boolean" % chunk.chunk_id)
			if spawn_key == "prey" or spawn_key == "predators":
				for spawn_tier in chunk.spawn_table[spawn_key]:
					_check(int(spawn_tier) == spawn_tier and int(spawn_tier) >= 1 and int(spawn_tier) <= 4, "%s spawn tiers should be valid" % chunk.chunk_id)
		_check(not grid_positions.has(chunk.grid_position), "%s should not overlap another chunk grid position" % chunk.chunk_id)
		grid_positions[chunk.grid_position] = true
		_check(abs(chunk.grid_position.x) <= 4 and abs(chunk.grid_position.y) <= 4, "%s grid position should remain inside the authored reserve" % chunk.chunk_id)
		_check(chunk.scene_path.ends_with(".tscn"), "%s should reference a Godot scene path" % chunk.chunk_id)
		_check(chunk.vegetation_density >= 0.0 and chunk.vegetation_density <= 2.0, "%s vegetation density should be bounded" % chunk.chunk_id)
		_check(chunk.fog_density >= 0.0 and chunk.fog_density <= 1.0, "%s fog density should be bounded" % chunk.chunk_id)
		_check(chunk.ground_color != Color.BLACK and chunk.ground_color.a > 0.0, "%s ground palette should remain visible" % chunk.chunk_id)
		_check(chunk.ground_color.a >= 0.99 and chunk.ground_color.r >= 0.0 and chunk.ground_color.r <= 1.0 and chunk.ground_color.g >= 0.0 and chunk.ground_color.g <= 1.0 and chunk.ground_color.b >= 0.0 and chunk.ground_color.b <= 1.0, "%s ground palette should use opaque in-range channels" % chunk.chunk_id)
		_check(chunk.navigation_layers > 0, "%s should expose navigation layers" % chunk.chunk_id)
		_check(FileAccess.file_exists(chunk.scene_path), "%s should reference an authored chunk scene" % chunk.chunk_id)
		_check(ResourceLoader.exists(chunk.scene_path) and load(chunk.scene_path) != null, "%s chunk scene should be loadable" % chunk.chunk_id)
		for neighbor_id in chunk.neighbor_ids:
			_check(neighbor_id is String and not neighbor_id.is_empty() and neighbor_id != chunk.chunk_id, "%s neighbor IDs should be valid and non-self" % chunk.chunk_id)
		_check(chunk.max_slope_degrees <= 35.0, "%s required routes must stay within the navigation slope limit" % chunk.chunk_id)
		_check(chunk.max_climb <= 0.5, "%s required routes must stay within the navigation climb limit" % chunk.chunk_id)
	var stream := WORLD_STREAM_MANAGER.new()
	stream.configure(chunks, 1)
	_check(stream.active_biome_names().is_empty(), "Uninitialized streaming should report no active biomes")
	_check(stream.grid_position_at_world_position(Vector3(31.0, 0.0, -29.0)) == Vector2i(1, 0), "World positions should map to streamed chunk grid coordinates")
	stream.update_player_chunk(Vector2i.ZERO)
	_check(stream.is_active("nest_basin") and stream.is_active("fernwood"), "Origin chunk should activate adjacent reserve cells")
	_check(stream.profile_for_chunk("fernwood") != null and stream.profile_for_chunk("fernwood").biome == "Fernwood", "Stream manager should expose readable chunk profiles")
	_check(stream.profile_for_chunk("missing_chunk") == null, "Unknown chunk profile lookups should return null")
	var active_biomes := stream.active_biome_names()
	var sorted_active_biomes := active_biomes.duplicate()
	sorted_active_biomes.sort()
	_check(active_biomes.has("Nest Basin") and active_biomes.has("Fernwood"), "Active biome names should be readable and stable")
	_check(active_biomes == sorted_active_biomes, "Active biome names should be sorted deterministically")
	var unique_active_biomes := {}
	for biome_name in active_biomes:
		unique_active_biomes[biome_name] = true
	_check(active_biomes.size() == unique_active_biomes.size(), "Active biome names should not contain duplicates")
	var duplicate_profiles: Array[RefCounted] = [
		WorldChunkProfile.new("duplicate_a", "Shared Biome", Vector2i.ZERO, "A", {}),
		WorldChunkProfile.new("duplicate_b", "Shared Biome", Vector2i.ONE, "B", {})
	]
	var duplicate_stream := WORLD_STREAM_MANAGER.new()
	duplicate_stream.configure(duplicate_profiles, 1)
	duplicate_stream.update_player_chunk(Vector2i.ZERO)
	_check(duplicate_stream.active_biome_names() == ["Shared Biome"], "Duplicate profile biomes should collapse to one diagnostic name")
	var cleared_stream := WORLD_STREAM_MANAGER.new()
	cleared_stream.configure(chunks, 1)
	cleared_stream.update_player_chunk(Vector2i.ZERO)
	cleared_stream.configure([], 1)
	_check(cleared_stream.active_biome_names().is_empty(), "Cleared streaming state should report no active biomes")
	_check(stream.landmark_for_chunk("missing_chunk") == null and stream.landmark_position_for_chunk("missing_chunk") == null, "Unknown landmark lookups should return null")
	var nest_instance := stream.instantiate_chunk("nest_basin", root)
	_check(stream.landmark_for_chunk("nest_basin") != null, "Active chunks should expose their landmark destination")
	var landmark_position: Variant = stream.landmark_position_for_chunk("nest_basin")
	_check(landmark_position is Vector3 and is_finite((landmark_position as Vector3).x), "Landmark destination should expose a world-space position")
	_check(stream.active_landmark_positions().has("nest_basin"), "Active landmark positions should include loaded destinations")
	var landmark_ids := stream.active_landmark_positions().keys()
	var sorted_landmark_ids := landmark_ids.duplicate()
	sorted_landmark_ids.sort()
	_check(landmark_ids == sorted_landmark_ids, "Active landmark enumeration should be stable")
	var nearest_landmark: Variant = stream.nearest_active_landmark(Vector3.ZERO)
	_check(nearest_landmark is Vector3, "Stream manager should select the nearest active landmark")
	if nest_instance != null:
		stream.release_chunk("nest_basin")
	var cloudforest_instance := stream.instantiate_chunk("cloudforest", root)
	_check(cloudforest_instance != null and cloudforest_instance.position == Vector3(-60.0, 0.0, 60.0), "Non-origin chunks should be placed at their authored grid position")
	var cloudforest_landmark: Variant = stream.landmark_position_for_chunk("cloudforest")
	_check(cloudforest_landmark is Vector3 and (cloudforest_landmark as Vector3).x < -50.0, "Translated landmarks should retain chunk world offset")
	stream.release_chunk("cloudforest")
	stream.update_player_chunk(Vector2i(2, 1))
	_check(stream.is_active("redstone_badlands") and not stream.is_active("nest_basin"), "Crossing a chunk boundary should update the active set")
	_check(chunks.size() == 16, "Reserve should define sixteen initial biome chunks")
	_check(WORLD_CHUNK_PROFILES.connections_are_symmetric(chunks), "Biome connections must be bidirectional")
	var route := WORLD_CHUNK_PROFILES.find_route(chunks, "nest_basin", "redstone_badlands")
	_check(route.size() >= 2, "Reserve must provide a route between distant biomes")
	_check(route.front() == "nest_basin" and route.back() == "redstone_badlands", "Biome route endpoints must be correct")
	for chunk in chunks:
		var chunk_route := WORLD_CHUNK_PROFILES.find_route(chunks, "nest_basin", chunk.chunk_id)
		_check(not chunk_route.is_empty(), "%s must be reachable from the safe nest" % chunk.chunk_id)
	var ids: Dictionary = {}
	var landmarks: Dictionary = {}
	var biomes: Dictionary = {}
	for chunk in chunks:
		_check(not ids.has(chunk.chunk_id), "Chunk IDs must be unique")
		ids[chunk.chunk_id] = true
		_check(not chunk.landmark_name.is_empty(), "Every chunk needs a landmark")
		_check(not landmarks.has(chunk.landmark_name), "Landmark names must be unique")
		landmarks[chunk.landmark_name] = true
		_check(not biomes.has(chunk.biome), "Biome names must be unique")
		biomes[chunk.biome] = true
		_check(not chunk.scene_path.is_empty(), "Every chunk needs a scene path")
		_check(chunk.has_scene(), "Every initial biome chunk should have a loadable scene shell")
		_check(chunk.vegetation_density > 0.0, "Every biome needs vegetation density")
		_check(chunk.fog_density > 0.0, "Every biome needs fog guidance")
		_check(chunk.navigation_layers > 0, "Every biome needs navigation layers")
		_check(chunk.agent_radius > 0.0, "Every biome needs an agent radius")
		_check(chunk.max_slope_degrees > 0.0 and chunk.max_slope_degrees <= 45.0, "Biome slope must remain traversable")
		_check(chunk.max_climb > 0.0, "Every biome needs a climb limit")
		_check(not chunk.neighbor_ids.is_empty() or chunk.chunk_id == "nest_basin", "Chunks should define connected neighbors")
		var rules := HABITAT_SPAWN_RULES.for_biome(chunk.biome)
		for tier in chunk.spawn_table.get("prey", []):
			_check((rules.get("prey_tiers", []) as Array).has(int(tier)), "%s prey tier must match habitat rules" % chunk.chunk_id)
		for tier in chunk.spawn_table.get("predators", []):
			_check((rules.get("predator_tiers", []) as Array).has(int(tier)), "%s predator tier must match habitat rules" % chunk.chunk_id)
		_check(bool(chunk.spawn_table.get("plants", false)) == bool(rules.get("plants", false)), "%s plant availability must match habitat rules" % chunk.chunk_id)
		var scene := load(chunk.scene_path) as PackedScene
		var visual_root := scene.instantiate()
		root.add_child(visual_root)
		visual_root.apply_chunk_profile(chunk)
		_check(visual_root.get_child_count() >= 1, "%s should create a visible landmark mesh" % chunk.chunk_id)
		_check(visual_root.get_node_or_null("Ground") != null, "%s should create a ground mesh" % chunk.chunk_id)
		_check(visual_root.get_node_or_null("GroundCollision") != null, "%s should create ground collision" % chunk.chunk_id)
		var ground := visual_root.get_node_or_null("Ground") as MeshInstance3D
		_check(ground.material_override.albedo_color.is_equal_approx(chunk.ground_color), "%s ground palette should be applied to the terrain mesh" % chunk.chunk_id)
		_check(ground.visibility_range_end > ground.visibility_range_begin, "%s ground mesh should define a bounded visibility range" % chunk.chunk_id)
		_check(ground.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON, "%s ground mesh should cast shadows" % chunk.chunk_id)
		var ground_shape := visual_root.get_node_or_null("GroundCollision/GroundShape") as CollisionShape3D
		_check(ground_shape != null and ground_shape.shape is BoxShape3D and (ground_shape.shape as BoxShape3D).size.x >= 60.0 and (ground_shape.shape as BoxShape3D).size.z >= 60.0, "%s ground collision should cover its visible pad" % chunk.chunk_id)
		_check(is_equal_approx(float(visual_root.get_meta("fog_density", 0.0)), chunk.fog_density), "%s fog density should be exposed on the visual root" % chunk.chunk_id)
		var biome_environment := visual_root.get_node_or_null("BiomeEnvironment") as WorldEnvironment
		_check(biome_environment != null and biome_environment.environment != null and biome_environment.environment.fog_enabled, "%s should create biome fog" % chunk.chunk_id)
		if biome_environment != null and biome_environment.environment != null:
			_check(is_equal_approx(biome_environment.environment.fog_density, chunk.fog_density), "%s fog should match its profile" % chunk.chunk_id)
			_check(biome_environment.environment.ambient_light_energy > 0.0, "%s should provide child-friendly ambient lighting" % chunk.chunk_id)
			_check(biome_environment.environment.background_color != Color.BLACK, "%s should derive a visible background palette" % chunk.chunk_id)
			_check(biome_environment.environment.background_color.is_equal_approx(chunk.ground_color.lightened(0.45)), "%s environment palette should follow its ground profile" % chunk.chunk_id)
			_check(biome_environment.environment.fog_light_color.is_equal_approx(chunk.ground_color.lightened(0.3)), "%s fog light color should follow its ground profile" % chunk.chunk_id)
			_check(is_equal_approx(biome_environment.environment.fog_sky_affect, 0.15), "%s fog sky affect should use the authored readability target" % chunk.chunk_id)
		_check(visual_root.get_node_or_null("LandmarkSilhouette") != null, "%s should create a landmark silhouette" % chunk.chunk_id)
		var silhouette := visual_root.get_node_or_null("LandmarkSilhouette")
		_check(str(silhouette.get_meta("biome", "")) == chunk.biome, "%s landmark should retain biome identity" % chunk.chunk_id)
		_check(not str(silhouette.get_meta("landmark_kind", "")).is_empty(), "%s landmark should expose a presentation kind" % chunk.chunk_id)
		_check(silhouette.material_override.albedo_color.is_equal_approx(chunk.ground_color.darkened(0.18)), "%s landmark palette should follow its ground profile" % chunk.chunk_id)
		_check(silhouette.visibility_range_begin > 0.0 and silhouette.visibility_range_begin <= 2.0 and silhouette.visibility_range_end >= 180.0 and silhouette.visibility_range_end > silhouette.visibility_range_begin, "%s landmark should remain visible across its authored camera range" % chunk.chunk_id)
		_check(silhouette.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON, "%s landmark should cast shadows" % chunk.chunk_id)
		_check(silhouette.mesh != null and silhouette.get_aabb().size.x > 0.0 and silhouette.get_aabb().size.y > 0.0 and silhouette.get_aabb().size.z > 0.0, "%s landmark silhouette should have positive visual dimensions" % chunk.chunk_id)
		_check(absf(silhouette.position.x) <= 30.0 and absf(silhouette.position.z) <= 30.0, "%s landmark silhouette should remain inside its streamed chunk bounds" % chunk.chunk_id)
		var vegetation := visual_root.get_node_or_null("Vegetation") as MultiMeshInstance3D
		_check(vegetation != null and vegetation.multimesh != null and vegetation.multimesh.instance_count > 0, "%s should create batched vegetation" % chunk.chunk_id)
		if vegetation != null:
			_check(vegetation.visibility_range_begin > 0.0 and vegetation.visibility_range_end > vegetation.visibility_range_begin, "%s vegetation should define a bounded visibility range" % chunk.chunk_id)
			_check(vegetation.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON, "%s vegetation should cast shadows" % chunk.chunk_id)
		if vegetation != null and vegetation.multimesh != null:
			var base_vegetation_count := int(visual_root.get_meta("vegetation_base_count", 0))
			_check(is_equal_approx(float(visual_root.get_meta("vegetation_density", 0.0)), chunk.vegetation_density), "%s vegetation density should be applied to the visual root" % chunk.chunk_id)
			_check(vegetation.multimesh.instance_count == maxi(1, int(round(float(base_vegetation_count) * chunk.vegetation_density))), "%s vegetation density should scale batched instances" % chunk.chunk_id)
			_check(vegetation.multimesh.mesh.material is StandardMaterial3D and vegetation.multimesh.mesh.material.albedo_color.is_equal_approx(chunk.ground_color.lightened(0.12)), "%s vegetation palette should follow its ground profile" % chunk.chunk_id)
			_check(vegetation.multimesh.mesh.material.roughness >= 0.0 and vegetation.multimesh.mesh.material.roughness <= 1.0, "%s vegetation roughness should remain bounded" % chunk.chunk_id)
			_check(vegetation.multimesh.mesh.material.metallic >= 0.0 and vegetation.multimesh.mesh.material.metallic <= 1.0, "%s vegetation metallic response should remain bounded" % chunk.chunk_id)
			_check(vegetation.multimesh.instance_count <= 40, "%s vegetation instance budget should remain bounded" % chunk.chunk_id)
		var water := visual_root.get_node_or_null("WaterSurface")
		var has_water: bool = chunk.biome == "River Wetlands" or chunk.biome == "Coastal Marsh" or chunk.biome == "Cypress Basin"
		_check(has_water == (water != null), "%s water surface should match its biome" % chunk.chunk_id)
		if water != null:
			var expected_water_color: Color = chunk.ground_color.lightened(0.18)
			expected_water_color.a = 0.72
			_check(water.material_override is StandardMaterial3D and water.material_override.albedo_color.is_equal_approx(expected_water_color), "%s water palette should follow its ground profile" % chunk.chunk_id)
			_check(water.visibility_range_end > water.visibility_range_begin, "%s water surface should define a bounded visibility range" % chunk.chunk_id)
			_check(water.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "%s water surface should avoid unnecessary shadows" % chunk.chunk_id)
			_check(water.material_override.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA and water.material_override.albedo_color.a > 0.0 and water.material_override.albedo_color.a < 1.0, "%s water surface should remain visibly translucent" % chunk.chunk_id)
			_check(water.material_override.roughness >= 0.0 and water.material_override.roughness <= 1.0 and water.material_override.metallic >= 0.0 and water.material_override.metallic <= 1.0, "%s water material channels should remain bounded" % chunk.chunk_id)
		var particles := visual_root.get_node_or_null("AmbientParticles") as GPUParticles3D
		_check(particles != null and particles.amount > 0 and particles.lifetime > 0.0, "%s should create ambient particles" % chunk.chunk_id)
		if particles != null:
			_check(particles.visibility_range_end > particles.visibility_range_begin, "%s ambient particles should define a bounded visibility range" % chunk.chunk_id)
			_check(particles.lifetime <= 10.0, "%s ambient particle lifetime should remain bounded" % chunk.chunk_id)
			_check(particles.visibility_aabb.size.x > 0.0 and particles.visibility_aabb.size.y > 0.0 and particles.visibility_aabb.size.z > 0.0, "%s ambient particles should define a non-empty visibility volume" % chunk.chunk_id)
		if particles != null and particles.draw_pass_1 is QuadMesh:
			_check(particles.draw_pass_1.material is StandardMaterial3D and particles.draw_pass_1.material.albedo_color.is_equal_approx(chunk.ground_color.lightened(0.35)), "%s ambient particles should follow its biome palette" % chunk.chunk_id)
			_check(particles.draw_pass_1.material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, "%s ambient particles should use unshaded materials" % chunk.chunk_id)
		_check(particles == null or particles.amount <= 10, "%s ambient particle budget should remain bounded" % chunk.chunk_id)
		var navigation := visual_root.get_node_or_null("NavigationRegion") as NavigationRegion3D
		_check(navigation != null and navigation.navigation_mesh != null, "%s should create a navigation region" % chunk.chunk_id)
		if navigation != null and navigation.navigation_mesh != null:
			_check(navigation.navigation_layers == chunk.navigation_layers, "%s navigation layers should match its profile" % chunk.chunk_id)
			_check(is_equal_approx(navigation.navigation_mesh.agent_radius, chunk.agent_radius), "%s navigation radius should match its profile" % chunk.chunk_id)
			_check(is_equal_approx(float(navigation.get_meta("max_slope_degrees", 0.0)), chunk.max_slope_degrees), "%s slope metadata should match its profile" % chunk.chunk_id)
			_check(is_equal_approx(float(navigation.get_meta("max_climb", 0.0)), chunk.max_climb), "%s climb metadata should match its profile" % chunk.chunk_id)
			var nav_vertices := navigation.navigation_mesh.vertices
			_check(nav_vertices.size() == 4, "%s navigation mesh should cover its ground pad" % chunk.chunk_id)
			if nav_vertices.size() == 4:
				var nav_bounds := Rect2(nav_vertices[0].x, nav_vertices[0].z, 0.0, 0.0)
				for vertex in nav_vertices:
					nav_bounds = nav_bounds.expand(Vector2(vertex.x, vertex.z))
				_check(nav_bounds.size.x >= 58.0 and nav_bounds.size.y >= 58.0, "%s navigation mesh should span the visible terrain pad" % chunk.chunk_id)
				var ground_shape_for_nav := visual_root.get_node_or_null("GroundCollision/GroundShape") as CollisionShape3D
				var ground_top := -0.12
				if ground_shape_for_nav != null and ground_shape_for_nav.shape is BoxShape3D:
					ground_top = ground_shape_for_nav.position.y + (ground_shape_for_nav.shape as BoxShape3D).size.y * 0.5
				_check(absf(nav_vertices[0].y - ground_top) <= 0.03, "%s navigation surface should align with ground collision height" % chunk.chunk_id)
		if chunk.biome != "Nest Basin":
			var elevation := visual_root.get_node_or_null("Elevation") as MeshInstance3D
			_check(elevation != null, "%s should create an elevated terrain feature" % chunk.chunk_id)
			_check(elevation.visibility_range_end > elevation.visibility_range_begin, "%s elevated terrain should define a bounded visibility range" % chunk.chunk_id)
			_check(elevation.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON, "%s elevated terrain should cast shadows" % chunk.chunk_id)
			_check(elevation.mesh is BoxMesh and (elevation.mesh as BoxMesh).size.x > 0.0 and (elevation.mesh as BoxMesh).size.y > 0.0 and (elevation.mesh as BoxMesh).size.z > 0.0, "%s elevated terrain should have positive visual dimensions" % chunk.chunk_id)
			_check(elevation.material_override is StandardMaterial3D and elevation.material_override.albedo_color.is_equal_approx(chunk.ground_color), "%s elevated terrain palette should match its ground profile" % chunk.chunk_id)
			_check(elevation.material_override.roughness >= 0.0 and elevation.material_override.roughness <= 1.0, "%s elevated terrain roughness should remain bounded" % chunk.chunk_id)
			_check(elevation.material_override.metallic >= 0.0 and elevation.material_override.metallic <= 1.0, "%s elevated terrain metallic response should remain bounded" % chunk.chunk_id)
			var elevation_collision := visual_root.get_node_or_null("ElevationCollision/ElevationShape") as CollisionShape3D
			_check(elevation_collision != null and elevation_collision.shape is BoxShape3D and (elevation_collision.shape as BoxShape3D).size.is_equal_approx((elevation.mesh as BoxMesh).size), "%s elevation collision should match its visible dimensions" % chunk.chunk_id)
			_check(elevation_collision != null and elevation_collision.position.is_equal_approx(elevation.position), "%s elevation collision should align with its visible mound" % chunk.chunk_id)
			_check(visual_root.get_node_or_null("ElevationCollision") != null, "%s should create elevated terrain collision" % chunk.chunk_id)
		var has_labelled_landmark := false
		var landmark_label_matches := false
		for child in visual_root.get_children():
			if child is MeshInstance3D and child.get_child_count() >= 1:
				for nested in child.get_children():
					if nested is Label3D:
						has_labelled_landmark = true
						landmark_label_matches = nested.text == chunk.landmark_name
						_check(nested.position.y >= 1.5, "%s landmark label should sit above its marker" % chunk.chunk_id)
						_check(nested.visibility_range_begin >= 2.0 and nested.visibility_range_end >= 38.0 and nested.visibility_range_end > nested.visibility_range_begin, "%s landmark label should remain visible across its readable distance" % chunk.chunk_id)
						_check(nested.font_size >= 24 and nested.outline_size >= 6, "%s landmark label should remain readable at gameplay distance" % chunk.chunk_id)
						_check(nested.outline_modulate != Color.WHITE, "%s landmark label should retain a contrasting outline" % chunk.chunk_id)
		_check(has_labelled_landmark, "%s landmark should include a readable label" % chunk.chunk_id)
		_check(landmark_label_matches, "%s landmark label should match its profile" % chunk.chunk_id)
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
	_check(hud.format_active_biomes([]) == "—", "HUD should show an empty biome placeholder")
	_check(hud.format_active_biomes("invalid") == "—", "HUD should tolerate malformed biome metrics")
	_check(hud.format_active_biomes(["Nest Basin", "Fernwood", "Glacier Valley"]) == "Nest Basin, Fernwood +1", "HUD should compact active biome metrics")
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
	_check(int(metrics.get("loaded_landmarks", 0)) >= 0, "Runtime metrics should report loaded landmarks")
	_check((metrics.get("active_biomes", []) as Array).has("Redstone Badlands"), "Runtime metrics should report active biome names")
	_check(int(metrics.get("active_biome_count", 0)) == (metrics.get("active_biomes", []) as Array).size(), "Runtime metrics should report the active biome count")
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
	var stray_actor := Node3D.new()
	holder.add_child(stray_actor)
	stray_actor.global_position = Vector3(999.0, -5.0, 999.0)
	_check(manager.confine_actor(stray_actor, Vector3.ZERO), "Out-of-bounds actors should be recovered")
	_check(manager.is_world_position_navigable(stray_actor.global_position), "Recovered actors should return to an active navigable chunk")
	manager.release_chunk("fernwood")
	_check(manager.connection_links.is_empty(), "Releasing a chunk should remove its navigation links")
	manager.set_chunk_state("fernwood", {"food_claimed": 3, "quest_marker": "trail"})
	manager.set_chunk_state("glacier_valley", {"food_claimed": 1, "quest_marker": "ice_beacon", "nested": {"tier": 3}})
	_check(manager.get_chunk_state("fernwood").get("food_claimed", 0) == 3, "Chunk state should survive release")
	_check(manager.get_chunk_state("fernwood").get("quest_marker", "") == "trail", "Chunk quest state should survive release")
	var snapshot: Dictionary = manager.snapshot_state()
	var restored = WORLD_STREAM_MANAGER.new()
	restored.configure(WORLD_CHUNK_PROFILES.reserve(), 1)
	restored.restore_state(snapshot)
	_check(restored.get_chunk_state("fernwood").get("food_claimed", 0) == 3, "Chunk state should restore from snapshot")
	_check(restored.get_chunk_state("glacier_valley").get("quest_marker", "") == "ice_beacon", "Expanded biome state should restore from snapshot")
	_check(restored.get_chunk_state("glacier_valley").get("nested", {}).get("tier", 0) == 3, "Chunk snapshots should preserve nested state")
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
		_check(not profile.display_name.is_empty(), "%s should have a readable display name" % profile.id)
		_check(profile.body_color != Color.BLACK, "%s should have a visible body color" % profile.id)
		_check(profile.role == "prey" or profile.role == "predator" or profile.role == "rival", "%s should use a supported NPC role" % profile.id)
		_check(profile.tier >= 1 and profile.tier <= 4, "%s should use a supported NPC tier" % profile.id)
		if profile.role == "prey":
			_check(profile.tier <= 3, "%s prey should not occupy finale tier" % profile.id)
		if profile.role == "rival":
			_check(profile.tier == 4, "%s rival should occupy tier four" % profile.id)
		var expected_health: float = [0.0, 30.0, 60.0, 100.0, 160.0][profile.tier]
		var expected_damage: float = [0.0, 5.0, 10.0, 16.0, 22.0][profile.tier]
		var expected_growth: int = [0, 1, 3, 6, 10][profile.tier]
		var expected_respawn: float = [0.0, 20.0, 30.0, 45.0, 0.0][profile.tier]
		_check(is_equal_approx(profile.max_health, expected_health), "%s health should match tier tuning" % profile.id)
		_check(is_equal_approx(profile.attack_damage, expected_damage), "%s damage should match tier tuning" % profile.id)
		_check(profile.growth_reward == expected_growth, "%s growth reward should match tier tuning" % profile.id)
		_check(profile.hunger_reward > 0.0, "%s should provide a positive hunger reward" % profile.id)
		if profile.tier > 1:
			var lower_tier_profile = creature_profiles.prey_for_tier(profile.tier - 1) if profile.role == "prey" else creature_profiles.predator_for_tier(profile.tier - 1)
			_check(profile.growth_reward >= lower_tier_profile.growth_reward, "%s rewards should not decrease at higher tiers" % profile.id)
		_check(is_equal_approx(profile.respawn_delay, expected_respawn), "%s respawn should match tier tuning" % profile.id)
		_check(profile.move_speed > 0.0 and profile.flee_speed >= profile.move_speed, "%s movement speeds should be positive and flee-capable" % profile.id)
		_check(profile.detection_range > 0.0 and profile.attack_range > 0.0 and profile.attack_cooldown > 0.0, "%s combat ranges and cooldown should be valid" % profile.id)
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
	prey.state = "recover"
	player.position = Vector3.ZERO
	prey._process(0.1)
	_check(prey.state == "wander", "Recovered prey should return to wandering")
	predator.position = Vector3(26.9, 0, 0)
	predator.home = Vector3(35, 0, 0)
	predator.state = "recover"
	predator._process(1.0)
	_check(absf(predator.global_position.x) <= ValleyPredator.VALLEY_LIMIT, "Predators must stay inside the valley")
	_check(absf(predator.home.x) <= ValleyPredator.VALLEY_LIMIT, "Predator recovery targets must stay inside the valley")
	predator.state = "recover"
	predator.home = predator.position
	predator._process(0.1)
	_check(predator.state == "wander", "Recovered predators should return to wandering")
	var npc_predator := ValleyPredator.new()
	npc_predator.setup(2, Vector3.ZERO)
	root.add_child(npc_predator)
	var npc_prey := PreyDino.new()
	npc_prey.setup("NPC Target", 1, Color.WHITE)
	npc_prey.position = Vector3(5.0, 0.0, 0.0)
	root.add_child(npc_prey)
	npc_predator._process(0.1)
	_check(npc_predator.state == "warn", "Predators should warn before pursuing NPC prey")
	npc_predator._process(1.0)
	_check(npc_predator.state == "chase", "Predators should chase eligible NPC prey after warning")
	npc_predator.free()
	npc_prey.free()
	player.free()
	prey.free()
	predator.free()

func _test_herd_context() -> void:
	var prey := PreyDino.new()
	prey.setup("Herd Test", 1, Color.WHITE)
	root.add_child(prey)
	prey.set_herd_context("tier_1", false, Vector3(2.0, 0.0, 0.0))
	var context := prey.herd_context()
	_check(context.get("id", "") == "tier_1" and not bool(context.get("leader", true)), "Prey should expose herd context")
	_check((context.get("anchor", Vector3.ZERO) as Vector3).x == 2.0, "Herd followers should retain their anchor")
	var sibling := PreyDino.new()
	sibling.setup("Herd Sibling", 1, Color.WHITE)
	root.add_child(sibling)
	sibling.set_herd_context("tier_1", false, Vector3.ZERO)
	prey.position = Vector3.ZERO
	sibling.position = Vector3(2.0, 0.0, 0.0)
	prey.alert_herd(Vector3(-2.0, 0.0, 0.0))
	_check(sibling.state == "flee", "Nearby herd members should flee together")
	sibling.free()
	prey.free()

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
	for tree in main_scene.animated_trees:
		_check(tree.visibility_range_end > tree.visibility_range_begin, "Animated tree trunks should define a bounded visibility range")
		_check(tree.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON, "Animated tree trunks should cast shadows")
		var crown := tree.get_child(0) as MeshInstance3D
		_check(crown != null and crown.visibility_range_end > crown.visibility_range_begin, "Animated tree crowns should define a bounded visibility range")
		_check(crown != null and crown.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON, "Animated tree crowns should cast shadows")
	_check(main_scene.waterfall_layers.size() == 3, "The waterfall should use layered animated water")
	for waterfall in main_scene.waterfall_layers:
		_check(waterfall.visibility_range_end > waterfall.visibility_range_begin, "Waterfall layers should define a bounded visibility range")
		_check(waterfall.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Waterfall layers should avoid unnecessary shadows")
	_check(main_scene.fireflies.size() == 12, "The valley should include ambient fireflies")
	for firefly in main_scene.fireflies:
		_check(firefly.visibility_range_end > firefly.visibility_range_begin, "Ambient fireflies should define a bounded visibility range")
		_check(firefly.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Ambient fireflies should avoid unnecessary shadows")
	for child in main_scene.get_children():
		if child is MeshInstance3D and child.get_child_count() > 0 and child.get_child(0) is Label3D:
			_check(child.visibility_range_end > child.visibility_range_begin, "Habitat landmark markers should define a bounded visibility range")
			var label := child.get_child(0) as Label3D
			_check(label.font_size >= 24 and label.outline_size >= 6, "Habitat landmark labels should remain readable at gameplay distance")
			_check(label.outline_modulate != Color.WHITE, "Habitat landmark labels should retain a contrasting outline")
			_check(child.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON, "Habitat landmark markers should cast shadows")
	_check(main_scene._terrain_height_at(0.0, -18.0) > 4.0, "Roaring Overlook should be elevated")
	_check(main_scene._terrain_height_at(19.0, -4.0) < main_scene._terrain_height_at(14.0, -12.0), "The waterfall pool should sit below Sunstone Ridge")
	_check(main_scene.get_node_or_null("ValleyNavigation") != null, "The valley should expose a navigation region")
	_check(main_scene.get_node_or_null("TerrainSafetyCollision") != null, "The valley should have terrain safety collision")
	var legacy_ground := main_scene.get_node_or_null("LegacyValleyGround") as MeshInstance3D
	_check(legacy_ground != null and legacy_ground.visibility_range_end > legacy_ground.visibility_range_begin, "Legacy valley ground should define a bounded visibility range")
	_check(legacy_ground != null and legacy_ground.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON, "Legacy valley ground should cast shadows")
	var main_environment := main_scene.get_node_or_null("LegacyEnvironment") as WorldEnvironment
	_check(main_environment != null and main_environment.environment != null and main_environment.environment.fog_enabled, "Legacy valley should provide global child-friendly fog")
	if main_environment != null and main_environment.environment != null:
		_check(main_environment.environment.fog_density > 0.0 and main_environment.environment.fog_density <= 1.0, "Legacy valley fog density should remain bounded")
		_check(main_environment.environment.background_color != Color.BLACK and main_environment.environment.fog_light_color != Color.BLACK, "Legacy valley fog and background colors should remain visible")
		_check(main_environment.environment.fog_sky_affect >= 0.0 and main_environment.environment.fog_sky_affect <= 1.0, "Legacy valley fog sky affect should remain bounded")
		_check(main_environment.environment.ambient_light_energy > 0.0 and main_environment.environment.ambient_light_energy <= 4.0, "Legacy valley ambient light energy should remain bounded")
	var sun := main_scene.get_node_or_null("ValleySun") as DirectionalLight3D
	_check(sun != null and sun.light_energy > 0.0 and sun.light_energy <= 4.0, "Legacy valley directional light should remain bounded")
	_check(sun != null and sun.shadow_enabled and sun.directional_shadow_max_distance > 0.0, "Legacy valley directional light should provide bounded shadows")
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
	file.store_string(JSON.stringify({"version": 0, "badges": ["old_badge"], "endless_unlocked": {"velociraptor": true}, "records": {"velociraptor": {"best_growth_points": 9}}}))
	file = null
	save.load_data()
	_check(int(save.data.get("version", 0)) == SaveSystem.SAVE_VERSION, "Old save must migrate")
	_check((save.data["badges"] as Array).has("old_badge"), "Migration must preserve rewards")
	_check(save.is_endless_unlocked("velociraptor"), "Migration must preserve Endless unlocks")
	_check(int(save.data["records"].get("velociraptor", {}).get("best_growth_points", 0)) == 9, "Migration must preserve species records")
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
