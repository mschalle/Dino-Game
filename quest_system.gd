class_name QuestSystem
extends RefCounted

signal quest_started(quest: QuestDefinition)
signal quest_progressed(quest: QuestDefinition, progress: int)
signal quest_completed(quest: QuestDefinition)
signal chain_completed

var quests: Array[QuestDefinition] = []
var current_index: int = 0
var current_progress: int = 0
var completed_ids: Dictionary = {}

func start(new_quests: Array[QuestDefinition]) -> void:
	quests = new_quests.duplicate()
	current_index = 0
	current_progress = 0
	completed_ids.clear()
	if not quests.is_empty():
		quest_started.emit(quests[0])

func current() -> QuestDefinition:
	if current_index < 0 or current_index >= quests.size():
		return null
	return quests[current_index]

func record(objective_type: String, target_id: String = "", amount: int = 1) -> bool:
	var quest := current()
	if quest == null or completed_ids.has(quest.id):
		return false
	if quest.objective_type != objective_type:
		return false
	if not quest.target_id.is_empty() and quest.target_id != target_id:
		return false
	current_progress = mini(current_progress + amount, quest.required_amount)
	quest_progressed.emit(quest, current_progress)
	if current_progress < quest.required_amount:
		return false
	completed_ids[quest.id] = true
	quest_completed.emit(quest)
	current_index += 1
	current_progress = 0
	if current_index >= quests.size():
		chain_completed.emit()
	else:
		quest_started.emit(quests[current_index])
	return true

func progress_text() -> String:
	var quest := current()
	if quest == null:
		return "Adventure complete"
	return "%s (%d/%d)" % [quest.title, current_progress, quest.required_amount]

