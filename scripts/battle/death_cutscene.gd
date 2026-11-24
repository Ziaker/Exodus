extends Node2D
## Fallen's death cutscene (creator 2026-11-23). Over the battle the screen fills with red
## Hebrew letters, written in rows from right to left (the prologue's option C), while the
## background turns black over 3 seconds. The letters then fly to their places and form the
## prologue's angel figure and dialogue box, in red (#a8182a); the angel's line is typed in
## the box at the prologue's pace, with "Do que te fortaleceu, parte perderás" in green;
## after the line, the stat losses ("-1 ATK") fly from the four screen corners into the
## angel; then figure and box come apart into letters and vanish.
## Figure, sizes and grid steps are the prologue's (prototypes/hebrew-transition/
## hebrew_transition.gd); the creator asked for "same as the prologue, only red".

signal finished

## D-055: 816 x 624 screen. The prologue composition (figure + box, 544 x 416) keeps its
## size and is centred; the letters still fill the whole screen.
const W := 816.0
const H := 624.0
const OFFSET := Vector2((W - 544.0) * 0.5, (H - 416.0) * 0.5)
const ALPHABET := "אבגדהוזחטיכלמנסעפצקרשת"
## Creator 2026-11-23: letters and angel in #a8182a.
const INK := Color("a8182a")
const TEXT_INK := Color("f8f1ea")
const BOX := Rect2(28 + OFFSET.x, 288 + OFFSET.y, 488, 104)
const BOX_STEP := 13.0
const SIL_STEP := 6.0
const LETTER_PX := 14.0
const SIL_PX := 9.0
const FIGURE_ART := "res://prototypes/hebrew-transition/art/angel_human_mask.png"
const FIGURE_TOP := 22.0 + OFFSET.y
const FIGURE_BOTTOM := 243.0 + OFFSET.y
## Timeline (seconds), creator 2026-11-23: 3 s of letters filling the screen, 2 s of
## flight, 5 s of the line (typed at the prologue's 34 chars/s, then held), 3 s of the
## losses flying into the angel, 1 s to come apart; 14 s in all.
const ENTER_END := 3.0
const FLY_END := ENTER_END + 2.0
const TEXT_START := FLY_END
const TEXT_END := TEXT_START + 5.0
const LOSS_END := TEXT_END + 3.0
const SCATTER_END := LOSS_END + 1.0
const END := SCATTER_END
const CHARS_PER_SECOND := 34.0
## Creator 2026-11-23 (alternative 2); [hebraico] is shown as loose letters, as in the prologue.
const LINE := "Levanta-te, %s, que a ti não é dada a bênção da morte. Do que te fortaleceu, parte perderás, como punição."
## Creator 2026-11-23: this part of the line in #81e6a8 (the ABSORBED green).
const GREEN_PART := "Do que te fortaleceu, parte perderás"
const GREEN_INK := Color("81e6a8")
const TEXT_PX := 13
## Creator 2026-11-23: losses as text ("-1 ATK"), from the 4 corners, in the angel's red.
## Placeholders for the creator's judgment: each label flies LOSS_FLIGHT s, the starts
## spread over the 3 s; size, the corner order and the point inside the angel.
const LOSS_FLIGHT := 1.5
const LOSS_PX := 14
const LOSS_TARGET := Vector2(W * 0.5, (FIGURE_TOP + FIGURE_BOTTOM) * 0.5)
const CORNERS: Array[Vector2] = [Vector2(16, 20), Vector2(W - 16, 20), Vector2(W - 16, H - 8), Vector2(16, H - 8)]
const STAT_NAMES := {"max_hp": "HP", "max_en": "EN", "atk": "ATK", "mak": "MAK", "defense": "DEF", "mef": "MEF", "agi": "AGI"}

## Stat gains lost to this death ({stat: amount}); set before the node enters the tree.
var losses: Dictionary = {}
var loss_labels: Array[Dictionary] = []
## Words of the line, laid out once: {"text", "pos", "start" (char index), "green"}.
var words: Array[Dictionary] = []
var label_font: SystemFont

var t := 0.0
var letters: Array[Dictionary] = []
var line := ""
var font: SystemFont
var rng := RandomNumberGenerator.new()
var _done := false
var figure_mask: Image
var figure_bbox := Rect2i()


func _ready() -> void:
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Tahoma", "Arial", "David Libre"])
	label_font = SystemFont.new()
	label_font.font_names = PackedStringArray(["Tahoma", "Arial", "sans-serif"])
	label_font.font_weight = 700
	rng.seed = 49
	line = LINE % _hebrew_word()
	_layout_words()
	_build_losses()
	var targets := _box_targets()
	targets.append_array(_silhouette_targets())
	targets.shuffle()
	var count := targets.size()
	var cols := int(W / 15.0)
	var rows := int(ceil(float(count) / cols))
	var row_h := (H - 20.0) / rows
	for i in count:
		var target: Dictionary = targets[i]
		letters.append({"glyph": ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)],
			"target": target.pos, "figure": target.figure,
			# Rows written right to left, top to bottom, on a regular grid.
			"rest": Vector2(W - 10 - (i % cols) * 15.0, 20 + (i / cols) * row_h),
			"appear": float(i) / count * (ENTER_END - 0.2),
			"fly_delay": rng.randf_range(0.0, 0.8),
			"scatter": Vector2.from_angle(rng.randf_range(0, TAU)) * rng.randf_range(60, 260),
			"scatter_delay": rng.randf_range(0.0, 0.5), "spin": rng.randf_range(-3.0, 3.0)})


## Word wrap of the line inside the box (the prologue's margins), so the green part can
## take its own colour.
func _layout_words() -> void:
	var green_from := line.find(GREEN_PART)
	var green_to := green_from + GREEN_PART.length()
	var left := BOX.position.x + 18
	var right := BOX.end.x - 18
	var pos := Vector2(left, BOX.position.y + 30)
	var space := font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, TEXT_PX).x
	var start := 0
	for piece in line.split(" "):
		var text := String(piece)
		# Green ends before the comma after "perderás".
		var green_len := clampi(green_to - start, 0, text.length()) if start >= green_from else 0
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, TEXT_PX).x
		if pos.x + width > right and pos.x > left:
			pos = Vector2(left, pos.y + font.get_height(TEXT_PX) + 3)
		# A Hebrew word drawn with its comma puts the comma on its left (bidi):
		# the punctuation becomes its own piece, drawn right after the word.
		var tail := ""
		if ALPHABET.contains(text.left(1)) and not ALPHABET.contains(text.right(1)):
			tail = text.right(1)
			text = text.left(text.length() - 1)
		words.append({"text": text, "pos": pos, "start": start, "green": green_len})
		if not tail.is_empty():
			var head_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, TEXT_PX).x
			words.append({"text": tail, "pos": pos + Vector2(head_w, 0), "start": start + text.length(), "green": 0, "joined": true})
		pos.x += width + space
		start += text.length() + tail.length() + 1


func _build_losses() -> void:
	var names: Array[String] = []
	for stat in ProgressStore.STAT_KEYS:
		if int(losses.get(stat, 0)) > 0:
			names.append("-%d %s" % [int(losses[stat]), STAT_NAMES[stat]])
	var gap := (LOSS_END - TEXT_END - LOSS_FLIGHT) / maxf(1.0, names.size() - 1)
	for i in names.size():
		loss_labels.append({"text": names[i], "from": CORNERS[i % CORNERS.size()],
			"start": TEXT_END + i * gap})


func _hebrew_word() -> String:
	var word := ""
	for i in rng.randi_range(3, 6):
		word += ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)]
	return word


func _box_targets() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var x := BOX.position.x
	while x <= BOX.end.x:
		out.append({"pos": Vector2(x, BOX.position.y), "figure": false})
		out.append({"pos": Vector2(x, BOX.end.y), "figure": false})
		x += BOX_STEP
	var y := BOX.position.y + BOX_STEP
	while y < BOX.end.y:
		out.append({"pos": Vector2(BOX.position.x, y), "figure": false})
		out.append({"pos": Vector2(BOX.end.x, y), "figure": false})
		y += BOX_STEP
	return out


func _silhouette_targets() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	figure_mask = (load(FIGURE_ART) as Texture2D).get_image()
	figure_bbox = figure_mask.get_used_rect()
	var k := (FIGURE_BOTTOM - FIGURE_TOP) / float(figure_bbox.size.y)
	var half_w := figure_bbox.size.x * k * 0.5
	var cx := W * 0.5
	var y := FIGURE_TOP
	while y <= FIGURE_BOTTOM:
		var x := cx - half_w
		while x <= cx + half_w:
			var px := figure_bbox.position + Vector2i(Vector2(x - (cx - half_w), y - FIGURE_TOP) / k)
			if _inside_figure(px):
				out.append({"pos": Vector2(x, y), "figure": true})
			x += SIL_STEP
		y += SIL_STEP
	return out


func _inside_figure(px: Vector2i) -> bool:
	if px.x < 0 or px.y < 0 or px.x >= figure_mask.get_width() or px.y >= figure_mask.get_height(): return false
	var c := figure_mask.get_pixelv(px)
	return c.a >= 0.5 and c.get_luminance() < 0.5


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if t >= END and not _done:
		_done = true
		finished.emit()


func _ease(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


func _draw() -> void:
	# The battle stays visible underneath and turns black during the 3 s of letters.
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, clampf(t / ENTER_END, 0.0, 1.0)))
	for letter in letters:
		var age: float = t - float(letter.appear)
		if age < 0.0: continue
		var pos: Vector2 = letter.rest
		var alpha := clampf(age / 0.35, 0.0, 1.0)
		var angle := 0.0
		var px := LETTER_PX
		if t >= ENTER_END:
			var f := _ease((t - ENTER_END - float(letter.fly_delay)) / (FLY_END - ENTER_END - 0.8))
			pos = (letter.rest as Vector2).lerp(letter.target, f)
			if letter.figure:
				px = lerpf(LETTER_PX, SIL_PX, f)
			alpha = 1.0
		if t >= LOSS_END:
			var s := clampf((t - LOSS_END - float(letter.scatter_delay)) / (SCATTER_END - LOSS_END - 0.5), 0.0, 1.0)
			pos = (letter.target as Vector2) + (letter.scatter as Vector2) * _ease(s)
			angle = float(letter.spin) * s
			alpha = 1.0 - s
		if alpha <= 0.0: continue
		draw_set_transform(pos, angle)
		draw_string(font, Vector2(-5, 5) * px / LETTER_PX, letter.glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, int(round(px)), Color(INK, alpha))
	draw_set_transform(Vector2.ZERO)
	_draw_text()
	_draw_losses()


## The angel's line, typed inside the formed box; GREEN_PART in green.
func _draw_text() -> void:
	if t < TEXT_START or t >= TEXT_END + 0.4: return
	var fade := 1.0 - clampf((t - TEXT_END) / 0.4, 0.0, 1.0)
	var budget := int((t - TEXT_START) * CHARS_PER_SECOND)
	for word in words:
		var shown := mini(String(word.text).length(), budget - int(word.start))
		if shown <= 0: break
		var text := String(word.text).substr(0, shown)
		var green := mini(int(word.green), shown)
		var pos: Vector2 = word.pos
		if green > 0:
			var head := text.substr(0, green)
			draw_string(font, pos, head, HORIZONTAL_ALIGNMENT_LEFT, -1, TEXT_PX, Color(GREEN_INK, fade))
			pos.x += font.get_string_size(head, HORIZONTAL_ALIGNMENT_LEFT, -1, TEXT_PX).x
			text = text.substr(green)
		if not text.is_empty():
			draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, TEXT_PX, Color(TEXT_INK, fade))


## The losses fly from the corners into the angel and vanish on arrival.
func _draw_losses() -> void:
	for label in loss_labels:
		var k := (t - float(label.start)) / LOSS_FLIGHT
		if k < 0.0 or k >= 1.0: continue
		var pos := (label.from as Vector2).lerp(LOSS_TARGET, _ease(k))
		var alpha := clampf(k / 0.15, 0.0, 1.0) * clampf((1.0 - k) / 0.2, 0.0, 1.0)
		var size := label_font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, LOSS_PX)
		draw_string(label_font, pos - Vector2(size.x * 0.5, -LOSS_PX * 0.35), label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, LOSS_PX, Color(INK, alpha))
