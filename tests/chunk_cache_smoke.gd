extends SceneTree

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var manager := WorldStreamManager.new()
	var profiles := preload("res://world_chunk_profiles.gd").reserve()
	manager.configure(profiles)
	var original := manager.instantiate_chunk("fernwood",world)
	var original_id := original.get_instance_id()
	await physics_frame
	await physics_frame
	check(_has_ground(),"Active chunk must supply real ground collision")
	manager.release_chunk("fernwood")
	await physics_frame
	await physics_frame
	check(not _has_ground(),"Detached cached chunk must not retain ground collision")
	check(not original.is_inside_tree(),"Cached terrain, navigation and dressing must leave the world")
	check(not manager.scene_instances.has("fernwood"),"Inactive cache must not count as active scenery")
	manager.set_chunk_state("fernwood",{"food_claimed":7})
	var restored := manager.instantiate_chunk("fernwood",world)
	await physics_frame
	await physics_frame
	check(_has_ground(),"Reused chunk must restore ground collision")
	check(restored.get_instance_id()==original_id,"Reentry must reuse the constructed chunk")
	check(restored.chunk_state.get("food_claimed")==7,"Reentry must restore current run state")
	check(restored.is_inside_tree(),"Reentry must restore terrain and navigation to the world")
	check(manager.activation_samples.back().get("reused",false),"Telemetry must distinguish warm activation")
	manager.release_chunk("fernwood")
	for profile in profiles:
		if profile.chunk_id=="fernwood":
			continue
		manager.instantiate_chunk(profile.chunk_id,world)
		manager.release_chunk(profile.chunk_id)
		check(manager.cached_instances.size()<=manager.CACHE_LIMIT,"Cache memory must remain bounded")
	check(not is_instance_valid(original),"Least recently used cached chunk must be freed on eviction")
	var last: Node3D = manager.cached_instances.values().back()
	world.free()
	check(not is_instance_valid(last),"World destruction must free detached cache contents")
	manager.configure(profiles)
	check(manager.cached_instances.is_empty(),"Reset must clear stale cache records")
	print("Chunk cache smoke: %s" % ("PASS" if failures==0 else "FAIL"))
	quit(0 if failures==0 else 1)

func _has_ground() -> bool:
	return not root.world_3d.direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(60,20,0),Vector3(60,-10,0),1)).is_empty()
