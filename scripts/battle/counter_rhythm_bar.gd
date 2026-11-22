extends Control
## D-049 (creator, 2026-11-22): counter-attack exchange on two rails. Top rail is the
## opponent's (red pointer, right to left, speed by AGI ratio); bottom rail is the
## player's (white pointer, left to right). Each side presses once; the enemy AI
## presses at a random moment. A press while both pointers still move and sit within
## 2% of each other is a perfect interruption. Drawn with primitives only.

signal finished(result: Dictionary)

const RAIL_GAP := 3.0
const RED_POINTER := Color("ff3b3b")
const WHITE_POINTER := Color("fffaf0")
const BEAM_COLOR := Color("d0aa64")
const POINT_COLOR := Color("80df9c")

## "panel": the two rails inside the reacting hero's status panel.
## "enemy": the two rails over the counter-attacking enemy's column.
var style := "panel"
var red_rect := Rect2()
var white_rect := Rect2()
var white_duration := 1.0
var red_duration := 1.0
var white_half := BattleMath.POINT_HALF_WIDTH
var red_half := BattleMath.POINT_HALF_WIDTH
var ai_press_time := 0.5
var elapsed := 0.0
var running := false
var white_stop := -1.0
var red_stop := -1.0
var white_result: int = BattleMath.RhythmResult.MISS
var red_result: int = BattleMath.RhythmResult.MISS
var white_perfect := false
var red_perfect := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(544, 416)
	hide()


func start(kind: String, top: Rect2, bottom: Rect2, white_seconds: float, red_seconds: float,
		white_point_half: float, red_point_half: float, ai_time: float) -> void:
	style = kind
	red_rect = top
	white_rect = bottom
	white_duration = maxf(0.05, white_seconds)
	red_duration = maxf(0.05, red_seconds)
	white_half = clampf(white_point_half, BattleMath.POINT_MIN_HALF_WIDTH, BattleMath.POINT_MAX_HALF_WIDTH)
	red_half = clampf(red_point_half, BattleMath.POINT_MIN_HALF_WIDTH, BattleMath.POINT_MAX_HALF_WIDTH)
	ai_press_time = clampf(ai_time, 0.0, red_duration)
	elapsed = 0.0
	white_stop = -1.0
	red_stop = -1.0
	white_result = BattleMath.RhythmResult.MISS
	red_result = BattleMath.RhythmResult.MISS
	white_perfect = false
	red_perfect = false
	running = true
	show()
	queue_redraw()


func white_moving() -> bool:
	return running and white_stop < 0.0 and elapsed < white_duration


func red_moving() -> bool:
	return running and red_stop < 0.0 and elapsed < red_duration


## Positions as fractions of the rail measured from the left edge.
func white_position() -> float:
	if white_stop >= 0.0: return white_stop
	return clampf(elapsed / white_duration, 0.0, 1.0)


func red_position() -> float:
	if red_stop >= 0.0: return red_stop
	return 1.0 - clampf(elapsed / red_duration, 0.0, 1.0)


func both_moving() -> bool:
	return white_moving() and red_moving()


## The player's Z / Enter / click.
func press_player() -> void:
	if not white_moving(): return
	white_perfect = both_moving() and BattleMath.pointers_aligned(white_position(), red_position())
	white_stop = white_position()
	white_result = BattleMath.rhythm_zone(white_stop, white_half)
	if white_perfect:
		# A perfect press interrupts the other side at once: its pointer freezes.
		red_stop = red_position()
	_check_done()


func _press_ai() -> void:
	if not red_moving(): return
	red_perfect = both_moving() and BattleMath.pointers_aligned(white_position(), red_position())
	red_stop = red_position()
	red_result = BattleMath.rhythm_zone(red_stop, red_half)
	if red_perfect:
		white_stop = white_position()
	_check_done()


func _process(delta: float) -> void:
	if not running: return
	elapsed += delta
	if red_stop < 0.0 and elapsed >= ai_press_time:
		# Evaluate the AI press at its own moment, not at the end of a long frame.
		var now := elapsed
		elapsed = minf(now, ai_press_time)
		_press_ai()
		elapsed = now
	if running and white_stop < 0.0 and elapsed >= white_duration:
		white_stop = 1.0
		white_result = BattleMath.RhythmResult.MISS
	if running and red_stop < 0.0 and elapsed >= red_duration:
		red_stop = 0.0
		red_result = BattleMath.RhythmResult.MISS
	_check_done()
	queue_redraw()


func _check_done() -> void:
	if not running or white_stop < 0.0 or red_stop < 0.0: return
	_emit()


## Tests and drivers: resolve the exchange with known results.
func finish(white: int, red: int, perfect_white := false, perfect_red := false) -> void:
	if not running: return
	white_result = white
	red_result = red
	white_perfect = perfect_white
	red_perfect = perfect_red
	white_stop = maxf(0.0, white_stop)
	red_stop = maxf(0.0, red_stop)
	_emit()


func _emit() -> void:
	running = false
	hide()
	finished.emit({"player": white_result, "enemy": red_result,
		"player_perfect": white_perfect, "enemy_perfect": red_perfect})


func _draw() -> void:
	if not running: return
	_rail(red_rect, red_half, red_position(), RED_POINTER)
	_rail(white_rect, white_half, white_position(), WHITE_POINTER)


func _rail(r: Rect2, half: float, at: float, pointer: Color) -> void:
	var beam := BattleMath.BEAM_HALF_WIDTH
	var spans: Array[Vector2] = [Vector2(0.5 - beam, 0.5 - half), Vector2(0.5 - half, 0.5 + half), Vector2(0.5 + half, 0.5 + beam)]
	if style == "panel":
		# Same look as the defense rail (.defense-rail in the HTML lab).
		draw_rect(r, Color("100a0d"))
		draw_rect(Rect2(r.position + Vector2(0.5, 0.5), r.size - Vector2.ONE), Color(1, 1, 1, 0.72), false, 1)
		var inner := r.size.x - 2.0
		_track(Rect2(r.position + Vector2(1, 3), Vector2(inner, 4)), Color(1, 1, 1, 0.7))
		for i in 3:
			draw_rect(Rect2(r.position + Vector2(1 + inner * spans[i].x, 4), Vector2(inner * (spans[i].y - spans[i].x), 2)), POINT_COLOR if i == 1 else BEAM_COLOR)
		_cursor(Rect2(r.position + Vector2(1 + inner * at - 1, -1), Vector2(2, 12)), pointer)
	else:
		# Same look as the attack rail (.attack-rail in the HTML lab).
		var w := r.size.x
		draw_rect(Rect2(r.position + Vector2(0, 5), Vector2(w, 5)), Color("111111", 0.6))
		_track(Rect2(r.position + Vector2(0, 4), Vector2(w, 5)), Color(1, 1, 1, 0.65))
		for i in 3:
			draw_rect(Rect2(r.position + Vector2(w * spans[i].x, 5), Vector2(w * (spans[i].y - spans[i].x), 3)), POINT_COLOR if i == 1 else BEAM_COLOR)
		_cursor(Rect2(r.position + Vector2(w * at - 1, 0), Vector2(2, 13)), pointer)


func _track(r: Rect2, border: Color) -> void:
	draw_rect(r, Color(0, 0, 0, 0.7))
	draw_rect(Rect2(r.position + Vector2(0.5, 0.5), r.size - Vector2.ONE), border, false, 1)


func _cursor(r: Rect2, color: Color) -> void:
	draw_rect(r.grow(1), Color(color, 0.3))
	draw_rect(r, color)
