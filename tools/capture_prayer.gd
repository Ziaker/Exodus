extends SceneTree
## D-048 captures of Yoch's prayer in the real playable battle (not headless):
##   godot --path . -s tools/capture_prayer.gd -- --out=<dir>
## Deterministic: enemies never counter ATTACK, the AI timing is scripted per shot.

class CaptureBattle extends "res://scripts/battle/playable_controller.gd":
	func _enemy_skill_pick(_n: int) -> int: return 0
	var enemy_timing := BattleMath.RhythmResult.MISS
	var pray_reaction := false
	var raam_counter := false
	func _ai_roll(_a: BattleUnit, _b: BattleUnit) -> int: return enemy_timing
	func _defender_reaction(_a: BattleUnit, _b: BattleUnit) -> int: return BattleMath.RhythmResult.MISS
	func _enemy_counter_roll(_e: BattleUnit) -> bool: return false
	func _enemy_pray_reaction_roll(_e: BattleUnit) -> bool: return pray_reaction
	func _enemy_raam_counter_roll(_e: BattleUnit) -> bool: return raam_counter
	func _counter_ai_time(red_seconds: float) -> float: return red_seconds * 0.8

var out := ""
## --hold=<k>: multiplies every wait (video recording with --write-movie); --nosave skips PNGs.
var hold := 1.0
var save := true
var battle: Control

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		elif arg.begins_with("--hold="):
			hold = arg.trim_prefix("--hold=").to_float()
		elif arg == "--nosave":
			save = false
	if not out.is_empty():
		DirAccess.make_dir_recursive_absolute(out)
	ProgressStore.save_path_override = "user://captureprayer_progress.json"
	call_deferred("_run")

## live = a running rail: never stretched by --hold, or it would time out before the scripted press.
func shot(name: String, settle := 0.5, live := false) -> void:
	var waited := 0.0
	while waited < settle * (1.0 if live else hold):
		await process_frame
		waited += root.get_process_delta_time()
	if not save:
		print("STEP ", name)
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("SHOT ", name, " mode=", battle.hud.mode)

func fresh(pp: int) -> void:
	# The new battle is added before the old one is freed: no empty (grey) frame between them.
	var old := battle
	ProgressStore.clear()
	ProgressStore.save_pp(pp)
	battle = CaptureBattle.new()
	# Same layout as BattlePlayable.tscn (full rect): a zero-size battle would cull the HUD
	# while the screen shakes.
	battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(battle)
	await process_frame
	if old != null:
		old.queue_free()
		await process_frame

func to_yoch(acts: int) -> void:
	battle.hud.players[1].acts_available = acts
	battle.submit_plan(battle.hud.plan_options.find("REST"))
	await shot("00_fallen_rest_result", 0.3)
	battle.proceed()

func row(prefix: String) -> int:
	for i in battle.hud.command_options.size():
		if battle.hud.command_options[i].begins_with(prefix): return i
	return -1

func _run() -> void:
	await fresh(3)
	battle.hud.players[0].current_hp = 4
	await shot("01_start_yoch_pp", 0.8)
	await to_yoch(3)
	battle.hud.plan_index = battle.hud.plan_options.find("PRAY")
	await shot("02_yoch_plan_pray_row")
	battle.submit_plan(battle.hud.plan_options.find("PRAY"))
	await shot("03_pray_submenu")
	battle.hud.command_index = row("Ra'am")
	await shot("04_pray_submenu_raam_info")
	battle.prayer.submit(row("Refuah"))
	await shot("05_refuah_target_ally")
	battle.submit_target(0)
	await shot("06_plan_refuah_queued_pp_paid")
	battle.submit_plan(battle.hud.plan_options.find("PRAY"))
	battle.prayer.submit(row("Refuah"))
	battle.submit_target(0)
	await shot("07_refuah_plus1_pp")
	battle.submit_plan(battle.hud.plan_options.find("PRAY"))
	battle.prayer.submit(row("PRAY"))
	battle.exec_plan()
	await shot("08_refuah_resolved_log_ink", 0.6)
	battle.proceed()
	await shot("09_pray_resolved", 0.6)

	# PRAY attacked by both enemies: interruption.
	await fresh(2)
	battle.pray_reaction = true
	battle.enemy_timing = BattleMath.RhythmResult.POINT
	battle.hud.players[1].stats.max_hp = 999
	battle.hud.players[1].current_hp = 999
	await to_yoch(2)
	battle.submit_plan(battle.hud.plan_options.find("PRAY"))
	battle.prayer.submit(row("PRAY"))
	battle.exec_plan()
	await shot("10_pray_attacked_first", 0.4)
	battle.proceed()
	await shot("11_pray_attacked_second", 0.4)
	battle.proceed()
	await shot("12_pray_interrupted", 0.4)
	battle.proceed()
	await shot("13_queue_lost", 0.4)

	# Ra'am counter-attacked on the D-049 rails.
	await fresh(3)
	battle.raam_counter = true
	await to_yoch(1)
	battle.submit_plan(battle.hud.plan_options.find("PRAY"))
	battle.prayer.submit(row("Ra'am"))
	await shot("14_raam_target_enemy")
	battle.submit_target(0)
	await shot("15_raam_counter_rails", 0.35, true)
	battle.counter.finish(BattleMath.RhythmResult.MISS, BattleMath.RhythmResult.POINT)
	await shot("16_raam_interrupted_pp_back", 0.4)

	# Ra'am on the attack rail.
	await fresh(3)
	await to_yoch(1)
	battle.submit_plan(battle.hud.plan_options.find("PRAY"))
	battle.prayer.submit(row("Ra'am"))
	battle.submit_target(0)
	await shot("17_raam_attack_rail", 0.48, true)
	battle.handle_confirm()
	await shot("18_raam_result", 0.5)

	# Haganah on Yoch.
	await fresh(2)
	await to_yoch(1)
	battle.submit_plan(battle.hud.plan_options.find("PRAY"))
	battle.prayer.submit(row("Haganah"))
	battle.submit_target(1)
	await shot("19_haganah_cast", 0.4)
	battle.queue_free()
	await process_frame
	ProgressStore.clear()
	quit(0)
