class_name DialogueBox
extends Control

## Caixa de diálogo placeholder: só nome e texto, sem retrato, 3 linhas (D-055).
## Texto datilografado e página seguinte. Não usa o DialogueManager do projeto
## (autoload separado), para manter os protótipos independentes das decisões de
## narrativa pendentes.
##
## Estilo da exploração em primeira pessoa (D-054/D-055): a interface P&B do teste, com
## o nome na primeira linha da própria caixa; a caixa cobre o painel de baixo. (O estilo
## XP do mapa top-down saiu junto com o mapa, criador 2026-11-23.)
## Uma página mais longa que 3 linhas vira várias páginas, para nada ficar cortado.

signal opened
signal closed

## Linhas por página, tamanho do texto e passo entre linhas. D-055 pedia 3 linhas de 12 px;
## o criador (2026-11-23) mudou para 2 linhas de 20 px, com o nome no mesmo tamanho.
var lines_per_page := 2
var text_size := 20
var line_step := 30
## Linha de base do nome, a partir do topo da caixa.
const NAME_BASELINE := 30
const SCREEN := Vector2(816, 624)
## Mesmas fontes e tamanhos do HUD de batalha / painel do teste.
const MONO_INK := Color("f7f3ed")

var style := "mono"
## Janela da caixa (o dono define com use_mono antes de abrir).
var window_rect := Rect2(6, 502, 804, 116)
var font: Font
var bold: Font
var speaker := ""
var pages: Array[String] = []
var page_index := 0
var shown_chars := 0.0
var chars_per_second := 45.0
var is_open := false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = SCREEN
	_load_fonts()
	visible = false


func _load_fonts() -> void:
	var sys := SystemFont.new()
	sys.font_names = PackedStringArray(["Tahoma", "Arial", "sans-serif"])
	font = sys
	var sys_bold := SystemFont.new()
	sys_bold.font_names = sys.font_names
	sys_bold.font_weight = 700
	bold = sys_bold


## Troca para o estilo P&B da exploração em primeira pessoa, cobrindo `rect`.
func use_mono(rect: Rect2) -> void:
	style = "mono"
	window_rect = rect
	_load_fonts()


func open(p_speaker: String, p_pages: Array[String]) -> void:
	speaker = p_speaker
	pages.clear()
	for page in p_pages:
		var lines := wrap_text(page)
		if lines.is_empty():
			pages.append("")
		for i in range(0, lines.size(), lines_per_page):
			pages.append(" ".join(lines.slice(i, i + lines_per_page)))
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


func text_px() -> int:
	return text_size


func line_height() -> int:
	return line_step


## Nome na primeira linha, as 3 linhas de texto abaixo dele.
func text_origin() -> Vector2:
	return window_rect.position + Vector2(15, NAME_BASELINE + line_step)


func text_width() -> float:
	return window_rect.size.x - 30.0


func _draw() -> void:
	if not is_open or font == null:
		return
	_draw_mono()
	var lines := visible_lines()
	var origin := text_origin()
	var ink := MONO_INK
	for i in mini(lines.size(), lines_per_page):
		draw_string(font, origin + Vector2(0, i * line_height()), lines[i],
				HORIZONTAL_ALIGNMENT_LEFT, -1, text_px(), ink)
	if fully_shown():
		var tip := Vector2(window_rect.end.x - 20.0, window_rect.end.y - 14.0)
		draw_colored_polygon(PackedVector2Array([
			tip, tip + Vector2(9, 0), tip + Vector2(4.5, 6),
		]), ink)


## P&B do teste: fundo preto opaco e a mesma linha fina da moldura da vista 3D.
func _draw_mono() -> void:
	draw_rect(window_rect, Color.BLACK)
	draw_rect(Rect2(window_rect.position + Vector2(0.5, 0.5), window_rect.size - Vector2.ONE), Color(1, 1, 1, 0.58), false, 1)
	draw_string(bold, window_rect.position + Vector2(15, NAME_BASELINE), speaker,
			HORIZONTAL_ALIGNMENT_LEFT, -1, text_size, Color.WHITE)


## Linhas já datilografadas. A quebra é feita na página inteira, então uma palavra
## nunca pula de linha no meio da digitação.
func visible_lines() -> Array[String]:
	var out: Array[String] = []
	var left := int(shown_chars)
	for line in wrap_text(current_page()):
		if left <= 0:
			break
		out.append(line.substr(0, left))
		left -= line.length() + 1
	return out


## Quebra por largura em pixels da janela (não por número de letras).
func wrap_text(text: String) -> Array[String]:
	var lines: Array[String] = []
	if font == null:
		_load_fonts()
	var width := text_width()
	var current := ""
	for word in text.split(" ", false):
		var trial := word if current.is_empty() else current + " " + word
		if current.is_empty() or font.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, text_px()).x <= width:
			current = trial
		else:
			lines.append(current)
			current = word
	if not current.is_empty():
		lines.append(current)
	return lines
