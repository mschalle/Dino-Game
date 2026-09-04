class_name FoodSpawner
extends Node3D

const PREY = preload("res://prey.gd")
const PLANT = preload("res://plant_food.gd")

var player: PlayerDino
var respawn_timer := 0.0
var endless_mode := false

func configure(is_endless: bool) -> void:
	endless_mode = is_endless
	_spawn_to_targets(0)

func set_player(new_player: PlayerDino) -> void:
	player = new_player
	for prey_node in get_tree().get_nodes_in_group("prey"):
		(prey_node as PreyDino).set_player(player)

func maintain(delta: float, survival_time: float) -> void:
	respawn_timer -= delta
	if respawn_timer > 0.0:
		return
	respawn_timer = 3.0
	var scarcity := mini(int(survival_time / 180.0), 4) if endless_mode else 0
	_spawn_to_targets(scarcity)

func _spawn_to_targets(scarcity: int) -> void:
	var prey_nodes := get_tree().get_nodes_in_group("prey")
	var tier_counts: Dictionary = {1: 0, 2: 0, 3: 0}
	for prey_node in prey_nodes:
		var nutrition := int(prey_node.get("nutrition"))
		if tier_counts.has(nutrition):
			tier_counts[nutrition] = int(tier_counts[nutrition]) + 1
	var tier_targets: Dictionary = {
		1: maxi(3 if endless_mode else 5, 5 - scarcity),
		2: maxi(1, 3 - scarcity),
		3: maxi(0, 2 - scarcity)
	}
	for nutrition in tier_targets:
		for index in maxi(0, int(tier_targets[nutrition]) - int(tier_counts[nutrition])):
			_spawn_prey(int(nutrition))
	var plant_target := maxi(5, 9 - scarcity)
	var plant_missing := maxi(0, plant_target - get_tree().get_nodes_in_group("plant_food").size())
	for index in plant_missing:
		_spawn_plant()

func _spawn_prey(forced_nutrition: int = 0) -> void:
	var prey := PREY.new()
	var nutrition := forced_nutrition if forced_nutrition > 0 else randi_range(1, 3)
	var colors: Array[Color] = [Color("#f3c353"), Color("#f2996b"), Color("#78cfd0"), Color("#c190e8")]
	prey.setup("Valley Dino", nutrition, colors.pick_random())
	prey.position = _random_position()
	add_child(prey)
	if player != null:
		prey.set_player(player)

func _spawn_plant() -> void:
	var plant := PLANT.new()
	var nutrition := randi_range(1, 3)
	var colors: Array[Color] = [Color("#60c879"), Color("#d8709e"), Color("#84c85c"), Color("#d6c65d")]
	plant.setup("Valley Plant", nutrition, colors.pick_random())
	plant.position = _random_position()
	add_child(plant)

func _random_position() -> Vector3:
	var position_2d := Vector2(randf_range(-23.0, 23.0), randf_range(-23.0, 23.0))
	while position_2d.length() < 5.0:
		position_2d = Vector2(randf_range(-23.0, 23.0), randf_range(-23.0, 23.0))
	return Vector3(position_2d.x, 0.0, position_2d.y)
