class_name WorldChunkProfile
extends RefCounted

var chunk_id: String
var biome: String
var grid_position: Vector2i
var scene_path: String
var neighbor_ids: Array[String]
var landmark_name: String
var spawn_table: Dictionary
var ground_color: Color
var vegetation_density: float
var fog_density: float

func _init(new_id: String, new_biome: String, new_grid: Vector2i, new_landmark: String, new_spawns: Dictionary, new_scene_path: String = "", new_ground_color: Color = Color("#72ae50"), new_vegetation_density: float = 1.0, new_fog_density: float = 0.006) -> void:
	chunk_id = new_id
	biome = new_biome
	grid_position = new_grid
	landmark_name = new_landmark
	spawn_table = new_spawns
	scene_path = new_scene_path
	ground_color = new_ground_color
	vegetation_density = new_vegetation_density
	fog_density = new_fog_density
	neighbor_ids = []

func set_neighbors(ids: Array[String]) -> WorldChunkProfile:
	neighbor_ids = ids.duplicate()
	return self

func has_scene() -> bool:
	return not scene_path.is_empty() and ResourceLoader.exists(scene_path)
