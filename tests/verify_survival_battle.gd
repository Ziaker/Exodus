extends SceneTree
## Verificação headless da batalha do Survival Mode: 1 demônio SMT dinâmico,
## itens BEAD (HP) e CHAKRA (EN), 3 continues sem perder metade dos status,
## isolamento total do ProgressStore e recompensa de Macca.

const SURVIVAL_BATTLE := preload("res://scripts/survival/survival_battle.gd")

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


func _wait_mode(battle: Control, mode_name: String, max_frames: int = 120) -> bool:
	for _i in max_frames:
		if battle.hud != null and battle.hud.mode == mode_name:
			return true
		# Um anúncio de ataque inimigo abre a reação e trava o turno do jogador.
		# O driver do teste nega e deixa a luta seguir até ao modo pedido.
		if battle.hud != null and battle.hud.mode == "react" and mode_name != "react":
			battle.handle_back()
		if battle.hud != null and battle.hud.mode in ["continue", "announce"] \
				and mode_name not in ["continue", "announce"]:
			battle.proceed()
		await process_frame
	return false


## Congela os outros combatentes para que itens/morte/vitória sejam testados
## sem a IA do demônio interromper o modo do HUD no meio das asserções.
func _freeze_other_actors(battle: Control) -> void:
	for unit in battle.state.units:
		if unit != battle._fallen:
			unit.acts_available = 0
			unit.stored_acts = 0
	battle._refresh_all()


func _run() -> void:
	var sandbox := "user://test_survival_battle_guard.json"
	ProgressStore.save_path_override = sandbox
	ProgressStore.clear()
	ProgressStore.save_gains({"atk": 10, "max_hp": 10})
	var main_gains_before := ProgressStore.load_gains()
	var main_deaths_before := ProgressStore.load_deaths()

	SurvivalState.reset()
	SurvivalState.patch({
		"encounter_id": "cerberus",
		# Seed fixa: elites são sorteados por semente, sem isto o teste era
		# intermitente (nome e Macca mudavam quando Cérbero virava elite).
		"seed": 1,
		"fallen_hp": 15,
		"fallen_en": 4,
		# D-111: o Yoch recrutado no grupo (a run começa só com o Fallen).
		"party": [_yoch_with_hp(20)],
		"bead": 1,
		"chakra": 1,
		"macca": 40,
		"continues": 3,
		# AGI alto deixa o Fallen agir antes do demônio: o teste de itens não
		# precisa disputar com um pedido de reação no meio do turno.
		"gains": {"max_hp": 0, "max_en": 0, "atk": 6, "mak": 0, "defense": 0, "mef": 0, "agi": 20},
	})

	var battle: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	battle.suppress_scene_change = true
	root.add_child(battle)
	await _wait_mode(battle, "plan")
	_freeze_other_actors(battle)

	_check(not battle.persist_progress, "Survival battle disables ProgressStore persistence")
	_check(battle.hud.opponents.size() == 1, "Survival battle has 1 opponent (got %d)" % battle.hud.opponents.size())
	_check(battle.hud.opponents[0].display_name == "CERBERUS", "Opponent is CERBERUS")
	_check(battle.hud.silhouettes.size() == 1, "Dynamic SMT silhouette generated for CERBERUS")
	var sil_size: Vector2 = battle.hud.silhouettes[0].get_size()
	_check(sil_size.x > 20 and sil_size.x < 180 and sil_size.y > 20 and sil_size.y < 180,
			"CERBERUS battle silhouette is cleanly cropped, not opaque box (%s)" % str(sil_size))
	_check(battle._fallen.current_hp == 15 and battle._fallen.current_en == 4,
			"Fallen loads current HP/EN from SurvivalState")
	_check(battle._fallen.stats.atk == int(SurvivalData.FALLEN_BASE.atk) + 6,
			"Fallen applies Survival run gains (+6 ATK)")

	# Item test: ITEM está disponível com 1 BEAD e 1 CHAKRA.
	var cmds: Array[String] = battle._commands(battle._fallen)
	_check(cmds.has("ITEM"), "ITEM command present when bag has items")

	# Usar BEAD (+20 HP) no Fallen.
	var item_idx := cmds.find("ITEM")
	_freeze_other_actors(battle)
	battle.submit_plan(item_idx)
	battle.exec_plan()
	_check(await _wait_mode(battle, "item"), "ITEM opens item submenu")
	_check(battle.item_ids == ["bead", "chakra"], "Submenu lists BEAD and CHAKRA")
	battle.submit_item(0) # BEAD
	_check(await _wait_mode(battle, "target"), "BEAD asks for ally target")
	battle.submit_target(0) # Fallen
	# O inimigo também age: confere o cura no mesmo instante em que ele resolve.
	# D-101: a ficha nova tem HP 26; a cura de 20 e limitada pelo HP maximo.
	_check(battle._fallen.current_hp == mini(battle._fallen.stats.max_hp, 15 + 20), "BEAD healed Fallen 15 -> %d HP (got %d)" % [mini(battle._fallen.stats.max_hp, 35), battle._fallen.current_hp])
	_check(int(SurvivalState.data().bead) == 0, "BEAD count decremented to 0")
	await _wait_mode(battle, "plan")

	# Usar CHAKRA (+10 EN) no Fallen.
	cmds = battle._commands(battle._fallen)
	_freeze_other_actors(battle)
	battle.submit_plan(cmds.find("ITEM"))
	battle.exec_plan()
	_check(await _wait_mode(battle, "item"), "ITEM opens submenu with remaining CHAKRA")
	_check(battle.item_ids == ["chakra"], "Submenu lists only CHAKRA now")
	battle.submit_item(0) # CHAKRA
	_check(await _wait_mode(battle, "target"), "CHAKRA asks for ally target")
	battle.submit_target(0) # Fallen
	for _i in 20:
		await process_frame
	_check(battle._fallen.current_en == mini(battle._fallen.stats.max_en, 4 + 10), "CHAKRA restored Fallen EN 4 -> %d (got %d)" % [mini(battle._fallen.stats.max_en, 14), battle._fallen.current_en])
	_check(int(SurvivalState.data().chakra) == 0, "CHAKRA count decremented to 0")
	_check(not battle._commands(battle._fallen).has("ITEM"), "ITEM command hidden when bag is empty")

	# Teste de morte + Continue (3 -> 2) SEM perder metade dos status.
	var atk_before_death: int = battle._fallen.stats.atk
	_freeze_other_actors(battle)
	# O loop de turno precisa estar esperando um comando para notar a morte.
	await _wait_mode(battle, "plan")
	battle._fallen.current_hp = 0
	# Força fim do turno atual se estiver aguardando comando.
	if battle.hud.mode in ["plan", "command"]:
		battle._chosen = -1
		battle.command_chosen.emit()
	for _i in 120:
		if battle.continue_prompt_open:
			break
		await process_frame
	_check(battle.continue_prompt_open, "Fallen's death opens Continue overlay")
	_check(int(SurvivalState.data().continues) == 3, "Continues still 3 before confirming")

	battle.answer_continue(true)
	for _i in 120:
		if not battle.continue_prompt_open and battle.hud.mode == "plan":
			break
		await process_frame
	_check(not battle.continue_prompt_open, "Continue overlay closes after confirming")
	_check(int(SurvivalState.data().continues) == 2, "Continues decremented 3 -> 2 (got %d)" % int(SurvivalState.data().continues))
	_check(battle._fallen.current_hp == battle._fallen.stats.max_hp and battle._fallen.current_en == battle._fallen.stats.max_en,
			"Continue restores Fallen to full HP and EN")
	_check(battle._ally.current_hp == battle._ally.stats.max_hp, "Continue restores the ally (Yoch) to full HP")
	_check(battle._fallen.stats.atk == atk_before_death, "Continue keeps all stats intact (no halving)")
	_check(ProgressStore.load_gains() == main_gains_before, "Main game ProgressStore gains untouched on Survival death")
	_check(ProgressStore.load_deaths() == main_deaths_before, "Main game ProgressStore deaths untouched on Survival death")

	# Teste de vitória: derrota Cerberus e confere Macca + defeated + retorno.
	var foe: BattleUnit = battle.hud.opponents[0]
	_freeze_other_actors(battle)
	await _wait_mode(battle, "plan")
	foe.current_hp = 0
	if battle.hud.mode in ["plan", "command"]:
		battle._chosen = -1
		battle.command_chosen.emit()
	_check(await _wait_mode(battle, "result", 120), "Battle reaches result screen on victory")
	_check((SurvivalState.data().defeated as Array).has("cerberus"), "CERBERUS recorded as defeated")
	_check(int(SurvivalState.data().macca) == 40 + 35, "Macca reward (+35) added (got %d)" % int(SurvivalState.data().macca))
	_check(Engine.get_meta("exodus_dungeon_return_scene", "") == SurvivalData.WORLD_SCENE,
			"Victory sets return scene to SurvivalWorld.tscn")
	_check(ProgressStore.load_gains() == main_gains_before, "Main game ProgressStore still untouched after victory")

	battle.queue_free()
	await process_frame

	# Teste de Game Over com 0 continues -> volta para Title sem tocar ProgressStore.
	SurvivalState.reset()
	SurvivalState.patch({
		"encounter_id": "pixie", "continues": 0,
		"gains": {"max_hp": 0, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": 20},
	})
	var battle2: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	battle2.suppress_scene_change = true
	root.add_child(battle2)
	await _wait_mode(battle2, "plan")
	_freeze_other_actors(battle2)
	battle2._fallen.current_hp = 0
	battle2._chosen = -1
	battle2.command_chosen.emit()
	for _i in 120:
		if battle2.continue_prompt_open:
			break
		await process_frame
	_check(battle2.continue_prompt_open and battle2._survival_gameover, "0 continues shows Survival Over overlay")
	battle2.answer_continue(true)
	for _i in 60:
		if battle2.left_to_title:
			break
		await process_frame
	_check(battle2.left_to_title, "0 continues returns to title screen")
	_check(ProgressStore.load_gains() == main_gains_before and ProgressStore.load_deaths() == main_deaths_before,
			"0 continues Game Over never touches ProgressStore")

	battle2.queue_free()
	await process_frame
	SurvivalState.clear()
	Engine.remove_meta("exodus_dungeon_return_scene")
	ProgressStore.clear()
	ProgressStore.save_path_override = ""

	print("SURVIVAL BATTLE CHECKS PASSED: %d FAILED: %d" % [checks, int(failed)])
	quit(1 if failed else 0)


func _yoch_with_hp(hp: int) -> Dictionary:
	var y := SurvivalAllies.yoch_member("test_yoch")
	y["hp"] = hp
	return y
