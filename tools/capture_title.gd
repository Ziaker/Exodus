extends SceneTree
## Windowed capture of the title screen. Run without --headless.
## Saves title_idle.png (cursor on New Game), title_continue.png (cursor on
## disabled Continue) and title_fade.png (mid-transition) to the given folder.

func _initialize() -> void:
	call_deferred("_run")

func _shot(dir: String, name: String) -> void:
	await process_frame
	await process_frame
	var path := dir.path_join(name)
	root.get_texture().get_image().save_png(path)
	print("CAPTURED: ", path)

func _run() -> void:
	var dir: String = OS.get_cmdline_user_args()[0]
	var title: Control = load("res://scenes/title/Title.tscn").instantiate()
	root.add_child(title)
	await _shot(dir, "title_idle.png")
	title.move_cursor(1)
	await _shot(dir, "title_continue.png")
	title.move_cursor(1)
	await _shot(dir, "title_shutdown.png")
	title.move_cursor(1)
	title.busy = true
	title._set_fade(0.5)
	await _shot(dir, "title_fade.png")
	quit(0)
