class_name CreatureProfile
extends RefCounted

var id: String
var display_name: String
var role: String
var tier: int
var max_health: float
var attack_damage: float
var move_speed: float
var flee_speed: float
var detection_range: float
var attack_range: float
var attack_cooldown: float
var growth_reward: int
var hunger_reward: float
var respawn_delay: float
var body_color: Color

func _init(new_id: String, new_name: String, new_role: String, new_tier: int, new_color: Color) -> void:
	id = new_id
	display_name = new_name
	role = new_role
	tier = new_tier
	body_color = new_color
	var health_values := [0.0, 30.0, 60.0, 100.0, 160.0]
	var damage_values := [0.0, 5.0, 10.0, 16.0, 22.0]
	var growth_values := [0, 1, 3, 6, 10]
	var respawn_values := [0.0, 20.0, 30.0, 45.0, 0.0]
	max_health = health_values[tier]
	attack_damage = damage_values[tier]
	growth_reward = growth_values[tier]
	respawn_delay = respawn_values[tier]
	hunger_reward = 16.0 + tier * 7.0
	move_speed = 2.5 + tier * 0.45
	flee_speed = 3.8 + tier * 0.65
	detection_range = 7.0 + tier * 1.5
	attack_range = 1.7
	attack_cooldown = 1.5
