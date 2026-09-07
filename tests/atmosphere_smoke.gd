extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.save_system = SaveSystem.new("res://.validation/atmosphere_save.json")
	game.save_system.save_data()
	root.add_child(game)
	game.set_process(false)
	var atmosphere = game.atmosphere
	var failures := 0
	for profile in WorldChunkProfiles.reserve():
		if profile.chunk_id in ["cloudforest","redwood_canyon"]:
			var habitat_palette: Dictionary = atmosphere.palette(profile.biome)
			if not is_equal_approx(float(habitat_palette.wind),0.55):
				failures += 1
				push_error("Forest must have sheltered wind: "+profile.chunk_id)
			if profile.chunk_id=="cloudforest" and habitat_palette.weather!="mist":
				failures += 1
				push_error("Cloudforest must receive mist")
	game._start_run(DinosaurProfiles.t_rex(),"adventure")
	for expected in [["high",70.0],["low",20.0],["medium",45.0]]:
		game._cycle_environment_quality()
		if EnvironmentQuality.active_id != expected[0] or not is_equal_approx(game.get_node("ValleySun").directional_shadow_max_distance,expected[1]):
			failures += 1
	game._animate_environment(0.0)
	if game.announced_biome != "Nest Basin":
		failures += 1
	# Loading a neighbor must not announce its biome or replace the player's ambience.
	game._on_chunk_activated("fernwood")
	if game.announced_biome != "Nest Basin":
		failures += 1
	game.player.position = Vector3(60,3,0)
	game._update_world_stream()
	game._animate_environment(0.0)
	if game.announced_biome != "Fernwood":
		failures += 1
	if game.find_children("*","WorldEnvironment",true,false).size()!=1:
		failures += 1
	if not game.find_children("BiomeWeather_*","GPUParticles3D",true,false).is_empty():
		failures += 1
	atmosphere.advance(2.0,"Nest Basin",Vector3.ZERO,false)
	var initial: Color = game.valley_sky_material.sky_top_color
	atmosphere.advance(0.0,"Glacier Valley",Vector3(180,3,180),false)
	if game.valley_sky_material.sky_top_color != initial:
		failures += 1
	atmosphere.advance(1.0,"Glacier Valley",Vector3(180,3,180),false)
	var midpoint: Color = game.valley_sky_material.sky_top_color
	var destination: Color = atmosphere.palette("Glacier Valley").sky
	if midpoint == initial or midpoint == destination:
		failures += 1
	if not is_equal_approx(float(atmosphere.current.wind),1.15):
		failures += 1
	atmosphere.advance(1.0,"Glacier Valley",Vector3(180,3,180),false)
	if not game.valley_sky_material.sky_top_color.is_equal_approx(destination):
		failures += 1
	if atmosphere.global_position != Vector3(180,5,180) or not atmosphere.weather.emitting:
		failures += 1
	for quality in ["low","medium","high"]:
		EnvironmentQuality.active_id = quality
		EnvironmentQuality.reduced_motion = true
		atmosphere.advance(0.1,"Glacier Valley",Vector3.ZERO,false)
		if atmosphere.weather.emitting:
			failures += 1
		if preload("res://jungle_dressing.gd").applied_wind != 0.0:
			failures += 1
		EnvironmentQuality.reduced_motion = false
		EnvironmentQuality.weather_enabled = false
		atmosphere.advance(0.1,"Glacier Valley",Vector3.ZERO,false)
		if atmosphere.weather.emitting:
			failures += 1
		EnvironmentQuality.weather_enabled = true
		if RenderingServer.get_current_rendering_method() != "forward_plus" and (game.valley_environment.ssao_enabled or game.valley_environment.volumetric_fog_enabled):
			failures += 1
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
	EnvironmentQuality.active_id = "medium"
	game.queue_free()
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
	if failures > 0:
		push_error("Atmosphere checks failed: %d" % failures)
	print("Atmosphere smoke: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
