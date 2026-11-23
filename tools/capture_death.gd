extends Node
## Capture of Fallen's death (creator 2026-11-23) in the real playable battle (layout D):
## Fallen starts at 3 HP, the player's inputs miss and nobody defends, an enemy hit drops
## him, the death cutscene plays over the battle and the game goes to the title screen.
## Run with --write-movie; quits 2 s after the title appears.

class CaptureBattle extends "res://scripts/battle/playable_controller.gd":
	func _enemy_counter_roll(_e: BattleUnit) -> bool: return false
	func _enemy_skill_pick(_n: int) -> int: return 0
	func _ai_roll(_a: BattleUnit, _b: BattleUnit) -> int: return BattleMath.RhythmResult.POINT
	func _leave_after_death() -> void:
		var tree := get_tree()
		tree.change_scene_to_file(DEATH_SCENE)
		tree.create_timer(2.0).timeout.connect(tree.quit)

var battle: Control


func _ready() -> void:
	ProgressStore.save_path_override = "user://capture_death_progress.json"
	ProgressStore.clear()
	ProgressStore.save_gains({"max_hp": 3, "max_en": 3, "atk": 2, "defense": 4, "agi": 2})
	for i in 3: ProgressStore.add_death()
	battle = CaptureBattle.new()
	add_child(battle)
	battle._fallen.current_hp = 3
	battle._refresh_all()
	_drive()


func _drive() -> void:
	while is_inside_tree() and battle.hud.mode != "death":
		match battle.hud.mode:
			"command", "plan": battle.submit_command(0)
			"target": battle.submit_target(battle.first_living_target())
			"timing": battle.rhythm._finish(BattleMath.RhythmResult.MISS)
			"counter": battle.counter.finish(BattleMath.RhythmResult.MISS, BattleMath.RhythmResult.POINT)
			"react": battle.answer_reaction(false)
			"continue", "announce": battle.proceed()
		await get_tree().create_timer(0.35).timeout
	print("DEATH_CAPTURE: gains now ", ProgressStore.load_gains())
