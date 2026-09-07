extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Tree impostor baking requires rendering")
		quit(1)
		return
	var directory := "res://assets/environment/impostors"
	if DirAccess.make_dir_recursive_absolute(directory)!=OK:
		quit(1)
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(512,512)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0,0,0,0)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.8,0.85,0.9)
	environment.environment.ambient_light_energy = 0.75
	viewport.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35,-25,0)
	sun.light_energy = 0.75
	viewport.add_child(sun)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	viewport.add_child(camera)
	camera.current = true
	var dressing = preload("res://jungle_dressing.gd")
	for variant in 3:
		var source := "res://glTF/CommonTree_%d.gltf" % (variant+1)
		var mesh := dressing.mesh_for(source,"tree").duplicate(true) as Mesh
		for surface in mesh.get_surface_count():
			var material := mesh.surface_get_material(surface) as ShaderMaterial
			material.set_shader_parameter("wind",0.0)
			material.set_shader_parameter("camera_clearance",0.0)
		var actor := MeshInstance3D.new()
		actor.mesh = mesh
		viewport.add_child(actor)
		var bounds := mesh.get_aabb()
		var center := bounds.get_center()
		var frame_size := maxf(bounds.size.x,bounds.size.y)*1.1
		camera.size = frame_size
		camera.position = center+Vector3(0,0,3)
		camera.look_at(center)
		for frame in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		var captured := viewport.get_texture().get_image()
		var preview := "%s/CommonTree_%d.png" % [directory,variant+1]
		if captured.save_png(preview)!=OK:
			quit(1)
			return
		captured.generate_mipmaps()
		var material := StandardMaterial3D.new()
		material.albedo_texture = ImageTexture.create_from_image(captured)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		material.alpha_scissor_threshold = 0.4
		material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		material.billboard_keep_scale = true
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		var card := QuadMesh.new()
		card.size = Vector2.ONE*frame_size
		card.center_offset = Vector3(center.x,center.y,0)
		card.material = material
		card.set_meta("source",source)
		card.set_meta("source_fingerprint",dressing.mesh_fingerprint(source))
		card.set_meta("source_stamp",dressing.mesh_fingerprint(source,false))
		card.set_meta("impostor_version",1)
		if ResourceSaver.save(card,"%s/CommonTree_%d.res" % [directory,variant+1])!=OK:
			quit(1)
			return
		actor.free()
	viewport.free()
	print("Tree impostor bake: PASS (3 variants)")
	quit()
