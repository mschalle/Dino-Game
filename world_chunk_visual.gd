extends Node3D

var chunk_state: Dictionary = {}

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
	var vegetation := get_node_or_null("Vegetation") as MultiMeshInstance3D
	if vegetation != null and vegetation.multimesh != null:
		var base_count := int(get_meta("vegetation_base_count", vegetation.multimesh.instance_count))
		set_meta("vegetation_base_count", base_count)
		vegetation.multimesh.instance_count = maxi(1, int(round(float(base_count) * profile.vegetation_density)))
		if vegetation.multimesh.mesh != null and vegetation.multimesh.mesh.material is StandardMaterial3D:
			(vegetation.multimesh.mesh.material as StandardMaterial3D).albedo_color = profile.ground_color.lightened(0.12)
		for index in vegetation.multimesh.instance_count:
			var x := float((index * 13) % 29) - 14.0
			var z := float((index * 17) % 29) - 14.0
			var height_scale := 0.8 + float(index % 3) * 0.15
			vegetation.multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * height_scale), Vector3(x, 0.35, z)))
	var ground := get_node_or_null("Ground") as MeshInstance3D
	if ground != null and ground.material_override is StandardMaterial3D:
		(ground.material_override as StandardMaterial3D).albedo_color = profile.ground_color
	var landmark := get_node_or_null("LandmarkSilhouette") as MeshInstance3D
	if landmark != null and landmark.material_override is StandardMaterial3D:
		(landmark.material_override as StandardMaterial3D).albedo_color = profile.ground_color.darkened(0.18)
	var water := get_node_or_null("WaterSurface") as MeshInstance3D
	if water != null and water.material_override is StandardMaterial3D:
		(water.material_override as StandardMaterial3D).albedo_color = profile.ground_color.lightened(0.18)
	var particles := get_node_or_null("AmbientParticles") as GPUParticles3D
	if particles != null and particles.draw_pass_1 is QuadMesh:
		var particle_mesh := particles.draw_pass_1 as QuadMesh
		if particle_mesh.material is StandardMaterial3D:
			(particle_mesh.material as StandardMaterial3D).albedo_color = profile.ground_color.lightened(0.35)

func apply_chunk_state(state: Dictionary) -> void:
	chunk_state = state.duplicate(true)

func _ready() -> void:
	var biome := str(get_meta("biome", "Biome"))
	var landmark := str(get_meta("landmark", biome))
	_create_ground(biome)
	_create_environment(biome)
	_create_elevation(biome)
	_create_vegetation(biome)
	_create_water(biome)
	_create_ambient_particles(biome)
	_create_navigation()
	_create_landmark_silhouette(biome)
	var marker := MeshInstance3D.new()
	var pillar := CylinderMesh.new()
	pillar.top_radius = 0.18
	pillar.bottom_radius = 0.42
	pillar.height = 2.2
	marker.mesh = pillar
	marker.material_override = _biome_material(biome)
	marker.position.y = 1.1
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
	var environment_node := WorldEnvironment.new()
	environment_node.name = "BiomeEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = _biome_material(biome).albedo_color.lightened(0.45)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = environment.background_color.lightened(0.15)
	environment.ambient_light_energy = 0.7 if biome != "Moonlit Grove" and biome != "Glacier Valley" else 0.55
	environment.fog_enabled = true
	environment.fog_light_color = environment.background_color
	environment.fog_density = float(get_meta("fog_density", 0.006))
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
	material.emission_enabled = true
	material.emission = color.darkened(0.35)
	material.emission_energy_multiplier = 0.35
	return material

func _create_ground(biome: String) -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60.0, 60.0)
	ground.mesh = plane
	ground.material_override = _biome_material(biome)
	ground.position.y = -0.12
	ground.name = "Ground"
	add_child(ground)
	var body := StaticBody3D.new()
	body.name = "GroundCollision"
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(60.0, 0.25, 60.0)
	collider.shape = shape
	collider.position.y = -0.12
	body.add_child(collider)
	add_child(body)

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
	mound.position = position
	mound.material_override = _biome_material(biome).duplicate()
	add_child(mound)
	var body := StaticBody3D.new()
	body.name = "ElevationCollision"
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	collider.position = position
	body.add_child(collider)
	add_child(body)

func _create_vegetation(biome: String) -> void:
	var foliage := MultiMeshInstance3D.new()
	foliage.name = "Vegetation"
	foliage.visibility_range_begin = 24.0
	foliage.visibility_range_end = 120.0
	foliage.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	var foliage_count := 16
	if biome == "River Wetlands" or biome == "Coastal Marsh":
		foliage_count = 10
	elif biome == "Volcanic Foothills" or biome == "Highland Plateau" or biome == "Glacier Valley" or biome == "Saltwind Dunes":
		foliage_count = 6
	elif biome == "Cypress Basin" or biome == "Redwood Canyon":
		foliage_count = 22
	batch.instance_count = foliage_count
	set_meta("vegetation_base_count", foliage_count)
	var blade := BoxMesh.new()
	blade.size = Vector3(0.22, 0.7, 0.22)
	blade.material = _biome_material(biome)
	batch.mesh = blade
	for index in batch.instance_count:
		var x := float((index * 13) % 29) - 14.0
		var z := float((index * 17) % 29) - 14.0
		var height_scale := 0.8 + float(index % 3) * 0.15
		if biome == "Redwood Canyon" or biome == "Cypress Basin":
			height_scale *= 1.35
		batch.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * height_scale), Vector3(x, 0.35, z)))
	foliage.multimesh = batch
	add_child(foliage)

func _create_water(biome: String) -> void:
	if biome != "River Wetlands" and biome != "Coastal Marsh" and biome != "Cypress Basin":
		return
	var water := MeshInstance3D.new()
	water.name = "WaterSurface"
	var surface := PlaneMesh.new()
	surface.size = Vector2(24.0, 18.0) if biome == "River Wetlands" else Vector2(20.0, 14.0)
	water.mesh = surface
	water.position = Vector3(6.0, 0.08, 5.0) if biome == "River Wetlands" else Vector3(-4.0, 0.08, 6.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#55b9d1") if biome != "Cypress Basin" else Color("#4f9f8b")
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.72
	material.roughness = 0.12
	material.metallic = 0.05
	water.material_override = material
	add_child(water)

func _create_ambient_particles(biome: String) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "AmbientParticles"
	particles.visibility_range_begin = 0.0
	particles.visibility_range_end = 90.0
	particles.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	var particle_count := 7
	if biome == "River Wetlands" or biome == "Coastal Marsh" or biome == "Cypress Basin":
		particle_count = 10
	elif biome == "Volcanic Foothills":
		particle_count = 5
	elif biome == "Glacier Valley" or biome == "Highland Plateau":
		particle_count = 4
	particles.amount = particle_count
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

func _create_navigation() -> void:
	var region := NavigationRegion3D.new()
	region.name = "NavigationRegion"
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
	silhouette.visibility_range_begin = 2.0
	silhouette.visibility_range_end = 180.0
	silhouette.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	silhouette.position = landmark_position + Vector3(0.0, silhouette_height * 0.5, 0.0)
	silhouette.material_override = _biome_material(biome)
	silhouette.set_meta("landmark_kind", landmark_kind)
	silhouette.set_meta("biome", biome)
	add_child(silhouette)
