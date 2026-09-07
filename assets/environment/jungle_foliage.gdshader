shader_type spatial;
render_mode cull_disabled;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(0.68, 0.78, 0.60, 1.0);
uniform float wind = 0.045;
uniform float green_leaf = 0.0;
uniform float camera_clearance = 0.0;
varying vec3 world;
void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float nearby = 1.0 - smoothstep(22.0, 55.0, distance(world, CAMERA_POSITION_WORLD));
	VERTEX.x += sin(TIME * 1.7 + world.x * 0.7 + world.z * 0.4) * wind * clamp(VERTEX.y, 0.0, 1.0) * nearby;
}
void fragment() {
	vec4 tex = texture(albedo_texture, UV);
	vec3 leaf = vec3(0.32,0.45,0.18) * (0.55 + dot(tex.rgb,vec3(0.3,0.5,0.2)));
	ALBEDO = mix(tex.rgb * tint.rgb, leaf, green_leaf);
	float clearance = camera_clearance > 0.0 ? smoothstep(camera_clearance * 0.4, camera_clearance, distance(world, CAMERA_POSITION_WORLD)) : 1.0;
	ALPHA = tex.a * clearance;
	ALPHA_SCISSOR_THRESHOLD = 0.45;
	ROUGHNESS = 0.9;
}
