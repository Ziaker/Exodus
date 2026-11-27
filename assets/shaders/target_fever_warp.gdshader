shader_type canvas_item;
// D-125: Scanline Warp febril do alvo atingido (Motor 3). Reproduz, em faixas horizontais de 3.5 px do
// espaco de design 816x624, wx = sin(sy*0.18 + t*20)*amp + cos(sy*0.09 - t*12)*amp*0.5, e o flash de
// inversao osso (#e8ddd0) dos impact frames, preservando a silhueta do sprite.

uniform float warp_amp = 0.0;                 // px de design
uniform float time_val = 0.0;
uniform float invert_mix : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ink : source_color = vec4(0.0, 0.0, 0.0, 1.0);   // a silhueta do HUD e uma mascara tingida de preto
uniform vec4 bone : source_color = vec4(0.910, 0.867, 0.816, 1.0);
uniform vec2 rect_size = vec2(100.0, 100.0);  // tamanho logico do sprite
uniform float px_scale = 1.5;                 // px de design por px logico

void fragment() {
	float h = rect_size.y * px_scale;
	float w = rect_size.x * px_scale;
	float sy = (UV.y - 0.5) * h;
	float start = -0.5 * h;
	float band = floor((sy - start) / 3.5) * 3.5 + start;
	float wx = sin(band * 0.18 + time_val * 20.0) * warp_amp + cos(band * 0.09 - time_val * 12.0) * warp_amp * 0.5;
	vec4 tex = texture(TEXTURE, vec2(UV.x - wx / w, UV.y));
	vec3 rgb = mix(ink.rgb, bone.rgb, invert_mix);
	COLOR = vec4(rgb, tex.a);
}
