class_name ValleyPredator
extends Node3D

signal bump_attack(damage: float)
signal creature_defeated(creature: Node3D, profile: RefCounted)

const CREATURE_PROFILES = preload("res://creature_profiles.gd")
const COMBAT_COMPONENT = preload("res://combat_component.gd")

const VALLEY_LIMIT := 27.0

var player: PlayerDino
var strength := 2
var creature_profile
var combat = COMBAT_COMPONENT.new()
var defeat_timer := 0.0
var navigation_agent: NavigationAgent3D
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
var imported_model: Node3D
var imported_animation_player: AnimationPlayer
var respawn_gate: Callable
var prey_target: PreyDino
var passage_target := Vector3.ZERO
var passage_return_home := Vector3.ZERO
var passage_active := false

func setup(new_strength: int, new_position: Vector3) -> void:
	strength = new_strength
	creature_profile = CREATURE_PROFILES.predator_for_tier(new_strength)
	position = new_position
	home = new_position

func set_player(new_player: PlayerDino) -> void:
	player = new_player

func set_respawn_gate(gate: Callable) -> void:
	respawn_gate = gate

func _ready() -> void:
	add_to_group("predator")
	if creature_profile == null:
		creature_profile = CREATURE_PROFILES.predator_for_tier(strength)
	combat.configure(creature_profile.max_health)
	navigation_agent = NavigationAgent3D.new()
	navigation_agent.path_desired_distance = 1.5
	navigation_agent.target_desired_distance = 1.5
	navigation_agent.radius = 0.65
	add_child(navigation_agent)
	_create_visuals()

func _process(delta: float) -> void:
	combat.tick(delta)
	if combat.is_defeated():
		defeat_timer -= delta
		if defeat_timer <= 0.0 and creature_profile.respawn_delay > 0.0 and (respawn_gate.is_null() or respawn_gate.call()):
			combat.reset()
			visible = true
			global_position = home
			state = "wander"
		return
	phase += delta
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if passage_active:
		_update_passage(delta)
		_clamp_to_valley()
		_animate_visuals(true)
		return
	if player == null:
		_process_npc_prey(delta)
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
		var direction := _navigation_direction(player.global_position)
		global_position += direction * 4.0 * delta
		look_at(global_position + direction, Vector3.UP)
		if distance < 1.7 and attack_cooldown <= 0.0:
			attack_cooldown = 1.5
			bump_attack.emit(creature_profile.attack_damage)
		if distance > 20.0 or not can_challenge:
			state = "recover"
	elif state == "recover":
		var direction_home := _navigation_direction(home)
		if direction_home.length() > 1.0:
			global_position += direction_home * 2.2 * delta
		else:
			state = "wander"
	_clamp_to_valley()
	_animate_visuals(state == "chase" or state == "recover")

func scare_away() -> void:
	passage_active = false
	state = "recover"
	if player != null:
		home = global_position + (global_position - player.global_position).normalized() * 8.0
		home.x = clampf(home.x, -VALLEY_LIMIT, VALLEY_LIMIT)
		home.z = clampf(home.z, -VALLEY_LIMIT, VALLEY_LIMIT)

func _process_npc_prey(delta: float) -> void:
	if prey_target == null or not is_instance_valid(prey_target) or not prey_target.visible:
		prey_target = _nearest_prey()
	if prey_target == null:
		state = "wander"
		_wander()
		_animate_visuals(false)
		return
	var distance := global_position.distance_to(prey_target.global_position)
	if state == "wander" and distance < 11.0:
		state = "warn"
		warning_timer = 0.8
	elif state == "warn":
		warning_timer -= delta
		look_at(Vector3(prey_target.global_position.x, global_position.y, prey_target.global_position.z), Vector3.UP)
		if warning_timer <= 0.0:
			state = "chase"
	elif state == "chase":
		var direction := _navigation_direction(prey_target.global_position)
		global_position += direction * 3.5 * delta
		look_at(global_position + direction, Vector3.UP)
		if distance < 1.7 or distance > 20.0:
			state = "recover"
	elif state == "recover":
		var direction_home := _navigation_direction(home)
		if direction_home.length() > 1.0:
			global_position += direction_home * 2.2 * delta
		else:
			state = "wander"
	_clamp_to_valley()
	_animate_visuals(state == "chase" or state == "recover")

func _nearest_prey() -> PreyDino:
	var nearest: PreyDino
	var nearest_distance := 14.0
	for candidate in get_tree().get_nodes_in_group("prey"):
		var prey := candidate as PreyDino
		if prey == null or not prey.visible:
			continue
		var distance := global_position.distance_to(prey.global_position)
		if distance < nearest_distance:
			nearest = prey
			nearest_distance = distance
	return nearest

func begin_passage(destination: Vector3) -> void:
	passage_target = destination
	passage_target.x = clampf(passage_target.x, -VALLEY_LIMIT, VALLEY_LIMIT)
	passage_target.z = clampf(passage_target.z, -VALLEY_LIMIT, VALLEY_LIMIT)
	passage_return_home = home
	passage_active = true
	state = "passage"

func _update_passage(delta: float) -> void:
	var direction := _navigation_direction(passage_target)
	var speed := maxf(2.5, creature_profile.move_speed * 0.7)
	var distance := global_position.distance_to(passage_target)
	if distance <= speed * delta:
		global_position = passage_target
	else:
		global_position += direction * speed * delta
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)
	if global_position.distance_to(passage_target) <= 0.8:
		passage_active = false
		home = passage_return_home
		state = "recover"

func _navigation_direction(target: Vector3) -> Vector3:
	var direct := target - global_position
	direct.y = 0.0
	if navigation_agent != null:
		navigation_agent.target_position = target
		var next_point := navigation_agent.get_next_path_position()
		var navigated := next_point - global_position
		navigated.y = 0.0
		if navigated.length() > 0.2:
			return navigated.normalized()
	return direct.normalized() if direct.length() > 0.01 else Vector3.ZERO

func receive_attack(damage: float, attacker_position: Vector3) -> bool:
	if not combat.take_hit(damage):
		return false
	var away := (global_position - attacker_position).normalized()
	global_position += Vector3(away.x, 0.0, away.z) * 0.3
	if passage_active:
		passage_active = false
		home = passage_return_home
		state = "recover"
		return true
	if combat.is_defeated():
		defeat_timer = creature_profile.respawn_delay
		visible = false
		creature_defeated.emit(self, creature_profile)
	else:
		state = "warn"
		warning_timer = 0.35
	return true

func _wander() -> void:
	global_position = home + Vector3(sin(phase * 0.35) * 2.0, 0.0, cos(phase * 0.28) * 2.0)

func _clamp_to_valley() -> void:
	global_position.x = clampf(global_position.x, -VALLEY_LIMIT, VALLEY_LIMIT)
	global_position.z = clampf(global_position.z, -VALLEY_LIMIT, VALLEY_LIMIT)
	home.x = clampf(home.x, -VALLEY_LIMIT, VALLEY_LIMIT)
	home.z = clampf(home.z, -VALLEY_LIMIT, VALLEY_LIMIT)

func _create_visuals() -> void:
	if _try_imported_model():
		return
	var material := StandardMaterial3D.new()
	material.albedo_color = creature_profile.body_color if creature_profile != null else Color("#8b5f9d")
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

func _try_imported_model() -> bool:
	if creature_profile == null:
		return false
	var model_path := "res://assets/models/dinosaurs/%s.glb" % creature_profile.id
	if not ResourceLoader.exists(model_path):
		return false
	var model_scene := load(model_path) as PackedScene
	if model_scene == null:
		return false
	imported_model = model_scene.instantiate() as Node3D
	if imported_model == null:
		return false
	add_child(imported_model)
	imported_model.name = "ImportedDinosaurModel"
	imported_model.scale = Vector3.ONE * (0.82 + creature_profile.tier * 0.14)
	_set_model_shadows(imported_model)
	_create_imported_animation_library()
	return true

func _set_model_shadows(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for child in node.get_children():
		_set_model_shadows(child)

func _create_imported_animation_library() -> void:
	imported_animation_player = AnimationPlayer.new()
	var library := AnimationLibrary.new()
	for name in ["Idle", "Walk", "Run", "Attack", "Eat", "Hit", "Defeat"]:
		var animation := Animation.new()
		animation.length = 0.8 if name != "Idle" else 2.0
		animation.loop_mode = Animation.LOOP_LINEAR if name in ["Idle", "Walk", "Run"] else Animation.LOOP_NONE
		var track := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, NodePath("../ImportedDinosaurModel:rotation"))
		var tilt := Vector3.ZERO
		if name == "Attack": tilt.x = -0.2
		elif name == "Hit": tilt.z = 0.16
		elif name == "Defeat": tilt.z = 0.7
		animation.track_insert_key(track, 0.0, Vector3.ZERO)
		animation.track_insert_key(track, animation.length * 0.5, tilt)
		animation.track_insert_key(track, animation.length, Vector3.ZERO)
		library.add_animation(name, animation)
	imported_animation_player.add_animation_library("", library)
	add_child(imported_animation_player)
	imported_animation_player.play("Idle")

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
	if imported_animation_player != null:
		var desired := "Run" if moving else "Idle"
		if imported_animation_player.current_animation != desired:
			imported_animation_player.play(desired)
		return
	if body_mesh == null:
		return
	var bob := sin(phase * 5.0) * (0.04 if moving else 0.012)
	body_mesh.position.y = body_rest_y + bob
	head_mesh.position.y = head_rest_y + bob * 0.7
	tail_mesh.rotation = tail_rest_rotation + Vector3(0.0, sin(phase * 2.2) * (0.2 if moving else 0.05), 0.0)
	for index in leg_meshes.size():
		leg_meshes[index].rotation.x = sin(phase * 5.0 + PI * float(index % 2)) * (0.28 if moving else 0.04)
