extends SceneTree
const SANDBOX := preload("res://tests/progress_sandbox.gd")

class ControlledBattle extends "res://scripts/battle/playable_controller.gd":
	func _ai_roll(_a: BattleUnit, _b: BattleUnit) -> int: return BattleMath.RhythmResult.POINT
	func _defender_reaction(_a: BattleUnit, _b: BattleUnit) -> int: return BattleMath.RhythmResult.MISS

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
	for effect in fx.effects:
		check(not effect.clip_rect.intersects(battle.hud.LOG_RECT), "Effects must not cover the battle log")
		check(not effect.clip_rect.intersects(battle.hud.COMMAND_RECT), "Effects must not cover the command menu")
	var before: BattleUnit = battle.active_actor
	battle.handle_confirm()
	check(battle.active_actor == before, "Confirm must not skip an unfinished impact effect")
	for i in 120:
		await process_frame
		if not fx.is_busy(): break
	check(fx.played_cells > 0, "Real spritesheet cells must have been rendered")
	check(fx.applied_flashes > 0, "Original RGSS flash timings must have reached the renderer")
	check(fx.find_children("*", "AudioStreamPlayer", true, false).is_empty(), "Combat effects must never create audio players")
	check(not fx.is_busy(), "Transient effects must finish and release input")
	battle.handle_confirm()
	check(battle.active_actor == battle._ally, "Gameplay must continue after the effect")
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
	battle.submit_command(3); battle.submit_target(0)
	check(fx.count_kind("ABSORB") == 1, "Mashing must animate the selected absorption target")
	for i in 12: battle.handle_confirm()
	# Absorption mashing lasts 2 s of timers; headless frames run faster than
	# 60 fps, so wait on real time (5 s cap) instead of a fixed frame count.
	var mash_deadline := Time.get_ticks_msec() + 5000
	while battle._mash_active and Time.get_ticks_msec() < mash_deadline:
		await process_frame
	check(fx.count_kind("ABSORBED") == 1, "Successful absorption must visibly signal its reward")
	battle.queue_free(); await process_frame
	print("PLAYABLE_FX_OK: %d checks; source frames, flashes, silent combat, hit/death, heal, miss, dodge, enemy cue, input gating" % checks)
	quit(0)

func _finalize() -> void:
	SANDBOX.end()
