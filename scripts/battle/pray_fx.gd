extends Node2D
## Prayer visuals drawn over the HUD (D-048 / D-107 / D-112 / D-113):
## D-113 mandatory rule: EVERY prayer effect in EXODUS must have Hebrew-letter VFX here
## (100% typographic, no geometric circles/arcs/borders replacing letters), with persistent
## Hebrew marks for multi-round / pending-action states (ה, מ, ג, ז, ס, נ).

const ALPHABET := "אבגדהוזחטיכלמנסעפצקרשת"
const RISE_LETTERS := 14
const RISE_TIME := 0.8
const RISE_STAGGER := 0.5
const RISE_HEIGHT := 70.0
const LETTER_PX := 12
const MARK_GLYPH := "ה"
const MARK_MAGEN := "מ"
const MARK_GEVURAH := "ג"
const MARK_ZOHAR := "ז"
const MARK_SANVERIM := "ס"
const MARK_NECHAMAH := "נ"
const MARK_CHAKI := "ח"
const MARK_SHACHAR := "ש"
const MARK_LIOR := "ל"
const MARK_PX := 13
const PULSE_HZ := 2.6
const INK_HOT := Color(1.0, 1.0, 0.88)
const INK_DEBUFF := Color(0.88, 0.32, 0.32)
const INK_HEAL := Color("b8f5a2")
## D-118 sacred fire 3-color palette (orange, yellow, white) + light/heal palettes + emerald bush.
const FIRE_PALETTE: Array[Color] = [Color("ff7a1f"), Color("ffd84a"), Color("ffffff")]
const LIGHT_PALETTE: Array[Color] = [Color("ffffff"), Color("fffce0"), Color("f5f58c")]
const HEAL_PALETTE: Array[Color] = [Color("fffce0"), Color("f5f58c"), Color("b8f5a2")]
const INK_BUSH := Color("5ee389")

var hud: Control
var font: SystemFont
var rng := RandomNumberGenerator.new()
var time := 0.0
## {"glyph", "x", "bottom", "born"} per rising letter.
var letters: Array[Dictionary] = []
## D-112: card-anchored prayer animations (Tahorah, Magen, Gevurah, Zohar).
var card_fx: Array[Dictionary] = []


func _ready() -> void:
	z_index = 100
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Tahoma", "Arial", "David Libre"])
	font.font_weight = 800


func _process(delta: float) -> void:
	time += delta
	_shake_step()
	for i in range(letters.size() - 1, -1, -1):
		if time - float(letters[i].born) > RISE_TIME:
			letters.remove_at(i)
	for i in range(card_fx.size() - 1, -1, -1):
		if time - float(card_fx[i].born) > float(card_fx[i].dur):
			card_fx.remove_at(i)
	_prune_d118()
	queue_redraw()


## Letters rise from the bottom of `unit`'s status card.
func cast(unit: BattleUnit) -> void:
	var index: int = hud.players.find(unit)
	if index < 0:
		return
	var card: Rect2 = hud.status_rect(index)
	for i in RISE_LETTERS:
		letters.append({"glyph": ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)],
			"x": rng.randf_range(card.position.x + 10, card.end.x - 10),
			"bottom": card.end.y - 6, "born": time + rng.randf_range(0.0, RISE_STAGGER)})


func is_busy() -> bool:
	return not letters.is_empty() or not card_fx.is_empty() or raam_busy() or mishpat_busy() or cherev_busy() or sanverim_busy() or chaki_busy() or shachar_busy() or esh_sinai_busy() or lehavah_busy() or hasneh_busy() or shalhevet_busy() or nogah_busy() or lior_busy() or d118_busy()


func _draw() -> void:
	if hud == null:
		return
	_draw_hasneh_haboer()
	_draw_raam()
	_draw_mishpat()
	_draw_cherev()
	_draw_sanverim()
	_draw_chaki()
	_draw_shachar()
	_draw_lehavah()
	_draw_esh_sinai()
	_draw_shalhevet()
	_draw_nogah()
	_draw_d118()
	var pulse := 0.55 + 0.45 * absf(sin(time * PULSE_HZ))
	if shachar_pending:
		_glyph(MARK_SHACHAR, Vector2(hud.SCREEN.x - 20.0, 18.0), MARK_PX + 2, Color(INK_HOT, 0.72 + 0.28 * pulse), Color(INK_DARK, 0.9))
	for i in hud.opponents.size():
		var foe: BattleUnit = hud.opponents[i]
		if not foe.is_alive():
			continue
		var er: Rect2 = hud.enemy_sprite_rect(i)
		var em_x := er.get_center().x + er.size.x * 0.35
		var em_y := er.end.y + 12.0
		if foe.has_status(&"blind"):
			_glyph(MARK_SANVERIM, Vector2(em_x, em_y), MARK_PX, Color(INK_DEBUFF, 0.65 + 0.35 * pulse), Color(INK_DARK, 0.85))
			em_x += 14.0
		if foe.has_status(&"chaki"):
			_glyph(MARK_CHAKI, Vector2(em_x, em_y), MARK_PX, Color(PrayerBook.INK, 0.70 + 0.30 * pulse), Color(INK_DARK, 0.9))
			em_x += 14.0
		if not foe.mends.is_empty():
			_glyph(MARK_NECHAMAH, Vector2(em_x, em_y), MARK_PX, Color(PrayerBook.INK, 0.65 + 0.35 * pulse), Color(INK_DARK, 0.85))
			if foe.mends.size() > 1:
				_glyph("x%d" % foe.mends.size(), Vector2(em_x + 12.0, em_y), 10, Color(PrayerBook.INK, 0.65 + 0.35 * pulse), Color(INK_DARK, 0.85))
			em_x += 28.0
		if foe.paralyzed_acts > 0:
			_glyph(MARK_ANGEL_HUG, Vector2(em_x, em_y), MARK_PX, Color(PARA_PALETTE[0], 0.7 + 0.3 * pulse), Color(INK_DARK, 0.85))
			_glyph("x%d" % foe.paralyzed_acts, Vector2(em_x + 14.0, em_y), 10, Color(PARA_PALETTE[0], 0.7 + 0.3 * pulse), Color(INK_DARK, 0.85))
			em_x += 32.0
		if foe.has_status(&"gods_message"):
			_glyph(MARK_GODS_MESSAGE, Vector2(em_x, em_y), MARK_PX, Color("ffd84a", 0.7 + 0.3 * pulse), Color(INK_DARK, 0.85))
	for i in hud.players.size():
		var unit: BattleUnit = hud.players[i]
		if not unit.is_alive():
			continue
		var card: Rect2 = hud.status_rect(i)
		var marks: Array[Dictionary] = []
		if not unit.haganah.is_empty() and not bool(unit.haganah.get("non_prayer", false)):
			marks.append({"glyph": MARK_GLYPH, "color": Color(PrayerBook.INK, pulse), "jitter": 0.0})
		if not unit.def_stages.is_empty():
			marks.append({"glyph": MARK_MAGEN, "color": Color(PrayerBook.INK, pulse), "jitter": 0.0})
		if unit.gevurah_bonus > 0.0:
			marks.append({"glyph": MARK_GEVURAH, "color": INK_HOT, "jitter": sin(time * 40.0) * 1.1})
		if unit.has_status(&"zohar"):
			marks.append({"glyph": MARK_ZOHAR, "color": INK_HOT, "jitter": 0.0})
		if unit.has_status(&"blind"):
			marks.append({"glyph": MARK_SANVERIM, "color": Color(INK_DEBUFF, 0.65 + 0.35 * pulse), "jitter": 0.0})
		if unit.has_status(&"chaki"):
			marks.append({"glyph": MARK_CHAKI, "color": Color(PrayerBook.INK, 0.70 + 0.30 * pulse), "jitter": 0.0})
		if not unit.mends.is_empty():
			marks.append({"glyph": MARK_NECHAMAH, "color": Color(PrayerBook.INK, pulse), "jitter": 0.0,
				"suffix": "x%d" % unit.mends.size() if unit.mends.size() > 1 else ""})
		if lior_active.has(unit) and int(lior_active[unit].actions) > 0:
			marks.append({"glyph": MARK_LIOR, "color": Color(INK_HEAL, 0.72 + 0.28 * pulse), "jitter": 0.0,
				"suffix": "x%d" % int(lior_active[unit].actions)})
		if unit.has_status(&"taunt"):
			marks.append({"glyph": MARK_MEIR, "color": Color(INK_ALERT, 0.75 + 0.25 * pulse), "jitter": 0.0})
		if not unit.atk_stages.is_empty():
			marks.append({"glyph": MARK_GEVER, "color": Color(GEVER_PALETTE[0], 0.75 + 0.25 * pulse), "jitter": 0.0,
				"suffix": "x%d" % unit.atk_stages.size()})
		if unit.paralyzed_acts > 0:
			marks.append({"glyph": MARK_ANGEL_HUG, "color": Color(PARA_PALETTE[0], 0.7 + 0.3 * pulse), "jitter": 0.0,
				"suffix": "x%d" % unit.paralyzed_acts})
		if unit.has_status(&"gods_message"):
			marks.append({"glyph": MARK_GODS_MESSAGE, "color": Color("ffd84a", 0.7 + 0.3 * pulse), "jitter": 0.0})
		var x: float = card.position.x + 7 + hud._width(NameCase.of(unit.display_name), 13, true) + 8
		var cursor := x
		for m_idx in marks.size():
			var mk: Dictionary = marks[m_idx]
			var mx := cursor + float(mk.jitter)
			draw_string(font, Vector2(mx, card.position.y + 18),
				String(mk.glyph), HORIZONTAL_ALIGNMENT_LEFT, -1, MARK_PX, Color(mk.color))
			var suf := String(mk.get("suffix", ""))
			cursor += 16.0
			if not suf.is_empty():
				draw_string(font, Vector2(mx + 9.0, card.position.y + 18),
					suf, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(mk.color))
				cursor += font.get_string_size(suf, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 2.0
	for letter in letters:
		var k := (time - float(letter.born)) / RISE_TIME
		if k < 0.0 or k > 1.0:
			continue
		var pos := Vector2(float(letter.x), float(letter.bottom) - RISE_HEIGHT * k)
		draw_string_outline(font, pos, letter.glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, LETTER_PX, 3, Color(0.15, 0.12, 0.0, 1.0 - k))
		draw_string(font, pos, letter.glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, LETTER_PX, Color(PrayerBook.INK, 1.0 - k))
	_draw_card_fx()
	_draw_lior()


# ---------------------------------------------------------------- Ra'am (approved 2026-11-23)
## Ra'am "letters" v2 from prototypes/pray-vfx, approved by the creator on 2026-11-23:
## charge (stage darkens, letters spiral in, the word רעם forms in the sky), white impact
## frame, double strike of large glowing letters down to the ground with letter branches,
## the foe flashing white, screen shake, a ring of letters along the ground, letters thrown up
## from the ground and the bolt letters smouldering and rising away. Same numbers as the
## prototype.
const L_CHARGE := 0.7
const L_FLASH := 0.05
const L_REFLASH := [0.07, 0.11]
const L_BOLT_HOLD := 0.32
const L_SHAKE_PX := 9.0
const L_SHAKE_TIME := 0.45
const L_BURST_TIME := 0.9
const L_AFTER_TIME := 1.1
const L_END := 1.45
const INK_DARK := Color(0.12, 0.08, 0.0)
var raam_at := -99.0
var r_target := Rect2()
var r_white: Texture2D
var r_bolt := PackedVector2Array()
var r_branches: Array[PackedVector2Array] = []
var r_glyphs: Array[Dictionary] = []
var r_branch_glyphs: Array[Dictionary] = []
var r_gather: Array[Dictionary] = []
var r_burst: Array[Dictionary] = []
var r_ring: Array[String] = []
var r_ground := Vector2.ZERO
var r_sky := Vector2.ZERO
var _shaking := false
var _canvas := Transform2D.IDENTITY
var _clear := Color.BLACK


## Plays the thunder on `target`; returns at the strike (the damage lands then).
func play_raam(target: BattleUnit) -> void:
	var index: int = hud.opponents.find(target)
	if index < 0:
		return
	_build_raam(index)
	raam_at = time + L_CHARGE
	await get_tree().create_timer(L_CHARGE).timeout


func raam_busy() -> bool:
	return time - raam_at < L_END


func _build_raam(index: int) -> void:
	rng.seed = 48
	r_target = hud.enemy_sprite_rect(index)
	r_white = hud.silhouettes[index] if index < hud.silhouettes.size() else null
	var sky: float = hud.FIELD_RECT.position.y
	r_ground = Vector2(r_target.get_center().x - 4, r_target.end.y - 14)
	r_sky = Vector2(r_target.get_center().x + 64, sky + 26)
	r_bolt = _zigzag(Vector2(r_sky.x, sky), r_ground, 9, 16.0)
	r_glyphs.clear()
	var count := int(_length(r_bolt) / 15.0)
	for i in count:
		r_glyphs.append({"glyph": _letter(), "at": float(i) / maxf(1.0, count - 1),
			"jit": Vector2(rng.randf_range(-2, 2), rng.randf_range(-2, 2)),
			"drift": rng.randf_range(10, 30), "off": rng.randf_range(0.0, 1.0)})
	r_branches.clear()
	r_branch_glyphs.clear()
	for k in [2, 4, 5, 7]:
		var start: Vector2 = r_bolt[k]
		var dir := -1.0 if k % 2 == 0 else 1.0
		var b := _zigzag(start, start + Vector2(dir * rng.randf_range(18, 32), rng.randf_range(34, 52)), 3, 6.0)
		r_branches.append(b)
		var n := int(_length(b) / 11.0)
		for i in n:
			r_branch_glyphs.append({"branch": r_branches.size() - 1, "at": float(i + 1) / n, "glyph": _letter()})
	r_gather.clear()
	for i in 20:
		r_gather.append({"glyph": _letter(), "angle": rng.randf_range(0, TAU), "radius": rng.randf_range(90, 170),
			"spin": rng.randf_range(2.0, 4.0) * (1 if i % 2 == 0 else -1), "delay": rng.randf_range(0.0, 0.25)})
	r_burst.clear()
	for i in 22:
		var a := rng.randf_range(PI * 1.05, PI * 1.95)
		r_burst.append({"glyph": _letter(), "vel": Vector2.RIGHT.rotated(a) * rng.randf_range(120, 260),
			"px": rng.randi_range(12, 18)})
	r_ring.clear()
	for i in 16:
		r_ring.append(ALPHABET[(i * 7) % ALPHABET.length()])


func _letter() -> String:
	return ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)]


func _zigzag(from: Vector2, to: Vector2, segments: int, spread: float) -> PackedVector2Array:
	var points := PackedVector2Array([from])
	var normal := (to - from).orthogonal().normalized()
	for i in range(1, segments):
		points.append(from.lerp(to, float(i) / segments) + normal * rng.randf_range(-spread, spread))
	points.append(to)
	return points


func _length(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in points.size() - 1:
		total += points[i].distance_to(points[i + 1])
	return total


func _point_along(points: PackedVector2Array, k: float) -> Vector2:
	var want := _length(points) * clampf(k, 0.0, 1.0)
	for i in points.size() - 1:
		var seg := points[i].distance_to(points[i + 1])
		if want <= seg:
			return points[i].lerp(points[i + 1], want / maxf(seg, 0.001))
		want -= seg
	return points[points.size() - 1]


func _glyph(glyph: String, pos: Vector2, px: int, color: Color, outline: Color) -> void:
	draw_string_outline(font, pos, glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, px, 3, outline)
	draw_string(font, pos, glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, px, color)


func _shake_step() -> void:
	var amp := 0.0
	var age := time - raam_at
	if age >= 0.0 and age < L_SHAKE_TIME:
		amp = maxf(amp, L_SHAKE_PX * pow(1.0 - age / L_SHAKE_TIME, 2))
	var mage := time - mishpat_at
	if mage >= 0.0 and mage < M_SHAKE_TIME:
		amp = maxf(amp, M_SHAKE_PX * pow(1.0 - mage / M_SHAKE_TIME, 2))
	var cage := time - cherev_at
	if cage >= 0.0 and cage < C_SHAKE_TIME:
		amp = maxf(amp, C_SHAKE_PX * pow(1.0 - cage / C_SHAKE_TIME, 2))
	var sage := time - sanverim_at
	if sage >= 0.0 and sage < S_SHAKE_TIME:
		amp = maxf(amp, S_SHAKE_PX * pow(1.0 - sage / S_SHAKE_TIME, 2))
	var lage := time - lehavah_at
	if lage >= 0.0 and lage < LEHAVAH_SHAKE_TIME:
		amp = maxf(amp, LEHAVAH_SHAKE_PX * pow(1.0 - lage / LEHAVAH_SHAKE_TIME, 2))
	var es_age := time - esh_sinai_at
	if es_age >= 0.0 and es_age < ESH_SINAI_END:
		for h in esh_sinai_hits:
			if int(h.idx) > esh_sinai_max_hit:
				continue
			var h_age := es_age - float(h.ht)
			if h_age >= 0.0 and h_age < 0.22:
				var mag := (9.0 if int(h.idx) == 0 else 5.0) * (1.0 - h_age / 0.22)
				amp = maxf(amp, mag)
	var sh_age := time - shalhevet_at
	if sh_age >= 0.58 and sh_age <= 1.45:
		var sm := 6.0 * (1.0 - absf(sh_age - 1.0) / 0.55)
		if sm > 0.0:
			amp = maxf(amp, sm)
	amp = maxf(amp, _d118_shake())
	if amp > 0.0:
		if not _shaking:
			_shaking = true
			_canvas = get_viewport().canvas_transform
			_clear = RenderingServer.get_default_clear_color()
			RenderingServer.set_default_clear_color(Color.BLACK)
		get_viewport().canvas_transform = _canvas.translated((Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * amp).round())
	elif _shaking:
		_end_shake()


func _end_shake() -> void:
	_shaking = false
	get_viewport().canvas_transform = _canvas
	RenderingServer.set_default_clear_color(_clear)


func _exit_tree() -> void:
	if _shaking:
		_end_shake()


func _draw_raam() -> void:
	var age := time - raam_at
	if age < -L_CHARGE or age > L_END:
		return
	var flick := 1.0 if int(time * 30.0) % 4 != 0 else 0.5
	var dark := 0.0
	if age < 0.0:
		dark = 0.62 * clampf((age + L_CHARGE) / L_CHARGE, 0.0, 1.0)
	elif age < 1.4:
		dark = 0.62 * (1.0 - clampf((age - 0.4) / 1.0, 0.0, 1.0))
	if dark > 0.0:
		draw_rect(hud.STAGE_RECT, Color(0.02, 0.0, 0.05, dark))
	if age < 0.0:
		var c := clampf((age + L_CHARGE) / L_CHARGE, 0.0, 1.0)
		for g in r_gather:
			var k := clampf((c - float(g.delay)) / (1.0 - float(g.delay)), 0.0, 1.0)
			if k <= 0.0: continue
			var r := float(g.radius) * pow(1.0 - k, 1.6)
			var a := float(g.angle) + float(g.spin) * k
			_glyph(g.glyph, r_sky + Vector2(cos(a) * r, sin(a) * r * 0.6) + Vector2(0, 5), 12, Color(PrayerBook.INK, 0.35 + 0.65 * k), Color(INK_DARK, k))
		var word_k := clampf((c - 0.35) / 0.65, 0.0, 1.0)
		if word_k > 0.0:
			var sky_r := 18.0 + 18.0 * word_k + 3.0 * sin(time * 30.0)
			for i in 12:
				var a := TAU * float(i) / 12.0 + time * 2.4
				_glyph(ALPHABET[(i * 3) % ALPHABET.length()],
					r_sky + Vector2(cos(a) * sky_r, sin(a) * sky_r * 0.85) + Vector2(0, 4),
					11, Color(PrayerBook.INK, 0.75 * word_k), Color(INK_DARK, word_k))
			_glyph("רעם", r_sky + Vector2(0, 9), int(14 + 12 * word_k), Color(1, 1, 0.85, word_k), Color(INK_DARK, word_k))
		return
	if age < L_FLASH:
		draw_rect(Rect2(Vector2.ZERO, hud.SCREEN), Color(1, 1, 1, 0.92))
	var gap: bool = age >= L_REFLASH[0] and age < L_REFLASH[1]
	if age < L_BOLT_HOLD and not gap:
		for g in r_branch_glyphs:
			_glyph(g.glyph, _point_along(r_branches[int(g.branch)], float(g.at)) + Vector2(0, 5), 14, Color(1, 1, 0.9, flick), INK_DARK)
	var after := clampf((age - L_BOLT_HOLD) / L_AFTER_TIME, 0.0, 1.0)
	if not gap:
		for g in r_glyphs:
			var p: Vector2 = _point_along(r_bolt, float(g.at)) + g.jit
			var alpha := 1.0
			if after > 0.0:
				alpha = (1.0 - after) * (0.4 if fmod(time * 9.0 + float(g.off) * 7.0, 1.0) < 0.25 else 1.0)
				p += Vector2(0, -float(g.drift) * after)
			if alpha <= 0.01: continue
			var ink: Color = PrayerBook.INK if after > 0.0 else Color(1, 1, 0.88)
			_glyph(g.glyph, p + Vector2(0, 8), 20 if after <= 0.0 else 18, Color(ink, alpha), Color(INK_DARK, alpha))
	if r_white != null and age < 0.36 and int(age * 30.0) % 2 == 0:
		draw_texture_rect(r_white, r_target, false, Color(1, 1, 1, 0.9))
	if age < 0.5:
		var rk := age / 0.5
		for i in r_ring.size():
			var a := TAU * i / r_ring.size()
			_glyph(r_ring[i], r_ground + Vector2(cos(a) * (36 + 110 * rk), sin(a) * (9 + 26 * rk)) + Vector2(0, 5), 14, Color(PrayerBook.INK, 1.0 - rk), Color(INK_DARK, 1.0 - rk))
	if age < L_BURST_TIME:
		var bk := age / L_BURST_TIME
		for g in r_burst:
			var pos: Vector2 = r_ground + g.vel.normalized() * 14.0 + g.vel * age + Vector2(0, 520.0 * age * age)
			if pos.y > hud.STAGE_RECT.end.y - 4: continue
			_glyph(g.glyph, pos, int(g.px), Color(PrayerBook.INK, 1.0 - bk * bk), Color(INK_DARK, 1.0 - bk))


# ---------------------------------------------------------------- D-112 prayer VFX (approved 2026-11-26)

## Tahorah: rising line of letters with טהרה across the card; debuff glyphs turn red -> #f5f58c.
func play_tahorah(target: BattleUnit) -> void:
	if hud == null:
		return
	var index: int = hud.players.find(target)
	if index < 0:
		return
	var card: Rect2 = hud.status_rect(index)
	var debuffs: Array[Dictionary] = []
	for _i in 10:
		debuffs.append({
			"glyph": _letter(),
			"x": rng.randf_range(card.position.x + 12.0, card.end.x - 12.0),
			"y": rng.randf_range(card.position.y + 10.0, card.end.y - 10.0),
			"spin": rng.randf_range(-3.5, 3.5),
			"drift": rng.randf_range(34.0, 68.0),
		})
	var rises: Array[Dictionary] = []
	for _i in 14:
		rises.append({
			"glyph": _letter(),
			"x": rng.randf_range(card.position.x + 10.0, card.end.x - 10.0),
			"delay": rng.randf_range(0.0, 0.35),
			"speed": rng.randf_range(48.0, 82.0),
		})
	card_fx.append({"kind": &"tahorah", "card": card, "born": time, "dur": 1.35,
		"debuffs": debuffs, "rises": rises})


## Magen: falling letter columns lock into a shield wall across all living allies' cards.
func play_magen(allies: Array) -> void:
	if hud == null:
		return
	var cards: Array[Rect2] = []
	var cols: Array[Dictionary] = []
	for c_idx in allies.size():
		var idx: int = hud.players.find(allies[c_idx])
		if idx < 0:
			continue
		var card: Rect2 = hud.status_rect(idx)
		cards.append(card)
		for col in 5:
			for row in 2:
				cols.append({
					"glyph": _letter(),
					"x": lerpf(card.position.x + 14.0, card.end.x - 14.0, float(col) / 4.0),
					"y": card.position.y + 14.0 + float(row) * (card.size.y * 0.42),
					"delay": float(c_idx) * 0.06 + float(col) * 0.03 + float(row) * 0.04,
				})
	if cards.is_empty():
		return
	card_fx.append({"kind": &"magen", "cards": cards, "born": time, "dur": 1.45, "cols": cols})


## Gevurah: inward spiral collapse + expanding ring formed purely by 16 Hebrew letters (no stroke circle).
func play_gevurah(target: BattleUnit) -> void:
	if hud == null:
		return
	var index: int = hud.players.find(target)
	if index < 0:
		return
	var card: Rect2 = hud.status_rect(index)
	var in_letters: Array[Dictionary] = []
	for i in 18:
		in_letters.append({
			"glyph": _letter(),
			"angle": TAU * float(i) / 18.0 + rng.randf_range(-0.15, 0.15),
			"rad": rng.randf_range(52.0, 96.0),
			"spin": (1.0 if i % 2 == 0 else -1.0) * rng.randf_range(2.4, 3.8),
			"delay": rng.randf_range(0.0, 0.2),
		})
	var ring: Array[Dictionary] = []
	for i in 16:
		ring.append({
			"glyph": ALPHABET[(i * 5 + 2) % ALPHABET.length()],
			"angle": TAU * float(i) / 16.0,
		})
	card_fx.append({"kind": &"gevurah", "card": card, "born": time, "dur": 1.45,
		"in_letters": in_letters, "ring": ring})


## Zohar: זוהר lights up and splits into two horizontal letter beams (mirroring widened POINT zone).
func play_zohar(target: BattleUnit) -> void:
	if hud == null:
		return
	var index: int = hud.players.find(target)
	if index < 0:
		return
	var card: Rect2 = hud.status_rect(index)
	var beams: Array[Dictionary] = []
	for i in 16:
		beams.append({
			"glyph": _letter(),
			"dir": 1.0 if i % 2 == 0 else -1.0,
			"dist": rng.randf_range(24.0, card.size.x * 0.72),
			"dy": rng.randf_range(-card.size.y * 0.35, card.size.y * 0.35),
			"delay": rng.randf_range(0.0, 0.2),
		})
	card_fx.append({"kind": &"zohar", "card": card, "born": time, "dur": 1.35, "beams": beams})


func _draw_card_fx() -> void:
	for entry in card_fx:
		var age := time - float(entry.born)
		if age < 0.0:
			continue
		match StringName(entry.kind):
			&"tahorah":
				var card: Rect2 = entry.card
				var sweep_y := card.end.y + 6.0 - minf(1.0, age / 0.78) * (card.size.y + 28.0)
				if age < 0.95:
					var a := sin(clampf(age / 0.95, 0.0, 1.0) * PI) * 0.85
					for s_idx in 7:
						var sx := lerpf(card.position.x + 12.0, card.end.x - 12.0, float(s_idx) / 6.0)
						_glyph(ALPHABET[(s_idx * 4 + 1) % ALPHABET.length()], Vector2(sx, sweep_y),
							11, Color(INK_HOT, a), Color(INK_DARK, a))
				if age < 1.15:
					var wk := age / 1.15
					_glyph("טהרה", Vector2(card.get_center().x, card.end.y - wk * (card.size.y + 22.0)),
						16, Color(INK_HOT, sin(wk * PI)), Color(INK_DARK, sin(wk * PI)))
				for p in entry.debuffs:
					var py := float(p.y)
					if sweep_y > py:
						var jx := sin(time * 14.0 + float(p.spin)) * 1.5
						_glyph(String(p.glyph), Vector2(float(p.x) + jx, py), 12, Color(INK_DEBUFF, 0.9), Color(INK_DARK, 0.9))
					else:
						var k := clampf((py - sweep_y) / 62.0, 0.0, 1.0)
						var sx := float(p.x) + sin(k * 7.0 + float(p.spin)) * 9.0 * k
						var sy := py - k * float(p.drift)
						_glyph(String(p.glyph), Vector2(sx, sy), 12, Color(PrayerBook.INK, 1.0 - k), Color(INK_DARK, 1.0 - k))
				for p in entry.rises:
					var k := (age - float(p.delay)) / 0.85
					if k > 0.0 and k < 1.0:
						_glyph(String(p.glyph), Vector2(float(p.x), card.end.y - 4.0 - k * float(p.speed)),
							11, Color(PrayerBook.INK, (1.0 - k) * 0.85), Color(INK_DARK, (1.0 - k) * 0.85))
			&"magen":
				var cards: Array = entry.cards
				for p in entry.cols:
					var k := clampf((age - float(p.delay)) / 0.42, 0.0, 1.0)
					if k <= 0.0:
						continue
					var ease_k := 1.0 - pow(1.0 - k, 3.0)
					var cur_y := (float(p.y) - 68.0) + 68.0 * ease_k
					var fade := 1.0 if age < 1.0 else maxf(0.0, 1.0 - (age - 1.0) / 0.45)
					var col := INK_HOT if k > 0.92 else PrayerBook.INK
					_glyph(String(p.glyph), Vector2(float(p.x), cur_y), 12, Color(col, fade * 0.9), Color(INK_DARK, fade * 0.9))
				if age > 0.2 and age < 1.35 and not cards.is_empty():
					var lock := minf(1.0, (age - 0.2) / 0.28)
					var fade := 1.0 if age < 0.95 else maxf(0.0, 1.0 - (age - 0.95) / 0.4)
					var min_x := (cards[0] as Rect2).position.x
					var max_x := (cards[0] as Rect2).end.x
					var top_y := (cards[0] as Rect2).position.y
					for c in cards:
						var r: Rect2 = c
						min_x = minf(min_x, r.position.x)
						max_x = maxf(max_x, r.end.x)
						top_y = minf(top_y, r.position.y)
					_glyph("מגן", Vector2((min_x + max_x) * 0.5, top_y - 12.0),
						int(15.0 + 5.0 * lock), Color(INK_HOT, fade), Color(INK_DARK, fade))
			&"gevurah":
				var card: Rect2 = entry.card
				var center := card.get_center()
				if age < 0.72:
					for p in entry.in_letters:
						var k := clampf((age - float(p.delay)) / 0.52, 0.0, 1.0)
						if k <= 0.0 or k >= 1.0:
							continue
						var r := float(p.rad) * pow(1.0 - k, 1.7)
						var a := float(p.angle) + float(p.spin) * k
						_glyph(String(p.glyph), center + Vector2(cos(a) * r, sin(a) * r * 0.55),
							12, Color(PrayerBook.INK, 0.35 + 0.65 * k), Color(INK_DARK, k))
				if age >= 0.45 and age < 1.4:
					var k := clampf((age - 0.45) / 0.85, 0.0, 1.0)
					var fade := maxf(0.0, 1.0 - k)
					var rx := 18.0 + k * (card.size.x * 0.46)
					var ry := 10.0 + k * (card.size.y * 0.48)
					for p in entry.ring:
						var a := float(p.angle) + k * 1.1
						var col := INK_HOT if k < 0.25 else PrayerBook.INK
						_glyph(String(p.glyph), center + Vector2(cos(a) * rx, sin(a) * ry),
							int(13.0 - 2.0 * k), Color(col, fade), Color(INK_DARK, fade))
					_glyph("גבורה", center + Vector2(0.0, -6.0 - k * 14.0),
						int(18.0 - 3.0 * k), Color(INK_HOT, sin(k * PI)), Color(INK_DARK, sin(k * PI)))
			&"zohar":
				var card: Rect2 = entry.card
				var center := card.get_center()
				var open := minf(1.0, age / 0.55)
				var fade := 1.0 if age < 0.9 else maxf(0.0, 1.0 - (age - 0.9) / 0.45)
				for p in entry.beams:
					var k := clampf((age - float(p.delay)) / 0.72, 0.0, 1.0)
					if k <= 0.0:
						continue
					var lx := center.x + float(p.dir) * float(p.dist) * k
					var ly := center.y + float(p.dy) * (1.0 - k * 0.5)
					_glyph(String(p.glyph), Vector2(lx, ly), 12, Color(PrayerBook.INK, (1.0 - k) * 0.9), Color(INK_DARK, (1.0 - k) * 0.9))
				_glyph("זוהר", Vector2(center.x, card.position.y - 12.0),
					int(14.0 + 6.0 * open), Color(INK_HOT, fade), Color(INK_DARK, fade))
			&"nechamah":
				var rect: Rect2 = entry.rect
				var center := rect.get_center()
				var soft_glow := sin(clampf(age / float(entry.dur), 0.0, 1.0) * PI)
				draw_rect(rect, Color(PrayerBook.INK, 0.14 * soft_glow))
				_glyph("נחמה", Vector2(center.x, rect.position.y - 14.0 - sin(age * 2.4) * 3.0),
					17, Color(INK_HOT, soft_glow), Color(INK_DARK, soft_glow))
				for p in entry.drops:
					var k := clampf((age - float(p.delay)) / 0.95, 0.0, 1.0)
					if k <= 0.0 or k >= 1.0:
						continue
					var ease_k := 1.0 - pow(1.0 - k, 2.0)
					var px := float(p.x) + sin(k * 5.0 + float(p.phase)) * float(p.sway)
					var py := lerpf(float(p.start_y), float(p.end_y), ease_k)
					var a := sin(k * PI) * 0.92
					var col := INK_HOT if k > 0.72 else PrayerBook.INK
					_glyph(String(p.glyph), Vector2(px, py), int(p.px), Color(col, a), Color(INK_DARK, a))
			&"nechamah_tick":
				for p in entry.parts:
					var pa := age - float(p.delay)
					if pa < 0.0 or pa > float(p.dur):
						continue
					var k := pa / float(p.dur)
					var px := float(p.x) + sin(k * 5.0 + float(p.phase)) * float(p.sway)
					var py := float(p.y) + float(p.vy) * pa
					_glyph(String(p.glyph), Vector2(px, py), 12, Color(INK_HEAL, 1.0 - k), Color(INK_DARK, 1.0 - k))
			&"refuah":
				var card: Rect2 = entry.card
				var center := card.get_center()
				var extra := int(entry.extra)
				var glow := sin(clampf(age / float(entry.dur), 0.0, 1.0) * PI)
				draw_rect(card, Color(PrayerBook.INK, (0.14 + float(extra) * 0.04) * glow))
				for p in entry.helix:
					var k := clampf((age - float(p.delay)) / 0.88, 0.0, 1.0)
					if k <= 0.0 or k >= 1.0:
						continue
					var px := center.x + sin(k * PI * 2.4) * float(p.amp) * float(p.strand) * (1.0 - k * 0.25)
					var py := card.end.y - 6.0 - k * float(p.height)
					var col := INK_HOT if (extra >= 2 and k < 0.35) else PrayerBook.INK
					_glyph(String(p.glyph), Vector2(px, py), int(p.px), Color(col, (1.0 - k) * 0.95), Color(INK_DARK, (1.0 - k) * 0.95))
				_glyph("רפואה", Vector2(center.x, card.position.y - 14.0 - glow * 10.0),
					int(16.0 + float(extra) * 2.0), Color(INK_HOT, glow), Color(INK_DARK, glow))


# ---------------------------------------------------------------- Mishpat (approved 2026-11-26)
## Retribution letters arc red -> #f5f58c from ally to enemy, two walls of Hebrew letters
## slam inward with משפט, white impact frame + shake, then letters drop heavily to the ground.
const M_CHARGE := 0.72
const M_FLASH := 0.05
const M_SHAKE_PX := 7.0
const M_SHAKE_TIME := 0.40
const M_END := 1.25
var mishpat_at := -99.0
var m_target := Rect2()
var m_white: Texture2D
var m_return: Array[Dictionary] = []
var m_crush: Array[Dictionary] = []


## Plays Mishpat on `target`; returns at the impact instant (damage lands then).
func play_mishpat(caster: BattleUnit, target: BattleUnit) -> void:
	if hud == null:
		return
	var enemy_idx: int = hud.opponents.find(target)
	if enemy_idx < 0:
		return
	var caster_idx: int = hud.players.find(caster)
	var origin: Vector2 = hud.status_rect(caster_idx).get_center() if caster_idx >= 0 else Vector2(hud.STAGE_RECT.get_center().x, hud.STAGE_RECT.end.y)
	_build_mishpat(origin, enemy_idx)
	mishpat_at = time + M_CHARGE
	await get_tree().create_timer(M_CHARGE).timeout


func mishpat_busy() -> bool:
	return time - mishpat_at < M_END


func _build_mishpat(origin: Vector2, enemy_idx: int) -> void:
	m_target = hud.enemy_sprite_rect(enemy_idx)
	m_white = hud.silhouettes[enemy_idx] if enemy_idx < hud.silhouettes.size() else null
	var center := m_target.get_center()
	m_return.clear()
	for _i in 14:
		var sx := origin.x + rng.randf_range(-42.0, 42.0)
		var sy := origin.y + rng.randf_range(-12.0, 12.0)
		var ex := center.x + rng.randf_range(-m_target.size.x * 0.35, m_target.size.x * 0.35)
		var ey := center.y + rng.randf_range(-m_target.size.y * 0.35, m_target.size.y * 0.35)
		m_return.append({
			"glyph": _letter(),
			"start": Vector2(sx, sy),
			"ctrl": Vector2(lerpf(sx, ex, 0.5) + rng.randf_range(-40.0, 40.0), minf(sy, ey) - rng.randf_range(28.0, 68.0)),
			"end": Vector2(ex, ey),
			"delay": rng.randf_range(0.0, 0.22),
		})
	m_crush.clear()
	for i in 16:
		var side := -1.0 if i % 2 == 0 else 1.0
		var row := int(i / 2)
		m_crush.append({
			"glyph": _letter(),
			"side": side,
			"y": lerpf(m_target.position.y + 8.0, m_target.end.y - 8.0, float(row) / 7.0),
			"vx": rng.randf_range(-28.0, 28.0),
			"vy": rng.randf_range(24.0, 82.0),
			"px": rng.randi_range(14, 18),
		})


func _draw_mishpat() -> void:
	var age := time - mishpat_at
	if age < -M_CHARGE or age > M_END:
		return
	var center := m_target.get_center()
	var dark := 0.0
	if age < 0.0:
		dark = 0.56 * clampf((age + M_CHARGE) / M_CHARGE, 0.0, 1.0)
	elif age < 1.1:
		dark = 0.56 * (1.0 - clampf((age - 0.3) / 0.8, 0.0, 1.0))
	if dark > 0.0:
		draw_rect(hud.STAGE_RECT, Color(0.02, 0.0, 0.05, dark))
	if age < 0.0:
		var c := age + M_CHARGE
		for p in m_return:
			var k := clampf((c - float(p.delay)) / 0.5, 0.0, 1.0)
			if k <= 0.0:
				continue
			var u := 1.0 - k
			var pos: Vector2 = u * u * (p.start as Vector2) + 2.0 * u * k * (p.ctrl as Vector2) + k * k * (p.end as Vector2)
			var col := INK_DEBUFF if k < 0.55 else PrayerBook.INK
			_glyph(String(p.glyph), pos, int(11.0 + 4.0 * k), Color(col, 0.35 + 0.65 * k), Color(INK_DARK, k))
		var slam := clampf((c - 0.38) / 0.34, 0.0, 1.0)
		if slam > 0.0:
			var ease_s := slam * slam
			var gap := 86.0 * (1.0 - ease_s)
			for p in m_crush:
				var col := INK_HOT if slam > 0.75 else PrayerBook.INK
				_glyph(String(p.glyph), Vector2(center.x + float(p.side) * (14.0 + gap), float(p.y)),
					int(p.px), Color(col, slam), Color(INK_DARK, slam))
			_glyph("משפט", Vector2(center.x, m_target.position.y - 12.0 + 12.0 * ease_s),
				int(16.0 + 8.0 * ease_s), Color(INK_HOT, slam), Color(INK_DARK, slam))
		return
	if age < M_FLASH:
		draw_rect(Rect2(Vector2.ZERO, hud.SCREEN), Color(1, 1, 1, 0.88))
	if m_white != null and age < 0.34 and int(age * 30.0) % 2 == 0:
		draw_texture_rect(m_white, m_target, false, Color(1, 1, 1, 0.9))
	if age < 0.38:
		var k := age / 0.38
		_glyph("משפט", center, int(26.0 - 4.0 * k), Color(INK_HOT, 1.0 - k * 0.3), Color(INK_DARK, 1.0 - k * 0.3))
	if age < M_END:
		var bk := age / M_END
		var floor_y: float = float(hud.STAGE_RECT.end.y) - 6.0
		for p in m_crush:
			var px := center.x + float(p.side) * 12.0 + float(p.vx) * age
			var py := minf(floor_y, float(p.y) + float(p.vy) * age + 240.0 * age * age)
			_glyph(String(p.glyph), Vector2(px, py), int(p.px), Color(PrayerBook.INK, 1.0 - bk * bk), Color(INK_DARK, 1.0 - bk))


# ---------------------------------------------------------------- Sanverim, Nechamah, Cherev, Refuah (approved 2026-11-26)

func _unit_rect(unit: BattleUnit) -> Rect2:
	if hud == null or unit == null:
		return Rect2()
	var idx: int = hud.players.find(unit)
	if idx >= 0:
		return hud.status_rect(idx)
	idx = hud.opponents.find(unit)
	if idx >= 0:
		return hud.enemy_sprite_rect(idx)
	return Rect2()


## Refuah: ascending double helix of Hebrew letters + רפואה, scaling with extra PP.
func play_refuah(target: BattleUnit, extra_pp: int = 0) -> void:
	if hud == null:
		return
	var index: int = hud.players.find(target)
	if index < 0:
		return
	var card: Rect2 = hud.status_rect(index)
	var extra := maxi(0, extra_pp)
	var count := 18 + extra * 8
	var helix: Array[Dictionary] = []
	for i in count:
		helix.append({
			"glyph": _letter(),
			"strand": 1.0 if i % 2 == 0 else -1.0,
			"delay": (float(i) / float(count)) * 0.55,
			"amp": rng.randf_range(card.size.x * 0.22, card.size.x * 0.42),
			"height": rng.randf_range(72.0, 108.0) + float(extra) * 10.0,
			"px": rng.randi_range(11, 14 + extra),
		})
	card_fx.append({"kind": &"refuah", "card": card, "born": time, "dur": 1.5,
		"helix": helix, "extra": extra})


## Nechamah: gentle dew-like falling Hebrew letters + נחמה (opposite of burn).
func play_nechamah(target: BattleUnit, stacks: int = 1) -> void:
	var rect := _unit_rect(target)
	if rect.size == Vector2.ZERO:
		return
	var count := 16 + maxi(1, stacks) * 5
	var drops: Array[Dictionary] = []
	for _i in count:
		drops.append({
			"glyph": _letter(),
			"x": rng.randf_range(rect.position.x + 12.0, rect.end.x - 12.0),
			"start_y": rect.position.y - rng.randf_range(34.0, 82.0),
			"end_y": rect.position.y + rng.randf_range(12.0, maxf(14.0, rect.size.y - 10.0)),
			"delay": rng.randf_range(0.0, 0.52),
			"sway": rng.randf_range(5.0, 13.0),
			"phase": rng.randf_range(0.0, TAU),
			"px": rng.randi_range(11, 14),
		})
	card_fx.append({"kind": &"nechamah", "rect": rect, "born": time, "dur": 1.65,
		"drops": drops, "stacks": maxi(1, stacks)})


## Nechamah round tick: gentle rising letters in soft healing green (#b8f5a2).
func play_nechamah_tick(target: BattleUnit, stacks: int = 1) -> void:
	var rect := _unit_rect(target)
	if rect.size == Vector2.ZERO:
		return
	var parts: Array[Dictionary] = []
	for _i in 6 + maxi(1, stacks) * 3:
		parts.append({
			"glyph": _letter(),
			"x": rng.randf_range(rect.position.x + 14.0, rect.end.x - 14.0),
			"y": rect.end.y - 10.0,
			"vy": -rng.randf_range(32.0, 58.0),
			"sway": rng.randf_range(4.0, 10.0),
			"phase": rng.randf_range(0.0, TAU),
			"delay": rng.randf_range(0.0, 0.2),
			"dur": 0.9,
		})
	card_fx.append({"kind": &"nechamah_tick", "born": time, "dur": 1.15, "parts": parts})


## Sanverim: closing letter curtains squeeze vision, blinding flash, shake, radial letter flares.
const S_IMPACT := 0.42
const S_SHAKE_PX := 5.5
const S_SHAKE_TIME := 0.28
const S_END := 1.15
var sanverim_at := -99.0
var s_rect := Rect2()
var s_white: Texture2D
var s_curtains: Array[Dictionary] = []
var s_flares: Array[Dictionary] = []


func play_sanverim(target: BattleUnit) -> void:
	var rect := _unit_rect(target)
	if rect.size == Vector2.ZERO:
		return
	s_rect = rect
	var e_idx: int = hud.opponents.find(target)
	s_white = hud.silhouettes[e_idx] if (e_idx >= 0 and e_idx < hud.silhouettes.size()) else null
	s_curtains.clear()
	for i in 20:
		s_curtains.append({
			"glyph": _letter(),
			"side": -1.0 if i % 2 == 0 else 1.0,
			"row": float(int(i / 2)) / 9.0,
			"jitter": rng.randf_range(-4.0, 4.0),
			"px": rng.randi_range(12, 16),
		})
	s_flares.clear()
	for i in 18:
		s_flares.append({
			"glyph": _letter(),
			"a": TAU * float(i) / 18.0 + rng.randf_range(-0.12, 0.12),
			"speed": rng.randf_range(70.0, 155.0),
			"px": rng.randi_range(11, 16),
		})
	sanverim_at = time + S_IMPACT


func sanverim_busy() -> bool:
	return time - sanverim_at < S_END


func _draw_sanverim() -> void:
	var age := time - sanverim_at
	if age < -S_IMPACT or age > S_END:
		return
	var center := s_rect.get_center()
	var w := s_rect.size.x + 24.0
	var h := s_rect.size.y
	if age < 0.0:
		var c := clampf((age + S_IMPACT) / S_IMPACT, 0.0, 1.0)
		var ease_c := c * c
		draw_rect(hud.STAGE_RECT, Color(0.02, 0.01, 0.04, 0.38 * c))
		for p in s_curtains:
			var x_off := lerpf(w * 0.72, 6.0, ease_c)
			var px := center.x + float(p.side) * x_off + float(p.jitter)
			var py := center.y - h * 0.42 + float(p.row) * h * 0.84
			var col := INK_HOT if c > 0.78 else PrayerBook.INK
			_glyph(String(p.glyph), Vector2(px, py), int(p.px), Color(col, 0.35 + 0.65 * c), Color(INK_DARK, c))
		_glyph("סנוורים", Vector2(center.x, center.y - h * 0.52), int(14.0 + 7.0 * ease_c), Color(INK_HOT, c), Color(INK_DARK, c))
		return
	if age < 0.08:
		draw_rect(Rect2(Vector2.ZERO, hud.SCREEN), Color(1.0, 1.0, 0.91, (1.0 - age / 0.08) * 0.85))
	if s_white != null and age < 0.28 and int(age * 30.0) % 2 == 0:
		draw_texture_rect(s_white, s_rect, false, Color(1, 1, 1, 0.9))
	if age < 0.85:
		var k := age / 0.85
		for p in s_flares:
			var dist := 10.0 + float(p.speed) * age * (1.0 - k * 0.35)
			var px := center.x + cos(float(p.a)) * dist
			var py := center.y + sin(float(p.a)) * dist * 0.65
			var col := INK_HOT if k < 0.3 else (PrayerBook.INK if k < 0.65 else INK_DEBUFF)
			_glyph(String(p.glyph), Vector2(px, py), int(float(p.px) * (1.0 - k * 0.2)), Color(col, 1.0 - k * k), Color(INK_DARK, 1.0 - k * k))
		var wa := maxf(0.0, 1.0 - k * 1.25)
		if wa > 0.01:
			_glyph("סנוורים", Vector2(center.x, center.y - 4.0 - k * 16.0), int(22.0 - 4.0 * k), Color(INK_HOT, wa), Color(INK_DARK, wa))


## Cherev: AoE blade of Hebrew letters across the target row (3 PP), with charge, slash, flash, shake.
const C_CHARGE := 0.48
const C_FLASH := 0.055
const C_SHAKE_PX := 7.5
const C_SHAKE_TIME := 0.42
const C_END := 1.18
var cherev_at := -99.0
var c_on_enemies := true
var c_y_mid := 140.0
var c_x_start := 24.0
var c_x_end := 520.0
var c_charge: Array[Dictionary] = []
var c_trail: Array[Dictionary] = []


func play_cherev(on_enemies: bool) -> void:
	if hud == null:
		return
	c_on_enemies = on_enemies
	c_x_start = 24.0
	c_x_end = hud.SCREEN.x - 24.0
	if on_enemies:
		c_y_mid = hud.STAGE_RECT.get_center().y
		for i in hud.opponents.size():
			if (hud.opponents[i] as BattleUnit).is_alive():
				c_y_mid = hud.enemy_sprite_rect(i).get_center().y
				break
	else:
		c_y_mid = hud.status_rect(0).get_center().y if not hud.players.is_empty() else hud.STAGE_RECT.end.y
	c_charge.clear()
	for i in 16:
		c_charge.append({
			"glyph": _letter(),
			"angle": rng.randf_range(0.0, TAU),
			"rad": rng.randf_range(55.0, 115.0),
			"spin": (1.0 if i % 2 == 0 else -1.0) * rng.randf_range(2.2, 3.6),
			"delay": rng.randf_range(0.0, 0.16),
		})
	c_trail.clear()
	var tilt := -48.0 if on_enemies else -14.0
	for i in 30:
		var k := float(i) / 29.0
		var x := lerpf(c_x_start, c_x_end, k)
		var y := c_y_mid + (k - 0.5) * tilt + rng.randf_range(-8.0, 8.0)
		var split_dir := -1.0 if i % 2 == 0 else 1.0
		c_trail.append({
			"glyph": _letter(),
			"x": x, "y": y, "k": k,
			"vx": rng.randf_range(14.0, 54.0),
			"vy": split_dir * rng.randf_range(38.0, 105.0),
			"px": rng.randi_range(14, 21),
		})
	cherev_at = time + C_CHARGE
	await get_tree().create_timer(C_CHARGE).timeout


func cherev_busy() -> bool:
	return time - cherev_at < C_END


func _draw_cherev() -> void:
	var age := time - cherev_at
	if age < -C_CHARGE or age > C_END:
		return
	var tilt := -48.0 if c_on_enemies else -14.0
	var dark := 0.0
	if age < 0.0:
		dark = 0.55 * clampf((age + C_CHARGE) / C_CHARGE, 0.0, 1.0)
	elif age < 1.0:
		dark = 0.55 * (1.0 - clampf((age - 0.25) / 0.75, 0.0, 1.0))
	if dark > 0.0:
		draw_rect(hud.STAGE_RECT, Color(0.02, 0.01, 0.05, dark))
	if age < 0.0:
		var c := clampf((age + C_CHARGE) / C_CHARGE, 0.0, 1.0)
		var ox := c_x_start + 26.0
		var oy := c_y_mid - tilt * 0.5
		for p in c_charge:
			var k := clampf((c - float(p.delay)) / (1.0 - float(p.delay)), 0.0, 1.0)
			if k <= 0.0:
				continue
			var r := float(p.rad) * pow(1.0 - k, 1.6)
			var a := float(p.angle) + float(p.spin) * k
			_glyph(String(p.glyph), Vector2(ox + cos(a) * r, oy + sin(a) * r * 0.55), 13, Color(PrayerBook.INK, 0.35 + 0.65 * k), Color(INK_DARK, k))
		_glyph("חרב", Vector2(ox + 10.0, oy - 22.0), int(15.0 + 8.0 * c), Color(INK_HOT, c), Color(INK_DARK, c))
		return
	if age < C_FLASH:
		draw_rect(Rect2(Vector2.ZERO, hud.SCREEN), Color(1.0, 1.0, 0.96, 0.88))
	if c_on_enemies and age < 0.42 and int(age * 32.0) % 2 == 0:
		for i in hud.opponents.size():
			if (hud.opponents[i] as BattleUnit).is_alive() and i < hud.silhouettes.size() and hud.silhouettes[i] != null:
				draw_texture_rect(hud.silhouettes[i], hud.enemy_sprite_rect(i), false, Color(1, 1, 1, 0.9))
	var slash_k := clampf(age / 0.16, 0.0, 1.0)
	for p in c_trail:
		if float(p.k) > slash_k:
			continue
		var local_age := maxf(0.0, age - float(p.k) * 0.14)
		var lk := clampf(local_age / 0.95, 0.0, 1.0)
		var px := float(p.x) + float(p.vx) * local_age
		var py := float(p.y) + float(p.vy) * local_age + 140.0 * local_age * local_age
		var col := INK_HOT if lk < 0.22 else PrayerBook.INK
		_glyph(String(p.glyph), Vector2(px, py), int(float(p.px) * (1.0 - lk * 0.25)), Color(col, 1.0 - lk * lk), Color(INK_DARK, 1.0 - lk * lk))
	if age < 0.55:
		var wk := age / 0.55
		_glyph("חרב", Vector2(hud.SCREEN.x * 0.5, c_y_mid - 28.0 - wk * 12.0), int(26.0 - 4.0 * wk), Color(INK_HOT, 1.0 - wk), Color(INK_DARK, 1.0 - wk))


# ------------------------------------------------------------------ D-118 Chaki & Shachar (100% Hebrew letters)

## Chaki (חכי): 6 parallel counter-flowing columns of Hebrew letters bind the target with lock-in & persistent ח.
const CHAKI_LOCK := 0.55
const CHAKI_END := 1.85
var chaki_at := -99.0
var chaki_target: BattleUnit
var chaki_bars: Array[Dictionary] = []
var chaki_shards: Array[Dictionary] = []


func play_chaki(target: BattleUnit) -> void:
	if hud == null or target == null:
		return
	chaki_target = target
	chaki_bars.clear()
	for b in 6:
		var ox := -42.0 + float(b) * 16.8
		var dir := 1.0 if b % 2 == 0 else -1.0
		var glyphs: Array[Dictionary] = []
		for g in 14:
			glyphs.append({"y0": -110.0 + float(g) * 18.0, "glyph": _letter(), "px": 11 + (g % 3) * 2})
		chaki_bars.append({"ox": ox, "dir": dir, "glyphs": glyphs})
	chaki_shards.clear()
	for i in 22:
		var a := float(i) / 22.0 * TAU
		chaki_shards.append({
			"vx": cos(a) * rng.randf_range(50.0, 120.0),
			"vy": sin(a) * rng.randf_range(35.0, 90.0),
			"glyph": _letter(),
			"px": rng.randi_range(11, 16),
		})
	chaki_at = time


func chaki_busy() -> bool:
	return time - chaki_at < CHAKI_END


func _draw_chaki() -> void:
	var age := time - chaki_at
	if age < 0.0 or age > CHAKI_END or chaki_target == null:
		return
	var rect := _unit_rect(chaki_target)
	if rect.size.x <= 0.0:
		return
	var center := rect.get_center()
	var locked := age >= CHAKI_LOCK
	var lock_age := maxf(0.0, age - CHAKI_LOCK)
	var dark := 0.34 * (1.0 - clampf((age - 1.2) / 0.65, 0.0, 1.0))
	if dark > 0.01:
		draw_rect(hud.STAGE_RECT, Color(0.02, 0.01, 0.06, dark))
	var squeeze := lerpf(1.42, 1.0, clampf(age / CHAKI_LOCK, 0.0, 1.0))
	var cage_a := clampf(age / 0.25, 0.0, 1.0) if age < 1.25 else maxf(0.0, 1.0 - (age - 1.25) / 0.6)
	var speed_px := 26.0 if locked else 140.0
	var top_y: float = hud.STAGE_RECT.position.y + 8.0
	var span_h: float = maxf(80.0, hud.STAGE_RECT.size.y - 16.0)
	for bar in chaki_bars:
		var bx := center.x + float(bar.ox) * squeeze
		var dir := float(bar.dir)
		for g in bar.glyphs:
			var raw_y := float(g.y0) + age * speed_px * dir
			var gy := top_y + fposmod(raw_y + span_h * 2.0, span_h)
			var col := PrayerBook.INK if locked else INK_HOT
			_glyph(String(g.glyph), Vector2(bx, gy), int(g.px), Color(col, cage_a * 0.9), Color(INK_DARK, cage_a * 0.85))
	var word_y := lerpf(top_y + 24.0, center.y, clampf(age / CHAKI_LOCK, 0.0, 1.0))
	var word_a := 1.0 if age < 1.3 else maxf(0.0, 1.0 - (age - 1.3) / 0.55)
	if word_a > 0.01:
		_glyph("חכי", Vector2(center.x, word_y), 28 if locked else 22, Color(INK_HOT, word_a), Color(INK_DARK, word_a))
	if locked and lock_age < 0.52:
		var sa := 1.0 - lock_age / 0.52
		for s in chaki_shards:
			_glyph(String(s.glyph), Vector2(center.x + float(s.vx) * lock_age, center.y + float(s.vy) * lock_age),
				int(s.px), Color(PrayerBook.INK, sa), Color(INK_DARK, sa))
	if locked and lock_age < 0.065:
		draw_rect(Rect2(Vector2.ZERO, hud.SCREEN), Color(1.0, 1.0, 0.9, (1.0 - lock_age / 0.065) * 0.5))


## Shachar (שחר): Phase 1 cast (solar arc of Hebrew letters + pending mark ש); Phase 2 dawn rays at next round start.
const SHACHAR_CAST_END := 1.25
const SHACHAR_DAWN_END := 1.55
var shachar_pending := false
var shachar_cast_at := -99.0
var shachar_dawn_at := -99.0
var shachar_arc: Array[Dictionary] = []
var shachar_rays: Array[Dictionary] = []
var shachar_motes: Array[Dictionary] = []


func play_shachar() -> void:
	if hud == null:
		return
	shachar_pending = true
	shachar_arc.clear()
	for ring in 3:
		var n := 12 + ring * 5
		for i in n:
			var ang := PI + (float(i) / float(n - 1)) * PI
			shachar_arc.append({"ring": ring, "ang": ang, "glyph": _letter(), "px": 10 + ring * 2})
	shachar_cast_at = time


func play_shachar_dawn() -> void:
	if hud == null:
		return
	shachar_pending = false
	shachar_rays.clear()
	for r in 18:
		var ang := PI * 0.14 + (float(r) / 17.0) * PI * 0.72
		var stream: Array[Dictionary] = []
		for k in 13:
			var ch := "שחר"[k % 3] if k % 4 == 0 else _letter()
			stream.append({"dist": 22.0 + float(k) * 20.0, "glyph": ch, "px": 11 + (k % 3) * 2, "wobble": rng.randf_range(-5.0, 5.0)})
		shachar_rays.append({"ang": ang, "stream": stream})
	shachar_motes.clear()
	for i in 36:
		shachar_motes.append({
			"x": rng.randf_range(40.0, hud.SCREEN.x - 40.0),
			"y": hud.STAGE_RECT.end.y - rng.randf_range(6.0, 44.0),
			"vy": rng.randf_range(35.0, 75.0),
			"glyph": _letter(),
			"px": rng.randi_range(10, 16),
			"delay": rng.randf_range(0.0, 0.35),
		})
	shachar_dawn_at = time


func shachar_busy() -> bool:
	return (time - shachar_cast_at < SHACHAR_CAST_END) or (time - shachar_dawn_at < SHACHAR_DAWN_END)


func _draw_shachar() -> void:
	var sun := Vector2(hud.SCREEN.x * 0.5, hud.STAGE_RECT.position.y + 18.0)
	var cast_age := time - shachar_cast_at
	if cast_age >= 0.0 and cast_age <= SHACHAR_CAST_END:
		var prog := clampf(cast_age / SHACHAR_CAST_END, 0.0, 1.0)
		var alpha := clampf(cast_age / 0.25, 0.0, 1.0) * (1.0 - clampf((cast_age - 0.85) / 0.4, 0.0, 1.0))
		draw_rect(hud.STAGE_RECT, Color(0.03, 0.01, 0.07, 0.32 * alpha))
		for l in shachar_arc:
			var r := (20.0 + float(l.ring) * 18.0) * (0.45 + 0.55 * prog)
			var lx := sun.x + cos(float(l.ang) + cast_age * 0.25) * r * 1.45
			var ly := sun.y - sin(float(l.ang)) * r * 0.65 + 14.0
			var col := INK_HOT if int(l.ring) == 0 else PrayerBook.INK
			_glyph(String(l.glyph), Vector2(lx, ly), int(l.px), Color(col, alpha), Color(INK_DARK, alpha))
		_glyph("שחר", sun + Vector2(0, 24.0), int(20.0 + 10.0 * prog), Color(INK_HOT, alpha), Color(INK_DARK, alpha))
	var dawn_age := time - shachar_dawn_at
	if dawn_age >= 0.0 and dawn_age <= SHACHAR_DAWN_END:
		var glow := maxf(0.0, 0.34 * (1.0 - dawn_age / SHACHAR_DAWN_END))
		draw_rect(hud.STAGE_RECT, Color(1.0, 0.89, 0.52, glow))
		var ra := 1.0 if dawn_age < 0.2 else maxf(0.0, 1.0 - (dawn_age - 0.2) / (SHACHAR_DAWN_END - 0.2))
		var reach := clampf(dawn_age / 0.22, 0.0, 1.0)
		for ray in shachar_rays:
			var ang := float(ray.ang)
			for s in ray.stream:
				var d := float(s.dist) * reach + dawn_age * 105.0
				var rx := sun.x + cos(ang) * d * 1.35 + float(s.wobble)
				var ry := sun.y + sin(ang) * d
				if ry > hud.STAGE_RECT.end.y:
					continue
				var col := INK_HOT if float(s.dist) < 120.0 else PrayerBook.INK
				_glyph(String(s.glyph), Vector2(rx, ry), int(s.px), Color(col, ra), Color(INK_DARK, ra * 0.85))
		_glyph("שחר", sun + Vector2(0, 26.0), 32, Color(INK_HOT, ra), Color(INK_DARK, ra))
		for m in shachar_motes:
			var ma := dawn_age - float(m.delay)
			if ma < 0.0 or ma > 1.2:
				continue
			var alpha := maxf(0.0, 1.0 - ma / 1.2)
			_glyph(String(m.glyph), Vector2(float(m.x), float(m.y) - float(m.vy) * ma), int(m.px),
				Color(PrayerBook.INK, alpha * 0.85), Color(INK_DARK, alpha * 0.7))
		if dawn_age < 0.095:
			draw_rect(Rect2(Vector2.ZERO, hud.SCREEN), Color(1.0, 0.98, 0.86, (1.0 - dawn_age / 0.095) * 0.72))


# ------------------------------------------------------------------ D-118 Esh Sinai, Lehavah & Hasneh Habo'er (100% Hebrew letters)

## Draws a Hebrew word right-to-left cycling through `palette` per glyph with real glyph widths.
func _draw_palette_word(word: String, center: Vector2, px: int, alpha: float, palette: Array[Color]) -> void:
	if alpha <= 0.01 or word.is_empty() or palette.is_empty():
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
		var w := widths[i]
		cursor_x -= w
		if ch != " ":
			var col: Color = palette[i % palette.size()]
			var pos := Vector2(cursor_x, center.y)
			draw_string_outline(font, pos, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, px, 3, Color(INK_DARK, alpha * 0.9))
			draw_string(font, pos, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, px, Color(col, alpha))
		cursor_x -= pad


## Draws a Hebrew word right-to-left with alternating 3-color sacred fire glyphs (orange, yellow, white).
func _draw_tricolor_word(word: String, center: Vector2, px: int, alpha: float) -> void:
	_draw_palette_word(word, center, px, alpha, FIRE_PALETTE)


## Esh Sinai (אש סיני): 4 fiery Hebrew-letter pillars in 3 colors (orange, yellow, white);
## screen flash ONLY on the 1st immediate impact (hits I, II, III have no screen flash).
const ESH_SINAI_HIT_TIMES: Array[float] = [0.0, 0.72, 1.32, 1.92]
const ESH_SINAI_END := 2.75
var esh_sinai_at := -99.0
var esh_sinai_target: BattleUnit
var esh_sinai_white: Texture2D
var esh_sinai_hits: Array[Dictionary] = []
var esh_sinai_max_hit := 3


func play_esh_sinai(target: BattleUnit) -> void:
	if hud == null or target == null:
		return
	esh_sinai_target = target
	var e_idx: int = hud.opponents.find(target)
	esh_sinai_white = hud.silhouettes[e_idx] if (e_idx >= 0 and e_idx < hud.silhouettes.size()) else null
	esh_sinai_hits.clear()
	esh_sinai_max_hit = ESH_SINAI_HIT_TIMES.size() - 1
	var sinai_word := "אשסיני"
	for idx in ESH_SINAI_HIT_TIMES.size():
		var col: Array[Dictionary] = []
		var count := 60 if idx == 0 else 44
		var tilt := 0.0 if idx == 0 else (-18.0 if idx == 1 else (18.0 if idx == 2 else 0.0))
		for i in count:
			var ch := sinai_word.substr(i % sinai_word.length(), 1) if i % 5 == 0 else _letter()
			col.append({
				"frac": float(i) / float(count),
				"jitter_x": rng.randf_range(-1.0, 1.0) * (27.0 if idx == 0 else 19.0),
				"glyph": ch,
				"px": rng.randi_range(15, 28) if idx == 0 else rng.randi_range(13, 23),
				"color_idx": i % 3,
			})
		var embers: Array[Dictionary] = []
		var ember_count := 34 if idx == 0 else 22
		for i in ember_count:
			var ang := -PI * 0.15 - rng.randf() * PI * 0.7
			var spd := rng.randf_range(75.0, 260.0)
			var side := 1.0 if rng.randf() < 0.5 else -1.0
			embers.append({
				"vx": cos(ang) * spd * side * 0.9,
				"vy": sin(ang) * spd - 35.0,
				"glyph": _letter(),
				"px": rng.randi_range(11, 20),
				"life": rng.randf_range(0.45, 1.0),
				"color_idx": i % 3,
			})
		esh_sinai_hits.append({
			"ht": ESH_SINAI_HIT_TIMES[idx],
			"idx": idx,
			"tilt": tilt,
			"col": col,
			"embers": embers,
		})
	esh_sinai_at = time


func cancel_esh_sinai_after(last_idx: int) -> void:
	esh_sinai_max_hit = mini(esh_sinai_max_hit, last_idx)


func esh_sinai_busy() -> bool:
	return time - esh_sinai_at < ESH_SINAI_END


func _draw_esh_sinai() -> void:
	var age := time - esh_sinai_at
	if age < 0.0 or age > ESH_SINAI_END or esh_sinai_target == null:
		return
	var rect := _unit_rect(esh_sinai_target)
	if rect.size.x <= 0.0:
		return
	var center := rect.get_center()
	var dark := 0.44 if age < 2.2 else maxf(0.0, 0.44 * (1.0 - (age - 2.2) / 0.55))
	if dark > 0.01:
		draw_rect(hud.STAGE_RECT, Color(0.03, 0.01, 0.05, dark))
	var top_y: float = hud.STAGE_RECT.position.y + 8.0
	var span_h: float = maxf(120.0, hud.STAGE_RECT.size.y - 16.0)
	var flash_foe := false
	var screen_flash := 0.0
	for h in esh_sinai_hits:
		var idx := int(h.idx)
		if idx > esh_sinai_max_hit:
			continue
		var h_age := age - float(h.ht)
		if h_age < 0.0 or h_age > 0.72:
			continue
		if h_age < 0.22 and int(h_age * 30.0) % 2 == 0:
			flash_foe = true
		# Screen flash ONLY on the 1st immediate impact (idx == 0)
		if idx == 0 and h_age < 0.085:
			screen_flash = (1.0 - h_age / 0.085) * 0.62
		var alpha := 1.0 if h_age < 0.08 else maxf(0.0, 1.0 - (h_age - 0.08) / 0.58)
		var tilt := float(h.tilt)
		for p in h.col:
			var frac := float(p.frac)
			var py := top_y + frac * span_h
			var px := center.x + float(p.jitter_x) * (0.4 + frac * 0.7) + tilt * (1.0 - frac)
			var ci := int(p.color_idx)
			var ga := alpha * (1.0 if ci == 2 else 0.92)
			_glyph(String(p.glyph), Vector2(px, py), int(p.px), Color(FIRE_PALETTE[ci], ga), Color(INK_DARK, ga * 0.85))
		_draw_tricolor_word("אש סיני", Vector2(center.x + tilt * 0.4, top_y + span_h * 0.34 + h_age * 36.0),
			32 if idx == 0 else 24, alpha)
		for e in h.embers:
			var elife := float(e.life)
			if h_age > elife:
				continue
			var ea := maxf(0.0, 1.0 - h_age / elife)
			var ex := center.x + float(e.vx) * h_age
			var ey := rect.end.y - 12.0 + float(e.vy) * h_age + 130.0 * h_age * h_age
			_glyph(String(e.glyph), Vector2(ex, ey), int(e.px), Color(FIRE_PALETTE[int(e.color_idx)], ea), Color(INK_DARK, ea * 0.8))
	if flash_foe and esh_sinai_white != null:
		draw_texture_rect(esh_sinai_white, rect, false, Color(1.0, 0.98, 0.88, 0.9))
	if screen_flash > 0.01:
		draw_rect(Rect2(Vector2.ZERO, hud.SCREEN), Color(1.0, 0.96, 0.82, screen_flash))


## Lehavah (להבה): spiral convergence of 3-color light & fire letters -> 3-color explosion
## + white-gold blinding letter ring + single flash (returns at boom instant).
const LEHAVAH_BOOM := 0.62
const LEHAVAH_SHAKE_PX := 7.5
const LEHAVAH_SHAKE_TIME := 0.26
const LEHAVAH_END := 1.45
var lehavah_at := -99.0
var lehavah_target: BattleUnit
var lehavah_white: Texture2D
var lehavah_inward: Array[Dictionary] = []
var lehavah_blast: Array[Dictionary] = []
var lehavah_ring: Array[Dictionary] = []


func play_lehavah(target: BattleUnit) -> void:
	if hud == null or target == null:
		return
	lehavah_target = target
	var e_idx: int = hud.opponents.find(target)
	lehavah_white = hud.silhouettes[e_idx] if (e_idx >= 0 and e_idx < hud.silhouettes.size()) else null
	lehavah_inward.clear()
	for i in 28:
		lehavah_inward.append({
			"a": (float(i) / 28.0) * TAU,
			"rad": rng.randf_range(95.0, 160.0),
			"glyph": _letter(),
			"px": rng.randi_range(12, 18),
			"color_idx": i % 3,
		})
	lehavah_blast.clear()
	var leh_word := "להבה"
	for i in 48:
		var a := (float(i) / 48.0) * TAU + rng.randf_range(-0.15, 0.15)
		var spd := rng.randf_range(95.0, 305.0)
		var ch := leh_word.substr(i % leh_word.length(), 1) if i % 4 == 0 else _letter()
		lehavah_blast.append({
			"vx": cos(a) * spd,
			"vy": sin(a) * spd * 0.78,
			"glyph": ch,
			"px": rng.randi_range(13, 24),
			"color_idx": i % 3,
			"life": rng.randf_range(0.55, 1.05),
		})
	lehavah_ring.clear()
	for i in 20:
		lehavah_ring.append({
			"a": (float(i) / 20.0) * TAU,
			"glyph": _letter(),
			"px": 15 + (i % 2) * 3,
		})
	lehavah_at = time + LEHAVAH_BOOM
	await get_tree().create_timer(LEHAVAH_BOOM).timeout


func lehavah_busy() -> bool:
	return time - lehavah_at < LEHAVAH_END


func _draw_lehavah() -> void:
	var age := time - lehavah_at
	if age < -LEHAVAH_BOOM or age > LEHAVAH_END or lehavah_target == null:
		return
	var rect := _unit_rect(lehavah_target)
	if rect.size.x <= 0.0:
		return
	var center := rect.get_center()
	var dark := 0.36 * clampf((age + LEHAVAH_BOOM) / LEHAVAH_BOOM, 0.0, 1.0) if age < 0.0 else maxf(0.0, 0.36 * (1.0 - age / 1.4))
	if dark > 0.01:
		draw_rect(hud.STAGE_RECT, Color(0.04, 0.01, 0.05, dark))
	if age < 0.0:
		var p := clampf((age + LEHAVAH_BOOM) / LEHAVAH_BOOM, 0.0, 1.0)
		for pt in lehavah_inward:
			var r := float(pt.rad) * pow(1.0 - p, 1.4)
			var ang := float(pt.a) + p * 3.2
			var pos := center + Vector2(cos(ang) * r, sin(ang) * r * 0.72)
			_glyph(String(pt.glyph), pos, int(pt.px), Color(FIRE_PALETTE[int(pt.color_idx)], 0.3 + 0.7 * p), Color(INK_DARK, p * 0.85))
		_draw_tricolor_word("להבה", center + Vector2(0.0, -34.0), int(18.0 + p * 12.0), p)
		return
	if lehavah_white != null and age < 0.24 and int(age * 30.0) % 2 == 0:
		draw_texture_rect(lehavah_white, rect, false, Color(1.0, 0.99, 0.9, 0.9))
	for pt in lehavah_blast:
		var life := float(pt.life)
		if age > life:
			continue
		var a := maxf(0.0, 1.0 - age / life)
		var pos := center + Vector2(float(pt.vx) * age, float(pt.vy) * age + 55.0 * age * age)
		_glyph(String(pt.glyph), pos, int(pt.px), Color(FIRE_PALETTE[int(pt.color_idx)], a), Color(INK_DARK, a * 0.85))
	if age < 0.85:
		var ra := 1.0 - age / 0.85
		var rad := 22.0 + age * 175.0
		for b in lehavah_ring:
			var ang := float(b.a) + age * 1.4
			var pos := center + Vector2(cos(ang) * rad, sin(ang) * rad * 0.62)
			_glyph(String(b.glyph), pos, int(b.px), Color(1.0, 0.99, 0.88, ra), Color(INK_DARK, ra * 0.8))
	if age < 0.95:
		_draw_tricolor_word("להבה", center + Vector2(0.0, -24.0 - age * 26.0), 34, 1.0 - age / 0.95)
	if age < 0.08:
		draw_rect(Rect2(Vector2.ZERO, hud.SCREEN), Color(1.0, 0.98, 0.86, (1.0 - age / 0.08) * 0.65))


## Hasneh Habo'er (הסנה הבוער): Gabriel's Burning Bush (10 HP) — living emerald-green Hebrew-letter
## branches interwoven with continuous 3-color flame letters that burn without consuming it.
## Supports multiple simultaneous living bushes.
const HASNEH_BLOOM := 0.78
const HASNEH_INTRO_END := 2.25
var hasneh_at := -99.0
var hasneh_hp := 0
var hasneh_pos := Vector2.ZERO
var hasneh_branches: Array[Dictionary] = []
var hasneh_flames: Array[Dictionary] = []
var hasneh_bushes: Array[Dictionary] = []


func play_hasneh_haboer(caster: BattleUnit, bush_hp: int = PrayerBook.HASNEH_BUSH_HP, bush_unit: BattleUnit = null) -> void:
	if hud == null:
		return
	var slot_idx := hasneh_bushes.size()
	var pos := Vector2(hud.SCREEN.x * 0.72, hud.STAGE_RECT.end.y - 26.0)
	if bush_unit != null:
		var u_rect := _unit_rect(bush_unit)
		if u_rect.size.x > 0.0:
			pos = Vector2(u_rect.get_center().x, u_rect.end.y - 12.0)
	else:
		var rect := _unit_rect(caster)
		var base_x: float = hud.SCREEN.x * 0.72
		if rect.size.x > 0.0 and not caster.is_player:
			base_x = rect.get_center().x + 120.0
		var offset_x := float(slot_idx % 3) * -96.0 if slot_idx > 0 else 0.0
		pos = Vector2(clampf(base_x + offset_x, 88.0, hud.SCREEN.x - 88.0), hud.STAGE_RECT.end.y - 26.0)
	var branches: Array[Dictionary] = []
	var branch_angles: Array[float] = [-1.15, -0.78, -0.42, -0.1, 0.22, 0.58, 0.96, 1.25]
	for bi in branch_angles.size():
		var ang := branch_angles[bi]
		var segs := 7 + (bi % 3)
		for s in segs:
			var frac := float(s + 1) / float(segs)
			var curve := sin(frac * 2.4 + float(bi)) * 14.0
			branches.append({
				"x_off": sin(ang) * (frac * 56.0) + curve,
				"y_off": -cos(ang * 0.7) * (frac * 74.0) - 6.0,
				"glyph": _letter(),
				"px": 12 + (s % 3) * 2,
				"delay": frac * 0.55 + float(bi % 2) * 0.08,
				"phase": rng.randf_range(0.0, TAU),
			})
	var flames: Array[Dictionary] = []
	var bush_word := "הסנההבוער"
	for i in 42:
		var ch := bush_word.substr(i % bush_word.length(), 1) if i % 5 == 0 else _letter()
		flames.append({
			"x_off": rng.randf_range(-52.0, 52.0),
			"base_y": rng.randf_range(-74.0, -10.0),
			"rise": rng.randf_range(26.0, 72.0),
			"glyph": ch,
			"px": rng.randi_range(12, 20),
			"color_idx": i % 3,
			"speed": rng.randf_range(1.4, 2.8),
			"phase": rng.randf_range(0.0, TAU),
		})
	hasneh_bushes.append({
		"born": time,
		"hp": maxi(0, bush_hp),
		"unit": bush_unit,
		"pos": pos,
		"branches": branches,
		"flames": flames,
	})
	hasneh_at = time
	hasneh_pos = pos
	hasneh_branches = branches
	hasneh_flames = flames
	_sync_hasneh_hp()


func set_hasneh_hp(hp: int) -> void:
	if not hasneh_bushes.is_empty():
		hasneh_bushes[0].hp = maxi(0, hp)
	_sync_hasneh_hp()


func set_hasneh_bush_hp(index: int, hp: int) -> void:
	if index >= 0 and index < hasneh_bushes.size():
		hasneh_bushes[index].hp = maxi(0, hp)
	_sync_hasneh_hp()


func clear_hasneh_bushes() -> void:
	hasneh_bushes.clear()
	hasneh_hp = 0


func _bush_live_hp(b: Dictionary) -> int:
	var u: BattleUnit = b.get("unit", null)
	if u != null:
		return maxi(0, u.current_hp)
	return maxi(0, int(b.hp))


func _sync_hasneh_hp() -> void:
	var total := 0
	for b in hasneh_bushes:
		total += _bush_live_hp(b)
	hasneh_hp = total


func hasneh_busy() -> bool:
	return time - hasneh_at < HASNEH_INTRO_END


func _draw_hasneh_haboer() -> void:
	if hasneh_bushes.is_empty():
		return
	_sync_hasneh_hp()
	if hasneh_hp <= 0:
		return
	var flash_alpha := 0.0
	var warm_alpha := 0.0
	for bush in hasneh_bushes:
		var hp := _bush_live_hp(bush)
		if hp <= 0:
			continue
		var age := time - float(bush.born)
		if age < 0.0:
			continue
		var pos: Vector2 = bush.pos
		var u: BattleUnit = bush.get("unit", null)
		if u != null:
			var u_rect := _unit_rect(u)
			if u_rect.size.x > 0.0:
				pos = Vector2(u_rect.get_center().x, u_rect.end.y - 12.0)
		var live := age >= HASNEH_BLOOM
		var live_age := maxf(0.0, age - HASNEH_BLOOM)
		var warm := minf(0.24, age * 0.25) if age < HASNEH_INTRO_END else 0.08
		warm_alpha = maxf(warm_alpha, warm)
		# 1) Living emerald-green Hebrew-letter branches (never consumed by the fire)
		for br in bush.branches:
			var ba := age - float(br.delay)
			if ba < 0.0:
				continue
			var grow := minf(1.0, ba / 0.35)
			var sway := sin(time * 2.6 + float(br.phase)) * 2.5 if live else 0.0
			var bpos := pos + Vector2(float(br.x_off) * grow + sway, float(br.y_off) * grow)
			_glyph(String(br.glyph), bpos, int(br.px), Color(INK_BUSH, 0.35 + 0.65 * grow), Color(INK_DARK, 0.85))
		# 2) Continuous 3-color flame letters (orange, yellow, white)
		if age > 0.25:
			var fire_a := minf(1.0, (age - 0.25) / 0.5)
			for fl in bush.flames:
				var cyc := fposmod(time * float(fl.speed) + float(fl.phase), 1.0)
				var fpos := pos + Vector2(float(fl.x_off) + sin(time * 5.0 + float(fl.phase)) * 7.0,
					float(fl.base_y) - cyc * float(fl.rise))
				var a := fire_a * (1.0 - cyc) * 0.95
				_glyph(String(fl.glyph), fpos, int(fl.px), Color(FIRE_PALETTE[int(fl.color_idx)], a), Color(INK_DARK, a * 0.75))
		# 3) Tri-color Hebrew title during manifestation
		if age > 0.35 and age < 2.2:
			var ta := (age - 0.35) / 0.5 if age < 0.85 else maxf(0.0, 1.0 - (age - 1.55) / 0.65)
			_draw_tricolor_word("הסנה הבוער", pos + Vector2(0.0, -112.0), 22, ta)
		# 4) Living summon HP tag (ASCII only, separate from Hebrew glyphs)
		if live:
			var tag_a := minf(1.0, live_age * 2.5)
			_glyph("BUSH %d HP" % hp, pos + Vector2(0.0, 14.0), 11, Color(FIRE_PALETTE[1], tag_a), Color(INK_DARK, tag_a * 0.9))
		if live and live_age < 0.08:
			flash_alpha = maxf(flash_alpha, (1.0 - live_age / 0.08) * 0.45)
	if warm_alpha > 0.01:
		draw_rect(hud.STAGE_RECT, Color(1.0, 0.51, 0.14, warm_alpha * 0.35))
	if flash_alpha > 0.01:
		draw_rect(Rect2(Vector2.ZERO, hud.SCREEN), Color(1.0, 0.91, 0.63, flash_alpha))


# ------------------------------------------------------------------ D-118 Shalhevet, Nogah & Lior (100% Hebrew letters)

## Shalhevet (שלהבת): sweeping 3-color wave of Hebrew fire across all living foes + per-foe ember eruptions.
const SHALHEVET_IMPACT := 0.58
const SHALHEVET_END := 2.45
var shalhevet_at := -99.0
var shalhevet_wave: Array[Dictionary] = []
var shalhevet_pillars: Array[Dictionary] = []


func play_shalhevet(foes: Array) -> void:
	if hud == null:
		return
	shalhevet_wave.clear()
	var sh_word := "שלהבת"
	var stage_bottom: float = hud.STAGE_RECT.end.y - 12.0
	var stage_span: float = maxf(100.0, hud.STAGE_RECT.size.y - 44.0)
	for i in 110:
		var ch := sh_word.substr(i % sh_word.length(), 1) if i % 5 == 0 else _letter()
		shalhevet_wave.append({
			"frac": float(i) / 110.0,
			"y_base": stage_bottom - rng.randf() * stage_span,
			"amp": rng.randf_range(14.0, 42.0),
			"rise": rng.randf_range(35.0, 110.0),
			"glyph": ch,
			"px": rng.randi_range(13, 25),
			"color_idx": i % 3,
			"phase": rng.randf_range(0.0, TAU),
		})
	shalhevet_pillars.clear()
	var fi := 0
	for f in foes:
		var unit: BattleUnit = f
		if unit == null or not unit.is_alive():
			continue
		var e_idx: int = hud.opponents.find(unit)
		var rect := _unit_rect(unit)
		if rect.size.x <= 0.0:
			continue
		var white: Texture2D = hud.silhouettes[e_idx] if (e_idx >= 0 and e_idx < hud.silhouettes.size()) else null
		var parts: Array[Dictionary] = []
		for i in 24:
			parts.append({
				"x_off": rng.randf_range(-31.0, 31.0),
				"y_off": rng.randf_range(-45.0, 45.0),
				"vx": rng.randf_range(-27.5, 27.5),
				"vy": rng.randf_range(-165.0, -55.0),
				"glyph": _letter(),
				"px": rng.randi_range(12, 21),
				"color_idx": i % 3,
				"life": rng.randf_range(0.5, 1.05),
			})
		shalhevet_pillars.append({
			"rect": rect,
			"white": white,
			"hit_t": 0.58 + float(fi) * 0.24,
			"parts": parts,
		})
		fi += 1
	shalhevet_at = time
	await get_tree().create_timer(SHALHEVET_IMPACT).timeout


func shalhevet_busy() -> bool:
	return time - shalhevet_at < SHALHEVET_END


func _draw_shalhevet() -> void:
	var age := time - shalhevet_at
	if age < 0.0 or age > SHALHEVET_END:
		return
	var stage_w: float = hud.SCREEN.x
	var wave_start := 0.25
	var wave_dur := 1.45
	var wp := clampf((age - wave_start) / wave_dur, 0.0, 1.0)
	var head_x := -60.0 + wp * (stage_w + 180.0)
	var dark := 0.36 * minf(1.0, age / 0.3) if age < 1.9 else maxf(0.0, 0.36 * (1.0 - (age - 1.9) / 0.55))
	if dark > 0.01:
		draw_rect(hud.STAGE_RECT, Color(0.055, 0.016, 0.04, dark))
	for p in shalhevet_pillars:
		var p_age := age - float(p.hit_t)
		if p_age >= 0.0 and p_age < 0.24 and p.white != null and int(p_age * 30.0) % 2 == 0:
			draw_texture_rect(p.white, p.rect, false, Color(1.0, 0.98, 0.88, 0.9))
	if age >= wave_start and age < 2.4:
		for w in shalhevet_wave:
			var wx := float(w.frac) * (stage_w + 80.0) - 40.0
			var dist := head_x - wx
			if dist < 0.0 or dist > 250.0:
				continue
			var local := dist / 250.0
			var a := local / 0.2 if local < 0.2 else maxf(0.0, 1.0 - (local - 0.2) / 0.8)
			var wy := float(w.y_base) - local * float(w.rise) + sin(age * 9.0 + float(w.phase)) * float(w.amp) * 0.4
			_glyph(String(w.glyph), Vector2(wx, wy), int(w.px), Color(FIRE_PALETTE[int(w.color_idx)], a * 0.95), Color(INK_DARK, a * 0.8))
	for p in shalhevet_pillars:
		var p_age := age - float(p.hit_t)
		if p_age < 0.0:
			continue
		var center: Vector2 = (p.rect as Rect2).get_center()
		for pt in p.parts:
			var life := float(pt.life)
			if p_age > life:
				continue
			var a := maxf(0.0, 1.0 - p_age / life)
			var pos := center + Vector2(float(pt.x_off) + float(pt.vx) * p_age, float(pt.y_off) + float(pt.vy) * p_age)
			_glyph(String(pt.glyph), pos, int(pt.px), Color(FIRE_PALETTE[int(pt.color_idx)], a), Color(INK_DARK, a * 0.8))
	if age >= 0.25 and age < 2.0:
		var wa := (age - 0.25) / 0.3 if age < 0.55 else maxf(0.0, 1.0 - (age - 1.3) / 0.7)
		var wx := minf(stage_w * 0.5, 140.0 + wp * 340.0)
		_draw_tricolor_word("שלהבת", Vector2(wx, hud.STAGE_RECT.position.y + 92.0), 32, wa)
	if age >= 0.82 and age < 0.90:
		draw_rect(Rect2(Vector2.ZERO, hud.SCREEN), Color(1.0, 0.89, 0.67, (1.0 - (age - 0.82) / 0.08) * 0.42))


## Nogah (נוגה): 24-ray starlight burst + blinding letter rings over every living foe (mark ס).
const NOGAH_BURST := 0.72
const NOGAH_END := 1.45
var nogah_at := -99.0
var nogah_rays: Array[Dictionary] = []
var nogah_veils: Array[Dictionary] = []


func play_nogah(foes: Array) -> void:
	if hud == null:
		return
	nogah_rays.clear()
	var n_word := "נוגה"
	for r in 24:
		var ang := (float(r) / 24.0) * TAU
		var segs: Array[Dictionary] = []
		for k in 6:
			var ch := n_word.substr(k % n_word.length(), 1) if k % 3 == 0 else _letter()
			segs.append({
				"dist": 24.0 + float(k) * 42.0,
				"glyph": ch,
				"px": 16 - k,
				"color_idx": k % 3,
			})
		nogah_rays.append({"ang": ang, "segs": segs})
	nogah_veils.clear()
	for f in foes:
		var unit: BattleUnit = f
		if unit == null or not unit.is_alive():
			continue
		var e_idx: int = hud.opponents.find(unit)
		var rect := _unit_rect(unit)
		if rect.size.x <= 0.0:
			continue
		var white: Texture2D = hud.silhouettes[e_idx] if (e_idx >= 0 and e_idx < hud.silhouettes.size()) else null
		var glyphs: Array[Dictionary] = []
		for i in 16:
			glyphs.append({
				"ang": (float(i) / 16.0) * TAU,
				"glyph": _letter(),
				"px": 12 + (i % 3) * 2,
				"rad": 36.0 + float(i % 2) * 14.0,
			})
		nogah_veils.append({"rect": rect, "white": white, "glyphs": glyphs})
	nogah_at = time + NOGAH_BURST
	await get_tree().create_timer(NOGAH_BURST).timeout


func nogah_busy() -> bool:
	return time - nogah_at < NOGAH_END


func _draw_nogah() -> void:
	var age := time - nogah_at
	if age < -NOGAH_BURST or age > NOGAH_END:
		return
	var star := Vector2(hud.SCREEN.x * 0.5, hud.STAGE_RECT.position.y + 92.0)
	var dark := 0.4 * clampf((age + NOGAH_BURST) / NOGAH_BURST, 0.0, 1.0) if age < 0.0 else maxf(0.0, 0.4 * (1.0 - age / NOGAH_END))
	if dark > 0.01:
		draw_rect(hud.STAGE_RECT, Color(0.04, 0.024, 0.07, dark))
	if age < 0.0:
		var p := clampf((age + NOGAH_BURST) / NOGAH_BURST, 0.0, 1.0)
		for ray in nogah_rays:
			var ang := float(ray.ang) + p * 1.4
			for s in ray.segs:
				var dist := float(s.dist) * (1.2 - p * 0.85)
				var pos := star + Vector2(cos(ang) * dist, sin(ang) * dist * 0.42)
				_glyph(String(s.glyph), pos, int(s.px), Color(LIGHT_PALETTE[int(s.color_idx)], 0.25 + 0.75 * p), Color(INK_DARK, p * 0.8))
		_draw_palette_word("נוגה", star + Vector2(0.0, 10.0), int(20.0 + p * 14.0), p, LIGHT_PALETTE)
		return
	if age < 0.26 and int(age * 30.0) % 2 == 0:
		for v in nogah_veils:
			if v.white != null:
				draw_texture_rect(v.white, v.rect, false, Color(1.0, 0.99, 0.9, 0.9))
	if age < 1.35:
		var ra := maxf(0.0, 1.0 - age / 1.35)
		var top_y: float = hud.STAGE_RECT.position.y + 4.0
		var bot_y: float = hud.STAGE_RECT.end.y - 4.0
		for ray in nogah_rays:
			var ang := float(ray.ang)
			for s in ray.segs:
				var dist := float(s.dist) * (0.4 + age * 1.75)
				var pos := star + Vector2(cos(ang) * dist * 1.45, sin(ang) * dist * 0.65)
				if pos.y < top_y or pos.y > bot_y:
					continue
				_glyph(String(s.glyph), pos, int(s.px), Color(LIGHT_PALETTE[int(s.color_idx)], ra * 0.9), Color(INK_DARK, ra * 0.75))
		_draw_palette_word("נוגה", star + Vector2(0.0, 12.0 - age * 12.0), 34, ra, LIGHT_PALETTE)
	if age < 1.25:
		var va := maxf(0.0, 1.0 - age / 1.25)
		for v in nogah_veils:
			var center: Vector2 = (v.rect as Rect2).get_center() + Vector2(0.0, -20.0)
			for g in v.glyphs:
				var r := float(g.rad) * (1.2 - minf(0.65, age * 0.8))
				var ang := float(g.ang) + age * 2.2
				var col := LIGHT_PALETTE[0] if age < 0.35 else PrayerBook.INK
				_glyph(String(g.glyph), center + Vector2(cos(ang) * r, sin(ang) * r * 0.48), int(g.px), Color(col, va), Color(INK_DARK, va * 0.8))
	if age < 0.085:
		draw_rect(Rect2(Vector2.ZERO, hud.SCREEN), Color(1.0, 0.99, 0.91, (1.0 - age / 0.085) * 0.58))


## Lior (ליאור): healing light shroud around the caster card with 5 orbiting letters of ליאור,
## persistent mark ל + xN (BiDi-safe separate calls), and per-action heal burst.
const LIOR_CAST_END := 1.55
const LIOR_TICK_END := 1.2
var lior_active: Dictionary = {}
var lior_ticks: Array[Dictionary] = []
var lior_cast_at := -99.0


func play_lior(unit: BattleUnit, actions: int = PrayerBook.LIOR_ACTIONS) -> void:
	if hud == null or unit == null:
		return
	var shroud: Array[Dictionary] = []
	var l_word := "ליאור"
	for i in 34:
		var ch := l_word.substr(i % l_word.length(), 1) if i % 4 == 0 else _letter()
		shroud.append({
			"x_frac": rng.randf(),
			"delay": rng.randf_range(0.0, 0.45),
			"rise": rng.randf_range(52.0, 112.0),
			"sway": rng.randf_range(5.0, 14.0),
			"phase": rng.randf_range(0.0, TAU),
			"glyph": ch,
			"px": rng.randi_range(8, 11),
			"color_idx": i % 3,
		})
	var orbits: Array[Dictionary] = []
	for i in 5:
		orbits.append({
			"idx": i,
			"ang": (float(i) / 5.0) * TAU,
			"glyph": l_word.substr(i, 1),
		})
	lior_active[unit] = {
		"born": time,
		"actions": maxi(0, actions),
		"shroud": shroud,
		"orbits": orbits,
	}
	lior_cast_at = time


func set_lior_actions(unit: BattleUnit, remaining: int) -> void:
	if unit == null or not lior_active.has(unit):
		return
	if remaining <= 0:
		lior_active.erase(unit)
	else:
		lior_active[unit].actions = remaining


func play_lior_tick(unit: BattleUnit, healed: int, remaining: int) -> void:
	if hud == null or unit == null:
		return
	set_lior_actions(unit, remaining)
	var rect := _unit_rect(unit)
	if rect.size.x <= 0.0:
		return
	var parts: Array[Dictionary] = []
	var span_x := rect.size.x * 0.42
	for _i in 18:
		parts.append({
			"x_off": rng.randf_range(-span_x, span_x),
			"vy": rng.randf_range(-90.0, -40.0),
			"glyph": _letter(),
			"px": rng.randi_range(8, 11),
			"delay": rng.randf_range(0.0, 0.18),
		})
	lior_ticks.append({
		"born": time,
		"rect": rect,
		"healed": healed,
		"parts": parts,
	})


func lior_busy() -> bool:
	if time - lior_cast_at < LIOR_CAST_END:
		return true
	for tk in lior_ticks:
		if time - float(tk.born) < LIOR_TICK_END:
			return true
	return false


func _draw_lior() -> void:
	for unit in lior_active.keys():
		var u: BattleUnit = unit
		if u == null or not u.is_alive():
			continue
		var st: Dictionary = lior_active[u]
		var actions := int(st.actions)
		if actions <= 0:
			continue
		var rect := _unit_rect(u)
		if rect.size.x <= 0.0:
			continue
		var age := time - float(st.born)
		var center := rect.get_center()
		var glow := 0.06 + 0.03 * sin(time * 4.5)
		draw_rect(rect, Color(PrayerBook.INK, glow))
		for s in st.shroud:
			var sa := age - float(s.delay)
			if sa < 0.0:
				continue
			var cyc := fposmod(sa * 0.55, 1.0)
			var px := rect.position.x + 12.0 + float(s.x_frac) * maxf(10.0, rect.size.x - 24.0) + sin(time * 3.5 + float(s.phase)) * float(s.sway)
			var py := rect.end.y - 6.0 - cyc * float(s.rise)
			var a := sin(cyc * PI) * 0.40
			_glyph(String(s.glyph), Vector2(px, py), int(s.px), Color(HEAL_PALETTE[int(s.color_idx)], a), Color(INK_DARK, a * 0.55))
		var orb_rx := rect.size.x * 0.44
		for o in st.orbits:
			if int(o.idx) >= actions:
				continue
			var ang := float(o.ang) + time * 1.9
			var pos := Vector2(center.x + cos(ang) * orb_rx, center.y - 22.0 + sin(ang) * 18.0)
			_glyph(String(o.glyph), pos, 10, Color(HEAL_PALETTE[0], 0.52), Color(INK_DARK, 0.45))
		if age < LIOR_CAST_END:
			var wa := age / 0.35 if age < 0.35 else maxf(0.0, 1.0 - (age - 0.9) / 0.65)
			_draw_palette_word("ליאור", Vector2(center.x, rect.position.y - 22.0 - age * 10.0), 20, wa * 0.85, HEAL_PALETTE)
	for i in range(lior_ticks.size() - 1, -1, -1):
		var tk: Dictionary = lior_ticks[i]
		var ta := time - float(tk.born)
		if ta > LIOR_TICK_END:
			lior_ticks.remove_at(i)
			continue
		var rect: Rect2 = tk.rect
		var cx := rect.get_center().x
		for pt in tk.parts:
			var ha := ta - float(pt.delay)
			if ha < 0.0 or ha > 0.9:
				continue
			var a := maxf(0.0, 1.0 - ha / 0.9) * 0.42
			_glyph(String(pt.glyph), Vector2(cx + float(pt.x_off), rect.position.y + 10.0 + float(pt.vy) * ha),
				int(pt.px), Color(INK_HEAL, a), Color(INK_DARK, a * 0.55))
		var la := maxf(0.0, 1.0 - ta / 1.1)
		if la > 0.01 and int(tk.healed) > 0:
			var lpos := Vector2(cx, rect.position.y - 14.0 - ta * 26.0)
			draw_string_outline(font, lpos, "+%d HP" % int(tk.healed), HORIZONTAL_ALIGNMENT_CENTER, -1, 16, 4, Color(0.04, 0.03, 0.06, la))
			draw_string(font, lpos, "+%d HP" % int(tk.healed), HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(INK_HEAL, la))


# ------------------------------------------------------------------ D-118 lotes 2-4 (100% Hebrew letters)
## Esh, Meir, Ur Esh, Seraf, Nitzotz, Esh Ochelet, Gever, Angel Hug, God's Message and Adin -> Adina -> Adinut.
## Ported from prototypes/d118-prayers-vfx (round4..round7), approved by the creator in the prototype.
## Every effect is a Dictionary in `d118` with a start time (`at`), a duration (`dur`) and its own letters; the
## common layers (dark stage, screen flash, foe whiten, shake) live in the effect so one dispatcher draws all.
const MARK_MEIR := "א"
const MARK_GEVER := "ב"
const MARK_ANGEL_HUG := "ע"
const MARK_GODS_MESSAGE := "ד"
const INK_ALERT := Color("ff6464")
const GEVER_PALETTE: Array[Color] = [Color("ff5a36"), Color("ffd84a"), Color("ffffff")]
const SERAF_PALETTE: Array[Color] = [Color("ffffff"), Color("ffd84a"), Color("b8f5a2"), Color("ff7a1f")]
const ANGEL_PALETTE: Array[Color] = [Color("ffffff"), Color("fffce0"), Color("ffd84a")]
const ZAHAV_PALETTE: Array[Color] = [Color("ffd84a"), Color("ffffff"), Color("ff7a1f")]
const PARA_PALETTE: Array[Color] = [Color("9ee8ff"), Color("ffffff"), Color("ffd84a")]
const ADIN_PALETTE: Array[Color] = [Color("8ad8ff"), Color("b8f5a2"), Color("ffd84a"), Color("ffffff")]
const ESH_HIT := 0.44
const UR_ESH_BOOM := 0.85
const NITZOTZ_SNAP := 0.56
const ANGEL_HUG_OPEN := 0.32
const ANGEL_HUG_CLAP := 0.70
const GM_UNROLL := 0.45
const GM_WRITE := 1.35
const GM_SEAL := 1.65

var d118: Array[Dictionary] = []
var _ochelet_rings: Dictionary = {}


func d118_busy() -> bool:
	return not d118.is_empty()


func _add_d118(e: Dictionary, delay: float = 0.0) -> Dictionary:
	e["at"] = time + delay
	d118.append(e)
	return e


func _prune_d118() -> void:
	for i in range(d118.size() - 1, -1, -1):
		if time - float(d118[i].at) > float(d118[i].dur):
			d118.remove_at(i)


func _center_of(unit: BattleUnit) -> Vector2:
	var r := _unit_rect(unit)
	if r.size.x > 0.0:
		return r.get_center()
	return Vector2(hud.SCREEN.x * 0.5, hud.STAGE_RECT.position.y + 120.0)


## Where a cast leaves from: the top of a hero's status card, or the chest of a foe.
func _source_of(unit: BattleUnit) -> Vector2:
	var r := _unit_rect(unit)
	if r.size.x <= 0.0:
		return Vector2(hud.SCREEN.x * 0.5, hud.SCREEN.y - 60.0)
	if hud.players.has(unit):
		return Vector2(r.get_center().x, r.position.y + 6.0)
	return r.get_center()


func _bezier2(a: Vector2, c: Vector2, b: Vector2, k: float) -> Vector2:
	var u := 1.0 - k
	return a * (u * u) + c * (2.0 * u * k) + b * (k * k)


func _glyph_a(glyph: String, pos: Vector2, px: int, color: Color, alpha: float) -> void:
	if alpha <= 0.01:
		return
	_glyph(glyph, pos, px, Color(color, alpha), Color(INK_DARK, alpha * 0.8))


func _white_of(unit: BattleUnit) -> Texture2D:
	var idx: int = hud.opponents.find(unit)
	return hud.silhouettes[idx] if (idx >= 0 and idx < hud.silhouettes.size()) else null


func _burst_letters(count: int, word: String, spd_min: float, spd_max: float, vy_scale: float,
		px_min: int, px_max: int, life_min: float, life_max: float, lift: float = 0.0) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in count:
		var a := (float(i) / float(count)) * TAU + rng.randf_range(-0.12, 0.12)
		var spd := rng.randf_range(spd_min, spd_max)
		out.append({
			"vx": cos(a) * spd,
			"vy": sin(a) * spd * vy_scale - lift,
			"glyph": word.substr(i % word.length(), 1) if (i % 4 == 0 and not word.is_empty()) else _letter(),
			"px": rng.randi_range(px_min, px_max),
			"color_idx": i % 3,
			"life": rng.randf_range(life_min, life_max),
		})
	return out


func _draw_burst(items: Array, origin: Vector2, age: float, palette: Array[Color], gravity: float) -> void:
	for pt in items:
		var life := float(pt.life)
		if age > life:
			continue
		var a := maxf(0.0, 1.0 - age / life)
		var pos := origin + Vector2(float(pt.vx) * age, float(pt.vy) * age + gravity * age * age)
		_glyph_a(String(pt.glyph), pos, int(pt.px), palette[int(pt.color_idx) % palette.size()], a)


## ---------------------------------------------------------------- Esh (אש)
func play_esh(caster: BattleUnit, target: BattleUnit, burned: bool) -> void:
	if hud == null or target == null:
		return
	var src := _source_of(caster)
	var dst := _center_of(target)
	var side := -1.0 if src.x >= dst.x - 1.0 else 1.0
	var trail: Array[Dictionary] = []
	for i in 30:
		trail.append({
			"frac": float(i) / 30.0,
			"jitter": rng.randf_range(-6.0, 6.0),
			"glyph": "אש".substr(i % 2, 1) if i % 3 == 0 else _letter(),
			"px": 13 + (i % 4) * 3,
			"color_idx": i % 3,
		})
	var licks: Array[Dictionary] = []
	if burned:
		for i in 16:
			licks.append({
				"x_off": rng.randf_range(-29.0, 29.0), "y_off": rng.randf_range(-38.0, 38.0),
				"rise": rng.randf_range(24.0, 58.0), "phase": rng.randf_range(0.0, TAU),
				"glyph": _letter(), "px": rng.randi_range(11, 16), "color_idx": i % 2,
			})
	_add_d118({
		"kind": "esh", "dur": 2.75, "src": src, "dst": dst, "ctrl": (src + dst) * 0.5 + Vector2(side * 110.0, -30.0),
		"trail": trail, "burst": _burst_letters(34, "אש", 75.0, 250.0, 0.85, 12, 22, 0.42, 0.87, 25.0),
		"licks": licks, "burned": burned, "white": _white_of(target), "rect": _unit_rect(target),
		"dark": 0.3, "dark_hold": 1.4, "dark_out": 0.7,
		"shake": {"t": ESH_HIT, "dur": 0.22, "px": 6.5},
		"flash": {"t": ESH_HIT, "dur": 0.065, "a": 0.36, "col": Color(1.0, 0.96, 0.82)},
	})
	await get_tree().create_timer(ESH_HIT).timeout


func _draw_esh(e: Dictionary, age: float) -> void:
	var dst: Vector2 = e.dst
	if age < ESH_HIT + 0.22:
		var prog := minf(1.0, age / ESH_HIT)
		var fade := 1.0 if age <= ESH_HIT else maxf(0.0, 1.0 - (age - ESH_HIT) / 0.22)
		for p in e.trail:
			var frac := float(p.frac)
			if frac > prog:
				continue
			var tail := prog - frac
			if tail > 0.55:
				continue
			var pos := _bezier2(e.src, e.ctrl, dst, frac)
			pos += Vector2(float(p.jitter) * (1.0 - frac * 0.4), float(p.jitter) * 0.5)
			var col := Color.WHITE if tail < 0.12 else FIRE_PALETTE[int(p.color_idx)]
			_glyph_a(String(p.glyph), pos, int(p.px), col, fade * maxf(0.0, 1.0 - tail / 0.55))
	if age < ESH_HIT:
		return
	var h := age - ESH_HIT
	_draw_burst(e.burst, dst + Vector2(0.0, 10.0), h, FIRE_PALETTE, 90.0)
	if bool(e.burned):
		var burn_a := 0.9 if h < 1.5 else maxf(0.0, 0.9 * (1.0 - (h - 1.5) / 0.7))
		for bl in e.licks:
			var cyc := fposmod(h * 1.8 + float(bl.phase), 1.0)
			_glyph_a(String(bl.glyph), dst + Vector2(float(bl.x_off), float(bl.y_off) - cyc * float(bl.rise)),
				int(bl.px), FIRE_PALETTE[int(bl.color_idx)], burn_a * (1.0 - cyc))
	if h < 0.85:
		_draw_palette_word("אש", dst + Vector2(0.0, -14.0 - h * 24.0), 34, 1.0 - h / 0.85, FIRE_PALETTE)
	var white: Texture2D = e.white
	if white != null and h < 0.24 and int(h * 30.0) % 2 == 0:
		draw_texture_rect(white, e.rect, false, Color(1.0, 0.98, 0.88, 0.9))


## ---------------------------------------------------------------- Ur Esh (אור אש)
func play_ur_esh(_caster: BattleUnit, target: BattleUnit, was_burning: bool) -> void:
	if hud == null or target == null:
		return
	var embers: Array[Dictionary] = []
	for i in 14:
		embers.append({"x_off": rng.randf_range(-28.0, 28.0), "phase": rng.randf_range(0.0, TAU),
			"rise": rng.randf_range(28.0, 62.0), "glyph": _letter(), "px": rng.randi_range(11, 15)})
	var descent: Array[Dictionary] = []
	var ur_word := "אוראש"
	for i in 42:
		descent.append({
			"a": (float(i) / 42.0) * TAU, "rad": rng.randf_range(80.0, 125.0),
			"glyph": ur_word.substr(i % ur_word.length(), 1) if i % 5 == 0 else _letter(),
			"px": rng.randi_range(13, 21), "color_idx": i % 3,
		})
	_add_d118({
		"kind": "ur_esh", "dur": 3.1, "dst": _center_of(target), "was_burning": was_burning,
		"embers": embers, "descent": descent, "burst": _burst_letters(56, ur_word, 110.0, 340.0, 0.8, 14, 25, 0.55, 1.05),
		"white": _white_of(target), "rect": _unit_rect(target),
		"dark": 0.42, "dark_in": UR_ESH_BOOM, "dark_hold": UR_ESH_BOOM, "dark_out": 1.4,
		"shake": {"t": UR_ESH_BOOM, "dur": 0.28, "px": 9.0},
		"flash": {"t": UR_ESH_BOOM, "dur": 0.085, "a": 0.62, "col": Color(1.0, 0.93, 0.69)},
	})
	await get_tree().create_timer(UR_ESH_BOOM).timeout


func _draw_ur_esh(e: Dictionary, age: float) -> void:
	var dst: Vector2 = e.dst
	if age < UR_ESH_BOOM:
		if bool(e.was_burning):
			for eb in e.embers:
				var cyc := fposmod(age * 1.4 + float(eb.phase), 1.0)
				_glyph_a(String(eb.glyph), dst + Vector2(float(eb.x_off), 30.0 - cyc * float(eb.rise)), int(eb.px), FIRE_PALETTE[0], (1.0 - cyc) * 0.85)
		var p := age / UR_ESH_BOOM
		for d in e.descent:
			var r := float(d.rad) * pow(1.0 - p, 1.5)
			var ang := float(d.a) + p * 3.8
			_glyph_a(String(d.glyph), dst + Vector2(cos(ang) * r, sin(ang) * r * 0.68), int(d.px),
				ZAHAV_PALETTE[int(d.color_idx)], 0.25 + 0.75 * p)
		var word := "אש" if p < 0.42 else "אור אש"
		_draw_palette_word(word, dst + Vector2(0.0, -42.0), int(22.0 + p * 14.0), minf(1.0, p * 1.6), ZAHAV_PALETTE)
		return
	var b := age - UR_ESH_BOOM
	_draw_burst(e.burst, dst, b, ZAHAV_PALETTE, 70.0)
	if b < 1.0:
		_draw_palette_word("אור אש", dst + Vector2(0.0, -26.0 - b * 26.0), 38, 1.0 - b, ZAHAV_PALETTE)
	var white: Texture2D = e.white
	if white != null and b < 0.26 and int(b * 30.0) % 2 == 0:
		draw_texture_rect(white, e.rect, false, Color(1.0, 0.98, 0.88, 0.9))


## ---------------------------------------------------------------- Meir (מאיר)
func play_meir(caster: BattleUnit, foes: Array) -> void:
	if hud == null or caster == null:
		return
	var card := _unit_rect(caster)
	var pulse: Array[Dictionary] = []
	for i in 20:
		pulse.append({"a": (float(i) / 20.0) * TAU, "glyph": "מאיר".substr(i % 4, 1) if i % 4 == 0 else _letter(), "px": 13 + (i % 2) * 3})
	var frame: Array[Dictionary] = []
	for i in 16:
		frame.append({"a": (float(i) / 16.0) * TAU, "glyph": _letter()})
	var locks: Array[Dictionary] = []
	var whites: Array[Dictionary] = []
	for f in foes:
		var foe: BattleUnit = f
		if foe == null or not foe.is_alive():
			continue
		var fr := _unit_rect(foe)
		if fr.size.x <= 0.0:
			continue
		var chain: Array[Dictionary] = []
		for i in 12:
			chain.append({"frac": float(i + 1) / 13.0, "glyph": "מאיר".substr(i % 4, 1) if i % 4 == 0 else _letter(), "px": 12 + (i % 2) * 2})
		locks.append({"from": fr.get_center() + Vector2(0.0, -10.0), "top": fr.position.y, "x": fr.get_center().x, "chain": chain})
		whites.append({"white": _white_of(foe), "rect": fr})
	_add_d118({
		"kind": "meir", "dur": 3.1, "card": card, "src": _source_of(caster), "pulse": pulse, "frame": frame, "locks": locks,
		"whites": whites, "dark": 0.38, "dark_in": 0.25, "dark_hold": 2.3, "dark_out": 0.6,
	})


func _draw_meir(e: Dictionary, age: float) -> void:
	var alert_t := 0.45
	var lock_t := 0.85
	var card: Rect2 = e.card
	var src: Vector2 = e.src
	var locked := age >= lock_t
	if age < 0.75:
		var p := age / 0.75
		var r := 15.0 + p * 190.0
		for pr in e.pulse:
			_glyph_a(String(pr.glyph), src + Vector2(cos(float(pr.a)) * r, -absf(sin(float(pr.a))) * r * 0.75), int(pr.px), Color("fffce0"), 1.0 - p)
	if age >= alert_t and age < 2.65:
		var aa := 0.95 if age < 2.1 else maxf(0.0, 0.95 * (1.0 - (age - 2.1) / 0.55))
		var bounce := absf(sin(age * 7.0)) * 4.0
		for lk in e.locks:
			_glyph_a(MARK_MEIR, Vector2(float(lk.x), float(lk.top) - 30.0 - bounce), 20, INK_ALERT, aa)
		var wa := age - alert_t
		if wa < 0.18:
			for w in e.whites:
				if w.white != null and int(wa * 30.0) % 2 == 0:
					draw_texture_rect(w.white, w.rect, false, Color(1.0, 0.98, 0.88, 0.7))
	if age >= alert_t and age < 2.8:
		var prog := minf(1.0, (age - alert_t) / (lock_t - alert_t))
		var fade := 1.0 if age < 2.2 else maxf(0.0, 1.0 - (age - 2.2) / 0.6)
		for lk in e.locks:
			var from: Vector2 = lk.from
			var ci := 0
			for c in lk.chain:
				ci += 1
				var frac := float(c.frac)
				if frac > prog:
					continue
				var pf := frac + (fposmod(age * 0.45, 1.0 / 13.0) if locked else 0.0)
				var col := INK_ALERT if frac < 0.45 else (Color("ffd84a") if frac < 0.8 else Color.WHITE)
				_glyph_a(String(c.glyph), from.lerp(src, minf(1.0, pf)), int(c.px), col, fade * (0.65 + 0.35 * sin(age * 10.0 - float(ci))))
	if locked and age < 2.95:
		var fa := 0.95 if age < 2.4 else maxf(0.0, 0.95 * (1.0 - (age - 2.4) / 0.55))
		var c0 := card.get_center()
		var i := 0
		for tf in e.frame:
			var ang := float(tf.a) + age * 1.4
			_glyph_a(String(tf.glyph), c0 + Vector2(cos(ang) * card.size.x * 0.52, sin(ang) * card.size.y * 0.62), 12,
				INK_ALERT if i % 2 == 0 else Color("ffd84a"), fa)
			i += 1
	if age < 1.9:
		var wa2 := age / 0.3 if age < 0.3 else maxf(0.0, 1.0 - (age - 1.25) / 0.65)
		_draw_palette_word("מאיר", Vector2(card.get_center().x, card.position.y - 22.0), 28, wa2, LIGHT_PALETTE)


## ---------------------------------------------------------------- Seraf (שרף)
func play_seraf(unit: BattleUnit, healed: int) -> void:
	if hud == null or unit == null:
		return
	var wings: Array[Dictionary] = []
	for side in [-1, 1]:
		for row in 3:
			var count := 9 - row
			for i in count:
				var frac := float(i + 1) / float(count)
				wings.append({
					"side": float(side), "row": row, "frac": frac,
					"glyph": "שרף".substr(i % 3, 1) if i % 3 == 0 else _letter(),
					"px": 11 + (3 - row) * 2, "color_idx": 3 if frac > 0.72 else (1 if frac > 0.38 else 0),
				})
	var motes: Array[Dictionary] = []
	for i in 20:
		motes.append({"x_off": rng.randf_range(-105.0, 105.0), "vy": rng.randf_range(-90.0, -38.0),
			"delay": rng.randf_range(0.35, 0.9), "glyph": _letter(), "px": rng.randi_range(11, 16)})
	var orbs: Array[Dictionary] = []
	var card := _unit_rect(unit)
	for i in 12:
		orbs.append({"sx": card.get_center().x + rng.randf_range(-80.0, 80.0), "sy": card.position.y + rng.randf_range(0.0, 40.0),
			"delay": 0.45 + float(i) / 12.0 * 0.45, "glyph": _letter(), "px": 12 + (i % 3) * 2})
	_add_d118({"kind": "seraf", "dur": 3.1, "card": card, "wings": wings, "motes": motes, "orbs": orbs, "healed": healed})


func _draw_seraf(e: Dictionary, age: float) -> void:
	var card: Rect2 = e.card
	var cx := card.get_center().x
	var cy := card.position.y + 6.0
	var glow := sin(minf(1.0, age / 2.2) * PI) * 0.24 if age < 2.2 else 0.0
	draw_rect(card, Color(1.0, 0.88, 0.5, glow))
	var spread := minf(1.0, age / 0.65)
	var wing_fade := 1.0 if age < 1.8 else maxf(0.0, 1.0 - (age - 1.8) / 0.9)
	var flap := sin(age * 4.2) * 0.08
	for w in e.wings:
		var ang := (-0.25 - float(w.row) * 0.28 + flap) + float(w.frac) * 0.55
		var reach := (24.0 + float(w.frac) * 105.0) * spread
		var pos := Vector2(cx + float(w.side) * cos(ang) * reach, cy - 14.0 - sin(ang + 0.55) * reach * 0.72 + float(w.row) * 11.0)
		_glyph_a(String(w.glyph), pos, int(w.px), SERAF_PALETTE[int(w.color_idx)], wing_fade * (0.45 + 0.55 * spread))
	for m in e.motes:
		var ma := age - float(m.delay)
		if ma < 0.0 or ma > 1.0:
			continue
		_glyph_a(String(m.glyph), Vector2(cx + float(m.x_off), card.position.y + 14.0 + float(m.vy) * ma), int(m.px), INK_HEAL, 1.0 - ma)
	var sp_target := Vector2(card.end.x - 56.0, card.position.y + 12.0)
	for o in e.orbs:
		var oa := age - float(o.delay)
		if oa < 0.0 or oa > 0.75:
			continue
		var k := oa / 0.75
		var pos := Vector2(lerpf(float(o.sx), sp_target.x, k), lerpf(float(o.sy), sp_target.y, k) - sin(k * PI) * 30.0)
		_glyph_a(String(o.glyph), pos, int(o.px), Color("ffd84a"), sin(k * PI))
	if age > 0.2 and age < 2.2:
		var wa := (age - 0.2) / 0.4 if age < 0.6 else maxf(0.0, 1.0 - (age - 1.5) / 0.7)
		_draw_palette_word("שרף", Vector2(cx, cy - 52.0), 28, wa, FIRE_PALETTE)
	if age >= 0.9 and age < 2.2:
		var ha := maxf(0.0, 1.0 - (age - 0.9) / 1.2)
		var ly := card.position.y - 12.0 - (age - 0.9) * 22.0
		draw_string_outline(font, Vector2(cx - 40.0, ly), "+%d HP" % int(e.healed), HORIZONTAL_ALIGNMENT_CENTER, -1, 15, 4, Color(0.04, 0.03, 0.06, ha))
		draw_string(font, Vector2(cx - 40.0, ly), "+%d HP" % int(e.healed), HORIZONTAL_ALIGNMENT_CENTER, -1, 15, Color(INK_HEAL, ha))
		draw_string_outline(font, Vector2(cx + 44.0, ly), "+%d SP" % PrayerBook.SERAF_SP, HORIZONTAL_ALIGNMENT_CENTER, -1, 15, 4, Color(0.04, 0.03, 0.06, ha))
		draw_string(font, Vector2(cx + 44.0, ly), "+%d SP" % PrayerBook.SERAF_SP, HORIZONTAL_ALIGNMENT_CENTER, -1, 15, Color("ffd84a", ha))


## ---------------------------------------------------------------- Nitzotz (ניצוץ)
func play_nitzotz(caster: BattleUnit, target: BattleUnit) -> void:
	if hud == null or target == null:
		return
	var offsets := [Vector2(-147.0, -56.0), Vector2(147.0, -56.0), Vector2(-102.0, -91.0), Vector2(102.0, -91.0), Vector2(-52.0, -108.0), Vector2(52.0, -108.0)]
	var word := "ניצוץא"
	var arcs: Array[Dictionary] = []
	for idx in 6:
		arcs.append({"glyph": word.substr(idx, 1), "off": offsets[idx], "delay": float(idx) * 0.03, "color_idx": idx % 3})
	var flames: Array[Dictionary] = []
	for i in 28:
		flames.append({"x_off": rng.randf_range(-31.0, 31.0), "base_y": rng.randf_range(-32.0, 36.0), "rise": rng.randf_range(22.0, 58.0),
			"phase": rng.randf_range(0.0, TAU), "glyph": "ניצוץ".substr(i % 5, 1) if i % 5 == 0 else _letter(),
			"px": rng.randi_range(11, 17), "extra": i >= 12})
	_add_d118({
		"kind": "nitzotz", "dur": 3.1, "src": _source_of(caster), "dst": _center_of(target), "arcs": arcs, "flames": flames,
		"burst": _burst_letters(36, "ניצוץ", 105.0, 320.0, 0.72, 12, 21, 0.35, 0.7),
		"white": _white_of(target), "rect": _unit_rect(target),
		"dark": 0.16, "dark_hold": 99.0,
		"shake": {"t": NITZOTZ_SNAP, "dur": 0.22, "px": 7.0},
		"flash": {"t": NITZOTZ_SNAP, "dur": 0.07, "a": 0.45, "col": Color(1.0, 0.96, 0.82)},
	})
	await get_tree().create_timer(NITZOTZ_SNAP).timeout


func _draw_nitzotz(e: Dictionary, age: float) -> void:
	var dst: Vector2 = e.dst
	var src: Vector2 = e.src
	var snapped := age >= NITZOTZ_SNAP
	var s_age := maxf(0.0, age - NITZOTZ_SNAP)
	var idx := 0
	for fl in e.flames:
		idx += 1
		if bool(fl.extra) and not snapped:
			continue
		var spd := 2.4 if snapped else 1.1
		var rise := float(fl.rise) * (2.1 if snapped else 1.0)
		var cyc := fposmod(age * spd + float(fl.phase), 1.0)
		var col: Color = FIRE_PALETTE[idx % 3] if snapped else FIRE_PALETTE[0]
		_glyph_a(String(fl.glyph), dst + Vector2(float(fl.x_off) + sin(age * 7.0 + float(fl.phase)) * 5.0, float(fl.base_y) - cyc * rise),
			int(fl.px) + (4 if snapped else 0), col, (1.0 - cyc) * (0.98 if snapped else 0.65))
	var flight := 0.44
	for arc in e.arcs:
		var a_age := age - float(arc.delay)
		if a_age < 0.0 or a_age > flight + 0.14:
			continue
		var prog := minf(1.0, a_age / flight)
		var fade := 1.0 if a_age <= flight else maxf(0.0, 1.0 - (a_age - flight) / 0.14)
		var ctrl := (src + dst) * 0.5 + (arc.off as Vector2)
		for k in 4:
			var pf := maxf(0.0, prog - float(k) * 0.065)
			var col := Color.WHITE if k == 0 else FIRE_PALETTE[int(arc.color_idx)]
			_glyph_a(String(arc.glyph), _bezier2(src, ctrl, dst, pf), 22 - k * 3, col, fade * (1.0 - float(k) * 0.24))
	if snapped:
		_draw_burst(e.burst, dst, s_age, FIRE_PALETTE, 0.0)
		if s_age < 0.95:
			_draw_palette_word("ניצוץ", dst + Vector2(0.0, -38.0 - s_age * 20.0), 32, 1.0 - s_age / 0.95, FIRE_PALETTE)
		var white: Texture2D = e.white
		if white != null and s_age < 0.24 and int(s_age * 30.0) % 2 == 0:
			draw_texture_rect(white, e.rect, false, Color(1.0, 0.98, 0.88, 0.9))


## ---------------------------------------------------------------- Esh Ochelet (אש אוכלת)
func play_esh_ochelet(target: BattleUnit) -> void:
	if hud == null or target == null:
		return
	_add_d118({
		"kind": "ochelet_apply", "dur": 1.8, "dst": _center_of(target), "white": _white_of(target), "rect": _unit_rect(target),
		"dark": 0.36, "dark_in": 0.2, "dark_hold": 1.2, "dark_out": 0.5,
		"flash": {"t": 0.0, "dur": 0.075, "a": 0.48, "col": Color(1.0, 0.95, 0.78)},
	})


func play_ochelet_bite(target: BattleUnit) -> void:
	if hud == null or target == null:
		return
	_add_d118({
		"kind": "ochelet_bite", "dur": 1.0, "dst": _center_of(target), "unit": target, "white": _white_of(target), "rect": _unit_rect(target),
		"burst": _burst_letters(24, "אשאוכלת", 70.0, 210.0, 0.75, 11, 19, 0.4, 0.75),
		"shake": {"t": 0.0, "dur": 0.22, "px": 6.0},
	})


func _draw_ochelet_apply(e: Dictionary, age: float) -> void:
	if age < 1.1:
		_draw_palette_word("אש אוכלת", Vector2((e.dst as Vector2).x, (e.rect as Rect2).position.y - 30.0), 26, maxf(0.0, 1.0 - maxf(0.0, age - 0.5) / 0.6), FIRE_PALETTE)
	var white: Texture2D = e.white
	if white != null and age < 0.18 and int(age * 30.0) % 2 == 0:
		draw_texture_rect(white, e.rect, false, Color(1.0, 0.98, 0.88, 0.8))


func _draw_ochelet_bite(e: Dictionary, age: float) -> void:
	_draw_burst(e.burst, e.dst, age, FIRE_PALETTE, 0.0)
	var white: Texture2D = e.white
	if white != null and age < 0.22 and int(age * 30.0) % 2 == 0:
		draw_texture_rect(white, e.rect, false, Color(1.0, 0.98, 0.88, 0.9))


## Persistent crown / jaw of tricolor fire letters around every unit carrying Esh Ochelet; it closes at each bite.
func _draw_ochelet_rings() -> void:
	var marked: Array[BattleUnit] = []
	for foe in hud.opponents:
		if (foe as BattleUnit).is_alive() and (foe as BattleUnit).has_status(&"ochelet"):
			marked.append(foe)
	for hero in hud.players:
		if (hero as BattleUnit).is_alive() and (hero as BattleUnit).has_status(&"ochelet"):
			marked.append(hero)
	for u in marked:
		if not _ochelet_rings.has(u):
			var glyphs: Array[Dictionary] = []
			for i in 26:
				glyphs.append({"a": (float(i) / 26.0) * TAU, "glyph": "אשאוכלת".substr(i % 7, 1) if i % 4 == 0 else _letter(),
					"px": 13 + (i % 3) * 2, "color_idx": i % 3})
			_ochelet_rings[u] = glyphs
		var squeeze := 1.0
		for e in d118:
			if String(e.kind) == "ochelet_bite" and e.unit == u:
				var b_age := time - float(e.at)
				if b_age >= 0.0 and b_age < 0.35:
					squeeze = minf(squeeze, 1.0 - 0.55 * sin(b_age / 0.35 * PI))
		var rect := _unit_rect(u)
		if rect.size.x <= 0.0:
			continue
		var c := rect.get_center()
		var rx := maxf(34.0, rect.size.x * 0.6) * squeeze
		var ry := maxf(44.0, rect.size.y * 0.58) * squeeze
		for g in _ochelet_rings[u]:
			var ang := float(g.a) + time * 2.2
			_glyph_a(String(g.glyph), c + Vector2(cos(ang) * rx, sin(ang) * ry), int(g.px), FIRE_PALETTE[int(g.color_idx)], 0.92)


## ---------------------------------------------------------------- Gever (גבר)
func play_gever(unit: BattleUnit) -> void:
	if hud == null or unit == null:
		return
	var card := _unit_rect(unit)
	var surges: Array[Dictionary] = []
	var starts := [0.15, 0.45, 0.75, 1.05]
	for si in 4:
		var cols: Array[Dictionary] = []
		for i in 14:
			cols.append({"x": (float(i) / 13.0 - 0.5) * card.size.x * 0.92, "rise": (62.0 + float(si) * 26.0 + rng.randf_range(0.0, 22.0)) * 0.8,
				"glyph": "גבר".substr(i % 3, 1) if i % 3 == 0 else _letter(), "px": 12 + si * 2, "color_idx": (i + si) % 3})
		surges.append({"st": starts[si], "si": si, "cols": cols})
	var ring: Array[Dictionary] = []
	for i in 20:
		ring.append({"a": (float(i) / 20.0) * TAU, "glyph": _letter(), "px": 13 + (i % 2) * 3, "color_idx": i % 3})
	_add_d118({"kind": "gever", "dur": 3.0, "card": card, "surges": surges, "ring": ring})


func _draw_gever(e: Dictionary, age: float) -> void:
	var card: Rect2 = e.card
	var cx := card.get_center().x
	var stages := 0
	for s in e.surges:
		if age >= float(s.st):
			stages = int(s.si) + 1
	if stages > 0:
		var g := 0.07 * float(stages) * (1.0 if age < 2.2 else maxf(0.0, 1.0 - (age - 2.2) / 0.7))
		draw_rect(card, Color(1.0, 0.47, 0.19, g))
	for s in e.surges:
		var s_age := age - float(s.st)
		if s_age < 0.0 or s_age > 0.95:
			continue
		var k := s_age / 0.95
		var a := k / 0.2 if k < 0.2 else maxf(0.0, 1.0 - (k - 0.2) / 0.8)
		for c in s.cols:
			_glyph_a(String(c.glyph), Vector2(cx + float(c.x), card.position.y + 12.0 - k * float(c.rise)), int(c.px), GEVER_PALETTE[int(c.color_idx)], a * 0.95)
	if stages >= 4 and age < 2.8:
		var ra := 0.95 if age < 2.1 else maxf(0.0, 0.95 * (1.0 - (age - 2.1) / 0.7))
		for r in e.ring:
			var ang := float(r.a) + age * 2.8
			_glyph_a(String(r.glyph), Vector2(cx + cos(ang) * card.size.x * 0.52, card.get_center().y - 8.0 + sin(ang) * 24.0), int(r.px), GEVER_PALETTE[int(r.color_idx)], ra)
	if age > 0.15 and age < 2.4:
		var wa := (age - 0.15) / 0.3 if age < 0.45 else maxf(0.0, 1.0 - (age - 1.7) / 0.7)
		_draw_palette_word("גבר", Vector2(cx, card.position.y - 44.0 - float(stages) * 5.0), 24 + stages * 3, wa, GEVER_PALETTE)
	if stages > 0 and age < 2.5:
		var txt := "+%d ATK" % stages
		var col := Color("ffd84a") if stages >= 4 else Color("ff8a5c")
		draw_string_outline(font, Vector2(cx, card.position.y - 14.0), txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, 4, Color(0.04, 0.03, 0.06, 0.9))
		draw_string(font, Vector2(cx, card.position.y - 14.0), txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, col)


## ---------------------------------------------------------------- Angel Hug (מלאך)
func play_angel_hug(caster: BattleUnit, target: BattleUnit, landed: bool) -> void:
	if hud == null or target == null:
		return
	var wings: Array[Dictionary] = []
	var word := "מלאך"
	for side in [-1, 1]:
		for row in 5:
			var count := 10 - row
			for i in count:
				wings.append({"side": float(side), "row": row, "frac": float(i + 1) / float(count),
					"glyph": word.substr(i % 4, 1) if i % 3 == 0 else _letter(), "px": 12 + (4 - row) * 2, "color_idx": (i + row) % 3})
	var rect := _unit_rect(target)
	var statics: Array[Dictionary] = []
	for i in 14:
		statics.append({"x": rng.randf_range(-0.5, 0.5) * maxf(60.0, rect.size.x * 0.9), "y": rng.randf_range(-19.0, 19.0),
			"glyph": _letter(), "phase": rng.randf_range(0.0, TAU)})
	_add_d118({
		"kind": "angel_hug", "dur": 3.1, "pivot": _source_of(caster) + Vector2(0.0, -8.0), "dst": rect.get_center(), "rect": rect,
		"wings": wings, "burst": _burst_letters(34, "", 85.0, 280.0, 0.45, 11, 19, 0.42, 0.77), "statics": statics, "landed": landed,
		"dark": 0.32, "dark_in": 0.25, "dark_hold": 1.9, "dark_out": 0.7,
		"shake": {"t": ANGEL_HUG_CLAP, "dur": 0.28, "px": 9.5},
		"flash": {"t": ANGEL_HUG_CLAP, "dur": 0.085, "a": 0.62, "col": Color(1.0, 0.99, 0.91)},
	})
	await get_tree().create_timer(ANGEL_HUG_CLAP).timeout


func _draw_angel_hug(e: Dictionary, age: float) -> void:
	var pivot: Vector2 = e.pivot
	var dst: Vector2 = e.dst
	var clapped := age >= ANGEL_HUG_CLAP
	var c_age := maxf(0.0, age - ANGEL_HUG_CLAP)
	if age < ANGEL_HUG_CLAP + 0.55:
		var open_k := minf(1.0, age / ANGEL_HUG_OPEN)
		var sweep_k := 0.0 if age <= ANGEL_HUG_OPEN else minf(1.0, (age - ANGEL_HUG_OPEN) / (ANGEL_HUG_CLAP - ANGEL_HUG_OPEN))
		var ease_k := pow(sweep_k, 2.2)
		var wing_a := maxf(0.0, 1.0 - c_age / 0.55) if clapped else (0.35 + 0.65 * open_k)
		for w in e.wings:
			var side := float(w.side)
			var row := int(w.row)
			var frac := float(w.frac)
			var open_ang := -0.28 + float(row) * 0.16
			var length := (36.0 + frac * (130.0 - float(row) * 11.0)) * open_k
			var open_pos := pivot + Vector2(side * cos(open_ang) * length, sin(open_ang) * length)
			var close_pos := pivot.lerp(dst, 0.25 + 0.75 * frac) + Vector2(side * (10.0 + float(row) * 5.0) * (1.0 - frac * 0.6), 0.0)
			var col := Color.WHITE if (clapped and c_age < 0.14) else ANGEL_PALETTE[int(w.color_idx)]
			_glyph_a(String(w.glyph), open_pos.lerp(close_pos, ease_k), int(w.px), col, wing_a)
	if not clapped:
		return
	_draw_burst(e.burst, dst + Vector2(0.0, -14.0), c_age, PARA_PALETTE, 0.0)
	if bool(e.landed):
		var static_a := 0.9 if c_age < 1.9 else maxf(0.0, 0.9 * (1.0 - (c_age - 1.9) / 0.5))
		var i := 0
		for ps in e.statics:
			if sin(age * 24.0 + float(ps.phase)) >= 0.15:
				_glyph_a(String(ps.glyph), dst + Vector2(float(ps.x), float(ps.y)), 13, PARA_PALETTE[0] if i % 2 == 0 else PARA_PALETTE[2], static_a)
			i += 1


## ---------------------------------------------------------------- God's Message (דבר אל)
func play_gods_message(caster: BattleUnit, target: BattleUnit, landed: bool) -> void:
	if hud == null or target == null:
		return
	var border: Array[Dictionary] = []
	for i in 14:
		border.append({"frac": float(i) / 13.0, "top": _letter(), "bot": _letter(), "l": _letter(), "r": _letter()})
	_add_d118({
		"kind": "gods_message", "dur": 2.4, "caster": _source_of(caster), "dst": _center_of(target), "card": _unit_rect(target),
		"scroll": Vector2(hud.SCREEN.x * 0.5, hud.STAGE_RECT.position.y + hud.STAGE_RECT.size.y * 0.42),
		"border": border, "decree": "דבר אל", "landed": landed,
		"dark": 0.44, "dark_in": 0.3, "dark_hold": 1.9, "dark_out": 0.5,
	})
	await get_tree().create_timer(GM_SEAL).timeout


func _draw_gods_message(e: Dictionary, age: float) -> void:
	var scroll: Vector2 = e.scroll
	if age < 1.95:
		var open_k := minf(1.0, age / GM_UNROLL)
		var fade := 1.0 if age < 1.5 else maxf(0.0, 1.0 - (age - 1.5) / 0.45)
		var half_w := 14.0 + open_k * 105.0
		var half_h := 30.0
		draw_rect(Rect2(scroll - Vector2(half_w, half_h), Vector2(half_w * 2.0, half_h * 2.0)), Color(1.0, 0.86, 0.47, 0.09 * open_k * fade))
		for b in e.border:
			var bx := scroll.x - half_w + float(b.frac) * half_w * 2.0
			_glyph_a(String(b.top), Vector2(bx, scroll.y - half_h + 4.0), 11, Color("ffd84a"), 0.72 * fade)
			_glyph_a(String(b.bot), Vector2(bx, scroll.y + half_h + 4.0), 11, Color("ffd84a"), 0.72 * fade)
		for r in 5:
			var ry := scroll.y - half_h + (float(r) / 4.0) * half_h * 2.0 + 4.0
			_glyph_a(String(e.border[r].l), Vector2(scroll.x - half_w, ry), 15, Color.WHITE, 0.95 * fade)
			_glyph_a(String(e.border[r].r), Vector2(scroll.x + half_w, ry), 15, Color.WHITE, 0.95 * fade)
	if age < GM_UNROLL * 0.7:
		return
	var write_p := clampf((age - GM_UNROLL * 0.7) / (GM_WRITE - GM_UNROLL * 0.7), 0.0, 1.0)
	var desc_p := 0.0
	if bool(e.landed) and age > GM_WRITE:
		desc_p = minf(1.0, (age - GM_WRITE) / (GM_SEAL - GM_WRITE))
	var ease_k := desc_p * desc_p
	var card: Rect2 = e.card
	var seal_at := Vector2(card.get_center().x, card.position.y - 14.0)
	var word_pos := (scroll + Vector2(0.0, 8.0)).lerp(seal_at, ease_k)
	var out_a := 1.0
	if not bool(e.landed) and age > GM_WRITE:
		out_a = maxf(0.0, 1.0 - (age - GM_WRITE) / 0.4)
	var px := int(round(28.0 - ease_k * 8.0))
	var decree: String = e.decree
	var n := decree.length()
	var step := float(px) * 0.68
	var start_x := word_pos.x + float(n - 1) * step * 0.5
	for i in n:
		var ch := decree.substr(i, 1)
		if ch == " ":
			continue
		var threshold := float(i) / float(n)
		if write_p < threshold:
			continue
		var char_age := (write_p - threshold) * float(n)
		var pop := minf(1.0, char_age * 2.5)
		var col := Color.WHITE if char_age < 0.35 else Color("ffd84a")
		_glyph_a(ch, Vector2(start_x - float(i) * step, word_pos.y), int(round(float(px) * (1.28 - 0.28 * pop))), col, pop * out_a)


func play_gods_message_fulfilled(unit: BattleUnit, stat_name: String) -> void:
	if hud == null or unit == null:
		return
	var rect := _unit_rect(unit)
	var sparks: Array[Dictionary] = []
	for i in 28:
		sparks.append({"x_off": rng.randf_range(-0.5, 0.5) * maxf(60.0, rect.size.x), "vy": rng.randf_range(35.0, 110.0),
			"vx": rng.randf_range(-27.0, 27.0), "glyph": _letter(), "px": rng.randi_range(11, 17), "life": rng.randf_range(0.5, 0.95)})
	_add_d118({
		"kind": "gm_fulfil", "dur": 1.4, "rect": rect, "stat": stat_name, "sparks": sparks,
		"shake": {"t": 0.0, "dur": 0.22, "px": 6.5},
		"flash": {"t": 0.0, "dur": 0.07, "a": 0.38, "col": Color(1.0, 0.82, 0.7)},
	})


func _draw_gm_fulfil(e: Dictionary, age: float) -> void:
	var rect: Rect2 = e.rect
	for s in e.sparks:
		if age > float(s.life):
			continue
		_glyph_a(String(s.glyph), Vector2(rect.get_center().x + float(s.x_off) + float(s.vx) * age, rect.position.y + float(s.vy) * age),
			int(s.px), INK_ALERT, maxf(0.0, 1.0 - age / float(s.life)))
	if age < 1.2:
		var da := maxf(0.0, 1.0 - age / 1.2)
		var txt := "-3 %s" % String(e.stat)
		var pos := Vector2(rect.get_center().x, rect.position.y - 8.0 + age * 18.0)
		draw_string_outline(font, pos, txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, 4, Color(0.04, 0.03, 0.06, da))
		draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(INK_ALERT, da))


## ---------------------------------------------------------------- Adin -> Adina -> Adinut (עדין / עדינה / עדינות)
func play_adin(unit: BattleUnit, stage: int) -> void:
	if hud == null or unit == null:
		return
	var st := clampi(stage, 0, 2)
	var counts := [16, 28, 40]
	var motes: Array[Dictionary] = []
	for i in int(counts[st]):
		motes.append({"phase": rng.randf(), "a": (float(i) / float(counts[st])) * TAU, "rad": rng.randf_range(26.0, 66.0),
			"rise": rng.randf_range(48.0, 92.0), "glyph": _letter(), "px": rng.randi_range(10, 14), "color_idx": i % 4})
	var e := {"kind": "adin", "dur": 1.6, "stage": st, "rect": _unit_rect(unit), "motes": motes,
		"burst": _burst_letters(40, "", 70.0, 230.0, 0.7, 12, 20, 0.5, 0.95)}
	if st == 2:
		e["flash"] = {"t": 0.0, "dur": 0.08, "a": 0.45, "col": Color(0.94, 1.0, 0.88)}
	_add_d118(e)


func _draw_adin(e: Dictionary, age: float) -> void:
	var st := int(e.stage)
	var rect: Rect2 = e.rect
	var c := rect.get_center()
	var fade := 1.0 if age < 1.2 else maxf(0.0, 1.0 - (age - 1.2) / 0.4)
	var glow := (maxf(0.0, 1.0 - age / 0.5) if st == 2 else 0.25 * sin(minf(1.0, age / 1.2) * PI)) * 0.5
	draw_rect(rect, Color(0.8, 1.0, 0.9, glow))
	var pal: Array[Color] = ADIN_PALETTE
	for m in e.motes:
		var cyc := fposmod(age * (0.7 + float(st) * 0.25) + float(m.phase), 1.0)
		var ang := float(m.a) + age * (1.2 + float(st) * 0.8)
		var rad := float(m.rad) * (0.85 + float(st) * 0.25) * (1.0 - cyc * 0.3)
		var pos := c + Vector2(cos(ang) * rad, rect.size.y * 0.35 - cyc * (float(m.rise) + float(st) * 20.0))
		var col: Color = pal[int(m.color_idx)]
		if st == 0:
			col = pal[0]
		elif st == 1:
			col = pal[0] if int(m.color_idx) % 2 == 0 else pal[1]
		_glyph_a(String(m.glyph), pos, int(m.px) + st * 2, col, sin(cyc * PI) * 0.95 * fade)
	if st == 2:
		_draw_burst(e.burst, c, age, ADIN_PALETTE, 0.0)
	var words := ["עדין", "עדינה", "עדינות"]
	var pals: Array = [[pal[0], pal[3]], [pal[0], pal[1], pal[3]], [pal[0], pal[1], pal[2], pal[3]]]
	var word_pal: Array[Color] = []
	for col2 in pals[st]:
		word_pal.append(col2)
	_draw_palette_word(String(words[st]), Vector2(c.x, rect.position.y - 20.0 - age * 8.0), 22 + st * 4, 0.95 * fade, word_pal)


## ---------------------------------------------------------------- dispatcher / layers
func _d118_shake() -> float:
	var amp := 0.0
	for e in d118:
		if not e.has("shake"):
			continue
		var s: Dictionary = e.shake
		var s_age := time - float(e.at) - float(s.t)
		if s_age >= 0.0 and s_age < float(s.dur):
			amp = maxf(amp, float(s.px) * pow(1.0 - s_age / float(s.dur), 2))
	return amp


func _draw_d118() -> void:
	_draw_ochelet_rings()
	for e in d118:
		var age := time - float(e.at)
		if age < 0.0 or age > float(e.dur):
			continue
		if e.has("dark"):
			var peak := float(e.dark)
			var d_in := float(e.get("dark_in", 0.2))
			var d_hold := float(e.get("dark_hold", 1.0))
			var d_out := float(e.get("dark_out", 0.5))
			var dark := peak * minf(1.0, age / d_in) if age < d_hold else maxf(0.0, peak * (1.0 - (age - d_hold) / d_out))
			if dark > 0.01:
				draw_rect(hud.STAGE_RECT, Color(0.05, 0.016, 0.04, dark))
		match String(e.kind):
			"esh": _draw_esh(e, age)
			"ur_esh": _draw_ur_esh(e, age)
			"meir": _draw_meir(e, age)
			"seraf": _draw_seraf(e, age)
			"nitzotz": _draw_nitzotz(e, age)
			"ochelet_apply": _draw_ochelet_apply(e, age)
			"ochelet_bite": _draw_ochelet_bite(e, age)
			"gever": _draw_gever(e, age)
			"angel_hug": _draw_angel_hug(e, age)
			"gods_message": _draw_gods_message(e, age)
			"gm_fulfil": _draw_gm_fulfil(e, age)
			"adin": _draw_adin(e, age)
		if e.has("flash"):
			var f: Dictionary = e.flash
			var f_age := age - float(f.t)
			if f_age >= 0.0 and f_age < float(f.dur):
				draw_rect(Rect2(Vector2.ZERO, hud.SCREEN), Color(f.col, (1.0 - f_age / float(f.dur)) * float(f.a)))
