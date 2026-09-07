extends SceneTree
const WATER = preload("res://reserve_water.gd")
const TERRAIN = preload("res://valley_terrain.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures := 0
	for origin in [Vector2(60,120),Vector2(-120,180)]:
		WATER.meshes.clear()
		var started := Time.get_ticks_usec()
		var mesh := WATER.mesh(origin)
		var baked_usec := Time.get_ticks_usec()-started
		started = Time.get_ticks_usec()
		var raw := WATER.mesh(origin,false)
		var raw_usec := Time.get_ticks_usec()-started
		print("Water %s construction CPU: baked %.3f ms, procedural %.3f ms" % [origin,baked_usec/1000.0,raw_usec/1000.0])
		if not WATER.valid_bake(mesh,origin) or mesh.get_faces()!=raw.get_faces():
			push_error("Baked water must match procedural geometry exactly")
			failures += 1
		var stale := mesh.duplicate() as ArrayMesh
		stale.set_meta("source_fingerprint","stale")
		if WATER.valid_bake(stale,origin) or WATER.valid_bake(null,origin):
			failures += 1
		var level := WATER.level_at(origin)
		var layout := WATER.bank_reeds(origin)
		if layout.size()<10 or layout.size()>96:
			push_error("Wetland bank reed population out of bounds")
			failures += 1
		for transform in layout:
			var local := Vector2(transform.origin.x,transform.origin.z)
			if absf(local.x)<3.0 or absf(local.y)<3.0 or local.length()<5.0:
				failures += 1
			if absf(transform.origin.y-TERRAIN.height_at(origin.x+local.x,origin.y+local.y))>0.001:
				failures += 1
		WATER.bank_layouts.clear()
		if WATER.bank_reeds(origin)!=layout:
			push_error("Bank dressing must be deterministic")
			failures += 1
		print("Bank reeds: %d" % layout.size())
		var bank_parent := preload("res://world_chunk_visual.gd").new()
		bank_parent.position = Vector3(origin.x,0,origin.y)
		WATER.build_bank_reeds(bank_parent)
		var reeds := bank_parent.get_node("BankReeds") as MultiMeshInstance3D
		var previous_count := -1
		var original_quality := EnvironmentQuality.active_id
		for quality in ["low","medium","high"]:
			EnvironmentQuality.active_id = quality
			bank_parent.apply_visual_tier("full",true)
			var full_count := reeds.multimesh.visible_instance_count
			if full_count<=previous_count or full_count>layout.size():
				push_error("Quality count mismatch: %s %d after %d" % [quality,full_count,previous_count])
				failures += 1
			previous_count = full_count
			bank_parent.apply_visual_tier("adjacent",true)
			if reeds.multimesh.visible_instance_count>=full_count:
				push_error("Adjacent reeds not reduced")
				failures += 1
			bank_parent.apply_visual_tier("full")
			if reeds.multimesh.visible_instance_count!=full_count:
				push_error("Full reed count not restored")
				failures += 1
			# The headless dummy renderer does not retain MultiMesh transform data.
			# Grounded CPU layouts are tested above; verify GPU uploads when rendered.
			if DisplayServer.get_name()!="headless":
				for index in layout.size():
					if not reeds.multimesh.get_instance_transform(index).is_equal_approx(layout[index]):
						push_error("Reed transform changed at %d" % index)
						failures += 1
		EnvironmentQuality.active_id = original_quality
		if not bank_parent.find_children("*","CollisionObject3D",true,false).is_empty():
			failures += 1
		bank_parent.free()
		if mesh==null or mesh.get_surface_count()==0:
			failures += 1
			continue
		var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		if vertices.size()<100 or WATER.mesh(origin)!=mesh:
			failures += 1
		var max_bank_error := 0.0
		var max_depth := 0.0
		for vertex in vertices:
			var point: Vector2 = Vector2(vertex.x,vertex.z)+origin
			max_bank_error = maxf(max_bank_error,TERRAIN.height_at(point.x,point.y)-level)
			max_depth = maxf(max_depth,level-TERRAIN.height_at(point.x,point.y))
			if not is_equal_approx(vertex.y,level) or WATER.shore_distance(point,origin+Vector2(-4,6))>0.03:
				failures += 1
		if max_bank_error>0.02:
			failures += 1
		if max_depth>0.5:
			push_error("Wetland must remain shallow and walkable")
			failures += 1
		print("Reserve water %s: %d vertices; bank error %.5f m" % [origin,vertices.size(),max_bank_error])
		print("Maximum sampled depth: %.3f m" % max_depth)
		if "--capture" in OS.get_cmdline_user_args():
			if DisplayServer.get_name()=="headless":
				push_error("Water capture requires rendering")
				failures += 1
				continue
			var scene := preload("res://world_chunk_visual.gd").new()
			var biome := "Coastal Marsh" if origin.x>0 else "Cypress Basin"
			scene.set_meta("biome",biome)
			scene.set_process(false)
			scene.position = Vector3(origin.x,0,origin.y)
			root.add_child(scene)
			# Chunk previews do not own the gameplay world's directional sun.
			var light := DirectionalLight3D.new()
			light.rotation_degrees = Vector3(-50,-25,0)
			scene.add_child(light)
			var camera := Camera3D.new()
			scene.add_child(camera)
			camera.position = Vector3(14,level+18,27)
			camera.look_at(Vector3(origin.x-4,level,origin.y+6))
			for frame in 5:
				await process_frame
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png("res://.validation/water_%s.png" % biome.to_snake_case())!=OK:
				failures += 1
			scene.queue_free()
			await process_frame
	print("Reserve water smoke: %s" % ("PASS" if failures==0 else "FAIL"))
	quit(0 if failures==0 else 1)
