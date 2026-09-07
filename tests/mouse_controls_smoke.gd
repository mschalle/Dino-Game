extends SceneTree

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _init() -> void:
	call_deferred("_run")

func motion(game: Node, x: float, y: float = 0.0) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = Vector2(x,y)
	game._input(event)

func button(game: Node, index: MouseButton, pressed: bool = true) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = index
	event.pressed = pressed
	game._input(event)

func _run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Mouse controls smoke requires a rendered window for real mouse capture")
		quit(1)
		return
	var game = load("res://Main.tscn").instantiate()
	game.save_system = SaveSystem.new("res://.validation/mouse_controls_save.json")
	root.add_child(game)
	game._start_run(DinosaurProfiles.t_rex(),"adventure")
	for frame in 4:
		await physics_frame
	check(Input.mouse_mode==Input.MOUSE_MODE_CAPTURED,"Adventure must capture mouse")
	motion(game,200.0)
	var heading: Vector3 = game.player.facing
	check(heading.x>0.0,"Mouse right must turn dinosaur right")
	for action in ["move_forward","move_back"]:
		game.player.velocity = Vector3.ZERO
		var start: Vector3 = game.player.position
		Input.action_press(action)
		for frame in 20:
			await physics_frame
		Input.action_release(action)
		var moved: Vector3 = game.player.position-start
		check(moved.dot(heading)>0.1 if action=="move_forward" else moved.dot(heading)<-0.1,"W/S must move along/opposite current heading")
		check(game.player.facing.is_equal_approx(heading),"Backward movement must not turn dinosaur around")
	button(game,MOUSE_BUTTON_RIGHT)
	game._follow_player(1.0)
	var camera_yaw: float = game.camera_arm.rotation.y
	motion(game,100.0,50.0)
	game._follow_player(1.0)
	check(game.camera_panning and game.camera_orbit_yaw<0.0,"RMB drag must orbit camera")
	check(absf(angle_difference(camera_yaw,game.camera_arm.rotation.y))>0.2,"RMB drag must rotate the actual camera arm")
	check(game.player.facing.is_equal_approx(heading),"Camera drag must not turn dinosaur")
	button(game,MOUSE_BUTTON_RIGHT,false)
	check(not game.camera_panning and game.camera_orbit_yaw==0.0,"Release must restore follow heading")
	for index in 30:
		button(game,MOUSE_BUTTON_WHEEL_UP)
	game._follow_player(1.0)
	var close_length: float = game.camera_arm.spring_length
	check(is_equal_approx(game.camera_zoom,0.45),"Zoom in must be bounded")
	for index in 30:
		button(game,MOUSE_BUTTON_WHEEL_DOWN)
	check(is_equal_approx(game.camera_zoom,1.8),"Zoom out must be bounded")
	game._follow_player(1.0)
	check(game.camera_arm.spring_length>close_length,"Wheel zoom must change the actual spring arm")
	game._set_paused(true)
	motion(game,500.0)
	check(game.player.facing.is_equal_approx(heading) and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"Pause releases cursor and blocks turning")
	game._set_paused(false)
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(paused and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"Focus loss must pause and release the cursor")
	game._set_paused(false)
	var joy := InputEventJoypadMotion.new()
	joy.axis_value = 0.6
	game._input(joy)
	check(not game.player.mouse_steering,"Gamepad must retain stick-facing movement")
	motion(game,0.0)
	check(game.player.mouse_steering,"Mouse resumes mouse steering")
	game.save_system.data["settings"]["bindings"] = {"power_bite":{"type":"mouse","code":MOUSE_BUTTON_RIGHT}}
	game._apply_saved_bindings()
	for event in InputMap.action_get_events("power_bite"):
		check(not (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT),"Legacy saved RMB ability must not conflict")
	game._cleanup_run()
	check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"Selection/cleanup must release cursor")
	game.free()
	print("Mouse controls smoke: %s" % ("PASS" if failures==0 else "FAIL"))
	quit(0 if failures==0 else 1)
