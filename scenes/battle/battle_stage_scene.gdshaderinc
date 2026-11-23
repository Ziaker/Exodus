// Shared static scene of the battle stage (copied from prototypes/battle-bg/bg_scene.gdshaderinc).
// Keeps the original backdrop's elements (exodus_feedback_lab.html): sky bands,
// the moon, two mountain ridges, the two ruined pillars and the scorched ground,
// now with a floor in perspective. Everything is quantised to 2 px pixels and a
// fixed palette; tone steps use a 4x4 ordered dither instead of smooth gradients.

const float PIX = 2.0;
const float SVG_Y = 298.0 / 251.0;
const float HORIZON = 214.0; // stage px: where the floor meets the hills

// Original backdrop palette.
const vec3 SKY[4] = {
	vec3(0.157, 0.043, 0.078), // #280b14 top
	vec3(0.208, 0.075, 0.110), // between #280b14 and #431a26
	vec3(0.263, 0.102, 0.149), // #431a26
	vec3(0.361, 0.110, 0.169)  // #5c1c2b near the horizon
};
const vec3 FAR_HILL = vec3(0.208, 0.098, 0.141);  // #351924
const vec3 MID_HILL = vec3(0.231, 0.153, 0.157);  // #3b2728
const vec3 SOIL_FAR = vec3(0.231, 0.153, 0.157);  // #3b2728
const vec3 SOIL_MID = vec3(0.290, 0.200, 0.161);  // between #3b2728 and #61442e
const vec3 SOIL_NEAR = vec3(0.380, 0.267, 0.180); // #61442e
const vec3 CRACK = vec3(0.106, 0.059, 0.067);     // dark scorched seam
const vec3 EMBER = vec3(0.733, 0.239, 0.282);     // #bb3d48
const vec3 MOON = vec3(0.682, 0.337, 0.365);      // #ae565d

const float BAYER[16] = {0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0};

// Ridge points from the original SVG (x, svg y).
const vec2 FAR_RIDGE[13] = {vec2(0.0, 168.0), vec2(62.0, 138.0), vec2(95.0, 143.0), vec2(131.0, 108.0), vec2(170.0, 134.0), vec2(227.0, 130.0), vec2(268.0, 94.0), vec2(307.0, 141.0), vec2(371.0, 127.0), vec2(417.0, 100.0), vec2(460.0, 131.0), vec2(505.0, 116.0), vec2(544.0, 145.0)};
const vec2 MID_RIDGE[10] = {vec2(0.0, 202.0), vec2(84.0, 188.0), vec2(120.0, 198.0), vec2(187.0, 169.0), vec2(243.0, 195.0), vec2(315.0, 181.0), vec2(374.0, 192.0), vec2(437.0, 162.0), vec2(500.0, 189.0), vec2(544.0, 174.0)};

float bayer(vec2 p) {
	return BAYER[int(mod(p.x, 4.0)) + int(mod(p.y, 4.0)) * 4] / 16.0;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float far_ridge(float x) {
	for (int i = 0; i < 12; i++) {
		if (x <= FAR_RIDGE[i + 1].x) {
			float k = (x - FAR_RIDGE[i].x) / (FAR_RIDGE[i + 1].x - FAR_RIDGE[i].x);
			return mix(FAR_RIDGE[i].y, FAR_RIDGE[i + 1].y, k) * SVG_Y;
		}
	}
	return FAR_RIDGE[12].y * SVG_Y;
}

float mid_ridge(float x) {
	for (int i = 0; i < 9; i++) {
		if (x <= MID_RIDGE[i + 1].x) {
			float k = (x - MID_RIDGE[i].x) / (MID_RIDGE[i + 1].x - MID_RIDGE[i].x);
			float y = mix(MID_RIDGE[i].y, MID_RIDGE[i + 1].y, k) * SVG_Y;
			// Compressed so the near hills rest on the horizon of the new floor.
			return 192.0 + (y - 192.0) * 0.45;
		}
	}
	return HORIZON;
}

// Sky tone index 0..3: the height gradient split into 12 px stripes that
// alternate one tone, so sideways motion reads as soft moving bands.
float sky_level(vec2 px, vec2 cell) {
	float v = clamp(px.y / HORIZON, 0.0, 1.0) * 2.0;
	float stripe = mod(floor(px.y / 12.0), 2.0);
	return floor(v + 0.5) + stripe;
}

vec3 sky_color(float level) {
	return SKY[int(clamp(level, 0.0, 3.0))];
}

// Voronoi edge distance in floor space: small near cell borders (the cracks).
float crack_edge(vec2 q) {
	vec2 i = floor(q);
	vec2 f = fract(q);
	float d1 = 8.0;
	float d2 = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(hash(i + g), hash(i + g + 17.0));
			float d = length(g + o - f);
			if (d < d1) { d2 = d1; d1 = d; }
			else if (d < d2) { d2 = d; }
		}
	}
	return d2 - d1;
}

// Pillar from the original: stepped top, x range and svg heights; base on the floor.
bool pillar(vec2 px, float x0, float x1, float xs0, float xs1, float top_outer, float top_mid, float top_inner, float base) {
	if (px.x < x0 || px.x > x1 || px.y > base) return false;
	float w = x1 - x0;
	float rel = (px.x - x0) / w;
	float top = top_outer;
	if (px.x >= xs0 && px.x <= xs1) top = top_inner;
	else if (rel > 0.12 && rel < 0.88) top = top_mid;
	return px.y >= top;
}

// Static scene over a given sky colour; t only drives the ember flicker.
vec3 scene(vec2 px, vec2 cell, vec3 sky, float t) {
	vec3 col = sky;
	// Moon: the original disc at 22% over the sky, drawn as a dithered mask.
	vec2 m = (px - vec2(426.0, 85.0 * SVG_Y)) / vec2(37.0, 37.0 * SVG_Y);
	if (dot(m, m) < 1.0) col = mix(col, MOON, 0.22);
	if (px.y >= far_ridge(px.x)) col = FAR_HILL;
	if (px.y >= mid_ridge(px.x)) col = MID_HILL;
	if (px.y >= HORIZON) {
		// Perspective floor: depth grows towards the horizon.
		float dy = max(px.y - HORIZON, 0.5);
		float z = 40.0 / dy;
		vec2 q = vec2((px.x - 272.0) * z / 40.0, z);
		float near = clamp(dy / (298.0 - HORIZON), 0.0, 1.0);
		// Burnt patches: low-frequency noise picks one of three soil tones.
		float patch = vnoise(q * vec2(1.3, 0.9)) + near * 0.55;
		col = patch < 0.55 ? SOIL_FAR : (patch < 0.95 ? SOIL_MID : SOIL_NEAR);
		// Fissures: warped Voronoi so they break irregularly instead of tiling.
		vec2 w = q * vec2(0.9, 0.7) + 0.6 * vec2(vnoise(q * 1.7), vnoise(q * 1.7 + 9.0));
		float e = crack_edge(w);
		float width = mix(0.0, 0.07, smoothstep(0.18, 1.0, near)) * (0.6 + 0.8 * vnoise(q * 3.0));
		if (e < width) {
			col = CRACK;
			// Rare embers deep in the widest seams, breathing slowly.
			// Screen-space so an ember stays one 2 px dot, never stretched by perspective.
			float h = hash(cell);
			if (h > 0.985 && e < width * 0.4 && sin(t * 0.7 + h * 40.0) > 0.2) col = EMBER;
		}
		// Haze: a solid step into the hill colour right at the horizon.
		if (near < 0.07) col = MID_HILL;
	}
	// Creator 2026-11-22: the two ruined pillars were removed (they got in the way).
	return col;
}

// Slow envelope: calm most of the time, a gentle swell every `period` seconds.
float swell(float t, float period) {
	float s = max(0.0, sin(t * 6.2831853 / period));
	return s * s * s;
}
