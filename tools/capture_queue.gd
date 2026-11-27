extends SceneTree

## Windowed capture helper for the D-046 command queue and chained rhythm bar.

const PLAN_OUTPUT := "res://captures/queue_plan.png"
const CHAIN_OUTPUT := "res://captures/queue_chain.png"

func _new_battle() -> Control:
	var packed: PackedScene = load("res://scenes/battle/Battle.tscn")
	var battle: Control = packed.instantiate()
	root.add_child(battle)
	for _i in range(10):
		await process_frame
	return battle


func _save(path: String) -> void:
	var image: Image = root.get_texture().get_image()
	var global := ProjectSettings.globalize_path(path)
	image.save_png(global)
	print("CAPTURED: ", global)


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://captures")
	# Avoid touching the player's real progress; keep this capture isolated.
	ProgressStore.save_path_override = "user://capture_progress.json"
	ProgressStore.clear()

	# Frame 1: two planned commands, green ACT markers and PLAN label.
	var battle := await _new_battle()
	for _i in range(30):
		if battle._plan_active:
			break
		await process_frame
	# One committed command: the plan is still open and the menu stays visible.
	battle._chosen = 0
	battle.command_chosen.emit()
	await process_frame
	_save(PLAN_OUTPUT)
	battle.free()

	# Frame 2: two chained attacks sharing one persistent rhythm line.
	var chain := await _new_battle()
	for enemy in [chain.state.units[2], chain.state.units[3]]:
		enemy.current_hp = 999
		enemy.stats.max_hp = 999
	for _i in range(30):
		if chain._plan_active:
			break
		await process_frame
	chain._chosen = 0
	chain.command_chosen.emit()
	await process_frame
	chain._chosen = 0
	chain.command_chosen.emit()
	await process_frame
	# Finalize the partial plan so the two attacks actually start resolving.
	chain._chosen = chain._plan_options.size() - 2  # EXEC
	chain.command_chosen.emit()
	for _i in range(30):
		if chain.rhythm._chain_mode:
			break
		await process_frame
	_save(CHAIN_OUTPUT)
	quit(0)
