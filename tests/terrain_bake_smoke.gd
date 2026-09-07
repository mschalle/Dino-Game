extends SceneTree

const TERRAIN = preload("res://valley_terrain.gd")

func _init() -> void:
	var failures := 0
	var count := 0
	for profile in preload("res://world_chunk_profiles.gd").reserve():
		var origin := Vector2(profile.grid_position)*TERRAIN.CHUNK_SIZE
		for cells in [TERRAIN.VISUAL_CELLS,TERRAIN.COLLISION_CELLS]:
			var baked := load(TERRAIN.bake_path(origin,cells)) as ArrayMesh
			var procedural := TERRAIN.build_mesh(origin,cells,false)
			if not TERRAIN.valid_bake(baked,origin,cells):
				failures += 1
				push_error("Missing or stale terrain bake: %s" % profile.chunk_id)
				continue
			if baked.surface_get_arrays(0) != procedural.surface_get_arrays(0) or baked.get_faces()!=procedural.get_faces():
				failures += 1
				push_error("Terrain bake differs from procedural geometry: %s" % profile.chunk_id)
			if TERRAIN.build_mesh(origin,cells)!=baked:
				failures += 1
			var samples: Dictionary = baked.get_meta("height_samples",{})
			if samples.is_empty():
				failures += 1
			for point in samples:
				TERRAIN._sample_cache.erase(point)
				if TERRAIN.sample_height(point.x,point.y)!=samples[point]:
					failures += 1
			count += 1
	var fixture := load(TERRAIN.bake_path(Vector2.ZERO,TERRAIN.VISUAL_CELLS)) as ArrayMesh
	fixture.set_meta("bake_version",-1)
	if TERRAIN.build_mesh(Vector2.ZERO)==fixture:
		failures += 1
	fixture.set_meta("bake_version",TERRAIN.BAKE_VERSION)
	var fingerprint: String = fixture.get_meta("source_fingerprint")
	fixture.set_meta("source_fingerprint","stale")
	if TERRAIN.build_mesh(Vector2.ZERO)==fixture:
		failures += 1
	fixture.set_meta("source_fingerprint",fingerprint)
	var missing := TERRAIN.build_mesh(Vector2(7,7))
	if missing.get_surface_count()!=1:
		failures += 1
	print("Terrain bake smoke: %s (%d exact mesh comparisons)" % ["PASS" if failures==0 else "FAIL",count])
	quit(0 if failures==0 else 1)
