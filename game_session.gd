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
var food_eaten := 0
var food_by_nutrition: Dictionary = {1: 0, 2: 0, 3: 0}
var defeat_count := 0
var damage_taken := 0.0
var starvation_seconds := 0.0
var stage_seconds: Array[float] = [0.0, 0.0, 0.0, 0.0]
var attacks_landed := 0
var damage_dealt := 0.0
var targets_defeated: Dictionary = {}
var tokens_claimed := 0

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
	food_eaten = 0
	food_by_nutrition = {1: 0, 2: 0, 3: 0}
	defeat_count = 0
	damage_taken = 0.0
	starvation_seconds = 0.0
	stage_seconds = [0.0, 0.0, 0.0, 0.0]
	attacks_landed = 0
	damage_dealt = 0.0
	targets_defeated = {}
	tokens_claimed = 0

func tick(delta: float, danger_nearby: bool) -> void:
	if defeat_in_progress:
		return
	survival_time += delta
	stage_seconds[growth.stage_index] += delta
	time_since_damage += delta
	hunger = maxf(0.0, hunger - profile.hunger_drain_per_second * delta)
	if hunger <= 0.0:
		starvation_seconds += delta
		_apply_health_change(-5.0 * delta)
	elif hunger > 50.0 and time_since_damage >= 5.0 and not danger_nearby:
		_apply_health_change(2.0 * delta)
	hunger_changed.emit(hunger)
	if health <= 0.0:
		defeat_in_progress = true
		player_defeated.emit()

func consume(food_id: String, nutrition: int) -> void:
	var growth_award := maxi(nutrition, 1)
	food_eaten += 1
	food_by_nutrition[growth_award] = int(food_by_nutrition.get(growth_award, 0)) + 1
	hunger = minf(100.0, hunger + 15.0 + nutrition * 8.0)
	growth.add_points(growth_award)
	food_consumed.emit(food_id, growth_award)
	hunger_changed.emit(hunger)

func claim_creature_reward(species_id: String, tier: int, growth_reward: int, hunger_reward: float) -> void:
	tokens_claimed += 1
	food_eaten += 1
	food_by_nutrition[tier] = int(food_by_nutrition.get(tier, 0)) + 1
	hunger = minf(100.0, hunger + hunger_reward)
	growth.add_points(growth_reward)
	food_consumed.emit("prey", growth_reward)
	hunger_changed.emit(hunger)

func record_attack(damage: float) -> void:
	attacks_landed += 1
	damage_dealt += damage

func record_target_defeated(species_id: String, tier: int) -> void:
	var key := "%s_tier_%d" % [species_id, tier]
	targets_defeated[key] = int(targets_defeated.get(key, 0)) + 1

func take_damage(amount: float) -> void:
	if defeat_in_progress:
		return
	time_since_damage = 0.0
	var applied_damage := absf(amount)
	damage_taken += applied_damage
	_apply_health_change(-applied_damage)
	if health <= 0.0:
		defeat_in_progress = true
		player_defeated.emit()

func respawn_at_stage_floor() -> void:
	defeat_count += 1
	growth.reset_to_stage_floor()
	health = profile.max_health
	hunger = 100.0
	time_since_damage = 99.0
	defeat_in_progress = false
	health_changed.emit(health)
	hunger_changed.emit(hunger)

func summary() -> Dictionary:
	return {
		"survival_time": survival_time,
		"growth_points": growth.points,
		"quests_completed": quests_completed,
		"food_eaten": food_eaten,
		"food_by_nutrition": food_by_nutrition.duplicate(),
		"defeat_count": defeat_count,
		"damage_taken": damage_taken,
		"starvation_seconds": starvation_seconds,
		"stage_seconds": stage_seconds.duplicate(),
		"attacks_landed": attacks_landed,
		"damage_dealt": damage_dealt,
		"targets_defeated": targets_defeated.duplicate(),
		"tokens_claimed": tokens_claimed
	}

func _apply_health_change(amount: float) -> void:
	health = clampf(health + amount, 0.0, profile.max_health)
	health_changed.emit(health)
