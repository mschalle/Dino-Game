extends SceneTree

func _init() -> void:
	var habitat = preload("res://jungle_habitat.gd")
	var terrain = preload("res://valley_terrain.gd")
	if DirAccess.make_dir_recursive_absolute("res://assets/environment/habitats") != OK:
		push_error("Cannot create habitat bake directory")
		quit(1)
		return
	var count := 0
	for biome in habitat.BIOMES:
		for kind in habitat.BUDGETS:
			var data := Resource.new()
			data.set_meta("layout_version",1)
			data.set_meta("biome",biome)
			data.set_meta("kind",kind)
			data.set_meta("source_fingerprint",terrain.source_fingerprint())
			data.set_meta("transforms",habitat.placements(biome,kind,false))
			if ResourceSaver.save(data,habitat.layout_path(biome,kind)) != OK:
				push_error("Cannot save habitat layout")
				quit(1)
				return
			count += 1
	print("Habitat layout bake: PASS (%d layouts)" % count)
	quit()
