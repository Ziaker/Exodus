extends RhythmBar
## Same timing and input logic, fitted to the existing black gap above the log.

func _ready() -> void:
	position = Vector2(92, 234)
	size = Vector2(BAR_WIDTH, 52)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(BattleWidgets.window_frame(Vector2.ZERO, size))
	_label = BattleWidgets.styled_label("RHYTHM - Z / ENTER", 12, HORIZONTAL_ALIGNMENT_CENTER)
	_label.position = Vector2(0, 1)
	_label.size = Vector2(BAR_WIDTH, 18)
	add_child(_label)
	var track := ColorRect.new()
	track.color = TRACK_COLOR
	track.position = Vector2(10, 22)
	track.size = Vector2(BAR_WIDTH - 20, BAR_HEIGHT)
	add_child(track)
	# Keep the base zone references so configure() can resize POINT (D-034).
	_beam_left = _make_zone(0.35, 0.10, BEAM_COLOR)
	_point_zone = _make_zone(0.45, 0.10, POINT_COLOR)
	_beam_right = _make_zone(0.55, 0.10, BEAM_COLOR)
	for zone in [_beam_left, _point_zone, _beam_right]:
		zone.position.y = 22
	_layout_zones()
	_marker = ColorRect.new()
	_marker.color = MARKER_COLOR
	_marker.position = Vector2(10, 22)
	_marker.size = Vector2(4, BAR_HEIGHT)
	add_child(_marker)
	hide()
