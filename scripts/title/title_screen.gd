extends Control
## Title screen modeled on RPG Maker XP's Scene_Title (proposal 1).
## Creator decisions (2026-11-21): black background + "EXODUS" text, no music,
## this scene is the game's main scene. Creator 2026-11-23: the top-down placeholder
## map was removed; New Game opens the first-person dungeon TEST (D-054/D-055).
## Geometry follows XP's default Scene_Title (192 px command window at y=288 on
## 640x480) scaled to this project's old 544x416 viewport. D-055 (816x624): the window,
## rows and fonts keep that size; only the positions follow XP's proportions on the new
## height (window at 288/480 of the screen, title halfway to it). Continue stays disabled
## until a save system exists (proposal 10), like XP with no Save*.rxdata files.

signal command_executed(command: String)

const GAME_TITLE := "EXODUS"
const COMMANDS := ["New Game", "Continue", "Survival", "Shutdown"]
const NEW_GAME_SCENE := "res://prototypes/dungeon-crawler/DungeonProto.tscn"
## Modo à parte, "for fun": não lê nem escreve o ProgressStore da campanha.
const SURVIVAL_SCENE := "res://scenes/survival/SurvivalWorld.tscn"
const SURVIVAL_INTRO_SCENE := "res://scenes/survival/SurvivalIntro.tscn"
const SCALE := 416.0 / 480.0
const WINDOW_WIDTH := 192.0 * SCALE
const ROW_HEIGHT := 32.0 * SCALE
const PADDING := 16.0 * SCALE
const SCREEN_HEIGHT := 624.0
const WINDOW_Y := 288.0 / 480.0 * SCREEN_HEIGHT
const FONT_PX := 18
const TITLE_PX := 48
const FADE_TIME := 20.0 / 40.0 # XP Graphics.transition default: 20 frames at 40 fps.
const INK := Color("ece9dc")
const DISABLED_INK := Color(0.93, 0.91, 0.86, 0.5) # XP disabled_color: alpha 128.
## Creator 2026-11-23: Fallen's deaths in Roman numerals, in the title font, #a8182a,
## 44 px, centred between the title and the command window (hidden before any death).
const DEATHS_PX := 44
const DEATHS_INK := Color("a8182a")

var font: FontFile
var index := 0
var busy := false
var fade_alpha := 0.0
var deaths := 0


func _ready() -> void:
	font = load("res://addons/gut/fonts/AnonymousPro-Bold.ttf").duplicate()
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	index = 1 if has_save() else 0
	deaths = ProgressStore.load_deaths()
	queue_redraw()


func has_save() -> bool:
	return false # No save system yet (proposal 10 pending).


func is_enabled(i: int) -> bool:
	return i != 1 or has_save()


func window_rect() -> Rect2:
	var height := ROW_HEIGHT * COMMANDS.size() + PADDING * 2.0
	# Rounded to whole pixels so the 1 px borders stay crisp with nearest filtering.
	var width := roundf(WINDOW_WIDTH)
	return Rect2(roundf((size.x - width) / 2.0), roundf(WINDOW_Y), width, roundf(height))


func row_rect(i: int) -> Rect2:
	var w := window_rect()
	return Rect2(w.position.x + PADDING - 4.0, w.position.y + PADDING + i * ROW_HEIGHT,
			w.size.x - PADDING * 2.0 + 8.0, ROW_HEIGHT)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
	var title_w := font.get_string_size(GAME_TITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_PX).x
	draw_string(font, Vector2((size.x - title_w) / 2.0, WINDOW_Y / 2.0 + TITLE_PX / 3.0),
			GAME_TITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_PX, INK)
	if deaths > 0:
		var numeral := roman(deaths)
		var numeral_w := font.get_string_size(numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, DEATHS_PX).x
		draw_string(font, Vector2((size.x - numeral_w) / 2.0, deaths_center_y() + DEATHS_PX / 3.0),
				numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, DEATHS_PX, DEATHS_INK)
	var w := window_rect()
	draw_rect(w, Color("252531f2"))
	draw_rect(w, Color("080b14"), false, 1)
	draw_rect(w.grow(-1), Color("b9b8c5"), false, 1)
	draw_rect(w.grow(-2), Color("515163"), false, 1)
	for i in COMMANDS.size():
		var r := row_rect(i)
		if i == index:
			draw_rect(r, Color("5c546d99"))
			draw_rect(r, Color("a7a0b466"), false, 1)
		var color := INK if is_enabled(i) else DISABLED_INK
		draw_string(font, Vector2(r.position.x + 8.0, r.position.y + ROW_HEIGHT / 2.0 + FONT_PX / 3.0),
				COMMANDS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_PX, color)
	if fade_alpha > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, fade_alpha))


## Midway between the title's baseline and the top of the command window.
func deaths_center_y() -> float:
	var title_baseline := WINDOW_Y / 2.0 + TITLE_PX / 3.0
	return (title_baseline + window_rect().position.y) / 2.0


static func roman(n: int) -> String:
	var values := [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
	var symbols := ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]
	var out := ""
	for i in values.size():
		while n >= values[i]:
			out += symbols[i]
			n -= values[i]
	return out


func move_cursor(step: int) -> void:
	if busy:
		return
	index = wrapi(index + step, 0, COMMANDS.size())
	queue_redraw()


func confirm() -> void:
	if busy or not is_enabled(index):
		return
	busy = true
	var command: String = COMMANDS[index]
	command_executed.emit(command)
	var tween := create_tween()
	tween.tween_method(_set_fade, 0.0, 1.0, FADE_TIME)
	await tween.finished
	match command:
		"New Game":
			get_tree().change_scene_to_file(NEW_GAME_SCENE)
		"Survival":
			# Retoma a run salva; NEW RUN no santuário começa do zero.
			var resumed := SurvivalState.load_from_file()
			if not resumed:
				SurvivalState.reset()
			# Meta-unlocks são relíquias; a run em si continua isolada.
			for id in SurvivalMeta.data().get("unlocked", []):
				SurvivalState.grant_relic(String(id))
			# Run nova: cutscene de entrada do Kazfiel antes do mapa (criador 2026-11-27).
			get_tree().change_scene_to_file(SURVIVAL_SCENE if resumed else SURVIVAL_INTRO_SCENE)
		"Shutdown":
			get_tree().quit()


func _set_fade(value: float) -> void:
	fade_alpha = value
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		move_cursor(-1)
	elif event.is_action_pressed("ui_down"):
		move_cursor(1)
	elif event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed
			and not event.echo and event.keycode == KEY_Z):
		confirm()
	elif event is InputEventMouseMotion or (event is InputEventMouseButton and event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT):
		for i in COMMANDS.size():
			if row_rect(i).has_point(event.position):
				if i != index:
					index = i
					queue_redraw()
				if event is InputEventMouseButton:
					confirm()
				break
