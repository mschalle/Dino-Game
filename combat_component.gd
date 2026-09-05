class_name CombatComponent
extends RefCounted

signal health_changed(value: float, maximum: float)
signal attacked(damage: float)
signal defeated

var max_health := 1.0
var health := 1.0
var invulnerability_timer := 0.0

func configure(value: float) -> void:
	max_health = value
	health = value
	invulnerability_timer = 0.0

func tick(delta: float) -> void:
	invulnerability_timer = maxf(0.0, invulnerability_timer - delta)

func take_hit(damage: float) -> bool:
	if health <= 0.0 or invulnerability_timer > 0.0:
		return false
	invulnerability_timer = 0.18
	health = maxf(0.0, health - absf(damage))
	attacked.emit(damage)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		defeated.emit()
	return true

func reset() -> void:
	health = max_health
	invulnerability_timer = 0.0
	health_changed.emit(health, max_health)

func is_defeated() -> bool:
	return health <= 0.0
