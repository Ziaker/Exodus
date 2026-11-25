extends SceneTree
## D-103 (creator, 2026-11-25): the absorption mash only counts presses; the result
## (SP taken, the single roll, the absorption) is applied once, when the 2 s run out or
## at the 10th press, whichever comes first; no press is counted after that.
## Runs the real BattlePlayable (PlayableController) with real key events.
const SANDBOX := preload("res://tests/progress_sandbox.gd")

class ResultBattle extends "res://scripts/battle/playable_controller.gd":
	var rolls := 0
	var roll_value := 100.0
	var results := 0
	func _enemy_skill_pick(_n: int) -> int: return 0
	func _enemy_counter_roll(_e: BattleUnit) -> bool: return false
	func _absorb_roll() -> float:
		rolls += 1
		return roll_value
	func _on_absorb_result(u: BattleUnit, d: BattleUnit, r: Dictionary) -> void:
		results += 1
		super._on_absorb_result(u, d, r)

var checks := 0


func _initialize() -> void:
	SANDBOX.begin()
	call_deferred("_run")


func check(ok: bool, reason: String) -> void:
	if not ok:
		push_error(reason)
		quit(1)
		assert(ok, reason)
	checks += 1


func _key_z() -> void:
	var down := InputEventKey.new()
	down.keycode = KEY_Z
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var up := InputEventKey.new()
	up.keycode = KEY_Z
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame


func vfx_letters(b: Control) -> int:
	return b.get_node("AbsorbVFX").letters_sent


func fresh() -> ResultBattle:
	var battle := ResultBattle.new()
	battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(battle)
	return battle


## Opens the mash on FOE A: ABSORB, target 0. Returns when the mash accepts presses.
func open_mash(battle: ResultBattle, foe_sp: int, fallen_sp: int) -> BattleUnit:
	var foe: BattleUnit = battle.hud.opponents[0]
	foe.current_sp = foe_sp
	battle._fallen.current_sp = fallen_sp
	battle.submit_command(battle.hud.command_options.find("ABSORB"))
	if battle.hud.mode == "target":
		battle.submit_target(0)
	for _i in 120:
		if battle._mash_active: break
		await process_frame
	check(battle._mash_active and battle.hud.mode == "absorb", "ABSORB opens the mash (mode %s)" % battle.hud.mode)
	return foe


func _run() -> void:
	# 1) No gain per press: real Z presses only count. SP, roll, stats and the target
	#    stay as they were until the result.
	var b := fresh()
	var foe := await open_mash(b, 10, 30)
	var stats_before := [b._fallen.stats.atk, b._fallen.stats.mak, b._fallen.stats.defense,
		b._fallen.stats.mef, b._fallen.stats.agi, b._fallen.stats.max_hp, b._fallen.stats.max_en]
	var vfx: Node2D = b.get_node("AbsorbVFX")
	for i in 7:
		await _key_z()
		check(b._mash_count == i + 1, "Real Z press %d is counted (got %d)" % [i + 1, b._mash_count])
		check(foe.current_sp == 10, "No SP is taken per press (foe SP %d after %d presses)" % [foe.current_sp, i + 1])
		check(b._fallen.current_sp == 30, "No SP reaches Fallen per press (got %d)" % b._fallen.current_sp)
		check(b.rolls == 0 and b.results == 0, "No roll and no result per press")
		check(not foe.absorbed and foe.is_alive(), "Nothing is absorbed per press, even past the 5 presses that would drain 10 SP")
	var stats_now := [b._fallen.stats.atk, b._fallen.stats.mak, b._fallen.stats.defense,
		b._fallen.stats.mef, b._fallen.stats.agi, b._fallen.stats.max_hp, b._fallen.stats.max_en]
	check(stats_now == stats_before, "No attribute/HP/EN gain per press")
	# D-052 kept by the creator (2026-11-25): the green letters still leave per press.
	check(vfx.letters_sent == 7 * vfx.MASH_LETTERS, "Letters leave on every counted press (got %d)" % vfx.letters_sent)
	b.queue_free(); await process_frame

	# 2) Result applied at timeout: 3 presses, the window closes after 2 s of game time
	#    with ONE roll; failure keeps the 6 SP taken (D-051).
	b = fresh()
	b.roll_value = 99.0
	foe = await open_mash(b, 500, 0)
	var opened_ms := Time.get_ticks_msec()
	for _i in 3:
		await _key_z()
	check(b._mash_active and b.results == 0, "Below 10 presses the mash waits for the time")
	var deadline := Time.get_ticks_msec() + 6000
	while b._mash_active and Time.get_ticks_msec() < deadline:
		await process_frame
	var waited := Time.get_ticks_msec() - opened_ms
	check(not b._mash_active, "The mash closes when the time runs out")
	check(waited >= 1900, "The timeout result comes after the 2 s window (%d ms)" % waited)
	await process_frame
	check(b.results == 1 and b.rolls == 1, "Exactly one result and one roll at timeout (results %d, rolls %d)" % [b.results, b.rolls])
	check(foe.current_sp == 494 and b._fallen.current_sp == 6, "Timeout result moves 3 x 2 SP once (foe %d, Fallen %d)" % [foe.current_sp, b._fallen.current_sp])
	check(b.absorb_chance == 6, "Chance = 0 gap + 6 SP taken (got %d)" % b.absorb_chance)
	check(not foe.absorbed, "A roll over the chance fails")
	check(b.log_history.any(func(l: String) -> bool: return l.contains("resisted (6 SP taken, chance 6%)")), "Failure log reports the single chance")
	b.queue_free(); await process_frame

	# 3) Result applied immediately at the 10th press, long before the 2 s.
	b = fresh()
	b.roll_value = 100.0
	foe = await open_mash(b, 500, 0)
	opened_ms = Time.get_ticks_msec()
	for _i in 9:
		b.handle_confirm()
	check(b._mash_active and b._mash_count == 9, "Nine presses keep the mash open")
	await process_frame
	check(b.results == 0 and foe.current_sp == 500, "Nothing applied before the 10th press")
	b.handle_confirm()
	check(b._mash_count == 10 and not b._mash_active, "The 10th press closes the mash at once")
	var resolved_ms := Time.get_ticks_msec() - opened_ms
	check(b.results == 1 and b.rolls == 1, "The result is applied by the 10th press itself, same frame (results %d, rolls %d)" % [b.results, b.rolls])
	check(vfx_letters(b) == 10 * b.get_node("AbsorbVFX").MASH_LETTERS, "All 10 presses sent their letters by then")
	check(resolved_ms < 1500, "The 10th press does not wait for the 2 s (%d ms)" % resolved_ms)
	check(foe.current_sp == 480 and b._fallen.current_sp == 20, "10 presses move 20 SP once (foe %d, Fallen %d)" % [foe.current_sp, b._fallen.current_sp])

	# 4) No more input counted after that (real key events and direct confirms).
	await _key_z()
	await _key_z()
	b.handle_confirm()
	b.register_mash_press()
	check(b._mash_count == 10, "Presses after the 10th are not counted (got %d)" % b._mash_count)
	check(foe.current_sp == 480 and b._fallen.current_sp == 20, "Late presses move no SP")
	check(b.rolls == 1 and b.results == 1, "Late presses never roll or resolve again")
	b.queue_free(); await process_frame

	# 5) Guaranteed absorption at the result: 10 SP drained by the counted presses
	#    absorbs even though the roll misses, and only once.
	b = fresh()
	b.roll_value = 100.0
	foe = await open_mash(b, 10, 0)
	for _i in 10:
		await _key_z()
	deadline = Time.get_ticks_msec() + 8000
	while not foe.absorbed and Time.get_ticks_msec() < deadline:
		if b.hud.mode == "command" or b.hud.mode == "absorb_choice":
			b.handle_confirm()
		await process_frame
	check(foe.absorbed and not foe.is_alive(), "Draining the SP in the result absorbs for sure")
	check(b.results == 1 and b.rolls == 1, "One result for one absorption")
	check(b._fallen.current_sp >= 10, "The 10 SP drained reached Fallen")
	b.queue_free(); await process_frame

	# 6) Zero presses: the time runs out, no roll, nothing taken.
	b = fresh()
	foe = await open_mash(b, 30, 10)
	deadline = Time.get_ticks_msec() + 6000
	while b._mash_active and Time.get_ticks_msec() < deadline:
		await process_frame
	await process_frame
	check(b.rolls == 0 and foe.current_sp == 30 and b._fallen.current_sp == 10, "No input: no roll and no SP moved")
	check(b.log_history.any(func(l: String) -> bool: return l.contains("no input")), "No input is logged as a failure")
	b.queue_free(); await process_frame

	print("VERIFY ABSORB RESULT OK (%d checks)" % checks)
	SANDBOX.end()
	quit(0)
