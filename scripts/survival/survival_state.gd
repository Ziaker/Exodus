class_name SurvivalState
extends RefCounted

## Estado da run de Survival Mode mantido em Engine meta entre trocas de cena
## (Overworld <-> Batalha). Nunca lê nem escreve no ProgressStore do jogo principal.
## D-076: versão 2 (estratos, eventos, itens novos, OMEN). D-111 (criador 2026-11-26): versão 3,
## com grupo de aliados e reserva; a run começa só com o Fallen. Saves antigos (v1/v2, com o Yoch
## fixo no grupo) são descartados e a run recomeça.

const META_KEY := &"exodus_survival_state"
const SAVE_PATH := "user://exodus_survival_run.json"
const SAVE_VERSION := 3
## D-111: saves abaixo desta versão são descartados (não migram).
const MIN_SAVE_VERSION := 3
const ITEM_KEYS := ["bead", "chakra", "medicine", "soma", "blast"]


static func _zero_gains() -> Dictionary:
	var gains := {}
	for key in ProgressStore.STAT_KEYS:
		gains[key] = 0
	return gains


static func _default_state() -> Dictionary:
	var seed := absi(int(Time.get_unix_time_from_system())) % 2147483647
	var entrance := SurvivalStrata.entrance(1)
	return {
		"fallen_hp": int(SurvivalData.FALLEN_BASE.max_hp),
		"fallen_en": int(SurvivalData.FALLEN_BASE.max_en),
		"gains": _zero_gains(),
		"skills": [],
		"unidentified": [],
		## D-073: começa com 1 relíquia inicial sorteada pela semente.
		"relics": [SurvivalRelics.starting_relic(seed)],
		"fallen_relics": [],
		## D-111: aliados no grupo (até 2) e na reserva do santuário (até 8). Ver SurvivalAllies.
		"party": [],
		"reserve": [],
		"next_uid": 1,
		## O Yoch já entrou nesta run (não aparece de novo).
		"yoch_joined": false,
		## Encontros de recrutamento do mapa já resolvidos (ids "sN_rM").
		"recruits_done": [],
		## Contratados no santuário ("N:id": estrato e demônio), que saem do estoque.
		"hired": [],
		## Avisos de crescimento a mostrar no mapa ("PIXIE +1 AGI").
		"growth_toast": [],
		## Estrato cujo aviso do Yoch já apareceu.
		"yoch_notice": 0,
		## Luta-teste em andamento: o que volta ao fim (HP/EN/PP/continues; itens não).
		"duel": {},
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
		"cell": [entrance.x, entrance.y],
		"necropole": true,
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
	return v >= MIN_SAVE_VERSION and v <= SAVE_VERSION


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
			"relics", "fallen_relics", "events_done", "pending_relic_choice",
			"party", "reserve", "recruits_done", "growth_toast", "hired"]:
		if not (s.get(key) is Array):
			return false
	if (s.get("fallen_relics") as Array).size() > SurvivalRelics.MAX_PER_UNIT:
		return false
	var known_relics := SurvivalRelics.all_ids()
	for key in ["relics", "fallen_relics", "pending_relic_choice"]:
		for id in (s.get(key) as Array):
			if not (id is String) or not known_relics.has(id):
				return false
	for key in ["gains", "absorbs", "duel"]:
		if not (s.get(key) is Dictionary):
			return false
	var g: Dictionary = s.get("gains")
	for stat in ProgressStore.STAT_KEYS:
		if not _in_range(g.get(stat, 0), 0, 999):
			return false
	if (s.get("party") as Array).size() > SurvivalAllies.PARTY_MAX \
			or (s.get("reserve") as Array).size() > SurvivalAllies.RESERVE_MAX:
		return false
	var uids := {}
	for list_key in ["party", "reserve"]:
		for m in (s.get(list_key) as Array):
			if not _valid_member(m, known_relics) or uids.has(String(m.uid)):
				return false
			uids[String(m.uid)] = true
	if not _in_range(s.get("next_uid"), 1, 1000000) or not (s.get("yoch_joined") is bool):
		return false
	if not _in_range(s.get("stratum"), 1, SurvivalStrata.COUNT):
		return false
	if not _in_range(s.get("omen"), 0, SurvivalMeta.MAX_OMEN):
		return false
	# HP máximo com ganhos E relíquias/pactos (antes a relíquia de HP invalidava o save).
	var gains: Dictionary = s.get("gains")
	var max_hp := int(SurvivalData.FALLEN_BASE.max_hp) + int(gains.get("max_hp", 0)) \
			+ SurvivalRelics.bonus(s.get("fallen_relics"), "max_hp")
	var max_en := int(SurvivalData.FALLEN_BASE.max_en) + int(gains.get("max_en", 0)) \
			+ SurvivalRelics.bonus(s.get("fallen_relics"), "max_en")
	if not _in_range(s.get("fallen_hp"), 1, max_hp) or not _in_range(s.get("fallen_en"), 0, max_en):
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


## Um aliado salvo (SurvivalAllies): tipos, ficha, relíquias dentro do teto, HP/EN/PP no intervalo.
static func _valid_member(m: Variant, known_relics: Array) -> bool:
	if not (m is Dictionary):
		return false
	var d := m as Dictionary
	for key in ["uid", "kind", "id", "name", "picture"]:
		if not (d.get(key) is String):
			return false
	if not (String(d.kind) in ["demon", "human", "yoch"]):
		return false
	for key in ["skills", "spells", "relics"]:
		if not (d.get(key) is Array):
			return false
	if not (d.get("stats") is Dictionary) or not (d.get("down") is bool) or not (d.get("auto") is bool):
		return false
	if (d.relics as Array).size() > SurvivalRelics.cap_of(d):
		return false
	for id in (d.relics as Array):
		if not (id is String) or not known_relics.has(id):
			return false
	if String(d.kind) != "yoch":
		if SurvivalData.demon_by_id(String(d.id)).is_empty():
			return false
		for k in SurvivalAllies.STAT_KEYS:
			if not _in_range((d.stats as Dictionary).get(k, -1), 0, 9999):
				return false
	if not _in_range(d.get("hp"), -1, 99999) or not _in_range(d.get("en"), 0, 9999) \
			or not _in_range(d.get("pp"), 0, PrayerBook.MAX_PP) or not _in_range(d.get("fights"), 0, 100000):
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
	if version < MIN_SAVE_VERSION or version > SAVE_VERSION:
		return false
	var loaded: Variant = (parsed as Dictionary).get("state", null)
	if not (loaded is Dictionary):
		return false
	# Migração: campos que faltam entram com o padrão em vez de descartar a run.
	var restored := _default_state()
	for key in (loaded as Dictionary).keys():
		if restored.has(key):
			restored[key] = loaded[key]
	if int(restored.get("stratum", 1)) == 1 and loaded.get("necropole", false) != true:
		# A grade antiga só perde a posição e a memória espacial.
		var entrance := SurvivalStrata.entrance(1)
		restored.merge({"cell": [entrance.x, entrance.y], "facing": 0,
			"visited": [], "seen": [], "enemies": [], "necropole": true}, true)
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


# ------------------------------------------------------------ D-111: aliados

static func fallen_sp() -> int:
	return fallen_stats().sp_value()


static func party() -> Array:
	return data().get("party", [])


static func reserve() -> Array:
	return data().get("reserve", [])


static func member_stats(m: Dictionary) -> UnitStats:
	return SurvivalAllies.member_stats(m, fallen_sp())


static func member_max_hp(m: Dictionary) -> int:
	return member_stats(m).max_hp


## HP atual do aliado (o Yoch começa com -1 = cheio; o máximo dele muda com o Fallen).
static func member_hp(m: Dictionary) -> int:
	var top := member_max_hp(m)
	if bool(m.get("down", false)):
		return 0
	var hp := int(m.get("hp", -1))
	return top if hp < 0 else clampi(hp, 1, top)


static func new_uid() -> String:
	var s := data()
	var n := int(s.get("next_uid", 1))
	patch({"next_uid": n + 1})
	return "m%d" % n


## Põe o aliado no grupo (se couber) ou na reserva. Devolve "party", "reserve" ou "" (sem lugar).
static func add_member(m: Dictionary) -> String:
	var s := data()
	var p: Array = (s.get("party", []) as Array).duplicate(true)
	var r: Array = (s.get("reserve", []) as Array).duplicate(true)
	var where := ""
	if p.size() < SurvivalAllies.PARTY_MAX:
		p.append(m)
		where = "party"
	elif r.size() < SurvivalAllies.RESERVE_MAX:
		r.append(m)
		where = "reserve"
	else:
		return ""
	var changes := {"party": p, "reserve": r}
	if String(m.get("kind", "")) == "yoch":
		changes["yoch_joined"] = true
	patch(changes)
	return where


static func has_room() -> bool:
	return party().size() < SurvivalAllies.PARTY_MAX or reserve().size() < SurvivalAllies.RESERVE_MAX


static func find_member(uid: String) -> Dictionary:
	for list in [party(), reserve()]:
		for m in list:
			if String(m.get("uid", "")) == uid:
				return m
	return {}


## Troca no santuário: grupo -> reserva; reserva -> grupo (se couber) ou troca de lugar com o
## aliado do grupo indicado em `with_uid`.
static func move_member(uid: String, with_uid: String = "") -> bool:
	var p: Array = party().duplicate(true)
	var r: Array = reserve().duplicate(true)
	var pi := -1
	var ri := -1
	for i in p.size():
		if String(p[i].uid) == uid: pi = i
	for i in r.size():
		if String(r[i].uid) == uid: ri = i
	if pi >= 0:
		if r.size() >= SurvivalAllies.RESERVE_MAX:
			return false
		r.append(p[pi])
		p.remove_at(pi)
	elif ri >= 0:
		if p.size() < SurvivalAllies.PARTY_MAX:
			p.append(r[ri])
			r.remove_at(ri)
		else:
			var wi := -1
			for i in p.size():
				if String(p[i].uid) == with_uid: wi = i
			if wi < 0:
				return false
			var t: Dictionary = p[wi]
			p[wi] = r[ri]
			r[ri] = t
	else:
		return false
	patch({"party": p, "reserve": r})
	return true


## Troca chaves de um aliado (grupo ou reserva) e salva.
static func update_member(uid: String, changes: Dictionary) -> void:
	var p: Array = party().duplicate(true)
	var r: Array = reserve().duplicate(true)
	for list in [p, r]:
		for m in list:
			if String(m.uid) == uid:
				for k in changes.keys():
					m[k] = changes[k]
	patch({"party": p, "reserve": r})


## HEAL do santuário: Fallen e todos os aliados (grupo e reserva) cheios; D-111: revive os caídos.
static func heal_party_full() -> void:
	var lists := {}
	for key in ["party", "reserve"]:
		var out: Array = (data().get(key, []) as Array).duplicate(true)
		for m in out:
			var st := member_stats(m)
			m["down"] = false
			m["hp"] = st.max_hp
			m["en"] = st.max_en
		lists[key] = out
	patch({
		"fallen_hp": fallen_max_hp(),
		"fallen_en": fallen_max_en(),
		"party": lists.party,
		"reserve": lists.reserve,
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
	if changes.is_empty():
		return data()
	var out := patch(changes)
	# Tirar uma relíquia de HP não pode deixar o HP atual acima do máximo novo.
	var lists := {}
	for key in ["party", "reserve"]:
		var ms: Array = (out.get(key, []) as Array).duplicate(true)
		for m in ms:
			if not bool(m.get("down", false)) and int(m.get("hp", -1)) >= 0:
				m["hp"] = clampi(int(m.hp), 1, member_max_hp(m))
			m["en"] = clampi(int(m.get("en", 0)), 0, member_stats(m).max_en)
		lists[key] = ms
	patch({"fallen_hp": clampi(int(out.fallen_hp), 1, fallen_max_hp()),
		"fallen_en": clampi(int(out.fallen_en), 0, fallen_max_en()),
		"party": lists.party, "reserve": lists.reserve})
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
	# Só o Fallen: os aliados da luta são revividos pela própria batalha (D-111: aliado caído
	# fora da luta só volta pelo HEAL do santuário).
	s["fallen_hp"] = fallen_max_hp()
	s["fallen_en"] = fallen_max_en()
	_commit(s)
	return left
