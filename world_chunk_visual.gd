extends Node3D

var chunk_state: Dictionary = {}

func apply_chunk_profile(profile: RefCounted) -> void:
	set_meta("navigation_layers", profile.navigation_layers)
	set_meta("agent_radius", profile.agent_radius)
	set_meta("max_slope_degrees", profile.max_slope_degrees)
	set_meta("max_climb", profile.max_climb)

func apply_chunk_state(state: Dictionary) -> void:
	chunk_state = state.duplicate(true)

func _ready() -> void:
	var biome := str(get_meta("biome", "Biome"))
	var landmark := str(get_meta("landmark", biome))
	_create_ground(biome)
	_create_elevation(biome)
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

func _create_ground(biome: String) -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60.0, 60.0)
	ground.mesh = plane
	ground.material_override = _biome_material(biome)
	ground.position.y = -0.12
	ground.name = "Ground"
	add_child(ground)
	var body := StaticBody3D.new()
	body.name = "GroundCollision"
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(60.0, 0.25, 60.0)
	collider.shape = shape
	collider.position.y = -0.12
	body.add_child(collider)
	add_child(body)

func _create_elevation(biome: String) -> void:
	var size := Vector3(18.0, 1.2, 14.0)
	var position := Vector3(0.0, 0.55, 0.0)
	if biome == "Sunstone Ridge":
		size = Vector3(24.0, 4.0, 16.0)
		position = Vector3(8.0, 2.0, -5.0)
	elif biome == "Redstone Badlands":
		size = Vector3(20.0, 3.0, 18.0)
		position = Vector3(-7.0, 1.5, 4.0)
	elif biome == "River Wetlands":
		size = Vector3(16.0, 0.7, 12.0)
		position = Vector3(-5.0, 0.35, -4.0)
	elif biome == "Ancient Meadow":
		size = Vector3(22.0, 1.8, 18.0)
		position = Vector3(5.0, 0.9, 5.0)
	elif biome == "Fernwood":
		size = Vector3(14.0, 1.0, 20.0)
		position = Vector3(-6.0, 0.5, 6.0)
	var mound := MeshInstance3D.new()
	mound.name = "Elevation"
	var mesh := BoxMesh.new()
	mesh.size = size
	mound.mesh = mesh
	mound.position = position
	mound.material_override = _biome_material(biome).duplicate()
	add_child(mound)
	var body := StaticBody3D.new()
	body.name = "ElevationCollision"
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	collider.position = position
	body.add_child(collider)
	add_child(body)
