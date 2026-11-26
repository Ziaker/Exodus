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
	# D-106 (creator 2026-11-25): rework of the 27 Survival skills, one signature effect each
	# ("fx"). Main-game skills above are untouched. Hit-effect values live in SkillFx.
	&"pixie_dust": {"name": "PIXIE DUST", "acts": 1, "en": 3, "hp": 0, "pp": 0, "kind": "magic",
		"power": 4, "burn_chance": 0, "fx": {"sleep_chance": 30},
		"info": "PIXIE DUST 1 ACT / 3 EN: power 4 magic, all foes; each foe has 30% to lose its next act (SLEEP)."},
	&"frost_breath": {"name": "FROST BREATH", "acts": 2, "en": 5, "hp": 0, "pp": 0, "kind": "magic",
		"power": 6, "burn_chance": 0, "fx": {"status": "slow", "rounds": 1},
		"info": "FROST BREATH 2 ACT / 5 EN: power 6 cold magic, all foes; they act last next round (SLOW)."},
	&"hellfire": {"name": "HELLFIRE", "acts": 2, "en": 7, "hp": 0, "pp": 0, "kind": "magic",
		"power": 8, "burn_chance": 35, "fx": {"burn_rounds": 5},
		"info": "HELLFIRE 2 ACT / 7 EN: power 8 flame magic, all foes, 35% burn lasting 5 rounds (INFERNO)."},
	&"spirit_bolt": {"name": "SPIRIT BRAND", "acts": 1, "en": 5, "hp": 0, "pp": 0, "kind": "magic",
		"power": 7, "burn_chance": 0, "fx": {"status": "mark", "rounds": 3},
		"info": "SPIRIT BRAND 1 ACT / 5 EN: power 7 spirit magic, all foes; the next hit on a branded foe deals +25% (MARK)."},
	&"curse_ray": {"name": "CURSE RAY", "acts": 2, "en": 8, "hp": 0, "pp": 0, "kind": "magic",
		"power": 9, "burn_chance": 0, "fx": {"sp_drain": 2},
		"info": "CURSE RAY 2 ACT / 8 EN: power 9 dark magic, all foes; each foe hit loses 2 SP (CURSE)."},
	&"shadow_bite": {"name": "SHADOW BITE", "acts": 1, "en": 4, "hp": 0, "pp": 0, "kind": "strike",
		"power": 6, "marks": [0.35, 0.65], "fx": {"steal_sp": 1},
		"info": "SHADOW BITE 1 ACT / 4 EN: power 6 physical hit, twice; each hit that lands steals 1 SP."},
	&"fang_flurry": {"name": "FANG FLURRY", "acts": 2, "en": 5, "hp": 0, "pp": 0, "kind": "strike",
		"power": 4, "marks": [0.25, 0.5, 0.75], "fx": {"bleed": 1},
		"info": "FANG FLURRY 2 ACT / 5 EN: power 4 physical hit, three times; each hit that lands adds a BLEED (2/round, 3 rounds, stacks)."},
	&"heavy_crush": {"name": "HEAVY CRUSH", "acts": 2, "en": 5, "hp": 0, "pp": 0, "kind": "strike",
		"power": 11, "marks": [0.5], "fx": {"status": "break", "rounds": 2},
		"info": "HEAVY CRUSH 2 ACT / 5 EN: power 11 heavy strike; the target's DEF falls 25% for 2 rounds (BREAK)."},
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
	&"soul_pierce": {"name": "SOUL PIERCE", "acts": 1, "en": 4, "hp": 0, "pp": 0, "kind": "strike",
		"power": 7, "marks": [0.5], "fx": {"pierce": 0.5},
		"info": "SOUL PIERCE 1 ACT / 4 EN: power 7 strike that ignores half of the target's DEF (PIERCE)."},
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
	&"life_drain": {"name": "LIFE DRAIN", "acts": 2, "en": 8, "hp": 0, "pp": 0, "kind": "strike",
		"power": 6, "marks": [0.5], "fx": {"lifesteal": 1.0},
		"info": "LIFE DRAIN 2 ACT / 8 EN: power 6 strike; the user heals as much HP as the damage dealt."},
	&"spirit_wave": {"name": "SOUL LEECH", "acts": 1, "en": 4, "hp": 0, "pp": 0, "kind": "magic",
		"power": 5, "burn_chance": 0, "fx": {"leech": 2},
		"info": "SOUL LEECH 1 ACT / 4 EN: power 5 spirit magic, all foes; the user heals 2 HP per foe hit."},
	&"crushing_blow": {"name": "FINISHING BLOW", "acts": 2, "en": 7, "hp": 0, "pp": 0, "kind": "strike",
		"power": 13, "marks": [0.5], "fx": {"execute": 1.5, "below": 0.4},
		"info": "FINISHING BLOW 2 ACT / 7 EN: power 13 strike, x1.5 against a target below 40% HP (EXECUTE)."},
	&"ember_touch": {"name": "EMBER BURST", "acts": 1, "en": 5, "hp": 0, "pp": 0, "kind": "magic",
		"power": 7, "burn_chance": 50, "fx": {"detonate": true},
		"info": "EMBER BURST 1 ACT / 5 EN: power 7 flame magic, all foes, 50% burn; a foe already burning takes its burn damage now (DETONATE)."},
	&"renew": {"name": "RENEW", "acts": 2, "en": 10, "hp": 0, "pp": 0, "kind": "heal",
		"heal": 0, "fx": {"regen": 6, "rounds": 3},
		"info": "RENEW 2 ACT / 10 EN: restores 6 HP at the start of each of the next 3 rounds (REGEN)."},
	&"void_gaze": {"name": "VOID GAZE", "acts": 2, "en": 10, "hp": 0, "pp": 0, "kind": "magic",
		"power": 12, "burn_chance": 0, "fx": {"unblockable": true},
		"info": "VOID GAZE 2 ACT / 10 EN: power 12 dark magic, all foes; it cannot be defended (UNBLOCKABLE)."},
	&"blade_dance": {"name": "BLADE DANCE", "acts": 2, "en": 6, "hp": 0, "pp": 0, "kind": "strike",
		"power": 4, "powers": [3, 4, 5, 6], "marks": [0.25, 0.5, 0.75, 0.9],
		"info": "BLADE DANCE 2 ACT / 6 EN: four physical hits whose power climbs 3, 4, 5, 6."},
	# D-107 (creator 2026-11-25): prayers of the human enemies. They cost PP, not EN; all are HOLY by
	# name only (HOLY has no mechanical effect yet) and have Hebrew names.
	&"pray": {"name": "PRAY", "acts": 1, "en": 0, "hp": 0, "pp": 0, "kind": "prayer",
		"fx": {"pray": true},
		"info": "PRAY 1 ACT: +1 PP."},
	&"sanverim": {"name": "SANVERIM", "hebrew": "סַנְוֵרִים", "acts": 1, "en": 0, "hp": 0, "pp": 2, "kind": "prayer",
		"fx": {"blind": true},
		"info": "SANVERIM 2 PP: blinding light; until the end of the next round the target is more likely to miss (smaller POINT zone)."},
	&"nechamah": {"name": "NECHAMAH", "hebrew": "נֶחָמָה", "acts": 1, "en": 0, "hp": 0, "pp": 1, "kind": "prayer",
		"fx": {"mend": true},
		"info": "NECHAMAH 1 PP: heals an ally 5 HP at the start of each of the next 3 rounds; mends stack."},
	&"cherav": {"name": "CHERAV", "hebrew": "חֶרֶב", "acts": 1, "en": 0, "hp": 0, "pp": 3, "kind": "magic",
		"power": 10, "burn_chance": 0, "fx": {"prayer_base": true},
		"info": "CHERAV 3 PP: a cut of light across every hero, 10 + MAK - MEF each."},
	&"stone_grasp": {"name": "STONE GRASP", "acts": 1, "en": 4, "hp": 0, "pp": 0, "kind": "strike",
		"power": 6, "marks": [0.5], "fx": {"status": "snare", "rounds": 2},
		"info": "STONE GRASP 1 ACT / 4 EN: power 6 earth strike; the target's AGI falls by 4 for 2 rounds (SNARE)."},
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
static func affordable(skill: StringName, acts_left: int, en_left: int, hp_left: int, pp_left: int = 99) -> bool:
	var d := def(skill)
	if d.is_empty():
		return false
	if int(d.acts) > acts_left or int(d.en) > en_left or int(d.get("pp", 0)) > pp_left:
		return false
	if int(d.hp) > 0 and hp_left <= int(d.hp):
		return false
	return true
