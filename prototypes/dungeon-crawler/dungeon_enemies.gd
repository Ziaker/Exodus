class_name DungeonEnemies
extends RefCounted

## Inimigos de exploração do teste de dungeon: pontos vermelhos no automapa que
## avançam um tile por passo do jogador e iniciam o combate ao alcançá-lo.
## Estado puro (sem desenho, sem cena) para poder ser verificado headless.

const RED := Color("bb3d48")
const DARK_RED := Color("5c1c2b")

var entries: Array[Dictionary] = []
var seen := {}


func _init(definitions: Array) -> void:
	for item in definitions:
		var definition: Dictionary = item
		var enemy := definition.duplicate(true)
		enemy["home"] = enemy["cell"]
		entries.append(enemy)


func at(c: Vector2i) -> Dictionary:
	for enemy in entries:
		if enemy.cell == c:
			return enemy
	return {}


func cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for enemy in entries:
		out.append(enemy.cell)
	return out


func restore(saved: Array) -> void:
	if saved.is_empty():
		return
	# Só voltam os inimigos presentes no estado salvo: o encontrado na batalha
	# não deve ressuscitar quando o mapa é recarregado.
	var kept: Array[Dictionary] = []
	for enemy in entries:
		for item in saved:
			var record: Dictionary = item
			if String(record.get("id", "")) == String(enemy.id):
				var cell: Array = record.get("cell", [])
				if cell.size() == 2:
					enemy.cell = Vector2i(int(cell[0]), int(cell[1]))
				kept.append(enemy)
				break
	entries = kept


func serialise() -> Array:
	var out: Array = []
	for enemy in entries:
		out.append({"id": String(enemy.id), "cell": [enemy.cell.x, enemy.cell.y]})
	return out


## Um passo por combatente. O eixo maior vem primeiro; se estiver bloqueado,
## tenta o outro. Retorna o inimigo que chegou à célula do jogador.
func step_toward(player_cell: Vector2i, can_enter: Callable) -> Dictionary:
	for enemy in entries:
		var delta: Vector2i = player_cell - enemy.cell
		if delta == Vector2i.ZERO:
			return enemy
		var horizontal := Vector2i(int(signf(float(delta.x))), 0)
		var vertical := Vector2i(0, int(signf(float(delta.y))))
		var options: Array[Vector2i] = []
		if absi(delta.x) >= absi(delta.y):
			options = [horizontal, vertical]
		else:
			options = [vertical, horizontal]
		for direction in options:
			if direction == Vector2i.ZERO:
				continue
			var target: Vector2i = enemy.cell + direction
			if target == player_cell:
				enemy.cell = target
				return enemy
			if not bool(can_enter.call(target)) or not at(target).is_empty():
				continue
			enemy.cell = target
			break
		if enemy.cell == player_cell:
			return enemy
	return {}


func observe(is_visible: Callable) -> void:
	for enemy in entries:
		if not seen.has(enemy.id) and bool(is_visible.call(enemy.cell)):
			seen[enemy.id] = true


func in_front(player_cell: Vector2i, direction: Vector2i, distance: int = 3) -> Dictionary:
	for step in range(1, distance + 1):
		var found := at(player_cell + direction * step)
		if not found.is_empty():
			return found
	return {}
