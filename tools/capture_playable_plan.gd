extends SceneTree
## Captura o plano D-046 no cenário jogável: marcadores verdes e linha persistente.

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://captures")
	ProgressStore.save_path_override = "user://plan_capture_progress.json"
	ProgressStore.clear()
	call_deferred("_run")


func _save(path: String) -> void:
	var image: Image = root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(path))
	print("CAPTURED: ", path)


func _run() -> void:
	var battle: Control = load("res://scenes/battle/BattlePlayable.tscn").instantiate()
	root.add_child(battle)
	for _i in 30:
		await process_frame
	battle.submit_plan(0)
	for _i in 20:
		await process_frame
	_save("res://captures/playable_queue_plan.png")
	# O segundo comando completa o bloco e inicia a cadeia na mesma linha de ritmo.
	battle.submit_plan(0)
	battle.submit_target(0)
	for _i in 20:
		await process_frame
	_save("res://captures/playable_queue_chain.png")
	battle.queue_free()
	quit(0)
