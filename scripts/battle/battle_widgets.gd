class_name BattleWidgets
extends RefCounted

## Widgets de batalha desenhados inteiramente em codigo.
## Nenhum PNG de janela, cursor ou fonte da fangame: a unica arte permitida
## na cena e o oponente e o fundo. Cores reaproveitadas da implementacao anterior.

const PANEL_BG := Color(0.16, 0.17, 0.16, 1.0)
const BORDER_OUTER := Color(0.55, 0.56, 0.54, 1.0)
const BORDER_INNER := Color(0.30, 0.32, 0.30, 1.0)
const GAUGE_BG := Color(0.06, 0.08, 0.07, 1.0)
const TEXT_COLOR := Color(0.93, 0.94, 0.90)
const OUTLINE_COLOR := Color(0.0, 0.0, 0.0, 0.9)


static func window_frame(position: Vector2, size: Vector2) -> Control:
	var root := Control.new()
	root.position = position
	root.size = size
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var fill := ColorRect.new()
	fill.color = PANEL_BG
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(fill)

	_border(root, 0.0, 0.0, size.x, 2.0, BORDER_OUTER)
	_border(root, 0.0, size.y - 2.0, size.x, 2.0, BORDER_OUTER)
	_border(root, 0.0, 0.0, 2.0, size.y, BORDER_OUTER)
	_border(root, size.x - 2.0, 0.0, 2.0, size.y, BORDER_OUTER)
	_border(root, 2.0, 2.0, size.x - 4.0, 1.0, BORDER_INNER)
	_border(root, 2.0, size.y - 3.0, size.x - 4.0, 1.0, BORDER_INNER)
	_border(root, 2.0, 2.0, 1.0, size.y - 4.0, BORDER_INNER)
	_border(root, size.x - 3.0, 2.0, 1.0, size.y - 4.0, BORDER_INNER)
	return root


static func _border(parent: Control, x: float, y: float, w: float, h: float,
		color: Color) -> void:
	var line := ColorRect.new()
	line.color = color
	line.position = Vector2(x, y)
	line.size = Vector2(w, h)
	parent.add_child(line)


static func styled_label(text: String, font_size: int = 15,
		alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", 1)
	return label


static func gauge(width: float, height: float, color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, height)
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var back := ColorRect.new()
	back.color = GAUGE_BG
	panel.add_child(back)
	var fill := ColorRect.new()
	fill.color = color
	fill.name = "Fill"
	panel.add_child(fill)
	return panel


static func set_gauge(panel: PanelContainer, ratio: float) -> void:
	var fill := panel.get_node_or_null("Fill") as ColorRect
	if fill == null:
		return
	var usable := panel.size.x - 4.0
	fill.position = Vector2(2.0, 2.0)
	fill.size = Vector2(maxf(0.0, usable * clampf(ratio, 0.0, 1.0)), maxf(0.0, panel.size.y - 4.0))


static func opponent_texture(path: String) -> AtlasTexture:
	# As sprites temporarias deixaram uma borda opaca de 2 px da composicao
	# original. Recorta-se essa borda para que so o oponente apareca na cena.
	var texture: Texture2D = load(path)
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(2, 2, texture.get_width() - 4, texture.get_height() - 4)
	return atlas
