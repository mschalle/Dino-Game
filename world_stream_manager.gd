class_name WorldStreamManager
extends RefCounted

const HABITAT_RULES = preload("res://habitat_spawn_rules.gd")
const TERRAIN = preload("res://valley_terrain.gd")

signal chunk_activated(chunk_id: String)
signal chunk_deactivated(chunk_id: String)

var chunks: Array = []
var active_ids: Dictionary = {}
var simulated_ids: Dictionary = {}
var scene_instances: Dictionary = {}
var distant_instances: Dictionary = {}
var connection_links: Dictionary = {}
var chunk_states: Dictionary = {}
var activation_samples: Array[Dictionary] = []
const CACHE_LIMIT := 8
var cached_instances: Dictionary = {}
var cache_owners: Dictionary = {}
var actor_pool: Array[Dictionary] = []
const ACTOR_POOL_LIMIT := 25
var defer_decoration := false
var decoration_samples: Array[Dictionary] = []
var active_radius := 1
var chunk_world_size := 60.0
const UNLOAD_MARGIN := 6.0

func configure(chunk_profiles: Array, radius: int = 1) -> void:
	_clear_cached_chunks()
	clear_actor_pool()
	for instance in distant_instances.values():
		if is_instance_valid(instance):
			instance.free()
	distant_instances.clear()
	chunks = chunk_profiles.duplicate()
	active_radius = maxi(0, radius)
	active_ids.clear()
	simulated_ids.clear()
	scene_instances.clear()
	connection_links.clear()
	chunk_states.clear()
	activation_samples.clear()
	decoration_samples.clear()

func update_player_position(world_position: Vector3) -> void:
	update_player_chunk(grid_position_at_world_position(world_position),world_position)

func update_player_chunk(grid_position: Vector2i, world_position: Variant = null) -> void:
	var next_active: Dictionary = {}
	simulated_ids.clear()
	for chunk in chunks:
		var offset: Vector2i = chunk.grid_position-grid_position
		var distance := maxi(abs(chunk.grid_position.x - grid_position.x), abs(chunk.grid_position.y - grid_position.y))
		if distance <= active_radius:
			next_active[chunk.chunk_id] = true
			if absi(offset.x)+absi(offset.y)<=1:
				simulated_ids[chunk.chunk_id] = true
		elif world_position is Vector3 and active_ids.has(chunk.chunk_id):
			var center := Vector3(chunk.grid_position.x*chunk_world_size,0,chunk.grid_position.y*chunk_world_size)
			var separation: Vector3 = world_position-center
			var unload_distance := (float(active_radius)+0.5)*chunk_world_size+UNLOAD_MARGIN
			if maxf(absf(separation.x),absf(separation.z))<=unload_distance:
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

func advance_decoration() -> void:
	# One phase globally per frame, not one phase for every newly loaded chunk.
	for chunk_id in scene_instances:
		var instance: Node3D = scene_instances[chunk_id]
		if not instance.decoration_steps.is_empty():
			var started := Time.get_ticks_usec()
			var phase: StringName = instance.decoration_steps[0].get_method()
			instance.build_next_decoration()
			if instance.decoration_steps.is_empty():
				instance.apply_chunk_profile(_find_chunk(chunk_id))
			instance.apply_visual_tier(str(instance.get_meta("stream_tier","full")),true)
			decoration_samples.append({"chunk_id":chunk_id,"phase":str(phase),"build_ms":float(Time.get_ticks_usec()-started)/1000.0,"completed_usec":Time.get_ticks_usec()})
			if decoration_samples.size()>32:
				decoration_samples.pop_front()
			return

func update_visual_tiers(parent: Node, grid: Vector2i) -> void:
	for chunk_id in scene_instances:
		var profile := _find_chunk(chunk_id)
		scene_instances[chunk_id].apply_visual_tier("full" if profile.grid_position==grid else "adjacent")
	var desired: Dictionary = {}
	for profile in chunks:
		var offset: Vector2i = profile.grid_position-grid
		if maxi(absi(offset.x),absi(offset.y))<=active_radius+1 and not is_active(profile.chunk_id):
			desired[profile.chunk_id] = profile
	for chunk_id in distant_instances.keys():
		if not desired.has(chunk_id):
			distant_instances[chunk_id].queue_free()
			distant_instances.erase(chunk_id)
	# Bound distant construction to one presentation-only scene per update.
	for chunk_id in desired:
		if distant_instances.has(chunk_id):
			continue
		var instance := preload("res://distant_chunk_visual.gd").new()
		instance.configure(desired[chunk_id])
		parent.add_child(instance)
		distant_instances[chunk_id] = instance
		break

func is_simulated(chunk_id: String) -> bool:
	return simulated_ids.has(chunk_id)

func update_actor_simulation(scene_root: Node) -> void:
	for group_name in ["prey","predator"]:
		for actor in scene_root.get_tree().get_nodes_in_group(group_name):
			if not actor is Node3D or actor.is_queued_for_deletion():
				continue
			var simulate := is_simulated(chunk_id_at_world_position(actor.global_position))
			if not simulate and not actor.has_meta("stream_process_mode"):
				actor.set_meta("stream_process_mode",actor.process_mode)
				actor.process_mode = Node.PROCESS_MODE_DISABLED
			elif simulate and actor.has_meta("stream_process_mode"):
				actor.process_mode = int(actor.get_meta("stream_process_mode"))
				actor.remove_meta("stream_process_mode")

func profile_for_chunk(chunk_id: String) -> RefCounted:
	return _find_chunk(chunk_id)

func active_biome_names() -> Array[String]:
	var names: Array[String] = []
	var seen: Dictionary = {}
	for chunk_id in active_chunk_ids():
		var profile := profile_for_chunk(str(chunk_id))
		if profile != null and not seen.has(profile.biome):
			names.append(profile.biome)
			seen[profile.biome] = true
	names.sort()
	return names

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
		if not is_simulated(chunk.chunk_id):
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
			var habitat_id := ""
			var grid := grid_position_at_world_position(actor.global_position)
			for profile in chunks:
				if profile.grid_position==grid:
					habitat_id = profile.chunk_id
			if (actor is PreyDino or actor is ValleyPredator) and not habitat_id.is_empty() and not actor.is_queued_for_deletion():
				var parent := actor.get_parent()
				parent.remove_child(actor)
				var owner := preload("res://cached_chunk_owner.gd").new()
				owner.chunk = actor
				parent.add_child(owner)
				actor_pool.append({"actor":actor,"parent":parent,"owner":owner,"habitat":habitat_id})
				if actor_pool.size()>ACTOR_POOL_LIMIT:
					var oldest: Dictionary = actor_pool.pop_front()
					if is_instance_valid(oldest.owner):
						oldest.owner.free()
			else:
				actor.queue_free()
			removed += 1
	return removed

func restore_pooled_actors(scene_root: Node, limit: int = 25) -> void:
	var count := scene_root.get_tree().get_nodes_in_group("prey").size()+scene_root.get_tree().get_nodes_in_group("predator").size()
	for record in actor_pool.duplicate():
		if not is_instance_valid(record.actor) or not is_instance_valid(record.parent):
			actor_pool.erase(record)
			continue
		if count>=limit or not is_simulated(record.habitat) or not record.parent.is_inside_tree() or record.parent.is_queued_for_deletion():
			continue
		record.owner.chunk = null
		record.owner.free()
		record.parent.add_child(record.actor)
		actor_pool.erase(record)
		count += 1

func clear_actor_pool() -> void:
	for record in actor_pool:
		if is_instance_valid(record.owner):
			record.owner.free()
	actor_pool.clear()

func capture_population(scene_root: Node) -> void:
	var counts: Dictionary = {}
	var herds: Dictionary = {}
	var herd_anchors: Dictionary = {}
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
			if group_name == "prey" and actor is PreyDino and not (actor as PreyDino).herd_id.is_empty():
				var chunk_herds: Dictionary = herds.get(chunk_id, {})
				var chunk_anchors: Dictionary = herd_anchors.get(chunk_id, {})
				var herd_id := (actor as PreyDino).herd_id
				chunk_herds[herd_id] = int(chunk_herds.get(herd_id, 0)) + 1
				if not chunk_anchors.has(herd_id):
					var anchor := (actor as PreyDino).herd_anchor
					chunk_anchors[herd_id] = {"x": anchor.x, "y": anchor.y, "z": anchor.z}
				herds[chunk_id] = chunk_herds
				herd_anchors[chunk_id] = chunk_anchors
	for chunk in chunks:
		if not is_active(chunk.chunk_id):
			continue
		var state := get_chunk_state(chunk.chunk_id)
		state["population"] = counts.get(chunk.chunk_id, {"prey": 0, "predator": 0})
		state["herds"] = herds.get(chunk.chunk_id, {})
		state["herd_anchors"] = herd_anchors.get(chunk.chunk_id, {})
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

func active_herd_budget() -> Dictionary:
	var herds: Dictionary = {}
	for chunk in chunks:
		if not is_active(chunk.chunk_id):
			continue
		var saved_herds: Dictionary = get_chunk_state(chunk.chunk_id).get("herds", {})
		for herd_id in saved_herds.keys():
			herds[herd_id] = int(herds.get(herd_id, 0)) + int(saved_herds[herd_id])
	return herds

func active_herd_records() -> Dictionary:
	var records: Dictionary = {}
	for chunk in chunks:
		if not is_active(chunk.chunk_id):
			continue
		var state := get_chunk_state(chunk.chunk_id)
		var saved_herds: Dictionary = state.get("herds", {})
		var saved_anchors: Dictionary = state.get("herd_anchors", {})
		for herd_id_variant in saved_herds.keys():
			var herd_id := str(herd_id_variant)
			var tier_parts := herd_id.split("_")
			var tier := int(tier_parts[1]) if tier_parts.size() > 1 else 0
			records[herd_id] = {
				"count": clampi(int(saved_herds[herd_id_variant]), 1, 4),
				"tier": tier,
				"anchor": saved_anchors.get(herd_id_variant, Vector3.ZERO)
			}
	return records

func runtime_metrics(scene_root: Node) -> Dictionary:
	var npc_count := 0
	var pending_decoration := 0
	var full_chunks := 0
	for instance in scene_instances.values():
		pending_decoration += instance.decoration_steps.size()
		if instance.get_meta("stream_tier","full")=="full":
			full_chunks += 1
	for group_name in ["prey", "predator"]:
		npc_count += scene_root.get_tree().get_nodes_in_group(group_name).size()
	var budget := active_population_budget()
	var herd_budget := active_herd_budget()
	var herd_records := active_herd_records()
	var total_budget := int(budget.get("prey", 0)) + int(budget.get("predator", 0))
	var biome_names := active_biome_names()
	return {
		"active_chunks": active_ids.size(),
		"simulated_chunks": simulated_ids.size(),
		"cached_chunks": cached_instances.size(),
		"pooled_actors": actor_pool.size(),
		"pending_decoration_phases": pending_decoration,
		"distant_chunk_scenes": distant_instances.size(),
		"full_chunk_scenes": full_chunks,
		"adjacent_chunk_scenes": scene_instances.size()-full_chunks,
		"active_biomes": biome_names,
		"active_biome_count": biome_names.size(),
		"loaded_chunk_scenes": scene_instances.size(),
		"loaded_landmarks": active_landmark_positions().size(),
		"npc_count": npc_count,
		"population_budget": total_budget,
		"population_utilization": float(npc_count) / float(maxi(1, total_budget)),
		"active_herd_count": herd_budget.size(),
		"herd_budget": herd_budget,
		"restorable_herd_count": herd_records.size()
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
	for record in actor_pool:
		if is_instance_valid(record.actor):
			record.actor.defeat_timer = maxf(0.0,record.actor.defeat_timer-delta)
			record.actor.combat.tick(delta)
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
	if cached_instances.has(chunk_id) and not is_instance_valid(cached_instances[chunk_id]):
		cached_instances.erase(chunk_id)
		cache_owners.erase(chunk_id)
	if cached_instances.has(chunk_id):
		var started := Time.get_ticks_usec()
		var reused: Node3D = cached_instances[chunk_id]
		cached_instances.erase(chunk_id)
		var owner: Node = cache_owners[chunk_id]
		owner.chunk = null
		owner.free()
		cache_owners.erase(chunk_id)
		parent.add_child(reused)
		if reused.has_method("apply_chunk_state"):
			reused.apply_chunk_state(get_chunk_state(chunk_id))
		if reused.has_node("AssetPackDressing") and preload("res://jungle_habitat.gd").contains(str(reused.get_meta("biome",""))):
			preload("res://jungle_dressing.gd").apply_quality(reused)
		scene_instances[chunk_id] = reused
		_create_neighbor_links(_find_chunk(chunk_id),parent)
		activation_samples.append({"chunk_id":chunk_id,"reused":true,"build_ms":float(Time.get_ticks_usec()-started)/1000.0,"completed_usec":Time.get_ticks_usec()})
		if activation_samples.size() > 32:
			activation_samples.pop_front()
		return reused
	for chunk in chunks:
		if chunk.chunk_id != chunk_id or not chunk.has_scene():
			continue
		var started := Time.get_ticks_usec()
		var scene := load(chunk.scene_path) as PackedScene
		if scene == null:
			return null
		var instance := scene.instantiate() as Node3D
		if instance == null:
			return null
		instance.position = Vector3(chunk.grid_position.x * chunk_world_size, 0.0, chunk.grid_position.y * chunk_world_size)
		instance.set_meta("defer_decoration",defer_decoration)
		parent.add_child(instance)
		if instance.has_method("apply_chunk_profile"):
			instance.apply_chunk_profile(chunk)
		if instance.has_method("apply_chunk_state"):
			instance.apply_chunk_state(get_chunk_state(chunk_id))
		scene_instances[chunk_id] = instance
		_create_neighbor_links(chunk, parent)
		activation_samples.append({"chunk_id":chunk_id,"build_ms":float(Time.get_ticks_usec()-started)/1000.0,"core":instance.get_meta("core_timings",{}),"completed_usec":Time.get_ticks_usec()})
		if activation_samples.size() > 32:
			activation_samples.pop_front()
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

func active_landmark_positions() -> Dictionary:
	var result: Dictionary = {}
	var active_chunk_ids_sorted := active_chunk_ids()
	active_chunk_ids_sorted.sort()
	for chunk_id in active_chunk_ids_sorted:
		var position: Variant = landmark_position_for_chunk(str(chunk_id))
		if position is Vector3:
			result[str(chunk_id)] = position
	return result

func nearest_active_landmark(world_position: Vector3) -> Variant:
	var nearest: Variant = null
	var best_distance := INF
	for position in active_landmark_positions().values():
		var landmark_position: Vector3 = position
		var distance := world_position.distance_squared_to(landmark_position)
		if distance < best_distance:
			best_distance = distance
			nearest = landmark_position
	return nearest

func release_chunk(chunk_id: String) -> void:
	_remove_neighbor_links(chunk_id)
	if not scene_instances.has(chunk_id):
		return
	var instance: Node3D = scene_instances[chunk_id]
	if is_instance_valid(instance):
		var parent := instance.get_parent()
		# Detached chunks have no physics, navigation, rendering or processing cost.
		# World-owned cache holders free detached scenes on eviction or teardown.
		parent.remove_child(instance)
		cached_instances[chunk_id] = instance
		var owner := preload("res://cached_chunk_owner.gd").new()
		owner.chunk = instance
		parent.add_child(owner)
		cache_owners[chunk_id] = owner
		while cached_instances.size() > CACHE_LIMIT:
			var oldest: String = cached_instances.keys()[0]
			cache_owners[oldest].free()
			cache_owners.erase(oldest)
			cached_instances.erase(oldest)
	scene_instances.erase(chunk_id)

func _clear_cached_chunks() -> void:
	for owner in cache_owners.values():
		if is_instance_valid(owner):
			owner.free()
	cache_owners.clear()
	cached_instances.clear()

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
		var midpoint := (start + end) * 0.5
		var direction := (end - start).normalized()
		start = midpoint - direction * 1.5
		end = midpoint + direction * 1.5
		start.y = TERRAIN.height_at(start.x, start.z) + 0.05
		end.y = TERRAIN.height_at(end.x, end.z) + 0.05
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
