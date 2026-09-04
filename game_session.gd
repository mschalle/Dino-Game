class_name GameSession
extends RefCounted

signal food_consumed(food_id: String, growth_awarded: int)
signal player_defeated
signal health_changed(value: float)
signal hunger_changed(value: float)

var profile: DinosaurProfile
var mode: String = "adventure"
var growth := GrowthSystem.new()
var health: float = 100.0
var hunger: float = 100.0
var survival_time: float = 0.0
var time_since_damage: float = 99.0
var quests_completed: int = 0
var defeat_in_progress := false

func start(new_profile: DinosaurProfile, new_mode: String) -> void:
	profile = new_profile
	mode = new_mode
	growth.configure(profile.growth_thresholds)
	health = profile.max_health
	hunger = 100.0
	survival_time = 0.0
	time_since_damage = 99.0
	quests_completed = 0
	defeat_in_progress = false

func tick(delta: float, danger_nearby: bool) -> void:
	if defeat_in_progress:
		return
	survival_time += delta
	time_since_damage += delta
	hunger = maxf(0.0, hunger - profile.hunger_drain_per_second * delta)
	if hunger <= 0.0:
		_apply_health_change(-5.0 * delta)
	elif hunger > 50.0 and time_since_damage >= 5.0 and not danger_nearby:
		_apply_health_change(2.0 * delta)
	hunger_changed.emit(hunger)
	if health <= 0.0:
		defeat_in_progress = true
		player_defeated.emit()

func consume(food_id: String, nutrition: int) -> void:
	var growth_award := maxi(nutrition, 1)
	hunger = minf(100.0, hunger + 15.0 + nutrition * 8.0)
	growth.add_points(growth_award)
	food_consumed.emit(food_id, growth_award)
	hunger_changed.emit(hunger)

func take_damage(amount: float) -> void:
	if defeat_in_progress:
		return
	time_since_damage = 0.0
	_apply_health_change(-absf(amount))
	if health <= 0.0:
		defeat_in_progress = true
		player_defeated.emit()

func respawn_at_stage_floor() -> void:
	growth.reset_to_stage_floor()
	health = profile.max_health
	hunger = 100.0
	time_since_damage = 99.0
	defeat_in_progress = false
	health_changed.emit(health)
	hunger_changed.emit(hunger)

func _apply_health_change(amount: float) -> void:
	health = clampf(health + amount, 0.0, profile.max_health)
	health_changed.emit(health)
