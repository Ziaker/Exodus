shader_type sky;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(43.13, 157.77))) * 14371.43);
}

float vapor(vec2 p) {
	vec2 i = floor(p);
	vec2 f = smoothstep(vec2(0.0), vec2(1.0), fract(p));
	return mix(mix(hash2(i), hash2(i + vec2(1.0, 0.0)), f.x),
		mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0)), f.x), f.y);
}

void sky() {
	// Os quatro campos do fundo D agitam só o céu, na velocidade da batalha.
	float t = TIME * 0.8;
	vec2 cell = vec2(EYEDIR.x * 96.0 + EYEDIR.z * 61.0,
		EYEDIR.y * 108.0 + EYEDIR.z * 42.0) + vec2(68.0, 74.0);
	vec2 center = vec2(68.0 + 40.0 * sin(t * 0.5), 74.0 + 25.0 * cos(t * 0.37));
	float v = sin(cell.x * 0.07 + t)
		+ sin(cell.y * 0.09 - t * 1.3)
		+ sin((cell.x + cell.y) * 0.05 + t * 0.7)
		+ sin(length(cell - center) * 0.12);
	vec2 drift = vec2(0.88 * sin(cell.y * 0.049 + t), 0.45 * cos(cell.x * 0.057 - t * 1.3));
	vec2 p = vec2(atan(EYEDIR.x, EYEDIR.z) * 8.8, EYEDIR.y * 13.0) + drift * (0.62 + v * 0.10);
	float cloud = 0.55 * vapor(p) + 0.30 * vapor(p * 2.17) + 0.15 * vapor(p * 4.47);
	float field = mix(cloud, (v + 4.0) / 8.0, 0.42);
	// Os limites da paleta vermelha vêm do céu original da Necrópole.
	vec3 red = mix(vec3(0.026, 0.007, 0.009), vec3(0.33, 0.044, 0.030),
		smoothstep(0.18, 0.90, field));
	COLOR = mix(red, vec3(0.027, 0.015, 0.013), smoothstep(0.0, 0.19, -EYEDIR.y));
}
