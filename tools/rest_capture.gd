extends Node
## Dev capture driver: executa REST no próprio turno e mantém a cena aberta
## para inspecionar a mensagem e o número "+2 EN".

const START_DELAY: float = 1.0

var battle: Control
var elapsed: float = 0.0
var done: bool = false


func _ready() -> void:
	Engine.time_scale = 0.5
	ProgressStore.save_path_override = "user://restcap_progress.json"
	ProgressStore.clear()


func _process(delta: float) -> void:
	if battle == null:
		elapsed += delta
		if elapsed < START_DELAY:
			return
		battle = load("res://scenes/battle/BattlePlayable.tscn").instantiate()
		add_child(battle)
		return
	if done or battle.hud == null:
		return
	if battle.hud.mode not in ["command", "plan"]:
		return
	var index: int = battle.hud.command_options.find("REST")
	if index < 0:
		return
	done = true
	battle.submit_command(index)
