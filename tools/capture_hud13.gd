extends Node
## Screenshots of every state of the HUD option 13 (creator 2026-11-24) in the real
## playable battle, at the 816 x 624 window: empty plan, queued plan (EXEC/UNDO), skill
## submenu, target, attack rail, result, enemy announcement (REACT/DENY), reaction
## commands, defense rail in the hero window, the hero damage number over the window,
## and Yoch's plan with the PRAY submenu. Run windowed (not headless).

const OUT := "res://captures/hud13/"

class ShotBattle extends "res://scripts/battle/playable_controller.gd":
	func _enemy_counter_roll(_e: BattleUnit) -> bool: return false
	func _enemy_skill_pick(_n: int) -> int: return 0
	func _ai_roll(_a: BattleUnit, _b: BattleUnit) -> int: return BattleMath.RhythmResult.POINT

var battle: Control


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	ProgressStore.save_path_override = "user://capture_hud13.json"
	ProgressStore.clear()
	ProgressStore.save_skill_progress({}, [&"lunge"] as Array[StringName])
	ProgressStore.save_pp(3)
	battle = ShotBattle.new()
	battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(battle)
	await _settle()
	await _shot("01_plan_empty")
	battle.submit_plan(battle.hud.plan_options.find("ITEM"))
	await _settle()
	await _shot("02_plan_queued")
	battle.undo_plan()
	battle.submit_plan(battle.hud.plan_options.find("FIGHT"))
	await _settle()
	await _shot("03_skill_menu")
	battle.submit_skill(0)
	await _settle()
	battle.exec_plan()
	await _settle()
	await _shot("04_target")
	battle.submit_target(0)
	await _settle(0.3)
	await _shot("05_attack_rail")
	battle.rhythm._finish(BattleMath.RhythmResult.MISS)
	await _settle(1.2)
	await _shot("06_result")
	battle.proceed()
	await _settle(0.5)
	await _shot("07_announcement_react")
	battle.answer_reaction(true)
	await _settle()
	await _shot("08_reaction_commands")
	battle.submit_command(battle.hud.command_options.find("DEFEND"))
	await _settle(0.3)
	await _shot("09_defense_rail")
	battle.rhythm._finish(BattleMath.RhythmResult.MISS)
	var waited := 0.0
	while battle.fx.numbers.is_empty() and waited < 4.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
	await _settle(0.1)
	await _shot("10_hero_number")
	# Yoch's plan: a second battle where Yoch plays right after Fallen, who rests.
	battle.queue_free()
	await _settle()
	ProgressStore.save_pp(3)
	battle = ShotBattle.new()
	battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(battle)
	await _settle()
	var order: Array[BattleUnit] = battle.state.turn_order
	order.erase(battle._ally)
	order.insert(order.find(battle._fallen) + 1, battle._ally)
	battle.submit_plan(battle.hud.plan_options.find("REST"))
	await _settle(0.3)
	if battle.hud.mode == "continue": battle.proceed()
	# Let the REST effect (screen tint) finish before the shot.
	await _settle(2.0)
	await _shot("11_yoch_plan")
	battle.submit_plan(battle.hud.plan_options.find("PRAY"))
	await _settle()
	await _shot("12_pray_menu")
	print("HUD13_SHOTS_DONE")
	get_tree().quit()


func _settle(seconds := 0.15) -> void:
	await get_tree().create_timer(seconds).timeout
	await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
	print("SHOT ", name, " mode=", battle.hud.mode)
