extends SceneTree
## Windowed capture of the playable battle's compact rhythm bar at the minimum
## and maximum POINT widths (D-034). Usage: -s tools/capture_compact_rhythm.gd -- <dir>

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var dir: String = OS.get_cmdline_user_args()[0]
	var battle: Control = load("res://scenes/battle/BattlePlayable.tscn").instantiate()
	root.add_child(battle)
	for i in 5: await process_frame
	for pair in [["min", BattleMath.POINT_MIN_HALF_WIDTH], ["max", BattleMath.POINT_MAX_HALF_WIDTH]]:
		battle.rhythm.configure(pair[1])
		battle.rhythm.start(5.0)
		battle.hud.mode = "timing"
		for i in 20: await process_frame
		var path: String = dir.path_join("compact_point_%s.png" % pair[0])
		root.get_texture().get_image().save_png(path)
		print("CAPTURED: ", path)
	quit(0)
