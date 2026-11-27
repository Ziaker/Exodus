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
## Desenha a camada de trás (`"back"` dos efeitos) no espaço de design.
class BackLayer extends Node2D:
	var fx: Node2D
	func _process(_d: float) -> void:
		queue_redraw()
	## Preenche um polígono possivelmente auto-intersectado (leque a partir do centroide se a triangulação falhar).
	func fill_poly(pts: PackedVector2Array, col: Color) -> void:
		if pts.size() < 3: return
		if not Geometry2D.triangulate_polygon(pts).is_empty():
			draw_colored_polygon(pts, col)
			return
		var centroid := Vector2.ZERO
		for p in pts: centroid += p
		centroid /= float(pts.size())
		for i in pts.size():
			var tri := PackedVector2Array([centroid, pts[i], pts[(i + 1) % pts.size()]])
			if absf((tri[1] - tri[0]).cross(tri[2] - tri[0])) > 0.01:
				draw_colored_polygon(tri, col)
	func _draw() -> void:
		if fx == null: return
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE / fx.DESIGN_SCALE)
		for e in fx._effects:
			var back: Callable = e.get("back", Callable())
			if back.is_valid():
				back.call(fx, fx.time - float(e.at), self)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Distorção febril: unit.id -> {"unit", "at", "dur", "amp", "invert", "sprite"}.
var _warps: Dictionary = {}
## Camada de trás (garganta do Dark Breath, que fica ATRÁS do cone de Moiré): {"back": Callable}.
var _back_layer: Node2D
## Sprites do warp dos inimigos: ficam na camada MAIS BAIXA do motor (z 47), atrás de qualquer efeito (regra do criador:
## nenhum efeito aparece atrás da figura).
var _warp_layer: Node2D
var _shake_until := -1.0
var _shake_px := 0.0
var _shaking := false
var _canvas := Transform2D.IDENTITY


func _ready() -> void:
	z_index = 50  # abaixo do DamageLayer (z 100) e das janelas; PrayFX/SkillLetters ficam acima
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Tahoma", "Arial", "David Libre"])
	font.font_weight = 800
	_warp_layer = Node2D.new()
	_warp_layer.z_index = -3
	add_child(_warp_layer)
	_back_layer = BackLayer.new()
	_back_layer.fx = self
	_back_layer.z_index = -2  # atrás do Moiré
	add_child(_back_layer)
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
		var half := (16.0 + reach * 0.21 / float(spec.get("cone_scale", 1.0))) * float(spec.get("cone_scale", 1.0))
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
		mat.set_shader_parameter("cone_scale", float(spec.get("cone_scale", 1.0)))


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
		_warp_layer.add_child(sprite)
		entry.sprite = sprite
		hud.warp_hidden[unit.id] = true
	_warps[unit.id] = entry


## Distorção dirigida quadro a quadro pelo efeito (amplitude e inversão calculadas pela coreografia).
func drive_target_warp(unit: BattleUnit, amp: float, invert_mix: float = 0.0) -> void:
	if unit == null or hud == null:
		return
	if not _warps.has(unit.id) or not bool(_warps[unit.id].get("manual", false)):
		trigger_target_warp(unit, 1.0, 9999.0, 0.0)
		if _warps.has(unit.id):
			_warps[unit.id]["manual"] = true
	if _warps.has(unit.id):
		_warps[unit.id]["drive_amp"] = amp
		_warps[unit.id]["drive_inv"] = invert_mix


func release_target_warp(unit: BattleUnit) -> void:
	if unit != null:
		_stop_warp(unit.id)


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
		var manual: bool = bool(entry.get("manual", false))
		if not manual and age >= float(entry.dur):
			_stop_warp(id)
			continue
		var env := 1.0 - age / maxf(0.001, float(entry.dur))
		var amp := float(entry.amp) * env
		if manual:
			amp = float(entry.get("drive_amp", 0.0))
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
			mat.set_shader_parameter("invert_mix", float(entry.get("drive_inv", 0.0)) if manual else (1.0 if age < float(entry.invert) else 0.0))
			mat.set_shader_parameter("rect_size", art.size)
			mat.set_shader_parameter("px_scale", DESIGN_SCALE)
		else:
			# herói: o cartão ondula na mesma equação (wx do HTML), em px lógicos
			var wx := sin(age * 20.0 * 3.0) * amp + cos(age * 12.0 * 3.0) * amp * 0.5
			hud.warp_card[id] = Vector2(wx / DESIGN_SCALE, 0.0)


# ------------------------------------------------------------------ efeitos desenhados + ciclo de vida

## Registra um efeito desenhado: `drawer.call(self, age)` roda em _draw (já no espaço de design) até `dur`.
## `updater.call(self, age)` roda todo quadro (campos, véu, warps); `on_end.call(self)` ao terminar; `back` desenha atrás do Moiré.
func add_effect(dur: float, drawer: Callable, updater: Callable = Callable(), on_end: Callable = Callable(), back: Callable = Callable()) -> float:
	_effects.append({"at": time, "dur": dur, "draw": drawer, "update": updater, "end": on_end, "back": back})
	return time


func effect_count() -> int:
	return _effects.size()


func is_busy() -> bool:
	return not _effects.is_empty() or not _fields.is_empty() or not _warps.is_empty() or _darken > 0.01 or time < _shake_until


func clear_all() -> void:
	for e in _effects:
		var on_end: Callable = e.end
		if on_end.is_valid():
			on_end.call(self)
	_effects.clear()
	clear_fields()
	_clear_warps()
	set_darken(0.0)
	_shake_until = -1.0


func _process(delta: float) -> void:
	time += delta
	for i in range(_effects.size() - 1, -1, -1):
		var e: Dictionary = _effects[i]
		var age := time - float(e.at)
		if age >= float(e.dur):
			var on_end: Callable = e.end
			if on_end.is_valid():
				on_end.call(self)
			_effects.remove_at(i)
		else:
			var upd: Callable = e.update
			if upd.is_valid():
				upd.call(self, age)
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


# ------------------------------------------------------------------ coreografias dos 8 ataques (Fases 4 e 5)
## Porte 1:1 das funções canônicas dos HTMLs (docs/vfx_refs/d124_d125/README.md): tempos, hit times, envelopes,
## geometria relativa ao alvo e camadas são os dos HTMLs. As formas são escaladas por `k` = altura do sprite do
## alvo / 100 (a altura do inimigo no HTML), porque os sprites do jogo são maiores que as caixas do HTML.
## Momentos de impacto (segundos desde o início do efeito), para o controlador sincronizar a mecânica:
const HIT_MAZZ := 0.56
const HIT_STING := 0.50
const HIT_SPINE: Array[float] = [0.44, 1.04]
const HIT_VULN := 0.64
const HIT_UMBRAL := 0.62
const HIT_IGNOMA := 0.62
const HIT_ESH: Array[float] = [0.62, 1.04]
const DURATIONS := {&"mazz_bite": 2.35, &"fang_sting": 2.35, &"fang_spine": 2.70, &"vuln_pierce": 2.45,
	&"dark_breath": 2.95, &"umbral_gaze": 2.85, &"ignoma": 2.45, &"ignoma_esh": 2.85}
const HEBREW_ALPHABET := "אבגדהוזחטיכלמנסעפצקרשת"
const BREATH_SPEED := 640.0
const BREATH_START := 0.26


## Geometria de uma unidade no espaço de design: centro, escala `k`, altura e pés.
## Ordem do criador (2026-11-27): todos os efeitos grotescos saem com 85% do tamanho anterior (inimigos E aliados, iguais).
const EFFECT_SCALE := 0.85


func unit_geom(u: BattleUnit) -> Dictionary:
	if u.is_player:
		var idx: int = hud.players.find(u)
		var card: Rect2 = hud.status_rect(maxi(0, idx))
		# Ordem do criador: o herói não tem figura no palco, então o efeito acontece NO CARTÃO dele (centro do cartão), com o
		# MESMO tamanho (k, altura) do efeito num inimigo. Pode cobrir o texto do cartão: isso é aceito.
		var ref := _enemy_reference()
		var c: Vector2 = to_design(card.get_center())
		return {"c": c, "k": ref.k, "h": ref.h, "feet": c.y + float(ref.h) * 0.5, "origin": c,
			"card": Rect2(to_design(card.position), to_design(card.size))}
	var index: int = maxi(0, hud.opponents.find(u))
	var rect: Rect2 = hud.enemy_sprite_rect(index)
	var cc: Vector2 = to_design(rect.get_center())
	var hd: float = rect.size.y * DESIGN_SCALE
	return {"c": cc, "k": clampf(hd / 100.0, 1.0, 2.6) * EFFECT_SCALE, "h": hd, "feet": to_design(Vector2(0, rect.end.y)).y, "origin": cc}


## Tamanho do efeito num inimigo (referência para o efeito nos cartões dos aliados).
func _enemy_reference() -> Dictionary:
	for u in hud.opponents:
		if u.is_alive():
			return unit_geom(u)
	return {"c": Vector2(408.0, 280.0), "k": 2.2, "h": 220.0, "feet": 390.0, "origin": Vector2(408.0, 280.0)}


func _origin_of(caster: BattleUnit) -> Vector2:
	if caster == null:
		return Vector2(140.0, 420.0)
	return unit_geom(caster).origin


## Quando o sopro do Dark Breath chega em `unit` (segundos desde o início): breathStart + distância / 640.
func breath_hit_age(caster: BattleUnit, unit: BattleUnit) -> float:
	var mx := 104.0 if (caster == null or caster.is_player) else 816.0 - 104.0
	return BREATH_START + absf(float(unit_geom(unit).c.x) - mx) / BREATH_SPEED


## Espera até `age_needed` segundos depois de `start` (o controlador aplica o dano nesse momento).
func wait_age(start: float, age_needed: float) -> void:
	while is_inside_tree() and time - start < age_needed:
		await get_tree().process_frame


func _q(age: float) -> float:
	return floor(age * 12.0) / 12.0


func _pb() -> Dictionary:
	var p: Dictionary = PAL_BLOOD.duplicate()
	p["hi"] = BONE_SOFT
	return p


func _pb_v3() -> Dictionary:
	var p: Dictionary = PAL_BLOOD.duplicate()
	p["hi"] = BONE
	return p


## Desenha `body` com a origem em `c` e a escala `k` (coordenadas relativas ao alvo, como nos HTMLs).
func _local(c: Vector2, k: float, flip: float = 1.0) -> void:
	draw_set_transform(c / DESIGN_SCALE, 0.0, Vector2(k * flip, k) / DESIGN_SCALE)


func _unlocal() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE / DESIGN_SCALE)


func _release_all(units: Array) -> void:
	for u in units:
		release_target_warp(u)
	clear_fields()
	set_darken(0.0)


# ---- 1. MAZZ BITE (v2 renderMazzBite) -------------------------------------------------------------------------
func play_mazz_bite(caster: BattleUnit, target: BattleUnit) -> float:
	var g := unit_geom(target)
	var c: Vector2 = g.c
	var k: float = g.k
	var pal := _pb()
	var st := {"shaken": false}
	return add_effect(DURATIONS[&"mazz_bite"], func(_fx: Node2D, t: float) -> void:
		var qt := _q(t)
		var f_idx := boil_index(t)
		var hit := qt >= HIT_MAZZ
		var age := maxf(0.0, qt - HIT_MAZZ)
		if t > 0.16 and age < 0.85:
			var p := pow((qt - 0.16) / (HIT_MAZZ - 0.16), 1.8) if not hit else 1.0
			var a := minf(1.0, 0.35 + 0.65 * p) if not hit else maxf(0.0, 1.0 - age / 0.85)
			var gap := (1.0 - p) * 52.0 if not hit else 0.0
			_local(c, k)
			for dir in [-1, 1]:
				var by: float = dir * (12.0 + gap)
				var pts := PackedVector2Array()
				pts.append(Vector2(-74.0, by + dir * 28.0))
				for i in range(-5, 6):
					var tx := float(i) * 12.0
					var th := (sketch_hash(float(i * 19 + dir * 7)) * 20.0 + 12.0) * (1.55 if absi(i) == 2 else 1.0)
					pts.append(Vector2(tx - 4.0, by))
					pts.append(Vector2(tx + (sketch_hash(float(i * 11)) - 0.5) * 6.0, by - dir * th))
					pts.append(Vector2(tx + 4.0, by))
				pts.append(Vector2(74.0, by + dir * 28.0))
				draw_sketch_shape(pts, f_idx + dir * 5, pal, 2.4, FILL_BODY, 2.0, a)
			if hit and age < 0.65:
				draw_sketch_eye(-62.0, -34.0, 13.0, 6.0, f_idx + 1, pal, false, false, a)
				draw_sketch_eye(64.0, -26.0, 11.0, 5.0, f_idx + 2, pal, false, false, a)
				draw_sketch_eye(-48.0, 38.0, 10.0, 4.5, f_idx + 3, pal, false, false, a)
			_unlocal(),
		func(_fx: Node2D, t: float) -> void:
			var qt := _q(t)
			var hit := qt >= HIT_MAZZ
			var age := maxf(0.0, qt - HIT_MAZZ)
			var env := pow(qt / HIT_MAZZ, 1.6) * 0.65 if not hit else maxf(0.0, 1.0 - age / 1.0)
			set_field(&"mazz", {"mode": 0, "cx": c.x, "cy": c.y, "rx": (48.0 + env * 74.0) * k, "ry": (42.0 + env * 62.0) * k,
				"env": env, "pal": pal, "profile": &"v2"})
			drive_target_warp(target, env * 11.0 * k, 1.0 if (hit and age < 0.14) else 0.0)
			if hit and not st.shaken:
				st.shaken = true
			if hit and age < 0.25:
				camera_shake(5.0, 0.12),
		func(_fx: Node2D) -> void: _release_all([target]))


# ---- 2. FANG STING (v2 renderFangSting) -----------------------------------------------------------------------
func play_fang_sting(caster: BattleUnit, target: BattleUnit, landed_point: bool = true) -> float:
	var g := unit_geom(target)
	var c: Vector2 = g.c
	var k: float = g.k
	var pal := _pb()
	var flip := 1.0 if (caster == null or caster.is_player) else -1.0
	return add_effect(DURATIONS[&"fang_sting"], func(_fx: Node2D, t: float) -> void:
		var qt := _q(t)
		var f_idx := boil_index(t)
		var hit := qt >= HIT_STING
		var age := maxf(0.0, qt - HIT_STING)
		if age < 0.65:
			var ext := pow(qt / HIT_STING, 1.5) * 0.55 if not hit else minf(1.0, 0.55 + age * 4.0)
			var a := 0.85 if not hit else maxf(0.0, 1.0 - age / 0.65)
			_local(c, k, flip)
			var x0 := -155.0
			var y0 := 62.0
			var x1 := x0 + 285.0 * ext
			var y1 := y0 - 115.0 * ext
			draw_sketch_shape(PackedVector2Array([Vector2(x0 - 8.0, y0 - 12.0), Vector2(x0 + 95.0 * ext, y0 - 44.0 * ext), Vector2(x1, y1),
				Vector2(x0 + 100.0 * ext, y0 - 26.0 * ext), Vector2(x0 + 10.0, y0 + 10.0)]), f_idx, pal, 2.2, FILL_BODY, 2.0, a)
			if hit:
				for i in 8:
					var ang := -0.6 + (sketch_hash(float(i * 17)) - 0.5) * 1.4
					var d := 14.0 + age * (90.0 + sketch_hash(float(i * 23)) * 130.0)
					var sx := cos(ang) * d
					var sy := sin(ang) * d + 85.0 * age * age
					draw_sketch_shape(PackedVector2Array([Vector2(sx - 3.0, sy - 2.0), Vector2(sx + 5.0, sy), Vector2(sx - 2.0, sy + 5.0)]),
						f_idx + i, pal, 1.4, pal.accent, 2.0, a)
			_unlocal(),
		func(_fx: Node2D, t: float) -> void:
			var qt := _q(t)
			var hit := qt >= HIT_STING
			var age := maxf(0.0, qt - HIT_STING)
			var env := maxf(0.0, 1.0 - age / 0.95) if hit else 0.0
			if hit:
				set_field(&"sting", {"mode": 0, "cx": c.x, "cy": c.y, "rx": 88.0 * env * k, "ry": 26.0 * env * k, "env": env, "pal": pal, "profile": &"v2"})
			drive_target_warp(target, env * 8.0 * k, 1.0 if (hit and age < 0.14) else 0.0),
		func(_fx: Node2D) -> void: _release_all([target]))


# ---- 3. FANG SPINE [ZAHAV] (v3 renderFangSpine) ---------------------------------------------------------------
func play_fang_spine(caster: BattleUnit, targets: Array) -> float:
	var t0: BattleUnit = targets[0]
	var t1: BattleUnit = targets[1] if targets.size() > 1 else targets[0]
	var g0 := unit_geom(t0)
	var g1 := unit_geom(t1)
	var pal := palette_for(&"blood", true)
	var same := t0 == t1
	var all_units: Array = [t0] if same else [t0, t1]
	var geoms: Array = [g0, g1]
	var units: Array = [t0, t1]
	return add_effect(DURATIONS[&"fang_spine"], func(_fx: Node2D, t: float) -> void:
		var qt := _q(t)
		var f_idx := boil_index(t)
		if qt >= 0.42 and qt <= 1.38:
			var prog := minf(1.0, (qt - 0.42) / 0.62)
			var fade := 1.0 if qt < 1.08 else maxf(0.0, 1.0 - (qt - 1.08) / 0.3)
			var segs := maxi(1, int(floor(prog * 10.0)))
			var k_s: float = (float(g0.k) + float(g1.k)) * 0.5
			for i in segs:
				var p := float(i) / 9.0
				var vx: float
				var vy: float
				if same:
					vx = float(g0.c.x) + (p - 0.5) * 2.0 * 60.0 * k_s
					vy = float(g0.c.y) - sin(p * PI) * 72.0 * k_s
				else:
					vx = lerpf(float(g0.c.x), float(g1.c.x), p)
					vy = lerpf(float(g0.c.y), float(g1.c.y), p) - sin(p * PI) * 72.0 * k_s
				_local(Vector2(vx, vy), k_s)
				draw_sketch_shape(PackedVector2Array([Vector2(-8, -5), Vector2(0, -17), Vector2(8, -5), Vector2(6, 7), Vector2(-6, 7)]),
					f_idx + i * 3, pal, 1.8, FILL_BODY, 2.0, fade)
				_unlocal()
		for hi in 2:
			var age := qt - HIT_SPINE[hi]
			if age < 0.0 or age > 0.88:
				continue
			var gg: Dictionary = geoms[hi]
			var a := maxf(0.0, 1.0 - age / 0.88)
			var open := minf(1.0, age / 0.14)
			_local(gg.c, gg.k)
			var kk := -1.5
			while kk <= 1.5:
				var y0 := kk * 22.0
				for side in [-1, 1]:
					var reach := (56.0 + (2.0 - absf(kk)) * 12.0) * open
					draw_sketch_shape(PackedVector2Array([
						Vector2(side * 6.0, y0 - 5.0), Vector2(side * (reach * 0.65), y0 - 16.0 * open),
						Vector2(side * reach, y0 + 6.0 * open), Vector2(side * (reach * 0.58), y0 - 4.0 * open),
						Vector2(side * 4.0, y0 + 5.0)]), f_idx + int(round(kk * 7.0)) + side * 5 + hi * 13, pal, 2.0, FILL_BODY, 2.0, a)
				kk += 1.0
			for d in 8:
				var ang := (float(d) / 8.0) * TAU + 0.2
				var dist := 16.0 + age * 115.0
				var bx := cos(ang) * dist
				var by := sin(ang) * dist + 70.0 * age * age
				draw_sketch_shape(PackedVector2Array([Vector2(bx - 3.0, by - 3.0), Vector2(bx + 5.0, by), Vector2(bx - 1.0, by + 5.0)]),
					f_idx + d, pal, 1.2, pal.accent, 1.3, a)
			_unlocal(),
		func(_fx: Node2D, t: float) -> void:
			var qt := _q(t)
			set_darken(0.16)
			var env_by: Array = [0.0, 0.0]
			var inv_by: Array = [0.0, 0.0]
			for hi in 2:
				var age := qt - HIT_SPINE[hi]
				var gg: Dictionary = geoms[hi]
				if age >= 0.0 and age < 0.95:
					var env := 1.0 - age / 0.95
					set_field(StringName("spine%d" % hi), {"mode": 0, "cx": gg.c.x, "cy": gg.c.y, "rx": (76.0 * env + 18.0) * gg.k, "ry": (60.0 * env + 14.0) * gg.k,
						"env": env, "pal": pal, "profile": &"v3"})
				else:
					clear_field(StringName("spine%d" % hi))
				if age >= 0.0 and age < 0.9:
					env_by[hi] = (1.0 - age / 0.9) * 9.0 * float(gg.k)
					inv_by[hi] = 1.0 if age < 0.14 else 0.0
			for hi in 2:
				if env_by[hi] > 0.0 or (same and hi == 0):
					var amp: float = maxf(env_by[0], env_by[1]) if same else env_by[hi]
					var inv: float = maxf(inv_by[0], inv_by[1]) if same else inv_by[hi]
					drive_target_warp(units[hi], amp, inv)
				elif not same:
					drive_target_warp(units[hi], 0.0, 0.0),
		func(_fx: Node2D) -> void: _release_all(all_units))


# ---- 4. VULN PIERCE (v3 renderVulnPierce) ---------------------------------------------------------------------
func play_vuln_pierce(caster: BattleUnit, target: BattleUnit, doubled: bool = true) -> float:
	var g := unit_geom(target)
	var c: Vector2 = g.c
	var k: float = g.k
	var pal := _pb_v3()  # normal: ZERO dourado
	return add_effect(DURATIONS[&"vuln_pierce"], func(_fx: Node2D, t: float) -> void:
		var qt := _q(t)
		var f_idx := boil_index(t)
		var hit := qt >= HIT_VULN
		var age := maxf(0.0, qt - HIT_VULN)
		_local(c, k)
		if not hit:
			var gg := minf(1.0, qt / 0.45)
			draw_sketch_eye(0.0, 0.0, 26.0 * gg, 12.0 * gg, f_idx, pal, false)
		elif age < 0.72:
			var a := maxf(0.0, 1.0 - age / 0.72)
			draw_sketch_shape(PackedVector2Array([Vector2(-190, -10), Vector2(195, 0), Vector2(-190, 10)]), f_idx, pal, 2.8, FILL_BODY, 2.2, a)
			for i in 10:
				var ang := (float(i) / 10.0) * TAU + 0.3
				var d := 16.0 + age * 150.0
				var sx := cos(ang) * d
				var sy := sin(ang) * d * 0.7
				draw_sketch_shape(PackedVector2Array([Vector2(sx - 6.0, sy - 4.0), Vector2(sx + 7.0, sy), Vector2(sx - 2.0, sy + 6.0)]),
					f_idx + i * 5, pal, 1.8, FILL_BODY, 2.0, a)
		_unlocal(),
		func(_fx: Node2D, t: float) -> void:
			var qt := _q(t)
			var hit := qt >= HIT_VULN
			var age := maxf(0.0, qt - HIT_VULN)
			var env := (qt / HIT_VULN) * 0.45 if not hit else maxf(0.0, 1.0 - age / 0.95)
			set_darken(0.14)
			set_field(&"vuln", {"mode": 0, "cx": c.x, "cy": c.y, "rx": (44.0 + env * 86.0) * k, "ry": (36.0 + env * 66.0) * k,
				"env": env, "pal": pal, "profile": &"v3"})
			drive_target_warp(target, env * 12.0 * k, 1.0 if (hit and age < 0.16) else 0.0),
		func(_fx: Node2D) -> void: _release_all([target]))


# ---- 5. DARK BREATH v2 (v4 renderDarkBreath) ------------------------------------------------------------------
func play_dark_breath(caster: BattleUnit, targets: Array, dodged_ids: Array = []) -> float:
	var pal := palette_for(&"abyss", false)
	pal["hi"] = PAL_ABYSS_DARK.hi_breath
	var player_cast := caster == null or caster.is_player
	var dir := 1.0 if player_cast else -1.0
	var geoms: Array = []
	var k := 1.0
	var my := 0.0
	for u in targets:
		var gg := unit_geom(u)
		geoms.append(gg)
		k += float(gg.k)
		my += float(gg.c.y)
	k = (k - 1.0) / maxf(1.0, float(targets.size()))
	my = my / maxf(1.0, float(targets.size()))
	# Alvos aliados: o sopro roda na linha dos CARTOES (a boca fica na borda direita, na altura dos cartoes), nunca sobre a
	# figura do inimigo que ataca (ordem do criador).
	var mx := 104.0 if player_cast else 816.0 - 104.0
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 4242
	var streams: Array = []
	for i in 28:
		streams.append({"delay": 0.28 + (float(i) / 28.0) * 0.95, "spread": (sketch_hash(float(i * 19 + 3)) - 0.5) * 0.44,
			"spd": 360.0 + sketch_hash(float(i * 23)) * 260.0, "wf": 0.04 + sketch_hash(float(i * 7)) * 0.05,
			"wa": 8.0 + sketch_hash(float(i * 11)) * 18.0, "life": 0.65 + sketch_hash(float(i * 13)) * 0.55,
			"thick": 1.4 + sketch_hash(float(i * 5)) * 2.2})
	var puffs: Array = []
	for i in 22:
		puffs.append({"delay": 0.30 + (float(i) / 22.0) * 1.05, "spread": (sketch_hash(float(i * 31 + 1)) - 0.5) * 0.42,
			"spd": 290.0 + sketch_hash(float(i * 41)) * 210.0, "base_r": 9.0 + sketch_hash(float(i * 17)) * 14.0,
			"life": 0.7 + sketch_hash(float(i * 29)) * 0.55})
	var open_of := func(t: float) -> float:
		return t / 0.28 if t < 0.28 else (1.0 if t < 1.95 else maxf(0.0, 1.0 - (t - 1.95) / 0.5))
	var jaw_of := func(t: float) -> float:
		var b_age := maxf(0.0, t - BREATH_START)
		var pulse := sin(t * 26.0) * 2.6 if (b_age > 0.0 and t < 1.95) else 0.0
		return 44.0 * k * float(open_of.call(t)) + pulse * k
	return add_effect(DURATIONS[&"dark_breath"], func(_fx: Node2D, t: float) -> void:
		var qt := _q(t)
		var f_idx := boil_index(t)
		var open: float = open_of.call(t)
		var b_age := maxf(0.0, t - BREATH_START)
		var jaw: float = jaw_of.call(t)
		# 2) alvos atingidos: olho riscado em X (somente quem não desviou)
		for i in targets.size():
			var u: BattleUnit = targets[i]
			if dodged_ids.has(u.id):
				continue
			var gg: Dictionary = geoms[i]
			var hit_t := BREATH_START + absf(float(gg.c.x) - mx) / BREATH_SPEED
			var age := qt - hit_t
			if age >= 0.0 and age < 1.5:
				var fa := maxf(0.0, 1.0 - maxf(0.0, age - 0.8) / 0.7)
				draw_sketch_eye(float(gg.c.x), float(gg.c.y) - 34.0 * float(gg.k), 17.0 * float(gg.k), 7.0 * float(gg.k), f_idx + i * 9, pal, true, false, fa)
		# 3) correntes de ar e nuvens negras, de dentro da garganta
		if b_age > 0.0:
			for si in streams.size():
				var s: Dictionary = streams[si]
				var sa := t - float(s.delay)
				if sa < 0.0 or sa > float(s.life):
					continue
				var kk := sa / float(s.life)
				var a := (kk / 0.15 if kk < 0.15 else 1.0 - (kk - 0.15) / 0.85) * 0.88
				var dist_head := sa * float(s.spd)
				var dist_tail := maxf(0.0, dist_head - (78.0 + kk * 92.0))
				var line := PackedVector2Array()
				for j in 9:
					var d := dist_tail + (dist_head - dist_tail) * (float(j) / 8.0)
					var px: float = mx - 4.0 * dir + cos(float(s.spread)) * d * dir
					var py: float = my + sin(float(s.spread)) * d + sin(d * float(s.wf) - t * 18.0 + float(si)) * float(s.wa) * k * (d / 320.0)
					line.append(Vector2(px, py))
				var col: Color = pal.hi if si % 3 == 0 else pal.accent
				draw_polyline(line, Color(col, a), float(s.thick) * (1.0 - kk * 0.4) * k, false)
			for pi in puffs.size():
				var p: Dictionary = puffs[pi]
				var pa := qt - float(p.delay)
				if pa < 0.0 or pa > float(p.life):
					continue
				var kk := pa / float(p.life)
				var a := (kk / 0.15 if kk < 0.15 else 1.0 - (kk - 0.15) / 0.85) * 0.80
				var d := pa * float(p.spd)
				var px: float = mx + 2.0 * dir + cos(float(p.spread)) * d * dir
				var py: float = my + sin(float(p.spread)) * d + sin(d * 0.04 + float(pi)) * 14.0 * k
				var rad := float(p.base_r) * k * (0.45 + kk * 1.45)
				var pts := PackedVector2Array()
				for v in 9:
					var ang := (float(v) / 9.0) * TAU
					var rr := rad * (0.75 + sketch_hash(float(pi * 13 + v * 5)) * 0.5)
					pts.append(Vector2(px + cos(ang) * rr, py + sin(ang) * rr))
				draw_sketch_shape(pts, f_idx + pi * 3, pal, 2.2, Color("040108"), 1.4, a)
		# 4) maxilares + dentes tortos POR CIMA do sopro
		if open > 0.02:
			var al := minf(1.0, open * 1.2)
			var upper := PackedVector2Array()
			for v in [Vector2(-44, -6), Vector2(-16, -jaw / k - 18), Vector2(34, -jaw / k - 4), Vector2(22, -jaw / k + 16), Vector2(14, -jaw / k + 4),
					Vector2(6, -jaw / k + 18), Vector2(-2, -jaw / k + 5), Vector2(-12, -jaw / k + 14), Vector2(-24, -4)]:
				upper.append(Vector2(mx + v.x * dir * k, my + v.y * k))
			draw_sketch_shape(upper, f_idx + 5, pal, 2.0 * k, FILL_BODY, 2.0, al)
			var lower := PackedVector2Array()
			for v in [Vector2(-44, 6), Vector2(-24, 4), Vector2(-10, jaw / k - 14), Vector2(-2, jaw / k - 5), Vector2(8, jaw / k - 18),
					Vector2(16, jaw / k - 5), Vector2(26, jaw / k - 15), Vector2(32, jaw / k + 6), Vector2(-16, jaw / k + 18)]:
				lower.append(Vector2(mx + v.x * dir * k, my + v.y * k))
			draw_sketch_shape(lower, f_idx + 11, pal, 2.0 * k, FILL_BODY, 2.0, al),
		func(_fx: Node2D, t: float) -> void:
			var qt := _q(t)
			var b_age := maxf(0.0, t - BREATH_START)
			var reach := minf(816.0 - mx + 40.0 if player_cast else mx + 40.0, b_age * BREATH_SPEED) if b_age > 0.0 else 0.0
			var breath_env := minf(1.0, b_age / 0.25) if t < 2.0 else maxf(0.0, 1.0 - (t - 2.0) / 0.75)
			var dark := 0.48 * minf(1.0, t / 0.3) * (1.0 if t < 2.15 else maxf(0.0, 1.0 - (t - 2.15) / 0.75))
			set_darken(dark)
			if b_age > 0.0:
				set_field(&"breath", {"mode": 1, "mouth": Vector2(mx - 6.0 * dir, my), "reach": reach, "dir_x": dir, "env": breath_env * 0.92,
					"pal": pal, "profile": &"v4", "cone_scale": k})
			for i in targets.size():
				var u: BattleUnit = targets[i]
				if dodged_ids.has(u.id):
					continue
				var gg: Dictionary = geoms[i]
				var hit_t := BREATH_START + absf(float(gg.c.x) - mx) / BREATH_SPEED
				var age := qt - hit_t
				var env := 1.0 - age / 1.2 if (age >= 0.0 and age < 1.2) else 0.0
				drive_target_warp(u, env * 11.0 * float(gg.k), 0.0),  # 0 de dano: sem flash de inversão
		func(_fx: Node2D) -> void: _release_all(targets),
		func(_fx: Node2D, t: float, canvas: Node2D) -> void:
			# camada 0: garganta negra funda, ATRÁS do cone de Moiré
			var open: float = open_of.call(t)
			if open <= 0.02:
				return
			var jaw: float = jaw_of.call(t)
			var f_idx := boil_index(t)
			var th := PackedVector2Array()
			for v in [Vector2(-46, -10), Vector2(-18, -jaw / k - 10), Vector2(18, -jaw / k + 6), Vector2(22, 0), Vector2(18, jaw / k - 6),
					Vector2(-18, jaw / k + 10), Vector2(-46, 10)]:
				th.append(Vector2(mx + v.x * dir * k, my + v.y * k))
			canvas.fill_poly(sketchy_pts(th, f_idx, 2.2 * k), Color("020005", minf(1.0, open * 1.2)))
			var hi: Color = pal.hi
			canvas.draw_polyline(_closed(sketchy_pts(th, f_idx, 2.2 * k)), Color(hi, minf(1.0, open * 1.2)), 1.6, false))


# ---- 6. UMBRAL GAZE (v3 renderUmbralGaze) ---------------------------------------------------------------------
func play_umbral_gaze(caster: BattleUnit, target: BattleUnit) -> float:
	var g := unit_geom(target)
	var c: Vector2 = g.c
	var k: float = g.k
	var fy: float = float(g.h) * 0.52  # relativo ao centro: os pés do alvo
	var pal := palette_for(&"abyss", false)
	return add_effect(DURATIONS[&"umbral_gaze"], func(_fx: Node2D, t: float) -> void:
		var qt := _q(t)
		var f_idx := boil_index(t)
		var hit := qt >= HIT_UMBRAL
		var age := maxf(0.0, qt - HIT_UMBRAL)
		var fade := 1.0 if qt < 2.25 else maxf(0.0, 1.0 - (qt - 2.25) / 0.6)
		var gg := minf(1.0, qt / 0.42)
		draw_sketch_eye(c.x, c.y + fy, 76.0 * gg * k, 17.0 * gg * k, f_idx, pal, false, true, fade)
		if hit:
			var r := minf(1.0, age / 0.16)
			_local(Vector2(c.x, c.y + fy), k)
			var i := 0
			for ox in [-48.0, -24.0, 0.0, 24.0, 48.0]:
				var sh := (92.0 + float(i % 2) * 38.0) * r
				var bend := float(i - 2) * -10.0
				draw_sketch_shape(PackedVector2Array([Vector2(ox - 6.0, 0.0), Vector2(ox + bend * 0.5 - 4.0, -sh * 0.55), Vector2(ox + bend, -sh),
					Vector2(ox + bend * 0.5 + 5.0, -sh * 0.55), Vector2(ox + 6.0, 0.0)]), f_idx + i * 7, pal, 2.5, FILL_BODY_DARK, 1.6, fade)
				i += 1
			_unlocal(),
		func(_fx: Node2D, t: float) -> void:
			var qt := _q(t)
			var hit := qt >= HIT_UMBRAL
			var age := maxf(0.0, qt - HIT_UMBRAL)
			var fade := 1.0 if qt < 2.25 else maxf(0.0, 1.0 - (qt - 2.25) / 0.6)
			var env := minf(0.95, qt / 0.45) * fade
			set_darken(0.56 * env)
			set_field(&"umbral", {"mode": 0, "cx": c.x, "cy": c.y + 18.0 * k, "rx": 96.0 * env * k, "ry": 78.0 * env * k, "env": env * 0.92,
				"pal": pal, "profile": &"v3", "dark_bias": true})
			drive_target_warp(target, env * 8.0 * k, 1.0 if (hit and age < 0.12) else 0.0),
		func(_fx: Node2D) -> void: _release_all([target]))


# ---- 7. IGNOMA (v3 renderIgnoma) ------------------------------------------------------------------------------
func play_ignoma(caster: BattleUnit, target: BattleUnit) -> float:
	var g := unit_geom(target)
	var c: Vector2 = g.c
	var k: float = g.k
	var src := _origin_of(caster)
	var pal := palette_for(&"fire", false)
	var arc := 52.0 * k
	var pos_at := func(p: float) -> Vector2:
		return Vector2(src.x + (c.x - src.x) * p, src.y + (c.y - src.y) * p - sin(p * PI) * arc)
	return add_effect(DURATIONS[&"ignoma"], func(_fx: Node2D, t: float) -> void:
		var qt := _q(t)
		var f_idx := boil_index(t)
		var hit := qt >= HIT_IGNOMA
		var age := maxf(0.0, qt - HIT_IGNOMA)
		var p := minf(1.0, qt / HIT_IGNOMA)
		if not hit:
			var p2 := maxf(0.0, p - 0.12)
			var tp: Vector2 = pos_at.call(p2)
			var bp: Vector2 = pos_at.call(p)
			draw_sketch_flame(tp.x, tp.y, 0.55 * k, f_idx + 5, pal, pal.deep, 0.55)
			draw_sketch_flame(bp.x, bp.y, 1.0 * k, f_idx, pal, pal.deep, 0.96)
		elif age < 0.95:
			var kk := age / 0.95
			var a := 1.0 - kk
			draw_sketch_flame(c.x, c.y + (12.0 - kk * 24.0) * k, (1.45 + kk * 0.7) * k, f_idx, pal, pal.deep, a)
			draw_sketch_flame(c.x - (36.0 + kk * 24.0) * k, c.y + (18.0 - kk * 14.0) * k, 0.85 * k, f_idx + 7, pal, pal.deep, a)
			draw_sketch_flame(c.x + (36.0 + kk * 24.0) * k, c.y + (18.0 - kk * 14.0) * k, 0.85 * k, f_idx + 13, pal, pal.deep, a),
		func(_fx: Node2D, t: float) -> void:
			var qt := _q(t)
			var hit := qt >= HIT_IGNOMA
			var age := maxf(0.0, qt - HIT_IGNOMA)
			var env := 0.55 if not hit else maxf(0.0, 1.0 - age / 0.95)
			var p := minf(1.0, qt / HIT_IGNOMA)
			var bp: Vector2 = pos_at.call(p) if not hit else c
			set_darken(env * 0.22 if hit else 0.1)
			set_field(&"ignoma", {"mode": 0, "cx": bp.x, "cy": bp.y, "rx": (44.0 if not hit else 44.0 + (1.0 - env) * 96.0) * k,
				"ry": (38.0 if not hit else 38.0 + (1.0 - env) * 78.0) * k, "env": env, "pal": pal, "profile": &"v3"})
			drive_target_warp(target, (env * 10.0 * k) if hit else 0.0, 1.0 if (hit and age < 0.14) else 0.0),
		func(_fx: Node2D) -> void: _release_all([target]))


# ---- 8. IGNOMA ESH [ZAHAV] (v4 renderIgnomaEsh) ---------------------------------------------------------------
func play_ignoma_esh(caster: BattleUnit, targets: Array) -> float:
	var t0: BattleUnit = targets[0]
	var t1: BattleUnit = targets[1] if targets.size() > 1 else targets[0]
	var units: Array = [t0, t1]
	var geoms: Array = [unit_geom(t0), unit_geom(t1)]
	var src := _origin_of(caster)
	var pal := palette_for(&"fire", true)
	var rng_e := RandomNumberGenerator.new()
	rng_e.seed = 7788
	var starts: Array[float] = [0.08, 0.44]
	var arcs: Array[float] = [52.0, 82.0]
	var bursts: Array = []
	for oi in 2:
		var burst: Array = []
		for i in 38:
			var a := (float(i) / 38.0) * TAU + (rng_e.randf() - 0.5) * 0.2
			var sp := 68.0 + rng_e.randf() * 185.0
			burst.append({"vx": cos(a) * sp, "vy": sin(a) * sp - 22.0, "ch": ("אש".substr(i % 2, 1)) if i % 3 == 0 else HEBREW_ALPHABET.substr(rng_e.randi_range(0, HEBREW_ALPHABET.length() - 1), 1),
				"sz": 12.0 + rng_e.randf() * 11.0, "ci": i % 3, "life": 0.54 + rng_e.randf() * 0.48})
		bursts.append(burst)
	var pos_at := func(oi: int, p: float) -> Vector2:
		var gg: Dictionary = geoms[oi]
		var k: float = gg.k
		return Vector2(src.x + (float(gg.c.x) - src.x) * p, src.y + (float(gg.c.y) - src.y) * p - sin(p * PI) * arcs[oi] * k)
	return add_effect(DURATIONS[&"ignoma_esh"], func(_fx: Node2D, t: float) -> void:
		var qt := _q(t)
		var f_idx := boil_index(t)
		for oi in 2:
			var gg: Dictionary = geoms[oi]
			var k: float = gg.k
			if qt >= starts[oi] and qt < HIT_ESH[oi]:
				var p := (qt - starts[oi]) / (HIT_ESH[oi] - starts[oi])
				var bp: Vector2 = pos_at.call(oi, p)
				draw_sketch_flame(bp.x, bp.y, 0.95 * k, f_idx + oi * 5, pal, pal.deep, 1.0, &"v4")
				draw_hebrew_tri_word("אש", Vector2(bp.x, bp.y + 4.0 * k), int(round(18.0 * k)), 0.95)
			elif t >= HIT_ESH[oi]:
				var age := t - HIT_ESH[oi]
				var c: Vector2 = gg.c
				if age < 0.55:
					draw_sketch_flame(c.x, c.y + (8.0 - age * 24.0) * k, (1.35 + age * 1.1) * k, f_idx + oi * 7, pal, Color(0, 0, 0, 0), maxf(0.0, 1.0 - age / 0.55), &"v4")
				for b in bursts[oi]:
					if age > float(b.life):
						continue
					var a := maxf(0.0, 1.0 - age / float(b.life))
					var col: Color = FIRE_HEBREW[int(b.ci)]
					var ks := sqrt(k)
					var pos := Vector2(c.x + float(b.vx) * age * ks, c.y + float(b.vy) * age * ks + 85.0 * age * age * ks)
					var stage_d := Rect2(stage_rect().position * DESIGN_SCALE, stage_rect().size * DESIGN_SCALE).grow(-14.0)
					if not stage_d.has_point(pos):
						continue  # as letras nunca cobrem o HUD superior, o Battle Log nem os cartoes (D-125)
					draw_string(font, pos, str(b.ch), HORIZONTAL_ALIGNMENT_CENTER, -1, int(float(b.sz) * ks), Color(col, a))
				if age < 0.95:
					draw_hebrew_tri_word("אש", Vector2(c.x, c.y - (26.0 + age * 20.0) * k), int(round(32.0 * k)), 1.0 - age / 0.95),
		func(_fx: Node2D, t: float) -> void:
			var qt := _q(t)
			set_darken(0.22)
			var warp_amp: Array = [0.0, 0.0]
			var warp_inv: Array = [0.0, 0.0]
			for oi in 2:
				var gg: Dictionary = geoms[oi]
				var k: float = gg.k
				var key := StringName("esh%d" % oi)
				if qt >= starts[oi] and qt < HIT_ESH[oi]:
					var p := (qt - starts[oi]) / (HIT_ESH[oi] - starts[oi])
					var bp: Vector2 = pos_at.call(oi, p)  # o Moiré segue EXATAMENTE o arco da própria bola (52 / 82)
					set_field(key, {"mode": 0, "cx": bp.x, "cy": bp.y, "rx": 42.0 * k, "ry": 36.0 * k, "env": 0.55, "pal": pal, "profile": &"v4"})
				elif qt >= HIT_ESH[oi] and qt - HIT_ESH[oi] < 0.95:
					var env := 1.0 - (qt - HIT_ESH[oi]) / 0.95
					set_field(key, {"mode": 0, "cx": gg.c.x, "cy": gg.c.y, "rx": (46.0 + (1.0 - env) * 88.0) * k, "ry": (40.0 + (1.0 - env) * 74.0) * k,
						"env": env, "pal": pal, "profile": &"v4"})
				else:
					clear_field(key)
				var age := qt - HIT_ESH[oi]
				if age >= 0.0 and age < 0.9:
					warp_amp[oi] = (1.0 - age / 0.9) * 9.0 * k
					warp_inv[oi] = 1.0 if age < 0.14 else 0.0
			for oi in 2:
				if units[0] == units[1] and oi == 1:
					continue
				var amp: float = maxf(warp_amp[0], warp_amp[1]) if units[0] == units[1] else warp_amp[oi]
				var inv: float = maxf(warp_inv[0], warp_inv[1]) if units[0] == units[1] else warp_inv[oi]
				drive_target_warp(units[oi], amp, inv),
		func(_fx: Node2D) -> void: _release_all(units))

