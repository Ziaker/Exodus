extends Node2D
## PROTOTYPE (criador 2026-11-26): transição do título para o início do Survival, com o
## anjo da 1ª dungeon (Kazfiel, Preguiça — ordem e pecado aprovados em
## docs/plans/2026-11-25-survival-roguelike.md, itens 11 e 15) falando com o jogador.
## Quatro encenações para o criador escolher; teclas 1/2/3/4 trocam e reiniciam,
## argumento de usuário --opt=a|b|c|d escolhe a inicial. R reinicia. Em todas, Z mostra a
## fala inteira e, com ela completa, pula para a próxima (criador 2026-11-26).
##   A  PÁLPEBRA  — o jogador acorda; pisca cada vez mais devagar enquanto o anjo fala;
##                  o texto "adormece" (as letras caem); fecha os olhos e acorda na dungeon.
##   B  SATURNO   — Kazfiel (anjo de Saturno, o tempo) no centro de um mostrador com os
##                  8 chefes; areia branca cai como numa ampulheta, cobre a tela e se
##                  desfaz grão a grão revelando a dungeon.
##   C  CORREDOR  — primeira pessoa num corredor que nunca chega ao fim; o anjo, lá no
##                  fundo, nunca fica mais perto — até aparecer colado na câmera; as asas
##                  se abrem e as penas douradas caem revelando a dungeon.
##   D  A + B HEBRAICO (criador 2026-11-26: "texto animado do A, visual do B, estética
##                  hebraica, anjo amarelo feito de letras") — letras hebraicas soltas no
##                  escuro voam e formam o Kazfiel amarelo, o mostrador e a moldura da caixa
##                  (como no prólogo); a fala adormece como na A; a areia que cai
##                  e cobre a tela é feita de letras, que se desfazem revelando a dungeon.
## Falas, tempos, cores, tamanhos e formas são PLACEHOLDER do protótipo, nenhum é decisão.

const W := 816.0
const H := 624.0
const KAZFIEL_ART := "res://assets/graphics/battlers/Herald Kazfiel.png"
## Quadro do início real do Survival (gerado por tools/capture_survival_intro.gd).
const DUNGEON_ART := "res://prototypes/survival-intro/art/dungeon_start.png"

## Paleta da folha de direção de arte (ocre/rubro).
const OCRE := Color("b17a35")
const FERRUGEM := Color("8a5b33")
const RUBRO := Color("6e1817")
const VINHO := Color("351216")
const AMEIXA := Color("1c0e11")
const NEVOA := Color("c6a17e")
const AREIA := Color("e8e0d0")
const OURO := Color("f2d34b")
const INK := Color("f7f3ed")

## Caixa de diálogo no mesmo estilo P&B da exploração (scripts/ui/dialogue_box.gd).
const BOX := Rect2(6, 502, 804, 116)
## Criador 2026-11-26: o nome do anjo aparece em hebraico. Grafia da angelologia para
## Kafziel/Qafsiel (קפציאל), confirmada pelo criador em 2026-11-26.
const ANGEL_NAME := "קפציאל"
const SPEAKER := ANGEL_NAME
## Criador 2026-11-26: TODO texto do Survival em inglês. Falas PLACEHOLDER (o criador
## escreve as definitivas); %n é o nome do anjo em hebraico.
const LINES := [
	"Hm... another one who cannot stay lying down.",
	"I am %n. I keep the first of the eight gates: the gate of Sloth.",
	"Go down, if you insist. Down there no one hurries... and no one returns.",
]
const BOSSES := [ANGEL_NAME, "ZAPHKIEL · TZAPHKIEL", "OPHANIEL", "ANIEL", "URIEL", "RAPHAEL", "MICHAEL", "GABRIEL"]
const NUMERALS := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"]

## Linha do tempo de cada opção: início/fim de cada fala, início do desfecho, momento em
## que a dungeon aparece e fim do loop (segundos).
const TIMING := {
	"a": {"lines": [[3.6, 9.0], [10.2, 15.4], [17.6, 23.8]], "outro": 24.0, "dungeon": 27.6, "end": 32.0},
	"b": {"lines": [[2.6, 8.0], [8.6, 14.0], [14.6, 20.6]], "outro": 21.0, "dungeon": 24.6, "end": 31.0},
	"c": {"lines": [[2.2, 7.6], [8.2, 13.6], [15.4, 21.2]], "outro": 21.6, "dungeon": 23.0, "end": 28.0},
	"d": {"lines": [[5.8, 11.8], [12.4, 18.6], [19.2, 25.6]], "outro": 26.0, "dungeon": 29.9, "end": 35.0},
}
const TYPE_SPEED := 34.0
const SLEEPY_SPEED := 17.0

var option := "a"
var t := 0.0
## Captura: o tempo não avança sozinho.
var frozen := false
var font: SystemFont
var bold: SystemFont
var kazfiel: Texture2D
var dungeon: Texture2D
var rng := RandomNumberGenerator.new()
## Z: fala em que o texto foi mostrado inteiro e em que idade da fala isso aconteceu.
var skip_line := -1
var skip_age := INF
var sand: Array[Dictionary] = []
var dissolve_order := PackedInt32Array()
var feathers: Array[Dictionary] = []
const CELL := 12


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Tahoma", "Arial", "sans-serif"])
	bold = SystemFont.new()
	bold.font_names = font.font_names
	bold.font_weight = 700
	kazfiel = _load_sprite(KAZFIEL_ART)
	var shot := Image.load_from_file(ProjectSettings.globalize_path(DUNGEON_ART))
	if shot != null and not shot.is_empty():
		dungeon = ImageTexture.create_from_image(shot)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--opt="):
			option = arg.trim_prefix("--opt=")
	restart()


## O battler do SMT vem num painel opaco de 3 tons (borda clara em cima/esquerda, miolo
## verde-acinzentado, borda escura embaixo/direita) com uma sombra preta no chão. Some
## tudo o que for dessas cores e estiver ligado à borda; a sombra (linhas abaixo da figura,
## que termina na linha 158 do arquivo) sai inteira; depois recorta no que sobrou.
const PANEL := [Color8(128, 152, 144), Color8(96, 120, 112), Color8(24, 24, 24)]
const SHADOW_FROM_ROW := 168
## Canto do recorte dentro do arquivo original (para achar o rosto depois do recorte).
var sprite_offset := Vector2.ZERO


func _is_panel(c: Color) -> bool:
	for p in PANEL:
		if absf(c.r - p.r) < 0.01 and absf(c.g - p.g) < 0.01 and absf(c.b - p.b) < 0.01:
			return true
	return false


func _load_sprite(path: String) -> Texture2D:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var stack: Array[Vector2i] = []
	for x in w:
		stack.append(Vector2i(x, 0)); stack.append(Vector2i(x, h - 1))
	for y in h:
		stack.append(Vector2i(0, y)); stack.append(Vector2i(w - 1, y))
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h: continue
		var i := p.y * w + p.x
		if seen[i] == 1: continue
		if not _is_panel(img.get_pixelv(p)): continue
		seen[i] = 1
		img.set_pixelv(p, Color(0, 0, 0, 0))
		stack.append(p + Vector2i.RIGHT); stack.append(p + Vector2i.LEFT)
		stack.append(p + Vector2i.DOWN); stack.append(p + Vector2i.UP)
	for y in range(mini(SHADOW_FROM_ROW, h), h):
		for x in w:
			img.set_pixel(x, y, Color(0, 0, 0, 0))
	var used := img.get_used_rect()
	sprite_offset = Vector2(used.position)
	return ImageTexture.create_from_image(img.get_region(used))


func restart() -> void:
	t = 0.0
	skip_line = -1
	skip_age = INF
	rng.seed = 26
	sand.clear()
	for i in 520:
		sand.append({"x": rng.randf_range(0, W), "phase": rng.randf(), "speed": rng.randf_range(0.55, 1.0),
			"drift": rng.randf_range(-12, 12), "size": rng.randf_range(1.0, 2.6)})
	var cells := int(ceil(W / CELL)) * int(ceil(H / CELL))
	var order := range(cells)
	order.shuffle()
	dissolve_order = PackedInt32Array(order)
	_build_hebrew()
	feathers.clear()
	for i in 260:
		var a := rng.randf_range(0, TAU)
		feathers.append({"dir": Vector2.from_angle(a) * rng.randf_range(160, 760), "delay": rng.randf_range(0.0, 0.7),
			"spin": rng.randf_range(-4, 4), "len": rng.randf_range(14, 34), "sway": rng.randf_range(0, TAU),
			"gold": rng.randf() < 0.55, "fall": rng.randf_range(60, 140)})


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo): return
	match event.keycode:
		KEY_1: option = "a"; restart()
		KEY_2: option = "b"; restart()
		KEY_3: option = "c"; restart()
		KEY_4: option = "d"; restart()
		KEY_R: restart()
		KEY_Z, KEY_ENTER, KEY_SPACE:
			skip_text()


## Z (criador 2026-11-26): com a fala ainda sendo escrita, mostra ela inteira; com ela
## completa, pula para a próxima fala (ou para o desfecho, depois da última).
func skip_text() -> void:
	var active := _active_line()
	if active.x < 0: return
	var index := int(active.x)
	if skip_line != index:
		skip_line = index
		skip_age = INF
	if active.y < _type_time(index) and skip_age == INF:
		skip_age = active.y
		return
	var spans: Array = _timing().lines
	t = float(spans[index + 1][0]) if index + 1 < spans.size() else float(_timing().outro)
	skip_line = -1
	skip_age = INF


## Segundos que a fala `index` leva para ser escrita sem pular.
func _type_time(index: int) -> float:
	return _line_text(index).length() / (SLEEPY_SPEED if option in ["a", "d"] else TYPE_SPEED)


## Texto lógico da fala (o hebraico na ordem de leitura).
func _line_text(index: int) -> String:
	var text: String = d_lines[index] if option == "d" else LINES[index]
	return text.replace("%n", ANGEL_NAME)


## No jogo (scripts/survival/survival_intro_cutscene.gd) a etiqueta do protótipo some.
var show_label := true


func _process(delta: float) -> void:
	if frozen: return
	t += delta
	if t >= _timing().end:
		restart()
	queue_redraw()


func _timing() -> Dictionary:
	return TIMING[option]


func _ease(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


func _phase(a: float, b: float) -> float:
	return clampf((t - a) / (b - a), 0.0, 1.0)


func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color.BLACK)
	match option:
		"b": _draw_saturn()
		"c": _draw_corridor()
		"d": _draw_hebrew()
		_: _draw_eyelid()
	if not show_label: return
	draw_string(font, Vector2(8, 14), "PROTOTYPE  survival intro  option %s  (1/2/3/4 switch, R restart, Z skip text)" % option.to_upper(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.4))


# --- comum ---------------------------------------------------------------------------

func _draw_sky(top: Color, mid: Color, bottom: Color, alpha := 1.0) -> void:
	var bands := 48
	for i in bands:
		var f := float(i) / bands
		var c := top.lerp(mid, f * 2.0) if f < 0.5 else mid.lerp(bottom, (f - 0.5) * 2.0)
		c.a = alpha
		draw_rect(Rect2(0, H * f, W, H / bands + 1), c)


func _draw_fog(strength: float) -> void:
	# faixas de névoa da largura da tela, com borda suave (sem pontas retas)
	for i in 4:
		var y := 150.0 + i * 82.0 + sin(t * 0.21 + i * 1.7) * 18.0
		var thick := 9 + i * 2
		for j in thick:
			var a := sin(PI * (j + 0.5) / thick)
			draw_rect(Rect2(0, y + j * 3.0, W, 3.0), Color(NEVOA, 0.03 * a * strength))


func _draw_kazfiel(center: Vector2, scale: float, alpha := 1.0, tint := Color.WHITE) -> void:
	if kazfiel == null: return
	var size := kazfiel.get_size() * scale
	draw_texture_rect(kazfiel, Rect2(center - size * 0.5, size), false, Color(tint, alpha))


func _draw_dungeon(alpha: float) -> void:
	if dungeon == null:
		draw_rect(Rect2(0, 0, W, H), Color(0.2, 0.05, 0.05, alpha))
		draw_string(font, Vector2(20, 300), "missing prototypes/survival-intro/art/dungeon_start.png", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, alpha))
		return
	draw_texture_rect(dungeon, Rect2(0, 0, W, H), false, Color(1, 1, 1, alpha))


## Índice e progresso da fala ativa; -1 fora das falas.
func _active_line() -> Vector2:
	var lines: Array = _timing().lines
	for i in lines.size():
		var span: Array = lines[i]
		if t >= span[0] and t < span[1]:
			return Vector2(i, t - span[0])
	return Vector2(-1, 0)


func _draw_box(alpha := 1.0, droop := false, frame := true) -> void:
	var active := _active_line()
	if active.x < 0 or alpha <= 0.0: return
	var age := active.y
	var span: Array = _timing().lines[int(active.x)]
	var fade := clampf(age / 0.2, 0, 1) * clampf((span[1] - t) / 0.25, 0, 1) * alpha
	# sem moldura (opção D) o fundo da caixa é desenhado pelo dono, por baixo das letras
	if frame:
		draw_rect(BOX, Color(0, 0, 0, fade))
		draw_rect(Rect2(BOX.position + Vector2(0.5, 0.5), BOX.size - Vector2.ONE), Color(1, 1, 1, 0.58 * fade), false, 1)
	draw_string(bold, BOX.position + Vector2(15, 30), SPEAKER, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(Color.WHITE, fade))
	var index := int(active.x)
	var text := _line_text(index)
	var speed := SLEEPY_SPEED if droop else TYPE_SPEED
	var skipped := skip_line == index and skip_age != INF
	var chars := text.length() if skipped else int(age * speed)
	var lines := _wrap(text, BOX.size.x - 30)
	var origin := BOX.position + Vector2(15, 60)
	var before := 0
	for li in lines.size():
		var line: String = lines[li]
		var shown_count := clampi(chars - before, 0, line.length())
		if shown_count <= 0: break
		if droop:
			_draw_drooping(line, shown_count, before, origin + Vector2(0, li * 30), age, speed, skip_age if skipped else INF, fade)
		else:
			draw_string(font, origin + Vector2(0, li * 30), line.substr(0, shown_count), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(INK, fade))
		before += line.length() + 1
	if chars >= text.length():
		var tip := Vector2(BOX.end.x - 20.0, BOX.end.y - 14.0) + Vector2(0, sin(t * 4.0) * 2.0)
		draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(9, 0), tip + Vector2(4.5, 6)]), Color(INK, fade))


func _is_hebrew(ch: String) -> bool:
	var c := ch.unicode_at(0)
	return c >= 0x0590 and c <= 0x05FF


## Ordem visual da linha: índices lógicos na ordem em que são desenhados da esquerda para
## a direita (cada trecho de letras hebraicas é invertido, pois se lê da direita).
func _visual_order(line: String) -> PackedInt32Array:
	var order := PackedInt32Array()
	var i := 0
	while i < line.length():
		if _is_hebrew(line[i]):
			var j := i
			while j < line.length() and _is_hebrew(line[j]):
				j += 1
			for k in range(j - 1, i - 1, -1):
				order.append(k)
			i = j
		else:
			order.append(i)
			i += 1
	return order


## Opções A e D: cada letra, depois de escrita, vai "pegando no sono" e afunda devagar.
## `skip_at`: momento em que o Z mostrou a fala inteira (as letras ainda não escritas
## contam como escritas nesse instante).
func _draw_drooping(line: String, shown_count: int, before: int, base: Vector2, age: float, speed: float, skip_at: float, fade: float) -> void:
	var x := base.x
	for li in _visual_order(line):
		var ch := line[li]
		var w := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		if li >= shown_count:
			x += w
			continue
		var typed_at := minf(float(before + li) / speed, skip_at)
		var sleep := maxf(0.0, age - typed_at - 1.2)
		var sink := minf(9.0, sleep * sleep * 1.4)
		var tilt := minf(0.16, sleep * 0.05) * (1.0 if (before + li) % 2 == 0 else -0.6)
		draw_set_transform(Vector2(x, base.y + sink), tilt)
		draw_string(font, Vector2.ZERO, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(INK, fade * (1.0 - minf(0.45, sleep * 0.08))))
		x += w
	draw_set_transform(Vector2.ZERO)


func _wrap(text: String, width: float) -> Array[String]:
	var out: Array[String] = []
	var current := ""
	for word in text.split(" ", false):
		var trial := word if current.is_empty() else current + " " + word
		if current.is_empty() or font.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x <= width:
			current = trial
		else:
			out.append(current)
			current = word
	if not current.is_empty():
		out.append(current)
	return out


# --- A: PÁLPEBRA ---------------------------------------------------------------------

## Abertura dos olhos (0 fechado, 1 aberto) ao longo do tempo.
func _eye_open() -> float:
	var d: float = _timing().dungeon
	if t < 3.0: return _ease(t / 3.0) * 0.85 if t > 0.6 else 0.0
	if t < 9.4: return 0.85 + 0.15 * _ease((t - 3.0) / 2.0)
	# piscada rápida entre as falas 1 e 2
	if t < 10.2: return 1.0 - sin(_phase(9.4, 10.2) * PI) * 1.0
	if t < 15.6: return 1.0
	# piscada pesada (fecha, fica, abre devagar)
	if t < 17.6:
		var p := _phase(15.6, 17.6)
		return 1.0 - (_ease(p / 0.3) if p < 0.3 else (1.0 if p < 0.55 else 1.0 - _ease((p - 0.55) / 0.45) * 0.92))
	if t < 24.0: return 0.92 - 0.12 * _ease(_phase(19.0, 24.0))
	# fecha de vez
	if t < 26.6: return 0.8 * (1.0 - _ease(_phase(24.0, 26.6)))
	if t < d: return 0.0
	# acorda na dungeon
	return _ease(_phase(d, d + 2.4))


func _draw_eyelid() -> void:
	var d: float = _timing().dungeon
	if t < d:
		_draw_sky(RUBRO, VINHO, AMEIXA)
		_draw_fog(1.0)
		# Kazfiel flutua devagar, quase parando
		var bob := sin(t * TAU / 9.0) * 7.0
		_draw_kazfiel(Vector2(408, 250 + bob), 2.0)
	else:
		_draw_dungeon(1.0)
	var open := _eye_open()
	# vista turva quando o olho está meio fechado
	if open < 1.0:
		draw_rect(Rect2(0, 0, W, H), Color(AMEIXA, (1.0 - open) * 0.45))
	_draw_lids(open)
	# a caixa é interface: fica por cima da pálpebra, para a fala nunca ser cortada
	if t < d:
		_draw_box(1.0, true)
	if t >= 26.6 and t < d:
		var a := _phase(26.6, 27.0) * (1.0 - _phase(27.2, d))
		draw_string(font, Vector2(0, 318), "...", HORIZONTAL_ALIGNMENT_CENTER, W, 20, Color(INK, a * 0.6))


## Pálpebras: borda em arco de elipse larga que desce de cima e sobe de baixo. Desenhadas
## em faixas verticais (polígono côncavo dava erro de triangulação). Com open = 1 as duas
## saem inteiras da tela, inclusive nos cantos.
func _draw_lids(open: float) -> void:
	if open >= 1.0: return
	var half := H * 0.5
	var k := 1.6
	var reach := (half + 4.0) / sqrt(1.0 - 1.0 / (k * k))
	var strips := 102
	var sw := W / strips
	for i in strips:
		var u := ((i + 0.5) * sw - W * 0.5) / (W * 0.5 * k)
		var lift := reach * open * sqrt(1.0 - u * u)
		var edge := maxf(0.0, half - lift)
		if edge > 0.0:
			draw_rect(Rect2(i * sw - 0.5, 0, sw + 1.0, edge), Color.BLACK)
			draw_rect(Rect2(i * sw - 0.5, H - edge, sw + 1.0, edge), Color.BLACK)


# --- B: SATURNO ----------------------------------------------------------------------

func _draw_saturn() -> void:
	var o: float = _timing().outro
	var d: float = _timing().dungeon
	if t >= d:
		_draw_dungeon(1.0)
		_draw_sand_dissolve(_phase(d, d + 3.0))
		return
	_draw_sky(AMEIXA, VINHO, Color(0.08, 0.03, 0.04))
	var center := Vector2(408, 250)
	var intro := _ease(_phase(0.3, 2.4))
	# o mostrador gira devagar; no desfecho ele trava com KAZFIEL no alto
	var spin := t * 0.06
	if t >= o:
		spin = lerpf(o * 0.06, ceil(o * 0.06 / TAU) * TAU, _ease(_phase(o, o + 1.4)))
	var r := 196.0
	draw_arc(center, r + 26, 0, TAU, 96, Color(OCRE, 0.6 * intro), 1.0)
	draw_arc(center, r - 26, 0, TAU, 96, Color(OCRE, 0.6 * intro), 1.0)
	draw_arc(center, r - 34, 0, TAU, 96, Color(FERRUGEM, 0.25 * intro), 1.0)
	for k in 64:
		var a := spin + TAU * k / 64.0 - PI * 0.5
		var long := k % 8 == 0
		draw_line(center + Vector2.from_angle(a) * (r + (14 if long else 20)), center + Vector2.from_angle(a) * (r + 26), Color(OCRE, (0.8 if long else 0.35) * intro), 1.0)
	for i in 8:
		var a := spin + TAU * i / 8.0 - PI * 0.5 + TAU / 16.0 * 0.0
		var lit := i == 0
		var dim := 1.0 - _phase(o + 0.8, o + 2.0) if not lit else 1.0
		var pos := center + Vector2.from_angle(a) * r
		draw_set_transform(pos, a + PI * 0.5)
		var name_px := 13 if not lit else 15
		var col := OURO if lit else Color(NEVOA, 0.62)
		col.a *= intro * dim
		draw_string(bold if lit else font, Vector2(-120, 5), BOSSES[i], HORIZONTAL_ALIGNMENT_CENTER, 240, name_px, col)
		draw_string(font, Vector2(-30, -14), NUMERALS[i], HORIZONTAL_ALIGNMENT_CENTER, 60, 10, Color(col, col.a * 0.8))
		draw_set_transform(Vector2.ZERO)
	# ponteiro fixo apontando para o alto
	var hand := Color(OURO, 0.7 * intro)
	draw_line(center + Vector2(0, -r + 34), center + Vector2(0, -r + 14), hand, 2.0)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-6, -r + 34), center + Vector2(6, -r + 34), center + Vector2(0, -r + 44)]), hand)
	# Kazfiel no centro, respirando devagar
	var breathe := 1.0 + sin(t * TAU / 6.0) * 0.015
	_draw_kazfiel(center + Vector2(0, 6), 1.45 * breathe, intro)
	_draw_falling_sand(o, d)
	_draw_box(1.0, false)


## Areia branca cai o tempo todo e se acumula no chão; no desfecho vira cascata e cobre
## a tela inteira (a ampulheta vira).
func _draw_falling_sand(o: float, d: float) -> void:
	var pour := _ease(_phase(o + 1.6, d))
	var pile := lerpf(minf(t, o) * 2.2, H + 10.0, pour)
	var floor_y := H - pile
	var density := 0.25 + 0.75 * _phase(o, o + 1.6)
	for i in sand.size():
		if float(i) / sand.size() > density: continue
		var g: Dictionary = sand[i]
		var fall_time: float = 3.6 * float(g.speed)
		var p: float = fmod(t / fall_time + g.phase, 1.0)
		var y := p * (H + 20.0) - 10.0
		if y > floor_y: continue
		var x: float = g.x + sin(t * 0.7 + g.phase * TAU) * g.drift
		draw_rect(Rect2(x, y, g.size, g.size * 1.6), Color(AREIA, 0.75))
	# monte com a borda ondulada
	if pile > 0.5:
		var poly := PackedVector2Array([Vector2(W + 2, H + 2), Vector2(-2, H + 2)])
		for k in 33:
			var x := W * k / 32.0
			poly.append(Vector2(x, floor_y + sin(x * 0.03 + t * 0.4) * 3.0 * (1.0 - pour)))
		draw_colored_polygon(poly, AREIA.darkened(0.1))
		draw_rect(Rect2(0, floor_y - 1, W, 1), Color(AREIA, 0.9))


## A tela de areia se desfaz em células, em ordem embaralhada, revelando a dungeon.
func _draw_sand_dissolve(p: float) -> void:
	var cols := int(ceil(W / CELL))
	var gone := int(p * dissolve_order.size())
	for k in range(gone, dissolve_order.size()):
		var c := dissolve_order[k]
		var shade := AREIA.darkened(0.1 + 0.08 * float(c % 3) / 2.0)
		draw_rect(Rect2((c % cols) * CELL, (c / cols) * CELL, CELL, CELL), shade)


# --- C: CORREDOR ---------------------------------------------------------------------

const VP := Vector2(408, 236)


## Avanço do jogador em passos: cada passo dura 0,8 s e o corredor anda uma "fatia".
func _walk() -> float:
	var stop := 14.0
	var tw := minf(t, stop)
	var step := floorf(tw / 0.8)
	var f := _ease(fmod(tw, 0.8) / 0.45)
	return step + f


func _project(z: float) -> Rect2:
	var s := 1.0 / maxf(z, 0.05)
	var half := Vector2(300, 190) * s
	return Rect2(VP - half, half * 2.0)


func _draw_corridor() -> void:
	var o: float = _timing().outro
	var d: float = _timing().dungeon
	if t >= d:
		_draw_dungeon(_ease(_phase(d, d + 1.2)))
	if t < d + 1.2:
		var hide := 1.0 - _ease(_phase(d, d + 1.2))
		if t < 15.0:
			_draw_corridor_walls()
			# o anjo, no fundo, nunca chega mais perto
			_draw_kazfiel(VP + Vector2(0, -6 + sin(t * 1.3) * 2.0), 0.34, _ease(_phase(0.6, 2.2)))
		elif t < o:
			# colado na câmera: o rosto ocupa a tela (corte seco)
			_draw_sky(RUBRO, VINHO, AMEIXA)
			var zoom := 5.2 + _phase(15.0, o) * 0.5
			var face := Vector2(88, 90) - sprite_offset # rosto no battler original 185x190
			var size := kazfiel.get_size() * zoom
			var origin := Vector2(408, 250) - face * zoom
			draw_texture_rect(kazfiel, Rect2(origin, size), false)
			var flash := 1.0 - _phase(15.0, 15.25)
			draw_rect(Rect2(0, 0, W, H), Color(1, 0.9, 0.8, flash * 0.8))
		else:
			_draw_sky(RUBRO, VINHO, AMEIXA, hide)
			var open := _ease(_phase(o, o + 0.6))
			_draw_kazfiel(Vector2(408, 250), lerpf(5.2, 2.2, open), hide)
		_draw_feathers(o, hide)
	_draw_box(1.0, false)


func _draw_corridor_walls() -> void:
	_draw_sky(RUBRO, VINHO, AMEIXA)
	var walk := _walk()
	var bob := sin(walk * PI) * 3.0
	draw_set_transform(Vector2(0, bob))
	var offset := fmod(walk, 1.0)
	var slices := 14
	# do fundo para a frente
	for i in range(slices, -1, -1):
		var z_far := float(i) + 1.3 - offset
		var z_near := maxf(float(i) + 0.3 - offset, 0.06)
		var far := _project(z_far)
		var near := _project(z_near)
		var fog := clampf((z_near - 1.0) / 11.0, 0.0, 1.0)
		var wall := FERRUGEM.darkened(0.25).lerp(VINHO, fog)
		var floor_c := Color("4a2a22").lerp(AMEIXA, fog)
		var edge := Color(OCRE, 0.55 * (1.0 - fog))
		# chão
		draw_colored_polygon(PackedVector2Array([Vector2(far.position.x, far.end.y), Vector2(far.end.x, far.end.y), Vector2(near.end.x, near.end.y), Vector2(near.position.x, near.end.y)]), floor_c)
		# paredes (paredões baixos: o céu aparece por cima, como no corredor do survival)
		var lf := PackedVector2Array([Vector2(near.position.x, near.position.y + near.size.y * 0.42), Vector2(far.position.x, far.position.y + far.size.y * 0.42), Vector2(far.position.x, far.end.y), Vector2(near.position.x, near.end.y)])
		var rt := PackedVector2Array([Vector2(near.end.x, near.position.y + near.size.y * 0.42), Vector2(far.end.x, far.position.y + far.size.y * 0.42), Vector2(far.end.x, far.end.y), Vector2(near.end.x, near.end.y)])
		draw_colored_polygon(lf, wall.darkened(0.12 if i % 2 == 0 else 0.0))
		draw_colored_polygon(rt, wall.darkened(0.0 if i % 2 == 0 else 0.12))
		draw_line(lf[0], lf[3], edge, 1.0)
		draw_line(rt[0], rt[3], edge, 1.0)
		draw_line(Vector2(near.position.x, near.end.y), Vector2(near.end.x, near.end.y), Color(edge, edge.a * 0.6), 1.0)
	draw_set_transform(Vector2.ZERO)
	# vinheta
	for k in 6:
		draw_rect(Rect2(k * 6, k * 6, W - k * 12, H - k * 12), Color(0, 0, 0, 0.08), false, 6)


## Penas douradas: explodem do centro quando as asas se abrem e caem balançando.
func _draw_feathers(o: float, hide: float) -> void:
	if t < o: return
	for f in feathers:
		var age: float = t - o - float(f.delay)
		if age <= 0.0: continue
		var burst := 1.0 - exp(-age * 2.4)
		var pos: Vector2 = Vector2(408, 250) + (f.dir as Vector2) * burst + Vector2(sin(age * 2.0 + f.sway) * 18.0, age * float(f.fall))
		var a: float = f.spin * age * 0.3 + sin(age * 3.0 + f.sway) * 0.6
		var len: float = f.len
		var col: Color = OURO if f.gold else OCRE
		col.a = hide
		var dir := Vector2.from_angle(a)
		var side := dir.orthogonal() * len * 0.18
		draw_colored_polygon(PackedVector2Array([pos - dir * len * 0.5, pos + side, pos + dir * len * 0.5, pos - side]), col)
		draw_line(pos - dir * len * 0.55, pos + dir * len * 0.5, Color(FERRUGEM, hide * 0.8), 1.0)


# --- D: A + B em letras hebraicas ----------------------------------------------------

const ALPHABET := "אבגדהוזחטיכלמנסעפצקרשת"
## Numerais hebraicos de 1 a 8 (alef = 1 ... chet = 8) marcando as 8 portas no mostrador.
const GATES := "אבגדהוזח"
const LETTER_INK := Color("e8e0d0")
const SIL_STEP := 8.0
const SIL_PX := 12.0
const LOOSE_PX := 18.0
const BOX_STEP := 18.0
const RING_R := 214.0
const GATE_R := 182.0
const RING_COUNT := 66
const D_CENTER := Vector2(408, 244)
## Altura do Kazfiel de letras na tela.
const SIL_HEIGHT := 270.0
## Fim da entrada das letras soltas e do voo até o lugar (segundos).
const D_ENTER := 2.6
const D_FLY := 4.8
## Falas PLACEHOLDER em inglês, com uma palavra de letras soltas no lugar do hebraico
## (como no protótipo do prólogo); o criador escreve as definitivas.
const D_LINES := [
	"Hm... another one who cannot stay lying down, %s.",
	"I am %n. I keep the first of the eight gates: the gate of Sloth.",
	"Go down, if you insist. Down there no one hurries... %s.",
]

var d_lines: Array[String] = []
var d_letters: Array[Dictionary] = []
var sil_cells: Array[Vector2] = []
## Luminância do pixel do battler sob cada letra (dá o claro/escuro dentro do anjo).
var sil_shade: Array[float] = []


func _glyph() -> String:
	return ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)]


## Palavra de 3 a 6 letras ao acaso (ordem de leitura).
func _hebrew_word() -> String:
	var word := ""
	for i in rng.randi_range(3, 6):
		word += _glyph()
	return word


func _build_hebrew() -> void:
	d_lines.clear()
	for line in D_LINES:
		d_lines.append(String(line).replace("%s", _hebrew_word()))
	_sample_silhouette()
	d_letters.clear()
	var targets: Array[Dictionary] = []
	for ci in sil_cells.size():
		targets.append({"kind": "sil", "pos": sil_cells[ci], "shade": sil_shade[ci]})
	for i in RING_COUNT:
		targets.append({"kind": "ring", "index": i})
	for i in GATES.length():
		targets.append({"kind": "gate", "index": i})
	var x := BOX.position.x
	while x <= BOX.end.x:
		targets.append({"kind": "box", "pos": Vector2(x, BOX.position.y)})
		targets.append({"kind": "box", "pos": Vector2(x, BOX.end.y)})
		x += BOX_STEP
	var y := BOX.position.y + BOX_STEP
	while y < BOX.end.y:
		targets.append({"kind": "box", "pos": Vector2(BOX.position.x, y)})
		targets.append({"kind": "box", "pos": Vector2(BOX.end.x, y)})
		y += BOX_STEP
	for target in targets:
		var glyph := _glyph()
		if target.kind == "ring":
			glyph = ALPHABET[int(target.index) % ALPHABET.length()]
		elif target.kind == "gate":
			glyph = GATES[int(target.index)]
		target.merge({"glyph": glyph, "rest": Vector2(rng.randf_range(12, W - 12), rng.randf_range(24, H - 10)),
			"appear": rng.randf_range(0.2, D_ENTER - 0.3), "fly": rng.randf_range(0.0, 0.9),
			"swap": rng.randf_range(2.0, 9.0), "phase": rng.randf(),
			"scatter": Vector2.from_angle(rng.randf_range(0, TAU)) * rng.randf_range(60, 300),
			"scatter_delay": rng.randf_range(0.0, 0.6), "spin": rng.randf_range(-3.0, 3.0)})
		d_letters.append(target)


## Grade de letras dentro da silhueta do battler (pixels opacos do recorte).
func _sample_silhouette() -> void:
	sil_cells.clear()
	sil_shade.clear()
	if kazfiel == null: return
	var img := kazfiel.get_image()
	var k := SIL_HEIGHT / img.get_height()
	var size := Vector2(img.get_size()) * k
	var top_left := D_CENTER - size * 0.5
	var y := 0.0
	while y < size.y:
		var x := 0.0
		while x < size.x:
			var px := Vector2i(Vector2(x + SIL_STEP * 0.5, y + SIL_STEP * 0.5) / k)
			if px.x < img.get_width() and px.y < img.get_height() and img.get_pixelv(px).a > 0.5:
				sil_cells.append(top_left + Vector2(x, y) + Vector2(SIL_STEP, SIL_STEP) * 0.5)
				sil_shade.append(img.get_pixelv(px).get_luminance())
			x += SIL_STEP
		y += SIL_STEP


## Giro do mostrador; no desfecho trava com a 1ª porta (alef) no alto.
func _d_spin() -> float:
	var o: float = _timing().outro
	var spin := t * 0.05
	if t >= o:
		spin = lerpf(o * 0.05, ceil(o * 0.05 / TAU) * TAU, _ease(_phase(o, o + 1.4)))
	return spin


func _d_target(l: Dictionary, spin: float) -> Vector2:
	match String(l.kind):
		"ring":
			return D_CENTER + Vector2.from_angle(spin + TAU * int(l.index) / RING_COUNT - PI * 0.5) * RING_R
		"gate":
			return D_CENTER + Vector2.from_angle(spin + TAU * int(l.index) / 8.0 - PI * 0.5) * GATE_R
		"sil":
			# respira devagar a partir do centro
			var breathe := 1.0 + sin(t * TAU / 7.0) * 0.012
			return D_CENTER + ((l.pos as Vector2) - D_CENTER) * breathe
	return l.pos


func _draw_hebrew() -> void:
	var o: float = _timing().outro
	var d: float = _timing().dungeon
	if t >= d:
		# a volta: o Fallen pisca e acorda na dungeon (pálpebra da opção A)
		_draw_dungeon(1.0)
		var open := _wake_blink(t - d)
		if open < 1.0:
			draw_rect(Rect2(0, 0, W, H), Color(AMEIXA, (1.0 - open) * 0.45))
		_draw_lids(open)
		return
	var sc := _scatter_phase()
	_draw_sky(AMEIXA, VINHO, Color(0.08, 0.03, 0.04), _ease(_phase(D_ENTER, D_FLY + 1.0)) * (1.0 - _ease(sc)))
	var spin := _d_spin()
	var settled := _phase(D_FLY, D_FLY + 0.6)
	# círculos finos do mostrador
	var ring_a := 0.45 * settled * (1.0 - _ease(sc * 2.0))
	draw_arc(D_CENTER, RING_R + 16, 0, TAU, 128, Color(OCRE, ring_a), 1.0)
	draw_arc(D_CENTER, RING_R - 14, 0, TAU, 128, Color(OCRE, ring_a), 1.0)
	draw_arc(D_CENTER, GATE_R - 16, 0, TAU, 128, Color(FERRUGEM, ring_a * 0.7), 1.0)
	# ponteiro fixo no alto
	var hand := Color(OURO, 0.75 * settled * (1.0 - _ease(sc * 2.0)))
	var tip := D_CENTER + Vector2(0, -RING_R - 30)
	draw_colored_polygon(PackedVector2Array([tip + Vector2(-7, -8), tip + Vector2(7, -8), tip + Vector2(0, 4)]), hand)
	var dim_others := 1.0 - _phase(o + 0.8, o + 2.0)
	# a caixa formada pelas letras fica de pé entre as falas e se desfaz no desfecho
	var box_life := 1.0 - _phase(o, o + 0.8)
	for l in d_letters:
		if l.kind != "box":
			_draw_d_letter(l, spin, dim_others, box_life)
	_draw_letter_sand(o, box_life, sc)
	# a caixa fica por cima da areia (é interface)
	draw_rect(BOX, Color(0, 0, 0, _phase(D_FLY - 0.4, D_FLY + 0.2) * box_life))
	for l in d_letters:
		if l.kind == "box":
			_draw_d_letter(l, spin, dim_others, box_life)
	_draw_box(1.0, true, false)


func _draw_d_letter(l: Dictionary, spin: float, dim_others: float, box_life: float) -> void:
	var age: float = t - float(l.appear)
	if age < 0.0: return
	var fly := _ease((t - D_ENTER - float(l.fly)) / (D_FLY - D_ENTER - 0.9))
	var target := _d_target(l, spin)
	var pos: Vector2 = (l.rest as Vector2).lerp(target, fly)
	var px := lerpf(LOOSE_PX, _d_px(l), fly)
	var ink := LETTER_INK.lerp(_d_ink(l), fly)
	ink.a = clampf(age / 0.35, 0.0, 1.0)
	var angle := 0.0
	if l.kind == "box":
		ink.a *= box_life
	if l.kind == "ring" or l.kind == "gate":
		angle = lerpf(0.0, (target - D_CENTER).angle() + PI * 0.5, fly)
		if l.kind == "gate" and int(l.index) > 0:
			ink.a *= dim_others
		if l.kind == "ring":
			ink.a *= lerpf(1.0, 0.55, fly) * (0.4 + 0.6 * dim_others)
	var glyph: String = l.glyph
	# as letras do anjo trocam devagar, uma de cada vez (o corpo "respira" em letras)
	if l.kind == "sil" and t > D_FLY:
		var n := int((t + float(l.phase) * float(l.swap)) / float(l.swap))
		glyph = ALPHABET[(ALPHABET.find(String(l.glyph)) + n) % ALPHABET.length()]
	var sc := _scatter_phase()
	if sc > 0.0:
		# as letras se espalham, giram e somem (como no fim do prólogo)
		var own := clampf((sc * SCATTER_TIME - float(l.scatter_delay)) / (SCATTER_TIME - 0.6), 0.0, 1.0)
		var away := (l.scatter as Vector2)
		if l.kind == "sil" or l.kind == "ring" or l.kind == "gate":
			away += (pos - D_CENTER).normalized() * 120.0
		pos += away * _ease(own)
		angle += float(l.spin) * own
		ink.a *= 1.0 - own
	if ink.a <= 0.0: return
	draw_set_transform(pos, angle)
	draw_string(font, Vector2(-px * 0.32, px * 0.36), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, int(round(px)), ink)
	draw_set_transform(Vector2.ZERO)


## Espalhamento das letras: começa depois de o mostrador travar.
const SCATTER_TIME := 2.0


func _scatter_phase() -> float:
	var start: float = float(_timing().outro) + 1.6
	return _phase(start, start + SCATTER_TIME)


## Piscada de quem acorda: abre um pouco, fecha de novo e abre de vez.
func _wake_blink(age: float) -> float:
	if age < 0.4: return 0.0
	if age < 1.2: return 0.5 * _ease((age - 0.4) / 0.8)
	if age < 1.5: return 0.5 - 0.42 * _ease((age - 1.2) / 0.3)
	return minf(1.0, 0.08 + 0.92 * _ease((age - 1.5) / 1.3))


func _d_px(l: Dictionary) -> float:
	match String(l.kind):
		"sil": return SIL_PX
		"gate": return 22.0 if int(l.index) == 0 else 16.0
		"ring": return 13.0
	return 15.0


func _d_ink(l: Dictionary) -> Color:
	match String(l.kind):
		"sil": return OCRE.darkened(0.45).lerp(OURO, clampf(float(l.shade) * 1.5, 0.0, 1.0))
		"gate": return OURO if int(l.index) == 0 else NEVOA
		"ring": return OCRE
	return LETTER_INK


## Areia de letras: caem o tempo todo e se empilham embaixo; no desfecho, o monte e as
## letras no ar se espalham com o resto.
func _draw_letter_sand(o: float, box_life: float, sc: float) -> void:
	var pile := clampf(minf(t, o) - D_FLY, 0.0, o) * 1.6
	var floor_y := H - pile
	var start := _phase(D_FLY - 0.5, D_FLY + 1.0)
	for i in sand.size():
		if float(i) / sand.size() > 0.18 * start: continue
		var g: Dictionary = sand[i]
		var fall_time: float = 4.2 * float(g.speed)
		var p: float = fmod(t / fall_time + float(g.phase), 1.0)
		var y := p * (H + 30.0) - 15.0
		if y > floor_y: continue
		var x: float = float(g.x) + sin(t * 0.6 + float(g.phase) * TAU) * float(g.drift)
		# não cai por cima do texto enquanto a caixa existe
		if box_life > 0.0 and BOX.grow(6.0).has_point(Vector2(x, y)): continue
		var glyph := ALPHABET[i % ALPHABET.length()]
		var a := 0.7 * (1.0 - _ease(sc * 1.5))
		if a <= 0.0: continue
		draw_string(font, Vector2(x, y), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, int(9 + float(g.size) * 2.0), Color(AREIA, a))
	if pile > 0.5:
		_draw_letter_wall(floor_y, sc)


## Monte de areia: grade de letras; no desfecho cada letra voa para um lado e some.
func _draw_letter_wall(from_y: float, sc: float) -> void:
	var cols := int(ceil(W / CELL))
	if sc <= 0.0:
		draw_rect(Rect2(0, from_y, W, H - from_y), AREIA.darkened(0.55))
	for r in range(int(floor(from_y / CELL)), int(ceil(H / CELL))):
		var y := r * CELL + CELL - 1.0
		if y - CELL < from_y - 2.0: continue
		for c in cols:
			var idx := r * cols + c
			var glyph := ALPHABET[(idx * 7 + r) % ALPHABET.length()]
			var pos := Vector2(c * CELL + 1.0, y)
			var ink := AREIA.darkened(0.05 * float(idx % 3))
			if sc > 0.0:
				var h := float((idx * 2654435761) % 1000) / 1000.0
				var own := clampf((sc * SCATTER_TIME - h * 0.6) / (SCATTER_TIME - 0.6), 0.0, 1.0)
				pos += Vector2.from_angle(-PI * (0.15 + 0.7 * h)) * (80.0 + 220.0 * h) * _ease(own)
				ink.a = 1.0 - own
				if ink.a <= 0.0: continue
			draw_string(font, pos, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, CELL, ink)
