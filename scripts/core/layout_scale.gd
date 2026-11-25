extends RefCounted
## Creator 2026-11-24 (fixes D-055): scenes laid out at 544 x 416 (battles, their death
## cutscene, the angel prologue) are shown 1.5x on the 816 x 624 screen. While such a scene
## is in the tree the window's content scale uses its layout size, fractional, so the
## 816 x 624 window shows it 1.5x and text is rendered at the real size (sharp).
##
## All three stretch keys are applied at RUNTIME, not just read from project.godot: an
## editor instance started before the project setting changed would otherwise keep the
## old integer mode and CLIP the right edge of the log box and the command panels when
## the window is smaller than 816 px (the creator's screenshot, 732 px wide). Keep mode,
## aspect and stretch fractional for the whole session so no scene is ever cropped.

const LAYOUT_544 := Vector2i(544, 416)


static func use(window: Window, layout: Vector2i = LAYOUT_544) -> Dictionary:
	if window == null: return {}
	var saved := {"size": window.content_scale_size}
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	window.content_scale_size = layout
	return saved


static func restore(window: Window, saved: Dictionary) -> void:
	if saved.is_empty() or window == null: return
	window.content_scale_size = saved.size
	# Keep the safe (fractional) stretch for the rest of the session.
	window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
