extends GutTest

## D-028: absorption gains must survive between battles via a versioned save.

const TEST_PATH := "user://test_progress_store.json"

func before_each() -> void:
	ProgressStore.save_path_override = TEST_PATH
	ProgressStore.clear()


func after_each() -> void:
	ProgressStore.clear()
	ProgressStore.save_path_override = ""


func _write_raw(text: String) -> void:
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_missing_save_returns_no_gains() -> void:
	assert_false(FileAccess.file_exists(TEST_PATH))
	assert_eq(ProgressStore.load_gains(), {})


func test_save_and_load_round_trip() -> void:
	var gains := {"atk": 3, "max_hp": 2, "max_en": 2, "mef": 1}
	assert_true(ProgressStore.save_gains(gains))
	var loaded: Dictionary = ProgressStore.load_gains()
	assert_eq(int(loaded["atk"]), 3)
	assert_eq(int(loaded["max_hp"]), 2)
	assert_eq(int(loaded["max_en"]), 2)
	assert_eq(int(loaded["mef"]), 1)
	assert_eq(int(loaded["mak"]), 0)


func test_corrupt_save_is_ignored() -> void:
	_write_raw("not json")
	assert_eq(ProgressStore.load_gains(), {})


func test_wrong_version_is_ignored() -> void:
	_write_raw('{"version":999,"gains":{"atk":9}}')
	assert_eq(ProgressStore.load_gains(), {})


func test_new_battle_applies_saved_gains() -> void:
	ProgressStore.save_gains({"atk": 4, "max_hp": 2, "max_en": 2})
	var packed: PackedScene = load("res://scenes/battle/Battle.tscn")
	var battle: Control = packed.instantiate()
	add_child_autofree(battle)
	for _i in range(60):
		if battle._fallen != null:
			break
		await get_tree().process_frame
	assert_eq(battle._fallen.stats.atk, 11)
	assert_eq(battle._fallen.stats.max_hp, 16)
	assert_eq(battle._fallen.stats.max_en, 10)
	assert_eq(battle._fallen.sp_base(), 54)


func test_absorption_writes_gains_to_save() -> void:
	var packed: PackedScene = load("res://scenes/battle/Battle.tscn")
	var battle: Control = packed.instantiate()
	add_child_autofree(battle)
	for _i in range(60):
		if battle._fallen != null:
			break
		await get_tree().process_frame
	get_tree().create_timer(0.1).timeout.connect(func(): battle._mash_count = 12)
	battle._perform_absorption(battle._fallen, battle.state.units[2])
	await get_tree().create_timer(2.4).timeout
	var loaded: Dictionary = ProgressStore.load_gains()
	assert_gt(int(loaded["atk"]), 0, "highest stat of the first enemy is ATK")
	assert_gt(int(loaded["max_hp"]), 0)
	assert_gt(int(loaded["max_en"]), 0)
