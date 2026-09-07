extends SceneTree

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _init() -> void:
	var habitat = preload("res://jungle_habitat.gd")
	for biome in habitat.BIOMES:
		for kind in habitat.BUDGETS:
			var path: String = habitat.layout_path(biome,kind)
			check(ResourceLoader.exists(path),"Missing habitat bake: " + path)
			if not ResourceLoader.exists(path):
				continue
			var data := load(path)
			check(habitat.valid_layout(data,biome,kind),"Stale habitat bake: " + path)
			var expected: Array = habitat.placements(biome,kind,false)
			habitat.layout_cache.clear()
			check(habitat.placements(biome,kind)==expected,"Baked layout differs from procedural: " + path)
			check(data.get_meta("transforms")==expected,"Saved transforms differ: " + path)
			# Poison cached resource metadata, not the on-disk asset, to exercise real fallback.
			data.set_meta("layout_version",0)
			habitat.layout_cache.clear()
			check(not habitat.valid_layout(data,biome,kind),"Stale version must be rejected")
			check(habitat.placements(biome,kind)==expected,"Stale layout must regenerate")
			data.set_meta("layout_version",1)
	check(not habitat.valid_layout(null,"Fernwood","tree"),"Missing resource must be invalid")
	print("Habitat bake smoke: %s" % ("PASS" if failures==0 else "FAIL"))
	quit(0 if failures==0 else 1)
