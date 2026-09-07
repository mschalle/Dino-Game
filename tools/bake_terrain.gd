extends SceneTree

const TERRAIN = preload("res://valley_terrain.gd")

func _init() -> void:
	var error := DirAccess.make_dir_recursive_absolute("res://assets/environment/terrain")
	if error != OK:
		push_error("Cannot create terrain bake directory: %s" % error)
		quit(1)
		return
	var count := 0
	for profile in preload("res://world_chunk_profiles.gd").reserve():
		var origin := Vector2(profile.grid_position)*TERRAIN.CHUNK_SIZE
		for cells in [TERRAIN.VISUAL_CELLS,TERRAIN.COLLISION_CELLS]:
			var mesh := TERRAIN.build_mesh(origin,cells,false)
			mesh.set_meta("bake_version",TERRAIN.BAKE_VERSION)
			mesh.set_meta("origin",origin)
			mesh.set_meta("cells",cells)
			mesh.set_meta("source_fingerprint",TERRAIN.source_fingerprint())
			var samples: Dictionary = {}
			for point in TERRAIN._sample_cache:
				var offset: Vector2 = point-origin
				if maxf(absf(offset.x),absf(offset.y))<=TERRAIN.HALF_SIZE+TERRAIN.SAMPLE_STEP*2.0:
					samples[point] = TERRAIN._sample_cache[point]
			mesh.set_meta("height_samples",samples)
			error = ResourceSaver.save(mesh,TERRAIN.bake_path(origin,cells))
			if error != OK:
				push_error("Terrain bake failed: %s" % error)
				quit(1)
				return
			count += 1
	print("Terrain bake: PASS (%d meshes)" % count)
	quit()
