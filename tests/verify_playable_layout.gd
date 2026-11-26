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

func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	return e


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
	# Layout 544 x 416 shown 1.5x on the 816 x 624 screen (creator 2026-11-24, fixes D-055);
	# HUD option 13 (prototypes/combat-hud-html): its 816 x 624 pixels / 1.5.
	var hud: Control = battle.hud
	var shift: float = hud.STAGE_SHIFT
	var down := 24.0
	_check(is_equal_approx(shift * 1.5, -32.0), "Stage art raised 32 screen px (21.33 layout px)")
	_check(root.content_scale_size == Vector2i(544, 416) and root.content_scale_stretch == Window.CONTENT_SCALE_STRETCH_FRACTIONAL, "The battle is laid out at 544 x 416 and shown 1.5x (fractional content scale)")
	_check(hud.SCREEN == Vector2(544, 416) and ProjectSettings.get_setting("display/window/size/viewport_width") == 816, "Layout 544 x 416 on the D-055 816 x 624 screen")
	_check(hud.enemy_column(0).is_equal_approx(Rect2(17, 86 + shift + down, 220, 206)) and hud.enemy_column(1).is_equal_approx(Rect2(247, 86 + shift + down, 220, 206)), "Enemy columns: 10 px gap, shrunk only for 3 demons (option 13)")
	_check(is_equal_approx(hud.enemy_sprite_rect(0).end.y, 252.0 + shift + down) or is_equal_approx(hud.enemy_horizon, 252.0 + shift + down), "Enemy feet on the floor line, 36 screen px lower")
	_check(is_equal_approx(battle.stage.position.y, shift) and is_equal_approx(battle.stage.position.y + battle.stage.size.y, hud.SCREEN.y) and hud.STAGE_RECT == Rect2(0, 0, 544, hud.BATTLE_LOG_RECT.position.y), "Stage D raised and running to the bottom of the screen; battlefield down to the log")
	_check(battle.stage.material.get_shader_parameter("stage_size") == battle.stage.size, "The stage shader draws 1:1 (floor continues, not stretched)")
	# Option 13 windows (prototype px / 1.5).
	var win := func(x: float, y: float, w: float, h: float) -> Rect2: return Rect2(x / 1.5, y / 1.5, w / 1.5, h / 1.5)
	_check(hud.BATTLE_LOG_RECT.is_equal_approx(win.call(8, 450, 800, 88)), "Log window: 8, 450, 800 x 88 on screen (two lines, D-056)")
	_check(hud.STATUS_RECTS[0].is_equal_approx(win.call(8, 546, 293, 66)) and hud.STATUS_RECTS[1].is_equal_approx(win.call(309, 546, 293, 66)), "Hero windows: 293 x 66 at 8 and 309, y 546 on screen")
	_check(is_equal_approx(hud.COMMAND_RECT.end.y, hud.BATTLE_LOG_RECT.position.y - 3.0) and is_equal_approx(hud.COMMAND_RECT.position.x, hud.BATTLE_LOG_RECT.position.x), "Choice menu: vertical column anchored right above the log (creator 2026-11-26)")
	_check(hud.SP_TRACK.position.y < 15 and hud.HEADER_BASELINE < 16, "Round, SP names and SP bar share one thin top line")
	_check(hud.LOG_LINES == 2 and hud.LOG_FIRST_BASELINE + (hud.LOG_LINES - 1) * hud.LOG_STEP + 3 <= hud.BATTLE_LOG_RECT.end.y, "2 log lines inside the log window (D-056)")
	_check(hud.BATTLE_LOG_RECT.position.y >= hud.enemy_column(0).end.y - 30 + 4, "The log stays under the enemies' name labels")
	_check(battle.fx.HERO_NUMBER_PX == 20 and is_equal_approx(battle.fx.HERO_NUMBER_TIME, 0.5), "Heroes' damage numbers: 20 px, half the time")
	for i in 2:
		var art: Rect2 = hud.enemy_sprite_rect(i)
		var box := Rect2(hud.enemy_column(i).position + Vector2(32, 0), Vector2(156, 166))
		_check(box.grow(0.01).encloses(art) and is_equal_approx(art.end.y, box.end.y), "Silhouette %d must fit the HTML sprite box and stand on its floor" % i)
		_check(hud.STAGE_RECT.encloses(art), "Silhouette must be on the stage")
	_check(hud._round_caption() == "ROUND 01", "Header must show the HTML round label")
	await process_frame
	await process_frame
	# Creator 2026-11-24: no REACT on the own turn, no EXEC/UNDO before something is queued.
	# D-105 (creator 2026-11-25): PASS right before REST.
	_check(hud._menu_rows() == ["FIGHT", "ITEM", "PASS", "REST", "ABSORB"], "Fallen's empty plan lists FIGHT, ITEM, PASS, REST, ABSORB only (%s)" % [hud._menu_rows()])
	_check(hud._choosing_unit() == battle._fallen, "The arrow marks Fallen as the one choosing")
	var first_row: Rect2 = hud.hitboxes.filter(func(h: Dictionary) -> bool: return String(h.key) == "live-plan:0")[0].rect
	var menu_win: Rect2 = hud.menu_rect(5)
	_check(menu_win.encloses(first_row) and is_equal_approx(first_row.position.y, menu_win.position.y + 2) and is_equal_approx(menu_win.end.y, hud.COMMAND_RECT.end.y) and menu_win.end.y < hud.BATTLE_LOG_RECT.position.y, "Plan cells start at the top of the menu, which ends above the log")
	var cells: Array = hud.hitboxes.filter(func(h: Dictionary) -> bool: return String(h.key).begins_with("live-plan:"))
	_check(cells.size() == 5 and is_equal_approx(cells[2].rect.position.x, first_row.position.x) and cells[1].rect.position.y > first_row.position.y and cells[4].rect.position.y > cells[3].rect.position.y, "One vertical column: FIGHT, ITEM, PASS, REST, ABSORB top to bottom")
	for c in ["FIGHT", "ITEM", "PASS", "REST", "ABSORB", "DEFEND", "PRAY", "EXEC", "UNDO", "REACT", "DENY"]:
		_check(hud._width(c, hud.COMMAND_PX, true) + hud.MENU_TEXT_X <= cells[0].rect.size.x, "%s fits its command cell (%.1f + %.1f > %.1f)" % [c, hud._width(c, hud.COMMAND_PX, true), hud.MENU_TEXT_X, cells[0].rect.size.x])
	battle.submit_plan(1)
	await process_frame
	_check(hud.mode == "plan" and hud._menu_rows() == ["FIGHT", "ITEM", "PASS", "REST", "ABSORB", "EXEC", "UNDO"], "Once something is queued, EXEC and UNDO appear (%s)" % [hud._menu_rows()])
	hud._input(_key(KEY_RIGHT)); _check(hud.plan_index == 1, "Right moves one cell in the grid")
	# O HUD agora escolhe 3, 2 ou 1 coluna conforme o rótulo caiba (D-055).
	var cols: int = hud.menu_columns()
	hud._input(_key(KEY_DOWN))
	_check(hud.plan_index == posmod(1 + cols, hud.plan_options.size()),
			"Down moves one row (%d columns)" % cols)
	battle.undo_plan()
	await process_frame
	_check(hud._menu_rows() == ["FIGHT", "ITEM", "PASS", "REST", "ABSORB"], "UNDO of the only command hides EXEC/UNDO again")
	# Silhouettes: opaque pixels plus enclosed dither holes become one solid mask.
	var ring := Image.create_empty(5, 5, false, Image.FORMAT_RGBA8)
	for p in [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(1, 2), Vector2i(3, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3)]:
		ring.set_pixelv(p, Color.RED)
	var mask: Image = hud.make_silhouette(ring)
	_check(mask.get_pixel(2, 2).a == 1.0 and mask.get_pixel(1, 1) == Color.WHITE, "Enclosed holes must be filled; shape pixels become the white mask")
	# D-056 (2 visible lines, newest at the bottom) + D-057 (creator 2026-11-25): the log
	# holds only event lines pushed by the controller; unread lines show oldest first and
	# Z pages the rest; menu explanations stay transient and never enter the history.
	var saved_mode: String = hud.mode
	var saved_message: String = hud.message
	var saved_events: Array[Dictionary] = []
	saved_events.assign(hud.events)
	var saved_read: int = hud.events_read
	hud.mode = "command"
	hud.events.clear()
	hud.events_read = 0
	hud.message = "Choose enemy: Left / Right or click. Z: confirm. X: back."
	_check(hud.visible_log_lines().is_empty(), "D-057: instructions never enter the log")
	for text in ["LOG A", "LOG B", "LOG C", "LOG D"]:
		hud.push_event(text)
	_check(hud.visible_log_lines() == ["LOG A", "LOG B"] and hud.log_hidden(), "D-057: unread lines show oldest first; the rest waits (%s)" % [hud.visible_log_lines()])
	hud.page_log()
	_check(hud.visible_log_lines() == ["LOG C", "LOG D"] and not hud.log_hidden(), "D-057: Z pages to the next unread lines")
	hud.page_log()
	_check(hud.visible_log_lines() == ["LOG C", "LOG D"], "D-056: once read, the log shows the last 2 lines, oldest first")
	hud.mode = "absorb"
	var shown: Array[String] = hud.visible_log_lines()
	_check(shown.size() == 2 and shown[0] == "LOG D" and shown[1].begins_with("ABSORB [Z]"), "D-055: a transient line (absorb mash) is the newest line while it lasts")
	_check(String(hud.events[-1].text) == "LOG D", "D-055: transient lines are not kept in the history")
	hud.mode = "command"
	_check(hud.visible_log_lines() == ["LOG C", "LOG D"], "D-055: the transient line goes away with its mode")
	hud.mode = saved_mode
	hud.message = saved_message
	hud.events.assign(saved_events)
	hud.events_read = saved_read
	for i in hud.LOG_LINES:
		var baseline: float = hud.LOG_FIRST_BASELINE + i * hud.LOG_STEP
		_check(baseline <= hud.BATTLE_LOG_RECT.end.y - 1.0 and baseline + 4 < hud.STATUS_RECTS[0].position.y, "D-056: log line %d inside the log rect, above the panels" % (i + 1))
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
	battle.submit_command(battle.hud.command_options.find("REST"))  # D-105: PASS sits before REST
	_check(battle._fallen.current_en == BattleMath.REST_EN_RECOVERY, "D-038: REST must recover exactly 2 EN flat")
	_check(battle._fallen.acts_available == 0 and battle._fallen.stored_acts == 2, "D-038: REST spends no act, stores the remaining two and ends participation")
	battle.queue_free()
	await process_frame
	battle = _new_battle()
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_DOWN
	battle.hud._input(key)
	_check(battle.hud.plan_index == 1, "Down key moves one row of the vertical plan column")
	key.keycode = KEY_UP
	battle.hud._input(key)
	key.keycode = KEY_Z
	battle.hud._input(key)
	# D-057 (creator 2026-11-25): the ATTACK asks for its real target while planning.
	_check(battle.hud.mode == "target", "Z on ATTACK must ask for a real target while planning")
	battle.cancel_target()
	_check(battle.hud.mode == "plan" and battle._planned.is_empty(), "Cancel target must return to the D-046 plan without queuing the command")
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
	battle.submit_command(battle.hud.command_options.find("ABSORB"))  # D-105: PASS shifted ABSORB
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
	_check(later._fallen.stats.max_hp == 14 + int(kept["max_hp"]), "The next battle applies the halved gains (max_hp %d, kept %s, now %s)" % [later._fallen.stats.max_hp, kept, ProgressStore.load_gains()])
	later.queue_free()
	# Let the audio thread release the death music before quitting (no leak report).
	await create_timer(0.5).timeout
	print("PLAYABLE_LAYOUT_OK: %d checks; live resources, keyboard, item/rest, cancel, targeting, absorption, victory, death, title" % checks)
	quit(0)

func _finalize() -> void:
	SANDBOX.end()
