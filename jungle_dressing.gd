extends RefCounted

const HABITAT = preload("res://jungle_habitat.gd")
const QUALITY = preload("res://environment_quality.gd")
static var mesh_cache: Dictionary = {}
static var wind_multiplier := 1.0
static var applied_wind := -1.0
static var white_texture: ImageTexture

static func surface_lods(source: Mesh, surface: int, distance_scale: float) -> Dictionary:
	var data := RenderingServer.mesh_get_surface(source.get_rid(),surface)
	var result: Dictionary = {}
	var index_count := int(data.get("index_count",0))
	if index_count == 0:
		return result
	var index_data: PackedByteArray = data.index_data
	var stride := int(index_data.size()/index_count)
	for lod in data.get("lods",[]):
		var bytes: PackedByteArray = lod.index_data
		var indices := PackedInt32Array()
		indices.resize(int(bytes.size()/stride))
		for index in indices.size():
			indices[index] = bytes.decode_u16(index*stride) if stride==2 else bytes.decode_u32(index*stride)
		result[float(lod.edge_length)*distance_scale] = indices
	return result

static func _parts(node: Node, parent_transform: Transform3D, result: Array) -> void:
	var transform := parent_transform
	if node is Node3D:
		transform *= node.transform
	if node is MeshInstance3D and node.mesh != null:
		result.append({"mesh": node.mesh, "transform": transform})
	for child in node.get_children():
		_parts(child, transform, result)

static func mesh_bake_path(path: String, kind: String) -> String:
	return "res://assets/environment/foliage/%s_%s.res" % [path.get_file().get_basename(),kind]

static func mesh_fingerprint(path: String, full_hash: bool = true) -> String:
	# Raw sources may be omitted by compiled exports; pre-export validation is required.
	if not FileAccess.file_exists("res://jungle_dressing.gd"):
		return ""
	var sources: Array[String] = ["res://jungle_dressing.gd", "res://assets/environment/jungle_foliage.gdshader",path]
	if FileAccess.file_exists(path+".import"):
		sources.append(path+".import")
	if path.get_extension()=="gltf" and FileAccess.file_exists(path):
		var document = JSON.parse_string(FileAccess.get_file_as_string(path))
		if document is Dictionary:
			for section in ["buffers","images"]:
				for item in document.get(section,[]):
					var uri: String = item.get("uri","")
					if not uri.is_empty() and not uri.begins_with("data:"):
						sources.append(path.get_base_dir().path_join(uri))
	var hashes := ""
	for source in sources:
		if full_hash:
			hashes += source+":"+FileAccess.get_sha256(source)+";"
		else:
			var file := FileAccess.open(source,FileAccess.READ)
			hashes += "%s:%s:%s;" % [source,FileAccess.get_modified_time(source),file.get_length() if file != null else -1]
	return hashes.sha256_text()

static func valid_mesh_bake(mesh: ArrayMesh, path: String, kind: String) -> bool:
	if mesh==null or mesh.get_meta("bake_version",0)!=1 or mesh.get_meta("source","")!=path or mesh.get_meta("kind","")!=kind:
		return false
	var fingerprint := mesh_fingerprint(path,false)
	return fingerprint.is_empty() or mesh.get_meta("source_stamp","")==fingerprint

static func mesh_for(path: String, kind: String, use_baked: bool = true) -> Mesh:
	var key := path + kind
	if use_baked and mesh_cache.has(key):
		return mesh_cache[key]
	if use_baked and ResourceLoader.exists(path) and ResourceLoader.exists(mesh_bake_path(path,kind)):
		var baked := load(mesh_bake_path(path,kind)) as ArrayMesh
		if valid_mesh_bake(baked,path,kind):
			for surface in baked.get_surface_count():
				var material := baked.surface_get_material(surface) as ShaderMaterial
				material.set_shader_parameter("wind",0.0 if QUALITY.reduced_motion else float(material.get_meta("wind_strength",0.0))*wind_multiplier)
			mesh_cache[key] = baked
			return baked
	var parts: Array = []
	if ResourceLoader.exists(path):
		var scene := load(path) as PackedScene
		if scene != null:
			var node := scene.instantiate()
			_parts(node, Transform3D.IDENTITY, parts)
			node.free()
	if parts.is_empty():
		# Leaf-shaped, smooth fallback remains usable without optional asset packs.
		var leaf := SphereMesh.new()
		leaf.radius = 0.3
		leaf.height = 1.0
		leaf.radial_segments = 8
		leaf.rings = 4
		parts.append({"mesh": leaf, "transform": Transform3D(Basis.IDENTITY, Vector3.UP * 0.5)})
	var bounds: AABB = parts[0].transform * parts[0].mesh.get_aabb()
	for part in parts:
		bounds = bounds.merge(part.transform * part.mesh.get_aabb())
	var inverse_height := 1.0 / maxf(bounds.size.y, 0.01)
	var mesh := ArrayMesh.new()
	if white_texture == null:
		var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		white_texture = ImageTexture.create_from_image(image)
	for part in parts:
		for surface in part.mesh.get_surface_count():
			var arrays: Array = part.mesh.surface_get_arrays(surface).duplicate(true)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			for index in vertices.size():
				vertices[index] = (part.transform * vertices[index] - Vector3(0, bounds.position.y, 0)) * inverse_height
				if index < normals.size():
					normals[index] = (part.transform.basis * normals[index]).normalized()
			arrays[Mesh.ARRAY_VERTEX] = vertices
			arrays[Mesh.ARRAY_NORMAL] = normals
			# Preserve imported simplification indices and normalize their error distances.
			var basis: Basis = part.transform.basis
			var distance_scale := maxf(basis.x.length(),maxf(basis.y.length(),basis.z.length()))*inverse_height
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays,[],surface_lods(part.mesh,surface,distance_scale))
			var original := part.mesh.surface_get_material(surface) as StandardMaterial3D
			var material := ShaderMaterial.new()
			material.shader = preload("res://assets/environment/jungle_foliage.gdshader")
			material.set_shader_parameter("albedo_texture", original.albedo_texture if original != null and original.albedo_texture != null else white_texture)
			material.set_shader_parameter("tint", Color(0.76, 0.83, 0.68) if kind not in ["rock", "log"] else Color(0.65, 0.64, 0.57))
			material.set_shader_parameter("green_leaf", 0.8 if kind in ["bush", "grass"] else 0.0)
			material.set_shader_parameter("camera_clearance", 3.0 if kind == "tree" else 0.0)
			material.set_shader_parameter("wind", 0.0 if kind in ["rock", "log"] or QUALITY.reduced_motion else 0.035 * wind_multiplier)
			material.set_meta("wind_strength", 0.0 if kind in ["rock", "log"] else 0.035)
			mesh.surface_set_material(mesh.get_surface_count()-1, material)
	if use_baked:
		mesh_cache[key] = mesh
	return mesh

static func build(parent: Node3D, biome: String, include_trunks: bool = true, kinds: Array = []) -> void:
	var root := parent.get_node_or_null("AssetPackDressing") as Node3D
	if root == null:
		root = Node3D.new()
		root.name = "AssetPackDressing"
		parent.add_child(root)
	for kind in (HABITAT.BUDGETS.keys() if kinds.is_empty() else kinds):
		var layout := HABITAT.placements(biome, kind)
		var limit := layout.size()
		var buckets: Dictionary = {}
		for index in limit:
			var transform := layout[index]
			var cell := Vector2i(floori(transform.origin.x / 12.0), floori(transform.origin.z / 12.0))
			var variant: int = index % HABITAT.PALETTE[kind].size()
			var key := "%s_%s_%d" % [kind, cell, variant]
			if not buckets.has(key):
				buckets[key] = {"cell": cell, "variant": variant, "transforms": []}
			buckets[key].transforms.append(transform)
		for key in buckets:
			var bucket: Dictionary = buckets[key]
			var asset: String = HABITAT.PALETTE[kind][bucket.variant]
			var path := asset if asset.begins_with("res://") else "res://glTF/%s.gltf" % asset
			var batch := MultiMeshInstance3D.new()
			batch.name = key.replace("(", "").replace(")", "").replace(",", "_")
			batch.position = Vector3(bucket.cell.x * 12.0, 0, bucket.cell.y * 12.0)
			batch.multimesh = MultiMesh.new()
			batch.multimesh.transform_format = MultiMesh.TRANSFORM_3D
			batch.multimesh.mesh = mesh_for(path, kind)
			batch.multimesh.instance_count = bucket.transforms.size()
			for index in bucket.transforms.size():
				var transform: Transform3D = bucket.transforms[index]
				transform.origin -= batch.position
				batch.multimesh.set_instance_transform(index, transform)
			batch.visibility_range_end = 170.0 if kind == "tree" else (65.0 if kind in ["grass", "fern", "reed"] else 100.0)
			batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if kind in ["tree", "bush", "rock", "log"] else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			batch.set_meta("habitat_kind", kind)
			root.add_child(batch)
	if include_trunks:
		build_trunks(parent,biome)
	apply_quality(parent)

static func build_trunks(parent: Node3D, biome: String) -> void:
	# Trunk layout is quality-independent, including low quality and asset fallback.
	var trunks := StaticBody3D.new()
	trunks.name = "JungleTrunks"
	trunks.collision_layer = 2
	parent.add_child(trunks)
	for transform in HABITAT.placements(biome, "tree"):
		var shape := CollisionShape3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.32
		capsule.height = 3.0
		shape.shape = capsule
		shape.position = transform.origin + Vector3.UP * 1.5
		trunks.add_child(shape)

static func apply_quality(parent: Node3D) -> void:
	var multiplier := 0.5 if QUALITY.active_id == "low" else (1.35 if QUALITY.active_id == "high" else 1.0)
	var tier_multiplier := 0.55 if parent.get_meta("stream_tier","full")=="adjacent" else 1.0
	for batch in parent.get_node("AssetPackDressing").get_children():
		if not batch is MultiMeshInstance3D:
			continue
		var kind: String = batch.get_meta("habitat_kind", "")
		batch.multimesh.visible_instance_count = batch.multimesh.instance_count if kind == "tree" else floori(batch.multimesh.instance_count * multiplier * tier_multiplier / 1.35)
		batch.visibility_range_end = 170.0 if kind == "tree" else (65.0 if kind in ["grass", "fern", "reed"] else 100.0)
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if kind in ["tree", "bush", "rock", "log"] else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for mesh in mesh_cache.values():
		for surface in mesh.get_surface_count():
			var material: ShaderMaterial = mesh.surface_get_material(surface)
			material.set_shader_parameter("wind", 0.0 if QUALITY.reduced_motion else float(material.get_meta("wind_strength", 0.0)) * wind_multiplier)
	var water := parent.get_node_or_null("WaterSurface") as MeshInstance3D
	if water != null and water.material_override is ShaderMaterial:
		water.material_override.set_shader_parameter("motion", 0.0 if QUALITY.reduced_motion else 1.0)

static func set_wind_multiplier(value: float) -> void:
	wind_multiplier = value
	var effective := 0.0 if QUALITY.reduced_motion else value
	if is_equal_approx(effective,applied_wind):
		return
	applied_wind = effective
	for mesh in mesh_cache.values():
		for surface in mesh.get_surface_count():
			var material: ShaderMaterial = mesh.surface_get_material(surface)
			material.set_shader_parameter("wind",float(material.get_meta("wind_strength",0.0))*effective)
