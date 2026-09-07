shader_type spatial;

#include "res://assets/environment/reserve_palette.gdshaderinc"
varying vec3 world;
varying vec3 world_normal;

void vertex() {
	world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment() {
	ALBEDO=reserve_surface(world,world_normal);
	ROUGHNESS=0.94;
}
