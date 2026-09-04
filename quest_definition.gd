class_name QuestDefinition
extends RefCounted

var id: String
var title: String
var description: String
var objective_type: String
var target_id: String
var required_amount: int
var reward_growth: int
var required_stage: int
var marker_position: Vector3
var optional: bool

func _init(
	new_id: String,
	new_title: String,
	new_description: String,
	new_objective_type: String,
	new_target_id: String,
	new_required_amount: int,
	new_reward_growth: int,
	new_required_stage: int,
	new_marker_position: Vector3,
	new_optional: bool = false
) -> void:
	id = new_id
	title = new_title
	description = new_description
	objective_type = new_objective_type
	target_id = new_target_id
	required_amount = new_required_amount
	reward_growth = new_reward_growth
	required_stage = new_required_stage
	marker_position = new_marker_position
	optional = new_optional

