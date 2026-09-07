extends Node3D

const ENVIRONMENT_QUALITY = preload("res://environment_quality.gd")
const TERRAIN = preload("res://valley_terrain.gd")
const JUNGLE = preload("res://jungle_habitat.gd")

var chunk_state: Dictionary = {}
var visual_time := 0.0
var uses_heightfield := false
var decoration_steps: Array[Callable] = []
static var clearance_white_texture: ImageTexture

func apply_visual_tier(tier: String, force: bool = false) -> void:
	if not force and get_meta("stream_tier","")==tier:
		return
	set_meta("stream_tier",tier)
	preload("res://reserve_water.gd").apply_bank_quality(self)
	if JUNGLE.contains(str(get_meta("biome",""))):
		if has_node("AssetPackDressing"):
			preload("res://jungle_dressing.gd").apply_quality(self)
	else:
		var vegetation := get_node_or_null("Vegetation") as MultiMeshInstance3D
		if vegetation != null:
			vegetation.multimesh.visible_instance_count = vegetation.multimesh.instance_count if tier=="full" else maxi(1,floori(vegetation.multimesh.instance_count*0.55))

func build_next_decoration() -> void:
	if not decoration_steps.is_empty():
		var step: Callable = decoration_steps.pop_front()
		step.call()

func _ground_height(x: float, z: float) -> float:
	return TERRAIN.height_at(position.x + x, position.z + z) if uses_heightfield else 0.0

func _process(delta: float) -> void:
	if JUNGLE.contains(str(get_meta("biome", ""))):
		return # Shared shader wind; water levels never bob.
	var water := get_node_or_null("WaterSurface") as MeshInstance3D
	if water != null and water.material_override is ShaderMaterial:
		water.material_override.set_shader_parameter("motion",0.0 if ENVIRONMENT_QUALITY.reduced_motion else 1.0)
	if ENVIRONMENT_QUALITY.reduced_motion:
		return
	visual_time += delta
	var dressing := get_node_or_null("AssetPackDressing") as Node3D
	if dressing != null:
		var wind_amount := 0.018 * float(ENVIRONMENT_QUALITY.preset({}).get("effects", 1.0)) * preload("res://jungle_dressing.gd").wind_multiplier
		for prop in dressing.get_children():
			if not prop.has_meta("wind_sway"):
				continue
			var phase := float(prop.get_meta("wind_sway", 0.0))
			prop.rotation.z = sin(visual_time * 1.3 + phase) * wind_amount

func apply_chunk_profile(profile: RefCounted) -> void:
	set_meta("ground_color", profile.ground_color)
	set_meta("vegetation_density", profile.vegetation_density)
	set_meta("fog_density", profile.fog_density)
	set_meta("navigation_layers", profile.navigation_layers)
	set_meta("agent_radius", profile.agent_radius)
	set_meta("max_slope_degrees", profile.max_slope_degrees)
	set_meta("max_climb", profile.max_climb)
	var navigation_region := get_node_or_null("NavigationRegion") as NavigationRegion3D
	if navigation_region != null:
		navigation_region.navigation_layers = profile.navigation_layers
		navigation_region.set_meta("max_slope_degrees", profile.max_slope_degrees)
		navigation_region.set_meta("max_climb", profile.max_climb)
		if navigation_region.navigation_mesh != null:
			navigation_region.navigation_mesh.agent_radius = profile.agent_radius
	var biome_environment := get_node_or_null("BiomeEnvironment") as WorldEnvironment
	if biome_environment != null and biome_environment.environment != null:
		biome_environment.environment.fog_density = profile.fog_density
		biome_environment.environment.background_color = profile.ground_color.lightened(0.45)
		biome_environment.environment.ambient_light_color = profile.ground_color.lightened(0.6)
		biome_environment.environment.fog_light_color = profile.ground_color.lightened(0.3)
		biome_environment.environment.fog_sky_affect = 0.15
	var vegetation := get_node_or_null("Vegetation") as MultiMeshInstance3D
	if vegetation != null and vegetation.multimesh != null:
		var base_count := int(get_meta("vegetation_base_count", vegetation.multimesh.instance_count))
		set_meta("vegetation_base_count", base_count)
		vegetation.multimesh.instance_count = maxi(1, int(round(float(base_count) * profile.vegetation_density)))
		for index in vegetation.multimesh.instance_count:
			vegetation.multimesh.set_instance_transform(index,_ground_cover_transform(index))
	var ground := get_node_or_null("Ground") as MeshInstance3D
	if not uses_heightfield and ground != null and ground.material_override is StandardMaterial3D:
		(ground.material_override as StandardMaterial3D).albedo_color = profile.ground_color
	var elevation := get_node_or_null("Elevation") as MeshInstance3D
	if elevation != null and elevation.material_override is StandardMaterial3D:
		(elevation.material_override as StandardMaterial3D).albedo_color = profile.ground_color
	var landmark := get_node_or_null("LandmarkSilhouette") as MeshInstance3D
	if landmark != null and landmark.material_override is StandardMaterial3D:
		(landmark.material_override as StandardMaterial3D).albedo_color = profile.ground_color.darkened(0.18)
	var water := get_node_or_null("WaterSurface") as MeshInstance3D
	if water != null and water.material_override is StandardMaterial3D:
		var water_color: Color = profile.ground_color.lightened(0.18)
		water_color.a = 0.72
		(water.material_override as StandardMaterial3D).albedo_color = water_color
	var particles := get_node_or_null("AmbientParticles") as GPUParticles3D
	if particles != null and particles.draw_pass_1 is QuadMesh:
		var particle_mesh := particles.draw_pass_1 as QuadMesh
		if particle_mesh.material is StandardMaterial3D:
			(particle_mesh.material as StandardMaterial3D).albedo_color = profile.ground_color.lightened(0.35)

func apply_chunk_state(state: Dictionary) -> void:
	chunk_state = state.duplicate(true)

func _ready() -> void:
	var biome := str(get_meta("biome", "Biome"))
	uses_heightfield = TERRAIN.is_heightfield_biome(biome)
	var landmark := str(get_meta("landmark", biome))
	var phase_started := Time.get_ticks_usec()
	_create_ground(biome)
	var ground_ms := float(Time.get_ticks_usec()-phase_started)/1000.0
	_create_environment(biome)
	if JUNGLE.contains(biome):
		preload("res://jungle_dressing.gd").build_trunks(self,biome)
		for kind in JUNGLE.BUDGETS:
			decoration_steps.append(preload("res://jungle_dressing.gd").build.bind(self,biome,false,[kind]))
		(get_node("Ground") as MeshInstance3D).material_override = preload("res://jungle_water.gd").ground_material()
		if biome == "River Wetlands":
			decoration_steps.append(preload("res://jungle_water.gd").build.bind(self))
	else:
		decoration_steps.append(_create_vegetation.bind(biome))
		decoration_steps.append(_create_asset_pack_dressing.bind(biome))
		decoration_steps.append(_create_water.bind(biome))
	decoration_steps.append(_create_ambient_particles.bind(biome))
	if not bool(get_meta("defer_decoration",false)):
		while not decoration_steps.is_empty():
			build_next_decoration()
	phase_started = Time.get_ticks_usec()
	_create_navigation()
	set_meta("core_timings",{"ground_ms":ground_ms,"navigation_ms":float(Time.get_ticks_usec()-phase_started)/1000.0})
	_create_landmark_silhouette(biome)
	var marker := MeshInstance3D.new()
	var pillar := CylinderMesh.new()
	pillar.top_radius = 0.18
	pillar.bottom_radius = 0.42
	pillar.height = 2.2
	marker.mesh = pillar
	marker.material_override = _biome_material(biome)
	marker.position.y = _ground_height(0.0, 0.0) + 1.1
	add_child(marker)
	var label := Label3D.new()
	label.text = landmark
	label.position.y = 1.6
	label.font_size = 28
	label.outline_size = 7
	label.modulate = Color.WHITE
	label.outline_modulate = Color("#163342")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.visibility_range_begin = 3.0
	label.visibility_range_end = 38.0
	marker.add_child(label)

func _create_environment(biome: String) -> void:
	if not get_tree().get_nodes_in_group("world_controller").is_empty():
		return
	var environment_node := WorldEnvironment.new()
	environment_node.name = "BiomeEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	var biome_color := _biome_material(biome).albedo_color
	sky_material.sky_top_color = biome_color.darkened(0.35)
	sky_material.sky_horizon_color = biome_color.lightened(0.28)
	sky_material.ground_bottom_color = biome_color.darkened(0.55)
	sky_material.ground_horizon_color = biome_color.darkened(0.05)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.background_color = biome_color.lightened(0.25)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = environment.background_color.lightened(0.15)
	environment.ambient_light_energy = 0.55 if biome != "Moonlit Grove" and biome != "Glacier Valley" else 0.42
	environment.ssao_enabled = true
	environment.ssao_radius = 1.6
	environment.ssao_intensity = 0.9
	environment.ssao_power = 1.2
	environment.fog_enabled = true
	environment.fog_light_color = biome_color.lightened(0.12)
	environment.fog_density = float(get_meta("fog_density", 0.006)) * 1.15
	environment.fog_sky_affect = 0.3
	environment.fog_height = 1.0
	environment.fog_height_density = 0.02
	environment_node.environment = environment
	add_child(environment_node)

func _biome_material(biome: String) -> StandardMaterial3D:
	var color := Color("#72ae50")
	if biome == "Fernwood":
		color = Color("#4f8e55")
	elif biome == "River Wetlands":
		color = Color("#6bb8a0")
	elif biome == "Sunstone Ridge":
		color = Color("#c88b55")
	elif biome == "Redstone Badlands":
		color = Color("#c97862")
	elif biome == "Ancient Meadow":
		color = Color("#91c85a")
	elif biome == "Cloudforest Rise":
		color = Color("#568b78")
	elif biome == "Coastal Marsh":
		color = Color("#6caa8d")
	elif biome == "Volcanic Foothills":
		color = Color("#9c6257")
	elif biome == "Fossil Flats":
		color = Color("#b49b68")
	elif biome == "Redwood Canyon":
		color = Color("#536f4d")
	elif biome == "Highland Plateau":
		color = Color("#8a8370")
	elif biome == "Moonlit Grove":
		color = Color("#536c78")
	elif biome == "Saltwind Dunes":
		color = Color("#c4a36c")
	elif biome == "Glacier Valley":
		color = Color("#8bb4c2")
	elif biome == "Cypress Basin":
		color = Color("#587b62")
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	var texture_path := "res://Textures/Grass.png"
	if biome == "Sunstone Ridge" or biome == "Redstone Badlands" or biome == "Fossil Flats" or biome == "Saltwind Dunes":
		texture_path = "res://Textures/Rocks_Desert_Diffuse.png"
	elif biome == "Volcanic Foothills" or biome == "Highland Plateau" or biome == "Glacier Valley":
		texture_path = "res://Textures/PathRocks_Diffuse.png"
	elif biome == "River Wetlands" or biome == "Coastal Marsh" or biome == "Cypress Basin":
		texture_path = "res://Textures/Leaves.png"
	var albedo := load(texture_path) as Texture2D if ResourceLoader.exists(texture_path) else null
	if albedo != null:
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		material.albedo_texture = albedo
		material.uv1_scale = Vector3(5.0, 5.0, 5.0) if texture_path.find("Grass") >= 0 else Vector3(3.5, 3.5, 3.5)
	material.roughness = 0.86
	material.metallic = 0.0
	return material

func _create_ground(biome: String) -> void:
	if uses_heightfield:
		var origin := Vector2(position.x, position.z)
		var terrain := MeshInstance3D.new()
		terrain.name = "Ground"
		terrain.mesh = TERRAIN.build_mesh(origin)
		terrain.material_override = preload("res://reserve_ground.gd").material(biome,origin)
		terrain.visibility_range_end = 260.0
		add_child(terrain)
		var terrain_body := StaticBody3D.new()
		terrain_body.name = "GroundCollision"
		var terrain_collider := CollisionShape3D.new()
		terrain_collider.name = "GroundShape"
		var terrain_shape := ConcavePolygonShape3D.new()
		terrain_shape.data = TERRAIN.collision_faces(origin)
		terrain_collider.shape = terrain_shape
		terrain_body.add_child(terrain_collider)
		add_child(terrain_body)
		return
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60.0, 60.0)
	ground.mesh = plane
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	ground.visibility_range_begin = 0.0
	ground.visibility_range_end = 220.0
	ground.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	ground.material_override = _biome_material(biome)
	ground.position.y = 0.0
	ground.name = "Ground"
	add_child(ground)
	var body := StaticBody3D.new()
	body.name = "GroundCollision"
	var collider := CollisionShape3D.new()
	collider.name = "GroundShape"
	var shape := BoxShape3D.new()
	shape.size = Vector3(60.0, 0.25, 60.0)
	collider.shape = shape
	collider.position.y = -0.125
	body.add_child(collider)
	add_child(body)

func _create_geology_layers(biome: String, mound_size: Vector3, mound_position: Vector3) -> void:
	var layered := biome == "Sunstone Ridge" or biome == "Redstone Badlands" or biome == "Volcanic Foothills" or biome == "Fossil Flats" or biome == "Highland Plateau"
	if not layered:
		return
	var layer_color := _biome_material(biome).albedo_color.darkened(0.22)
	for index in 3:
		var layer := MeshInstance3D.new()
		layer.name = "GeologyLayer_%d" % index
		var mesh := BoxMesh.new()
		var inset := float(index) * 1.8
		mesh.size = Vector3(maxf(4.0, mound_size.x - inset), 0.18 + float(index) * 0.08, maxf(4.0, mound_size.z - inset))
		layer.mesh = mesh
		layer.position = mound_position + Vector3(0.0, -mound_size.y * 0.38 + float(index) * 0.42, 0.0)
		var material := _biome_material(biome)
		material.albedo_color = layer_color.lightened(float(index) * 0.12)
		material.roughness = 0.94
		layer.material_override = material
		layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		layer.visibility_range_end = 180.0
		add_child(layer)

func _create_elevation(biome: String) -> void:
	var size := Vector3(18.0, 1.2, 14.0)
	var position := Vector3(0.0, 0.55, 0.0)
	if biome == "Sunstone Ridge":
		size = Vector3(24.0, 4.0, 16.0)
		position = Vector3(8.0, 2.0, -5.0)
	elif biome == "Redstone Badlands":
		size = Vector3(20.0, 3.0, 18.0)
		position = Vector3(-7.0, 1.5, 4.0)
	elif biome == "River Wetlands":
		size = Vector3(16.0, 0.7, 12.0)
		position = Vector3(-5.0, 0.35, -4.0)
	elif biome == "Ancient Meadow":
		size = Vector3(22.0, 1.8, 18.0)
		position = Vector3(5.0, 0.9, 5.0)
	elif biome == "Fernwood":
		size = Vector3(14.0, 1.0, 20.0)
		position = Vector3(-6.0, 0.5, 6.0)
	elif biome == "Cloudforest Rise":
		size = Vector3(20.0, 2.6, 16.0)
		position = Vector3(-8.0, 1.3, -3.0)
	elif biome == "Coastal Marsh":
		size = Vector3(18.0, 0.6, 20.0)
		position = Vector3(6.0, 0.3, 7.0)
	elif biome == "Volcanic Foothills":
		size = Vector3(24.0, 5.0, 18.0)
		position = Vector3(7.0, 2.5, 5.0)
	elif biome == "Fossil Flats":
		size = Vector3(20.0, 1.0, 22.0)
		position = Vector3(-8.0, 0.5, 6.0)
	elif biome == "Redwood Canyon":
		size = Vector3(18.0, 3.4, 24.0)
		position = Vector3(-6.0, 1.7, -6.0)
	elif biome == "Highland Plateau":
		size = Vector3(26.0, 6.0, 16.0)
		position = Vector3(8.0, 3.0, -4.0)
	elif biome == "Moonlit Grove":
		size = Vector3(16.0, 1.4, 20.0)
		position = Vector3(-5.0, 0.7, 7.0)
	elif biome == "Saltwind Dunes":
		size = Vector3(24.0, 2.2, 14.0)
		position = Vector3(6.0, 1.1, -7.0)
	elif biome == "Glacier Valley":
		size = Vector3(22.0, 4.4, 20.0)
		position = Vector3(7.0, 2.2, 6.0)
	elif biome == "Cypress Basin":
		size = Vector3(20.0, 1.0, 18.0)
		position = Vector3(-7.0, 0.5, 5.0)
	var mound := MeshInstance3D.new()
	mound.name = "Elevation"
	var mesh := BoxMesh.new()
	mesh.size = size
	mound.mesh = mesh
	mound.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	mound.visibility_range_begin = 0.0
	mound.visibility_range_end = 220.0
	mound.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	mound.position = position
	mound.material_override = _biome_material(biome).duplicate()
	add_child(mound)
	var body := StaticBody3D.new()
	body.name = "ElevationCollision"
	var collider := CollisionShape3D.new()
	collider.name = "ElevationShape"
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	collider.position = position
	body.add_child(collider)
	add_child(body)
	_create_geology_layers(biome, size, position)

func _create_vegetation(biome: String) -> void:
	var foliage := MultiMeshInstance3D.new()
	foliage.name = "Vegetation"
	foliage.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	foliage.visibility_range_begin = 0.0
	foliage.visibility_range_end = 65.0
	foliage.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	var quality: Dictionary = ENVIRONMENT_QUALITY.preset({})
	var foliage_count := int(180.0 * float(quality["foliage"]))
	if biome == "River Wetlands" or biome == "Coastal Marsh":
		foliage_count = int(140.0 * float(quality["foliage"]))
	elif biome == "Volcanic Foothills" or biome == "Highland Plateau" or biome == "Glacier Valley" or biome == "Saltwind Dunes":
		foliage_count = int(40.0 * float(quality["foliage"]))
	elif biome == "Cypress Basin" or biome == "Redwood Canyon":
		foliage_count = int(220.0 * float(quality["foliage"]))
	batch.instance_count = foliage_count
	set_meta("vegetation_base_count", foliage_count)
	var barren := biome in ["Glacier Valley","Volcanic Foothills","Saltwind Dunes"]
	batch.mesh = preload("res://jungle_dressing.gd").mesh_for("res://glTF/Rock_Medium_1.gltf" if barren else "res://glTF/Grass_Wispy_Short.gltf","rock" if barren else "grass")
	for index in batch.instance_count:
		batch.set_instance_transform(index,_ground_cover_transform(index))
	foliage.multimesh = batch
	add_child(foliage)
	_create_ground_debris(biome, mini(foliage_count,24))

func _ground_cover_transform(index: int) -> Transform3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3(position.x,float(index),position.z))
	# Each indexed sample is independent, so density changes retain existing positions.
	var x := rng.randf_range(4.0,28.0)*(1.0 if rng.randf()>0.5 else -1.0)
	var z := rng.randf_range(4.0,28.0)*(1.0 if rng.randf()>0.5 else -1.0)
	var biome := str(get_meta("biome",""))
	if biome in ["Coastal Marsh","Cypress Basin"]:
		var water = preload("res://reserve_water.gd")
		# Move wet samples to the dry opposite side, outside the pond footprint.
		if water.shore_distance(Vector2(x,z),Vector2(-4,6))<2.0:
			x = rng.randf_range(17.0,28.0)
	var height_scale := rng.randf_range(0.32,0.65)
	return Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*height_scale),Vector3(x,_ground_height(x,z),z))

func _create_ground_debris(biome: String, foliage_count: int) -> void:
	var debris := MultiMeshInstance3D.new()
	debris.name = "GroundDebris"
	debris.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	debris.visibility_range_begin = 0.0
	debris.visibility_range_end = 85.0
	debris.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.instance_count = maxi(5, int(foliage_count * 0.7))
	var rock_mesh := SphereMesh.new()
	rock_mesh.radius = 0.24
	rock_mesh.height = 0.18
	rock_mesh.radial_segments = 6
	rock_mesh.rings = 3
	var material := _biome_material(biome)
	material.albedo_color = material.albedo_color.darkened(0.22)
	material.roughness = 0.98
	rock_mesh.material = material
	batch.mesh = rock_mesh
	for index in batch.instance_count:
		var x := float((index * 19) % 31) - 15.0
		var z := float((index * 23) % 31) - 15.0
		var scale := 0.55 + float(index % 4) * 0.16
		batch.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3(scale, 0.65 * scale, scale)), Vector3(x, _ground_height(x, z) + 0.12, z)))
	debris.multimesh = batch
	add_child(debris)

func _create_asset_pack_dressing(biome: String) -> void:
	# Imported asset-pack scenes are optional presentation layers.  The procedural
	# vegetation above remains the fallback for clean clones or missing imports.
	var dressing := Node3D.new()
	dressing.name = "AssetPackDressing"
	var paths: Array[String] = [
		"res://glTF/CommonTree_2.gltf",
		"res://glTF/Fern_1.gltf",
		"res://glTF/Rock_Medium_1.gltf",
		"res://glTF/Bush_Common.gltf",
		"res://glTF/Flower_3_Group.gltf",
		"res://glTF/Rock_Medium_2.gltf"
	]
	if biome == "Sunstone Ridge" or biome == "Volcanic Foothills" or biome == "Highland Plateau" or biome == "Saltwind Dunes":
		paths = ["res://glTF/Rock_Medium_1.gltf", "res://glTF/Rock_Medium_2.gltf", "res://glTF/Pine_2.gltf", "res://glTF/DeadTree_2.gltf"]
	elif biome == "Redstone Badlands" or biome == "Fossil Flats":
		paths = ["res://glTF/Rock_Medium_3.gltf", "res://glTF/DeadTree_3.gltf", "res://glTF/DeadTree_5.gltf", "res://glTF/Rock_Medium_2.gltf"]
	elif biome == "River Wetlands" or biome == "Coastal Marsh" or biome == "Cypress Basin":
		paths = ["res://glTF/Fern_1.gltf", "res://glTF/Bush_Common.gltf", "res://glTF/Flower_3_Group.gltf", "res://glTF/CommonTree_1.gltf"]
	elif biome == "Ancient Meadow" or biome == "Cloudforest Rise" or biome == "Fernwood" or biome == "Moonlit Grove":
		paths = ["res://glTF/CommonTree_3.gltf", "res://glTF/Fern_1.gltf", "res://glTF/Flower_4_Group.gltf", "res://glTF/Bush_Common_Flowers.gltf", "res://glTF/Rock_Medium_1.gltf"]
	var quality: Dictionary = ENVIRONMENT_QUALITY.preset({})
	var foliage_scale := float(quality.get("foliage", 1.0))
	var prop_count := mini(paths.size(), maxi(3, int(ceil(paths.size() * foliage_scale))))
	for index in prop_count:
		var path_index := index % paths.size()
		var packed := load(paths[path_index]) as PackedScene if ResourceLoader.exists(paths[path_index]) else null
		if packed == null:
			continue
		var prop := packed.instantiate() as Node3D
		if prop == null:
			continue
		prop.name = "PackProp_%d" % index
		prop.position = Vector3(float((index * 11) % 23) - 11.0, 0.0, float((index * 17) % 23) - 11.0)
		prop.position.y = _ground_height(prop.position.x, prop.position.z)
		prop.rotation.y = float(index) * 1.4
		prop.scale = Vector3.ONE * (0.65 + float(index % 2) * 0.18)
		prop.set_meta("environment_lod", "hero" if index == 0 else "detail")
		prop.set_meta("biome", biome)
		var prop_path := paths[path_index].to_lower()
		if prop_path.contains("tree") or prop_path.contains("pine"):
			_apply_tree_camera_clearance(prop)
		if prop_path.find("tree") >= 0 or prop_path.find("fern") >= 0 or prop_path.find("flower") >= 0 or prop_path.find("bush") >= 0 or prop_path.find("pine") >= 0:
			prop.set_meta("wind_sway", float(index) * 0.8 + float(biome.hash() % 17))
		_apply_prop_visibility(prop, quality)
		dressing.add_child(prop)
	add_child(dressing)

func _apply_tree_camera_clearance(prop: Node3D) -> void:
	if clearance_white_texture == null:
		var image := Image.create(1,1,false,Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		clearance_white_texture = ImageTexture.create_from_image(image)
	# Imported scenes may nest meshes below several transform nodes.
	for node in prop.find_children("*","MeshInstance3D",true,false):
		var visual := node as MeshInstance3D
		for surface in visual.mesh.get_surface_count():
			var original := visual.get_active_material(surface) as StandardMaterial3D
			if original == null:
				continue
			var material := ShaderMaterial.new()
			material.shader = preload("res://assets/environment/jungle_foliage.gdshader")
			material.set_shader_parameter("albedo_texture",original.albedo_texture if original.albedo_texture != null else clearance_white_texture)
			material.set_shader_parameter("tint",original.albedo_color)
			material.set_shader_parameter("wind",0.0)
			material.set_shader_parameter("camera_clearance",3.0)
			visual.set_surface_override_material(surface,material)

func _apply_prop_visibility(prop: Node3D, quality: Dictionary) -> void:
	var end_distance := 95.0 * float(quality.get("foliage", 1.0))
	for node in prop.get_children():
		var visual := node as GeometryInstance3D
		if visual == null:
			continue
		visual.visibility_range_begin = 0.0
		visual.visibility_range_end = end_distance
		visual.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED

func _create_water(biome: String) -> void:
	if biome != "River Wetlands" and biome != "Coastal Marsh" and biome != "Cypress Basin":
		return
	var water := MeshInstance3D.new()
	water.name = "WaterSurface"
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water.visibility_range_begin = 0.0
	water.visibility_range_end = 140.0
	water.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	water.mesh = preload("res://reserve_water.gd").mesh(Vector2(position.x,position.z))
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/environment/reserve_water.gdshader")
	material.set_shader_parameter("opacity",0.72)
	material.set_shader_parameter("roughness",0.32)
	material.set_shader_parameter("motion",0.0 if ENVIRONMENT_QUALITY.reduced_motion else 1.0)
	water.material_override = material
	add_child(water)
	preload("res://reserve_water.gd").build_bank_reeds(self)

func _create_ambient_particles(biome: String) -> void:
	if not ENVIRONMENT_QUALITY.weather_enabled:
		return
	var quality: Dictionary = ENVIRONMENT_QUALITY.preset({})
	var effects_scale := float(quality.get("effects", 1.0))
	var particles := GPUParticles3D.new()
	particles.name = "AmbientParticles"
	particles.visibility_range_begin = 0.0
	particles.visibility_range_end = 90.0
	particles.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	var particle_count := maxi(2, int(7.0 * effects_scale))
	if biome == "River Wetlands" or biome == "Coastal Marsh" or biome == "Cypress Basin":
		particle_count = maxi(3, int(10.0 * effects_scale))
	elif biome == "Volcanic Foothills":
		particle_count = maxi(2, int(5.0 * effects_scale))
	elif biome == "Glacier Valley" or biome == "Highland Plateau":
		particle_count = maxi(2, int(4.0 * effects_scale))
	particles.amount = particle_count
	particles.set_meta("base_particle_count", particle_count)
	particles.lifetime = 5.0
	particles.visibility_aabb = AABB(Vector3(-30.0, -1.0, -30.0), Vector3(60.0, 12.0, 60.0))
	var particle_material := StandardMaterial3D.new()
	particle_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var particle_color := Color("#d8f1b0")
	if biome == "Redstone Badlands" or biome == "Volcanic Foothills":
		particle_color = Color("#f5c78c")
	elif biome == "Glacier Valley" or biome == "Highland Plateau":
		particle_color = Color("#d8f4ff")
	elif biome == "Moonlit Grove":
		particle_color = Color("#b5d2ff")
	particle_material.albedo_color = particle_color
	var particle_mesh := QuadMesh.new()
	particle_mesh.size = Vector2(0.08, 0.08)
	particle_mesh.material = particle_material
	particles.draw_pass_1 = particle_mesh
	var process_material := ParticleProcessMaterial.new()
	process_material.gravity = Vector3(0.0, -0.03, 0.0)
	process_material.initial_velocity_min = 0.08
	process_material.initial_velocity_max = 0.18
	process_material.spread = 35.0
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(24.0, 3.0, 24.0)
	particles.process_material = process_material
	add_child(particles)
	_create_weather_particles(biome, effects_scale)

func _create_weather_particles(biome: String, effects_scale: float) -> void:
	if not get_tree().get_nodes_in_group("world_controller").is_empty():
		return # The live reserve uses one player-centered weather emitter.
	var weather_kind := ""
	if biome == "River Wetlands" or biome == "Coastal Marsh" or biome == "Cypress Basin":
		weather_kind = "mist"
	elif biome == "Glacier Valley":
		weather_kind = "snow"
	elif biome == "Redstone Badlands" or biome == "Saltwind Dunes" or biome == "Volcanic Foothills":
		weather_kind = "dust"
	if weather_kind.is_empty():
		return
	var particles := GPUParticles3D.new()
	particles.name = "BiomeWeather_%s" % weather_kind
	particles.amount = maxi(4, int(18.0 * effects_scale))
	particles.set_meta("base_particle_count", 18)
	particles.lifetime = 4.0 if weather_kind == "mist" else 2.5
	particles.visibility_aabb = AABB(Vector3(-30.0, -2.0, -30.0), Vector3(60.0, 14.0, 60.0))
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.74, 0.86, 0.92, 0.16) if weather_kind == "mist" else Color(0.9, 0.9, 0.82, 0.3)
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.12, 0.12) if weather_kind != "snow" else Vector2(0.2, 0.2)
	mesh.material = material
	particles.draw_pass_1 = mesh
	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(25.0, 5.0, 25.0)
	process_material.gravity = Vector3(0.0, -0.12 if weather_kind == "snow" else -0.02, 0.0)
	process_material.initial_velocity_min = 0.1 if weather_kind == "mist" else 0.35
	process_material.initial_velocity_max = 0.25 if weather_kind == "mist" else 0.7
	process_material.spread = 45.0
	particles.process_material = process_material
	add_child(particles)

func _create_navigation() -> void:
	var region := NavigationRegion3D.new()
	region.name = "NavigationRegion"
	if uses_heightfield:
		var biome := str(get_meta("biome", ""))
		var path := "res://assets/environment/jungle_%s_navigation.tres" % JUNGLE.IDS[JUNGLE.BIOMES.find(biome)] if JUNGLE.contains(biome) else ""
		region.navigation_mesh = load(path) as NavigationMesh if not path.is_empty() and ResourceLoader.exists(path) else _build_heightfield_navigation_mesh(Vector2(position.x, position.z))
		add_child(region)
		return
	var nav_mesh := NavigationMesh.new()
	nav_mesh.vertices = PackedVector3Array([
		Vector3(-29.0, 0.02, -29.0), Vector3(29.0, 0.02, -29.0),
		Vector3(29.0, 0.02, 29.0), Vector3(-29.0, 0.02, 29.0)
	])
	nav_mesh.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	nav_mesh.agent_radius = float(get_meta("agent_radius", 0.8))
	nav_mesh.agent_height = 1.8
	region.navigation_mesh = nav_mesh
	add_child(region)

func _build_heightfield_navigation_mesh(origin: Vector2) -> NavigationMesh:
	var nav_mesh := NavigationMesh.new()
	var vertices := PackedVector3Array()
	var spacing := TERRAIN.CHUNK_SIZE / float(TERRAIN.COLLISION_CELLS)
	for row in TERRAIN.COLLISION_CELLS + 1:
		for column in TERRAIN.COLLISION_CELLS + 1:
			var x := -TERRAIN.HALF_SIZE + float(column) * spacing
			var z := -TERRAIN.HALF_SIZE + float(row) * spacing
			vertices.append(Vector3(x, TERRAIN.height_at(origin.x + x, origin.y + z), z))
	nav_mesh.vertices = vertices
	for row in TERRAIN.COLLISION_CELLS:
		for column in TERRAIN.COLLISION_CELLS:
			var a := row * (TERRAIN.COLLISION_CELLS + 1) + column
			var b := a + 1
			var c := a + TERRAIN.COLLISION_CELLS + 2
			var d := a + TERRAIN.COLLISION_CELLS + 1
			nav_mesh.add_polygon(PackedInt32Array([a, b, c]))
			nav_mesh.add_polygon(PackedInt32Array([a, c, d]))
	nav_mesh.agent_radius = float(get_meta("agent_radius", 0.8))
	nav_mesh.agent_height = 1.8
	nav_mesh.agent_max_slope = float(get_meta("max_slope_degrees", 35.0))
	nav_mesh.agent_max_climb = float(get_meta("max_climb", 0.5))
	nav_mesh.set_meta("terrain_fingerprint", hash(TERRAIN.collision_faces(origin)))
	return nav_mesh

func _create_landmark_silhouette(biome: String) -> void:
	var silhouette := MeshInstance3D.new()
	silhouette.name = "LandmarkSilhouette"
	var mesh: PrimitiveMesh = CylinderMesh.new()
	var silhouette_height := 2.8
	var landmark_kind := "stone_marker"
	var landmark_position := Vector3(-10.0, 0.0, -10.0)
	if biome == "Sunstone Ridge" or biome == "Redstone Badlands":
		var spire := PrismMesh.new()
		spire.size = Vector3(3.0, 7.0, 3.0)
		mesh = spire
		silhouette_height = 7.0
		landmark_kind = "ridge_spire"
		landmark_position = Vector3(10.0, 0.0, -8.0)
	elif biome == "Volcanic Foothills":
		var cone := PrismMesh.new()
		cone.size = Vector3(4.0, 6.0, 4.0)
		mesh = cone
		silhouette_height = 6.0
		landmark_kind = "volcanic_cone"
		landmark_position = Vector3(9.0, 0.0, 8.0)
	elif biome == "Glacier Valley" or biome == "Highland Plateau":
		var ice := CylinderMesh.new()
		ice.top_radius = 0.35
		ice.bottom_radius = 1.2
		ice.height = 4.5
		mesh = ice
		silhouette_height = 4.5
		landmark_kind = "ice_beacon"
		landmark_position = Vector3(9.0, 0.0, 8.0)
	elif biome == "River Wetlands":
		var beacon := CylinderMesh.new()
		beacon.top_radius = 0.2
		beacon.bottom_radius = 1.0
		beacon.height = 5.0
		mesh = beacon
		landmark_kind = "wetland_beacon"
		landmark_position = Vector3(7.0, 0.0, 7.0)
	elif biome == "Volcanic Foothills" or biome == "Highland Plateau" or biome == "Glacier Valley":
		landmark_position = Vector3(9.0, 0.0, 8.0)
	elif biome == "Redwood Canyon" or biome == "Cypress Basin":
		landmark_position = Vector3(-8.0, 0.0, 8.0)
	elif biome == "Saltwind Dunes" or biome == "Coastal Marsh":
		landmark_position = Vector3(8.0, 0.0, -8.0)
	else:
		var stone := CylinderMesh.new()
		stone.top_radius = 0.8
		stone.bottom_radius = 1.4
		stone.height = 2.8
		mesh = stone
	silhouette.mesh = mesh
	silhouette.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	silhouette.visibility_range_begin = 2.0
	silhouette.visibility_range_end = 180.0
	silhouette.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	landmark_position.y = _ground_height(landmark_position.x, landmark_position.z)
	silhouette.position = landmark_position + Vector3(0.0, silhouette_height * 0.5, 0.0)
	silhouette.material_override = _biome_material(biome)
	silhouette.set_meta("landmark_kind", landmark_kind)
	silhouette.set_meta("biome", biome)
	add_child(silhouette)
	var marker := MeshInstance3D.new()
	marker.name = "LandmarkGroundMarker"
	var ring := TorusMesh.new()
	ring.inner_radius = 1.05
	ring.outer_radius = 1.2
	marker.mesh = ring
	marker.position = landmark_position + Vector3.UP * 0.06
	marker.material_override = _biome_material(biome)
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.visibility_range_begin = 0.0
	marker.visibility_range_end = 90.0
	add_child(marker)
