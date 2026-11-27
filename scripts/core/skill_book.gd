class_name SkillBook
extends RefCounted

## Enemy skills of the first fight (docs/PROLOGUE_SCRIPT.md, creator 2026-11-22) and
## the absorption learning rule (creator 2026-11-23): every 4 absorptions of one enemy
## kind, Fallen (Deviron) permanently learns one random skill of that kind that he does
## not know yet and that does not use PP. With nothing left to learn the counter is MAX.

const ABSORBS_PER_SKILL := 4
## Creator 2026-11-23: one ATK stage = +25% ATK; stages stack, each lasting 1 full round.
const ATK_STAGE_BONUS := 0.25
## Heat wave burn: 3 damage at the start of each of the next 3 rounds; burns stack.
const BURN_DAMAGE := 3
const BURN_ROUNDS := 3

const LUNGE := &"lunge"
const BLEEDBUFF := &"bleedbuff"
const HEAT_WAVE := &"heat_wave"
const ENERGY_EAT := &"energy_eat"

## kind: strike (physical, one target), magic (all opponents), buff (self), heal (self).
## Lunge: two hits. Creator 2026-11-23: TWO normal bars, one per hit, one after the other
## ("it was never one bar"). Only the number of entries in `marks` is used (hits).
const DEFS := {
	&"lunge": {"name": "LUNGE", "acts": 1, "en": 4, "hp": 0, "pp": 0, "kind": "strike",
		"power": 5, "marks": [0.35, 0.65],
		"info": "LUNGE 1 ACT / 4 EN: power 5 physical hit, twice in one rhythm."},
	&"bleedbuff": {"name": "BLEEDBUFF", "acts": 2, "en": 0, "hp": 4, "pp": 0, "kind": "buff",
		"info": "BLEEDBUFF 2 ACT / 4 HP: +1 ATK stage (+25% ATK) for 1 full round."},
	&"heat_wave": {"name": "HEAT WAVE", "acts": 2, "en": 6, "hp": 0, "pp": 0, "kind": "magic",
		"power": 5, "burn_chance": 25,
		"info": "HEAT WAVE 2 ACT / 6 EN: power 5 IGNI magic, all foes, 25% burn (3/round x3)."},
	&"energy_eat": {"name": "ENERGEAT", "acts": 1, "en": 6, "hp": 0, "pp": 0, "kind": "heal",
		"heal": 5,
		"info": "ENERGEAT 1 ACT / 6 EN: heals 5 HP, +1 HP per extra EN spent."},
	# D-106 (creator 2026-11-25): rework of the 27 Survival skills, one signature effect each
	# ("fx"). Main-game skills above are untouched. Hit-effect values live in SkillFx.
	&"pixie_dust": {"name": "PIXIE DUST", "acts": 1, "en": 3, "hp": 0, "pp": 0, "kind": "magic",
		"power": 4, "burn_chance": 0, "fx": {"sleep_chance": 30},
		"info": "PIXIE DUST 1 ACT / 3 EN: power 4 magic, all foes; each foe has 30% to lose its next act (SLEEP)."},
	&"hellfire": {"name": "HELLFIRE", "acts": 2, "en": 7, "hp": 0, "pp": 0, "kind": "magic",
		"power": 8, "burn_chance": 35, "fx": {"burn_rounds": 5},
		"info": "HELLFIRE 2 ACT / 7 EN: power 8 flame magic, all foes, 35% burn lasting 5 rounds (INFERNO)."},
	&"howl": {"name": "HOWL", "acts": 1, "en": 4, "hp": 0, "pp": 0, "kind": "buff",
		"fx": {"stages": 1, "taunt": true},
		"info": "HOWL 1 ACT / 4 EN: +1 ATK stage and foes can only attack the user until the next round (TAUNT)."},
	&"primal_roar": {"name": "PRIMAL ROAR", "acts": 1, "en": 0, "hp": 3, "pp": 0, "kind": "buff",
		"fx": {"stages": 2, "status": "berserk", "rounds": 1},
		"info": "PRIMAL ROAR 1 ACT / 3 HP: +2 ATK stages, but DEF falls 25% for the round (BERSERK)."},
	&"mend": {"name": "MEND", "acts": 1, "en": 4, "hp": 0, "pp": 0, "kind": "heal",
		"heal": 8, "fx": {"cleanse": true},
		"info": "MEND 1 ACT / 4 EN: restores 8 HP to the user and cleanses its burns and bleeds."},
	&"dark_siphon": {"name": "DARK BOON", "acts": 2, "en": 7, "hp": 0, "pp": 0, "kind": "heal",
		"heal": 12, "fx": {"ally": true},
		"info": "DARK BOON 2 ACT / 7 EN: restores 12 HP to one ally of your choice."},
	# 15 novos placeholders do Survival (35 demônios). KIND_SKILLS da campanha segue intacto.
	# D-124 (criador 2026-11-27): 6 ataques canônicos + 2 evoluções ZAHAV. Cinco substituem skills antigas
	# do Survival (SHADOW BITE, FANG FLURRY, SOUL PIERCE, FROST BREATH, VOID GAZE). "power" é o poder da
	# fórmula normal de combate (poder x ATK/DEF, ou MAK/MEF se "magic"); "strike" = 1 alvo.
	&"mazz_bite": {"name": "MAZZ BITE", "acts": 1, "en": 0, "hp": 0, "grotesque": true, "hp_pct": 0.30, "pp": 0, "kind": "strike",
		"power": 10, "marks": [0.5], "high_speed": true, "fx": {"power_hp_pct": 0.30},
		"info": "MAZZ BITE 1 ACT / 30% max HP: HIGH SPEED physical hit, power 10 + 30% of the user's max HP. Needs more HP than the cost."},
	&"fang_sting": {"name": "FANG STING", "acts": 2, "en": 6, "hp": 0, "grotesque": true, "pp": 0, "kind": "strike",
		"power": 5, "marks": [0.5], "fx": {"bleed": 1, "bleed_point_only": true},
		"info": "FANG STING 2 ACT / 6 EN: power 5 physical hit; BLEED only when it lands on POINT."},
	&"fang_spine": {"name": "FANG SPINE", "acts": 3, "en": 10, "hp": 0, "grotesque": true, "pp": 0, "kind": "strike",
		"power": 15, "marks": [0.35, 0.65], "dual": true, "zahav": true, "zahav_of": &"fang_sting",
		"fx": {"bleed": 1, "bleed_point": 2},
		"info": "FANG SPINE (ZAHAV) 3 ACT / 10 EN: two power-15 hits on one or two foes; BLEED on contact, x2 on POINT."},
	&"vuln_pierce": {"name": "VULN PIERCE", "acts": 1, "en": 8, "hp": 0, "grotesque": true, "pp": 0, "kind": "strike",
		"power": 15, "marks": [0.5], "fx": {"vs_passive": 2.0},
		"info": "VULN PIERCE 1 ACT / 8 EN: power 15 physical hit, x2 against a target doing a non-offensive action."},
	&"dark_breath": {"name": "DARK BREATH", "acts": 3, "en": 15, "hp": 0, "grotesque": true, "pp": 0, "kind": "magic",
		"power": 0, "burn_chance": 0, "fx": {"no_damage": true, "pp_drain": 3, "status": "blind", "rounds": 1},
		"info": "DARK BREATH 3 ACT / 15 EN: no damage, all foes; each foe that does not dodge loses 3 PP and is blinded until the end of the round."},
	&"umbral_gaze": {"name": "UMBRAL GAZE", "acts": 3, "en": 15, "hp": 0, "grotesque": true, "pp": 0, "kind": "strike", "magic": true,
		"power": 15, "marks": [0.5], "fx": {"trap": 2},
		"info": "UMBRAL GAZE 3 ACT / 15 EN: power 15 magic on one foe; it is trapped for 2 global actions."},
	&"ignoma": {"name": "IGNOMA", "acts": 2, "en": 8, "hp": 0, "grotesque": true, "pp": 0, "kind": "strike", "magic": true,
		"power": 10, "marks": [0.5], "burn_chance": 35,
		"info": "IGNOMA 2 ACT / 8 EN: power 10 fire magic on one foe, 35% BURN."},
	&"ignoma_esh": {"name": "IGNOMA ESH", "acts": 3, "en": 12, "hp": 0, "grotesque": true, "pp": 0, "kind": "strike", "magic": true,
		"power": 10, "marks": [0.35, 0.65], "burn_chance": 35, "dual": true, "zahav": true, "zahav_of": &"ignoma",
		"info": "IGNOMA ESH (ZAHAV) 3 ACT / 12 EN: two power-10 fire balls on one or two foes, 35% BURN each."},
	# D-131 (criador 2026-11-27): Lote 2 canonico, taxonomia oficial ("cat": PHYS/MAGI/STAT, "dmg_type": PHYS/MAGI/DMG,
	# "targets": 1T/2T/3T). Substituem HEAVY CRUSH, FINISHING BLOW, LIFE DRAIN, CURSE RAY e SPIRIT BRAND do Survival.
	# "DMG" = dano sem tipagem (ignora DEF e MEF). As habilidades STAT usam uma passagem de ritmo sem dano ("no_damage").
	&"stone_crush": {"name": "STONE CRUSH", "acts": 4, "en": 0, "hp": 0, "grotesque": true, "pp": 0, "kind": "strike",
		"cat": "PHYS", "dmg_type": "PHYS", "targets": "1T", "power": 30, "marks": [0.5],
		"info": "STONE CRUSH 4 ACT / 0 EN (PHYS, 1T): a huge rock thrown at one foe, power 30 physical damage (+ATK)."},
	&"energy_blow": {"name": "ENERGY BLOW", "acts": 3, "en": 0, "hp": 0, "grotesque": true, "pp": 0, "kind": "strike", "magic": true,
		"cat": "MAGI", "dmg_type": "DMG", "targets": "1T", "power": 25, "marks": [0.5],
		"fx": {"cond": "vuln_or_quarter_hp", "steal_max_en_ratio": 0.5},
		"info": "ENERGY BLOW 3 ACT / 0 EN (MAGI, 1T): only on a vulnerable foe or one at 1/4 HP or less; power 25 untyped damage (+MAK, ignores DEF/MEF) and steals half of the foe's max EN until the end of the battle."},
	&"drain_claw": {"name": "DRAIN CLAW", "acts": 2, "en": 15, "hp": 0, "grotesque": true, "pp": 0, "kind": "strike",
		"cat": "PHYS", "dmg_type": "PHYS", "targets": "1T", "power": 15, "marks": [0.5], "zahav_to": &"vital_claws",
		"fx": {"drain_max_hp_ratio": 0.25, "boss_cap": 40, "heal_ratio": 0.8},
		"info": "DRAIN CLAW 2 ACT / 15 EN (PHYS, 1T): power 15 physical hit plus 1/4 of the foe's max HP (40 cap vs bosses); heals 80% of the HP drained (BLEED applies)."},
	&"vital_claws": {"name": "VITAL CLAWS", "acts": 3, "en": 25, "hp": 0, "grotesque": true, "pp": 0, "kind": "strike",
		"cat": "PHYS", "dmg_type": "PHYS", "targets": "1T", "power": 30, "marks": [0.5], "zahav": true, "zahav_of": &"drain_claw",
		"fx": {"drain_max_hp_ratio": 0.25, "boss_cap": 60, "heal_ratio": 0.8, "steal_en": 15},
		"info": "VITAL CLAWS (ZAHAV) 3 ACT / 25 EN (PHYS, 1T): power 30 physical hit plus 1/4 of the foe's max HP (60 cap vs bosses) and 15 EN; heals 80% of the HP drained."},
	&"weaken": {"name": "WEAKEN", "acts": 1, "en": 10, "hp": 0, "grotesque": true, "pp": 0, "kind": "strike",
		"cat": "STAT", "targets": "1T", "power": 0, "marks": [0.5], "zahav_to": &"weakenen",
		"fx": {"no_damage": true, "weaken_mef_base": 5, "weaken_mak_ratio": 0.5, "dispellable": true},
		"info": "WEAKEN 1 ACT / 10 EN (STAT, 1T): lowers the foe's MEF by 5 (+50% of your MAK) until the end of the battle; stacks up to -50% of its base MEF; dispellable."},
	&"weakenen": {"name": "WEAKENEN", "acts": 2, "en": 15, "hp": 0, "grotesque": true, "pp": 0, "kind": "strike",
		"cat": "STAT", "targets": "2T", "power": 0, "marks": [0.35, 0.65], "dual": true, "zahav": true, "zahav_of": &"weaken",
		"fx": {"no_damage": true, "weaken_mef_base": 10, "weaken_mak_base": 10, "weaken_mak_ratio": 0.5, "dispellable": true},
		"info": "WEAKENEN (ZAHAV) 2 ACT / 15 EN (STAT, 2T): lowers MAK and MEF of two distinct foes by 10 (+50% of your MAK) until the end of the battle; stacks up to -50%; dispellable."},
	&"mark_of_sun": {"name": "MARK OF SUN", "acts": 4, "en": 20, "hp": 0, "grotesque": true, "pp": 0, "kind": "strike",
		"cat": "STAT", "targets": "1T", "power": 0, "marks": [0.5],
		"fx": {"no_damage": true, "mark_of_sun_hits": 3, "mark_of_sun_magi": 20, "mark_of_sun_min": 5, "dispellable": true},
		"info": "MARK OF SUN 4 ACT / 20 EN (STAT, 1T): a sun over the foe; each hit it takes deals 20 MAGI extra (MEF mitigates, min 5) until the end of the next round or its 3rd hit."},
	&"twin_fang": {"name": "TWIN FANG", "acts": 2, "en": 5, "hp": 0, "pp": 0, "kind": "strike",
		"power": 5, "marks": [0.35, 0.65], "fx": {"combo": 0.5},
		"info": "TWIN FANG 2 ACT / 5 EN: power 5 physical hit, twice; if the first lands the second deals +50% (COMBO)."},
	&"war_cry": {"name": "WAR CRY", "acts": 2, "en": 6, "hp": 0, "pp": 0, "kind": "buff",
		"fx": {"stages": 1, "team": true},
		"info": "WAR CRY 2 ACT / 6 EN: +1 ATK stage for the user and every ally (TEAM)."},
	&"venom_cloud": {"name": "VENOM CLOUD", "acts": 2, "en": 6, "hp": 0, "pp": 0, "kind": "magic",
		"power": 6, "burn_chance": 0, "fx": {"status": "weaken", "rounds": 3, "chance": 40},
		"info": "VENOM CLOUD 2 ACT / 6 EN: power 6 magic, all foes; 40% to weaken a foe, its hits deal 20% less for 3 rounds (WEAKEN)."},
	&"mind_blast": {"name": "MIND DRAIN", "acts": 2, "en": 8, "hp": 0, "pp": 0, "kind": "magic",
		"power": 8, "burn_chance": 0, "fx": {"en_drain": 3},
		"info": "MIND DRAIN 2 ACT / 8 EN: power 8 psychic magic, all foes; each foe hit loses 3 EN, and with no EN it cannot use skills."},
	&"frost_lance": {"name": "FROST LANCE", "acts": 1, "en": 5, "hp": 0, "pp": 0, "kind": "strike",
		"power": 9, "marks": [0.5], "fx": {"status": "chill", "rounds": 2},
		"info": "FROST LANCE 1 ACT / 5 EN: power 9 cold strike; the target's next attack deals 25% less (CHILL)."},
	&"thunder_call": {"name": "THUNDER CALL", "acts": 2, "en": 9, "hp": 0, "pp": 0, "kind": "magic",
		"power": 10, "burn_chance": 0, "fx": {"storm": true},
		"info": "THUNDER CALL 2 ACT / 9 EN: power 10 lightning magic, all foes; each foe takes 1 or 2 bolts at random (STORM)."},
	&"spirit_wave": {"name": "SOUL LEECH", "acts": 1, "en": 4, "hp": 0, "pp": 0, "kind": "magic",
		"power": 5, "burn_chance": 0, "fx": {"leech": 2},
		"info": "SOUL LEECH 1 ACT / 4 EN: power 5 spirit magic, all foes; the user heals 2 HP per foe hit."},
	&"ember_touch": {"name": "EMBER BURST", "acts": 1, "en": 5, "hp": 0, "pp": 0, "kind": "magic",
		"power": 7, "burn_chance": 50, "fx": {"detonate": true},
		"info": "EMBER BURST 1 ACT / 5 EN: power 7 flame magic, all foes, 50% burn; a foe already burning takes its burn damage now (DETONATE)."},
	&"renew": {"name": "RENEW", "acts": 2, "en": 10, "hp": 0, "pp": 0, "kind": "heal",
		"heal": 0, "fx": {"regen": 6, "rounds": 3},
		"info": "RENEW 2 ACT / 10 EN: restores 6 HP at the start of each of the next 3 rounds (REGEN)."},
	&"blade_dance": {"name": "BLADE DANCE", "acts": 2, "en": 6, "hp": 0, "pp": 0, "kind": "strike",
		"power": 4, "powers": [3, 4, 5, 6], "marks": [0.25, 0.5, 0.75, 0.9],
		"info": "BLADE DANCE 2 ACT / 6 EN: four physical hits whose power climbs 3, 4, 5, 6."},
	&"stone_grasp": {"name": "STONE GRASP", "acts": 1, "en": 4, "hp": 0, "pp": 0, "kind": "strike",
		"power": 6, "marks": [0.5], "fx": {"status": "snare", "rounds": 2},
		"info": "STONE GRASP 1 ACT / 4 EN: power 6 earth strike; the target's AGI falls by 4 for 2 rounds (SNARE)."},
	# D-129 (creator 2026-11-27): 5 new Floater Eye support buff spells (1 full round, ally-targeted;
	# Floater Eyes never target themselves or other Floater Eyes).
	&"verdant_might": {"name": "VERDANT MIGHT", "acts": 1, "en": 8, "hp": 0, "pp": 0, "kind": "buff",
		"fx": {"ally_only": true, "atk_stages": 1, "mak_stages": 1},
		"info": "VERDANT MIGHT 1 ACT / 8 EN: raises an ally's ATK and MAK by 1 stage (+25% each) for 1 full round."},
	&"verdant_shell": {"name": "VERDANT SHELL", "acts": 1, "en": 8, "hp": 0, "pp": 0, "kind": "buff",
		"fx": {"ally_only": true, "def_stages": 1, "mef_stages": 1},
		"info": "VERDANT SHELL 1 ACT / 8 EN: raises an ally's DEF and MEF by 1 stage (+25% each) for 1 full round."},
	&"keen_gaze": {"name": "KEEN GAZE", "acts": 1, "en": 6, "hp": 0, "pp": 0, "kind": "buff",
		"fx": {"ally_only": true, "agi_bonus": 4, "high_speed_next": true},
		"info": "KEEN GAZE 1 ACT / 6 EN: +4 AGI for 1 full round and the ally's next attack gains HIGH SPEED."},
	&"ether_link": {"name": "ETHER LINK", "acts": 2, "en": 10, "hp": 0, "pp": 0, "kind": "buff",
		"fx": {"ally_only": true, "sp_bonus": 6},
		"info": "ETHER LINK 2 ACT / 10 EN: grants an ally +6 temporary SP for 1 full round."},
	&"aegis_iris": {"name": "AEGIS IRIS", "acts": 1, "en": 8, "hp": 0, "pp": 0, "kind": "buff",
		"fx": {"ally_only": true, "status_shield": true},
		"info": "AEGIS IRIS 1 ACT / 8 EN: shields an ally from status conditions for 1 full round."},
}

## Creator 2026-11-23: the current first-fight enemies keep their attributes and get the
## prologue skills (enemy 1 -> FOE A, enemy 2 -> FOE B).
## D-131: the five older Survival skills became the canonical ones; saved runs are migrated with this map.
const LEGACY_IDS := {
	&"spirit_bolt": &"mark_of_sun", &"curse_ray": &"weaken", &"heavy_crush": &"stone_crush",
	&"life_drain": &"drain_claw", &"crushing_blow": &"energy_blow",
}

const KIND_SKILLS := {
	&"genetic_foe_a": [&"lunge", &"bleedbuff"],
	&"genetic_foe_b": [&"heat_wave", &"energy_eat"],
}


## D-124 HIGH SPEED: the pointer of this attack runs 20% faster (also against the opponent's pointer in a counter).
const HIGH_SPEED_FACTOR := 1.2


static func is_high_speed(skill: StringName) -> bool:
	return bool(def(skill).get("high_speed", false))


## Bar seconds after HIGH SPEED (the base seconds when the attack is not HIGH SPEED).
static func bar_seconds(seconds: float, high_speed: bool) -> float:
	return seconds / HIGH_SPEED_FACTOR if high_speed else seconds


## D-131: a (possibly old) skill id as the current one.
static func migrate_id(skill: Variant) -> Variant:
	var id := StringName(str(skill))
	var current: StringName = LEGACY_IDS.get(id, id)
	return String(current) if skill is String else current


## D-131: a saved list of skill ids migrated (and without duplicates).
static func migrate_ids(skills: Array) -> Array:
	var result: Array = []
	for skill in skills:
		var id: Variant = migrate_id(skill)
		if not result.has(id):
			result.append(id)
	return result


static func def(skill: StringName) -> Dictionary:
	if DEFS.has(skill):
		return DEFS[skill]
	if PrayerBook.is_prayer(skill):
		return PrayerBook.as_skill_def(skill)
	return {}


static func display_name(skill: StringName) -> String:
	return String(def(skill).get("name", String(skill).to_upper()))


static func skills_of(kind: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	for skill in KIND_SKILLS.get(kind, []):
		result.append(StringName(skill))
	return result


## Skills of `kind` that can still be learned: not known yet and not using PP.
static func learnable(kind: StringName, known: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = []
	for skill in skills_of(kind):
		if int(def(skill).get("pp", 0)) > 0 or known.has(skill):
			continue
		result.append(skill)
	return result


## Can the skill be paid with these remaining resources? Bleedbuff needs more HP than
## its cost (creator 2026-11-23: with 4 HP or less it cannot be used).
static func affordable(skill: StringName, acts_left: int, en_left: int, hp_left: int, pp_left: int = 99, max_hp: int = 0) -> bool:
	var d := def(skill)
	if d.is_empty():
		return false
	if int(d.acts) > acts_left or int(d.en) > en_left or int(d.get("pp", 0)) > pp_left:
		return false
	var hp_cost := hp_cost_of(skill, max_hp)
	if hp_cost > 0 and hp_left <= hp_cost:
		return false
	return true


## D-124: HP the skill costs (a fixed amount, or a share of the max HP: MAZZ BITE 30%).
static func hp_cost_of(skill: StringName, max_hp: int) -> int:
	var d := def(skill)
	var cost := int(d.get("hp", 0))
	if float(d.get("hp_pct", 0.0)) > 0.0:
		cost += int(ceil(float(max_hp) * float(d.hp_pct)))
	return cost
