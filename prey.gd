class_name PreyDino
extends Node3D

const VALLEY_LIMIT := 27.0

var nutrition := 1
var label := "Small Dino"
var base_position := Vector3.ZERO
var phase := 0.0
var tint := Color("#f1a95b")
var player: PlayerDino
var state := "wander"
var flee_speed := 4.2
var body_mesh: MeshInstance3D
var crest_mesh: MeshInstance3D
var tail_mesh: MeshInstance3D
var leg_meshes: Array[MeshInstance3D] = []
var body_rest_y := 0.0
var crest_rest_y := 0.0
var tail_rest_rotation := Vector3.ZERO

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
		_clamp_to_valley()
		_animate_visuals(false)
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
	_clamp_to_valley()
	_animate_visuals(state != "notice")

func set_player(new_player: PlayerDino) -> void:
	player = new_player

func _wander() -> void:
	position = base_position + Vector3(sin(phase) * 0.8, 0.0, cos(phase * 0.7) * 0.55)
	rotation.y = -phase

func _clamp_to_valley() -> void:
	var clamped_x := clampf(global_position.x, -VALLEY_LIMIT, VALLEY_LIMIT)
	var clamped_z := clampf(global_position.z, -VALLEY_LIMIT, VALLEY_LIMIT)
	if not is_equal_approx(global_position.x, clamped_x) or not is_equal_approx(global_position.z, clamped_z):
		global_position.x = clamped_x
		global_position.z = clamped_z
		base_position.x = clamped_x
		base_position.z = clamped_z

func _create_visuals() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.9
	body_mesh = MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.38 + nutrition * 0.1
	mesh.height = 0.76 + nutrition * 0.2
	body_mesh.mesh = mesh
	body_mesh.material_override = material
	body_mesh.position.y = 0.45 + nutrition * 0.05
	add_child(body_mesh)
	crest_mesh = MeshInstance3D.new()
	var crest_shape := CylinderMesh.new()
	crest_shape.bottom_radius = 0.24
	crest_shape.top_radius = 0.02
	crest_shape.height = 0.6
	crest_mesh.mesh = crest_shape
	var crest_material := StandardMaterial3D.new()
	crest_material.albedo_color = tint.lightened(0.12)
	crest_material.roughness = 0.9
	crest_mesh.material_override = crest_material
	crest_mesh.position = Vector3(0, 1.18 + nutrition * 0.08, 0.12)
	add_child(crest_mesh)
	tail_mesh = MeshInstance3D.new()
	var tail := CylinderMesh.new()
	tail.top_radius = 0.02
	tail.bottom_radius = 0.15 + nutrition * 0.02
	tail.height = 0.9 + nutrition * 0.15
	tail_mesh.mesh = tail
	tail_mesh.material_override = material
	tail_mesh.rotation_degrees.x = 90.0
	tail_mesh.position = Vector3(0, 0.54 + nutrition * 0.05, 0.78)
	add_child(tail_mesh)
	for x in [-0.22, 0.22]:
		_add_leg(Vector3(x, 0.22, 0.24), material)
		_add_leg(Vector3(x, 0.22, -0.22), material)
	body_rest_y = body_mesh.position.y
	crest_rest_y = crest_mesh.position.y
	tail_rest_rotation = tail_mesh.rotation

func _add_leg(leg_position: Vector3, material: Material) -> void:
	var leg := MeshInstance3D.new()
	var leg_shape := CapsuleMesh.new()
	leg_shape.radius = 0.09 + nutrition * 0.015
	leg_shape.height = 0.48 + nutrition * 0.06
	leg.mesh = leg_shape
	leg.material_override = material
	leg.position = leg_position
	add_child(leg)
	leg_meshes.append(leg)

func _animate_visuals(moving: bool) -> void:
	if body_mesh == null:
		return
	var bob := sin(phase * 4.0) * (0.032 if moving else 0.012)
	body_mesh.position.y = body_rest_y + bob
	crest_mesh.position.y = crest_rest_y + bob
	tail_mesh.rotation = tail_rest_rotation + Vector3(0.0, sin(phase * 2.7) * (0.22 if moving else 0.06), 0.0)
	for index in leg_meshes.size():
		leg_meshes[index].rotation.x = sin(phase * 4.0 + PI * float(index % 2)) * (0.32 if moving else 0.04)
