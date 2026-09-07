extends SceneTree

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var manager := WorldStreamManager.new()
	var profiles := preload("res://world_chunk_profiles.gd").reserve()
	manager.configure(profiles)
	for center in profiles:
		manager.update_player_chunk(center.grid_position)
		check(manager.simulated_ids.size()<=5,"Only five chunks may simulate creatures")
		check(manager.is_simulated(center.chunk_id),"Current habitat must simulate")
		for profile in profiles:
			var offset: Vector2i = profile.grid_position-center.grid_position
			check(manager.is_simulated(profile.chunk_id)==(absi(offset.x)+absi(offset.y)<=1),"Simulation must include only current and cardinal habitats")
		for spawn in manager.active_spawn_plan():
			check(manager.is_simulated(spawn.chunk_id),"New wildlife must spawn in simulated habitats")
	manager.update_player_chunk(Vector2i.ZERO)
	check(manager.is_active("sunstone_ridge") and not manager.is_simulated("sunstone_ridge"),"Diagonal terrain stays active without full simulation")
	var actor := PreyDino.new()
	actor.position = Vector3(60,2,60)
	root.add_child(actor)
	var health: float = actor.combat.health
	manager.update_actor_simulation(root)
	var position_before := actor.position
	await physics_frame
	await physics_frame
	check(not actor.can_process() and actor.position==position_before,"Distant prey must suspend movement")
	check(actor.combat.health==health,"Suspension must preserve health")
	manager.update_player_chunk(Vector2i.ONE)
	manager.update_actor_simulation(root)
	check(actor.can_process() and not actor.has_meta("stream_process_mode"),"Reentry must restore previous processing mode")
	check(actor.combat.health==health,"Reentry must not reset creature health")
	actor.free()
	manager.update_player_position(Vector3.ZERO)
	manager.update_player_position(Vector3(89,0,0))
	check(manager.is_active("nest_basin"),"Old neighborhood must remain loaded before the border")
	for x in [91.0,89.0,92.0,88.0]:
		manager.update_player_position(Vector3(x,0,0))
		check(manager.is_active("nest_basin"),"Border oscillation must retain terrain within unload margin")
		check(manager.simulated_ids.size()<=5,"Unload margin must not expand simulation budget")
	manager.update_player_position(Vector3(97,0,0))
	check(not manager.is_active("nest_basin"),"Chunk must unload beyond six-metre hysteresis margin")
	manager.update_player_position(Vector3.ZERO)
	check(manager.is_active("nest_basin") and manager.is_simulated("nest_basin"),"Teleport must immediately activate destination terrain and simulation")
	manager.configure(profiles)
	check(manager.simulated_ids.is_empty(),"Reset must clear simulation state")
	print("Stream simulation smoke: %s" % ("PASS" if failures==0 else "FAIL"))
	quit(0 if failures==0 else 1)
