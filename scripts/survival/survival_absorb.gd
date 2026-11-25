class_name SurvivalAbsorb
extends RefCounted
## Regras roguelike de absorção do Survival Mode, isoladas da batalha:
## 30% de vir uma habilidade nova; senão 3 opções de atributo (1..4 pontos),
## com a habilidade ocupando o lugar de uma dessas opções quando aparece.
## Tudo vem de um RNG semeado pela run, reproduzível para debug/daily.

const SKILL_CHANCE := 0.30
const MAX_POINTS := 4
const OPTION_COUNT := 3
const STAT_KEYS: Array[StringName] = [&"atk", &"mak", &"defense", &"mef", &"agi"]


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


static func shuffled_stats(rng: RandomNumberGenerator) -> Array[StringName]:
	var out := STAT_KEYS.duplicate()
	for i in range(out.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: StringName = out[i]
		out[i] = out[j]
		out[j] = tmp
	return out


## Três opções: [skill?] + atributos até completar OPTION_COUNT.
static func roll_options(rng: RandomNumberGenerator, demon: Dictionary,
		owned: Array[StringName], hp_share: float = 1.0) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var pool := available_skills(demon, owned)
	if rng.randf() < SKILL_CHANCE and not pool.is_empty():
		var skill: StringName = pool[rng.randi_range(0, pool.size() - 1)]
		out.append({"kind": "skill", "skill": skill,
			"label": "LEARN: %s" % SkillBook.display_name(skill)})
	# Risco/recompensa: com menos de 35% de HP o desespero garante +4.
	var desperate := hp_share < 0.35
	for stat in shuffled_stats(rng):
		if out.size() >= OPTION_COUNT:
			break
		var amount := MAX_POINTS if desperate else rng.randi_range(1, MAX_POINTS)
		out.append({"kind": "stat", "stat": stat, "amount": amount,
			"label": "+%d %s" % [amount, BattleMath.STAT_LABELS[stat]]})
	return out


## Aplicação pura (testável sem cena): altera status/ganhos/habilidades da run.
static func apply_option(stats: UnitStats, gains: Dictionary, skills: Array[StringName],
		option: Dictionary) -> void:
	if String(option.get("kind", "")) == "skill":
		var skill := StringName(option.get("skill", &""))
		if not skill == &"" and not skills.has(skill):
			skills.append(skill)
		return
	var stat := StringName(option.get("stat", &""))
	var amount := int(option.get("amount", 0))
	match stat:
		&"atk": stats.atk += amount
		&"mak": stats.mak += amount
		&"defense": stats.defense += amount
		&"mef": stats.mef += amount
		&"agi": stats.agi += amount
		_: return
	gains[String(stat)] = int(gains.get(String(stat), 0)) + amount
