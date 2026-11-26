class_name SurvivalMeta
extends RefCounted
## Meta-progresso separado da run: score, melhor score, relíquias desbloqueadas,
## D-075: OMEN desbloqueado (dificuldade empilhada, como Ascensão/Heat) e CODEX
## (compêndio de demônios derrotados em qualquer run). A run é apagada no game over;
## isto sobrevive e não é o ProgressStore da campanha.

const SAVE_PATH := "user://exodus_survival_meta.json"
const VERSION := 1
const MAX_OMEN := 5
const OMEN_INFO := [
	"OMEN 0: the arena as it is.",
	"OMEN 1: demons +15% HP.",
	"OMEN 2: + the sanctuary HEAL is never free.",
	"OMEN 3: + elites appear 35% of the time.",
	"OMEN 4: + only 2 continues.",
	"OMEN 5: + wardens +3 ATK / +3 MAK.",
]


static func _defaults() -> Dictionary:
	return {"version": VERSION, "best": 0, "runs": 0,
		"unlocked": [], "last_score": 0, "omen_unlocked": 0, "codex": [], "clears": 0}


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
		if (parsed as Dictionary).has(key) and typeof(parsed[key]) == typeof(fallback[key]):
			fallback[key] = parsed[key]
		elif (parsed as Dictionary).has(key) and (fallback[key] is int) and (parsed[key] is float):
			fallback[key] = int(parsed[key])
	fallback["omen_unlocked"] = clampi(int(fallback.omen_unlocked), 0, MAX_OMEN)
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


## Fórmula antiga (mantida para compatibilidade dos testes/telas antigas).
static func score(defeated: int, macca: int, continues: int) -> int:
	return defeated * 100 + maxi(0, macca) + maxi(0, continues) * 50


## D-075: score da run inteira.
static func run_score(state: Dictionary) -> int:
	var defeated: Array = state.get("defeated", [])
	var wardens := 0
	for s in range(1, SurvivalStrata.COUNT + 1):
		if defeated.has(SurvivalStrata.warden_of(s)):
			wardens += 1
	var base := defeated.size() * 100 + int(state.get("stratum", 1)) * 300 + wardens * 250 \
			+ maxi(0, int(state.get("macca", 0))) / 2 + maxi(0, int(state.get("continues", 0))) * 100
	return int(round(float(base) * (1.0 + 0.2 * float(int(state.get("omen", 0))))))


static func finish_run(defeated: int, macca: int, continues: int, state: Dictionary = {}) -> Dictionary:
	var meta := data()
	var value := score(defeated, macca, continues) if state.is_empty() else run_score(state)
	meta["last_score"] = value
	meta["best"] = maxi(int(meta.best), value)
	meta["runs"] = int(meta.runs) + 1
	var unlocked: Array = meta.unlocked
	for id in SurvivalRelics.UNLOCK_SCORES.keys():
		if value >= int(SurvivalRelics.UNLOCK_SCORES[id]) and not unlocked.has(id):
			unlocked.append(id)
	meta["unlocked"] = unlocked
	if not state.is_empty():
		var codex: Array = meta.codex
		for id in state.get("defeated", []):
			# D-107: o CODEX é de demônios; grupos de humanos não entram.
			if not codex.has(String(id)) and not String(id).begins_with("humans_"):
				codex.append(String(id))
		meta["codex"] = codex
		# Vencer no OMEN n libera o n+1.
		var cleared := (state.get("defeated", []) as Array).has(SurvivalStrata.warden_of(SurvivalStrata.COUNT))
		if cleared:
			meta["clears"] = int(meta.clears) + 1
			var level := int(state.get("omen", 0))
			if level >= int(meta.omen_unlocked) and level < MAX_OMEN:
				meta["omen_unlocked"] = level + 1
	save(meta)
	return meta


static func daily_seed() -> int:
	var d := Time.get_date_dict_from_system(true)
	return int(d.year) * 10000 + int(d.month) * 100 + int(d.day)
