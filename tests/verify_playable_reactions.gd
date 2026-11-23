extends SceneTree
const SANDBOX := preload("res://tests/progress_sandbox.gd")

class ControlledBattle extends "res://scripts/battle/playable_controller.gd":
	## ATTACK-flow checks: the enemy AI never draws a skill here (skills: verify_playable_skills).
	func _enemy_skill_pick(_n: int) -> int: return 0
	func _ai_roll(_attacker: BattleUnit, _defender: BattleUnit) -> int:
		return BattleMath.RhythmResult.MISS
	func _defender_reaction(_defender: BattleUnit, _attacker: BattleUnit) -> int:
		return BattleMath.RhythmResult.MISS
	func _enemy_counter_roll(_e: BattleUnit) -> bool:
		return false  # D-049 counters are covered by verify_playable_counter.gd
	# These checks isolate act economy, so enemy attacks must never land. D-022
	# auto-hit is disabled here and covered by AutoHitBattle below.
	func _perform_attack(attacker: BattleUnit, defender: BattleUnit, power: int, is_reaction: bool, defense_act_paid: bool = false, _auto_hit: bool = false, _chain: bool = false) -> void:
		await super._perform_attack(attacker, defender, power, is_reaction, defense_act_paid, false, _chain)

## D-022: enemy timing always rolls MISS, so a landed POINT can only come from auto-hit.
class AutoHitBattle extends "res://scripts/battle/playable_controller.gd":
	## ATTACK-flow checks: the enemy AI never draws a skill here (skills: verify_playable_skills).
	func _enemy_skill_pick(_n: int) -> int: return 0
	func _ai_roll(_attacker: BattleUnit, _defender: BattleUnit) -> int:
		return BattleMath.RhythmResult.MISS
	func _defender_reaction(_defender: BattleUnit, _attacker: BattleUnit) -> int:
		return BattleMath.RhythmResult.MISS
	func _enemy_counter_roll(_e: BattleUnit) -> bool:
		return false  # D-049 counters are covered by verify_playable_counter.gd

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
	var battle := ControlledBattle.new()
	root.add_child(battle)
	return battle

func advance(battle: Control, frames: int = 60) -> void:
	for i in frames:
		if battle.hud.mode in ["continue", "announce"]: battle.proceed()
		elif battle.hud.mode == "react": battle.answer_reaction(false)
		else: return
		await process_frame

func reserve(battle: Control) -> void:
	var index: int = battle.hud.command_options.find("REACT")
	check(index >= 0, "Own-turn menu must expose REACT to reserve acts")
	battle.submit_command(index)

func _run() -> void:
	var battle := fresh()
	check(battle._fallen.acts_available == 2, "Opening the menu must show both acts, not spend one in advance")
	check(battle.hud.command_options.has("REACT"), "REACT must be discoverable from the normal menu")
	battle.submit_command(0); battle.cancel_target()
	check(battle._fallen.acts_available == 2, "Canceling target must not consume an act")
	battle.submit_command(0); battle.submit_target(0)
	battle.rhythm._finish(BattleMath.RhythmResult.MISS)
	check(battle._fallen.acts_available == 1, "One attack spends exactly one act")
	await advance(battle)
	check(battle.active_actor == battle._fallen, "D-044: o mesmo combatente esgota seus atos em bloco (A,A,B,B)")
	battle.submit_command(0); battle.submit_target(0)
	battle.rhythm._finish(BattleMath.RhythmResult.MISS)
	check(battle._fallen.acts_available == 0, "Two attacks consume the two available acts")
	var attacks := 0
	for line in battle.log_history:
		if line.begins_with("FALLEN ->"): attacks += 1
	check(attacks == 2, "Two physical attacks must actually resolve in the same round")
	battle.queue_free(); await process_frame
	battle = fresh()
	reserve(battle)
	check(battle._fallen.acts_available == 2, "Waiting to react must not spend an act")
	reserve(battle)
	check(battle.hud.mode == "react", "Enemy announcement must open a reaction prompt")
	for reaction in 2:
		battle.select_reactor(0)
		battle.answer_reaction(true)
		check(battle.hud.command_options.has("FIGHT") and battle.hud.command_options.has("ITEM") and battle.hud.command_options.has("REST") and battle.hud.command_options.has("ABSORB") and battle.hud.command_options.has("DEFEND"), "D-045: the attacked Fallen keeps every command plus DEFEND as a reaction")
		battle.submit_command(0)  # counter-attack: D-038 REST no longer spends acts
		# D-049: the counter uses the two-rail exchange; both MISS = tie, no damage.
		check(battle.hud.mode == "counter", "D-049: a counter-attack opens the two-rail exchange")
		battle.counter.finish(BattleMath.RhythmResult.MISS, BattleMath.RhythmResult.MISS)
		check(battle._fallen.acts_available == 1 - reaction, "Each reaction must spend exactly one shared act")
		check(battle.state.round_number == 1, "Both reactions must occur in round one")
		if reaction == 0:
			battle.proceed()
			check(battle.hud.mode == "react", "A second enemy announcement must offer the remaining reaction")
	battle.queue_free(); await process_frame
	# D-038: REST como reação também consome zero ACT, guarda os atos e dá 2 EN fixos.
	battle = fresh()
	reserve(battle); reserve(battle)
	battle.select_reactor(0)
	battle.answer_reaction(true)
	battle._fallen.current_en = 0
	battle.submit_command(battle.hud.command_options.find("REST"))
	check(battle._fallen.current_en == BattleMath.REST_EN_RECOVERY, "D-038: REST reaction must recover exactly 2 EN flat")
	check(battle._fallen.acts_available == 0 and battle._fallen.stored_acts == 2, "D-038: REST reaction must store both acts and end participation")
	check(battle.log_history.any(func(line: String) -> bool: return line.contains("+2 EN, 2 act(s) stored")), "D-038: REST log must report 2 EN and stored acts, never a spent act")
	battle.queue_free(); await process_frame
	battle = fresh()
	reserve(battle); reserve(battle)
	battle.select_reactor(1)
	battle.answer_reaction(true)
	check(not battle.hud.command_options.has("ABSORB"), "Ally must not receive Fallen-only absorption")
	check(battle.reaction_defender == battle._fallen and battle.hud.command_options == ["FIGHT", "PRAY", "ITEM"], "D-045: a reactor who is not the target may only counter-attack or use an item; D-048 (creator 2026-11-23): Yoch may also PRAY (got %s)" % [battle.hud.command_options])
	battle.submit_command(0)
	# Both MISS: a tie, so the ally's strike resolves (no contact) and no affinity penalty applies.
	battle.counter.finish(BattleMath.RhythmResult.MISS, BattleMath.RhythmResult.MISS)
	check(battle._ally.acts_available == 1 and battle._fallen.acts_available == 2, "Ally may react when Fallen is attacked, spending only Ally's act")
	check(battle.log_history.any(func(line: String) -> bool: return line.begins_with("Yoch ->")), "Off-turn attack must use the real attack resolver")
	battle.queue_free(); await process_frame
	battle = fresh()
	reserve(battle); reserve(battle)
	battle._fallen.current_hp = 1
	battle.select_reactor(1); battle.answer_reaction(true)
	battle.submit_command(battle.hud.command_options.find("ITEM"))
	check(battle.target_side == "player" and battle.hud.mode == "target", "Reaction item must allow choosing an ally")
	battle.submit_target(0)
	check(battle._fallen.current_hp == 7, "Ally reaction must heal Fallen, not the reactor")
	check(battle._ally.acts_available == 1 and battle._fallen.acts_available == 2, "Reaction item spends only the reactor's act")
	battle.queue_free(); await process_frame
	battle = fresh()
	reserve(battle); reserve(battle)
	battle.select_reactor(0); battle.answer_reaction(true)
	battle.submit_command(battle.hud.command_options.find("DEFEND"))
	check(battle.hud.mode == "timing" and battle.rhythm._running, "DEFEND reaction must open real defensive rhythm")
	check(battle._fallen.acts_available == 1, "Defensive timing must cost exactly one reaction act")
	battle.rhythm._finish(BattleMath.RhythmResult.POINT)
	check(battle._fallen.current_hp == 14, "Perfect defensive reaction prevents damage")
	battle.queue_free(); await process_frame
	battle = fresh()
	battle.submit_command(0); battle.submit_target(1)
	battle.rhythm._finish(BattleMath.RhythmResult.POINT)
	check(battle._fallen.acts_available == 0, "A landed resisted hit spends one action plus the documented -1 act")
	check(battle.hud.message.contains("-1 ACT"), "Resist penalty must be explicit in the visible battle log")
	battle.queue_free(); await process_frame
	# D-022: declining the reaction makes the enemy attack an automatic hit.
	battle = AutoHitBattle.new()
	root.add_child(battle)
	reserve(battle); reserve(battle)
	check(battle.hud.mode == "react", "D-022 case must reach an enemy announcement")
	var hp_before: int = battle.action_defender.current_hp
	battle.answer_reaction(false)
	check(battle.log_history.back().contains("rhythm POINT"), "D-022: declined reaction makes the enemy attack hit (got %s)" % battle.log_history.back())
	check(battle.action_defender.current_hp < hp_before, "D-022: the automatic hit deals real damage")
	battle.queue_free(); await process_frame
	# Declaring any reaction (here REST) keeps the normal enemy timing roll (MISS).
	battle = AutoHitBattle.new()
	root.add_child(battle)
	reserve(battle); reserve(battle)
	var defender: BattleUnit = battle.action_defender
	hp_before = defender.current_hp
	battle.select_reactor(battle.hud.players.find(defender))
	battle.answer_reaction(true)
	battle.submit_command(battle.hud.command_options.find("REST"))
	check(battle.log_history.back().contains("rhythm MISS"), "D-022: a declared reaction uses the normal enemy timing (got %s)" % battle.log_history.back())
	check(defender.current_hp == hp_before, "D-022: the missed enemy attack deals no damage")
	battle.queue_free(); await process_frame
	# D-047: o mesmo inimigo resolve dois ataques em bloco, cada um com seu número.
	battle = AutoHitBattle.new()
	root.add_child(battle)
	reserve(battle); reserve(battle)
	check(battle.hud.mode == "react", "D-047: first enemy announcement opens a reaction prompt")
	var combo_attacker: BattleUnit = battle.action_attacker
	battle.answer_reaction(false)
	await process_frame
	var hits1: int = battle.fx.history.count("HIT") + battle.fx.history.count("CRITICAL")
	check(hits1 == 1, "D-047: first combo attack draws one damage number (got %d)" % hits1)
	check(battle.hud.mode == "continue", "D-047: result pause happens after each combo attack")
	battle.proceed()
	check(battle.hud.mode == "react", "D-047: second announcement belongs to the same enemy turn")
	check(battle.action_attacker == combo_attacker, "D-047: the same enemy performs both attacks in one block")
	battle.answer_reaction(false)
	await process_frame
	var hits2: int = battle.fx.history.count("HIT") + battle.fx.history.count("CRITICAL")
	check(hits2 == 2, "D-047: second combo attack draws another damage number (got %d)" % hits2)
	# Creator 2026-11-22: hero damage numbers sit just above the hit hero's card and
	# only appear after the hit animation has ended.
	var hero_hit: Dictionary = {}
	for effect in battle.fx.effects:
		if effect.unit != null and effect.unit.is_player and effect.kind in ["HIT", "CRITICAL"]:
			hero_hit = effect
	check(not hero_hit.is_empty(), "D-047: the second combo hit must still be animating on a hero")
	check(battle.fx.numbers.is_empty(), "No damage number may show while its hit animation is playing")
	var card: Rect2 = hero_hit.target_rect
	var nr: Rect2 = battle.fx.number_rect(hero_hit)
	check(is_equal_approx(nr.end.y, card.position.y), "Hero damage number band must end at the top of the hero's card")
	check(is_equal_approx(nr.position.y, battle.hud.STAGE_RECT.end.y), "Hero damage number band must start below the stage")
	check(nr.position.x == card.position.x and nr.size.x == card.size.x, "Hero damage number stays over the hit hero's card")
	for panel in battle.hud.STATUS_RECTS:
		check(not nr.intersects(panel), "Hero damage number must not cover a status panel")
	var waited := 0.0
	while battle.fx.effects.has(hero_hit) and waited < 5.0:
		await process_frame
		waited += root.get_process_delta_time()
	check(not battle.fx.effects.has(hero_hit), "The hero hit animation must end")
	check(battle.fx.numbers.any(func(n: Dictionary) -> bool: return n.unit == hero_hit.unit and n.amount == hero_hit.amount), "The hero's number appears once the hit animation has ended")
	check(battle.fx.is_busy(), "A showing damage number keeps input gated like the hit did")
	var shown: Dictionary = battle.fx.numbers.filter(func(n: Dictionary) -> bool: return n.unit == hero_hit.unit)[0]
	var expected: Color = battle.fx.LETHAL_INK if not hero_hit.unit.is_alive() else battle.fx.NUMBER_INK
	check(battle.fx.number_color(shown) == expected, "Hero number is #ff3b3b exactly when the hit was lethal")
	battle.queue_free(); await process_frame
	# D-046 no caminho jogável: linhas EXEC/UNDO, marcadores verdes e cadeia compartilhada.
	battle = fresh()
	check(battle.hud.mode == "plan", "Playable battle must open the D-046 plan")
	check(battle.hud.plan_options.size() == 7, "Plan menu must expose five commands plus EXEC and UNDO")
	battle.submit_plan(0)
	check(battle._planned.size() == 1, "One ATTACK must be committed")
	battle.undo_plan()
	check(battle._planned.is_empty(), "UNDO must drop the last planned command")
	battle.submit_plan(0)
	battle.submit_plan(0)
	check(battle._planned.size() == 2, "Two ATTACKs must be committed before resolving")
	check(battle.planned_acts_for(battle._fallen) == 2, "Committed acts must light the green ACT markers")
	battle.exec_plan()
	check(battle.hud.mode == "target", "EXEC must start resolving the plan")
	battle.submit_target(0)
	check(battle.rhythm._chain_mode, "Two planned ATTACKs must share one persistent rhythm line")
	battle.rhythm._finish(BattleMath.RhythmResult.MISS)
	battle.queue_free(); await process_frame
	# Item 2 da auditoria: reação que mata o atacante ainda pausa o resultado do combo.
	battle = AutoHitBattle.new()
	root.add_child(battle)
	reserve(battle); reserve(battle)
	var doomed: BattleUnit = battle.action_attacker
	doomed.current_hp = 1
	battle.select_reactor(0)
	battle.answer_reaction(true)
	battle.submit_command(0)
	battle.counter.finish(BattleMath.RhythmResult.POINT, BattleMath.RhythmResult.MISS)
	check(not doomed.is_alive(), "The counter-attack must defeat the announced attacker")
	check(battle.hud.mode == "continue", "An interrupted combo must still pause so the player reads the reaction")
	battle.queue_free(); await process_frame
	print("PLAYABLE_REACTIONS_OK: %d checks; two attacks, two reactions, D-022 auto-hit, D-038 REST, D-046 playable plan, D-047 enemy combo and interrupted pause" % checks)
	# Let queued battle nodes and their pending coroutines release before exit.
	await process_frame
	await process_frame
	quit(0)

func _finalize() -> void:
	SANDBOX.end()
