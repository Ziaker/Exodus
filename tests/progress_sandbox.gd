extends RefCounted
## Keeps verify_* scripts independent of the player's real D-024 save.
## begin(): back up user://exodus_progress.json (if any) and start from no gains.
## end(): discard what the test wrote and restore the backup byte for byte.
## Call end() from SceneTree._finalize() so it also runs after a failed check.

static var _had_save := false
static var _backup := ""


static func begin() -> void:
	_had_save = FileAccess.file_exists(ProgressStore.SAVE_PATH)
	if _had_save:
		_backup = FileAccess.get_file_as_string(ProgressStore.SAVE_PATH)
	ProgressStore.clear()


static func end() -> void:
	ProgressStore.clear()
	if _had_save:
		var file := FileAccess.open(ProgressStore.SAVE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string(_backup)
			file.close()
