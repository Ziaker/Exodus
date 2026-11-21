class_name BattleWidgets
extends RefCounted

## VX Ace-style widgets built from the fangame's temporary assets.

const WINDOW_SKIN := "res://assets/graphics/system/Window.png"
const CURSOR_SKIN := "res://assets/graphics/system/Window.png"
const FONT_PATH := "res://assets/fonts/msgothic.ttf"

static func window_frame(position: Vector2, size: Vector2) -> NinePatchRect:
	var frame := NinePatchRect.new()
	frame.texture = load(WINDOW_SKIN)
	frame.region_rect = Rect2(0, 0, 128, 128)
	frame.patch_margin_left = 16
	frame.patch_margin_top = 16
	frame.patch_margin_right = 16
	frame.patch_margin_bottom = 16
	frame.position = position
	frame.size = size
	return frame

static func make_font(size: int) -> FontFile:
	var font: FontFile = load(FONT_PATH)
	# FontFile is shared; sizing is done per-control via theme overrides.
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

static func cursor_icon() -> TextureRect:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(CURSOR_SKIN)
	atlas.region = Rect2(65, 65, 54, 54)
	var rect := TextureRect.new()
	rect.texture = atlas
	rect.custom_minimum_size = Vector2(18, 18)
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	return rect

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
