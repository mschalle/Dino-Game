shader_type spatial;
render_mode cull_disabled;
uniform float motion = 1.0;
uniform float opacity : hint_range(0.0,1.0) = 0.72;
uniform float roughness : hint_range(0.0,1.0) = 0.32;
varying vec3 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
	float ripple = sin(world.x*3.0+TIME*motion)*cos(world.z*2.5-TIME*motion*0.8);
	ALBEDO = mix(vec3(0.13,0.25,0.20),vec3(0.25,0.39,0.32),ripple*0.15+0.5);
	NORMAL_MAP = normalize(vec3(sin(world.x*4.0+TIME*motion)*0.08,cos(world.z*3.0-TIME*motion)*0.08,1.0))*0.5+0.5;
	ROUGHNESS = roughness;
	SPECULAR = 0.25;
	ALPHA = opacity;
}
