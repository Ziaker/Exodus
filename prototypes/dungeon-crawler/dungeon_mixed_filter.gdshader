shader_type canvas_item;
render_mode unshaded;

uniform sampler2D world_image : hint_screen_texture, filter_linear, repeat_disable;
// The Cartucho ocre + Fita de horror curves, baked as a 64³ sRGB LUT.
// Each 64×64 tile maps red and green for one blue slice, in an 8×8 grid.
uniform sampler2D mixed_palette : filter_linear, repeat_disable;
uniform float frame_height;

const vec2 PIXEL_GRID = vec2(288.0, 176.0);
const float BAYER[16] = {0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0};

vec2 palette_uv(vec2 red_green, float blue_slice) {
	vec2 tile = vec2(mod(blue_slice, 8.0), floor(blue_slice / 8.0));
	return (tile * 64.0 + red_green + 0.5) / 512.0;
}

vec3 grade(vec3 color) {
	vec3 lookup = color * 63.0;
	float slice = floor(lookup.b);
	vec3 lower = texture(mixed_palette, palette_uv(lookup.rg, slice)).rgb;
	vec3 upper = texture(mixed_palette, palette_uv(lookup.rg, min(slice + 1.0, 63.0))).rgb;
	return mix(lower, upper, fract(lookup.b));
}

void fragment() {
	vec2 cell = min(floor(UV * PIXEL_GRID), PIXEL_GRID - 1.0);
	vec2 cell_center = (cell + 0.5) / PIXEL_GRID;
	vec2 view_scale = vec2(dFdx(SCREEN_UV.x) / dFdx(UV.x), dFdy(SCREEN_UV.y) / dFdy(UV.y));
	// Linear sampling must stay inside the BackBufferCopy region, even in a small window.
	vec2 half_texel = min(abs(SCREEN_PIXEL_SIZE / view_scale) * 0.5, vec2(0.5));
	cell_center = clamp(cell_center, half_texel, 1.0 - half_texel);
	vec3 color = grade(texture(world_image, SCREEN_UV + (cell_center - UV) * view_scale).rgb);

	int bayer_index = int(mod(cell.x, 4.0)) + (3 - int(mod(cell.y, 4.0))) * 4;
	float dither = ((BAYER[bayer_index] + 0.5) / 16.0 - 0.5) * 0.012;
	color = clamp(floor((color + dither) * 26.0 + 0.5) / 26.0, 0.0, 1.0);

	float row = UV.y * frame_height;
	float line = 1.0 - step(1.0, mod(floor(row), 3.0));
	// Fade scanlines when the viewport becomes too small to resolve them.
	float gain = 1.0 - 0.15 * line * clamp(3.0 - 2.0 * fwidth(row), 0.0, 1.0);
	// The reference scanline gain is applied in linear light; the canvas is sRGB.
	vec3 scan_color = (color + 0.055) * pow(gain, 1.0 / 2.4) - 0.055;
	COLOR = vec4(mix(color * gain, scan_color, step(vec3(0.04045), color)), 1.0);
}
