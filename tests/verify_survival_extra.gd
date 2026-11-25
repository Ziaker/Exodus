extends SceneTree
## Cobertura adicional do Survival: lutas com 2/3 demônios, X encerra a run,
## CHAKRA em Yoch (PP), item desperdiçado, e as 35 silhuetas dinâmicas do HUD.

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


func _wait_mode(b: Control, wanted: String, limit: int = 240) -> bool:
	for _i in limit:
		if b.hud != null and b.hud.mode == wanted:
			return true
		if b.hud != null and b.hud.mode == "react" and wanted != "react":
			b.handle_back()
		if b.hud != null and b.hud.mode in ["continue", "announce"] \
				and wanted not in ["continue", "announce"]:
			b.proceed()
		await process_frame
	return false


func _freeze(b: Control) -> void:
	for unit in b.state.units:
		if unit != b._fallen:
			unit.acts_available = 0
			unit.stored_acts = 0
	b._refresh_all()


func _new_battle(enc_id: String, extra: Dictionary) -> Control:
	SurvivalState.reset()
	var patch := {
		"encounter_id": enc_id,
		"gains": {"max_hp": 0, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": 20},
	}
	for key in extra.keys():
		patch[key] = extra[key]
	SurvivalState.patch(patch)
	var b: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	b.suppress_scene_change = true
	root.add_child(b)
	await _wait_mode(b, "plan")
	_freeze(b)
	return b


func _run() -> void:
	var sandbox := "user://test_survival_extra_guard.json"
	ProgressStore.save_path_override = sandbox
	ProgressStore.clear()
	var gains_before := ProgressStore.load_gains()

	# Lutas escalonadas por tier.
	var big := await _new_battle("beelzebub", {})
	_check(big.hud.opponents.size() == 3, "Tier 5 encounter has 3 demons (got %d)" % big.hud.opponents.size())
	var names := {}
	for foe in big.hud.opponents:
		names[foe.display_name] = true
	_check(names.size() == 3, "The 3 defenders are distinct demons")
	_check(big.hud.silhouettes.size() == 3, "HUD has one silhouette per defender")
	big.queue_free()
	await process_frame

	var mid := await _new_battle("ganesha", {})
	_check(mid.hud.opponents.size() == 2, "Tier 3 encounter has 2 demons (got %d)" % mid.hud.opponents.size())
	mid.queue_free()
	await process_frame

	# X no overlay de continue encerra a run sem tocar no ProgressStore.
	var quitter := await _new_battle("pixie", {"continues": 2})
	quitter._fallen.current_hp = 0
	quitter._chosen = -1
	quitter.command_chosen.emit()
	for _i in 120:
		if quitter.continue_prompt_open:
			break
		await process_frame
	_check(quitter.continue_prompt_open, "Death opens continue overlay before X")
	quitter.answer_continue(false)
	for _i in 120:
		if quitter.left_to_title:
			break
		await process_frame
	_check(quitter.left_to_title, "X ends the run and returns to the title")
	_check(not Engine.has_meta(SurvivalState.META_KEY), "X clears the saved run")
	_check(ProgressStore.load_gains() == gains_before, "X never touches main ProgressStore")
	quitter.queue_free()
	await process_frame

	# CHAKRA em Yoch: 2 PP, e o item sai da bolsa.
	var healer := await _new_battle("pixie", {"chakra": 1, "yoch_pp": 2})
	var cmds: Array[String] = healer._commands(healer._fallen)
	healer.submit_plan(cmds.find("ITEM"))
	healer.exec_plan()
	_check(await _wait_mode(healer, "item"), "ITEM submenu opens for CHAKRA test")
	healer.submit_item(healer.item_ids.find("chakra"))
	_check(await _wait_mode(healer, "target"), "CHAKRA asks for a target")
	var pp_before: int = healer._ally.current_pp
	healer.submit_target(1) # Yoch
	_check(healer._ally.current_pp == mini(pp_before + 2, PrayerBook.MAX_PP),
			"CHAKRA grants 2 PP to praying Yoch (got %d)" % healer._ally.current_pp)
	_check(int(SurvivalState.data().chakra) == 0, "CHAKRA consumed from the bag")
	healer.queue_free()
	await process_frame

	# Item em alvo cheio não é desperdiçado.
	var full := await _new_battle("pixie", {"bead": 1, "fallen_hp": int(SurvivalData.FALLEN_BASE.max_hp)})
	var acts_before: int = full._fallen.acts_available
	var cmds2: Array[String] = full._commands(full._fallen)
	full.submit_plan(cmds2.find("ITEM"))
	full.exec_plan()
	_check(await _wait_mode(full, "item"), "ITEM submenu opens for full-HP test")
	full.submit_item(0)
	_check(await _wait_mode(full, "target"), "BEAD asks for a target")
	full.submit_target(0)
	_check(int(SurvivalState.data().bead) == 1, "BEAD on a full-HP ally is kept")
	_check(full._fallen.acts_available == acts_before, "No ACT spent on a wasted item")
	full.queue_free()
	await process_frame

	# As 35 silhuetas dinâmicas são crops justos com os pés na sombra.
	var sil := await _new_battle("pixie", {})
	for demon in SurvivalData.DEMONS:
		var paths: Array[String] = [String(demon.picture)]
		sil.hud.set_opponent_sprites(paths)
		var img: Image = sil.hud.silhouettes[0].get_image()
		var box: Rect2i = alpha_box(img)
		var pad: int = img.get_height() - box.end.y
		_check(pad == 0 and box.size.y > 20,
				"%s battle silhouette is tight (pad=%d, h=%d)" % [String(demon.id), pad, box.size.y])
		_check(absf(sil.hud.enemy_sprite_rect(0).end.y - sil.hud.enemy_horizon) < 0.5,
				"%s feet line matches the ground shadow" % String(demon.id))
	sil.queue_free()
	await process_frame

	# Save inconsistente (lista de inimigos vazia): derrotados não renascem.
	SurvivalState.patch({"defeated": ["pixie", "hel"], "enemies": []})
	Engine.remove_meta(SurvivalState.META_KEY)
	_check(SurvivalState.load_from_file(), "Inconsistent saved run reloads")
	var restored: Control = load(SurvivalData.WORLD_SCENE).instantiate()
	restored.battle_scene = ""
	root.add_child(restored)
	await process_frame
	_check(restored.enemies.entries.size() == SurvivalData.DEMONS.size() - 2,
			"Defeated demons stay off the map after reload (got %d)" % restored.enemies.entries.size())
	restored.queue_free()
	await process_frame

	# NEW RUN zera Macca/continues e reinicia o mundo sem erro de current_scene.
	SurvivalState.reset()
	var nr: Control = load(SurvivalData.WORLD_SCENE).instantiate()
	nr.battle_scene = ""
	root.add_child(nr)
	await process_frame
	SurvivalState.patch({"macca": 0})
	nr.talk()
	nr.service_index = 5
	_check(nr.confirm_service_option() == "new_run", "NEW RUN is in the service bar")
	_check(nr.service_pending == "new_run", "NEW RUN asks for confirmation")
	_check(int(SurvivalState.data().macca) == 0, "First Z does not erase the run")
	_check(nr.confirm_service_option() == "new_run", "Second Z confirms NEW RUN")
	_check(int(SurvivalState.data().macca) == SurvivalData.STARTING_MACCA, "NEW RUN restores starting Macca")
	_check(int(SurvivalState.data().continues) == SurvivalData.MAX_CONTINUES, "NEW RUN restores 3 continues")
	_check(nr.SERVICE_OPTIONS[6].id == "title", "TITLE is available in the same bar")
	nr.talk() # NEW RUN fechou a barra
	nr.service_index = 6
	_check(nr.confirm_service_option() == "title", "TITLE option executes")
	for _i in 180:
		if current_scene != null and current_scene.scene_file_path == "res://scenes/title/Title.tscn":
			break
		await process_frame
	_check(current_scene != null and current_scene.scene_file_path == "res://scenes/title/Title.tscn",
			"TITLE returns to the title screen after the fade")
	nr.queue_free()
	await process_frame

	# Save inválido é recusado (campos fora do intervalo), sem apagar a run atual.
	SurvivalState.reset()
	var f := FileAccess.open(SurvivalState.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": SurvivalState.SAVE_VERSION,
		"state": {"macca": -5, "continues": 99, "cell": [999, 999]}}))
	f.close()
	Engine.remove_meta(SurvivalState.META_KEY)
	_check(not SurvivalState.load_from_file(), "Corrupt save is rejected")
	_check(not Engine.has_meta(SurvivalState.META_KEY), "Rejected save leaves state untouched")

	SurvivalState.clear()
	ProgressStore.clear()
	ProgressStore.save_path_override = ""
	print("SURVIVAL EXTRA CHECKS PASSED: %d FAILED: %d" % [checks, int(failed)])
	quit(1 if failed else 0)


static func alpha_box(img: Image) -> Rect2i:
	var min_x := img.get_width()
	var min_y := img.get_height()
	var max_x := -1
	var max_y := -1
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.01:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < 0:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
