class_name RhythmBar
extends Control

## Reflex bar for physical attacks. Zones: point 10% center, beam 20% around.
## Styled with the fangame's VX Ace window skin.

signal finished(result: int)

const BAR_WIDTH: float = 360.0
const BAR_HEIGHT: float = 26.0

var duration: float = 1.0
var _elapsed: float = 0.0
var _running: bool = false
var _marker: ColorRect
var _label: Label

func _ready() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	position = Vector2(92, 104)
	size = Vector2(BAR_WIDTH, BAR_HEIGHT + 34.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var frame := BattleWidgets.window_frame(Vector2(0, 0), Vector2(BAR_WIDTH, BAR_HEIGHT + 32.0))
	add_child(frame)

	_label = BattleWidgets.styled_label("RHYTHM - Z / ENTER", 13, HORIZONTAL_ALIGNMENT_CENTER)
	_label.position = Vector2(0, 4)
	_label.size = Vector2(BAR_WIDTH, 20)
	add_child(_label)

	var track := ColorRect.new()
	track.color = Color(0.05, 0.06, 0.05, 1.0)
	track.position = Vector2(10, 28)
	track.size = Vector2(BAR_WIDTH - 20, BAR_HEIGHT)
	add_child(track)

	var left := _make_zone(0.35, 0.10, Color(0.85, 0.65, 0.15, 0.95))
	var center := _make_zone(0.45, 0.10, Color(0.20, 0.80, 0.35, 0.95))
	var right := _make_zone(0.55, 0.10, Color(0.85, 0.65, 0.15, 0.95))

	_marker = ColorRect.new()
	_marker.color = Color.WHITE
	_marker.position = Vector2(10, 28)
	_marker.size = Vector2(4, BAR_HEIGHT)
	add_child(_marker)
	hide()


func _make_zone(start_fraction: float, width_fraction: float, color: Color) -> ColorRect:
	var zone := ColorRect.new()
	zone.color = color
	zone.position = Vector2(10 + (BAR_WIDTH - 20) * start_fraction, 28)
	zone.size = Vector2((BAR_WIDTH - 20) * width_fraction, BAR_HEIGHT)
	add_child(zone)
	return zone


func start(seconds: float) -> void:
	duration = maxf(seconds, 0.05)
	_elapsed = 0.0
	_running = true
	_marker.position.x = 10.0
	show()


func _process(delta: float) -> void:
	if not _running:
		return
	_elapsed += delta
	var progress := clampf(_elapsed / duration, 0.0, 1.0)
	_marker.position.x = 10.0 + progress * (BAR_WIDTH - 20.0)
	if progress >= 1.0:
		_finish(BattleMath.RhythmResult.MISS)


func _unhandled_input(event: InputEvent) -> void:
	if not _running:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.keycode == KEY_Z or key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
			var progress := (_marker.position.x - 10.0) / (BAR_WIDTH - 20.0)
			_finish(BattleMath.rhythm_zone(progress))
			accept_event()


func _finish(result: int) -> void:
	if not _running:
		return
	_running = false
	hide()
	finished.emit(result)
