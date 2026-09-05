class_name EndlessChallengeSystem
extends RefCounted

const QUEST = preload("res://quest_definition.gd")

const FORAGE := "forage"
const DISCOVER := "discover"
const OBSERVE_HERD := "observe_herd"
const EVADE_PREDATOR := "evade_predator"

var last_family := ""
var skipped_ids: Dictionary = {}

func next(round: int, dinosaur_profile, active_event_id: String, destination: Vector3) -> QuestDefinition:
	var families: Array[String] = [FORAGE, DISCOVER]
	if active_event_id == "herd_journey":
		families.append(OBSERVE_HERD)
	if active_event_id == "predator_passage":
		families.append(EVADE_PREDATOR)
	var family := families[round % families.size()]
	if active_event_id == "herd_journey" and last_family != OBSERVE_HERD:
		family = OBSERVE_HERD
	elif active_event_id == "predator_passage" and last_family != EVADE_PREDATOR:
		family = EVADE_PREDATOR
	if family == last_family and families.size() > 1:
		family = families[(round + 1) % families.size()]
	last_family = family
	var id := "endless_%s_%d" % [family, round]
	if family == FORAGE:
		var target := "plant" if dinosaur_profile.diet == "herbivore" else "prey"
		return QUEST.new(id, "Endless Forage", "Find suitable renewable food.", "eat", target, 5, 3, 0, Vector3.ZERO)
	if family == DISCOVER:
		return QUEST.new(id, "Trail Discovery", "Reach the glowing landmark.", "reach", "endless_marker", 1, 3, 0, destination)
	if family == OBSERVE_HERD:
		return QUEST.new(id, "Herd Watch", "Stay near the traveling herd.", "survive", "herd_journey", 15, 3, 0, Vector3.ZERO)
	return QUEST.new(id, "Safe Passage", "Keep clear while the predator travels.", "survive", "predator_passage", 15, 3, 0, Vector3.ZERO)

func skip(quest_id: String) -> bool:
	if quest_id.is_empty() or skipped_ids.has(quest_id):
		return false
	skipped_ids[quest_id] = true
	return true
