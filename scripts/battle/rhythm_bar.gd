class_name RhythmBar
extends Control

## Barra de reflexo para ataques fisicos. Zonas: ponto 10% central, trave 20% ao redor.
## Desenhada apenas com primitivas do Godot — nenhum asset de imagem da fangame.

signal finished(result: int)

const BAR_WIDTH: float = 360.0
const BAR_HEIGHT: float = 26.0
const TRACK_COLOR := Color(0.05, 0.06, 0.05, 1.0)
const BEAM_COLOR := Color(0.85, 0.65, 0.15, 0.95)
const POINT_COLOR := Color(0.20, 0.80, 0.35, 0.95)
const MARKER_COLOR := Color.WHITE

var duration: float = 1.0
var _elapsed: float = 0.0
var _running: bool = false
var _marker: ColorRect
var _label: Label
var _beam_left: ColorRect
var _point_zone: ColorRect
var _beam_right: ColorRect
var _point_half_width: float = BattleMath.POINT_HALF_WIDTH
var _chain_mode: bool = false
## Hit marks along the rail (fractions). One mark at the centre for every normal
## strike; Lunge uses two marks in one pass (creator 2026-11-23: 35% and 65%).
var marks: Array[float] = [0.5]
## One result per mark, in order, filled by press() during the current pass.
var results: Array[int] = []

func _ready() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	position = Vector2(92, 104)
	size = Vector2(BAR_WIDTH, BAR_HEIGHT + 34.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(BattleWidgets.window_frame(Vector2(0, 0), Vector2(BAR_WIDTH, BAR_HEIGHT + 32.0)))

	_label = BattleWidgets.styled_label("RHYTHM - Z / ENTER", 13, HORIZONTAL_ALIGNMENT_CENTER)
	_label.position = Vector2(0, 4)
	_label.size = Vector2(BAR_WIDTH, 20)
	add_child(_label)

	var track := ColorRect.new()
	track.color = TRACK_COLOR
	track.position = Vector2(10, 28)
	track.size = Vector2(BAR_WIDTH - 20, BAR_HEIGHT)
	add_child(track)

	_beam_left = _make_zone(0.35, 0.10, BEAM_COLOR)
	_point_zone = _make_zone(0.45, 0.10, POINT_COLOR)
	_beam_right = _make_zone(0.55, 0.10, BEAM_COLOR)
	_layout_zones()

	_marker = ColorRect.new()
	_marker.color = MARKER_COLOR
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


func _layout_zones() -> void:
	var track_width := BAR_WIDTH - 20.0
	var half := _point_half_width
	var beam := BattleMath.BEAM_HALF_WIDTH
	_beam_left.position.x = 10.0 + track_width * (0.5 - beam)
	_beam_left.size.x = track_width * (beam - half)
	_point_zone.position.x = 10.0 + track_width * (0.5 - half)
	_point_zone.size.x = track_width * half * 2.0
	_beam_right.position.x = 10.0 + track_width * (0.5 + half)
	_beam_right.size.x = track_width * (beam - half)


## D-034: AGI/SP change POINT width, not bar speed.
func configure(point_half: float) -> void:
	_point_half_width = clampf(point_half,
		BattleMath.POINT_MIN_HALF_WIDTH, BattleMath.POINT_MAX_HALF_WIDTH)
	_layout_zones()


func start(seconds: float) -> void:
	_chain_mode = false
	_begin(seconds)


## D-046: keeps the bar on screen between consecutive planned attacks.
func start_chain(seconds: float) -> void:
	_chain_mode = true
	_begin(seconds)


func stop_chain() -> void:
	_chain_mode = false
	_running = false
	hide()


## Next passes use these hit marks (call before start/start_chain).
func set_marks(new_marks: Array[float]) -> void:
	marks = new_marks.duplicate() if not new_marks.is_empty() else [0.5]
	queue_redraw()


## Judges a press at the current position. With several marks, a press belongs to the
## first unresolved mark until the pointer passes the midpoint to the next mark (the
## skipped mark is a MISS); the pass ends when every mark has a result.
func press() -> void:
	if not _running:
		return
	var progress := clampf(_elapsed / maxf(duration, 0.001), 0.0, 1.0)
	_skip_passed_marks(progress)
	if results.size() < marks.size():
		results.append(BattleMath.rhythm_zone_at(progress, marks[results.size()], _point_half_width))
	if results.size() >= marks.size():
		_finish(results[0])


func _skip_passed_marks(progress: float) -> void:
	while results.size() < marks.size() - 1:
		var i := results.size()
		if progress <= (marks[i] + marks[i + 1]) * 0.5:
			break
		results.append(BattleMath.RhythmResult.MISS)


func _begin(seconds: float) -> void:
	duration = maxf(seconds, 0.05)
	results.clear()
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
		while results.size() < marks.size():
			results.append(BattleMath.RhythmResult.MISS)
		_finish(results[0])


func _unhandled_input(event: InputEvent) -> void:
	if not _running:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.keycode == KEY_Z or key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
			press()
			accept_event()


func _finish(result: int) -> void:
	if not _running:
		return
	_running = false
	# Direct callers (tests, drivers) finish a one-mark pass with an explicit result.
	if results.is_empty():
		results.append(result)
	while results.size() < marks.size():
		results.append(BattleMath.RhythmResult.MISS)
	if _chain_mode:
		# Same line stays visible; the next marker starts from the left again.
		_elapsed = 0.0
		_marker.position.x = 10.0
	else:
		hide()
	finished.emit(result)
