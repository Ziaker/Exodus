extends SceneTree
## D-105 (creator 2026-11-25): PASS hands the turn over without spending acts; the hero acts
## again later in the same round; the round ends when the turn comes back to someone who
## passed with nobody acting since; REST stays as it was on the own turn and is no reaction.
const SANDBOX := preload("res://tests/progress_sandbox.gd")

class ControlledBattle extends "res://scripts/battle/playable_controller.gd":
	func _enemy_skill_pick(_n: int) -> int: return 0
	func _ai_roll(_attacker: BattleUnit, _defender: BattleUnit) -> int:
		return BattleMath.RhythmResult.MISS
	func _defender_reaction(_defender: BattleUnit, _attacker: BattleUnit) -> int:
		return BattleMath.RhythmResult.MISS
	func _enemy_counter_roll(_e: BattleUnit) -> bool:
		return false
	# Act economy only: enemy attacks never land (no D-022 auto-hit).
	func _perform_attack(attacker: BattleUnit, defender: BattleUnit, power: int, is_reaction: bool, defense_act_paid: bool = false, _auto_hit: bool = false, _chain: bool = false) -> void:
		await super._perform_attack(attacker, defender, power, is_reaction, defense_act_paid, false, _chain)

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

func fresh(reserve := false) -> Control:
	var battle := ControlledBattle.new()
	battle.offer_reserve = reserve
	root.add_child(battle)
	return battle

func advance(battle: Control, frames: int = 600) -> void:
	for i in frames:
		if battle.hud.mode in ["continue", "announce"]: battle.proceed()
		elif battle.hud.mode == "react": battle.answer_reaction(false)
		elif battle.hud.mode not in ["busy", "turn"]: return
		await process_frame

## A fresh battle fills its menu a few frames after _ready.
func wait_menu(battle: Control) -> void:
	for _i in 60:
		if battle.hud.mode in ["plan", "command"] and not battle.hud.command_options.is_empty(): return
		await process_frame

func names(units: Array) -> Array:
	return units.map(func(u: BattleUnit) -> String: return u.display_name)

func _run() -> void:
	var battle := fresh()
	await wait_menu(battle)
	var fallen: BattleUnit = battle._fallen
	var yoch: BattleUnit = battle._ally
	var foe_a: BattleUnit = battle.state.units[2]
	var foe_b: BattleUnit = battle.state.units[3]
	# D-109: the enemy's white-mark blow now lands for 50%; this test checks the act economy
	# only, so the heroes get enough HP to survive every pass.
	for hero in [fallen, yoch]:
		hero.stats.max_hp = 999
		hero.current_hp = 999
	check(battle.state.turn_order == ([fallen, foe_b, yoch, foe_a] as Array[BattleUnit]), "Turn order Fallen, FOE B, Yoch, FOE A (%s)" % [names(battle.state.turn_order)])
	# Menu: PASS right before REST, on Fallen's own turn.
	check(battle.active_actor == fallen and battle.hud.mode == "plan", "Round 1 opens on Fallen's plan")
	check(battle.hud._menu_rows() == ["FIGHT", "ITEM", "PASS", "REST", "ABSORB"], "Fallen's menu: FIGHT, ITEM, PASS, REST, ABSORB (%s)" % [battle.hud._menu_rows()])

	# ---- 1. Fallen passes at once: no act, no EN, no SP; the turn goes to FOE B.
	var en_before: int = fallen.current_en
	var sp_before: int = fallen.current_sp
	battle.submit_command(battle.hud.command_options.find("PASS"))
	check(fallen.acts_available == 2 and fallen.stored_acts == 0, "PASS spends no act and stores nothing (%d/%d)" % [fallen.acts_available, fallen.stored_acts])
	check(fallen.current_en == en_before and fallen.current_sp == sp_before, "PASS gives no EN and no SP")
	check(battle.log_history.any(func(l: String) -> bool: return l.contains("FALLEN passes the turn: 2 act(s) kept.")), "Log tells the pass and the acts kept")
	await advance(battle)
	check(foe_b.acts_available == 0, "FOE B played after Fallen's pass (acts %d)" % foe_b.acts_available)
	check(battle.active_actor == yoch and battle.hud.mode == "plan", "Then Yoch's turn")
	check(battle.hud._menu_rows() == ["FIGHT", "PRAY", "ITEM", "PASS", "REST"], "Yoch's menu: FIGHT, PRAY, ITEM, PASS, REST (%s)" % [battle.hud._menu_rows()])

	# ---- 2. Yoch passes too; FOE A plays; the turn comes back to Fallen IN THE SAME ROUND.
	battle.submit_command(battle.hud.command_options.find("PASS"))
	check(yoch.acts_available == 2, "Yoch keeps both acts")
	await advance(battle)
	check(foe_a.acts_available == 0, "FOE A played after Yoch's pass")
	check(battle.state.round_number == 1, "Still round 1 (round %d)" % battle.state.round_number)
	check(battle.active_actor == fallen and battle.hud.mode == "plan" and fallen.acts_available == 2, "After PASS Fallen acts again later in the same round with both acts")

	# ---- 3. A queue may end with PASS: ATTACK, PASS spends one act and keeps the other.
	battle.submit_plan(battle.hud.plan_options.find("FIGHT"))
	# D-109: the white mark now lands; FOE B (RESIST) gives no WEAK +1 act, so the count stays exact.
	battle.submit_target(1)
	check(battle.hud.mode == "plan", "Back to planning after choosing the ATTACK target")
	battle.submit_plan(battle.hud.plan_options.find("PASS"))
	check(battle.hud.mode == "timing", "PASS closed the queue and the ATTACK runs (mode %s)" % battle.hud.mode)
	battle.rhythm._finish(BattleMath.RhythmResult.MISS)
	await advance(battle)
	check(fallen.acts_available == 1, "ATTACK spent one act, PASS none (%d left)" % fallen.acts_available)
	check(battle.log_history.any(func(l: String) -> bool: return l.contains("FALLEN passes the turn: 1 act(s) kept.")), "The queued PASS ran after the ATTACK")
	# Enemies are out of acts, so the turn goes to Yoch (who passed earlier but a real turn
	# came after his pass) — the round goes on.
	check(battle.state.round_number == 1 and battle.active_actor == yoch and battle.hud.mode == "plan", "Yoch gets his turn back in round 1 (round %d, actor %s)" % [battle.state.round_number, battle.active_actor.display_name])

	# ---- 4. Yoch passes again: everyone left with a turn passed -> the round ends,
	# leftover acts go to the stock (D-005) and round 2 starts with them.
	battle.submit_command(battle.hud.command_options.find("PASS"))
	await advance(battle)
	check(battle.state.round_number == 2, "Everyone left passed: round 2 starts (round %d)" % battle.state.round_number)
	check(fallen.acts_available == 3, "Fallen's unused act came back as +1 act (2 + 1 = %d)" % fallen.acts_available)
	check(yoch.acts_available == 4, "Yoch's two unused acts came back (2 + 2 = %d)" % yoch.acts_available)
	check(battle.active_actor == fallen and battle.hud.mode == "plan", "Round 2 opens on Fallen")

	# ---- 5. The only one with acts passes: the round ends at once.
	battle.queue_free(); await process_frame
	battle = fresh()
	await wait_menu(battle)
	fallen = battle._fallen
	for u: BattleUnit in battle.state.units:
		if u != fallen: u.acts_available = 0
	battle.submit_command(battle.hud.command_options.find("PASS"))
	await advance(battle)
	check(battle.state.round_number == 2, "Fallen alone with acts passes: the round ends (round %d)" % battle.state.round_number)
	check(fallen.acts_available == 4, "His two acts went to the stock: 2 + 2 = %d" % fallen.acts_available)

	# ---- 6. REST on the own turn is unchanged (D-038): 0 act, +2 EN, acts stored, done.
	battle.queue_free(); await process_frame
	battle = fresh()
	await wait_menu(battle)
	fallen = battle._fallen
	fallen.current_en = 0
	battle.submit_command(battle.hud.command_options.find("REST"))
	check(fallen.current_en == BattleMath.REST_EN_RECOVERY, "REST still gives exactly 2 EN")
	check(fallen.acts_available == 0 and fallen.stored_acts == 2, "REST still stores both acts and ends the round for him")

	# ---- 7. Neither REST nor PASS is a reaction.
	battle.queue_free(); await process_frame
	battle = fresh(true)
	await wait_menu(battle)
	# Fallen reserves (test-only REACT); FOE B announces right away (verify_playable_reactions).
	for _i in 2:
		if battle.hud.mode in ["plan", "command"] and battle.hud.command_options.has("REACT"):
			battle.submit_command(battle.hud.command_options.find("REACT"))
	check(battle.hud.mode == "react", "An enemy announcement opens the reaction prompt")
	battle.select_reactor(0)
	battle.answer_reaction(true)
	var react_opts: Array = battle.hud.command_options
	check(react_opts.has("DEFEND") and not react_opts.has("REST") and not react_opts.has("PASS"), "Reaction menu has no REST and no PASS (%s)" % [react_opts])

	# ---- 8. D-049: a lost PASS gives the interrupter no act.
	var foe: BattleUnit = battle.state.units[3]
	var foe_acts: int = foe.acts_available
	battle._lose_queue(battle._fallen, ["FIGHT", "PASS"], foe, 1)
	check(foe.acts_available == foe_acts + 1, "Lost FIGHT + PASS: the enemy gains 1 act, not 2 (%d -> %d)" % [foe_acts, foe.acts_available])
	battle.queue_free(); await process_frame

	print("PLAYABLE_PASS_OK: %d checks; D-105 PASS keeps acts, hero acts again in the same round, all-passed ends the round, REST unchanged and no reaction" % checks)
	quit(0)

func _finalize() -> void:
	SANDBOX.end()
