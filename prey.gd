class_name PreyDino
extends Node3D

var nutrition := 1
var label := "Small Dino"
var base_position := Vector3.ZERO
var phase := 0.0
var tint := Color("#f1a95b")
var player: PlayerDino
var state := "wander"
var flee_speed := 4.2

func setup(new_label: String, new_nutrition: int, new_tint: Color) -> void:
	label = new_label
	nutrition = new_nutrition
	tint = new_tint

func _ready() -> void:
	add_to_group("prey")
	base_position = position
	phase = randf() * TAU
	_create_visuals()

func _process(delta: float) -> void:
	phase += delta * (0.55 + nutrition * 0.08)
	if player == null:
		_wander()
		return
	var distance := global_position.distance_to(player.global_position)
	if state == "wander" and distance < 8.0:
		state = "notice"
	elif state == "notice":
		rotation.y = lerp_angle(rotation.y, atan2(player.global_position.x - global_position.x, player.global_position.z - global_position.z), delta * 6.0)
		if distance < 5.5:
			state = "flee"
		elif distance > 9.0:
			state = "wander"
	elif state == "flee":
		var away := (global_position - player.global_position).normalized()
		away.y = 0.0
		global_position += away * flee_speed * delta
		base_position = global_position
		rotation.y = atan2(-away.x, -away.z)
		if distance > 12.0:
			state = "recover"
	elif state == "recover":
		_wander()
		if distance > 14.0:
			state = "wander"
	else:
		_wander()

func set_player(new_player: PlayerDino) -> void:
	player = new_player

func _wander() -> void:
	position = base_position + Vector3(sin(phase) * 0.8, 0.0, cos(phase * 0.7) * 0.55)
	rotation.y = -phase

func _create_visuals() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.9
	var body := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.38 + nutrition * 0.1
	mesh.height = 0.76 + nutrition * 0.2
	body.mesh = mesh
	body.material_override = material
	body.position.y = 0.45 + nutrition * 0.05
	add_child(body)
	var crest := MeshInstance3D.new()
	var crest_mesh := CylinderMesh.new()
	crest_mesh.bottom_radius = 0.24
	crest_mesh.top_radius = 0.02
	crest_mesh.height = 0.6
	crest.mesh = crest_mesh
	crest.material_override = material
	crest.position = Vector3(0, 1.18 + nutrition * 0.08, 0.12)
	add_child(crest)
