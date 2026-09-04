class_name SaveSystem
extends RefCounted

const DEFAULT_SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 1

var data: Dictionary = {}
var save_path: String

func _init(custom_save_path: String = "") -> void:
	save_path = DEFAULT_SAVE_PATH if custom_save_path.is_empty() else custom_save_path
	data = _defaults()

func load_data() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		data = _defaults()
		return
	var parsed: Variant = json.data
	if not parsed is Dictionary:
		data = _defaults()
		return
	var loaded := parsed as Dictionary
	if int(loaded.get("version", 0)) != SAVE_VERSION:
		data = _migrate(loaded)
	else:
		data = _merge_defaults(loaded)

func save_data() -> bool:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "  "))
	return true

func is_endless_unlocked(species_id: String) -> bool:
	return bool((data["endless_unlocked"] as Dictionary).get(species_id, false))

func unlock_endless(species_id: String) -> void:
	(data["endless_unlocked"] as Dictionary)[species_id] = true
	award_badge("%s_adventure" % species_id)
	save_data()

func award_badge(badge_id: String) -> void:
	var badges := data["badges"] as Array
	if not badges.has(badge_id):
		badges.append(badge_id)

func unlock_ability(species_id: String, ability_id: String) -> void:
	var all_unlocks := data["ability_unlocks"] as Dictionary
	var species_unlocks: Array = all_unlocks.get(species_id, [])
	if not species_unlocks.has(ability_id):
		species_unlocks.append(ability_id)
	all_unlocks[species_id] = species_unlocks
	save_data()

func record_run(species_id: String, survival_time: float, growth_points: int, quests_completed: int, run_summary: Dictionary = {}) -> void:
	var records := data["records"] as Dictionary
	var current: Dictionary = records.get(species_id, {})
	current["best_survival_seconds"] = maxf(float(current.get("best_survival_seconds", 0.0)), survival_time)
	current["best_growth_points"] = maxi(int(current.get("best_growth_points", 0)), growth_points)
	current["best_quests"] = maxi(int(current.get("best_quests", 0)), quests_completed)
	if not run_summary.is_empty():
		current["last_run"] = run_summary.duplicate(true)
	records[species_id] = current
	save_data()

func _defaults() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"endless_unlocked": {},
		"cosmetics": {
			"t_rex": ["default"],
			"velociraptor": ["default"],
			"triceratops": ["default"]
		},
		"badges": [],
		"ability_unlocks": {},
		"records": {},
		"settings": {"large_text": true, "reduced_flashes": true}
	}

func _merge_defaults(loaded: Dictionary) -> Dictionary:
	var merged := _defaults()
	for key in loaded:
		merged[key] = loaded[key]
	return merged

func _migrate(loaded: Dictionary) -> Dictionary:
	loaded["version"] = SAVE_VERSION
	return _merge_defaults(loaded)
