extends RefCounted

const JUNGLE = preload("res://jungle_habitat.gd")

# World-space samples are independent of chunk activation and generation order.
# The whole reserve now uses one continuous heightfield so chunk borders share
# the same physical surface instead of meeting at box-shaped elevation mounds.
const CHUNK_SIZE := 60.0
const HALF_SIZE := CHUNK_SIZE * 0.5
const VISUAL_CELLS := 64
const COLLISION_CELLS := 32
const SAMPLE_STEP := CHUNK_SIZE / COLLISION_CELLS
const BORDER_BLEND := 6.0
const RESERVE_MIN := Vector2(-150.0, -30.0)
const RESERVE_MAX := Vector2(210.0, 210.0)
const NAVIGATION_PATH := "res://assets/environment/nest_basin_navigation.tres"
const BAKE_VERSION := 1
static var _source_fingerprint := "unchecked"

static func source_fingerprint() -> String:
	if _source_fingerprint == "unchecked":
		var hashes := ""
		for path in ["res://valley_terrain.gd","res://jungle_habitat.gd"]:
			if not FileAccess.file_exists(path):
				_source_fingerprint = ""
				return "" # Exported compiled scripts may omit source; parity is a build gate.
			hashes += FileAccess.get_sha256(path)
		_source_fingerprint = hashes.sha256_text()
	return _source_fingerprint

static func bake_path(origin: Vector2, cells: int) -> String:
	return "res://assets/environment/terrain/terrain_%d_%d_%d.res" % [int(origin.x),int(origin.y),cells]

static func valid_bake(mesh: ArrayMesh, origin: Vector2, cells: int) -> bool:
	return mesh != null and mesh.get_meta("bake_version",0)==BAKE_VERSION and mesh.get_meta("origin",Vector2.INF)==origin and mesh.get_meta("cells",0)==cells and (source_fingerprint().is_empty() or mesh.get_meta("source_fingerprint","")==source_fingerprint())
const CLEARINGS := [
	Vector2(0, 7), Vector2(-15, -12), Vector2(0, -18), Vector2(16, 16),
	Vector2(14, -12), Vector2(-5, -16), Vector2(10, 3), Vector2(-18, 17),
	Vector2(-13, 11), Vector2(13, -3), Vector2(-17, -17), Vector2(14, -4),
	Vector2(19, -4),
	Vector2(60, 0), Vector2(60, 60), Vector2(0, 60), Vector2(0, 120),
	Vector2(-60, 60), Vector2(-60, 120), Vector2(-120, 60), Vector2(-120, 120),
	Vector2(120, 60), Vector2(120, 120), Vector2(180, 120), Vector2(180, 180),
	Vector2(60, 120), Vector2(120, 180), Vector2(-120, 180)
]
const BIOME_CLEARINGS := [
	Vector2(0, 7), Vector2(60, 0), Vector2(60, 60), Vector2(0, 60),
	Vector2(0, 120), Vector2(-60, 60), Vector2(60, 120), Vector2(120, 60),
	Vector2(120, 120), Vector2(-60, 120), Vector2(-120, 60), Vector2(120, 180),
	Vector2(-120, 120), Vector2(180, 120), Vector2(180, 180), Vector2(-120, 180)
]
static var _sample_cache: Dictionary = {}

static func is_heightfield_biome(biome: String) -> bool:
	return not biome.is_empty()

static func _landform(point: Vector2) -> float:
	var height := 1.1 * sin(point.x / 42.0) + 0.8 * cos(point.y / 48.0)
	height += 1.1 * sin((point.x + point.y) / 64.0)
	height += 2.0 * exp(-point.distance_squared_to(Vector2(-13, 11)) / 120.0)
	height += 3.6 * exp(-point.distance_squared_to(Vector2(14, -12)) / 110.0)
	height += 5.0 * exp(-point.distance_squared_to(Vector2(0, -18)) / 130.0)
	height += 3.0 * exp(-point.distance_squared_to(Vector2(17, 17)) / 130.0)
	height -= 2.2 * exp(-point.distance_squared_to(Vector2(19, -4)) / 55.0)
	height += 4.6 * exp(-point.distance_squared_to(Vector2(60, 60)) / 900.0)
	height += 5.5 * exp(-point.distance_squared_to(Vector2(120, 70)) / 900.0)
	height += 7.0 * exp(-point.distance_squared_to(Vector2(135, 150)) / 1300.0)
	height += 5.8 * exp(-point.distance_squared_to(Vector2(180, 185)) / 900.0)
	height += 3.7 * exp(-point.distance_squared_to(Vector2(-100, 70)) / 850.0)
	height += 4.2 * exp(-point.distance_squared_to(Vector2(-105, 145)) / 1100.0)
	height -= 2.4 * exp(-point.distance_squared_to(Vector2(8, 66)) / 620.0)
	height -= 1.6 * exp(-point.distance_squared_to(Vector2(66, 125)) / 720.0)
	return height

static func _cleared_landform(point: Vector2) -> float:
	var height := _landform(point)
	for clearing in CLEARINGS:
		var distance := point.distance_to(clearing)
		var safe_nest: bool = clearing == Vector2(0, 7)
		var outer_radius := 8.0 if safe_nest else 5.0
		if distance < outer_radius:
			var level := 0.0 if safe_nest else _landform(clearing)
			height = lerpf(level, height, smoothstep(3.5 if safe_nest else 1.5, outer_radius, distance))
	return height

static func _reserve_edge_distance(point: Vector2) -> float:
	return minf(minf(point.x - RESERVE_MIN.x, RESERVE_MAX.x - point.x),
		minf(point.y - RESERVE_MIN.y, RESERVE_MAX.y - point.y))

static func sample_height(x: float, z: float) -> float:
	var point := Vector2(x, z)
	var edge_distance := _reserve_edge_distance(point)
	if edge_distance <= 0.0:
		return 0.0
	if _sample_cache.has(point):
		return _sample_cache[point]
	# Smooth the joins between nearby clearings before sampling the fixed lattice.
	# Memoization keeps this authoring filter out of per-actor movement cost.
	var height := 0.0
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var weight := (2.0 if dx == 0 else 1.0) * (2.0 if dz == 0 else 1.0)
			height += _cleared_landform(point + Vector2(dx, dz) * 3.5) * weight / 16.0
	# A bounded approach grade prevents the transition itself forming a steep wall.
	height = minf(height, edge_distance * 0.34)
	height *= smoothstep(0.0, BORDER_BLEND * 2.0, edge_distance)
	height = maxf(0.0, height)
	# Compact support keeps every neighboring chunk and quest platform unchanged.
	var bank := JUNGLE.water_distance(point)
	if bank < 4.0:
		height = lerpf(0.0, maxf(height, 0.55), smoothstep(-0.8, 4.0, bank))
	_sample_cache[point] = height
	return height

static func height_at(x: float, z: float) -> float:
	# Barycentric interpolation uses exactly the collision mesh's diagonal.
	# The denser visual mesh subdivides these faces, so feet never float on slopes.
	var x0 := floorf(x / SAMPLE_STEP) * SAMPLE_STEP
	var z0 := floorf(z / SAMPLE_STEP) * SAMPLE_STEP
	var u := (x - x0) / SAMPLE_STEP
	var v := (z - z0) / SAMPLE_STEP
	var a := sample_height(x0, z0)
	var c := sample_height(x0 + SAMPLE_STEP, z0 + SAMPLE_STEP)
	if u >= v:
		return a * (1.0 - u) + sample_height(x0 + SAMPLE_STEP, z0) * (u - v) + c * v
	return a * (1.0 - v) + sample_height(x0, z0 + SAMPLE_STEP) * (v - u) + c * u

static func normal_at(x: float, z: float) -> Vector3:
	if _reserve_edge_distance(Vector2(x, z)) <= 0.0:
		return Vector3.UP
	var spacing := SAMPLE_STEP
	# Normals follow the actual interpolated surface, not extra off-lattice
	# authoring samples (which also repeated the expensive smoothing filter).
	return Vector3(height_at(x - spacing, z) - height_at(x + spacing, z),
		2.0 * spacing, height_at(x, z - spacing) - height_at(x, z + spacing)).normalized()

static func build_mesh(origin: Vector2, cells: int = VISUAL_CELLS, use_baked: bool = true) -> ArrayMesh:
	if use_baked:
		var path := bake_path(origin,cells)
		if ResourceLoader.exists(path):
			var baked := load(path) as ArrayMesh
			if valid_bake(baked,origin,cells):
				_sample_cache.merge(baked.get_meta("height_samples",{}),false)
				return baked
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var spacing := CHUNK_SIZE / float(cells)
	for row in cells + 1:
		for column in cells + 1:
			var x := -HALF_SIZE + column * spacing
			var z := -HALF_SIZE + row * spacing
			var wx := x + origin.x
			var wz := z + origin.y
			var height := height_at(wx, wz)
			var normal := normal_at(wx, wz)
			vertices.append(Vector3(x, height, z))
			normals.append(normal)
			uvs.append(Vector2(wx, wz) / 12.0)
			var tint := Color("#66774a").lerp(Color("#8b836d"), clampf(height / 6.0, 0.0, 1.0))
			tint = tint.lerp(Color("#68675c"), clampf((1.0 - normal.y) * 3.0, 0.0, 0.6))
			colors.append(tint)
	for row in cells:
		for column in cells:
			var a := row * (cells + 1) + column
			var b := a + 1
			var c := a + cells + 2
			var d := a + cells + 1
			# Godot front faces are clockwise when viewed from above.
			indices.append_array([a, b, c, a, c, d])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

static func collision_faces(origin: Vector2) -> PackedVector3Array:
	return build_mesh(origin, COLLISION_CELLS).get_faces()

static func material() -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.vertex_color_use_as_albedo = true
	result.roughness = 0.95
	return result
