class_name WorldStreamManager
extends RefCounted

const HABITAT_RULES = preload("res://habitat_spawn_rules.gd")

signal chunk_activated(chunk_id: String)
signal chunk_deactivated(chunk_id: String)

var chunks: Array = []
var active_ids: Dictionary = {}
var scene_instances: Dictionary = {}
var connection_links: Dictionary = {}
var chunk_states: Dictionary = {}
var active_radius := 1
var chunk_world_size := 60.0

func configure(chunk_profiles: Array, radius: int = 1) -> void:
	chunks = chunk_profiles.duplicate()
	active_radius = maxi(0, radius)
	active_ids.clear()
	scene_instances.clear()
	connection_links.clear()
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

func grid_position_at_world_position(world_position: Vector3) -> Vector2i:
	return Vector2i(roundi(world_position.x / chunk_world_size), roundi(world_position.z / chunk_world_size))

func active_spawn_plan() -> Array[Dictionary]:
	var plan: Array[Dictionary] = []
	for chunk in chunks:
		if not is_active(chunk.chunk_id):
			continue
		var rules := HABITAT_RULES.for_biome(chunk.biome)
		for tier in rules.get("prey_tiers", []):
			plan.append({"chunk_id": chunk.chunk_id, "biome": chunk.biome, "role": "prey", "tier": int(tier)})
		for tier in rules.get("predator_tiers", []):
			plan.append({"chunk_id": chunk.chunk_id, "biome": chunk.biome, "role": "predator", "tier": int(tier)})
	return plan

func chunk_id_at_world_position(world_position: Vector3) -> String:
	var grid := grid_position_at_world_position(world_position)
	for chunk in chunks:
		if chunk.grid_position == grid and is_active(chunk.chunk_id):
			return chunk.chunk_id
	return ""

func is_world_position_navigable(world_position: Vector3) -> bool:
	return not chunk_id_at_world_position(world_position).is_empty() and world_position.y >= -1.0

func confine_actor(actor: Node3D, fallback: Vector3) -> bool:
	if is_world_position_navigable(actor.global_position):
		return false
	var nearest: Variant = _nearest_active_chunk_position(actor.global_position)
	if nearest == null:
		actor.global_position = fallback
	else:
		actor.global_position = nearest
	return true

func prune_inactive_actors(scene_root: Node) -> int:
	var removed := 0
	for group_name in ["prey", "predator"]:
		for node in scene_root.get_tree().get_nodes_in_group(group_name):
			var actor := node as Node3D
			if actor == null or is_world_position_navigable(actor.global_position):
				continue
			actor.queue_free()
			removed += 1
	return removed

func capture_population(scene_root: Node) -> void:
	var counts: Dictionary = {}
	for group_name in ["prey", "predator"]:
		for node in scene_root.get_tree().get_nodes_in_group(group_name):
			var actor := node as Node3D
			if actor == null:
				continue
			var chunk_id := chunk_id_at_world_position(actor.global_position)
			if chunk_id.is_empty():
				continue
			var role_counts: Dictionary = counts.get(chunk_id, {"prey": 0, "predator": 0})
			role_counts[group_name] = int(role_counts.get(group_name, 0)) + 1
			counts[chunk_id] = role_counts
	for chunk in chunks:
		var state := get_chunk_state(chunk.chunk_id)
		state["population"] = counts.get(chunk.chunk_id, {"prey": 0, "predator": 0})
		set_chunk_state(chunk.chunk_id, state)

func active_population_budget() -> Dictionary:
	var budget: Dictionary = {"prey": 0, "predator": 0}
	for chunk in chunks:
		if not is_active(chunk.chunk_id):
			continue
		var population: Dictionary = get_chunk_state(chunk.chunk_id).get("population", {})
		budget["prey"] = int(budget["prey"]) + int(population.get("prey", 0))
		budget["predator"] = int(budget["predator"]) + int(population.get("predator", 0))
	return budget

func runtime_metrics(scene_root: Node) -> Dictionary:
	var npc_count := 0
	for group_name in ["prey", "predator"]:
		npc_count += scene_root.get_tree().get_nodes_in_group(group_name).size()
	var budget := active_population_budget()
	var total_budget := int(budget.get("prey", 0)) + int(budget.get("predator", 0))
	return {
		"active_chunks": active_ids.size(),
		"loaded_chunk_scenes": scene_instances.size(),
		"npc_count": npc_count,
		"population_budget": total_budget,
		"population_utilization": float(npc_count) / float(maxi(1, total_budget))
	}

func set_respawn_cooldown(chunk_id: String, seconds: float) -> void:
	var state := get_chunk_state(chunk_id)
	state["respawn_cooldown"] = maxf(0.0, seconds)
	set_chunk_state(chunk_id, state)

func start_respawn_cooldown_at(world_position: Vector3, seconds: float) -> String:
	var chunk_id := chunk_id_at_world_position(world_position)
	if not chunk_id.is_empty():
		set_respawn_cooldown(chunk_id, seconds)
	return chunk_id

func set_tier_respawn_cooldown(chunk_id: String, role: String, tier: int, seconds: float) -> void:
	var state := get_chunk_state(chunk_id)
	var cooldowns: Dictionary = state.get("tier_respawn_cooldowns", {})
	cooldowns["%s_%d" % [role, tier]] = maxf(0.0, seconds)
	state["tier_respawn_cooldowns"] = cooldowns
	set_chunk_state(chunk_id, state)

func get_tier_respawn_cooldown(chunk_id: String, role: String, tier: int) -> float:
	var cooldowns: Dictionary = get_chunk_state(chunk_id).get("tier_respawn_cooldowns", {})
	return maxf(0.0, float(cooldowns.get("%s_%d" % [role, tier], 0.0)))

func tier_respawn_ready(chunk_id: String, role: String, tier: int) -> bool:
	return get_tier_respawn_cooldown(chunk_id, role, tier) <= 0.0

func get_respawn_cooldown(chunk_id: String) -> float:
	return maxf(0.0, float(get_chunk_state(chunk_id).get("respawn_cooldown", 0.0)))

func active_respawn_cooldown() -> float:
	var highest := 0.0
	for chunk in chunks:
		if is_active(chunk.chunk_id):
			highest = maxf(highest, get_respawn_cooldown(chunk.chunk_id))
	return highest

func active_tier_respawn_cooldowns() -> Dictionary:
	var result: Dictionary = {}
	for chunk in chunks:
		if not is_active(chunk.chunk_id):
			continue
		var cooldowns: Dictionary = get_chunk_state(chunk.chunk_id).get("tier_respawn_cooldowns", {})
		for key in cooldowns:
			result[key] = maxf(float(result.get(key, 0.0)), float(cooldowns[key]))
	return result

func tick_respawn_cooldowns(delta: float) -> void:
	for chunk in chunks:
		var cooldown := get_respawn_cooldown(chunk.chunk_id)
		var state := get_chunk_state(chunk.chunk_id)
		var tier_cooldowns: Dictionary = state.get("tier_respawn_cooldowns", {})
		for key in tier_cooldowns:
			tier_cooldowns[key] = maxf(0.0, float(tier_cooldowns[key]) - delta)
		state["tier_respawn_cooldowns"] = tier_cooldowns
		if cooldown > 0.0:
			state["respawn_cooldown"] = maxf(0.0, cooldown - delta)
		set_chunk_state(chunk.chunk_id, state)

func _nearest_active_chunk_position(world_position: Vector3) -> Variant:
	var best: Variant = null
	var best_distance := INF
	for chunk in chunks:
		if not is_active(chunk.chunk_id):
			continue
		var center := Vector3(chunk.grid_position.x * chunk_world_size, 0.0, chunk.grid_position.y * chunk_world_size)
		var distance := center.distance_squared_to(world_position)
		if distance < best_distance:
			best_distance = distance
			best = center
	return best

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
		if instance.has_method("apply_chunk_profile"):
			instance.apply_chunk_profile(chunk)
		if instance.has_method("apply_chunk_state"):
			instance.apply_chunk_state(get_chunk_state(chunk_id))
		scene_instances[chunk_id] = instance
		_create_neighbor_links(chunk, parent)
		return instance
	return null

func landmark_for_chunk(chunk_id: String) -> Node3D:
	var instance := scene_instances.get(chunk_id) as Node3D
	if instance == null or not is_instance_valid(instance):
		return null
	return instance.get_node_or_null("LandmarkSilhouette") as Node3D

func landmark_position_for_chunk(chunk_id: String) -> Variant:
	var landmark := landmark_for_chunk(chunk_id)
	if landmark == null:
		return null
	return landmark.global_position

func release_chunk(chunk_id: String) -> void:
	_remove_neighbor_links(chunk_id)
	if not scene_instances.has(chunk_id):
		return
	var instance: Node3D = scene_instances[chunk_id]
	if is_instance_valid(instance):
		instance.queue_free()
	scene_instances.erase(chunk_id)

func _create_neighbor_links(chunk: RefCounted, parent: Node) -> void:
	for neighbor_id in chunk.neighbor_ids:
		var key := _connection_key(chunk.chunk_id, neighbor_id)
		if connection_links.has(key) or not scene_instances.has(neighbor_id):
			continue
		var neighbor := _find_chunk(neighbor_id)
		if neighbor == null:
			continue
		var link := NavigationLink3D.new()
		link.name = "Link_%s" % key
		var start := Vector3(chunk.grid_position.x * chunk_world_size, 0.05, chunk.grid_position.y * chunk_world_size)
		var end := Vector3(neighbor.grid_position.x * chunk_world_size, 0.05, neighbor.grid_position.y * chunk_world_size)
		link.start_position = start
		link.end_position = end
		link.enter_cost = 1.0
		link.travel_cost = start.distance_to(end)
		parent.add_child(link)
		connection_links[key] = link

func _remove_neighbor_links(chunk_id: String) -> void:
	for key in connection_links.keys():
		if str(key).begins_with(chunk_id + "|") or str(key).ends_with("|" + chunk_id):
			var link: NavigationLink3D = connection_links[key]
			if is_instance_valid(link):
				link.queue_free()
			connection_links.erase(key)

func _find_chunk(chunk_id: String) -> RefCounted:
	for chunk in chunks:
		if chunk.chunk_id == chunk_id:
			return chunk
	return null

func _connection_key(first: String, second: String) -> String:
	return first + "|" + second if first < second else second + "|" + first

func set_chunk_state(chunk_id: String, state: Dictionary) -> void:
	chunk_states[chunk_id] = state.duplicate(true)

func get_chunk_state(chunk_id: String) -> Dictionary:
	return (chunk_states.get(chunk_id, {}) as Dictionary).duplicate(true)

func snapshot_state() -> Dictionary:
	return chunk_states.duplicate(true)

func restore_state(snapshot: Dictionary) -> void:
	chunk_states = snapshot.duplicate(true)
