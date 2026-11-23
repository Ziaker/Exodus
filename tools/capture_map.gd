extends SceneTree
## Registro visual do protótipo de mapa placeholder (sem assets de terceiros).

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://captures")
	call_deferred("_run")


func _save(path: String) -> void:
	var image: Image = root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(path))
	print("CAPTURED: ", path)


func _run() -> void:
	var map: Node2D = load("res://scenes/map/Map.tscn").instantiate()
	root.add_child(map)
	for _i in 20:
		await process_frame
	_save("res://captures/map_overview.png")
	map.player.place(Vector2i(11, 8))
	map.player.set_facing(MapPlayer.Facing.UP)
	map.interact()
	for _i in 60:
		await process_frame
	_save("res://captures/map_dialogue.png")
	for _i in 8:
		if not map.dialogue.is_open:
			break
		map.dialogue.advance()
	map.player.place(Vector2i(31, 13))
	map.player.set_facing(MapPlayer.Facing.RIGHT)
	map.interact()
	for _i in 20:
		await process_frame
	_save("res://captures/map_ruins.png")
	map.queue_free()
	quit(0)
