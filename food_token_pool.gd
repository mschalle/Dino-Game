extends Node3D

const CAPACITY := 25
var available: Array[FoodToken] = []

func acquire(profile: RefCounted, world_position: Vector3) -> FoodToken:
	var token: FoodToken = null
	while not available.is_empty() and not is_instance_valid(token):
		token = available.pop_back()
	if not is_instance_valid(token):
		token = FoodToken.new()
		token.expired.connect(release)
		add_child(token)
	token.setup(profile)
	token.global_position = world_position
	return token

func release(token: FoodToken) -> void:
	if not is_instance_valid(token) or token.get_parent()!=self or available.has(token):
		return
	token.deactivate()
	if available.size()<CAPACITY:
		available.append(token)
	else:
		token.queue_free()
