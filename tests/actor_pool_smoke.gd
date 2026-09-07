extends SceneTree

var failures := 0
var rewards := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _init() -> void:
	call_deferred("_run")

func _reward(_actor: Node3D, _profile: RefCounted) -> void:
	rewards += 1

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var manager := WorldStreamManager.new()
	manager.configure(preload("res://world_chunk_profiles.gd").reserve())
	manager.update_player_chunk(Vector2i(3,3))
	var prey := PreyDino.new()
	prey.position = Vector3(60,2,60)
	world.add_child(prey)
	prey.combat.health = 12.0
	var predator := ValleyPredator.new()
	predator.setup(1,Vector3(60,2,60))
	world.add_child(predator)
	predator.creature_defeated.connect(_reward)
	predator.receive_attack(10000.0, Vector3(59,2,60))
	predator.defeat_timer = 3.0
	check(rewards==1,"Initial defeat must award one event")
	check(manager.prune_inactive_actors(world)==2,"Both creature types must leave inactive terrain")
	check(not prey.is_inside_tree() and not predator.is_inside_tree(),"Pooled actors must leave processing and group queries")
	check(get_nodes_in_group("prey").is_empty() and get_nodes_in_group("predator").is_empty(),"Pool must not consume active creature slots")
	manager.tick_respawn_cooldowns(4.0)
	check(predator.defeat_timer==0.0 and predator.combat.is_defeated(),"Cooldown may expire in pool without spawning or rewarding")
	manager.update_player_chunk(Vector2i.ONE)
	manager.restore_pooled_actors(world,1)
	check(manager.actor_pool.size()==1,"Restoration must honor available creature slots")
	manager.restore_pooled_actors(world,25)
	manager.update_actor_simulation(world)
	check(prey.is_inside_tree() and predator.is_inside_tree(),"Habitat reentry must restore original actors")
	check(prey.combat.health==12.0,"Reentry must preserve injured health")
	predator._process(0.01)
	check(not predator.combat.is_defeated() and rewards==1,"Normal respawn after reentry must not duplicate defeat rewards")
	check(predator.creature_defeated.get_connections().size()==1,"Pooling must not duplicate signal connections")
	prey.free()
	predator.free()
	manager.update_player_chunk(Vector2i(3,3))
	var oldest: PreyDino
	for index in 26:
		var actor := PreyDino.new()
		actor.position = Vector3(60,2,60)
		world.add_child(actor)
		if index==0:
			oldest = actor
	manager.prune_inactive_actors(world)
	check(manager.actor_pool.size()==25 and not is_instance_valid(oldest),"Pool capacity must evict the oldest actor")
	var last: Node3D = manager.actor_pool.back().actor
	world.free()
	check(not is_instance_valid(last),"Run/world teardown must free detached actors")
	manager.clear_actor_pool()
	check(manager.actor_pool.is_empty(),"Cleanup must clear pool records")
	print("Actor pool smoke: %s" % ("PASS" if failures==0 else "FAIL"))
	quit(0 if failures==0 else 1)
