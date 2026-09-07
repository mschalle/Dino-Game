extends SceneTree
const WATER = preload("res://reserve_water.gd")

func _init() -> void:
	var error := DirAccess.make_dir_recursive_absolute("res://assets/environment/water")
	if error!=OK:
		quit(1)
		return
	for origin in [Vector2(60,120),Vector2(-120,180)]:
		var mesh := WATER.mesh(origin,false)
		mesh.set_meta("water_version",1)
		mesh.set_meta("origin",origin)
		mesh.set_meta("source_fingerprint",WATER.fingerprint())
		if ResourceSaver.save(mesh,WATER.bake_path(origin))!=OK:
			quit(1)
			return
	print("Reserve water bake: PASS")
	quit()
