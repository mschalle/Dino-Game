class_name WorldChunkProfiles
extends RefCounted

const CHUNK_PROFILE = preload("res://world_chunk_profile.gd")

static func reserve() -> Array[RefCounted]:
	var chunks: Array[RefCounted] = [
		CHUNK_PROFILE.new("nest_basin", "Nest Basin", Vector2i(0, 0), "Safe Nest", {"prey": [1], "plants": true}, "res://world_chunks/nest_basin.tscn", Color("#72ae50"), 1.0, 0.004, 1),
		CHUNK_PROFILE.new("fernwood", "Fernwood", Vector2i(1, 0), "Fernwood Trail", {"prey": [1, 2], "predators": [1]}, "res://world_chunks/fernwood.tscn", Color("#4f8e55"), 1.5, 0.009, 3),
		CHUNK_PROFILE.new("river_wetlands", "River Wetlands", Vector2i(0, 1), "Waterfall Pool", {"prey": [2, 3], "plants": true}, "res://world_chunks/river_wetlands.tscn", Color("#6bb8a0"), 1.2, 0.012, 3),
		CHUNK_PROFILE.new("sunstone_ridge", "Sunstone Ridge", Vector2i(1, 1), "Roaring Overlook", {"prey": [2], "predators": [2]}, "res://world_chunks/sunstone_ridge.tscn", Color("#c88b55"), 0.7, 0.005, 7),
		CHUNK_PROFILE.new("redstone_badlands", "Redstone Badlands", Vector2i(2, 1), "Rival Arena", {"predators": [2, 3, 4]}, "res://world_chunks/redstone_badlands.tscn", Color("#c97862"), 0.45, 0.004, 7),
		CHUNK_PROFILE.new("ancient_meadow", "Ancient Meadow", Vector2i(0, 2), "Herd Sanctuary", {"prey": [1, 2, 3], "plants": true}, "res://world_chunks/ancient_meadow.tscn", Color("#91c85a"), 1.35, 0.007, 3),
		CHUNK_PROFILE.new("cloudforest", "Cloudforest Rise", Vector2i(-1, 1), "Misty Canopy", {"prey": [2], "predators": [1]}, "res://world_chunks/cloudforest.tscn", Color("#568b78"), 1.1, 0.014, 3),
		CHUNK_PROFILE.new("coastal_marsh", "Coastal Marsh", Vector2i(1, 2), "Reed Crossing", {"prey": [1, 2], "plants": true}, "res://world_chunks/coastal_marsh.tscn", Color("#6caa8d"), 1.0, 0.01, 3),
		CHUNK_PROFILE.new("volcanic_foothills", "Volcanic Foothills", Vector2i(2, 2), "Ember Steps", {"prey": [2, 3], "predators": [2, 3]}, "res://world_chunks/volcanic_foothills.tscn", Color("#9c6257"), 0.55, 0.006, 7),
		CHUNK_PROFILE.new("fossil_flats", "Fossil Flats", Vector2i(-1, 2), "Bonewind Basin", {"prey": [1, 2], "predators": [1], "plants": true}, "res://world_chunks/fossil_flats.tscn", Color("#b49b68"), 0.9, 0.008, 3),
		CHUNK_PROFILE.new("redwood_canyon", "Redwood Canyon", Vector2i(-2, 1), "Echoing Gulch", {"prey": [1, 2], "predators": [1, 2], "plants": true}, "res://world_chunks/redwood_canyon.tscn", Color("#536f4d"), 1.25, 0.011, 3),
		CHUNK_PROFILE.new("highland_plateau", "Highland Plateau", Vector2i(2, 3), "Cloudbreak Shelf", {"prey": [3], "predators": [2, 3]}, "res://world_chunks/highland_plateau.tscn", Color("#8a8370"), 0.5, 0.005, 7),
		CHUNK_PROFILE.new("moonlit_grove", "Moonlit Grove", Vector2i(-2, 2), "Lunar Clearing", {"prey": [1, 2], "predators": [1], "plants": true}, "res://world_chunks/moonlit_grove.tscn", Color("#536c78"), 1.15, 0.01, 3),
		CHUNK_PROFILE.new("saltwind_dunes", "Saltwind Dunes", Vector2i(3, 2), "Windcarved Arch", {"prey": [2, 3], "predators": [2]}, "res://world_chunks/saltwind_dunes.tscn", Color("#c4a36c"), 0.6, 0.006, 7),
		CHUNK_PROFILE.new("glacier_valley", "Glacier Valley", Vector2i(3, 3), "Frostback Pass", {"prey": [3], "predators": [3]}, "res://world_chunks/glacier_valley.tscn", Color("#8bb4c2"), 0.35, 0.004, 7),
		CHUNK_PROFILE.new("cypress_basin", "Cypress Basin", Vector2i(-2, 3), "Cypress Gate", {"prey": [1, 2], "predators": [1, 2], "plants": true}, "res://world_chunks/cypress_basin.tscn", Color("#587b62"), 1.0, 0.013, 3)
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

static func connections_are_symmetric(chunk_profiles: Array) -> bool:
	var by_id: Dictionary = {}
	for chunk in chunk_profiles:
		by_id[chunk.chunk_id] = chunk
	for chunk in chunk_profiles:
		for neighbor_id in chunk.neighbor_ids:
			if not by_id.has(neighbor_id):
				return false
			var neighbor: Variant = by_id[neighbor_id]
			if not neighbor.neighbor_ids.has(chunk.chunk_id):
				return false
	return true

static func find_route(chunk_profiles: Array, start_id: String, destination_id: String) -> Array[String]:
	var by_id: Dictionary = {}
	for chunk in chunk_profiles:
		by_id[chunk.chunk_id] = chunk
	if not by_id.has(start_id) or not by_id.has(destination_id):
		return []
	var queue: Array[String] = [start_id]
	var previous: Dictionary = {start_id: ""}
	while not queue.is_empty():
		var current: String = queue.pop_front()
		if current == destination_id:
			break
		for neighbor_id in by_id[current].neighbor_ids:
			if not previous.has(neighbor_id):
				previous[neighbor_id] = current
				queue.append(neighbor_id)
	if not previous.has(destination_id):
		return []
	var route: Array[String] = []
	var cursor := destination_id
	while cursor != "":
		route.push_front(cursor)
		cursor = str(previous[cursor])
	return route
