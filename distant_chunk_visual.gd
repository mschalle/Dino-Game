extends Node3D

const TERRAIN = preload("res://valley_terrain.gd")
const HABITAT = preload("res://jungle_habitat.gd")

func configure(profile: RefCounted) -> void:
	name = "Distant_"+profile.chunk_id
	set_meta("stream_tier","distant")
	position = Vector3(profile.grid_position.x*TERRAIN.CHUNK_SIZE,0,profile.grid_position.y*TERRAIN.CHUNK_SIZE)
	var ground := MeshInstance3D.new()
	ground.name = "DistantGround"
	ground.mesh = TERRAIN.build_mesh(Vector2(position.x,position.z),TERRAIN.COLLISION_CELLS)
	ground.material_override = preload("res://jungle_water.gd").ground_material() if HABITAT.contains(profile.biome) else preload("res://reserve_ground.gd").material(profile.biome,Vector2(position.x,position.z))
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ground)
	var layout: Array[Transform3D] = []
	if HABITAT.contains(profile.biome):
		layout = HABITAT.placements(profile.biome,"tree")
	elif profile.biome in ["Cloudforest Rise","Redwood Canyon","Moonlit Grove","Cypress Basin","Coastal Marsh"]:
		for index in 12:
			var x := float((index*13)%51)-25.0
			var z := float((index*19)%51)-25.0
			layout.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*(5.0+index%3)),Vector3(x,TERRAIN.height_at(x+position.x,z+position.z),z)))
	if layout.is_empty():
		return
	var canopy := Node3D.new()
	canopy.name = "DistantCanopy"
	add_child(canopy)
	for variant in 3:
		var transforms: Array[Transform3D] = []
		for index in layout.size():
			if index%3==variant:
				transforms.append(layout[index])
		if transforms.is_empty():
			continue
		var trees := MultiMeshInstance3D.new()
		trees.name = "Tree%d" % (variant+1)
		trees.multimesh = MultiMesh.new()
		trees.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		trees.multimesh.mesh = preload("res://tree_impostor.gd").mesh_for(variant)
		trees.multimesh.instance_count = transforms.size()
		for index in transforms.size():
			trees.multimesh.set_instance_transform(index,transforms[index])
		trees.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		trees.lod_bias = 0.25
		canopy.add_child(trees)
