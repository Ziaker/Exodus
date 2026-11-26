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
	battle.offer_reserve = true  # creator 2026-11-24: REACT left the own-turn menu
	root.add_child(battle)
	# D-109 (criador 2026-11-25): a trilha branca agora acerta com 50%. Estes checks isolam a
	# economia de atos, entao nenhum golpe pode matar nem dar +1 ACT por fraqueza.
	for hero in battle.hud.players:
		hero.stats.max_hp = 999
		hero.current_hp = 999
	for foe in battle.hud.opponents:
		foe.stats.max_hp = 999
		foe.current_hp = 999
		if foe.affinity == BattleMath.Affinity.WEAK:
			foe.affinity = BattleMath.Affinity.NORMAL
	return battle

func advance(battle: Control, frames: int = 60) -> void:
	for i in frames:
		if battle.hud.mode in ["continue", "announce"]: battle.proceed()
		elif battle.hud.mode == "react": battle.answer_reaction(false)
		else: return
		await process_frame

## D-057: Z first pages the event lines still waiting beyond the two-row log, then goes on.
func confirm(battle: Control) -> void:
	for _i in 8:
		var paging: bool = battle.hud.mode in ["continue", "announce"] and battle.hud.log_hidden()
		battle.proceed()
		if not paging: return

## Creator 2026-11-23: FOE B plays right after Fallen, before Yoch, so once Fallen reserves
## the enemy announces at once; a second call (Yoch's REACT) then has no own turn to use.
func reserve(battle: Control) -> void:
	if battle.hud.mode not in ["plan", "command"]: return
	var index: int = battle.hud.command_options.find("REACT")
	check(index >= 0, "Own-turn menu must expose REACT to reserve acts")
	battle.submit_command(index)

## D-109: dano que o golpe do inimigo (trilha branca, 50%) causou em FALLEN depois da acao.
func hit_on_fallen(battle: Control) -> int:
	var total := 0
	for line in battle.log_history:
		if String(line).contains("-> FALLEN: ") and String(line).contains(" dmg"):
			total = String(line).get_slice("-> FALLEN: ", 1).get_slice(" dmg", 0).to_int()
	return total

func _run() -> void:
	var battle := fresh()
	check(battle._fallen.acts_available == 2, "Opening the menu must show both acts, not spend one in advance")
	check(battle.hud.command_options.has("REACT"), "REACT must be discoverable from the normal menu")
	battle.submit_command(0); battle.cancel_target()
	check(battle._fallen.acts_available == 2, "Canceling target must not consume an act")
	battle.submit_command(0); battle.submit_target(0)
	battle.rhythm._finish(BattleMath.RhythmResult.MISS)
	check(battle._fallen.acts_available == 1, "One attack spends exactly one act")
	# Creator 2026-11-23: one turn each by speed. Fallen (AGI 6) used his turn; FOE B (AGI 5,
	# more SP than Yoch) attacks, then Yoch (AGI 5) plays, FOE A (AGI 4), then Fallen again.
	var foe_b: BattleUnit = battle.state.units[3]
	var foe_a: BattleUnit = battle.state.units[2]
	check(battle.state.turn_order == ([battle._fallen, foe_b, battle._ally, foe_a] as Array[BattleUnit]), "Turn order: fastest first, AGI tie to the higher SP (%s)" % [battle.state.turn_order.map(func(u: BattleUnit) -> String: return u.display_name)])
	await advance(battle)
	# D-057 (creator 2026-11-25): the act left after the queue is planned in the same turn;
	# the turn only ends with 0 acts or REST.
	check(battle.active_actor == battle._fallen and battle.hud.mode == "plan" and battle._fallen.acts_available == 1, "After the first command Fallen plans his act left in the same turn")
	check(foe_b.acts_available == 2 and foe_a.acts_available == 2, "Nobody else played during Fallen's turn")
	battle.submit_command(0); battle.submit_target(0)
	battle.rhythm._finish(BattleMath.RhythmResult.MISS)
	check(battle._fallen.acts_available == 0, "Two attacks consume the two available acts")
	var attacks := 0
	for line in battle.log_history:
		if line.begins_with("FALLEN ->"): attacks += 1
	check(attacks == 2, "Two physical attacks must actually resolve in the same round")
	await advance(battle)
	check(battle.active_actor == battle._ally and foe_b.acts_available == 0 and foe_a.acts_available == 2, "With Fallen at 0 acts the turn passes on: FOE B, then Yoch")
	battle.submit_command(battle.hud.command_options.find("REST"))
	await advance(battle)
	# FOE A played after Yoch and the round closed: round 2 opens with Fallen planning.
	check(battle.state.round_number == 2 and battle.active_actor == battle._fallen and battle.hud.mode == "plan", "FOE A plays after Yoch, then the next round starts (round %d)" % battle.state.round_number)
	battle.queue_free(); await process_frame
	battle = fresh()
	reserve(battle)
	check(battle._fallen.acts_available == 2, "Waiting to react must not spend an act")
	reserve(battle)
	check(battle.hud.mode == "react", "Enemy announcement must open a reaction prompt")
	for reaction in 2:
		battle.select_reactor(0)
		battle.answer_reaction(true)
		check(battle.hud.command_options.has("FIGHT") and battle.hud.command_options.has("ITEM") and battle.hud.command_options.has("DEFEND"), "D-045: the attacked Fallen keeps FIGHT, ITEM plus DEFEND as a reaction")
		check(not battle.hud.command_options.has("ABSORB"), "D-104: ABSORB is never a reaction (got %s)" % [battle.hud.command_options])
		# D-105 (creator 2026-11-25): REST and PASS are own-turn only.
		check(not battle.hud.command_options.has("REST") and not battle.hud.command_options.has("PASS"), "D-105: REST and PASS are not reactions (%s)" % [battle.hud.command_options])
		battle.submit_command(0)  # counter-attack: D-038 REST no longer spends acts
		# D-049: the counter uses the two-rail exchange; both MISS = tie (D-109: both hit for 50%).
		check(battle.hud.mode == "counter", "D-049: a counter-attack opens the two-rail exchange")
		battle.counter.finish(BattleMath.RhythmResult.MISS, BattleMath.RhythmResult.MISS)
		check(battle._fallen.acts_available == 1 - reaction, "Each reaction must spend exactly one shared act")
		check(battle.state.round_number == 1, "Both reactions must occur in round one")
		if reaction == 0:
			confirm(battle)
			# The counter tie cost FOE B its second attack; Yoch's turn comes before FOE A's.
			check(battle.active_actor == battle._ally and battle.hud.mode == "plan", "After FOE B, Yoch plays before FOE A")
			reserve(battle)
			check(battle.hud.mode == "react", "A second enemy announcement must offer the remaining reaction")
	battle.queue_free(); await process_frame
	# D-105 (creator 2026-11-25): REST left the reactions (it stays on the own turn, D-038).
	battle = fresh()
	reserve(battle); reserve(battle)
	battle.select_reactor(0)
	battle.answer_reaction(true)
	check(battle.hud.command_options.find("REST") == -1, "D-105: REST is no longer offered as a reaction")
	battle.queue_free(); await process_frame
	battle = fresh()
	reserve(battle); reserve(battle)
	battle.select_reactor(1)
	battle.answer_reaction(true)
	check(not battle.hud.command_options.has("ABSORB"), "Ally must not receive Fallen-only absorption")
	check(battle.reaction_defender == battle._fallen and battle.hud.command_options == ["FIGHT", "PRAY", "ITEM"], "D-045: a reactor who is not the target may only counter-attack or use an item; D-048 (creator 2026-11-23): Yoch may also PRAY (got %s)" % [battle.hud.command_options])
	battle.submit_command(0)
	# Both MISS: a tie, so both strikes resolve (D-109: 50% each) and no affinity penalty applies.
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
	check(hit_on_fallen(battle) > 0 and battle._fallen.current_hp == 7 - hit_on_fallen(battle), "Ally reaction must heal Fallen (+6), not the reactor; D-109: the white-mark attack then hits (hp %d)" % battle._fallen.current_hp)
	check(battle._ally.acts_available == 1 and battle._fallen.acts_available == 2, "Reaction item spends only the reactor's act")
	battle.queue_free(); await process_frame
	battle = fresh()
	reserve(battle); reserve(battle)
	battle.select_reactor(0); battle.answer_reaction(true)
	battle.submit_command(battle.hud.command_options.find("DEFEND"))
	check(battle.hud.mode == "timing" and battle.rhythm._running, "DEFEND reaction must open real defensive rhythm")
	check(battle._fallen.acts_available == 1, "Defensive timing must cost exactly one reaction act")
	battle.rhythm._finish(BattleMath.RhythmResult.POINT)
	check(battle._fallen.current_hp == 999, "Perfect defensive reaction prevents damage")
	battle.queue_free(); await process_frame
	battle = fresh()
	battle.submit_command(0); battle.submit_target(1)
	battle.rhythm._finish(BattleMath.RhythmResult.POINT)
	# D-057 (creator 2026-11-25): an affinity never takes an act; RESIST spends only the action.
	check(battle._fallen.acts_available == 1, "A landed resisted hit spends only its own act (no -1 penalty)")
	check(not battle.hud.events.any(func(e: Dictionary) -> bool: return String(e.text).contains("loses") or String(e.text).contains("COMMAND")), "No act loss is told for a resisted hit")
	battle.queue_free(); await process_frame
	# D-022: declining the reaction makes the enemy attack an automatic hit.
	battle = AutoHitBattle.new()
	battle.offer_reserve = true  # creator 2026-11-24: REACT left the own-turn menu
	root.add_child(battle)
	reserve(battle); reserve(battle)
	check(battle.hud.mode == "react", "D-022 case must reach an enemy announcement")
	var hp_before: int = battle.action_defender.current_hp
	battle.answer_reaction(false)
	check(battle.log_history.back().contains("rhythm POINT"), "D-022: declined reaction makes the enemy attack hit (got %s)" % battle.log_history.back())
	check(battle.action_defender.current_hp < hp_before, "D-022: the automatic hit deals real damage")
	battle.queue_free(); await process_frame
	# Declaring any reaction (here DEFEND; REST left the reactions, D-105) keeps the normal
	# enemy timing roll (MISS = white mark, D-109).
	battle = AutoHitBattle.new()
	battle.offer_reserve = true  # creator 2026-11-24: REACT left the own-turn menu
	root.add_child(battle)
	reserve(battle); reserve(battle)
	var defender: BattleUnit = battle.action_defender
	hp_before = defender.current_hp
	battle.select_reactor(battle.hud.players.find(defender))
	battle.answer_reaction(true)
	battle.submit_command(battle.hud.command_options.find("DEFEND"))
	# The DEFEND line comes first; wait for the enemy blow to resolve.
	for _f in 300:
		if battle.log_history.back().contains("rhythm"): break
		await process_frame
	check(battle.log_history.back().contains("rhythm MISS"), "D-022: a declared reaction uses the normal enemy timing (got %s)" % battle.log_history.back())
	check(defender.current_hp < hp_before and battle.log_history.back().contains("HIT 50%"), "D-109: the enemy white mark still hits for 50%% (got %s)" % battle.log_history.back())
	battle.queue_free(); await process_frame
	# D-047: o mesmo inimigo resolve dois ataques em bloco, cada um com seu número.
	battle = AutoHitBattle.new()
	battle.offer_reserve = true  # creator 2026-11-24: REACT left the own-turn menu
	root.add_child(battle)
	# Creator 2026-11-23: Fallen's death ends the battle; he must survive both hits here.
	battle._fallen.current_hp = 999
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
	# Creator 2026-11-24 (HUD option 13): hero damage numbers sit over the hit hero's
	# window and only appear after the hit animation has ended.
	var hero_hit: Dictionary = {}
	for effect in battle.fx.effects:
		if effect.unit != null and effect.unit.is_player and effect.kind in ["HIT", "CRITICAL"]:
			hero_hit = effect
	check(not hero_hit.is_empty(), "D-047: the second combo hit must still be animating on a hero")
	check(battle.fx.numbers.is_empty(), "No damage number may show while its hit animation is playing")
	var card: Rect2 = hero_hit.target_rect
	var nr: Rect2 = battle.fx.number_rect(hero_hit)
	check(nr == card and battle.hud.STATUS_RECTS.has(card), "Hero damage number sits over the hit hero's own window")
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
	# Creator 2026-11-24: EXEC/UNDO only once something is queued (REACT here: test driver).
	# D-105: FIGHT, ITEM, PASS, REST, ABSORB + REACT = 6.
	check(battle.hud.plan_options.size() == 6 and not battle.hud.plan_options.has("EXEC"), "Empty plan: commands only, no EXEC or UNDO")
	# D-057: each ATTACK takes its target while planning.
	battle.submit_plan(0); battle.submit_target(0)
	check(battle._planned.size() == 1 and battle.queued_acts_for(battle.hud.opponents[0]) == 1, "One ATTACK must be committed with its target")
	check(battle.hud.plan_options.slice(-2) == ["EXEC", "UNDO"], "A queued command brings EXEC and UNDO")
	battle.undo_plan()
	check(battle._planned.is_empty() and battle.queued_acts_for(battle.hud.opponents[0]) == 0, "UNDO must drop the last planned command and its target mark")
	battle.submit_plan(0); battle.submit_target(0)
	check(battle._planned.size() == 1 and battle.planned_acts_for(battle._fallen) == 1, "Committed acts must light the green ACT markers")
	battle.submit_plan(0); battle.submit_target(0)
	# Two acts committed: the plan runs at once, no confirmation and no target question.
	check(battle.hud.mode == "timing" and battle.rhythm._chain_mode, "Two planned ATTACKs on one target run at once on one persistent rhythm line")
	check(battle.planned_acts_for(battle._fallen) == 1, "During the queue only the command still to run stays green")
	battle.rhythm._finish(BattleMath.RhythmResult.MISS)
	battle.queue_free(); await process_frame
	# Item 2 da auditoria: reação que mata o atacante ainda pausa o resultado do combo.
	battle = AutoHitBattle.new()
	battle.offer_reserve = true  # creator 2026-11-24: REACT left the own-turn menu
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
	print("PLAYABLE_REACTIONS_OK: %d checks; two attacks, two reactions, D-022 auto-hit, D-105 no REST reaction, D-046 playable plan, D-047 enemy combo and interrupted pause" % checks)
	# Let queued battle nodes and their pending coroutines release before exit.
	await process_frame
	await process_frame
	quit(0)

func _finalize() -> void:
	SANDBOX.end()
