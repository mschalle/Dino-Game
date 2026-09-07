extends SceneTree

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _init() -> void:
	var dressing = preload("res://jungle_dressing.gd")
	var habitat = preload("res://jungle_habitat.gd")
	var quality = preload("res://environment_quality.gd")
	for kind in habitat.PALETTE:
		for asset in habitat.PALETTE[kind]:
			var path: String = asset if asset.begins_with("res://") else "res://glTF/%s.gltf" % asset
			var baked := load(dressing.mesh_bake_path(path,kind)) as ArrayMesh
			check(dressing.valid_mesh_bake(baked,path,kind),"Missing/stale foliage bake: "+path)
			if baked==null:
				continue
			check(baked.get_meta("source_fingerprint","")==dressing.mesh_fingerprint(path),"Source content changed: "+path)
			var expected: Mesh = dressing.mesh_for(path,kind,false)
			check(expected.get_surface_count()==baked.get_surface_count(),"Surface count differs: "+path)
			for surface in mini(expected.get_surface_count(),baked.get_surface_count()):
				check(expected.surface_get_arrays(surface)==baked.surface_get_arrays(surface),"Geometry differs: "+path)
				check(dressing.surface_lods(expected,surface,1.0)==dressing.surface_lods(baked,surface,1.0),"LOD data differs: "+path)
				var original := expected.surface_get_material(surface) as ShaderMaterial
				var actual := baked.surface_get_material(surface) as ShaderMaterial
				for parameter in ["tint","green_leaf","camera_clearance"]:
					check(original.get_shader_parameter(parameter)==actual.get_shader_parameter(parameter),"Material differs: "+path)
				check(original.get_shader_parameter("albedo_texture").get_image().get_data()==actual.get_shader_parameter("albedo_texture").get_image().get_data(),"Texture differs: "+path)
			quality.reduced_motion = true
			dressing.mesh_cache.clear()
			var loaded: Mesh = dressing.mesh_for(path,kind)
			check(loaded==baked,"Must use accepted baked mesh")
			check(loaded.surface_get_material(0).get_shader_parameter("wind")==0.0,"Reduced Motion must disable baked wind")
			quality.reduced_motion = false
			baked.set_meta("bake_version",0)
			dressing.mesh_cache.clear()
			check(dressing.mesh_for(path,kind)!=baked,"Stale bake must use original source")
			baked.set_meta("bake_version",1)
	check(dressing.mesh_for("res://missing_foliage_fixture.glb","tree").get_surface_count()>0,"Missing source must retain procedural fallback")
	print("Foliage bake smoke: %s" % ("PASS" if failures==0 else "FAIL"))
	quit(0 if failures==0 else 1)
