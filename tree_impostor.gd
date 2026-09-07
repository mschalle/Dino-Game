extends RefCounted

static var cache: Dictionary = {}

static func resource_path(variant: int) -> String:
	return "res://assets/environment/impostors/CommonTree_%d.res" % (variant+1)

static func source_path(variant: int) -> String:
	return "res://glTF/CommonTree_%d.gltf" % (variant+1)

static func valid_card(card: QuadMesh, variant: int) -> bool:
	if card==null or card.get_meta("impostor_version",0)!=1 or card.get_meta("source","")!=source_path(variant):
		return false
	var stamp: String = preload("res://jungle_dressing.gd").mesh_fingerprint(source_path(variant),false)
	return stamp.is_empty() or card.get_meta("source_stamp","")==stamp

static func mesh_for(variant: int, use_baked: bool = true) -> Mesh:
	if use_baked and cache.has(variant):
		return cache[variant]
	if use_baked and ResourceLoader.exists(resource_path(variant)) and ResourceLoader.exists(source_path(variant)):
		var card := load(resource_path(variant)) as QuadMesh
		if valid_card(card,variant):
			cache[variant] = card
			return card
	return preload("res://jungle_dressing.gd").mesh_for(source_path(variant),"tree")
