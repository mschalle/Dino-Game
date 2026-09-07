@tool
extends SceneTree
const HABITAT = preload("res://jungle_habitat.gd")
const TERRAIN = preload("res://valley_terrain.gd")

func _init() -> void:
	for index in HABITAT.BIOMES.size():
		var mesh := NavigationMesh.new()
		mesh.agent_radius = 0.8
		mesh.agent_height = 1.8
		mesh.agent_max_slope = 35.0
		mesh.agent_max_climb = 0.5
		mesh.cell_size = 0.25
		mesh.cell_height = 0.1
		mesh.detail_sample_distance = 0.0
		mesh.detail_sample_max_error = 0.1
		var source := NavigationMeshSourceGeometryData3D.new()
		var faces := TERRAIN.collision_faces(HABITAT.ORIGINS[index])
		source.add_faces(faces, Transform3D.IDENTITY)
		var trunk := CylinderMesh.new()
		trunk.top_radius = 0.32
		trunk.bottom_radius = 0.32
		trunk.height = 3.0
		trunk.radial_segments = 12
		for placement in HABITAT.placements(HABITAT.BIOMES[index], "tree"):
			source.add_faces(trunk.get_faces(), Transform3D(Basis.IDENTITY, placement.origin + Vector3.UP * 1.5))
		NavigationServer3D.bake_from_source_geometry_data(mesh, source)
		mesh.set_meta("terrain_fingerprint", hash(faces))
		mesh.set_meta("trunk_fingerprint", hash(HABITAT.placements(HABITAT.BIOMES[index], "tree")))
		var error := ResourceSaver.save(mesh, "res://assets/environment/jungle_%s_navigation.tres" % HABITAT.IDS[index])
		if error != OK or mesh.get_polygon_count() == 0:
			push_error("Jungle navigation bake failed")
			quit(1)
			return
		print("Baked %s: %d polygons" % [HABITAT.IDS[index], mesh.get_polygon_count()])
	quit()
