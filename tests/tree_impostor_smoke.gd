extends SceneTree

const IMPOSTOR = preload("res://tree_impostor.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for variant in 3:
		var card := load(IMPOSTOR.resource_path(variant)) as QuadMesh
		check(IMPOSTOR.valid_card(card,variant),"Missing or stale tree impostor")
		if card==null:
			continue
		check(card.get_meta("source_fingerprint","")==preload("res://jungle_dressing.gd").mesh_fingerprint(IMPOSTOR.source_path(variant)),"Impostor source content changed")
		check(card.get_faces().size()==6,"Each tree must use two triangles")
		var material := card.material as StandardMaterial3D
		check(material.billboard_mode==BaseMaterial3D.BILLBOARD_FIXED_Y and material.billboard_keep_scale,"Card must face camera without losing growth scale")
		check(material.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR,"Tree card must use cutout transparency")
		var pixels := material.albedo_texture.get_image()
		check(pixels.has_mipmaps() and pixels.get_size()==Vector2i(512,512),"Tree texture must have mipmaps and expected resolution")
		var opaque := 0
		for y in range(0,512,4):
			for x in range(0,512,4):
				if pixels.get_pixel(x,y).a>0.5:
					opaque += 1
		check(opaque>800 and opaque<13000 and pixels.get_pixel(0,0).a<0.01,"Capture must contain a tree surrounded by transparent background")
		check(IMPOSTOR.mesh_for(variant)==card,"Valid card must be used")
		card.set_meta("impostor_version",0)
		IMPOSTOR.cache.clear()
		var fallback: Mesh = IMPOSTOR.mesh_for(variant)
		check(not fallback is QuadMesh and fallback.get_surface_count()>0,"Stale card must fall back to source geometry")
		card.set_meta("impostor_version",1)
		IMPOSTOR.cache.clear()
	check(not IMPOSTOR.valid_card(null,0),"Missing card must be rejected")
	if "--capture" in OS.get_cmdline_user_args():
		if DisplayServer.get_name()=="headless":
			check(false,"Capture requires rendering")
		else:
			await capture_views()
	print("Tree impostor smoke: %s" % ("PASS" if failures==0 else "FAIL"))
	quit(0 if failures==0 else 1)

func capture_views() -> void:
	root.size = Vector2i(1280,720)
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.5,0.65,0.7)
	world.add_child(environment)
	for variant in 3:
		var batch := MultiMeshInstance3D.new()
		batch.multimesh = MultiMesh.new()
		batch.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		batch.multimesh.mesh = IMPOSTOR.mesh_for(variant)
		batch.multimesh.instance_count = 1
		batch.multimesh.set_instance_transform(0,Transform3D(Basis(Vector3.UP,variant*0.8).scaled(Vector3.ONE*8.0),Vector3((variant-1)*10.0,0,0)))
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(batch)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.current = true
	for view in ["front","oblique"]:
		camera.position = Vector3(0,8,35) if view=="front" else Vector3(25,10,30)
		camera.look_at(Vector3(0,4,0))
		for frame in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://.validation/tree_impostors_%s.png" % view)==OK,"Impostor capture must save")
	world.free()
