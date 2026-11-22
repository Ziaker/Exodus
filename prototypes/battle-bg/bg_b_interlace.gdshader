shader_type canvas_item;
// Option B — "Ecos da lua": soft rings spread from the moon during a pulse
// every ~12 s, each 4 px row pair slightly out of phase; plain sky otherwise.
#include "res://prototypes/battle-bg/bg_scene.gdshaderinc"

uniform vec2 stage_size = vec2(544.0, 298.0);

void fragment() {
	vec2 cell = floor(UV * stage_size / PIX);
	vec2 px = cell * PIX;
	float t = TIME;
	float env = swell(t, 12.0);
	float level = sky_level(px, cell);
	vec2 d = (px - vec2(426.0, 85.0 * SVG_Y)) / vec2(1.0, SVG_Y);
	float phase = mod(floor(cell.y / 2.0), 2.0) < 1.0 ? 0.0 : 0.06;
	float ring = fract(length(d) / 22.0 - t * 0.35 + phase);
	if (ring < 0.3 * env) level = mod(level + 1.0, 4.0);
	COLOR = vec4(scene(px, cell, sky_color(level), t), 1.0);
}
