extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var habitat = preload("res://jungle_habitat.gd")
	var dressing = preload("res://jungle_dressing.gd")
	var terrain = preload("res://valley_terrain.gd")
	terrain.build_mesh(Vector2(60,0))
	var results: Array = []
	for kind in habitat.BUDGETS:
		var started := Time.get_ticks_usec()
		var layout: Array = habitat.placements("Fernwood",kind)
		var layout_ms := float(Time.get_ticks_usec()-started)/1000.0
		started = Time.get_ticks_usec()
		for asset in habitat.PALETTE[kind]:
			var path: String = asset if asset.begins_with("res://") else "res://glTF/%s.gltf" % asset
			dressing.mesh_for(path,kind)
		var mesh_ms := float(Time.get_ticks_usec()-started)/1000.0
		var parent := Node3D.new()
		root.add_child(parent)
		started = Time.get_ticks_usec()
		dressing.build(parent,"Fernwood",false,[kind])
		results.append({"kind":kind,"count":layout.size(),"layout_ms":layout_ms,"mesh_ms":mesh_ms,"batch_ms":float(Time.get_ticks_usec()-started)/1000.0})
		parent.free()
	print("Jungle construction CPU costs: ",JSON.stringify(results))
	quit()
