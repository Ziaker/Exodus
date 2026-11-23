extends Node2D

## Protótipo de navegação top-down estilo RPG Maker XP, 100% placeholder.
## Grid de 16 px, 34x26 tiles, quatro direções, colisão, objetos interativos,
## baús, portas entre duas áreas e HUD mínimo. Nada aqui é decisão de design:
## GDD §3 (core loop) e §16 (regiões) continuam PENDENTES.

const MAP_W := PlaceholderMaps.MAP_W
const MAP_H := PlaceholderMaps.MAP_H
const TILE := PlaceholderMaps.TILE_SIZE
const VIEWPORT := Vector2(544, 416)
const STEP_SECONDS := 0.12
const FADE_SECONDS := 0.18

var current_id := "outskirts"
var data: Dictionary = {}
var tiles: Array[String] = []
var inventory: Dictionary = {}
var opened_chests: Dictionary = {}
var fade := 0.0
var busy := false

var player: MapPlayer
var dialogue: DialogueBox
var font: FontFile


func _ready() -> void:
	font = load("res://addons/gut/fonts/AnonymousPro-Bold.ttf") as FontFile
	player = MapPlayer.new()
	player.name = "MapPlayer"
	add_child(player)
	dialogue = DialogueBox.new()
	dialogue.name = "DialogueBox"
	dialogue.z_index = 10
	add_child(dialogue)
	dialogue.opened.connect(queue_redraw)
	dialogue.closed.connect(queue_redraw)
	load_map("outskirts", "start")
	queue_redraw()


func load_map(id: String, spawn_key: String) -> void:
	data = PlaceholderMaps.get_map(id).duplicate(true)
	if data.is_empty():
		return
	current_id = id
	var rows: Array[String] = []
	rows.assign(data.get("tiles", []))
	tiles = rows
	var spawn: Array = data.get("spawns", {}).get(spawn_key, [1, 1])
	player.place(Vector2i(int(spawn[0]), int(spawn[1])))
	busy = false
	queue_redraw()


func _process(delta: float) -> void:
	dialogue.process_text(delta)
	if fade > 0.0:
		fade = maxf(0.0, fade - delta / FADE_SECONDS)
		queue_redraw()
	player.update(delta)
	if player.just_finished:
		var landing := _transfer_at(player.tile)
		if not landing.is_empty():
			_do_transfer(landing)
	if dialogue.is_open or busy or player.moving:
		return
	var direction := _held_direction()
	if direction == Vector2i.ZERO:
		return
	player.set_facing(_facing_of(direction))
	if not _walkable(player.tile + direction):
		return
	player.step(direction)


func _held_direction() -> Vector2i:
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		return Vector2i(0, -1)
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		return Vector2i(0, 1)
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		return Vector2i(-1, 0)
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		return Vector2i(1, 0)
	return Vector2i.ZERO


func _facing_of(direction: Vector2i) -> MapPlayer.Facing:
	if direction == Vector2i(0, -1):
		return MapPlayer.Facing.UP
	if direction == Vector2i(0, 1):
		return MapPlayer.Facing.DOWN
	if direction == Vector2i(-1, 0):
		return MapPlayer.Facing.LEFT
	return MapPlayer.Facing.RIGHT


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var keycode: Key = (event as InputEventKey).keycode
	if keycode in [KEY_Z, KEY_ENTER, KEY_SPACE]:
		if dialogue.is_open:
			dialogue.advance()
		else:
			interact()
		get_viewport().set_input_as_handled()
	elif keycode in [KEY_X, KEY_ESCAPE] and dialogue.is_open:
		dialogue.advance()
		get_viewport().set_input_as_handled()


func _tile_char(tile: Vector2i) -> String:
	if tile.x < 0 or tile.y < 0 or tile.x >= MAP_W or tile.y >= MAP_H or tiles.is_empty():
		return PlaceholderMaps.WALL
	return tiles[tile.y].substr(tile.x, 1)


func _walkable(tile: Vector2i) -> bool:
	if _tile_char(tile) == PlaceholderMaps.WALL:
		return false
	return _object_at(tile).is_empty()


func _object_at(tile: Vector2i) -> Dictionary:
	for item in data.get("objects", []):
		var obj: Dictionary = item
		var pos: Array = obj.get("tile", [])
		if pos.size() >= 2 and int(pos[0]) == tile.x and int(pos[1]) == tile.y:
			return obj
	return {}


func _transfer_at(tile: Vector2i) -> Dictionary:
	var key := "%d,%d" % [tile.x, tile.y]
	var transfers: Dictionary = data.get("transfers", {})
	if transfers.has(key):
		var result: Dictionary = transfers[key]
		return result
	return {}


func _faced_tile() -> Vector2i:
	return player.tile + player.facing_vector()


func interact() -> void:
	if dialogue.is_open or busy or player.moving:
		return
	var target := _faced_tile()
	var obj := _object_at(target)
	if not obj.is_empty():
		if String(obj.get("kind", "")) == "chest":
			_open_chest(obj)
		else:
			var pages: Array[String] = []
			pages.assign(obj.get("pages", []))
			dialogue.open(String(obj.get("name", "")), pages)
		return
	var landing := _transfer_at(target)
	if not landing.is_empty():
		_do_transfer(landing)


func _open_chest(obj: Dictionary) -> void:
	var key := "%s:%s" % [current_id, String(obj.get("id", ""))]
	if opened_chests.has(key):
		dialogue.open("CHEST", ["Empty. [PLACEHOLDER]"])
		return
	opened_chests[key] = true
	var item := String(obj.get("item", "ITEM"))
	inventory[item] = int(inventory.get(item, 0)) + 1
	dialogue.open("CHEST", ["Found %s x1. [PLACEHOLDER]" % item])


func _do_transfer(landing: Dictionary) -> void:
	busy = true
	fade = 1.0
	load_map(String(landing.get("map", current_id)), String(landing.get("spawn", "start")))
	queue_redraw()


func _draw() -> void:
	if tiles.is_empty():
		return
	for y in MAP_H:
		for x in MAP_W:
			var r := Rect2(x * TILE, y * TILE, TILE, TILE)
			var ch := _tile_char(Vector2i(x, y))
			if ch == PlaceholderMaps.WALL:
				draw_rect(r, Color("4a3b35"))
				draw_rect(Rect2(r.position, Vector2(TILE, 3)), Color("6c5147"))
			elif ch == PlaceholderMaps.FLOOR:
				draw_rect(r, Color("8b857b") if (x + y) % 2 == 0 else Color("827c73"))
			elif ch == PlaceholderMaps.DOOR:
				draw_rect(r, Color("2a2020"))
				draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(12, 14)), Color("c9a85f"))
				draw_rect(Rect2(r.position + Vector2(4, 4), Vector2(8, 12)), Color("1b1414"))
			else:
				draw_rect(r, Color("cfc0a8") if (x + y) % 2 == 0 else Color("c7b7a0"))
	for item in data.get("objects", []):
		_draw_object(item)
	_draw_marker()
	_draw_hud()
	if not dialogue.is_open:
		draw_rect(Rect2(0, 398, VIEWPORT.x, 18), Color("101018dd"))
		if font != null:
			draw_string(font, Vector2(8, 411), "ARROWS/WASD: move   Z/ENTER: interact   X: close",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("cfc9bd"))
	if fade > 0.0:
		draw_rect(Rect2(Vector2.ZERO, VIEWPORT), Color(0, 0, 0, fade))


func _draw_object(item: Variant) -> void:
	var obj: Dictionary = item
	var pos: Array = obj.get("tile", [])
	if pos.size() < 2:
		return
	var p := Vector2(int(pos[0]) * TILE, int(pos[1]) * TILE)
	var kind := String(obj.get("kind", ""))
	if kind == "npc":
		draw_rect(Rect2(p + Vector2(4, 2), Vector2(8, 8)), Color("e6bd96"))
		draw_rect(Rect2(p + Vector2(3, 9), Vector2(10, 7)), Color("76548f"))
	elif kind == "sign":
		draw_rect(Rect2(p + Vector2(7, 4), Vector2(3, 11)), Color("5b3d28"))
		draw_rect(Rect2(p + Vector2(2, 3), Vector2(13, 7)), Color("a97845"))
		draw_rect(Rect2(p + Vector2(7, 4), Vector2(2, 5)), Color("2a1d17"))
	elif kind == "chest":
		var opened := opened_chests.has("%s:%s" % [current_id, String(obj.get("id", ""))])
		draw_rect(Rect2(p + Vector2(2, 6), Vector2(12, 9)), Color("6b4326"))
		draw_rect(Rect2(p + Vector2(2, 4), Vector2(12, 3)), Color("c9a85f" if opened else "8d6134"))
		draw_rect(Rect2(p + Vector2(7, 9), Vector2(2, 3)), Color("e0c479"))
	elif kind == "enemy":
		draw_rect(Rect2(p + Vector2(3, 2), Vector2(10, 10)), Color("8e2730"))
		draw_rect(Rect2(p + Vector2(5, 5), Vector2(2, 2)), Color("f2e6c2"))
		draw_rect(Rect2(p + Vector2(10, 5), Vector2(2, 2)), Color("f2e6c2"))
		draw_rect(Rect2(p + Vector2(2, 12), Vector2(12, 3)), Color("4a1a20"))


func _draw_marker() -> void:
	var faced := _faced_tile()
	if _object_at(faced).is_empty() and _transfer_at(faced).is_empty():
		return
	var tip := Vector2(faced.x * TILE + 8, faced.y * TILE - 9)
	draw_colored_polygon(PackedVector2Array([
		tip, tip + Vector2(8, 0), tip + Vector2(4, 6),
	]), Color("f2d37c"))


func _draw_hud() -> void:
	var r := Rect2(4, 4, 250, 36)
	draw_rect(r, Color("12121fe8"))
	draw_rect(r, Color("05060b"), false, 1)
	draw_rect(r.grow(-1), Color("b9b8c5"), false, 1)
	draw_rect(r.grow(-2), Color("515163"), false, 1)
	if font == null:
		return
	draw_string(font, r.position + Vector2(8, 15), String(data.get("name", "")),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("ece9dc"))
	var items := ""
	for key in inventory.keys():
		items += "%s x%d  " % [String(key), int(inventory[key])]
	if items.is_empty():
		items = "-"
	draw_string(font, r.position + Vector2(8, 30), "ITEMS: " + items,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("a7e2b8"))
