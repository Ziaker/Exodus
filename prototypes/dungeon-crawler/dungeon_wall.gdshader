shader_type spatial;
// Parede do teste de dungeon: textura sem luz, escurecida por profundidade como o
// script 3D do SMT VX (camada preta de alpha 50/255 por tile de distância).
render_mode unshaded, cull_disabled;

uniform sampler2D wall_tex : source_color, filter_nearest;
// Brilho que sobra a cada tile: 1 - 50/255.
uniform float keep_per_tile = 0.80392157;

void fragment() {
	vec3 c = texture(wall_tex, UV).rgb;
	float depth_tiles = max(-VERTEX.z, 0.0);
	ALBEDO = c * pow(keep_per_tile, depth_tiles);
}
