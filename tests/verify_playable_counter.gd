extends SceneTree
## D-049 (creator, 2026-11-22): counter-attack on two rails, interruption, SP theft,
## lost queues, perfect interruption (white scenery flash + shake), enemy counters.
const SANDBOX := preload("res://tests/progress_sandbox.gd")

## Enemy timing rolls MISS and enemies never counter on their own, so every outcome
## below comes from the exchange results the test chooses.
class CounterBattle extends "res://scripts/battle/playable_controller.gd":
	## ATTACK-flow checks: the enemy AI never draws a skill here (skills: verify_playable_skills).
	func _enemy_skill_pick(_n: int) -> int: return 0
	var force_enemy_counter := false
	func _ai_roll(_a: BattleUnit, _b: BattleUnit) -> int:
		return BattleMath.RhythmResult.MISS
	func _defender_reaction(_a: BattleUnit, _b: BattleUnit) -> int:
		return BattleMath.RhythmResult.MISS
	## When >= 0, only the counter roll with this index (0 = first) counters.
	var counter_on_roll := -1
	var _rolls := 0
	func _enemy_counter_roll(_e: BattleUnit) -> bool:
		_rolls += 1
		if counter_on_roll >= 0: return _rolls - 1 == counter_on_roll
		return force_enemy_counter

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

func fresh() -> Control:
	var battle := CounterBattle.new()
	battle.offer_reserve = true  # creator 2026-11-24: REACT left the own-turn menu
	root.add_child(battle)
	return battle

## Creator 2026-11-23: FOE B plays right after Fallen, before Yoch, so once Fallen reserves
## the enemy announces at once; a second call (Yoch's REACT) then has no own turn to use.
func reserve(battle: Control) -> void:
	if battle.hud.mode not in ["plan", "command"]: return
	battle.submit_command(battle.hud.command_options.find("REACT"))

## Both heroes reserve, the first enemy announces; `who` reacts with ATTACK.
func open_counter(battle: Control, who: int) -> void:
	reserve(battle); reserve(battle)
	check(battle.hud.mode == "react", "An enemy announcement must open the reaction prompt")
	battle.select_reactor(who)
	battle.answer_reaction(true)
	battle.submit_command(battle.hud.command_options.find("FIGHT"))

func wait_seconds(seconds: float) -> void:
	var waited := 0.0
	while waited < seconds:
		await process_frame
		waited += root.get_process_delta_time()

## D-057: Z first pages the event lines still waiting beyond the two-row log, then goes on.
func confirm(battle: Control) -> void:
	for _i in 8:
		var paging: bool = battle.hud.mode == "continue" and battle.hud.log_hidden()
		battle.proceed()
		if not paging: return


func lost_line(battle: Control) -> String:
	for i in range(battle.log_history.size() - 1, -1, -1):
		if battle.log_history[i].contains("queued command"): return battle.log_history[i]
	return ""

func _run() -> void:
	# ---- Pure exchange rules.
	var R := BattleMath.RhythmResult
	var W := BattleMath.CounterWinner
	check(BattleMath.resolve_counter(R.POINT, R.BEAM).winner == W.PLAYER, "POINT beats BLAST")
	check(BattleMath.resolve_counter(R.BEAM, R.MISS).winner == W.PLAYER, "BLAST beats MISS")
	check(BattleMath.resolve_counter(R.MISS, R.POINT).winner == W.ENEMY, "Enemy POINT beats a player MISS")
	check(BattleMath.resolve_counter(R.POINT, R.BEAM).steal == 4, "A normal interruption steals 4 SP")
	check(BattleMath.resolve_counter(R.POINT, R.POINT).winner == W.TIE and BattleMath.resolve_counter(R.POINT, R.POINT).steal == 0, "Both POINT: tie, no SP")
	check(BattleMath.resolve_counter(R.MISS, R.MISS).winner == W.TIE, "Both MISS: tie")
	var perfect := BattleMath.resolve_counter(R.MISS, R.POINT, true, false)
	check(perfect.winner == W.PLAYER and perfect.perfect and perfect.steal == 16 and perfect.player_timing == R.POINT, "A perfect press wins as POINT and steals 16 SP even from a MISS zone")
	check(BattleMath.resolve_counter(R.BEAM, R.BEAM, true, true).winner == W.TIE, "Two perfect presses are a tie")
	check(is_equal_approx(BattleMath.counter_red_duration(1.0, 4, 6), 1.5), "Lower opponent AGI = slower red pointer (6/4 = 1.5 s)")
	check(is_equal_approx(BattleMath.counter_red_duration(1.0, 8, 4), 0.5), "Higher opponent AGI = faster red pointer")
	check(BattleMath.pointers_aligned(0.50, 0.52) and not BattleMath.pointers_aligned(0.50, 0.53), "Alignment window is 2% of the bar")
	check(is_equal_approx(BattleMath.ENEMY_COUNTER_CHANCE, 0.33), "Enemy counter chance is 33%")

	# ---- The rails: pointer motion, perfect only while both move, AI press.
	var battle := fresh()
	var bar: Control = battle.counter
	var rails: Array[Rect2] = battle.hud.counter_rail_rects("panel", 0)
	bar.start("panel", rails[0], rails[1], 1.0, 1.0, 0.05, 0.05, 0.9)
	bar.elapsed = 0.5
	check(is_equal_approx(bar.white_position(), 0.5) and is_equal_approx(bar.red_position(), 0.5), "White runs left to right, red right to left")
	bar.press_player()
	check(bar.white_perfect and bar.white_result == R.POINT, "Pressing at the crossing is a perfect interruption")
	check(not bar.running and is_equal_approx(bar.red_stop, 0.5), "A perfect press interrupts at once: the red pointer freezes and the exchange ends")
	bar.start("panel", rails[0], rails[1], 1.0, 1.0, 0.05, 0.05, 0.5)
	bar._process(0.5)
	check(bar.red_stop >= 0.0 and is_equal_approx(bar.red_stop, 0.5), "The AI presses at its random moment")
	bar.press_player()
	check(not bar.white_perfect, "Aligning with a stopped pointer is not perfect")
	check(not bar.running, "The exchange ends once both sides pressed")
	bar.start("panel", rails[0], rails[1], 1.0, 1.0, 0.05, 0.05, 0.95)
	bar.elapsed = 0.3
	bar.press_player()
	check(not bar.white_perfect and bar.white_result == R.MISS, "Away from the crossing and from the zones: MISS, not perfect")
	bar.finish(R.MISS, R.MISS)
	# The real controller's roll (not the test override), seeded, outside the tree.
	var plain: Control = load("res://scripts/battle/playable_controller.gd").new()
	plain.rng.seed = 4049
	var hits := 0
	for i in 3000:
		if plain._enemy_counter_roll(null): hits += 1
	plain.free()
	check(hits > 900 and hits < 1080, "Default enemy counter roll lands about 33%% of the time (got %d/3000)" % hits)
	battle.queue_free(); await process_frame

	# ---- Hero counter wins: enemy attack interrupted, 4 SP stolen, its combo lost.
	battle = fresh()
	reserve(battle); reserve(battle)
	var enemy: BattleUnit = battle.action_attacker
	var target: BattleUnit = battle.action_defender
	var reactor_index: int = battle.hud.players.find(target)
	battle.select_reactor(reactor_index)
	battle.answer_reaction(true)
	check(battle.hud.command_options.has("FIGHT"), "The attacked hero may counter-attack")
	battle.submit_command(battle.hud.command_options.find("FIGHT"))
	check(battle.hud.mode == "counter", "D-049: ATTACK as a reaction opens the two-rail exchange, no target choice")
	check(battle.counter.style == "panel", "Hero counter: rails use the panel (defense) look")
	# D-058 (creator 2026-11-25): a hero's reaction runs inside the battle log, not over the hero.
	var log_rect: Rect2 = battle.hud.BATTLE_LOG_RECT
	check(log_rect.encloses(battle.counter.red_rect) and log_rect.encloses(battle.counter.white_rect), "Both rails of a hero counter sit inside the battle log")
	check(battle.hud.rails_in_log(), "The log text gives way to the rails")
	check(battle.counter.red_rect.end.y <= battle.counter.white_rect.position.y, "Opponent rail is on top, the hero's below")
	check(is_equal_approx(battle.counter.red_duration, float(target.stats.agi) / float(enemy.stats.agi)), "Red pointer duration follows the AGI ratio")
	enemy.current_hp = 999  # survive the counter so its lost combo is observable
	var enemy_sp: int = enemy.current_sp
	var target_hp: int = target.current_hp
	var enemy_acts: int = enemy.acts_available
	check(enemy_acts >= 1, "The announcing enemy still has its second combo act")
	# D-057: the lost combo (and the act it gives) is told inside the exchange result.
	var mid_acts: int = target.acts_available
	battle.counter.finish(R.POINT, R.BEAM)
	check(enemy.current_sp == maxi(0, enemy_sp - 4), "Winning interruption steals 4 SP from the enemy")
	check(target.current_hp == target_hp, "An interrupted enemy attack deals no damage")
	check(battle.log_history.any(func(l: String) -> bool: return l.begins_with(target.display_name + " ->")), "The winning counter strike resolves")
	check(battle.hud.impact_left == 0.0 and battle.hud._shakes.is_empty(), "A normal interruption has no impact frame or shake")
	check(battle.hud.mode == "continue", "The exchange result pauses for reading")
	confirm(battle)
	check(lost_line(battle).contains("loses 1 queued") and lost_line(battle).contains("gains 1"), "Interrupted enemy loses its next combo attack; the interrupter gains an act (%s)" % lost_line(battle))
	check(target.acts_available == mini(4, mid_acts + 1), "+1 act for the lost enemy command")
	check(enemy.acts_available == enemy_acts - 1, "The lost combo attack spends the enemy's act")
	check(not (battle.hud.mode == "react" and battle.action_attacker == enemy), "The interrupted enemy does not announce its second attack")
	battle.queue_free(); await process_frame

	# ---- A non-target counter-attacker that loses takes the hit in the target's place.
	battle = fresh()
	reserve(battle); reserve(battle)
	enemy = battle.action_attacker
	target = battle.action_defender
	var other: BattleUnit = battle._ally if target == battle._fallen else battle._fallen
	battle.select_reactor(battle.hud.players.find(other))
	battle.answer_reaction(true)
	battle.submit_command(battle.hud.command_options.find("FIGHT"))
	check(battle.hud.mode == "counter", "A non-target hero may counter-attack on the two rails (D-045)")
	target_hp = target.current_hp
	var other_hp: int = other.current_hp
	var other_sp: int = other.current_sp
	enemy_sp = enemy.current_sp
	battle.counter.finish(R.MISS, R.POINT)
	check(target.current_hp == target_hp, "The original target is spared when the counter-attacker loses")
	check(other.current_hp < other_hp, "The losing counter-attacker takes the enemy hit")
	check(other.current_sp == maxi(0, other_sp - 4), "The losing counter-attacker loses the stolen SP")
	check(enemy.current_sp >= enemy_sp + 4, "The enemy gains the stolen SP")
	confirm(battle)
	check(lost_line(battle).is_empty(), "A winning enemy is not interrupted and keeps its combo")
	battle.queue_free(); await process_frame

	# ---- Tie (both hit): both strikes land, the enemy loses its next attack, nobody gains.
	battle = fresh()
	reserve(battle); reserve(battle)
	enemy = battle.action_attacker
	target = battle.action_defender
	target.current_hp = 999
	enemy.current_hp = 999
	battle.select_reactor(battle.hud.players.find(target))
	battle.answer_reaction(true)
	battle.submit_command(battle.hud.command_options.find("FIGHT"))
	enemy_sp = enemy.current_sp
	var hero_sp: int = target.current_sp
	enemy_acts = enemy.acts_available
	check(enemy_acts >= 1, "Tie case: the enemy still has a combo act")
	battle.counter.finish(R.BEAM, R.BEAM)
	check(target.current_hp < 999, "Tie: the enemy strike lands on its target")
	check(battle.log_history.any(func(l: String) -> bool: return l.begins_with(target.display_name + " ->") and not l.contains("NO CONTACT")), "Tie: the counter strike lands too")
	check(battle.log_history.any(func(l: String) -> bool: return l.begins_with("COUNTER TIE")), "Tie is reported in the log")
	check(not battle.log_history.any(func(l: String) -> bool: return l.contains("SP stolen")), "Tie steals no SP")
	check(enemy.current_sp >= enemy_sp, "Tie: the enemy loses no SP")
	confirm(battle)
	check(lost_line(battle).contains("loses 1 queued") and not lost_line(battle).contains("gains"), "Tie: the enemy loses its next attack and nobody gains an act")
	battle.queue_free(); await process_frame

	# ---- Perfect interruption: 16 SP, white scenery for 3 frames, 0.4 s 4 px shake.
	battle = fresh()
	reserve(battle); reserve(battle)
	enemy = battle.action_attacker
	target = battle.action_defender
	battle.select_reactor(battle.hud.players.find(target))
	battle.answer_reaction(true)
	battle.submit_command(battle.hud.command_options.find("FIGHT"))
	enemy.current_sp = 40
	battle.counter.finish(R.MISS, R.MISS, true, false)
	check(enemy.current_sp == 24, "Perfect interruption steals 16 SP")
	check(battle.log_history.any(func(l: String) -> bool: return l.begins_with("PERFECT INTERRUPTION")), "Perfect interruption is logged")
	check(battle.last_counter.player_timing == R.POINT, "The perfect strike counts as POINT")
	check(is_equal_approx(battle.hud.impact_left, 3.0 / 60.0), "Impact frame lasts 3 frames")
	check(battle.hud._shakes.has(enemy.id) and absf(battle.hud.shake_offset(enemy).x) == 4.0 and battle.hud.shake_offset(enemy).y == 0.0, "The interrupted enemy sprite shakes 4 px horizontally")
	check(battle.hud.shake_offset(target) == Vector2.ZERO, "Only the interrupted unit shakes")
	battle.hud._shakes[enemy.id] = 1.0 / 30.0 + 0.001
	check(signf(battle.hud.shake_offset(enemy).x) == -1.0, "Shake alternates direction at 30 Hz")
	battle.hud._shakes[enemy.id] = 0.0
	await wait_seconds(0.1)
	check(battle.hud.impact_left == 0.0, "The white scenery ends after its 3 frames")
	await wait_seconds(0.4)
	check(battle.hud.shake_offset(enemy) == Vector2.ZERO, "The shake ends after 0.4 s")
	# Damage shake: any unit that loses HP shakes (same 4 px / 0.4 s), the others stay still.
	target.current_hp = target.stats.max_hp
	await wait_seconds(0.1)
	check(battle.hud.shake_offset(target) == Vector2.ZERO, "No shake without damage")
	target.take_damage(1)
	await wait_seconds(0.02)
	check(battle.hud._shakes.has(target.id) and absf(battle.hud.shake_offset(target).x) == 4.0, "A unit that takes damage shakes")
	battle.queue_free(); await process_frame

	# ---- Enemy counter on the hero's own plan: rails over the enemy, queue lost on defeat.
	battle = fresh()
	battle.force_enemy_counter = true
	battle._fallen.current_hp = 999
	battle.hud.opponents[0].current_hp = 999
	# D-057: each ATTACK takes its target while planning; the full plan runs at once.
	battle.submit_plan(0); battle.submit_target(0)
	battle.submit_plan(0); battle.submit_target(0)
	enemy = battle.hud.opponents[0]
	check(battle.hud.mode == "counter" and battle.counter.style == "enemy", "An enemy counter opens the rails over the enemy")
	# D-059 (creator 2026-11-25): a counter-attack is one arrow from each side meeting in the
	# middle, with a spark at the clash.
	await process_frame
	var clash: Array = battle.hud.role_arrows().filter(func(a): return a.clash)
	check(clash.size() == 1 and clash[0].key == "%s<>%s" % [battle._fallen.id, battle.hud.opponents[0].id], "The counter is drawn as one clash between Fallen and FOE A")
	check(battle.hud.role_arrows().filter(func(a): return not a.clash).is_empty(), "No plain arrow between the two while they clash")
	var column: Rect2 = battle.hud.enemy_column(0)
	check(column.encloses(battle.counter.red_rect) and column.encloses(battle.counter.white_rect), "Enemy-counter rails stay over the enemy column")
	check(not battle.rhythm.visible, "The single rail is hidden while the two rails run")
	enemy_acts = enemy.acts_available
	var fallen_sp: int = battle._fallen.current_sp
	battle.counter.finish(R.MISS, R.POINT)
	# Power 8 with no damage floor yet (D-033 floor not implemented) can land a 0-damage hit:
	# the strike is proven by its event line, not by HP.
	var struck: bool = battle.hud.events.any(func(e): return String(e.text).contains("→ Fallen  "))
	check(struck, "The winning enemy counter strikes the hero (%s)" % str(battle.hud.events.map(func(e): return e.text)))
	check(battle._fallen.current_sp <= fallen_sp - 4, "The hero loses 4 SP to the enemy")
	confirm(battle)
	check(lost_line(battle).contains("FALLEN loses 1 queued") and lost_line(battle).contains("gains 1"), "The hero's next planned attack is lost; the enemy gains an act (%s)" % lost_line(battle))
	check(enemy.acts_available == mini(4, enemy_acts + 1), "+1 act for the enemy per lost hero command")
	check(battle._fallen.acts_available == 0, "The lost command takes its act with it")
	battle.queue_free(); await process_frame

	# ---- Creator 2026-11-25: two chained ATTACKs; the enemy counters the SECOND one. The
	# attack rail kept between the hits must leave with the counter, not stay on screen
	# (it used to stay through the next turns, over the spot of the dead enemy).
	battle = fresh()
	battle.counter_on_roll = 1
	battle._fallen.current_hp = 999
	battle.submit_plan(0); battle.submit_target(0)
	battle.submit_plan(0); battle.submit_target(0)
	battle.exec_plan()
	check(battle.hud.mode == "timing" and battle.rhythm.visible, "The chained rail runs for the first hit")
	battle.rhythm._finish(R.MISS)
	for i in 240:
		if battle.hud.mode in ["counter", "continue"]: break
		await process_frame
	check(not battle.rhythm.visible, "The kept attack rail leaves when the enemy counters the last hit (mode %s)" % battle.hud.mode)
	for i in 240:
		if battle.hud.mode == "counter": break
		if battle.hud.mode == "continue": confirm(battle)
		await process_frame
	if battle.hud.mode == "counter": battle.counter.finish(R.POINT, R.MISS)
	for i in 600:
		if battle.hud.mode in ["plan", "react", "command", "result"]: break
		if battle.hud.mode in ["continue", "announce"]: confirm(battle)
		await process_frame
	check(not battle.rhythm.visible, "No attack rail after the exchange, on the next prompt (mode %s)" % battle.hud.mode)
	battle.queue_free(); await process_frame

	# ---- Real input: Z stops the white pointer on the live rails.
	battle = fresh()
	battle.force_enemy_counter = true
	battle._fallen.current_hp = 999
	battle.submit_plan(0)
	battle.exec_plan()
	battle.submit_target(0)
	check(battle.hud.mode == "counter", "Live counter rails are running")
	await wait_seconds(0.2)
	check(battle.counter.white_position() > 0.0 and battle.counter.red_position() < 1.0, "Both pointers move in real time")
	battle.handle_confirm()
	check(battle.counter.white_stop >= 0.0, "Z / Enter stops the white pointer")
	var deadline := Time.get_ticks_msec() + 4000
	while battle.hud.mode == "counter" and Time.get_ticks_msec() < deadline:
		await process_frame
	check(battle.hud.mode == "continue", "The exchange resolves once the AI pressed or its pointer ran out")
	check(not battle.last_counter.is_empty(), "The exchange outcome is recorded")
	battle.queue_free(); await process_frame

	# ---- D-051 absorption: SP dispute and the player's choice of gain.
	battle = fresh()
	var foe: BattleUnit = battle.hud.opponents[0]
	foe.stats.mak = 16
	foe.stats.mef = 8
	foe.current_sp = 6
	var fallen: BattleUnit = battle._fallen
	var mak0: int = fallen.stats.mak
	var mef0: int = fallen.stats.mef
	var hp0: int = fallen.stats.max_hp
	var sp0: int = fallen.current_sp
	battle.submit_command(battle.hud.command_options.find("ABSORB"))
	battle.submit_target(0)
	check(battle.hud.mode == "absorb", "ABSORB opens the mash")
	for i in 3: battle.handle_confirm()
	# D-103: under 10 presses the result waits for the 2 s window, then the break (~2.3 s).
	deadline = Time.get_ticks_msec() + 8000
	while battle.hud.mode != "command" and Time.get_ticks_msec() < deadline:
		await process_frame
	check(fallen.current_sp - sp0 == 6 - foe.current_sp and foe.current_sp <= 4, "The result moves 2 SP per press from the target into Fallen")
	check(battle.hud.mode == "command" and battle.hud.command_options == ["+2 MAK", "+2 MEF", "+1 MAK / +1 MEF"], "Two multiples of 8: the player chooses the gain (got %s)" % [battle.hud.command_options])
	battle.submit_command(2)
	check(fallen.stats.mak == mak0 + 1 and fallen.stats.mef == mef0 + 1, "+1/+1 applies to both chosen attributes")
	check(fallen.stats.max_hp == hp0 + 2, "Absorption still grants +HP of the same amount")
	check(foe.absorbed and not foe.is_alive(), "The absorbed target is eliminated")
	check(battle.absorb_gain_label == "+1 MAK / +1 MEF", "The chosen gain is the one labelled (got %s)" % battle.absorb_gain_label)
	# Creator 2026-11-23: green ABSORBED + gain, where the absorbed enemy stood.
	var label_fx: Array = battle.fx.effects.filter(func(e: Dictionary) -> bool: return e.kind == "ABSORBED")
	check(label_fx.size() == 1 and label_fx[0].lines == ["ABSORBED", "+1 MAK / +1 MEF", "1/4", ""], "ABSORBED label carries the gain and the 1/4 counter (got %s)" % [label_fx[0].lines if label_fx.size() > 0 else []])
	check(label_fx[0].label_rect == battle.hud.enemy_sprite_rect(0) and label_fx[0].ink == battle.ABSORBED_INK, "ABSORBED label sits on the enemy, in green")
	check(ProgressStore.load_gains().get("mak", 0) == 1 and ProgressStore.load_gains().get("mef", 0) == 1, "The chosen +1/+1 is what gets saved")
	battle.queue_free(); await process_frame

	print("PLAYABLE_COUNTER_OK: %d checks; D-049 rails, AGI speed, perfect window, 4/16 SP theft, ties, redirect, lost queues, impact flash, shake, enemy counter" % checks)
	await process_frame
	await process_frame
	quit(0)

func _finalize() -> void:
	SANDBOX.end()
