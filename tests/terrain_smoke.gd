extends SceneTree

const TERRAIN = preload("res://valley_terrain.gd")
var failures := 0

class TerrainWorld extends Node3D:
	func _terrain_height_at(x: float, z: float) -> float:
		return TERRAIN.height_at(x, z)

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func _run() -> void:
	TERRAIN._sample_cache.clear()
	var sample_normal: Vector3 = TERRAIN.normal_at(0.9375,8.4375)
	check(is_equal_approx(sample_normal.length(),1.0) and sample_normal.y>0.0,"Terrain normals must be normalized and upward")
	for point in TERRAIN._sample_cache:
		check(is_equal_approx(point.x/TERRAIN.SAMPLE_STEP,roundf(point.x/TERRAIN.SAMPLE_STEP)) and is_equal_approx(point.y/TERRAIN.SAMPLE_STEP,roundf(point.y/TERRAIN.SAMPLE_STEP)),"Normals must reuse collision lattice samples rather than evaluate off-lattice landforms")
	var mesh := TERRAIN.build_mesh(Vector2.ZERO)
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	check(vertices.size() == 65 * 65, "Pilot visual grid must have 65x65 shared vertices")
	var faces := TERRAIN.collision_faces(Vector2.ZERO)
	check(faces.size() == 32 * 32 * 6, "Collision must use a 33x33 sample grid")
	var max_grade := 0.0
	var steepest_point := Vector3.ZERO
	for index in range(0, faces.size(), 3):
		var normal := (faces[index + 2] - faces[index]).cross(faces[index + 1] - faces[index]).normalized()
		check(normal.y > 0.0, "Terrain faces must point up, not be backface culled from above")
		var grade := rad_to_deg(acos(clampf(normal.y, -1.0, 1.0)))
		if grade > max_grade:
			max_grade = grade
			steepest_point = (faces[index] + faces[index + 1] + faces[index + 2]) / 3.0
	check(max_grade < 30.0, "Pilot slopes including border approaches must remain below 30 degrees")
	print("Terrain maximum grade: %.2f degrees at %s" % [max_grade, steepest_point])
	for vertex in vertices:
		check(absf(vertex.y - TERRAIN.height_at(vertex.x, vertex.z)) < 0.0001, "Visual vertices must match collision interpolation")
	for offset in [Vector2(60, 0), Vector2(-60, 0), Vector2(0, 60), Vector2(0, -60)]:
		var adjacent := TERRAIN.build_mesh(offset)
		var adjacent_vertices: PackedVector3Array = adjacent.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for vertex in adjacent_vertices:
			var world_point: Vector2 = Vector2(vertex.x, vertex.z) + offset
			if absf(world_point.x) <= 30.0 and absf(world_point.y) <= 30.0:
				check(absf(vertex.y - TERRAIN.height_at(world_point.x, world_point.y)) < 0.0001, "Neighbor sampling must match all shared edges")
	var world := TerrainWorld.new()
	world.add_to_group("world_controller")
	root.add_child(world)
	var manager = load("res://world_stream_manager.gd").new()
	manager.configure(WorldChunkProfiles.reserve(), 1)
	manager.update_player_chunk(Vector2i.ZERO)
	var nest: Node3D = manager.instantiate_chunk("nest_basin", world)
	for chunk in WorldChunkProfiles.reserve():
		var instance: Node3D = manager.instantiate_chunk(chunk.chunk_id, world)
		check(instance.get_node_or_null("Elevation") == null, "%s must not contain a box elevation mound" % chunk.chunk_id)
		check(instance.get_node_or_null("ElevationCollision") == null, "%s must not contain box elevation collision" % chunk.chunk_id)
	var navigation: NavigationMesh = nest.get_node("NavigationRegion").navigation_mesh
	check(navigation.get_meta("terrain_fingerprint", 0) == hash(faces), "Navigation must match current collision; rebuild after terrain edits")
	for frame in 10:
		await physics_frame
	var space := root.world_3d.direct_space_state
	var max_collision_error := 0.0
	for x in range(-29, 30, 2):
		for z in range(-29, 30, 2):
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, 20, z), Vector3(x, -10, z), 1))
			check(not hit.is_empty(), "Every terrain sample must have physical support")
			if not hit.is_empty():
				max_collision_error = maxf(max_collision_error, absf(hit.position.y - TERRAIN.height_at(x, z)))
	check(max_collision_error < 0.001, "Physics ray hits must match terrain height queries within 1mm")
	print("Terrain physics height error: %.6f m" % max_collision_error)
	var nav_map := root.world_3d.navigation_map
	for chunk in manager.scene_instances.values():
		var region: NavigationRegion3D = chunk.get_node("NavigationRegion")
		var sync_deadline := Time.get_ticks_msec() + 5000
		while NavigationServer3D.region_get_iteration_id(region.get_rid()) == 0 and Time.get_ticks_msec() < sync_deadline:
			await process_frame
		check(NavigationServer3D.region_get_iteration_id(region.get_rid()) > 0, "Navigation region must finish its asynchronous build")
	# Explicitly flush the asynchronously queued region build in this fast test.
	NavigationServer3D.map_force_update(nav_map)
	check(NavigationServer3D.map_get_iteration_id(nav_map) > 0, "Baked navigation must synchronize before path requests")
	var safe := Vector3(0, TERRAIN.height_at(0, 7) + 0.05, 7)
	var route_count := 0
	for point in TERRAIN.CLEARINGS:
		var destination := Vector3(point.x, TERRAIN.height_at(point.x, point.y) + 0.05, point.y)
		var support := space.intersect_ray(PhysicsRayQueryParameters3D.create(destination + Vector3.UP * 20.0, destination + Vector3.DOWN * 4.0, 1))
		check(not support.is_empty() and absf(support.position.y - TERRAIN.height_at(point.x, point.y)) < 0.001, "Every quest clearing must sit on generated terrain collision: %s" % point)
		route_count += 1
	print("Terrain clearings: %d physical locations checked" % route_count)
	for border in [Vector2(30, 0), Vector2(0, 30), Vector2(90, 60), Vector2(-90, 120), Vector2(150, 120)]:
		for step in range(-4, 5):
			var point: Vector2 = border + border.normalized() * float(step) * 0.125
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(point.x, 20, point.y), Vector3(point.x, -2, point.y), 1))
			check(not hit.is_empty() and absf(hit.position.y - TERRAIN.height_at(point.x, point.y)) < 0.001, "Loaded heightfield chunks must meet without a collision step or gap")
	# No main.gd grounding/teleport helper is present in this fixture. Movement
	# succeeds only if the actual player capsule walks on the terrain collider.
	for action in ["move_left", "move_right", "move_forward", "move_back", "sprint"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	for profile in [DinosaurProfiles.t_rex(), DinosaurProfiles.velociraptor(), DinosaurProfiles.triceratops()]:
		var actor := PlayerDino.new()
		actor.configure(profile)
		actor.position = safe + Vector3.UP * 0.1
		world.add_child(actor)
		for frame in 20:
			await physics_frame
		check(actor.is_on_floor(), "%s must settle on terrain collision" % profile.id)
		var movement_targets := [Vector2(0, -18), Vector2(14, -12), Vector2(32, 0), Vector2(0, 32), Vector2(0, 7)]
		if profile.id == "t_rex":
			movement_targets.append_array([Vector2(60, 0), Vector2(60, 60), Vector2(120, 60), Vector2(120, 120), Vector2(180, 120), Vector2(180, 180)])
		for target in movement_targets:
			if target == Vector2(32, 0):
				actor.grow_to(1.75)
				for frame in 45:
					await physics_frame
				check(actor.scale.is_equal_approx(Vector3.ONE * 1.75), "Adult collider must reach its gameplay scale")
			var destination := Vector3(target.x, TERRAIN.height_at(target.x, target.y) + 0.05, target.y)
			var same_chunk_target := absf(target.x) < 30.0 and absf(target.y) < 30.0
			var path := PackedVector3Array()
			if same_chunk_target:
				path = PackedVector3Array([destination])
			else:
				path = NavigationServer3D.map_get_path(nav_map, actor.position, destination, true)
				check(path.size() >= 2 and path[path.size() - 1].distance_to(destination) < 0.4, "A usable path must cross each loaded biome border")
			for waypoint in path:
				for frame in 600:
					var direction := Vector2(waypoint.x - actor.position.x, waypoint.z - actor.position.z)
					if direction.length() < 0.45:
						break
					_set_direction(direction.normalized())
					await physics_frame
				_set_direction(Vector2.ZERO)
			check(Vector2(actor.position.x, actor.position.z).distance_to(target) < 0.8, "%s must walk to %s without teleporting" % [profile.id, target])
			check(absf(actor.position.y - TERRAIN.height_at(actor.position.x, actor.position.z)) < 0.4, "Feet must stay near terrain through the slope route")
		print("Terrain physics routes: %s hatchling/adult and two borders checked" % profile.id)
		actor.free()
	world.free()
	await process_frame
	print("Terrain smoke: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func _set_direction(direction: Vector2) -> void:
	for action in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action)
	if direction.x != 0.0:
		Input.action_press("move_right" if direction.x > 0.0 else "move_left", absf(direction.x))
	if direction.y != 0.0:
		Input.action_press("move_back" if direction.y > 0.0 else "move_forward", absf(direction.y))
