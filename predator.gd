class_name ValleyPredator
extends Node3D

signal bump_attack(damage: float)

var player: PlayerDino
var strength := 2
var state := "wander"
var home := Vector3.ZERO
var phase := 0.0
var warning_timer := 0.0
var attack_cooldown := 0.0
var awareness_multiplier := 1.0

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

func scare_away() -> void:
	state = "recover"
	if player != null:
		home = global_position + (global_position - player.global_position).normalized() * 8.0

func _wander() -> void:
	global_position = home + Vector3(sin(phase * 0.35) * 2.0, 0.0, cos(phase * 0.28) * 2.0)

func _create_visuals() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#8b5f9d")
	material.roughness = 0.88
	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.72
	body_mesh.height = 2.6
	body.mesh = body_mesh
	body.material_override = material
	body.rotation_degrees.z = 90.0
	body.position.y = 1.0
	add_child(body)
	var head := MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(1.0, 0.8, 1.1)
	head.mesh = head_mesh
	head.material_override = material
	head.position = Vector3(0, 1.35, -0.7)
	add_child(head)
