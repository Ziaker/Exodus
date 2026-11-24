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
	_check(battle.hud.mode == "plan", "Real battle must wait for the D-046 plan")
	# D-034: the drawn rail must use the configured POINT width, not a fixed 10%.
	for half in [BattleMath.POINT_MIN_HALF_WIDTH, BattleMath.POINT_MAX_HALF_WIDTH]:
		battle.rhythm.configure(half)
		var spans: Array[Vector2] = battle.rhythm.zone_spans()
		_check(is_equal_approx(spans[1].y - spans[1].x, half * 2.0), "Drawn POINT width must follow configure(%s)" % half)
		_check(is_equal_approx((spans[1].x + spans[1].y) / 2.0, 0.5), "Drawn POINT must stay centered")
		_check(is_equal_approx(spans[0].x, 0.5 - BattleMath.BEAM_HALF_WIDTH) and is_equal_approx(spans[2].y, 0.5 + BattleMath.BEAM_HALF_WIDTH), "Drawn BEAM must use the real width")
	battle.rhythm.configure(BattleMath.POINT_HALF_WIDTH)
	# exodus_feedback_lab.html geometry, D-055 816 x 624 (sizes kept, stage drawn 1.5x).
	var hud: Control = battle.hud
	_check(hud.enemy_column(0) == Rect2(128, 212, 220, 206) and hud.enemy_column(1) == Rect2(468, 212, 220, 206), "Enemy columns must follow the HTML space-evenly layout")
	_check(is_equal_approx(hud.enemy_sprite_rect(0).end.y / hud.STAGE_SCALE, 252.0) or is_equal_approx(hud.enemy_horizon / hud.STAGE_SCALE, 252.0), "D-055: enemy feet on the scaled floor line (old 252 x 1.5)")
	_check(battle.stage.size == hud.STAGE_RECT.size and hud.STAGE_RECT.size == Vector2(544, 298) * hud.STAGE_SCALE, "D-055/D-053: stage D fills the width at 1.5x")
	_check(hud.LOG_LINES == 3 and hud.BATTLE_LOG_RECT.end.y <= hud.STATUS_RECTS[0].position.y, "D-055: 3-line Battle Log above the status panels")
	for i in 2:
		var art: Rect2 = hud.enemy_sprite_rect(i)
		var box := Rect2(hud.enemy_column(i).position + Vector2(32, 0), Vector2(156, 166))
		_check(box.grow(0.01).encloses(art) and is_equal_approx(art.end.y, box.end.y), "Silhouette %d must fit the HTML sprite box and stand on its floor" % i)
		_check(hud.STAGE_RECT.encloses(art), "Silhouette must be on the stage")
	_check(hud.STATUS_RECTS[0] == Rect2(8, 540, 168, 77) and hud.STATUS_RECTS[1] == Rect2(182, 540, 168, 77), "Status windows keep the HTML size (D-055 position)")
	_check(hud.COMMAND_RECT == Rect2(628, 540, 180, 77), "Command window keeps the HTML size (D-055 position)")
	_check(hud._round_caption() == "ROUND 01", "Header must show the HTML round label")
	await process_frame
	await process_frame
	_check(hud._menu_rows().size() == 7 and hud._menu_rows()[4] == "REACT", "D-046: Fallen menu lists five commands plus EXEC and UNDO")
	var first_row: Rect2 = hud.hitboxes.filter(func(h: Dictionary) -> bool: return String(h.key) == "live-plan:0")[0].rect
	_check(first_row.position.y == hud.COMMAND_RECT.position.y + 3, "D-046: the title is hidden and plan rows start at the top of the command window")
	# Silhouettes: opaque pixels plus enclosed dither holes become one solid mask.
	var ring := Image.create_empty(5, 5, false, Image.FORMAT_RGBA8)
	for p in [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(1, 2), Vector2i(3, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3)]:
		ring.set_pixelv(p, Color.RED)
	var mask: Image = hud.make_silhouette(ring)
	_check(mask.get_pixel(2, 2).a == 1.0 and mask.get_pixel(1, 1) == Color.WHITE, "Enclosed holes must be filled; shape pixels become the white mask")
	# D-055: Battle Log with 3 visible lines (newest at the bottom); menu explanations
	# are transient and never pushed into the history.
	var saved_mode: String = hud.mode
	var saved_message: String = hud.message
	var saved_lines: Array[String] = hud.log_lines.duplicate()
	hud.mode = "command"
	hud.log_lines.clear()
	for text in ["LOG A", "LOG B", "LOG B", "LOG C", "LOG D"]:
		hud.message = text
		hud.visible_log_lines()
	_check(hud.visible_log_lines() == ["LOG B", "LOG C", "LOG D"], "D-055: the log shows the last 3 distinct lines, oldest first")
	hud.mode = "absorb"
	var shown: Array[String] = hud.visible_log_lines()
	_check(shown.size() == 3 and shown[0] == "LOG C" and shown[2].begins_with("ABSORB [Z]"), "D-055: a transient line (absorb mash) is the newest line while it lasts")
	_check(hud.log_lines[-1] == "LOG D", "D-055: transient lines are not kept in the history")
	hud.mode = "command"
	_check(hud.visible_log_lines() == ["LOG B", "LOG C", "LOG D"], "D-055: the transient line goes away with its mode")
	hud.mode = saved_mode
	hud.message = saved_message
	hud.log_lines.assign(saved_lines)
	for i in 3:
		var baseline: float = hud.BATTLE_LOG_RECT.position.y + 0.5 + 15.5 + i * hud.LOG_STEP
		_check(baseline <= hud.BATTLE_LOG_RECT.end.y and baseline + 4 < hud.STATUS_RECTS[0].position.y, "D-055: log line %d inside the log rect, above the panels" % (i + 1))
	_check(mask.get_pixel(0, 0).a == 0.0 and mask.get_pixel(4, 2).a == 0.0, "Outside transparency must stay transparent")
	_check(hud.silhouettes.size() == 2 and hud.silhouettes[0].get_size() == hud.battler_regions[0].size, "One silhouette per SMT battler, same size as its art")
	# Silhouette: drawn with a black modulate; the whiten ghost starts at alpha 128/255.
	_check(is_equal_approx(battle.fx.whiten_alpha(0.0), 128.0 / 255.0) and is_equal_approx(battle.fx.whiten_alpha(0.026), 118.0 / 255.0) and battle.fx.whiten_alpha(0.33) == 0.0 and battle.fx.whiten_alpha(0.41) == 0.0, "Whiten must follow RPG::Sprite#whiten (128, -10/frame at 40 fps)")
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
	_check(battle._fallen.current_en == BattleMath.REST_EN_RECOVERY, "D-038: REST must recover exactly 2 EN flat")
	_check(battle._fallen.acts_available == 0 and battle._fallen.stored_acts == 2, "D-038: REST spends no act, stores the remaining two and ends participation")
	battle.queue_free()
	await process_frame
	battle = _new_battle()
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_DOWN
	battle.hud._input(key)
	_check(battle.hud.plan_index == 1, "Down key must navigate the D-046 plan rows")
	key.keycode = KEY_UP
	battle.hud._input(key)
	key.keycode = KEY_Z
	battle.hud._input(key)
	_check(battle._planned.size() == 1, "Z must commit the highlighted plan command")
	battle.exec_plan()
	_check(battle.hud.mode == "target", "Executing an ATTACK plan must ask for a real target")
	battle.cancel_target()
	_check(battle.hud.mode == "plan", "Cancel target must return to the D-046 plan")
	_check(battle._fallen.acts_available == 2, "Opening/canceling a menu must not spend an act")
	battle.submit_command(0)
	battle.submit_target(1)
	# D-049: the attacked enemy may counter-attack (33%), opening the two rails instead.
	_check(battle.hud.mode in ["timing", "counter"], "Attack must start real rhythm input")
	if battle.hud.mode == "timing":
		_check(battle.rhythm._running, "Real rhythm timer must run")
		battle.rhythm._finish(BattleMath.RhythmResult.POINT)
	else:
		_check(battle.counter.running, "Real counter rails must run")
		battle.counter.finish(BattleMath.RhythmResult.POINT, BattleMath.RhythmResult.MISS)
	_check(battle.log_history.any(func(line: String) -> bool: return line.contains("FALLEN -> GENETIC FOE B")), "Chosen enemy must receive the actual attack")
	_check(battle.state.units[2].current_hp == 12, "Unselected enemy must stay untouched")
	battle.queue_free()
	await process_frame
	battle = _new_battle()
	battle.state.units[2].current_sp = 10  # D-051: drained by the presses, absorption guaranteed
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
	# D-052: on success the hit and the break into letters (~2.3 s) play before the target
	# is consumed, so wait for the absorption itself (real time, 6 s cap).
	var break_deadline := Time.get_ticks_msec() + 6000
	while not battle.state.units[2].absorbed and Time.get_ticks_msec() < break_deadline:
		await process_frame
	_check(battle.state.units[2].absorbed, "Successful absorption must mark the real target")
	_check(battle._fallen.stats.max_hp > 14, "Absorption must grant actual attributes")
	battle.queue_free()
	await process_frame
	battle = _new_battle()
	for frame in 2400:
		match battle.hud.mode:
			"command", "plan": battle.submit_command(0)
			"target": battle.submit_target(battle.first_living_target())
			"timing": battle.rhythm._finish(BattleMath.RhythmResult.POINT)
			"counter": battle.counter.finish(BattleMath.RhythmResult.POINT, BattleMath.RhythmResult.MISS)
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
	var before_death: Dictionary = ProgressStore.load_gains()
	_check(int(before_death.get("max_hp", 0)) > 0, "The victory run must have stored gains (got %s)" % before_death)
	# A second full run with failed physical input and no defense exercises Fallen's death.
	for frame in 2400:
		match battle.hud.mode:
			"command", "plan": battle.submit_command(0)
			"target": battle.submit_target(battle.first_living_target())
			"timing": battle.rhythm._finish(BattleMath.RhythmResult.MISS)
			"counter": battle.counter.finish(BattleMath.RhythmResult.MISS, BattleMath.RhythmResult.POINT)
			"react": battle.answer_reaction(false)
			"continue", "announce": battle.proceed()
			"result", "death": break
		await process_frame
	# Creator 2026-11-23: Fallen's death plays the death cutscene and goes to the title.
	_check(battle.hud.mode == "death", "Failed-input battle must end in Fallen's death (mode %s)" % battle.hud.mode)
	_check(not battle._fallen.is_alive() and battle.log_history.has("DEFEAT."), "Defeat must appear in the battle log")
	_check(battle.death_cutscene != null and battle.death_cutscene.is_inside_tree(), "The death cutscene must play")
	var kept: Dictionary = ProgressStore.load_gains()
	for stat in before_death.keys():
		var gain := int(before_death[stat])
		_check(int(kept[stat]) == gain - gain / 2, "Death keeps the larger half of %s (+%d -> got +%d)" % [stat, gain, int(kept[stat])])
	current_scene = battle
	var deadline := Time.get_ticks_msec() + 30000
	while current_scene == battle and Time.get_ticks_msec() < deadline:
		await process_frame
	await process_frame
	_check(current_scene != null and current_scene.scene_file_path == "res://scenes/title/Title.tscn", "After the cutscene the game returns to the title screen (got %s)" % (current_scene.scene_file_path if current_scene != null else "null"))
	# The next battle starts with the halved gains applied (no more base-attribute restart).
	var later: Control = load("res://scenes/battle/BattlePlayable.tscn").instantiate()
	root.add_child(later)
	_check(later._fallen.stats.max_hp == 14 + int(kept["max_hp"]), "The next battle applies the halved gains")
	later.queue_free()
	await process_frame
	print("PLAYABLE_LAYOUT_OK: %d checks; live resources, keyboard, item/rest, cancel, targeting, absorption, victory, death, title" % checks)
	quit(0)

func _finalize() -> void:
	SANDBOX.end()
