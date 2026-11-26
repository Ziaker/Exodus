class_name SurvivalAllies
extends RefCounted
## D-111 (criador 2026-11-26): aliados do Survival além do Yoch. Regras puras (sem cena): quem
## aparece no mapa, quem está à venda, oferta ao vencer, crescimento e a ficha de cada aliado.
## Especificação completa: docs/plans/2026-11-26-survival-aliados.md.
##
## Um aliado é um dicionário guardado na run (grupo ou reserva):
##   uid, kind ("demon" | "human" | "yoch"), id, name, picture, stats {7 atributos}, affinity,
##   skills [String], spells [String] (rezas do Yoch que ele conhece), hp, en, pp, down,
##   relics [String], fights, auto.

const PARTY_MAX := 2
const RESERVE_MAX := 8
## Oferta ao vencer: 25% das vitórias (pela semente da run).
const OFFER_CHANCE := 0.25
## Yoch: 15% por estrato.
const YOCH_CHANCE := 0.15
const YOCH_NOTICE := "YOCH IS SOMEWHERE IN THIS STRATUM"
## Arte do Yoch no mapa: o battler do Masakado pintado de amarelo chapado (criador 2026-11-26).
const YOCH_PICTURE := "res://assets/graphics/battlers/Zealot Masakado.png"
const YOCH_INK := Color(1.0, 0.86, 0.0)
## Encontros de recrutamento por estrato: 0 (15%), 1 (35%), 2 (35%), 3 (15%).
const ENCOUNTER_WEIGHTS := [15, 35, 35, 15]
## 75% demônio do estrato / 25% humano.
const DEMON_CANDIDATE_CHANCE := 0.75
const ENCOUNTER_KINDS := ["talk", "item", "money", "duel"]
const ITEM_REQUESTS := ["bead", "chakra", "medicine", "soma", "blast"]
## Crescimento: a cada 2 lutas terminadas de pé, +1 (65%) / +2 (20%) / +3 (15%) num atributo.
const GROWTH_EVERY := 2
const GROWTH_TABLE := [[1, 65], [2, 20], [3, 15]]
const STAT_KEYS := ["max_hp", "max_en", "atk", "mak", "defense", "mef", "agi"]
const STAT_LABELS := {"max_hp": "HP", "max_en": "EN", "atk": "ATK", "mak": "MAK",
	"defense": "DEF", "mef": "MEF", "agi": "AGI"}
## Humano recrutado (não o Yoch): 3 rezas do pool (rezas do Yoch + dos humanos + D-112), sem Ra'am.
const HUMAN_PRAYER_POOL := ["refuah", "haganah", "sanverim", "nechamah", "cherav",
	"tahorah", "magen", "gevurah", "mishpat", "zohar"]
const HUMAN_PRAYER_COUNT := 3
## Rezas que vêm do PrayerBook (agora todas as rezas humanas ficam no menu PRAY).
const BOOK_SPELLS := ["refuah", "haganah", "raam", "tahorah", "magen", "gevurah", "mishpat", "zohar",
	"sanverim", "nechamah", "cherav"]


static func _rng(seed: int, salt: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = (absi(seed) + salt) % 2147483647
	return r


# ------------------------------------------------------------------ fichas

static func stats_dict(stats: UnitStats) -> Dictionary:
	var out := {}
	for k in STAT_KEYS:
		out[k] = int(stats.get(k))
	return out


static func to_stats(d: Dictionary) -> UnitStats:
	var s := UnitStats.new()
	for k in STAT_KEYS:
		s.set(k, int(d.get(k, 0)))
	return s


static func sp_of(d: Dictionary) -> int:
	var total := 0
	for k in STAT_KEYS:
		total += int(d.get(k, 0))
	return total


## "Como na luta": a ficha da tabela ajustada ao SP do Fallen naquele estrato (D-101), sem elite
## nem OMEN. Vale para quem entra pelo santuário e pelo mapa.
static func stats_like_battle(id: String, fallen_sp: int) -> Dictionary:
	var def := SurvivalData.demon_by_id(id)
	if def.is_empty():
		return {}
	var s := to_stats(def.stats)
	var stratum := maxi(1, SurvivalStrata.stratum_of(id))
	SurvivalData.follow_hero(s, fallen_sp, SurvivalStrata.par_sp(stratum))
	return stats_dict(s)


static func is_human_id(id: String) -> bool:
	return SurvivalData.is_human_id(id)


## Ficha nova de aliado. `stats` já pronta; HP/EN cheios; PP 0 (como os humanos na luta).
static func new_member(uid: String, id: String, stats: Dictionary, seed: int = 0) -> Dictionary:
	var def := SurvivalData.demon_by_id(id)
	var human := is_human_id(id)
	var skills: Array = []
	var spells: Array = []
	if human:
		var picks := human_prayers(_rng(seed, absi(uid.hash()) + 77))
		for p in picks:
			if PrayerBook.is_book_spell(StringName(p)):
				spells.append(p)
			else:
				skills.append(p)
	else:
		for sk in def.get("skills", []):
			skills.append(String(sk))
	return {
		"uid": uid,
		"kind": "human" if human else "demon",
		"id": id,
		"name": String(def.get("name", id)),
		"picture": String(def.get("picture", "")),
		"stats": stats.duplicate(),
		"affinity": int(def.get("affinity", BattleMath.Affinity.NORMAL)),
		"skills": skills,
		"spells": spells,
		"hp": int(stats.get("max_hp", 1)),
		"en": int(stats.get("max_en", 0)),
		"pp": 0,
		"down": false,
		"relics": [],
		"fights": 0,
		"auto": false,
	}


static func yoch_member(uid: String) -> Dictionary:
	return {
		"uid": uid, "kind": "yoch", "id": "yoch", "name": "YOCH", "picture": YOCH_PICTURE,
		"stats": {}, "affinity": BattleMath.Affinity.NORMAL, "skills": [],
		"spells": ["refuah", "haganah", "raam"], "hp": -1, "en": 0,
		"pp": int(SurvivalData.YOCH_BASE.pp), "down": false, "relics": [], "fights": 0, "auto": false,
	}


static func human_prayers(rng: RandomNumberGenerator) -> Array:
	var pool: Array = PrayerBook.human_pool_ids()
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: String = pool[i]
		pool[i] = pool[j]
		pool[j] = t
	return pool.slice(0, HUMAN_PRAYER_COUNT)


## Yoch: sempre o mesmo SP do Fallen (criador 2026-11-26), repartido na proporção da ficha dele
## (sem EN: reza com PP). `fallen_sp` = SP da ficha completa do Fallen.
static func yoch_base_stats(fallen_sp: int) -> UnitStats:
	var base := SurvivalData.YOCH_BASE
	var keys := ["max_hp", "atk", "mak", "defense", "mef", "agi"]
	var own := 0
	for k in keys:
		own += int(base[k])
	var s := UnitStats.new()
	s.max_en = 0
	var spent := 0
	for k in keys:
		if k == "max_hp":
			continue
		var v := maxi(1, int(round(float(base[k]) * float(fallen_sp) / float(own))))
		s.set(k, v)
		spent += v
	s.max_hp = maxi(1, fallen_sp - spent)
	return s


## Ficha completa do aliado na batalha/mapa: base (ou a do Yoch) + relíquias e pactos dele.
static func member_stats(m: Dictionary, fallen_sp: int) -> UnitStats:
	var s: UnitStats
	if String(m.get("kind", "")) == "yoch":
		s = yoch_base_stats(fallen_sp)
	else:
		s = to_stats(m.get("stats", {}))
	SurvivalRelics.apply_all(s, m.get("relics", []))
	if String(m.get("kind", "")) in ["yoch", "human"]:
		s.max_en = 0
	return s


static func prays(m: Dictionary) -> bool:
	return String(m.get("kind", "")) in ["yoch", "human"]


# ------------------------------------------------------------------ mapa

## Yoch no estrato? 15% por estrato, pela semente.
static func yoch_in_stratum(seed: int, stratum: int) -> bool:
	return _rng(seed, stratum * 92_821 + 5).randf() < YOCH_CHANCE


static func encounter_count(seed: int, stratum: int) -> int:
	var r := _rng(seed, stratum * 31_607 + 11).randi_range(1, 100)
	var acc := 0
	for i in ENCOUNTER_WEIGHTS.size():
		acc += int(ENCOUNTER_WEIGHTS[i])
		if r <= acc:
			return i
	return 0


## Encontros de recrutamento do estrato nas células livres do layout (depois dos eventos).
## Cada um: {id, kind, candidate (id do demônio/humano), item (se pede item), cell}.
## A última célula livre fica para o Yoch quando ele está no estrato.
static func encounters(seed: int, stratum: int) -> Array:
	var spare: Array = SurvivalStrata.layout(seed, stratum).get("spare", [])
	var count := mini(encounter_count(seed, stratum), maxi(0, spare.size() - 1))
	var demons := SurvivalStrata.ids_for(stratum)
	demons.erase(SurvivalStrata.warden_of(stratum))
	var humans := SurvivalData.human_unit_ids(stratum)
	var out: Array = []
	for i in count:
		var r := _rng(seed, stratum * 7_919 + i * 104_729 + 23)
		var candidate := ""
		if r.randf() < DEMON_CANDIDATE_CHANCE:
			candidate = String(demons[r.randi_range(0, demons.size() - 1)])
		else:
			candidate = String(humans[r.randi_range(0, humans.size() - 1)])
		var kind := String(ENCOUNTER_KINDS[r.randi_range(0, ENCOUNTER_KINDS.size() - 1)])
		var entry := {"id": "s%d_r%d" % [stratum, i], "kind": kind, "candidate": candidate,
			"cell": spare[i]}
		if kind == "item":
			entry["item"] = String(ITEM_REQUESTS[r.randi_range(0, ITEM_REQUESTS.size() - 1)])
		out.append(entry)
	return out


static func yoch_cell(seed: int, stratum: int) -> Vector2i:
	var spare: Array = SurvivalStrata.layout(seed, stratum).get("spare", [])
	return spare[spare.size() - 1] if not spare.is_empty() else Vector2i(-1, -1)


# ------------------------------------------------------------------ santuário

## 2 demônios do estrato atual (sem guardião) para contratar, pela semente.
static func hire_stock(seed: int, stratum: int) -> Array[String]:
	var ids := SurvivalStrata.ids_for(stratum)
	ids.erase(SurvivalStrata.warden_of(stratum))
	var r := _rng(seed, stratum * 15_485_863 + 3)
	for i in range(ids.size() - 1, 0, -1):
		var j := r.randi_range(0, i)
		var t: String = ids[i]
		ids[i] = ids[j]
		ids[j] = t
	var out: Array[String] = []
	out.assign(ids.slice(0, 2))
	return out


## Contratar no santuário: SP × 2 Macca.
static func hire_price(stats: Dictionary) -> int:
	return sp_of(stats) * 2


## Quem pede dinheiro no mapa: SP × 1 Macca.
static func money_price(stats: Dictionary) -> int:
	return sp_of(stats)


# ------------------------------------------------------------------ batalha

## Oferta ao vencer (25% das vitórias), pela semente + número da luta.
static func offer_rolls(seed: int, battle_number: int) -> bool:
	return _rng(seed, battle_number * 2_750_159 + 41).randf() < OFFER_CHANCE


## Qual dos derrotados oferece (nunca anjo). -1 = nenhum elegível.
static func offer_pick(seed: int, battle_number: int, candidates: Array) -> int:
	var ok: Array[int] = []
	for i in candidates.size():
		var u: BattleUnit = candidates[i]
		if u != null and u.race != PrayerBook.ANGEL:
			ok.append(i)
	if ok.is_empty():
		return -1
	return ok[_rng(seed, battle_number * 3_571 + 43).randi_range(0, ok.size() - 1)]


## Crescimento: conta a luta e, a cada 2, sorteia +1/+2/+3 num atributo. Devolve {} ou
## {"stat", "amount"} (o dicionário do aliado já sai mudado). O Yoch não cresce: o SP dele é
## sempre o do Fallen.
static func grow(m: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if String(m.get("kind", "")) == "yoch":
		return {}
	m["fights"] = int(m.get("fights", 0)) + 1
	if int(m.fights) % GROWTH_EVERY != 0:
		return {}
	var keys: Array = STAT_KEYS.duplicate()
	if prays(m):
		keys.erase("max_en")
	var stat := String(keys[rng.randi_range(0, keys.size() - 1)])
	var roll := rng.randi_range(1, 100)
	var amount := 1
	var acc := 0
	for row in GROWTH_TABLE:
		acc += int(row[1])
		if roll <= acc:
			amount = int(row[0])
			break
	var st: Dictionary = m.get("stats", {})
	st[stat] = int(st.get(stat, 0)) + amount
	m["stats"] = st
	if stat == "max_hp":
		m["hp"] = int(m.get("hp", 0)) + amount
	elif stat == "max_en":
		m["en"] = int(m.get("en", 0)) + amount
	return {"stat": stat, "amount": amount}


static func growth_line(m: Dictionary, g: Dictionary) -> String:
	return "%s +%d %s" % [String(m.get("name", "?")), int(g.amount), String(STAT_LABELS.get(String(g.stat), g.stat))]
