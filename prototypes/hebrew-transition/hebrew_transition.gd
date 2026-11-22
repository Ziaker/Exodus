extends Node2D
## PROTOTYPE (D-050 prologue, creator 2026-11-22). After the impact the dark screen
## fills with loose Hebrew letters; they fly to their places to form the dialogue box
## and the yellow silhouette above it; the lines are shown; then figure and box scatter
## and vanish, leaving black. Three entrance options for the creator to choose from:
##   a = letters appear scattered, b = letters fall from above, c = letters written in
##   rows from right to left. Keys 1/2/3 switch and restart; user arg --opt=a|b|c.
## Every size, colour, speed and shape here is a prototype placeholder, not a decision.

const W := 544.0
const H := 416.0
const ALPHABET := "אבגדהוזחטיכלמנסעפצקרשת"
const LETTER_INK := Color("e8e0d0")
const SILHOUETTE_INK := Color("f2d34b")
const TEXT_INK := Color("f8f1ea")
const BOX := Rect2(28, 288, 488, 104)
const BOX_STEP := 13.0
const SIL_STEP := 9.0
## Timeline (seconds).
const ENTER_END := 3.0
const FLY_END := 5.0
const TEXT_END := 12.5
const SCATTER_END := 14.5
const LOOP_END := 15.5
## Creator's lines; the [hebraico] markers stay pending, shown as loose letters.
const LINES := [
	"Levanta-te %s, Tu és um fracasso de vosso, %s não é te dado o ritual de repouso",
	"Sirva como punição, %s, Levanta-te. Levanta-te.",
]

var option := "a"
var t := 0.0
var letters: Array[Dictionary] = []
var font: SystemFont
var rng := RandomNumberGenerator.new()
var lines: Array[String] = []


func _ready() -> void:
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Tahoma", "Arial", "David Libre"])
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--opt="):
			option = arg.trim_prefix("--opt=")
	_restart()


func _restart() -> void:
	t = 0.0
	rng.seed = 49
	letters.clear()
	lines.clear()
	for line in LINES:
		lines.append(line % _hebrew_word() if line.count("%s") == 1 else line % [_hebrew_word(), _hebrew_word()])
	var targets := _box_targets()
	targets.append_array(_silhouette_targets())
	targets.shuffle()
	var count := targets.size()
	for i in count:
		var target: Dictionary = targets[i]
		var letter := {"glyph": ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)], "target": target.pos, "yellow": target.yellow,
			"rest": Vector2(rng.randf_range(10, W - 10), rng.randf_range(16, H - 6)),
			"appear": 0.0, "fly_delay": rng.randf_range(0.0, 0.8),
			"scatter": Vector2.from_angle(rng.randf_range(0, TAU)) * rng.randf_range(60, 260),
			"scatter_delay": rng.randf_range(0.0, 0.5), "spin": rng.randf_range(-3.0, 3.0)}
		match option:
			"b":
				letter.appear = rng.randf_range(0.0, ENTER_END - 0.9)
			"c":
				pass
			_:
				letter.appear = rng.randf_range(0.0, ENTER_END - 0.3)
		letters.append(letter)
	if option == "c":
		# Rows written right to left, top to bottom, on a regular grid.
		var cols := int(W / 15.0)
		var rows := int(ceil(float(count) / cols))
		var row_h := (H - 20.0) / rows
		for i in count:
			var row := i / cols
			var col := i % cols
			letters[i].rest = Vector2(W - 10 - col * 15.0, 20 + row * row_h)
			letters[i].appear = float(i) / count * (ENTER_END - 0.2)


func _hebrew_word() -> String:
	var word := ""
	for i in rng.randi_range(3, 6):
		word += ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)]
	return word


func _box_targets() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var x := BOX.position.x
	while x <= BOX.end.x:
		out.append({"pos": Vector2(x, BOX.position.y), "yellow": false})
		out.append({"pos": Vector2(x, BOX.end.y), "yellow": false})
		x += BOX_STEP
	var y := BOX.position.y + BOX_STEP
	while y < BOX.end.y:
		out.append({"pos": Vector2(BOX.position.x, y), "yellow": false})
		out.append({"pos": Vector2(BOX.end.x, y), "yellow": false})
		y += BOX_STEP
	return out


## Placeholder standing figure (head, shoulders, robe) sampled on a letter grid.
func _silhouette_targets() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var cx := W * 0.5
	var y := 52.0
	while y < 272.0:
		var x := cx - 90.0
		while x <= cx + 90.0:
			if _inside_figure(Vector2(x - cx, y)):
				out.append({"pos": Vector2(x, y), "yellow": true})
			x += SIL_STEP
		y += SIL_STEP
	return out


## Placeholder robed figure: head, shoulders, arms hanging apart from the body, robe.
const FIGURE := [Vector2(-7, 90), Vector2(7, 90), Vector2(36, 102), Vector2(54, 116), Vector2(68, 182),
	Vector2(56, 186), Vector2(46, 132), Vector2(36, 134), Vector2(44, 200), Vector2(64, 272),
	Vector2(-64, 272), Vector2(-44, 200), Vector2(-36, 134), Vector2(-46, 132), Vector2(-56, 186),
	Vector2(-68, 182), Vector2(-54, 116), Vector2(-36, 102)]


func _inside_figure(p: Vector2) -> bool:
	if p.distance_to(Vector2(0, 70)) <= 18: return true
	return Geometry2D.is_point_in_polygon(p, PackedVector2Array(FIGURE))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: option = "a"; _restart()
			KEY_2: option = "b"; _restart()
			KEY_3: option = "c"; _restart()


func _process(delta: float) -> void:
	t += delta
	if t >= LOOP_END:
		_restart()
	queue_redraw()


func _ease(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color.BLACK)
	for letter in letters:
		var age: float = t - float(letter.appear)
		if age < 0.0: continue
		var pos: Vector2 = letter.rest
		var alpha := clampf(age / 0.35, 0.0, 1.0)
		var ink := LETTER_INK
		var angle := 0.0
		if option == "b" and t < ENTER_END + 0.0:
			# Falls from above the screen to its resting spot.
			var fall := _ease(age / 0.9)
			pos = Vector2(letter.rest.x, lerpf(-20.0, letter.rest.y, fall))
			alpha = 1.0
		if t >= ENTER_END:
			var f := _ease((t - ENTER_END - float(letter.fly_delay)) / (FLY_END - ENTER_END - 0.8))
			pos = (letter.rest as Vector2).lerp(letter.target, f)
			if letter.yellow: ink = LETTER_INK.lerp(SILHOUETTE_INK, f)
			alpha = 1.0
		if t >= TEXT_END:
			var s := clampf((t - TEXT_END - float(letter.scatter_delay)) / (SCATTER_END - TEXT_END - 0.5), 0.0, 1.0)
			pos = (letter.target as Vector2) + (letter.scatter as Vector2) * _ease(s)
			angle = float(letter.spin) * s
			alpha = 1.0 - s
		if alpha <= 0.0: continue
		ink.a = alpha
		draw_set_transform(pos, angle)
		draw_string(font, Vector2(-5, 5), letter.glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, ink)
	draw_set_transform(Vector2.ZERO)
	_draw_text()
	draw_string(font, Vector2(6, 12), "PROTOTYPE  entrada %s  (1/2/3)" % option.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1, 0.35))


## The two lines, typed one after the other inside the formed box.
func _draw_text() -> void:
	if t < FLY_END + 0.2 or t >= TEXT_END + 0.4: return
	var fade := 1.0 - clampf((t - TEXT_END) / 0.4, 0.0, 1.0)
	var start := FLY_END + 0.2
	var per_line := (TEXT_END - start) / lines.size()
	var index := mini(int((t - start) / per_line), lines.size() - 1)
	var shown: String = lines[index]
	var chars := int((t - start - index * per_line) * 34.0)
	shown = shown.substr(0, chars)
	draw_multiline_string(font, BOX.position + Vector2(18, 30), shown, HORIZONTAL_ALIGNMENT_LEFT, BOX.size.x - 36, 13, 3, Color(TEXT_INK, fade))
