extends Node3D

var chunk_state: Dictionary = {}

func apply_chunk_profile(profile: RefCounted) -> void:
	set_meta("navigation_layers", profile.navigation_layers)
	set_meta("agent_radius", profile.agent_radius)
	set_meta("max_slope_degrees", profile.max_slope_degrees)
	set_meta("max_climb", profile.max_climb)

func apply_chunk_state(state: Dictionary) -> void:
	chunk_state = state.duplicate(true)

func _ready() -> void:
	var biome := str(get_meta("biome", "Biome"))
	var landmark := str(get_meta("landmark", biome))
	_create_ground(biome)
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
	if biome == "Sunstone Ridge" or biome == "Redstone Badlands":
		var spire := PrismMesh.new()
		spire.size = Vector3(3.0, 7.0, 3.0)
		mesh = spire
		silhouette_height = 7.0
		landmark_kind = "ridge_spire"
	elif biome == "River Wetlands":
		var beacon := CylinderMesh.new()
		beacon.top_radius = 0.2
		beacon.bottom_radius = 1.0
		beacon.height = 5.0
		mesh = beacon
		landmark_kind = "wetland_beacon"
	else:
		var stone := CylinderMesh.new()
		stone.top_radius = 0.8
		stone.bottom_radius = 1.4
		stone.height = 2.8
		mesh = stone
	silhouette.mesh = mesh
	silhouette.position = Vector3(-10.0, silhouette_height * 0.5, -10.0)
	silhouette.material_override = _biome_material(biome)
	silhouette.set_meta("landmark_kind", landmark_kind)
	silhouette.set_meta("biome", biome)
	add_child(silhouette)
