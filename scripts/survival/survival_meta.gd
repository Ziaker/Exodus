class_name SurvivalMeta
extends RefCounted
## Meta-progresso separado da run: score, melhor score e relíquias desbloqueadas.
## A run é apagada no game over; isto sobrevive e não é ProgressStore da campanha.

const SAVE_PATH := "user://exodus_survival_meta.json"
const VERSION := 1


static func _defaults() -> Dictionary:
	return {"version": VERSION, "best": 0, "runs": 0,
		"unlocked": [], "last_score": 0}


static func data() -> Dictionary:
	var fallback := _defaults()
	if not FileAccess.file_exists(SAVE_PATH):
		return fallback
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return fallback
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		return fallback
	for key in fallback.keys():
		if (parsed as Dictionary).has(key):
			fallback[key] = parsed[key]
	return fallback


static func save(data_dict: Dictionary) -> void:
	var out := _defaults()
	for key in data_dict.keys():
		if out.has(key):
			out[key] = data_dict[key]
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(out))
	f.close()


static func score(defeated: int, macca: int, continues: int) -> int:
	return defeated * 100 + maxi(0, macca) + maxi(0, continues) * 50


static func finish_run(defeated: int, macca: int, continues: int) -> Dictionary:
	var meta := data()
	var value := score(defeated, macca, continues)
	meta["last_score"] = value
	meta["best"] = maxi(int(meta.best), value)
	meta["runs"] = int(meta.runs) + 1
	var unlocked: Array = meta.unlocked
	for id in SurvivalRelics.UNLOCK_SCORES.keys():
		if value >= int(SurvivalRelics.UNLOCK_SCORES[id]) and not unlocked.has(id):
			unlocked.append(id)
	meta["unlocked"] = unlocked
	save(meta)
	return meta


static func daily_seed() -> int:
	var d := Time.get_date_dict_from_system(true)
	return int(d.year) * 10000 + int(d.month) * 100 + int(d.day)
