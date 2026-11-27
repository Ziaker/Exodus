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
const MARK_PX := 13
const PULSE_HZ := 2.6
const INK_HOT := Color(1.0, 1.0, 0.88)
const INK_DEBUFF := Color(0.88, 0.32, 0.32)
const INK_HEAL := Color("b8f5a2")

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
	return not letters.is_empty() or not card_fx.is_empty() or raam_busy() or mishpat_busy() or cherev_busy() or sanverim_busy() or chaki_busy() or shachar_busy()


func _draw() -> void:
	if hud == null:
		return
	_draw_raam()
	_draw_mishpat()
	_draw_cherev()
	_draw_sanverim()
	_draw_chaki()
	_draw_shachar()
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
	for i in hud.players.size():
		var unit: BattleUnit = hud.players[i]
		if not unit.is_alive():
			continue
		var card: Rect2 = hud.status_rect(i)
		var marks: Array[Dictionary] = []
		if not unit.haganah.is_empty():
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
		var x: float = card.position.x + 7 + hud._width(unit.display_name, 13, true) + 8
		for m_idx in marks.size():
			var mk: Dictionary = marks[m_idx]
			var mx := x + float(m_idx) * 16.0 + float(mk.jitter)
			draw_string(font, Vector2(mx, card.position.y + 18),
				String(mk.glyph), HORIZONTAL_ALIGNMENT_LEFT, -1, MARK_PX, Color(mk.color))
			var suf := String(mk.get("suffix", ""))
			if not suf.is_empty():
				draw_string(font, Vector2(mx + 9.0, card.position.y + 18),
					suf, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(mk.color))
	for letter in letters:
		var k := (time - float(letter.born)) / RISE_TIME
		if k < 0.0 or k > 1.0:
			continue
		var pos := Vector2(float(letter.x), float(letter.bottom) - RISE_HEIGHT * k)
		draw_string_outline(font, pos, letter.glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, LETTER_PX, 3, Color(0.15, 0.12, 0.0, 1.0 - k))
		draw_string(font, pos, letter.glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, LETTER_PX, Color(PrayerBook.INK, 1.0 - k))
	_draw_card_fx()


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
