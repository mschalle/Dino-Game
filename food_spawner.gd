class_name FoodSpawner
extends Node3D

signal creature_defeated(creature: Node3D, profile: RefCounted)

const PREY = preload("res://prey.gd")
const PLANT = preload("res://plant_food.gd")

var player: PlayerDino
var respawn_timer := 0.0
var endless_mode := false
var allowed_prey_tiers: Array[int] = [1, 2, 3]
var habitat_plan: Array[Dictionary] = []
var population_caps: Dictionary = {1: 5, 2: 3, 3: 2}
var persisted_population_budget := 0
var habitat_respawn_cooldown := 0.0
var tier_respawn_cooldowns: Dictionary = {}
var respawn_gate_factory: Callable
var persisted_herd_records: Dictionary = {}
var active_creature_limit := 25
var event_plant_bonus := 0

func configure(is_endless: bool) -> void:
	endless_mode = is_endless
	_spawn_to_targets(0)

func set_player(new_player: PlayerDino) -> void:
	player = new_player
	for prey_node in get_tree().get_nodes_in_group("prey"):
		var prey := prey_node as PreyDino
		if prey != null:
			prey.set_player(player)

func set_spawn_plan(plan: Array[Dictionary]) -> void:
	habitat_plan = plan
	var tiers: Array[int] = []
	var counts: Dictionary = {}
	for entry in plan:
		if entry.get("role", "") == "prey":
			var tier := int(entry.get("tier", 0))
			if tier > 0 and not tiers.has(tier):
				tiers.append(tier)
			counts[tier] = int(counts.get(tier, 0)) + 1
	if not tiers.is_empty():
		allowed_prey_tiers = tiers
		for tier in counts:
			population_caps[int(tier)] = maxi(1, int(counts[tier]) * 4)

func set_population_budget(budget: Dictionary) -> void:
	var prey_budget := int(budget.get("prey", 0))
	if prey_budget <= 0 or prey_budget == persisted_population_budget:
		return
	persisted_population_budget = prey_budget
	var total_caps := int(population_caps.get(1, 0)) + int(population_caps.get(2, 0)) + int(population_caps.get(3, 0))
	if total_caps <= prey_budget:
		return
	var population_scale := float(prey_budget) / float(total_caps)
	for tier in population_caps:
		population_caps[tier] = maxi(1, floori(float(population_caps[tier]) * population_scale))

func set_persisted_herd_records(records: Dictionary) -> void:
	# Records come from streamed chunks.  Keep a private copy so unloading a chunk
	# cannot mutate a herd while it is being rebuilt by the spawner.
	persisted_herd_records = records.duplicate(true)

func set_active_creature_limit(limit: int) -> void:
	active_creature_limit = maxi(1, limit)

func set_event_plant_bonus(amount: int) -> void:
	event_plant_bonus = clampi(amount, 0, 6)

func set_respawn_cooldown(seconds: float) -> void:
	habitat_respawn_cooldown = maxf(0.0, seconds)

func set_tier_respawn_cooldowns(cooldowns: Dictionary) -> void:
	tier_respawn_cooldowns = cooldowns.duplicate()

func set_respawn_gate_factory(factory: Callable) -> void:
	respawn_gate_factory = factory

func maintain(delta: float, survival_time: float) -> void:
	respawn_timer -= delta
	habitat_respawn_cooldown = maxf(0.0, habitat_respawn_cooldown - delta)
	if respawn_timer > 0.0:
		return
	respawn_timer = 3.0
	if habitat_respawn_cooldown > 0.0:
		return
	var scarcity := mini(int(survival_time / 180.0), 4) if endless_mode else 0
	_spawn_to_targets(scarcity)

func _spawn_to_targets(scarcity: int) -> void:
	var prey_nodes := get_tree().get_nodes_in_group("prey")
	var tier_counts: Dictionary = {1: 0, 2: 0, 3: 0}
	for prey_node in prey_nodes:
		var nutrition_value: Variant = prey_node.get("nutrition")
		if nutrition_value == null:
			continue
		var nutrition: int = nutrition_value
		if tier_counts.has(nutrition):
			tier_counts[nutrition] = int(tier_counts[nutrition]) + 1
	var tier_targets: Dictionary = {
		1: maxi(3 if endless_mode else 5, 5 - scarcity),
		2: maxi(1, 3 - scarcity),
		3: maxi(0, 2 - scarcity)
	}
	for nutrition in tier_targets:
		if not allowed_prey_tiers.has(int(nutrition)):
			continue
		if float(tier_respawn_cooldowns.get("prey_%d" % int(nutrition), 0.0)) > 0.0:
			continue
		tier_targets[nutrition] = mini(int(tier_targets[nutrition]), int(population_caps.get(int(nutrition), tier_targets[nutrition])))
		var missing := maxi(0, int(tier_targets[nutrition]) - int(tier_counts[nutrition]))
		for index in mini(missing, _available_creature_slots()):
			_spawn_prey(int(nutrition))
	var plant_target := maxi(5, 9 - scarcity) + event_plant_bonus
	var plant_missing := maxi(0, plant_target - get_tree().get_nodes_in_group("plant_food").size())
	for index in plant_missing:
		_spawn_plant()

func _available_creature_slots() -> int:
	var active_creatures := get_tree().get_nodes_in_group("prey").size() + get_tree().get_nodes_in_group("predator").size()
	return maxi(0, active_creature_limit - active_creatures)

func _spawn_prey(forced_nutrition: int = 0) -> void:
	var prey := PREY.new()
	var nutrition := forced_nutrition if forced_nutrition > 0 else randi_range(1, 3)
	var colors: Array[Color] = [Color("#f3c353"), Color("#f2996b"), Color("#78cfd0"), Color("#c190e8")]
	prey.setup("Valley Dino", nutrition, colors.pick_random())
	var restored_herd := _available_persisted_herd(nutrition)
	prey.position = _restored_herd_position(restored_herd) if not restored_herd.is_empty() else _random_position(nutrition)
	add_child(prey)
	_place_on_terrain(prey)
	var same_tier_count := 0
	for sibling in get_children():
		if sibling is PreyDino and (sibling as PreyDino).nutrition == nutrition:
			same_tier_count += 1
	var herd_id := str(restored_herd.get("id", "tier_%d_%d" % [nutrition, int(float(same_tier_count) / 4.0)]))
	var herd_anchor := prey.position
	var herd_leader := true
	if not restored_herd.is_empty():
		herd_anchor = _record_anchor(restored_herd.get("anchor", prey.position), prey.position)
	for sibling in get_children():
		if sibling is PreyDino and sibling != prey and (sibling as PreyDino).nutrition == nutrition and not (sibling as PreyDino).herd_id.is_empty():
			if (sibling as PreyDino).herd_id == herd_id:
				herd_anchor = (sibling as PreyDino).herd_anchor
				herd_leader = false
	prey.set_herd_context(herd_id, herd_leader, herd_anchor)
	prey.creature_defeated.connect(func(creature: Node3D, profile: RefCounted) -> void: creature_defeated.emit(creature, profile))
	if not respawn_gate_factory.is_null():
		prey.set_respawn_gate(respawn_gate_factory.bind(prey))
	if player != null:
		prey.set_player(player)

func _available_persisted_herd(nutrition: int) -> Dictionary:
	var record_ids: Array = persisted_herd_records.keys()
	record_ids.sort()
	for record_id in record_ids:
		var record: Dictionary = persisted_herd_records[record_id] as Dictionary
		if int(record.get("tier", 0)) != nutrition:
			continue
		var desired_count := clampi(int(record.get("count", 0)), 1, 4)
		var current_count := 0
		for sibling in get_children():
			if sibling is PreyDino and (sibling as PreyDino).herd_id == str(record_id):
				current_count += 1
		if current_count < desired_count:
			var result := record.duplicate(true)
			result["id"] = str(record_id)
			result["member_index"] = current_count
			return result
	return {}

func _restored_herd_position(record: Dictionary) -> Vector3:
	var anchor := _record_anchor(record.get("anchor", Vector3.ZERO), Vector3.ZERO)
	var member_index := int(record.get("member_index", 0))
	if member_index == 0:
		return anchor
	var angle := TAU * float(member_index) / 4.0
	return anchor + Vector3(cos(angle), 0.0, sin(angle)) * 1.7

func _record_anchor(value: Variant, fallback: Vector3) -> Vector3:
	if value is Vector3:
		return value
	if value is Dictionary:
		return Vector3(float(value.get("x", fallback.x)), float(value.get("y", fallback.y)), float(value.get("z", fallback.z)))
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return fallback

func _spawn_plant() -> void:
	var plant := PLANT.new()
	var nutrition := randi_range(1, 3)
	var colors: Array[Color] = [Color("#60c879"), Color("#d8709e"), Color("#84c85c"), Color("#d6c65d")]
	plant.setup("Valley Plant", nutrition, colors.pick_random())
	plant.position = _random_position(0)
	add_child(plant)
	_place_on_terrain(plant)

func _random_position(tier: int = 0) -> Vector3:
	var jungle = preload("res://jungle_habitat.gd")
	var best := -1
	var lowest := 100000
	for entry in habitat_plan:
		var index: int = jungle.BIOMES.find(str(entry.get("biome", "")))
		if index < 0 or entry.get("role", "") != "prey" or int(entry.get("tier", 0)) != tier:
			continue
		var count := 0
		for child in get_children():
			if child is PreyDino and child.nutrition == tier and child.habitat_origin == jungle.ORIGINS[index]:
				count += 1
		# Keep three easy prey in the starting basin before spreading the herd.
		if index == 0 and tier == 1 and count < 3:
			best = 0
			break
		if count < lowest:
			lowest = count
			best = index
	if best >= 0:
		var point: Vector2 = jungle.PREY_CLEARINGS[best] + Vector2(randf_range(-2.0,2.0),randf_range(-2.0,2.0))
		return Vector3(point.x,0,point.y)
	# Keep creatures in readable habitat bands: basin, meadow, then ridge.
	var center := Vector2.ZERO
	var radius := 10.0
	match tier:
		1:
			center = Vector2(-8.0, 8.0)
			radius = 9.0
		2:
			center = Vector2(-13.0, 11.0)
			radius = 7.0
		3:
			center = Vector2(0.0, -18.0)
			radius = 6.0
		_:
			center = Vector2(-4.0, 4.0)
			radius = 18.0
	var position_2d := center + Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
	while position_2d.length() < 5.0 or position_2d.x < -27.0 or position_2d.x > 27.0 or position_2d.y < -27.0 or position_2d.y > 27.0:
		position_2d = center + Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
	return Vector3(position_2d.x, 0.0, position_2d.y)

func _place_on_terrain(actor: Node3D) -> void:
	var world := get_tree().get_first_node_in_group("world_controller")
	if world != null and world.has_method("_terrain_height_at"):
		actor.position.y = float(world._terrain_height_at(actor.position.x, actor.position.z))
