class_name DinosaurProfile
extends RefCounted

var id: String
var display_name: String
var tagline: String
var body_color: Color
var accent_color: Color
var diet: String
var move_speed: float
var sprint_speed: float
var base_strength: int
var max_energy: float
var max_health: float
var hunger_drain_per_second: float
var growth_thresholds: Array[int]
var abilities: Array[AbilityDefinition]
var adventure_quests: Array[QuestDefinition]
var optional_quests: Array[QuestDefinition]
var ai_relationships: Dictionary

func _init(
	new_id: String,
	new_display_name: String,
	new_tagline: String,
	new_body_color: Color,
	new_accent_color: Color,
	new_diet: String,
	new_move_speed: float,
	new_sprint_speed: float,
	new_base_strength: int,
	new_max_energy: float,
	new_max_health: float,
	new_hunger_drain_per_second: float,
	new_abilities: Array[AbilityDefinition],
	new_adventure_quests: Array[QuestDefinition],
	new_optional_quests: Array[QuestDefinition],
	new_ai_relationships: Dictionary
) -> void:
	id = new_id
	display_name = new_display_name
	tagline = new_tagline
	body_color = new_body_color
	accent_color = new_accent_color
	diet = new_diet
	move_speed = new_move_speed
	sprint_speed = new_sprint_speed
	base_strength = new_base_strength
	max_energy = new_max_energy
	max_health = new_max_health
	hunger_drain_per_second = new_hunger_drain_per_second
	growth_thresholds = [0, 5, 12, 25]
	abilities = new_abilities
	adventure_quests = new_adventure_quests
	optional_quests = new_optional_quests
	ai_relationships = new_ai_relationships.duplicate(true)

func ability_by_action(action: String, stage_index: int) -> AbilityDefinition:
	for ability in abilities:
		if ability.input_action == action and stage_index >= ability.unlock_stage:
			return ability
	return null

func ability_summary(stage_index: int) -> String:
	var parts: Array[String] = []
	for ability in abilities:
		var status := "READY" if stage_index >= ability.unlock_stage else "at %s" % GrowthSystem.STAGE_NAMES[ability.unlock_stage]
		parts.append("%s [%s]" % [ability.display_name, status])
	return "  •  ".join(parts)

