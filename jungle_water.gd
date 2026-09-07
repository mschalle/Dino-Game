extends RefCounted

const HABITAT = preload("res://jungle_habitat.gd")
const TERRAIN = preload("res://valley_terrain.gd")
static var ground: ShaderMaterial
static var surface_mesh: ArrayMesh

static func ground_material() -> ShaderMaterial:
	if ground == null:
		ground = ShaderMaterial.new()
		ground.shader = preload("res://assets/environment/jungle_ground.gdshader")
		ground.set_shader_parameter("biome_palette",preload("res://reserve_ground.gd").palette())
	return ground

static func build(parent: Node3D) -> void:
	if surface_mesh == null:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		# Clip every water triangle to both the irregular footprint and actual bank.
		for z in range(104, 164):
			for x in range(0, 57):
				var p := Vector2(x, z) * 0.5
				for triangle in [[p,p+Vector2(0.5,0),p+Vector2(0.5,0.5)],[p,p+Vector2(0.5,0.5),p+Vector2(0,0.5)]]:
					var polygon: Array[Vector2] = []
					for i in 3:
						var a: Vector2 = triangle[i]
						var b: Vector2 = triangle[(i+1)%3]
						var da := maxf(HABITAT.water_distance(a), (TERRAIN.height_at(a.x,a.y)-HABITAT.WATER_LEVEL)*5.0)
						var db := maxf(HABITAT.water_distance(b), (TERRAIN.height_at(b.x,b.y)-HABITAT.WATER_LEVEL)*5.0)
						if da <= 0.0:
							polygon.append(a)
						if (da < 0.0) != (db < 0.0):
							polygon.append(a.lerp(b,da/(da-db)))
					for i in range(1,polygon.size()-1):
						for point in [polygon[0],polygon[i],polygon[i+1]]:
							surface.set_normal(Vector3.UP)
							surface.add_vertex(Vector3(point.x,HABITAT.WATER_LEVEL,point.y-60.0))
		surface_mesh = surface.commit()
	var water := MeshInstance3D.new()
	water.name = "WaterSurface"
	water.mesh = surface_mesh
	water.visibility_range_end = 160.0
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/environment/jungle_water.gdshader")
	material.set_shader_parameter("motion", 0.0 if preload("res://environment_quality.gd").reduced_motion else 1.0)
	water.material_override = material
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(water)
