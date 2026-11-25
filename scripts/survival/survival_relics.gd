class_name SurvivalRelics
extends RefCounted
## Relíquias antigas equipáveis (máximo 2 por aliado). Dados puros + regras
## de equipamento; efeitos são bônus de atributo aplicados na criação do herói.

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

## As 6 primeiras são comuns; as outras desbloqueiam por score (SurvivalMeta).
const STARTER_IDS := ["shard_of_urim", "ashen_tablet", "iron_covenant",
	"veil_of_shem", "swift_sandal", "blood_vessel"]
const UNLOCK_SCORES := {"dry_well": 500, "seer_eye": 1000, "ember_tooth": 1800,
	"marrow_crown": 2800, "wanderer_oath": 4000, "ancient_echo": 5500}


static func relic(id: String) -> Dictionary:
	for entry in RELICS:
		if String(entry.id) == id:
			return entry
	return {}


static func available(unlocked: Array) -> Array[String]:
	var out: Array[String] = []
	out.assign(STARTER_IDS)
	for id in unlocked:
		if not out.has(String(id)) and not relic(String(id)).is_empty():
			out.append(String(id))
	return out


static func label(id: String) -> String:
	var r := relic(id)
	if r.is_empty():
		return id
	return "%s  %s" % [String(r.hebrew), String(r.info)]


static func apply(stats: UnitStats, id: String) -> void:
	var r := relic(id)
	if r.is_empty():
		return
	for stat in (r.effect as Dictionary).keys():
		var amount := int(r.effect[stat])
		match StringName(stat):
			&"max_hp": stats.max_hp += amount
			&"max_en": stats.max_en += amount
			&"atk": stats.atk += amount
			&"mak": stats.mak += amount
			&"defense": stats.defense += amount
			&"mef": stats.mef += amount
			&"agi": stats.agi += amount


static func bonus(equipped: Array, stat: String) -> int:
	var total := 0
	for id in equipped:
		var r := relic(String(id))
		if r.is_empty():
			continue
		total += int((r.effect as Dictionary).get(stat, 0))
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
