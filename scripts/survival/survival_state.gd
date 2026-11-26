class_name SurvivalState
extends RefCounted

## Estado da run de Survival Mode mantido em Engine meta entre trocas de cena
## (Overworld <-> Batalha). Nunca lê nem escreve no ProgressStore do jogo principal.
## D-076: versão 2 (estratos, eventos, ganhos da Yoch, itens novos, OMEN). Saves v1
## são migrados: campos novos entram com o padrão e a run continua no estrato 1.

const META_KEY := &"exodus_survival_state"
const SAVE_PATH := "user://exodus_survival_run.json"
const SAVE_VERSION := 2
const ITEM_KEYS := ["bead", "chakra", "medicine", "soma", "blast"]


static func _zero_gains() -> Dictionary:
	var gains := {}
	for key in ProgressStore.STAT_KEYS:
		gains[key] = 0
	return gains


static func _default_state() -> Dictionary:
	var seed := absi(int(Time.get_unix_time_from_system())) % 2147483647
	return {
		"fallen_hp": int(SurvivalData.FALLEN_BASE.max_hp),
		"fallen_en": int(SurvivalData.FALLEN_BASE.max_en),
		"yoch_hp": int(SurvivalData.YOCH_BASE.max_hp),
		"yoch_pp": int(SurvivalData.YOCH_BASE.pp),
		"gains": _zero_gains(),
		## D-071: ganhos próprios da Yoch na run.
		"yoch_gains": _zero_gains(),
		"skills": [],
		"unidentified": [],
		## D-073: começa com 1 relíquia inicial sorteada pela semente.
		"relics": [SurvivalRelics.starting_relic(seed)],
		"fallen_relics": [],
		"yoch_relics": [],
		"absorbs": {},
		## Semente da run: reproduz recompensas, labirintos e posições.
		"seed": seed,
		"macca": SurvivalData.STARTING_MACCA,
		"bead": SurvivalData.STARTING_BEADS,
		"chakra": SurvivalData.STARTING_CHAKRAS,
		"medicine": 0,
		"soma": 0,
		"blast": 0,
		"continues": SurvivalData.MAX_CONTINUES,
		"defeated": [],
		"encounter_id": "",
		"cell": [12, 10],
		"facing": 0,
		"visited": [],
		"seen": [],
		"enemies": [],
		## D-066: estrato atual (1..5).
		"stratum": 1,
		## D-068: curas pagas/grátis já usadas neste estrato.
		"heals_used": 0,
		## D-074: eventos já resolvidos (ids "sN_eM").
		"events_done": [],
		## D-072: relíquia da loja já comprada neste estrato.
		"shop_relic_sold": false,
		## D-075: nível de OMEN escolhido para a run (0..5).
		"omen": 0,
		## Já houve alguma luta? (OMEN só muda antes disso.)
		"battles": 0,
		## Relíquias recebidas na última vitória (mostradas ao voltar ao mapa).
		"pending_relic_choice": [],
		"last_loot": "",
		## A run vencida já foi contada no meta (o overlay pode reabrir ao recarregar).
		"finished": false,
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
	if not (parsed is Dictionary):
		return false
	var v := int((parsed as Dictionary).get("version", 0))
	return v >= 1 and v <= SAVE_VERSION


static func _in_range(value: Variant, lo: int, hi: int) -> bool:
	if not (value is int or value is float):
		return false
	var n := int(value)
	return n >= lo and n <= hi


static func maze_rows(s: Dictionary = {}) -> Array[String]:
	var st := s if not s.is_empty() else data()
	return SurvivalStrata.maze(int(st.get("seed", 1)), int(st.get("stratum", 1)))


## Nunca confia só na versão: valida tipos e intervalos antes de usar o JSON.
static func _valid_state(s: Dictionary) -> bool:
	var defaults := _default_state()
	for key in defaults.keys():
		if not s.has(key):
			return false
	for key in ["visited", "seen", "enemies", "defeated", "skills", "unidentified",
			"relics", "fallen_relics", "yoch_relics", "events_done", "pending_relic_choice"]:
		if not (s.get(key) is Array):
			return false
	if (s.get("fallen_relics") as Array).size() > SurvivalRelics.MAX_PER_ALLY:
		return false
	if (s.get("yoch_relics") as Array).size() > SurvivalRelics.MAX_PER_ALLY:
		return false
	var known_relics := SurvivalRelics.all_ids()
	for key in ["relics", "fallen_relics", "yoch_relics", "pending_relic_choice"]:
		for id in (s.get(key) as Array):
			if not (id is String) or not known_relics.has(id):
				return false
	for key in ["gains", "yoch_gains", "absorbs"]:
		if not (s.get(key) is Dictionary):
			return false
	for key in ["gains", "yoch_gains"]:
		var g: Dictionary = s.get(key)
		for stat in ProgressStore.STAT_KEYS:
			if not _in_range(g.get(stat, 0), 0, 999):
				return false
	if not _in_range(s.get("stratum"), 1, SurvivalStrata.COUNT):
		return false
	if not _in_range(s.get("omen"), 0, SurvivalMeta.MAX_OMEN):
		return false
	# HP máximo com ganhos E relíquias/pactos (antes a relíquia de HP invalidava o save).
	var gains: Dictionary = s.get("gains")
	var ygains: Dictionary = s.get("yoch_gains")
	var max_hp := int(SurvivalData.FALLEN_BASE.max_hp) + int(gains.get("max_hp", 0)) \
			+ SurvivalRelics.bonus(s.get("fallen_relics"), "max_hp")
	var max_en := int(SurvivalData.FALLEN_BASE.max_en) + int(gains.get("max_en", 0)) \
			+ SurvivalRelics.bonus(s.get("fallen_relics"), "max_en")
	var ymax := int(SurvivalData.YOCH_BASE.max_hp) + int(ygains.get("max_hp", 0)) \
			+ SurvivalRelics.bonus(s.get("yoch_relics"), "max_hp")
	if not _in_range(s.get("fallen_hp"), 1, max_hp) or not _in_range(s.get("fallen_en"), 0, max_en):
		return false
	if not _in_range(s.get("yoch_hp"), 1, ymax):
		return false
	if not _in_range(s.get("yoch_pp"), 0, PrayerBook.MAX_PP):
		return false
	if not _in_range(s.get("macca"), 0, 1000000) or not _in_range(s.get("continues"), 0, SurvivalData.MAX_CONTINUES):
		return false
	for item in ITEM_KEYS:
		if not _in_range(s.get(item), 0, 99):
			return false
	if not _in_range(s.get("facing"), 0, 3) or not _in_range(s.get("seed"), 0, 2147483647):
		return false
	if not _in_range(s.get("heals_used"), 0, 999) or not _in_range(s.get("battles"), 0, 100000):
		return false
	var cell: Variant = s.get("cell")
	if not (cell is Array) or (cell as Array).size() != 2:
		return false
	var rows := maze_rows(s)
	if not SurvivalStrata.is_floor(rows, Vector2i(int((cell as Array)[0]), int((cell as Array)[1]))):
		return false
	var known := {}
	for demon in SurvivalData.DEMONS:
		known[String(demon.id)] = true
	for st in range(1, SurvivalStrata.COUNT + 1):
		known[SurvivalData.human_group_id(st)] = true
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
	# Migração: campos que faltam entram com o padrão em vez de descartar a run.
	var restored := _default_state()
	if version < 2:
		# v1 começava com as 6 iniciais: mantém o que a run já tinha.
		restored["relics"] = SurvivalRelics.STARTER_IDS.duplicate()
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


static func stratum() -> int:
	return clampi(int(data().get("stratum", 1)), 1, SurvivalStrata.COUNT)


static func omen() -> int:
	return int(data().get("omen", 0))


static func max_continues() -> int:
	return SurvivalData.MAX_CONTINUES - (1 if omen() >= 4 else 0)


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
	var s := data()
	return int(SurvivalData.YOCH_BASE.max_hp) + int((s.get("yoch_gains", {}) as Dictionary).get("max_hp", 0)) \
			+ SurvivalRelics.bonus(s.get("yoch_relics", []), "max_hp")


## Status completos do Fallen na run (base + absorções + relíquias + pactos).
static func fallen_stats() -> UnitStats:
	var s := data()
	var gains: Dictionary = s.get("gains", {})
	var fs := UnitStats.new()
	fs.max_hp = int(SurvivalData.FALLEN_BASE.max_hp) + int(gains.get("max_hp", 0))
	fs.max_en = int(SurvivalData.FALLEN_BASE.max_en) + int(gains.get("max_en", 0))
	fs.atk = int(SurvivalData.FALLEN_BASE.atk) + int(gains.get("atk", 0))
	fs.mak = int(SurvivalData.FALLEN_BASE.mak) + int(gains.get("mak", 0))
	fs.defense = int(SurvivalData.FALLEN_BASE.defense) + int(gains.get("defense", 0))
	fs.mef = int(SurvivalData.FALLEN_BASE.mef) + int(gains.get("mef", 0))
	fs.agi = int(SurvivalData.FALLEN_BASE.agi) + int(gains.get("agi", 0))
	SurvivalRelics.apply_all(fs, s.get("fallen_relics", []))
	return fs


## Status completos da Yoch (base + ganhos próprios + relíquias + pactos).
static func yoch_stats() -> UnitStats:
	var s := data()
	var g: Dictionary = s.get("yoch_gains", {})
	var ys := UnitStats.new()
	ys.max_hp = int(SurvivalData.YOCH_BASE.max_hp) + int(g.get("max_hp", 0))
	ys.max_en = 0
	ys.atk = int(SurvivalData.YOCH_BASE.atk) + int(g.get("atk", 0))
	ys.mak = int(SurvivalData.YOCH_BASE.mak) + int(g.get("mak", 0))
	ys.defense = int(SurvivalData.YOCH_BASE.defense) + int(g.get("defense", 0))
	ys.mef = int(SurvivalData.YOCH_BASE.mef) + int(g.get("mef", 0))
	ys.agi = int(SurvivalData.YOCH_BASE.agi) + int(g.get("agi", 0))
	SurvivalRelics.apply_all(ys, s.get("yoch_relics", []))
	ys.max_en = 0
	return ys


static func heal_party_full() -> void:
	patch({
		"fallen_hp": fallen_max_hp(),
		"fallen_en": fallen_max_en(),
		"yoch_hp": yoch_max_hp(),
	})


## D-068: preço da próxima cura do santuário (0 = grátis).
static func heal_price() -> int:
	var s := data()
	if int(s.get("heals_used", 0)) == 0 and omen() < 2:
		return 0
	return SurvivalData.HEAL_PRICE_PER_STRATUM * stratum()


## Cura paga/grátis. Retorna false (sem gastar nada) se faltar Macca.
static func sanctuary_heal() -> bool:
	var cost := heal_price()
	var s := data()
	if int(s.get("macca", 0)) < cost:
		return false
	patch({"macca": int(s.get("macca", 0)) - cost, "heals_used": int(s.get("heals_used", 0)) + 1})
	heal_party_full()
	return true


static func item_price(item_id: String) -> int:
	var item := SurvivalData.shop_item(item_id)
	if item.is_empty():
		return 0
	return SurvivalData.price(int(item.price), stratum(), data())


static func buy_item(item_id: String) -> bool:
	var item := SurvivalData.shop_item(item_id)
	if item.is_empty():
		return false
	var s := data()
	var cost := item_price(item_id)
	if int(s.get("macca", 0)) < cost or int(s.get(item_id, 0)) >= 99:
		return false
	s["macca"] = int(s.get("macca", 0)) - cost
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
	var total := 0
	for key in ITEM_KEYS:
		total += int(s.get(key, 0))
	return total


static func record_victory(demon_id: String, macca_reward: int) -> void:
	var s := data()
	var defeated: Array = s.get("defeated", [])
	if not demon_id.is_empty() and not defeated.has(demon_id):
		defeated.append(demon_id)
	s["defeated"] = defeated
	s["macca"] = int(s.get("macca", 0)) + maxi(0, macca_reward)
	_commit(s)


static func warden_down(stratum_n: int = -1) -> bool:
	var st := stratum() if stratum_n < 0 else stratum_n
	return (data().get("defeated", []) as Array).has(SurvivalStrata.warden_of(st))


static func run_cleared() -> bool:
	return warden_down(SurvivalStrata.COUNT)


## D-066: desce para o próximo estrato (só com o guardião derrotado).
static func descend() -> bool:
	var st := stratum()
	if not warden_down(st) or st >= SurvivalStrata.COUNT:
		return false
	patch({"stratum": st + 1, "cell": [SurvivalStrata.START.x, SurvivalStrata.START.y],
		"facing": 0, "visited": [], "seen": [], "enemies": [], "heals_used": 0,
		"shop_relic_sold": false})
	return true


static func toggle_relic(who: String, id: String) -> Dictionary:
	var changes := SurvivalRelics.toggle(data(), who, id)
	var out := patch(changes)
	# Tirar uma relíquia de HP não pode deixar o HP atual acima do máximo novo.
	patch({"fallen_hp": clampi(int(out.fallen_hp), 1, fallen_max_hp()),
		"fallen_en": clampi(int(out.fallen_en), 0, fallen_max_en()),
		"yoch_hp": clampi(int(out.yoch_hp), 1, yoch_max_hp())})
	return data()


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
		if not SurvivalRelics.party_has(s, "identified"):
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
