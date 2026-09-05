extends Node3D

const PLAYER = preload("res://player.gd")
const FOOD_SPAWNER = preload("res://food_spawner.gd")
const PREDATOR = preload("res://predator.gd")
const HABITAT_SPAWN_RULES = preload("res://habitat_spawn_rules.gd")
const HUD_SCENE = preload("res://game_hud.gd")
const PROFILES = preload("res://dinosaur_profiles.gd")
const SOUND_FEEDBACK = preload("res://sound_feedback.gd")
const FOOD_TOKEN = preload("res://food_token.gd")
const WORLD_CHUNK_PROFILES = preload("res://world_chunk_profiles.gd")
const ENVIRONMENT_QUALITY = preload("res://environment_quality.gd")
const WORLD_STREAM_MANAGER = preload("res://world_stream_manager.gd")
const WORLD_EVENT_SYSTEM = preload("res://world_event_system.gd")
const ENDLESS_CHALLENGE_SYSTEM = preload("res://endless_challenge_system.gd")

const SAFE_SPAWN := Vector3(0, 0, 7)
const VALLEY_LIMIT := 210.0

var save_system := SaveSystem.new()
var session: GameSession
var quest_system: QuestSystem
var profile: DinosaurProfile
var mode := "adventure"
var player: PlayerDino
var camera: Camera3D
var run_root: Node3D
var food_spawner: FoodSpawner
var hud: GameHUD
var selection_screen: CanvasLayer
var selection_adventure_buttons: Array[Button] = []
var active_marker: Node3D
var scent_dots: Array[MeshInstance3D] = []
var quest_props: Array[Node3D] = []
var predators: Array[ValleyPredator] = []
var ability_cooldowns: Dictionary = {}
var scent_timer := 0.0
var shield_timer := 0.0
var endless_round := 0
var endless_second_timer := 0.0
var optional_completed := false
var game_active := false
var controls_overlay: ColorRect
var waiting_rebind := ""
var attack_cooldown := 0.0
var active_target: Node3D
var rebind_buttons: Dictionary = {}
var sounds
var environment_time := 0.0
var valley_sky_material: ProceduralSkyMaterial
var valley_environment: Environment
var animated_trees: Array[MeshInstance3D] = []
var waterfall_layers: Array[MeshInstance3D] = []
var fireflies: Array[MeshInstance3D] = []
var distant_mountains: Array[MeshInstance3D] = []
var world_stream
var chunk_instances: Dictionary = {}
var world_events
var next_endless_event_time := 120.0
var endless_event_index := 0
var endless_challenges
var endless_challenges_completed := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("world_controller")
	randomize()
	_ensure_default_inputs()
	save_system.load_data()
	ENVIRONMENT_QUALITY.configure(save_system.data.get("settings", {}))
	_apply_saved_bindings()
	_create_world()
	world_stream = WORLD_STREAM_MANAGER.new()
	world_stream.configure(WORLD_CHUNK_PROFILES.reserve(), 1)
	world_stream.restore_state(save_system.load_chunk_states())
	world_stream.chunk_activated.connect(_on_chunk_activated)
	world_stream.chunk_deactivated.connect(_on_chunk_deactivated)
	world_stream.update_player_chunk(Vector2i.ZERO)
	sounds = SOUND_FEEDBACK.new()
	add_child(sounds)
	sounds.set_effects_volume(float((save_system.data["settings"] as Dictionary).get("effects_volume", 0.7)))
	_show_selection()

func _process(delta: float) -> void:
	if hud != null:
		hud.record_frame_time(delta)
	environment_time += delta
	_animate_environment(delta)
	if Input.is_action_just_pressed("ui_cancel") and game_active:
		_set_paused(not get_tree().paused)
	if Input.is_action_just_pressed("help") and game_active and hud != null:
		hud.toggle_help()
	if game_active and Input.is_action_just_pressed("volume_down"):
		_adjust_effects_volume(-0.1)
	if game_active and Input.is_action_just_pressed("volume_up"):
		_adjust_effects_volume(0.1)
	if game_active and Input.is_action_just_pressed("environment_quality"):
		_cycle_environment_quality()
	if game_active and Input.is_action_just_pressed("weather_toggle"):
		_toggle_weather()
	if game_active and Input.is_action_just_pressed("reduced_motion"):
		_toggle_reduced_motion()
	if game_active and Input.is_action_just_pressed("day_cycle_toggle"):
		_toggle_day_cycle()
	if not game_active or get_tree().paused:
		return
	_tick_cooldowns(delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	shield_timer = maxf(0.0, shield_timer - delta)
	scent_timer = maxf(0.0, scent_timer - delta)
	_set_scent_visible(scent_timer > 0.0)
	if Input.is_action_just_pressed("eat"):
		_try_consume(false)
	if Input.is_action_just_pressed("power_bite"):
		_use_primary_ability()
	if Input.is_action_just_pressed("scent_trail"):
		_use_scent_trail()
	if Input.is_action_just_pressed("dash"):
		_use_dash()
	if Input.is_action_just_pressed("special_ability"):
		_use_special_ability()
	if Input.is_action_just_pressed("skip_challenge"):
		_skip_endless_challenge()
	var danger_nearby := _danger_nearby()
	session.tick(delta, danger_nearby)
	food_spawner.maintain(delta, session.survival_time)
	_update_world_events(delta)
	_update_objectives(delta)
	_update_endless_difficulty()
	_keep_player_in_valley()
	_ground_world_actors()
	_follow_player(delta)
	_update_hud()
	_update_world_stream()
	if food_spawner != null and world_stream != null:
		world_stream.tick_respawn_cooldowns(delta)
		food_spawner.set_spawn_plan(world_stream.active_spawn_plan())
		food_spawner.set_population_budget(world_stream.active_population_budget())
		food_spawner.set_respawn_cooldown(world_stream.active_respawn_cooldown())
		food_spawner.set_tier_respawn_cooldowns(world_stream.active_tier_respawn_cooldowns())
		world_stream.prune_inactive_actors(self)
		world_stream.capture_population(self)
		food_spawner.set_persisted_herd_records(world_stream.active_herd_records())
		var metrics: Dictionary = world_stream.runtime_metrics(self)
		metrics["environment_quality"] = ENVIRONMENT_QUALITY.active_id
		metrics["weather_enabled"] = ENVIRONMENT_QUALITY.weather_enabled
		metrics["day_cycle_enabled"] = bool((save_system.data.get("settings", {}) as Dictionary).get("day_cycle_enabled", true))
		hud.update_diagnostics(metrics)
	if active_target != null and is_instance_valid(active_target):
		var active_combat = active_target.get("combat")
		if active_combat != null:
			hud.update_target_health(active_combat.health, active_combat.max_health)

func _create_world() -> void:
	var environment := WorldEnvironment.new()
	environment.name = "LegacyEnvironment"
	var env := Environment.new()
	valley_environment = env
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	valley_sky_material = sky_material
	sky_material.sky_top_color = Color("#263d58")
	sky_material.sky_horizon_color = Color("#c2b79f")
	sky_material.ground_bottom_color = Color("#1b242b")
	sky_material.ground_horizon_color = Color("#8f806c")
	sky_material.sun_angle_max = 18.0
	sky.sky_material = sky_material
	env.sky = sky
	env.background_color = Color("#8f806c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#d7d8cb")
	env.ambient_light_energy = 0.62
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.12
	env.ssao_enabled = true
	env.ssao_radius = 2.2
	env.ssao_intensity = 1.25
	env.ssao_power = 1.35
	env.fog_enabled = true
	env.fog_light_color = Color("#a9a18e")
	env.fog_density = 0.0045
	env.fog_sky_affect = 0.32
	env.fog_height = 1.5
	env.fog_height_density = 0.018
	environment.environment = env
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.name = "ValleySun"
	light.rotation_degrees = Vector3(-52, -35, 0)
	light.light_color = Color("#ffe2b0")
	light.light_energy = 1.35
	light.shadow_enabled = true
	light.directional_shadow_max_distance = float(ENVIRONMENT_QUALITY.preset(save_system.data.get("settings", {})).get("shadow_distance", 90.0))
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	light.light_angular_distance = 1.8
	add_child(light)
	var ground := MeshInstance3D.new()
	ground.name = "LegacyValleyGround"
	ground.mesh = _build_valley_mesh()
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	ground.visibility_range_begin = 0.0
	ground.visibility_range_end = 260.0
	ground.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	var terrain_material := _material(Color("#78b957"))
	terrain_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	terrain_material.vertex_color_use_as_albedo = true
	ground.material_override = terrain_material
	add_child(ground)
	_add_authored_hero_valley()
	_create_terrain_collision()
	_create_navigation_region()
	for index in 30:
		_create_scenery_piece(index)
	_create_habitat_landmarks()
	_create_waterfall()
	_create_fireflies()
	_apply_authored_environment_quality()
	_create_distant_mountains()
	_apply_authored_environment_quality()

func _create_distant_mountains() -> void:
	var mountain_material := _material(Color("#4e5c5b"))
	mountain_material.roughness = 1.0
	for index in 8:
		var peak := MeshInstance3D.new()
		peak.name = "DistantMountain_%d" % index
		var mesh := PrismMesh.new()
		mesh.size = Vector3(26.0 + float(index % 3) * 7.0, 18.0 + float(index % 4) * 4.0, 16.0 + float(index % 2) * 5.0)
		peak.mesh = mesh
		var angle := TAU * float(index) / 8.0
		peak.position = Vector3(cos(angle) * 178.0, mesh.size.y * 0.35 - 1.0, sin(angle) * 178.0)
		peak.rotation.y = angle + 0.4
		peak.material_override = mountain_material
		peak.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		peak.visibility_range_begin = 80.0
		peak.visibility_range_end = 320.0
		peak.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		add_child(peak)
		distant_mountains.append(peak)

func _add_authored_hero_valley() -> void:
	var terrain_path := "res://assets/environment/hero_valley.glb"
	if not ResourceLoader.exists(terrain_path):
		return
	var packed := load(terrain_path) as PackedScene
	if packed == null:
		return
	var authored := packed.instantiate() as Node3D
	if authored == null:
		return
	authored.name = "AuthoredHeroValley"
	authored.position = Vector3.ZERO
	add_child(authored)

func _update_world_stream() -> void:
	if world_stream == null or player == null:
		return
	world_stream.update_player_chunk(world_stream.grid_position_at_world_position(player.global_position))

func _on_chunk_activated(chunk_id: String) -> void:
	var instance: Node3D = world_stream.instantiate_chunk(chunk_id, self)
	if instance != null:
		chunk_instances[chunk_id] = instance
		if game_active and hud != null:
			var chunk_profile: RefCounted = world_stream.profile_for_chunk(chunk_id)
			if chunk_profile != null:
				hud.show_message("Entering %s" % chunk_profile.biome)
				if sounds != null:
					sounds.play_environment_cue(chunk_profile.biome)
					sounds.play_landmark_discovery()

func _on_chunk_deactivated(chunk_id: String) -> void:
	_cancel_world_event("the habitat unloaded")
	world_stream.release_chunk(chunk_id)
	chunk_instances.erase(chunk_id)

func _create_scenery_piece(index: int) -> void:
	var piece := MeshInstance3D.new()
	piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	piece.visibility_range_begin = 0.0
	piece.visibility_range_end = 170.0
	piece.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	if index % 3 == 0:
		var tree_mesh := CylinderMesh.new()
		tree_mesh.top_radius = 0.16
		tree_mesh.bottom_radius = 0.32
		tree_mesh.height = 2.4
		piece.mesh = tree_mesh
		piece.material_override = _material(Color("#8a6748"))
		piece.position.y = 1.2
		var crown := MeshInstance3D.new()
		var crown_mesh := SphereMesh.new()
		crown_mesh.radius = 0.72
		crown_mesh.height = 1.35
		crown.mesh = crown_mesh
		crown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		crown.visibility_range_begin = 0.0
		crown.visibility_range_end = 170.0
		crown.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		crown.material_override = _material(Color("#5da86a"))
		crown.position.y = 1.35
		piece.add_child(crown)
		piece.set_meta("sway_offset", randf() * TAU)
		animated_trees.append(piece)
	else:
		var rock_mesh := SphereMesh.new()
		rock_mesh.radius = 0.3 + randf() * 0.55
		rock_mesh.height = 0.6 + randf() * 0.55
		piece.mesh = rock_mesh
		piece.material_override = _material(Color("#759177"))
		piece.position.y = 0.25
	piece.position.x = randf_range(-26, 26)
	piece.position.z = randf_range(-26, 26)
	add_child(piece)

func _create_waterfall() -> void:
	for index in 3:
		var waterfall := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.68, 4.0 - index * 0.25, 0.18)
		waterfall.mesh = mesh
		waterfall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		waterfall.visibility_range_begin = 0.0
		waterfall.visibility_range_end = 150.0
		waterfall.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		waterfall.material_override = _glow_material(Color("#72d8f2").lightened(index * 0.04))
		waterfall.position = Vector3(18.3 + index * 0.72, 2.0 - index * 0.12, -4)
		waterfall.set_meta("flow_offset", float(index) * 1.7)
		add_child(waterfall)
		waterfall_layers.append(waterfall)

func _create_habitat_landmarks() -> void:
	var landmarks: Array[Array] = [["Nest", Vector3(-15, 0, -12), Color("#e8bd72")], ["Meadow", Vector3(-13, 0, 11), Color("#83d36b")], ["Ridge", Vector3(0, 0, -18), Color("#e7a65c")], ["Arena", Vector3(16, 0, 16), Color("#d97868")]]
	for landmark in landmarks:
		var marker := MeshInstance3D.new()
		var pillar := CylinderMesh.new()
		pillar.top_radius = 0.18
		pillar.bottom_radius = 0.42
		pillar.height = 2.4
		marker.mesh = pillar
		marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		marker.visibility_range_begin = 0.0
		marker.visibility_range_end = 180.0
		marker.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		marker.material_override = _glow_material(landmark[2])
		var point: Vector3 = landmark[1]
		marker.position = Vector3(point.x, _terrain_height_at(point.x, point.z) + 1.2, point.z)
		add_child(marker)
		var label := Label3D.new()
		label.text = str(landmark[0])
		label.position = Vector3(0.0, 1.7, 0.0)
		label.font_size = 32
		label.outline_size = 8
		label.modulate = Color.WHITE
		label.outline_modulate = Color("#163342")
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.visibility_range_begin = 4.0
		label.visibility_range_end = 42.0
		marker.add_child(label)

func _create_fireflies() -> void:
	for index in 12:
		var firefly := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.045
		mesh.height = 0.09
		firefly.mesh = mesh
		firefly.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		firefly.visibility_range_begin = 0.0
		firefly.visibility_range_end = 70.0
		firefly.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		firefly.material_override = _glow_material(Color("#fff3a6"))
		firefly.position = Vector3(randf_range(-24, 24), randf_range(1.0, 3.5), randf_range(-24, 24))
		firefly.set_meta("orbit", randf() * TAU)
		add_child(firefly)
		fireflies.append(firefly)

func _animate_environment(delta: float) -> void:
	var settings: Dictionary = save_system.data.get("settings", {})
	if bool(settings.get("day_cycle_enabled", true)):
		var sun := get_node_or_null("ValleySun") as DirectionalLight3D
		if sun != null:
			var cycle := fmod(environment_time, 240.0) / 240.0
			var arc := sin(cycle * TAU) * 0.5 + 0.5
			sun.rotation_degrees = Vector3(-28.0 - arc * 38.0, -35.0 + cycle * 24.0, 0.0)
			sun.light_energy = 0.72 + arc * 0.65
			if valley_sky_material != null:
				var dawn := Color("#d28d78").lerp(Color("#263d58"), arc)
				valley_sky_material.sky_top_color = dawn.darkened(0.12)
				valley_sky_material.sky_horizon_color = Color("#e0b28c").lerp(Color("#c2b79f"), arc)
			if valley_environment != null:
				valley_environment.fog_light_color = Color("#7b6472").lerp(Color("#a9a18e"), arc)
				valley_environment.fog_density = 0.0062 - arc * 0.002
	if not ENVIRONMENT_QUALITY.reduced_motion:
		for tree in animated_trees:
			if is_instance_valid(tree):
				tree.rotation.z = sin(environment_time * 0.8 + float(tree.get_meta("sway_offset", 0.0))) * 0.045
		for waterfall in waterfall_layers:
			if is_instance_valid(waterfall):
				var flow := sin(environment_time * 3.0 + float(waterfall.get_meta("flow_offset", 0.0)))
				waterfall.position.y = 2.0 + flow * 0.1
				waterfall.scale.y = 1.0 + flow * 0.035
				var material := waterfall.material_override as StandardMaterial3D
				if material != null:
					material.emission_energy_multiplier = 1.55 + (flow + 1.0) * 0.25
		for firefly in fireflies:
			if is_instance_valid(firefly):
				var orbit := float(firefly.get_meta("orbit", 0.0))
				firefly.position.y += sin(environment_time * 1.5 + orbit) * 0.002
				var glow := 0.7 + (sin(environment_time * 3.0 + orbit) + 1.0) * 0.45
				firefly.scale = Vector3.ONE * glow
	if not ENVIRONMENT_QUALITY.reduced_motion and active_marker != null and is_instance_valid(active_marker):
		active_marker.rotation.y += 0.9 * delta
		var ring := active_marker.get_child(0) as MeshInstance3D
		var beacon := active_marker.get_child(1) as MeshInstance3D
		if ring != null:
			ring.position.y = 0.2 + sin(environment_time * 2.0) * 0.06
		if beacon != null:
			beacon.position.y = 2.5 + sin(environment_time * 2.0) * 0.2
	if not ENVIRONMENT_QUALITY.reduced_motion:
		for dot in scent_dots:
			if is_instance_valid(dot) and dot.visible:
				var pulse := 0.85 + sin(environment_time * 5.0 + dot.global_position.length()) * 0.15
				dot.scale = Vector3.ONE * pulse

func _show_selection() -> void:
	selection_screen = CanvasLayer.new()
	selection_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(selection_screen)
	var panel := ColorRect.new()
	panel.color = Color("#18304b")
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	selection_screen.add_child(panel)
	var title := Label.new()
	title.text = "ROAR & RISE\nChoose Your Adventure"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(290, 58)
	title.size = Vector2(700, 100)
	title.add_theme_font_size_override("font_size", 38)
	panel.add_child(title)
	var card_scroll := ScrollContainer.new()
	card_scroll.position = Vector2(0, 170)
	card_scroll.size = Vector2(1280, 430)
	card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(card_scroll)
	var card_content := Control.new()
	card_content.custom_minimum_size = Vector2(1280, 820)
	card_scroll.add_child(card_content)
	var profiles := PROFILES.all()
	selection_adventure_buttons.clear()
	for index in profiles.size():
		var species_profile: DinosaurProfile = profiles[index]
		_create_species_card(card_content, species_profile, index)
	_wire_selection_focus()
	var footer := Label.new()
	footer.text = "Adventure unlocks Endless Survival for each dinosaur.   |   F1: How to Play\n%s" % _collection_summary()
	footer.position = Vector2(290, 625)
	footer.size = Vector2(700, 40)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 18)
	panel.add_child(footer)
	var controls_button := Button.new()
	controls_button.text = "Controls & Remapping"
	controls_button.position = Vector2(490, 670)
	controls_button.size = Vector2(300, 40)
	controls_button.pressed.connect(_show_controls_overlay)
	panel.add_child(controls_button)

func _collection_summary() -> String:
	var unlocked := 0
	var badges := (save_system.data["badges"] as Array).size()
	var cosmetics := save_system.data["cosmetics"] as Dictionary
	for species_id in cosmetics:
		unlocked += (cosmetics[species_id] as Array).size()
	return "Collection: %d color%s unlocked  |  %d badge%s earned" % [unlocked, "" if unlocked == 1 else "s", badges, "" if badges == 1 else "s"]
func _input(event: InputEvent) -> void:
	if waiting_rebind.is_empty():
		return
	var accepted := event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton
	if not accepted or not event.is_pressed():
		return
	for existing in InputMap.action_get_events(waiting_rebind):
		if (event is InputEventKey and existing is InputEventKey) or (event is InputEventMouseButton and existing is InputEventMouseButton) or (event is InputEventJoypadButton and existing is InputEventJoypadButton):
			InputMap.action_erase_event(waiting_rebind, existing)
	InputMap.action_add_event(waiting_rebind, event)
	var settings := save_system.data["settings"] as Dictionary
	var bindings: Dictionary = settings.get("bindings", {})
	bindings[waiting_rebind] = _serialize_input_event(event)
	settings["bindings"] = bindings
	save_system.save_data()
	var button := rebind_buttons.get(waiting_rebind) as Button
	if button != null:
		button.text = "%s: %s" % [_action_label(waiting_rebind), _event_name(event)]
	waiting_rebind = ""
	get_viewport().set_input_as_handled()

func _show_controls_overlay() -> void:
	if controls_overlay != null and is_instance_valid(controls_overlay):
		return
	controls_overlay = ColorRect.new()
	controls_overlay.color = Color(0.02, 0.05, 0.08, 0.98)
	controls_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	selection_screen.add_child(controls_overlay)
	var title := Label.new()
	title.text = "CONTROLS — Choose an action, then press a new key or button"
	title.position = Vector2(240, 75)
	title.size = Vector2(800, 55)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	controls_overlay.add_child(title)
	rebind_buttons.clear()
	var actions: Array[String] = ["move_forward", "move_back", "move_left", "move_right", "sprint", "eat", "power_bite", "scent_trail", "dash", "special_ability"]
	for index in actions.size():
		var action := actions[index]
		var button := Button.new()
		button.text = "%s: %s" % [_action_label(action), _primary_event_name(action)]
		button.position = Vector2(360 + (index % 2) * 310, 155 + (index / 2) * 70)
		button.size = Vector2(280, 48)
		button.pressed.connect(func() -> void:
			waiting_rebind = action
			button.text = "%s: Press input..." % _action_label(action)
		)
		controls_overlay.add_child(button)
		rebind_buttons[action] = button
	var close_button := Button.new()
	close_button.text = "Done"
	close_button.position = Vector2(490, 560)
	close_button.size = Vector2(300, 52)
	close_button.pressed.connect(func() -> void:
		waiting_rebind = ""
		controls_overlay.queue_free()
		controls_overlay = null
	)
	controls_overlay.add_child(close_button)

func _apply_saved_bindings() -> void:
	var settings := save_system.data["settings"] as Dictionary
	var bindings: Dictionary = settings.get("bindings", {})
	for action in bindings:
		if not InputMap.has_action(action):
			continue
		var event := _deserialize_input_event(bindings[action] as Dictionary)
		if event == null:
			continue
		for existing in InputMap.action_get_events(action):
			if (event is InputEventKey and existing is InputEventKey) or (event is InputEventMouseButton and existing is InputEventMouseButton) or (event is InputEventJoypadButton and existing is InputEventJoypadButton):
				InputMap.action_erase_event(action, existing)
		InputMap.action_add_event(action, event)

func _serialize_input_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"type": "key", "code": (event as InputEventKey).physical_keycode}
	if event is InputEventMouseButton:
		return {"type": "mouse", "code": (event as InputEventMouseButton).button_index}
	if event is InputEventJoypadButton:
		return {"type": "joy", "code": (event as InputEventJoypadButton).button_index}
	return {}

func _deserialize_input_event(value: Dictionary) -> InputEvent:
	var event_type := str(value.get("type", ""))
	var code := int(value.get("code", -1))
	if code < 0:
		return null
	if event_type == "key":
		var key_event := InputEventKey.new()
		key_event.physical_keycode = code as Key
		return key_event
	if event_type == "mouse":
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = code as MouseButton
		return mouse_event
	if event_type == "joy":
		var joy_event := InputEventJoypadButton.new()
		joy_event.button_index = code as JoyButton
		return joy_event
	return null

func _primary_event_name(action: String) -> String:
	var events := InputMap.action_get_events(action)
	return "Unbound" if events.is_empty() else _event_name(events[0])

func _event_name(event: InputEvent) -> String:
	if event is InputEventKey:
		return OS.get_keycode_string((event as InputEventKey).physical_keycode)
	if event is InputEventMouseButton:
		return "Mouse %d" % (event as InputEventMouseButton).button_index
	if event is InputEventJoypadButton:
		return "Gamepad %d" % (event as InputEventJoypadButton).button_index
	return event.as_text()

func _action_label(action: String) -> String:
	return action.replace("_", " ").capitalize()

func _create_species_card(parent: Control, species_profile: DinosaurProfile, index: int) -> void:
	var column := index % 3
	var row := index / 3
	var x := 105.0 + column * 390.0
	var card := ColorRect.new()
	card.color = Color(species_profile.body_color, 0.34)
	card.position = Vector2(x, 190.0 + row * 385.0)
	card.size = Vector2(330, 365)
	parent.add_child(card)
	var name_label := Label.new()
	name_label.text = species_profile.display_name.to_upper()
	name_label.position = Vector2(15, 18)
	name_label.size = Vector2(300, 38)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 24)
	card.add_child(name_label)
	var description := Label.new()
	description.text = "%s\nDiet: %s\nHealth: %d  •  Energy: %d" % [species_profile.tagline, species_profile.diet.capitalize(), species_profile.max_health, species_profile.max_energy]
	description.position = Vector2(18, 72)
	description.size = Vector2(294, 105)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.add_theme_font_size_override("font_size", 16)
	card.add_child(description)
	var swatch := ColorRect.new()
	swatch.color = _cosmetic_color(species_profile, save_system.selected_cosmetic(species_profile.id))
	swatch.position = Vector2(305, 178)
	swatch.size = Vector2(14, 20)
	card.add_child(swatch)
	var cosmetic_button := Button.new()
	cosmetic_button.text = "Color: %s" % save_system.selected_cosmetic(species_profile.id).capitalize()
	cosmetic_button.position = Vector2(30, 174)
	cosmetic_button.size = Vector2(270, 28)
	_style_selection_button(cosmetic_button, false)
	cosmetic_button.add_theme_font_size_override("font_size", 14)
	cosmetic_button.pressed.connect(func() -> void:
		_cycle_cosmetic(species_profile.id, cosmetic_button, swatch)
	)
	card.add_child(cosmetic_button)
	var adventure_button := Button.new()
	adventure_button.text = "Play Adventure"
	adventure_button.position = Vector2(30, 205)
	adventure_button.size = Vector2(270, 55)
	_style_selection_button(adventure_button, true)
	adventure_button.add_theme_font_size_override("font_size", 19)
	adventure_button.pressed.connect(func() -> void: _start_run(species_profile, "adventure"))
	selection_adventure_buttons.append(adventure_button)
	card.add_child(adventure_button)
	var endless_button := Button.new()
	var unlocked := save_system.is_endless_unlocked(species_profile.id)
	endless_button.text = "Play Endless" if unlocked else "Endless Locked"
	endless_button.disabled = not unlocked
	endless_button.position = Vector2(30, 277)
	endless_button.size = Vector2(270, 55)
	_style_selection_button(endless_button, true)
	endless_button.add_theme_font_size_override("font_size", 19)
	endless_button.pressed.connect(func() -> void: _start_run(species_profile, "endless"))
	card.add_child(endless_button)

func _wire_selection_focus() -> void:
	for index in selection_adventure_buttons.size():
		var button := selection_adventure_buttons[index]
		button.focus_neighbor_left = selection_adventure_buttons[DinosaurProfiles.selection_neighbor(index, "left")].get_path()
		button.focus_neighbor_right = selection_adventure_buttons[DinosaurProfiles.selection_neighbor(index, "right")].get_path()
		button.focus_neighbor_top = selection_adventure_buttons[DinosaurProfiles.selection_neighbor(index, "up")].get_path()
		button.focus_neighbor_bottom = selection_adventure_buttons[DinosaurProfiles.selection_neighbor(index, "down")].get_path()
	if not selection_adventure_buttons.is_empty():
		selection_adventure_buttons[0].grab_focus()

func _style_selection_button(button: Button, primary: bool) -> void:
	button.focus_mode = Control.FOCUS_ALL
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#274657") if primary else Color("#385a68")
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color("#8bb8c5")
	normal.corner_radius_top_left = 7
	normal.corner_radius_top_right = 7
	normal.corner_radius_bottom_left = 7
	normal.corner_radius_bottom_right = 7
	var focus := normal.duplicate()
	focus.bg_color = Color("#e8bd72")
	focus.border_color = Color.WHITE
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", focus)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color("#102532"))
	button.add_theme_color_override("font_focus_color", Color("#102532"))

func _cycle_cosmetic(species_id: String, button: Button, swatch: ColorRect) -> void:
	var owned: Array = (save_system.data["cosmetics"] as Dictionary).get(species_id, ["default"])
	if owned.is_empty():
		return
	var current := save_system.selected_cosmetic(species_id)
	var next_index := (owned.find(current) + 1) % owned.size()
	save_system.select_cosmetic(species_id, str(owned[next_index]))
	button.text = "Color: %s" % str(owned[next_index]).capitalize()
	var profile_preview := PROFILES.by_id(species_id)
	swatch.color = _cosmetic_color(profile_preview, str(owned[next_index]))

func _cosmetic_color(species_profile: DinosaurProfile, cosmetic: String) -> Color:
	if cosmetic == "sunset":
		return species_profile.body_color.lerp(Color("#f28b61"), 0.55)
	if cosmetic == "mint":
		return species_profile.body_color.lerp(Color("#72e0b0"), 0.5)
	return species_profile.body_color

func _apply_selected_cosmetic() -> void:
	var cosmetic := save_system.selected_cosmetic(profile.id)
	if cosmetic == "sunset":
		profile.body_color = profile.body_color.lerp(Color("#f28b61"), 0.55)
		profile.accent_color = profile.accent_color.lerp(Color("#fff0c2"), 0.35)
	elif cosmetic == "mint":
		profile.body_color = profile.body_color.lerp(Color("#72e0b0"), 0.5)
		profile.accent_color = profile.accent_color.lerp(Color("#d8fff0"), 0.4)

func _start_run(new_profile: DinosaurProfile, new_mode: String) -> void:
	if new_mode == "endless" and not save_system.is_endless_unlocked(new_profile.id):
		return
	profile = new_profile
	_apply_selected_cosmetic()
	mode = new_mode
	if selection_screen != null and is_instance_valid(selection_screen):
		selection_screen.queue_free()
	selection_screen = null
	run_root = Node3D.new()
	run_root.name = "Active Run"
	add_child(run_root)
	session = GameSession.new()
	session.start(profile, mode)
	session.growth.stage_changed.connect(_on_stage_changed)
	session.food_consumed.connect(_on_food_consumed)
	session.player_defeated.connect(_on_player_defeated)
	quest_system = QuestSystem.new()
	quest_system.quest_started.connect(_on_quest_started)
	quest_system.quest_completed.connect(_on_quest_completed)
	quest_system.chain_completed.connect(_on_quest_chain_completed)
	_create_player()
	_create_food_spawner()
	_create_predators()
	_create_scent_dots()
	_create_hud()
	ability_cooldowns.clear()
	optional_completed = false
	endless_round = 0
	endless_second_timer = 0.0
	world_events = WORLD_EVENT_SYSTEM.new()
	next_endless_event_time = 180.0
	endless_event_index = 0
	endless_challenges = ENDLESS_CHALLENGE_SYSTEM.new()
	endless_challenges_completed = 0
	if mode == "adventure":
		quest_system.start(profile.adventure_quests)
	else:
		_start_next_endless_quest()
	game_active = true
	hud.show_message("Explore, eat, grow, and rise!")

func _create_player() -> void:
	player = PLAYER.new()
	player.configure(profile)
	player.position = SAFE_SPAWN
	run_root.add_child(player)
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 68.0
	camera.near = 0.08
	camera.far = 340.0
	camera.position = SAFE_SPAWN + Vector3(0, 5.8, 9.5)
	run_root.add_child(camera)

func _create_food_spawner() -> void:
	food_spawner = FOOD_SPAWNER.new()
	run_root.add_child(food_spawner)
	food_spawner.configure(mode == "endless")
	food_spawner.set_player(player)
	food_spawner.set_respawn_gate_factory(_prey_respawn_ready)
	food_spawner.creature_defeated.connect(_on_creature_defeated)

func _create_predators() -> void:
	predators.clear()
	var predator_data: Array[Array] = [[1, Vector3(-9, 0, 15)], [2, Vector3(-20, 0, -18)], [3, Vector3(19, 0, 19)], [4, Vector3(16, 0, 16)]]
	for data in predator_data:
		if not HABITAT_SPAWN_RULES.allows_tier("Nest Basin", "predator", int(data[0])):
			continue
		var predator := PREDATOR.new()
		predator.setup(int(data[0]), data[1] as Vector3)
		predator.set_player(player)
		predator.set_respawn_gate(func() -> bool: return _predator_respawn_ready(predator))
		predator.bump_attack.connect(_on_predator_attack)
		predator.warning_started.connect(_on_predator_warning)
		predator.attack_landed.connect(_on_predator_attack_landed)
		predator.creature_defeated.connect(_on_creature_defeated)
		run_root.add_child(predator)
		predators.append(predator)

func _predator_respawn_ready(predator: ValleyPredator) -> bool:
	if world_stream == null or predator.creature_profile == null:
		return true
	var chunk_id: String = world_stream.chunk_id_at_world_position(predator.global_position)
	return not chunk_id.is_empty() and world_stream.tier_respawn_ready(chunk_id, "predator", predator.creature_profile.tier)

func _prey_respawn_ready(prey: PreyDino) -> bool:
	if world_stream == null or prey.creature_profile == null:
		return true
	var chunk_id: String = world_stream.chunk_id_at_world_position(prey.global_position)
	return not chunk_id.is_empty() and world_stream.tier_respawn_ready(chunk_id, "prey", prey.creature_profile.tier)

func _create_hud() -> void:
	hud = HUD_SCENE.new()
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud)
	hud.apply_ui_settings(save_system.data.get("settings", {}))
	hud.resume_requested.connect(func() -> void: _set_paused(false))
	hud.restart_requested.connect(func() -> void: call_deferred("_restart_run"))
	hud.selection_requested.connect(func() -> void: call_deferred("_return_to_selection"))

func _try_consume(power_bite: bool) -> bool:
	var reach := 3.2 if power_bite else 2.2
	var closest_token
	var closest_distance := INF
	for token_node in get_tree().get_nodes_in_group("food_token"):
		var token = token_node
		var distance := player.global_position.distance_to(token.global_position)
		if distance < closest_distance:
			closest_token = token
			closest_distance = distance
	if closest_token != null and closest_distance <= reach:
		return _claim_food_token(closest_token)
	if profile.diet == "herbivore":
		closest_distance = INF
		var closest_plant: Node3D
		for plant_node in get_tree().get_nodes_in_group("plant_food"):
			var plant := plant_node as Node3D
			var distance := player.global_position.distance_to(plant.global_position)
			if distance <= reach and distance < closest_distance:
				closest_plant = plant
				closest_distance = distance
		if closest_plant != null:
			player.celebrate_bite()
			session.consume("plant_food", int(closest_plant.get("nutrition")))
			sounds.play_food()
			closest_plant.queue_free()
			return true
	if attack_cooldown > 0.0:
		hud.show_message("Attack ready in %.1f seconds." % attack_cooldown)
		return false
	var target: Node3D
	closest_distance = INF
	for group_name in ["prey", "predator"]:
		for target_node in get_tree().get_nodes_in_group(group_name):
			var candidate := target_node as Node3D
			if not candidate.visible:
				continue
			var distance := player.global_position.distance_to(candidate.global_position)
			if distance < closest_distance:
				target = candidate
				closest_distance = distance
	if target == null or closest_distance > reach:
		hud.show_message("Get closer to a plant, token, or dinosaur.")
		return false
	var damage := (10.0 + player.strength * 5.0) * (1.6 if power_bite else 1.0)
	if not target.receive_attack(damage, player.global_position):
		return false
	attack_cooldown = 0.7
	player.play_combat_animation(power_bite)
	session.record_attack(damage)
	sounds.play_ability()
	var target_profile: Variant = target.get("creature_profile")
	var target_combat: Variant = target.get("combat")
	active_target = target
	hud.show_target(target_profile.display_name, target_profile.tier, target_combat.health, target_combat.max_health)
	_spawn_hit_burst(target.global_position)
	return true

func _spawn_hit_burst(at_position: Vector3) -> void:
	var settings := save_system.data["settings"] as Dictionary
	if bool(settings.get("reduced_flashes", true)):
		return
	var burst := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.18
	mesh.height = 0.36
	burst.mesh = mesh
	burst.material_override = _glow_material(Color("#e8a36e"))
	burst.global_position = at_position + Vector3.UP * 0.8
	run_root.add_child(burst)
	var tween := burst.create_tween()
	tween.tween_property(burst, "scale", Vector3.ONE * 2.2, 0.16)
	tween.tween_property(burst, "modulate:a", 0.0, 0.18)
	tween.tween_callback(burst.queue_free)
	_spawn_impact_decal(at_position)

func _spawn_impact_decal(at_position: Vector3) -> void:
	var decal := Decal.new()
	decal.name = "ImpactMark"
	decal.size = Vector3(0.55, 0.08, 0.55)
	decal.position = at_position + Vector3.UP * 0.03
	decal.modulate = Color(0.42, 0.16, 0.1, 0.48)
	decal.texture_albedo = _impact_texture()
	run_root.add_child(decal)
	var tween := decal.create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(decal, "modulate:a", 0.0, 1.0)
	tween.tween_callback(decal.queue_free)

func _impact_texture() -> Texture2D:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 16:
			var dx := float(x - 8) / 8.0
			var dy := float(y - 8) / 8.0
			var edge: float = clampf(1.0 - (dx * dx + dy * dy), 0.0, 1.0)
			image.set_pixel(x, y, Color(0.35, 0.08, 0.03, edge * 0.72))
	return ImageTexture.create_from_image(image)

func _claim_food_token(token) -> bool:
	var reward: Dictionary = token.claim()
	if reward.is_empty():
		return false
	var hunger_reward := float(reward["hunger"]) if profile.diet == "carnivore" else 0.0
	session.claim_creature_reward(str(reward["species_id"]), int(reward["tier"]), int(reward["growth"]), hunger_reward)
	var quest := quest_system.current()
	if str(reward["species_id"]) == "allosaurus" and quest != null and quest.objective_type == "finale" and quest.target_id == "valley_rival" and session.growth.is_adult():
		quest_system.record("finale", "valley_rival")
	hud.show_message("Victory token! +%d Growth Points" % int(reward["growth"]))
	sounds.play_food()
	token.queue_free()
	return true

func _on_creature_defeated(creature: Node3D, creature_profile: RefCounted) -> void:
	if world_stream != null:
		var defeated_chunk: String = world_stream.start_respawn_cooldown_at(creature.global_position, creature_profile.respawn_delay)
		var role := "predator" if creature_profile.role == "predator" else "prey"
		if not defeated_chunk.is_empty():
			world_stream.set_tier_respawn_cooldown(defeated_chunk, role, creature_profile.tier, creature_profile.respawn_delay)
	var token := FOOD_TOKEN.new()
	token.setup(creature_profile)
	token.global_position = creature.global_position
	run_root.add_child(token)
	session.record_target_defeated(creature_profile.id, creature_profile.tier)
	hud.show_message("%s dropped a glowing victory token!" % creature_profile.display_name)

func _use_primary_ability() -> void:
	var ability := profile.ability_by_action("power_bite", session.growth.stage_index)
	if ability == null:
		_show_locked_ability("power_bite")
		return
	if not _ability_ready(ability):
		return
	if ability.id == "power_bite":
		if not _try_consume(true):
			return
	elif ability.id == "horn_push":
		var moved := 0
		for prey_node in get_tree().get_nodes_in_group("prey"):
			var prey := prey_node as PreyDino
			if player.global_position.distance_to(prey.global_position) <= 3.2:
				prey.base_position += player.facing * 4.0
				moved += 1
		if moved > 0:
			hud.show_message("Horn Push! Nearby dinosaurs made room.")
		else:
			hud.show_message("Horn Push clears the path!")
		_record_ability_objective(ability)
	_start_cooldown(ability)
	sounds.play_ability()

func _use_dash() -> void:
	var ability := profile.ability_by_action("dash", session.growth.stage_index)
	if ability == null:
		return
	if not _ability_ready(ability):
		return
	if player.try_dash(true):
		_start_cooldown(ability)
		sounds.play_ability()
		hud.show_message("Dash!")

func _use_special_ability() -> void:
	var ability := profile.ability_by_action("special_ability", session.growth.stage_index)
	if ability == null:
		_show_locked_ability("special_ability")
		return
	if not _ability_ready(ability):
		return
	if ability.id == "roar":
		for predator in predators:
			if player.global_position.distance_to(predator.global_position) < 10.0:
				predator.scare_away()
		hud.show_message("ROAR! The valley heard you!")
	elif ability.id == "pack_call":
		hud.show_message("Your friendly pack answers from across the valley!")
	elif ability.id == "shield":
		shield_timer = 5.0
		hud.show_message("Shield Stance active for 5 seconds!")
	_record_ability_objective(ability)
	_start_cooldown(ability)
	sounds.play_ability()

func _use_scent_trail() -> void:
	var ability := profile.ability_by_action("scent_trail", session.growth.stage_index)
	if ability == null:
		_show_locked_ability("scent_trail")
		return
	if not _ability_ready(ability):
		return
	var target := _scent_target()
	if target == Vector3.ZERO:
		hud.show_message("No scent trail is available right now.")
		return
	for index in scent_dots.size():
		var fraction := float(index + 1) / float(scent_dots.size() + 1)
		scent_dots[index].global_position = player.global_position.lerp(target, fraction)
		scent_dots[index].global_position.y = 0.55
	scent_timer = 6.0 if profile.id == "velociraptor" else 4.5
	_set_scent_visible(true)
	_start_cooldown(ability)
	hud.show_message("Scent Trail is showing the way!")
	sounds.play_ability()

func _record_ability_objective(ability: AbilityDefinition) -> void:
	var quest := quest_system.current()
	if quest == null or quest.objective_type != "ability" or quest.target_id != ability.id:
		return
	if not _near_active_marker():
		hud.show_message("Use %s at the glowing quest marker." % ability.display_name)
		return
	quest_system.record("ability", ability.id)

func _on_food_consumed(food_id: String, growth_awarded: int) -> void:
	var target_id := "plant" if food_id == "plant_food" else "prey"
	quest_system.record("eat", target_id)
	hud.show_message("Yum! +%d Growth Point%s" % [growth_awarded, "" if growth_awarded == 1 else "s"])

func _on_stage_changed(stage_index: int, stage_name: String) -> void:
	player.strength = profile.base_strength + stage_index
	var scales: Array[float] = [1.0, 1.2, 1.45, 1.75]
	player.grow_to(scales[stage_index])
	sounds.play_growth()
	for ability in profile.abilities:
		if ability.unlock_stage == stage_index:
			save_system.unlock_ability(profile.id, ability.id)
			hud.show_message("You reached %s! %s unlocked." % [stage_name, ability.display_name])

func _on_quest_started(quest: QuestDefinition) -> void:
	_clear_quest_objects()
	if quest.marker_position != Vector3.ZERO:
		active_marker = _create_marker(quest.marker_position, profile.accent_color)
	if quest.objective_type == "collect" and quest.target_id == "egg":
		_create_eggs(quest.marker_position)

func _on_quest_completed(quest: QuestDefinition) -> void:
	session.quests_completed += 1
	session.growth.add_points(quest.reward_growth)
	if mode == "endless":
		endless_challenges_completed += 1
		save_system.record_challenge_completion(profile.id, endless_challenges_completed)
	hud.show_message("%s complete! +%d Growth Points" % [quest.title, quest.reward_growth])
	sounds.play_quest_reward()

func _on_quest_chain_completed() -> void:
	if mode == "adventure":
		_complete_adventure()
	else:
		endless_round += 1
		_start_next_endless_quest()

func _update_objectives(delta: float) -> void:
	var quest := quest_system.current()
	if quest != null and session.growth.stage_index >= quest.required_stage:
		if quest.objective_type == "reach" and _near_active_marker():
			quest_system.record("reach", quest.target_id)
		elif quest.objective_type == "finale" and quest.target_id != "valley_rival" and _near_active_marker():
			quest_system.record("finale", quest.target_id)
		elif quest.objective_type == "collect":
			_collect_nearby_props(quest)
		elif quest.objective_type == "survive":
			if quest.target_id.is_empty() or (world_events != null and world_events.is_active(quest.target_id)):
				endless_second_timer += delta
				while endless_second_timer >= 1.0:
					endless_second_timer -= 1.0
					quest_system.record("survive", quest.target_id, 1)
	if not optional_completed and player.global_position.distance_to(Vector3(19, 0, -4)) < 2.8:
		optional_completed = true
		session.growth.add_points(2)
		save_system.award_badge("%s_valley_explorer" % profile.id)
		save_system.unlock_cosmetic(profile.id, "sunset")
		save_system.save_data()
		hud.show_message("Optional quest complete: Valley Explorer! New badge earned.")

func _create_eggs(center: Vector3) -> void:
	var offsets: Array[Vector3] = [Vector3(-2, 0, 0), Vector3(1.5, 0, 1.5), Vector3(2, 0, -2)]
	for offset in offsets:
		var egg := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.3
		mesh.height = 0.75
		egg.mesh = mesh
		egg.material_override = _glow_material(Color("#fff0a8"))
		egg.position = center + offset + Vector3.UP * 0.38
		run_root.add_child(egg)
		quest_props.append(egg)

func _collect_nearby_props(quest: QuestDefinition) -> void:
	for prop in quest_props.duplicate():
		if is_instance_valid(prop) and player.global_position.distance_to(prop.global_position) < 1.7:
			quest_props.erase(prop)
			prop.queue_free()
			quest_system.record("collect", quest.target_id)
			hud.show_message("Found an egg! Keep following the trail.")
			break

func _start_next_endless_quest() -> void:
	var destination := Vector3(randf_range(-21, 21), 0, randf_range(-21, 21))
	var active_event_id: String = world_events.active_event_id if world_events != null else ""
	var repeatable: QuestDefinition = endless_challenges.next(endless_round, profile, active_event_id, destination)
	quest_system.start([repeatable])

func _skip_endless_challenge() -> void:
	if mode != "endless" or endless_challenges == null:
		return
	var quest := quest_system.current()
	if quest == null or not endless_challenges.skip(quest.id):
		return
	hud.show_message("Challenge skipped. No Growth Points awarded.")
	endless_round += 1
	_start_next_endless_quest()

func _complete_adventure() -> void:
	if not session.growth.is_adult():
		return
	game_active = false
	save_system.unlock_endless(profile.id)
	save_system.unlock_cosmetic(profile.id, "mint")
	save_system.record_run(profile.id, session.survival_time, session.growth.points, session.quests_completed, session.summary())
	hud.show_completion("ADVENTURE COMPLETE!", "%s reached Adult and completed the finale.\n%s\nEndless Survival is now unlocked for this dinosaur." % [profile.display_name, _run_summary_text()])

func _on_predator_attack(damage: float) -> void:
	var final_damage := damage * 0.3 if shield_timer > 0.0 else damage
	session.take_damage(final_damage)
	hud.show_message("A larger dinosaur bumped you! Find space to recover.")
	sounds.play_warning()

func _on_predator_warning() -> void:
	if sounds != null:
		sounds.play_predator_warning()
	hud.show_message("A predator is warning you. Find space or retreat.")

func _on_predator_attack_landed() -> void:
	if sounds != null:
		sounds.play_predator_attack()

func _on_player_defeated() -> void:
	_cancel_world_event("you returned to the safe nest")
	_show_dust_transition()
	player.position = SAFE_SPAWN
	player.velocity = Vector3.ZERO
	session.respawn_at_stage_floor()
	hud.show_message("Back at the safe nest. Current-stage growth was reset.")
	sounds.play_warning()

func _show_dust_transition() -> void:
	var dust := ColorRect.new()
	dust.color = Color("#d8b477")
	dust.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dust.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(dust)
	var tween := dust.create_tween()
	tween.tween_property(dust, "modulate:a", 0.0, 0.8)
	tween.tween_callback(dust.queue_free)

func _create_marker(target_position: Vector3, color: Color) -> Node3D:
	var marker := Node3D.new()
	marker.position = Vector3(target_position.x, _terrain_height_at(target_position.x, target_position.z), target_position.z)
	run_root.add_child(marker)
	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.7
	ring_mesh.outer_radius = 1.1
	ring.mesh = ring_mesh
	ring.material_override = _glow_material(color)
	ring.position.y = 0.2
	marker.add_child(ring)
	var beacon := MeshInstance3D.new()
	var beacon_mesh := SphereMesh.new()
	beacon_mesh.radius = 0.28
	beacon_mesh.height = 0.56
	beacon.mesh = beacon_mesh
	beacon.material_override = _glow_material(color)
	beacon.position.y = 2.5
	marker.add_child(beacon)
	var contrast_ring := MeshInstance3D.new()
	var contrast_mesh := TorusMesh.new()
	contrast_mesh.inner_radius = 0.82
	contrast_mesh.outer_radius = 1.22
	contrast_ring.mesh = contrast_mesh
	contrast_ring.material_override = _material(Color(0.03, 0.08, 0.1, 0.9))
	contrast_ring.position.y = 0.16
	contrast_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.add_child(contrast_ring)
	return marker

func _create_scent_dots() -> void:
	scent_dots.clear()
	for index in 10:
		var dot := MeshInstance3D.new()
		var dot_mesh := SphereMesh.new()
		dot_mesh.radius = 0.14
		dot_mesh.height = 0.28
		dot.mesh = dot_mesh
		dot.material_override = _glow_material(Color("#8ef5ff"))
		dot.visible = false
		run_root.add_child(dot)
		scent_dots.append(dot)

func _scent_target() -> Vector3:
	var quest := quest_system.current()
	if quest != null and session.growth.stage_index >= quest.required_stage and quest.marker_position != Vector3.ZERO:
		return quest.marker_position
	if world_stream != null:
		var nearest_landmark: Variant = world_stream.nearest_active_landmark(player.global_position)
		if nearest_landmark is Vector3:
			return nearest_landmark
	var food_group := "plant_food" if profile.diet == "herbivore" else "prey"
	var closest: Node3D
	var distance_best := INF
	for food_node in get_tree().get_nodes_in_group(food_group):
		var food := food_node as Node3D
		var distance := player.global_position.distance_to(food.global_position)
		if distance < distance_best:
			distance_best = distance
			closest = food
	return closest.global_position if closest != null else Vector3.ZERO

func _set_scent_visible(visible_value: bool) -> void:
	for dot in scent_dots:
		dot.visible = visible_value

func _near_active_marker() -> bool:
	return active_marker != null and is_instance_valid(active_marker) and player.global_position.distance_to(active_marker.global_position) < 3.0

func _clear_quest_objects() -> void:
	if active_marker != null and is_instance_valid(active_marker):
		active_marker.queue_free()
	active_marker = null
	for prop in quest_props:
		if is_instance_valid(prop):
			prop.queue_free()
	quest_props.clear()

func _danger_nearby() -> bool:
	for predator in predators:
		if is_instance_valid(predator) and player.global_position.distance_to(predator.global_position) < 9.0:
			return true
	return false

func _update_endless_difficulty() -> void:
	if mode != "endless":
		return
	var awareness := 1.0 + minf(session.survival_time / 600.0, 0.75)
	for predator in predators:
		predator.awareness_multiplier = awareness

func _update_world_events(delta: float) -> void:
	if mode != "endless" or world_events == null or food_spawner == null:
		return
	if get_tree().paused:
		return
	var active_event_before_tick: String = world_events.active_event_id
	if world_events.tick(delta):
		_finish_world_event(active_event_before_tick)
	if world_events.active_event_id.is_empty() and session.survival_time >= next_endless_event_time:
		var event_ids := [WORLD_EVENT_SYSTEM.FRESH_GROWTH, WORLD_EVENT_SYSTEM.HERD_JOURNEY, WORLD_EVENT_SYSTEM.PREDATOR_PASSAGE]
		var event_id: String = event_ids[endless_event_index % event_ids.size()]
		if not _event_is_eligible(event_id):
			next_endless_event_time += 30.0
		elif world_events.start(event_id, 45.0):
			if save_system.discover_event(event_id):
				hud.show_message("Field Guide discovery: %s" % WORLD_EVENT_SYSTEM.field_guide_text(event_id))
			if event_id == WORLD_EVENT_SYSTEM.FRESH_GROWTH:
				food_spawner.set_event_plant_bonus(4)
				hud.show_message("Fresh Growth! Extra plants have appeared for a short time.")
			else:
				if event_id == WORLD_EVENT_SYSTEM.HERD_JOURNEY:
					_start_herd_journey()
				else:
					_start_predator_passage()
			next_endless_event_time += 180.0
			endless_event_index += 1

func _start_herd_journey() -> void:
	var lead: PreyDino
	for node in get_tree().get_nodes_in_group("prey"):
		var prey := node as PreyDino
		if prey != null and prey.visible and (lead == null or prey.herd_leader):
			lead = prey
			if prey.herd_leader:
				break
	if lead == null:
		hud.show_message("Herd Journey could not find a nearby herd.")
		return
	var destination := Vector3(-lead.herd_anchor.x * 0.6, lead.herd_anchor.y, -lead.herd_anchor.z * 0.6)
	for node in get_tree().get_nodes_in_group("prey"):
		var prey := node as PreyDino
		if prey != null and prey.herd_id == lead.herd_id:
			prey.begin_journey(destination)
	hud.show_message("Herd Journey! Follow the traveling herd to its new meadow.")

func _start_predator_passage() -> void:
	var traveler: ValleyPredator
	for predator in predators:
		if is_instance_valid(predator) and predator.visible and (traveler == null or predator.strength < traveler.strength):
			traveler = predator
	if traveler == null:
		hud.show_message("Predator Passage could not find a nearby traveler.")
		return
	var destination := Vector3(-traveler.home.x * 0.55, traveler.home.y, -traveler.home.z * 0.55)
	traveler.begin_passage(destination)
	hud.show_message("Predator Passage! Keep your distance or use a safe retreat route.")

func _finish_world_event(finished_id: String) -> void:
	if finished_id == WORLD_EVENT_SYSTEM.FRESH_GROWTH:
		food_spawner.set_event_plant_bonus(0)
		hud.show_message("Fresh Growth has faded. The valley returns to normal.")
	elif finished_id == WORLD_EVENT_SYSTEM.HERD_JOURNEY:
		hud.show_message("Herd Journey complete. The herd has settled into a new meadow.")
	else:
		hud.show_message("Predator Passage complete. The route is safe again.")

func _event_is_eligible(event_id: String) -> bool:
	if event_id == WORLD_EVENT_SYSTEM.FRESH_GROWTH:
		return food_spawner != null
	if event_id == WORLD_EVENT_SYSTEM.HERD_JOURNEY:
		for node in get_tree().get_nodes_in_group("prey"):
			var prey := node as PreyDino
			if prey != null and prey.visible and not prey.herd_id.is_empty() and _event_actor_is_reachable(prey):
				return true
		return false
	for predator in predators:
		if is_instance_valid(predator) and predator.visible and _event_actor_is_reachable(predator):
			return true
	return false

func _event_actor_is_reachable(actor: Node3D) -> bool:
	return world_stream == null or not world_stream.chunk_id_at_world_position(actor.global_position).is_empty()

func _cancel_world_event(reason: String) -> void:
	if world_events == null or world_events.active_event_id.is_empty():
		return
	var cancelled_id: String = world_events.cancel()
	if food_spawner != null:
		food_spawner.set_event_plant_bonus(0)
	for node in get_tree().get_nodes_in_group("prey"):
		var prey := node as PreyDino
		if prey != null:
			prey.cancel_journey()
	for predator in predators:
		if is_instance_valid(predator):
			predator.cancel_passage()
	_replace_unavailable_endless_challenge(cancelled_id)
	if hud != null:
		hud.show_message("%s was cancelled because %s." % [cancelled_id.capitalize().replace("_", " "), reason])

func _replace_unavailable_endless_challenge(event_id: String) -> void:
	if mode != "endless" or endless_challenges == null or quest_system == null:
		return
	var quest := quest_system.current()
	if quest == null or quest.target_id != event_id:
		return
	endless_challenges.skip(quest.id)
	endless_round += 1
	_start_next_endless_quest()
	if hud != null:
		hud.show_message("Event challenge changed to a reachable challenge. No reward was granted.")

func _tick_cooldowns(delta: float) -> void:
	for ability_id in ability_cooldowns.keys():
		ability_cooldowns[ability_id] = maxf(0.0, float(ability_cooldowns[ability_id]) - delta)

func _ability_ready(ability: AbilityDefinition) -> bool:
	var remaining := float(ability_cooldowns.get(ability.id, 0.0))
	if remaining > 0.0:
		hud.show_message("%s is ready in %.1f seconds." % [ability.display_name, remaining])
		return false
	return true

func _start_cooldown(ability: AbilityDefinition) -> void:
	ability_cooldowns[ability.id] = ability.cooldown

func _show_locked_ability(action: String) -> void:
	for ability in profile.abilities:
		if ability.input_action == action:
			hud.show_message("%s unlocks at %s." % [ability.display_name, GrowthSystem.STAGE_NAMES[ability.unlock_stage]])
			return

func _cooldown_text() -> String:
	var active: Array[String] = []
	for ability_id in ability_cooldowns:
		var remaining := float(ability_cooldowns[ability_id])
		if remaining > 0.0:
			active.append("%s %.1fs" % [ability_id.replace("_", " ").capitalize(), remaining])
	return "Cooldowns: Ready" if active.is_empty() else "Cooldowns: %s" % ", ".join(active)

func _update_hud() -> void:
	if hud != null:
		hud.update_view(session, player, quest_system, _cooldown_text())

func _follow_player(delta: float) -> void:
	var desired := player.global_position + Vector3(0, 5.8, 9.5)
	camera.global_position = camera.global_position.lerp(desired, minf(delta * 5.0, 1.0))
	var look_ahead := Vector3.ZERO if ENVIRONMENT_QUALITY.reduced_motion else player.velocity
	look_ahead.y = 0.0
	if look_ahead.length() > 0.1:
		look_ahead = look_ahead.normalized() * 1.3
	camera.look_at(player.global_position + Vector3(0, 0.9, 0) + look_ahead, Vector3.UP)

func _keep_player_in_valley() -> void:
	player.position.x = clampf(player.position.x, -VALLEY_LIMIT, VALLEY_LIMIT)
	player.position.z = clampf(player.position.z, -VALLEY_LIMIT, VALLEY_LIMIT)
	player.position.y = _terrain_height_at(player.position.x, player.position.z)

func _ground_world_actors() -> void:
	for group_name in ["prey", "predator", "plant_food", "food_token"]:
		for node in get_tree().get_nodes_in_group(group_name):
			var actor := node as Node3D
			if actor == null:
				continue
			if world_stream != null:
				world_stream.confine_actor(actor, SAFE_SPAWN)
			if actor.global_position.y < -6.0:
				if actor.is_in_group("food_token"):
					actor.queue_free()
					continue
				actor.global_position = SAFE_SPAWN
			actor.global_position.y = _terrain_height_at(actor.global_position.x, actor.global_position.z)
			if actor is ValleyPredator:
				(actor as ValleyPredator).home.y = _terrain_height_at((actor as ValleyPredator).home.x, (actor as ValleyPredator).home.z)

func _terrain_height_at(x: float, z: float) -> float:
	var point := Vector2(x, z)
	var height := 0.0
	height += 2.0 * exp(-point.distance_squared_to(Vector2(-13, 11)) / 85.0)
	height += 4.0 * exp(-point.distance_squared_to(Vector2(14, -12)) / 70.0)
	height += 6.0 * exp(-point.distance_squared_to(Vector2(0, -18)) / 62.0)
	height += 3.5 * exp(-point.distance_squared_to(Vector2(17, 17)) / 95.0)
	height -= 1.4 * exp(-point.distance_squared_to(Vector2(19, -4)) / 32.0)
	return height

func _build_valley_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cells := 30
	var step := 2.0
	for z_index in cells:
		for x_index in cells:
			var x0 := -30.0 + x_index * step
			var z0 := -30.0 + z_index * step
			var a := Vector3(x0, _terrain_height_at(x0, z0), z0)
			var b := Vector3(x0 + step, _terrain_height_at(x0 + step, z0), z0)
			var c := Vector3(x0 + step, _terrain_height_at(x0 + step, z0 + step), z0 + step)
			var d := Vector3(x0, _terrain_height_at(x0, z0 + step), z0 + step)
			for vertex in [a, c, b, a, d, c]:
				var elevation_tint := clampf((vertex.y + 1.0) / 7.0, 0.0, 1.0)
				var terrain_color := Color("#72ae50").lerp(Color("#b5d96a"), elevation_tint)
				var zone := Vector2(vertex.x, vertex.z)
				if zone.distance_to(Vector2(19.0, -4.0)) < 6.5:
					terrain_color = terrain_color.lerp(Color("#6bb8a0"), 0.45)
				elif zone.distance_to(Vector2(0.0, -18.0)) < 8.5:
					terrain_color = terrain_color.lerp(Color("#c88b55"), 0.32)
				elif zone.distance_to(Vector2(16.0, 16.0)) < 8.0:
					terrain_color = terrain_color.lerp(Color("#c97862"), 0.25)
				surface.set_color(terrain_color)
				surface.set_uv(Vector2((vertex.x + 30.0) / 60.0, (vertex.z + 30.0) / 60.0))
				surface.add_vertex(vertex)
	surface.generate_normals()
	return surface.commit()

func _create_terrain_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "TerrainSafetyCollision"
	var shape := CollisionShape3D.new()
	# Use the same triangles as the visible terrain so slopes and hills are solid.
	# The broad safety volume remains unnecessary now that actors have recovery logic.
	var triangles := PackedVector3Array()
	var cells := 30
	var step := 2.0
	for z_index in cells:
		for x_index in cells:
			var x0 := -30.0 + x_index * step
			var z0 := -30.0 + z_index * step
			var a := Vector3(x0, _terrain_height_at(x0, z0), z0)
			var b := Vector3(x0 + step, _terrain_height_at(x0 + step, z0), z0)
			var c := Vector3(x0 + step, _terrain_height_at(x0 + step, z0 + step), z0 + step)
			var d := Vector3(x0, _terrain_height_at(x0, z0 + step), z0 + step)
			triangles.append_array([a, c, b, a, d, c])
	var terrain_shape := ConcavePolygonShape3D.new()
	terrain_shape.data = triangles
	shape.shape = terrain_shape
	body.add_child(shape)
	add_child(body)

func _create_navigation_region() -> void:
	var region := NavigationRegion3D.new()
	region.name = "ValleyNavigation"
	var navigation_mesh := NavigationMesh.new()
	navigation_mesh.agent_radius = 0.8
	navigation_mesh.agent_max_slope = 35.0
	navigation_mesh.agent_max_climb = 0.5
	var vertices := PackedVector3Array()
	var cells := 30
	var step := 2.0
	for z_index in cells + 1:
		for x_index in cells + 1:
			var x := -30.0 + x_index * step
			var z := -30.0 + z_index * step
			vertices.append(Vector3(x, _terrain_height_at(x, z) + 0.03, z))
	navigation_mesh.vertices = vertices
	for z_index in cells:
		for x_index in cells:
			var row := cells + 1
			var a := z_index * row + x_index
			var b := a + 1
			var c := a + row + 1
			var d := a + row
			navigation_mesh.add_polygon(PackedInt32Array([a, c, b]))
			navigation_mesh.add_polygon(PackedInt32Array([a, d, c]))
	region.navigation_mesh = navigation_mesh
	add_child(region)

func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	if hud != null:
		hud.set_paused(paused)

func _restart_run() -> void:
	_cancel_world_event("the run restarted")
	var restart_profile := profile
	var restart_mode := mode
	_record_current_run()
	_cleanup_run()
	_start_run(restart_profile, restart_mode)

func _return_to_selection() -> void:
	_cancel_world_event("you returned to dinosaur selection")
	_record_current_run()
	_cleanup_run()
	_show_selection()

func _record_current_run() -> void:
	if session != null and profile != null:
		var summary := session.summary()
		summary["endless_challenges_completed"] = endless_challenges_completed
		save_system.record_run(profile.id, session.survival_time, session.growth.points, session.quests_completed, summary)
	if world_stream != null:
		save_system.save_chunk_states(world_stream.snapshot_state())

func _run_summary_text() -> String:
	var defeat_word := "defeat" if session.defeat_count == 1 else "defeats"
	return "Run summary: %.1f min | %d food | %d %s" % [session.survival_time / 60.0, session.food_eaten, session.defeat_count, defeat_word]

func _cleanup_run() -> void:
	game_active = false
	get_tree().paused = false
	if hud != null and is_instance_valid(hud):
		hud.free()
	if run_root != null and is_instance_valid(run_root):
		run_root.free()
	hud = null
	run_root = null
	player = null
	camera = null
	active_marker = null
	scent_dots.clear()
	quest_props.clear()
	predators.clear()

func _ensure_default_inputs() -> void:
	_ensure_key_action("special_ability", KEY_R)
	_ensure_key_action("volume_down", KEY_F2)
	_ensure_key_action("volume_up", KEY_F3)
	_ensure_key_action("environment_quality", KEY_F4)
	_ensure_key_action("weather_toggle", KEY_F5)
	_ensure_key_action("reduced_motion", KEY_F6)
	_ensure_key_action("day_cycle_toggle", KEY_F7)
	_add_joy_button("sprint", JOY_BUTTON_LEFT_STICK)
	_add_joy_button("eat", JOY_BUTTON_X)
	_add_joy_button("power_bite", JOY_BUTTON_B)
	_add_joy_button("scent_trail", JOY_BUTTON_LEFT_SHOULDER)
	_add_joy_button("dash", JOY_BUTTON_A)
	_add_joy_button("special_ability", JOY_BUTTON_Y)
	_add_joy_button("ui_cancel", JOY_BUTTON_START)
	_add_joy_button("skip_challenge", JOY_BUTTON_RIGHT_SHOULDER)
	_ensure_key_action("help", KEY_F1)
	_ensure_key_action("skip_challenge", KEY_K)
	_add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_axis("move_forward", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis("move_back", JOY_AXIS_LEFT_Y, 1.0)

func _adjust_effects_volume(amount: float) -> void:
	var next_volume := clampf(sounds.get_effects_volume() + amount, 0.0, 1.0)
	sounds.set_effects_volume(next_volume)
	(save_system.data["settings"] as Dictionary)["effects_volume"] = next_volume
	save_system.save_data()
	hud.show_message("Effects volume: %d%% (F2/F3)" % roundi(next_volume * 100.0))

func _cycle_environment_quality() -> void:
	var settings := save_system.data["settings"] as Dictionary
	var next := ENVIRONMENT_QUALITY.next(str(settings.get("environment_quality", "medium")))
	settings["environment_quality"] = next
	ENVIRONMENT_QUALITY.configure(settings)
	var sun := get_node_or_null("ValleySun") as DirectionalLight3D
	if sun != null:
		sun.directional_shadow_max_distance = float(ENVIRONMENT_QUALITY.preset({}).get("shadow_distance", 90.0))
	if camera != null:
		camera.far = 220.0 if ENVIRONMENT_QUALITY.active_id == "low" else (340.0 if ENVIRONMENT_QUALITY.active_id == "high" else 280.0)
	if valley_environment != null:
		var ssao_enabled := ENVIRONMENT_QUALITY.active_id != "low"
		valley_environment.ssao_enabled = ssao_enabled
		valley_environment.ssao_intensity = 0.7 if ENVIRONMENT_QUALITY.active_id == "medium" else 1.0
		var fog_scale := 0.8 if ENVIRONMENT_QUALITY.active_id == "low" else (1.15 if ENVIRONMENT_QUALITY.active_id == "high" else 1.0)
		valley_environment.fog_density = 0.0045 * fog_scale
	for tree in animated_trees:
		if is_instance_valid(tree):
			tree.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if ENVIRONMENT_QUALITY.active_id == "low" else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_apply_authored_environment_quality()
	save_system.save_data()
	_apply_environment_settings_to_loaded_chunks()
	hud.show_message("Environment quality: %s (applied now)" % next.to_upper())

func _toggle_weather() -> void:
	var settings := save_system.data["settings"] as Dictionary
	settings["weather_enabled"] = not bool(settings.get("weather_enabled", true))
	ENVIRONMENT_QUALITY.configure(settings)
	save_system.save_data()
	_apply_environment_settings_to_loaded_chunks()
	sounds.play_weather_toggle(ENVIRONMENT_QUALITY.weather_enabled)
	hud.show_message("Weather effects: %s (applied now)" % ("ON" if ENVIRONMENT_QUALITY.weather_enabled else "OFF"))

func _toggle_reduced_motion() -> void:
	var settings := save_system.data["settings"] as Dictionary
	settings["reduced_motion"] = not bool(settings.get("reduced_motion", false))
	ENVIRONMENT_QUALITY.configure(settings)
	save_system.save_data()
	_apply_environment_settings_to_loaded_chunks()
	hud.show_message("Reduced motion: %s" % ("ON" if ENVIRONMENT_QUALITY.reduced_motion else "OFF"))

func _toggle_day_cycle() -> void:
	var settings := save_system.data["settings"] as Dictionary
	settings["day_cycle_enabled"] = not bool(settings.get("day_cycle_enabled", true))
	save_system.save_data()
	hud.show_message("Daylight cycle: %s" % ("ON" if bool(settings["day_cycle_enabled"]) else "OFF"))

func _apply_environment_settings_to_loaded_chunks() -> void:
	for chunk in chunk_instances.values():
		if not is_instance_valid(chunk):
			continue
		var ambient := chunk.get_node_or_null("AmbientParticles") as GPUParticles3D
		if ambient != null:
			ambient.emitting = ENVIRONMENT_QUALITY.weather_enabled and not ENVIRONMENT_QUALITY.reduced_motion
			ambient.amount = maxi(2, int(float(ambient.get_meta("base_particle_count", 7)) * float(ENVIRONMENT_QUALITY.preset({}).get("effects", 1.0))))
		for child in chunk.get_children():
			if child is GPUParticles3D and str(child.name).begins_with("BiomeWeather_"):
				var weather_particles := child as GPUParticles3D
				weather_particles.emitting = ENVIRONMENT_QUALITY.weather_enabled and not ENVIRONMENT_QUALITY.reduced_motion
				weather_particles.amount = maxi(4, int(float(weather_particles.get_meta("base_particle_count", 18)) * float(ENVIRONMENT_QUALITY.preset({}).get("effects", 1.0))))
		var dressing: Node = chunk.get_node_or_null("AssetPackDressing")
		if dressing != null:
			var prop_distance := 95.0 * float(ENVIRONMENT_QUALITY.preset({}).get("foliage", 1.0))
			for visual in dressing.find_children("*", "GeometryInstance3D", true, false):
				var prop_visual := visual as GeometryInstance3D
				prop_visual.visibility_range_end = prop_distance
				prop_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if ENVIRONMENT_QUALITY.active_id == "low" else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		var debris := chunk.get_node_or_null("GroundDebris") as MultiMeshInstance3D
		if debris != null:
			debris.visibility_range_end = 85.0 * float(ENVIRONMENT_QUALITY.preset({}).get("foliage", 1.0))
			debris.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if ENVIRONMENT_QUALITY.active_id == "low" else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		var biome_environment := chunk.get_node_or_null("BiomeEnvironment") as WorldEnvironment
		if biome_environment != null and biome_environment.environment != null:
			biome_environment.environment.ssao_enabled = ENVIRONMENT_QUALITY.active_id != "low"
			biome_environment.environment.ssao_intensity = 0.6 if ENVIRONMENT_QUALITY.active_id == "medium" else 0.9
			var fog_scale := 0.8 if ENVIRONMENT_QUALITY.active_id == "low" else (1.15 if ENVIRONMENT_QUALITY.active_id == "high" else 1.0)
			biome_environment.environment.fog_density = float(chunk.get_meta("fog_density", 0.006)) * fog_scale
		var water := chunk.get_node_or_null("WaterSurface") as MeshInstance3D
		if water != null and water.material_override is StandardMaterial3D:
			var water_material := water.material_override as StandardMaterial3D
			var effects_scale := float(ENVIRONMENT_QUALITY.preset({}).get("effects", 1.0))
			water_material.albedo_color.a = 0.58 + effects_scale * 0.12
			water_material.roughness = 0.2 - effects_scale * 0.05

func _apply_authored_environment_quality() -> void:
	var preset := ENVIRONMENT_QUALITY.preset({})
	var effects_scale := float(preset.get("effects", 1.0))
	var foliage_scale := float(preset.get("foliage", 1.0))
	for waterfall in waterfall_layers:
		if is_instance_valid(waterfall):
			waterfall.visibility_range_end = 110.0 + effects_scale * 90.0
	for firefly in fireflies:
		if is_instance_valid(firefly):
			firefly.visibility_range_end = 42.0 + foliage_scale * 28.0
	var mountain_distance := 170.0 + foliage_scale * 100.0
	for mountain in distant_mountains:
		if is_instance_valid(mountain):
			mountain.visibility_range_end = mountain_distance

func _ensure_key_action(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if InputMap.action_get_events(action).is_empty():
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action, event)

func _add_joy_button(action: String, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for existing in InputMap.action_get_events(action):
		if existing is InputEventJoypadButton and (existing as InputEventJoypadButton).button_index == button:
			return
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)

func _add_joy_axis(action: String, axis: JoyAxis, axis_value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for existing in InputMap.action_get_events(action):
		if existing is InputEventJoypadMotion and (existing as InputEventJoypadMotion).axis == axis and is_equal_approx((existing as InputEventJoypadMotion).axis_value, axis_value):
			return
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action, event)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	return material

func _glow_material(color: Color) -> StandardMaterial3D:
	var material := _material(color)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.7
	return material
