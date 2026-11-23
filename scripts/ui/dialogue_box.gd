class_name DialogueBox
extends Control

## Janela de diálogo placeholder no estilo RPG Maker XP: nome, texto datilografado
## e página seguinte. Não usa o DialogueManager do projeto (autoload separado),
## para manter o protótipo de mapa independente das decisões de narrativa pendentes.

signal opened
signal closed

const WINDOW := Rect2(0, 336, 544, 80)
const NAME_WINDOW := Rect2(16, 312, 176, 24)
const TEXT_ORIGIN := Vector2(26, 351)
const MAX_CHARS := 58
const LINE_HEIGHT := 19

var font: FontFile
var speaker := ""
var pages: Array[String] = []
var page_index := 0
var shown_chars := 0.0
var chars_per_second := 45.0
var is_open := false


func _ready() -> void:
	font = load("res://addons/gut/fonts/AnonymousPro-Bold.ttf") as FontFile
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visible = false


func open(p_speaker: String, p_pages: Array[String]) -> void:
	speaker = p_speaker
	pages = p_pages.duplicate()
	if pages.is_empty():
		pages.append("")
	page_index = 0
	shown_chars = 0.0
	is_open = true
	visible = true
	opened.emit()
	queue_redraw()


func current_page() -> String:
	return pages[clampi(page_index, 0, pages.size() - 1)]


func fully_shown() -> bool:
	return shown_chars >= float(current_page().length())


func advance() -> void:
	if not is_open:
		return
	if not fully_shown():
		shown_chars = float(current_page().length())
	elif page_index + 1 < pages.size():
		page_index += 1
		shown_chars = 0.0
	else:
		is_open = false
		visible = false
		closed.emit()
	queue_redraw()


func process_text(delta: float) -> void:
	if not is_open or fully_shown():
		return
	shown_chars = minf(float(current_page().length()), shown_chars + chars_per_second * delta)
	queue_redraw()


func _draw() -> void:
	if not is_open:
		return
	_frame(WINDOW)
	_frame(NAME_WINDOW)
	if font == null:
		return
	draw_string(font, NAME_WINDOW.position + Vector2(8, 16), speaker,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("f2d37c"))
	var text := current_page().substr(0, int(shown_chars))
	var lines := _wrap(text)
	for i in mini(lines.size(), 3):
		draw_string(font, TEXT_ORIGIN + Vector2(0, i * LINE_HEIGHT), lines[i],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("ece9dc"))
	if fully_shown():
		var tip := Vector2(WINDOW.end.x - 20.0, WINDOW.end.y - 14.0)
		draw_colored_polygon(PackedVector2Array([
			tip, tip + Vector2(9, 0), tip + Vector2(4.5, 6),
		]), Color("ece9dc"))


func _frame(r: Rect2) -> void:
	draw_rect(r, Color("12121f"))
	draw_rect(r, Color("05060b"), false, 1)
	draw_rect(r.grow(-1), Color("b9b8c5"), false, 1)
	draw_rect(r.grow(-2), Color("515163"), false, 1)


func _wrap(text: String) -> Array[String]:
	var lines: Array[String] = []
	var current := ""
	for word in text.split(" ", false):
		if current.is_empty():
			current = word
		elif current.length() + 1 + word.length() <= MAX_CHARS:
			current += " " + word
		else:
			lines.append(current)
			current = word
	if not current.is_empty():
		lines.append(current)
	return lines
