extends SceneTree
## Verificação headless do overworld do Survival Mode: mapa 25x21, 20 demônios,
## Curandeiro + Vendedor na mesma barra de opções, zona segura e transição de encontro.

var checks := 0
var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, description: String) -> void:
	if not ok:
		failed = true
		push_error("FAIL: " + description)
		print("FAIL: ", description)
	else:
		checks += 1


func _idle(w: Control) -> void:
	while w.busy:
		await process_frame


func _run() -> void:
	SurvivalState.reset()
	Engine.remove_meta("exodus_dungeon_return_scene")

	var w: Control = load(SurvivalData.WORLD_SCENE).instantiate()
	w.battle_scene = ""
	root.add_child(w)
	await process_frame

	_check(w.grid.size() == 21 and w.grid[0].length() == 25, "SurvivalWorld loads 25x21 map")
	_check(w.enemies.entries.size() == SurvivalData.DEMONS.size(), "SurvivalWorld spawns all %d SMT demons (got %d)" % [SurvivalData.DEMONS.size(), w.enemies.entries.size()])
	_check(w.viewport.find_children("*", "Sprite3D", true, false).size() == SurvivalData.DEMONS.size(), "All %d demons have 3D corridor silhouettes" % SurvivalData.DEMONS.size())
	_check(w.cell == Vector2i(12, 10) and w.facing == 0, "Player starts at sanctuary facing North toward healer/vendor")
	_check(w.npc_picture.visible, "Healer/vendor SMT portrait is visible directly ahead on spawn")
	# Posições são embaralhadas pela semente: isola Pixie/Hel para o teste de passo.
	var keep: Array = []
	for enemy in w.enemies.entries:
		if String(enemy.id) == "pixie":
			enemy.cell = Vector2i(12, 7)
			keep.append(enemy)
		elif String(enemy.id) == "hel":
			enemy.cell = Vector2i(23, 19)
			keep.append(enemy)
	w.enemies.entries.assign(keep)
	_check(w.nearest_demon_hint() == "N 3", "HUD points to the nearest demon from the start (got %s)" % w.nearest_demon_hint())

	# Ferir o grupo e testar Curandeiro + Vendedor na mesma barra de opções.
	SurvivalState.patch({"fallen_hp": 10, "fallen_en": 2, "yoch_hp": 5, "macca": 40, "bead": 0, "chakra": 0})
	w._sync_party_from_state()
	_check(w.party[0].current_hp == 10 and w.party[0].current_en == 2, "Injured party synced to HUD")

	_check(w.talk(), "Z opens unified Healer & Shop option bar")
	_check(w.service_open, "Service bar is open")
	_check(w.SERVICE_OPTIONS.size() == 8, "Service bar has HEAL, BEAD, CHAKRA, RELICS, DAILY, NEW RUN, TITLE, LEAVE")

	# Opção 0: HEAL (grátis).
	_check(w.confirm_service_option() == "heal", "Option 0 executes HEAL")
	_check(w.party[0].current_hp == w.party[0].stats.max_hp and w.party[0].current_en == w.party[0].stats.max_en,
			"HEAL restores Fallen HP and EN to full")
	_check(w.party[1].current_hp == w.party[1].stats.max_hp, "HEAL restores Yoch HP to full")
	_check(int(SurvivalState.data().macca) == 40, "HEAL is free")

	# Opção 1: BUY BEAD (-20M).
	w.move_service_cursor(1)
	_check(w.confirm_service_option() == "bead", "Option 1 buys BEAD")
	_check(int(SurvivalState.data().macca) == 20 and int(SurvivalState.data().bead) == 1, "BEAD bought for 20M")

	# Opção 2: BUY CHAKRA (-20M).
	w.move_service_cursor(1)
	_check(w.confirm_service_option() == "chakra", "Option 2 buys CHAKRA")
	_check(int(SurvivalState.data().macca) == 0 and int(SurvivalState.data().chakra) == 1, "CHAKRA bought for 20M")

	# Sem Macca: compra recusada.
	w.confirm_service_option()
	_check(int(SurvivalState.data().chakra) == 1 and w.service_feedback.contains("NOT ENOUGH MACCA"),
			"Purchase rejected with 0 Macca")

	# Opção 8: LEAVE.
	w.move_service_cursor(5)
	_check(w.confirm_service_option() == "leave", "Last option closes bar")
	_check(not w.service_open, "Service bar closed after LEAVE")

	# Movimento: dar 1 passo para frente (12, 9) dentro da SAFE_ZONE — Pixie em (12, 7) persegue até (12, 8),
	# mas demônio distante (Hel em 23, 19) não se move.
	var hel_before: Vector2i = w.enemies.at(Vector2i(23, 19)).cell
	w.request(w.Act.FORWARD)
	await _idle(w)
	_check(w.cell == Vector2i(12, 9), "Player stepped to (12, 9)")
	_check(w.enemies.at(Vector2i(23, 19)).cell == hel_before, "Distant demon outside chase radius stays put")
	_check(not w.enemies.at(Vector2i(12, 8)).is_empty(), "Nearby Pixie stepped toward player to (12, 8)")
	_check(not w.encounter_pending, "No battle while inside safe zone")

	# Mais um passo para (12, 8): encosta na Pixie e inicia batalha!
	w.request(w.Act.FORWARD)
	await _idle(w)
	_check(w.encounter_pending, "Stepping into Pixie triggers encounter")
	_check(String(SurvivalState.data().encounter_id) == "pixie",
			"Encounter records demon id 'pixie' (got %s)" % String(SurvivalState.data().encounter_id))
	_check(Engine.get_meta("exodus_dungeon_return_scene", "") == SurvivalData.WORLD_SCENE,
			"Return scene points to SurvivalWorld.tscn")

	# Fim de run: derrotar todos os 35 abre a tela de conclusão.
	var all_ids: Array[String] = []
	for d in SurvivalData.DEMONS:
		all_ids.append(String(d.id))
	SurvivalState.patch({"defeated": all_ids})
	w._check_cleared()
	_check(w.cleared_open, "All 35 demons defeated opens SURVIVAL CLEARED overlay")
	_check(w._is_modal_open(), "Cleared overlay blocks movement")
	w.cleared_open = false

	w.queue_free()
	await process_frame
	SurvivalState.clear()
	Engine.remove_meta("exodus_dungeon_return_scene")

	print("SURVIVAL WORLD CHECKS PASSED: %d FAILED: %d" % [checks, int(failed)])
	quit(1 if failed else 0)
