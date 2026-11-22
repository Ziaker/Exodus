shader_type canvas_item;
// Option A — "Maré lenta": the sky bands sway sideways in a slow sine, like
// scanline offset, only during a swell every ~14 s; calm in between.
#include "res://prototypes/battle-bg/bg_scene.gdshaderinc"

uniform vec2 stage_size = vec2(544.0, 298.0);

void fragment() {
	vec2 cell = floor(UV * stage_size / PIX);
	vec2 px = cell * PIX;
	float t = TIME;
	float env = swell(t, 14.0);
	float y = px.y + env * 9.0 * sin(px.x * 0.018 + t * 0.6 + px.y * 0.04);
	float level = sky_level(vec2(px.x, y), cell);
	COLOR = vec4(scene(px, cell, sky_color(level), t), 1.0);
}
