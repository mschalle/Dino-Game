extends RefCounted

const TERRAIN = preload("res://valley_terrain.gd")
const LEVEL := 0.08
static var meshes: Dictionary = {}
static var bank_layouts: Dictionary = {}
static var bake_fingerprint := ""

static func fingerprint() -> String:
	if bake_fingerprint.is_empty():
		bake_fingerprint = (FileAccess.get_sha256("res://reserve_water.gd")+TERRAIN.source_fingerprint()).sha256_text()
	return bake_fingerprint

static func bake_path(origin: Vector2) -> String:
	return "res://assets/environment/water/surface_%d_%d.res" % [int(origin.x),int(origin.y)]

static func valid_bake(candidate: ArrayMesh, origin: Vector2) -> bool:
	return candidate!=null and candidate.get_meta("water_version",0)==1 and candidate.get_meta("origin",Vector2.INF)==origin and candidate.get_meta("source_fingerprint","")==fingerprint()

static func bank_reeds(origin: Vector2) -> Array[Transform3D]:
	if bank_layouts.has(origin):
		return bank_layouts[origin]
	var result: Array[Transform3D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(origin)
	var center := origin+Vector2(-4,6)
	var level := level_at(origin)
	for attempt in 1200:
		if result.size()>=96:
			break
		var point := center+Vector2(rng.randf_range(-12,12),rng.randf_range(-9,9))
		var local := point-origin
		# Preserve six-metre cardinal routes and the central landmark/combat clearing.
		if absf(local.x)<3.0 or absf(local.y)<3.0 or local.length()<5.0:
			continue
		var distance := shore_distance(point,center)
		var height := TERRAIN.height_at(point.x,point.y)
		if distance<0.1 or distance>1.8 or height<level-0.1 or height>level+0.45:
			continue
		var basis := Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*rng.randf_range(0.75,1.2))
		result.append(Transform3D(basis,Vector3(local.x,height,local.y)))
	bank_layouts[origin] = result
	return result

static func build_bank_reeds(parent: Node3D) -> void:
	var layout := bank_reeds(Vector2(parent.position.x,parent.position.z))
	var reeds := MultiMeshInstance3D.new()
	reeds.name = "BankReeds"
	reeds.multimesh = MultiMesh.new()
	reeds.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	reeds.multimesh.mesh = preload("res://jungle_dressing.gd").mesh_for("res://assets/environment/jungle_reeds.glb","reed")
	reeds.multimesh.instance_count = layout.size()
	for index in layout.size():
		reeds.multimesh.set_instance_transform(index,layout[index])
	reeds.visibility_range_end = 55.0
	reeds.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(reeds)
	apply_bank_quality(parent)

static func apply_bank_quality(parent: Node3D) -> void:
	var reeds := parent.get_node_or_null("BankReeds") as MultiMeshInstance3D
	if reeds == null:
		return
	var quality := preload("res://environment_quality.gd").active_id
	var fraction := 0.5 if quality=="low" else (1.0 if quality=="high" else 0.74)
	if parent.get_meta("stream_tier","full")!="full":
		fraction *= 0.55
	reeds.multimesh.visible_instance_count = floori(reeds.multimesh.instance_count*fraction)

static func level_at(origin: Vector2) -> float:
	return TERRAIN.height_at(origin.x-4.0,origin.y+6.0)+LEVEL

static func shore_distance(point: Vector2, center: Vector2) -> float:
	var relative := (point-center)/Vector2(10,7)
	var angle := relative.angle()
	return (relative.length()-1.0-0.08*sin(angle*3.0)-0.04*cos(angle*5.0))*7.0

static func mesh(origin: Vector2, use_baked: bool = true) -> ArrayMesh:
	if use_baked and meshes.has(origin):
		return meshes[origin]
	if use_baked and ResourceLoader.exists(bake_path(origin)):
		var baked := load(bake_path(origin)) as ArrayMesh
		if valid_bake(baked,origin):
			meshes[origin] = baked
			return baked
	var center := origin+Vector2(-4,6)
	var level := level_at(origin)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(-17,18):
		for x in range(-23,24):
			var p := center+Vector2(x,z)*0.5
			for triangle in [[p,p+Vector2(0.5,0),p+Vector2(0.5,0.5)],[p,p+Vector2(0.5,0.5),p+Vector2(0,0.5)]]:
				var polygon: Array[Vector2] = []
				for i in 3:
					var a: Vector2 = triangle[i]
					var b: Vector2 = triangle[(i+1)%3]
					var da := maxf(shore_distance(a,center),(TERRAIN.height_at(a.x,a.y)-level)*5.0)
					var db := maxf(shore_distance(b,center),(TERRAIN.height_at(b.x,b.y)-level)*5.0)
					if da<=0.0:
						polygon.append(a)
					if (da<0.0)!=(db<0.0):
						polygon.append(a.lerp(b,da/(da-db)))
				for i in range(1,polygon.size()-1):
					for point in [polygon[0],polygon[i],polygon[i+1]]:
						surface.set_normal(Vector3.UP)
						surface.add_vertex(Vector3(point.x-origin.x,level,point.y-origin.y))
	var result := surface.commit()
	if use_baked:
		meshes[origin] = result
	return result
