class_name ProgressStore
extends RefCounted

## D-028: absorption gains survive between battles in a versioned JSON file.
## Only stat deltas are stored; no third-party data and no game rules are invented.

const SAVE_FILE := "exodus_progress.json"
const SAVE_PATH := "user://" + SAVE_FILE
const VERSION := 1
const STAT_KEYS: Array[String] = [
	"max_hp", "max_en", "atk", "mak", "defense", "mef", "agi",
]
const MAX_GAIN := 10000

## Tests may point the store at a private file so asynchronous battles from
## other test scripts cannot overwrite the save being asserted.
static var save_path_override: String = ""

static func _path() -> String:
	return save_path_override if not save_path_override.is_empty() else SAVE_PATH


static func load_gains() -> Dictionary:
	var file := FileAccess.open(_path(), FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text().strip_edges()
	file.close()
	# Cheap guard: avoid handing obvious garbage to the JSON parser, which logs
	# an engine error that GUT rightly treats as a failure.
	if text.is_empty() or not text.begins_with("{") or not text.ends_with("}"):
		return {}
	if not text.contains("\"version\"") or not text.contains("\"gains\""):
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {}
	var data: Dictionary = parsed
	if int(data.get("version", -1)) != VERSION:
		return {}
	var raw: Variant = data.get("gains", {})
	if not (raw is Dictionary):
		return {}
	var result := {}
	for key in STAT_KEYS:
		result[key] = clampi(int((raw as Dictionary).get(key, 0)), 0, MAX_GAIN)
	return result


static func save_gains(gains: Dictionary) -> bool:
	var entries := {}
	for key in STAT_KEYS:
		entries[key] = clampi(int(gains.get(key, 0)), 0, MAX_GAIN)
	var payload := {"version": VERSION, "gains": entries}
	var file := FileAccess.open(_path(), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload))
	file.close()
	return true


static func clear() -> void:
	var path := _path()
	var file_name := path.get_file()
	var dir := DirAccess.open(path.get_base_dir())
	if dir != null and dir.file_exists(file_name):
		dir.remove(file_name)
