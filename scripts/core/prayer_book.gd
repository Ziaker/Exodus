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
## D-118: approved prayers & skills ported from prototype (2026-11-26).
const CHAKI := &"chaki"
const SHACHAR := &"shachar"
const LEHAVAH := &"lehavah"
const ESH_SINAI := &"esh_sinai"
const HASNEH_HABOER := &"hasneh_haboer"
const SHALHEVET := &"shalhevet"
const NOGAH := &"nogah"
const LIOR := &"lior"
## D-118 Lotes 2-4 (creator 2026-11-27): Esh/Meir/Ur Esh, Seraf/Nitzotz/Esh Ochelet/Gever, Gabriel skills.
const ESH := &"esh"
const MEIR := &"meir"
const UR_ESH := &"ur_esh"
const SERAF := &"seraf"
const NITZOTZ := &"nitzotz"
const ESH_OCHELET := &"esh_ochelet"
const GEVER := &"gever"
const ANGEL_HUG := &"angel_hug"
const GODS_MESSAGE := &"gods_message"
const ADIN := &"adin"
const ADINA := &"adina"
const ADINUT := &"adinut"

const ESH_BASE_DAMAGE := 20
const ESH_BURN_CHANCE := 30
const ESH_BURN_CHANCE_PER_PP := 10
const UR_ESH_BURNING_BONUS := 40
const SERAF_SP := 20
const NITZOTZ_DAMAGE := 20
const NITZOTZ_BURN_POWER := 10
const ESH_OCHELET_DAMAGE := 30
const GEVER_STAGES := 4
const ANGEL_HUG_ACTS := 3
const GODS_MESSAGE_STAGES := 3
## Skills that only appear in the menu by evolving from another one (next round after use).
const EVOLUTIONS := {&"esh": &"ur_esh", &"adin": &"adina", &"adina": &"adinut"}

const ESH_SINAI_HIT_DAMAGE := 30
const ESH_SINAI_FOLLOWUP_HITS := 3
const HASNEH_BUSH_HP := 10
## Canonical attack damage of Hasneh Habo'er's Burning Bush (12 base / 24 vs burning foes).
const HASNEH_BUSH_BASE_DAMAGE := 12
const SHALHEVET_BURN_CHANCE := 50
const LIOR_ACTIONS := 5

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
	# D-118 (creator 2026-11-26): visually approved prayers & angel/Gabriel skills.
	&"chaki": {"name": "Chaki", "hebrew": "חָכִי", "cost": 3, "acts": 3, "target": "enemy", "reactable": false, "extra": false,
		"info": "Chaki (3 PP / 3 ACT): binds one foe in a pillar of light, preventing actions until the end of the round."},
	&"shachar": {"name": "Shachar", "hebrew": "שַׁחַר", "cost": 3, "acts": 3, "target": "enemies", "reactable": false, "extra": false,
		"info": "Shachar (3 PP / 3 ACT): radiant dawn deals 30 + MAK damage to all foes at the start of the next round."},
	&"lehavah": {"name": "Lehavah", "hebrew": "לֶהָבָה", "cost": 3, "acts": 2, "target": "enemy", "reactable": false, "extra": false,
		"info": "Lehavah (3 PP / 2 ACT): light and fire explosion dealing 40 + MAK damage and blinding the foe until the end of the next round."},
	&"esh_sinai": {"name": "Esh Sinai", "hebrew": "אֵשׁ סִינַי", "cost": 6, "en": 40, "acts": 4, "target": "enemy", "reactable": false, "immediate": true, "extra": false, "angelic": true,
		"info": "Esh Sinai (6 PP or 40 EN / 4 ACT, IMMEDIATE): immediately deals 30 magic damage, then 3 successive 30-damage hits (reactable)."},
	&"hasneh_haboer": {"name": "Hasneh Habo'er", "hebrew": "הַסְּנֶה הַבֹּעֵר", "cost": 0, "en": 30, "acts": 4, "target": "self", "reactable": false, "extra": false, "gabriel": true,
		"info": "Hasneh Habo'er (30 EN / 4 ACT, Gabriel): summons a living Burning Bush (10 HP) whose attacks inflict BURN and deal 2x damage to burning targets."},
	&"shalhevet": {"name": "Shalhevet", "hebrew": "שַׁלְהֶבֶת", "cost": 4, "acts": 3, "target": "enemies", "reactable": false, "extra": false,
		"info": "Shalhevet (4 PP / 3 ACT): sweeping wave of fire dealing 30 + MAK damage to all foes with 50% chance to inflict BURN."},
	&"nogah": {"name": "Nogah", "hebrew": "נֹגַהּ", "cost": 2, "acts": 3, "target": "enemies", "reactable": false, "extra": false,
		"info": "Nogah (2 PP / 3 ACT): blinding starlight that blinds all foes until the end of the next round."},
	&"lior": {"name": "Lior", "hebrew": "לִיאוֹר", "cost": 2, "acts": 1, "target": "self", "reactable": false, "extra": true,
		"info": "Lior (2 PP / 1 ACT): light shroud around the caster healing 5 + 5 per PP over the next 5 actions."},
		# D-118 Lotes 2-4 (creator 2026-11-27).
		&"esh": {"name": "Esh", "hebrew": "אֵשׁ", "cost": 1, "acts": 2, "target": "enemy", "reactable": false, "extra": true,
			"info": "Esh (1 PP / 2 ACT): burns one foe for 20 + MAK - MEF, 30% (+10% per extra PP) chance of BURN."},
		&"meir": {"name": "Meir", "hebrew": "מֵאִיר", "cost": 2, "acts": 1, "target": "self", "reactable": false, "extra": false,
			"info": "Meir (2 PP / 1 ACT): taunt; every foe can only attack the caster until the end of the round."},
		&"ur_esh": {"name": "Ur Esh", "hebrew": "אוּר אֵשׁ", "cost": 3, "en": 15, "acts": 2, "target": "enemy", "reactable": false, "extra": false, "angelic": true,
			"info": "Ur Esh (3 PP or 15 EN / 2 ACT): 20 + MAK - MEF and a guaranteed BURN; +40 damage on a foe already burning. Esh evolves into it."},
		&"seraf": {"name": "Seraf", "hebrew": "שָׂרָף", "cost": 2, "en": 10, "acts": 2, "target": "self", "reactable": false, "extra": false, "angelic": true,
			"info": "Seraf (2 PP or 10 EN / 2 ACT): heals the caster by its MAK and grants +20 SP."},
		&"nitzotz": {"name": "Nitzotz", "hebrew": "נִיצוֹץ", "cost": 3, "en": 15, "acts": 2, "target": "enemy", "reactable": false, "extra": false, "angelic": true,
			"info": "Nitzotz (3 PP or 15 EN / 2 ACT): 20 magic damage to a BURNING foe and BURN rises to 10 damage per round."},
		&"esh_ochelet": {"name": "Esh Ochelet", "hebrew": "אֵשׁ אֹכֶלֶת", "cost": 5, "en": 30, "acts": 4, "target": "enemy", "reactable": false, "immediate": true, "extra": false, "angelic": true,
			"info": "Esh Ochelet (5 PP or 30 EN / 4 ACT, IMMEDIATE): 30 magic damage for every action the foe takes in its next turn; never interrupts."},
		&"gever": {"name": "Gever", "hebrew": "גֶּבֶר", "cost": 4, "en": 20, "acts": 3, "target": "self", "reactable": false, "extra": false, "angelic": true,
			"info": "Gever (4 PP or 20 EN / 3 ACT): +4 ATK stages until the end of the next round."},
		&"angel_hug": {"name": "Angel Hug", "hebrew": "מַלְאָךְ", "cost": 0, "en": 5, "acts": 2, "target": "enemy", "reactable": false, "immediate": true, "extra": false, "gabriel": true,
			"info": "Angel Hug (5 EN / 2 ACT, IMMEDIATE): paralyzes the target for 3 acts (it can neither act nor react)."},
		&"gods_message": {"name": "God's Message", "hebrew": "דְּבַר אֵל", "cost": 0, "en": 5, "acts": 1, "target": "enemy", "reactable": false, "immediate": true, "extra": false, "gabriel": true,
			"info": "God's Message (5 EN / 1 ACT, IMMEDIATE): on its next turn the target loses 3 stages of a random stat."},
		&"adin": {"name": "Adin", "hebrew": "עָדִין", "cost": 0, "en": 0, "acts": 2, "target": "self", "reactable": false, "extra": false, "gabriel": true,
			"info": "Adin (0 EN / 2 ACT): recovers 15 EN. Next round it evolves into Adina."},
		&"adina": {"name": "Adina", "hebrew": "עֲדִינָה", "cost": 0, "en": 0, "acts": 2, "target": "self", "reactable": false, "extra": false, "gabriel": true,
			"info": "Adina (0 EN / 2 ACT): recovers 25 EN and 25 HP. Next round it evolves into Adinut."},
		&"adinut": {"name": "Adinut", "hebrew": "עֲדִינוּת", "cost": 0, "en": 0, "acts": 1, "target": "self", "reactable": false, "immediate": true, "extra": false, "gabriel": true,
			"info": "Adinut (0 EN / 1 ACT, IMMEDIATE): recovers 30 EN and 30 HP at once."},
}
## Default campaign spells of Yoch (D-048).
const SPELL_ORDER: Array[StringName] = [&"refuah", &"haganah", &"raam"]
## All PrayerBook spells in display order (used when a unit declares its known spells via meta).
const ALL_BOOK_ORDER: Array[StringName] = [
	&"refuah", &"haganah", &"raam",
	&"tahorah", &"magen", &"gevurah", &"mishpat", &"zohar",
	&"sanverim", &"nechamah", &"cherav",
	&"chaki", &"shachar", &"lehavah", &"esh_sinai", &"hasneh_haboer",
	&"shalhevet", &"nogah", &"lior",
	&"esh", &"meir", &"ur_esh", &"seraf", &"nitzotz", &"esh_ochelet", &"gever",
	&"angel_hug", &"gods_message", &"adin",
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


static func targets_self(id: StringName) -> bool:
	return String(entry(id).get("target", "")) == "self"


static func en_cost(id: StringName) -> int:
	return int(entry(id).get("en", 0))


static func is_immediate(id: StringName) -> bool:
	return bool(entry(id).get("immediate", false))


## D-118: true when `unit` pays `id` in EN instead of PP (EN-only skills, or angelic spells cast by a non-praying unit).
static func uses_en(id: StringName, unit: BattleUnit) -> bool:
	var e := entry(id)
	if e.is_empty():
		return false
	var en := int(e.get("en", 0))
	if en <= 0:
		return false
	return int(e.get("cost", 0)) == 0 or (unit != null and not unit.prays)


## Spells that appear in a menu only through evolution (Adina, Adinut).
static func is_evolution_only(id: StringName) -> bool:
	return id == ADINA or id == ADINUT


## D-118 Esh: (20 + MAK - MEF) magic damage.
static func esh_damage(caster_mak: int, target_mef: int = 0) -> int:
	return maxi(0, ESH_BASE_DAMAGE + maxi(0, caster_mak) - maxi(0, target_mef))


## D-118 Esh: 30% BURN chance, +10% per extra PP (and +20% per ZAHAV boost, when it exists).
static func esh_burn_chance(extra_pp: int) -> int:
	return clampi(ESH_BURN_CHANCE + ESH_BURN_CHANCE_PER_PP * maxi(0, extra_pp), 0, 100)


## D-118 Ur Esh: (20 + MAK [+40 if already burning] - MEF) magic damage.
static func ur_esh_damage(caster_mak: int, target_mef: int, target_burning: bool) -> int:
	var raw := ESH_BASE_DAMAGE + maxi(0, caster_mak) + (UR_ESH_BURNING_BONUS if target_burning else 0)
	return maxi(0, raw - maxi(0, target_mef))


## D-118 Nitzotz: 20 magic damage (MEF applies).
static func nitzotz_damage(target_mef: int = 0) -> int:
	return maxi(0, NITZOTZ_DAMAGE - maxi(0, target_mef))


## D-118 Esh Ochelet: 30 magic damage per foe action (MEF applies).
static func esh_ochelet_damage(target_mef: int = 0) -> int:
	return maxi(0, ESH_OCHELET_DAMAGE - maxi(0, target_mef))


## D-118 Seraf: heals the caster by its MAK.
static func seraf_heal(caster_mak: int) -> int:
	return maxi(0, caster_mak)


## D-118 Adin chain: {"en", "hp"} recovered by Adin / Adina / Adinut.
static func adin_recovery(id: StringName) -> Dictionary:
	match id:
		ADIN:
			return {"en": 15, "hp": 0}
		ADINA:
			return {"en": 25, "hp": 25}
		ADINUT:
			return {"en": 30, "hp": 30}
	return {"en": 0, "hp": 0}


## D-112 Gevurah: +15% damage + 5% per extra PP on the ally's next attack.
static func gevurah_bonus(extra_pp: int) -> float:
	return 0.15 + 0.05 * float(maxi(0, extra_pp))


## D-112 Mishpat: damage equal to the foe's last dealt damage + 15.
static func mishpat_damage(target_last_damage: int) -> int:
	return maxi(0, target_last_damage) + 15


## D-118 Shachar: (30 + MAK - MEF) damage to every living foe at the start of the next round.
static func shachar_damage(caster_mak: int, target_mef: int = 0) -> int:
	var base := maxi(0, 30 + maxi(0, caster_mak) - maxi(0, target_mef))
	return base


## D-118 Lehavah: (40 + MAK - MEF) light-and-fire explosion damage on one foe (+ blind).
static func lehavah_damage(caster_mak: int, target_mef: int = 0) -> int:
	var base := maxi(0, 40 + maxi(0, caster_mak) - maxi(0, target_mef))
	return base


## D-118 Esh Sinai (creator 2026-11-26): immediate damage does NOT ignore defenses;
## each of the 4 strikes applies (30 - MEF).
static func esh_sinai_hit_damage(target_mef: int = 0) -> int:
	var base := maxi(0, ESH_SINAI_HIT_DAMAGE - maxi(0, target_mef))
	return base


## D-118 Hasneh Habo'er: Burning Bush deals 2x damage against an already burning target (12 base / 24 burning).
static func hasneh_bush_damage(target_burning: bool, base_dmg: int = HASNEH_BUSH_BASE_DAMAGE) -> int:
	var base := maxi(0, base_dmg)
	return base * 2 if target_burning else base


## D-118 Shalhevet: (30 + MAK - MEF) fire damage to every living foe (50% BURN).
static func shalhevet_damage(caster_mak: int, target_mef: int = 0) -> int:
	var base := maxi(0, 30 + maxi(0, caster_mak) - maxi(0, target_mef))
	return base


## D-118 Lior: heals 5 + 5 per PP allocated (base 2 PP = 15 HP) per action over 5 actions.
static func lior_heal(total_pp: int) -> int:
	return 5 + 5 * maxi(0, total_pp)


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
		"en": int(e.get("en", 0)),
		"hp": 0,
		"pp": int(e.get("cost", 0)),
		"immediate": bool(e.get("immediate", false)),
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


## Ra'am damage. Like ATTACK (creator 2026-11-23): SP roll, variation and critical;
## BEAM halving is applied by the caller like ATTACK.
## No effect at all against angels.
## Result keys: amount, base, crit, sp_roll, variation, angel.
static func raam_damage(extra_pp: int, caster_mak: int, caster_agi: int, target_mef: int,
		caster_sp: int, target_sp: int, target_race: StringName,
		rng: RandomNumberGenerator) -> Dictionary:
	var base := float(raam_base(extra_pp, caster_mak, target_mef))
	if target_race == ANGEL:
		return {"amount": 0, "base": base, "crit": false, "sp_roll": 0,
			"variation": 0.0, "angel": true}
	var difference := caster_sp - target_sp
	var sp_roll := BattleMath.sp_bonus_roll(difference, rng)  # D-108: só a vantagem soma
	var variation := rng.randf_range(-BattleMath.BASE_VARIATION, BattleMath.BASE_VARIATION)  # D-019
	var crit := BattleMath.critical_roll(caster_agi, caster_sp, target_sp, rng)
	var amount := maxf(0.0, base) + float(sp_roll)
	amount *= 1.0 + variation
	if crit:
		amount *= BattleMath.CRIT_MULTIPLIER
	return {"amount": maxi(0, int(round(amount))), "base": base, "crit": crit,
		"sp_roll": sp_roll, "variation": variation, "angel": false}


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
