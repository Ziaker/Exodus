extends SceneTree
## D-064 capture: ABSORB as an immediate 2-ACT action in the real BattlePlayable.
## Frames: plan with a queued FIGHT and ABSORB enabled; the mash opening at once (queue
## still pending); the absorption result; back in the plan with the queue unchanged; ABSORB
## dimmed with 1 free act; the REACT menu without ABSORB.
## Run (not headless):  Godot --path . -s tools/capture_absorb_immediate.gd
## Output folder: env CAPTURE_DIR (absolute), default res://captures/absorb_immediate.

class CapBattle extends "res://scripts/battle/playable_controller.gd":
	func _enemy_skill_pick(_n: int) -> int: return 0
	func _enemy_counter_roll(_e: BattleUnit) -> bool: return false
	func _ai_roll(_a: BattleUnit, _b: BattleUnit) -> int: return BattleMath.RhythmResult.MISS
	func _defender_reaction(_a: BattleUnit, _b: BattleUnit) -> int: return BattleMath.RhythmResult.MISS
	func _absorb_roll() -> float: return 100.0  # only the SP drain absorbs: the whole mash plays

var out := ""


func _initialize() -> void:
	out = OS.get_environment("CAPTURE_DIR")
	if out.is_empty():
		out = ProjectSettings.globalize_path("res://captures/absorb_immediate")
	DirAccess.make_dir_recursive_absolute(out)
	ProgressStore.save_path_override = "user://capture_absorb_immediate_progress.json"
	ProgressStore.clear()
	call_deferred("_run")


func _finalize() -> void:
	ProgressStore.clear()
	ProgressStore.save_path_override = ""


func _save(name: String) -> void:
	await process_frame
	var image: Image = root.get_texture().get_image()
	var path := out.path_join(name + ".png")
	image.save_png(path)
	print("CAPTURED: ", path)


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _wait(battle: Control, modes: Array, seconds: float = 8.0) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while battle.hud.mode not in modes and Time.get_ticks_msec() < deadline:
		await process_frame


func _fresh() -> Control:
	var battle := CapBattle.new()
	battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle.offer_reserve = true
	root.add_child(battle)
	return battle


func _run() -> void:
	var battle := _fresh()
	await _wait(battle, ["plan"])
	await _frames(40)
	var fallen: BattleUnit = battle._fallen
	fallen.acts_available = 4
	battle.hud.opponents[0].current_sp = 10  # 5 presses drain it: guaranteed absorption (D-051)
	battle._refresh_all()
	# 1. FIGHT on FOE B queued, cursor on ABSORB (enabled: 3 free acts).
	battle.submit_plan(battle.hud.plan_options.find("FIGHT"))
	battle.submit_target(1)
	await _frames(30)
	battle.hud.plan_index = battle.hud.plan_options.find("ABSORB")
	battle.hud.queue_redraw()
	await _frames(20)
	await _save("01_plan_fight_queued_absorb_enabled")
	# 2. ABSORB -> target -> the mash opens at once, before EXEC.
	battle.submit_plan(battle.hud.plan_options.find("ABSORB"))
	await _frames(20)
	await _save("02_absorb_choose_target")
	battle.submit_target(0)
	await _frames(12)
	await _save("03_absorb_mash_opens_immediately")
	for i in 5:
		battle.handle_confirm()
		await _frames(10)
	await _save("04_absorb_mash_presses")
	var deadline := Time.get_ticks_msec() + 8000
	var mid_saved := false
	while battle.hud.mode not in ["continue", "plan"] and Time.get_ticks_msec() < deadline:
		if battle.hud.mode == "command" and battle.hud.command_options.size() > 0 and battle.hud.command_options[0].begins_with("+"):
			await _frames(20)
			await _save("05_absorb_gain_choice")
			battle.submit_command(0)
		if not mid_saved and not battle.absorb_fx.pieces.is_empty():
			mid_saved = true
			await _save("05b_absorb_break")
		await process_frame
	# The green ABSORBED label is drawn once the flash animation ends (fx.numbers).
	deadline = Time.get_ticks_msec() + 4000
	while battle.fx.numbers.is_empty() and Time.get_ticks_msec() < deadline:
		await process_frame
	await _frames(2)  # it lives ~0.28 s (heal_flash length at PLAY_SPEED 2x)
	await _save("06_absorb_result")
	for _i in 8:
		if battle.hud.mode in ["continue", "announce"]: battle.proceed()
	await _wait(battle, ["plan"])
	await _frames(40)
	await _save("07_back_to_plan_queue_unchanged")
	print("STATE after absorb: acts=%d planned=%s targets=%s foeA_absorbed=%s" % [fallen.acts_available, battle._planned, battle._planned_targets.map(func(u): return u.display_name if u != null else "-"), battle.hud.opponents[0].absorbed])
	battle.queue_free()
	await _frames(5)

	# 3. One free act: ABSORB dimmed.
	battle = _fresh()
	await _wait(battle, ["plan"])
	await _frames(40)
	battle.submit_plan(battle.hud.plan_options.find("FIGHT"))
	battle.submit_target(1)
	await _frames(20)
	battle.hud.plan_index = battle.hud.plan_options.find("ABSORB")
	battle.hud.queue_redraw()
	await _frames(20)
	await _save("08_absorb_dimmed_one_free_act")
	battle.queue_free()
	await _frames(5)

	# 4. REACT menu: no ABSORB.
	battle = _fresh()
	await _wait(battle, ["plan"])
	await _frames(40)
	battle.submit_command(battle.hud.command_options.find("REACT"))
	battle.submit_command(battle.hud.command_options.find("REACT"))
	await _wait(battle, ["react"])
	battle.select_reactor(0)
	battle.answer_reaction(true)
	await _frames(30)
	await _save("09_react_menu_without_absorb")
	print("REACT options: %s" % [battle.hud.command_options])
	battle.queue_free()
	await _frames(5)

	# 5. Edge: FIGHT queued on FOE A, then FOE A absorbed (the queue keeps its target).
	battle = _fresh()
	await _wait(battle, ["plan"])
	await _frames(40)
	battle._fallen.acts_available = 4
	battle.hud.opponents[0].current_sp = 10
	battle._refresh_all()
	battle.submit_plan(battle.hud.plan_options.find("FIGHT"))
	battle.submit_target(0)
	await _frames(10)
	battle.submit_plan(battle.hud.plan_options.find("ABSORB"))
	battle.submit_target(0)
	for i in 5:
		battle.handle_confirm()
		await _frames(10)
	deadline = Time.get_ticks_msec() + 8000
	while battle.hud.mode not in ["continue", "plan"] and Time.get_ticks_msec() < deadline:
		if battle.hud.mode == "command" and battle.hud.command_options.size() > 0 and battle.hud.command_options[0].begins_with("+"):
			battle.submit_command(0)
		await process_frame
	for _i in 8:
		if battle.hud.mode in ["continue", "announce"]: battle.proceed()
	await _wait(battle, ["plan"])
	await _frames(40)
	await _save("10_queued_target_was_absorbed")
	battle.queue_free()
	await _frames(5)
	quit(0)
