class_name SkillGrotesqueFX
extends Node2D
## D-125 (criador 2026-11-27): motor reutilizável dos VFX de ataques NÃO-reza — Anatômico Grotesco de
## Rabisco (boil de 12 FPS) + Interferência Hipnótica (Moiré na GPU) + distorção febril do alvo.
## Porte 1:1 das primitivas dos HTMLs aprovados (docs/vfx_refs/d124_d125/). Guia: docs/NON_PRAYER_VFX_STYLE.md.
##
## Todas as primitivas desenham no espaço de DESIGN do HTML (816 de largura): o nó escala o espaço lógico do
## jogo (544x416) por 1,5, então um quadrado de Moiré de 5 px de design é exatamente 5 px reais na janela
## 816x624. Os efeitos específicos de cada ataque (Fases 4 e 5) usam esta base via `add_effect()`.
##
## Regras estruturais (D-125): ouro `#ffd84a` só existe em ZAHAV (`palette_for`); letras hebraicas só no híbrido
## `Ignoma Esh` (`draw_hebrew_tri_word`); camada abaixo do DamageLayer (z_index 100) e recortada entre o HUD
## superior e o Battle Log.

const DESIGN_SCALE := 1.5                 # px de design por px lógico (544 -> 816)
const STEP := 5.0                         # célula do Moiré, px de design
const STAGE_TOP := 22.0                   # px lógicos: abaixo do HUD superior
const VEIL_COLOR := Color(4.0 / 255.0, 1.0 / 255.0, 8.0 / 255.0)
const BONE := Color("e8ddd0")             # flash de inversão dos impact frames
const BONE_SOFT := Color("efe6d5")
const GOLD := Color("ffd84a")
const FIRE_HEBREW: Array[Color] = [Color("ff7a1f"), Color("ffd84a"), Color("ffffff")]
const MOIRE_SHADER := preload("res://assets/shaders/hypnotic_moire.gdshader")
const WARP_SHADER := preload("res://assets/shaders/target_fever_warp.gdshader")

## Paletas canônicas (docs/NON_PRAYER_VFX_STYLE.md §4). `deep` = preenchimento escuro.
const PAL_BLOOD := {"accent": Color("a81c2e"), "hi": Color("efe6d5"), "hi_soft": Color("e8ddd0"), "deep": Color("24050a")}
const PAL_ZAHAV_BLOOD := {"accent": Color("a81c2e"), "hi": Color("ffd84a"), "deep": Color("26080d")}
const PAL_ABYSS_DARK := {"accent": Color("361c52"), "hi": Color("9b8ab0"), "hi_breath": Color("a997bd"), "deep": Color("09030f")}
const PAL_FIRE_NORMAL := {"accent": Color("c94c14"), "hi": Color("f2d9b6"), "deep": Color("240903")}
const PAL_ZAHAV_FIRE := {"accent": Color("d95b16"), "hi": Color("ffd84a"), "deep": Color("290d04")}
## Preenchimentos de corpo (negro abissal) usados pelos rabiscos.
const FILL_BODY := Color("050208")
const FILL_BODY_DARK := Color("030106")
const FILL_BODY_ABYSS := Color("020005")

## Perfis de limiar do Moiré por HTML canônico (cada ataque usa a função do seu arquivo; ver README).
const MOIRE_PROFILES := {
	&"v2": {"threshold": 0.30, "hi_t": 1.28, "mid_t": 0.72, "alpha_k": 1.45, "alpha_cap": 0.92},
	&"v3": {"threshold": 0.26, "hi_t": 1.30, "mid_t": 0.72, "alpha_k": 1.50, "alpha_cap": 0.95},
	&"v4": {"threshold": 0.30, "hi_t": 1.30, "mid_t": 0.72, "alpha_k": 1.45, "alpha_cap": 0.92},
}

var battle: Node
var hud: Control
var font: SystemFont
var time := 0.0
## Campos de Moiré vivos: key -> {"rect": ColorRect, "spec": Dictionary}.
var _fields: Dictionary = {}
var _fields_layer: Node2D
var _veil: ColorRect
var _darken := 0.0
## Efeitos desenhados em _draw: {"at": float, "dur": float, "draw": Callable(fx, age)}.
var _effects: Array[Dictionary] = []
## Distorção febril: unit.id -> {"unit", "at", "dur", "amp", "invert", "sprite"}.
var _warps: Dictionary = {}
var _shake_until := -1.0
var _shake_px := 0.0
var _shaking := false
var _canvas := Transform2D.IDENTITY


func _ready() -> void:
	z_index = 50  # abaixo do DamageLayer (z 100) e das janelas; PrayFX/SkillLetters ficam acima
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Tahoma", "Arial", "David Libre"])
	font.font_weight = 800
	_fields_layer = Node2D.new()
	_fields_layer.z_index = -1  # o Moiré fica ATRÁS dos rabiscos desenhados por este nó
	add_child(_fields_layer)
	_veil = ColorRect.new()
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.color = Color(VEIL_COLOR, 0.0)
	_veil.visible = false
	_fields_layer.add_child(_veil)
	_place_veil()


func _exit_tree() -> void:
	if _shaking:
		_end_shake()
	_clear_warps()


# ------------------------------------------------------------------ paletas e hash (regra D-125)

## Paleta da família (&"blood" | &"abyss" | &"fire"). O ouro `#ffd84a` só aparece com `is_zahav == true`.
static func palette_for(family: StringName, is_zahav: bool) -> Dictionary:
	if is_zahav:
		match family:
			&"blood": return PAL_ZAHAV_BLOOD.duplicate()
			&"fire": return PAL_ZAHAV_FIRE.duplicate()
			_:
				var p: Dictionary = PAL_ABYSS_DARK.duplicate()
				p["hi"] = GOLD
				return p
	match family:
		&"blood": return PAL_BLOOD.duplicate()
		&"fire": return PAL_FIRE_NORMAL.duplicate()
		_: return PAL_ABYSS_DARK.duplicate()


## hash(n) = fract(sin(n * 127.1 + 311.7) * 43758.5453) — jitter determinístico (não usa randf).
static func sketch_hash(n: float) -> float:
	var s := sin(n * 127.1 + 311.7) * 43758.5453
	return s - floor(s)


## f_idx = floor(t * 12): o rabisco só muda 12 vezes por segundo.
static func boil_index(t: float) -> int:
	return int(floor(t * 12.0))


## Vértices com jitter do quadro `f_idx` (sketchyPoly): jx/jy = (hash(f*31+i*7 / f*47+i*13) - 0.5) * jitter * 2.
func sketchy_pts(pts: PackedVector2Array, f_idx: int, jitter: float = 2.4) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in pts.size():
		var jx := (sketch_hash(float(f_idx * 31 + i * 7)) - 0.5) * jitter * 2.0
		var jy := (sketch_hash(float(f_idx * 47 + i * 13)) - 0.5) * jitter * 2.0
		out.append(pts[i] + Vector2(jx, jy))
	return out


# ------------------------------------------------------------------ conversão lógico <-> design

static func to_design(logical: Vector2) -> Vector2:
	return logical * DESIGN_SCALE


static func to_logical(design: Vector2) -> Vector2:
	return design / DESIGN_SCALE


## Retângulo do palco recortado entre o HUD superior e o Battle Log (px lógicos).
func stage_rect() -> Rect2:
	var bottom: float = 300.0
	var width: float = 544.0
	if hud != null:
		bottom = hud.BATTLE_LOG_RECT.position.y
		width = hud.SCREEN.x
	return Rect2(0.0, STAGE_TOP, width, bottom - STAGE_TOP)


func _place_veil() -> void:
	if _veil == null:
		return
	var r := stage_rect()
	_veil.position = r.position
	_veil.size = r.size


# ------------------------------------------------------------------ campos de Moiré (GPU)

## Cria/atualiza o campo `key`. Medidas no espaço de DESIGN. Chaves de `spec`:
##   mode 0 (radial): "cx", "cy", "rx", "ry".   mode 1 (cone da boca): "mouth" (Vector2), "reach", "dir_x".
##   comuns: "env", "pal" (Dictionary), "profile" (&"v2"/&"v3"/&"v4"), "dark_bias" (bool), "dark_col" (Color).
func set_field(key: StringName, spec: Dictionary) -> void:
	var rect: ColorRect = null
	if _fields.has(key):
		rect = _fields[key].rect
	else:
		rect = ColorRect.new()
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.color = Color.WHITE
		var mat := ShaderMaterial.new()
		mat.shader = MOIRE_SHADER
		rect.material = mat
		_fields_layer.add_child(rect)
		_fields[key] = {"rect": rect, "spec": spec}
	_fields[key].spec = spec
	var mode := int(spec.get("mode", 0))
	var area_d: Rect2
	if mode == 0:
		var cx := float(spec.cx)
		var cy := float(spec.cy)
		var rx := float(spec.rx)
		var ry := float(spec.ry)
		area_d = Rect2(cx - rx, cy - ry, rx * 2.0, ry * 2.0)
	else:
		var mouth: Vector2 = spec.mouth
		var reach := float(spec.reach)
		var dir := float(spec.get("dir_x", 1.0))
		var half := 16.0 + reach * 0.21
		var x0 := mouth.x if dir > 0.0 else mouth.x - reach
		area_d = Rect2(x0, mouth.y - half, reach, half * 2.0)
	# o retângulo coberto é recortado ao palco (o Moiré nunca passa do HUD superior nem do Battle Log)
	var stage_d := Rect2(stage_rect().position * DESIGN_SCALE, stage_rect().size * DESIGN_SCALE)
	var clipped := area_d.intersection(stage_d)
	if clipped.size.x <= 0.0 or clipped.size.y <= 0.0 or float(spec.get("env", 1.0)) <= 0.02:
		rect.visible = false
		return
	rect.visible = true
	rect.position = clipped.position / DESIGN_SCALE
	rect.size = clipped.size / DESIGN_SCALE
	var mat: ShaderMaterial = rect.material
	var pal: Dictionary = spec.get("pal", PAL_BLOOD)
	var profile: Dictionary = MOIRE_PROFILES[spec.get("profile", &"v4")]
	mat.set_shader_parameter("mode", mode)
	mat.set_shader_parameter("time_val", time)
	mat.set_shader_parameter("env", float(spec.get("env", 1.0)))
	mat.set_shader_parameter("dark_bias", bool(spec.get("dark_bias", false)))
	mat.set_shader_parameter("rect_size", clipped.size)
	mat.set_shader_parameter("rect_origin", clipped.position)
	for k in profile:
		mat.set_shader_parameter(k, float(profile[k]))
	var hi_key := "hi_breath" if (mode == 1 and pal.has("hi_breath")) else "hi"
	mat.set_shader_parameter("col_hi", pal[hi_key])
	mat.set_shader_parameter("col_accent", pal.accent)
	mat.set_shader_parameter("col_dark", spec.get("dark_col", FILL_BODY_DARK if bool(spec.get("dark_bias", false)) or mode == 1 else FILL_BODY))
	if mode == 1:
		var mouth_d: Vector2 = spec.mouth
		mat.set_shader_parameter("mouth_pos", mouth_d)
		mat.set_shader_parameter("reach", float(spec.reach))
		mat.set_shader_parameter("dir_x", float(spec.get("dir_x", 1.0)))


func clear_field(key: StringName) -> void:
	if _fields.has(key):
		(_fields[key].rect as ColorRect).queue_free()
		_fields.erase(key)


func clear_fields() -> void:
	for key in _fields.keys():
		clear_field(key)


func field_count() -> int:
	return _fields.size()


## Véu `rgba(4,1,8,darken)` só sobre o palco (entre o HUD superior e o Battle Log).
func set_darken(amount: float) -> void:
	_darken = clampf(amount, 0.0, 1.0)
	_place_veil()
	_veil.visible = _darken > 0.01
	_veil.color = Color(VEIL_COLOR, _darken)


func darken() -> float:
	return _darken


# ------------------------------------------------------------------ shake e distorção febril do alvo

## Tremor de tela de `px` pixels por `dur` segundos (não disputa com o tremor do PrayFX).
func camera_shake(px: float, dur: float) -> void:
	_shake_px = maxf(_shake_px, px)
	_shake_until = maxf(_shake_until, time + dur)


func _shake_step() -> void:
	var active := time < _shake_until
	var pray_shaking := false
	if battle != null and battle.get("prayer") != null and battle.prayer != null and battle.prayer.fx != null:
		pray_shaking = bool(battle.prayer.fx.get("_shaking"))
	if active and not pray_shaking:
		if not _shaking:
			_shaking = true
			_canvas = get_viewport().canvas_transform
		var k := clampf((_shake_until - time) / maxf(0.001, _shake_until - (_shake_until - 0.2)), 0.0, 1.0)
		var off := Vector2(sketch_hash(time * 60.0) - 0.5, sketch_hash(time * 60.0 + 9.0) - 0.5) * 2.0 * _shake_px * minf(1.0, k)
		get_viewport().canvas_transform = _canvas.translated(off.round())
	else:
		if _shaking:
			_end_shake()
		if not active:
			_shake_px = 0.0


func _end_shake() -> void:
	_shaking = false
	get_viewport().canvas_transform = _canvas


## Distorção febril do alvo: `amp` px de design decaindo por `dur`s; o flash osso de inversão dura
## `invert_dur`s desde o início. Inimigo: sprite sobreposto com `target_fever_warp`; herói: o cartão ondula.
func trigger_target_warp(unit: BattleUnit, amp: float, dur: float, invert_dur: float = 0.0) -> void:
	if unit == null or hud == null:
		return
	_stop_warp(unit.id)
	var entry := {"unit": unit, "at": time, "dur": dur, "amp": amp, "invert": invert_dur, "sprite": null}
	var index: int = hud.opponents.find(unit)
	if index >= 0 and not unit.is_player:
		var sprite := Sprite2D.new()
		sprite.centered = false
		sprite.texture = hud.silhouettes[index % hud.silhouettes.size()]
		var mat := ShaderMaterial.new()
		mat.shader = WARP_SHADER
		sprite.material = mat
		add_child(sprite)
		entry.sprite = sprite
		hud.warp_hidden[unit.id] = true
	_warps[unit.id] = entry


func _stop_warp(unit_id: StringName) -> void:
	if not _warps.has(unit_id):
		return
	var entry: Dictionary = _warps[unit_id]
	if entry.sprite != null:
		(entry.sprite as Sprite2D).queue_free()
	if hud != null:
		hud.warp_hidden.erase(unit_id)
		hud.warp_card.erase(unit_id)
	_warps.erase(unit_id)


func _clear_warps() -> void:
	for id in _warps.keys():
		_stop_warp(id)


func warp_count() -> int:
	return _warps.size()


func _warp_step() -> void:
	for id in _warps.keys():
		var entry: Dictionary = _warps[id]
		var age := time - float(entry.at)
		if age >= float(entry.dur):
			_stop_warp(id)
			continue
		var env := 1.0 - age / maxf(0.001, float(entry.dur))
		var amp := float(entry.amp) * env
		var unit: BattleUnit = entry.unit
		if entry.sprite != null:
			var index: int = hud.opponents.find(unit)
			if index < 0:
				_stop_warp(id)
				continue
			var art: Rect2 = hud.enemy_sprite_rect(index)
			art.position += hud.shake_offset(unit)
			var sprite: Sprite2D = entry.sprite
			var tex_size := sprite.texture.get_size()
			sprite.position = art.position
			sprite.scale = art.size / tex_size
			var mat: ShaderMaterial = sprite.material
			mat.set_shader_parameter("warp_amp", amp)
			mat.set_shader_parameter("time_val", time)
			mat.set_shader_parameter("invert_mix", 1.0 if age < float(entry.invert) else 0.0)
			mat.set_shader_parameter("rect_size", art.size)
			mat.set_shader_parameter("px_scale", DESIGN_SCALE)
		else:
			# herói: o cartão ondula na mesma equação (wx do HTML), em px lógicos
			var wx := sin(age * 20.0 * 3.0) * amp + cos(age * 12.0 * 3.0) * amp * 0.5
			hud.warp_card[id] = Vector2(wx / DESIGN_SCALE, 0.0)


# ------------------------------------------------------------------ efeitos desenhados + ciclo de vida

## Registra um efeito desenhado: `drawer.call(self, age)` roda em _draw (já no espaço de design) até `dur`.
func add_effect(dur: float, drawer: Callable) -> void:
	_effects.append({"at": time, "dur": dur, "draw": drawer})


func effect_count() -> int:
	return _effects.size()


func is_busy() -> bool:
	return not _effects.is_empty() or not _fields.is_empty() or not _warps.is_empty() or _darken > 0.01 or time < _shake_until


func clear_all() -> void:
	_effects.clear()
	clear_fields()
	_clear_warps()
	set_darken(0.0)
	_shake_until = -1.0


func _process(delta: float) -> void:
	time += delta
	for i in range(_effects.size() - 1, -1, -1):
		if time - float(_effects[i].at) >= float(_effects[i].dur):
			_effects.remove_at(i)
	_warp_step()
	_shake_step()
	for key in _fields.keys():
		var spec: Dictionary = _fields[key].spec
		set_field(key, spec)  # atualiza time_val do shader
	queue_redraw()


func _draw() -> void:
	if _effects.is_empty():
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE / DESIGN_SCALE)
	for e in _effects:
		var drawer: Callable = e.draw
		if drawer.is_valid():
			drawer.call(self, time - float(e.at))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ------------------------------------------------------------------ primitivas 1:1 dos HTMLs (espaço de design)

func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	if pts.size() > 0:
		out.append(pts[0])
	return out


func _fill_poly(pts: PackedVector2Array, col: Color) -> void:
	if pts.size() < 3:
		return
	var tri := Geometry2D.triangulate_polygon(pts)
	if not tri.is_empty():
		draw_colored_polygon(pts, col)
		return
	# polígono auto-intersectado pelo jitter: leque a partir do centroide (sempre válido)
	var centroid := Vector2.ZERO
	for p in pts:
		centroid += p
	centroid /= float(pts.size())
	for i in pts.size():
		var tri_pts := PackedVector2Array([centroid, pts[i], pts[(i + 1) % pts.size()]])
		if absf((tri_pts[1] - tri_pts[0]).cross(tri_pts[2] - tri_pts[0])) > 0.01:
			draw_colored_polygon(tri_pts, col)


## drawSketchShape: preenchimento escuro + 1º traço `pal.hi` + 2º traço deslocado (f_idx+77, jitter*1.45) `pal.accent`.
func draw_sketch_shape(pts: PackedVector2Array, f_idx: int, pal: Dictionary, jitter: float = 2.4,
		fill_col: Color = FILL_BODY, line_w: float = 2.0, alpha: float = 1.0) -> void:
	var first := sketchy_pts(pts, f_idx, jitter)
	if fill_col.a > 0.0:
		_fill_poly(first, Color(fill_col, fill_col.a * alpha))
	var hi: Color = pal.hi
	draw_polyline(_closed(first), Color(hi, hi.a * alpha), line_w, false)
	var second := sketchy_pts(pts, f_idx + 77, jitter * 1.45)
	var accent: Color = pal.accent
	draw_polyline(_closed(second), Color(accent, accent.a * alpha), maxf(1.1, line_w * 0.65), false)


## drawSketchEye: 12 vértices; olho aberto com pupila trêmula, ou fenda fechada com risco em X (cegueira).
func draw_sketch_eye(cx: float, cy: float, rx: float, ry: float, f_idx: int, pal: Dictionary,
		closed: bool = false, dark_iris: bool = false, alpha: float = 1.0) -> void:
	var pts := PackedVector2Array()
	for i in 12:
		var a := (float(i) / 12.0) * TAU
		pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * (ry * 0.18 if closed else ry)))
	var fill: Color = Color("040108") if closed else (Color("b8abc9") if dark_iris else pal.hi)
	draw_sketch_shape(pts, f_idx, pal, 1.4, fill, 2.0, alpha)
	if not closed:
		var pupil := Vector2(cx + (sketch_hash(float(f_idx * 13)) - 0.5) * rx * 0.25, cy)
		draw_circle(pupil, minf(rx, ry) * 0.58, Color(FILL_BODY_DARK, alpha))
	else:
		var hi: Color = pal.hi
		var col := Color(hi, hi.a * alpha)
		draw_line(Vector2(cx - rx * 1.15, cy - ry * 0.95), Vector2(cx + rx * 1.15, cy + ry * 0.95), col, 1.8, false)
		draw_line(Vector2(cx + rx * 1.15, cy - ry * 0.95), Vector2(cx - rx * 1.15, cy + ry * 0.95), col, 1.8, false)


## Os 11 vértices da chama. "v3" (baseW = 24*scale) é a de Ignoma; "v4" usa os valores arredondados de Ignoma Esh.
static func flame_points(cx: float, cy: float, scale: float, variant: StringName = &"v3") -> PackedVector2Array:
	if variant == &"v4":
		return PackedVector2Array([
			Vector2(cx - 14 * scale, cy + 16 * scale), Vector2(cx - 24 * scale, cy + 2 * scale), Vector2(cx - 19 * scale, cy - 16 * scale),
			Vector2(cx - 10 * scale, cy - 6 * scale), Vector2(cx - 7 * scale, cy - 36 * scale), Vector2(cx, cy - 16 * scale),
			Vector2(cx + 3 * scale, cy - 44 * scale), Vector2(cx + 8 * scale, cy - 14 * scale), Vector2(cx + 16 * scale, cy - 28 * scale),
			Vector2(cx + 22 * scale, cy + 4 * scale), Vector2(cx + 13 * scale, cy + 18 * scale)])
	var base_w := 24.0 * scale
	return PackedVector2Array([
		Vector2(cx - base_w * 0.6, cy + 16 * scale), Vector2(cx - base_w, cy + 2 * scale), Vector2(cx - base_w * 0.78, cy - 16 * scale),
		Vector2(cx - base_w * 0.42, cy - 6 * scale), Vector2(cx - base_w * 0.28, cy - 36 * scale), Vector2(cx, cy - 16 * scale),
		Vector2(cx + base_w * 0.14, cy - 44 * scale), Vector2(cx + base_w * 0.34, cy - 14 * scale), Vector2(cx + base_w * 0.68, cy - 28 * scale),
		Vector2(cx + base_w * 0.92, cy + 4 * scale), Vector2(cx + base_w * 0.55, cy + 18 * scale)])


## drawSketchFlame: 11 vértices + língua interna preenchida com `pal.accent` (0.52 / 0.55), SEM olho.
func draw_sketch_flame(cx: float, cy: float, scale: float, f_idx: int, pal: Dictionary,
		fill_col: Color = FILL_BODY, alpha: float = 1.0, variant: StringName = &"v3") -> void:
	var pts := flame_points(cx, cy, scale, variant)
	draw_sketch_shape(pts, f_idx, pal, 3.2 * minf(1.4, scale), fill_col, 2.2, alpha)
	var inner := PackedVector2Array()
	for p in pts:
		inner.append(Vector2(cx + (p.x - cx) * 0.52, cy + 4.0 * scale + (p.y - cy) * 0.55))
	var accent: Color = pal.accent
	_fill_poly(sketchy_pts(inner, f_idx + 19, 2.0), Color(accent, accent.a * alpha))


## drawHebrewTriWord: palavra hebraica RTL em 3 cores (`FIRE_HEBREW`). SÓ para híbridos (Ignoma Esh = `אש`).
## Cada glifo é desenhado sozinho (nunca mistura ASCII na mesma chamada) com a largura real do glifo.
func draw_hebrew_tri_word(word: String, center: Vector2, px: int, alpha: float) -> void:
	if alpha <= 0.01 or word.is_empty():
		return
	var n := word.length()
	var widths: Array[float] = []
	var total_w := 0.0
	var pad := 1.5
	for i in n:
		var ch := word.substr(i, 1)
		var w := float(px) * 0.34 if ch == " " else maxf(float(px) * 0.24, font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x)
		widths.append(w)
		total_w += w + (pad if i < n - 1 else 0.0)
	var cursor_x := center.x + total_w * 0.5
	for i in n:
		var ch := word.substr(i, 1)
		cursor_x -= widths[i]
		if ch != " ":
			var col: Color = FIRE_HEBREW[i % FIRE_HEBREW.size()]
			var pos := Vector2(cursor_x, center.y)
			draw_string_outline(font, pos, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, px, 3, Color(FILL_BODY, alpha * 0.9))
			draw_string(font, pos, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, px, Color(col, alpha))
		cursor_x -= pad
