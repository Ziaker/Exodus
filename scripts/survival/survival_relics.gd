class_name SurvivalRelics
extends RefCounted
## Relíquias antigas equipáveis (máximo 2 por aliado). Dados puros + regras de
## equipamento. Dois tipos: de atributo (bônus aplicado na criação do herói) e,
## desde a D-073, de efeito (perk que muda uma regra da run). Pares no mesmo
## aliado liberam pactos (COVENANTS).

const MAX_PER_ALLY := 2

const RELICS := [
	{"id": "shard_of_urim", "name": "SHARD OF URIM", "hebrew": "שבר אורים",
		"effect": {"atk": 3}, "info": "+3 ATK"},
	{"id": "ashen_tablet", "name": "ASHEN TABLET", "hebrew": "לוח אפר",
		"effect": {"mak": 3}, "info": "+3 MAK"},
	{"id": "iron_covenant", "name": "IRON COVENANT", "hebrew": "ברית ברזל",
		"effect": {"defense": 4}, "info": "+4 DEF"},
	{"id": "veil_of_shem", "name": "VEIL OF SHEM", "hebrew": "מסך שם",
		"effect": {"mef": 4}, "info": "+4 MEF"},
	{"id": "swift_sandal", "name": "SWIFT SANDAL", "hebrew": "סנדל מהיר",
		"effect": {"agi": 3}, "info": "+3 AGI"},
	{"id": "blood_vessel", "name": "BLOOD VESSEL", "hebrew": "כלי דם",
		"effect": {"max_hp": 20}, "info": "+20 HP"},
	{"id": "dry_well", "name": "DRY WELL", "hebrew": "באר יבשה",
		"effect": {"max_en": 8}, "info": "+8 EN"},
	{"id": "seer_eye", "name": "SEER EYE", "hebrew": "עין רואה",
		"effect": {"atk": 2, "mak": 2}, "info": "+2 ATK / +2 MAK"},
	{"id": "ember_tooth", "name": "EMBER TOOTH", "hebrew": "שן גחלת",
		"effect": {"atk": 2, "agi": 2}, "info": "+2 ATK / +2 AGI"},
	{"id": "marrow_crown", "name": "MARROW CROWN", "hebrew": "כתר מח",
		"effect": {"defense": 4, "mef": 4}, "info": "+4 DEF / +4 MEF"},
	{"id": "wanderer_oath", "name": "WANDERER'S OATH", "hebrew": "שבועת נודד",
		"effect": {"agi": 6, "defense": -2}, "info": "+6 AGI / -2 DEF"},
	{"id": "ancient_echo", "name": "ANCIENT ECHO", "hebrew": "הד קדום",
		"effect": {"mak": 5, "max_hp": 10}, "info": "+5 MAK / +10 HP"},
]

## D-073: relíquias com efeito (perk). Não dão atributo: mudam regras da run.
## Valem enquanto equipadas; as de batalha valem para o aliado que as usa.
const EFFECT_RELICS := [
	{"id": "golden_calf", "name": "GOLDEN CALF", "hebrew": "עגל זהב",
		"effect": {}, "perk": "macca_up", "info": "+50% MACCA from battles"},
	{"id": "prophet_scroll", "name": "PROPHET'S SCROLL", "hebrew": "מגילת נביא",
		"effect": {}, "perk": "absorb_four", "info": "Absorption offers 4 choices"},
	{"id": "burning_bush", "name": "BURNING BUSH", "hebrew": "סנה בוער",
		"effect": {}, "perk": "skill_chance", "info": "+25% new-skill chance"},
	{"id": "manna_jar", "name": "MANNA JAR", "hebrew": "צנצנת מן",
		"effect": {}, "perk": "victory_heal", "info": "Victory heals both allies 15 HP"},
	{"id": "aaron_rod", "name": "AARON'S ROD", "hebrew": "מטה אהרן",
		"effect": {}, "perk": "opening_stage", "info": "Holder opens battles +1 ATK stage"},
	{"id": "ark_shard", "name": "ARK SHARD", "hebrew": "רסיס ארון",
		"effect": {}, "perk": "yoch_pp", "info": "Yoch starts battles with +2 PP"},
	{"id": "shepherd_staff", "name": "SHEPHERD'S STAFF", "hebrew": "מקל רועה",
		"effect": {}, "perk": "item_boost", "info": "Healing items restore +50%"},
	{"id": "leviathan_scale", "name": "LEVIATHAN SCALE", "hebrew": "קשקש לויתן",
		"effect": {}, "perk": "burn_immune", "info": "Holder is immune to burns"},
	{"id": "raziel_book", "name": "BOOK OF RAZIEL", "hebrew": "ספר רזיאל",
		"effect": {}, "perk": "skill_chance_2", "info": "+25% new-skill chance"},
	{"id": "merchant_seal", "name": "MERCHANT SEAL", "hebrew": "חותם סוחר",
		"effect": {}, "perk": "shop_discount", "info": "Shop prices -25%"},
	{"id": "sling_of_david", "name": "SLING OF DAVID", "hebrew": "קלע דוד",
		"effect": {}, "perk": "giant_slayer", "info": "Holder +4 ATK/MAK vs ELITE/WARDEN"},
]

## D-073 pactos (bênçãos duplas do Hades): o par no MESMO aliado libera um
## terceiro efeito, em atributo e/ou perk.
const COVENANTS := [
	{"id": "wrath", "name": "WRATH", "pair": ["shard_of_urim", "ember_tooth"],
		"effect": {"atk": 4}, "perk": "", "info": "+4 ATK"},
	{"id": "prophecy", "name": "PROPHECY", "pair": ["ashen_tablet", "ancient_echo"],
		"effect": {"mak": 5}, "perk": "", "info": "+5 MAK"},
	{"id": "bastion", "name": "BASTION", "pair": ["iron_covenant", "marrow_crown"],
		"effect": {"defense": 4, "mef": 4}, "perk": "", "info": "+4 DEF / +4 MEF"},
	{"id": "exodus", "name": "EXODUS", "pair": ["swift_sandal", "wanderer_oath"],
		"effect": {"agi": 4, "defense": 2}, "perk": "", "info": "+4 AGI / +2 DEF"},
	{"id": "blood_pact", "name": "BLOOD PACT", "pair": ["blood_vessel", "manna_jar"],
		"effect": {"max_hp": 20}, "perk": "", "info": "+20 HP"},
	{"id": "mammon", "name": "MAMMON", "pair": ["golden_calf", "merchant_seal"],
		"effect": {}, "perk": "mammon", "info": "MACCA x2 / shop -50%"},
	{"id": "revelation", "name": "REVELATION", "pair": ["seer_eye", "raziel_book"],
		"effect": {}, "perk": "revelation", "info": "+20% more skill chance"},
]

## As 6 primeiras são comuns; as outras desbloqueiam por score (SurvivalMeta).
const STARTER_IDS := ["shard_of_urim", "ashen_tablet", "iron_covenant",
	"veil_of_shem", "swift_sandal", "blood_vessel"]
const UNLOCK_SCORES := {"dry_well": 500, "seer_eye": 1000, "ember_tooth": 1800,
	"marrow_crown": 2800, "wanderer_oath": 4000, "ancient_echo": 5500}


static func relic(id: String) -> Dictionary:
	for entry in RELICS:
		if String(entry.id) == id:
			return entry
	for entry in EFFECT_RELICS:
		if String(entry.id) == id:
			return entry
	return {}


static func all_ids() -> Array[String]:
	var out: Array[String] = []
	for entry in RELICS:
		out.append(String(entry.id))
	for entry in EFFECT_RELICS:
		out.append(String(entry.id))
	return out


static func available(unlocked: Array) -> Array[String]:
	var out: Array[String] = []
	out.assign(STARTER_IDS)
	for id in unlocked:
		if not out.has(String(id)) and not relic(String(id)).is_empty():
			out.append(String(id))
	return out


## D-073: a run começa com UMA relíquia inicial, sorteada pela semente.
static func starting_relic(seed: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = (absi(seed) + 9_176) % 2147483647
	return String(STARTER_IDS[rng.randi_range(0, STARTER_IDS.size() - 1)])


## Relíquias que ainda podem cair: iniciais + desbloqueadas pelo meta + todas as
## de efeito, menos as já possuídas.
static func drop_pool(owned: Array, unlocked: Array) -> Array[String]:
	var out: Array[String] = []
	for id in available(unlocked):
		if not owned.has(id):
			out.append(id)
	for entry in EFFECT_RELICS:
		var id := String(entry.id)
		if not owned.has(id) and not out.has(id):
			out.append(id)
	return out


## Sorteia até `count` relíquias distintas do pool (vazio se não sobrar nenhuma).
static func roll(rng: RandomNumberGenerator, owned: Array, unlocked: Array, count: int) -> Array[String]:
	var pool := drop_pool(owned, unlocked)
	var out: Array[String] = []
	while out.size() < count and not pool.is_empty():
		var i := rng.randi_range(0, pool.size() - 1)
		out.append(pool[i])
		pool.remove_at(i)
	return out


static func covenants(equipped: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in COVENANTS:
		var pair: Array = c.pair
		if equipped.has(pair[0]) and equipped.has(pair[1]):
			out.append(c)
	return out


## Perk presente nas relíquias (ou pactos) desta lista de equipadas.
static func has_perk(equipped: Array, perk: String) -> bool:
	for id in equipped:
		if String(relic(String(id)).get("perk", "")) == perk:
			return true
	for c in covenants(equipped):
		if String(c.perk) == perk:
			return true
	return false


## Perk em qualquer aliado da run (economia: Macca, loja, absorção).
static func party_has(state: Dictionary, perk: String) -> bool:
	return has_perk(state.get("fallen_relics", []), perk) \
			or has_perk(state.get("yoch_relics", []), perk)


static func name_of(id: String) -> String:
	return String(relic(id).get("name", id))


static func label(id: String) -> String:
	var r := relic(id)
	if r.is_empty():
		return id
	return "%s  %s" % [String(r.hebrew), String(r.info)]


static func apply(stats: UnitStats, id: String) -> void:
	var r := relic(id)
	if r.is_empty():
		return
	_apply_effect(stats, r.effect)


## Relíquias + pactos do aliado (é o que a batalha e o mapa usam).
static func apply_all(stats: UnitStats, equipped: Array) -> void:
	for id in equipped:
		apply(stats, String(id))
	for c in covenants(equipped):
		_apply_effect(stats, c.effect)


static func _apply_effect(stats: UnitStats, effect: Dictionary) -> void:
	for stat in effect.keys():
		var amount := int(effect[stat])
		match StringName(stat):
			&"max_hp": stats.max_hp += amount
			&"max_en": stats.max_en += amount
			&"atk": stats.atk += amount
			&"mak": stats.mak += amount
			&"defense": stats.defense += amount
			&"mef": stats.mef += amount
			&"agi": stats.agi += amount


## Soma das relíquias e dos pactos ativos no atributo pedido.
static func bonus(equipped: Array, stat: String) -> int:
	var total := 0
	for id in equipped:
		var r := relic(String(id))
		if r.is_empty():
			continue
		total += int((r.effect as Dictionary).get(stat, 0))
	for c in covenants(equipped):
		total += int((c.effect as Dictionary).get(stat, 0))
	return total


## Equipa alternando; a relíquia é única e muda de aliado ao ser equipada alhures.
static func toggle(equipped: Dictionary, who: String, id: String) -> Dictionary:
	var fallen: Array = equipped.get("fallen_relics", []).duplicate()
	var yoch: Array = equipped.get("yoch_relics", []).duplicate()
	var target := fallen if who == "fallen" else yoch
	var other := yoch if who == "fallen" else fallen
	if target.has(id):
		target.erase(id)
	elif target.size() < MAX_PER_ALLY:
		other.erase(id)
		target.append(id)
	return {"fallen_relics": fallen, "yoch_relics": yoch}
