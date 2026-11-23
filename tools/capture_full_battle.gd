extends SceneTree

## Drives one battle using the D-046 queue: plans two attacks at once so the
## green ACT markers and the persistent chained rhythm bar are visible.

const FRAME_DIR := "res://captures/battle_frames"
const MAX_FRAMES := 6000
const CAPTURE_EVERY := 2

var battle: Control
var frame_count: int = 0
var saved_count: int = 0
var last_action_frame: int = -100
var last_log_count: int = 0
var plan_index: int = 0
var plan_ready_frame: int = -1
var was_planning: bool = false

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(FRAME_DIR)
	ProgressStore.save_path_override = "user://capture_full_progress.json"
	ProgressStore.clear()
	var dir := DirAccess.open(FRAME_DIR)
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
	var packed: PackedScene = load("res://scenes/battle/Battle.tscn")
	battle = packed.instantiate()
	root.add_child(battle)
	battle.rng.seed = 4242
	for _i in range(12):
		await process_frame

	for _i in range(MAX_FRAMES):
		_drive()
		if frame_count % CAPTURE_EVERY == 0:
			_save_frame()
		await process_frame
		frame_count += 1
		if battle.state != null and battle.state.is_over() and frame_count > 20:
			break

	for _i in range(90):
		if frame_count % CAPTURE_EVERY == 0:
			_save_frame()
		await process_frame
		frame_count += 1

	print("FRAMES: ", saved_count, "  FINAL_OVER: ", battle.state.is_over())
	quit(0)


func _drive() -> void:
	if battle.log_history.size() != last_log_count:
		last_log_count = battle.log_history.size()
		plan_index = 0
		plan_ready_frame = -1
	if battle._mash_active:
		battle._mash_count = 12
	if battle._reaction_active and frame_count - last_action_frame > 16:
		battle._reaction_yes = true
		last_action_frame = frame_count
		return
	if battle.rhythm != null and battle.rhythm._running \
			and battle.rhythm.visible and battle.rhythm._elapsed > 0.30:
		battle._on_rhythm_finished(BattleMath.RhythmResult.POINT)
		last_action_frame = frame_count
		return
	if battle._plan_active:
		if not was_planning:
			was_planning = true
			plan_index = 0
			plan_ready_frame = -1
		if plan_index < 2 and frame_count - last_action_frame > 8:
			battle._chosen = 0  # ATTACK + ATTACK in the same planned block
			plan_index += 1
			battle.command_chosen.emit()
			last_action_frame = frame_count
			if plan_index == 2:
				plan_ready_frame = frame_count
		elif plan_index >= 2 and plan_ready_frame > 0 \
				and frame_count - plan_ready_frame > 40 \
				and frame_count - last_action_frame > 8:
			# Only needed when the unit has more acts than the two planned.
			battle._chosen = battle._plan_options.size() - 2  # EXEC
			battle.command_chosen.emit()
			last_action_frame = frame_count
		return
	was_planning = false
	if battle.command_box != null and battle.command_box.get_child_count() > 0 \
			and frame_count - last_action_frame > 12:
		battle._chosen = 0
		battle.command_chosen.emit()
		last_action_frame = frame_count


func _save_frame() -> void:
	var image: Image = root.get_texture().get_image()
	var path := "%s/frame_%04d.png" % [FRAME_DIR, saved_count]
	image.save_png(ProjectSettings.globalize_path(path))
	saved_count += 1
