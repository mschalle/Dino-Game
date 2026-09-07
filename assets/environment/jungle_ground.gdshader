shader_type spatial;
#include "res://assets/environment/reserve_palette.gdshaderinc"
varying vec3 world;
varying vec3 world_normal;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1.0,0.0)),f.x),mix(hash(i+vec2(0.0,1.0)),hash(i+vec2(1.0)),f.x),f.y)*2.0-1.0;
}
void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
	float macro = noise(world.xz * 0.28) * 0.5 + 0.5;
	float detail = noise(world.xz * 18.0) * 0.025;
	float bank = (length((world.xz - vec2(12.0,72.0)) / vec2(10.0,7.0)) - 1.0) * 7.0;
	float wet = (1.0 - smoothstep(0.0, 4.0, bank)) * (1.0 - smoothstep(0.4,1.0,world.y));
	vec3 soil = vec3(0.25,0.205,0.13);
	vec3 grass = mix(vec3(0.24,0.30,0.13), vec3(0.34,0.38,0.20), macro);
	vec3 ground = mix(soil, grass, smoothstep(0.15,0.7,macro));
	ground = mix(ground, vec3(0.31,0.32,0.29), smoothstep(0.12,0.32,1.0-world_normal.y));
	float edge = min(min(world.x+30.0,90.0-world.x), min(world.z+30.0,90.0-world.z));
	ALBEDO = mix(reserve_surface(world,world_normal), mix(ground, vec3(0.18,0.155,0.11),wet) + detail, smoothstep(0.0,6.0,edge));
	ROUGHNESS = mix(0.95,0.48,wet);
}
