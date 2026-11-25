extends SceneTree
## D-064 (creator 2026-11-25): ABSORB is an immediate action of the hero's own turn. It costs
## exactly 2 ACT, puts nothing in the queue, resolves the moment it is chosen and is never a
## reaction. Without 2 acts free of the queue the row is dimmed and refuses (like a skill the
## hero cannot pay). How the absorption itself resolves (mash, gains) is not tested here.
const SANDBOX := preload("res://tests/progress_sandbox.gd")

class AbsorbBattle extends "res://scripts/battle/playable_controller.gd":
	func _enemy_skill_pick(_n: int) -> int: return 0
	func _ai_roll(_a: BattleUnit, _b: BattleUnit) -> int: return BattleMath.RhythmResult.MISS
	func _defender_reaction(_a: BattleUnit, _b: BattleUnit) -> int: return BattleMath.RhythmResult.MISS
	func _enemy_counter_roll(_e: BattleUnit) -> bool: return false
	## When true the absorption minigame is replaced by a probe recording the moment it ran.
	var stub := true
	var absorb_calls: Array[Dictionary] = []
	func _perform_absorption(unit: BattleUnit, defender: BattleUnit) -> void:
		if not stub:
			await super._perform_absorption(unit, defender)
			return
		absorb_calls.append({
			"unit": unit, "target": defender, "acts": unit.acts_available,
			"planned": _planned.duplicate(), "targets": _planned_targets.duplicate(),
			"exec_index": _exec_index, "mode": hud.mode, "reacting": in_reaction,
			"hp": [hud.opponents[0].current_hp, hud.opponents[1].current_hp],
		})

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

func fresh(stub: bool = true) -> Control:
	var battle := AbsorbBattle.new()
	battle.stub = stub
	battle.offer_reserve = true
	battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(battle)
	return battle

func wait_mode(battle: Control, modes: Array, seconds: float = 6.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while battle.hud.mode not in modes and Time.get_ticks_msec() < deadline:
		await process_frame
	return battle.hud.mode in modes

## Z through the result pause (pages any hidden log lines first).
func confirm(battle: Control) -> void:
	for _i in 8:
		if battle.hud.mode not in ["continue", "announce"]: return
		battle.proceed()

func absorb_row(battle: Control) -> int:
	return battle.hud.plan_options.find("ABSORB")

func fight_row(battle: Control) -> int:
	return battle.hud.plan_options.find("FIGHT")


func _run() -> void:
	# ---- 1. Cost: exactly 2 ACT, spent before the absorption runs.
	var battle := fresh()
	check(await wait_mode(battle, ["plan"]), "Fallen's turn opens the plan")
	var fallen: BattleUnit = battle._fallen
	fallen.acts_available = 4
	battle._refresh_all()
	check(absorb_row(battle) >= 0 and not battle.plan_row_disabled(absorb_row(battle)), "With 4 acts ABSORB is offered and enabled")
	battle.submit_plan(absorb_row(battle))
	check(battle.hud.mode == "target", "ABSORB asks for its target at once")
	battle.submit_target(0)
	check(battle.absorb_calls.size() == 1, "The absorption ran the moment the target was chosen (calls %d)" % battle.absorb_calls.size())
	check(int(battle.absorb_calls[0].acts) == 2, "2 ACT were spent before the absorption (4 -> %d)" % int(battle.absorb_calls[0].acts))
	check(fallen.acts_available == 2, "ABSORB costs exactly 2 ACT (4 -> %d)" % fallen.acts_available)
	check(battle.absorb_calls[0].target == battle.hud.opponents[0], "It absorbs the chosen target")
	check(int(battle.absorb_calls[0].exec_index) == -1 and battle.absorb_calls[0].planned.is_empty(), "It ran while planning, not as a queued command")
	check(battle.hud.mode == "continue", "Its result pauses for Z like any resolved action (mode %s)" % battle.hud.mode)
	confirm(battle)
	check(battle.hud.mode == "plan" and battle.active_actor == fallen, "The plan goes on with the 2 acts left (mode %s)" % battle.hud.mode)
	check(battle._planned.is_empty() and battle.hud.plan_options.find("EXEC") < 0, "Nothing was queued: no EXEC / UNDO in the menu (%s)" % [battle.hud.plan_options])
	check(battle.queued_acts_for(battle.hud.opponents[0]) == 0, "No queued-act marker on the absorbed target")
	battle.queue_free(); await process_frame

	# ---- 2. With 2 acts, ABSORB takes both and the turn ends without a queue.
	battle = fresh()
	await wait_mode(battle, ["plan"])
	fallen = battle._fallen
	check(fallen.acts_available == 2, "Round 1 starts with 2 acts")
	battle.submit_command(absorb_row(battle))  # driver API: "execute now"
	check(battle.hud.mode == "target", "submit_command(ABSORB) also asks for the target")
	battle.submit_target(1)
	check(battle.absorb_calls.size() == 1 and battle.absorb_calls[0].target == battle.hud.opponents[1] and fallen.acts_available == 0, "Both acts spent on the immediate absorption")
	confirm(battle)
	await process_frame
	check(battle.active_actor != fallen or battle.hud.mode != "plan", "With 0 acts left Fallen's turn ends")
	battle.queue_free(); await process_frame

	# ---- 3. The queue is unchanged by an absorption made in the middle of planning.
	battle = fresh()
	await wait_mode(battle, ["plan"])
	fallen = battle._fallen
	fallen.acts_available = 4
	var foe_a: BattleUnit = battle.hud.opponents[0]
	var foe_b: BattleUnit = battle.hud.opponents[1]
	var hp_b: int = foe_b.current_hp
	battle.submit_plan(fight_row(battle))
	battle.submit_target(1)
	check(battle._planned.size() == 1 and battle._planned_targets == [foe_b], "FIGHT on FOE B is queued")
	var planned_before: Array = battle._planned.duplicate()
	var targets_before: Array = battle._planned_targets.duplicate()
	var skills_before: Array = battle._planned_skills.duplicate(true)
	check(not battle.plan_row_disabled(absorb_row(battle)), "4 acts, 1 committed: 3 free, ABSORB enabled")
	battle.submit_plan(absorb_row(battle))
	battle.submit_target(0)
	check(battle.absorb_calls.size() == 1, "ABSORB ran at once with a queue open")
	check(battle.absorb_calls[0].planned == planned_before and battle.absorb_calls[0].targets == targets_before, "While it ran the queue held only the FIGHT on FOE B")
	check(battle.absorb_calls[0].hp == [foe_a.current_hp, hp_b], "The queued FIGHT had not run before the absorption")
	confirm(battle)
	check(battle.hud.mode == "plan", "Back in the plan after the absorption (mode %s)" % battle.hud.mode)
	check(battle._planned == planned_before and battle._planned_targets == targets_before and battle._planned_skills == skills_before, "The queue is unchanged after absorbing")
	check(battle.queued_acts_for(foe_b) == 1 and battle.queued_acts_for(foe_a) == 0, "Target markers unchanged: 1 on FOE B, none on FOE A")
	check(fallen.acts_available == 2 and battle.planned_acts_for(fallen) == 1, "2 acts left, 1 still committed to the queue")
	check(foe_b.current_hp == hp_b, "The queued FIGHT still has not run")
	# The queue still runs normally afterwards.
	battle.exec_plan()
	check(await wait_mode(battle, ["timing", "continue"]), "EXEC runs the queued FIGHT")
	if battle.hud.mode == "timing": battle.rhythm._finish(BattleMath.RhythmResult.BEAM)
	check(fallen.acts_available == 1, "The FIGHT spends its own act (2 -> %d)" % fallen.acts_available)
	battle.queue_free(); await process_frame

	# ---- 4. Fewer than 2 free acts: the row is dimmed and refuses; nothing runs or changes.
	battle = fresh()
	await wait_mode(battle, ["plan"])
	fallen = battle._fallen
	foe_b = battle.hud.opponents[1]
	hp_b = foe_b.current_hp
	battle.submit_plan(fight_row(battle))
	battle.submit_target(1)
	check(fallen.acts_available == 2 and battle._planned.size() == 1, "2 acts, 1 committed: 1 free")
	var row := absorb_row(battle)
	check(battle.plan_row_disabled(row) and not battle.absorb_affordable(fallen), "With 1 free act ABSORB is dimmed")
	battle.submit_plan(row)
	check(battle.hud.mode == "plan" and battle.absorb_calls.is_empty(), "submit_plan(ABSORB) is refused: no target prompt, no absorption")
	battle.submit_command(row)
	check(battle.hud.mode == "plan" and battle.absorb_calls.is_empty() and foe_b.current_hp == hp_b, "submit_command(ABSORB) is refused too and does not run the queue")
	check(battle._planned.size() == 1 and fallen.acts_available == 2, "Refusal spends nothing and keeps the queue")
	battle.queue_free(); await process_frame
	battle = fresh()
	await wait_mode(battle, ["plan"])
	battle._fallen.acts_available = 1
	battle._refresh_all()
	check(battle.plan_row_disabled(absorb_row(battle)), "With 1 act in total ABSORB is dimmed")
	battle.submit_plan(absorb_row(battle))
	check(battle.hud.mode == "plan" and battle.absorb_calls.is_empty() and battle._fallen.acts_available == 1, "and refused without spending the act")
	battle.queue_free(); await process_frame

	# ---- 5. Never a reaction.
	battle = fresh()
	await wait_mode(battle, ["plan"])
	fallen = battle._fallen
	battle.submit_command(battle.hud.command_options.find("REACT"))
	battle.submit_command(battle.hud.command_options.find("REACT"))
	check(await wait_mode(battle, ["react"]), "An enemy announcement opens the reaction prompt")
	check(battle.reaction_defender == fallen, "The announced attack targets Fallen")
	battle.select_reactor(0)
	battle.answer_reaction(true)
	check(battle.hud.mode == "command" and battle.in_reaction, "Fallen opens the reaction commands")
	check(not battle.hud.command_options.has("ABSORB"), "ABSORB is absent from the REACT menu (%s)" % [battle.hud.command_options])
	check(battle.hud.command_options.has("DEFEND") and battle.hud.command_options.has("FIGHT"), "The other reaction commands stay (%s)" % [battle.hud.command_options])
	check(not battle._commands(fallen, true).has("ABSORB") and battle._commands(fallen, false).has("ABSORB"), "_commands: ABSORB only outside a reaction")
	check(not battle.absorb_affordable(fallen), "absorb_affordable is false during a reaction")
	var acts_before: int = fallen.acts_available
	var refused: bool = await battle._execute_command(fallen, "ABSORB", true, false, {}, battle.hud.opponents[0])
	check(not refused and fallen.acts_available == acts_before and battle.absorb_calls.is_empty(), "_execute_command(ABSORB, reacting) is refused and spends nothing")
	battle.queue_free(); await process_frame

	# ---- 6. Real absorption (no probe): immediate, 2 ACT, queue unchanged.
	battle = fresh(false)
	await wait_mode(battle, ["plan"])
	fallen = battle._fallen
	fallen.acts_available = 4
	foe_a = battle.hud.opponents[0]
	foe_b = battle.hud.opponents[1]
	foe_a.current_sp = 10  # D-051: drained by the presses, absorption guaranteed
	battle.submit_plan(fight_row(battle))
	battle.submit_target(1)
	planned_before = battle._planned.duplicate()
	targets_before = battle._planned_targets.duplicate()
	battle.submit_plan(absorb_row(battle))
	battle.submit_target(0)
	check(battle.hud.mode == "absorb" and battle._mash_active, "The real mash opens at once")
	check(fallen.acts_available == 2, "2 ACT spent as the mash opens")
	for _i in 12: battle.handle_confirm()
	var deadline := Time.get_ticks_msec() + 8000
	while battle.hud.mode not in ["continue", "plan"] and Time.get_ticks_msec() < deadline:
		if battle.hud.mode == "command" and not battle.in_reaction and battle.hud.command_options.size() > 0 and battle.hud.command_options[0].begins_with("+"):
			battle.submit_command(0)  # D-051 gain choice
		await process_frame
	check(foe_a.absorbed and not foe_a.is_alive(), "FOE A was absorbed")
	confirm(battle)
	check(await wait_mode(battle, ["plan"]), "Back to the plan")
	check(battle._planned == planned_before and battle._planned_targets == targets_before, "Real run: the queue is unchanged after absorbing")
	check(fallen.acts_available == 2 and foe_b.is_alive(), "Real run: 2 acts left; the queued FIGHT has not run")
	battle.queue_free(); await process_frame

	print("PLAYABLE_ABSORB_OK: %d checks; D-064 cost 2 ACT, immediate, queue unchanged, refused under 2 free acts, never a reaction" % checks)
	await process_frame
	await process_frame
	quit(0)

func _finalize() -> void:
	SANDBOX.end()
