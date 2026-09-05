class_name HabitatSpawnRules
extends RefCounted

static func for_biome(biome: String) -> Dictionary:
	match biome:
		"Nest Basin":
			return {"prey_tiers": [1], "predator_tiers": [1], "plants": true}
		"Fernwood":
			return {"prey_tiers": [1, 2], "predator_tiers": [1], "plants": true}
		"River Wetlands":
			return {"prey_tiers": [2, 3], "predator_tiers": [1], "plants": true}
		"Sunstone Ridge":
			return {"prey_tiers": [2], "predator_tiers": [2], "plants": false}
		"Redstone Badlands":
			return {"prey_tiers": [], "predator_tiers": [2, 3, 4], "plants": false}
		"Ancient Meadow":
			return {"prey_tiers": [1, 2, 3], "predator_tiers": [], "plants": true}
		_:
			return {"prey_tiers": [1], "predator_tiers": [], "plants": true}

static func allows_tier(biome: String, role: String, tier: int) -> bool:
	var rules := for_biome(biome)
	var key := "prey_tiers" if role == "prey" else "predator_tiers"
	return (rules.get(key, []) as Array).has(tier)
