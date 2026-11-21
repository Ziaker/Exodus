extends SceneTree

## Windowed capture helper: opens the battle scene, triggers ATTACK and saves
## a frame while the rhythm bar is active. Run without --headless.

const OUTPUT := "res://captures/rhythm_active.png"

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/battle/Battle.tscn")
	var battle: Control = packed.instantiate()
	root.add_child(battle)
	for _i in range(10):
		await process_frame
	battle._chosen = 0
	battle.command_chosen.emit()
	for _i in range(10):
		await process_frame
	var image: Image = root.get_texture().get_image()
	var dir := DirAccess.open("res://captures")
	if dir == null:
		DirAccess.make_dir_recursive_absolute("res://captures")
	image.save_png(ProjectSettings.globalize_path(OUTPUT))
	print("CAPTURED: ", ProjectSettings.globalize_path(OUTPUT))
	quit(0)
