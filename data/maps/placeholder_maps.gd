class_name PlaceholderMaps
extends RefCounted

## Dados de exploração 100% PLACEHOLDER. Nenhuma decisão do criador foi registrada
## aqui: GDD §3 e §16 continuam PENDENTES. Nomes, textos, itens, geografia e regras
## são apenas suportes para testar a navegação; trocar por dados reais depois.

const MAP_W := 34
const MAP_H := 26
const TILE_SIZE := 16
const SAND := "."
const WALL := "#"
const FLOOR := "o"
const DOOR := "D"

static var _cache: Dictionary = {}


static func blank(fill: String) -> Array[String]:
	var rows: Array[String] = []
	for y in MAP_H:
		var line := ""
		for x in MAP_W:
			if x == 0 or y == 0 or x == MAP_W - 1 or y == MAP_H - 1:
				line += WALL
			else:
				line += fill
		rows.append(line)
	return rows


static func paint(rows: Array[String], x: int, y: int, ch: String) -> void:
	if x < 0 or x >= MAP_W or y < 0 or y >= MAP_H:
		return
	rows[y] = rows[y].substr(0, x) + ch + rows[y].substr(x + 1)


static func get_map(id: String) -> Dictionary:
	if _cache.is_empty():
		_cache["outskirts"] = _outskirts()
		_cache["ruins"] = _ruins()
	return _cache.get(id, {})


static func _outskirts() -> Dictionary:
	var rows := blank(SAND)
	for x in range(14, 17):
		for y in range(8, 11):
			paint(rows, x, y, WALL)
	for x in range(6, 9):
		for y in range(17, 20):
			paint(rows, x, y, WALL)
	paint(rows, 32, 13, DOOR)
	return {
		"name": "AREA 01 - SAND SEA [PLACEHOLDER]",
		"tiles": rows,
		"spawns": {"start": [3, 13], "from_ruins": [30, 13]},
		"objects": [
			{"id": "sign_01", "kind": "sign", "tile": [5, 5], "name": "SIGN",
				"pages": ["PLACEHOLDER SIGN.", "Ruins to the east ->"]},
			{"id": "npc_01", "kind": "npc", "tile": [11, 7], "name": "NPC-01",
				"pages": ["Who are you? [PLACEHOLDER]", "The sand remembers everything."]},
			{"id": "chest_01", "kind": "chest", "tile": [22, 5], "name": "CHEST", "item": "POTION"},
			{"id": "enemy_01", "kind": "enemy", "tile": [26, 21], "name": "ENEMY",
				"pages": ["A hostile shape blocks the path.", "COMBAT LINK PENDING."]},
		],
		"transfers": {"32,13": {"map": "ruins", "spawn": "from_outskirts"}},
	}


static func _ruins() -> Dictionary:
	var rows := blank(FLOOR)
	for x in range(12, 16):
		for y in range(6, 9):
			paint(rows, x, y, WALL)
	for x in range(20, 23):
		for y in range(14, 17):
			paint(rows, x, y, WALL)
	paint(rows, 1, 13, DOOR)
	return {
		"name": "AREA 02 - RUINS [PLACEHOLDER]",
		"tiles": rows,
		"spawns": {"from_outskirts": [3, 13], "start": [3, 13]},
		"objects": [
			{"id": "npc_02", "kind": "npc", "tile": [8, 9], "name": "NPC-02",
				"pages": ["This place has no name yet.", "[PLACEHOLDER DIALOGUE]"]},
			{"id": "chest_02", "kind": "chest", "tile": [27, 7], "name": "CHEST", "item": "ETHER"},
			{"id": "sign_02", "kind": "sign", "tile": [17, 19], "name": "SIGN",
				"pages": ["West: sand sea.", "[PLACEHOLDER]"]},
		],
		"transfers": {"1,13": {"map": "outskirts", "spawn": "from_ruins"}},
	}
