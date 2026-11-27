class_name SurvivalAbsorb
extends RefCounted
## Regras roguelike de absorção do Survival Mode, isoladas da batalha.
## 30% de vir uma habilidade nova (relíquias sobem); o resto são atributos.
## D-071: cada oferta de atributo tem RARIDADE (COMMON/RARE/EPIC) cujo peso sobe
## por estrato; HP < 35% sobe um nível (risco/recompensa); a primeira oferta é um
## dos 2 atributos mais fortes do demônio (herança, como na fusão do SMT); HP e EN
## máximos entram no sorteio. D-111 (criador 2026-11-26): a absorção só melhora o Fallen (a oferta
## YOCH +n saiu; os aliados crescem a cada 2 lutas, SurvivalAllies.grow).
## Tudo vem de um RNG semeado pela run, reproduzível para debug/daily.

const SKILL_CHANCE := 0.30
const OPTION_COUNT := 3
const STAT_KEYS: Array[StringName] = [&"atk", &"mak", &"defense", &"mef", &"agi"]
const POOL_KEYS: Array[StringName] = [&"atk", &"mak", &"defense", &"mef", &"agi", &"max_hp", &"max_en"]
const RARITIES := ["COMMON", "RARE", "EPIC"]
## Pontos por raridade (combate: sorteado no intervalo; HP/EN: fixo).
const AMOUNTS := {
	"COMMON": {"stat": [1, 2], "max_hp": 6, "max_en": 3},
	"RARE": {"stat": [3, 4], "max_hp": 10, "max_en": 5},
	"EPIC": {"stat": [6, 6], "max_hp": 16, "max_en": 8},
}
const LABELS := {&"atk": "ATK", &"mak": "MAK", &"defense": "DEF", &"mef": "MEF",
	&"agi": "AGI", &"max_hp": "HP", &"max_en": "EN"}
## Maior ganho possível numa oferta (usado pelos testes e pela validação).
const MAX_POINTS := 6


## Chances de RARE e EPIC no estrato (o resto é COMMON).
static func rarity_weights(stratum: int) -> Dictionary:
	var s := clampi(stratum, 1, SurvivalStrata.COUNT)
	return {"RARE": 0.22 + 0.05 * float(s - 1), "EPIC": 0.04 + 0.04 * float(s - 1)}


static func roll_rarity(rng: RandomNumberGenerator, stratum: int, desperate: bool) -> String:
	var w := rarity_weights(stratum)
	var r := rng.randf()
	var tier := 0
	if r < float(w.EPIC):
		tier = 2
	elif r < float(w.EPIC) + float(w.RARE):
		tier = 1
	if desperate:
		tier = mini(tier + 1, 2)
	return String(RARITIES[tier])


static func available_skills(demon: Dictionary, owned: Array[StringName]) -> Array[StringName]:
	var pool: Array[StringName] = []
	# As habilidades do demônio absorvido vêm primeiro (tema do inimigo).
	for sk in demon.get("skills", []):
		var id := StringName(sk)
		if not owned.has(id) and not SkillBook.def(id).is_empty() and not pool.has(id):
			pool.append(id)
	for id in SurvivalData.SURVIVAL_SKILLS:
		if not owned.has(id) and not SkillBook.def(id).is_empty() and not pool.has(id):
			pool.append(id)
	return pool


## Os 2 atributos de combate mais fortes do demônio (empate: ordem de STAT_KEYS).
## D-129: Floater Eye herda EN (seu atributo de destaque) e AGI.
static func signature_stats(demon: Dictionary) -> Array[StringName]:
	if bool(demon.get("floater_eye", false)):
		return [&"max_en", &"agi"]
	var stats: Dictionary = demon.get("stats", {})
	var keys := STAT_KEYS.duplicate()
	keys.sort_custom(func(a: StringName, b: StringName) -> bool:
		var va := int(stats.get(String(a), 0))
		var vb := int(stats.get(String(b), 0))
		return va > vb if va != vb else STAT_KEYS.find(a) < STAT_KEYS.find(b))
	return [keys[0], keys[1]]


static func shuffled(rng: RandomNumberGenerator, keys: Array[StringName]) -> Array[StringName]:
	var out := keys.duplicate()
	for i in range(out.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: StringName = out[i]
		out[i] = out[j]
		out[j] = tmp
	return out


## Compatibilidade com o teste antigo (só os 5 atributos de combate).
static func shuffled_stats(rng: RandomNumberGenerator) -> Array[StringName]:
	return shuffled(rng, STAT_KEYS)


static func amount_for(rng: RandomNumberGenerator, stat: StringName, rarity: String) -> int:
	var table: Dictionary = AMOUNTS[rarity]
	if stat == &"max_hp" or stat == &"max_en":
		return int(table[String(stat)])
	var span: Array = table.stat
	return rng.randi_range(int(span[0]), int(span[1]))


static func _stat_option(rng: RandomNumberGenerator, stat: StringName, rarity: String,
		used: Array[StringName], who: String = "fallen") -> Dictionary:
	# Épico de combate: metade das vezes vira +3/+3 em dois atributos.
	if rarity == "EPIC" and STAT_KEYS.has(stat) and who == "fallen" and rng.randf() < 0.5:
		var second: StringName = &""
		for other in shuffled(rng, STAT_KEYS):
			if other != stat and not used.has(other):
				second = other
				break
		if second != &"":
			used.append(second)
			return {"kind": "stat2", "stats": [stat, second], "amount": 3, "rarity": rarity,
				"label": "+3 %s / +3 %s" % [LABELS[stat], LABELS[second]]}
	var amount := amount_for(rng, stat, rarity)
	return {"kind": "stat", "stat": stat, "amount": amount, "rarity": rarity,
		"label": "+%d %s" % [amount, LABELS[stat]]}


## Opções: [skill?] + atributos até completar `count` (3; 4 com PROPHET'S SCROLL).
## ctx: stratum (1..5), skill_bonus (0..1), count.
static func roll_options(rng: RandomNumberGenerator, demon: Dictionary,
		owned: Array[StringName], hp_share: float = 1.0, ctx: Dictionary = {}) -> Array[Dictionary]:
	var stratum := int(ctx.get("stratum", 1))
	var count := int(ctx.get("count", OPTION_COUNT))
	var out: Array[Dictionary] = []
	var pool := available_skills(demon, owned)
	var chance := SKILL_CHANCE + float(ctx.get("skill_bonus", 0.0))
	if rng.randf() < chance and not pool.is_empty():
		var pick_pool := pool
		# D-129: absorver um Floater Eye prioriza as magias de buff dele ainda não aprendidas.
		if bool(demon.get("floater_eye", false)):
			var own_skills: Array[StringName] = []
			for sk in demon.get("skills", []):
				var sid := StringName(sk)
				if not owned.has(sid) and not SkillBook.def(sid).is_empty():
					own_skills.append(sid)
			if not own_skills.is_empty():
				pick_pool = own_skills
		var skill: StringName = pick_pool[rng.randi_range(0, pick_pool.size() - 1)]
		out.append({"kind": "skill", "skill": skill, "rarity": "SKILL",
			"label": "LEARN: %s" % SkillBook.display_name(skill)})
	var desperate := hp_share < 0.35
	var used: Array[StringName] = []
	# Herança: um dos 2 atributos mais fortes do demônio vem primeiro.
	var sig := signature_stats(demon)
	var order: Array[StringName] = [sig[rng.randi_range(0, 1)]]
	for stat in shuffled(rng, POOL_KEYS):
		if not order.has(stat):
			order.append(stat)
	for stat in order:
		if out.size() >= count:
			break
		if used.has(stat):
			continue
		used.append(stat)
		out.append(_stat_option(rng, stat, roll_rarity(rng, stratum, desperate), used))
	return out


static func _add(stats: UnitStats, stat: StringName, amount: int) -> bool:
	match stat:
		&"atk": stats.atk += amount
		&"mak": stats.mak += amount
		&"defense": stats.defense += amount
		&"mef": stats.mef += amount
		&"agi": stats.agi += amount
		&"max_hp": stats.max_hp += amount
		&"max_en": stats.max_en += amount
		_: return false
	return true


## Aplicação pura (testável sem cena): altera status/ganhos/habilidades da run.
static func apply_option(stats: UnitStats, gains: Dictionary, skills: Array[StringName],
		option: Dictionary) -> void:
	var kind := String(option.get("kind", ""))
	match kind:
		"skill":
			var skill := StringName(option.get("skill", &""))
			if not skill == &"" and not skills.has(skill):
				skills.append(skill)
		"stat":
			var stat := StringName(option.get("stat", &""))
			var amount := int(option.get("amount", 0))
			if _add(stats, stat, amount):
				gains[String(stat)] = int(gains.get(String(stat), 0)) + amount
		"stat2":
			var amount := int(option.get("amount", 0))
			for s in option.get("stats", []):
				if _add(stats, StringName(s), amount):
					gains[String(s)] = int(gains.get(String(s), 0)) + amount
