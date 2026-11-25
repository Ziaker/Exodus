extends SceneTree
## Verificação headless dos inimigos do dungeon: pontos vermelhos, um passo por
## passo do jogador, encontro e ida/volta ao combate novo. Não prova o visual.

const SCENE := "res://prototypes/dungeon-crawler/DungeonProto.tscn"
const Proto := preload("res://prototypes/dungeon-crawler/dungeon_proto.gd")

var checks := 0
var failed := false
var encounters: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, description: String) -> void:
	if not ok:
		failed = true
		push_error("FAIL: " + description)
		print("FAIL: ", description)
	else:
		checks += 1


func _new() -> Control:
	var d: Control = load(SCENE).instantiate()
	d.encounter_started.connect(func(id: String) -> void: encounters.append(id))
	root.add_child(d)
	return d


func _place(d: Control, c: Vector2i, f: int) -> void:
	d.cell = c
	d.facing = f
	d._snap_to_state()
	d._map_cell(c)


func _idle(d: Control) -> void:
	while d.busy:
		await process_frame


func _step(d: Control) -> void:
	d.request(Proto.Act.FORWARD)
	await _idle(d)


func _run() -> void:
	Engine.remove_meta(Proto.DUNGEON_STATE_META)
	Engine.remove_meta(Proto.DUNGEON_RETURN_META)

	# Ambiente gerado; personagens/inimigos continuam com os assets SMT placeholder.
	for path in ["wall.png", "backdrop.png", "floor_tile.png"]:
		_check(ResourceLoader.exists("res://assets/generated/dungeon/" + path),
				"Generated overworld asset exists: " + path)
	var src := FileAccess.open("res://prototypes/dungeon-crawler/dungeon_proto.gd", FileAccess.READ).get_as_text()
	_check(src.contains("Pictures/P15.png") and src.contains("AutoMapMarker.png"),
			"NPC pictures and automap marker use the SMT placeholders")

	var d := _new()
	d.battle_scene = ""  # lógica primeiro: sem troca de cena real
	_check(d.enemies.entries.size() == Proto.ENEMY_DEFS.size(), "Enemy list loaded")
	for enemy in d.enemies.entries:
		_check(not d.is_wall(enemy.cell), "Enemy starts on a walkable cell (%s)" % str(enemy.cell))
		_check(enemy.cell != Vector2i(1, 1) and d.npc_at(enemy.cell).is_empty(),
				"Enemy does not start on the player or an NPC (%s)" % str(enemy.cell))
	_check(Proto.ENEMY_INK == Color("bb3d48"), "Enemies use the battle red on the automap")
	_check(d.viewport.find_children("*", "Sprite3D", true, false).size() == d.enemies.entries.size(),
			"Every enemy has a moving silhouette in the corridor")
	for enemy in d.enemies.entries:
		var sprite: Sprite3D = d.enemy_sprites[String(enemy.id)]
		var art_path := sprite.texture.resource_path
		_check(art_path.contains("generated/dungeon/enemy_"),
				"Enemy is a silhouette extracted from an SMT battler (%s)" % art_path)
		var expected := Vector3(float(enemy.cell.x), Proto.ENEMY_HEIGHT * 0.5, float(enemy.cell.y))
		_check(sprite.position.distance_to(expected) < 0.001,
				"Enemy %s starts in the corridor centre, inside its cell (%s)" % [enemy.id, str(sprite.position)])
	var art_script := FileAccess.open("res://tools/generate_dungeon_art.py", FileAccess.READ).get_as_text()
	_check(art_script.contains("Avatar Anubis.png") and art_script.contains("Avatar Chimera.png")
			and art_script.contains("Avian Garuda.png"),
			"Silhouettes come from the real SMT battlers")
	_check(d.viewport.find_children("FloorGrid", "MeshInstance3D", true, false).size() == 1,
			"Floor is a 3D mesh with square tile markings")

	_place(d, Vector2i(1, 1), 1)
	_check(d.enemies.seen.has("stalker"), "Enemy ahead is marked on the automap")
	_check(not d.enemies.seen.has("hound"), "Enemy around a corner stays hidden")

	# Um passo do jogador = um passo de cada inimigo.
	_place(d, Vector2i(1, 1), 1)
	var before: Vector2i = d.enemies.at(Vector2i(4, 1)).cell
	await _step(d)
	_check(d.cell == Vector2i(2, 1), "Player advanced one tile")
	_check(d.enemies.at(Vector2i(3, 1)).cell == Vector2i(3, 1),
			"Stalker advanced exactly one tile toward the player (from %s)" % str(before))
	for _i in 12:
		await process_frame
	var silhouette: Sprite3D = d.enemy_sprites["stalker"]
	var half_h := Proto.ENEMY_HEIGHT * 0.5
	_check(is_equal_approx(silhouette.position.x, 3.0) and is_equal_approx(silhouette.position.z, 1.0),
			"The silhouette moves to the enemy cell centre, not the wall corner (pos=%s)" % str(silhouette.position))
	_check(is_equal_approx(silhouette.position.y, half_h),
			"Silhouette stands on the floor (y=%s)" % str(silhouette.position.y))
	var drawn_h: float = silhouette.texture.get_height() * silhouette.pixel_size * silhouette.scale.y
	_check(drawn_h <= Proto.WALL_HEIGHT and drawn_h >= Proto.WALL_HEIGHT * 0.75,
			"Silhouette fits inside the corridor height (%.2f vs wall %.2f)" % [drawn_h, Proto.WALL_HEIGHT])
	_check(not d.encounter_pending, "No battle before contact")

	# Segundo passo: o inimigo alcança o jogador e o combate novo é iniciado.
	await _step(d)
	_check(d.encounter_pending, "Contact starts an encounter")
	_check(encounters == ["stalker"], "Encounter names the enemy (%s)" % str(encounters))
	_check(Engine.has_meta(Proto.DUNGEON_STATE_META), "Map state saved before battle")
	_check(Engine.get_meta(Proto.DUNGEON_RETURN_META, "") == Proto.DUNGEON_SCENE,
			"Battle knows where to return")
	var saved: Dictionary = Engine.get_meta(Proto.DUNGEON_STATE_META)
	_check(saved.cell == [3, 1] and saved.facing == 1, "Saved position survives the battle")
	_check(d.enemies.at(Vector2i(3, 1)).is_empty(), "Encountered enemy leaves the map")
	_check(not d.enemy_sprites.has("stalker"), "Encountered enemy silhouette leaves the corridor")

	# Volta: o mapa restaura posição, automapa e inimigos restantes.
	var back := _new()
	back.battle_scene = ""
	_check(back.cell == Vector2i(3, 1) and back.facing == 1, "Returned dungeon restores the player")
	_check(back.visited.has(Vector2i(2, 1)), "Automap progress restored")
	_check(back.enemies.entries.size() == 2 and back.enemies.at(Vector2i(3, 1)).is_empty(),
			"Defeated enemy is not re-spawned")
	_check(not back.encounter_pending, "Restoring does not immediately re-trigger a battle")

	# Andar para a célula de um inimigo também dispara o combate.
	_place(back, Vector2i(7, 4), 0)
	await _step(back)
	_check(back.cell == Vector2i(7, 3) and back.encounter_pending,
			"Stepping onto the enemy cell starts the encounter")
	back.queue_free()
	await process_frame

	# Transição real para a cena de combate nova (BattlePlayable).
	var live := _new()
	# O hound saiu no encontro anterior; o wraith também avançou um tile no mesmo passo.
	var wraith_cell := Vector2i.ZERO
	for enemy in live.enemies.entries:
		if String(enemy.id) == "wraith":
			wraith_cell = enemy.cell
	_check(wraith_cell != Vector2i.ZERO, "Remaining enemy survives for the real transition test")
	_place(live, wraith_cell + Vector2i(0, 1), 0)
	await _step(live)
	_check(live.encounter_pending, "Real transition starts from an enemy contact")
	_check(root.get_node_or_null("SceneFader") != null, "Scene fader autoload exists")
	_check(root.get_node("SceneFader").is_busy(), "Encounter starts the cross-scene fade")
	for _i in 80:
		if current_scene != null and current_scene.scene_file_path == Proto.BATTLE_SCENE:
			break
		await process_frame
	_check(current_scene != null and current_scene.scene_file_path == Proto.BATTLE_SCENE,
			"Encounter changes to the new battle scene (got %s)" % (
				current_scene.scene_file_path if current_scene else "null"))
	_check(current_scene.has_method("handle_confirm"), "Battle scene is the new combat controller")
	for _i in 40:
		await process_frame
	_check(not root.get_node("SceneFader").is_busy(), "Fade in finishes after the scene change")
	# Vitória simulada: Z na tela de resultado volta ao dungeon com o estado salvo.
	current_scene.hud.mode = "result"
	current_scene.handle_confirm()
	for _i in 80:
		if current_scene != null and current_scene.scene_file_path == Proto.DUNGEON_SCENE:
			break
		await process_frame
	_check(current_scene != null and current_scene.scene_file_path == Proto.DUNGEON_SCENE,
			"Battle result returns to the dungeon (got %s)" % (
				current_scene.scene_file_path if current_scene else "null"))
	_check(not Engine.has_meta(Proto.DUNGEON_RETURN_META), "Return meta is consumed once")

	Engine.remove_meta(Proto.DUNGEON_STATE_META)
	Engine.remove_meta(Proto.DUNGEON_RETURN_META)
	print("ENCOUNTER CHECKS PASSED: %d FAILED: %d" % [checks, int(failed)])
	quit(1 if failed else 0)
