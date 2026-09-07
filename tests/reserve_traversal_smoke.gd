extends SceneTree

const TERRAIN = preload("res://valley_terrain.gd")
# Connected cardinal routes, including every reserve habitat and a return to the nest.
const ROUTE = [Vector2i(1,0),Vector2i(1,1),Vector2i(2,1),Vector2i(2,2),Vector2i(3,2),Vector2i(3,3),Vector2i(2,3),Vector2i(2,2),Vector2i(1,2),Vector2i(0,2),Vector2i(-1,2),Vector2i(-2,2),Vector2i(-2,3),Vector2i(-2,2),Vector2i(-2,1),Vector2i(-1,1),Vector2i(0,1),Vector2i(0,0)]
var failures := 0
var captures: Dictionary = {}
var frame_times: Array[float] = []
var last_frame_usec := 0
var measurement_start_usec := 0
var benchmark_route := Vector2i.ZERO
var spike_samples: Array[Dictionary] = []
var frame_markers: Array[Dictionary] = []
var benchmark_stream: RefCounted

func _record_frame() -> void:
	var now := Time.get_ticks_usec()
	if last_frame_usec>0:
		var ms := float(now-last_frame_usec)/1000.0
		frame_times.append(ms)
		if ms>33.333:
			var builds: Array = []
			if benchmark_stream != null:
				for sample in benchmark_stream.activation_samples+benchmark_stream.decoration_samples:
					if int(sample.get("completed_usec",0))>=last_frame_usec:
						builds.append(sample.duplicate(true))
			spike_samples.append({"elapsed_seconds":float(now-measurement_start_usec)/1000000.0,"ms":ms,"destination":str(benchmark_route),"test_work":frame_markers.duplicate(true),"chunk_work":builds})
	else:
		measurement_start_usec = now
	frame_markers.clear()
	last_frame_usec = now

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var capture := "--capture" in OS.get_cmdline_user_args()
	var benchmark := "--benchmark" in OS.get_cmdline_user_args()
	var early_diagnostic := "--early-diagnostic" in OS.get_cmdline_user_args()
	if early_diagnostic and not benchmark:
		check(false,"Early diagnostic requires benchmark mode")
		quit(1)
		return
	if benchmark and (capture or "--fixed-fps" in OS.get_cmdline_args()):
		check(false,"Benchmark must not use fixed FPS or screenshot capture")
		quit(1)
		return
	if (capture or benchmark) and DisplayServer.get_name()=="headless":
		check(false,"Reserve captures require rendering")
		quit(1)
		return
	var game = load("res://Main.tscn").instantiate()
	game.save_system = SaveSystem.new("res://.validation/reserve_traversal_save.json")
	root.add_child(game)
	game._start_run(DinosaurProfiles.t_rex(),"adventure")
	if benchmark and "--prewarm-water" in OS.get_cmdline_user_args():
		var viewport := SubViewport.new()
		viewport.size = Vector2i(64,64)
		viewport.own_world_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var water := MeshInstance3D.new()
		water.mesh = PlaneMesh.new()
		var material := ShaderMaterial.new()
		material.shader = preload("res://assets/environment/reserve_water.gdshader")
		water.material_override = material
		viewport.add_child(water)
		var camera := Camera3D.new()
		viewport.add_child(camera)
		camera.position = Vector3(0,2,2)
		camera.look_at(Vector3.ZERO)
		for frame in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		viewport.queue_free()
		await process_frame
	if benchmark:
		benchmark_stream = game.world_stream
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
		root.size = Vector2i(1280,720)
		DisplayServer.window_set_size(Vector2i(1280,720))
		print("Reserve benchmark: warming up for 30 seconds")
		await create_timer(30.0,false).timeout
		process_frame.connect(_record_frame)
	var visited: Dictionary = {Vector2i.ZERO:true}
	for grid in ROUTE:
		visited[grid] = true
	for profile in WorldChunkProfiles.reserve():
		check(visited.has(profile.grid_position),"Traversal route must cover "+profile.chunk_id)
	for adult in [false,true]:
		if adult and early_diagnostic:
			break
		if adult:
			game.session.growth.add_points(25)
		for grid in ROUTE:
			if early_diagnostic and grid==Vector2i(2,1):
				break
			benchmark_route = grid
			var destination := Vector2(grid)*TERRAIN.CHUNK_SIZE
			for frame in 3:
				await physics_frame
			for chunk in game.world_stream.scene_instances.values():
				var region: NavigationRegion3D = chunk.get_node("NavigationRegion")
				var deadline := Time.get_ticks_msec()+5000
				while NavigationServer3D.region_get_iteration_id(region.get_rid())==0 and Time.get_ticks_msec()<deadline:
					await process_frame
				check(NavigationServer3D.region_get_iteration_id(region.get_rid())>0,"Navigation region must finish asynchronous setup")
			var sync_started := Time.get_ticks_usec()
			NavigationServer3D.map_force_update(game.get_world_3d().navigation_map)
			if benchmark:
				frame_markers.append({"operation":"test_navigation_sync","ms":float(Time.get_ticks_usec()-sync_started)/1000.0})
			var endpoint := Vector3(destination.x,TERRAIN.height_at(destination.x,destination.y),destination.y)
			var path := NavigationServer3D.map_get_path(game.get_world_3d().navigation_map,game.player.global_position,endpoint,true)
			check(not path.is_empty() and path[path.size()-1].distance_to(endpoint)<1.0,"Navigation must connect habitat %s; path end %s" % [grid,path[path.size()-1] if not path.is_empty() else Vector3.INF])
			if failures>0:
				break
			var waypoint := 0
			var arrived := false
			var max_ground_error := 0.0
			for frame in 1200:
				var current := Vector2(game.player.position.x,game.player.position.z)
				if current.distance_to(destination)<0.8:
					arrived = true
					break
				while waypoint<path.size()-1 and current.distance_to(Vector2(path[waypoint].x,path[waypoint].z))<0.65:
					waypoint += 1
				var direction := Vector2(path[waypoint].x,path[waypoint].z)-current
				var yaw := atan2(-direction.x,-direction.y)
				game.player.turn_with_mouse(-angle_difference(game.player.rotation.y,yaw))
				Input.action_press("move_forward")
				game.session.health = game.session.profile.max_health
				game.session.hunger = 100.0
				await physics_frame
				max_ground_error = maxf(max_ground_error,absf(game.player.position.y-TERRAIN.height_at(game.player.position.x,game.player.position.z)))
			Input.action_release("move_forward")
			check(arrived,"Cannot walk to %s at %s; stopped at %s" % [grid,"Adult" if adult else "Hatchling",game.player.position])
			if not arrived:
				for index in game.player.get_slide_collision_count():
					print("Blocked by: ",game.player.get_slide_collision(index).get_collider().get_path())
				break
			check(absf(game.player.position.y-TERRAIN.height_at(game.player.position.x,game.player.position.z))<0.5,"Player must remain grounded")
			check(max_ground_error<0.5,"Player must remain grounded throughout the route, not only at its destination")
			check(game.world_stream.simulated_ids.size()<=5,"Simulation must stay within five habitats")
			check(get_nodes_in_group("prey").size()+get_nodes_in_group("predator").size()<=25,"Live creature cap must hold across reserve")
			print("Reserve traversal: %s reached %s" % ["Adult" if adult else "Hatchling",grid])
			if capture and not adult and not captures.has(grid):
				# Let the two-second biome atmosphere blend finish before art review.
				await create_timer(2.2, false).timeout
				check(is_equal_approx(game.atmosphere.blend_elapsed,2.0),"Capture atmosphere must finish blending")
				await RenderingServer.frame_post_draw
				for profile in WorldChunkProfiles.reserve():
					if profile.grid_position==grid:
						check(root.get_texture().get_image().save_png("res://.validation/reserve_%s.png" % profile.chunk_id)==OK,"Reserve capture must save")
				captures[grid] = true
		if failures>0:
			break
	if capture:
		check(captures.size()==16,"Rendered review must capture all 16 habitats")
	if benchmark:
		process_frame.disconnect(_record_frame)
		check(not frame_times.is_empty(),"Benchmark requires measured frames")
		if not frame_times.is_empty():
			var total := 0.0
			var spikes := 0
			for ms in frame_times:
				total += ms
				if ms>33.333:
					spikes += 1
			frame_times.sort()
			var report := {"renderer":RenderingServer.get_current_rendering_method(),"quality":EnvironmentQuality.active_id,"resolution":[1280,720],"measured_seconds":total/1000.0,"frames":frame_times.size(),"average_fps":frame_times.size()*1000.0/total,"p95_ms":frame_times[floori((frame_times.size()-1)*0.95)],"p99_ms":frame_times[floori((frame_times.size()-1)*0.99)],"max_ms":frame_times.back(),"frames_over_33_ms":spikes,"functional_failures":failures}
			var file := FileAccess.open("res://.validation/reserve_performance.json",FileAccess.WRITE)
			report["spikes"] = spike_samples
			report["scope"] = "first_two_routes_only" if early_diagnostic else "full_reserve_both_growth_sizes"
			report["prewarmed_water"] = "--prewarm-water" in OS.get_cmdline_user_args()
			check(file!=null,"Benchmark report must be writable")
			if file!=null:
				file.store_string(JSON.stringify(report,"\t"))
				file.close()
			print("Reserve benchmark: ",JSON.stringify(report))
	benchmark_stream = null
	game._cleanup_run()
	game.free()
	print("Reserve traversal smoke: %s" % ("PASS" if failures==0 else "FAIL"))
	quit(0 if failures==0 else 1)
