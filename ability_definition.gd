class_name AbilityDefinition
extends RefCounted

var id: String
var display_name: String
var description: String
var unlock_stage: int
var input_action: String
var cooldown: float

func _init(
	new_id: String,
	new_display_name: String,
	new_description: String,
	new_unlock_stage: int,
	new_input_action: String,
	new_cooldown: float
) -> void:
	id = new_id
	display_name = new_display_name
	description = new_description
	unlock_stage = new_unlock_stage
	input_action = new_input_action
	cooldown = new_cooldown

