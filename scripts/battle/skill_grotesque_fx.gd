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
## D-131 (Lote 2): paletas dos 7 ataques (zero ouro nas normais; `#ffd84a` só no ZAHAV).
const PAL_STONE := {"accent": Color("6d5e52"), "hi": Color("d9cfc2"), "deep": Color("16110e")}
const PAL_ENERGY := {"accent": Color("553675"), "hi": Color("c9bde0"), "deep": Color("0b0514")}
const PAL_BLUE_STAT := {"accent": Color("25568a"), "hi": Color("9fc9ec"), "deep": Color("061124")}
const PAL_ZAHAV_BLUE := {"accent": Color("2b669e"), "hi": Color("ffd84a"), "deep": Color("08162b")}
const PAL_SUN_NORMAL := {"accent": Color("c94c14"), "hi": Color("f2d9b6"), "deep": Color("240903")}
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
			&"blue": return PAL_ZAHAV_BLUE.duplicate()
			&"fire": return PAL_ZAHAV_FIRE.duplicate()
			_:
				var p: Dictionary = PAL_ABYSS_DARK.duplicate()
				p["hi"] = GOLD
				return p
	match family:
		&"blood": return PAL_BLOOD.duplicate()
		&"fire": return PAL_FIRE_NORMAL.duplicate()
		&"stone": return PAL_STONE.duplicate()
		&"energy": return PAL_ENERGY.duplicate()
		&"blue": return PAL_BLUE_STAT.duplicate()
		&"sun": return PAL_SUN_NORMAL.duplicate()
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
	# D-131: no cartão do aliado o Moiré é "livre" (HTML allowOverCards: passa do palco); `min_y` segura a borda de cima
	# (a marca de Mark of Sun nunca invade o Battle Log).
	if bool(spec.get("free", false)):
		var screen: Vector2 = hud.SCREEN if hud != null else Vector2(544.0, 416.0)
		stage_d = Rect2(0.0, STAGE_TOP * DESIGN_SCALE, screen.x * DESIGN_SCALE, (screen.y - STAGE_TOP) * DESIGN_SCALE)
	if spec.has("min_y"):
		var top := maxf(stage_d.position.y, float(spec.min_y))
		stage_d = Rect2(stage_d.position.x, top, stage_d.size.x, maxf(0.0, stage_d.end.y - top))
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


## `include_sun` false: a marca persistente de Mark of Sun (campo `sunm_*`) sobrevive ao fim de um efeito.
func clear_fields(include_sun: bool = false) -> void:
	for key in _fields.keys():
		if include_sun or not _is_sun_key(key):
			clear_field(key)


## Campos de efeito vivos (a marca persistente de Mark of Sun não conta como efeito em andamento).
func field_count() -> int:
	var n := 0
	for key in _fields.keys():
		if not _is_sun_key(key):
			n += 1
	return n


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
	return not _effects.is_empty() or field_count() > 0 or not _warps.is_empty() or _darken > 0.01 or time < _shake_until


func clear_all() -> void:
	for e in _effects:
		var on_end: Callable = e.end
		if on_end.is_valid():
			on_end.call(self)
	_effects.clear()
	clear_fields(true)
	_sun_pulse.clear()
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
	_sun_step()
	for key in _fields.keys():
		var spec: Dictionary = _fields[key].spec
		set_field(key, spec)  # atualiza time_val do shader
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE / DESIGN_SCALE)
	for e in _effects:
		var drawer: Callable = e.draw
		if drawer.is_valid():
			drawer.call(self, time - float(e.at))
	_draw_suns()
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
	&"dark_breath": 2.95, &"umbral_gaze": 2.85, &"ignoma": 2.45, &"ignoma_esh": 2.85,
	# D-131 (README do canônico). Mark of Sun: só o ACENDER (0,65 s); depois vale a marca persistente.
	&"stone_crush": 2.55, &"energy_blow": 2.65, &"drain_claw": 2.25, &"vital_claws": 2.40, &"weaken": 2.45, &"weakenen": 2.50,
	&"mark_of_sun": 0.67}
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


# ====================================================================================================================
# D-131 (criador 2026-11-27): Lote 2 — Stone Crush, Energy Blow, Drain Claw, Vital Claws [ZAHAV], Weaken, Weakenen [ZAHAV]
# e Mark of Sun. Porte 1:1 de docs/vfx_refs/d131/d131_skills_vfx_canon.html (README: tempos, camadas, paletas). O alvo é
# sempre o referencial local (centro `c`, escala `k`): num inimigo é a figura; num aliado é o CARTÃO, com o MESMO k.
# Em aliados o Moiré é "livre" (pode passar do palco, HTML `allowOverCards`) e a marca persistente de Mark of Sun nunca
# invade o Battle Log (`min_y`).
# ====================================================================================================================

const HIT_STONE := 0.62
const HIT_ENERGY := 0.56
const HIT_DRAIN := 0.36
const HIT_VITAL_CLAWS: Array[float] = [0.34, 0.48]
const HIT_VITAL := 0.48              # a mecânica fecha com a 2ª garra (o número aparece nesse instante)
const HIT_WEAKEN := 0.58
const HIT_WEAKENEN: Array[float] = [0.78, 0.90]
const HIT_SUN := 0.65                # a marca acende
const SUN_TRIGGER_DUR := 0.48
const INK_DEEP := Color("050208")
const EN_PAL := {"accent": Color("2c5078"), "hi": Color("9fc9ec")}
const EN_DROP_PAL := {"accent": Color("2b669e"), "hi": Color("ffd84a")}

## id da unidade -> intensidade (0..1) do pulso do sol enquanto o clarão de um golpe dura.
var _sun_pulse: Dictionary = {}


# ---- primitivas novas (porte de drawSketchLine / drawSketchOrb / drawSingleImpaleClaw / drawSolarHitFlare) -------

## drawSketchLine: traço aberto sujo (um só traço de `col`).
func draw_sketch_line(pts: PackedVector2Array, f_idx: int, col: Color, line_w: float = 2.0, jitter: float = 2.0, alpha: float = 1.0) -> void:
	if pts.size() < 2:
		return
	draw_polyline(sketchy_pts(pts, f_idx, jitter), Color(col, col.a * alpha), line_w, false)


## drawSketchOrb: esfera rabiscada (2 anéis tortos girando em sentidos opostos + núcleo escuro).
func _draw_sketch_orb(center: Vector2, radius: float, f_idx: int, pal: Dictionary, alpha: float = 1.0) -> void:
	for kk in [1, 0]:
		var rr: float = radius * (0.62 + float(kk) * 0.38)
		var pts := PackedVector2Array()
		for i in 14:
			var a := (float(i) / 14.0) * TAU + float(f_idx) * (0.18 if kk == 1 else -0.16)
			var wob := 1.0 + (sketch_hash(float(f_idx * 17 + i * 11 + kk * 53)) - 0.5) * 0.24
			pts.append(center + Vector2(cos(a), sin(a)) * rr * wob)
		var fill_col: Color = pal.deep if kk == 0 else Color(0, 0, 0, 0)
		draw_sketch_shape(pts, f_idx + kk * 23, pal, 2.0 + float(kk) * 0.6, fill_col, 2.3 if kk == 1 else 1.6, alpha)
	var core := PackedVector2Array()
	for i in 9:
		var a2 := (float(i) / 9.0) * TAU
		core.append(center + Vector2(cos(a2), sin(a2)) * radius * 0.32)
	_fill_poly(sketchy_pts(core, f_idx + 91, 1.2), Color(FILL_BODY_DARK, alpha))


## drawSingleImpaleClaw: UMA garra afiada com a ponta em `tip` (px de design absolutos), `angle` e comprimento `length`
## (unidades locais, escaladas por `k`). Desenha no próprio transform (rotação) e devolve ao de design.
func _draw_single_impale_claw(tip: Vector2, angle: float, length: float, k: float, f_idx: int, pal: Dictionary, alpha: float = 1.0) -> void:
	if alpha <= 0.01:
		return
	var claw := PackedVector2Array([
		Vector2(0, 0), Vector2(-length * 0.28, -length * 0.14), Vector2(-length * 0.65, -length * 0.18), Vector2(-length, -length * 0.08),
		Vector2(-length * 0.92, length * 0.12), Vector2(-length * 0.52, length * 0.06), Vector2(-length * 0.22, length * 0.04)])
	draw_set_transform(tip / DESIGN_SCALE, angle, Vector2(k, k) / DESIGN_SCALE)
	draw_sketch_shape(claw, f_idx, pal, 1.9, FILL_BODY, 2.2, alpha)
	_unlocal()


## drawSolarHitFlare: anel solar rabiscado + estrela de 8 raios finos + núcleo breve de clarão osso-quente. SEM triângulos,
## SEM cone trapezoide. `min_y` (design) segura os pontos acima do limite (aliado: logo abaixo do Battle Log).
func _draw_solar_hit_flare(center: Vector2, trig_prog: float, trig_env: float, f_idx: int, pal: Dictionary, min_y: float, ally_mode: bool, k: float = 1.0) -> void:
	if trig_env <= 0.02:
		return
	var ring_r := (14.0 + trig_prog * 56.0) * k
	var ring := PackedVector2Array()
	for i in 14:
		var a := (float(i) / 14.0) * TAU + float(f_idx) * 0.14
		ring.append(Vector2(center.x + cos(a) * ring_r, maxf(min_y, center.y + sin(a) * ring_r * (0.56 if ally_mode else 0.88))))
	draw_sketch_shape(ring, f_idx + 17, pal, 2.4, Color(0, 0, 0, 0), 2.2, trig_env)
	var main_len := (30.0 + (1.0 - trig_prog) * 44.0) * k
	var diag_len := main_len * 0.58
	for i in 8:
		var a2 := (float(i) / 8.0) * TAU + (0.0 if i % 2 == 0 else 0.08)
		var len := main_len if i % 2 == 0 else diag_len
		var ry_scale := 0.58 if ally_mode else 0.95
		var p1 := Vector2(center.x + cos(a2) * 6.0 * k, maxf(min_y, center.y + sin(a2) * 6.0 * ry_scale * k))
		var p2 := Vector2(center.x + cos(a2) * len, maxf(min_y, center.y + sin(a2) * len * ry_scale))
		draw_sketch_line(PackedVector2Array([p1, p2]), f_idx + i * 9, pal.hi, 2.6 if i % 2 == 0 else 1.6, 1.8, trig_env)
		draw_sketch_line(PackedVector2Array([p1, p2]), f_idx + i * 9 + 41, pal.accent, 1.2, 2.2, trig_env)
	if trig_prog < 0.42:
		var core_r := (1.0 - trig_prog / 0.42) * 18.0 * k
		var core := PackedVector2Array()
		for i in 10:
			var a3 := (float(i) / 10.0) * TAU
			core.append(Vector2(center.x + cos(a3) * core_r, maxf(min_y, center.y + sin(a3) * core_r * (0.7 if ally_mode else 1.0))))
		var hi: Color = pal.hi
		_fill_poly(sketchy_pts(core, f_idx + 61, 1.6), Color(hi, hi.a * trig_env))


## Olho de Energy Blow (a íris escura `#261838` do HTML D-131; a claro é `#b8abc9`).
func _draw_eye_d131(cx: float, cy: float, rx: float, ry: float, f_idx: int, pal: Dictionary, dark_iris: bool, alpha: float = 1.0) -> void:
	var pts := PackedVector2Array()
	for i in 12:
		var a := (float(i) / 12.0) * TAU
		pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	draw_sketch_shape(pts, f_idx, pal, 1.4, Color("261838") if dark_iris else Color("b8abc9"), 2.0, alpha)
	var pupil := Vector2(cx + (sketch_hash(float(f_idx * 13 + 5)) - 0.5) * rx * 0.35, cy + (sketch_hash(float(f_idx * 19 + 9)) - 0.5) * ry * 0.25)
	var pr := maxf(2.5, minf(rx, ry) * 0.42)
	var pp := PackedVector2Array()
	for i in 8:
		var a2 := (float(i) / 8.0) * TAU
		pp.append(pupil + Vector2(cos(a2), sin(a2)) * pr)
	_fill_poly(sketchy_pts(pp, f_idx + 5, 0.9), Color(FILL_BODY_DARK, alpha))


## Gota (losango) de Drain Claw / Vital Claws que sobe do alvo ao conjurador.
func _draw_drop(p: Vector2, sz: float, f_idx: int, pal: Dictionary, fill_col: Color, diamond_en: bool = false) -> void:
	var pts: PackedVector2Array
	if diamond_en:
		pts = PackedVector2Array([Vector2(p.x, p.y - sz * 1.2), Vector2(p.x + sz, p.y), Vector2(p.x, p.y + sz * 1.2), Vector2(p.x - sz, p.y)])
	else:
		pts = PackedVector2Array([Vector2(p.x + sz * 1.3, p.y), Vector2(p.x, p.y - sz), Vector2(p.x - sz * 1.1, p.y), Vector2(p.x, p.y + sz)])
	draw_sketch_shape(pts, f_idx, pal, 1.1, fill_col, 1.5)


## Seta descendente de Weaken / Weakenen: haste (traço) + ponta em V.
func _draw_weak_arrow(ax: float, ay: float, ln: float, f_idx: int, hi_col: Color, accent: Color, big: bool, alpha: float) -> void:
	draw_sketch_line(PackedVector2Array([Vector2(ax, ay - ln), Vector2(ax, ay)]), f_idx, hi_col, 2.0 if big else 1.9, 1.4 if big else 1.3, alpha)
	var wing := 5.0 if big else 4.5
	var up := 6.0 if big else 5.5
	draw_sketch_line(PackedVector2Array([Vector2(ax - wing, ay - up), Vector2(ax, ay), Vector2(ax + wing, ay - up)]), f_idx + 3, accent, 1.8, 1.1 if big else 1.0, alpha)


# ---- 1. STONE CRUSH (renderStoneCrush) -----------------------------------------------------------------------------
func play_stone_crush(caster: BattleUnit, target: BattleUnit) -> float:
	var g := unit_geom(target)
	var c: Vector2 = g.c
	var k: float = g.k
	var ally := target.is_player
	var cv := (_origin_of(caster) - c) / k
	var pal := palette_for(&"stone", false)
	var arc := 85.0 if ally else 118.0
	var floor_y := 26.0 if ally else 52.0
	var debris: Array = []
	for i in 14:
		var a := -PI * 0.92 + (float(i) / 13.0) * PI * 0.84 + (sketch_hash(float(i * 17)) - 0.5) * 0.18
		var sp := 110.0 + sketch_hash(float(i * 31)) * 195.0
		debris.append({"vx": cos(a) * sp, "vy": sin(a) * sp - 45.0, "r": 5.0 + sketch_hash(float(i * 19)) * 10.0,
			"rot": sketch_hash(float(i * 13)) * TAU, "vr": (sketch_hash(float(i * 23)) - 0.5) * 8.0})
	var cracks: Array = []
	for i in 7:
		cracks.append({"a": (float(i) / 7.0) * TAU + sketch_hash(float(i * 11)) * 0.4, "len": 38.0 + sketch_hash(float(i * 29)) * 56.0})
	return add_effect(DURATIONS[&"stone_crush"], func(_fx: Node2D, t: float) -> void:
		var f_idx := boil_index(t)
		var post := maxf(0.0, t - HIT_STONE)
		var impact_env := maxf(0.0, 1.0 - post / 1.15) if post > 0.0 else 0.0
		_local(c, k)
		if post > 0.0 and impact_env > 0.05:
			var grow := minf(1.0, post / 0.18)
			var gy := 18.0 if ally else floor_y
			for idx in cracks.size():
				var cr: Dictionary = cracks[idx]
				var m := Vector2(cos(cr.a) * cr.len * 0.5 * grow, gy + sin(cr.a) * cr.len * 0.2 * grow)
				var e := Vector2(cos(cr.a) * cr.len * grow, gy + sin(cr.a) * cr.len * 0.32 * grow)
				var line := PackedVector2Array([Vector2(0, gy), m, e])
				var al := minf(1.0, impact_env * 1.4)
				draw_sketch_line(line, f_idx + idx * 7, INK_DEEP, 4.5, 1.8, al)
				draw_sketch_line(line, f_idx + idx * 7 + 3, pal.hi, 1.4, 1.5, al)
		if t < HIT_STONE + 0.14:
			var p := minf(1.0, t / HIT_STONE)
			var ease := p * p * (1.25 - 0.25 * p)
			var e1 := minf(1.0, ease)
			var b := Vector2(cv.x * (1.0 - e1), cv.y + (-6.0 - cv.y) * e1 - sin(p * PI) * arc)
			var rscale := 0.65 + p * 0.55
			var rot := t * 5.2
			var boulder := PackedVector2Array()
			for i in 13:
				var ang := (float(i) / 13.0) * TAU + rot
				var rad := (26.0 + sketch_hash(float(i * 19 + 3)) * 15.0) * rscale
				boulder.append(Vector2(b.x + cos(ang) * rad, b.y + sin(ang) * rad * 0.88))
			draw_sketch_shape(boulder, f_idx, pal, 3.0, FILL_BODY, 2.6)
			draw_sketch_line(PackedVector2Array([boulder[1], b, boulder[7]]), f_idx + 5, pal.accent, 1.8, 1.6)
			draw_sketch_line(PackedVector2Array([boulder[4], b + Vector2(4, -2), boulder[10]]), f_idx + 9, pal.hi, 1.2, 1.4)
		if post > 0.0 and post < 1.35:
			var da := maxf(0.0, 1.0 - post / 1.35)
			for idx in debris.size():
				var d: Dictionary = debris[idx]
				var dx: float = d.vx * post
				var dy: float = d.vy * post + 0.5 * 520.0 * post * post
				if dy > floor_y:
					dy = floor_y - absf(dy - floor_y) * 0.32
				var ang2: float = d.rot + d.vr * post
				var poly := PackedVector2Array()
				for kk in 5:
					var a2 := ang2 + (float(kk) / 5.0) * TAU
					var r: float = d.r * (0.7 + sketch_hash(float(idx * 7 + kk * 13)) * 0.55)
					poly.append(Vector2(dx + cos(a2) * r, dy + sin(a2) * r))
				draw_sketch_shape(poly, f_idx + idx * 5, pal, 1.4, FILL_BODY, 1.6, da)
		_unlocal(),
		func(_fx: Node2D, t: float) -> void:
			var post := maxf(0.0, t - HIT_STONE)
			var impact_env := maxf(0.0, 1.0 - post / 1.15) if post > 0.0 else 0.0
			if post > 0.0:
				set_field(&"stone", {"mode": 0, "cx": c.x, "cy": c.y + (0.0 if ally else 22.0 * k), "rx": 132.0 * k, "ry": 68.0 * k,
					"env": impact_env * 0.95, "pal": pal, "profile": &"v4", "free": ally})
			else:
				var p := minf(1.0, t / HIT_STONE)
				var bp := Vector2(cv.x * (1.0 - p), cv.y + (-8.0 - cv.y) * p - sin(p * PI) * arc)
				set_field(&"stone", {"mode": 0, "cx": c.x + bp.x * k, "cy": c.y + bp.y * k, "rx": 54.0 * k, "ry": 48.0 * k,
					"env": 0.55, "pal": pal, "profile": &"v4", "free": ally})
			drive_target_warp(target, impact_env * 13.0 * k, 1.0 if (post > 0.0 and post < 0.16) else 0.0)
			set_darken(impact_env * 0.24)
			if post > 0.0 and post < 0.42:
				camera_shake((1.0 - post / 0.42) * 11.0, 0.06),
		func(_fx: Node2D) -> void: _release_all([target]))


# ---- 2. ENERGY BLOW (renderEnergyBlow) -----------------------------------------------------------------------------
func play_energy_blow(caster: BattleUnit, target: BattleUnit) -> float:
	var g := unit_geom(target)
	var c: Vector2 = g.c
	var k: float = g.k
	var ally := target.is_player
	var cv := (_origin_of(caster) - c) / k
	var pal := palette_for(&"energy", false)
	var strands: Array = []
	for i in 16:
		strands.append({"delay": 0.64 + (float(i) / 16.0) * 0.48, "arc": (sketch_hash(float(i * 19)) - 0.5) * 110.0,
			"ox": (sketch_hash(float(i * 7)) - 0.5) * 40.0, "oy": (sketch_hash(float(i * 13)) - 0.5) * 52.0, "life": 0.72 + sketch_hash(float(i * 29)) * 0.32})
	return add_effect(DURATIONS[&"energy_blow"], func(_fx: Node2D, t: float) -> void:
		var f_idx := boil_index(t)
		var post := maxf(0.0, t - HIT_ENERGY)
		var charge_env := t / HIT_ENERGY if t < HIT_ENERGY else 0.0
		_local(c, k)
		if t < HIT_ENERGY:
			var s := 1.0 - charge_env * 0.35
			_draw_eye_d131(0.0, -4.0, 30.0 * s, 16.0 * s, f_idx, pal, true)
			for i in 8:
				var a := (float(i) / 8.0) * TAU + t * 2.2
				var r1 := 92.0 * (1.0 - charge_env * 0.75) + 16.0
				var r2 := r1 + 24.0
				draw_sketch_line(PackedVector2Array([Vector2(cos(a) * r1, sin(a) * r1), Vector2(cos(a) * r2, sin(a) * r2)]), f_idx + i * 5, pal.hi, 1.8, 1.6)
		if post > 0.0 and post < 0.72:
			var p := post / 0.72
			var b_scale := 0.45 + p * 1.15
			var burst := PackedVector2Array()
			for i in 24:
				var a2 := (float(i) / 24.0) * TAU + float(f_idx) * 0.06
				var rad := (58.0 + sketch_hash(float(i * 19)) * 32.0 if i % 2 == 0 else 22.0 + sketch_hash(float(i * 7)) * 10.0) * b_scale
				burst.append(Vector2(cos(a2) * rad, sin(a2) * rad * 0.85))
			draw_sketch_shape(burst, f_idx, pal, 3.4, FILL_BODY if p < 0.35 else Color(0, 0, 0, 0), 2.5, maxf(0.0, 1.0 - p))
		if post > 0.08:
			for idx in strands.size():
				var st: Dictionary = strands[idx]
				var lt: float = t - st.delay
				if lt < 0.0 or lt > st.life:
					continue
				var u: float = lt / st.life
				var sx: float = st.ox
				var sy: float = st.oy
				var pts := PackedVector2Array()
				for kk in 6:
					var ku := clampf(u - 0.24 + (float(kk) / 5.0) * 0.30, 0.0, 1.0)
					pts.append(Vector2(sx + (cv.x - sx) * ku, sy + (cv.y - sy) * ku + sin(ku * PI) * st.arc))
				var al := sin(u * PI)
				draw_sketch_line(pts, f_idx + idx * 7, EN_PAL.hi, 2.2, 2.0, al)
				draw_sketch_line(pts, f_idx + idx * 7 + 31, EN_PAL.accent, 1.3, 2.6, al)
		_unlocal(),
		func(_fx: Node2D, t: float) -> void:
			var post := maxf(0.0, t - HIT_ENERGY)
			var charge_env := t / HIT_ENERGY if t < HIT_ENERGY else 0.0
			var blast_env := maxf(0.0, 1.0 - post / 1.25) if post > 0.0 else 0.0
			if t < HIT_ENERGY:
				var r := (110.0 * (1.0 - charge_env * 0.72) + 18.0) * k
				set_field(&"energy", {"mode": 0, "cx": c.x, "cy": c.y, "rx": r, "ry": r * 0.85, "env": 0.85, "pal": pal, "profile": &"v3", "dark_bias": true, "free": ally})
			else:
				set_field(&"energy", {"mode": 0, "cx": c.x, "cy": c.y, "rx": 122.0 * (0.7 + (1.0 - blast_env) * 0.4) * k, "ry": 96.0 * k,
					"env": blast_env, "pal": pal, "profile": &"v3", "dark_bias": true, "free": ally})
			drive_target_warp(target, (charge_env * 5.0 if t < HIT_ENERGY else blast_env * 12.0) * k, 1.0 if (post > 0.0 and post < 0.15) else 0.0)
			set_darken(maxf(charge_env * 0.34, blast_env * 0.40))
			if post > 0.0 and post < 0.36:
				camera_shake((1.0 - post / 0.36) * 9.0, 0.06),
		func(_fx: Node2D) -> void: _release_all([target]))


# ---- 3. DRAIN CLAW / 3Z. VITAL CLAWS -------------------------------------------------------------------------------
func play_drain_claw(caster: BattleUnit, target: BattleUnit) -> float:
	var g := unit_geom(target)
	var c: Vector2 = g.c
	var k: float = g.k
	var cv := (_origin_of(caster) - c) / k
	var pal := palette_for(&"blood", false)
	var drops: Array = []
	for i in 6:
		drops.append({"delay": 0.44 + float(i) * 0.12, "arc": -20.0 - sketch_hash(float(i * 19)) * 34.0, "sz": 4.5 + sketch_hash(float(i * 13)) * 3.0, "life": 0.58})
	return add_effect(DURATIONS[&"drain_claw"], func(_fx: Node2D, t: float) -> void:
		var f_idx := boil_index(t)
		var post := maxf(0.0, t - HIT_DRAIN)
		if t < 1.38:
			var tip: Vector2
			var alpha := 1.0
			if t < HIT_DRAIN:
				var p := t / HIT_DRAIN
				var ease := p * p
				tip = Vector2(-105.0 * (1.0 - ease), 42.0 * (1.0 - ease))
			elif t < 1.05:
				tip = Vector2((sketch_hash(float(f_idx * 11)) - 0.5) * 3.0, (sketch_hash(float(f_idx * 17)) - 0.5) * 3.0)
			else:
				var out := (t - 1.05) / 0.33
				tip = Vector2(-out * 75.0, out * 30.0)
				alpha = maxf(0.0, 1.0 - out)
			_draw_single_impale_claw(c + tip * k, -0.36, 86.0, k, f_idx, pal, alpha)
		if post > 0.05:
			_local(c, k)
			for idx in drops.size():
				var d: Dictionary = drops[idx]
				var lt: float = t - d.delay
				if lt < 0.0 or lt > d.life:
					continue
				var u: float = lt / d.life
				var p2 := Vector2(cv.x * u, cv.y * u + sin(u * PI) * d.arc)
				_draw_drop(p2, d.sz, f_idx + idx * 7, pal, pal.accent)
			_unlocal(),
		func(_fx: Node2D, t: float) -> void:
			var post := maxf(0.0, t - HIT_DRAIN)
			var env := maxf(0.0, 1.0 - maxf(0.0, post - 0.95) / 0.72) if post > 0.0 else 0.0
			if post > 0.0:
				set_field(&"drain", {"mode": 0, "cx": c.x, "cy": c.y, "rx": 70.0 * k, "ry": 56.0 * k, "env": env * 0.80, "pal": pal, "profile": &"v4", "free": target.is_player})
			drive_target_warp(target, env * 7.5 * k, 1.0 if (post > 0.0 and post < 0.12) else 0.0)
			set_darken(env * 0.16)
			if post > 0.0 and post < 0.28:
				camera_shake((1.0 - post / 0.28) * 6.5, 0.06),
		func(_fx: Node2D) -> void: _release_all([target]))


func play_vital_claws(caster: BattleUnit, target: BattleUnit) -> float:
	var g := unit_geom(target)
	var c: Vector2 = g.c
	var k: float = g.k
	var cv := (_origin_of(caster) - c) / k
	var pal := palette_for(&"blood", true)
	var hp_drops: Array = []
	for i in 6:
		hp_drops.append({"delay": 0.54 + float(i) * 0.12, "arc": -22.0 - sketch_hash(float(i * 19)) * 38.0, "sz": 4.5 + sketch_hash(float(i * 13)) * 3.0, "life": 0.60})
	var en_drops: Array = []
	for i in 5:
		en_drops.append({"delay": 0.60 + float(i) * 0.13, "arc": 22.0 + sketch_hash(float(i * 29)) * 36.0, "sz": 4.0 + sketch_hash(float(i * 7)) * 2.5, "life": 0.60})
	return add_effect(DURATIONS[&"vital_claws"], func(_fx: Node2D, t: float) -> void:
		var f_idx := boil_index(t)
		var post2 := maxf(0.0, t - HIT_VITAL_CLAWS[1])
		if t < 1.50:
			var tip1: Vector2
			var a1 := 1.0
			if t < HIT_VITAL_CLAWS[0]:
				var p := t / HIT_VITAL_CLAWS[0]
				var e := p * p
				tip1 = Vector2(-10.0 - 95.0 * (1.0 - e), 38.0 * (1.0 - e))
			elif t < 1.16:
				tip1 = Vector2(-10.0 + (sketch_hash(float(f_idx * 11)) - 0.5) * 3.0, 0.0)
			else:
				var out := (t - 1.16) / 0.34
				tip1 = Vector2(-10.0 - out * 72.0, out * 28.0)
				a1 = maxf(0.0, 1.0 - out)
			_draw_single_impale_claw(c + tip1 * k, -0.34, 92.0, k, f_idx, pal, a1)
		if t > 0.12 and t < 1.56:
			var tip2: Vector2
			var a2 := 1.0
			if t < HIT_VITAL_CLAWS[1]:
				var p2 := (t - 0.12) / (HIT_VITAL_CLAWS[1] - 0.12)
				var e2 := p2 * p2
				tip2 = Vector2(10.0 + 95.0 * (1.0 - e2), -34.0 * (1.0 - e2))
			elif t < 1.22:
				tip2 = Vector2(10.0 + (sketch_hash(float(f_idx * 19)) - 0.5) * 3.0, 0.0)
			else:
				var out2 := (t - 1.22) / 0.34
				tip2 = Vector2(10.0 + out2 * 72.0, -out2 * 28.0)
				a2 = maxf(0.0, 1.0 - out2)
			_draw_single_impale_claw(c + tip2 * k, PI - 0.34, 92.0, k, f_idx + 37, pal, a2)
		if post2 > 0.04:
			_local(c, k)
			for idx in hp_drops.size():
				var d: Dictionary = hp_drops[idx]
				var lt: float = t - d.delay
				if lt < 0.0 or lt > d.life:
					continue
				var u: float = lt / d.life
				_draw_drop(Vector2(cv.x * u, cv.y * u + sin(u * PI) * d.arc), d.sz, f_idx + idx * 7, pal, Color("a81c2e"))
			for idx in en_drops.size():
				var d2: Dictionary = en_drops[idx]
				var lt2: float = t - d2.delay
				if lt2 < 0.0 or lt2 > d2.life:
					continue
				var u2: float = lt2 / d2.life
				_draw_drop(Vector2(cv.x * u2, cv.y * u2 + sin(u2 * PI) * d2.arc), d2.sz, f_idx + idx * 11, EN_DROP_PAL, Color("5d98c9"), true)
			_unlocal(),
		func(_fx: Node2D, t: float) -> void:
			var post1 := maxf(0.0, t - HIT_VITAL_CLAWS[0])
			var post2 := maxf(0.0, t - HIT_VITAL_CLAWS[1])
			var env := maxf(0.0, 1.0 - maxf(0.0, post1 - 1.05) / 0.75) if post1 > 0.0 else 0.0
			var inv := (post1 > 0.0 and post1 < 0.08) or (post2 > 0.0 and post2 < 0.12)
			if post1 > 0.0:
				set_field(&"vital", {"mode": 0, "cx": c.x, "cy": c.y, "rx": 82.0 * k, "ry": 66.0 * k, "env": env * 0.86, "pal": pal, "profile": &"v4", "free": target.is_player})
			drive_target_warp(target, env * 9.5 * k, 1.0 if inv else 0.0)
			set_darken(0.20 * (1.0 if t < 1.9 else maxf(0.0, 1.0 - (t - 1.9) / 0.5)))
			if post1 > 0.0 and post1 < 0.42:
				camera_shake((1.0 - post1 / 0.42) * 8.0, 0.06),
		func(_fx: Node2D) -> void: _release_all([target]))


# ---- 4. WEAKEN / 4Z. WEAKENEN ----------------------------------------------------------------------------------------
func _weak_arrows() -> Array:
	var out: Array = []
	for i in 7:
		out.append({"ox": (sketch_hash(float(i * 17)) - 0.5) * 66.0, "delay": (float(i) / 7.0) * 0.55, "spd": 44.0 + sketch_hash(float(i * 29)) * 32.0, "len": 13.0 + sketch_hash(float(i * 11)) * 11.0})
	return out


func play_weaken(caster: BattleUnit, target: BattleUnit) -> float:
	var g := unit_geom(target)
	var c: Vector2 = g.c
	var k: float = g.k
	var cv := (_origin_of(caster) - c) / k
	var pal := palette_for(&"blue", false)
	var arrows := _weak_arrows()
	return add_effect(DURATIONS[&"weaken"], func(_fx: Node2D, t: float) -> void:
		var f_idx := boil_index(t)
		var post := maxf(0.0, t - HIT_WEAKEN)
		var env := maxf(0.0, 1.0 - maxf(0.0, post - 1.0) / 0.78) if post > 0.0 else 0.0
		_local(c, k)
		if t < HIT_WEAKEN + 0.16:
			var p := minf(1.0, t / HIT_WEAKEN)
			var o := Vector2(cv.x * (1.0 - p), cv.y * (1.0 - p) - sin(p * PI) * 44.0)
			var r := 22.0 + sin(t * 16.0) * 2.5 if t < HIT_WEAKEN else 22.0 * (1.0 + ((t - HIT_WEAKEN) / 0.16) * 1.4)
			_draw_sketch_orb(o, r, f_idx, pal, 1.0 if t < HIT_WEAKEN else maxf(0.0, 1.0 - (t - HIT_WEAKEN) / 0.16))
		if post > 0.04 and env > 0.05:
			for idx in arrows.size():
				var ar: Dictionary = arrows[idx]
				var lt := fmod(post + ar.delay, 0.85)
				_draw_weak_arrow(ar.ox, -42.0 + lt * ar.spd * 1.5, ar.len, f_idx + idx * 7, pal.hi, pal.accent, true, minf(1.0, env * 1.25))
		_unlocal(),
		func(_fx: Node2D, t: float) -> void:
			var post := maxf(0.0, t - HIT_WEAKEN)
			var env := maxf(0.0, 1.0 - maxf(0.0, post - 1.0) / 0.78) if post > 0.0 else 0.0
			if t < HIT_WEAKEN:
				var p := t / HIT_WEAKEN
				set_field(&"weaken", {"mode": 0, "cx": c.x + cv.x * (1.0 - p) * k, "cy": c.y + (cv.y * (1.0 - p) - sin(p * PI) * 44.0) * k,
					"rx": 46.0 * k, "ry": 46.0 * k, "env": 0.75, "pal": pal, "profile": &"v4", "free": target.is_player})
			else:
				set_field(&"weaken", {"mode": 0, "cx": c.x, "cy": c.y, "rx": 92.0 * k, "ry": 84.0 * k, "env": env * 0.90, "pal": pal, "profile": &"v4", "free": target.is_player})
			drive_target_warp(target, env * 7.5 * k, 0.0)
			set_darken(env * 0.24),
		func(_fx: Node2D) -> void: _release_all([target]))


func play_weakenen(caster: BattleUnit, victims: Array) -> float:
	var t1: BattleUnit = victims[0]
	var t2: BattleUnit = victims[1] if victims.size() > 1 else victims[0]
	var single := t1 == t2
	var g1 := unit_geom(t1)
	var g2 := unit_geom(t2)
	var pal := palette_for(&"blue", true)
	var arrows := _weak_arrows()
	var kk: float = (float(g1.k) + float(g2.k)) * 0.5
	var origin := _origin_of(caster) + Vector2(0.0, (10.0 if t1.is_player else -36.0) * kk)
	var geoms: Array = [g1, g2]
	var units: Array = [t1, t2]
	var hits: Array[float] = [HIT_WEAKENEN[0], HIT_WEAKENEN[1]]
	var starts: Array[float] = [0.36, 0.42]
	var arcs: Array[float] = [42.0, 62.0]
	var ally := t1.is_player
	var all_units: Array = [t1] if single else [t1, t2]
	return add_effect(DURATIONS[&"weakenen"], func(_fx: Node2D, t: float) -> void:
		var f_idx := boil_index(t)
		if t < 0.42:
			var p := minf(1.0, t / 0.36)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE / DESIGN_SCALE)
			_draw_sketch_orb(origin, (14.0 + p * 18.0) * kk, f_idx, pal)
		for oi in (1 if single else 2):
			var gg: Dictionary = geoms[oi]
			var tc: Vector2 = gg.c
			var hit: float = hits[oi]
			var post := maxf(0.0, t - hit)
			var env := maxf(0.0, 1.0 - maxf(0.0, post - (0.95 if oi == 0 else 0.88)) / 0.65) if post > 0.0 else 0.0
			if t >= starts[oi] and t < hit + 0.15:
				var p2 := minf(1.0, (t - starts[oi]) / (hit - starts[oi]))
				var o := origin.lerp(tc, p2) - Vector2(0.0, sin(p2 * PI) * arcs[oi] * kk)
				var r := 24.0 * kk if t < hit else 24.0 * kk * (1.0 + ((t - hit) / 0.15) * 1.35)
				_draw_sketch_orb(o, r, f_idx + oi * 19, pal, 1.0 if t < hit else maxf(0.0, 1.0 - (t - hit) / 0.15))
			if post > 0.03 and env > 0.04:
				_local(tc, gg.k)
				for idx in arrows.size():
					var ar: Dictionary = arrows[idx]
					var lt := fmod(post + ar.delay, 0.85)
					_draw_weak_arrow(ar.ox, -40.0 + lt * ar.spd * 1.45, ar.len, f_idx + idx * 7 + oi * 29, GOLD, pal.accent, false, minf(1.0, env * 1.25))
				_unlocal(),
		func(_fx: Node2D, t: float) -> void:
			var any_env := 0.0
			for oi in (1 if single else 2):
				var gg: Dictionary = geoms[oi]
				var hit: float = hits[oi]
				var post := maxf(0.0, t - hit)
				var env := maxf(0.0, 1.0 - maxf(0.0, post - (0.95 if oi == 0 else 0.88)) / 0.65) if post > 0.0 else 0.0
				any_env = maxf(any_env, env)
				var key := StringName("weakenen%d" % oi)
				if t >= starts[oi] and t < hit:
					var p2 := minf(1.0, (t - starts[oi]) / (hit - starts[oi]))
					var o: Vector2 = origin.lerp(gg.c, p2) - Vector2(0.0, sin(p2 * PI) * arcs[oi] * kk)
					set_field(key, {"mode": 0, "cx": o.x, "cy": o.y, "rx": 38.0 * kk, "ry": 38.0 * kk, "env": 0.65, "pal": pal, "profile": &"v4", "free": ally})
				elif post > 0.03 and env > 0.04:
					set_field(key, {"mode": 0, "cx": gg.c.x, "cy": gg.c.y, "rx": 84.0 * gg.k, "ry": 76.0 * gg.k, "env": env * 0.88, "pal": pal, "profile": &"v4", "free": ally})
				else:
					clear_field(key)
				drive_target_warp(units[oi], env * 7.5 * gg.k, 0.0)
			if t < 0.42:
				var p := minf(1.0, t / 0.36)
				set_field(&"weakenen_src", {"mode": 0, "cx": origin.x, "cy": origin.y, "rx": (44.0 * p + 12.0) * kk, "ry": (44.0 * p + 12.0) * kk, "env": 0.70, "pal": pal, "profile": &"v4", "free": ally})
			else:
				clear_field(&"weakenen_src")
			set_darken(0.22 * (1.0 if t < 2.0 else maxf(0.0, 1.0 - (t - 2.0) / 0.5))),
		func(_fx: Node2D) -> void: _release_all(all_units))


# ---- 5. MARK OF SUN: acender, marca persistente e disparo -------------------------------------------------------------

func _is_sun_key(key: StringName) -> bool:
	return String(key).begins_with("sunm_")


## Onde o sol de `u` fica. Inimigo: acima da cabeça (abaixo do HUD superior), escalado por k. Aliado: no meio
## horizontal no extremo canto direito do cartão (`card.end.x`, `card.get_center().y`), sem cortar na tela nem
## invadir o Battle Log ou a fileira de ícones de status na borda inferior.
func sun_spot(u: BattleUnit) -> Dictionary:
	var g := unit_geom(u)
	if u.is_player:
		var card: Rect2 = g.card
		var log_bottom: float = hud.BATTLE_LOG_RECT.end.y * DESIGN_SCALE
		return {"p": Vector2(card.end.x, card.get_center().y), "r": 8.5, "ray_min": 4.5, "ray_var": 4.5, "ray_jit": 1.1, "ray_w": 1.4,
			"disc_jit": 1.3, "disc_w": 1.8, "halo": Vector2(24.0, 18.0), "ally": true, "min_y": log_bottom + 2.0, "k": 1.0, "card": card}
	var k: float = g.k
	var top := maxf(float(g.c.y) - 80.0 * k, STAGE_TOP * DESIGN_SCALE + 34.0 * k)
	return {"p": Vector2(g.c.x, top), "r": 15.0 * k, "ray_min": 10.0 * k, "ray_var": 10.0 * k, "ray_jit": 1.9, "ray_w": 1.8,
		"disc_jit": 2.2, "disc_w": 2.4, "halo": Vector2(52.0 * k, 36.0 * k), "ally": false, "min_y": STAGE_TOP * DESIGN_SCALE, "k": k}


## O sol (12 raios tortos + disco + miolo): SEM triângulos soltos. `hits` = cargas restantes (contador só no aliado).
func _draw_sun_body(spot: Dictionary, grow: float, pulse_env: float, hits: int, f_idx: int, t: float, alpha: float = 1.0) -> void:
	var pal := palette_for(&"sun", false)
	var p: Vector2 = spot.p
	var pulse := 1.0 + sin(t * 9.0) * 0.05 + pulse_env * 0.28
	var sr: float = float(spot.r) * grow * pulse
	if sr < 1.2:
		return
	var j_scale := clampf(grow, 0.0, 1.0)
	var ray_j := float(spot.ray_jit) * j_scale
	var disc_j := minf(float(spot.disc_jit) * j_scale, sr * 0.16)
	var inner_j := minf(1.1 * j_scale, sr * 0.08)
	var ally: bool = spot.ally
	for i in 12:
		var a := (float(i) / 12.0) * TAU + floorf(t * 12.0) * 0.04
		var ln: float = (float(spot.ray_min) + sketch_hash(float(i * 19 + 5)) * float(spot.ray_var)) * grow * pulse
		var r_in := sr * 0.90
		var r_out := sr + ln
		var spread := 0.14
		draw_sketch_shape(PackedVector2Array([
			p + Vector2(cos(a - spread), sin(a - spread)) * r_in, p + Vector2(cos(a), sin(a)) * r_out, p + Vector2(cos(a + spread), sin(a + spread)) * r_in]),
			f_idx + i * 7, pal, ray_j, pal.deep, float(spot.ray_w), alpha)
	var disc := PackedVector2Array()
	for i in 14:
		var a2 := (float(i) / 14.0) * TAU
		disc.append(p + Vector2(cos(a2), sin(a2)) * sr)
	draw_sketch_shape(disc, f_idx, pal, disc_j, pal.deep, float(spot.disc_w), alpha)
	var inner := PackedVector2Array()
	for q in disc:
		inner.append(p + (q - p) * 0.48)
	var core_col: Color = pal.hi if pulse_env > 0.2 else pal.accent
	_fill_poly(sketchy_pts(inner, f_idx + 31, inner_j), Color(core_col, core_col.a * alpha))
	if ally and grow > 0.45:
		var hi: Color = pal.hi
		var count_pos := p + Vector2(-16.0 - 30.0, 4.0)
		draw_string_outline(font, count_pos, "×%d" % hits, HORIZONTAL_ALIGNMENT_RIGHT, 30.0, 10, 3, Color(0.04, 0.02, 0.02, 0.9 * alpha))
		draw_string(font, count_pos, "×%d" % hits, HORIZONTAL_ALIGNMENT_RIGHT, 30.0, 10, Color(hi, hi.a * alpha))


func _sun_field_spec(spot: Dictionary, grow: float, env: float) -> Dictionary:
	var halo: Vector2 = spot.halo
	var spec := {"mode": 0, "cx": spot.p.x, "cy": spot.p.y, "rx": halo.x * grow, "ry": halo.y * grow, "env": env, "pal": palette_for(&"sun", false), "profile": &"v4"}
	if bool(spot.ally):
		spec["free"] = true
		spec["min_y"] = spot.min_y
	return spec


## Marca persistente: todo quadro, para cada unidade viva com `sun_mark_hits > 0` o sol fica no lugar dela (campo Moiré contido).
func _sun_step() -> void:
	if hud == null or hud.get("players") == null:
		return
	var live := {}
	for list in [hud.players, hud.opponents]:
		for u in list:
			if u.is_alive() and u.sun_mark_hits > 0:
				var key := StringName("sunm_%s" % u.id)
				live[key] = true
				var pulse := float(_sun_pulse.get(u.id, 0.0))
				set_field(key, _sun_field_spec(sun_spot(u), 1.0, minf(1.0, 0.72 + pulse * 0.25)))
	for key in _fields.keys():
		if _is_sun_key(key) and not live.has(key):
			clear_field(key)


func _draw_suns() -> void:
	if hud == null or hud.get("players") == null:
		return
	var f_idx := boil_index(time)
	for list in [hud.players, hud.opponents]:
		for u in list:
			if u.is_alive() and u.sun_mark_hits > 0:
				_draw_sun_body(sun_spot(u), 1.0, float(_sun_pulse.get(u.id, 0.0)), u.sun_mark_hits, f_idx, time)


func has_sun(u: BattleUnit) -> bool:
	return _fields.has(StringName("sunm_%s" % u.id))


## O sol cresce sobre o alvo (grow 0..1 em 0,65 s) e passa para a marca persistente quando a mecânica a acende.
func play_mark_of_sun(caster: BattleUnit, target: BattleUnit) -> float:
	var spot := sun_spot(target)
	var g := unit_geom(target)
	var k: float = g.k
	return add_effect(DURATIONS[&"mark_of_sun"], func(_fx: Node2D, t: float) -> void:
		var grow := minf(1.0, t / HIT_SUN)
		_draw_sun_body(spot, grow, 0.0, 3, boil_index(t), t),
		func(_fx: Node2D, t: float) -> void:
			var grow := minf(1.0, t / HIT_SUN)
			set_field(&"sunc_cast", _sun_field_spec(spot, grow, 0.72 * grow))
			drive_target_warp(target, grow * 3.5 * k, 0.0)
			set_darken(0.24 * grow),
		func(_fx: Node2D) -> void:
			clear_field(&"sunc_cast")
			_release_all([target]))


## +20 MAGI: clarão solar (anel + estrela fina + núcleo breve + pulso Moiré contido) sobre o alvo, em ambos os lados.
func play_mark_of_sun_trigger(target: BattleUnit) -> float:
	var g := unit_geom(target)
	var c: Vector2 = g.c
	var k: float = g.k
	var ally := target.is_player
	var pal := palette_for(&"sun", false)
	var min_y: float = hud.BATTLE_LOG_RECT.end.y * DESIGN_SCALE + 2.0 if ally else STAGE_TOP * DESIGN_SCALE
	var kf: float = 1.0 if ally else k
	var key := StringName("sunc_flare%d" % int(time * 1000.0))
	return add_effect(SUN_TRIGGER_DUR, func(_fx: Node2D, t: float) -> void:
		var prog := minf(1.0, t / SUN_TRIGGER_DUR)
		var env := pow(1.0 - prog, 1.3)
		_draw_solar_hit_flare(c, prog, env, boil_index(t), pal, min_y, ally, kf),
		func(_fx: Node2D, t: float) -> void:
			var prog := minf(1.0, t / SUN_TRIGGER_DUR)
			var env := pow(1.0 - prog, 1.3)
			_sun_pulse[target.id] = env
			var spec := {"mode": 0, "cx": c.x, "cy": c.y, "rx": (56.0 + prog * 36.0) * kf, "ry": (42.0 + prog * 24.0) * kf, "env": env * 0.92, "pal": pal, "profile": &"v4"}
			if ally:
				spec["free"] = true
				spec["min_y"] = min_y
			set_field(key, spec)
			drive_target_warp(target, env * (8.5 if ally else 9.0) * (1.0 if ally else k), 1.0 if t < 0.09 else 0.0),
		func(_fx: Node2D) -> void:
			clear_field(key)
			_sun_pulse.erase(target.id)
			release_target_warp(target))
