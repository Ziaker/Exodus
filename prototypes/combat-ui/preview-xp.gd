extends "res://prototypes/combat-ui/preview.gd"
## XP-inspired layout revision: 333/416 px reserved for the battlefield (80.05%).
## Commands are contextual. No rules or results beyond the UI preview are added.

const STAGE_HEIGHT := 333
const BACKGROUND_SOURCE := Rect2(48, 58, 448, 216)
const BACKGROUND_RECT := Rect2(48, 16.5, 448, 216)
const LOG_RECT := Rect2(0, 288, 544, 22)
const LOCAL_BATTLERS := [
    "res://assets/graphics/battle_sprites/Avatar Anubis.png",
    "res://assets/graphics/battle_sprites/Avatar Chimera.png",
]
const LOCAL_BACKGROUND := "res://assets/graphics/parallaxes/BB01-001.png"
var battler_textures: Array[Texture2D] = []
var battler_regions: Array[Rect2] = []
var background_texture: Texture2D


func _ready() -> void:
	# Local reference assets explicitly requested by the user. Sources stay unchanged.
	for path in LOCAL_BATTLERS:
		var texture := load(path) as Texture2D
		assert(texture != null, "Missing local battler: " + path)
		battler_textures.append(texture)
		# These local PNGs contain a baked two-pixel window frame, not enemy art.
		# Trim it in the source region, then measure only the transparent sprite interior.
		var image := texture.get_image()
		var interior := image.get_region(Rect2i(2, 2, image.get_width() - 4, image.get_height() - 4))
		var region := Rect2(interior.get_used_rect())
		region.position += Vector2(2, 2)
		battler_regions.append(region)
	background_texture = load(LOCAL_BACKGROUND) as Texture2D
	assert(background_texture != null, "Missing local battleback")
	mode = "idle"
	message = "Z / Enter: commands    Tab: ally    F: 2/4 foes    R: reset"
	super._ready()
	DisplayServer.window_set_title("Exodus — XP HUD interactive preview")


func _box(r: Rect2, active: bool = false) -> void:
	draw_rect(r, Color("252531f2"))
	draw_rect(r, Color("080b14"), false, 1)
	draw_rect(r.grow(-1), Color("b9b8c5"), false, 1)
	draw_rect(r.grow(-2), Color("515163"), false, 1)
	if active:
		draw_rect(r.grow(-4), Color("d5c7a4"), false, 1)


func _draw() -> void:
	if font == null:
		return
	hitboxes.clear()
	ink = Color("f0eadd")
	accent = Color("e8ca99")
	_world()
	_text(_round_caption(), 13, 24, Color("26191f"), 12)
	_text(_round_caption(), 12, 23, ink, 12)
	for i in enemy_count:
		var x := (168.0 + i * 208.0) if enemy_count == 2 else (104.0 + i * 112.0)
		_enemy(x, i)
	draw_rect(LOG_RECT, Color.BLACK)
	_text(message, 12, 303, Color("ece5d9"), 11)
	_sp_meter()
	_box(Rect2(0, STAGE_HEIGHT, 544, 83))
	_character(0, Rect2(6, 338, 264, 48))
	_character(1, Rect2(274, 338, 264, 48))
	draw_line(Vector2(272, 342), Vector2(272, 383), Color("62616d"))
	draw_line(Vector2(12, 388), Vector2(532, 388), Color("62616d"))
	_text(_footer_caption(), 12, 405, Color("cecad0"), 11)
	if mode == "command":
		_command_window()
	elif mode in ["timing", "absorb", "items", "react"]:
		_overlay()
	elif mode == "target":
		_text(_target_caption(), 236, 29, accent, 12)


func _world() -> void:
	# Original scene scale: source pixels map 1:1, including its original margins.
	draw_rect(Rect2(0, 0, 544, STAGE_HEIGHT), Color.BLACK)
	draw_texture_rect_region(background_texture, BACKGROUND_RECT, BACKGROUND_SOURCE)


func _round_caption() -> String:
	return "TURN 1"


func _target_caption() -> String:
	return "ENEMY " + char(65 + target)


func _footer_caption() -> String:
	return "Z / Enter: commands    Tab: ally    F: 2/4 foes    R: reset"


func _enemy_art_rect(x: float, region: Rect2) -> Rect2:
	# Preserve the pre-correction scale, measured against the full 185x190 PNG.
	# Removing its frame/transparent padding must not enlarge the remaining art.
	var limits := Vector2(188, 240) if enemy_count == 2 else Vector2(118, 218)
	var factor := minf(limits.x / 185.0, limits.y / 190.0)
	var art_size := region.size * factor
	# A common ground line inside the street, rather than inside the black letterbox.
	return Rect2(Vector2(x - art_size.x * 0.5, 217 - art_size.y), art_size)


func _enemy(x: float, index: int) -> void:
	var art_index := index % battler_textures.size()
	var region := battler_regions[art_index]
	var art_rect := _enemy_art_rect(x, region)
	var r := art_rect.grow(5)
	hitboxes.append({"rect": r, "key": "target:" + str(index)})
	draw_texture_rect_region(battler_textures[art_index], art_rect, region)
	if mode == "target" and index == target:
		var arrow_y := art_rect.position.y - 12
		draw_colored_polygon(PackedVector2Array([Vector2(x - 5, arrow_y), Vector2(x + 5, arrow_y), Vector2(x, arrow_y + 6)]), ink)
		for p in [r.position, r.position + Vector2(r.size.x, 0), r.position + Vector2(0, r.size.y), r.end]:
			var dx := 8 if p.x == r.position.x else -8
			var dy := 8 if p.y == r.position.y else -8
			draw_line(p, p + Vector2(dx, 0), accent, 1)
			draw_line(p, p + Vector2(0, dy), accent, 1)


func _sp_meter() -> void:
	draw_rect(Rect2(0, 310, 544, 23), Color("181622cc"))
	_text("SP", 10, 322, Color("ddd5ce"), 11)
	_text("PARTY", 33, 322, Color("ddd5ce"), 10)
	_text("ENEMY", 496, 322, Color("ddd5ce"), 10)
	draw_rect(Rect2(33, 325, 500, 4), Color("3c2830"))
	for i in 50:
		draw_rect(Rect2(34 + i * 10, 326, 9, 2), GREEN if i < 30 else RED)


func _character(who: int, r: Rect2) -> void:
	var x := r.position.x + 9
	_text(NAMES[who], x, 351, accent if who == actor else ink, 13)
	if who == actor:
		draw_colored_polygon(PackedVector2Array([Vector2(x - 7, 342), Vector2(x - 7, 349), Vector2(x - 3, 345.5)]), accent)
	_text("HP", x, 368, Color("a4c7b4"), 12)
	_text("XXX", x + 26, 368, ink, 13)
	_text("EN", x + 92, 368, Color("aebcd6"), 12)
	_text("XXX", x + 118, 368, ink, 13)
	_text("ACTS", x + 115, 351, Color("c4bec4"), 10)
	for i in 4:
		var pip := Rect2(x + 145 + i * 10, 344, 6, 6)
		if i < 2:
			draw_rect(pip, accent if who == actor else ink)
		else:
			draw_rect(pip, Color("827d8a"), false, 1)
	hitboxes.append({"rect": r, "key": "actor:" + str(who)})
	_text("[Z] COMMAND" if who == actor and mode == "idle" else "", x, 382, Color("b7b0b7"), 10)


func _command_window() -> void:
	var x := 8.0 if actor == 0 else 282.0
	var h: int = COMMANDS[actor].size() * 18 + 12
	var r := Rect2(x, STAGE_HEIGHT - h - 5, 112, h)
	# Modal menu consumes mouse input before the battlefield underneath.
	hitboxes.clear()
	_box(r)
	for j in COMMANDS[actor].size():
		var row := Rect2(x + 5, r.position.y + 6 + j * 18, 102, 18)
		if selected[actor] == j:
			draw_rect(row, Color("5c546d99"))
			draw_rect(row, Color("a7a0b466"), false, 1)
		_text(COMMANDS[actor][j].capitalize(), x + 16, row.position.y + 13, ink, 13)
		hitboxes.append({"rect": row, "key": "command:" + str(actor) + ":" + str(j)})


func _overlay() -> void:
	hitboxes.clear()
	# All contextual feedback stays at the bottom, leaving the battlers unobscured.
	_box(Rect2(4, 336, 536, 77))
	if mode == "timing":
		_text("STOP [Z / Enter]", 16, 353, ink, 12)
		var track := Rect2(16, 362, 512, 12)
		draw_rect(track, Color("51343f"))
		draw_rect(Rect2(195.2, 362, 153.6, 12), Color("a6905d"))
		draw_rect(Rect2(246.4, 362, 51.2, 12), GREEN)
		draw_rect(Rect2(16 + phase * 512, 359, 2, 18), ink)
		_text("Timing preview                              Esc: cancel", 16, 399, Color("c4bec4"), 11)
		hitboxes.append({"rect": Rect2(4, 336, 536, 77), "key": "confirm"})
	elif mode == "absorb":
		_text("ABSORB   Z / Enter: press    Esc: finish", 16, 358, ink, 12)
		_text("Presses: " + str(hits) + "   (input preview only)", 16, 383, accent, 12)
		hitboxes.append({"rect": Rect2(4, 336, 536, 77), "key": "confirm"})
	elif mode == "react":
		_text("Enemy A announces an attack.", 16, 358, ink, 12)
		_text("Z / Enter: react      Esc: pass", 16, 383, accent, 12)
		hitboxes.append({"rect": Rect2(4, 336, 536, 77), "key": "confirm"})
	else:
		_text("ITEMS   Inventory content is not defined.", 16, 358, ink, 12)
		_text("Esc: back", 16, 383, accent, 12)
		hitboxes.append({"rect": Rect2(4, 336, 536, 77), "key": "back"})


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB and mode in ["idle", "command"]:
			actor = 1 - actor
			queue_redraw()
			return
		if event.keycode in [KEY_UP, KEY_DOWN] and mode == "idle":
			mode = "command"
		# Theme comparisons are no longer in the game view.
		if event.keycode in [KEY_1, KEY_2, KEY_3]:
			return
	super._input(event)


func _dispatch(key: String) -> void:
	if key.begins_with("actor:") and mode == "idle":
		actor = int(key.split(":")[1])
		mode = "command"
	elif key == "back":
		if mode == "command":
			mode = "idle"
			message = "Z / Enter: commands    Tab: ally    F: 2/4 foes    R: reset"
		else:
			super._dispatch(key)
	elif key == "reset":
		super._dispatch(key)
		mode = "idle"
		message = "Z / Enter: commands    Tab: ally    F: 2/4 foes    R: reset"
	else:
		super._dispatch(key)
	queue_redraw()


func _confirm() -> void:
	if mode == "idle":
		mode = "command"
		message = NAMES[actor].capitalize() + ": choose a command."
	else:
		super._confirm()
		if mode == "command":
			mode = "idle"
		elif mode == "target":
			message = "Select target: Left / Right    Z: confirm    Esc: back"
	queue_redraw()


func _smoke() -> void:
	await get_tree().process_frame
	assert(STAGE_HEIGHT / 416.0 >= 0.8)
	assert(battler_textures.size() == 2 and battler_regions.size() == 2)
	assert(background_texture.get_width() == 544)
	for region in battler_regions:
		assert(region.has_area())
		assert(region.position.x >= 2 and region.position.y >= 2)
		assert(region.end.x <= 183 and region.end.y <= 188)
	assert(LOG_RECT.position.y >= BACKGROUND_RECT.end.y)
	assert(LOG_RECT.end.y <= 310)
	assert(BACKGROUND_RECT.size == BACKGROUND_SOURCE.size)
	for count in [2, 4]:
		enemy_count = count
		for i in count:
			var x: float = (168.0 + i * 208.0) if count == 2 else (104.0 + i * 112.0)
			var region := battler_regions[i % 2]
			var art_rect := _enemy_art_rect(x, region)
			assert(BACKGROUND_RECT.encloses(art_rect))
			var original_scale := 188.0 / 185.0 if count == 2 else 118.0 / 185.0
			assert(art_rect.size.is_equal_approx(region.size * original_scale))
	enemy_count = 2
	assert(mode == "idle")
	assert(hitboxes.size() == 4)
	_confirm(); assert(mode == "command")
	await get_tree().process_frame
	await get_tree().process_frame
	assert(hitboxes.size() == 5)
	for hit in hitboxes:
		assert(hit.rect.end.y <= STAGE_HEIGHT)
	_confirm(); assert(mode == "target")
	_dispatch("target:1"); assert(mode == "timing" and target == 1)
	phase = 0.5; _confirm(); assert(mode == "idle" and message.contains("POINT"))
	selected[0] = 1; _confirm(); _confirm(); assert(mode == "react")
	_confirm(); assert(mode == "timing")
	_dispatch("back"); _dispatch("back"); assert(mode == "idle")
	selected[0] = 2; _confirm(); _confirm(); _confirm(); assert(mode == "absorb")
	_confirm(); assert(hits == 1)
	_dispatch("reset")
	_dispatch("actor:1"); selected[1] = 2; _confirm(); assert(mode == "items")
	_dispatch("reset"); _dispatch("foes"); assert(enemy_count == 4)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(hitboxes.size() == 6)
	_dispatch("reset")
	print("HUD_XP_OK: 2 local SMT battlers + battleback loaded, 80% stage, contextual commands, 2/4 targets, timing, reaction, absorb, items")
	get_tree().quit()


func _capture_preview() -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var result := get_viewport().get_texture().get_image().save_png("res://prototypes/combat-ui/xp-live.png")
	assert(result == OK)
	print("HUD_XP_CAPTURE_OK")
