class_name WorldStreamManager
extends RefCounted

signal chunk_activated(chunk_id: String)
signal chunk_deactivated(chunk_id: String)

var chunks: Array = []
var active_ids: Dictionary = {}
var scene_instances: Dictionary = {}
var chunk_states: Dictionary = {}
var active_radius := 1
var chunk_world_size := 60.0

func configure(chunk_profiles: Array, radius: int = 1) -> void:
	chunks = chunk_profiles.duplicate()
	active_radius = maxi(0, radius)
	active_ids.clear()
	scene_instances.clear()
	chunk_states.clear()

func update_player_chunk(grid_position: Vector2i) -> void:
	var next_active: Dictionary = {}
	for chunk in chunks:
		var distance := maxi(abs(chunk.grid_position.x - grid_position.x), abs(chunk.grid_position.y - grid_position.y))
		if distance <= active_radius:
			next_active[chunk.chunk_id] = true
	for chunk in chunks:
		var was_active := active_ids.has(chunk.chunk_id)
		var should_be_active := next_active.has(chunk.chunk_id)
		if should_be_active and not was_active:
			chunk_activated.emit(chunk.chunk_id)
		elif was_active and not should_be_active:
			chunk_deactivated.emit(chunk.chunk_id)
	active_ids = next_active

func is_active(chunk_id: String) -> bool:
	return active_ids.has(chunk_id)

func active_chunk_ids() -> Array[String]:
	var result: Array[String] = []
	for chunk_id in active_ids:
		result.append(str(chunk_id))
	return result

func instantiate_chunk(chunk_id: String, parent: Node) -> Node3D:
	if scene_instances.has(chunk_id):
		return scene_instances[chunk_id]
	for chunk in chunks:
		if chunk.chunk_id != chunk_id or not chunk.has_scene():
			continue
		var scene := load(chunk.scene_path) as PackedScene
		if scene == null:
			return null
		var instance := scene.instantiate() as Node3D
		if instance == null:
			return null
		instance.position = Vector3(chunk.grid_position.x * chunk_world_size, 0.0, chunk.grid_position.y * chunk_world_size)
		parent.add_child(instance)
		scene_instances[chunk_id] = instance
		return instance
	return null

func release_chunk(chunk_id: String) -> void:
	if not scene_instances.has(chunk_id):
		return
	var instance: Node3D = scene_instances[chunk_id]
	if is_instance_valid(instance):
		instance.queue_free()
	scene_instances.erase(chunk_id)

func set_chunk_state(chunk_id: String, state: Dictionary) -> void:
	chunk_states[chunk_id] = state.duplicate(true)

func get_chunk_state(chunk_id: String) -> Dictionary:
	return (chunk_states.get(chunk_id, {}) as Dictionary).duplicate(true)

func snapshot_state() -> Dictionary:
	return chunk_states.duplicate(true)

func restore_state(snapshot: Dictionary) -> void:
	chunk_states = snapshot.duplicate(true)
