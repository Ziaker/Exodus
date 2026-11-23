extends SceneTree

const LOG := "user://debug_playable.log"

var file: FileAccess

func _log(text: String) -> void:
	if file == null:
		return
	file.store_line(text)
	file.flush()

func _initialize() -> void:
	file = FileAccess.open(LOG, FileAccess.WRITE)
	_log("START")
	var packed: PackedScene = load("res://scenes/battle/BattlePlayable.tscn")
	_log("SCENE LOADED")
	var battle: Control = packed.instantiate()
	_log("INSTANCED")
	root.add_child(battle)
	_log("ADDED")
	for _i in range(10):
		await process_frame
		_log("FRAME " + str(_i))
	_log("HUD=" + str(battle.hud != null))
	_log("MODE=" + (battle.hud.mode if battle.hud != null else "-"))
	quit(0)
