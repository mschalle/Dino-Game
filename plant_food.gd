class_name PlantFood
extends Node3D

var nutrition := 1
var label := "Fern"
var tint := Color("#6fcf75")

func setup(new_label: String, new_nutrition: int, new_tint: Color) -> void:
	label = new_label
	nutrition = new_nutrition
	tint = new_tint

func _ready() -> void:
	add_to_group("plant_food")
	var stem := MeshInstance3D.new()
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.08
	stem_mesh.bottom_radius = 0.12
	stem_mesh.height = 0.8
	stem.mesh = stem_mesh
	stem.material_override = _material(tint)
	stem.position.y = 0.4
	add_child(stem)
	for angle in [0.0, 120.0, 240.0]:
		var leaf := MeshInstance3D.new()
		var leaf_mesh := SphereMesh.new()
		leaf_mesh.radius = 0.28
		leaf_mesh.height = 0.32
		leaf.mesh = leaf_mesh
		leaf.material_override = _material(tint.lightened(0.12))
		leaf.position = Vector3(sin(deg_to_rad(angle)) * 0.32, 0.83, cos(deg_to_rad(angle)) * 0.32)
		leaf.scale = Vector3(0.8, 0.35, 1.5)
		add_child(leaf)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material
