shader_type canvas_item;
// Option C — "Véu de plasma": a slow plasma moves through the sky only as a
// one-step tone shift (adjacent colours, dithered), fading in and out every ~16 s.
#include "res://prototypes/battle-bg/bg_scene.gdshaderinc"

uniform vec2 stage_size = vec2(544.0, 298.0);

void fragment() {
	vec2 cell = floor(UV * stage_size / PIX);
	vec2 px = cell * PIX;
	float t = TIME;
	float env = swell(t, 16.0);
	float v = sin(px.x * 0.021 + t * 0.35) + sin(px.y * 0.05 - t * 0.27)
		+ sin((px.x + px.y) * 0.014 + t * 0.2);
	float shift = (v / 3.0) * env;
	float level = sky_level(px, cell) + floor(shift * 1.6 + 0.5);
	COLOR = vec4(scene(px, cell, sky_color(level), t), 1.0);
}
