extends SceneTree
## D-139 (criador 2026-11-27/28), Fase 1: regras de motor — STURDY (anti-interrupção, bloqueio de efeitos
## debilitantes consumindo STURDY, prioridade AEGIS IRIS > STURDY, +15 DEF acoplado em Stone Body, dispell
## positivo vs Tahorah), IMEDIATO em skills, e Blade Dance (ALL ACT -> ACT+1 golpes de 15 PHYS fixo a 0 EN,
## alvo intercalado com 1/2/3 alvos e morte no meio, sem COUNTER permitindo DEFEND, cooldown de 2 rounds).
const SANDBOX := preload("res://tests/progress_sandbox.gd")
const R := BattleMath.RhythmResult

class FxBattle extends "res://scripts/battle/playable_controller.gd":
	var roll := true
	var ai_result: int = BattleMath.RhythmResult.POINT
	var force_counter_winner: int = -99
	var counter_rolls := 0
	var forced_attack: int = BattleMath.RhythmResult.POINT
	func _ai_roll(_a: BattleUnit, _b: BattleUnit) -> int: return ai_result
	func _defender_reaction(_a: BattleUnit, _b: BattleUnit) -> int: return BattleMath.RhythmResult.MISS
	func _zone_roll(_h: float) -> int: return BattleMath.RhythmResult.MISS
	func _enemy_counter_roll(_e: BattleUnit) -> bool:
		counter_rolls += 1
		return true
	func _fx_roll(_c: int) -> bool: return roll
	func _burn_roll(_c: int) -> bool: return roll
	func _skill_bars(count: int, _point_half: float) -> Array[int]:
		var out: Array[int] = []
		for _i in count:
			out.append(forced_attack)
		return out
	func _counter_exchange(hero: BattleUnit, enemy: BattleUnit, _kind: String, _fast_side: String = "") -> Dictionary:
		if force_counter_winner != -99:
			return {
				"winner": force_counter_winner,
				"player_timing": BattleMath.RhythmResult.BEAM,
				"enemy_timing": BattleMath.RhythmResult.POINT,
				"steal": 4,
				"perfect": false,
				"hero": hero,
				"enemy": enemy,
			}
		return {"winner": BattleMath.CounterWinner.ENEMY, "player_timing": BattleMath.RhythmResult.BEAM,
			"enemy_timing": BattleMath.RhythmResult.POINT, "steal": 4, "perfect": false}

var checks := 0
var b: FxBattle
var hero: BattleUnit
var ally: BattleUnit
var foe0: BattleUnit
var foe1: BattleUnit


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
	b.grotesque_fx.clear_all()
	for u in [hero, ally, foe0, foe1]:
		u.statuses.clear()
		u.bleeds.clear()
		u.burns.clear()
		u.haganah = {}
		u.trapped_actions = 0
		u.paralyzed_acts = 0
		u.passive_stance = false
		u.sturdy_def_bonus = 0
		u.sturdy_zahav = false
		u.skill_cooldowns.clear()
		u.weaken_mef_penalty = 0
		u.weaken_mak_penalty = 0
		u.sun_mark_hits = 0
		u.sun_mark_rounds = 0
		u.stats.max_hp = 1000
		u.current_hp = 1000
		u.stats.defense = 10
		u.stats.mef = 10
		u.stats.atk = 20
		u.stats.mak = 20
		u.stats.max_en = 40
		u.current_en = 40
		u.current_sp = 100
		u.acts_available = 4
	b.counter_rolls = 0
	b.force_counter_winner = -99
	b._player_interrupted = false
	b._enemy_interrupted = false
	b._counter_resolved = false
	b._announced_skill = &""
	b.log_history.clear()


func _run() -> void:
	b = FxBattle.new()
	b.offer_reserve = true
	root.add_child(b)
	for _i in 15:
		await process_frame
	hero = b._fallen
	ally = b._ally
	foe0 = b.hud.opponents[0]
	foe1 = b.hud.opponents[1]
	await _test_sturdy_basics_and_stone_body()
	await _test_sturdy_counter_no_interrupt()
	await _test_sturdy_debilitating_and_aegis_priority()
	await _test_blade_dance_rules()
	await _test_blade_dance_no_counter_menu_and_cooldown()
	print("VERIFY_D139_RULES_OK: %d checks; STURDY (round expiry, anti-interruption, debuff block & shatter, AEGIS IRIS priority, Stone Body +15 DEF lifetime, dispel vs Tahorah), IMEDIATO skills, Blade Dance (ALL ACT -> ACT+1 fixed 15 PHYS at 0 EN, interleaved 1/2 targets + mid-dance fallback, DEFEND-only no COUNTER, 2-round cooldown)" % checks)
	b.queue_free()
	quit(0)


func _test_sturdy_basics_and_stone_body() -> void:
	reset()
	var sp_before := hero.sp_base()
	var en_before := hero.current_en
	await b._execute_skill(hero, {"skill": &"rock_body", "extra": 0}, false)
	check(hero.has_status(&"sturdy"), "ROCK BODY grants STURDY")
	check(hero.current_en == en_before - 10, "ROCK BODY spends 10 EN (%d -> %d)" % [en_before, hero.current_en])
	check(hero.acts_available == 3, "ROCK BODY spends 1 ACT (4 -> 3)")
	check(hero.effective_def() == 10 and not hero.sturdy_zahav, "ROCK BODY adds no extra DEF and is not ZAHAV")
	check(SkillBook.is_immediate(&"rock_body") and SkillBook.is_immediate(&"stone_body"), "ROCK BODY and STONE BODY are IMEDIATO")

	# Tahorah preserves STURDY (positive buff), enemy dispel_positive removes it
	SkillFx.cleanse_all(hero)
	check(hero.has_status(&"sturdy"), "Tahorah (cleanse_all) preserves positive buff STURDY")
	var dispelled := SkillFx.dispel_positive(hero)
	check(dispelled >= 1 and not hero.has_status(&"sturdy"), "dispel_positive removes STURDY")

	# Stone Body [ZAHAV]: STURDY + 15 DEF while STURDY lasts, without mutating stats.defense or sp_base()
	reset()
	var def_base := hero.stats.defense
	await b._execute_skill(hero, {"skill": &"stone_body", "extra": 0}, false)
	check(hero.has_status(&"sturdy") and hero.sturdy_zahav, "STONE BODY grants ZAHAV STURDY")
	check(hero.current_en == 15, "STONE BODY spends 25 EN (40 -> 15)")
	check(hero.effective_def() == def_base + 15, "STONE BODY adds +15 effective DEF (%d)" % hero.effective_def())
	check(hero.stats.defense == def_base and hero.sp_base() == sp_before, "STONE BODY never mutates stats.defense or sp_base()")

	# Expira no fim do round (1 tick) e derruba +15 DEF junto
	SkillFx.tick(hero)
	check(not hero.has_status(&"sturdy") and hero.sturdy_def_bonus == 0 and hero.effective_def() == def_base,
		"STURDY and Stone Body +15 DEF expire at round end (1 tick)")


func _test_sturdy_counter_no_interrupt() -> void:
	reset()
	hero.apply_sturdy(0, 1, false)
	b.force_counter_winner = BattleMath.CounterWinner.ENEMY
	var hero_hp_before := hero.current_hp
	var foe_hp_before := foe0.current_hp
	await b._enemy_counter(hero, foe0, &"")
	check(hero.current_hp < hero_hp_before, "STURDY still takes counter damage (%d -> %d)" % [hero_hp_before, hero.current_hp])
	check(not b._player_interrupted, "STURDY prevents interruption when enemy wins COUNTER")
	check(foe0.current_hp < foe_hp_before, "STURDY lets hero's own attack still land after counter")
	check(hero.has_status(&"sturdy"), "Pure damage counter does NOT consume STURDY")

	# Same on enemy side when hero wins COUNTER against STURDY enemy
	reset()
	foe0.apply_sturdy(15, 1, true)
	b.force_counter_winner = BattleMath.CounterWinner.PLAYER
	var f_before := foe0.current_hp
	await b._execute_counter(hero, foe0, ally)
	check(foe0.current_hp < f_before, "STURDY enemy still takes player counter damage")
	check(not b._enemy_interrupted and not b._counter_resolved, "STURDY enemy is NOT interrupted by player COUNTER")


func _test_sturdy_debilitating_and_aegis_priority() -> void:
	# Debilitating effect blocked and consumes STURDY (dropping Stone Body +15 DEF too)
	reset()
	hero.apply_sturdy(15, 1, true)
	check(hero.effective_def() == 25, "Stone Body active (+15 DEF)")
	b._skill_hit_fx(foe0, hero, &"fang_sting", 0, false, R.POINT, R.MISS, false)
	check(hero.bleeds.is_empty(), "STURDY blocks debilitating BLEED")
	check(not hero.has_status(&"sturdy") and hero.effective_def() == 10,
		"Blocking debilitating effect consumes STURDY and drops Stone Body +15 DEF")
	# Subsequent debilitating effect now lands normally
	b._skill_hit_fx(foe0, hero, &"fang_sting", 0, false, R.POINT, R.MISS, false)
	check(hero.bleeds.size() == 1, "After STURDY broke, next BLEED lands normally")

	# Also blocks Weaken / Mark of Sun / Trap / Burn / Sleep
	for case_skill in [&"weaken", &"mark_of_sun", &"umbral_gaze", &"ignoma", &"pixie_dust"]:
		reset()
		hero.apply_sturdy(0, 1, false)
		var magic := bool(SkillBook.def(case_skill).get("magic", false)) or String(SkillBook.def(case_skill).kind) == "magic"
		b._skill_hit_fx(foe0, hero, case_skill, 0, false, R.POINT, R.MISS, magic)
		check(not hero.has_status(&"sturdy"), "STURDY consumed blocking %s" % case_skill)
		check(hero.weaken_mef_penalty == 0 and hero.sun_mark_hits == 0 and hero.trapped_actions == 0
			and hero.burns.is_empty() and not hero.has_status(&"sleep"),
			"STURDY completely blocked debilitating effect of %s" % case_skill)

	# Priority: AEGIS IRIS / Haganah absorbs FIRST, preserving STURDY!
	reset()
	hero.haganah = {"round": 1, "owner": &"eye", "non_prayer": true}
	hero.apply_sturdy(15, 1, true)
	b._skill_hit_fx(foe0, hero, &"fang_sting", 0, false, R.POINT, R.MISS, false)
	check(hero.bleeds.is_empty(), "AEGIS IRIS blocks BLEED")
	check(hero.has_status(&"sturdy") and hero.effective_def() == 25,
		"Priority AEGIS IRIS > STURDY: AEGIS absorbs first and preserves STURDY +15 DEF")


func _test_blade_dance_rules() -> void:
	# 4 ACT -> 5 hits at 0 EN alternating foe0 -> foe1 -> foe0 -> foe1 -> foe0, NO counter rolls!
	reset()
	hero.acts_available = 4
	hero.current_en = 0
	var hp0 := foe0.current_hp
	var hp1 := foe1.current_hp
	await b._execute_skill(hero, {"skill": &"blade_dance", "extra": 0}, false)
	check(hero.acts_available == 0, "BLADE DANCE consumes ALL remaining acts (4 -> 0)")
	check(hero.current_en == 0, "BLADE DANCE costs 0 EN")
	check(b.counter_rolls == 0, "BLADE DANCE cannot be countered (0 enemy counter rolls)")
	check(foe0.current_hp < hp0 and foe1.current_hp < hp1, "BLADE DANCE interleaved across both foes (foe0=%d, foe1=%d)" % [hp0 - foe0.current_hp, hp1 - foe1.current_hp])
	check((hp0 - foe0.current_hp) > (hp1 - foe1.current_hp), "With 5 hits across 2 foes, foe0 takes 3 hits > foe1's 2 hits")

	# 2 ACT -> 3 hits; single living target fallback (foe1 dead -> all 3 hits land on foe0)
	reset()
	hero.acts_available = 2
	foe1.current_hp = 0
	var hp0_solo := foe0.current_hp
	await b._execute_skill(hero, {"skill": &"blade_dance", "extra": 0}, false)
	check(hero.acts_available == 0, "BLADE DANCE spends all 2 acts -> 3 hits")
	check(foe0.current_hp < hp0_solo, "BLADE DANCE with 1 living foe lands all hits on it (%d dmg)" % [hp0_solo - foe0.current_hp])

	# Mid-dance kill redirect: foe0 dies on hit 1 -> remaining hits redirect to foe1
	reset()
	hero.acts_available = 2
	foe0.current_hp = 1
	var hp1_before := foe1.current_hp
	await b._execute_skill(hero, {"skill": &"blade_dance", "extra": 0}, false)
	check(not foe0.is_alive() and foe1.current_hp < hp1_before, "When foe0 dies mid-dance, remaining hits redirect to foe1")


func _test_blade_dance_no_counter_menu_and_cooldown() -> void:
	# Reaction menu when enemy announces BLADE DANCE: DEFEND allowed, FIGHT/COUNTER blocked
	reset()
	b._announced_skill = &"blade_dance"
	b.reaction_defender = hero
	var opts_target := b._commands(hero, true)
	check(opts_target.has("DEFEND") and not opts_target.has(b.FIGHT),
		"Against enemy BLADE DANCE, target may DEFEND but NOT FIGHT/COUNTER (got %s)" % str(opts_target))
	var opts_other := b._commands(ally, true)
	check(not opts_other.has(b.FIGHT),
		"Against enemy BLADE DANCE, other ally cannot FIGHT/COUNTER either (got %s)" % str(opts_other))
	b._announced_skill = &""

	# Cooldown: used Round 1 -> blocked Round 2 (CD 1R) -> ready Round 3 (CD 0)
	reset()
	await b._execute_skill(hero, {"skill": &"blade_dance", "extra": 0}, false)
	check(hero.skill_cooldown(&"blade_dance") == 2, "Used in Round 1: cooldown starts at 2")
	# End Round 1 -> Round 2 starts (tick)
	SkillFx.tick(hero)
	check(hero.skill_cooldown(&"blade_dance") == 1, "Round 2: cooldown is 1 (blocked)")
	# Verify enemy AI skips it while on cooldown
	foe0.skills.assign([&"blade_dance"])
	foe0.set_skill_cooldown(&"blade_dance", 1)
	check(b._enemy_choice(foe0, 2) == &"", "Enemy AI skips BLADE DANCE while on cooldown")
	# End Round 2 -> Round 3 starts (tick)
	SkillFx.tick(hero)
	check(hero.skill_cooldown(&"blade_dance") == 0, "Round 3: cooldown cleared (ready again)")
