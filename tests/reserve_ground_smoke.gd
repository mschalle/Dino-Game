extends SceneTree

const GROUND = preload("res://reserve_ground.gd")
const TERRAIN = preload("res://valley_terrain.gd")
var failures := 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var palette_count := 0
	for profile in WorldChunkProfiles.reserve():
		if preload("res://jungle_habitat.gd").contains(profile.biome):
			continue
		check(GROUND.PALETTES.has(profile.biome),"Missing palette: "+profile.biome)
		var origin := Vector2(profile.grid_position)*TERRAIN.CHUNK_SIZE
		var material := GROUND.material(profile.biome,origin)
		var palette: Image = material.get_shader_parameter("biome_palette").get_image()
		var pixel := Vector2i(profile.grid_position.x+2,profile.grid_position.y*3+1)
		check(palette.get_pixelv(pixel).is_equal_approx(Color(GROUND.PALETTES[profile.biome][1])),"Palette must match habitat at its world grid location")
		var distant := preload("res://distant_chunk_visual.gd").new()
		distant.configure(profile)
		if profile.chunk_id in ["cloudforest","redwood_canyon"]:
			check(distant.get_node_or_null("DistantCanopy")!=null,"Forest habitat must retain distant trees: "+profile.chunk_id)
		check(distant.get_node("DistantGround").material_override.get_shader_parameter("biome_palette")==material.get_shader_parameter("biome_palette"),"Distant and near palettes must share the same world lookup")
		distant.free()
		palette_count += 1
	check(palette_count==12,"All twelve non-jungle habitats need palettes")
	check(GROUND.palette().get_image().get_pixel(5,10)!=GROUND.palette().get_image().get_pixel(4,7),"Snow and volcanic ground must differ")
	check(preload("res://jungle_water.gd").ground_material().get_shader_parameter("biome_palette")==GROUND.palette(),"Jungle borders must use the same world lookup")
	if "--capture" in OS.get_cmdline_user_args():
		check(DisplayServer.get_name()!="headless","Capture requires rendering")
		var scene := Node3D.new()
		root.add_child(scene)
		var terrain := MeshInstance3D.new()
		var origin := Vector2(180,180)
		terrain.mesh = TERRAIN.build_mesh(origin)
		terrain.position = Vector3(origin.x,0,origin.y)
		terrain.material_override = GROUND.material("Glacier Valley",origin)
		scene.add_child(terrain)
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-55,-30,0)
		scene.add_child(light)
		var camera := Camera3D.new()
		scene.add_child(camera)
		var center := Vector3(180,TERRAIN.height_at(180,180),180)
		camera.position = center+Vector3(18,16,22)
		camera.look_at(center)
		for frame in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://.validation/reserve_ground_glacier.png")==OK,"Capture must save")
		var neighbor := MeshInstance3D.new()
		neighbor.mesh = TERRAIN.build_mesh(Vector2(120,180))
		neighbor.position = Vector3(120,0,180)
		neighbor.material_override = GROUND.material("Highland Plateau",Vector2(120,180))
		scene.add_child(neighbor)
		center = Vector3(150,TERRAIN.height_at(150,180),180)
		camera.position = center+Vector3(0,38,40)
		camera.look_at(center)
		for frame in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://.validation/reserve_ground_border.png")==OK,"Border capture must save")
		scene.queue_free()
		await process_frame
	print("Reserve ground smoke: %s" % ("PASS" if failures==0 else "FAIL"))
	quit(0 if failures==0 else 1)
