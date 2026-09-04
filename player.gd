class_name PlayerDino
extends CharacterBody3D

signal energy_changed(value: float)

var profile: DinosaurProfile
var move_speed := 6.0
var sprint_speed := 9.0
var energy := 100.0
var max_energy := 100.0
var strength := 1
var growth_scale := 1.0
var facing := Vector3.FORWARD
var dash_cooldown := 0.0
var dash_timer := 0.0

var body_mesh: MeshInstance3D
var head_mesh: MeshInstance3D
var tail_mesh: MeshInstance3D

func configure(new_profile: DinosaurProfile) -> void:
	profile = new_profile
	move_speed = profile.move_speed
	sprint_speed = profile.sprint_speed
	strength = profile.base_strength
	max_energy = profile.max_energy
	energy = max_energy

func _ready() -> void:
	name = profile.display_name if profile != null else "Young T. rex"
	_create_visuals()

func _physics_process(_delta: float) -> void:
	dash_cooldown = maxf(0.0, dash_cooldown - _delta)
	dash_timer = maxf(0.0, dash_timer - _delta)
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input_vector.x, 0.0, input_vector.y)
	if dash_timer > 0.0:
		direction = facing
	var sprinting := Input.is_action_pressed("sprint") and energy > 0.0 and direction.length() > 0.0
	var speed := 18.0 if dash_timer > 0.0 else (sprint_speed if sprinting else move_speed)
	if sprinting:
		energy = maxf(0.0, energy - 26.0 * _delta)
	else:
		energy = minf(max_energy, energy + 16.0 * _delta)
	energy_changed.emit(energy)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if direction.length() > 0.0:
		facing = direction.normalized()
		rotation.y = lerp_angle(rotation.y, atan2(-facing.x, -facing.z), 10.0 * _delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)
	move_and_slide()

func try_dash(unlocked: bool) -> bool:
	if profile == null or not unlocked or dash_cooldown > 0.0 or energy < 20.0:
		return false
	dash_cooldown = 2.0
	dash_timer = 0.22
	energy -= 20.0
	return true

func grow_to(new_scale: float) -> void:
	growth_scale = new_scale
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE * growth_scale, 0.35).set_trans(Tween.TRANS_BACK)

func celebrate_bite() -> void:
	var tween := create_tween()
	tween.tween_property(head_mesh, "position:z", -0.52, 0.08)
	tween.tween_property(head_mesh, "position:z", -0.33, 0.12)

func _create_visuals() -> void:
	if profile != null and profile.id == "velociraptor":
		_create_raptor_visuals()
		return
	if profile != null and profile.id == "triceratops":
		_create_triceratops_visuals()
		return
	var green := _material(profile.body_color if profile != null else Color("#66bc5a"))
	var cream := _material(Color("#f7d27c"))
	body_mesh = MeshInstance3D.new()
	var body := CapsuleMesh.new()
	body.radius = 0.55
	body.height = 2.2
	body_mesh.mesh = body
	body_mesh.material_override = green
	body_mesh.rotation_degrees.z = 90.0
	body_mesh.position.y = 0.95
	add_child(body_mesh)

	head_mesh = MeshInstance3D.new()
	var head := BoxMesh.new()
	head.size = Vector3(0.9, 0.65, 1.05)
	head_mesh.mesh = head
	head_mesh.material_override = green
	head_mesh.position = Vector3(0.0, 1.28, -0.33)
	add_child(head_mesh)
	for x in [-0.23, 0.23]:
		var eye := MeshInstance3D.new()
		var eye_sphere := SphereMesh.new()
		eye_sphere.radius = 0.09
		eye_sphere.height = 0.18
		eye.mesh = eye_sphere
		eye.material_override = _material(Color("#2e3a36"))
		eye.position = Vector3(x, 1.43, -0.82)
		add_child(eye)

	tail_mesh = MeshInstance3D.new()
	var tail := CylinderMesh.new()
	tail.top_radius = 0.07
	tail.bottom_radius = 0.36
	tail.height = 2.2
	tail_mesh.mesh = tail
	tail_mesh.material_override = green
	tail_mesh.rotation_degrees.x = 90.0
	tail_mesh.position = Vector3(0.0, 0.9, 1.4)
	add_child(tail_mesh)
	for x in [-0.34, 0.34]:
		var leg := MeshInstance3D.new()
		var leg_mesh := CapsuleMesh.new()
		leg_mesh.radius = 0.16
		leg_mesh.height = 0.8
		leg.mesh = leg_mesh
		leg.material_override = cream
		leg.position = Vector3(x, 0.4, 0.38)
		add_child(leg)

func _create_raptor_visuals() -> void:
	var blue := _material(profile.body_color)
	var cream := _material(Color("#dceaff"))
	body_mesh = MeshInstance3D.new()
	var body := CapsuleMesh.new()
	body.radius = 0.36
	body.height = 1.65
	body_mesh.mesh = body
	body_mesh.material_override = blue
	body_mesh.rotation_degrees.z = 90.0
	body_mesh.position.y = 0.75
	add_child(body_mesh)
	head_mesh = MeshInstance3D.new()
	var head := SphereMesh.new()
	head.radius = 0.34
	head.height = 0.68
	head_mesh.mesh = head
	head_mesh.material_override = blue
	head_mesh.position = Vector3(0.0, 1.05, -0.55)
	add_child(head_mesh)
	tail_mesh = MeshInstance3D.new()
	var tail := CylinderMesh.new()
	tail.top_radius = 0.03
	tail.bottom_radius = 0.18
	tail.height = 2.5
	tail_mesh.mesh = tail
	tail_mesh.material_override = blue
	tail_mesh.rotation_degrees.x = 90.0
	tail_mesh.position = Vector3(0.0, 0.72, 1.7)
	add_child(tail_mesh)
	for x in [-0.23, 0.23]:
		var leg := MeshInstance3D.new()
		var leg_mesh := CapsuleMesh.new()
		leg_mesh.radius = 0.11
		leg_mesh.height = 0.9
		leg.mesh = leg_mesh
		leg.material_override = cream
		leg.position = Vector3(x, 0.42, 0.25)
		add_child(leg)

func _create_triceratops_visuals() -> void:
	var coral := _material(profile.body_color)
	var horn := _material(Color("#fff2c9"))
	body_mesh = MeshInstance3D.new()
	var body := SphereMesh.new()
	body.radius = 0.72
	body.height = 1.45
	body_mesh.mesh = body
	body_mesh.material_override = coral
	body_mesh.position.y = 0.86
	body_mesh.scale = Vector3(1.15, 0.9, 1.45)
	add_child(body_mesh)
	head_mesh = MeshInstance3D.new()
	var head := SphereMesh.new()
	head.radius = 0.52
	head.height = 1.04
	head_mesh.mesh = head
	head_mesh.material_override = coral
	head_mesh.position = Vector3(0.0, 1.0, -0.78)
	add_child(head_mesh)
	for x in [-0.28, 0.28]:
		var horn_mesh := MeshInstance3D.new()
		var horn_shape := CylinderMesh.new()
		horn_shape.top_radius = 0.02
		horn_shape.bottom_radius = 0.11
		horn_shape.height = 0.65
		horn_mesh.mesh = horn_shape
		horn_mesh.material_override = horn
		horn_mesh.rotation_degrees.x = 90.0
		horn_mesh.position = Vector3(x, 1.1, -1.22)
		add_child(horn_mesh)
	for x in [-0.48, 0.48]:
		var leg := MeshInstance3D.new()
		var leg_mesh := CapsuleMesh.new()
		leg_mesh.radius = 0.18
		leg_mesh.height = 0.75
		leg.mesh = leg_mesh
		leg.material_override = coral
		leg.position = Vector3(x, 0.38, 0.35)
		add_child(leg)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	return material
