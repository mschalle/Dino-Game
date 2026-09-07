extends Node3D

const QUALITY = preload("res://environment_quality.gd")
var environment: Environment
var sky: ProceduralSkyMaterial
var sun: DirectionalLight3D
var weather: GPUParticles3D
var biome := ""
var blend_elapsed := 2.0
var current := {"sky":Color("#7896a2"),"horizon":Color("#b4c6c5"),"fog":Color("#9aaead"),"density":0.0028,"wind":0.8}
var previous: Dictionary = {}
var target: Dictionary = {}
var weather_kind := ""
var daylight_time := 0.0

func configure(env: Environment, sky_material: ProceduralSkyMaterial, light: DirectionalLight3D) -> void:
	environment = env
	sky = sky_material
	sun = light
	weather = GPUParticles3D.new()
	weather.name = "PlayerWeather"
	weather.amount = 36
	weather.lifetime = 3.0
	weather.local_coords = false
	weather.visibility_aabb = AABB(Vector3(-18,-8,-18),Vector3(36,20,36))
	weather.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.10,0.10)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mesh.material = material
	weather.draw_pass_1 = mesh
	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(14,4,14)
	weather.process_material = process_material
	weather.emitting = false
	add_child(weather)

static func palette(region: String) -> Dictionary:
	var result := {"sky":Color("#7896a2"),"horizon":Color("#b4c6c5"),"fog":Color("#9aaead"),"density":0.0028,"weather":""}
	if region in ["River Wetlands","Coastal Marsh","Cypress Basin","Cloudforest Rise"]:
		result.merge({"sky":Color("#718e96"),"horizon":Color("#a7c0bb"),"fog":Color("#90aaa4"),"density":0.0045,"weather":"mist"},true)
	elif region in ["Redstone Badlands","Volcanic Foothills","Saltwind Dunes"]:
		result.merge({"sky":Color("#8e8581"),"horizon":Color("#c3b8a5"),"fog":Color("#b1a18b"),"density":0.0035,"weather":"dust"},true)
	elif region == "Glacier Valley":
		result.merge({"sky":Color("#829aac"),"horizon":Color("#c9d4da"),"fog":Color("#bbcbd5"),"density":0.004,"weather":"snow"},true)
	elif region == "Moonlit Grove":
		result.merge({"sky":Color("#566a83"),"horizon":Color("#9aaeb9"),"fog":Color("#8599ad"),"density":0.004},true)
	result["wind"] = 0.8
	if region in ["Fernwood","Cloudforest Rise","Moonlit Grove","Redwood Canyon"]:
		result.wind = 0.55
	elif region in ["Sunstone Ridge","Highland Plateau","Glacier Valley","Saltwind Dunes"]:
		result.wind = 1.5
	return result

func advance(delta: float, region: String, player_position: Vector3, day_cycle: bool) -> void:
	if environment == null:
		return
	global_position = player_position + Vector3.UP*2.0
	if region != biome or target.is_empty():
		biome = region
		previous = current.duplicate()
		target = palette(region)
		blend_elapsed = 0.0
		weather_kind = target.weather
	blend_elapsed = minf(2.0,blend_elapsed+delta)
	var weight := smoothstep(0.0,2.0,blend_elapsed)
	for key in ["sky","horizon","fog"]:
		current[key] = (previous[key] as Color).lerp(target[key],weight)
	current.density = lerpf(float(previous.density),float(target.density),weight)
	current.wind = lerpf(float(previous.wind),float(target.wind),weight)
	preload("res://jungle_dressing.gd").set_wind_multiplier(float(current.wind))
	sky.sky_top_color = current.sky
	sky.sky_horizon_color = current.horizon
	environment.fog_light_color = current.fog
	environment.fog_density = float(current.density)*float(QUALITY.preset({}).fog)
	if day_cycle:
		daylight_time += delta
	var arc := sin(daylight_time*TAU/240.0)*0.5+0.5
	sun.rotation_degrees.x = -38.0-arc*18.0
	sun.light_energy = 0.78+arc*0.14
	var forward := RenderingServer.get_current_rendering_method() == "forward_plus"
	environment.ssao_enabled = forward and QUALITY.active_id != "low"
	environment.volumetric_fog_enabled = forward and QUALITY.active_id == "high"
	var material := weather.draw_pass_1.material as StandardMaterial3D
	material.albedo_color = Color(0.78,0.87,0.88,0.18) if weather_kind=="mist" else Color(0.88,0.86,0.78,0.45)
	var process_material := weather.process_material as ParticleProcessMaterial
	process_material.gravity = Vector3(0.05*float(current.wind),-0.6,0) if weather_kind=="snow" else Vector3(0.12*float(current.wind),-0.02,0)
	var count := maxi(4,int(36.0*float(QUALITY.preset({}).effects)))
	if weather.amount != count:
		weather.amount = count
	weather.emitting = not weather_kind.is_empty() and QUALITY.weather_enabled and not QUALITY.reduced_motion
