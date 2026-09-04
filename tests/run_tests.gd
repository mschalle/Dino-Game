extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	_test_profiles()
	_test_growth()
	_test_quests()
	_test_survival()
	_test_ai_states()
	_test_gameplay_integration()
	_test_save_recovery()
	if failures == 0:
		print("Roar & Rise tests: PASS")
		quit(0)
	else:
		push_error("Roar & Rise tests: %d failure(s)" % failures)
		quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _test_profiles() -> void:
	var profiles := DinosaurProfiles.all()
	_check(profiles.size() == 3, "Expected three playable profiles")
	var ids: Dictionary = {}
	for profile in profiles:
		_check(not ids.has(profile.id), "Species IDs must be unique")
		ids[profile.id] = true
		_check(profile.growth_thresholds == [0, 5, 12, 25], "Growth thresholds must match the design")
		_check(profile.adventure_quests.size() == 4, "%s needs four main quests" % profile.id)
		_check(not profile.abilities.is_empty(), "%s needs abilities" % profile.id)
	_check(DinosaurProfiles.triceratops().diet == "herbivore", "Triceratops must eat plants")
	_check(DinosaurProfiles.t_rex().diet == "carnivore", "T. rex must eat prey")

func _test_growth() -> void:
	var growth := GrowthSystem.new()
	growth.configure([0, 5, 12, 25])
	growth.add_points(13)
	_check(growth.stage_index == 2, "13 points should reach Young Adult")
	growth.reset_to_stage_floor()
	_check(growth.points == 12, "Defeat should reset to the current stage floor")
	growth.add_points(13)
	_check(growth.is_adult(), "25 points should reach Adult")

func _test_quests() -> void:
	var quest := QuestDefinition.new("test", "Test", "", "eat", "prey", 2, 3, 0, Vector3.ZERO)
	var quests := QuestSystem.new()
	quests.start([quest])
	_check(not quests.record("eat", "plant"), "Wrong food must not progress a quest")
	_check(not quests.record("eat", "prey"), "Quest should require two items")
	_check(quests.record("eat", "prey"), "Second matching item should complete the quest")
	_check(not quests.record("eat", "prey"), "Completed quest cannot award twice")

func _test_survival() -> void:
	var profile := DinosaurProfiles.t_rex()
	var session := GameSession.new()
	session.start(profile, "adventure")
	session.hunger = 1.0
	session.tick(10.0, false)
	_check(session.health < profile.max_health, "Starvation must drain health")
	session.take_damage(999.0)
	_check(session.defeat_in_progress, "Lethal damage must trigger defeat")
	session.growth.add_points(13)
	session.respawn_at_stage_floor()
	_check(session.health == profile.max_health and session.hunger == 100.0, "Respawn must restore survival stats")
	_check(session.growth.points == 12, "Respawn must preserve reached stage")

func _test_ai_states() -> void:
	var player := PlayerDino.new()
	player.configure(DinosaurProfiles.t_rex())
	root.add_child(player)
	player.position = Vector3.ZERO
	var prey := PreyDino.new()
	prey.setup("Test Prey", 1, Color.WHITE)
	root.add_child(prey)
	prey.position = Vector3(4, 0, 0)
	prey.base_position = prey.position
	prey.set_player(player)
	prey._process(0.1)
	_check(prey.state == "notice", "Nearby prey should notice the player")
	prey._process(0.1)
	_check(prey.state == "flee", "Close prey should flee")
	var predator := ValleyPredator.new()
	predator.setup(3, Vector3(5, 0, 0))
	predator.set_player(player)
	root.add_child(predator)
	predator._process(0.1)
	_check(predator.state == "warn", "Stronger nearby predator should warn before chasing")
	player.free()
	prey.free()
	predator.free()

func _test_gameplay_integration() -> void:
	var main_scene: Variant = load("res://Main.tscn").instantiate()
	root.add_child(main_scene)
	var trike := DinosaurProfiles.triceratops()
	main_scene._start_run(trike, "adventure")
	var plant := PlantFood.new()
	plant.setup("Test Plant", 2, Color.GREEN)
	plant.position = main_scene.player.position
	main_scene.run_root.add_child(plant)
	var prey := PreyDino.new()
	prey.setup("Wrong Food", 1, Color.ORANGE)
	prey.position = main_scene.player.position
	main_scene.run_root.add_child(prey)
	var before: int = main_scene.session.growth.points
	_check(main_scene._try_consume(false), "Triceratops should consume nearby plants")
	_check(main_scene.session.growth.points == before + 2, "Food should award its nutrition as growth")
	_check(is_instance_valid(prey), "Herbivore eating must not consume dinosaur prey")
	main_scene.free()

func _test_save_recovery() -> void:
	var path := "res://.godot/test_savegame.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("not valid json")
	file = null
	var save := SaveSystem.new(path)
	save.load_data()
	_check(int(save.data.get("version", 0)) == SaveSystem.SAVE_VERSION, "Corrupt save must recover defaults")
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 0, "badges": ["old_badge"]}))
	file = null
	save.load_data()
	_check(int(save.data.get("version", 0)) == SaveSystem.SAVE_VERSION, "Old save must migrate")
	_check((save.data["badges"] as Array).has("old_badge"), "Migration must preserve rewards")
	save.unlock_endless("t_rex")
	var reloaded := SaveSystem.new(path)
	reloaded.load_data()
	_check(reloaded.is_endless_unlocked("t_rex"), "Valid save must preserve Endless unlocks")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
