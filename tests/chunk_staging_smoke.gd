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
	manager.configure(preload("res://world_chunk_profiles.gd").reserve())
	manager.defer_decoration = true
	var forest := manager.instantiate_chunk("fernwood",world)
	var distant := manager.instantiate_chunk("cloudforest",world)
	for chunk in [forest,distant]:
		check(chunk.has_node("GroundCollision") and chunk.has_node("NavigationRegion"),"Cold loading must supply ground and navigation immediately")
		check(not chunk.has_node("AssetPackDressing") and not chunk.decoration_steps.is_empty(),"Decoration must be staged")
	check(forest.has_node("JungleTrunks"),"Movement-blocking trunks must exist before decorative trees")
	await physics_frame
	await physics_frame
	check(not root.world_3d.direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(60,20,0),Vector3(60,-10,0),1)).is_empty(),"Cold ground must support physics before dressing")
	var pending: int = forest.decoration_steps.size()+distant.decoration_steps.size()
	manager.advance_decoration()
	check(forest.decoration_steps.size()+distant.decoration_steps.size()==pending-1,"Only one decorative phase may execute per scheduler call")
	for batch in forest.get_node("AssetPackDressing").get_children():
		check(batch.get_meta("habitat_kind")=="tree","First jungle phase must not also construct all ground cover")
	var forest_pending: int = forest.decoration_steps.size()
	manager.release_chunk("fernwood")
	manager.advance_decoration()
	check(forest.decoration_steps.size()==forest_pending,"Detached chunks must not receive background decoration")
	check(manager.instantiate_chunk("fernwood",world)==forest,"Partial construction must survive cache reuse")
	for step in 12:
		manager.advance_decoration()
	check(forest.decoration_steps.is_empty() and distant.decoration_steps.is_empty(),"All scheduled phases must eventually complete")
	check(forest.has_node("AssetPackDressing") and distant.has_node("AssetPackDressing"),"Both dressing paths must finish")
	check(distant.has_meta("vegetation_base_count"),"Delayed vegetation must receive its chunk profile after construction")
	check(distant.get_node("Vegetation").multimesh.instance_count==maxi(1,roundi(float(distant.get_meta("vegetation_base_count"))*manager.profile_for_chunk("cloudforest").vegetation_density)),"Staged density must match the original profile behavior")
	check(forest.find_children("JungleTrunks","StaticBody3D",true,false).size()==1,"Staging must not duplicate trunk colliders")
	if "--timings" in OS.get_cmdline_user_args():
		print("CPU construction timings (not GPU acceptance): ",JSON.stringify({"core":manager.activation_samples,"decoration":manager.decoration_samples}))
	world.free()
	print("Chunk staging smoke: %s" % ("PASS" if failures==0 else "FAIL"))
	quit(0 if failures==0 else 1)
