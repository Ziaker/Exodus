extends SceneTree

const FRAME_DIR := "res://captures/playable_frames"
const LOG := "user://capture_playable.log"

var file: FileAccess
var battle: Control

func _log(text: String) -> void:
	file.store_line(text)
	file.flush()

func _initialize() -> void:
	file = FileAccess.open(LOG, FileAccess.WRITE)
	DirAccess.make_dir_recursive_absolute(FRAME_DIR)
	var dir := DirAccess.open(FRAME_DIR)
	if dir != null:
		for f in dir.get_files():
			dir.remove(f)
	_log("START")
	var packed: PackedScene = load("res://scenes/battle/BattlePlayable.tscn")
	battle = packed.instantiate()
	root.add_child(battle)
	_log("INSTANCED")
	for _i in range(8):
		await process_frame
	for i in range(40):
		var image: Image = root.get_texture().get_image()
		var path := "%s/frame_%03d.png" % [FRAME_DIR, i]
		image.save_png(ProjectSettings.globalize_path(path))
		_log("SAVED " + str(i) + " mode=" + battle.hud.mode)
		await process_frame
	_log("DONE")
	quit(0)
