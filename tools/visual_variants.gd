extends SceneTree

## Prototipo visual: seis interpretacoes de combate em primeira pessoa.
## Regras comuns: so oponente e fundo usam imagens; todo o HUD e codigo.
## Cada opcao e validada ANTES de salvar: texto medido, sem vazamento e sem
## elemento fora da tela. Se houver violacao, a captura NAO e gravada.

const W := 544.0
const H := 416.0
const BACK := "res://assets/graphics/parallaxes/BB01-001.png"
const FOES := [
	"res://assets/graphics/battle_sprites/Avatar Anubis.png",
	"res://assets/graphics/battle_sprites/Avatar Chimera.png",
]
const OUTPUTS := [
	"res://captures/option_a.png",
	"res://captures/option_b.png",
	"res://captures/option_c.png",
	"res://captures/option_d.png",
	"res://captures/option_e.png",
	"res://captures/option_f.png",
	"res://captures/option_a2.png",
	"res://captures/option_a3.png",
	"res://captures/option_b2.png",
	"res://captures/option_b3.png",
	"res://captures/option_r1.png",
	"res://captures/option_r2.png",
	"res://captures/option_r3.png",
	"res://captures/option_v1.png",
	"res://captures/option_v2.png",
	"res://captures/option_v3.png",
]

const FILL := Color(0.16, 0.17, 0.16, 1.0)
const BORDER := Color(0.55, 0.56, 0.54, 1.0)
const INNER := Color(0.30, 0.32, 0.30, 1.0)
const TEXT := Color(0.93, 0.94, 0.90)
const GREEN := Color(0.20, 0.78, 0.36)
const BLUE := Color(0.25, 0.55, 0.95)
const RED := Color(0.85, 0.25, 0.25)
const SP_BLUE := Color(0.30, 0.60, 0.95)
const AMBER := Color(0.85, 0.65, 0.15)
const MAROON := Color(0.34, 0.16, 0.16)
const LIGHT := Color(0.82, 0.84, 0.85)
const DARK_TEXT := Color(0.10, 0.10, 0.10)
const GREEN_TEXT := Color(0.25, 0.85, 0.35)
const WHITE := Color(0.95, 0.95, 0.95)


func _initialize() -> void:
	var builders := [Callable(self, "_option_a"), Callable(self, "_option_b"),
		Callable(self, "_option_c"), Callable(self, "_option_d"),
		Callable(self, "_option_e"), Callable(self, "_option_f"),
		Callable(self, "_option_a2"), Callable(self, "_option_a3"),
		Callable(self, "_option_b2"), Callable(self, "_option_b3"),
		Callable(self, "_option_r1"), Callable(self, "_option_r2"),
		Callable(self, "_option_r3"), Callable(self, "_option_v1"),
		Callable(self, "_option_v2"), Callable(self, "_option_v3")]
	var all_ok := true
	for i in builders.size():
		var screen := Control.new()
		screen.position = Vector2.ZERO
		screen.size = Vector2(W, H)
		root.add_child(screen)
		_background(screen)
		builders[i].call(screen)
		for _j in 3:
			await process_frame

		var errors := _validate(screen)
		if errors.is_empty():
			var image: Image = root.get_texture().get_image()
			image.save_png(ProjectSettings.globalize_path(OUTPUTS[i]))
			print("OK   ", OUTPUTS[i], " - 0 erros de layout")
		else:
			all_ok = false
			push_error("FALHA " + OUTPUTS[i])
			for e in errors:
				push_error("  " + e)
		screen.queue_free()
		for _j in 3:
			await process_frame
	quit(0 if all_ok else 1)


# ---------- Validacao ----------

func _measure(text: String, font_size: int, font: Font = null) -> Vector2:
	var used: Font = font if font != null else ThemeDB.fallback_font
	return used.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, float(font_size))


func _validate(screen: Control) -> Array[String]:
	var errors: Array[String] = []
	_check(screen, errors, null)
	return errors


func _check(node: Node, errors: Array[String], panel: Control) -> void:
	if node is Label:
		var label := node as Label
		var size := label.get_theme_font_size("font_size")
		var need_a := _measure(label.text, size, label.get_theme_font("font"))
		var need_b := _measure(label.text, size, ThemeDB.fallback_font)
		var need := Vector2(maxf(need_a.x, need_b.x), maxf(need_a.y, need_b.y))
		if need.x > label.size.x + 1.0 or need.y > label.size.y + 1.0:
			errors.append("TEXTO VAZANDO: '%s' precisa %dx%d, caixa %dx%d" % [
				label.text, int(need.x), int(need.y), int(label.size.x), int(label.size.y)])
	if node is Control:
		var control := node as Control
		var rect := control.get_global_rect()
		if rect.position.x < -1.0 or rect.position.y < -1.0 \
			or rect.end.x > W + 1.0 or rect.end.y > H + 1.0:
			var extra := ""
			if control is Label:
				extra = " texto='%s' need=%s" % [(control as Label).text,
					_measure((control as Label).text,
						(control as Label).get_theme_font_size("font_size"),
						(control as Label).get_theme_font("font"))]
			errors.append("FORA DA TELA: %s %s%s" % [control.name, rect, extra])
		if panel != null and node != panel:
			var outer := panel.get_global_rect()
			if not outer.encloses(rect):
				errors.append("VAZAMENTO DE PAINEL: %s %s fora de %s" % [
					control.name, rect, outer])
	var next_panel := panel
	if node is Control and (node as Control).has_meta("painel"):
		next_panel = node as Control
	for child in node.get_children():
		_check(child, errors, next_panel)


# ---------- Primitivas ----------

func _background(parent: Control) -> void:
	var back := TextureRect.new()
	back.texture = load(BACK)
	back.position = Vector2.ZERO
	back.size = Vector2(W, H)
	back.stretch_mode = TextureRect.STRETCH_SCALE
	parent.add_child(back)


func _rect(parent: Control, x: float, y: float, w: float, h: float,
		color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.position = Vector2(x, y)
	r.size = Vector2(w, h)
	parent.add_child(r)
	return r


func _panel(parent: Control, pos: Vector2, size: Vector2) -> Control:
	var p := Control.new()
	p.position = pos
	p.size = size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.clip_contents = true
	p.set_meta("painel", true)
	parent.add_child(p)
	_rect(p, 0, 0, size.x, size.y, FILL)
	_rect(p, 0, 0, size.x, 2, BORDER)
	_rect(p, 0, size.y - 2, size.x, 2, BORDER)
	_rect(p, 0, 0, 2, size.y, BORDER)
	_rect(p, size.x - 2, 0, 2, size.y, BORDER)
	_rect(p, 2, 2, size.x - 4, 1, INNER)
	_rect(p, 2, size.y - 3, size.x - 4, 1, INNER)
	_rect(p, 2, 2, 1, size.y - 4, INNER)
	_rect(p, size.x - 3, 2, 1, size.y - 4, INNER)
	return p


func _label(parent: Control, text: String, x: float, y: float, font_size: int,
		color: Color = TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", ThemeDB.fallback_font)
	var need := _measure(text, font_size, ThemeDB.fallback_font)
	label.position = Vector2(x, y)
	label.size = Vector2(ceilf(need.x) + 2.0, ceilf(need.y) + 4.0)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 1)
	parent.add_child(label)
	return label


func _label_centered(parent: Control, text: String, center_x: float, y: float,
		width: float, font_size: int, color: Color = TEXT) -> Label:
	var need := _measure(text, font_size)
	return _label(parent, text, center_x - need.x / 2.0, y, font_size, color)


func _label_right(parent: Control, text: String, right_x: float, y: float,
		font_size: int, color: Color = TEXT) -> Label:
	var need := _measure(text, font_size)
	return _label(parent, text, right_x - need.x, y, font_size, color)


func _bar(parent: Control, x: float, y: float, w: float, h: float,
		ratio: float, color: Color) -> void:
	_rect(parent, x, y, w, h, Color(0.06, 0.08, 0.07))
	_rect(parent, x + 1, y + 1, (w - 2) * clampf(ratio, 0.0, 1.0), h - 2, color)


func _foe(parent: Control, index: int, pos: Vector2, size: Vector2) -> void:
	var texture: Texture2D = load(FOES[index])
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(2, 2, texture.get_width() - 4, texture.get_height() - 4)
	var sprite := TextureRect.new()
	sprite.texture = atlas
	sprite.position = pos
	sprite.custom_minimum_size = size
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	parent.add_child(sprite)


func _buttons(parent: Control, labels: Array[String], x0: float, y: float,
		button_w: float, button_h: float, gap: float, font_size: int) -> void:
	for i in labels.size():
		var x := x0 + i * (button_w + gap)
		_rect(parent, x, y, button_w, button_h, Color(0.09, 0.10, 0.09))
		_rect(parent, x, y, button_w, 2, BORDER)
		_rect(parent, x, y + button_h - 2, button_w, 2, BORDER)
		_rect(parent, x, y, 2, button_h, BORDER)
		_rect(parent, x + button_w - 2, y, 2, button_h, BORDER)
		_label_centered(parent, labels[i], x + button_w / 2.0,
			y + (button_h - 20.0) / 2.0, button_w, font_size)


func _reticle(parent: Control, cx: float, cy: float, hw: float, hh: float) -> void:
	var l := cx - hw
	var r := cx + hw - 20.0
	var t := cy - hh
	var b := cy + hh - 20.0
	_rect(parent, l, t, 20, 3, AMBER)
	_rect(parent, l, t, 3, 20, AMBER)
	_rect(parent, r, t, 20, 3, AMBER)
	_rect(parent, r + 17, t, 3, 20, AMBER)
	_rect(parent, l, b + 17, 20, 3, AMBER)
	_rect(parent, l, b, 3, 20, AMBER)
	_rect(parent, r, b + 17, 20, 3, AMBER)
	_rect(parent, r + 17, b, 3, 20, AMBER)
	_rect(parent, cx - 4, cy - 1, 8, 2, AMBER)
	_rect(parent, cx - 1, cy - 4, 2, 8, AMBER)


func _vertical(parent: Control, text: String, x: float, y: float,
		font_size: int, color: Color) -> void:
	for i in text.length():
		_label(parent, text.substr(i, 1), x, y + i * (font_size + 6.0),
			font_size, color)


func _banner(parent: Control, x: float, y: float, w: float, h: float,
		text: String) -> void:
	_rect(parent, x, y, w, h, LIGHT)
	_rect(parent, x, y + h - 2, w, 2, Color(0.20, 0.20, 0.20))
	_label(parent, text, x + 8, y + 4, 14, DARK_TEXT)


func _meter(parent: Control, x: float, y: float, w: float, h: float,
		segments: int, green: int) -> void:
	var step := w / float(segments)
	for i in segments:
		_rect(parent, x + i * step, y, step - 2, h,
			GREEN if i < green else RED)


func _stat_panel(parent: Control, x: float, y: float, w: float, h: float,
		title: String, hp: String, ep: String, acts: String) -> void:
	var p := _panel(parent, Vector2(x, y), Vector2(w, h))
	_label(p, title, 8, 4, 12, WHITE)
	_label(p, "HP - " + hp, 8, 20, 11, WHITE)
	_label(p, "EP - " + ep, 8, 34, 11, WHITE)
	_label(p, "ACT   " + acts, 8, 48, 11, WHITE)


# ---------- A: minima / cinematografica ----------

func _option_a(screen: Control) -> void:
	_foe(screen, 0, Vector2(152, 26), Vector2(240, 246))
	_rect(screen, 0, 0, W, 54, Color(0, 0, 0, 0.82))
	_label(screen, "ROUND 1", 14, 10, 14)
	_label_right(screen, "SP 46 / 47", 530, 11, 13)
	_rect(screen, 14, 36, 516, 1, BORDER)

	_rect(screen, 0, 274, W, 142, Color(0, 0, 0, 0.82))
	_label(screen, "FALLEN acts.", 14, 284, 14)
	_rect(screen, 12, 314, 4, 22, AMBER)
	_label(screen, "ATTACK   ITEM   REST   ABSORB", 24, 315, 13)
	_label(screen, "FALLEN   HP 14/14   EN 8/8   SP 46   A3 S0", 14, 350, 12)
	_bar(screen, 14, 370, 180, 5, 1.0, GREEN)
	_bar(screen, 200, 370, 120, 5, 1.0, BLUE)
	_label(screen, "ALLY   HP 11/11   EN 7/7   SP 36   A3 S0", 14, 382, 12)
	_bar(screen, 14, 402, 180, 5, 1.0, GREEN)
	_bar(screen, 200, 402, 120, 5, 1.0, BLUE)


# ---------- B: visor ----------

func _option_b(screen: Control) -> void:
	_foe(screen, 0, Vector2(167, 26), Vector2(210, 216))
	_rect(screen, 150, 52, 26, 3, AMBER)
	_rect(screen, 150, 52, 3, 26, AMBER)
	_rect(screen, 368, 52, 26, 3, AMBER)
	_rect(screen, 391, 52, 3, 26, AMBER)
	_rect(screen, 150, 238, 26, 3, AMBER)
	_rect(screen, 150, 215, 3, 26, AMBER)
	_rect(screen, 368, 238, 26, 3, AMBER)
	_rect(screen, 391, 215, 3, 26, AMBER)
	_rect(screen, 268, 118, 8, 2, AMBER)
	_rect(screen, 271, 115, 2, 8, AMBER)

	var top := _panel(screen, Vector2(8, 6), Vector2(528, 42))
	_label(top, "ROUND 1", 8, 6, 12)
	_label(top, "FALLEN", 150, 6, 12)
	_bar(top, 150, 26, 120, 8, 1.0, GREEN)
	_label(top, "FOE", 300, 6, 12)
	_bar(top, 300, 26, 120, 8, 0.96, RED)

	var left := _panel(screen, Vector2(8, 296), Vector2(260, 112))
	_label(left, "FALLEN   SP 46   A3 S0", 8, 6, 12)
	_bar(left, 8, 28, 244, 8, 1.0, GREEN)
	_bar(left, 8, 40, 244, 8, 1.0, BLUE)
	_label(left, "ALLY   SP 36   A3 S0", 8, 60, 12)
	_bar(left, 8, 82, 244, 8, 1.0, GREEN)
	_bar(left, 8, 94, 244, 8, 1.0, BLUE)

	var right := _panel(screen, Vector2(276, 296), Vector2(260, 112))
	_label(right, "FALLEN acts.", 8, 6, 12)
	var names: Array[String] = ["ATTACK", "ITEM", "REST", "ABSORB"]
	for i in names.size():
		var x := 8 + (i % 2) * 126
		var y := 34 + (i / 2) * 36
		_rect(right, x, y, 120, 30, Color(0.09, 0.10, 0.09))
		_rect(right, x, y, 120, 2, BORDER)
		_rect(right, x, y + 28, 120, 2, BORDER)
		_rect(right, x, y, 2, 30, BORDER)
		_rect(right, x + 118, y, 2, 30, BORDER)
		_label_centered(right, names[i], x + 60, y + 5, 120, 12)

	var gauge := _panel(screen, Vector2(498, 70), Vector2(38, 214))
	for i in 10:
		_rect(gauge, 6, 10 + i * 20, 26, 16, SP_BLUE if i < 4 else RED)
	_label_centered(gauge, "SP", 19, 186, 38, 10)


# ---------- C: tatica ----------

func _option_c(screen: Control) -> void:
	_foe(screen, 1, Vector2(244, 46), Vector2(140, 144))
	_foe(screen, 0, Vector2(160, 30), Vector2(200, 206))

	var head := _panel(screen, Vector2(192, 4), Vector2(160, 30))
	_label_centered(head, "ROUND 1", 80, 3, 160, 13)

	var left := _panel(screen, Vector2(6, 70), Vector2(156, 196))
	_label(left, "FALLEN", 8, 6, 13)
	_bar(left, 8, 28, 140, 8, 1.0, GREEN)
	_bar(left, 8, 40, 140, 8, 1.0, BLUE)
	_label(left, "HP 14/14  EN 8/8", 8, 52, 11)
	_label(left, "SP 46  A3  S0", 8, 70, 11)
	_rect(left, 8, 92, 140, 1, INNER)
	_label(left, "ALLY", 8, 98, 13)
	_bar(left, 8, 120, 140, 8, 1.0, GREEN)
	_bar(left, 8, 132, 140, 8, 1.0, BLUE)
	_label(left, "HP 11/11  EN 7/7", 8, 146, 11)
	_label(left, "SP 36  A3  S0", 8, 164, 11)

	var right := _panel(screen, Vector2(382, 70), Vector2(156, 196))
	_label(right, "FOE A", 8, 6, 13)
	_bar(right, 8, 28, 140, 8, 0.92, RED)
	_label(right, "HP 12/13  WEAK", 8, 52, 11)
	_rect(right, 8, 92, 140, 1, INNER)
	_label(right, "FOE B", 8, 98, 13)
	_bar(right, 8, 120, 140, 8, 1.0, RED)
	_label(right, "HP 15/15  RESIST", 8, 146, 11)
	_label(right, "SP 47", 8, 164, 11)

	var bottom := _panel(screen, Vector2(6, 282), Vector2(532, 86))
	_label(bottom, "FALLEN acts.", 8, 4, 13)
	_buttons(bottom, ["ATTACK", "ITEM", "REST", "ABSORB"], 10, 30, 124, 50, 6, 13)


# ---------- D: console ----------

func _option_d(screen: Control) -> void:
	for y in range(0, 416, 4):
		_rect(screen, 0, y, W, 1, Color(0, 0, 0, 0.10))
	_foe(screen, 0, Vector2(167, 26), Vector2(210, 216))

	var head := _panel(screen, Vector2(356, 6), Vector2(182, 28))
	_label(head, "ROUND 1   SP 46 / 47", 8, 5, 12)

	var left := _panel(screen, Vector2(8, 62), Vector2(150, 206))
	_label(left, "FALLEN", 8, 8, 13)
	_bar(left, 8, 32, 134, 9, 1.0, GREEN)
	_bar(left, 8, 46, 134, 9, 1.0, BLUE)
	_label(left, "HP 14/14", 8, 62, 11)
	_label(left, "EN 8/8", 8, 82, 11)
	_label(left, "SP 46  A3  S0", 8, 102, 11)
	_rect(left, 8, 128, 134, 1, AMBER)
	_label(left, "ALLY", 8, 136, 13)
	_bar(left, 8, 160, 134, 9, 1.0, GREEN)
	_bar(left, 8, 174, 134, 9, 1.0, BLUE)
	_label(left, "HP 11/11  SP 36", 8, 180, 11)

	var console := _panel(screen, Vector2(8, 276), Vector2(528, 132))
	_label(console, "FALLEN acts.", 12, 8, 16)
	_rect(console, 8, 36, 512, 1, AMBER)
	_buttons(console, ["ATTACK", "ITEM", "REST", "ABSORB"], 10, 54, 122, 62, 6, 13)


# ---------- E: bloco ----------

func _option_e(screen: Control) -> void:
	_foe(screen, 0, Vector2(160, 48), Vector2(224, 206))
	_rect(screen, 0, 0, W, 44, FILL)
	_rect(screen, 0, 0, W, 4, AMBER)
	_rect(screen, 0, 40, W, 4, AMBER)
	_label(screen, "ROUND 1", 12, 10, 17)
	_label_right(screen, "SP 46 / 47", 532, 12, 15)

	var left := Control.new()
	left.position = Vector2(8, 52)
	left.size = Vector2(170, 214)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.clip_contents = true
	left.set_meta("painel", true)
	screen.add_child(left)
	_rect(left, 0, 0, 170, 214, FILL)
	_rect(left, 0, 0, 170, 4, AMBER)
	_rect(left, 0, 210, 170, 4, AMBER)
	_rect(left, 0, 0, 4, 214, AMBER)
	_rect(left, 166, 0, 4, 214, AMBER)
	_label(left, "FALLEN", 12, 10, 16)
	_bar(left, 12, 40, 146, 14, 1.0, GREEN)
	_bar(left, 12, 62, 146, 14, 1.0, BLUE)
	_label(left, "HP 14/14", 12, 84, 13)
	_label(left, "EN 8/8", 12, 108, 13)
	_label(left, "SP 46", 12, 132, 13)
	_rect(left, 12, 160, 146, 3, INNER)
	_label(left, "ALLY", 12, 168, 16)
	_bar(left, 12, 194, 146, 12, 1.0, GREEN)

	var right := Control.new()
	right.position = Vector2(366, 52)
	right.size = Vector2(170, 214)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.clip_contents = true
	right.set_meta("painel", true)
	screen.add_child(right)
	_rect(right, 0, 0, 170, 214, FILL)
	_rect(right, 0, 0, 170, 4, AMBER)
	_rect(right, 0, 210, 170, 4, AMBER)
	_rect(right, 0, 0, 4, 214, AMBER)
	_rect(right, 166, 0, 4, 214, AMBER)
	var names: Array[String] = ["ATTACK", "ITEM", "REST", "ABSORB"]
	for i in names.size():
		var y := 10 + i * 50
		if i == 0:
			_rect(right, 8, y, 154, 44, AMBER)
		_rect(right, 12, y + 4, 146, 36, Color(0.09, 0.10, 0.09))
		_label_centered(right, names[i], 85, y + 13, 146, 14)

	var bottom := Control.new()
	bottom.position = Vector2(8, 274)
	bottom.size = Vector2(528, 134)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.clip_contents = true
	bottom.set_meta("painel", true)
	screen.add_child(bottom)
	_rect(bottom, 0, 0, 528, 134, FILL)
	_rect(bottom, 0, 0, 528, 4, AMBER)
	_rect(bottom, 0, 130, 528, 4, AMBER)
	_label(bottom, "FALLEN acts.", 16, 14, 20)


# ---------- F: foco ----------

func _option_f(screen: Control) -> void:
	_foe(screen, 0, Vector2(214, 22), Vector2(230, 236))
	_rect(screen, 14, 44, 516, 10, Color(0.06, 0.08, 0.07))
	_rect(screen, 15, 45, 330, 8, SP_BLUE)
	_rect(screen, 345, 45, 185, 8, RED)
	_label(screen, "SP 46 / 47", 14, 60, 12)

	var head := _panel(screen, Vector2(452, 6), Vector2(92, 28))
	_label(head, "ROUND 1", 8, 3, 11)

	_label(screen, "FALLEN", 14, 86, 21)
	_label(screen, "HP 14/14", 14, 122, 16)
	_bar(screen, 14, 148, 180, 9, 1.0, GREEN)
	_label(screen, "EN 8/8", 14, 164, 16)
	_bar(screen, 14, 190, 180, 9, 1.0, BLUE)
	_label(screen, "SP 46   A3   S0", 14, 206, 13)

	_label(screen, "FALLEN acts.", 14, 266, 15)
	_rect(screen, 14, 292, 516, 1, BORDER)
	var names: Array[String] = ["ATTACK", "ITEM", "REST", "ABSORB"]
	for i in names.size():
		_label_centered(screen, names[i], 76 + i * 129, 304, 124, 13)


# ---------- A2: minima, comandos na coluna direita ----------

func _option_a2(screen: Control) -> void:
	_foe(screen, 0, Vector2(152, 26), Vector2(240, 246))
	_rect(screen, 0, 0, W, 54, Color(0, 0, 0, 0.82))
	_label(screen, "ROUND 1", 14, 10, 14)
	_label_right(screen, "SP 46 / 47", 530, 11, 13)
	_rect(screen, 14, 36, 516, 1, BORDER)

	_rect(screen, 0, 274, W, 142, Color(0, 0, 0, 0.82))
	_label(screen, "FALLEN acts.", 14, 284, 14)
	_rect(screen, 420, 306, 4, 20, AMBER)
	_label(screen, "ATTACK", 432, 306, 12)
	_label(screen, "ITEM", 432, 328, 12)
	_label(screen, "REST", 432, 350, 12)
	_label(screen, "ABSORB", 432, 372, 12)

	_label(screen, "FALLEN  HP 14/14  EN 8/8", 14, 306, 12)
	_bar(screen, 14, 328, 200, 5, 1.0, GREEN)
	_bar(screen, 220, 328, 120, 5, 1.0, BLUE)
	_label(screen, "SP 46  A3  S0", 14, 336, 12)
	_label(screen, "ALLY  HP 11/11  EN 7/7", 14, 362, 12)
	_bar(screen, 14, 384, 200, 5, 1.0, GREEN)
	_bar(screen, 220, 384, 120, 5, 1.0, BLUE)
	_label(screen, "SP 36  A3  S0", 14, 392, 12)


# ---------- A3: minima, numeros grandes e acento vertical ----------

func _option_a3(screen: Control) -> void:
	_foe(screen, 0, Vector2(160, 30), Vector2(224, 230))
	_rect(screen, 0, 0, W, 54, Color(0, 0, 0, 0.82))
	_label(screen, "ROUND 1", 14, 10, 14)
	_label_right(screen, "SP 46 / 47", 530, 11, 13)
	_rect(screen, 14, 36, 516, 1, BORDER)

	_rect(screen, 0, 274, W, 142, Color(0, 0, 0, 0.55))
	_rect(screen, 12, 282, 3, 120, AMBER)
	_label(screen, "FALLEN acts.", 22, 282, 14)
	_label(screen, "FALLEN", 22, 306, 18)
	_label(screen, "HP 14/14", 22, 336, 14)
	_bar(screen, 22, 360, 180, 7, 1.0, GREEN)
	_label(screen, "EN 8/8", 22, 372, 14)
	_bar(screen, 22, 396, 180, 7, 1.0, BLUE)

	var cmds: Array[String] = ["ATTACK", "ITEM", "REST", "ABSORB"]
	for i in cmds.size():
		_label(screen, cmds[i], 420, 300 + i * 24, 12)


# ---------- B2: visor com SP segmentado horizontal ----------

func _option_b2(screen: Control) -> void:
	_foe(screen, 0, Vector2(167, 26), Vector2(210, 216))
	_reticle(screen, 272, 140, 121, 92)

	var top := _panel(screen, Vector2(8, 6), Vector2(528, 36))
	_label(top, "ROUND 1", 8, 8, 12)
	_label(top, "SP 46 / 47", 440, 8, 12)

	for i in 10:
		_rect(screen, 8 + i * 52, 256, 48, 16, SP_BLUE if i < 4 else RED)

	var left := _panel(screen, Vector2(8, 280), Vector2(260, 128))
	_label(left, "FALLEN   SP 46   A3 S0", 8, 6, 12)
	_bar(left, 8, 28, 244, 8, 1.0, GREEN)
	_bar(left, 8, 40, 244, 8, 1.0, BLUE)
	_label(left, "ALLY   SP 36   A3 S0", 8, 60, 12)
	_bar(left, 8, 82, 244, 8, 1.0, GREEN)
	_bar(left, 8, 94, 244, 8, 1.0, BLUE)

	var right := _panel(screen, Vector2(276, 280), Vector2(260, 128))
	_label(right, "FALLEN acts.", 8, 6, 12)
	var cmds: Array[String] = ["ATTACK", "ITEM", "REST", "ABSORB"]
	for i in cmds.size():
		var x := 8 + (i % 2) * 126
		var y := 34 + (i / 2) * 42
		_rect(right, x, y, 120, 36, Color(0.09, 0.10, 0.09))
		_rect(right, x, y, 120, 2, BORDER)
		_rect(right, x, y + 34, 120, 2, BORDER)
		_rect(right, x, y, 2, 36, BORDER)
		_rect(right, x + 118, y, 2, 36, BORDER)
		_label_centered(right, cmds[i], x + 60, y + 8, 120, 12)


# ---------- B3: visor com dois alvos ----------

func _option_b3(screen: Control) -> void:
	_foe(screen, 1, Vector2(316, 30), Vector2(200, 206))
	_foe(screen, 0, Vector2(104, 30), Vector2(200, 206))
	_reticle(screen, 204, 133, 95, 90)
	_reticle(screen, 416, 133, 95, 90)

	var top := _panel(screen, Vector2(8, 6), Vector2(528, 36))
	_label(top, "ROUND 1", 8, 8, 12)
	_label(top, "SP 46 / 47", 440, 8, 12)

	for i in 10:
		_rect(screen, 8 + i * 52, 258, 48, 14, SP_BLUE if i < 4 else RED)

	var left := _panel(screen, Vector2(8, 290), Vector2(170, 118))
	_label(left, "FALLEN", 8, 6, 12)
	_bar(left, 8, 28, 154, 8, 1.0, GREEN)
	_label(left, "ALLY", 8, 46, 12)
	_bar(left, 8, 68, 154, 8, 1.0, BLUE)
	_label(left, "SP 46 / 36", 8, 88, 11)

	var middle := _panel(screen, Vector2(186, 290), Vector2(172, 118))
	_label(middle, "FALLEN acts.", 8, 6, 13)
	_label(middle, "FOE A  HP 12/13", 8, 36, 11)
	_bar(middle, 8, 56, 156, 8, 0.92, RED)
	_label(middle, "FOE B  HP 15/15", 8, 76, 11)
	_bar(middle, 8, 96, 156, 8, 1.0, RED)

	var right := _panel(screen, Vector2(366, 290), Vector2(170, 118))
	var cmds: Array[String] = ["ATTACK", "ITEM", "REST", "ABSORB"]
	for i in cmds.size():
		var x := 8 + (i % 2) * 82
		var y := 10 + (i / 2) * 48
		_rect(right, x, y, 76, 40, Color(0.09, 0.10, 0.09))
		_rect(right, x, y, 76, 2, BORDER)
		_rect(right, x, y + 38, 76, 2, BORDER)
		_rect(right, x, y, 2, 40, BORDER)
		_rect(right, x + 74, y, 2, 40, BORDER)
		_label_centered(right, cmds[i], x + 38, y + 10, 76, 11)


# ---------- R1: referencia, faixa clara e nomes verticais ----------

func _option_r1(screen: Control) -> void:
	_rect(screen, 0, 0, W, H, MAROON)
	_foe(screen, 0, Vector2(167, 26), Vector2(210, 216))
	_banner(screen, 8, 6, 528, 28, "TURN 1")
	_vertical(screen, "ENEMY", 70, 70, 18, WHITE)
	_vertical(screen, "ENEMY", 456, 70, 18, WHITE)
	_label(screen, "SP METER", 442, 254, 12, GREEN_TEXT)
	_meter(screen, 8, 272, 528, 16, 20, 12)
	_rect(screen, 8, 296, 528, 26, Color(0.45, 0.45, 0.45))
	_rect(screen, 8, 296, 528, 2, Color(0.20, 0.20, 0.20))
	_label(screen, "BATTLE LOG", 14, 300, 12, DARK_TEXT)
	_label(screen, "Fallen acts.", 14, 326, 13, WHITE)
	_stat_panel(screen, 8, 344, 180, 72, "Fallen", "14/14", "8/8", "1")
	_stat_panel(screen, 196, 344, 170, 72, "Ally", "11/11", "7/7", "0")
	var sp := _panel(screen, Vector2(490, 344), Vector2(46, 72))
	_rect(sp, 8, 8, 30, 56, Color(0.06, 0.08, 0.07))
	_rect(sp, 9, 32, 28, 31, RED)
	_label(sp, "SP", 11, 44, 10, WHITE)


# ---------- R2: referencia com nomes sobre o oponente ----------

func _option_r2(screen: Control) -> void:
	_rect(screen, 0, 0, W, H, MAROON)
	_foe(screen, 0, Vector2(150, 24), Vector2(244, 250))
	_banner(screen, 8, 6, 528, 28, "TURN 1")
	_meter(screen, 8, 40, 528, 12, 20, 12)
	_vertical(screen, "ENEMY", 110, 66, 16, WHITE)
	_vertical(screen, "ENEMY", 256, 66, 16, WHITE)
	_vertical(screen, "ENEMY", 402, 66, 16, WHITE)
	_label(screen, "SP METER", 442, 256, 12, GREEN_TEXT)
	_meter(screen, 8, 272, 528, 16, 20, 12)
	_rect(screen, 8, 296, 528, 26, Color(0.45, 0.45, 0.45))
	_rect(screen, 8, 296, 528, 2, Color(0.20, 0.20, 0.20))
	_label(screen, "BATTLE LOG", 14, 300, 12, DARK_TEXT)
	_label(screen, "Fallen acts.", 14, 326, 13, WHITE)
	_stat_panel(screen, 8, 344, 180, 72, "Fallen", "14/14", "8/8", "1")
	_stat_panel(screen, 196, 344, 170, 72, "Ally", "11/11", "7/7", "0")
	var sp := _panel(screen, Vector2(490, 344), Vector2(46, 72))
	_rect(sp, 8, 8, 30, 56, Color(0.06, 0.08, 0.07))
	_rect(sp, 9, 20, 28, 43, RED)


# ---------- R3: referencia com dois oponentes ----------

func _option_r3(screen: Control) -> void:
	_rect(screen, 0, 0, W, H, MAROON)
	_foe(screen, 1, Vector2(310, 30), Vector2(200, 206))
	_foe(screen, 0, Vector2(70, 30), Vector2(200, 206))
	_banner(screen, 8, 6, 528, 28, "TURN 1")
	_vertical(screen, "ENEMY", 118, 44, 15, WHITE)
	_vertical(screen, "ENEMY", 358, 44, 15, WHITE)
	_label(screen, "SP METER", 442, 252, 12, GREEN_TEXT)
	_meter(screen, 8, 270, 528, 16, 20, 12)
	_rect(screen, 8, 294, 528, 26, Color(0.45, 0.45, 0.45))
	_rect(screen, 8, 294, 528, 2, Color(0.20, 0.20, 0.20))
	_label(screen, "BATTLE LOG", 14, 298, 12, DARK_TEXT)
	_label(screen, "Fallen acts.", 14, 324, 13, WHITE)
	_stat_panel(screen, 8, 342, 180, 74, "Fallen", "14/14", "8/8", "1")
	_stat_panel(screen, 196, 342, 170, 74, "Ally", "11/11", "7/7", "0")
	var sp := _panel(screen, Vector2(490, 342), Vector2(46, 74))
	_rect(sp, 8, 8, 30, 58, Color(0.06, 0.08, 0.07))
	_rect(sp, 9, 28, 28, 37, RED)
	_label(sp, "SP", 11, 46, 10, WHITE)


# ---------- V1: anel de SP ao redor do oponente ----------

func _option_v1(screen: Control) -> void:
	_rect(screen, 0, 0, W, H, MAROON)
	_foe(screen, 0, Vector2(172, 36), Vector2(200, 206))

	var chip := _panel(screen, Vector2(8, 6), Vector2(74, 26))
	_rect(chip, 2, 2, 70, 22, LIGHT)
	_label(chip, "TURN 1", 6, 2, 12, DARK_TEXT)

	for i in 24:
		var a := TAU * float(i) / 24.0 - PI / 2.0
		var x := 272.0 + cos(a) * 120.0 - 5.0
		var y := 150.0 + sin(a) * 110.0 - 3.0
		_rect(screen, x, y, 10, 6, GREEN if i < 14 else RED)

	_label_centered(screen, "GENETIC FOE A", 272, 250, 300, 14, WHITE)
	for j in 3:
		_rect(screen, 428 + j * 2, 182 + j * 7, 14 - j * 4, 3, GREEN_TEXT)
		_rect(screen, 102 + j * 2, 182 + j * 7, 14 - j * 4, 3, RED)

	_rect(screen, 8, 286, 528, 24, Color(0.45, 0.45, 0.45))
	_label(screen, "Fallen acts.", 14, 290, 12, DARK_TEXT)
	_label(screen, "FALLEN  HP 14/14  EN 8/8  SP 46  A3 S0", 14, 322, 12, WHITE)
	_bar(screen, 14, 344, 240, 6, 1.0, GREEN)
	_bar(screen, 260, 344, 120, 6, 1.0, BLUE)
	_label(screen, "ALLY  HP 11/11  EN 7/7  SP 36  A3 S0", 14, 360, 12, WHITE)
	_bar(screen, 14, 382, 240, 6, 1.0, GREEN)
	_bar(screen, 260, 382, 120, 6, 1.0, BLUE)


# ---------- V2: torres de SP nas laterais ----------

func _option_v2(screen: Control) -> void:
	_rect(screen, 0, 0, W, H, MAROON)
	_foe(screen, 0, Vector2(172, 30), Vector2(200, 206))

	var chip := _panel(screen, Vector2(462, 6), Vector2(74, 26))
	_rect(chip, 2, 2, 70, 22, LIGHT)
	_label(chip, "TURN 1", 6, 2, 12, DARK_TEXT)

	for i in 16:
		_rect(screen, 54, 200 - i * 10, 18, 8, GREEN)
		_rect(screen, 472, 200 - i * 10, 18, 8, RED)
	_label(screen, "^", 58, 34, 15, GREEN_TEXT)
	_label(screen, "v", 476, 210, 15, RED)

	_label_centered(screen, "GENETIC FOE A", 272, 10, 260, 14, WHITE)
	_rect(screen, 8, 244, 528, 24, Color(0.45, 0.45, 0.45))
	_label(screen, "Fallen acts.", 14, 248, 12, DARK_TEXT)

	_label(screen, "FALLEN  SP 46  A3", 14, 282, 12, WHITE)
	_bar(screen, 14, 302, 500, 10, 1.0, GREEN)
	_label(screen, "ALLY  SP 36  A3", 14, 320, 12, WHITE)
	_bar(screen, 14, 340, 500, 10, 1.0, BLUE)
	_label(screen, "HP 14/14   EN 8/8", 14, 364, 12, WHITE)
	_label(screen, "HP 11/11   EN 7/7", 14, 384, 12, WHITE)


# ---------- V3: faixa superior espessa e oponente deslocado ----------

func _option_v3(screen: Control) -> void:
	_rect(screen, 0, 0, W, H, MAROON)
	_foe(screen, 0, Vector2(290, 40), Vector2(210, 216))

	_rect(screen, 0, 0, W, 46, Color(0.12, 0.10, 0.10))
	_rect(screen, 0, 44, W, 2, BORDER)
	_rect(screen, 0, 8, 330, 14, GREEN)
	_rect(screen, 330, 8, 214, 14, RED)
	_label(screen, "1", 12, 6, 16, DARK_TEXT)

	_label(screen, "FALLEN  HP 14/14", 14, 80, 13, WHITE)
	_bar(screen, 14, 104, 170, 8, 1.0, GREEN)
	_label(screen, "EN 8/8", 14, 120, 13, WHITE)
	_bar(screen, 14, 144, 170, 8, 1.0, BLUE)
	_label(screen, "SP 46  A3", 14, 164, 13, WHITE)
	_label(screen, "ALLY  SP 36", 14, 196, 13, WHITE)

	_label(screen, "GENETIC FOE A", 292, 262, 13, WHITE)
	_rect(screen, 14, 286, 516, 1, BORDER)
	_label(screen, "Fallen acts.", 14, 296, 14, WHITE)
	var cmds: Array[String] = ["ATTACK", "ITEM", "REST", "ABSORB"]
	for i in cmds.size():
		_label_centered(screen, cmds[i], 76 + i * 129, 332, 124, 12)
