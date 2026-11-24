extends Node2D
## D-048 prayer visuals chosen by the creator (2026-11-23), drawn over the HUD:
## - cast (PRAY, Refuah, Haganah): option A of prototypes/pray-vfx, Hebrew letters in
##   #f5f58c rising from the bottom of the card of the one who receives the prayer;
## - Haganah mark: the mix of idea C (the letter he, ה, next to the name) and idea B (the
##   card border lit and pulsing in #f5f58c) while the shield is up.
## Sizes and timings are the prototype's.

const ALPHABET := "אבגדהוזחטיכלמנסעפצקרשת"
const RISE_LETTERS := 14
const RISE_TIME := 0.8
const RISE_STAGGER := 0.5
const RISE_HEIGHT := 70.0
const LETTER_PX := 12
const MARK_GLYPH := "ה"
const MARK_PX := 13
const PULSE_HZ := 2.6

var hud: Control
var font: SystemFont
var rng := RandomNumberGenerator.new()
var time := 0.0
## {"glyph", "x", "bottom", "born"} per rising letter.
var letters: Array[Dictionary] = []


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
	queue_redraw()


## Letters rise from the bottom of `unit`'s status card.
func cast(unit: BattleUnit) -> void:
	var index: int = hud.players.find(unit)
	if index < 0:
		return
	var card: Rect2 = hud.STATUS_RECTS[index]
	for i in RISE_LETTERS:
		letters.append({"glyph": ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)],
			"x": rng.randf_range(card.position.x + 10, card.end.x - 10),
			"bottom": card.end.y - 6, "born": time + rng.randf_range(0.0, RISE_STAGGER)})


func is_busy() -> bool:
	return not letters.is_empty() or raam_busy()


func _draw() -> void:
	if hud == null:
		return
	_draw_raam()
	for i in hud.players.size():
		var unit: BattleUnit = hud.players[i]
		if unit.haganah.is_empty() or not unit.is_alive():
			continue
		var card: Rect2 = hud.STATUS_RECTS[i]
		var pulse := 0.55 + 0.45 * absf(sin(time * PULSE_HZ))
		draw_rect(Rect2(card.position + Vector2(0.5, 0.5), card.size - Vector2.ONE), Color(PrayerBook.INK, pulse), false, 1.5)
		var x: float = card.position.x + 7 + hud._width(unit.display_name, 13, true) + 8
		draw_string(font, Vector2(x, card.position.y + 18), MARK_GLYPH, HORIZONTAL_ALIGNMENT_LEFT, -1, MARK_PX, PrayerBook.INK)
	for letter in letters:
		var k := (time - float(letter.born)) / RISE_TIME
		if k < 0.0 or k > 1.0:
			continue
		var pos := Vector2(float(letter.x), float(letter.bottom) - RISE_HEIGHT * k)
		draw_string_outline(font, pos, letter.glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, LETTER_PX, 3, Color(0.15, 0.12, 0.0, 1.0 - k))
		draw_string(font, pos, letter.glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, LETTER_PX, Color(PrayerBook.INK, 1.0 - k))


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


func _glow(points: PackedVector2Array, radius: float, color: Color) -> void:
	var steps := int(_length(points) / 5.0)
	for i in steps + 1:
		draw_circle(_point_along(points, float(i) / maxf(1.0, steps)), radius, color)


func _glyph(glyph: String, pos: Vector2, px: int, color: Color, outline: Color) -> void:
	draw_string_outline(font, pos, glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, px, 3, outline)
	draw_string(font, pos, glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, px, color)


func _shake_step() -> void:
	var age := time - raam_at
	if age >= 0.0 and age < L_SHAKE_TIME:
		if not _shaking:
			_shaking = true
			_canvas = get_viewport().canvas_transform
			_clear = RenderingServer.get_default_clear_color()
			RenderingServer.set_default_clear_color(Color.BLACK)
		var amp := L_SHAKE_PX * pow(1.0 - age / L_SHAKE_TIME, 2)
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
			draw_arc(r_sky, 14.0 + 16.0 * word_k + 3.0 * sin(time * 30.0), 0, TAU, 40, Color(PrayerBook.INK, 0.7 * word_k), 1.5)
			_glyph("רעם", r_sky + Vector2(0, 9), int(14 + 12 * word_k), Color(1, 1, 0.85, word_k), Color(INK_DARK, word_k))
		return
	if age < L_FLASH:
		draw_rect(Rect2(Vector2.ZERO, hud.SCREEN), Color(1, 1, 1, 0.92))
	var gap: bool = age >= L_REFLASH[0] and age < L_REFLASH[1]
	if age < L_BOLT_HOLD and not gap:
		_glow(r_bolt, 11.0, Color(PrayerBook.INK, 0.07 * flick))
		_glow(r_bolt, 5.0, Color(1, 1, 0.9, 0.35))
		draw_polyline(r_bolt, Color(1, 1, 0.95, 0.9), 2.0)
		for b in r_branches:
			_glow(b, 5.0, Color(PrayerBook.INK, 0.06 * flick))
		for g in r_branch_glyphs:
			_glyph(g.glyph, _point_along(r_branches[int(g.branch)], float(g.at)) + Vector2(0, 5), 13, Color(1, 1, 0.9, flick), INK_DARK)
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
