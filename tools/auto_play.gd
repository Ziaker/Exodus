extends Node

## Auto-driver for recording BattlePlayable.tscn with an external screen capture.

const START_DELAY: float = 12.0

var battle: Control
var last_frame: int = -100
var seen_mode: String = ""
var done: bool = false
var elapsed: float = 0.0

func _ready() -> void:
	ProgressStore.save_path_override = "user://autoplay_progress.json"
	ProgressStore.clear()

func _process(delta: float) -> void:
	if battle == null:
		elapsed += delta
		if elapsed < START_DELAY:
			return
		var packed: PackedScene = load("res://scenes/battle/BattlePlayable.tscn")
		battle = packed.instantiate()
		add_child(battle)
		return
	if done or battle.hud == null:
		return
	var hud: Control = battle.hud
	if hud.mode != seen_mode:
		seen_mode = hud.mode
		last_frame = Engine.get_process_frames() - 8
	if Engine.get_process_frames() - last_frame < 8:
		return
	match hud.mode:
		"turn": battle.handle_confirm()
		"command", "plan":
			var options: Array[String] = hud.command_options
			var index: int = 0
			if hud.command_options.has("DEFEND"):
				index = hud.command_options.size() - 1
			elif options.size() > 2 and battle.state.round_number % 3 == 0:
				index = 2
			battle.submit_command(clampi(index, 0, options.size() - 1))
		"target": battle.submit_target(battle.first_living_target())
		"timing":
			var ratio := 0.0
			if battle.rhythm.duration > 0.0:
				ratio = battle.rhythm._elapsed / battle.rhythm.duration
			if ratio >= 0.45:
				battle.handle_confirm()
			else:
				return
		"counter":
			# D-049: stop the white pointer near the middle of its rail.
			if battle.counter.white_position() >= 0.45:
				battle.handle_confirm()
			else:
				return
		"react": battle.answer_reaction(false)
		"absorb": battle._mash_count = 12
		"continue", "announce": battle.proceed()
		"result":
			done = true
			return
		_: return
	last_frame = Engine.get_process_frames()
