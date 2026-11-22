extends SceneTree
const SANDBOX := preload("res://tests/progress_sandbox.gd")

class ControlledBattle extends "res://scripts/battle/playable_controller.gd":
	func _ai_roll(_attacker: BattleUnit, _defender: BattleUnit) -> int:
		return BattleMath.RhythmResult.MISS
	func _defender_reaction(_defender: BattleUnit, _attacker: BattleUnit) -> int:
		return BattleMath.RhythmResult.MISS
	# These checks isolate act economy, so enemy attacks must never land. D-022
	# auto-hit is disabled here and covered by AutoHitBattle below.
	func _perform_attack(attacker: BattleUnit, defender: BattleUnit, power: int, is_reaction: bool, defense_act_paid: bool = false, _auto_hit: bool = false) -> void:
		await super._perform_attack(attacker, defender, power, is_reaction, defense_act_paid, false)

## D-022: enemy timing always rolls MISS, so a landed POINT can only come from auto-hit.
class AutoHitBattle extends "res://scripts/battle/playable_controller.gd":
	func _ai_roll(_attacker: BattleUnit, _defender: BattleUnit) -> int:
		return BattleMath.RhythmResult.MISS
	func _defender_reaction(_defender: BattleUnit, _attacker: BattleUnit) -> int:
		return BattleMath.RhythmResult.MISS

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
	check(battle.active_actor == battle._ally, "Acts remain interleaved, not two consecutive attacks")
	battle.submit_command(0); battle.submit_target(0)
	battle.rhythm._finish(BattleMath.RhythmResult.MISS)
	await advance(battle)
	check(battle.active_actor == battle._fallen and battle.state.round_number == 1, "Fallen must get a second action in round one")
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
		battle._fallen.current_en = 0
		battle.answer_reaction(true)
		check(battle.hud.command_options.has("ATTACK") and battle.hud.command_options.has("ITEM") and battle.hud.command_options.has("REST") and battle.hud.command_options.has("ABSORB") and battle.hud.command_options.has("DEFEND"), "D-043: the attacked Fallen keeps every command plus DEFEND as a reaction")
		battle.submit_command(battle.hud.command_options.find("REST"))
		check(battle._fallen.current_en == 1, "Off-turn rest must recover real energy")
		check(battle._fallen.acts_available == 1 - reaction, "Each reaction must spend exactly one shared act")
		check(battle.state.round_number == 1, "Both reactions must occur in round one")
		if reaction == 0:
			battle.proceed()
			check(battle.hud.mode == "react", "A second enemy announcement must offer the remaining reaction")
	battle.queue_free(); await process_frame
	battle = fresh()
	reserve(battle); reserve(battle)
	battle.select_reactor(1)
	battle.answer_reaction(true)
	check(not battle.hud.command_options.has("ABSORB"), "Ally must not receive Fallen-only absorption")
	check(battle.reaction_defender == battle._fallen and battle.hud.command_options == ["ATTACK", "ITEM"], "D-043: a reactor who is not the target may only counter-attack or use an item (got %s)" % [battle.hud.command_options])
	battle.submit_command(0); battle.submit_target(0)
	battle.rhythm._finish(BattleMath.RhythmResult.MISS)
	check(battle._ally.acts_available == 1 and battle._fallen.acts_available == 2, "Ally may react when Fallen is attacked, spending only Ally's act")
	check(battle.log_history.any(func(line: String) -> bool: return line.begins_with("ALLY ->")), "Off-turn attack must use the real attack resolver")
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
	print("PLAYABLE_REACTIONS_OK: %d checks; two attacks, two reactions, shared acts, ally response, full reaction commands, D-022 auto-hit" % checks)
	quit(0)

func _finalize() -> void:
	SANDBOX.end()
