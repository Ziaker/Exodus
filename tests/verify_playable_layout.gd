extends SceneTree
const SANDBOX := preload("res://tests/progress_sandbox.gd")

var checks := 0

func _initialize() -> void:
	SANDBOX.begin()
	call_deferred("_run")

func _check(ok: bool, description: String) -> void:
	if not ok:
		push_error(description)
		quit(1)
		assert(ok, description)
	checks += 1

func _new_battle() -> Control:
	var scene: PackedScene = load("res://scenes/battle/BattlePlayable.tscn")
	var battle: Control = scene.instantiate()
	root.add_child(battle)
	battle.rng.seed = 913
	return battle

func _run() -> void:
	if not ResourceLoader.exists("res://scenes/battle/BattlePlayable.tscn"):
		push_error("Playable layout scene is missing")
		quit(1)
		return
	var battle := _new_battle()
	_check(battle.hud.mode == "command", "Real battle must wait for a command")
	_check(battle.hud.players[0] == battle.state.units[0], "HUD must reference real units")
	_check(battle.hud.players[0].current_hp == 14, "HUD must show live HP")
	battle._fallen.current_hp = 1
	battle.submit_command(1) # Existing ITEM command, not a simulated inventory.
	_check(battle._fallen.current_hp == 7, "Item must heal actual HP")
	_check(battle._fallen.current_sp == battle._fallen.sp_base() - 2, "Item must pay existing SP cost")
	_check(battle.hud.mode == "continue", "Player must be able to read item results")
	battle.queue_free()
	await process_frame
	battle = _new_battle()
	battle._fallen.current_en = 0
	battle.submit_command(2)
	_check(battle._fallen.current_en == 1, "Rest must recover actual EN")
	battle.queue_free()
	await process_frame
	battle = _new_battle()
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_DOWN
	battle.hud._input(key)
	_check(battle.hud.command_index == 1, "Down key must navigate real commands")
	key.keycode = KEY_UP
	battle.hud._input(key)
	key.keycode = KEY_Z
	battle.hud._input(key)
	_check(battle.hud.mode == "target", "Attack must ask for a real target")
	battle.cancel_target()
	_check(battle.hud.mode == "command", "Cancel target must return to command menu")
	_check(battle._fallen.acts_available == 2, "Opening/canceling a menu must not spend an act")
	battle.submit_command(0)
	battle.submit_target(1)
	_check(battle.hud.mode == "timing", "Attack must start real rhythm input")
	_check(battle.rhythm._running, "Real rhythm timer must run")
	battle.rhythm._finish(BattleMath.RhythmResult.POINT)
	_check(battle.log_history.any(func(line: String) -> bool: return line.contains("FALLEN -> GENETIC FOE B")), "Chosen enemy must receive the actual attack")
	_check(battle.state.units[2].current_hp == 12, "Unselected enemy must stay untouched")
	battle.queue_free()
	await process_frame
	battle = _new_battle()
	battle.submit_command(3)
	battle.submit_target(0)
	_check(battle._mash_active, "Absorption must accept real presses")
	for i in 12:
		battle.handle_confirm()
	# Absorption mashing lasts 2 s of timers; headless frames run faster than
	# 60 fps, so wait on real time (5 s cap) instead of a fixed frame count.
	var mash_deadline := Time.get_ticks_msec() + 5000
	while battle._mash_active and Time.get_ticks_msec() < mash_deadline:
		await process_frame
	_check(battle.state.units[2].absorbed, "Successful absorption must mark the real target")
	_check(battle._fallen.stats.max_hp > 14, "Absorption must grant actual attributes")
	battle.queue_free()
	await process_frame
	battle = _new_battle()
	for frame in 2400:
		match battle.hud.mode:
			"command": battle.submit_command(0)
			"target": battle.submit_target(battle.first_living_target())
			"timing": battle.rhythm._finish(BattleMath.RhythmResult.POINT)
			"react": battle.answer_reaction(true)
			"continue", "announce": battle.proceed()
			"result": break
		await process_frame
	_check(battle.hud.mode == "result", "Battle must reach a real end state")
	_check(battle.state.player_victory(), "Controlled successful inputs should win this seeded battle")
	_check(battle.log_history.has("VICTORY."), "Victory must appear in the battle log")
	battle.queue_free()
	await process_frame
	battle = _new_battle()
	# A second full run with failed physical input and no defense exercises defeat.
	for frame in 2400:
		match battle.hud.mode:
			"command": battle.submit_command(0)
			"target": battle.submit_target(battle.first_living_target())
			"timing": battle.rhythm._finish(BattleMath.RhythmResult.MISS)
			"react": battle.answer_reaction(false)
			"continue", "announce": battle.proceed()
			"result": break
		await process_frame
	_check(battle.hud.mode == "result", "Failed-input battle must finish")
	_check(battle.log_history.has("DEFEAT."), "Defeat must appear in the battle log")
	current_scene = battle
	battle.handle_confirm()
	await process_frame
	await process_frame
	battle = current_scene
	_check(battle != null and battle.hud.mode == "command", "Restart must launch a fresh playable battle")
	_check(battle._fallen.current_hp == 14 and battle.state.round_number == 1, "Restart must restore battle resources")
	# Creator decision: Restart after DEFEAT starts at base attributes but keeps the save.
	var kept: Dictionary = ProgressStore.load_gains()
	_check(int(kept.get("max_hp", 0)) > 0, "Defeat restart must keep the saved absorption gains (got %s)" % kept)
	_check(battle._fallen.stats.max_hp == 14, "Defeat restart must ignore saved gains for this battle")
	# A later battle (not a defeat restart) applies the kept gains again.
	var later: Control = load("res://scenes/battle/BattlePlayable.tscn").instantiate()
	root.add_child(later)
	_check(later._fallen.stats.max_hp == 14 + int(kept["max_hp"]), "The next normal battle applies the saved gains")
	later.queue_free()
	battle.queue_free()
	await process_frame
	print("PLAYABLE_LAYOUT_OK: %d checks; live resources, keyboard, item/rest, cancel, targeting, absorption, victory, defeat, restart" % checks)
	quit(0)

func _finalize() -> void:
	SANDBOX.end()
