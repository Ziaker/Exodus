extends SceneTree
## Regressão do travamento relatado: o painel ABSORPTION REWARD abria mas as
## teclas não faziam nada. O HUD é filho do controller e chama
## set_input_as_handled(), então _input() do survival_battle nunca era chamado.
## Aqui as teclas são injetadas de verdade via Input.parse_input_event(), que
## percorre a mesma árvore de nós do jogo interativo.

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


func _key(code: Key) -> void:
	var down := InputEventKey.new()
	down.keycode = code
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var up := InputEventKey.new()
	up.keycode = code
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame


func _wait_mode(b: Control, wanted: String, limit: int = 240) -> bool:
	for _i in limit:
		if b.hud != null and b.hud.mode == wanted:
			return true
		if b.hud != null and b.hud.mode == "react":
			b.handle_back()
		await process_frame
	return false


func _open_reward(b: Control) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var options := SurvivalAbsorb.roll_options(rng,
			SurvivalData.demon_by_id("pixie"), [], 1.0)
	# Chamada sem await: a corrotina fica pendurada no sinal absorb_chosen,
	# exatamente como acontece durante a absorção real.
	b.call("_wait_absorb_choice", options)
	await process_frame
	_check(b.hud.mode == "absorb_choice", "Reward panel opened with real key route")
	_check(b.absorb_options.size() == 3, "Reward panel has three options")


func _run() -> void:
	# A janela headless nasce 64x64; simular clique exige um viewport realista.
	get_root().size = Vector2i(816, 624)
	var sandbox := "user://test_survival_input_guard.json"
	ProgressStore.save_path_override = sandbox
	ProgressStore.clear()
	SurvivalState.reset()
	SurvivalState.patch({
		"encounter_id": "pixie", "seed": 42, "continues": 3,
		"gains": {"max_hp": 0, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": 20},
	})
	var b: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	b.suppress_scene_change = true
	root.add_child(b)
	_check(await _wait_mode(b, "plan"), "Battle reaches planning mode with a live HUD child")

	# 1) Setas movem o cursor pelo _input do HUD (que engole o evento).
	await _open_reward(b)
	await _key(KEY_RIGHT)
	_check(b.absorb_index == 1, "Right arrow moves the reward cursor (got %d)" % b.absorb_index)
	await _key(KEY_LEFT)
	_check(b.absorb_index == 0, "Left arrow moves the reward cursor back")
	await _key(KEY_DOWN)
	_check(b.absorb_index == 1, "Down arrow also moves the cursor")

	# 2) Z confirma e libera a batalha (antes: travava para sempre).
	await _key(KEY_Z)
	await process_frame
	_check(b._absorb_layer == null, "Z closes the reward overlay")
	_check(b.absorb_options.is_empty(), "Reward coroutine resumed and cleared its options")
	b.hud.mode = "busy" # o chamador real (_perform_absorption) faz isto

	# 3) X escolhe a primeira opção e também libera a batalha.
	await _open_reward(b)
	await _key(KEY_X)
	await process_frame
	_check(b._absorb_layer == null, "X closes the reward overlay too")
	_check(b.absorb_options.is_empty(), "X resumed the reward coroutine")
	b.hud.mode = "busy"

	# 4) O HUD converte o clique num índice; o headless não atualiza o mouse,
	# então validamos a conversão pura e o envio pelo mesmo caminho do HUD.
	await _open_reward(b)
	var rect := b.absorb_option_rect(2) as Rect2
	_check(b.absorb_option_at(rect.get_center()) == 2, "Mouse hit test finds the third option")
	_check(b.absorb_option_at(Vector2(2, 2)) == -1, "Mouse hit test ignores clicks outside the options")
	b.submit_absorb_choice(2)
	await process_frame
	b.hud.mode = "busy"

	# 5) Teclas continuam chegando ao mash de absorção normal.
	var before: int = b._mash_count
	b.hud.mode = "absorb"
	b._mash_active = true
	await _key(KEY_Z)
	_check(b._mash_count == before + 1, "Z still feeds the absorption mash (got %d)" % b._mash_count)
	b._mash_active = false

	b.queue_free()
	await process_frame
	SurvivalState.clear()
	print("SURVIVAL INPUT CHECKS PASSED: %d FAILED: %d" % [checks, int(failed)])
	quit(1 if failed else 0)
