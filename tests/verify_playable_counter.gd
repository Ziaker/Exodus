extends SceneTree
## D-049 (creator, 2026-11-22): counter-attack on two rails, interruption, SP theft,
## lost queues, perfect interruption (white scenery flash + shake), enemy counters.
const SANDBOX := preload("res://tests/progress_sandbox.gd")

## Enemy timing rolls MISS and enemies never counter on their own, so every outcome
## below comes from the exchange results the test chooses.
class CounterBattle extends "res://scripts/battle/playable_controller.gd":
	var force_enemy_counter := false
	func _ai_roll(_a: BattleUnit, _b: BattleUnit) -> int:
		return BattleMath.RhythmResult.MISS
	func _defender_reaction(_a: BattleUnit, _b: BattleUnit) -> int:
		return BattleMath.RhythmResult.MISS
	func _enemy_counter_roll(_e: BattleUnit) -> bool:
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
	root.add_child(battle)
	return battle

func reserve(battle: Control) -> void:
	battle.submit_command(battle.hud.command_options.find("REACT"))

## Both heroes reserve, the first enemy announces; `who` reacts with ATTACK.
func open_counter(battle: Control, who: int) -> void:
	reserve(battle); reserve(battle)
	check(battle.hud.mode == "react", "An enemy announcement must open the reaction prompt")
	battle.select_reactor(who)
	battle.answer_reaction(true)
	battle.submit_command(battle.hud.command_options.find("ATTACK"))

func wait_seconds(seconds: float) -> void:
	var waited := 0.0
	while waited < seconds:
		await process_frame
		waited += root.get_process_delta_time()

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
	check(battle.hud.command_options.has("ATTACK"), "The attacked hero may counter-attack")
	battle.submit_command(battle.hud.command_options.find("ATTACK"))
	check(battle.hud.mode == "counter", "D-049: ATTACK as a reaction opens the two-rail exchange, no target choice")
	check(battle.counter.style == "panel", "Hero counter: rails sit in the hero's status panel")
	var panel: Rect2 = battle.hud.STATUS_RECTS[reactor_index]
	check(panel.encloses(battle.counter.red_rect) and panel.encloses(battle.counter.white_rect), "Both rails stay inside the reacting hero's panel")
	check(battle.counter.red_rect.end.y <= battle.counter.white_rect.position.y, "Opponent rail is on top, the hero's below")
	check(is_equal_approx(battle.counter.red_duration, float(target.stats.agi) / float(enemy.stats.agi)), "Red pointer duration follows the AGI ratio")
	enemy.current_hp = 999  # survive the counter so its lost combo is observable
	var enemy_sp: int = enemy.current_sp
	var target_hp: int = target.current_hp
	var enemy_acts: int = enemy.acts_available
	check(enemy_acts >= 1, "The announcing enemy still has its second combo act")
	battle.counter.finish(R.POINT, R.BEAM)
	check(enemy.current_sp == maxi(0, enemy_sp - 4), "Winning interruption steals 4 SP from the enemy")
	check(target.current_hp == target_hp, "An interrupted enemy attack deals no damage")
	check(battle.log_history.any(func(l: String) -> bool: return l.begins_with(target.display_name + " ->")), "The winning counter strike resolves")
	check(battle.hud.impact_left == 0.0 and battle.hud.shake_unit == null, "A normal interruption has no impact frame or shake")
	check(battle.hud.mode == "continue", "The exchange result pauses for reading")
	var mid_acts: int = target.acts_available
	battle.proceed()
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
	battle.submit_command(battle.hud.command_options.find("ATTACK"))
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
	battle.proceed()
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
	battle.submit_command(battle.hud.command_options.find("ATTACK"))
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
	battle.proceed()
	check(lost_line(battle).contains("loses 1 queued") and not lost_line(battle).contains("gains"), "Tie: the enemy loses its next attack and nobody gains an act")
	battle.queue_free(); await process_frame

	# ---- Perfect interruption: 16 SP, white scenery for 3 frames, 0.4 s 4 px shake.
	battle = fresh()
	reserve(battle); reserve(battle)
	enemy = battle.action_attacker
	target = battle.action_defender
	battle.select_reactor(battle.hud.players.find(target))
	battle.answer_reaction(true)
	battle.submit_command(battle.hud.command_options.find("ATTACK"))
	enemy.current_sp = 40
	battle.counter.finish(R.MISS, R.MISS, true, false)
	check(enemy.current_sp == 24, "Perfect interruption steals 16 SP")
	check(battle.log_history.any(func(l: String) -> bool: return l.begins_with("PERFECT INTERRUPTION")), "Perfect interruption is logged")
	check(battle.last_counter.player_timing == R.POINT, "The perfect strike counts as POINT")
	check(is_equal_approx(battle.hud.impact_left, 3.0 / 60.0), "Impact frame lasts 3 frames")
	check(battle.hud.shake_unit == enemy and absf(battle.hud.shake_offset(enemy).x) == 4.0 and battle.hud.shake_offset(enemy).y == 0.0, "The interrupted enemy sprite shakes 4 px horizontally")
	check(battle.hud.shake_offset(target) == Vector2.ZERO, "Only the interrupted unit shakes")
	battle.hud.shake_age = 1.0 / 30.0 + 0.001
	check(signf(battle.hud.shake_offset(enemy).x) == -1.0, "Shake alternates direction at 30 Hz")
	battle.hud.shake_age = 0.0
	await wait_seconds(0.1)
	check(battle.hud.impact_left == 0.0, "The white scenery ends after its 3 frames")
	await wait_seconds(0.4)
	check(battle.hud.shake_offset(enemy) == Vector2.ZERO, "The shake ends after 0.4 s")
	battle.queue_free(); await process_frame

	# ---- Enemy counter on the hero's own plan: rails over the enemy, queue lost on defeat.
	battle = fresh()
	battle.force_enemy_counter = true
	battle._fallen.current_hp = 999
	battle.submit_plan(0); battle.submit_plan(0)
	battle.exec_plan()
	battle.hud.opponents[0].current_hp = 999
	battle.submit_target(0)
	enemy = battle.hud.opponents[0]
	check(battle.hud.mode == "counter" and battle.counter.style == "enemy", "An enemy counter opens the rails over the enemy")
	var column: Rect2 = battle.hud.enemy_column(0)
	check(column.encloses(battle.counter.red_rect) and column.encloses(battle.counter.white_rect), "Enemy-counter rails stay over the enemy column")
	check(not battle.rhythm.visible, "The single rail is hidden while the two rails run")
	enemy_acts = enemy.acts_available
	var fallen_sp: int = battle._fallen.current_sp
	battle.counter.finish(R.MISS, R.POINT)
	check(battle._fallen.current_hp < 999, "The winning enemy counter strikes the hero")
	check(battle._fallen.current_sp <= fallen_sp - 4, "The hero loses 4 SP to the enemy")
	battle.proceed()
	check(lost_line(battle).contains("FALLEN loses 1 queued") and lost_line(battle).contains("gains 1"), "The hero's next planned attack is lost; the enemy gains an act (%s)" % lost_line(battle))
	check(enemy.acts_available == mini(4, enemy_acts + 1), "+1 act for the enemy per lost hero command")
	check(battle._fallen.acts_available == 0, "The lost command takes its act with it")
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

	print("PLAYABLE_COUNTER_OK: %d checks; D-049 rails, AGI speed, perfect window, 4/16 SP theft, ties, redirect, lost queues, impact flash, shake, enemy counter" % checks)
	await process_frame
	await process_frame
	quit(0)

func _finalize() -> void:
	SANDBOX.end()
