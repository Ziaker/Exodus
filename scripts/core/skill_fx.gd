class_name SkillFx
extends RefCounted
## D-106 (creator 2026-11-25): signature effects of the 27 Survival skills (SkillBook "fx").
## Pure rules, no scene dependencies; the controller calls these around each hit and each round.
## Every value here is a proposal awaiting the creator's judgment.

const CHILL_MULT := 0.75        # the chilled unit's next attack deals 25% less
const WEAKEN_MULT := 0.8        # a weakened unit's hits deal 20% less
const MARK_MULT := 1.25         # the next hit on a marked unit deals 25% more
const BLEED_DAMAGE := 2         # per bleed, per round
const BLEED_ROUNDS := 3
const BREAK_DEF := 0.25         # BREAK and BERSERK: DEF falls 25%
const SNARE_AGI := 4
const SLEEP_ID := &"sleep"
const MEND_HEAL := 5             # NECHAMAH: HP per mend per round (the opposite of a burn)
const MEND_ROUNDS := 3
const BLIND_ROUNDS := 2          # SANVERIM: until the end of the next round

## Statuses that only change a stat (restored when they end).
const STAT_STATUSES := [&"snare", &"break", &"berserk"]


## Adds (or refreshes) a status on `target`. Stat statuses change the stat at once.
static func apply_status(target: BattleUnit, id: StringName, rounds: int) -> void:
	var mod := {}
	if id == &"snare":
		mod = {"stat": "agi", "delta": -mini(SNARE_AGI, target.stats.agi - 1)}
	elif id == &"break" or id == &"berserk":
		mod = {"stat": "defense", "delta": -mini(int(float(target.stats.defense) * BREAK_DEF), target.stats.defense - 1)}
	target.add_status(id, rounds, mod)


## Multiplier on the damage of a hit by `attacker` (CHILL, WEAKEN).
static func out_mult(attacker: BattleUnit) -> float:
	var m := 1.0
	if attacker.has_status(&"chill"): m *= CHILL_MULT
	if attacker.has_status(&"weaken"): m *= WEAKEN_MULT
	return m


## CHILL ends with the first attack it weakens.
static func consume_attack(attacker: BattleUnit) -> void:
	if attacker.has_status(&"chill"):
		attacker.remove_status(&"chill")


## Multiplier on a hit that lands on `defender` (MARK, consumed by the hit).
static func in_mult(defender: BattleUnit) -> float:
	if defender.has_status(&"mark"):
		defender.remove_status(&"mark")
		return MARK_MULT
	return 1.0


## One round passes for `unit`: bleeds hurt, REGEN heals, every counter drops by one and
## the expired statuses fall off. Returns {"bleed": damage dealt, "regen": hp healed}.
static func tick(unit: BattleUnit) -> Dictionary:
	var result := {"bleed": 0, "regen": 0, "mend": 0}
	if not unit.is_alive():
		return result
	if not unit.bleeds.is_empty():
		result.bleed = unit.take_damage(BLEED_DAMAGE * unit.bleeds.size())
		for i in range(unit.bleeds.size() - 1, -1, -1):
			unit.bleeds[i] -= 1
			if unit.bleeds[i] <= 0:
				unit.bleeds.remove_at(i)
	if not unit.mends.is_empty() and unit.is_alive():
		result.mend = unit.heal(MEND_HEAL * unit.mends.size())
		for i in range(unit.mends.size() - 1, -1, -1):
			unit.mends[i] -= 1
			if unit.mends[i] <= 0:
				unit.mends.remove_at(i)
	if unit.regen_rounds > 0 and unit.is_alive():
		result.regen = unit.heal(unit.regen_amount)
		unit.regen_rounds -= 1
		if unit.regen_rounds <= 0:
			unit.regen_amount = 0
	for id in unit.statuses.keys():
		unit.statuses[id].rounds = int(unit.statuses[id].rounds) - 1
		if int(unit.statuses[id].rounds) <= 0:
			unit.remove_status(id)
	return result


## MEND: burns and bleeds go away.
static func cleanse(unit: BattleUnit) -> void:
	unit.burns.clear()
	unit.bleeds.clear()


## TAUNT: when a taunting unit is among the candidates, only it can be attacked.
static func taunter(candidates: Array) -> BattleUnit:
	for c in candidates:
		if (c as BattleUnit).is_alive() and (c as BattleUnit).has_status(&"taunt"):
			return c
	return null


## Which of a skill's "fx" keys it carries.
static func fx_of(skill: StringName) -> Dictionary:
	return SkillBook.def(skill).get("fx", {})


## Power of hit `index` (BLADE DANCE climbs); every other skill keeps one power.
static func hit_power(skill: StringName, index: int) -> int:
	var d := SkillBook.def(skill)
	if d.has("powers"):
		var powers: Array = d.powers
		return int(powers[clampi(index, 0, powers.size() - 1)])
	return int(d.get("power", 0))
