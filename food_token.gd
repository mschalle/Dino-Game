class_name FoodToken
extends Node3D

signal expired(token: FoodToken)

var creature_profile
var lifetime := 30.0
var claimed := false
var phase := 0.0

func setup(profile) -> void:
	creature_profile = profile
	lifetime = 30.0
	claimed = false
	phase = 0.0
	rotation = Vector3.ZERO
	visible = true
	set_process(true)
	if is_inside_tree():
		add_to_group("food_token")

func deactivate() -> void:
	claimed = true
	creature_profile = null
	visible = false
	set_process(false)
	remove_from_group("food_token")

func _ready() -> void:
	add_to_group("food_token")
	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.28
	mesh.height = 0.56
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#fff3a6")
	material.emission_enabled = true
	material.emission = Color("#ffd96a")
	material.emission_energy_multiplier = 2.0
	mesh_instance.material_override = material
	mesh_instance.position.y = 0.5
	add_child(mesh_instance)

func _process(delta: float) -> void:
	lifetime -= delta
	phase += delta
	position.y += sin(phase * 3.0) * 0.002
	rotation.y += delta
	if lifetime <= 0.0:
		if expired.has_connections():
			expired.emit(self)
		else:
			queue_free()

func claim() -> Dictionary:
	if claimed or creature_profile == null:
		return {}
	claimed = true
	return {"growth": creature_profile.growth_reward, "hunger": creature_profile.hunger_reward, "role": creature_profile.role, "species_id": creature_profile.id, "tier": creature_profile.tier}
