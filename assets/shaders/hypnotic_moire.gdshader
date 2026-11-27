shader_type canvas_item;
// D-125: Campo de Interferencia Hipnotica (Moire / ondas febris), porte 1:1 de drawHypnoticField (mode 0)
// e drawBreathConeMoire (mode 1) dos HTMLs aprovados (docs/vfx_refs/d124_d125/). Avaliado na GPU em
// celulas pixel-crisp de 5x5 px do espaco de design 816x624 (sem loop GDScript por pixel).
// Todas as medidas abaixo estao no espaco de DESIGN (816 de largura): o no converte px logicos x 1.5.

uniform int mode = 0;                       // 0 = elipse radial, 1 = cone exalado da boca
uniform float time_val = 0.0;
uniform float env : hint_range(0.0, 2.0) = 1.0;
uniform bool dark_bias = false;             // Umbral Gaze: limiares mais escuros
uniform vec2 rect_size = vec2(100.0, 100.0);   // tamanho do retangulo coberto
uniform vec2 rect_origin = vec2(0.0, 0.0);     // canto superior esquerdo do retangulo
uniform vec2 mouth_pos = vec2(0.0, 0.0);       // modo 1: garganta
uniform float reach = 0.0;                     // modo 1: alcance do cone
uniform float dir_x = 1.0;                     // modo 1: +1 direita / -1 esquerda (espelhamento)
// Perfil de limiares da versao canonica do HTML de cada ataque (v2: 0.30/1.28; v3: 0.26/1.30; v4: 0.30/1.30).
uniform float threshold = 0.30;
uniform float hi_t = 1.30;
uniform float mid_t = 0.72;
uniform float alpha_k = 1.45;
uniform float alpha_cap = 0.92;
uniform vec4 col_hi : source_color = vec4(0.937, 0.902, 0.835, 1.0);
uniform vec4 col_accent : source_color = vec4(0.659, 0.110, 0.180, 1.0);
uniform vec4 col_dark : source_color = vec4(0.020, 0.008, 0.031, 1.0);

const float STEP = 5.0;

void fragment() {
	vec2 p = rect_origin + UV * rect_size;
	vec2 c = floor(p / STEP) * STEP;   // canto da celula 5x5
	float v;
	float fall;
	float thr = threshold;
	float hi_v = hi_t;
	float mid_v = mid_t;
	float ak = alpha_k;
	float acap = alpha_cap;
	if (mode == 0) {
		vec2 center = rect_origin + rect_size * 0.5;
		float rx = rect_size.x * 0.5;
		float ry = rect_size.y * 0.5;
		float dx = c.x - center.x;
		float dy = c.y - center.y;
		float norm = dx * dx / (rx * rx + 1.0) + dy * dy / (ry * ry + 1.0);
		if (norm > 1.0) { discard; }
		fall = 1.0 - sqrt(norm);
		float dist = sqrt(dx * dx + dy * dy);
		float ang = atan(dy, dx);
		v = sin(dist * 0.21 - time_val * 14.0 + sin(ang * 4.0 + time_val * 5.0) * 2.1)
			+ cos((dx * 0.1 - dy * 0.08) + sin(c.y * 0.08 + time_val * 8.0) * 1.9);
		if (dark_bias) { hi_v = 1.55; mid_v = 0.85; }  // Umbral Gaze (darkBias): cristas mais escuras
	} else {
		float dx = (c.x - mouth_pos.x) * dir_x;
		if (dx < 0.0 || dx >= reach) { discard; }
		float frac = dx / max(1.0, reach);
		float half_h = 16.0 + dx * 0.21;
		float dy = abs(c.y - mouth_pos.y);
		if (dy > half_h) { discard; }
		float edge_x = frac < 0.08 ? frac / 0.08 : (frac > 0.78 ? max(0.0, 1.0 - (frac - 0.78) / 0.22) : 1.0);
		float edge_y = max(0.0, 1.0 - dy / half_h);
		fall = edge_x * edge_y;
		if (fall <= 0.04) { discard; }
		v = sin(dx * 0.095 - time_val * 19.0 + sin(c.y * 0.1 + time_val * 9.0) * 2.3)
			+ cos((c.y - mouth_pos.y) * 0.13 + sin(dx * 0.055 - time_val * 11.0) * 2.2);
		thr = 0.22;      // drawBreathConeMoire (v4): limiares proprios
		hi_v = 1.55;
		mid_v = 0.78;
		ak = 1.55;
		acap = 0.95;
	}
	if (v * fall * env <= thr) { discard; }
	vec4 col = v > hi_v ? col_hi : (v > mid_v ? col_accent : col_dark);
	COLOR = vec4(col.rgb, min(acap, env * fall * ak) * col.a);
}
