extends SceneTree
## D-124 (criador 2026-11-27), Fase 2: as 6 skills canônicas + 2 evoluções ZAHAV (mecânica, custos, alvos,
## dano, status) e a migração das 5 skills antigas do Survival. Sem VFX (Fases 3 a 5).
const SANDBOX := preload("res://tests/progress_sandbox.gd")
const R := BattleMath.RhythmResult
const NEW_IDS: Array[StringName] = [&"mazz_bite", &"fang_sting", &"fang_spine", &"vuln_pierce", &"dark_breath", &"umbral_gaze", &"ignoma", &"ignoma_esh"]
const OLD_IDS: Array[StringName] = [&"shadow_bite", &"fang_flurry", &"soul_pierce", &"frost_breath", &"void_gaze"]

class FxBattle extends "res://scripts/battle/playable_controller.gd":
	var roll := true
	var ai_result: int = BattleMath.RhythmResult.POINT
	func _ai_roll(_a: BattleUnit, _b: BattleUnit) -> int: return ai_result
	func _defender_reaction(_a: BattleUnit, _b: BattleUnit) -> int: return BattleMath.RhythmResult.MISS
	func _zone_roll(_h: float) -> int: return BattleMath.RhythmResult.MISS
	func _enemy_counter_roll(_e: BattleUnit) -> bool: return false
	func _fx_roll(_c: int) -> bool: return roll
	func _burn_roll(_c: int) -> bool: return roll

var checks := 0
var b: FxBattle
var hero: BattleUnit
var ally: BattleUnit
var foe: BattleUnit
var foe2: BattleUnit


func _initialize() -> void:
	SANDBOX.begin()
	call_deferred("_run")


func check(ok: bool, reason: String) -> void:
	if not ok:
		push_error("FAIL: " + reason)
		quit(1)
		assert(ok, reason)
	checks += 1


func reset() -> void:
	for u in [hero, ally, foe, foe2]:
		u.statuses.clear()
		u.bleeds.clear()
		u.burns.clear()
		u.haganah = {}
		u.trapped_actions = 0
		u.passive_stance = false
		u.stats.max_hp = 1000
		u.current_hp = 1000
		u.stats.defense = 10
		u.stats.mef = 10
		u.stats.atk = 20
		u.stats.mak = 20
		u.current_en = 40
		u.stats.max_en = 40
		u.current_sp = 100
	hero.acts_available = 4
	b.roll = true
	b.ai_result = R.POINT
	b._hit_mods = {}
	b._second_target = null
	b._defender_defending = false


## One skill hit with explicit timings; returns the HP removed from the defender.
func h(who: BattleUnit, at: BattleUnit, skill: StringName, attack: int = R.POINT, defense: int = R.MISS, idx: int = 0) -> int:
	b.rng.seed = 7
	var before := at.current_hp
	var d := SkillBook.def(skill)
	var magic := bool(d.get("magic", false)) or String(d.kind) == "magic"
	b._skill_hit_fx(who, at, skill, idx, false, attack, defense, magic, -1)
	return before - at.current_hp


func _run() -> void:
	b = FxBattle.new()
	b.offer_reserve = true
	root.add_child(b)
	for _i in 20:
		await process_frame
	hero = b._fallen
	ally = b._ally
	foe = b.hud.opponents[0]
	foe2 = b.hud.opponents[1]
	reset()
	_catalog()
	_mazz_bite()
	_fang_sting()
	await _fang_spine()
	_vuln_pierce()
	_dark_breath()
	_umbral_gaze()
	await _ignoma()
	print("VERIFY_D124_SKILLS_OK: %d checks; 6 skills + 2 ZAHAV (Mazz Bite 30%% HP, Fang Sting/Spine BLEED rules, Vuln Pierce x2, Dark Breath 0 dmg -3 PP BLIND, Umbral Gaze trap, Ignoma/Ignoma Esh), Survival migration" % checks)
	b.queue_free()
	quit(0)


# --------------------------------------------------------------------------- catálogo e migração
func _catalog() -> void:
	var expect := {
		&"mazz_bite": [1, 0, "strike"], &"fang_sting": [2, 6, "strike"], &"fang_spine": [3, 10, "strike"],
		&"vuln_pierce": [1, 8, "strike"], &"dark_breath": [3, 15, "magic"], &"umbral_gaze": [3, 15, "strike"],
		&"ignoma": [2, 8, "strike"], &"ignoma_esh": [3, 12, "strike"]}
	for id in NEW_IDS:
		var d := SkillBook.def(id)
		check(not d.is_empty() and int(d.acts) == expect[id][0] and int(d.en) == expect[id][1] and String(d.kind) == expect[id][2],
			"%s: %d ACT / %d EN / %s" % [id, expect[id][0], expect[id][1], expect[id][2]])
		check(String(d.info).begins_with(String(d.name)), "%s: the description starts with its name" % id)
	for id in OLD_IDS:
		check(SkillBook.def(id).is_empty(), "%s is gone from the SkillBook (replaced by D-124)" % id)
		check(not SurvivalData.SURVIVAL_SKILLS.has(id), "%s is gone from the Survival pool" % id)
		for demon in SurvivalData.DEMONS:
			check(not demon.skills.has(id), "%s does not stay in the loadout of %s" % [id, demon.id])
	for id in [&"mazz_bite", &"fang_sting", &"vuln_pierce", &"dark_breath", &"umbral_gaze", &"ignoma"]:
		check(SurvivalData.SURVIVAL_SKILLS.has(id), "%s is in the Survival pool" % id)
	for id in [&"fang_spine", &"ignoma_esh"]:
		check(bool(SkillBook.def(id).zahav) and not SurvivalData.SURVIVAL_SKILLS.has(id), "%s is a ZAHAV evolution, not a pool skill" % id)
	check(SkillBook.def(&"fang_spine").zahav_of == &"fang_sting" and SkillBook.def(&"ignoma_esh").zahav_of == &"ignoma", "ZAHAV evolutions point at their base skill")
	check(SurvivalData.SURVIVAL_SKILLS.size() == 27, "the pool has 27 skills (D-139 removed frost_lance)")
	for id in [&"lunge", &"bleedbuff", &"heat_wave", &"energy_eat"]:
		check(not SkillBook.def(id).is_empty() and not SkillBook.def(id).has("zahav"), "%s (Prologue) is untouched" % id)
	check(SkillBook.is_high_speed(&"mazz_bite") and not SkillBook.is_high_speed(&"fang_sting"), "only MAZZ BITE is HIGH SPEED")
	check(bool(SkillBook.def(&"umbral_gaze").magic) and bool(SkillBook.def(&"ignoma").magic) and not bool(SkillBook.def(&"fang_sting").get("magic", false)),
		"UMBRAL GAZE / IGNOMA are single-target magic; FANG STING is physical")
	check(String(SkillBook.def(&"dark_breath").kind) == "magic" and SkillBook.def(&"dark_breath").get("dual", false) == false, "DARK BREATH keeps the all-foes magic path")


# --------------------------------------------------------------------------- Mazz Bite
func _mazz_bite() -> void:
	check(SkillBook.hp_cost_of(&"mazz_bite", 100) == 30 and SkillBook.hp_cost_of(&"mazz_bite", 38) == 12, "MAZZ BITE costs 30%% of the max HP (rounded up): 100 -> 30, 38 -> 12")
	check(SkillBook.hp_cost_of(&"lunge", 100) == 0 and SkillBook.hp_cost_of(&"bleedbuff", 100) == 4, "fixed HP costs are unchanged (BLEEDBUFF 4)")
	check(SkillBook.affordable(&"mazz_bite", 1, 0, 31, 99, 100), "MAZZ BITE with HP 31 of 100 can be used")
	check(not SkillBook.affordable(&"mazz_bite", 1, 0, 30, 99, 100), "MAZZ BITE needs HP > cost: HP 30 of 100 is refused")
	check(not SkillBook.affordable(&"mazz_bite", 1, 0, 10, 99, 100), "MAZZ BITE at low HP is refused (no automatic suicide)")
	check(not SkillBook.affordable(&"mazz_bite", 0, 0, 90, 99, 100), "MAZZ BITE still needs its ACT")
	reset()
	hero.stats.max_hp = 100
	hero.current_hp = 100
	b._pay_skill(hero, &"mazz_bite", 0)
	check(hero.current_hp == 70 and hero.acts_available == 3 and hero.current_en == 40, "paying MAZZ BITE: -30 HP (30%%), -1 ACT, no EN")
	check(SkillFx.hit_power(&"mazz_bite", 0, hero) == 40, "power = 10 + 30%% of the max HP (100) = 40")
	hero.stats.max_hp = 1000
	var low := SkillFx.hit_power(&"mazz_bite", 0, null)
	check(low == 10 and SkillFx.hit_power(&"mazz_bite", 0, hero) == 310, "without the user the power is 10; with 1000 max HP it is 310")
	reset()
	var big := h(hero, foe, &"mazz_bite")
	check(big > 0, "MAZZ BITE hurts (%d)" % big)
	# normal DEF still applies (it does not pierce)
	reset(); foe.stats.defense = 40
	var armored := h(hero, foe, &"mazz_bite")
	check(armored < big, "MAZZ BITE does not ignore DEF (%d vs %d)" % [armored, big])
	# the plan counts the percentage cost
	b.active_actor = hero
	b._planned_skills.clear()
	b._planned_skills.append({"skill": &"mazz_bite"})
	check(b._planned_hp() == 300, "the plan counts 30%% of the max HP (1000 -> 300)")
	b._planned_skills.clear()


# --------------------------------------------------------------------------- Fang Sting
func _fang_sting() -> void:
	reset()
	h(hero, foe, &"fang_sting", R.POINT)
	check(foe.bleeds.size() == 1, "FANG STING on POINT adds 1 BLEED")
	reset()
	var beam := h(hero, foe, &"fang_sting", R.BEAM)
	check(beam > 0 and foe.bleeds.is_empty(), "FANG STING on BEAM hurts but adds NO bleed")
	reset()
	h(hero, foe, &"fang_sting", R.MISS)
	check(foe.bleeds.is_empty(), "FANG STING on MISS adds nothing")
	reset()
	h(hero, foe, &"fang_sting", R.POINT, R.POINT)
	check(foe.bleeds.is_empty() and foe.current_hp == 1000, "a perfect dodge (defense POINT) avoids FANG STING entirely")
	reset()
	foe.haganah = {"round": 1, "owner": ally.id}
	h(hero, foe, &"fang_sting", R.POINT)
	check(foe.bleeds.is_empty(), "Haganah blocks the BLEED")


# --------------------------------------------------------------------------- Fang Spine (ZAHAV, 2 golpes)
func _fang_spine() -> void:
	# the foe attacks two heroes: hit 1 on the first target, hit 2 on the second (own defense each)
	reset()
	b._second_target = ally
	await b._skill_strike(foe, hero, &"fang_spine", false, false, true)
	check(hero.current_hp < 1000 and ally.current_hp < 1000, "FANG SPINE: one hit on each of two targets")
	check(hero.bleeds.size() == 2 and ally.bleeds.size() == 2, "FANG SPINE: BLEED x2 on POINT on each target (%d/%d)" % [hero.bleeds.size(), ally.bleeds.size()])
	reset()
	b.ai_result = R.BEAM
	b._second_target = ally
	await b._skill_strike(foe, hero, &"fang_spine", false, false, false)
	check(hero.bleeds.size() == 1 and ally.bleeds.size() == 1, "FANG SPINE: BLEED x1 on contact that is not POINT")
	reset()
	b._second_target = hero
	await b._skill_strike(foe, hero, &"fang_spine", false, false, true)
	check(hero.bleeds.size() == 4 and 1000 - hero.current_hp > 0, "FANG SPINE on ONE target: 2 hits, 2+2 BLEED stacks (capped at 4)")
	reset()
	b._second_target = null
	await b._skill_strike(foe, hero, &"fang_spine", false, false, true)
	check(hero.bleeds.size() == 4, "FANG SPINE without a second target hits the first one twice")
	reset()
	var single := h(foe, hero, &"fang_spine")
	check(single > h(foe, hero, &"fang_sting"), "a FANG SPINE hit (power 15) is stronger than a FANG STING hit (power 5)")
	check(b._enemy_second_target(hero) in [hero, ally], "the enemy AI picks its second target among the living heroes")


# --------------------------------------------------------------------------- Vuln Pierce
func _vuln_pierce() -> void:
	reset()
	var normal := h(hero, foe, &"vuln_pierce")
	check(normal > 0, "VULN PIERCE hurts an offensive target (%d)" % normal)
	reset()
	foe.passive_stance = true
	var doubled := h(hero, foe, &"vuln_pierce")
	check(doubled == normal * 2, "VULN PIERCE does x2 against a non-offensive action (%d vs %d)" % [doubled, normal])
	reset()
	b._defender_defending = true
	var vs_defend := h(hero, foe, &"vuln_pierce")
	check(vs_defend == normal * 2, "VULN PIERCE does x2 against a defender")
	b._defender_defending = false
	reset()
	foe.passive_stance = true
	var other := h(hero, foe, &"fang_sting")
	reset()
	var other_normal := h(hero, foe, &"fang_sting")
	check(other == other_normal, "only VULN PIERCE reads the non-offensive stance")
	# D-131 unified vulnerable target: forced-PASS effects (trapped, paralyzed, sleep) also double VULN PIERCE
	reset()
	foe.trap(2)
	check(foe.is_vulnerable(), "D-131: a trapped target is vulnerable")
	var vs_trapped := h(hero, foe, &"vuln_pierce")
	check(vs_trapped == normal * 2, "D-131: VULN PIERCE does x2 against a trapped target (%d vs %d)" % [vs_trapped, normal])
	SkillFx.cleanse_all(foe)
	check(not foe.is_vulnerable(), "D-131: freeing the target clears vulnerability")
	var after_free := h(hero, foe, &"vuln_pierce")
	check(after_free == normal, "D-131: VULN PIERCE returns to x1 once target is freed (%d vs %d)" % [after_free, normal])
	reset()
	foe.paralyzed_acts = 2
	foe.add_status(&"paralyzed", 2)
	check(foe.is_vulnerable(), "D-131: a paralyzed target is vulnerable")
	var vs_paralyzed := h(hero, foe, &"vuln_pierce")
	check(vs_paralyzed == normal * 2, "D-131: VULN PIERCE does x2 against a paralyzed target (%d vs %d)" % [vs_paralyzed, normal])
	foe.paralyzed_acts = 0
	foe.remove_status(&"paralyzed")
	reset()
	foe.add_status(&"sleep", 1)
	check(foe.is_vulnerable(), "D-131: a sleeping target is vulnerable")
	var vs_sleep := h(hero, foe, &"vuln_pierce")
	check(vs_sleep == normal * 2, "D-131: VULN PIERCE does x2 against a sleeping target (%d vs %d)" % [vs_sleep, normal])
	foe.remove_status(&"sleep")
	# the stance is set by the non-offensive actions and cleared by offensive ones
	reset()
	b._execute_pass(foe)
	check(foe.passive_stance, "PASS is a non-offensive action")
	b._turn_passed = false
	foe.passive_stance = false
	b._execute_rest(foe, false)
	check(foe.acts_available >= 0, "REST resolves")


# --------------------------------------------------------------------------- Dark Breath
func _dark_breath() -> void:
	reset()
	ally.start_praying(5)
	var pp_before := ally.current_pp
	var hp_before := ally.current_hp
	b.ai_result = R.POINT
	b._current_skill = &"dark_breath"
	b.rng.seed = 7
	var applied: int = b._skill_hit_fx(foe, ally, &"dark_breath", 0, false, R.POINT, R.MISS, true, -1)
	check(applied == 0 and ally.current_hp == hp_before, "DARK BREATH deals 0 damage (applied %d)" % applied)
	check(ally.current_pp == pp_before - 3, "DARK BREATH takes 3 PP from a target that prays (%d -> %d)" % [pp_before, ally.current_pp])
	check(ally.has_status(&"blind"), "DARK BREATH blinds")
	check(int(ally.statuses[&"blind"].rounds) == 1, "the blindness lasts until the end of the round (1 round tick)")
	# a target without PP only gets the blindness
	reset()
	check(not hero.prays, "FALLEN does not pray")
	b.rng.seed = 7
	b._skill_hit_fx(foe, hero, &"dark_breath", 0, false, R.POINT, R.MISS, true, -1)
	check(hero.has_status(&"blind") and hero.current_hp == 1000, "a target without PP is only blinded")
	# the dodge is intact: a perfect dodge (defense POINT) avoids everything
	reset()
	ally.start_praying(5)
	var pp := ally.current_pp
	b._skill_hit_fx(foe, ally, &"dark_breath", 0, false, R.POINT, R.POINT, true, -1)
	check(ally.current_pp == pp and not ally.has_status(&"blind"), "a perfect dodge avoids the PP loss and the blindness")
	# PP never goes below 0
	reset()
	ally.start_praying(2)
	b._skill_hit_fx(foe, ally, &"dark_breath", 0, false, R.POINT, R.MISS, true, -1)
	check(ally.current_pp == 0, "PP stops at 0")
	# Haganah shields the blindness
	reset()
	ally.haganah = {"round": 1, "owner": ally.id}
	b._skill_hit_fx(foe, ally, &"dark_breath", 0, false, R.POINT, R.MISS, true, -1)
	check(not ally.has_status(&"blind"), "Haganah blocks the blindness")
	ally.change_pp(-8)


# --------------------------------------------------------------------------- Umbral Gaze
func _umbral_gaze() -> void:
	reset()
	var dmg := h(hero, foe, &"umbral_gaze")
	check(dmg > 0, "UMBRAL GAZE hurts (%d)" % dmg)
	check(foe.trapped_actions == 2 and foe.has_status(&"trapped"), "UMBRAL GAZE traps the target for 2 global actions")
	reset()
	foe.stats.mef = 40
	var armored := h(hero, foe, &"umbral_gaze")
	reset()
	var plain := h(hero, foe, &"umbral_gaze")
	check(armored < plain, "UMBRAL GAZE respects the MEF (%d vs %d)" % [armored, plain])
	reset()
	h(hero, foe, &"umbral_gaze", R.POINT, R.POINT)
	check(foe.trapped_actions == 0, "a perfect dodge avoids the trap")
	reset()
	foe.haganah = {"round": 1, "owner": ally.id}
	h(hero, foe, &"umbral_gaze")
	check(foe.trapped_actions == 0, "Haganah blocks the trap")
	reset()
	h(hero, foe, &"umbral_gaze")
	b._global_action_done()
	b._global_action_done()
	check(foe.trapped_actions == 0 and not foe.has_status(&"trapped"), "after 2 global actions the target is freed")
	check(SkillBook.def(&"umbral_gaze").kind == "strike", "UMBRAL GAZE hits ONE target (it is no longer AoE like VOID GAZE)")


# --------------------------------------------------------------------------- Ignoma / Ignoma Esh
func _ignoma() -> void:
	reset()
	var dmg := h(hero, foe, &"ignoma")
	check(dmg > 0 and foe.burns.size() == 1, "IGNOMA hurts and burns when the 35%% roll succeeds (%d)" % dmg)
	reset(); b.roll = false
	h(hero, foe, &"ignoma")
	check(foe.burns.is_empty(), "IGNOMA does not burn when the roll fails")
	reset()
	foe.stats.mef = 40
	var armored := h(hero, foe, &"ignoma")
	reset()
	check(armored < h(hero, foe, &"ignoma"), "IGNOMA uses MAK against MEF")
	reset()
	foe.haganah = {"round": 1, "owner": ally.id}
	h(hero, foe, &"ignoma")
	check(foe.burns.is_empty(), "Haganah blocks the BURN")
	# IGNOMA ESH: two fire balls, on one or two targets (foe attacks the party to avoid the hero's bars)
	reset()
	b._second_target = ally
	await b._skill_strike(foe, hero, &"ignoma_esh", false, false, true)
	check(hero.current_hp < 1000 and ally.current_hp < 1000 and hero.burns.size() == 1 and ally.burns.size() == 1,
		"IGNOMA ESH on 2 targets: a ball each, each burning")
	reset()
	b._second_target = hero
	await b._skill_strike(foe, hero, &"ignoma_esh", false, false, true)
	check(hero.burns.size() == 2, "IGNOMA ESH on 1 target: two balls, two BURN stacks")
	reset(); b.roll = false
	b._second_target = ally
	await b._skill_strike(foe, hero, &"ignoma_esh", false, false, true)
	check(hero.burns.is_empty() and ally.burns.is_empty() and hero.current_hp < 1000, "IGNOMA ESH: each ball rolls its own 35%% BURN")
