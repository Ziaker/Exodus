shader_type spatial;
render_mode unshaded;

// Piso do overworld: lajes quadradas repetidas em perspectiva real (malha 3D).
uniform sampler2D floor_tex;
uniform vec2 tiles = vec2(40.0, 40.0);

void fragment() {
	ALBEDO = texture(floor_tex, UV * tiles).rgb;
}
