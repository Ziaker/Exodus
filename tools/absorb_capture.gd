extends Node
## Dev capture for D-051: Fallen absorbs an enemy with two multiples of 8 (MAK 16,
## MEF 8); the mash drains its SP and the gain menu appears.

var battle: Control
var wait := 1.0
var step := 0


func _ready() -> void:
	ProgressStore.save_path_override = "user://absorbcap_progress.json"
	ProgressStore.clear()


func _process(delta: float) -> void:
	wait -= delta
	if wait > 0.0: return
	wait = 0.12
	if battle == null:
		battle = load("res://scenes/battle/BattlePlayable.tscn").instantiate()
		add_child(battle)
		wait = 1.0
		return
	var foe: BattleUnit = battle.hud.opponents[0]
	match battle.hud.mode:
		"plan":
			foe.stats.mak = 16
			foe.stats.mef = 8
			foe.current_sp = 12
			battle.submit_command(battle.hud.command_options.find("ABSORB"))
			wait = 0.8
		"target":
			battle.submit_target(0)
		"absorb":
			battle.handle_confirm()
		"command":
			step += 1
			if step == 12:
				battle.hud.command_index = 2
			if step == 20:
				battle.submit_command(2)
				wait = 2.0
		"continue":
			get_tree().quit()
