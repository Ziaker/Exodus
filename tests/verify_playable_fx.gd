extends SceneTree
const SANDBOX := preload("res://tests/progress_sandbox.gd")

class ControlledBattle extends "res://scripts/battle/playable_controller.gd":
	## ATTACK-flow checks: the enemy AI never draws a skill here (skills: verify_playable_skills).
	func _enemy_skill_pick(_n: int) -> int: return 0
	func _ai_roll(_a: BattleUnit, _b: BattleUnit) -> int: return BattleMath.RhythmResult.POINT
	func _defender_reaction(_a: BattleUnit, _b: BattleUnit) -> int: return BattleMath.RhythmResult.MISS
	# D-051 rolls always miss, so the absorption only completes by draining the SP in the
	# D-063 result: the number of counted presses (and of D-052 letters) is deterministic.
	func _absorb_roll() -> float: return 100.0
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
	return battle

func _run() -> void:
	var battle := fresh()
	if not battle.has_node("BattleEffects"):
		push_error("No real effects renderer exists in the playable battle")
		quit(1)
		return
	var fx: Control = battle.get_node("BattleEffects")
	check(fx.library.animation_count == 225, "Animation metadata must come from the inspected database")
	check(fx.library.profiles.claw.frames.size() == 10, "Claw animation must preserve source frame count")
	check(fx.library.profiles.bite.frames.size() == 12, "Bite animation must preserve source frame count")
	battle.submit_command(0); battle.submit_target(0)
	battle.rhythm._finish(BattleMath.RhythmResult.POINT)
	check(fx.count_kind("HIT") + fx.count_kind("CRITICAL") == 1, "Landed attack must start a real hit animation")
	check(fx.has_target_sprite(battle.state.units[2]), "Defeated enemy must remain visible during its hit/fade animation")
	check(fx.numbers.is_empty(), "Enemy damage number must wait for the hit animation to end")
	# Creator 2026-11-22: lethal numbers are #ff3b3b; every number fades over its second half.
	check(fx.number_color({"kind": "HIT", "amount": 9, "dying": true}) == Color("ff3b3b"), "Lethal hit number must be #ff3b3b")
	check(fx.number_color({"kind": "HIT", "amount": 9, "dying": false}) == fx.NUMBER_INK, "Non-lethal hit number keeps its normal ink")
	check(fx.number_color({"kind": "MISS", "amount": 0, "dying": true}) == fx.NUMBER_INK, "MISS is never painted as lethal")
	check(fx.number_alpha(0.0, 0.8) == 1.0 and fx.number_alpha(0.4, 0.8) == 1.0, "Number stays opaque for the first half of its life")
	check(is_equal_approx(fx.number_alpha(0.6, 0.8), 0.5) and fx.number_alpha(0.8, 0.8) == 0.0, "Number loses opacity linearly over its second half")
	var killed: Array = fx.effects.filter(func(e: Dictionary) -> bool: return e.kind in ["HIT", "CRITICAL"])
	check(killed.size() == 1 and fx.number_color(killed[0]) == fx.LETHAL_INK, "The live killing blow on the defeated enemy is painted red")
	for effect in fx.effects:
		check(not effect.clip_rect.intersects(battle.hud.BATTLE_LOG_RECT), "Effects must not cover the battle log")
		check(not effect.clip_rect.intersects(battle.hud.COMMAND_RECT), "Effects must not cover the command menu")
	var before: BattleUnit = battle.active_actor
	battle.handle_confirm()
	check(battle.active_actor == before, "Confirm must not skip an unfinished impact effect")
	# Real time, not a frame count: the number now shows after the hit animation.
	var waited := 0.0
	while fx.is_busy() and waited < 5.0:
		await process_frame
		waited += root.get_process_delta_time()
	check(fx.played_cells > 0, "Real spritesheet cells must have been rendered")
	check(fx.applied_flashes > 0, "Original RGSS flash timings must have reached the renderer")
	check(fx.find_children("*", "AudioStreamPlayer", true, false).is_empty(), "Combat effects must never create audio players")
	check(not fx.is_busy(), "Transient effects must finish and release input")
	# D-057: each Z first pages event lines still waiting beyond the two-row log.
	for _page in 5:
		if battle.hud.mode != "continue": break
		battle.handle_confirm()
	# D-057 (creator 2026-11-25): the act left (WEAK +1) is planned in the same turn.
	check(battle.active_actor == battle._fallen and battle.hud.mode == "plan", "After the effect Fallen plans the act left in the same turn")
	battle.queue_free(); await process_frame
	battle = fresh(); fx = battle.get_node("BattleEffects")
	battle._fallen.current_hp = 1; battle.submit_command(1)
	check(fx.count_kind("HEAL") == 1, "Healing must trigger original flash/audio effects")
	battle.queue_free(); await process_frame
	battle = fresh(); fx = battle.get_node("BattleEffects")
	battle.submit_command(0); battle.submit_target(0)
	battle.rhythm._finish(BattleMath.RhythmResult.MISS)
	check(fx.count_kind("MISS") == 1 and fx.count_kind("HIT") == 0, "A miss must not fake a landed impact")
	battle.queue_free(); await process_frame
	battle = fresh(); fx = battle.get_node("BattleEffects")
	battle.submit_command(battle.hud.command_options.find("REACT"))
	battle.submit_command(battle.hud.command_options.find("REACT"))
	check(fx.count_kind("WHITEN") > 0, "Enemy announcement must whiten the attacking enemy")
	check(fx.count_kind("ANNOUNCE") == 0 and fx.count_kind("ATTACK") == 0, "Creator decision: no TARGET01 SEARCH cue on announcements or attacks")
	battle.select_reactor(0); battle.answer_reaction(true)
	battle.submit_command(battle.hud.command_options.find("DEFEND"))
	battle.rhythm._finish(BattleMath.RhythmResult.POINT)
	check(fx.count_kind("DODGE") == 1 and fx.count_kind("HIT") == 0, "Perfect defense must display dodge without a damage flash")
	battle.queue_free(); await process_frame
	battle = fresh(); fx = battle.get_node("BattleEffects")
	battle.submit_command(battle.hud.command_options.find("REACT"))
	battle.submit_command(battle.hud.command_options.find("REACT"))
	battle.select_reactor(0); battle.answer_reaction(true)
	battle.submit_command(battle.hud.command_options.find("DEFEND"))
	battle.rhythm._finish(BattleMath.RhythmResult.BEAM)
	check(fx.count_kind("BLOCK") == 1 and fx.count_kind("HIT") == 0, "Blocked contact must have its own outcome effect")
	battle.queue_free(); await process_frame
	battle = fresh(); fx = battle.get_node("BattleEffects")
	battle.hud.opponents[0].current_sp = 10  # D-051: drained by the presses, absorption guaranteed
	battle.submit_command(3); battle.submit_target(0)
	# D-052: the old SMT absorb animation is replaced by AbsorbVFX.
	check(fx.count_kind("ABSORB") == 0, "D-052: the old SMT absorb animation must not play")
	var vfx: Node2D = battle.get_node("AbsorbVFX")
	var foe_a: BattleUnit = battle.hud.opponents[0]
	for i in 12: battle.handle_confirm()
	# Absorption mashing lasts 2 s of timers; headless frames run faster than
	# 60 fps, so wait on real time (5 s cap) instead of a fixed frame count.
	var mash_deadline := Time.get_ticks_msec() + 5000
	while battle._mash_active and Time.get_ticks_msec() < mash_deadline:
		await process_frame
	# D-063: presses only count (up to 10, the 12 sent are clamped) and the result drains
	# the 10 SP once; every counted press still sends its D-052 letters.
	check(vfx.letters_sent == 10 * vfx.MASH_LETTERS, "D-052: every counted mash press sends MASH_LETTERS green letters (got %d)" % vfx.letters_sent)
	var break_deadline := Time.get_ticks_msec() + 6000
	var saw_break := false
	var saw_shake := false
	while not foe_a.absorbed and Time.get_ticks_msec() < break_deadline:
		if not vfx.pieces.is_empty():
			saw_break = true
			check(battle.hud.broken_units.has(foe_a), "D-052: the broken opponent must leave the HUD at the impact")
		if vfx._shaking:
			check(root.canvas_transform.origin == vfx.shake_offset, "D-052: the screen shake moves the viewport canvas")
			check(battle.position == Vector2.ZERO, "D-052: the shake must not move the battle node (HUD culling)")
			saw_shake = saw_shake or vfx.shake_offset != Vector2.ZERO
		await process_frame
	check(saw_shake, "D-052: the impact must shake the screen")
	check(saw_break, "D-052: a successful absorption must break the opponent into letters")
	check(foe_a.absorbed, "Absorption must complete after the break")
	check(fx.count_kind("ABSORBED") == 1, "Successful absorption must visibly signal its reward")
	while vfx._shaking and Time.get_ticks_msec() < break_deadline:
		await process_frame
	check(root.canvas_transform == Transform2D.IDENTITY, "D-052: the screen shake must end at rest")
	battle.queue_free(); await process_frame
	print("PLAYABLE_FX_OK: %d checks; source frames, flashes, silent combat, hit/death, heal, miss, dodge, enemy cue, input gating" % checks)
	quit(0)

func _finalize() -> void:
	SANDBOX.end()
