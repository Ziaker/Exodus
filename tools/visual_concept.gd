extends SceneTree

## Proposta visual unica para o Exodus.
## Premissa canonica: mar de areia branca sob ceu vermelho-escuro.
## Regra D-003: nenhum asset da fangame. Oponente e fundo sao desenhados em
## codigo; o HUD e baseado nos sistemas do jogo (SP, atos, reacao, ritmo).
## A captura so e salva se a validacao nao acusar nenhum erro de layout.

const W := 544.0
const H := 416.0
const OUTPUT := "res://captures/concept_exodus.png"

const SKY_TOP := Color(0.20, 0.07, 0.08)
const SKY_BOT := Color(0.48, 0.16, 0.13)
const SAND := Color(0.80, 0.78, 0.72)
const SPIRE := Color(0.10, 0.06, 0.07)
const BODY := Color(0.07, 0.05, 0.07)
const EYE := Color(0.95, 0.25, 0.18)
const ACCENT := Color(0.55, 0.10, 0.10)
const LIGHT := Color(0.82, 0.84, 0.85)
const DARK := Color(0.10, 0.10, 0.10)
const GREEN := Color(0.20, 0.78, 0.36)
const RED := Color(0.85, 0.22, 0.22)
const BLUE := Color(0.25, 0.55, 0.95)
const AMBER := Color(0.90, 0.70, 0.20)
const WHITE := Color(0.95, 0.95, 0.95)

const DEMON := [
	"......##........##......",
	".....####......####.....",
	".....####......####.....",
	"......##........##......",
	".......##########.......",
	".....##############.....",
	"....################....",
	"....###ee######ee###....",
	"....################....",
	".....##############.....",
	".....####rrrrrr####.....",
	"......############......",
	"......############......",
	".......##########.......",
	".......##########.......",
	".......###....###.......",
	"......####....####......",
	"......####....####......",
	".....#####....#####.....",
	".....####......####.....",
	"....###..........###....",
	"....##............##....",
]


func _initialize() -> void:
	var screen := Control.new()
	screen.position = Vector2.ZERO
	screen.size = Vector2(W, H)
	root.add_child(screen)
	_world(screen)
	_opponent(screen)
	_hud(screen)
	for _i in 3:
		await process_frame
	var errors := _validate(screen)
	if errors.is_empty():
		var image: Image = root.get_texture().get_image()
		image.save_png(ProjectSettings.globalize_path(OUTPUT))
		print("OK ", OUTPUT, " - 0 erros de layout")
	else:
		for e in errors:
			push_error(e)
	quit(0 if errors.is_empty() else 1)


# ---------- Mundo original (sem assets da fangame) ----------

func _world(parent: Control) -> void:
	var bands := 10
	for i in bands:
		var t := float(i) / float(bands - 1)
		var c := SKY_TOP.lerp(SKY_BOT, t)
		_rect(parent, 0, i * 21, W, 21, c)
	_rect(parent, 0, 210, W, H - 210, SAND)
	# Espiras na linha do horizonte.
	for spec in [[40, 26, 16], [124, 40, 12], [404, 34, 14], [486, 24, 18]]:
		_rect(parent, spec[0], 210 - spec[1], spec[2], spec[1], SPIRE)
	# Velo escuro para manter o HUD legvel sobre a areia.
	_rect(parent, 0, 276, W, H - 276, Color(0, 0, 0, 0.78))


func _opponent(parent: Control) -> void:
	var scale := 8.0
	var x0 := 176.0
	var y0 := 54.0
	for row in DEMON.size():
		var line: String = DEMON[row]
		for col in line.length():
			var ch := line.substr(col, 1)
			if ch == ".":
				continue
			var color := BODY
			if ch == "e":
				color = EYE
			elif ch == "r":
				color = ACCENT
			_rect(parent, x0 + col * scale, y0 + row * scale, scale, scale, color)


# ---------- HUD ancorado nos sistemas do jogo ----------

func _hud(parent: Control) -> void:
	# Turno e atos disponiveis no canto superior direito (Press Turn).
	var chip := _panel(parent, Vector2(458, 8), Vector2(78, 26))
	_rect(chip, 2, 2, 74, 22, LIGHT)
	_label(chip, "TURN 1", 6, 2, 12, DARK)
	for i in 3:
		_rect(parent, 460 + i * 18, 38, 14, 6, GREEN)

	# Medidor de SP: disputa entre Fallen (verde) e inimigos (vermelho),
	# com marca do limiar de 70% que concede +1 ato.
	for i in 16:
		_rect(parent, 40 + i * 13, 252, 11, 12, GREEN)
		_rect(parent, 493 - i * 13, 252, 11, 12, RED)
	_rect(parent, 264, 246, 2, 24, AMBER)
	_rect(parent, 278, 246, 2, 24, AMBER)
	_label_centered(parent, "SP", 272, 232, 40, 11, WHITE)
	_label(parent, "FALLEN", 40, 268, 11, GREEN)
	_label_right(parent, "FOES", 504, 268, 11, RED)

	# Log de batalha com uma unica linha e sublinhado.
	_label(parent, "Fallen acts.", 14, 286, 14, WHITE)
	_rect(parent, 14, 304, 200, 1, AMBER)

	# Estado compacto: HP/EN, SP e atos.
	_label(parent, "FALLEN  HP 14/14  EN 8/8  SP 46  A3  S0", 14, 314, 12, WHITE)
	_bar(parent, 14, 336, 200, 6, 1.0, GREEN)
	_bar(parent, 220, 336, 120, 6, 1.0, BLUE)
	_label(parent, "ALLY  HP 11/11  EN 7/7  SP 36  A3  S0", 14, 352, 12, WHITE)
	_bar(parent, 14, 374, 200, 6, 1.0, GREEN)
	_bar(parent, 220, 374, 120, 6, 1.0, BLUE)

	# Comandos na base, com cursor.
	_rect(parent, 14, 392, 4, 12, AMBER)
	_label(parent, "ATTACK    ITEM    REST    ABSORB", 24, 390, 12, WHITE)


# ---------- Validacao ----------

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
	_rect(p, 0, 0, size.x, size.y, Color(0.16, 0.17, 0.16, 1.0))
	return p


func _measure(text: String, font_size: int, font: Font = null) -> Vector2:
	var used: Font = font if font != null else ThemeDB.fallback_font
	return used.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, float(font_size))


func _label(parent: Control, text: String, x: float, y: float, font_size: int,
		color: Color) -> Label:
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


func _label_centered(parent: Control, text: String, cx: float, y: float,
		width: float, font_size: int, color: Color) -> Label:
	var need := _measure(text, font_size)
	return _label(parent, text, cx - need.x / 2.0, y, font_size, color)


func _label_right(parent: Control, text: String, right_x: float, y: float,
		font_size: int, color: Color) -> Label:
	var need := _measure(text, font_size)
	return _label(parent, text, right_x - need.x, y, font_size, color)


func _bar(parent: Control, x: float, y: float, w: float, h: float,
		ratio: float, color: Color) -> void:
	_rect(parent, x, y, w, h, Color(0.06, 0.08, 0.07))
	_rect(parent, x + 1, y + 1, (w - 2) * clampf(ratio, 0.0, 1.0), h - 2, color)


func _validate(screen: Control) -> Array[String]:
	var errors: Array[String] = []
	_check(screen, errors, null)
	return errors


func _check(node: Node, errors: Array[String], panel: Control) -> void:
	if node is Label:
		var label := node as Label
		var size := label.get_theme_font_size("font_size")
		var a := _measure(label.text, size, label.get_theme_font("font"))
		var b := _measure(label.text, size, ThemeDB.fallback_font)
		if maxf(a.x, b.x) > label.size.x + 1.0 or maxf(a.y, b.y) > label.size.y + 1.0:
			errors.append("TEXTO VAZANDO: '%s'" % label.text)
	if node is Control:
		var rect := (node as Control).get_global_rect()
		if rect.position.x < -1.0 or rect.position.y < -1.0 \
			or rect.end.x > W + 1.0 or rect.end.y > H + 1.0:
			errors.append("FORA DA TELA: %s %s" % [node.name, rect])
		if panel != null and node != panel and not panel.get_global_rect().encloses(rect):
			errors.append("VAZAMENTO DE PAINEL: %s" % node.name)
	var next_panel := panel
	if node is Control and (node as Control).has_meta("painel"):
		next_panel = node as Control
	for child in node.get_children():
		_check(child, errors, next_panel)
