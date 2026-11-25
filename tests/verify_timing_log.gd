extends SceneTree
## TESTE (pedido do criador): as disputas de linha, ponteiros e ataques podem
## acontecer dentro da faixa do battlelog em vez de dentro do cartão do jogador.
## A flag é explícita; o layout padrão precisa continuar idêntico.

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
		if b.hud != null and b.hud.mode in ["react", "announce"] and wanted not in ["react", "announce"]:
			b.proceed()
		await process_frame
	return false


func _run() -> void:
	var sandbox := "user://test_timing_log_guard.json"
	ProgressStore.save_path_override = sandbox
	ProgressStore.clear()
	SurvivalState.reset()
	SurvivalState.patch({
		"encounter_id": "pixie", "seed": 9, "continues": 3,
		"gains": {"max_hp": 0, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": 20},
	})
	var b: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	b.suppress_scene_change = true
	root.add_child(b)
	_check(await _wait_mode(b, "plan"), "Battle ready for the layout test")

	var hud: Control = b.hud
	var log: Rect2 = hud.BATTLE_LOG_RECT
	var default_attack: Rect2 = hud.attack_rail_rect(0)
	var default_defense: Rect2 = hud.defense_rail_rect(0)
	_check(default_attack.position.y < log.position.y,
			"Default attack rail stays in the enemy column, above the log")
	# D-058 (creator 2026-11-25): defenses always run inside the battle log.
	_check(log.encloses(default_defense),
			"Default defense rail sits inside the battlelog (got %s)" % str(default_defense))
	var default_panel: Array = hud.counter_rail_rects("panel", 0)
	_check(log.encloses(default_panel[0]) and log.encloses(default_panel[1]) and not default_panel[0].intersects(default_panel[1]),
			"Default hero-counter rails sit inside the battlelog without overlapping")

	hud.timing_at_log = true
	var attack: Rect2 = hud.attack_rail_rect(0)
	var defense: Rect2 = hud.defense_rail_rect(0)
	var rails: Array = hud.counter_rail_rects("panel", 0)
	_check(log.encloses(attack), "Attack rail moves inside the battlelog (got %s)" % str(attack))
	_check(log.encloses(defense), "Defense rail moves inside the battlelog (got %s)" % str(defense))
	_check(log.encloses(rails[0]) and log.encloses(rails[1]),
			"Both counter rails move inside the battlelog")
	_check(not rails[0].intersects(rails[1]), "The two counter rails do not overlap each other")

	# Disputa real: a trilha usada pelo rhythm é a que o HUD devolveu.
	for unit in b.state.units:
		if unit != b._fallen:
			unit.acts_available = 0
			unit.stored_acts = 0
	b._refresh_all()
	var cmds: Array[String] = b._commands(b._fallen)
	b.submit_plan(cmds.find("FIGHT"))
	b.exec_plan()
	_check(await _wait_mode(b, "target"), "FIGHT asks for a target")
	b.submit_target(0)
	_check(await _wait_mode(b, "timing") or b.hud.mode == "counter",
			"A real attack opens the timing dispute")
	var placed: Rect2 = Rect2(b.rhythm.position, b.rhythm.size)
	_check(log.encloses(placed) or b.hud.mode == "counter",
			"The real timing rail is placed inside the battlelog (got %s)" % str(placed))
	if b.hud.mode == "timing":
		b.rhythm._finish(BattleMath.RhythmResult.POINT)
	else:
		b.counter.finish(BattleMath.RhythmResult.POINT, BattleMath.RhythmResult.MISS)

	b.queue_free()
	await process_frame
	SurvivalState.clear()
	print("TIMING AT LOG CHECKS PASSED: %d FAILED: %d" % [checks, int(failed)])
	quit(1 if failed else 0)
