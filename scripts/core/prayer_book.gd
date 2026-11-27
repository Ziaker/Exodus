class_name PrayerBook
extends RefCounted

## D-048: Yoch's prayer (Pray Points). Pure rules, no scene dependencies.
## Values from docs/COMBAT_SPEC.md §Reza and the creator's answers of 2026-11-23.

const PRAY := &"pray"
const REFUAH := &"refuah"
const HAGANAH := &"haganah"
const RAAM := &"raam"
## D-107: human prayers (internal id `"cherav"` kept for save compatibility; displayed as CHEREV).
const SANVERIM := &"sanverim"
const NECHAMAH := &"nechamah"
const CHEREV := &"cherav"
## D-112: five new Hebrew prayers defined by the creator (2026-11-26).
const TAHORAH := &"tahorah"
const MAGEN := &"magen"
const GEVURAH := &"gevurah"
const MISHPAT := &"mishpat"
const ZOHAR := &"zohar"
## D-118: approved prayers ported from prototype (2026-11-26).
const CHAKI := &"chaki"
const SHACHAR := &"shachar"

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

## target: "ally" (one ally), "allies" (all living allies), or "enemy" (one enemy).
## Enemies react only to "reactable" casts. `acts` defaults to 1; `extra` = accepts +1 PP in queue.
const SPELLS := {
	&"refuah": {"name": "Refuah", "hebrew": "רְפוּאָה", "cost": 2, "acts": 1, "target": "ally", "reactable": false, "extra": true,
		"info": "Refuah: heals one ally 20 HP, +10 per extra PP."},
	&"haganah": {"name": "Haganah", "hebrew": "הֲגָנָה", "cost": 2, "acts": 1, "target": "ally", "reactable": false, "extra": false,
		"info": "Haganah: shields one ally from status conditions for one round."},
	&"raam": {"name": "Ra'am", "hebrew": "רַעַם", "cost": 3, "acts": 1, "target": "enemy", "reactable": true, "extra": true,
		"info": "Ra'am: thunder on one foe, 10 + MAK + 10 per extra PP - MEF."},
	# D-112 (creator 2026-11-26): five new prayers.
	&"tahorah": {"name": "Tahorah", "hebrew": "טָהֳרָה", "cost": 2, "acts": 1, "target": "ally", "reactable": false, "extra": false,
		"info": "Tahorah (2 PP / 1 ACT): cleanses burns, bleeds and negative statuses from one ally."},
	&"magen": {"name": "Magen", "hebrew": "מָגֵן", "cost": 2, "acts": 2, "target": "allies", "reactable": false, "extra": false,
		"info": "Magen (2 PP / 2 ACT): raises all allies' physical DEF by 1 stage until the end of the next round."},
	&"gevurah": {"name": "Gevurah", "hebrew": "גְּבוּרָה", "cost": 1, "acts": 1, "target": "ally", "reactable": false, "extra": true,
		"info": "Gevurah (1 PP / 1 ACT): boosts one ally's next attack by +15%, +5% per extra PP."},
	&"mishpat": {"name": "Mishpat", "hebrew": "מִשְׁפָּט", "cost": 2, "acts": 2, "target": "enemy", "reactable": false, "extra": false,
		"info": "Mishpat (2 PP / 2 ACT): deals damage to one foe equal to the damage it dealt in its last action + 15."},
	&"zohar": {"name": "Zohar", "hebrew": "זֹהַר", "cost": 3, "acts": 1, "target": "ally", "reactable": false, "extra": false,
		"info": "Zohar (3 PP / 1 ACT): widens one ally's POINT zone until the end of the next round."},
	# D-107 (creator 2026-11-25): human prayers unified into PrayerBook.
	&"sanverim": {"name": "SANVERIM", "hebrew": "סַנְוֵרִים", "cost": 2, "acts": 1, "target": "enemy", "reactable": false, "extra": false,
		"info": "SANVERIM 2 PP: blinding light; until the end of the next round the target is more likely to miss (smaller POINT zone)."},
	&"nechamah": {"name": "NECHAMAH", "hebrew": "נֶחָמָה", "cost": 1, "acts": 1, "target": "ally", "reactable": false, "extra": false,
		"info": "NECHAMAH 1 PP: heals an ally 5 HP at the start of each of the next 3 rounds; mends stack."},
	&"cherav": {"name": "CHEREV", "hebrew": "חֶרֶב", "cost": 3, "acts": 1, "target": "enemies", "reactable": false, "extra": false,
		"info": "CHEREV 3 PP: a cut of light across every foe, 10 + MAK - MEF each."},
	# D-118 (creator 2026-11-26): Chaki & Shachar (visually approved and implemented).
	&"chaki": {"name": "Chaki", "hebrew": "חָכִי", "cost": 3, "acts": 3, "target": "enemy", "reactable": false, "extra": false,
		"info": "Chaki (3 PP / 3 ACT): binds one foe in a pillar of light, preventing actions until the end of the round."},
	&"shachar": {"name": "Shachar", "hebrew": "שַׁחַר", "cost": 3, "acts": 3, "target": "enemies", "reactable": false, "extra": false,
		"info": "Shachar (3 PP / 3 ACT): radiant dawn deals 30 + MAK damage to all foes at the start of the next round."},
}
## Default campaign spells of Yoch (D-048).
const SPELL_ORDER: Array[StringName] = [&"refuah", &"haganah", &"raam"]
## All PrayerBook spells in display order (used when a unit declares its known spells via meta).
const ALL_BOOK_ORDER: Array[StringName] = [
	&"refuah", &"haganah", &"raam",
	&"tahorah", &"magen", &"gevurah", &"mishpat", &"zohar",
	&"sanverim", &"nechamah", &"cherav",
	&"chaki", &"shachar",
]
## D-107: subset of human prayers also mirrored in SkillBook for enemy human AI.
const HUMAN_SPELLS := {
	&"sanverim": SPELLS[&"sanverim"],
	&"nechamah": SPELLS[&"nechamah"],
	&"cherav": SPELLS[&"cherav"],
}
## D-111 + D-112: prayer pool for recruited humans in Survival (all D-048/D-107/D-112 prayers except Ra'am).
const HUMAN_POOL_ORDER: Array[StringName] = [
	&"refuah", &"haganah", &"sanverim", &"nechamah", &"cherav",
	&"tahorah", &"magen", &"gevurah", &"mishpat", &"zohar",
]


static func is_book_spell(id: StringName) -> bool:
	return SPELLS.has(id)


static func is_human_spell(id: StringName) -> bool:
	return HUMAN_SPELLS.has(id)


static func is_prayer(id: StringName) -> bool:
	return id == PRAY or SPELLS.has(id) or HUMAN_SPELLS.has(id)


static func entry(id: StringName) -> Dictionary:
	if SPELLS.has(id):
		return SPELLS[id]
	return HUMAN_SPELLS.get(id, {})


static func human_pool_ids() -> Array[String]:
	var out: Array[String] = []
	for id in HUMAN_POOL_ORDER:
		out.append(String(id))
	return out


static func book_spell_ids() -> Array[String]:
	var out: Array[String] = []
	for id in ALL_BOOK_ORDER:
		out.append(String(id))
	return out


static func act_cost(id: StringName) -> int:
	if id == PRAY:
		return 1
	return int(entry(id).get("acts", 1))


static func accepts_extra_pp(id: StringName) -> bool:
	return bool(entry(id).get("extra", false))


static func targets_allies(id: StringName) -> bool:
	return String(entry(id).get("target", "")) == "allies"


static func targets_enemies(id: StringName) -> bool:
	return String(entry(id).get("target", "")) == "enemies"


## D-112 Gevurah: +15% damage + 5% per extra PP on the ally's next attack.
static func gevurah_bonus(extra_pp: int) -> float:
	return 0.15 + 0.05 * float(maxi(0, extra_pp))


## D-112 Mishpat: damage equal to the foe's last dealt damage + 15.
static func mishpat_damage(target_last_damage: int) -> int:
	return maxi(0, target_last_damage) + 15


## D-118 Shachar: 30 + MAK damage to every living foe at the start of the next round.
static func shachar_damage(caster_mak: int) -> int:
	return 30 + maxi(0, caster_mak)


## Single source of truth bridge for SkillBook/SkillFx/AI lookups of prayers.
static func as_skill_def(id: StringName) -> Dictionary:
	if id == PRAY:
		return {"name": "PRAY", "acts": 1, "en": 0, "hp": 0, "pp": 0, "kind": "prayer",
			"fx": {"pray": true}, "info": "PRAY 1 ACT: +1 PP."}
	var e := entry(id)
	if e.is_empty():
		return {}
	var fx := {}
	var kind := "prayer"
	var power := 0
	match id:
		SANVERIM:
			fx = {"blind": true}
		NECHAMAH:
			fx = {"mend": true}
		CHEREV:
			kind = "magic"
			power = 10
			fx = {"prayer_base": true}
	return {
		"name": String(e.get("name", String(id).to_upper())),
		"hebrew": String(e.get("hebrew", "")),
		"acts": int(e.get("acts", 1)),
		"en": 0,
		"hp": 0,
		"pp": int(e.get("cost", 0)),
		"kind": kind,
		"power": power,
		"burn_chance": 0,
		"fx": fx,
		"info": String(e.get("info", "")),
	}


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
