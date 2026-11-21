extends SceneTree

## Windowed capture of the battle screen at its initial state (no attack).

const OUTPUT := "res://captures/battle_initial.png"

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/battle/Battle.tscn")
	var battle: Control = packed.instantiate()
	root.add_child(battle)
	for _i in range(10):
		await process_frame
	var image: Image = root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUTPUT))
	print("CAPTURED: ", ProjectSettings.globalize_path(OUTPUT))
	quit(0)
