extends SceneTree
## Verificação headless do primeiro estrato do Survival Mode,
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
	# O fim de run grava no meta (OMEN/CODEX): guarda e restaura o arquivo do jogador.
	var meta_backup := ""
	if FileAccess.file_exists(SurvivalMeta.SAVE_PATH):
		meta_backup = FileAccess.get_file_as_string(SurvivalMeta.SAVE_PATH)
	SurvivalMeta.save({})
	SurvivalState.reset()
	Engine.remove_meta("exodus_dungeon_return_scene")

	var w: Control = load(SurvivalData.WORLD_SCENE).instantiate()
	w.battle_scene = ""
	root.add_child(w)
	await process_frame

	var start := SurvivalStrata.entrance(1)
	var far := SurvivalStrata.NECROPOLE.sepulchre()
	_check(w.grid == SurvivalStrata.maze(int(SurvivalState.data().seed), 1), "SurvivalWorld loads the Necropolis")
	# D-066: o estrato 1 tem 7 dos 35 demônios (os outros esperam nos estratos 2..5).
	_check(w.enemies.entries.size() == SurvivalStrata.PER_STRATUM + 1, "SurvivalWorld spawns the 7 demons and the human group of stratum 1 (got %d)" % w.enemies.entries.size())
	var expected_floaters := 0
	for e in w.enemies.entries:
		expected_floaters += SurvivalData.floater_eye_count(int(SurvivalState.data().seed), String(e.id))
	_check(w.enemy_sprites.size() == SurvivalStrata.PER_STRATUM + 1 and w.viewport.find_children("*", "Sprite3D", true, false).size() == SurvivalStrata.PER_STRATUM + 1 + expected_floaters + w.npc_sprites.size(), "All 7 stratum demons, the human group and their Floater Eyes (+ the NPC sprites) have 3D corridor silhouettes")
	_check(w.cell == start and w.facing == 0, "Player starts at sanctuary facing North toward healer/vendor")
	# Criador 2026-11-27: de frente só há o sprite 3D (sem zoom); a figura grande e a conversa são no bloco do NPC.
	_check(not w.npc_picture.visible and w.npc_near().is_empty(), "Healer/vendor: no zoom and no talking from the block ahead")
	_check(w.npc_sprites.has("sanctuary_keeper"), "Healer/vendor has a 3D sprite visible from afar")
	w.cell = start + Vector2i.UP
	w._snap_to_state()
	w.refresh_front_picture()
	_check(w.npc_picture.visible, "Healer/vendor SMT portrait is visible on his own block")
	w.cell = start
	w._snap_to_state()
	w.refresh_front_picture()
	# Posições são embaralhadas pela semente: isola Pixie/Jack Frost para o teste de passo.
	var keep: Array = []
	for enemy in w.enemies.entries:
		if String(enemy.id) == "pixie":
			enemy.cell = start + Vector2i.UP * 3
			keep.append(enemy)
		elif String(enemy.id) == "jack_frost":
			enemy.cell = far
			keep.append(enemy)
	w.enemies.entries.assign(keep)
	_check(w.nearest_demon_hint() == "N 3", "HUD points to the nearest demon from the start (got %s)" % w.nearest_demon_hint())

	# Ferir o grupo e testar Curandeiro + Vendedor na mesma barra de opções.
	var yoch := SurvivalAllies.yoch_member("test_yoch")
	yoch.hp = 5
	SurvivalState.patch({"fallen_hp": 10, "fallen_en": 2, "party": [yoch], "macca": 40, "bead": 0, "chakra": 0})
	w._sync_party_from_state()
	_check(w.party[0].current_hp == 10 and w.party[0].current_en == 2, "Injured party synced to HUD")
	_check(w.party.size() == 2 and w.party[1].current_hp == 5, "Recruited Yoch synced to HUD")

	# Tutorial da 1ª conversa (criador 2026-11-26) fica de fora: visto só na memória da cena.
	w._meta_cache = SurvivalMeta.data()
	w._meta_cache["keeper_intro"] = true
	w.cell = start + Vector2i.UP  # só se fala com o curandeiro no bloco dele
	_check(w.talk(), "Z opens unified Healer & Shop option bar")
	w.cell = start
	_check(w.service_open, "Service bar is open")
	_check(w.service_options().size() == 9, "Service bar has HEAL, SHOP, RELICS, HIRE, RESERVE, NEW RUN, DAILY, TITLE, LEAVE")

	# Opção 0: HEAL (grátis).
	_check(w.confirm_service_option() == "heal", "Option 0 executes HEAL")
	_check(w.party[0].current_hp == w.party[0].stats.max_hp and w.party[0].current_en == w.party[0].stats.max_en,
			"HEAL restores Fallen HP and EN to full")
	_check(w.party[1].current_hp == w.party[1].stats.max_hp, "HEAL restores Yoch HP to full")
	_check(int(SurvivalState.data().macca) == 40, "First HEAL of the stratum is free (D-068)")

	# Opção 1: SHOP (D-072) — painel próprio; BEAD e CHAKRA sempre no estoque.
	w.move_service_cursor(1)
	_check(w.confirm_service_option() == "shop" and w.shop_open, "Option 1 opens the SHOP panel")
	w.shop_index = 0
	_check(w.confirm_shop(), "SHOP buys BEAD")
	_check(int(SurvivalState.data().macca) == 20 and int(SurvivalState.data().bead) == 1, "BEAD bought for 20M")
	w.move_shop_cursor(1)
	_check(w.confirm_shop(), "SHOP buys CHAKRA")
	_check(int(SurvivalState.data().macca) == 0 and int(SurvivalState.data().chakra) == 1, "CHAKRA bought for 20M")

	# Sem Macca: compra recusada.
	w.confirm_shop()
	_check(int(SurvivalState.data().chakra) == 1 and w.shop_feedback.contains("NOT ENOUGH MACCA"),
			"Purchase rejected with 0 Macca")
	w.close_shop()

	# Última opção: LEAVE.
	w.cell = start + Vector2i.UP
	w.talk()
	w.service_index = w.service_options().size() - 1
	_check(w.confirm_service_option() == "leave", "Last option closes bar")
	_check(not w.service_open, "Service bar closed after LEAVE")
	w.cell = start
	w._snap_to_state()

	# Pixie persegue até a borda do santuário, Jack Frost fica no extremo do mapa.
	w.request(w.Act.FORWARD)
	await _idle(w)
	_check(w.cell == start + Vector2i.UP, "Player stepped North within sanctuary")
	_check(not w.enemies.at(far).is_empty(), "Distant demon outside chase radius stays put")
	_check(not w.enemies.at(start + Vector2i.UP * 2).is_empty(), "Nearby Pixie follows to the edge of sanctuary")
	_check(not w.encounter_pending, "No battle while inside safe zone")

	# Mais um passo encosta na Pixie fora da zona segura.
	w.request(w.Act.FORWARD)
	await _idle(w)
	_check(w.encounter_pending, "Stepping into Pixie triggers encounter")
	_check(String(SurvivalState.data().encounter_id) == "pixie",
			"Encounter records demon id 'pixie' (got %s)" % String(SurvivalState.data().encounter_id))
	_check(Engine.get_meta("exodus_dungeon_return_scene", "") == SurvivalData.WORLD_SCENE,
			"Return scene points to SurvivalWorld.tscn")

	# Fim de run (D-066): derrotar o guardião do estrato 5 abre a tela de conclusão.
	var all_ids: Array[String] = []
	for st in range(1, SurvivalStrata.COUNT + 1):
		all_ids.append(SurvivalStrata.warden_of(st))
	SurvivalState.patch({"defeated": all_ids})
	w._check_cleared()
	_check(w.cleared_open, "Stratum 5 warden defeated opens SURVIVAL CLEARED overlay")
	_check(w._is_modal_open(), "Cleared overlay blocks movement")
	w.cleared_open = false

	w.queue_free()
	await process_frame
	SurvivalState.clear()
	Engine.remove_meta("exodus_dungeon_return_scene")

	if meta_backup.is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SurvivalMeta.SAVE_PATH))
	else:
		var mf := FileAccess.open(SurvivalMeta.SAVE_PATH, FileAccess.WRITE)
		mf.store_string(meta_backup)
		mf.close()
	print("SURVIVAL WORLD CHECKS PASSED: %d FAILED: %d" % [checks, int(failed)])
	quit(1 if failed else 0)
