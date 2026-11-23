class_name MapPlayer
extends Node2D

## Personagem placeholder para navegação top-down em grid (16 px, estilo RPG Maker XP).
## Um comando = um tile; a interpolação só suaviza o desenho, não muda a lógica.

enum Facing { DOWN, LEFT, RIGHT, UP }

var tile_size := 16
var tile := Vector2i.ZERO
var facing: Facing = Facing.DOWN
var moving := false
var just_finished := false
var step_duration := 0.12

var body_color := Color("3e5d92")
var head_color := Color("e6bd96")
var ink := Color("141018")

var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _target := Vector2i.ZERO
var _t := 0.0


func place(t: Vector2i) -> void:
	tile = t
	_from = Vector2(t.x * tile_size, t.y * tile_size)
	_to = _from
	_target = t
	_t = 1.0
	moving = false
	just_finished = false
	position = _from
	queue_redraw()


func set_facing(f: Facing) -> void:
	facing = f
	queue_redraw()


func facing_vector() -> Vector2i:
	if facing == Facing.DOWN:
		return Vector2i(0, 1)
	if facing == Facing.LEFT:
		return Vector2i(-1, 0)
	if facing == Facing.RIGHT:
		return Vector2i(1, 0)
	return Vector2i(0, -1)


func step(direction: Vector2i) -> void:
	if moving:
		return
	if direction == Vector2i(0, 1):
		facing = Facing.DOWN
	elif direction == Vector2i(-1, 0):
		facing = Facing.LEFT
	elif direction == Vector2i(1, 0):
		facing = Facing.RIGHT
	elif direction == Vector2i(0, -1):
		facing = Facing.UP
	else:
		return
	_from = position
	_target = tile + direction
	_to = Vector2(_target.x * tile_size, _target.y * tile_size)
	_t = 0.0
	moving = true
	just_finished = false
	queue_redraw()


func update(delta: float) -> void:
	just_finished = false
	if not moving:
		return
	_t = minf(1.0, _t + delta / step_duration)
	position = _from.lerp(_to, _t)
	if _t >= 1.0:
		moving = false
		tile = _target
		position = _to
		just_finished = true
	queue_redraw()


func _draw() -> void:
	# Silhueta de 16x16 feita só de retângulos: placeholder sem nenhum asset.
	draw_rect(Rect2(-5, -13, 10, 8), head_color)
	draw_rect(Rect2(-6, -5, 12, 9), body_color)
	draw_rect(Rect2(-5, 4, 4, 3), ink)
	draw_rect(Rect2(1, 4, 4, 3), ink)
	var notch := Vector2(-2, 7)
	if facing == Facing.UP:
		notch = Vector2(-2, -15)
	elif facing == Facing.LEFT:
		notch = Vector2(-9, -2)
	elif facing == Facing.RIGHT:
		notch = Vector2(7, -2)
	draw_rect(Rect2(notch, Vector2(4, 3)), ink)
