extends SceneTree

const CANDIDATE = preload("res://researched_trex_player.gd")
var failures := 0

class NoCandidate extends CANDIDATE:
	func _imported_model_paths() -> Array[String]:
		return ["res://assets/models/dinosaurs/researched/missing_for_test.glb","res://assets/models/dinosaurs/t_rex.glb"]

class NoLaterStage extends CANDIDATE:
	func _imported_model_paths() -> Array[String]:
		if model_stage>0:
			return ["res://assets/models/dinosaurs/researched/missing_later_stage.glb","res://assets/models/dinosaurs/t_rex.glb"]
		return super._imported_model_paths()

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _local_bounds(node: Node, actor: Node3D) -> AABB:
	var result := AABB()
	if node is MeshInstance3D:
		result = (actor.global_transform.affine_inverse()*node.global_transform)*node.get_aabb()
	for child in node.get_children():
		var other := _local_bounds(child,actor)
		if other.size!=Vector3.ZERO:
			result = other if result.size==Vector3.ZERO else result.merge(other)
	return result

func _run() -> void:
	check("--researched-trex" in OS.get_cmdline_user_args(),"Run with -- --researched-trex to exercise the real Adventure preview")
	root.size = Vector2i(1280,720)
	var game = load("res://Main.tscn").instantiate()
	game.save_system = SaveSystem.new("res://.validation/researched_trex_test_save.json")
	root.add_child(game)
	game._start_run(DinosaurProfiles.t_rex(),"adventure")
	var actor = game.player
	check(actor is CANDIDATE,"Adventure selects the opt-in candidate")
	if not actor is CANDIDATE:
		game.free()
		quit(1)
		return
	for stage in 4:
		if stage>0:
			game.session.growth.add_points(game.session.growth.thresholds[stage]-game.session.growth.points)
		for frame in 30:
			await physics_frame
		check(actor.candidate_loaded and actor.model_stage==stage,"Correct candidate growth stage loads")
		check(actor.scale.is_equal_approx(Vector3.ONE),"Metre-authored stage must not be uniformly rescaled")
		check(actor.imported_native_animations,"Candidate uses native skeletal clips")
		var triangles := 0
		var body_pbr := false
		for node in actor.imported_model.find_children("*","MeshInstance3D",true,false):
			var visual := node as MeshInstance3D
			for surface in visual.mesh.get_surface_count():
				var index_count: int = visual.mesh.surface_get_array_index_len(surface)
				var vertex_count: int = visual.mesh.surface_get_array_len(surface)
				triangles += int(float(index_count if index_count>0 else vertex_count)/3.0)
				var material := visual.get_active_material(surface) as BaseMaterial3D
				if material!=null and material.resource_name=="Body":
					body_pbr = material.albedo_texture!=null and material.albedo_texture.get_width()==2048 and material.normal_enabled and material.normal_texture!=null and material.roughness_texture!=null and material.ao_enabled and material.ao_texture!=null
		check(triangles>=25000 and triangles<=35000,"Candidate keeps the LOD0 triangle budget")
		check(body_pbr,"Candidate imports its original 2K PBR maps")
		var animator: AnimationPlayer = actor.imported_animation_player
		animator.play("Idle",0.0)
		animator.seek(0.0,true)
		var bounds: AABB = _local_bounds(actor.imported_model,actor)
		var expected: Vector2 = CANDIDATE.DIMENSIONS[stage]
		check(absf(bounds.size.z-expected.x)/expected.x<.02,"Stage %d imported length matches dossier"%stage)
		var skeleton := actor.imported_model.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
		var hip := skeleton.global_transform*skeleton.get_bone_global_rest(skeleton.find_bone("Thigh.L")).origin
		check(absf(hip.y-actor.global_position.y-expected.y)<.03,"Stage %d hip height matches dossier"%stage)
		check(absf(bounds.position.y)<.03,"Stage %d sole plane is grounded"%stage)
		var capsule: CapsuleShape3D = actor.get_node("BodyCollision").shape
		check(capsule.radius<.8 and capsule.height>expected.y,"Capsule follows body height within route radius budget")
		for clip in ["Idle","Walk","Run","Attack","PowerBite","Eat","Hit","Stagger","Defeat","Roar","TurnLeft","TurnRight"]:
			check(animator.has_animation(clip),"Candidate exposes "+clip)
		check(animator.get_animation("PowerBite").length!=animator.get_animation("Attack").length,"PowerBite is not a renamed Attack")
		var start: Vector3 = actor.global_position
		Input.action_press("move_forward")
		for frame in 30:
			await physics_frame
		Input.action_release("move_forward")
		check(actor.global_position.distance_to(start)>1.0,"Stage %d moves on live terrain"%stage)
		check(actor.is_on_floor(),"Stage %d maintains floor contact"%stage)
		actor.turn_with_mouse(.35)
		Input.action_press("move_back")
		for frame in 15:
			await physics_frame
		Input.action_release("move_back")
		check(not actor.motion_profile.is_empty(),"Imported stride metadata is available")
		check(animator.speed_scale<0.0,"Reverse movement reverses locomotion playback")
		actor.play_combat_animation(true)
		check(animator.current_animation=="PowerBite","PowerBite plays through player API")
		for frame in 80:
			await physics_frame
		if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png("res://.validation/researched_adventure_%d.png"%stage)==OK,"Stage capture saved")
		print("Research stage %d: length %.4f m, hip %.4f m"%[stage,bounds.size.z,hip.y-start.y])
	var fallback := NoCandidate.new()
	fallback.configure(DinosaurProfiles.t_rex())
	game.run_root.add_child(fallback)
	check(not fallback.candidate_loaded and fallback.imported_model!=null,"Missing research GLB falls back to preserved baseline")
	fallback.free()
	var later := NoLaterStage.new()
	later.configure(DinosaurProfiles.t_rex())
	game.run_root.add_child(later)
	check(later.candidate_loaded,"Later-stage fallback begins with candidate")
	later.grow_to(1.2)
	check(not later.candidate_loaded and later.imported_model!=null,"Missing later stage falls back without losing the model")
	check(is_equal_approx(later.get_node("BodyCollision").shape.height,1.6),"Fallback restores baseline collision dimensions")
	later.free()
	game.free()
	await process_frame
	print("Researched T. rex smoke: %s"%("PASS" if failures==0 else "FAIL"))
	quit(0 if failures==0 else 1)
