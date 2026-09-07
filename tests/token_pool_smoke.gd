extends SceneTree

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var profile = preload("res://creature_profiles.gd").predator_for_tier(1)
	var pool := preload("res://food_token_pool.gd").new()
	root.add_child(pool)
	var token := pool.acquire(profile,Vector3(5,2,3))
	var visual := token.get_child(0)
	check(not token.claim().is_empty() and token.claim().is_empty(),"Each activation grants one reward")
	pool.release(token)
	pool.release(token)
	check(pool.available.size()==1 and not token.is_in_group("food_token") and not token.is_processing(),"Retirement is idempotent and removes targeting/processing")
	check(token.claim().is_empty(),"Retired token cannot grant rewards")
	var reused := pool.acquire(profile,Vector3(2,4,6))
	check(reused==token and reused.get_child(0)==visual,"Reuse must preserve token and mesh identity")
	check(reused.global_position==Vector3(2,4,6) and reused.lifetime==30.0 and reused.phase==0.0 and reused.visible and not reused.claimed,"Reuse resets state and placement")
	reused._process(30.1)
	check(pool.available.size()==1 and reused.claim().is_empty(),"Expiration retires without rewards")
	var active: Array[FoodToken] = []
	for index in 26:
		active.append(pool.acquire(profile,Vector3.ZERO))
	for item in active:
		pool.release(item)
	check(pool.available.size()==25 and active.back().is_queued_for_deletion(),"Pool capacity must bound retained tokens")
	pool.free()
	check(not is_instance_valid(token),"Run teardown must free pooled visuals")
	var game = load("res://Main.tscn").instantiate()
	game.save_system = SaveSystem.new("res://.validation/token_pool_save.json")
	root.add_child(game)
	for dinosaur in [DinosaurProfiles.t_rex(),DinosaurProfiles.triceratops()]:
		game._start_run(dinosaur,"adventure")
		game.session.hunger = 50.0
		var reward_token: FoodToken = game.food_token_pool.acquire(profile,game.player.global_position)
		var growth_before: int = game.session.growth.points
		check(game._claim_food_token(reward_token),"Gameplay claim must succeed")
		check(game.session.growth.points==growth_before+profile.growth_reward,"Gameplay claim must grant expected growth")
		check(game.session.hunger>50.0 if dinosaur.diet=="carnivore" else game.session.hunger==50.0,"Diet-specific hunger must remain unchanged")
		check(not game._claim_food_token(reward_token),"Repeated gameplay click cannot duplicate rewards")
		check(game.food_token_pool.available.size()==1,"Gameplay claim must recycle its token")
		game._cleanup_run()
		check(not is_instance_valid(reward_token),"Restart must discard run-specific tokens")
	game.free()
	print("Token pool smoke: %s" % ("PASS" if failures==0 else "FAIL"))
	quit(0 if failures==0 else 1)
