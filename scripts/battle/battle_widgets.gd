class_name BattleWidgets
extends RefCounted

## VX Ace-style widgets built from the fangame's temporary assets.

const WINDOW_SKIN := "res://assets/graphics/system/Window.png"
const FONT_PATH := "res://assets/fonts/msgothic.ttf"

static func window_frame(position: Vector2, size: Vector2) -> Control:
	# Window.png is a 2x2 atlas of 64x64 sheets. The top-left sheet is the
	# dark-green window fill; the frame itself is drawn here so the cursor
	# and palette in the other sheets never leak into the UI.
	var root := Control.new()
	root.position = position
	root.size = size
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var fill_atlas := AtlasTexture.new()
	fill_atlas.atlas = load(WINDOW_SKIN)
	fill_atlas.region = Rect2(0, 0, 64, 64)
	var fill := TextureRect.new()
	fill.texture = fill_atlas
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fill.stretch_mode = TextureRect.STRETCH_SCALE
	root.add_child(fill)

	var outer := Color(0.55, 0.56, 0.54, 1.0)
	var inner := Color(0.16, 0.17, 0.16, 1.0)
	_border(root, 0.0, 0.0, size.x, 2.0, outer)
	_border(root, 0.0, size.y - 2.0, size.x, 2.0, outer)
	_border(root, 0.0, 0.0, 2.0, size.y, outer)
	_border(root, size.x - 2.0, 0.0, 2.0, size.y, outer)
	_border(root, 2.0, 2.0, size.x - 4.0, 1.0, inner)
	_border(root, 2.0, size.y - 3.0, size.x - 4.0, 1.0, inner)
	_border(root, 2.0, 2.0, 1.0, size.y - 4.0, inner)
	_border(root, size.x - 3.0, 2.0, 1.0, size.y - 4.0, inner)
	return root


static func _border(parent: Control, x: float, y: float, w: float, h: float,
		color: Color) -> void:
	var line := ColorRect.new()
	line.color = color
	line.position = Vector2(x, y)
	line.size = Vector2(w, h)
	parent.add_child(line)


static func make_font(size: int) -> FontFile:
	var font: FontFile = load(FONT_PATH)
	return font


static func styled_label(text: String, font_size: int = 15,
		alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.add_theme_font_override("font", make_font(font_size))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.93, 0.94, 0.90))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 1)
	return label


static func gauge(width: float, height: float, color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, height)
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var back := ColorRect.new()
	back.color = Color(0.06, 0.08, 0.07, 1.0)
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


static func pose_texture(path: String) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(path)
	atlas.region = Rect2(0, 0, 62, 190)
	return atlas


static func face_texture(path: String, index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(path)
	var column := index % 4
	var row := index / 4
	atlas.region = Rect2(column * 96, row * 96, 96, 96)
	return atlas
