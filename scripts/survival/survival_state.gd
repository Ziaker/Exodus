class_name SurvivalState
extends RefCounted

## Estado da run de Survival Mode mantido em Engine meta entre trocas de cena
## (Overworld <-> Batalha). Nunca lê nem escreve no ProgressStore do jogo principal.

const META_KEY := &"exodus_survival_state"
const SAVE_PATH := "user://exodus_survival_run.json"
const SAVE_VERSION := 1


static func _default_state() -> Dictionary:
	var gains := {}
	for key in ProgressStore.STAT_KEYS:
		gains[key] = 0
	return {
		"fallen_hp": int(SurvivalData.FALLEN_BASE.max_hp),
		"fallen_en": int(SurvivalData.FALLEN_BASE.max_en),
		"yoch_hp": int(SurvivalData.YOCH_BASE.max_hp),
		"yoch_pp": int(SurvivalData.YOCH_BASE.pp),
		"gains": gains,
		"skills": [],
		"unidentified": [],
		"relics": SurvivalRelics.STARTER_IDS.duplicate(),
		"fallen_relics": [],
		"yoch_relics": [],
		"absorbs": {},
		## Semente da run: reproduz recompensas e permite daily seeds depois.
		"seed": absi(int(Time.get_unix_time_from_system())) % 2147483647,
		"macca": SurvivalData.STARTING_MACCA,
		"bead": SurvivalData.STARTING_BEADS,
		"chakra": SurvivalData.STARTING_CHAKRAS,
		"continues": SurvivalData.MAX_CONTINUES,
		"defeated": [],
		"encounter_id": "",
		"cell": [12, 10],
		"facing": 0,
		"visited": [],
		"seen": [],
		"enemies": [],
	}


static func reset() -> Dictionary:
	var fresh := _default_state()
	Engine.set_meta(META_KEY, fresh)
	save_to_file()
	return fresh


static func clear() -> void:
	if Engine.has_meta(META_KEY):
		Engine.remove_meta(META_KEY)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


static func save_to_file() -> void:
	if not Engine.has_meta(META_KEY):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"version": SAVE_VERSION, "state": Engine.get_meta(META_KEY)}))
	f.close()


static func has_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed is Dictionary and int((parsed as Dictionary).get("version", 0)) == SAVE_VERSION


static func _in_range(value: Variant, lo: int, hi: int) -> bool:
	if not (value is int or value is float):
		return false
	var n := int(value)
	return n >= lo and n <= hi


## Nunca confia só na versão: valida tipos e intervalos antes de usar o JSON.
static func _valid_state(s: Dictionary) -> bool:
	var defaults := _default_state()
	for key in defaults.keys():
		if not s.has(key):
			return false
	for key in ["visited", "seen", "enemies", "defeated", "skills", "unidentified",
			"relics", "fallen_relics", "yoch_relics"]:
		if not (s.get(key) is Array):
			return false
	if (s.get("fallen_relics") as Array).size() > SurvivalRelics.MAX_PER_ALLY:
		return false
	if (s.get("yoch_relics") as Array).size() > SurvivalRelics.MAX_PER_ALLY:
		return false
	if not (s.get("gains") is Dictionary) or not (s.get("absorbs") is Dictionary):
		return false
	var gains: Dictionary = s.get("gains")
	for key in ProgressStore.STAT_KEYS:
		if not _in_range(gains.get(key, 0), 0, 999):
			return false
	var max_hp := int(SurvivalData.FALLEN_BASE.max_hp) + int(gains.get("max_hp", 0))
	var max_en := int(SurvivalData.FALLEN_BASE.max_en) + int(gains.get("max_en", 0))
	if not _in_range(s.get("fallen_hp"), 1, max_hp) or not _in_range(s.get("fallen_en"), 0, max_en):
		return false
	if not _in_range(s.get("yoch_hp"), 1, int(SurvivalData.YOCH_BASE.max_hp)):
		return false
	if not _in_range(s.get("yoch_pp"), 0, PrayerBook.MAX_PP):
		return false
	if not _in_range(s.get("macca"), 0, 1000000) or not _in_range(s.get("continues"), 0, SurvivalData.MAX_CONTINUES):
		return false
	if not _in_range(s.get("bead"), 0, 99) or not _in_range(s.get("chakra"), 0, 99):
		return false
	if not _in_range(s.get("facing"), 0, 3) or not _in_range(s.get("seed"), 0, 2147483647):
		return false
	var cell: Variant = s.get("cell")
	if not (cell is Array) or (cell as Array).size() != 2:
		return false
	var cx := int((cell as Array)[0])
	var cy := int((cell as Array)[1])
	if cy < 0 or cy >= SurvivalData.MAZE.size() or cx < 0 or cx >= SurvivalData.MAZE[cy].length():
		return false
	if SurvivalData.MAZE[cy][cx] == "#":
		return false
	var known := {}
	for demon in SurvivalData.DEMONS:
		known[String(demon.id)] = true
	for id in (s.get("defeated") as Array):
		if not (id is String) or not known.has(id):
			return false
	for skill in (s.get("skills") as Array):
		if not (skill is String):
			return false
	return true


static func load_from_file() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		return false
	var version := int((parsed as Dictionary).get("version", 0))
	if version <= 0 or version > SAVE_VERSION:
		return false
	var loaded: Variant = (parsed as Dictionary).get("state", null)
	if not (loaded is Dictionary):
		return false
	# Migração: saves da rodada anterior não tinham `seed` nem alguns campos.
	# Faltando qualquer chave, entra o default em vez de descartar a run.
	var restored := _default_state()
	for key in (loaded as Dictionary).keys():
		if restored.has(key):
			restored[key] = loaded[key]
	if not _valid_state(restored):
		return false
	Engine.set_meta(META_KEY, restored)
	save_to_file() # grava já no formato atual
	return true


static func _commit(state: Dictionary) -> Dictionary:
	Engine.set_meta(META_KEY, state)
	save_to_file()
	return state


static func data() -> Dictionary:
	if not Engine.has_meta(META_KEY):
		return reset()
	var current: Variant = Engine.get_meta(META_KEY)
	if not (current is Dictionary):
		return reset()
	return current


static func patch(updates: Dictionary) -> Dictionary:
	var state := data()
	for key in updates.keys():
		state[key] = updates[key]
	return _commit(state)


static func fallen_max_hp() -> int:
	var s := data()
	var gains: Dictionary = s.get("gains", {})
	return int(SurvivalData.FALLEN_BASE.max_hp) + int(gains.get("max_hp", 0)) \
			+ SurvivalRelics.bonus(s.get("fallen_relics", []), "max_hp")


static func fallen_max_en() -> int:
	var s := data()
	var gains: Dictionary = s.get("gains", {})
	return int(SurvivalData.FALLEN_BASE.max_en) + int(gains.get("max_en", 0)) \
			+ SurvivalRelics.bonus(s.get("fallen_relics", []), "max_en")


static func yoch_max_hp() -> int:
	return int(SurvivalData.YOCH_BASE.max_hp) \
			+ SurvivalRelics.bonus(data().get("yoch_relics", []), "max_hp")


static func heal_party_full() -> void:
	patch({
		"fallen_hp": fallen_max_hp(),
		"fallen_en": fallen_max_en(),
		"yoch_hp": yoch_max_hp(),
	})


static func buy_item(item_id: String) -> bool:
	var item := SurvivalData.shop_item(item_id)
	if item.is_empty():
		return false
	var s := data()
	var price := int(item.price)
	if int(s.get("macca", 0)) < price:
		return false
	s["macca"] = int(s.get("macca", 0)) - price
	s[item_id] = int(s.get(item_id, 0)) + 1
	_commit(s)
	return true


static func consume_item(item_id: String) -> bool:
	var s := data()
	var count := int(s.get(item_id, 0))
	if count <= 0:
		return false
	s[item_id] = count - 1
	_commit(s)
	return true


static func total_items() -> int:
	var s := data()
	return int(s.get("bead", 0)) + int(s.get("chakra", 0))


static func record_victory(demon_id: String, macca_reward: int) -> void:
	var s := data()
	var defeated: Array = s.get("defeated", [])
	if not demon_id.is_empty() and not defeated.has(demon_id):
		defeated.append(demon_id)
	s["defeated"] = defeated
	s["macca"] = int(s.get("macca", 0)) + maxi(0, macca_reward)
	_commit(s)


static func toggle_relic(who: String, id: String) -> Dictionary:
	var changes := SurvivalRelics.toggle(data(), who, id)
	return patch(changes)


static func grant_relic(id: String) -> bool:
	var s := data()
	var owned: Array = s.get("relics", [])
	if SurvivalRelics.relic(id).is_empty() or owned.has(id):
		return false
	owned.append(id)
	patch({"relics": owned})
	return true


static func learn_skill(skill: StringName) -> void:
	var s := data()
	var skills: Array = s.get("skills", [])
	var unknown: Array = s.get("unidentified", [])
	if not skills.has(String(skill)):
		skills.append(String(skill))
		unknown.append(String(skill))
	patch({"skills": skills, "unidentified": unknown})


static func identify_skill(skill: StringName) -> void:
	var s := data()
	var unknown: Array = s.get("unidentified", [])
	if unknown.has(String(skill)):
		unknown.erase(String(skill))
		patch({"unidentified": unknown})


static func use_continue() -> int:
	var s := data()
	var left := int(s.get("continues", 0))
	if left <= 0:
		return -1
	left -= 1
	s["continues"] = left
	_commit(s)
	heal_party_full()
	return left
