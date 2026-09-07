extends RefCounted

# World-space layout shared by art, collision, navigation and spawn exclusions.
const BIOMES = ["Nest Basin", "Fernwood", "River Wetlands", "Sunstone Ridge"]
const ORIGINS = [Vector2.ZERO, Vector2(60, 0), Vector2(0, 60), Vector2(60, 60)]
const IDS = ["nest_basin", "fernwood", "river_wetlands", "sunstone_ridge"]
const BUDGETS = {"tree": 40, "bush": 120, "fern": 240, "grass": 1200, "reed": 80, "rock": 26, "log": 8}
const PALETTE = {
	"tree": ["CommonTree_1", "CommonTree_2", "CommonTree_3"],
	"bush": ["Bush_Common"], "fern": ["Fern_1"],
	"grass": ["Grass_Wispy_Short"], "rock": ["Rock_Medium_1"],
	"log": ["DeadTree_2"], "reed": ["res://assets/environment/jungle_reeds.glb"]
}
const POND = Vector2(12, 72)
const WATER_LEVEL = 0.32
const CREEK = [Vector2(22, 55), Vector2(23, 60), Vector2(19, 65), Vector2(16, 69)]
const PREY_CLEARINGS = [Vector2(-8, 8), Vector2(49, 9), Vector2(10, 59), Vector2(50, 69)]
const PREDATOR_EDGES = [Vector2(19, 13), Vector2(75, -12), Vector2(-16, 72), Vector2(76, 72)]
const ROUTES = [Vector2(0, 7), Vector2(0, 0), Vector2(60, 0), Vector2(60, 60), Vector2(0, 60), Vector2(0, 0)]
static var layout_cache: Dictionary = {}

static func origin_for(p: Vector3) -> Vector2:
	var origin := Vector2(roundf(p.x / 60.0), roundf(p.z / 60.0)) * 60.0
	return origin if origin in ORIGINS else Vector2.ZERO

static func contains(biome: String) -> bool:
	return biome in BIOMES

static func segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	if a.is_equal_approx(b):
		return p.distance_to(a)
	return p.distance_to(a.lerp(b, clampf((p-a).dot(b-a)/(b-a).length_squared(), 0.0, 1.0)))

static func water_distance(p: Vector2) -> float:
	var q := p - POND
	var angle := atan2(q.y / 7.0, q.x / 10.0)
	var irregular := 1.0 + 0.055 * sin(angle * 3.0) + 0.035 * cos(angle * 5.0)
	var distance := (Vector2(q.x / 10.0, q.y / 7.0).length() - irregular) * 7.0
	for i in CREEK.size() - 1:
		distance = minf(distance, segment_distance(p, CREEK[i], CREEK[i+1]) - 0.85)
	return distance

static func route_distance(p: Vector2) -> float:
	var distance := INF
	for i in ROUTES.size() - 1:
		distance = minf(distance, segment_distance(p, ROUTES[i], ROUTES[i+1]))
	# Nest quests remain connected by broad radial approaches.
	for point in load("res://valley_terrain.gd").CLEARINGS:
		if absf(point.x) < 30.0 and absf(point.y) < 30.0:
			distance = minf(distance, segment_distance(p, Vector2(0, 7), point))
	return distance

static func excluded(p: Vector2, large: bool) -> bool:
	if route_distance(p) < (4.5 if large else 3.0):
		return true
	for point in load("res://valley_terrain.gd").CLEARINGS:
		if p.distance_to(point) < (6.0 if large else 2.5):
			return true
	for point in PREY_CLEARINGS + PREDATOR_EDGES:
		if p.distance_to(point) < (5.0 if large else 2.0):
			return true
	return p.distance_to(Vector2(0, 7)) < (10.0 if large else 3.0)

static func layout_path(biome: String, kind: String) -> String:
	return "res://assets/environment/habitats/%s_%s.res" % [IDS[BIOMES.find(biome)],kind]

static func valid_layout(resource: Resource, biome: String, kind: String) -> bool:
	var fingerprint: String = load("res://valley_terrain.gd").source_fingerprint()
	return resource != null and resource.get_meta("layout_version",0)==1 and resource.get_meta("biome","")==biome and resource.get_meta("kind","")==kind and (fingerprint.is_empty() or resource.get_meta("source_fingerprint","")==fingerprint) and resource.get_meta("transforms",null) is Array

static func placements(biome: String, kind: String, use_baked: bool = true) -> Array[Transform3D]:
	var cache_key := biome + kind
	if use_baked and layout_cache.has(cache_key):
		return layout_cache[cache_key]
	var result: Array[Transform3D] = []
	if use_baked and ResourceLoader.exists(layout_path(biome,kind)):
		var baked := load(layout_path(biome,kind))
		if valid_layout(baked,biome,kind):
			result.assign(baked.get_meta("transforms"))
			layout_cache[cache_key] = result
			return result
	var origin: Vector2 = ORIGINS[BIOMES.find(biome)]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(biome + ":" + kind)
	var budget := int(BUDGETS[kind])
	# All presets select prefixes of this deterministic maximum-density layout.
	if kind != "tree":
		budget = int(budget * 1.35)
	var large := kind in ["tree", "bush", "log", "rock"]
	for attempt in budget * 16:
		if result.size() >= budget:
			break
		var p := origin + Vector2(rng.randf_range(-28, 28), rng.randf_range(-28, 28))
		if excluded(p, large):
			continue
		var wet := water_distance(p)
		if (kind == "reed" and (wet < 0.1 or wet > 1.8)) or (kind != "reed" and wet < 0.5):
			continue
		var canopy := (sin(p.x * 0.19) * cos(p.y * 0.17) + 1.0) * 0.5
		if kind in ["fern", "bush"] and canopy < 0.25:
			continue
		if kind == "tree":
			var crowded := false
			for previous in result:
				if Vector2(previous.origin.x, previous.origin.z).distance_to(p - origin) < 4.5:
					crowded = true
			if crowded:
				continue
		var heights := {"tree": 10.0 if biome == "Fernwood" else 8.0, "bush": 1.25, "fern": 0.75, "grass": 0.42, "reed": 1.1, "rock": 1.3, "log": 3.2}
		var size := float(heights[kind]) * rng.randf_range(0.75, 1.25)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size)
		if kind == "log":
			basis = basis.rotated(Vector3.RIGHT, PI * 0.47)
		var y: float = load("res://valley_terrain.gd").height_at(p.x, p.y)
		result.append(Transform3D(basis, Vector3(p.x-origin.x, y, p.y-origin.y)))
	if use_baked:
		layout_cache[cache_key] = result
	return result
