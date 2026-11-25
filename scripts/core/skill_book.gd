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
	&"energy_eat": {"name": "ENERGY EAT", "acts": 1, "en": 6, "hp": 0, "pp": 0, "kind": "heal",
		"heal": 5,
		"info": "ENERGY EAT 1 ACT / 6 EN: heals 5 HP, +1 HP per extra EN spent."},
	# Placeholder skills for Survival Mode (20 SMT demons; main-game KIND_SKILLS untouched).
	&"pixie_dust": {"name": "PIXIE DUST", "acts": 1, "en": 3, "hp": 0, "pp": 0, "kind": "magic",
		"power": 4, "burn_chance": 15,
		"info": "PIXIE DUST 1 ACT / 3 EN: power 4 magic, all foes, 15% burn."},
	&"frost_breath": {"name": "FROST BREATH", "acts": 2, "en": 5, "hp": 0, "pp": 0, "kind": "magic",
		"power": 6, "burn_chance": 0,
		"info": "FROST BREATH 2 ACT / 5 EN: power 6 cold magic, all foes."},
	&"hellfire": {"name": "HELLFIRE", "acts": 2, "en": 7, "hp": 0, "pp": 0, "kind": "magic",
		"power": 8, "burn_chance": 35,
		"info": "HELLFIRE 2 ACT / 7 EN: power 8 flame magic, all foes, 35% burn."},
	&"spirit_bolt": {"name": "SPIRIT BOLT", "acts": 1, "en": 5, "hp": 0, "pp": 0, "kind": "magic",
		"power": 7, "burn_chance": 0,
		"info": "SPIRIT BOLT 1 ACT / 5 EN: power 7 spirit magic, all foes."},
	&"curse_ray": {"name": "CURSE RAY", "acts": 2, "en": 8, "hp": 0, "pp": 0, "kind": "magic",
		"power": 9, "burn_chance": 25,
		"info": "CURSE RAY 2 ACT / 8 EN: power 9 dark magic, all foes, 25% burn."},
	&"shadow_bite": {"name": "SHADOW BITE", "acts": 1, "en": 4, "hp": 0, "pp": 0, "kind": "strike",
		"power": 6, "marks": [0.35, 0.65],
		"info": "SHADOW BITE 1 ACT / 4 EN: power 6 physical hit, twice."},
	&"fang_flurry": {"name": "FANG FLURRY", "acts": 2, "en": 5, "hp": 0, "pp": 0, "kind": "strike",
		"power": 4, "marks": [0.25, 0.5, 0.75],
		"info": "FANG FLURRY 2 ACT / 5 EN: power 4 physical hit, three times."},
	&"heavy_crush": {"name": "HEAVY CRUSH", "acts": 2, "en": 5, "hp": 0, "pp": 0, "kind": "strike",
		"power": 11, "marks": [0.5],
		"info": "HEAVY CRUSH 2 ACT / 5 EN: power 11 heavy physical strike."},
	&"howl": {"name": "HOWL", "acts": 1, "en": 4, "hp": 0, "pp": 0, "kind": "buff",
		"info": "HOWL 1 ACT / 4 EN: +1 ATK stage (+25% ATK) for 1 full round."},
	&"primal_roar": {"name": "PRIMAL ROAR", "acts": 1, "en": 0, "hp": 3, "pp": 0, "kind": "buff",
		"info": "PRIMAL ROAR 1 ACT / 3 HP: +1 ATK stage (+25% ATK) for 1 full round."},
	&"mend": {"name": "MEND", "acts": 1, "en": 4, "hp": 0, "pp": 0, "kind": "heal",
		"heal": 8,
		"info": "MEND 1 ACT / 4 EN: restores 8 HP to the user."},
	&"dark_siphon": {"name": "DARK SIPHON", "acts": 2, "en": 7, "hp": 0, "pp": 0, "kind": "heal",
		"heal": 12,
		"info": "DARK SIPHON 2 ACT / 7 EN: restores 12 HP to the user."},
	# 15 novos placeholders do Survival (35 demônios). KIND_SKILLS da campanha segue intacto.
	&"soul_pierce": {"name": "SOUL PIERCE", "acts": 1, "en": 4, "hp": 0, "pp": 0, "kind": "strike",
		"power": 7, "marks": [0.5],
		"info": "SOUL PIERCE 1 ACT / 4 EN: power 7 physical strike."},
	&"twin_fang": {"name": "TWIN FANG", "acts": 2, "en": 5, "hp": 0, "pp": 0, "kind": "strike",
		"power": 5, "marks": [0.35, 0.65],
		"info": "TWIN FANG 2 ACT / 5 EN: power 5 physical hit, twice."},
	&"war_cry": {"name": "WAR CRY", "acts": 2, "en": 6, "hp": 0, "pp": 0, "kind": "buff",
		"info": "WAR CRY 2 ACT / 6 EN: +1 ATK stage (+25% ATK) for 1 full round."},
	&"venom_cloud": {"name": "VENOM CLOUD", "acts": 2, "en": 6, "hp": 0, "pp": 0, "kind": "magic",
		"power": 6, "burn_chance": 40,
		"info": "VENOM CLOUD 2 ACT / 6 EN: power 6 magic, all foes, 40% burn."},
	&"mind_blast": {"name": "MIND BLAST", "acts": 2, "en": 8, "hp": 0, "pp": 0, "kind": "magic",
		"power": 8, "burn_chance": 0,
		"info": "MIND BLAST 2 ACT / 8 EN: power 8 psychic magic, all foes."},
	&"frost_lance": {"name": "FROST LANCE", "acts": 1, "en": 5, "hp": 0, "pp": 0, "kind": "strike",
		"power": 9, "marks": [0.5],
		"info": "FROST LANCE 1 ACT / 5 EN: power 9 cold strike."},
	&"thunder_call": {"name": "THUNDER CALL", "acts": 2, "en": 9, "hp": 0, "pp": 0, "kind": "magic",
		"power": 10, "burn_chance": 20,
		"info": "THUNDER CALL 2 ACT / 9 EN: power 10 lightning magic, 20% burn."},
	&"life_drain": {"name": "LIFE DRAIN", "acts": 2, "en": 8, "hp": 0, "pp": 0, "kind": "heal",
		"heal": 16,
		"info": "LIFE DRAIN 2 ACT / 8 EN: restores 16 HP to the user."},
	&"spirit_wave": {"name": "SPIRIT WAVE", "acts": 1, "en": 4, "hp": 0, "pp": 0, "kind": "magic",
		"power": 5, "burn_chance": 0,
		"info": "SPIRIT WAVE 1 ACT / 4 EN: power 5 spirit magic, all foes."},
	&"crushing_blow": {"name": "CRUSHING BLOW", "acts": 2, "en": 7, "hp": 0, "pp": 0, "kind": "strike",
		"power": 13, "marks": [0.5],
		"info": "CRUSHING BLOW 2 ACT / 7 EN: power 13 heavy physical strike."},
	&"ember_touch": {"name": "EMBER TOUCH", "acts": 1, "en": 5, "hp": 0, "pp": 0, "kind": "magic",
		"power": 7, "burn_chance": 50,
		"info": "EMBER TOUCH 1 ACT / 5 EN: power 7 flame magic, 50% burn."},
	&"renew": {"name": "RENEW", "acts": 2, "en": 10, "hp": 0, "pp": 0, "kind": "heal",
		"heal": 20,
		"info": "RENEW 2 ACT / 10 EN: restores 20 HP to the user."},
	&"void_gaze": {"name": "VOID GAZE", "acts": 2, "en": 10, "hp": 0, "pp": 0, "kind": "magic",
		"power": 12, "burn_chance": 0,
		"info": "VOID GAZE 2 ACT / 10 EN: power 12 dark magic, all foes."},
	&"blade_dance": {"name": "BLADE DANCE", "acts": 2, "en": 6, "hp": 0, "pp": 0, "kind": "strike",
		"power": 4, "marks": [0.25, 0.5, 0.75, 0.9],
		"info": "BLADE DANCE 2 ACT / 6 EN: power 4 physical hit, four times."},
	&"stone_grasp": {"name": "STONE GRASP", "acts": 1, "en": 4, "hp": 0, "pp": 0, "kind": "strike",
		"power": 6, "marks": [0.5],
		"info": "STONE GRASP 1 ACT / 4 EN: power 6 earth strike."},
}

## Creator 2026-11-23: the current first-fight enemies keep their attributes and get the
## prologue skills (enemy 1 -> FOE A, enemy 2 -> FOE B).
const KIND_SKILLS := {
	&"genetic_foe_a": [&"lunge", &"bleedbuff"],
	&"genetic_foe_b": [&"heat_wave", &"energy_eat"],
}


static func def(skill: StringName) -> Dictionary:
	return DEFS.get(skill, {})


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
static func affordable(skill: StringName, acts_left: int, en_left: int, hp_left: int) -> bool:
	var d := def(skill)
	if d.is_empty():
		return false
	if int(d.acts) > acts_left or int(d.en) > en_left:
		return false
	if int(d.hp) > 0 and hp_left <= int(d.hp):
		return false
	return true
