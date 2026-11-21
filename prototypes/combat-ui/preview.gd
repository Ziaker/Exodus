extends Control
## Standalone interactive art-direction preview. No battle rules or project settings mutated.
## Results are illustrative UI states, never calculated combat outcomes.

const COMMANDS := [["ACT", "REACT", "ABSORB", "ITEMS", "REST"], ["ACT", "REACT", "ITEMS", "REST"]]
const NAMES := ["FALLEN", "ALLY"]
const OPTIONS := ["1 CLASSIC", "2 RITUAL", "3 GRAPHIC"]
const GREEN := Color("35ba75")
const RED := Color("ed5353")
const SPRITE := [
	".......aa...............",
	"......abba..............",
	".....abbba..............",
	".....abbba..............",
	"....abbcbba.............",
	"....abcccbba............",
	"...abceecbba............",
	"...abcccccbba...........",
	"....abcccbba............",
	"...aabbbbbaa............",
	"..abdbbbbd bba..........",
	".abddbbbbdddbba.........",
	"abdddbbbdbdddbba........",
	".abdbbbbdbbdbba.........",
	"..abbbbbdbbbba..........",
	"..abdbbbdbdbba..........",
	"..abdbbbdbdbba..........",
	".abddbbbdbdddbba........",
	".abddbbbdbdddbba........",
	"abdddbbbdbdddbbba.......",
	"abbddbbbdbdddbbbba......",
	"abbbbbbbdbbbbbbbba......",
	".aaaaaaaaaaaaaaaa.......",
]

var option := 1
var actor := 0
var selected := [0, 0]
var target := 0
var mode := "command"
var message := "Fallen: choose a command."
var phase := 0.0
var hits := 0
var enemy_count := 2
var font: FontFile
var hitboxes: Array[Dictionary] = []
var clock := 0.0
var paper := Color("ded9c6")
var ink := Color("ece9dc")
var panel := Color("20232c")
var edge := Color("a5a9b3")
var accent := Color("eaba80")


func _ready() -> void:
	font = load("res://addons/gut/fonts/AnonymousPro-Bold.ttf").duplicate()
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	DisplayServer.window_set_title("EXODUS — Interactive HUD proposals")
	queue_redraw()
	if "--preview-smoke" in OS.get_cmdline_user_args():
		call_deferred("_smoke")
	elif "--preview-capture" in OS.get_cmdline_user_args():
		call_deferred("_capture_preview")


func _process(delta: float) -> void:
	clock += delta
	if mode == "timing":
		phase = fmod(phase + delta * 0.65, 1.0)
	queue_redraw()


func _text(value: String, x: float, y: float, color: Color = Color.WHITE, px: int = 13) -> void:
	draw_string(font, Vector2(x, y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)


func _box(r: Rect2, active: bool = false) -> void:
	draw_rect(r, panel)
	if option == 0:
		draw_rect(r, Color("080a10"), false, 2)
		draw_rect(r.grow(-2), edge, false, 2)
		draw_rect(r.grow(-4), Color("515764"), false, 1)
		draw_line(r.position + Vector2(4, 4), r.position + Vector2(r.size.x - 4, 4), Color("e2dfcf"))
	elif option == 1:
		draw_rect(r, edge, false, 1)
	else:
		draw_rect(r, edge, false, 2)
	if active:
		draw_rect(Rect2(r.position + Vector2(5, 5), Vector2(3, r.size.y - 10)), accent)


func _button(r: Rect2, title: String, key: String, active: bool = false) -> void:
	_box(r, active)
	_text(title, r.position.x + 9, r.position.y + r.size.y * 0.5 + 4, accent if active else ink, 12)
	hitboxes.append({"rect": r, "key": key})


func _draw() -> void:
	if font == null:
		return
	hitboxes.clear()
	match option:
		0:
			panel = Color("20232c"); ink = Color("ece9dc"); edge = Color("a5a9b3"); accent = Color("eaba80")
		1:
			panel = paper; ink = Color("2a1419"); edge = Color("4d2229"); accent = Color("a3303f")
		2:
			panel = Color("e9e7de"); ink = Color("141419"); edge = Color("141419"); accent = Color("bc293c")
	draw_rect(Rect2(0, 0, 544, 416), Color("101017"))
	for i in 3:
		_button(Rect2(4 + i * 133, 3, 130, 23), OPTIONS[i], "theme:" + str(i), option == i)
	_button(Rect2(405, 3, 135, 23), "RESET [R]", "reset")
	_world()
	_box(Rect2(6, 31, 76, 24))
	_text("TURN 1", 16, 47, ink)
	_button(Rect2(416, 31, 122, 24), "2 / 4 FOES [F]", "foes")
	for i in enemy_count:
		var x := (166.0 + i * 212.0) if enemy_count == 2 else (78.0 + i * 130.0)
		_enemy(x, i)
	_sp_meter()
	_box(Rect2(6, 220, 532, 30))
	_text(message, 17, 239, ink, 12)
	_character(0, Rect2(6, 255, 171, 133))
	_character(1, Rect2(181, 255, 152, 133))
	_box(Rect2(337, 255, 30, 133))
	_text("SP", 344, 272, ink, 12)
	draw_rect(Rect2(346, 280, 12, 97), Color("371a24"))
	for i in 12:
		draw_rect(Rect2(347, 282 + i * 8, 10, 6), RED if i < 5 else GREEN)
	_context()
	_text("DEMO UI  |  TAB ally  Arrows move  Z/Enter confirm  Esc back", 8, 405, Color("bcb8b0"), 11)
	if mode in ["timing", "absorb", "items"]:
		_overlay()


func _world() -> void:
	var sky := Color("55252d") if option != 2 else Color("18181f")
	draw_rect(Rect2(0, 29, 544, 166), sky)
	if option == 0:
		for y in range(60, 168, 12):
			for x in range(0, 544, 16):
				if (x / 16 + y / 12) as int % 4 == 0:
					draw_rect(Rect2(x, y, 8, 2), Color("612a32"))
	elif option == 1:
		for radius in [50.0, 82.0, 114.0, 146.0]:
			draw_arc(Vector2(272, 166), radius, PI, TAU, 40, Color("996451"), 1)
	draw_rect(Rect2(0, 170, 544, 25), Color("a7988c") if option == 0 else paper)
	for x in range(0, 544, 8):
		var h := int(7 + sin(x * 0.04) * 5)
		draw_rect(Rect2(x, 170 - h, 8, h), Color("c8bdb0") if option == 0 else paper)
	if option == 0:
		for x in range(0, 544, 12):
			draw_rect(Rect2(x, 179 + int(x / 12) % 3 * 3, 4, 1), Color("786575"))


func _enemy(x: float, index: int) -> void:
	var sc := 3.0 if enemy_count == 2 else 2.5
	var r := Rect2(x - 34, 70, 68, 115)
	hitboxes.append({"rect": r, "key": "target:" + str(index)})
	var colors := {"a": Color("221d28"), "b": Color("71616e"), "c": Color("302734"), "d": Color("c1b0a0"), "e": Color("ffbb85")}
	for y in SPRITE.size():
		for col in SPRITE[y].length():
			var ch: String = SPRITE[y][col]
			if not colors.has(ch):
				continue
			var c: Color = colors[ch]
			if option == 1:
				c = Color("251b22") if ch != "e" else paper
			elif option == 2:
				c = Color("dfddd3") if ch in ["a", "d", "e"] else Color("18181f")
			draw_rect(Rect2(x - 31 + col * sc, 86 + y * sc, sc, sc), c)
	_text("ENEMY " + char(65 + index), x - 25, 186, Color("f4e7d5"), 11)
	if target == index:
		for p in [r.position, r.position + Vector2(r.size.x, 0), r.position + Vector2(0, r.size.y - 3), r.end - Vector2(0, 3)]:
			var dx := 10 if p.x == r.position.x else -10
			var dy := 10 if p.y == r.position.y else -10
			draw_line(p, p + Vector2(dx, 0), RED, 2)
			draw_line(p, p + Vector2(0, dy), RED, 2)


func _sp_meter() -> void:
	_box(Rect2(6, 195, 532, 22))
	_text("PARTY", 15, 210, ink, 11)
	_text("ENEMY", 490, 210, ink, 11)
	for i in 30:
		draw_rect(Rect2(59 + i * 14, 202, 12, 8), GREEN if i < 18 else RED)


func _character(who: int, r: Rect2) -> void:
	_box(r, actor == who)
	var x := r.position.x + 12
	var y := r.position.y
	_text(NAMES[who], x, y + 18, accent if actor == who else ink, 14)
	_text("HP  XXX  EN  XXX", x, y + 34, ink, 11)
	_text("ACTS", x, y + 48, ink, 11)
	for i in 4:
		var pip := Rect2(x + 35 + i * 11, y + 40, 7, 7)
		if i < 2:
			draw_rect(pip, ink)
		else:
			draw_rect(pip, ink, false, 1)
	for j in COMMANDS[who].size():
		var line := Rect2(x - 3, y + 53 + j * 14, r.size.x - 20, 14)
		var is_selected: bool = actor == who and selected[who] == j
		if is_selected:
			if option != 0:
				draw_rect(line, accent)
			else:
				draw_colored_polygon(PackedVector2Array([Vector2(x, line.position.y + 3), Vector2(x + 5, line.position.y + 7), Vector2(x, line.position.y + 11)]), ink)
		_text(COMMANDS[who][j], x + 12, line.position.y + 11, Color.WHITE if is_selected and option != 0 else ink, 12)
		hitboxes.append({"rect": line, "key": "command:" + str(who) + ":" + str(j)})


func _context() -> void:
	_box(Rect2(371, 255, 167, 133))
	var command: String = COMMANDS[actor][selected[actor]]
	_text(command, 383, 274, accent, 14)
	var lines: Array = {
		"ACT": ["Select an enemy.", "Then test timing."],
		"REACT": ["Preview an enemy", "announcement and", "reaction timing."],
		"ABSORB": ["Select an enemy.", "Mash Z / Enter."],
		"ITEMS": ["Open item menu.", "Preview only."],
		"REST": ["Preview rest", "confirmation."],
	}[command]
	for i in lines.size():
		_text(lines[i], 383, 294 + i * 14, ink, 11)
	_button(Rect2(382, 352, 145, 25), "CONFIRM [Z]", "confirm")
	if mode == "target":
		_text("CHOOSE TARGET", 383, 337, accent, 11)
	elif mode == "react":
		_text("REACT / ESC PASS", 383, 337, accent, 11)


func _overlay() -> void:
	hitboxes.clear()
	draw_rect(Rect2(0, 29, 544, 359), Color(0, 0, 0, 0.7))
	_box(Rect2(58, 105, 428, 161), true)
	if mode == "timing":
		_text("REACTION TIMING" if message.begins_with("Enemy") else "ATTACK TIMING", 78, 129, ink, 15)
		_text("Press Z / Enter or click STOP", 78, 151, ink, 12)
		draw_rect(Rect2(80, 171, 384, 22), Color("5a3038"))
		draw_rect(Rect2(214, 171, 116, 22), Color("ab955f"))
		draw_rect(Rect2(253, 171, 38, 22), GREEN)
		draw_rect(Rect2(80 + phase * 384, 166, 3, 32), Color.WHITE)
		_button(Rect2(184, 220, 176, 28), "STOP [Z / ENTER]", "confirm")
	elif mode == "absorb":
		_text("ABSORB — INPUT PREVIEW", 78, 133, ink, 15)
		_text("Mash Z / Enter. Press Esc to finish.", 78, 157, ink, 12)
		_text("PRESSES: " + str(hits), 78, 184, accent, 16)
		_button(Rect2(80, 217, 182, 29), "ABSORB [Z]", "confirm")
		_button(Rect2(276, 217, 187, 29), "FINISH [ESC]", "back")
	else:
		_text("ITEMS — MENU PREVIEW", 78, 133, ink, 15)
		_text("Inventory content is not defined.", 78, 161, ink, 12)
		_text("No items or costs simulated.", 78, 183, ink, 12)
		_button(Rect2(185, 218, 174, 29), "BACK [ESC]", "back")


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for hit in hitboxes:
			if hit.rect.has_point(get_local_mouse_position()):
				if mode in ["timing", "absorb", "items"] and hit.key not in ["confirm", "back"]:
					continue
				_dispatch(hit.key)
				break
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_2, KEY_3: _dispatch("theme:" + str(event.keycode - KEY_1))
			KEY_R: _dispatch("reset")
			KEY_F: _dispatch("foes")
			KEY_TAB:
				if mode == "command":
					actor = 1 - actor
					message = NAMES[actor].capitalize() + ": choose a command."
			KEY_UP, KEY_DOWN:
				if mode == "command":
					selected[actor] = posmod(selected[actor] + (1 if event.keycode == KEY_DOWN else -1), COMMANDS[actor].size())
			KEY_LEFT, KEY_RIGHT:
				if mode == "target":
					target = posmod(target + (1 if event.keycode == KEY_RIGHT else -1), enemy_count)
			KEY_Z, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE: _dispatch("confirm")
			KEY_ESCAPE: _dispatch("back")
	queue_redraw()


func _dispatch(key: String) -> void:
	var parts := key.split(":")
	match parts[0]:
		"theme":
			option = int(parts[1])
		"reset":
			actor = 0; selected = [0, 0]; target = 0; mode = "command"; hits = 0
			message = "Fallen: choose a command."
		"foes":
			enemy_count = 4 if enemy_count == 2 else 2
			target = mini(target, enemy_count - 1)
		"target":
			target = int(parts[1])
			if mode == "target":
				_confirm()
		"command":
			if mode != "command":
				return
			var who := int(parts[1])
			var item := int(parts[2])
			var again: bool = actor == who and selected[who] == item
			actor = who; selected[who] = item
			message = NAMES[actor].capitalize() + ": choose a command."
			if again:
				_confirm()
		"confirm": _confirm()
		"back":
			if mode == "absorb":
				message = "Input preview: %d presses. No rewards applied." % hits
			else:
				message = NAMES[actor].capitalize() + ": choose a command."
			mode = "command"
	queue_redraw()


func _confirm() -> void:
	match mode:
		"timing":
			var result := "POINT" if absf(phase - 0.5) <= 0.05 else ("BEAM" if absf(phase - 0.5) <= 0.15 else "MISS")
			message = "Timing: " + result + ". Preview only; no damage applied."
			mode = "command"
		"absorb": hits += 1
		"items": pass
		"react":
			mode = "timing"; phase = 0
		"target":
			if COMMANDS[actor][selected[actor]] == "ABSORB":
				mode = "absorb"; hits = 0
			else:
				mode = "timing"; phase = 0
		"command":
			match COMMANDS[actor][selected[actor]]:
				"ACT", "ABSORB":
					mode = "target"
					message = "Select enemy: arrows / click. Confirm: Z / Enter."
				"REACT":
					mode = "react"
					message = "Enemy A announces an attack. Z: react / Esc: pass."
				"ITEMS": mode = "items"
				"REST": message = "Rest selected. Preview only; no resources changed."


func _smoke() -> void:
	for i in 3:
		_dispatch("theme:" + str(i))
		assert(option == i)
		await get_tree().process_frame
		assert(hitboxes.size() >= 17)
	_dispatch("reset")
	_confirm(); assert(mode == "target")
	_dispatch("target:1"); assert(mode == "timing" and target == 1)
	phase = 0.5; _confirm(); assert(message.contains("POINT"))
	selected[0] = 1; _confirm(); assert(mode == "react")
	_confirm(); assert(mode == "timing")
	_dispatch("back")
	selected[0] = 2; _confirm(); _confirm(); assert(mode == "absorb")
	_confirm(); assert(hits == 1)
	_dispatch("back"); assert(mode == "command")
	actor = 1; selected[1] = 2; _confirm(); assert(mode == "items")
	_dispatch("back")
	_dispatch("foes"); assert(enemy_count == 4)
	_dispatch("reset")
	print("HUD_PREVIEW_OK: 3 themes, targets, timing, reaction, absorb, items, reset")
	get_tree().quit()


func _capture_preview() -> void:
	for i in 3:
		option = i
		queue_redraw()
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var output := "res://prototypes/combat-ui/live-option-%d.png" % (i + 1)
		var result := get_viewport().get_texture().get_image().save_png(output)
		assert(result == OK)
	option = 1
	queue_redraw()
	print("HUD_PREVIEW_CAPTURE_OK")
