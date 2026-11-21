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
	for zone in [Vector3(0.35, 0.1, 0), Vector3(0.45, 0.1, 1), Vector3(0.55, 0.1, 0)]:
		var control := _make_zone(zone.x, zone.y, POINT_COLOR if zone.z == 1 else BEAM_COLOR)
		control.position.y = 22
	_marker = ColorRect.new()
	_marker.color = MARKER_COLOR
	_marker.position = Vector2(10, 22)
	_marker.size = Vector2(4, BAR_HEIGHT)
	add_child(_marker)
	hide()
