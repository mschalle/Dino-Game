class_name DinosaurProfiles
extends RefCounted

static func all() -> Array[DinosaurProfile]:
	return [t_rex(), velociraptor(), triceratops(), ankylosaurus(), parasaurolophus(), carnotaurus()]

static func selection_neighbor(index: int, direction: String, count: int = 6, columns: int = 3) -> int:
	if count <= 0:
		return -1
	var row := floori(float(index) / float(columns))
	var column := index % columns
	match direction:
		"left": column = (column - 1 + columns) % columns
		"right": column = (column + 1) % columns
		"up": row = maxi(0, row - 1)
		"down": row = mini(floori(float(count - 1) / float(columns)), row + 1)
	return mini(count - 1, row * columns + column)

static func by_id(species_id: String) -> DinosaurProfile:
	for profile in all():
		if profile.id == species_id:
			return profile
	return t_rex()

static func t_rex() -> DinosaurProfile:
	var abilities: Array[AbilityDefinition] = [
		AbilityDefinition.new("scent", "Scent Trail", "Reveal the route to food or a quest.", 1, "scent_trail", 8.0),
		AbilityDefinition.new("power_bite", "Power Bite", "Reach farther when eating or challenging.", 2, "power_bite", 5.0),
		AbilityDefinition.new("roar", "Valley Roar", "Scare nearby threats and announce your strength.", 2, "special_ability", 8.0)
	]
	var quests: Array[QuestDefinition] = [
		QuestDefinition.new("trex_feast", "First Feast", "Eat three small dinosaurs.", "eat", "prey", 3, 3, 0, Vector3.ZERO),
		QuestDefinition.new("trex_nest", "Ancient Nest", "Follow the scent to the Ancient Nest.", "reach", "ancient_nest", 1, 4, 1, Vector3(-15, 0, -12)),
		QuestDefinition.new("trex_overlook", "Roaring Overlook", "Use Valley Roar at the overlook.", "ability", "roar", 1, 6, 2, Vector3(0, 0, -18)),
		QuestDefinition.new("trex_finale", "Valley Rival", "Defeat the Allosaurus and claim its token as an Adult.", "finale", "valley_rival", 1, 6, 3, Vector3(16, 0, 16))
	]
	return DinosaurProfile.new("t_rex", "Young T. rex", "Powerful hunter with a mighty bite.", Color("#66bc5a"), Color("#f7d27c"), "carnivore", 6.0, 9.0, 1, 100.0, 105.0, 0.35, abilities, quests, _optional_quests(), {"prey": ["small_dino"], "threats": ["rival"]})

static func velociraptor() -> DinosaurProfile:
	var abilities: Array[AbilityDefinition] = [
		AbilityDefinition.new("scent", "Long Scent Trail", "Reveal a longer-lasting route.", 0, "scent_trail", 6.0),
		AbilityDefinition.new("dash", "Dash", "Burst forward using energy.", 0, "dash", 2.0),
		AbilityDefinition.new("pack_call", "Pack Signal", "Call friendly raptors at the signal stone.", 2, "special_ability", 8.0)
	]
	var quests: Array[QuestDefinition] = [
		QuestDefinition.new("raptor_sunstone", "Sunstone Sprint", "Race to Sunstone Arch.", "reach", "sunstone", 1, 5, 0, Vector3(14, 0, -12)),
		QuestDefinition.new("raptor_eggs", "Lost Egg Trail", "Collect three glowing eggs.", "collect", "egg", 3, 5, 1, Vector3(-5, 0, -16)),
		QuestDefinition.new("raptor_signal", "Pack Signal", "Use Pack Signal at the signal stone.", "ability", "pack_call", 1, 7, 2, Vector3(10, 0, 3)),
		QuestDefinition.new("raptor_finale", "Grand Valley Race", "Reach the finish arch as an Adult.", "finale", "race_finish", 1, 5, 3, Vector3(-18, 0, 17))
	]
	return DinosaurProfile.new("velociraptor", "Velociraptor", "Quick explorer with a speedy Dash.", Color("#5aa8e6"), Color("#dceaff"), "carnivore", 7.5, 11.5, 1, 85.0, 85.0, 0.4, abilities, quests, _optional_quests(), {"prey": ["small_dino"], "threats": ["rival"]})

static func triceratops() -> DinosaurProfile:
	var abilities: Array[AbilityDefinition] = [
		AbilityDefinition.new("scent", "Garden Scent", "Reveal plants or the active quest.", 0, "scent_trail", 7.0),
		AbilityDefinition.new("horn_push", "Horn Push", "Move obstacles and gently scatter nearby dinosaurs.", 0, "power_bite", 2.5),
		AbilityDefinition.new("shield", "Shield Stance", "Reduce danger while protecting the herd.", 2, "special_ability", 8.0)
	]
	var quests: Array[QuestDefinition] = [
		QuestDefinition.new("trike_meadow", "Hidden Meadow", "Find the Hidden Meadow.", "reach", "hidden_meadow", 1, 5, 0, Vector3(-13, 0, 11)),
		QuestDefinition.new("trike_feast", "Plant Feast", "Eat three nourishing plants.", "eat", "plant", 3, 5, 1, Vector3.ZERO),
		QuestDefinition.new("trike_trail", "Clear the Trail", "Use Horn Push on the fallen log.", "ability", "horn_push", 1, 7, 2, Vector3(13, 0, -3)),
		QuestDefinition.new("trike_finale", "Herd Home", "Reach the herd sanctuary as an Adult.", "finale", "herd_home", 1, 5, 3, Vector3(-17, 0, -17))
	]
	return DinosaurProfile.new("triceratops", "Triceratops", "Sturdy garden guardian with a gentle Horn Push.", Color("#d97963"), Color("#fff2c9"), "herbivore", 5.0, 7.0, 2, 130.0, 135.0, 0.28, abilities, quests, _optional_quests(), {"prey": ["plant"], "threats": ["rival"]})

static func ankylosaurus() -> DinosaurProfile:
	var abilities: Array[AbilityDefinition] = [
		AbilityDefinition.new("scent", "Garden Scent", "Reveal nearby plants or the active quest.", 0, "scent_trail", 7.0),
		AbilityDefinition.new("tail_swing", "Tail Swing", "Knock back nearby threats with a friendly thump.", 0, "power_bite", 3.0),
		AbilityDefinition.new("brace", "Brace", "Reduce danger while standing your ground.", 2, "special_ability", 8.0)
	]
	var quests: Array[QuestDefinition] = [
		QuestDefinition.new("anky_garden", "Shielded Garden", "Find the sheltered fern garden.", "reach", "ancient_meadow", 1, 5, 0, Vector3(-13, 0, 11)),
		QuestDefinition.new("anky_feast", "Armored Feast", "Eat three nourishing plants.", "eat", "plant", 3, 5, 1, Vector3.ZERO),
		QuestDefinition.new("anky_bridge", "Clear the Crossing", "Use Tail Swing at the stone crossing.", "ability", "tail_swing", 1, 7, 2, Vector3(14, 0, -4)),
		QuestDefinition.new("anky_finale", "Safe Herd Path", "Reach the herd sanctuary as an Adult.", "finale", "herd_home", 1, 5, 3, Vector3(-17, 0, -17))
	]
	return DinosaurProfile.new("ankylosaurus", "Ankylosaurus", "Armored guardian with a powerful tail swing.", Color("#789b55"), Color("#d6b85e"), "herbivore", 4.5, 6.5, 2, 145.0, 120.0, 0.24, abilities, quests, _optional_quests(), {"prey": ["plant"], "threats": ["rival"]})

static func parasaurolophus() -> DinosaurProfile:
	var abilities: Array[AbilityDefinition] = [
		AbilityDefinition.new("scent", "Herd Scent", "Reveal food and safe routes for longer.", 0, "scent_trail", 7.0),
		AbilityDefinition.new("herd_call", "Herd Call", "Send a friendly signal across the meadow.", 0, "special_ability", 7.0),
		AbilityDefinition.new("endurance", "Endurance Run", "Sprint farther before tiring.", 2, "dash", 3.0)
	]
	var quests: Array[QuestDefinition] = [
		QuestDefinition.new("para_wetlands", "Call of the Wetlands", "Reach the river wetlands.", "reach", "waterfall", 1, 5, 0, Vector3(19, 0, -4)),
		QuestDefinition.new("para_feast", "Gentle Grazer", "Eat three nourishing plants.", "eat", "plant", 3, 5, 1, Vector3.ZERO),
		QuestDefinition.new("para_signal", "Herd Signal", "Use Herd Call at the meadow landmark.", "ability", "herd_call", 1, 7, 2, Vector3(-13, 0, 11)),
		QuestDefinition.new("para_finale", "Guide the Herd", "Reach the herd sanctuary as an Adult.", "finale", "herd_home", 1, 5, 3, Vector3(-17, 0, -17))
	]
	return DinosaurProfile.new("parasaurolophus", "Parasaurolophus", "Friendly herd navigator with a powerful call.", Color("#55a7a0"), Color("#f1ce67"), "herbivore", 6.0, 8.5, 1, 110.0, 125.0, 0.3, abilities, quests, _optional_quests(), {"prey": ["plant"], "threats": ["rival"]})

static func carnotaurus() -> DinosaurProfile:
	var abilities: Array[AbilityDefinition] = [
		AbilityDefinition.new("scent", "Hunter Scent", "Reveal prey and the active quest route.", 0, "scent_trail", 7.0),
		AbilityDefinition.new("charge", "Charge", "Burst forward into a safe bump attack.", 0, "dash", 2.5),
		AbilityDefinition.new("intimidate", "Intimidate", "Warn nearby predators away from your territory.", 2, "special_ability", 8.0)
	]
	var quests: Array[QuestDefinition] = [
		QuestDefinition.new("carno_ridge", "Badlands Sprint", "Reach the redstone ridge.", "reach", "sunstone", 1, 5, 0, Vector3(14, 0, -12)),
		QuestDefinition.new("carno_feast", "Hunter's Feast", "Claim three tier-one prey tokens.", "eat", "prey", 3, 5, 1, Vector3.ZERO),
		QuestDefinition.new("carno_charge", "Break the Chase", "Use Charge at the ridge route.", "ability", "charge", 1, 7, 2, Vector3(0, 0, -18)),
		QuestDefinition.new("carno_finale", "Ridge Champion", "Reach the rival arena as an Adult.", "finale", "valley_rival", 1, 6, 3, Vector3(16, 0, 16))
	]
	return DinosaurProfile.new("carnotaurus", "Carnotaurus", "Burst chaser built for quick valley runs.", Color("#b95d4b"), Color("#f1b45f"), "carnivore", 7.0, 10.5, 2, 105.0, 100.0, 0.38, abilities, quests, _optional_quests(), {"prey": ["small_dino"], "threats": ["rival"]})

static func _optional_quests() -> Array[QuestDefinition]:
	return [QuestDefinition.new("optional_explorer", "Valley Explorer", "Visit the sparkling waterfall.", "reach", "waterfall", 1, 2, 0, Vector3(19, 0, -4), true)]
