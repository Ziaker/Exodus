class_name PrayerBook
extends RefCounted

## D-048: Yoch's prayer (Pray Points). Pure rules, no scene dependencies.
## Values from docs/COMBAT_SPEC.md §Reza and the creator's answers of 2026-11-23.

const PRAY := &"pray"
const REFUAH := &"refuah"
const HAGANAH := &"haganah"
const RAAM := &"raam"

const MAX_PP := 8
## Every current PP is worth +2 SP to the one praying (8 PP = +16 SP).
const SP_PER_PP := 2
## Creator 2026-11-23: each enemy with a reaction act attacks a PRAY 33% of the time,
## and an enemy struck by Ra'am counter-attacks 33% of the time.
const ENEMY_PRAY_REACTION_CHANCE := 0.33
const ENEMY_RAAM_COUNTER_CHANCE := 0.33
## Log and PP colour (#f5f58c).
const INK := Color("f5f58c")
## Race that Ra'am cannot affect (no angel exists yet; classification is PENDING).
const ANGEL := &"angel"

## target: "ally" (Fallen or Yoch) or "enemy". Enemies react only to "reactable" casts.
const SPELLS := {
	&"refuah": {"name": "Refuah", "hebrew": "רְפוּאָה", "cost": 2, "target": "ally", "reactable": false,
		"info": "Refuah: heals one ally 20 HP, +10 per extra PP."},
	&"haganah": {"name": "Haganah", "hebrew": "הֲגָנָה", "cost": 2, "target": "ally", "reactable": false,
		"info": "Haganah: shields one ally from status conditions for one round."},
	&"raam": {"name": "Ra'am", "hebrew": "רַעַם", "cost": 3, "target": "enemy", "reactable": true,
		"info": "Ra'am: thunder on one foe, 10 + MAK + 10 per extra PP - MEF."},
}
const SPELL_ORDER: Array[StringName] = [&"refuah", &"haganah", &"raam"]


static func spell(id: StringName) -> Dictionary:
	return SPELLS.get(id, {})


static func spell_name(id: StringName) -> String:
	return String(spell(id).get("name", String(id)))


static func base_cost(id: StringName) -> int:
	return int(spell(id).get("cost", 0))


static func targets_enemy(id: StringName) -> bool:
	return String(spell(id).get("target", "")) == "enemy"


static func enemies_react_to(id: StringName) -> bool:
	return id == PRAY or bool(spell(id).get("reactable", false))


## Spells whose base cost is at most `pp`, in menu order.
static func unlocked(pp: int) -> Array[StringName]:
	var result: Array[StringName] = []
	for id in SPELL_ORDER:
		if base_cost(id) <= pp:
			result.append(id)
	return result


## Refuah: fixed 20 HP + 10 per extra PP.
static func refuah_heal(extra_pp: int) -> int:
	return 20 + 10 * maxi(0, extra_pp)


## Ra'am base before the rhythm (creator 2026-11-23): 10 + total MAK + 10 per extra PP
## - the target's MEF.
static func raam_base(extra_pp: int, caster_mak: int, target_mef: int) -> int:
	return 10 + caster_mak + 10 * maxi(0, extra_pp) - target_mef


## Ra'am damage. Like ATTACK (creator 2026-11-23): SP roll, variation, critical and the
## affinity multiplier; BEAM halving and Press Turn are applied by the caller like ATTACK.
## No effect at all against angels.
## Result keys: amount, base, crit, affinity, sp_roll, variation, angel.
static func raam_damage(extra_pp: int, caster_mak: int, caster_agi: int, target_mef: int,
		caster_sp: int, target_sp: int, affinity: BattleMath.Affinity, target_race: StringName,
		rng: RandomNumberGenerator) -> Dictionary:
	var base := float(raam_base(extra_pp, caster_mak, target_mef))
	if target_race == ANGEL:
		return {"amount": 0, "base": base, "crit": false, "affinity": affinity, "sp_roll": 0,
			"variation": 0.0, "angel": true}
	var difference := caster_sp - target_sp
	var sp_roll := BattleMath.sp_bonus_roll(difference, rng)  # D-108: só a vantagem soma
	var variation := rng.randf_range(-BattleMath.BASE_VARIATION, BattleMath.BASE_VARIATION)  # D-019
	var crit := BattleMath.critical_roll(caster_agi, caster_sp, target_sp, rng)
	var amount := maxf(0.0, base) + float(sp_roll)
	amount *= 1.0 + variation
	if crit:
		amount *= BattleMath.CRIT_MULTIPLIER
	amount *= BattleMath.affinity_multiplier(affinity)
	return {"amount": maxi(0, int(round(amount))), "base": base, "crit": crit,
		"affinity": affinity, "sp_roll": sp_roll, "variation": variation, "angel": false}


## Projected PP after a planned queue, resolving in order. Each entry is a Dictionary
## {"cmd": "PRAY"} or {"spell": id, "cost": base + extras}; other commands are ignored.
## Returns {"pp": pp at the end, "ok": never needed more than it had}.
static func simulate(start_pp: int, queue: Array) -> Dictionary:
	var pp := start_pp
	var ok := true
	for entry in queue:
		var item: Dictionary = entry
		if String(item.get("cmd", "")) == "PRAY":
			pp = mini(MAX_PP, pp + 1)
		elif item.has("spell"):
			pp -= int(item.get("cost", 0))
			if pp < 0:
				ok = false
	return {"pp": pp, "ok": ok}
