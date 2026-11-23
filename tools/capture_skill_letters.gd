extends Node
## Video capture of the Hebrew-letter skill effects (creator 2026-11-23) in the real playable
## battle: Fallen uses Lunge, Heat wave (+ a burn tick), Bleedbuff and Energy Eat; then the
## enemies use Heat wave, Lunge, Energy Eat and Bleedbuff on the heroes. Every hit lands
## (POINT) and nobody defends or counters, so each effect plays. Record with:
##   godot --path . --write-movie out/f.png --fixed-fps 30 res://tools/CaptureSkillLetters.tscn

class CaptureBattle extends "res://scripts/battle/playable_controller.gd":
	var enemy_pick := 0
	func _enemy_counter_roll(_e: BattleUnit) -> bool: return false
	func _ai_roll(_a: BattleUnit, _b: BattleUnit) -> int: return BattleMath.RhythmResult.POINT
	func _zone_roll(_h: float) -> int: return BattleMath.RhythmResult.MISS
	func _enemy_skill_pick(n: int) -> int: return mini(enemy_pick, n - 1)
	func _enemy_en_extra(_m: int) -> int: return 0
	func _burn_roll(_c: int) -> bool: return true

var battle: Control
const ALL: Array[StringName] = [&"lunge", &"heat_wave", &"energy_eat", &"bleedbuff"]


func _ready() -> void:
	ProgressStore.save_path_override = "user://capture_skill_letters_progress.json"
	ProgressStore.clear()
	_run()


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func until_mode(modes: Array, limit: float = 8.0) -> void:
	var left := limit
	while not modes.has(battle.hud.mode) and left > 0.0:
		await get_tree().process_frame
		left -= get_process_delta_time()


func new_battle(pick: int = 0) -> void:
	var old := battle
	battle = CaptureBattle.new()
	battle.enemy_pick = pick
	battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(battle)
	if old != null:
		await get_tree().process_frame
		old.queue_free()
	battle._fallen.skills.assign(ALL)
	for unit in battle.state.units:
		unit.stats.max_hp = 999
		unit.current_hp = 999
		unit.current_en = 30
		unit.stats.max_en = 30
	battle._refresh_all()
	await wait(0.6)


func press_marks(fractions: Array) -> void:
	for f in fractions:
		while battle.hud.mode == "timing" and battle.rhythm.progress() < float(f):
			await get_tree().process_frame
		battle.handle_confirm()


## Fallen plans one skill (FIGHT submenu row) and runs it.
func fallen_skill(row: int, marks: Array, target := -1) -> void:
	battle.submit_plan(0)
	await wait(0.5)
	battle.submit_skill(row)
	if battle.hud.mode == "en_extra":
		battle.confirm_en_extra()
	await wait(0.3)
	battle.exec_plan()
	if target >= 0:
		await until_mode(["target"])
		battle.submit_target(target)
	if not marks.is_empty():
		await until_mode(["timing"])
		await press_marks(marks)
	await until_mode(["continue"])
	await wait(1.8)


## Both heroes rest; the enemies then play their two-act blocks with the scripted pick.
func enemy_turns(seconds: float) -> void:
	battle.submit_plan(battle.hud.plan_options.find("REST"))
	await until_mode(["continue"])
	battle.proceed()
	await until_mode(["plan"])
	battle.submit_plan(battle.hud.plan_options.find("REST"))
	await until_mode(["continue"])
	battle.proceed()
	var left := seconds
	while left > 0.0:
		if battle.hud.mode in ["announce", "continue"]:
			await wait(1.4)
			left -= 1.4
			battle.proceed()
		else:
			await get_tree().process_frame
			left -= get_process_delta_time()


func _run() -> void:
	# Fallen: Lunge (two hits), Heat wave (+ burn tick), Bleedbuff, Energy Eat.
	await new_battle()
	await fallen_skill(1, [0.5, 0.5], 0)
	await new_battle()
	await fallen_skill(2, [0.5])
	await battle._burn_tick()
	await wait(1.4)
	await new_battle()
	await fallen_skill(4, [])
	await new_battle()
	await fallen_skill(3, [])
	# Enemies: pick 1 = their first skill (FOE B Heat wave, FOE A Lunge);
	# pick 2 = their second (FOE B Energy Eat, FOE A Bleedbuff).
	await new_battle(1)
	await enemy_turns(9.0)
	await new_battle(2)
	await enemy_turns(7.0)
	get_tree().quit()
