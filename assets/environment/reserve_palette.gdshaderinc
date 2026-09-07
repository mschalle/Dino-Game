// Six world-grid columns (-2..3), four rows (0..3), three material layers per row.
uniform sampler2D biome_palette : source_color, filter_nearest, repeat_disable;
vec3 palette_cell(vec2 cell, float layer) {
	vec2 pixel=vec2(clamp(cell.x+2.0,0.0,5.0),clamp(cell.y,0.0,3.0)*3.0+layer);
	return texture(biome_palette,(pixel+0.5)/vec2(6.0,12.0)).rgb;
}
vec3 palette_layer(vec2 point, float layer) {
	vec2 grid=point/60.0;
	vec2 cell=floor(grid);
	// Twelve metre transition centered on each shared boundary, including corners.
	vec2 weight=smoothstep(vec2(0.4),vec2(0.6),fract(grid));
	return mix(mix(palette_cell(cell,layer),palette_cell(cell+vec2(1.0,0.0),layer),weight.x),
		mix(palette_cell(cell+vec2(0.0,1.0),layer),palette_cell(cell+vec2(1.0),layer),weight.x),weight.y);
}
float reserve_hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float reserve_noise(vec2 p) {
	vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(reserve_hash(i),reserve_hash(i+vec2(1.0,0.0)),f.x),mix(reserve_hash(i+vec2(0.0,1.0)),reserve_hash(i+vec2(1.0)),f.x),f.y);
}
vec3 reserve_surface(vec3 point, vec3 normal) {
	float macro=reserve_noise(point.xz*0.12);
	vec3 ground=mix(palette_layer(point.xz,0.0),palette_layer(point.xz,1.0),smoothstep(0.2,0.8,macro));
	ground=mix(ground,palette_layer(point.xz,2.0),smoothstep(0.10,0.32,1.0-normal.y));
	return ground*(0.92+0.16*reserve_noise(point.xz*0.035))+(reserve_noise(point.xz*12.0)-0.5)*0.018;
}
