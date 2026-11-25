extends SceneTree
## Evidência visual do conserto do travamento: teclas REAIS (Input.parse_input_event)
## movem e confirmam o painel ABSORPTION REWARD no mesmo caminho do jogo aberto.

const CAPTURE_DIR := "res://captures/"


func _initialize() -> void:
	call_deferred("_run")


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


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


func _shot(label: String) -> void:
	var img: Image = root.get_texture().get_image()
	var path := CAPTURE_DIR + "absorb_input_%s.png" % label
	img.save_png(ProjectSettings.globalize_path(path))
	print("CAPTURED: ", path)


func _wait_mode(b: Control, wanted: String, limit: int = 240) -> bool:
	for _i in limit:
		if b.hud != null and b.hud.mode == wanted:
			return true
		await process_frame
	return false


func _run() -> void:
	print("ABSORB CAPTURE: start")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	SurvivalState.reset()
	SurvivalState.patch({
		"encounter_id": "pixie", "seed": 13, "continues": 3,
		"gains": {"max_hp": 0, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": 20},
	})
	var b: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	b.suppress_scene_change = true
	root.add_child(b)
	await _wait_mode(b, "plan")
	print("ABSORB CAPTURE: plan mode=", b.hud.mode if b.hud != null else "no hud")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	b.call("_wait_absorb_choice", SurvivalAbsorb.roll_options(rng,
			SurvivalData.demon_by_id("pixie"), [], 1.0))
	await _wait_mode(b, "absorb_choice")
	await _frames(3)
	_shot("01_open")
	await _key(KEY_RIGHT)
	await _key(KEY_RIGHT)
	await _frames(3)
	_shot("02_arrows_work")
	await _key(KEY_Z)
	await _frames(4)
	_shot("03_confirmed")
	print("ABSORB KEYBOARD DONE — index=", b.absorb_index,
			" overlay=", (b._absorb_layer != null), " options=", b.absorb_options.size())

	# Mouse real (janela aberta): warp_mouse atualiza get_local_mouse_position(),
	# que é o que o HUD usa para converter o clique em opção.
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 7
	b.call("_wait_absorb_choice", SurvivalAbsorb.roll_options(rng2,
			SurvivalData.demon_by_id("pixie"), [], 1.0))
	await _wait_mode(b, "absorb_choice")
	var target_rect := b.absorb_option_rect(1) as Rect2
	root.warp_mouse(target_rect.get_center())
	await _frames(2)
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = target_rect.get_center()
	Input.parse_input_event(down)
	await _frames(2)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = target_rect.get_center()
	Input.parse_input_event(up)
	await _frames(4)
	_shot("04_mouse_click")
	print("ABSORB MOUSE DONE — index=", b.absorb_index,
			" overlay=", (b._absorb_layer != null), " options=", b.absorb_options.size(),
			" local=", b.hud.get_local_mouse_position())
	b.queue_free()
	await process_frame
	SurvivalState.clear()
	quit(0)
