extends SceneTree

const MAP := preload("res://scripts/survival/necropole_map.gd")
const TITLE := "res://scenes/title/Title.tscn"
const DIRS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		printerr("FAIL: ", description)
		failures += 1


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	var released := event.duplicate()
	released.pressed = false
	Input.parse_input_event(released)


func _run() -> void:
	_check(SurvivalStrata.maze(1, 1) != SurvivalData.MAZE, "estrato 1 usa a Necrópole")
	if failures > 0:
		quit(1)
		return
	_test_legacy_save()
	SurvivalState.clear()
	change_scene_to_file(TITLE)
	await scene_changed
	_key(KEY_DOWN)
	await process_frame
	_key(KEY_DOWN)
	await process_frame
	_key(KEY_ENTER)
	await create_timer(0.9).timeout
	var dungeon := current_scene
	_check(dungeon != null and dungeon.scene_file_path == SurvivalData.WORLD_SCENE
		and dungeon.has_method("request"),
		"entrada pelo Survival do título")
	if failures > 0:
		quit(1)
		return
	var start := MAP.entrance()
	var finish := MAP.sepulchre()
	_check(dungeon.cell == start and SurvivalState.stratum() == 1, "run começa no Pórtico")
	_check(dungeon.party.size() == 1 and dungeon.party[0].id == &"fallen",
		"HUD inicial acompanha o grupo da run")
	_check(dungeon.npc_near().get("id") == "sanctuary_keeper", "santuário na entrada")
	_check(dungeon.enemies.entries.size() == SurvivalStrata.PER_STRATUM + 1, "demônios e grupo humano")
	var warden: Dictionary = dungeon.enemies.at(finish)
	_check(warden.get("id", "") == SurvivalStrata.warden_of(1) and warden.get("warden", false),
		"guardião do Survival no Sepulcro")
	_check(not dungeon.viewport.transparent_bg and not dungeon.parallax.visible, "céu substitui o parallax")
	_check(is_equal_approx(dungeon.camera.far, 5.5), "alcance da câmera")
	_check(is_equal_approx(dungeon.camera.fov, 77.7321), "FOV da câmera")
	_check(dungeon.viewport.find_children("*", "SpotLight3D", true, false).size() == 5, "luzes pendulares")
	var environment := dungeon.viewport.find_children("*", "WorldEnvironment", true, false)[0] as WorldEnvironment
	var sky := environment.environment.sky.sky_material as ShaderMaterial
	_check(sky.shader.resource_path.ends_with("/ceu_plasma.gdshader"), "céu animado ativo")
	var meshes: Array[Node] = dungeon.viewport.find_children("*", "MeshInstance3D", true, false)
	var stone := (meshes[0] as MeshInstance3D).material_override as ShaderMaterial
	_check(is_equal_approx(stone.get_shader_parameter("azul_chumbo"), 0.88), "pedra azul de chumbo")
	var filter := dungeon.get_node("OverworldFilter").material as ShaderMaterial
	_check(filter.get_shader_parameter("mixed_palette").resource_path ==
		"res://prototypes/dungeon-crawler/dungeon_mixed_palette.res", "LUT canônica ativa")
	var reached := SurvivalStrata.distances(dungeon.grid, start, 1)
	var rooms := 0
	for name in MAP.DATA.data.centers:
		if reached.has(MAP.center(name)):
			rooms += 1
	_check(rooms == 55 and reached.size() == 2639, "55 salas e 2639 células alcançáveis")
	_check(reached.get(finish, -1) + 1 == 314, "rota mínima de 314 células")
	var sealed: Array = dungeon.grid.duplicate()
	for pair in MAP.DATA.data.ruptura:
		var tile := MAP.cell_at(pair)
		var row: String = sealed[tile.y]
		sealed[tile.y] = row.left(tile.x) + "#" + row.substr(tile.x + 1)
	_check(not SurvivalStrata.distances(sealed, start, 1).has(finish), "Ruptura obrigatória")
	await _check_geometry(dungeon, reached, meshes)
	_key(KEY_UP)
	await create_timer(0.5).timeout
	_check(dungeon.cell == start + Vector2i.UP and not dungeon.busy, "passo com a seta no Pórtico")
	_key(KEY_RIGHT)
	await create_timer(0.3).timeout
	_check(dungeon.facing == 1, "giro com a seta")
	var edge: Array = MAP.DATA.data.closed_edges[0]
	var a := MAP.cell_at(edge[0])
	var b := MAP.cell_at(edge[1])
	dungeon.cell = a
	dungeon.facing = DIRS.find(b - a)
	dungeon._snap_to_state()
	_key(KEY_UP)
	await create_timer(0.4).timeout
	_check(dungeon.cell == a and dungeon.clash_count > 0, "parede interna bloqueia o passo")
	# Exercita a entrada real em batalha, o retorno e a descida sem montar outra campanha.
	dungeon._begin_battle(warden)
	await create_timer(1.0).timeout
	_check(current_scene.scene_file_path == SurvivalData.BATTLE_SCENE and
		SurvivalState.data().encounter_id == warden.id, "encontro abre a batalha do Survival")
	SurvivalState.record_victory(warden.id, 0)
	change_scene_to_file(SurvivalData.WORLD_SCENE)
	await scene_changed
	dungeon = current_scene
	_check(dungeon.cell == a and dungeon.enemies.at(finish).is_empty(), "retorno conserva a posição e a vitória")
	dungeon.cell = start
	dungeon.facing = 0
	dungeon._snap_to_state()
	_check(dungeon.talk(), "menu do santuário abre no Pórtico")
	dungeon.service_index = dungeon.service_index_of("descend")
	_check(dungeon.service_index >= 0, "vitória habilita DESCEND")
	dungeon.confirm_service_option()
	dungeon.confirm_service_option()
	await process_frame
	await process_frame
	_check(SurvivalState.stratum() == 2 and not current_scene._location_title().contains("SATURNINA")
		and current_scene.grid == SurvivalStrata.maze(int(SurvivalState.data().seed), 2),
		"segundo estrato continua usando sua geração")
	print("NECROPOLE ", rooms, " salas / ", reached.size(), " células / ", checks - failures,
		" verificações / ", failures, " falhas")
	SurvivalState.clear()
	quit(0 if failures == 0 else 1)


func _check_geometry(dungeon: Node, reachable: Dictionary, meshes: Array[Node]) -> void:
	for node in meshes:
		(node as MeshInstance3D).create_trimesh_collision()
	await physics_frame
	await physics_frame
	_check(meshes.size() == int(MAP.DATA.data.meshes), "mesmas malhas da exportação")
	var space: PhysicsDirectSpaceState3D = dungeon.viewport.find_world_3d().direct_space_state
	var invalid := 0
	for cell: Vector2i in reachable:
		var eye := Vector3(cell.x, dungeon.EYE_HEIGHT, cell.y)
		var floor_ray := PhysicsRayQueryParameters3D.create(
			Vector3(cell.x, 0.38, cell.y), Vector3(cell.x, -0.01, cell.y))
		floor_ray.hit_back_faces = true
		if space.intersect_ray(floor_ray).is_empty():
			invalid += 1
		for direction: Vector2i in DIRS:
			var next := cell + direction
			if not dungeon._can_step(cell, next):
				continue
			var ray := PhysicsRayQueryParameters3D.create(eye,
				eye + Vector3(direction.x, 0, direction.y) * 0.995)
			ray.hit_back_faces = true
			if not space.intersect_ray(ray).is_empty():
				invalid += 1
	_check(invalid == 0, "%d conflitos entre planta e colisores" % invalid)


func _test_legacy_save() -> void:
	var old := SurvivalState.reset().duplicate(true)
	old.erase("necropole")
	old.merge({"cell": [12, 9], "facing": 2, "macca": 777,
		"defeated": ["pixie"], "visited": [[12, 9]], "seen": ["jack_frost"]}, true)
	var file := FileAccess.open(SurvivalState.SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": SurvivalState.SAVE_VERSION, "state": old}))
	file.close()
	_check(SurvivalState.load_from_file(), "save válido anterior carrega")
	var saved := SurvivalState.data()
	var entry := MAP.entrance()
	_check(saved.cell == [entry.x, entry.y] and saved.visited.is_empty()
		and saved.seen.is_empty() and saved.facing == 0, "save antigo migra a memória espacial")
	_check(int(saved.macca) == 777 and saved.defeated == ["pixie"], "save preserva economia e progresso")
