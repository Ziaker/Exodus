extends Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ProgressStore.save_path_override = "user://autohit_progress.json"
	ProgressStore.clear()
	var packed: PackedScene = load("res://scenes/battle/BattlePlayable.tscn")
	var battle: Control = packed.instantiate()
	add_child(battle)
	await get_tree().create_timer(2.0).timeout
	var log := FileAccess.open("user://autohit.log", FileAccess.WRITE)
	log.store_line("fx=%s units=%d" % [str(battle.fx != null), battle.state.units.size()])
	log.flush()
	battle.fx.play("HIT", battle.state.units[0], 123)
	battle.fx.screen_flashes.clear()
	for _i in 180:
		if not battle.fx.effects.is_empty():
			battle.fx.effects.back()["age"] = 0.0
			battle.fx.screen_flashes.clear()
		await get_tree().process_frame
