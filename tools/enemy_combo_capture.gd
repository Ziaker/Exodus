extends Node
## Dev capture driver: reserva os atos dos dois jogadores e desacelera o fluxo
## para que as duas reações e os dois números de dano do combo inimigo apareçam.

const START_DELAY: float = 1.0
const FRAME_GAP: int = 75

var battle: Control
var elapsed: float = 0.0
var last_action: int = -1000
var reserved: int = 0


func _ready() -> void:
	# Capture-only slowdown: the real effect is brief, hold it long enough to see.
	Engine.time_scale = 0.35
	ProgressStore.save_path_override = "user://combocap_progress.json"
	ProgressStore.clear()


func _process(_delta: float) -> void:
	if battle == null:
		elapsed += _delta
		if elapsed < START_DELAY:
			return
		battle = load("res://scenes/battle/BattlePlayable.tscn").instantiate()
		add_child(battle)
		return
	if battle.hud == null or battle.hud.mode == "result":
		return
	var frame := Engine.get_process_frames()
	if frame - last_action < FRAME_GAP:
		return
	var mode: String = battle.hud.mode
	if mode in ["command", "plan"] and reserved < 2:
		var index: int = battle.hud.command_options.find("REACT")
		if index >= 0:
			battle.submit_command(index)
			reserved += 1
			last_action = frame
		return
	if mode == "react":
		battle.answer_reaction(false)
		last_action = frame
		return
	# Same gate as the player's Z: never skip a hit animation or its number.
	if mode in ["continue", "announce"] and not battle.fx.is_busy():
		battle.proceed()
		last_action = frame
