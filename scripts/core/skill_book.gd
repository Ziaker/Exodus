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
## Lunge marks: creator 2026-11-23, one rail with two hit zones at 35% and 65%.
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
