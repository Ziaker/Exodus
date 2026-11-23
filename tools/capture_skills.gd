extends Node
## Capture of the first-fight skills and the absorption counter in the real playable
## battle (layout D): FIGHT submenu with dimmed rows and the log explanation, Lunge on
## its two-mark rail, Energy Eat's extra EN line, an enemy Lunge defended on the
## two-mark defense rail, Heat wave + burn, Bleedbuff, and ABSORBED / gain / 4/4 /
## NEW SKILL. Enemy rolls miss and nobody counters, so every scene plays as scripted.

class CaptureBattle extends "res://scripts/battle/playable_controller.gd":
	var enemy_pick := 0
	func _absorb_roll() -> float: return 100.0
	func _enemy_counter_roll(_e: BattleUnit) -> bool: return false
	func _ai_roll(_a: BattleUnit, _b: BattleUnit) -> int: return BattleMath.RhythmResult.MISS
	func _zone_roll(_h: float) -> int: return BattleMath.RhythmResult.MISS
	func _enemy_skill_pick(n: int) -> int: return mini(enemy_pick, n - 1)
	func _burn_roll(_c: int) -> bool: return true
	func _skill_pick(_n: int) -> int: return 0

var battle: Control
const ALL: Array[StringName] = [&"lunge", &"heat_wave", &"energy_eat", &"bleedbuff"]


func _ready() -> void:
	ProgressStore.save_path_override = "user://capture_skills_progress.json"
	ProgressStore.clear()
	_run()


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func until_mode(mode: String, limit: float = 6.0) -> void:
	var left := limit
	while battle.hud.mode != mode and left > 0.0:
		await get_tree().process_frame
		left -= get_process_delta_time()


func new_battle(skills: Array[StringName], pick: int = 0) -> void:
	if battle != null:
		battle.queue_free()
		await get_tree().process_frame
	battle = CaptureBattle.new()
	battle.enemy_pick = pick
	battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(battle)
	battle._fallen.skills.assign(skills)
	await wait(0.6)


## Presses the live rail when the pointer reaches each fraction.
func press_marks(fractions: Array) -> void:
	for f in fractions:
		while battle.hud.mode == "timing" and battle.rhythm.progress() < float(f):
			await get_tree().process_frame
		battle.handle_confirm()


func _run() -> void:
	# 1. FIGHT submenu: EN 4 dims HEAT WAVE and ENERGY EAT; the log explains each row.
	await new_battle(ALL)
	battle._fallen.current_en = 4
	battle._refresh_all()
	battle.submit_plan(0)
	await wait(1.0)
	for i in range(1, 5):
		battle.hud.command_index = i
		await wait(1.0)
	battle.submit_skill(2)  # dimmed: refused (reject shake)
	await wait(0.8)
	battle.hud.command_index = 1
	await wait(0.4)
	battle.submit_skill(1)  # LUNGE
	await wait(0.6)
	battle.exec_plan()
	await until_mode("target")
	await wait(0.5)
	battle.hud.opponents[0].current_hp = 999
	battle.submit_target(0)
	await until_mode("timing")
	await press_marks([0.35, 0.65])
	await until_mode("continue")
	await wait(1.6)

	# 2. Energy Eat: extra EN line.
	await new_battle(ALL)
	battle._fallen.current_hp = 3
	battle._refresh_all()
	battle.submit_plan(0)
	await wait(0.6)
	battle.hud.command_index = 3
	await wait(0.6)
	battle.submit_skill(3)
	await wait(0.8)
	for i in 2:
		battle.adjust_en_extra(1)
		await wait(0.7)
	battle.confirm_en_extra()
	await wait(0.4)
	battle.exec_plan()
	await until_mode("continue")
	await wait(1.6)

	# 3. Enemy Lunge answered by DEFEND: defense rail with both marks.
	await new_battle([], 1)
	battle.hud.opponents[1].current_hp = 0
	battle._refresh_all()
	battle.submit_command(battle.hud.command_options.find("REACT"))
	await wait(0.3)
	battle.submit_command(battle.hud.command_options.find("REACT"))
	await until_mode("react")
	await wait(1.2)
	var hero: BattleUnit = battle.action_defender
	battle.select_reactor(battle.hud.players.find(hero))
	battle.answer_reaction(true)
	await wait(0.6)
	battle.submit_command(battle.hud.command_options.find("DEFEND"))
	await until_mode("timing")
	await press_marks([0.36, 0.64])
	await until_mode("continue")
	await wait(1.6)

	# 4. Heat wave by Fallen: both enemies hit and burning; then a burn tick.
	await new_battle(ALL)
	for foe in battle.hud.opponents: foe.current_hp = 999
	battle.submit_plan(0)
	await wait(0.6)
	battle.hud.command_index = 2
	await wait(0.8)
	battle.submit_skill(2)
	await wait(0.4)
	await until_mode("timing")
	await press_marks([0.5])
	await until_mode("continue")
	await wait(1.6)
	await battle._burn_tick()
	await wait(1.2)

	# 5. Bleedbuff: -4 HP, ATK UP.
	await new_battle(ALL)
	battle.submit_plan(0)
	await wait(0.6)
	battle.hud.command_index = 4
	await wait(0.8)
	battle.submit_skill(4)
	await until_mode("continue")
	await wait(1.8)

	# 6. 4th absorption of FOE A: ABSORBED / gain / 4/4 / NEW SKILL.
	ProgressStore.save_skill_progress({"genetic_foe_a": 3}, [])
	await new_battle([])
	battle.state.units[2].current_sp = 20
	battle._refresh_all()
	battle.submit_command(3)
	await until_mode("target")
	await wait(0.4)
	battle.submit_target(0)
	await until_mode("absorb")
	for i in 10:
		await wait(0.18)
		battle.handle_confirm()
	var left := 6.0
	while not battle.state.units[2].absorbed and left > 0.0:
		await get_tree().process_frame
		left -= get_process_delta_time()
	await wait(3.0)
	get_tree().quit()
