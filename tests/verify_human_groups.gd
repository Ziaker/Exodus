extends SceneTree
## D-107 (creator 2026-11-25): one group of plain humans per Survival stratum. Humans fight only with
## humans, pray with PP like Yoch, cannot be absorbed, and have three prayers of their own: SANVERIM
## (2 PP, blinds: smaller POINT zone until the end of the next round), NECHAMAH (1 PP, 5 HP per
## round for 3 rounds, stacking) and CHERAV (3 PP, 10 + MAK - MEF on every hero).
const SANDBOX := preload("res://tests/progress_sandbox.gd")
const R := BattleMath.RhythmResult

var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, reason: String) -> void:
	if not ok:
		push_error("FAIL: " + reason)
		quit(1)
		assert(ok, reason)
	checks += 1


func _wait_mode(b: Control, wanted: String, limit: int = 240) -> bool:
	for _i in limit:
		if b.hud != null and b.hud.mode == wanted:
			return true
		await process_frame
	return false


func _battle(encounter: String, stratum: int = 1) -> Control:
	SurvivalState.reset()
	SurvivalState.patch({"seed": 1, "encounter_id": encounter, "stratum": stratum,
		"gains": {"max_hp": 0, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": 30}})
	var b: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	b.suppress_scene_change = true
	root.add_child(b)
	await _wait_mode(b, "plan")
	return b


func _run() -> void:
	SANDBOX.begin()
	ProgressStore.save_path_override = "user://test_human_groups_guard.json"
	ProgressStore.clear()

	# ---- data: 5 groups of 3, only humans
	for st in range(1, 6):
		var units := SurvivalData.human_unit_ids(st)
		check(units.size() == 3, "Stratum %d has 3 humans" % st)
		check(SurvivalData.encounter_for(SurvivalData.human_group_id(st)) == units, "Touching the group of stratum %d fights its 3 humans" % st)
		check(SurvivalStrata.stratum_of(SurvivalData.human_group_id(st)) == st and SurvivalStrata.stratum_of(units[0]) == st, "Humans belong to stratum %d" % st)
		for id in units:
			var d := SurvivalData.demon_by_id(id)
			check(bool(d.human) and int(d.stats.max_en) == 0, "%s is a human with no EN" % id)
			check(d.skills == SurvivalData.HUMAN_SKILLS, "%s prays: %s" % [id, d.skills])
			check(not SurvivalData.is_elite(1, id, 5), "%s is never an elite" % id)
		for demon in SurvivalStrata.ids_for(st):
			check(not SurvivalData.encounter_for(demon).any(func(i: String) -> bool: return SurvivalData.is_human_id(i)), "Demon %s never fights next to a human" % demon)
		var cells: Dictionary = SurvivalStrata.layout(77, st).demons
		check(cells.has(SurvivalData.human_group_id(st)), "Stratum %d places its human group" % st)
		var seen := {}
		for id in cells.keys():
			check(not seen.has(cells[id]), "Stratum %d: no two groups share a cell (%s)" % [st, id])
			seen[cells[id]] = true
	for demon in SurvivalData.DEMONS:
		check(not bool(demon.get("human", false)), "%s is not a human" % demon.id)

	# ---- the three prayers exist with PP costs and Hebrew names
	check(int(SkillBook.def(&"sanverim").pp) == 2 and int(SkillBook.def(&"nechamah").pp) == 1 and int(SkillBook.def(&"cherav").pp) == 3, "Costs: SANVERIM 2 PP, NECHAMAH 1 PP, CHERAV 3 PP")
	for id in [&"sanverim", &"nechamah", &"cherav"]:
		check(String(SkillBook.def(id).hebrew).length() > 0, "%s has a Hebrew name" % id)
	check(not SkillBook.affordable(&"cherav", 2, 0, 10, 2) and SkillBook.affordable(&"cherav", 2, 0, 10, 3), "CHERAV needs 3 PP")

	# ---- a battle against the stratum 1 group
	var b := await _battle(SurvivalData.human_group_id(1))
	var foes: Array = b.hud.opponents
	check(foes.size() == 3, "The group has 3 humans (%d)" % foes.size())
	for f in foes:
		check(f.race == &"human" and f.prays and f.current_pp == 0 and f.stats.max_en == 0, "%s: human, prays, 0 PP, no EN" % f.display_name)
		check(f.display_name.begins_with("HUMAN"), "Plain name (%s)" % f.display_name)
	var hero: BattleUnit = b._fallen
	var yoch: BattleUnit = b._ally
	var h1: BattleUnit = foes[0]
	var h2: BattleUnit = foes[1]

	# humans cannot be absorbed
	hero.acts_available = 4
	var before: int = hero.acts_available
	var ok: bool = await b._execute_absorb(hero, h1, false)
	check(not ok and hero.acts_available == before, "ABSORB on a human is refused and spends nothing")

	# PRAY: +1 PP and +2 SP
	h1.acts_available = 4
	var sp0 := h1.current_sp
	b._enemy_prayer(h1, &"pray")
	check(h1.current_pp == 1 and h1.current_sp == sp0 + 2, "PRAY gives +1 PP (+2 SP)")
	h1.change_pp(7)
	check(h1.current_pp == 8, "PP caps at 8")
	h1.current_pp = 3

	# SANVERIM: pays 2 PP, blinds a hero; the POINT zone shrinks; it ends after the next round
	b._pay_skill(h1, &"sanverim", 0)
	check(h1.current_pp == 1, "SANVERIM costs 2 PP")
	b._enemy_prayer(h1, &"sanverim")
	var blinded: BattleUnit = hero if hero.has_status(&"blind") else yoch
	check(blinded.has_status(&"blind"), "SANVERIM blinds a hero")
	var rival: BattleUnit = h1
	var half_blind := BattleMath.unit_point_half(blinded, rival)
	blinded.remove_status(&"blind")
	var half_clear := BattleMath.unit_point_half(blinded, rival)
	check(half_blind < half_clear and is_equal_approx(half_blind, maxf(BattleMath.POINT_MIN_HALF_WIDTH * 0.5, half_clear * BattleMath.BLIND_POINT_MULT)), "BLIND shrinks the POINT zone (%.3f < %.3f)" % [half_blind, half_clear])
	SkillFx.apply_status(blinded, &"blind", SkillFx.BLIND_ROUNDS)
	await b._status_tick()
	check(blinded.has_status(&"blind"), "BLIND lasts through the next round")
	await b._status_tick()
	check(not blinded.has_status(&"blind"), "BLIND is over after the next round")

	# NECHAMAH: pays 1 PP; 5 HP per round for 3 rounds, stacking
	h1.current_pp = 3
	b._pay_skill(h1, &"nechamah", 0)
	check(h1.current_pp == 2, "NECHAMAH costs 1 PP")
	h2.stats.max_hp = 100
	h2.current_hp = 40
	h1.current_hp = 90
	b._enemy_prayer(h1, &"nechamah")
	check(h2.mends.size() == 1 or h1.mends.size() == 1, "NECHAMAH starts a mend on the weakest human")
	var patient: BattleUnit = h2 if h2.mends.size() == 1 else h1
	b._enemy_prayer(h1, &"nechamah")
	check(patient.mends.size() == 2, "Mends stack (%d)" % patient.mends.size())
	patient.current_hp = 10
	await b._status_tick()
	check(patient.current_hp == 10 + 2 * SkillFx.MEND_HEAL, "Each mend heals 5 per round (%d)" % patient.current_hp)
	await b._status_tick(); await b._status_tick()
	check(patient.mends.is_empty(), "A mend lasts 3 rounds")
	var after := patient.current_hp
	await b._status_tick()
	check(patient.current_hp == after, "...and then stops")

	# CHERAV: the prayer formula on a hero, 3 PP
	h1.current_pp = 5
	b._pay_skill(h1, &"cherav", 0)
	check(h1.current_pp == 2, "CHERAV costs 3 PP")
	hero.stats.max_hp = 500
	hero.current_hp = 500
	b.rng.seed = 11
	b.rng.seed = 11
	var rng_probe := RandomNumberGenerator.new()
	rng_probe.seed = 11
	var probe := PrayerBook.raam_damage(0, h1.stats.mak, h1.stats.agi, hero.stats.mef, h1.current_sp, hero.current_sp, BattleMath.Affinity.NORMAL, hero.race, rng_probe)
	b._magic_hit(h1, hero, &"cherav", false, R.POINT, R.MISS)
	check(500 - hero.current_hp == int(probe.amount) or int(probe.amount) == 0, "CHERAV deals the prayer formula (%d, expected %d)" % [500 - hero.current_hp, int(probe.amount)])
	check(float(probe.base) == float(10 + h1.stats.mak - hero.stats.mef), "Its base is 10 + MAK - MEF")

	# AI weights
	h1.current_pp = 0
	check(b._prayer_weight(h1, &"pray") > b._prayer_weight(h1, &"cherav") * 0.5, "With no PP a human prefers to pray")
	for u in [h1, h2, foes[2]]:
		u.current_hp = u.stats.max_hp
		u.mends.clear()
	check(b._prayer_weight(h1, &"nechamah") == 0.0, "NECHAMAH is not drawn when nobody is hurt")
	h2.current_hp = 1
	check(b._prayer_weight(h1, &"nechamah") > 0.0, "NECHAMAH is drawn when an ally is hurt")
	hero.add_status(&"blind", 2)
	yoch.add_status(&"blind", 2)
	check(b._prayer_weight(h1, &"sanverim") == 0.0, "SANVERIM is not drawn when every hero is blind")

	print("verify_human_groups: %d checks OK" % checks)
	ProgressStore.clear()
	await process_frame
	quit(0)
