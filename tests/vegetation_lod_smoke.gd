extends SceneTree

func _init() -> void:
	var failures := 0
	var scene := load("res://glTF/CommonTree_1.gltf") as PackedScene
	var node := scene.instantiate()
	var parts: Array = []
	preload("res://jungle_dressing.gd")._parts(node,Transform3D.IDENTITY,parts)
	var normalized := preload("res://jungle_dressing.gd").mesh_for("res://glTF/CommonTree_1.gltf","tree")
	var output_surface := 0
	var lod_count := 0
	for part in parts:
		for surface in part.mesh.get_surface_count():
			var source := preload("res://jungle_dressing.gd").surface_lods(part.mesh,surface,1.0)
			var output := preload("res://jungle_dressing.gd").surface_lods(normalized,output_surface,1.0)
			if source.size() != output.size():
				failures += 1
			for index in mini(source.size(),output.size()):
				if source.values()[index] != output.values()[index] or float(output.keys()[index]) <= 0.0:
					failures += 1
			lod_count += output.size()
			if part.mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX] != normalized.surface_get_arrays(output_surface)[Mesh.ARRAY_INDEX]:
				failures += 1
			output_surface += 1
	if lod_count == 0 or not is_equal_approx(normalized.get_aabb().size.y,1.0):
		failures += 1
	var fallback := preload("res://jungle_dressing.gd").mesh_for("res://missing_vegetation_lod_test.glb","fern")
	if fallback.get_surface_count() == 0:
		failures += 1
	# Exercise both server index encodings independently of the imported fixture.
	for vertex_count in [3,65537]:
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		var vertices := PackedVector3Array()
		vertices.resize(vertex_count)
		vertices[1] = Vector3.RIGHT
		vertices[vertex_count-1] = Vector3.UP
		arrays[Mesh.ARRAY_VERTEX] = vertices
		var indices := PackedInt32Array([0,1,vertex_count-1])
		arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0,1,vertex_count-1,vertex_count-1,1,0])
		var fixture := ArrayMesh.new()
		fixture.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{4.0:indices})
		var scaled := preload("res://jungle_dressing.gd").surface_lods(fixture,0,0.5)
		if not scaled.has(2.0) or scaled[2.0] != indices:
			failures += 1
	node.free()
	print("Vegetation LOD smoke: %s (%d preserved levels)" % ["PASS" if failures==0 else "FAIL",lod_count])
	quit(0 if failures==0 else 1)
