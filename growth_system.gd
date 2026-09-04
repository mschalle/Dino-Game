class_name GrowthSystem
extends RefCounted

signal stage_changed(stage_index: int, stage_name: String)

const STAGE_NAMES: Array[String] = ["Hatchling", "Juvenile", "Young Adult", "Adult"]

var thresholds: Array[int] = [0, 5, 12, 25]
var points: int = 0
var stage_index: int = 0

func configure(new_thresholds: Array[int]) -> void:
	thresholds = new_thresholds.duplicate()
	points = 0
	stage_index = 0

func add_points(amount: int) -> void:
	points += maxi(amount, 0)
	var previous_stage := stage_index
	while stage_index + 1 < thresholds.size() and points >= thresholds[stage_index + 1]:
		stage_index += 1
	if stage_index != previous_stage:
		stage_changed.emit(stage_index, stage_name())

func reset_to_stage_floor() -> void:
	points = thresholds[stage_index]

func stage_name() -> String:
	return STAGE_NAMES[clampi(stage_index, 0, STAGE_NAMES.size() - 1)]

func progress_to_next_stage() -> float:
	if stage_index >= thresholds.size() - 1:
		return 1.0
	var floor_value := thresholds[stage_index]
	var ceiling_value := thresholds[stage_index + 1]
	return clampf(float(points - floor_value) / float(ceiling_value - floor_value), 0.0, 1.0)

func is_adult() -> bool:
	return stage_index >= thresholds.size() - 1

