extends RhythmBar
## Same timing and input logic as RhythmBar, drawn as the HTML lab rails:
## "attack" = thin line over the target enemy, "defense" = line inside the defender panel.
## The base zone/marker nodes stay (hidden) so configure()/_finish() keep their contract.

var style := "attack"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = BattleWidgets.styled_label("RHYTHM - Z / ENTER", 12, HORIZONTAL_ALIGNMENT_CENTER)
	_label.visible = false
	add_child(_label)
	_beam_left = _make_zone(0.35, 0.10, BEAM_COLOR)
	_point_zone = _make_zone(0.45, 0.10, POINT_COLOR)
	_beam_right = _make_zone(0.55, 0.10, BEAM_COLOR)
	_layout_zones()
	_marker = ColorRect.new()
	_marker.position = Vector2(10, 28)
	_marker.size = Vector2(4, BAR_HEIGHT)
	add_child(_marker)
	for node in [_beam_left, _point_zone, _beam_right, _marker]:
		node.visible = false
	hide()


## Places the rail; called before start() by the playable controller.
func place(rect: Rect2, kind: String) -> void:
	position = rect.position
	size = rect.size
	style = kind
	queue_redraw()


func progress() -> float:
	return clampf(_elapsed / maxf(duration, 0.001), 0.0, 1.0)


## Zone spans as fractions of the rail: [beam left, point, beam right].
func zone_spans() -> Array[Vector2]:
	var half := _point_half_width
	var beam := BattleMath.BEAM_HALF_WIDTH
	var spans: Array[Vector2] = [Vector2(0.5 - beam, 0.5 - half), Vector2(0.5 - half, 0.5 + half), Vector2(0.5 + half, 0.5 + beam)]
	return spans


func _process(delta: float) -> void:
	super._process(delta)
	queue_redraw()


func _draw() -> void:
	var beam_color := Color("d0aa64")
	var point_color := Color("80df9c")
	var w := size.x
	if style == "defense":
		# .game .defense-rail: 1px frame, track top 2 h 4, zones top 3 h 2, cursor top -2 h 12.
		draw_rect(Rect2(Vector2.ZERO, size), Color("100a0d"))
		draw_rect(Rect2(Vector2(0.5, 0.5), size - Vector2.ONE), Color(1, 1, 1, 0.72), false, 1)
		var inner := w - 2.0
		_track(Rect2(1, 3, inner, 4), Color(1, 1, 1, 0.7))
		var spans := zone_spans()
		for i in 3:
			draw_rect(Rect2(1 + inner * spans[i].x, 4, inner * (spans[i].y - spans[i].x), 2), point_color if i == 1 else beam_color)
		_cursor(Rect2(1 + inner * progress() - 2, -1, 2, 12))
	else:
		# .attack-rail: drop-shadow(0 1px 2px #111); track top 4 h 5, zones top 5 h 3, cursor h 13.
		draw_rect(Rect2(0, 5, w, 5), Color("111111", 0.6))
		_track(Rect2(0, 4, w, 5), Color(1, 1, 1, 0.65))
		var spans := zone_spans()
		for i in 3:
			draw_rect(Rect2(w * spans[i].x, 5, w * (spans[i].y - spans[i].x), 3), point_color if i == 1 else beam_color)
		_cursor(Rect2(w * progress() - 2, 0, 2, 13))


func _track(r: Rect2, border: Color) -> void:
	draw_rect(r, Color(0, 0, 0, 0.7))
	draw_rect(Rect2(r.position + Vector2(0.5, 0.5), r.size - Vector2.ONE), border, false, 1)


func _cursor(r: Rect2) -> void:
	draw_rect(r.grow(1), Color(1, 1, 1, 0.3))
	draw_rect(r, Color("fffaf0"))
