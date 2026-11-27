extends SceneTree
## D-131 (criador 2026-11-27), Fase 2: as 7 skills do Lote 2 (5 base + 2 ZAHAV) — catálogo, custos, fichas, execução real de
## combate pelo fluxo do controlador (custo, alvo, ritmo, efeito), migração das 5 skills antigas do Survival (pool, demônios,
## saves), requisito de 4 ACT e a condição de Energy Blow no menu. Sem VFX (Fase 3).
const SANDBOX := preload("res://tests/progress_sandbox.gd")
const R := BattleMath.RhythmResult
const NEW_IDS: Array[StringName] = [&"stone_crush", &"energy_blow", &"drain_claw", &"vital_claws", &"weaken", &"weakenen", &"mark_of_sun"]
const OLD_IDS: Array[StringName] = [&"heavy_crush", &"crushing_blow", &"life_drain", &"curse_ray", &"spirit_bolt"]

## O jogador aperta o centro da barra (POINT) e escolhe os alvos roteirizados; o inimigo nunca defende nem contra-ataca.
class ExecBattle extends "res://scripts/battle/playable_controller.gd":
	var scripted: Array[BattleUnit] = []
	func _enemy_counter_roll(_e: BattleUnit) -> bool: return false
	func _zone_roll(_h: float) -> int: return BattleMath.RhythmResult.MISS
	func _ai_roll(_a: BattleUnit, _d: BattleUnit) -> int: return BattleMath.RhythmResult.POINT
	func _defender_reaction(_a: BattleUnit, _d: BattleUnit) -> int: return BattleMath.RhythmResult.MISS
	func _manual_rhythm(_duration: float, _half: float, _chain: bool = false) -> int: return BattleMath.RhythmResult.POINT
	func _wait_target(_side: String = "enemy") -> BattleUnit:
		return scripted.pop_front() if not scripted.is_empty() else null

var checks := 0
var b: ExecBattle
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
		u.paralyzed_acts = 0
		u.passive_stance = false
		u.boss_class = false
		u.battle_max_en_delta = 0
		u.weaken_mef_penalty = 0
		u.weaken_mak_penalty = 0
		u.sun_mark_hits = 0
		u.stats.max_hp = 1000
		u.current_hp = 1000
		u.stats.defense = 10
		u.stats.mef = 10
		u.stats.atk = 20
		u.stats.mak = 20
		u.stats.max_en = 60
		u.current_en = 60
		u.current_sp = 100
		u.acts_available = 4
	b.scripted.clear()
	b._second_target = null
	b._hit_mods = {}


func _run() -> void:
	b = ExecBattle.new()
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
	_migration()
	_four_act()
	await _execution()
	print("VERIFY_D131_SKILLS_OK: %d checks; 7 skills (5 + 2 ZAHAV): catalog, real combat flow, Survival migration, 4 ACT, Energy Blow COND in the menu" % checks)
	b.queue_free()
	quit(0)


# --------------------------------------------------------------------------- catálogo
func _catalog() -> void:
	# [acts, en, kind, cat, dmg_type, targets, power]
	var expect := {
		&"stone_crush": [4, 0, "strike", "PHYS", "PHYS", "1T", 30], &"energy_blow": [3, 0, "strike", "MAGI", "DMG", "1T", 25],
		&"drain_claw": [2, 15, "strike", "PHYS", "PHYS", "1T", 15], &"vital_claws": [3, 25, "strike", "PHYS", "PHYS", "1T", 30],
		&"weaken": [1, 10, "strike", "STAT", "", "1T", 0], &"weakenen": [2, 15, "strike", "STAT", "", "2T", 0],
		&"mark_of_sun": [4, 20, "strike", "STAT", "", "1T", 0]}
	for id in NEW_IDS:
		var d := SkillBook.def(id)
		var e: Array = expect[id]
		check(int(d.acts) == e[0] and int(d.en) == e[1] and String(d.kind) == e[2], "%s: %d ACT / %d EN" % [id, e[0], e[1]])
		check(String(d.cat) == e[3] and String(d.get("dmg_type", "")) == e[4] and String(d.targets) == e[5] and int(d.power) == e[6], "%s: %s / %s / %s / power %d" % [id, e[3], e[4], e[5], e[6]])
		check(bool(d.get("grotesque", false)), "%s is a grotesque (non-prayer) attack" % id)
		check(not d.has("affinity"), "%s has no affinity (D-119)" % id)
		check(String(d.info).begins_with(String(d.name)), "%s: the description starts with its name" % id)
		check(String(d.info).contains("%d ACT / %d EN" % [e[0], e[1]]), "%s: the description shows its cost" % id)
		check(not d.has("hebrew") and not String(d.name).contains("ZAHAV"), "%s: no hebrew letters in the data of the skill" % id)
	check(bool(SkillBook.def(&"vital_claws").zahav) and SkillBook.def(&"vital_claws").zahav_of == &"drain_claw", "VITAL CLAWS is the ZAHAV of DRAIN CLAW")
	check(bool(SkillBook.def(&"weakenen").zahav) and SkillBook.def(&"weakenen").zahav_of == &"weaken", "WEAKENEN is the ZAHAV of WEAKEN")
	check(SkillBook.def(&"drain_claw").zahav_to == &"vital_claws" and SkillBook.def(&"weaken").zahav_to == &"weakenen", "the base skills point at their evolution")
	check(not bool(SkillBook.def(&"drain_claw").get("zahav", false)) and not bool(SkillBook.def(&"weaken").get("zahav", false)), "the base skills are not ZAHAV themselves")
	var fx_drain: Dictionary = SkillBook.def(&"drain_claw").fx
	check(float(fx_drain.drain_max_hp_ratio) == 0.25 and int(fx_drain.boss_cap) == 40 and float(fx_drain.heal_ratio) == 0.8, "DRAIN CLAW: 1/4 max HP, cap 40, heals 80%")
	var fx_vital: Dictionary = SkillBook.def(&"vital_claws").fx
	check(int(fx_vital.boss_cap) == 60 and int(fx_vital.steal_en) == 15 and float(fx_vital.heal_ratio) == 0.8, "VITAL CLAWS: cap 60, 15 EN, heals 80%")
	check(int(SkillBook.def(&"weaken").fx.weaken_mef_base) == 5 and not SkillBook.def(&"weaken").fx.has("weaken_mak_base"), "WEAKEN: MEF 5 only")
	var fx_wn: Dictionary = SkillBook.def(&"weakenen").fx
	check(int(fx_wn.weaken_mef_base) == 10 and int(fx_wn.weaken_mak_base) == 10 and float(fx_wn.weaken_mak_ratio) == 0.5, "WEAKENEN: MEF and MAK 10 (+50% MAK)")
	var fx_sun: Dictionary = SkillBook.def(&"mark_of_sun").fx
	check(int(fx_sun.mark_of_sun_hits) == 3 and int(fx_sun.mark_of_sun_magi) == 20 and int(fx_sun.mark_of_sun_min) == 5, "MARK OF SUN: 3 hits, 20 MAGI, floor 5")
	check(String(SkillBook.def(&"energy_blow").fx.cond) == "vuln_or_quarter_hp" and float(SkillBook.def(&"energy_blow").fx.steal_max_en_ratio) == 0.5, "ENERGY BLOW: COND + 50% max EN")
	check(bool(SkillBook.def(&"weakenen").dual) and SkillBook.def(&"weakenen").marks.size() == 2, "WEAKENEN has two target slots (2T)")
	for id in [&"drain_claw", &"weaken", &"mark_of_sun", &"energy_blow", &"stone_crush"]:
		check(SurvivalData.SURVIVAL_SKILLS.has(id), "%s is in the Survival pool" % id)
	for id in [&"vital_claws", &"weakenen"]:
		check(not SurvivalData.SURVIVAL_SKILLS.has(id), "%s is an evolution, not a pool skill" % id)
	check(SurvivalData.SURVIVAL_SKILLS.size() == 28, "the pool still has 28 skills (1:1 replacement)")
	for id in SurvivalData.SURVIVAL_SKILLS:
		check(not SkillBook.def(id).is_empty() and SurvivalData.HEBREW_SKILLS.has(id), "%s: defined and has its unidentified (hebrew) name" % id)


# --------------------------------------------------------------------------- migração
func _migration() -> void:
	for id in OLD_IDS:
		check(SkillBook.def(id).is_empty(), "%s is gone from the SkillBook" % id)
		check(not SurvivalData.SURVIVAL_SKILLS.has(id) and not SurvivalData.HEBREW_SKILLS.has(id), "%s is gone from the Survival pool and names" % id)
		for demon in SurvivalData.DEMONS:
			check(not demon.skills.has(id), "%s does not stay in the loadout of %s" % [id, demon.id])
		check(SkillBook.LEGACY_IDS.has(id) and NEW_IDS.has(SkillBook.LEGACY_IDS[id]), "%s maps to a canonical skill" % id)
	check(SkillBook.LEGACY_IDS[&"heavy_crush"] == &"stone_crush" and SkillBook.LEGACY_IDS[&"crushing_blow"] == &"energy_blow"
		and SkillBook.LEGACY_IDS[&"life_drain"] == &"drain_claw" and SkillBook.LEGACY_IDS[&"curse_ray"] == &"weaken"
		and SkillBook.LEGACY_IDS[&"spirit_bolt"] == &"mark_of_sun", "the five replacements are the canonical ones")
	var migrated := SkillBook.migrate_ids(["spirit_bolt", "mend", "mark_of_sun", "life_drain"])
	check(migrated == ["mark_of_sun", "mend", "drain_claw"], "a saved list is migrated without duplicates: %s" % [migrated])
	check(SkillBook.migrate_id(&"curse_ray") == &"weaken" and SkillBook.migrate_id("heavy_crush") == "stone_crush" and SkillBook.migrate_id(&"lunge") == &"lunge",
		"migrate_id keeps the type and leaves other skills alone")
	# demônios do Survival: as skills substituídas ocupam o lugar das antigas
	var ghoul: Dictionary = {}
	for demon in SurvivalData.DEMONS:
		for sk in demon.skills:
			check(not SkillBook.def(sk).is_empty(), "%s: %s exists" % [demon.id, sk])
		if demon.skills.has(&"stone_crush"): ghoul = demon
	check(not ghoul.is_empty(), "some demon uses STONE CRUSH (was HEAVY CRUSH)")
	# o save principal (aprendizado por absorção)
	ProgressStore.save_path_override = "user://d131_skills_test.json"
	var f := FileAccess.open(ProgressStore.save_path_override, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": ProgressStore.VERSION, "gains": {}, "absorbs": {}, "skills": ["life_drain", "lunge", "crushing_blow"], "pp": 0, "deaths": 0}))
	f.close()
	var learned := ProgressStore.load_skills()
	check(learned.has(&"drain_claw") and learned.has(&"energy_blow") and learned.has(&"lunge") and learned.size() == 3, "ProgressStore migrates old learned skills (%s)" % [learned])
	ProgressStore.clear()


# --------------------------------------------------------------------------- requisito de 4 ACT
func _four_act() -> void:
	for id in [&"stone_crush", &"mark_of_sun"]:
		check(String(SkillBook.def(id).info).contains("4 ACT"), "%s shows its 4 ACT requirement" % id)
		check(not SkillBook.affordable(id, 3, 99, 99), "%s is NOT payable with 3 ACT" % id)
		check(SkillBook.affordable(id, 4, 99, 99), "%s is payable with exactly 4 ACT" % id)
	check(BattleMath.MAX_AVAILABLE_ACTS == 4, "the ceiling of D-005 is 4 acts")
	check(not SkillBook.affordable(&"mark_of_sun", 4, 19, 99) and SkillBook.affordable(&"mark_of_sun", 4, 20, 99), "MARK OF SUN also needs 20 EN")
	check(SkillBook.affordable(&"energy_blow", 3, 0, 99) and not SkillBook.affordable(&"energy_blow", 2, 99, 99), "ENERGY BLOW: 3 ACT, no EN")
	# menu: ENERGY BLOW sinalizado quando nenhum alvo cumpre a COND
	reset()
	check(not b._any_foe_meets_cond(&"energy_blow"), "menu: no foe qualifies for ENERGY BLOW (healthy, active)")
	foe2.current_hp = 200
	check(b._any_foe_meets_cond(&"energy_blow"), "menu: a foe at 1/4 HP qualifies")
	reset()
	foe.passive_stance = true
	check(b._any_foe_meets_cond(&"energy_blow"), "menu: a vulnerable foe qualifies")
	check(b._any_foe_meets_cond(&"stone_crush"), "menu: a skill without COND is never flagged")


# --------------------------------------------------------------------------- execução real (fluxo do controlador)
func _execution() -> void:
	# STONE CRUSH: 4 ACT, power 30
	reset()
	var ok: bool = await b._execute_skill(hero, {"skill": &"stone_crush"}, false, foe)
	check(ok and hero.acts_available == 0 and hero.current_en == 60, "STONE CRUSH: spends 4 ACT and no EN")
	var crush := 1000 - foe.current_hp
	check(crush > 0, "STONE CRUSH hurts (%d)" % crush)
	reset()
	hero.acts_available = 3
	ok = await b._execute_skill(hero, {"skill": &"stone_crush"}, false, foe)
	check(foe.current_hp == 1000 and hero.acts_available == 3, "STONE CRUSH cannot be used with 3 ACT (nothing is paid or dealt)")
	# ENERGY BLOW: recusa um alvo saudável, aceita um vulnerável e rouba EN
	reset()
	ok = await b._execute_skill(hero, {"skill": &"energy_blow"}, false, foe)
	check(not ok and hero.acts_available == 4 and foe.current_hp == 1000, "ENERGY BLOW is refused on a healthy, active foe (nothing spent)")
	reset()
	foe.passive_stance = true
	ok = await b._execute_skill(hero, {"skill": &"energy_blow"}, false, foe)
	check(ok and hero.acts_available == 1 and foe.current_hp < 1000, "ENERGY BLOW on a vulnerable foe: 3 ACT, damage")
	check(foe.effective_max_en() == 30 and hero.effective_max_en() == 90 and hero.current_en == 90, "ENERGY BLOW moved 30 max EN (foe 30, user 90)")
	reset()
	foe.current_hp = 250
	ok = await b._execute_skill(hero, {"skill": &"energy_blow"}, false, foe)
	check(ok and not foe.is_alive() or foe.current_hp < 250, "ENERGY BLOW on a foe at 1/4 HP works")
	# DRAIN CLAW
	reset()
	hero.current_hp = 100
	ok = await b._execute_skill(hero, {"skill": &"drain_claw"}, false, foe)
	check(ok and hero.acts_available == 2 and hero.current_en == 45, "DRAIN CLAW: 2 ACT, 15 EN")
	var drain_lost := 1000 - foe.current_hp
	check(drain_lost > 250 and hero.current_hp == 100 + int(floor(float(drain_lost) * 0.8)), "DRAIN CLAW: takes 1/4 max HP + the fixed part and heals 80%% (%d)" % drain_lost)
	# VITAL CLAWS
	reset()
	hero.current_hp = 100
	hero.current_en = 40
	ok = await b._execute_skill(hero, {"skill": &"vital_claws"}, false, foe)
	check(ok and hero.acts_available == 1, "VITAL CLAWS: 3 ACT")
	check(hero.current_en == 40 - 25 + 15 and foe.current_en == 45, "VITAL CLAWS: -25 EN, +15 EN stolen from the foe")
	# WEAKEN
	reset()
	foe.stats.mef = 100
	ok = await b._execute_skill(hero, {"skill": &"weaken"}, false, foe)
	check(ok and hero.acts_available == 3 and hero.current_en == 50, "WEAKEN: 1 ACT, 10 EN")
	check(foe.weaken_mef_penalty == 5 + 10 and foe.current_hp == 1000, "WEAKEN: -15 MEF and no damage")
	# WEAKENEN: 2T com dois vivos
	reset()
	for u in [foe, foe2]:
		u.stats.mef = 100
		u.stats.mak = 100
	b.scripted = [foe2]
	ok = await b._execute_skill(hero, {"skill": &"weakenen"}, false, foe)
	check(ok and hero.acts_available == 2 and hero.current_en == 45, "WEAKENEN: 2 ACT, 15 EN")
	check(foe.weaken_mef_penalty == 20 and foe2.weaken_mef_penalty == 20 and foe.weaken_mak_penalty == 20 and foe2.weaken_mak_penalty == 20,
		"WEAKENEN weakens the two distinct foes (-20 MAK and MEF each: %d/%d)" % [foe.weaken_mef_penalty, foe2.weaken_mef_penalty])
	# WEAKENEN: um só vivo
	reset()
	foe.stats.mef = 100
	foe.stats.mak = 100
	foe2.current_hp = 0
	ok = await b._execute_skill(hero, {"skill": &"weakenen"}, false, foe)
	check(ok and foe.weaken_mef_penalty == 20 and foe.weaken_mak_penalty == 20, "WEAKENEN with a single living foe lands once on it (%d)" % foe.weaken_mef_penalty)
	foe2.current_hp = 1000
	# MARK OF SUN
	reset()
	ok = await b._execute_skill(hero, {"skill": &"mark_of_sun"}, false, foe)
	check(ok and hero.acts_available == 0 and hero.current_en == 40, "MARK OF SUN: 4 ACT, 20 EN")
	check(foe.sun_mark_hits == 3 and foe.current_hp == 1000 and foe.has_status(&"mark_of_sun"), "MARK OF SUN: the foe is marked without damage")
	reset()
	foe.apply_sun_mark()
	hero.acts_available = 4
	var before := foe.current_hp
	await b._execute_skill(hero, {"skill": &"stone_crush"}, false, foe)
	check(foe.sun_mark_hits == 2 and before - foe.current_hp > crush, "a real STONE CRUSH on a marked foe adds the sun damage (%d > %d)" % [before - foe.current_hp, crush])
	# o inimigo usa as skills contra os heróis (IA)
	reset()
	hero.stats.mef = 10
	await b._skill_strike(foe, hero, &"mark_of_sun", false, false, true)
	check(hero.sun_mark_hits == 3, "an enemy can mark a hero")
	await b._skill_strike(foe, hero, &"weaken", false, false, true)
	check(hero.weaken_mef_penalty > 0, "an enemy can weaken a hero")
	reset()
	foe.current_hp = 100
	await b._skill_strike(foe, hero, &"drain_claw", false, false, true)
	check(foe.current_hp > 100 and hero.current_hp < 1000, "an enemy DRAIN CLAW heals the enemy")
