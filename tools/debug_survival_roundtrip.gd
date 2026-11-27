extends SceneTree
## DEBUG (D-111): ida e volta reais de cena (mapa -> luta -> mapa) com aliados, como no jogo:
## luta comum com oferta aceita, luta-teste vencida e perdida, e aliado que cai. Verifica o save
## e a cena atual depois de cada volta; erros de script são capturados por um Logger.
## Uso: Godot --headless --path . -s tools/debug_survival_roundtrip.gd

var failures: Array[String] = []
var errors: Array[String] = []


class TripLogger extends Logger:
	var sink: Array[String]

	func _init(target: Array[String]) -> void:
		sink = target

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if file.begins_with("core/") or file.begins_with("servers/") or file.begins_with("./core"):
			return
		sink.append("[%d] %s:%d %s %s %s" % [error_type, file, line, function, code, rationale])

	func _log_message(_message: String, _error: bool) -> void:
		pass


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, text: String) -> void:
	if not ok:
		failures.append(text)
		print("TRIP FAIL: ", text)
	else:
		print("ok: ", text)


## Espera a troca de cena por tempo (o SceneFader anima em segundos, não em quadros).
func _scene_is(path: String, seconds := 10.0) -> bool:
	var until := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		if current_scene != null and current_scene.scene_file_path == path:
			return true
		await process_frame
	print("   (scene now: %s)" % (current_scene.scene_file_path if current_scene != null else "<none>"))
	return false


func _battle_until(b: Node, wanted: Array, limit := 4000) -> bool:
	for _i in limit:
		if not is_instance_valid(b) or b.hud == null:
			return false
		if b.hud.mode in wanted:
			return true
		match String(b.hud.mode):
			"react": b.handle_back()
			"continue", "announce", "turn": b.handle_confirm()
		await process_frame
	return false


## Z na tela de resultado até voltar ao mapa (como o jogador, que aperta de novo).
func _leave(b: Node) -> bool:
	var until := Time.get_ticks_msec() + 10000
	while Time.get_ticks_msec() < until:
		if current_scene != null and current_scene.scene_file_path == SurvivalData.WORLD_SCENE:
			for _i in 10:
				await process_frame
			return true
		if is_instance_valid(b) and b.hud != null and b.hud.mode == "result":
			b.handle_confirm()
		for _i in 5:
			await process_frame
	return false


func _to_world() -> Node:
	change_scene_to_file(SurvivalData.WORLD_SCENE)
	await _scene_is(SurvivalData.WORLD_SCENE)
	for _i in 10:
		await process_frame
	return current_scene


func _run() -> void:
	var logger := TripLogger.new(errors)
	OS.add_logger(logger)
	var sandbox := "user://trip_progress_guard.json"
	ProgressStore.save_path_override = sandbox
	var backup := FileAccess.get_file_as_string(SurvivalState.SAVE_PATH) if FileAccess.file_exists(SurvivalState.SAVE_PATH) else ""

	# 1) Luta comum vinda do mapa, com oferta aceita.
	var number := 0
	while not SurvivalAllies.offer_rolls(3, number + 1):
		number += 1
	SurvivalState.reset()
	SurvivalState.patch({"seed": 3, "stratum": 2, "cell": [12, 10], "battles": number,
		"party": [SurvivalAllies.new_member("t_a", "pixie", SurvivalAllies.stats_like_battle("pixie", 73), 1)]})
	var w := await _to_world()
	_check(w != null and w.scene_file_path == SurvivalData.WORLD_SCENE, "map opened")
	var enemy: Dictionary = w.enemies.entries[0]
	w._begin_battle(enemy)
	_check(await _scene_is(SurvivalData.BATTLE_SCENE), "map -> battle")
	var b := current_scene
	_check(await _battle_until(b, ["plan"]), "battle reaches the plan")
	b.hud.players[1].current_hp = 0 # o aliado cai
	for f in b.hud.opponents:
		f.current_hp = 0
	b.state.round_number = 1
	b._show_result()
	_check(await _battle_until(b, ["offer", "result"]), "offer or result shows")
	if b.hud.mode == "offer":
		b.handle_confirm()
	_check(await _battle_until(b, ["result"]), "result after the offer")
	_check(await _leave(b), "battle -> map after victory")
	await process_frame
	var s := SurvivalState.data()
	_check(SurvivalState._valid_state(s.duplicate(true)), "save valid after the trip")
	_check(bool(SurvivalState.find_member("t_a").get("down", false)), "the fallen ally is down on the map")
	_check((s.party as Array).size() + (s.reserve as Array).size() == 2, "the offered demon joined (%d allies)" % [(s.party as Array).size() + (s.reserve as Array).size()])
	_check((s.defeated as Array).has(String(enemy.id)), "victory recorded")

	# 2) Luta-teste vencida e perdida, saindo do encontro do mapa.
	for win in [true, false]:
		w = current_scene
		var cand: String = SurvivalStrata.ids_for(2)[0]
		var npc := {"id": "s2_rT%s" % str(win), "role": "recruit", "kind": "duel", "candidate": cand,
			"name": "X", "cell": Vector2i(12, 10), "picture": "", "pages": [""]}
		var hp_before := int(SurvivalState.data().fallen_hp)
		var bead_before := int(SurvivalState.data().get("bead", 0))
		w.active_event = npc
		w.event_open = true
		w.event_index = 0
		w.confirm_event()
		_check(await _scene_is(SurvivalData.BATTLE_SCENE), "map -> test fight (%s)" % ("win" if win else "loss"))
		b = current_scene
		_check(await _battle_until(b, ["plan"]), "test fight reaches the plan")
		_check(b.duel and not b._commands(b._fallen).has("ABSORB"), "it is a test fight without ABSORB")
		if win:
			for f in b.hud.opponents:
				f.current_hp = 0
			b._show_result()
		else:
			b._fallen.current_hp = 0
			b._play_death()
		_check(await _battle_until(b, ["result"]), "test fight ends in a result")
		_check(await _leave(b), "test fight -> map")
		await process_frame
		s = SurvivalState.data()
		_check((s.duel as Dictionary).is_empty() and int(s.fallen_hp) == hp_before and int(s.get("bead", 0)) == bead_before, "test fight restored HP and cleared the duel")
		_check((s.recruits_done as Array).has(String(npc.id)), "encounter resolved")
		_check(SurvivalState._valid_state(s.duplicate(true)), "save valid after the test fight")

	OS.remove_logger(logger)
	for e in errors:
		failures.append("script error: " + e)
		print("TRIP FAIL: script error: ", e)
	ProgressStore.save_path_override = ""
	if backup.is_empty():
		SurvivalState.clear()
	else:
		var f := FileAccess.open(SurvivalState.SAVE_PATH, FileAccess.WRITE)
		f.store_string(backup)
		f.close()
	print("TRIP RESULT: %d failures" % failures.size())
	quit(1 if not failures.is_empty() else 0)
