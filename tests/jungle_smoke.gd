extends SceneTree

const HABITAT = preload("res://jungle_habitat.gd")
const DRESSING = preload("res://jungle_dressing.gd")
const TERRAIN = preload("res://valley_terrain.gd")
const QUALITY = preload("res://environment_quality.gd")
var failures := 0
var render_diagnostic_completed := false

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _direction(value: Vector2) -> void:
	for action in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action)
	if value.length() < 0.001:
		return
	Input.action_press("move_right" if value.x >= 0 else "move_left", absf(value.x))
	Input.action_press("move_back" if value.y >= 0 else "move_forward", absf(value.y))

func _run() -> void:
	if "--source-foliage" in OS.get_cmdline_user_args():
		for kind in HABITAT.PALETTE:
			for asset in HABITAT.PALETTE[kind]:
				var path: String = asset if asset.begins_with("res://") else "res://glTF/%s.gltf" % asset
				DRESSING.mesh_cache[path+kind] = DRESSING.mesh_for(path,kind,false)
		print("Diagnostic foliage: source-normalized meshes")
	check(is_equal_approx(HABITAT.segment_distance(Vector2(3,7),Vector2(0,7),Vector2(0,7)),3.0), "Zero-length nest approach must have finite point distance")
	for z in range(0,61):
		check(is_finite(HABITAT.route_distance(Vector2(60,z))) and HABITAT.route_distance(Vector2(60,z)) < 0.001, "Main north-south corridor must remain protected independently of other clearing segments")
	var game = load("res://Main.tscn").instantiate()
	game.save_system = SaveSystem.new("res://.validation/jungle_save.json")
	game.save_system.data["settings"]["environment_quality"] = "medium"
	game.save_system.save_data()
	root.add_child(game)
	game._start_run(DinosaurProfiles.t_rex(), "adventure")
	for frame in 20:
		await physics_frame
	for index in 4:
		var chunk: Node3D = game.world_stream.instantiate_chunk(HABITAT.IDS[index], game)
		var trunks := chunk.get_node("JungleTrunks").get_child_count()
		check(trunks > 0 and trunks <= 40, "Canopy budget must be bounded")
		var trunk: CollisionShape3D = chunk.get_node("JungleTrunks").get_child(0)
		var center := trunk.global_position
		var hit := root.world_3d.direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(center+Vector3(2,0,0),center-Vector3(2,0,0),2))
		check(not hit.is_empty(), "Substantial trunks must block the player and spring arm collision layer")
		var navigation: NavigationMesh = chunk.get_node("NavigationRegion").navigation_mesh
		check(navigation.get_meta("trunk_fingerprint", 0) == hash(HABITAT.placements(HABITAT.BIOMES[index], "tree")), "Offline navigation must include the current trunk layout")
		for kind in HABITAT.BUDGETS:
			var layout := HABITAT.placements(HABITAT.BIOMES[index], kind)
			check(layout == HABITAT.placements(HABITAT.BIOMES[index], kind), "Reload placement must be deterministic")
			for placement in layout:
				var p: Vector2 = Vector2(placement.origin.x,placement.origin.z)+HABITAT.ORIGINS[index]
				check(absf(placement.origin.y-TERRAIN.height_at(p.x,p.y)) < 0.001, "Vegetation must be grounded")
				check(not HABITAT.excluded(p, kind in ["tree","bush","rock","log"]), "Vegetation must preserve paths and clearings")
		var counts: Array[int] = []
		for quality in ["low","medium","high"]:
			QUALITY.active_id = quality
			DRESSING.apply_quality(chunk)
			var count := 0
			for batch in chunk.get_node("AssetPackDressing").get_children():
				check(batch.visibility_range_begin == 0.0, "Nearby ground cover must not disappear")
				if batch.get_meta("habitat_kind", "") == "grass":
					count += batch.multimesh.visible_instance_count
			counts.append(count)
			check(chunk.get_node("JungleTrunks").get_child_count() == trunks, "Quality must not change collision")
		check(counts[0] > 0 and counts[0] < counts[1] and counts[1] < counts[2], "Ground cover must scale across all presets")
		print("%s trees=%d grass Low/Medium/High=%s" % [HABITAT.IDS[index],trunks,counts])
		QUALITY.active_id = "medium"
		DRESSING.apply_quality(chunk)
	check(DRESSING.mesh_for("res://missing_jungle_test_asset.glb", "fern").get_aabb().size.y > 0.0, "Missing asset must have a visible fallback")
	var wetland: Node3D = game.world_stream.scene_instances["river_wetlands"]
	var water: MeshInstance3D = wetland.get_node("WaterSurface")
	var original_transform := water.transform
	wetland._process(10.0)
	check(water.transform == original_transform, "Water must not move as a whole")
	for vertex in water.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		check(absf(vertex.y-HABITAT.WATER_LEVEL) < 0.001, "Water level must be stable")
		check(TERRAIN.height_at(vertex.x,vertex.z+60) <= HABITAT.WATER_LEVEL+0.035, "Water must stay within its terrain banks")
	# Structural inspection may instantiate an inactive chunk; do not include it
	# in captures or performance measurements as an extra streaming resident.
	for chunk_id in game.world_stream.scene_instances.keys():
		if not game.world_stream.is_active(chunk_id):
			game.world_stream.release_chunk(chunk_id)
	# Fixed viewpoints retain the live game, dinosaur and gameplay FOV.
	var views := [
		["nest",Vector3(0,0,7),Vector3(4,4,16),Vector3(0,1,-3)],
		["forest",Vector3(60,0,3),Vector3(60,5,12),Vector3(60,1,0)],
		["pond",Vector3(12,0,61),Vector3(12,5,54),Vector3(12,0,65)],
		["overlook",Vector3(60,0,63),Vector3(60,5,72),Vector3(60,1,60)]
	]
	for view in views:
		game.player.global_position = view[1] + Vector3.UP*(TERRAIN.height_at(view[1].x,view[1].z)+0.1)
		game.player.velocity = Vector3.ZERO
		game._update_world_stream()
		for frame in 12:
			await physics_frame
		game.set_process(false)
		# A capture camera avoids SpringArm's internal physics overwriting the pose.
		# Never leave a modified local camera transform in the traversal benchmark.
		var capture_camera := Camera3D.new()
		capture_camera.fov = game.camera.fov
		game.add_child(capture_camera)
		capture_camera.global_position = view[2]+Vector3.UP*TERRAIN.height_at(view[1].x,view[1].z)
		capture_camera.look_at(view[3]+Vector3.UP*TERRAIN.height_at(view[1].x,view[1].z))
		capture_camera.make_current()
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png("res://.validation/jungle_%s.png" % view[0]) == OK, "View capture must succeed")
			if "--capture-renderer" in OS.get_cmdline_user_args():
				check(root.get_texture().get_image().save_png("res://.validation/jungle_%s_%s.png" % [RenderingServer.get_current_rendering_method(),view[0]]) == OK,"Renderer comparison capture must save")
		game.camera.make_current()
		capture_camera.queue_free()
		game.set_process(true)
	if "--pond-walk" in OS.get_cmdline_user_args():
		await _pond_walk(game)
	if "--wildlife" in OS.get_cmdline_user_args():
		await _wildlife(game)
	if "--render-diagnostic" in OS.get_cmdline_user_args():
		await _render_diagnostic(game)
		check(render_diagnostic_completed,"Every requested rendering isolation phase must finish")
	if "--benchmark" in OS.get_cmdline_user_args() or "--route-diagnostic" in OS.get_cmdline_user_args() or "--spike-diagnostic" in OS.get_cmdline_user_args():
		await _benchmark(game)
	game.queue_free()
	await process_frame
	print("Jungle smoke: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func _render_diagnostic(game: Node3D) -> void:
	check(DisplayServer.get_name() != "headless", "Rendering diagnostic requires the development GPU")
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	game.player.position = Vector3(60,TERRAIN.height_at(60,0)+0.1,0)
	game.player.velocity = Vector3.ZERO
	game._update_world_stream()
	_direction(Vector2.ZERO)
	var diagnostic_environment: Environment = game.valley_environment.duplicate()
	game.camera.environment = diagnostic_environment
	var sun: DirectionalLight3D = game.get_node("ValleySun")
	var original_shadow := sun.shadow_enabled
	var samples: Array[Dictionary] = []
	var modes := ["baseline", "no_ssao", "no_shadows", "baseline_repeat"]
	if "--atmosphere-diagnostic" in OS.get_cmdline_user_args():
		modes = ["baseline", "frozen_atmosphere", "baseline_repeat"]
	if "--processing-diagnostic" in OS.get_cmdline_user_args():
		modes = ["baseline", "frozen_gameplay", "no_3d", "baseline_repeat"]
	if "--foliage-diagnostic" in OS.get_cmdline_user_args():
		modes = ["baseline", "no_foliage", "baseline_repeat"]
	if "--distance-diagnostic" in OS.get_cmdline_user_args():
		modes = ["baseline", "no_distant", "baseline_repeat"]
	if "--steady-diagnostic" in OS.get_cmdline_user_args():
		modes = ["baseline", "baseline_repeat", "baseline_third"]
	for mode in modes:
		for distant in game.world_stream.distant_instances.values():
			distant.visible = mode != "no_distant"
		for dressing in game.find_children("AssetPackDressing", "Node3D",true,false):
			dressing.visible = mode != "no_foliage"
		game.process_mode = Node.PROCESS_MODE_DISABLED if mode == "frozen_gameplay" else Node.PROCESS_MODE_INHERIT
		root.disable_3d = mode == "no_3d"
		game.atmosphere.environment = null if mode == "frozen_atmosphere" else game.valley_environment
		diagnostic_environment.ssao_enabled = mode != "no_ssao"
		sun.shadow_enabled = original_shadow and mode != "no_shadows"
		var start := Time.get_ticks_usec()
		var previous := start
		var times: Array[float] = []
		var process_ms := 0.0
		var physics_ms := 0.0
		var render_cpu_ms := 0.0
		var render_gpu_ms := 0.0
		while Time.get_ticks_usec()-start < 20000000:
			await process_frame
			var now := Time.get_ticks_usec()
			if now-start > 5000000:
				times.append(float(now-previous)/1000.0)
				process_ms += Performance.get_monitor(Performance.TIME_PROCESS)*1000.0
				physics_ms += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0
				render_cpu_ms += RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid())
				render_gpu_ms += RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())
			previous = now
			game.session.health = game.session.profile.max_health
			game.session.hunger = 100.0
		var total := 0.0
		for value in times:
			total += value
		times.sort()
		samples.append({"mode":mode,"fps":times.size()*1000.0/total,"p95_ms":times[int(times.size()*0.95)],"process_ms":process_ms/times.size(),"physics_ms":physics_ms/times.size(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
		samples.back().merge({"render_cpu_ms":render_cpu_ms/times.size(),"render_gpu_ms":render_gpu_ms/times.size(),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"focused":root.has_focus()})
		print("Rendering isolation (stationary, not acceptance): ",JSON.stringify(samples.back()))
	game.camera.environment = null
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),false)
	for distant in game.world_stream.distant_instances.values():
		distant.visible = true
	game.process_mode = Node.PROCESS_MODE_INHERIT
	root.disable_3d = false
	for dressing in game.find_children("AssetPackDressing", "Node3D",true,false):
		dressing.visible = true
	game.atmosphere.environment = game.valley_environment
	sun.shadow_enabled = original_shadow
	var report := FileAccess.open("res://.validation/render_isolation.json",FileAccess.WRITE)
	report.store_string(JSON.stringify(samples,"\t"))
	render_diagnostic_completed = true

func _pond_walk(game: Node3D) -> void:
	game.session.growth.add_points(25)
	game.player.position = Vector3(0,TERRAIN.height_at(0,60)+0.1,60)
	game.player.velocity = Vector3.ZERO
	game._update_world_stream()
	for frame in 45:
		await physics_frame
	check(game.session.growth.is_adult() and game.player.scale.is_equal_approx(Vector3.ONE*1.75),"Pond fixture must use the real Adult growth stage and collider")
	for target in [Vector2(12,60),Vector2(12,66),Vector2(12,72),Vector2(12,60),Vector2(0,60)]:
		for frame in 600:
			var offset: Vector2 = target-Vector2(game.player.position.x,game.player.position.z)
			if offset.length() < 0.5:
				break
			_direction(offset.normalized())
			game.session.health = game.session.profile.max_health
			game.session.hunger = 100.0
			await physics_frame
		_direction(Vector2.ZERO)
		check(Vector2(game.player.position.x,game.player.position.z).distance_to(target)<0.8,"Adult must walk through pond access and return without teleporting: %s" % target)
		check(absf(game.player.position.y-TERRAIN.height_at(game.player.position.x,game.player.position.z))<0.4,"Adult feet must remain on the shallow pond bed")
		if target == Vector2(12,72) and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.validation/jungle_adult_pond.png")
	print("Adult pond access and return checked")

func _wildlife(game: Node3D) -> void:
	game.player.strength = 0 # Explicit lower-strength encounter stimulus.
	for index in 4:
		var anchor: Vector2 = HABITAT.PREY_CLEARINGS[index]
		game.player.position = Vector3(anchor.x-4,TERRAIN.height_at(anchor.x-4,anchor.y),anchor.y)
		game.player.velocity = Vector3.ZERO
		game._update_world_stream()
		var prey := PreyDino.new()
		prey.setup("Valley Dino",1 if index < 2 else 2,Color.WHITE)
		prey.position = Vector3(anchor.x,TERRAIN.height_at(anchor.x,anchor.y),anchor.y)
		prey.set_player(game.player)
		game.run_root.add_child(prey)
		var start := prey.position
		var fled := false
		for frame in 120:
			await physics_frame
			fled = fled or prey.state == "flee"
		check(fled and prey.position.distance_to(start)>2.0,"%s prey must notice and escape" % HABITAT.IDS[index])
		check(absf(prey.position.x-HABITAT.ORIGINS[index].x)<=27 and absf(prey.position.z-HABITAT.ORIGINS[index].y)<=27,"Escaping prey must stay in its habitat")
		prey.queue_free()
		anchor = HABITAT.PREDATOR_EDGES[index]
		game.player.position = Vector3(anchor.x-6,TERRAIN.height_at(anchor.x-6,anchor.y),anchor.y)
		game.player.velocity = Vector3.ZERO
		var predator := ValleyPredator.new()
		predator.setup(2 if index==3 else 1,Vector3(anchor.x,TERRAIN.height_at(anchor.x,anchor.y),anchor.y))
		predator.set_player(game.player)
		game.run_root.add_child(predator)
		start = predator.position
		var warned := false
		var chased := false
		for frame in 150:
			await physics_frame
			warned = warned or predator.state == "warn"
			chased = chased or predator.state == "chase"
		check(warned and chased and predator.position.distance_to(start)>2.0,"%s predator must warn before pursuing a weaker target" % HABITAT.IDS[index])
		check(absf(predator.position.x-HABITAT.ORIGINS[index].x)<=27 and absf(predator.position.z-HABITAT.ORIGINS[index].y)<=27,"Pursuing predator must stay in its habitat")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.validation/jungle_encounter_%s.png" % HABITAT.IDS[index])
		predator.queue_free()
		var chunk: Node3D = game.world_stream.scene_instances[HABITAT.IDS[index]]
		var trunk: CollisionShape3D = chunk.get_node("JungleTrunks").get_child(0)
		var test_point := trunk.global_position + Vector3(0,0,-2.5)
		test_point.y = TERRAIN.height_at(test_point.x,test_point.z)+0.05
		game.player.position = test_point
		game.player.velocity = Vector3.ZERO
		for frame in 45:
			await physics_frame
		check(game.camera_arm.get_hit_length()<4.0,"%s actual trunk must retract the gameplay camera" % HABITAT.IDS[index])
		var clearing: Vector2 = HABITAT.ORIGINS[index]
		game.player.position = Vector3(clearing.x,TERRAIN.height_at(clearing.x,clearing.y)+0.05,clearing.y)
		game.player.velocity = Vector3.ZERO
		for frame in 60:
			await physics_frame
		check(game.camera_arm.get_hit_length()>8.0,"%s camera must recover in the clear corridor" % HABITAT.IDS[index])
		print("Habitat escape/pursuit checked: ",HABITAT.IDS[index])
	await process_frame

func _benchmark(game: Node3D) -> void:
	check(DisplayServer.get_name() != "headless", "Performance acceptance requires the development GPU")
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var route := [Vector2(60,60),Vector2(60,0),Vector2(0,0),Vector2(0,60)]
	var waypoint := 0
	var reached := 0
	var times: Array[float] = []
	var start := Time.get_ticks_usec()
	var previous := start
	var elapsed := 0.0
	var diagnostic := "--route-diagnostic" in OS.get_cmdline_user_args()
	var spike_diagnostic := "--spike-diagnostic" in OS.get_cmdline_user_args()
	var spike_details: Array[Dictionary] = []
	var next_report := 5.0
	# Thirty seconds warm-up, then five unfixed-time minutes of actual movement.
	while elapsed < (20.0 if diagnostic else (90.0 if spike_diagnostic else 330.0)):
		var now := Time.get_ticks_usec()
		elapsed = float(now-start)/1000000.0
		if elapsed >= 30.0:
			times.append(float(now-previous)/1000.0)
		if float(now-previous)/1000.0 > 33.33:
			var activations: Array = []
			for sample in game.world_stream.activation_samples:
				if now-int(sample.completed_usec)<1000000:
					activations.append(sample)
			spike_details.append({"elapsed":elapsed,"frame_ms":float(now-previous)/1000.0,"position":str(game.player.position),"recent_activations":activations})
		previous = now
		var p := Vector2(game.player.position.x,game.player.position.z)
		if p.distance_to(route[waypoint]) < 1.0:
			waypoint = (waypoint+1)%route.size()
			reached += 1
		_direction((route[waypoint]-p).normalized())
		# Keep the endurance fixture alive without disabling live AI/combat.
		game.session.health = game.session.profile.max_health
		game.session.hunger = 100.0
		if elapsed >= next_report:
			var collisions: Array[String] = []
			for i in game.player.get_slide_collision_count():
				collisions.append(str(game.player.get_slide_collision(i).get_collider().get_path()))
			print("Traversal %.0fs position=%s velocity=%s waypoint=%d physics=%s collisions=%s" % [elapsed,game.player.position,game.player.velocity,waypoint,game.player.is_physics_processing(),collisions])
			next_report += 30.0 if not diagnostic else 5.0
		await process_frame
	_direction(Vector2.ZERO)
	if diagnostic:
		print("Route diagnostic only; no performance acceptance result")
		return
	check(reached >= (6 if spike_diagnostic else 12), "Benchmark must traverse the region repeatedly, not measure a stuck camera")
	var total := 0.0
	var spikes := 0
	for milliseconds in times:
		total += milliseconds
		if milliseconds > 33.33:
			spikes += 1
	times.sort()
	var report := {"seconds":total/1000.0,"frames":times.size(),"average_fps":times.size()*1000.0/total,"p95_ms":times[int(times.size()*0.95)],"p99_ms":times[int(times.size()*0.99)],"max_ms":times.back(),"frames_over_33ms":spikes,"waypoints_reached":reached,"renderer":RenderingServer.get_current_rendering_method(),"gpu":RenderingServer.get_video_adapter_name(),"resolution":str(root.size)}
	report["spikes"] = spike_details
	var file := FileAccess.open("res://.validation/jungle_spike_diagnostic.json" if spike_diagnostic else "res://.validation/jungle_performance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	var renderer_report := FileAccess.open("res://.validation/jungle_%s_%s.json" % [RenderingServer.get_current_rendering_method(),"diagnostic" if spike_diagnostic else "performance"],FileAccess.WRITE)
	renderer_report.store_string(JSON.stringify(report,"\t"))
	var summary := report.duplicate()
	summary.erase("spikes")
	print("Jungle GPU diagnostic (not five-minute acceptance): " if spike_diagnostic else "Jungle GPU traversal: ",JSON.stringify(summary))
