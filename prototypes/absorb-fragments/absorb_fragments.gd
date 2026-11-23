extends Node
## PROTOTYPE (D-051 absorption VFX, creator 2026-11-22). Inside the real playable
## battle, FOE A's silhouette breaks into fragments that fly to Fallen's status card.
## Four fragment shapes for the creator to compare:
##   shards = irregular triangles, blocks = square grid, strips = horizontal bands,
##   particles = fine dots. Keys 1-4 switch and restart; user arg --opt=<name>.
## Every count, size, timing, path and destination here is a prototype placeholder,
## not a decision: only the shape is under review.
## APPROVED by the creator (D-052): letters + hit ringburst + mash scene, run with
##   -- --opt=letters --hit=ringburst --mash
## Still open: colour, timing, path and destination of the break letters; failure visual.

## letters = the silhouette turns into loose Hebrew letters (creator 2026-11-22).
## The stage uses the background prototype D with enemies 15% smaller (battle-bg).
const OPTIONS := ["shards", "blocks", "strips", "particles", "letters"]
const ALPHABET := "אבגדהוזחטיכלמנסעפצקרשת"
## Creator 2026-11-22: letters 8 px apart and 20% larger than the 12 px first cut.
const LETTER_CELL := 8.0
const LETTER_PX := 12
const LETTER_SCALE := 1.2
## New hit VFX that strikes the enemy and causes the break (creator 2026-11-22, three
## options under review; --hit=<name>): slash = a blade cut across the silhouette,
## burst = rays exploding from the body centre, ring = a shock ring expanding from the
## impact point. The break starts when the hit ends. Ink, size and time are placeholders.
## ringburst = creator 2026-11-22: the ring's expansion drawn with the burst's look (flat
## anime impact, little detail) plus a shake.
## Creator corrections 2026-11-22 on ringburst: the enemy breaks AT the impact (not after
## the hit), the shake must be a real game screen shake (the enemy-only square wave was
## badly done), and the hit is white.
const HITS := ["none", "slash", "burst", "ring", "ringburst"]
const HIT_TIME := 0.35
const HIT_INK := Color.WHITE
## Screen shake: random offset every frame on both axes, amplitude decaying to zero.
## Amplitude and duration are prototype placeholders.
const SCREEN_SHAKE_PX := 6.0
const SCREEN_SHAKE_TIME := 0.35
## Timeline of one cycle (seconds).
const IMPACT_AT := 0.8
const BURST_TIME := 0.5
const FLY_TIME := 0.9
const FLY_STAGGER := 0.5
const CYCLE := 4.0
## --mash (creator 2026-11-22): the mash scene happens in the battle itself; on every press
## Hebrew letters leave the opponent and fly to the character, WITHOUT breaking it. Here the
## 10 presses are simulated evenly inside the 2 s window (D-051), each moving 2 SP, and the
## absorption succeeds at the end with the approved hit. Letters per press, flight time,
## path and press rhythm are prototype placeholders.
const MASH_START := 0.6
const MASH_SETTLE := 0.4
const MASH_LETTERS := 3
const MASH_FLY := 0.6
## Black mash letters vanished on the dark stage; three inks for the creator to compare
## (--ink=white|green|outline): the approved hit's white, the HUD's SP green, or the break
## letters' black with a light outline.
const MASH_INKS := ["white", "green", "outline"]
var mash_ink := "green"  # chosen by the creator 2026-11-22

var option := "shards"
var battle: Control
var hud: Control
var overlay: Node2D
var foe: BattleUnit
var foe_hp := 0
var texture: ImageTexture
var art := Rect2()
var target := Vector2.ZERO
var pieces: Array[Dictionary] = []
var t := -1.0
var rng := RandomNumberGenerator.new()
var font: SystemFont
var hit := "none"
var break_at := IMPACT_AT
var impact_at := IMPACT_AT
var cycle := CYCLE
var mash := false
var mash_letters: Array[Dictionary] = []
var presses := 0
var fallen: BattleUnit
var fallen_sp := 0
var foe_sp := 0
var base_mode := ""
var opaque_points: Array[Vector2] = []


func _ready() -> void:
	ProgressStore.save_path_override = "user://absorbfrag_progress.json"
	ProgressStore.clear()
	# The screen shake moves the whole battle; the strip it uncovers at the edges is black
	# (as on console screen shakes) instead of the engine's grey clear colour.
	RenderingServer.set_default_clear_color(Color.BLACK)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--opt=") and OPTIONS.has(arg.trim_prefix("--opt=")):
			option = arg.trim_prefix("--opt=")
		if arg.begins_with("--hit=") and HITS.has(arg.trim_prefix("--hit=")):
			hit = arg.trim_prefix("--hit=")
		if arg == "--mash":
			mash = true
		if arg.begins_with("--ink=") and MASH_INKS.has(arg.trim_prefix("--ink=")):
			mash_ink = arg.trim_prefix("--ink=")
	if mash:
		impact_at = MASH_START + BattleMath.ABSORB_SECONDS + MASH_SETTLE
		break_at = impact_at
		cycle = impact_at + 3.2
	if hit != "none" and hit != "ringburst":
		break_at = impact_at + HIT_TIME
	battle = load("res://scenes/battle/BattlePlayable.tscn").instantiate()
	add_child(battle)
	# The approved layout (stage D, enemies 15% smaller) is now built by the game itself.
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Tahoma", "Arial", "David Libre"])
	font.font_weight = 800
	battle.process_mode = Node.PROCESS_MODE_DISABLED  # frozen backdrop: no input, no AI
	overlay = Node2D.new()
	overlay.z_index = 100
	overlay.draw.connect(_draw_pieces)
	add_child(overlay)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var i: int = event.keycode - KEY_1
		if i >= 0 and i < OPTIONS.size():
			option = OPTIONS[i]
			_build()


func _process(delta: float) -> void:
	if hud == null:
		hud = battle.hud
		if hud == null or hud.opponents.is_empty(): return
		hud.process_mode = Node.PROCESS_MODE_ALWAYS
		foe = hud.opponents[0]
		foe_hp = foe.current_hp
		texture = hud.silhouettes[0]
		art = hud.enemy_sprite_rect(0)
		var card: Rect2 = hud.STATUS_RECTS[0]
		target = card.get_center()
		fallen = hud.players[0]
		fallen_sp = fallen.current_sp
		foe_sp = foe.current_sp
		base_mode = hud.mode
		_build()
		return
	t += delta
	if t >= cycle:
		t = 0.0
		presses = 0
		mash_letters.clear()
	if mash: _update_mash()
	var shake := Vector2.ZERO
	var age := t - impact_at
	if hit == "ringburst" and age >= 0.0 and age < SCREEN_SHAKE_TIME:
		var amp := SCREEN_SHAKE_PX * pow(1.0 - age / SCREEN_SHAKE_TIME, 2)
		shake = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * amp
	battle.position = shake.round()
	overlay.position = shake.round()
	# The real HUD draws FOE A while intact; from the break on the HUD drops it (art,
	# ground shadow, label) and the overlay draws the fragments. FOE A stays the action
	# target, so the SP header keeps showing it as during a real absorption.
	var broken := t >= break_at
	battle.action_defender = foe
	foe.current_hp = 0 if broken else foe_hp
	hud.queue_redraw()
	overlay.queue_redraw()


func _update_mash() -> void:
	var window: float = BattleMath.ABSORB_SECONDS
	var total: int = BattleMath.ABSORB_MAX_PRESSES
	var due := 0
	if t >= MASH_START:
		due = mini(total, int((t - MASH_START) / (window / total)) + 1)
	while presses < due:
		presses += 1
		var born := MASH_START + (presses - 1) * window / total
		for i in MASH_LETTERS:
			mash_letters.append({
				"glyph": ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)],
				"from": opaque_points[rng.randi_range(0, opaque_points.size() - 1)],
				"born": born + i * 0.05,
				"spin": rng.randf_range(-2.0, 2.0),
			})
	# The HUD stays in absorb mode from the first press to the end of the break, so the
	# command menu does not pop back between the mash and the hit.
	hud.mode = "absorb" if t >= MASH_START else base_mode
	battle._mash_count = presses
	foe.current_sp = maxi(0, foe_sp - 2 * presses)
	fallen.current_sp = fallen_sp + (foe_sp - foe.current_sp)


func _draw_mash() -> void:
	# Creator 2026-11-22: the letters go to the SP bar (not to the character), in SP green.
	# They land on the green/red boundary of the bar (HUD track Rect2(8, 59, 528, 8)),
	# where Fallen's share grows; that landing point is a prototype placeholder.
	var share := float(fallen.current_sp) / maxf(1.0, fallen.current_sp + foe.current_sp)
	var bar_point := Vector2(9.0 + 526.0 * share, 63.0)
	for letter in mash_letters:
		var k: float = (t - letter.born) / MASH_FLY
		if k < 0.0 or k >= 1.0: continue
		var e := k * k * (3.0 - 2.0 * k)
		var pos: Vector2 = letter.from.lerp(bar_point, e)
		overlay.draw_set_transform(pos, letter.spin * e, Vector2.ONE * lerpf(1.0, 0.25, e) * LETTER_SCALE)
		var w := font.get_string_size(letter.glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, LETTER_PX).x
		var at := Vector2(-w * 0.5, LETTER_PX * 0.4)
		match mash_ink:
			"white":
				overlay.draw_string(font, at, letter.glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, LETTER_PX, Color.WHITE)
			"green":
				overlay.draw_string(font, at, letter.glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, LETTER_PX, Color("81e6a8"))
			"outline":
				overlay.draw_string_outline(font, at, letter.glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, LETTER_PX, 3, Color.WHITE)
				overlay.draw_string(font, at, letter.glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, LETTER_PX, Color.BLACK)
	overlay.draw_set_transform(Vector2.ZERO)


func _build() -> void:
	t = 0.0
	rng.seed = 51
	pieces.clear()
	presses = 0
	mash_letters.clear()
	var image := texture.get_image()
	var size := image.get_size()
	opaque_points.clear()
	for y in range(0.0, art.size.y, 4.0):
		for x in range(0.0, art.size.x, 4.0):
			var px := Vector2i(int(x / art.size.x * size.x), int(y / art.size.y * size.y))
			if image.get_pixelv(px.clamp(Vector2i.ZERO, size - Vector2i.ONE)).a >= 0.5:
				opaque_points.append(art.position + Vector2(x, y))
	match option:
		"shards":
			var cols := 7
			var rows := 8
			var grid: Array = []
			for y in rows + 1:
				var row: Array[Vector2] = []
				for x in cols + 1:
					var p := Vector2(float(x) / cols, float(y) / rows)
					if x > 0 and x < cols: p.x += rng.randf_range(-0.4, 0.4) / cols
					if y > 0 and y < rows: p.y += rng.randf_range(-0.4, 0.4) / rows
					row.append(p)
				grid.append(row)
			for y in rows:
				for x in cols:
					var a: Vector2 = grid[y][x]; var b: Vector2 = grid[y][x + 1]
					var c: Vector2 = grid[y + 1][x + 1]; var d: Vector2 = grid[y + 1][x]
					var tris := [[a, b, c], [a, c, d]] if (x + y) % 2 == 0 else [[a, b, d], [b, c, d]]
					for tri in tris:
						_add_polygon(PackedVector2Array(tri), image, size)
		"blocks":
			var cell := 6.0
			for y in range(0.0, art.size.y, cell):
				for x in range(0.0, art.size.x, cell):
					var u0 := Vector2(x / art.size.x, y / art.size.y)
					var u1 := Vector2(minf(x + cell, art.size.x) / art.size.x, minf(y + cell, art.size.y) / art.size.y)
					_add_polygon(PackedVector2Array([u0, Vector2(u1.x, u0.y), u1, Vector2(u0.x, u1.y)]), image, size)
		"strips":
			var band := 5.0
			for y in range(0.0, art.size.y, band):
				var v0 := y / art.size.y
				var v1 := minf(y + band, art.size.y) / art.size.y
				_add_polygon(PackedVector2Array([Vector2(0, v0), Vector2(1, v0), Vector2(1, v1), Vector2(0, v1)]), image, size)
		"particles":
			var step := 2.0  # 2 px dots on a 2 px grid: the break starts from the full silhouette
			for y in range(0.0, art.size.y, step):
				for x in range(0.0, art.size.x, step):
					var px := Vector2i(int(x / art.size.x * size.x), int(y / art.size.y * size.y))
					if image.get_pixelv(px.clamp(Vector2i.ZERO, size - Vector2i.ONE)).a < 0.5: continue
					_add_piece({"dot": art.position + Vector2(x, y)}, art.position + Vector2(x + 1, y + 1))
		"letters":
			# One letter per opaque cell of the silhouette.
			for y in range(0.0, art.size.y, LETTER_CELL):
				for x in range(0.0, art.size.x, LETTER_CELL):
					var c := Vector2(x, y) + Vector2.ONE * LETTER_CELL * 0.5
					var px := Vector2i(int(c.x / art.size.x * size.x), int(c.y / art.size.y * size.y))
					if image.get_pixelv(px.clamp(Vector2i.ZERO, size - Vector2i.ONE)).a < 0.5: continue
					_add_piece({"glyph": ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)]}, art.position + c)


func _add_polygon(uvs: PackedVector2Array, image: Image, size: Vector2i) -> void:
	# Skip pieces cut only from the transparent part of the silhouette.
	var lo := uvs[0]; var hi := uvs[0]
	for uv in uvs:
		lo = lo.min(uv); hi = hi.max(uv)
	var opaque := false
	for sy in 5:
		for sx in 5:
			var uv := lo + (hi - lo) * Vector2((sx + 0.5) / 5.0, (sy + 0.5) / 5.0)
			if Geometry2D.is_point_in_polygon(uv, uvs) and image.get_pixel(clampi(int(uv.x * size.x), 0, size.x - 1), clampi(int(uv.y * size.y), 0, size.y - 1)).a >= 0.5:
				opaque = true
	if not opaque: return
	var center := Vector2.ZERO
	for uv in uvs: center += uv
	center /= uvs.size()
	var screen_center := art.position + center * art.size
	var local := PackedVector2Array()
	for uv in uvs: local.append(art.position + uv * art.size - screen_center)
	_add_piece({"points": local, "uvs": uvs}, screen_center)


func _add_piece(piece: Dictionary, center: Vector2) -> void:
	piece.center = center
	var away := center - art.get_center()
	piece.burst = (away.normalized() if away.length() > 0.01 else Vector2.UP) * rng.randf_range(2.0, 8.0)
	piece.delay = rng.randf_range(0.0, FLY_STAGGER)
	piece.spin = rng.randf_range(-2.0, 2.0)
	pieces.append(piece)


## k = 0..1 over HIT_TIME. Grows fast in the first 30%, then fades out.
func _draw_hit(k: float) -> void:
	var grow := _ease_out(k / 0.3)
	var fade := 1.0 if k < 0.5 else 1.0 - (k - 0.5) / 0.5
	var ink := Color(HIT_INK, fade)
	var c := art.get_center() + Vector2(0, -art.size.y * 0.1)
	match hit:
		"slash":
			# Tapered blade from upper right to lower left, widest in the middle.
			var a := c + Vector2(art.size.x * 0.55, -art.size.y * 0.45)
			var b := c + Vector2(-art.size.x * 0.55, art.size.y * 0.45)
			var tip := a.lerp(b, grow)
			var n := (b - a).normalized().orthogonal()
			var w := lerpf(5.0, 1.0, maxf(0.0, (k - 0.3) / 0.7))
			var mid := a.lerp(tip, 0.5)
			overlay.draw_colored_polygon(PackedVector2Array([a, mid + n * w, tip, mid - n * w]), ink)
		"burst":
			var rays := 12
			for i in rays:
				var ang := TAU * i / rays + 0.26
				var length := (60.0 if i % 2 == 0 else 38.0) * grow
				var dir := Vector2.from_angle(ang)
				var side := dir.orthogonal() * lerpf(4.0, 1.0, k)
				overlay.draw_colored_polygon(PackedVector2Array([c + side, c + dir * length, c - side]), ink)
			overlay.draw_circle(c, lerpf(10.0, 2.0, k), ink)
		"ring":
			var radius := 8.0 + 72.0 * grow
			overlay.draw_arc(c, radius, 0, TAU, 48, ink, lerpf(6.0, 1.0, k))
			if k < 0.3:
				overlay.draw_circle(c, lerpf(14.0, 4.0, k / 0.3), ink)
		"ringburst":
			# The burst's flat rays, pushed outward on an expanding ring: each ray's base
			# rides the ring, so the impact opens up like the ring instead of staying put.
			var rays := 12
			var radius := 8.0 + 52.0 * grow
			for i in rays:
				var dir := Vector2.from_angle(TAU * i / rays + 0.26)
				var length := (28.0 if i % 2 == 0 else 16.0) * (1.0 - 0.5 * k)
				var side := dir.orthogonal() * lerpf(6.0, 2.0, k)
				var base := c + dir * radius
				overlay.draw_colored_polygon(PackedVector2Array([base + side, base + dir * length, base - side]), ink)
			if k < 0.3:
				overlay.draw_circle(c, lerpf(16.0, 6.0, k / 0.3), ink)


func _ease_out(x: float) -> float: return 1.0 - pow(1.0 - clampf(x, 0, 1), 3)
func _ease_in(x: float) -> float: return pow(clampf(x, 0, 1), 3)


func _draw_pieces() -> void:
	if texture == null: return
	if mash: _draw_mash()
	_draw_letters()
	# The hit is drawn over the fragments, which break at the same instant.
	if hit != "none" and t >= impact_at and t < impact_at + HIT_TIME:
		_draw_hit((t - impact_at) / HIT_TIME)


func _draw_letters() -> void:
	if t < break_at: return
	var burst :=_ease_out((t - break_at) / BURST_TIME)
	for piece in pieces:
		var fly := _ease_in((t - break_at - BURST_TIME - piece.delay) / FLY_TIME)
		if fly >= 1.0: continue
		var start: Vector2 = piece.center + piece.burst * burst
		var pos := start.lerp(target, fly)
		var scale := lerpf(1.0, 0.25, fly)
		if piece.has("dot"):
			var s := 2.0 * scale
			overlay.draw_rect(Rect2(pos - Vector2(s, s) * 0.5, Vector2(s, s)), Color.BLACK)
			continue
		if piece.has("glyph"):
			overlay.draw_set_transform(pos, piece.spin * fly, Vector2.ONE * scale * LETTER_SCALE)
			var w := font.get_string_size(piece.glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, LETTER_PX).x
			overlay.draw_string(font, Vector2(-w * 0.5, LETTER_PX * 0.4), piece.glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, LETTER_PX, Color.BLACK)
			continue
		overlay.draw_set_transform(pos, piece.spin * fly, Vector2(scale, scale))
		overlay.draw_colored_polygon(piece.points, Color.BLACK, piece.uvs, texture)
	overlay.draw_set_transform(Vector2.ZERO)
