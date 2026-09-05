class_name WorldChunkProfiles
extends RefCounted

const CHUNK_PROFILE = preload("res://world_chunk_profile.gd")

static func reserve() -> Array[RefCounted]:
	var chunks: Array[RefCounted] = [
		CHUNK_PROFILE.new("nest_basin", "Nest Basin", Vector2i(0, 0), "Safe Nest", {"prey": [1], "plants": true}, "res://world_chunks/nest_basin.tscn", Color("#72ae50"), 1.0, 0.004),
		CHUNK_PROFILE.new("fernwood", "Fernwood", Vector2i(1, 0), "Fernwood Trail", {"prey": [1, 2], "predators": [1]}, "res://world_chunks/fernwood.tscn", Color("#4f8e55"), 1.5, 0.009),
		CHUNK_PROFILE.new("river_wetlands", "River Wetlands", Vector2i(0, 1), "Waterfall Pool", {"prey": [2, 3], "plants": true}, "res://world_chunks/river_wetlands.tscn", Color("#6bb8a0"), 1.2, 0.012),
		CHUNK_PROFILE.new("sunstone_ridge", "Sunstone Ridge", Vector2i(1, 1), "Roaring Overlook", {"prey": [2], "predators": [2]}, "res://world_chunks/sunstone_ridge.tscn", Color("#c88b55"), 0.7, 0.005),
		CHUNK_PROFILE.new("redstone_badlands", "Redstone Badlands", Vector2i(2, 1), "Rival Arena", {"predators": [2, 3, 4]}, "res://world_chunks/redstone_badlands.tscn", Color("#c97862"), 0.45, 0.004),
		CHUNK_PROFILE.new("ancient_meadow", "Ancient Meadow", Vector2i(0, 2), "Herd Sanctuary", {"prey": [1, 2, 3], "plants": true}, "res://world_chunks/ancient_meadow.tscn", Color("#91c85a"), 1.35, 0.007)
	]
	for chunk in chunks:
		var neighbors: Array[String] = []
		for other in chunks:
			if chunk == other:
				continue
			if chunk.grid_position.distance_to(other.grid_position) <= 1.01:
				neighbors.append(other.chunk_id)
		chunk.set_neighbors(neighbors)
	return chunks
