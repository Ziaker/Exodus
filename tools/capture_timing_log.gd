extends SceneTree
## Capturas do TESTE de layout: disputa de linha/ponteiro/ataque dentro do
## battlelog (flag HUD.timing_at_log) contra o layout original no cartão.

const CAPTURE_DIR := "res://captures/"


func _initialize() -> void:
	call_deferred("_run")


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _shot(label: String) -> void:
	var img: Image = root.get_texture().get_image()
	var path := CAPTURE_DIR + "timing_%s.png" % label
	img.save_png(ProjectSettings.globalize_path(path))
	print("CAPTURED: ", path)


func _wait_mode(b: Control, wanted: String, limit: int = 240) -> bool:
	for _i in limit:
		if b.hud != null and b.hud.mode == wanted:
			return true
		if b.hud != null and b.hud.mode in ["react", "announce"] and wanted not in ["react", "announce"]:
			b.proceed()
		await process_frame
	return false


func _freeze(b: Control) -> void:
	for unit in b.state.units:
		if unit != b._fallen:
			unit.acts_available = 0
			unit.stored_acts = 0
	b._refresh_all()


func _attack_dispute(at_log: bool, label: String) -> void:
	SurvivalState.reset()
	SurvivalState.patch({
		"encounter_id": "pixie", "seed": 9, "continues": 3,
		"gains": {"max_hp": 0, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": 20},
	})
	var b: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	b.suppress_scene_change = true
	root.add_child(b)
	await _wait_mode(b, "plan")
	b.hud.timing_at_log = at_log
	_freeze(b)
	await _wait_mode(b, "plan")
	var cmds: Array[String] = b._commands(b._fallen)
	b.submit_plan(cmds.find("FIGHT"))
	b.exec_plan()
	await _wait_mode(b, "target")
	b.submit_target(0)
	await _wait_mode(b, "timing")
	await _frames(12)
	_shot(label)
	b.queue_free()
	await _frames(2)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	await _attack_dispute(false, "01_card_default")
	await _attack_dispute(true, "02_log_attack")

	# Disputa de dois ponteiros (contra-ataque) desenhada dentro do battlelog.
	SurvivalState.reset()
	SurvivalState.patch({
		"encounter_id": "pixie", "seed": 9, "continues": 3,
		"gains": {"max_hp": 0, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": 20},
	})
	var b: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	b.suppress_scene_change = true
	root.add_child(b)
	await _wait_mode(b, "plan")
	b.hud.timing_at_log = true
	var rails: Array = b.hud.counter_rail_rects("panel", 0)
	b.hud.mode = "counter"
	b.counter.start("panel", rails[0], rails[1], 1.6, 1.6,
			BattleMath.POINT_HALF_WIDTH, BattleMath.POINT_HALF_WIDTH, 0.8)
	await _frames(26)
	_shot("03_log_counter")
	b.queue_free()
	await _frames(2)
	SurvivalState.clear()
	print("TIMING LOG CAPTURES DONE")
	quit(0)
