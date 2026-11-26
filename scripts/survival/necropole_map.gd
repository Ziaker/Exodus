extends RefCounted
## A planta navegável é medida na malha exportada. As coordenadas do Blender
## crescem para o norte; a grade do Survival cresce para o sul.

const DATA := preload("res://assets/generated/survival/necropole/mapa.tres")
const ORIGIN := Vector2i(16, 169)

static var _rows: Array[String] = []
static var _blocked: Dictionary = {}


static func cell_at(pair: Array) -> Vector2i:
	return ORIGIN + Vector2i(int(pair[0]), -int(pair[1]))


static func center(room: String) -> Vector2i:
	return cell_at(DATA.data.centers[room])


static func entrance() -> Vector2i:
	return center(DATA.data.start)


static func sepulchre() -> Vector2i:
	return center(DATA.data.end)


static func rows() -> Array[String]:
	if not _rows.is_empty():
		return _rows.duplicate()
	var tiles: Array[Vector2i] = []
	var extent := Vector2i.ZERO
	for pair in DATA.data.walkable:
		var tile := cell_at(pair)
		tiles.append(tile)
		extent = extent.max(tile)
	var buffer: Array[PackedByteArray] = []
	for y in range(extent.y + 2):
		var row := PackedByteArray()
		row.resize(extent.x + 2)
		row.fill(35) # #
		buffer.append(row)
	for tile in tiles:
		buffer[tile.y][tile.x] = 46 # .
	var start := entrance()
	buffer[start.y][start.x] = 83 # S
	for row in buffer:
		_rows.append(row.get_string_from_ascii())
	return _rows.duplicate()


static func edge_is_open(a: Vector2i, b: Vector2i) -> bool:
	if _blocked.is_empty():
		for edge in DATA.data.closed_edges:
			var first := cell_at(edge[0])
			var second := cell_at(edge[1])
			_blocked[Vector4i(first.x, first.y, second.x, second.y)] = true
			_blocked[Vector4i(second.x, second.y, first.x, first.y)] = true
	return not _blocked.has(Vector4i(a.x, a.y, b.x, b.y))
