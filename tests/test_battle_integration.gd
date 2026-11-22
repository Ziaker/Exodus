extends GutTest

## Drives the real battle scene far enough to prove the turn/command/rhythm
## chain runs without runtime errors. Input is simulated through signals.

func test_attack_resolves_through_rhythm() -> void:
	var packed: PackedScene = load("res://scenes/battle/Battle.tscn")
	var battle: Control = packed.instantiate()
	add_child_autofree(battle)

	var command_box: HBoxContainer = battle.command_box
	var bar: RhythmBar = battle.rhythm

	for _i in range(90):
		if command_box.get_child_count() > 0:
			break
		await get_tree().process_frame
	assert_gt(command_box.get_child_count(), 0, "command menu should appear")

	# D-046: plan ATTACK, then confirm EXEC.
	battle._chosen = 0
	battle.command_chosen.emit()
	await get_tree().process_frame
	battle._chosen = battle._plan_options.size() - 2
	battle.command_chosen.emit()

	for _i in range(30):
		if bar.visible:
			break
		await get_tree().process_frame
	assert_true(bar.visible, "rhythm bar should activate on ATTACK")

	battle._on_rhythm_finished(BattleMath.RhythmResult.POINT)

	for _i in range(30):
		await get_tree().process_frame
	var history: Array[String] = battle.log_history
	var has_damage := false
	for line in history:
		if line.contains("dmg"):
			has_damage = true
	assert_true(has_damage, "damage log line should be produced")
	assert_false(history.has("VICTORY.") and history.has("DEFEAT."))
