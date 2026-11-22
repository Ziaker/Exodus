shader_type canvas_item;
// Option D — the first plasma prototype (creator's pick, 2026-11-22) as the sky:
// four interfering sine fields, 6-colour palette cycling, 4x4 ordered dither,
// unchanged. The shared scene (moon, ridges, pillars, perspective scorched floor)
// is drawn over it.
#include "res://prototypes/battle-bg/bg_scene.gdshaderinc"

uniform vec2 stage_size = vec2(544.0, 298.0);
// Creator 2026-11-22: "mais escuro" — the plasma colours are scaled by this.
uniform float plasma_brightness = 0.6;

const vec3 PLASMA[6] = {
	vec3(0.361, 0.110, 0.169), // #5c1c2b
	vec3(0.263, 0.102, 0.149), // #431a26
	vec3(0.380, 0.267, 0.180), // #61442e
	vec3(0.682, 0.337, 0.365), // #ae565d
	vec3(0.733, 0.239, 0.282), // #bb3d48
	vec3(0.208, 0.098, 0.141)  // #351924
};

void fragment() {
	vec2 cell = floor(UV * stage_size / PIX);
	vec2 px = cell * PIX;
	// Creator 2026-11-22: the background animation runs 20% slower.
	float t = TIME * 0.8;
	vec2 c = vec2(68.0 + 40.0 * sin(t * 0.5), 74.0 + 25.0 * cos(t * 0.37));
	float v = sin(cell.x * 0.07 + t)
		+ sin(cell.y * 0.09 - t * 1.3)
		+ sin((cell.x + cell.y) * 0.05 + t * 0.7)
		+ sin(length(cell - c) * 0.12);
	float level = (v + 4.0) / 8.0 * 6.0 + t * 0.6;
	float step_index = floor(level) + (fract(level) > bayer(cell) ? 1.0 : 0.0);
	vec3 sky = PLASMA[int(mod(step_index, 6.0))] * plasma_brightness;
	COLOR = vec4(scene(px, cell, sky, t), 1.0);
}
