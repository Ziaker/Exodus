extends SceneTree
## Creator 2026-11-26: capturas do menu de escolhas vertical acima do log.

const OUT := "res://docs/plans/menu-above-log/"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	ProgressStore.save_path_override = "user://menu_capture_progress.json"
	ProgressStore.clear()
	call_deferred("_run")


func _save(name: String) -> void:
	var image: Image = root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("CAPTURED: ", name)


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _run() -> void:
	var battle: Control = load("res://scenes/battle/BattlePlayable.tscn").instantiate()
	root.add_child(battle)
	await _frames(40)
	_save("1_plan")
	battle.submit_plan(0)
	await _frames(20)
	_save("2_plan_com_fila")
	battle.queue_free()
	quit(0)
