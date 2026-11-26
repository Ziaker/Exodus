shader_type spatial;
render_mode cull_disabled;

varying vec3 position_world;
uniform float azul_chumbo : hint_range(0.0, 1.0) = 0.0;
uniform vec3 offset_world = vec3(0.0);

float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(41.071, 73.993, 37.727))) * 13457.97);
}

float grain(vec3 p) {
	vec3 c = floor(p);
	vec3 f = smoothstep(vec3(0.0), vec3(1.0), fract(p));
	vec4 a = vec4(hash3(c), hash3(c + vec3(1.0, 0.0, 0.0)),
		hash3(c + vec3(0.0, 1.0, 0.0)), hash3(c + vec3(1.0, 1.0, 0.0)));
	c.z += 1.0;
	vec4 b = vec4(hash3(c), hash3(c + vec3(1.0, 0.0, 0.0)),
		hash3(c + vec3(0.0, 1.0, 0.0)), hash3(c + vec3(1.0, 1.0, 0.0)));
	vec4 n = mix(a, b, f.z);
	return mix(mix(n.x, n.y, f.x), mix(n.z, n.w, f.x), f.y);
}

void vertex() {
	position_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz - offset_world;
}

void fragment() {
	float terrain = grain(position_world * vec3(5.4, 8.0, 5.4));
	float fine = grain(position_world * 22.0);
	float erosion = grain(position_world * vec3(3.9, 16.0, 4.1));
	float value = 0.77 + 0.32 * terrain + 0.13 * fine + 0.09 * erosion;
	float mineral = dot(COLOR.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 stone_tint = mineral * vec3(0.83, 1.05, 1.43);
	ALBEDO = mix(COLOR.rgb, stone_tint, azul_chumbo) * value;
	ROUGHNESS = 0.94;
	SPECULAR = 0.12;
}
