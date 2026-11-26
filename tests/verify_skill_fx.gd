extends SceneTree
## D-106 (creator 2026-11-25): each of the 27 Survival skills has its own signature effect.
## Every effect is proved by calling the controller's hit and round functions directly with
## fixed timings, so no input is needed. Damage effects compare the same seeded hit with and
## without the effect.
const SANDBOX := preload("res://tests/progress_sandbox.gd")
const R := BattleMath.RhythmResult

class FxBattle extends "res://scripts/battle/playable_controller.gd":
	var roll := true
	func _ai_roll(_a: BattleUnit, _b: BattleUnit) -> int: return BattleMath.RhythmResult.MISS
	func _defender_reaction(_a: BattleUnit, _b: BattleUnit) -> int: return BattleMath.RhythmResult.MISS
	func _zone_roll(_h: float) -> int: return BattleMath.RhythmResult.MISS
	func _enemy_counter_roll(_e: BattleUnit) -> bool: return false
	func _enemy_skill_pick(_n: int) -> int: return 0
	func _fx_roll(_c: int) -> bool: return roll
	func _burn_roll(_c: int) -> bool: return roll

var checks := 0
var b: FxBattle
var hero: BattleUnit
var foe: BattleUnit
var foe2: BattleUnit
var ally: BattleUnit


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
	for u in [hero, foe, foe2, ally]:
		u.statuses.clear()
		u.bleeds.clear()
		u.burns.clear()
		u.regen_rounds = 0
		u.regen_amount = 0
		u.stats.max_hp = 1000
		u.current_hp = 1000
		u.stats.defense = 10
		u.stats.mef = 10
		u.stats.agi = 10
		u.current_en = 20
		u.stats.max_en = 20
		u.current_sp = 100
		u.atk_stages.clear()
	hero.stats.atk = 20
	hero.stats.mak = 20
	hero.acts_available = 4
	b.roll = true
	b._hit_mods = {}


## HP removed by one seeded hit, so two calls with the same seed are comparable.
func hit(skill: StringName, idx: int = 0, prev: int = -1, magic: bool = false, who: BattleUnit = null, at: BattleUnit = null) -> int:
	var attacker := who if who != null else hero
	var defender := at if at != null else foe
	b.rng.seed = 7
	var before := defender.current_hp
	var applied := b._skill_hit_fx(attacker, defender, skill, idx, false, R.POINT, R.MISS, magic, prev)
	check(applied >= 0, "%s lands" % skill)
	return before - defender.current_hp


func plain(power: int, magic: bool = false) -> int:
	b.rng.seed = 7
	var before := foe.current_hp
	b._hit_mods = {}
	b._skill_hit(hero, foe, power, false, R.POINT, R.MISS, magic)
	return before - foe.current_hp


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

	# ---- the 27 skills all carry an effect and a description; the 4 main-game skills are untouched
	var ids: Array[StringName] = []
	ids.assign(SurvivalData.SURVIVAL_SKILLS)
	check(ids.size() == 27, "27 Survival skills")
	for id in ids:
		var d := SkillBook.def(id)
		check(d.has("fx") or d.has("powers"), "%s has a signature effect" % id)
		check(String(d.info).begins_with(String(d.name)), "%s: the description starts with its name" % id)
	for id in [&"lunge", &"bleedbuff", &"heat_wave", &"energy_eat"]:
		check(not SkillBook.def(id).has("fx"), "%s (yours) keeps its own effect" % id)
	var seen := {}
	for id in ids:
		var sig := JSON.stringify(SkillBook.def(id).get("fx", {})) + str(SkillBook.def(id).get("powers", []))
		check(not seen.has(sig), "%s has an effect no other skill has" % id)
		seen[sig] = true
	# renamed because the old name no longer fit the effect
	for pair in [[&"spirit_wave", "SOUL LEECH"], [&"spirit_bolt", "SPIRIT BRAND"], [&"ember_touch", "EMBER BURST"],
			[&"mind_blast", "MIND DRAIN"], [&"crushing_blow", "FINISHING BLOW"], [&"dark_siphon", "DARK BOON"]]:
		check(SkillBook.display_name(pair[0]) == pair[1], "%s is now %s" % [pair[0], pair[1]])

	# ---- physical
	check(SkillFx.hit_power(&"blade_dance", 0) == 3 and SkillFx.hit_power(&"blade_dance", 3) == 6, "BLADE DANCE climbs 3,4,5,6")
	reset(); foe.stats.defense = 20
	var normal := plain(7)
	reset(); foe.stats.defense = 20
	var pierced := hit(&"soul_pierce")
	check(pierced > normal, "SOUL PIERCE ignores half the DEF (%d vs %d)" % [pierced, normal])
	reset()
	var steal_before := hero.current_sp
	hit(&"shadow_bite", 0); hit(&"shadow_bite", 1)
	check(hero.current_sp >= steal_before + 2 and foe.current_sp <= 98, "SHADOW BITE steals 1 SP per hit that lands (hero %d, foe %d)" % [hero.current_sp, foe.current_sp])
	reset()
	hit(&"frost_lance")
	check(foe.has_status(&"chill"), "FROST LANCE chills")
	b.rng.seed = 7
	var before := hero.current_hp
	reset(); hero.statuses.clear()
	foe.add_status(&"chill", 2)
	var chilled := 0
	b.rng.seed = 7
	var h0 := hero.current_hp
	b._skill_hit(foe, hero, 7, false, R.POINT, R.MISS, false)
	chilled = h0 - hero.current_hp
	check(not foe.has_status(&"chill"), "CHILL ends with the first attack")
	foe.statuses.clear()
	hero.current_hp = 1000
	b.rng.seed = 7
	b._skill_hit(foe, hero, 7, false, R.POINT, R.MISS, false)
	var unchilled := 1000 - hero.current_hp
	check(chilled < unchilled, "CHILL cuts the next attack (%d vs %d)" % [chilled, unchilled])
	reset()
	hit(&"stone_grasp")
	check(foe.has_status(&"snare") and foe.stats.agi == 6, "STONE GRASP snares: AGI 10 -> 6")
	foe.remove_status(&"snare")
	check(foe.stats.agi == 10, "SNARE gives the AGI back")
	reset()
	var first := hit(&"twin_fang", 0)
	foe.current_hp = 1000
	var second_combo := hit(&"twin_fang", 1, first)
	foe.current_hp = 1000
	var second_plain := hit(&"twin_fang", 1, -1)
	check(second_combo > second_plain, "TWIN FANG: the 2nd hit is stronger when the 1st landed (%d vs %d)" % [second_combo, second_plain])
	reset()
	hit(&"fang_flurry", 0); hit(&"fang_flurry", 1); hit(&"fang_flurry", 2)
	check(foe.bleeds.size() == 3, "FANG FLURRY: each hit adds a bleed (%d)" % foe.bleeds.size())
	var hp := foe.current_hp
	await b._status_tick()
	check(hp - foe.current_hp == SkillFx.BLEED_DAMAGE * 3, "Bleeds hurt 2 each at the start of the round")
	await b._status_tick(); await b._status_tick()
	check(foe.bleeds.is_empty(), "A bleed lasts 3 rounds")
	reset()
	hit(&"heavy_crush")
	check(foe.has_status(&"break") and foe.stats.defense == 8, "HEAVY CRUSH breaks DEF 10 -> 8")
	foe.remove_status(&"break")
	check(foe.stats.defense == 10, "BREAK gives the DEF back")
	reset(); foe.current_hp = 300
	var finish_low := hit(&"crushing_blow")
	reset(); foe.current_hp = 900
	var finish_high := hit(&"crushing_blow")
	check(finish_low > finish_high, "FINISHING BLOW hits harder below 40%% HP (%d vs %d)" % [finish_low, finish_high])
	reset(); hero.current_hp = 500
	var drained_hit := hit(&"life_drain")
	check(hero.current_hp == 500 + drained_hit and drained_hit > 0, "LIFE DRAIN heals as much as the damage (%d)" % drained_hit)

	# ---- magic
	reset(); b.roll = true
	b.rng.seed = 7
	b._magic_hit(hero, foe, &"pixie_dust", false, R.POINT, R.MISS)
	check(foe.has_status(SkillFx.SLEEP_ID), "PIXIE DUST puts a foe to sleep")
	check(b._skip_if_asleep(foe) and foe.acts_available == 0 and not foe.has_status(SkillFx.SLEEP_ID), "A sleeping unit loses its turn and wakes up")
	check(not b._skip_if_asleep(foe), "An awake unit keeps its turn")
	reset()
	hero.current_hp = 500
	b.rng.seed = 7
	b._magic_hit(hero, foe, &"spirit_wave", false, R.POINT, R.MISS)
	check(hero.current_hp == 502, "SOUL LEECH heals 2 HP per foe hit")
	reset()
	hit(&"spirit_bolt", 0, -1, true)
	check(foe.has_status(&"mark"), "SPIRIT BRAND marks the foe")
	foe.current_hp = 1000
	var marked := plain(7)
	foe.current_hp = 1000
	var unmarked := plain(7)
	check(marked > unmarked and not foe.has_status(&"mark"), "A marked foe takes +25%% and the mark is used up (%d vs %d)" % [marked, unmarked])
	reset()
	var burst_plain := hit(&"ember_touch", 0, -1, true)
	reset(); foe.burns.append(3)
	var burst_total := hit(&"ember_touch", 0, -1, true)
	check(burst_total == burst_plain + SkillBook.BURN_DAMAGE, "EMBER BURST detonates an existing burn at once (%d vs %d)" % [burst_total, burst_plain])
	reset()
	b._magic_hit(hero, foe, &"hellfire", false, R.POINT, R.MISS)
	check(foe.burns.size() == 1 and foe.burns[0] == 5, "HELLFIRE burns for 5 rounds (%s)" % [foe.burns])
	reset()
	b._magic_hit(hero, foe, &"frost_breath", false, R.POINT, R.MISS)
	check(foe.has_status(&"slow"), "FROST BREATH slows")
	b.state.start_round()
	check(b.state.turn_order.back() == foe, "A slowed unit acts last in the round")
	reset()
	b._magic_hit(hero, foe, &"venom_cloud", false, R.POINT, R.MISS)
	check(foe.has_status(&"weaken"), "VENOM CLOUD weakens")
	reset(); foe.current_en = 10
	b._magic_hit(hero, foe, &"mind_blast", false, R.POINT, R.MISS)
	check(foe.current_en == 7, "MIND DRAIN takes 3 EN")
	check(not SkillBook.affordable(&"lunge", 2, 0, 10), "With no EN a skill cannot be used")
	reset()
	b._magic_hit(hero, foe, &"curse_ray", false, R.POINT, R.MISS)
	check(foe.current_sp == 98, "CURSE RAY drains 2 SP")
	reset()
	var log_before: int = b.log_history.size()
	b.rng.seed = 7
	b._magic_hit(hero, foe, &"thunder_call", false, R.POINT, R.MISS)
	check(b.log_history.slice(log_before).any(func(l: String) -> bool: return l.contains("struck twice")), "THUNDER CALL strikes twice")
	reset(); b.roll = false
	log_before = b.log_history.size()
	b._magic_hit(hero, foe, &"thunder_call", false, R.POINT, R.MISS)
	check(not b.log_history.slice(log_before).any(func(l: String) -> bool: return l.contains("struck twice")), "...and once when the roll fails")
	reset()
	b._current_skill = &"void_gaze"
	var rails: Array[int] = await b._skill_defense_timing(hero, foe, [0.5], true)
	check(rails == [R.MISS], "VOID GAZE cannot be defended: no rail even for a paid defense")
	b._current_skill = &"hellfire"

	# ---- heal
	reset(); hero.burns.append(2); hero.bleeds.append(2); hero.current_hp = 500
	b._self_skill(hero, &"mend", 0, false)
	check(hero.current_hp == 508 and hero.burns.is_empty() and hero.bleeds.is_empty(), "MEND heals 8 and cleanses burns and bleeds")
	reset(); ally.current_hp = 500; hero.current_hp = 500
	b._self_skill(hero, &"dark_siphon", 0, false, ally)
	check(ally.current_hp == 512 and hero.current_hp == 500, "DARK BOON heals the chosen ally, not the user")
	reset(); hero.current_hp = 500; ally.current_hp = 900
	check(b._weakest_ally(hero) == hero, "The AI heals its weakest ally")
	reset(); hero.current_hp = 500
	b._self_skill(hero, &"renew", 0, false)
	check(hero.current_hp == 500 and hero.regen_rounds == 3, "RENEW heals nothing at once")
	for _r in 3:
		await b._status_tick()
	check(hero.current_hp == 518 and hero.regen_rounds == 0, "RENEW restores 6 HP in each of 3 rounds (%d)" % hero.current_hp)
	await b._status_tick()
	check(hero.current_hp == 518, "...and then stops")

	# ---- buff
	reset()
	b._self_skill(hero, &"howl", 0, false)
	check(hero.atk_stages.size() == 1 and hero.has_status(&"taunt"), "HOWL: +1 ATK stage and taunt")
	check(b._player_with_most_sp() == hero, "TAUNT: foes can only attack the taunter")
	await b._status_tick()
	check(not hero.has_status(&"taunt"), "TAUNT ends at the next round")
	reset(); var def_before := hero.stats.defense
	b._self_skill(hero, &"primal_roar", 0, false)
	check(hero.atk_stages.size() == 2 and hero.has_status(&"berserk") and hero.stats.defense == 8, "PRIMAL ROAR: +2 ATK stages and DEF -25%")
	hero.remove_status(&"berserk")
	check(hero.stats.defense == def_before, "BERSERK gives the DEF back")
	reset()
	b._self_skill(hero, &"war_cry", 0, false)
	check(hero.atk_stages.size() == 1 and ally.atk_stages.size() == 1, "WAR CRY buffs the user and Yoch")
	var foes_buffed := b._allies_of(foe)
	check(foes_buffed.has(foe2) and not foes_buffed.has(hero), "An enemy's WAR CRY reaches only its own side")

	print("verify_skill_fx: %d checks OK" % checks)
	await process_frame
	quit(0)
