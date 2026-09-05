class_name CreatureProfiles
extends RefCounted

const CREATURE_PROFILE = preload("res://creature_profile.gd")

static func prey_for_tier(tier: int):
	var profiles := {
		1: CREATURE_PROFILE.new("psittacosaurus", "Psittacosaurus", "prey", 1, Color("#f3c353")),
		2: CREATURE_PROFILE.new("dryosaurus", "Dryosaurus", "prey", 2, Color("#78cfd0")),
		3: CREATURE_PROFILE.new("parasaurolophus", "Parasaurolophus", "prey", 3, Color("#c190e8"))
	}
	return profiles[clampi(tier, 1, 3)]

static func predator_for_tier(tier: int):
	var profiles := {
		1: CREATURE_PROFILE.new("raptor_predator", "Wild Velociraptor", "predator", 1, Color("#6f8fc5")),
		2: CREATURE_PROFILE.new("dilophosaurus", "Dilophosaurus", "predator", 2, Color("#8b79ad")),
		3: CREATURE_PROFILE.new("carnotaurus", "Carnotaurus", "predator", 3, Color("#a85f68")),
		4: CREATURE_PROFILE.new("allosaurus", "Valley Allosaurus", "rival", 4, Color("#76518f"))
	}
	return profiles[clampi(tier, 1, 4)]

static func all() -> Array:
	return [prey_for_tier(1), prey_for_tier(2), prey_for_tier(3), predator_for_tier(1), predator_for_tier(2), predator_for_tier(3), predator_for_tier(4)]
