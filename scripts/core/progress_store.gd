class_name ProgressStore
extends RefCounted

## D-028: absorption gains survive between battles in a versioned JSON file.
## Stat deltas, absorptions per enemy kind and learned skills (creator 2026-11-23).

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


## Validated save contents, or {} for a missing/corrupt/foreign file.
static func _read() -> Dictionary:
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
	if not (data.get("gains", {}) is Dictionary):
		return {}
	return data


static func load_gains() -> Dictionary:
	var data := _read()
	if data.is_empty():
		return {}
	var raw: Dictionary = data.get("gains", {})
	var result := {}
	for key in STAT_KEYS:
		result[key] = clampi(int(raw.get(key, 0)), 0, MAX_GAIN)
	return result


## Creator 2026-11-23: absorptions counted per enemy kind (towards the next skill).
static func load_absorbs() -> Dictionary:
	var raw: Variant = _read().get("absorbs", {})
	var result := {}
	if raw is Dictionary:
		for key in (raw as Dictionary).keys():
			result[String(key)] = clampi(int((raw as Dictionary)[key]), 0, SkillBook.ABSORBS_PER_SKILL)
	return result


## Skills Fallen learned by absorption (kept for good, also after a defeat restart).
static func load_skills() -> Array[StringName]:
	var raw: Variant = _read().get("skills", [])
	var result: Array[StringName] = []
	if raw is Array:
		for skill in raw:
			var id := StringName(str(skill))
			if SkillBook.DEFS.has(id) and not result.has(id):
				result.append(id)
	return result


static func save_gains(gains: Dictionary) -> bool:
	return _write(gains, load_absorbs(), load_skills())


static func save_skill_progress(absorbs: Dictionary, skills: Array[StringName]) -> bool:
	return _write(load_gains(), absorbs, skills)


static func _write(gains: Dictionary, absorbs: Dictionary, skills: Array[StringName]) -> bool:
	var entries := {}
	for key in STAT_KEYS:
		entries[key] = clampi(int(gains.get(key, 0)), 0, MAX_GAIN)
	var counts := {}
	for key in absorbs.keys():
		counts[String(key)] = clampi(int(absorbs[key]), 0, SkillBook.ABSORBS_PER_SKILL)
	var names: Array[String] = []
	for skill in skills:
		names.append(String(skill))
	var payload := {"version": VERSION, "gains": entries, "absorbs": counts, "skills": names}
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
