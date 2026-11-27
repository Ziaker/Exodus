class_name SkillFx
extends RefCounted
## D-106 (creator 2026-11-25): signature effects of the 27 Survival skills (SkillBook "fx").
## Pure rules, no scene dependencies; the controller calls these around each hit and each round.
## Every value here is a proposal awaiting the creator's judgment.

const CHILL_MULT := 0.75        # the chilled unit's next attack deals 25% less
const WEAKEN_MULT := 0.8        # a weakened unit's hits deal 20% less
const MARK_MULT := 1.25         # the next hit on a marked unit deals 25% more
## D-124 BLEED canônico: -20% of the healing received per stack, up to 4 stacks, until the end
## of the unit's next turn (read as 2 round ticks, like BLIND/MAGEN). No damage over time anymore.
const BLEED_HEAL_CUT := 0.20
const BLEED_MAX_STACKS := 4
const BLEED_ROUNDS := 2
const BREAK_DEF := 0.25         # BREAK and BERSERK: DEF falls 25%
const SNARE_AGI := 4
const SLEEP_ID := &"sleep"
const MEND_HEAL := 5             # NECHAMAH: HP per mend per round (the opposite of a burn)
const MEND_ROUNDS := 3
const BLIND_ROUNDS := 2          # SANVERIM: until the end of the next round
const MAGEN_ROUNDS := 2          # D-112 MAGEN: +1 physical DEF stage until the end of the next round
const ZOHAR_ROUNDS := 2          # D-112 ZOHAR: wider POINT zone until the end of the next round
## Negative statuses cleared by Tahorah (D-112). Positive buffs (taunt, zohar, etc.) are preserved.
const NEGATIVE_STATUSES: Array[StringName] = [&"blind", &"chill", &"weaken", &"mark", &"snare", &"break", &"sleep", &"slow", &"chaki", &"paralyzed", &"trapped", &"weaken_mef", &"weaken_mak", &"mark_of_sun"]
## D-131: WEAKEN / WEAKENEN cap (share of the base attribute) and MARK OF SUN defaults.
const WEAKEN_CAP := 0.5
const SUN_MARK_HITS := 3
const SUN_MARK_ROUNDS := 2
const SUN_MARK_MAGI := 20
const SUN_MARK_MIN := 5
const PERMANENT_ROUNDS := 9999    # "until the end of the battle"

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


## D-131 WEAKEN / WEAKENEN: lowers the target's MEF (and MAK when "weaken_mak_base" is set) by `base + 50% of the
## caster's MAK`, accumulating up to -50% of the base attribute (the effective value never falls under 1).
## Returns {"mef", "mak"}: the reduction actually added to each. Dispellable (cleanse_all).
static func apply_weaken(target: BattleUnit, caster: BattleUnit, fxd: Dictionary) -> Dictionary:
	var bonus := int(floor(caster.effective_mak() * float(fxd.get("weaken_mak_ratio", 0.5))))
	var result := {"mef": 0, "mak": 0}
	var mef_base := int(fxd.get("weaken_mef_base", 0))
	if mef_base > 0:
		var cap := int(floor(float(target.stats.mef) * WEAKEN_CAP))
		var next := mini(cap, target.weaken_mef_penalty + mef_base + bonus)
		result.mef = next - target.weaken_mef_penalty
		target.add_status(&"weaken_mef", PERMANENT_ROUNDS, {})
		target.weaken_mef_penalty = next
	var mak_base := int(fxd.get("weaken_mak_base", 0))
	if mak_base > 0:
		var cap_mak := int(floor(float(target.stats.mak) * WEAKEN_CAP))
		var next_mak := mini(cap_mak, target.weaken_mak_penalty + mak_base + bonus)
		result.mak = next_mak - target.weaken_mak_penalty
		target.add_status(&"weaken_mak", PERMANENT_ROUNDS, {})
		target.weaken_mak_penalty = next_mak
	return result


## D-131 MARK OF SUN: the extra MAGI damage one landed hit deals to a marked target (floor 5), 0 without a mark.
static func sun_mark_damage(defender: BattleUnit) -> int:
	if defender.sun_mark_hits <= 0:
		return 0
	return maxi(SUN_MARK_MIN, SUN_MARK_MAGI - defender.effective_mef())


## D-131 ENERGY BLOW `COND`: only on a vulnerable target or one with 1/4 of its max HP or less.
static func cond_met(skill: StringName, target: BattleUnit, defending: bool = false) -> bool:
	if String(fx_of(skill).get("cond", "")) != "vuln_or_quarter_hp":
		return true
	return target.is_vulnerable(defending) or target.current_hp * 4 <= target.stats.max_hp


## Multiplier on the damage of a hit by `attacker` (CHILL, WEAKEN, D-112 GEVURAH).
static func out_mult(attacker: BattleUnit) -> float:
	var m := 1.0
	if attacker.has_status(&"chill"): m *= CHILL_MULT
	if attacker.has_status(&"weaken"): m *= WEAKEN_MULT
	if attacker.gevurah_bonus > 0.0: m *= 1.0 + attacker.gevurah_bonus
	return m


## CHILL and GEVURAH end with the first attack they modify.
static func consume_attack(attacker: BattleUnit) -> void:
	if attacker.has_status(&"chill"):
		attacker.remove_status(&"chill")
	if attacker.gevurah_bonus > 0.0:
		attacker.gevurah_bonus = 0.0


## Multiplier on a hit that lands on `defender` (MARK, consumed by the hit).
static func in_mult(defender: BattleUnit) -> float:
	if defender.has_status(&"mark"):
		defender.remove_status(&"mark")
		return MARK_MULT
	return 1.0


## One round passes for `unit`: bleeds wear off, REGEN heals, every counter drops by one and
## the expired statuses fall off. Returns {"bleed": 0 (D-124: no damage), "regen": hp healed}.
static func tick(unit: BattleUnit) -> Dictionary:
	var result := {"bleed": 0, "regen": 0, "mend": 0}
	if not unit.is_alive():
		return result
	if not unit.bleeds.is_empty():
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
	for i in range(unit.def_stages.size() - 1, -1, -1):
		unit.def_stages[i] -= 1
		if unit.def_stages[i] <= 0:
			unit.def_stages.remove_at(i)
	for id in unit.statuses.keys():
		unit.statuses[id].rounds = int(unit.statuses[id].rounds) - 1
		if int(unit.statuses[id].rounds) <= 0:
			unit.remove_status(id)
	return result


## MEND: burns and bleeds go away.
static func cleanse(unit: BattleUnit) -> void:
	unit.burns.clear()
	unit.burn_power = 0
	unit.bleeds.clear()


## D-112 TAHORAH: clears burns, bleeds, and all negative statuses from one ally.
## Returns the total number of conditions removed.
static func cleanse_all(unit: BattleUnit) -> int:
	var removed := unit.burns.size() + unit.bleeds.size()
	unit.burns.clear()
	unit.burn_power = 0
	unit.bleeds.clear()
	for id in NEGATIVE_STATUSES:
		if unit.has_status(id):
			unit.remove_status(id)
			removed += 1
	unit.paralyzed_acts = 0
	unit.trapped_actions = 0
	# D-131: WEAKEN / WEAKENEN / MARK OF SUN are dispelled whole (their accumulators go with the status).
	unit.weaken_mef_penalty = 0
	unit.weaken_mak_penalty = 0
	unit.sun_mark_hits = 0
	unit.sun_mark_rounds = 0
	return removed


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
static func hit_power(skill: StringName, index: int, attacker: BattleUnit = null) -> int:
	var d := SkillBook.def(skill)
	if d.has("powers"):
		var powers: Array = d.powers
		return int(powers[clampi(index, 0, powers.size() - 1)])
	var power := int(d.get("power", 0))
	# D-124 MAZZ BITE: the power also carries a share of the user's max HP.
	var hp_share := float(fx_of(skill).get("power_hp_pct", 0.0))
	if hp_share > 0.0 and attacker != null:
		power += int(round(float(attacker.stats.max_hp) * hp_share))
	return power
