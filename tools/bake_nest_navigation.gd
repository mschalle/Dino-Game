@tool
extends SceneTree

const TERRAIN = preload("res://valley_terrain.gd")

# Offline authoring step: never rebake navigation during chunk activation.
# godot --headless --path . --script res://tools/bake_nest_navigation.gd
func _init() -> void:
	var mesh := NavigationMesh.new()
	mesh.agent_radius = 0.8
	mesh.agent_height = 1.8
	mesh.agent_max_slope = 35.0
	mesh.agent_max_climb = 0.5
	# Match the existing map's 0.25 m voxels. Godot conservatively rounds the
	# requested 0.8 m radius up to 1 m; keep its authoring warning visible.
	mesh.cell_size = 0.25
	mesh.cell_height = 0.1
	mesh.detail_sample_distance = 1.0
	mesh.detail_sample_max_error = 0.1
	var source := NavigationMeshSourceGeometryData3D.new()
	var faces := TERRAIN.collision_faces(Vector2.ZERO)
	source.add_faces(faces, Transform3D.IDENTITY)
	NavigationServer3D.bake_from_source_geometry_data(mesh, source)
	if mesh.get_polygon_count() == 0:
		push_error("Nest navigation bake produced no walkable polygons")
		quit(1)
		return
	mesh.set_meta("terrain_fingerprint", hash(faces))
	var result := ResourceSaver.save(mesh, TERRAIN.NAVIGATION_PATH)
	print("Nest navigation bake: %s (%d polygons)" % [error_string(result), mesh.get_polygon_count()])
	quit(0 if result == OK else 1)
