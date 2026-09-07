extends SceneTree

func _init() -> void:
	var dressing = preload("res://jungle_dressing.gd")
	var habitat = preload("res://jungle_habitat.gd")
	if DirAccess.make_dir_recursive_absolute("res://assets/environment/foliage") != OK:
		push_error("Cannot create foliage bake directory")
		quit(1)
		return
	var count := 0
	for kind in habitat.PALETTE:
		for asset in habitat.PALETTE[kind]:
			var path: String = asset if asset.begins_with("res://") else "res://glTF/%s.gltf" % asset
			var mesh: ArrayMesh = dressing.mesh_for(path,kind,false)
			mesh.set_meta("bake_version",1)
			mesh.set_meta("source",path)
			mesh.set_meta("kind",kind)
			mesh.set_meta("source_fingerprint",dressing.mesh_fingerprint(path))
			mesh.set_meta("source_stamp",dressing.mesh_fingerprint(path,false))
			if ResourceSaver.save(mesh,dressing.mesh_bake_path(path,kind)) != OK:
				push_error("Cannot save foliage mesh: "+path)
				quit(1)
				return
			count += 1
	print("Foliage mesh bake: PASS (%d meshes)" % count)
	quit()
