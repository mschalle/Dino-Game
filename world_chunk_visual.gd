extends Node3D

func _ready() -> void:
	var biome := str(get_meta("biome", "Biome"))
	var landmark := str(get_meta("landmark", biome))
	var marker := MeshInstance3D.new()
	var pillar := CylinderMesh.new()
	pillar.top_radius = 0.18
	pillar.bottom_radius = 0.42
	pillar.height = 2.2
	marker.mesh = pillar
	marker.material_override = _biome_material(biome)
	marker.position.y = 1.1
	add_child(marker)
	var label := Label3D.new()
	label.text = landmark
	label.position.y = 1.6
	label.font_size = 28
	label.outline_size = 7
	label.modulate = Color.WHITE
	label.outline_modulate = Color("#163342")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.visibility_range_begin = 3.0
	label.visibility_range_end = 38.0
	marker.add_child(label)

func _biome_material(biome: String) -> StandardMaterial3D:
	var color := Color("#72ae50")
	if biome == "Fernwood":
		color = Color("#4f8e55")
	elif biome == "River Wetlands":
		color = Color("#6bb8a0")
	elif biome == "Sunstone Ridge":
		color = Color("#c88b55")
	elif biome == "Redstone Badlands":
		color = Color("#c97862")
	elif biome == "Ancient Meadow":
		color = Color("#91c85a")
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color.darkened(0.35)
	material.emission_energy_multiplier = 0.35
	return material
