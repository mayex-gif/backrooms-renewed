shader_type spatial;

uniform vec4 color : source_color = vec4(0.72, 0.59, 0.27, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.98;
uniform float detail_scale : hint_range(1.0, 100.0) = 42.0;
uniform float variation_strength : hint_range(0.0, 0.5) = 0.2;

varying vec3 world_position;

float hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float noise3(vec3 p) {
	vec3 cell = floor(p);
	vec3 blend = fract(p);
	blend = blend * blend * (3.0 - 2.0 * blend);
	float c000 = hash31(cell + vec3(0.0, 0.0, 0.0));
	float c100 = hash31(cell + vec3(1.0, 0.0, 0.0));
	float c010 = hash31(cell + vec3(0.0, 1.0, 0.0));
	float c110 = hash31(cell + vec3(1.0, 1.0, 0.0));
	float c001 = hash31(cell + vec3(0.0, 0.0, 1.0));
	float c101 = hash31(cell + vec3(1.0, 0.0, 1.0));
	float c011 = hash31(cell + vec3(0.0, 1.0, 1.0));
	float c111 = hash31(cell + vec3(1.0, 1.0, 1.0));
	float low = mix(mix(c000, c100, blend.x), mix(c010, c110, blend.x), blend.y);
	float high = mix(mix(c001, c101, blend.x), mix(c011, c111, blend.x), blend.y);
	return mix(low, high, blend.z);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float broad = noise3(world_position * detail_scale * 0.16) - 0.5;
	float grain = noise3(world_position * detail_scale) - 0.5;
	float variation = (broad * 0.45 + grain * 0.55) * variation_strength;
	ALBEDO = color.rgb * (1.0 + variation);
	ROUGHNESS = roughness;
}
