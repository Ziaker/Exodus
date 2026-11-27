extends SceneTree
## D-124 (criador 2026-11-27), Fase 1: as 3 regras globais de combate.
##   HIGH SPEED (ponteiro 20% mais rápido, também no contra-ataque), BLEED canônico (-20% da cura
##   recebida por acúmulo, até 4, sem dano) e Temporização de Ação global (prisão = PASS automático).
const SANDBOX := preload("res://tests/progress_sandbox.gd")

class ControlledBattle extends "res://scripts/battle/playable_controller.gd":
	func _enemy_skill_pick(_n: int) -> int: return 0
	func _ai_roll(_a: BattleUnit, _d: BattleUnit) -> int: return BattleMath.RhythmResult.MISS
	func _defender_reaction(_d: BattleUnit, _a: BattleUnit) -> int: return BattleMath.RhythmResult.MISS
	func _enemy_counter_roll(_e: BattleUnit) -> bool: return false
	func _counter_ai_time(_red_seconds: float) -> float: return 99.0

var checks := 0


func _initialize() -> void:
	SANDBOX.begin()
	call_deferred("_run")


func check(ok: bool, reason: String) -> void:
	if not ok:
		push_error("FAIL: " + reason)
		quit(1)
		assert(ok, reason)
	checks += 1


func unit(hp: int = 100) -> BattleUnit:
	var s := UnitStats.new()
	s.max_hp = hp
	s.max_en = 10
	s.atk = 5
	s.mak = 5
	s.defense = 5
	s.mef = 5
	s.agi = 5
	var u := BattleUnit.new(&"t", "T", s, false)
	u.current_hp = 1
	return u


func fresh() -> Control:
	var battle := ControlledBattle.new()
	root.add_child(battle)
	return battle


func wait_menu(battle: Control) -> void:
	for _i in 60:
		if battle.hud.mode in ["plan", "command"] and not battle.hud.command_options.is_empty(): return
		await process_frame


func advance(battle: Control, frames: int = 600) -> void:
	for i in frames:
		if battle.hud.mode in ["continue", "announce"]: battle.proceed()
		elif battle.hud.mode == "react": battle.answer_reaction(false)
		elif battle.hud.mode not in ["busy", "turn"]: return
		await process_frame


func _run() -> void:
	_bleed()
	_high_speed_rules()
	_trap_unit()
	await _high_speed_bars()
	await _trap_flow()
	print("VERIFY_D124_RULES_OK: %d checks; HIGH SPEED x1.2 (bar + counter), BLEED -20%% healing x4 with no damage, global action trap = automatic PASS" % checks)
	quit(0)


# --------------------------------------------------------------------------- BLEED
func _bleed() -> void:
	var u := unit()
	check(u.heal_factor() == 1.0 and u.heal(10) == 10, "no BLEED: healing is whole")
	for stacks in [1, 2, 3, 4]:
		u = unit(1000)
		u.current_hp = 1
		u.add_bleed(stacks)
		var expected := int(round(100.0 * (1.0 - 0.2 * float(stacks))))
		check(u.bleeds.size() == stacks and u.heal(100) == expected,
			"%d BLEED stack(s): 100 healing becomes %d (got %d)" % [stacks, expected, 100 - expected])
	u = unit(1000)
	u.current_hp = 1
	u.add_bleed(7)
	check(u.bleeds.size() == SkillFx.BLEED_MAX_STACKS and u.heal(100) == 20, "stacks cap at 4 (-80%%): 100 -> 20")
	u.bleeds = [1, 1, 1, 1]
	u.add_bleed(1)
	check(u.bleeds == [SkillFx.BLEED_ROUNDS, SkillFx.BLEED_ROUNDS, SkillFx.BLEED_ROUNDS, SkillFx.BLEED_ROUNDS],
		"a 5th BLEED refreshes the 4 stacks without exceeding the cap")
	# no damage over time, the stacks only wear off
	u = unit(1000)
	u.current_hp = 500
	u.add_bleed(3)
	var res := SkillFx.tick(u)
	check(u.current_hp == 500 and int(res.bleed) == 0, "BLEED deals no damage over time (D-124)")
	check(u.bleeds.size() == 3, "BLEED lasts until the end of the unit's next turn (still on after 1 round tick)")
	SkillFx.tick(u)
	check(u.bleeds.is_empty() and u.heal_factor() == 1.0, "BLEED wears off after the next turn (round ticks)")
	# the heal paths that go through heal(): regen and mend are cut too
	u = unit(1000)
	u.current_hp = 1
	u.add_bleed(1)
	u.regen_rounds = 2
	u.regen_amount = 10
	var t := SkillFx.tick(u)
	check(int(t.regen) == 8, "REGEN is cut by BLEED (10 -> 8)")
	# cleanse and Tahorah
	u = unit()
	u.add_bleed(4)
	SkillFx.cleanse(u)
	check(u.bleeds.is_empty(), "MEND cleanses BLEED")
	u.add_bleed(2)
	u.burns.append(2)
	check(SkillFx.cleanse_all(u) >= 3 and u.bleeds.is_empty(), "Tahorah cleanses BLEED")
	# the legacy FANG FLURRY adds stacks through the same rule
	check(SkillBook.def(&"fang_sting").fx.bleed == 1, "FANG STING carries the canonical bleed fx")


# --------------------------------------------------------------------------- HIGH SPEED
func _high_speed_rules() -> void:
	check(is_equal_approx(SkillBook.bar_seconds(1.0, true), 1.0 / 1.2), "HIGH SPEED: 1.0 s bar runs in 1/1.2 s")
	check(SkillBook.bar_seconds(1.0, false) == 1.0, "a normal attack keeps the bar")
	check(not SkillBook.is_high_speed(&"lunge") and not SkillBook.is_high_speed(&"heat_wave") and not SkillBook.is_high_speed(&"zzz"),
		"no current skill is HIGH SPEED until phase 2 flags them")


func _high_speed_bars() -> void:
	var battle := fresh()
	await wait_menu(battle)
	var fallen: BattleUnit = battle._fallen
	var foe: BattleUnit = battle.state.units[2]
	battle.action_attacker = fallen
	battle.action_defender = foe
	battle.timing_role = "ATTACK"
	battle._high_speed = true
	var run: Callable = func() -> void: await battle._manual_rhythm(1.0, 0.1)
	run.call()
	for _i in 4: await process_frame
	check(is_equal_approx(battle.rhythm.duration, 1.0 / 1.2), "attack bar: a HIGH SPEED attack runs the pointer at x1.2 (%.4f s)" % battle.rhythm.duration)
	battle.rhythm._finish(BattleMath.RhythmResult.MISS)
	for _i in 4: await process_frame
	battle._high_speed = false
	run.call()
	for _i in 4: await process_frame
	check(is_equal_approx(battle.rhythm.duration, 1.0), "attack bar: a normal attack keeps 1.0 s")
	battle.rhythm._finish(BattleMath.RhythmResult.MISS)
	for _i in 4: await process_frame

	# counter-attack (D-049): the HIGH SPEED side's pointer is faster than the opponent's
	var normal_red := BattleMath.counter_red_duration(BattleMath.RHYTHM_FIXED_SECONDS, foe.stats.agi, fallen.stats.agi)
	var ex: Callable = func(side: String) -> void: await battle._counter_exchange(fallen, foe, "panel", side)
	ex.call("white")
	for _i in 4: await process_frame
	check(is_equal_approx(battle.counter.white_duration, 1.0 / 1.2) and is_equal_approx(battle.counter.red_duration, normal_red),
		"counter: a HIGH SPEED hero pointer runs x1.2 and the opponent's stays normal")
	battle.counter.finish(BattleMath.RhythmResult.MISS, BattleMath.RhythmResult.MISS)
	for _i in 4: await process_frame
	ex.call("red")
	for _i in 4: await process_frame
	check(is_equal_approx(battle.counter.red_duration, normal_red / 1.2) and is_equal_approx(battle.counter.white_duration, 1.0),
		"counter: a HIGH SPEED enemy pointer runs x1.2 and the hero's stays normal")
	battle.counter.finish(BattleMath.RhythmResult.MISS, BattleMath.RhythmResult.MISS)
	for _i in 4: await process_frame
	ex.call("")
	for _i in 4: await process_frame
	check(is_equal_approx(battle.counter.white_duration, 1.0) and is_equal_approx(battle.counter.red_duration, normal_red),
		"counter: without HIGH SPEED both pointers keep their speed (D-049 / D-034 unchanged)")
	battle.counter.finish(BattleMath.RhythmResult.MISS, BattleMath.RhythmResult.MISS)
	battle.queue_free()
	await process_frame


# --------------------------------------------------------------------------- Prisão
func _trap_unit() -> void:
	var u := unit()
	check(u.trapped_actions == 0 and not u.has_status(&"trapped"), "a unit starts free")
	u.trap(2)
	check(u.trapped_actions == 2 and u.has_status(&"trapped"), "trap(2) traps it for 2 global actions")
	check(not u.tick_trap() and u.trapped_actions == 1 and u.has_status(&"trapped"), "1st global action: 1 left")
	check(u.tick_trap() and u.trapped_actions == 0 and not u.has_status(&"trapped"), "2nd global action frees the unit")
	check(not u.tick_trap(), "a free unit is not affected by actions")
	u.trap(3)
	u.trap(1)
	check(u.trapped_actions == 3, "trapping again keeps the longer trap")
	check(SkillFx.NEGATIVE_STATUSES.has(&"trapped"), "Tahorah can purify the trap")
	check(SkillFx.cleanse_all(u) >= 1 and u.trapped_actions == 0 and not u.has_status(&"trapped"), "Tahorah frees a trapped unit")


func _trap_flow() -> void:
	var battle := fresh()
	await wait_menu(battle)
	var fallen: BattleUnit = battle._fallen
	var yoch: BattleUnit = battle._ally
	var foe_a: BattleUnit = battle.state.units[2]
	var foe_b: BattleUnit = battle.state.units[3]
	for hero in [fallen, yoch]:
		hero.stats.max_hp = 999
		hero.current_hp = 999
	# the global counter ticks for every trapped unit, whoever acted
	battle.trap_unit(foe_a, 2)
	check(foe_a.has_status(&"trapped") and battle.log_history.any(func(l: String) -> bool: return l.contains("is trapped for 2 action(s)")), "trap_unit traps and logs it")
	battle._global_action_done()
	check(foe_a.trapped_actions == 1, "an action of any unit counts down the trap")
	battle._global_action_done()
	check(foe_a.trapped_actions == 0 and not foe_a.has_status(&"trapped") and battle.log_history.any(func(l: String) -> bool: return l.contains("is freed")), "after 2 actions the unit is freed and the log says it")
	# a trapped unit's turn is an automatic PASS: acts kept, no attack
	battle.trap_unit(foe_b, 99)
	var hp_before := fallen.current_hp + yoch.current_hp
	battle.submit_command(battle.hud.command_options.find("PASS"))
	await advance(battle)
	check(foe_b.acts_available == 2, "a trapped FOE B keeps both acts on its turn (%d)" % foe_b.acts_available)
	check(fallen.current_hp + yoch.current_hp <= hp_before and battle.log_history.any(func(l: String) -> bool: return l.contains("is trapped and passes the turn (2 act(s) kept)")),
		"the trapped unit's turn is an automatic PASS with a clear log")
	check(foe_b.current_hp == foe_b.stats.max_hp, "the trapped unit lost no HP")
	# queued acts of a unit trapped during its own turn are lost
	battle.turn_owner = foe_a
	battle._enemy_interrupted = false
	battle.trap_unit(foe_a, 2)
	check(battle._enemy_interrupted, "trapping the unit that is playing cuts its running queue")
	battle.turn_owner = fallen
	battle._player_interrupted = false
	battle.trap_unit(fallen, 1)
	check(battle._player_interrupted, "trapping the hero that is playing cuts its running queue")
	battle.queue_free()
	await process_frame
