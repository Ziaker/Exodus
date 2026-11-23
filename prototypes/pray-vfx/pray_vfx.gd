extends Node
## PROTOTYPE (D-048 Reza, creator 2026-11-23). Options for the creator to compare, drawn
## over the real playable battle (frozen backdrop, stage D):
##   --scene=raam     Ra'am thunder on FOE A. Options (--opt=):
##                      letters = a lightning bolt made of Hebrew letters (creator's idea)
##                      fork    = original: flat white forked bolt from the top, flash + shake
##                      pillar  = original: a column of pale light (#f5f58c) with side arcs
##   --scene=haganah  Haganah shield mark on Yoch's panel. Options:
##                      label   = "HAGANAH" tag in #f5f58c on the panel
##                      frame   = the panel border lit in #f5f58c
##                      glyph   = Hebrew letter he (ה) next to the name
##   --scene=pray | refuah | haganah_cast   cast VFX on the panel. Options:
##                      rise    = Hebrew letters rising from the panel
##                      ring    = thin #f5f58c ring opening from the panel centre
##                      motes   = small light motes falling onto the panel
## Keys 1-3 switch option. --capture=<dir> saves frames at fixed instants and quits.
## Every size, timing, colour (except the decided #f5f58c) and path is a placeholder.

const INK := Color("f5f58c")
const ALPHABET := "אבגדהוזחטיכלמנסעפצקרשת"
const SCENES := {
	"raam": ["letters", "fork", "pillar"],
	"haganah": ["label", "frame", "glyph"],
	"pray": ["rise", "ring", "motes"],
	"refuah": ["rise", "ring", "motes"],
	"haganah_cast": ["rise", "ring", "motes"],
}
const CYCLE := 2.4
const STRIKE_AT := 0.5
const STRIKE_TIME := 0.6
const SHAKE_PX := 5.0
const SHAKE_TIME := 0.3
const CAPTURE_TIMES := [0.3, 0.55, 0.7, 0.85, 1.05, 1.4]
## Ra'am "letters" v2 (creator 2026-11-23: "more ambition in the first one"). Timeline:
## charge (the stage darkens, loose letters spiral in and the word רעם forms in the sky),
## an instant double strike of large glowing letters down to the ground with letter
## branches, white impact frame, enemy silhouette flashing white, heavy shake, a ring of
## letters running along the ground, letters thrown up from the ground, and the bolt's
## letters smouldering and rising away. Every number below is a prototype placeholder.
const L_CYCLE := 3.2
const L_STRIKE := 0.7
const L_CHARGE := 0.7
const L_FLASH := 0.05
const L_REFLASH := [0.07, 0.11]
const L_BOLT_HOLD := 0.32
const L_SHAKE_PX := 9.0
const L_SHAKE_TIME := 0.45
const L_BURST_TIME := 0.9
const L_AFTER_TIME := 1.1
const L_CAPTURE_TIMES := [0.2, 0.45, 0.66, 0.71, 0.76, 0.82, 0.95, 1.15, 1.45, 1.9]
var l_bolt := PackedVector2Array()
var l_branches: Array[PackedVector2Array] = []
var l_glyphs: Array[Dictionary] = []
var l_branch_glyphs: Array[Dictionary] = []
var l_gather: Array[Dictionary] = []
var l_burst: Array[Dictionary] = []
var l_ring: Array[String] = []
var l_ground := Vector2.ZERO
var l_sky := Vector2.ZERO
var white_foe: Texture2D

var scene := "raam"
var option := "letters"
var capture_dir := ""
var battle: Control
var hud: Control
var overlay: Node2D
var font: SystemFont
var rng := RandomNumberGenerator.new()
var t := 0.0
var bolt: PackedVector2Array = PackedVector2Array()
var branches: Array[PackedVector2Array] = []
var glyphs: Array[Dictionary] = []
var target := Rect2()
var panel := Rect2()
var _captured := 0


func _ready() -> void:
	ProgressStore.save_path_override = "user://prayvfx_progress.json"
	ProgressStore.clear()
	RenderingServer.set_default_clear_color(Color.BLACK)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scene=") and SCENES.has(arg.trim_prefix("--scene=")):
			scene = arg.trim_prefix("--scene=")
		elif arg.begins_with("--opt="):
			option = arg.trim_prefix("--opt=")
		elif arg.begins_with("--capture="):
			capture_dir = arg.trim_prefix("--capture=")
	if not (SCENES[scene] as Array).has(option):
		option = SCENES[scene][0]
	battle = load("res://scenes/battle/BattlePlayable.tscn").instantiate()
	add_child(battle)
	battle.process_mode = Node.PROCESS_MODE_DISABLED
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Tahoma", "Arial", "David Libre"])
	font.font_weight = 800
	overlay = Node2D.new()
	overlay.z_index = 100
	overlay.draw.connect(_draw_fx)
	add_child(overlay)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var i: int = event.keycode - KEY_1
		var opts: Array = SCENES[scene]
		if i >= 0 and i < opts.size():
			option = opts[i]
			_build()
			t = 0.0


func _build() -> void:
	rng.seed = 48
	target = hud.enemy_sprite_rect(0)
	panel = hud.STATUS_RECTS[1]
	# The bolt starts under the HUD header (field top), never over the SP bar.
	var sky: float = hud.FIELD_RECT.position.y
	bolt = _zigzag(Vector2(target.get_center().x + 30, sky), Vector2(target.get_center().x, target.get_center().y), 6, 14.0)
	branches.clear()
	for k in [2, 3, 4]:
		var start: Vector2 = bolt[k]
		var dir := 1.0 if k % 2 == 1 else -1.0
		branches.append(_zigzag(start, start + Vector2(dir * rng.randf_range(30, 55), rng.randf_range(30, 50)), 3, 10.0))
	_build_letters_v2()
	glyphs.clear()
	var length := 0.0
	for i in bolt.size() - 1:
		length += bolt[i].distance_to(bolt[i + 1])
	var count := int(length / 13.0)
	for i in count:
		glyphs.append({"glyph": ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)],
			"at": float(i) / maxf(1.0, count - 1), "jit": Vector2(rng.randf_range(-2, 2), rng.randf_range(-2, 2))})
	if scene in ["pray", "refuah", "haganah_cast"]:
		for i in 14:
			glyphs.append({"glyph": ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)],
				"x": rng.randf_range(panel.position.x + 10, panel.end.x - 10),
				"delay": rng.randf_range(0.0, 0.5), "mote": true})


func _build_letters_v2() -> void:
	var sky: float = hud.FIELD_RECT.position.y
	l_ground = Vector2(target.get_center().x - 4, target.end.y - 14)
	l_sky = Vector2(target.get_center().x + 64, sky + 26)
	l_bolt = _zigzag(Vector2(l_sky.x, sky), l_ground, 9, 16.0)
	l_glyphs.clear()
	var count := int(_length(l_bolt) / 15.0)
	for i in count:
		l_glyphs.append({"glyph": ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)],
			"at": float(i) / maxf(1.0, count - 1), "jit": Vector2(rng.randf_range(-2, 2), rng.randf_range(-2, 2)),
			"drift": rng.randf_range(10, 30), "off": rng.randf_range(0.0, 1.0)})
	l_branches.clear()
	l_branch_glyphs.clear()
	for k in [2, 4, 5, 7]:
		var start: Vector2 = l_bolt[k]
		var dir := -1.0 if k % 2 == 0 else 1.0
		var b := _zigzag(start, start + Vector2(dir * rng.randf_range(18, 32), rng.randf_range(34, 52)), 3, 6.0)
		l_branches.append(b)
		var n := int(_length(b) / 11.0)
		for i in n:
			l_branch_glyphs.append({"branch": l_branches.size() - 1, "at": float(i + 1) / n,
				"glyph": ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)]})
	l_gather.clear()
	for i in 20:
		l_gather.append({"glyph": ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)],
			"angle": rng.randf_range(0, TAU), "radius": rng.randf_range(90, 170),
			"spin": rng.randf_range(2.0, 4.0) * (1 if i % 2 == 0 else -1), "delay": rng.randf_range(0.0, 0.25)})
	l_burst.clear()
	for i in 22:
		var a := rng.randf_range(PI * 1.05, PI * 1.95)
		l_burst.append({"glyph": ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)],
			"vel": Vector2.RIGHT.rotated(a) * rng.randf_range(120, 260), "px": rng.randi_range(12, 18)})
	l_ring.clear()
	for i in 16:
		l_ring.append(ALPHABET[(i * 7) % ALPHABET.length()])
	# The HUD silhouettes are solid white masks: drawn unmodulated they flash the foe white.
	white_foe = hud.silhouettes[0]


func _glow(points: PackedVector2Array, radius: float, color: Color) -> void:
	var total := _length(points)
	var steps := int(total / 5.0)
	for i in steps + 1:
		overlay.draw_circle(_point_along(points, float(i) / maxf(1.0, steps)), radius, color)


func _length(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in points.size() - 1:
		total += points[i].distance_to(points[i + 1])
	return total


func _zigzag(from: Vector2, to: Vector2, segments: int, spread: float) -> PackedVector2Array:
	var points := PackedVector2Array([from])
	for i in range(1, segments):
		var k := float(i) / segments
		var p := from.lerp(to, k)
		var normal := (to - from).orthogonal().normalized()
		points.append(p + normal * rng.randf_range(-spread, spread))
	points.append(to)
	return points


func _point_along(points: PackedVector2Array, k: float) -> Vector2:
	var total := 0.0
	for i in points.size() - 1:
		total += points[i].distance_to(points[i + 1])
	var want := total * clampf(k, 0.0, 1.0)
	for i in points.size() - 1:
		var seg := points[i].distance_to(points[i + 1])
		if want <= seg:
			return points[i].lerp(points[i + 1], want / maxf(seg, 0.001))
		want -= seg
	return points[points.size() - 1]


func _process(delta: float) -> void:
	if hud == null:
		hud = battle.hud
		if hud == null or hud.players.size() < 2: return
		hud.process_mode = Node.PROCESS_MODE_ALWAYS
		_build()
		return
	t += delta
	var cycle_len := L_CYCLE if scene == "raam" and option == "letters" else CYCLE
	if capture_dir.is_empty() and t >= cycle_len:
		t = 0.0
	var shake := Vector2.ZERO
	var l_age := t - L_STRIKE
	if scene == "raam" and option == "letters" and l_age >= 0.0 and l_age < L_SHAKE_TIME:
		shake = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * L_SHAKE_PX * pow(1.0 - l_age / L_SHAKE_TIME, 2)
	var age := t - STRIKE_AT
	if scene == "raam" and option == "fork" and age >= 0.0 and age < SHAKE_TIME:
		shake = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * SHAKE_PX * pow(1.0 - age / SHAKE_TIME, 2)
	battle.position = shake.round()
	overlay.position = shake.round()
	hud.queue_redraw()
	overlay.queue_redraw()
	if not capture_dir.is_empty():
		_capture_step()


func _capture_step() -> void:
	var times: Array = L_CAPTURE_TIMES if scene == "raam" and option == "letters" else CAPTURE_TIMES
	if _captured >= times.size():
		get_tree().quit(0)
		return
	if t >= times[_captured]:
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		DirAccess.make_dir_recursive_absolute(capture_dir)
		image.save_png("%s/%s_%s_%02d.png" % [capture_dir, scene, option, _captured])
		_captured += 1


func _glyph(glyph: String, pos: Vector2, px: int, color: Color, outline := Color(0, 0, 0, 0)) -> void:
	if outline.a > 0.0:
		overlay.draw_string_outline(font, pos, glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, px, 3, outline)
	overlay.draw_string(font, pos, glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, px, color)


func _draw_fx() -> void:
	if hud == null: return
	match scene:
		"raam": _draw_raam()
		"haganah": _draw_mark()
		_: _draw_cast()
	overlay.draw_string(font, Vector2(8, 296), "PROTOTYPE %s / %s  (1-3)" % [scene, option], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.7))


func _draw_raam() -> void:
	if option == "letters":
		_draw_raam_letters()
		return
	var age := t - STRIKE_AT
	if age < -0.25 or age > STRIKE_TIME + 0.4: return
	var k := clampf(age / STRIKE_TIME, 0.0, 1.0)
	var flicker := 1.0 if int(t * 30.0) % 3 != 0 else 0.55
	match option:
		"letters":
			# The bolt is drawn letter by letter from the sky down (0.12 s), holds, then fades.
			var reach := clampf((age + 0.25) / 0.37, 0.0, 1.0)
			var fade := 1.0 - clampf((age - STRIKE_TIME) / 0.4, 0.0, 1.0)
			for g in glyphs:
				if not g.has("at") or float(g.at) > reach: continue
				var p: Vector2 = _point_along(bolt, float(g.at)) + g.jit
				_glyph(g.glyph, p + Vector2(0, 7), 17, Color(INK, fade * flicker), Color(0.12, 0.08, 0.0, fade))
			# Impact: eight letters burst outward from the strike point.
			if age >= 0.0 and age < 0.35:
				var b := age / 0.35
				for i in 8:
					var dir := Vector2.RIGHT.rotated(TAU * i / 8.0)
					var p := target.get_center() + dir * (6.0 + 46.0 * b)
					_glyph(ALPHABET[(i * 5) % ALPHABET.length()], p + Vector2(0, 6), 15, Color(INK, 1.0 - b), Color(0.12, 0.08, 0.0, 1.0 - b))
		"fork":
			if age < 0.0: return
			var fade := 1.0 - clampf((age - STRIKE_TIME) / 0.4, 0.0, 1.0)
			if age < 0.05:
				overlay.draw_rect(Rect2(0, 0, 544, 298), Color(1, 1, 1, 0.85))
			overlay.draw_polyline(bolt, Color(1, 1, 1, fade * flicker), 7.0)
			overlay.draw_polyline(bolt, Color(0.1, 0.1, 0.1, fade), 2.0)
			for b in branches:
				overlay.draw_polyline(b, Color(1, 1, 1, fade * flicker), 3.0)
			var ring := 10.0 + 60.0 * k
			overlay.draw_arc(target.get_center(), ring, 0, TAU, 40, Color(1, 1, 1, (1.0 - k) * fade), 4.0)
		"pillar":
			var grow := clampf((age + 0.25) / 0.25, 0.0, 1.0)
			var fade := 1.0 - clampf((age - STRIKE_TIME) / 0.4, 0.0, 1.0)
			var w := 26.0 * grow * (0.8 + 0.2 * flicker)
			var c := target.get_center()
			var top: float = hud.FIELD_RECT.position.y
			overlay.draw_rect(Rect2(c.x - w * 0.5, top, w, c.y + 30 - top), Color(INK, 0.55 * fade))
			overlay.draw_rect(Rect2(c.x - w * 0.2, top, w * 0.4, c.y + 30 - top), Color(1, 1, 0.95, 0.9 * fade))
			if age >= 0.0:
				for i in 4:
					var y := c.y - 50 + i * 28 + fmod(t * 120.0, 28.0)
					var side := 1.0 if i % 2 == 0 else -1.0
					var arc := _zigzag(Vector2(c.x, y), Vector2(c.x + side * 44, y + 6), 4, 6.0)
					overlay.draw_polyline(arc, Color(INK, fade * flicker), 2.0)


func _draw_raam_letters() -> void:
	var stage := Rect2(0, 0, 544, 298)
	var age := t - L_STRIKE
	var flick := 1.0 if int(t * 30.0) % 4 != 0 else 0.5
	var ink_dark := Color(0.12, 0.08, 0.0)
	# 1) Charge: the stage darkens; letters spiral into a point in the sky; the word forms.
	var dark := 0.0
	if age < 0.0:
		dark = 0.62 * clampf((t - (L_STRIKE - L_CHARGE)) / L_CHARGE, 0.0, 1.0)
	elif age < 1.4:
		dark = 0.62 * (1.0 - clampf((age - 0.4) / 1.0, 0.0, 1.0))
	if dark > 0.0:
		overlay.draw_rect(stage, Color(0.02, 0.0, 0.05, dark))
	if age < 0.0:
		var c := clampf((t - (L_STRIKE - L_CHARGE)) / L_CHARGE, 0.0, 1.0)
		for g in l_gather:
			var k := clampf((c - float(g.delay)) / (1.0 - float(g.delay)), 0.0, 1.0)
			if k <= 0.0: continue
			var r := float(g.radius) * pow(1.0 - k, 1.6)
			var a := float(g.angle) + float(g.spin) * k
			var pos := l_sky + Vector2(cos(a) * r, sin(a) * r * 0.6)
			_glyph(g.glyph, pos + Vector2(0, 5), 12, Color(INK, 0.35 + 0.65 * k), Color(ink_dark, k))
		var word_k := clampf((c - 0.35) / 0.65, 0.0, 1.0)
		if word_k > 0.0:
			overlay.draw_arc(l_sky, 14.0 + 16.0 * word_k + 3.0 * sin(t * 30.0), 0, TAU, 40, Color(INK, 0.7 * word_k), 1.5)
			_glyph("רעם", l_sky + Vector2(0, 9), int(14 + 12 * word_k), Color(1, 1, 0.85, word_k), Color(ink_dark, word_k))
		return
	# 2) Strike: white impact frame, then the bolt flashes twice.
	if age < L_FLASH:
		overlay.draw_rect(Rect2(0, 0, 544, 416), Color(1, 1, 1, 0.92))
	var gap: bool = age >= L_REFLASH[0] and age < L_REFLASH[1]
	if age < L_BOLT_HOLD and not gap:
		_glow(l_bolt, 11.0, Color(INK, 0.07 * flick))
		_glow(l_bolt, 5.0, Color(1, 1, 0.9, 0.35))
		overlay.draw_polyline(l_bolt, Color(1, 1, 0.95, 0.9), 2.0)
		for b in l_branches:
			_glow(b, 5.0, Color(INK, 0.06 * flick))
		for g in l_branch_glyphs:
			var p: Vector2 = _point_along(l_branches[int(g.branch)], float(g.at))
			_glyph(g.glyph, p + Vector2(0, 5), 13, Color(1, 1, 0.9, flick), Color(ink_dark, 1.0))
	# Bolt letters: full during the strike, then they smoulder, flicker and rise away.
	var after := clampf((age - L_BOLT_HOLD) / L_AFTER_TIME, 0.0, 1.0)
	if not gap:
		for g in l_glyphs:
			var p: Vector2 = _point_along(l_bolt, float(g.at)) + g.jit
			var alpha := 1.0
			if after > 0.0:
				alpha = (1.0 - after) * (0.4 if fmod(t * 9.0 + float(g.off) * 7.0, 1.0) < 0.25 else 1.0)
				p += Vector2(0, -float(g.drift) * after)
			if alpha <= 0.01: continue
			var ink: Color = INK if after > 0.0 else Color(1, 1, 0.88)
			_glyph(g.glyph, p + Vector2(0, 8), 20 if after <= 0.0 else 18, Color(ink, alpha), Color(ink_dark, alpha))
	# 3) The struck enemy flashes white.
	if age < 0.36 and int(age * 30.0) % 2 == 0:
		overlay.draw_texture_rect(white_foe, target, false, Color(1, 1, 1, 0.9))
	# 4) Ground: a ring of letters runs out along the floor; letters are thrown up and fall.
	if age < 0.5:
		var rk := age / 0.5
		for i in l_ring.size():
			var a := TAU * i / l_ring.size()
			var pos := l_ground + Vector2(cos(a) * (36 + 110 * rk), sin(a) * (9 + 26 * rk))
			_glyph(l_ring[i], pos + Vector2(0, 5), 14, Color(INK, 1.0 - rk), Color(ink_dark, 1.0 - rk))
	if age < L_BURST_TIME:
		var bk := age / L_BURST_TIME
		for g in l_burst:
			var pos: Vector2 = l_ground + g.vel.normalized() * 14.0 + g.vel * age + Vector2(0, 520.0 * age * age)
			if pos.y > stage.end.y - 4: continue  # thrown letters stay on the stage, never over the HUD
			_glyph(g.glyph, pos, int(g.px), Color(INK, 1.0 - bk * bk), Color(ink_dark, 1.0 - bk))


func _draw_mark() -> void:
	match option:
		"label":
			# Next to the name, clear of ACT, PP and the act pips.
			var w := 50.0
			var x0 := panel.position.x + 7 + font.get_string_size("Yoch", HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 8
			var r := Rect2(x0, panel.position.y + 8, w, 12)
			overlay.draw_rect(r, Color(0, 0, 0, 0.6))
			overlay.draw_string(font, Vector2(r.position.x + 3, r.end.y - 2), "HAGANAH", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, INK)
		"frame":
			var pulse := 0.55 + 0.45 * absf(sin(t * 2.6))
			overlay.draw_rect(Rect2(panel.position + Vector2(0.5, 0.5), panel.size - Vector2.ONE), Color(INK, pulse), false, 1.5)
		"glyph":
			var x := panel.position.x + 7 + font.get_string_size("Yoch", HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 8
			_glyph("ה", Vector2(x + 5, panel.position.y + 18), 13, INK)


func _draw_cast() -> void:
	var age := t - 0.3
	if age < 0.0 or age > 1.3: return
	var c := panel.get_center()
	match option:
		"rise":
			for g in glyphs:
				if not g.has("mote"): continue
				var k := (age - float(g.delay)) / 0.8
				if k < 0.0 or k > 1.0: continue
				var y := panel.end.y - 6 - 70.0 * k
				_glyph(g.glyph, Vector2(g.x, y), 12, Color(INK, 1.0 - k), Color(0.15, 0.12, 0.0, 1.0 - k))
		"ring":
			var k := clampf(age / 0.7, 0.0, 1.0)
			var radius := 8.0 + 70.0 * (1.0 - pow(1.0 - k, 2))
			overlay.draw_arc(c, radius, 0, TAU, 48, Color(INK, 1.0 - k), 3.0)
			overlay.draw_arc(c, radius * 0.6, 0, TAU, 40, Color(INK, (1.0 - k) * 0.6), 1.5)
		"motes":
			for g in glyphs:
				if not g.has("mote"): continue
				var k := (age - float(g.delay)) / 0.7
				if k < 0.0 or k > 1.0: continue
				var y := panel.position.y - 50 + 70.0 * k
				overlay.draw_circle(Vector2(g.x, y), 2.0, Color(INK, 1.0 - k * k))
