extends Node2D
## D-052 absorption VFX, approved by the creator (2026-11-22/23) in the prototype
## prototypes/absorb-fragments (--opt=letters --hit=ringburst --mash). Values match the
## approved captures:
## - mash: every press sends MASH_LETTERS green Hebrew letters (the HUD's SP green) from
##   the intact opponent to the SP bar, landing on its green/red boundary;
## - success: after MASH_SETTLE a flat white ring of 12 rays strikes the opponent, which
##   breaks into loose Hebrew letters AT the impact, with a decaying random screen shake
##   (the uncovered edge is black); the letters burst out and fly to Fallen's card.
## Still PENDING with the creator: colour, timing, path and destination of the break
## letters, and the failure visual (a failed mash shows no extra effect).

const ALPHABET := "אבגדהוזחטיכלמנסעפצקרשת"
const LETTER_CELL := 8.0
const LETTER_PX := 12
const LETTER_SCALE := 1.2
const LETTER_INK := Color.BLACK
const MASH_LETTERS := 3
const MASH_STAGGER := 0.05
const MASH_FLY := 0.6
const MASH_INK := Color("81e6a8")
const MASH_SETTLE := 0.4
const HIT_TIME := 0.35
const HIT_INK := Color.WHITE
const HIT_RAYS := 12
const SHAKE_PX := 6.0
const SHAKE_TIME := 0.35
const BURST_TIME := 0.5
const FLY_TIME := 0.9
const FLY_STAGGER := 0.5
## Track of the HUD SP bar: playable_hud.SP_TRACK (D-055: 800 px wide).
## Time from the impact until the last break letter has reached Fallen's card.
const BREAK_SECONDS := BURST_TIME + FLY_STAGGER + FLY_TIME

var battle: Control
var hud: Control
var time := 0.0
var font: SystemFont
var rng := RandomNumberGenerator.new()
var mash_letters: Array[Dictionary] = []
var pieces: Array[Dictionary] = []
var impact_at := -99.0
var impact_center := Vector2.ZERO
var card_center := Vector2.ZERO
var mash_target: BattleUnit
## Total mash letters sent in this battle (diagnostics/tests; on-screen ones expire).
var letters_sent := 0
var _points: Dictionary = {}
var _clear_color := Color.BLACK
var _shaking := false
var _canvas := Transform2D.IDENTITY
var shake_offset := Vector2.ZERO


func _init() -> void:
	z_index = 100
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Tahoma", "Arial", "David Libre"])
	font.font_weight = 800
	rng.seed = 52


func _process(delta: float) -> void:
	time += delta
	var age := time - impact_at
	if age >= 0.0 and age < SHAKE_TIME:
		if not _shaking:
			_shaking = true
			_clear_color = RenderingServer.get_default_clear_color()
			_canvas = get_viewport().canvas_transform
			RenderingServer.set_default_clear_color(Color.BLACK)
		var amp := SHAKE_PX * pow(1.0 - age / SHAKE_TIME, 2)
		# The whole screen moves through the viewport's canvas transform; moving the battle
		# Control instead let Godot cull a zero-size HUD at negative offsets (black frames).
		shake_offset = (Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * amp).round()
		get_viewport().canvas_transform = _canvas.translated(shake_offset)
	elif _shaking:
		_end_shake()
	mash_letters = mash_letters.filter(func(l: Dictionary) -> bool: return time - float(l.born) < MASH_FLY)
	if not pieces.is_empty() and age >= BREAK_SECONDS:
		pieces.clear()
	queue_redraw()


func _exit_tree() -> void:
	if _shaking: _end_shake()


func _end_shake() -> void:
	_shaking = false
	shake_offset = Vector2.ZERO
	get_viewport().canvas_transform = _canvas
	RenderingServer.set_default_clear_color(_clear_color)


func is_busy() -> bool:
	return not mash_letters.is_empty() or not pieces.is_empty() or time - impact_at < BREAK_SECONDS


## One counted mash press against target: green letters leave the intact opponent.
func mash_press(target: BattleUnit) -> void:
	var index: int = hud.opponents.find(target)
	if index < 0: return
	mash_target = target
	var points := _opaque_points(index)
	if points.is_empty(): return
	letters_sent += MASH_LETTERS
	for i in MASH_LETTERS:
		mash_letters.append({
			"glyph": ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)],
			"from": points[rng.randi_range(0, points.size() - 1)],
			"born": time + i * MASH_STAGGER,
			"spin": rng.randf_range(-2.0, 2.0),
		})


## Successful absorption: settle, hit, break into letters at the impact, letters fly to
## Fallen's card. Hides the target in the HUD from the impact on. Returns when done.
func play_break(target: BattleUnit) -> void:
	var index: int = hud.opponents.find(target)
	if index < 0: return
	await get_tree().create_timer(MASH_SETTLE).timeout
	if not is_inside_tree(): return
	var art: Rect2 = hud.enemy_sprite_rect(index)
	var image: Image = hud.silhouettes[index % hud.silhouettes.size()].get_image()
	var size := image.get_size()
	pieces.clear()
	for y in range(0.0, art.size.y, LETTER_CELL):
		for x in range(0.0, art.size.x, LETTER_CELL):
			var c := Vector2(x, y) + Vector2.ONE * LETTER_CELL * 0.5
			var px := Vector2i(int(c.x / art.size.x * size.x), int(c.y / art.size.y * size.y))
			if image.get_pixelv(px.clamp(Vector2i.ZERO, size - Vector2i.ONE)).a < 0.5: continue
			var center := art.position + c
			var away := center - art.get_center()
			pieces.append({
				"glyph": ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)],
				"center": center,
				"burst": (away.normalized() if away.length() > 0.01 else Vector2.UP) * rng.randf_range(2.0, 8.0),
				"delay": rng.randf_range(0.0, FLY_STAGGER),
				"spin": rng.randf_range(-2.0, 2.0),
			})
	impact_center = art.get_center() + Vector2(0, -art.size.y * 0.1)
	card_center = hud.status_rect(0).get_center()
	impact_at = time
	if not hud.broken_units.has(target): hud.broken_units.append(target)
	await get_tree().create_timer(BREAK_SECONDS).timeout


func _opaque_points(index: int) -> Array:
	if _points.has(index): return _points[index]
	var art: Rect2 = hud.enemy_sprite_rect(index)
	var image: Image = hud.silhouettes[index % hud.silhouettes.size()].get_image()
	var size := image.get_size()
	var points: Array = []
	for y in range(0.0, art.size.y, 4.0):
		for x in range(0.0, art.size.x, 4.0):
			var px := Vector2i(int(x / art.size.x * size.x), int(y / art.size.y * size.y))
			if image.get_pixelv(px.clamp(Vector2i.ZERO, size - Vector2i.ONE)).a >= 0.5:
				points.append(art.position + Vector2(x, y))
	_points[index] = points
	return points


func _draw() -> void:
	if hud == null: return
	_draw_mash()
	_draw_break()
	var k := (time - impact_at) / HIT_TIME
	if k >= 0.0 and k < 1.0:
		_draw_hit(k)


func _draw_mash() -> void:
	if mash_letters.is_empty() or mash_target == null: return
	var own: BattleUnit = battle._fallen
	var share := float(own.current_sp) / maxf(1.0, own.current_sp + mash_target.current_sp)
	var track: Rect2 = hud.SP_TRACK
	var bar_point := Vector2(track.position.x + 1.0 + (track.size.x - 2.0) * share, track.get_center().y)
	for letter in mash_letters:
		var k: float = (time - float(letter.born)) / MASH_FLY
		if k < 0.0 or k >= 1.0: continue
		var e := k * k * (3.0 - 2.0 * k)
		var pos: Vector2 = Vector2(letter.from).lerp(bar_point, e)
		_glyph(letter.glyph, pos, float(letter.spin) * e, lerpf(1.0, 0.25, e), MASH_INK)
	draw_set_transform(Vector2.ZERO)


func _draw_break() -> void:
	var age := time - impact_at
	if pieces.is_empty() or age < 0.0: return
	var burst := _ease_out(age / BURST_TIME)
	for piece in pieces:
		var fly := _ease_in((age - BURST_TIME - float(piece.delay)) / FLY_TIME)
		if fly >= 1.0: continue
		var start: Vector2 = Vector2(piece.center) + Vector2(piece.burst) * burst
		_glyph(piece.glyph, start.lerp(card_center, fly), float(piece.spin) * fly, lerpf(1.0, 0.25, fly), LETTER_INK)
	draw_set_transform(Vector2.ZERO)


## k = 0..1 over HIT_TIME: rays ride an expanding ring; central flash in the first 30%.
func _draw_hit(k: float) -> void:
	var grow := _ease_out(k / 0.3)
	var fade := 1.0 if k < 0.5 else 1.0 - (k - 0.5) / 0.5
	var ink := Color(HIT_INK, fade)
	var radius := 8.0 + 52.0 * grow
	for i in HIT_RAYS:
		var dir := Vector2.from_angle(TAU * i / HIT_RAYS + 0.26)
		var length := (28.0 if i % 2 == 0 else 16.0) * (1.0 - 0.5 * k)
		var side := dir.orthogonal() * lerpf(6.0, 2.0, k)
		var base := impact_center + dir * radius
		draw_colored_polygon(PackedVector2Array([base + side, base + dir * length, base - side]), ink)
	if k < 0.3:
		draw_circle(impact_center, lerpf(16.0, 6.0, k / 0.3), ink)


func _glyph(glyph: String, pos: Vector2, angle: float, scale_k: float, ink: Color) -> void:
	draw_set_transform(pos, angle, Vector2.ONE * scale_k * LETTER_SCALE)
	var w := font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, LETTER_PX).x
	draw_string(font, Vector2(-w * 0.5, LETTER_PX * 0.4), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, LETTER_PX, ink)


func _ease_out(x: float) -> float: return 1.0 - pow(1.0 - clampf(x, 0, 1), 3)
func _ease_in(x: float) -> float: return pow(clampf(x, 0, 1), 3)
