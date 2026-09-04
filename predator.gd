class_name ValleyPredator
extends Node3D

signal bump_attack(damage: float)

const VALLEY_LIMIT := 27.0

var player: PlayerDino
var strength := 2
var state := "wander"
var home := Vector3.ZERO
var phase := 0.0
var warning_timer := 0.0
var attack_cooldown := 0.0
var awareness_multiplier := 1.0
var body_mesh: MeshInstance3D
var head_mesh: MeshInstance3D
var tail_mesh: MeshInstance3D
var leg_meshes: Array[MeshInstance3D] = []
var body_rest_y := 0.0
var head_rest_y := 0.0
var tail_rest_rotation := Vector3.ZERO

func setup(new_strength: int, new_position: Vector3) -> void:
	strength = new_strength
	position = new_position
	home = new_position

func set_player(new_player: PlayerDino) -> void:
	player = new_player

func _ready() -> void:
	add_to_group("predator")
	_create_visuals()

func _process(delta: float) -> void:
	phase += delta
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if player == null:
		_wander()
		_animate_visuals(false)
		return
	var distance := global_position.distance_to(player.global_position)
	var can_challenge := strength > player.strength
	if state == "wander":
		_wander()
		if can_challenge and distance < 11.0 * awareness_multiplier:
			state = "warn"
			warning_timer = 1.0
	elif state == "warn":
		warning_timer -= delta
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
		if warning_timer <= 0.0:
			state = "chase" if can_challenge else "recover"
	elif state == "chase":
		var direction := (player.global_position - global_position).normalized()
		direction.y = 0.0
		global_position += direction * 4.0 * delta
		look_at(global_position + direction, Vector3.UP)
		if distance < 1.7 and attack_cooldown <= 0.0:
			attack_cooldown = 1.5
			bump_attack.emit(15.0)
		if distance > 20.0 or not can_challenge:
			state = "recover"
	elif state == "recover":
		var direction_home := (home - global_position)
		if direction_home.length() > 1.0:
			global_position += direction_home.normalized() * 2.2 * delta
		else:
			state = "wander"
	_clamp_to_valley()
	_animate_visuals(state == "chase" or state == "recover")

func scare_away() -> void:
	state = "recover"
	if player != null:
		home = global_position + (global_position - player.global_position).normalized() * 8.0
		home.x = clampf(home.x, -VALLEY_LIMIT, VALLEY_LIMIT)
		home.z = clampf(home.z, -VALLEY_LIMIT, VALLEY_LIMIT)

func _wander() -> void:
	global_position = home + Vector3(sin(phase * 0.35) * 2.0, 0.0, cos(phase * 0.28) * 2.0)

func _clamp_to_valley() -> void:
	global_position.x = clampf(global_position.x, -VALLEY_LIMIT, VALLEY_LIMIT)
	global_position.z = clampf(global_position.z, -VALLEY_LIMIT, VALLEY_LIMIT)
	home.x = clampf(home.x, -VALLEY_LIMIT, VALLEY_LIMIT)
	home.z = clampf(home.z, -VALLEY_LIMIT, VALLEY_LIMIT)

func _create_visuals() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#8b5f9d")
	material.roughness = 0.88
	body_mesh = MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.72
	body_mesh.height = 2.6
	self.body_mesh.mesh = body_mesh
	self.body_mesh.material_override = material
	self.body_mesh.rotation_degrees.z = 90.0
	self.body_mesh.position.y = 1.0
	add_child(self.body_mesh)
	head_mesh = MeshInstance3D.new()
	var head_shape := BoxMesh.new()
	head_shape.size = Vector3(1.0, 0.8, 1.1)
	head_mesh.mesh = head_shape
	head_mesh.material_override = material
	head_mesh.position = Vector3(0, 1.35, -0.7)
	add_child(head_mesh)
	tail_mesh = MeshInstance3D.new()
	var tail_shape := CylinderMesh.new()
	tail_shape.top_radius = 0.04
	tail_shape.bottom_radius = 0.3
	tail_shape.height = 1.8
	tail_mesh.mesh = tail_shape
	tail_mesh.material_override = material
	tail_mesh.rotation_degrees.x = 90.0
	tail_mesh.position = Vector3(0, 0.95, 1.55)
	add_child(tail_mesh)
	for x in [-0.42, 0.42]:
		_add_leg(Vector3(x, 0.42, 0.42), material)
		_add_leg(Vector3(x, 0.42, -0.35), material)
	body_rest_y = self.body_mesh.position.y
	head_rest_y = head_mesh.position.y
	tail_rest_rotation = tail_mesh.rotation

func _add_leg(leg_position: Vector3, material: Material) -> void:
	var leg := MeshInstance3D.new()
	var leg_shape := CapsuleMesh.new()
	leg_shape.radius = 0.16
	leg_shape.height = 0.85
	leg.mesh = leg_shape
	leg.material_override = material
	leg.position = leg_position
	add_child(leg)
	leg_meshes.append(leg)

func _animate_visuals(moving: bool) -> void:
	if body_mesh == null:
		return
	var bob := sin(phase * 5.0) * (0.04 if moving else 0.012)
	body_mesh.position.y = body_rest_y + bob
	head_mesh.position.y = head_rest_y + bob * 0.7
	tail_mesh.rotation = tail_rest_rotation + Vector3(0.0, sin(phase * 2.2) * (0.2 if moving else 0.05), 0.0)
	for index in leg_meshes.size():
		leg_meshes[index].rotation.x = sin(phase * 5.0 + PI * float(index % 2)) * (0.28 if moving else 0.04)
