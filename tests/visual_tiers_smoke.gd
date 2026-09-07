extends SceneTree

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	EnvironmentQuality.active_id = "medium"
	var world := Node3D.new()
	root.add_child(world)
	var manager := WorldStreamManager.new()
	manager.configure(preload("res://world_chunk_profiles.gd").reserve())
	manager.update_player_chunk(Vector2i.ZERO)
	for id in manager.active_chunk_ids():
		manager.instantiate_chunk(id,world)
	var forest: Node3D = manager.scene_instances["fernwood"]
	var full_count := grass_count(forest)
	var trunk_count := forest.get_node("JungleTrunks").get_child_count()
	manager.update_visual_tiers(world,Vector2i.ZERO)
	check(manager.distant_instances.size()<=1,"Only one distant scene should be created per update")
	check(grass_count(forest)>0 and grass_count(forest)<full_count,"Adjacent dressing must be reduced, not removed")
	for frame in 16:
		manager.update_visual_tiers(world,Vector2i.ZERO)
	check(not manager.distant_instances.is_empty(),"Reserve must have distant scenery")
	for id in manager.distant_instances:
		var distant: Node3D = manager.distant_instances[id]
		check(not manager.is_active(id) and not manager.is_simulated(id),"Distant scenery must not activate wildlife")
		check(distant.find_children("*","CollisionObject3D",true,false).is_empty() and distant.find_children("*","NavigationRegion3D",true,false).is_empty(),"Distant scenery must have no collision or navigation")
		check(distant.has_node("DistantGround"),"Distant scenes must retain continuous terrain")
		var canopy := distant.get_node_or_null("DistantCanopy")
		if canopy!=null:
			for batch in canopy.get_children():
				check(batch.multimesh.mesh is QuadMesh and batch.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"Distant trees must use shadow-free impostors")
	manager.update_visual_tiers(world,Vector2i(1,0))
	check(grass_count(forest)==full_count,"Entering a habitat must restore full nearby detail")
	check(forest.get_node("JungleTrunks").get_child_count()==trunk_count,"Visual tiers must not change collision")
	var promoted_id: String = manager.distant_instances.keys()[0]
	var promoted_grid: Vector2i = manager.profile_for_chunk(promoted_id).grid_position
	manager.update_player_chunk(promoted_grid)
	manager.instantiate_chunk(promoted_id,world)
	manager.update_visual_tiers(world,promoted_grid)
	check(not manager.distant_instances.has(promoted_id) and manager.scene_instances.has(promoted_id),"Full activation must replace, not overlay, distant scenery")
	manager.update_visual_tiers(world,Vector2i(20,20))
	check(manager.distant_instances.is_empty(),"Out-of-range distant scenes must be released")
	world.free()
	manager.configure([])
	print("Visual tiers smoke: %s" % ("PASS" if failures==0 else "FAIL"))
	quit(0 if failures==0 else 1)

func grass_count(chunk: Node3D) -> int:
	var result := 0
	for batch in chunk.get_node("AssetPackDressing").get_children():
		if batch.get_meta("habitat_kind","")=="grass":
			result += batch.multimesh.visible_instance_count
	return result
