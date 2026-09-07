extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var visual := preload("res://world_chunk_visual.gd").new()
	var failures := 0
	for path in ["res://glTF/DeadTree_3.gltf","res://glTF/Pine_2.gltf","res://glTF/CommonTree_1.gltf"]:
		var prop := (load(path) as PackedScene).instantiate()
		var originals: Array = []
		for mesh in prop.find_children("*","MeshInstance3D",true,false):
			for surface in mesh.mesh.get_surface_count():
				originals.append(mesh.get_active_material(surface))
		visual._apply_tree_camera_clearance(prop)
		var count := 0
		for mesh in prop.find_children("*","MeshInstance3D",true,false):
			for surface in mesh.mesh.get_surface_count():
				var material: Material = mesh.get_active_material(surface)
				if not material is ShaderMaterial or material.get_shader_parameter("camera_clearance")!=3.0:
					failures += 1
				elif material.get_shader_parameter("tint")!=originals[count].albedo_color:
					failures += 1
				elif originals[count].albedo_texture != null and material.get_shader_parameter("albedo_texture")!=originals[count].albedo_texture:
					failures += 1
				count += 1
		if count==0 or not prop.find_children("*","CollisionObject3D",true,false).is_empty():
			failures += 1
		prop.free()
	if "--capture" in OS.get_cmdline_user_args():
		if DisplayServer.get_name()=="headless":
			push_error("Tree clearance capture requires rendering")
			failures += 1
		else:
			var scene := Node3D.new()
			root.add_child(scene)
			var prop := (load("res://glTF/DeadTree_3.gltf") as PackedScene).instantiate() as Node3D
			scene.add_child(prop)
			var light := DirectionalLight3D.new()
			light.rotation_degrees = Vector3(-35,-25,0)
			scene.add_child(light)
			var camera := Camera3D.new()
			scene.add_child(camera)
			camera.position = Vector3(0,2,1.4)
			camera.look_at(Vector3(0,2,-3))
			var target := MeshInstance3D.new()
			target.mesh = SphereMesh.new()
			target.position = Vector3(0,2,-3)
			var marker := StandardMaterial3D.new()
			marker.albedo_color = Color(1,0.2,0.1)
			marker.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			target.material_override = marker
			scene.add_child(target)
			for phase in ["before","after","recovered"]:
				if phase=="after":
					visual._apply_tree_camera_clearance(prop)
				elif phase=="recovered":
					camera.position.z = 8.0
				for frame in 5:
					await process_frame
				await RenderingServer.frame_post_draw
				var capture := root.get_texture().get_image()
				var center := capture.get_pixel(capture.get_width() >> 1,capture.get_height() >> 1)
				var target_visible := center.r>0.8 and center.g<0.4 and center.b<0.3
				if target_visible != (phase=="after"):
					push_error("Unexpected tree occlusion during "+phase)
					failures += 1
				if capture.save_png("res://.validation/tree_clearance_%s.png" % phase)!=OK:
					failures += 1
			scene.queue_free()
			await process_frame
	visual.free()
	print("Tree clearance smoke: %s" % ("PASS" if failures==0 else "FAIL"))
	quit(0 if failures==0 else 1)
