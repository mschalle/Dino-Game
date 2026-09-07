extends RefCounted

const SHADER = preload("res://assets/environment/reserve_ground.gdshader")
# Soil, surface cover, exposed rock. Original palettes; no external textures.
const PALETTES = {
	"Nest Basin": ["#584d34", "#667443", "#777568"],
	"Fernwood": ["#484331", "#4d633c", "#6b7164"],
	"River Wetlands": ["#484435", "#596447", "#747970"],
	"Sunstone Ridge": ["#726047", "#777746", "#817766"],
	"Redstone Badlands": ["#684b3d", "#a07758", "#775545"],
	"Ancient Meadow": ["#584d34", "#667443", "#777568"],
	"Cloudforest Rise": ["#3f4030", "#485c43", "#65706a"],
	"Coastal Marsh": ["#484435", "#596447", "#747970"],
	"Volcanic Foothills": ["#38312d", "#50443a", "#45464a"],
	"Fossil Flats": ["#75644b", "#938162", "#8a8272"],
	"Redwood Canyon": ["#514332", "#4d5b38", "#72695b"],
	"Highland Plateau": ["#635e4f", "#73765c", "#777b77"],
	"Moonlit Grove": ["#414236", "#465749", "#626b6b"],
	"Saltwind Dunes": ["#9b8058", "#b6a178", "#88785d"],
	"Glacier Valley": ["#707b7d", "#d1dad9", "#788b94"],
	"Cypress Basin": ["#3d3a2d", "#4e6043", "#626d62"]
}

static var palette_texture: ImageTexture

static func palette() -> ImageTexture:
	if palette_texture != null:
		return palette_texture
	var image := Image.create(6,12,false,Image.FORMAT_RGBA8)
	var profiles := WorldChunkProfiles.reserve()
	for z in 4:
		for x in 6:
			var grid := Vector2i(x-2,z)
			var nearest: RefCounted = profiles[0]
			for profile in profiles:
				if grid.distance_squared_to(profile.grid_position)<grid.distance_squared_to(nearest.grid_position):
					nearest = profile
			for layer in 3:
				image.set_pixel(x,z*3+layer,Color(PALETTES[nearest.biome][layer]))
	palette_texture = ImageTexture.create_from_image(image)
	return palette_texture

static func material(_biome: String, _origin: Vector2) -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = SHADER
	result.set_shader_parameter("biome_palette",palette())
	return result
