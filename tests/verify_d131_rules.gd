extends SceneTree
## D-131 (criador 2026-11-27), Fase 1: regras do motor — DMG (sem tipagem), EN máx. temporário (Energy Blow), COND,
## dreno com teto de chefe (Drain Claw / Vital Claws), Weaken / Weakenen (acúmulo, teto -50%, piso 1, dispell),
## Mark of Sun (3 golpes, piso 5, expiração, dispell) e a seleção 2T. Sem VFX (Fase 3).
const SANDBOX := preload("res://tests/progress_sandbox.gd")
const R := BattleMath.RhythmResult

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
		u.paralyzed_acts = 0
		u.passive_stance = false
		u.boss_class = false
		u.race = &""
		u.prays = false
		u.battle_max_en_delta = 0
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
		u.current_en = 40
		u.stats.max_en = 40
		u.current_sp = 100
	hero.acts_available = 4
	b.roll = true
	b.ai_result = R.POINT
	b._hit_mods = {}
	b._second_target = null
	b._defender_defending = false
	b._current_skill = &""


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
	_taxonomy()
	_dmg()
	_energy_blow()
	_cond()
	_drain()
	_weaken()
	await _mark_of_sun()
	await _two_target()
	print("VERIFY_D131_RULES_OK: %d checks; DMG ignores DEF/MEF, Energy Blow COND + max EN steal, Drain Claw/Vital Claws 80%% heal + boss cap + BLEED, Weaken/Weakenen stack -50%% floor 1 + dispell, Mark of Sun 3 hits/floor 5/expiry/dispell, 2T" % checks)
	b.queue_free()
	quit(0)


# --------------------------------------------------------------------------- taxonomia
func _taxonomy() -> void:
	var expect := {
		&"stone_crush": ["PHYS", "PHYS", "1T"], &"energy_blow": ["MAGI", "DMG", "1T"], &"drain_claw": ["PHYS", "PHYS", "1T"],
		&"vital_claws": ["PHYS", "PHYS", "1T"], &"weaken": ["STAT", "", "1T"], &"weakenen": ["STAT", "", "2T"], &"mark_of_sun": ["STAT", "", "1T"]}
	for id in expect:
		var d := SkillBook.def(id)
		check(not d.is_empty(), "%s exists" % id)
		check(String(d.cat) == expect[id][0] and String(d.get("dmg_type", "")) == expect[id][1] and String(d.targets) == expect[id][2],
			"%s: taxonomy %s" % [id, expect[id]])
		check(not d.has("affinity"), "%s has NO affinity field (D-119)" % id)
	# retrocompatibilidade: as skills antigas continuam sem os campos novos e funcionam
	check(not SkillBook.def(&"lunge").has("cat") and not SkillBook.def(&"fang_spine").has("targets"), "older skills carry no D-131 fields")


# --------------------------------------------------------------------------- DMG
func _dmg() -> void:
	reset()
	var low := h(hero, foe, &"energy_blow")
	check(low > 0, "ENERGY BLOW hurts (%d)" % low)
	reset()
	foe.stats.defense = 1000
	foe.stats.mef = 1000
	var high := h(hero, foe, &"energy_blow")
	check(high == low, "DMG ignores DEF and MEF completely (%d vs %d)" % [high, low])
	reset()
	foe.stats.defense = 1000
	foe.stats.mef = 1000
	var phys := h(hero, foe, &"stone_crush")
	check(phys < low, "PHYS (STONE CRUSH) is still mitigated by DEF (%d < %d)" % [phys, low])
	# ritmo / bloqueio / desvio / SP continuam valendo
	reset()
	var beam := h(hero, foe, &"energy_blow", R.BEAM, R.MISS)
	check(beam < low and beam > 0, "DMG keeps the rhythm bar (BEAM hits for less: %d < %d)" % [beam, low])
	reset()
	check(h(hero, foe, &"energy_blow", R.POINT, R.POINT) == 0, "DMG can still be dodged (no contact)")
	reset()
	hero.current_sp = 100
	foe.current_sp = 100
	var even := h(hero, foe, &"energy_blow")
	reset()
	hero.current_sp = 140
	foe.current_sp = 100
	var adv := h(hero, foe, &"energy_blow")
	check(adv > even, "DMG keeps the SP advantage bonus (%d > %d)" % [adv, even])
	reset()
	var untouched := hero.stats.mak
	h(hero, foe, &"energy_blow")
	check(hero.stats.mak == untouched, "DMG does not mutate stats")


# --------------------------------------------------------------------------- Energy Blow: EN máx. temporário
func _energy_blow() -> void:
	reset()
	var sp_hero := hero.sp_base()
	var sp_foe := foe.sp_base()
	h(hero, foe, &"energy_blow")
	check(foe.battle_max_en_delta == -20 and foe.effective_max_en() == 20, "the foe loses half of its max EN (40 -> 20)")
	check(hero.battle_max_en_delta == 20 and hero.effective_max_en() == 60, "the user gains that max EN (40 -> 60)")
	check(foe.current_en == 20 and hero.current_en == 60, "current EN follows: foe clamped to 20, user +20")
	check(foe.stats.max_en == 40 and hero.stats.max_en == 40, "stats.max_en is never mutated (nothing reaches the save)")
	check(hero.sp_base() == sp_hero and foe.sp_base() == sp_foe, "sp_base() is untouched")
	# a segunda vez: metade do que sobrou
	h(hero, foe, &"energy_blow")
	check(foe.effective_max_en() == 10 and hero.effective_max_en() == 70, "a second hit takes half of the remaining 20")
	# recuperação respeita o teto temporário
	foe.recover_en_flat(99)
	hero.recover_en_flat(99)
	check(foe.current_en == 10 and hero.current_en == 70, "EN recovery uses the temporary max EN")
	# alvo sem EN (Yoch reza)
	reset()
	foe.start_praying(4)
	var before_hp := foe.current_hp
	h(hero, foe, &"energy_blow")
	check(before_hp - foe.current_hp > 0, "against a unit that prays the blow still deals its damage")
	check(foe.battle_max_en_delta == 0 and hero.battle_max_en_delta == 0 and foe.effective_max_en() == 0, "no EN is stolen from a unit without EN (Yoch)")
	# sem contato, nada é roubado
	reset()
	h(hero, foe, &"energy_blow", R.POINT, R.POINT)
	check(foe.battle_max_en_delta == 0, "a dodged blow steals nothing")
	# nova batalha = nova unidade: o delta não é persistido
	var fresh := BattleUnit.new(&"fresh", "Fresh", foe.stats, false)
	check(fresh.battle_max_en_delta == 0 and fresh.effective_max_en() == foe.stats.max_en, "a new battle starts with the real max EN")


# --------------------------------------------------------------------------- COND
func _cond() -> void:
	reset()
	check(not SkillFx.cond_met(&"energy_blow", foe, false), "COND: a healthy, active foe is not a valid target")
	check(SkillFx.cond_met(&"energy_blow", foe, true), "COND: a defending foe is vulnerable")
	foe.passive_stance = true
	check(SkillFx.cond_met(&"energy_blow", foe, false), "COND: a non-offensive action is vulnerable")
	reset()
	foe.trapped_actions = 2
	check(SkillFx.cond_met(&"energy_blow", foe, false), "COND: trapped (forced PASS) is vulnerable")
	reset()
	foe.paralyzed_acts = 1
	check(SkillFx.cond_met(&"energy_blow", foe, false), "COND: paralyzed is vulnerable")
	reset()
	foe.current_hp = 250
	check(SkillFx.cond_met(&"energy_blow", foe, false), "COND: exactly 1/4 of the max HP qualifies")
	foe.current_hp = 251
	check(not SkillFx.cond_met(&"energy_blow", foe, false), "COND: above 1/4 of the max HP does not")
	check(SkillFx.cond_met(&"stone_crush", foe, false), "a skill without COND is always allowed")
	# o herói não consegue usar: o ato não é gasto
	reset()
	hero.acts_available = 4
	var ok: bool = await b._execute_skill(hero, {"skill": &"energy_blow"}, false, foe)
	check(not ok and hero.acts_available == 4, "the hero cannot use ENERGY BLOW on a healthy foe and keeps its acts")
	# a IA só escolhe a skill quando algum herói cumpre a condição
	reset()
	check(b._cond_target_for_enemy(&"energy_blow") == null, "the AI has no valid target while every hero is healthy and active")
	ally.current_hp = 100
	check(b._cond_target_for_enemy(&"energy_blow") == ally, "the AI targets the hero that qualifies")
	reset()
	hero.passive_stance = true
	check(b._cond_target_for_enemy(&"energy_blow") == hero, "the AI targets a hero doing a non-offensive action")
	check(b._cond_target_for_enemy(&"stone_crush") != null, "a skill without COND keeps the usual target")


# --------------------------------------------------------------------------- Drain Claw / Vital Claws
func _drain() -> void:
	reset()
	hero.current_hp = 100
	var lost := h(hero, foe, &"drain_claw")
	var fixed := lost - 250
	check(fixed > 0, "DRAIN CLAW: the fixed part is mitigated by DEF and the bar (%d)" % fixed)
	check(hero.current_hp - 100 == int(floor(float(lost) * 0.8)), "DRAIN CLAW heals 80%% of the HP drained (%d of %d)" % [hero.current_hp - 100, lost])
	# parcela percentual com teto de chefe
	reset()
	foe.boss_class = true
	var boss_lost := h(hero, foe, &"drain_claw")
	check(boss_lost == fixed + 40, "DRAIN CLAW: the 1/4 part is capped at 40 against a boss (%d)" % boss_lost)
	reset()
	foe.race = PrayerBook.ANGEL
	check(h(hero, foe, &"drain_claw") == fixed + 40, "the cap also applies against an Angel")
	reset()
	foe.stats.max_hp = 4000
	foe.current_hp = 4000
	check(h(hero, foe, &"drain_claw") == fixed + 1000, "an ordinary foe has no cap (1/4 of 4000 = 1000)")
	# BLEED reduz a cura
	reset()
	hero.current_hp = 100
	hero.add_bleed(2)
	var l2 := h(hero, foe, &"drain_claw")
	check(hero.current_hp - 100 == int(round(float(int(floor(float(l2) * 0.8))) * 0.6)), "BLEED (-40%%) cuts the drain heal")
	# Vital Claws
	reset()
	hero.current_hp = 100
	hero.current_en = 10
	var v := h(hero, foe, &"vital_claws")
	check(v > 250 + fixed, "VITAL CLAWS: power 30 fixed part is stronger than DRAIN CLAW's (%d)" % v)
	check(hero.current_hp - 100 == int(floor(float(v) * 0.8)), "VITAL CLAWS heals 80%% too")
	check(foe.current_en == 25 and hero.current_en == 25, "VITAL CLAWS steals 15 EN from the target (foe 25, user 25)")
	reset()
	foe.boss_class = true
	var vb := h(hero, foe, &"vital_claws")
	check(vb - (v - 250) == 60, "VITAL CLAWS: the 1/4 part is capped at 60 against a boss")
	reset()
	hero.current_en = 38
	h(hero, foe, &"vital_claws")
	check(hero.current_en == 40, "the stolen EN respects the user's max EN")
	reset()
	foe.start_praying(3)
	hero.current_en = 10
	h(hero, foe, &"vital_claws")
	check(hero.current_en == 10, "no EN is stolen from a unit that prays")
	# sem contato: nada acontece
	reset()
	hero.current_hp = 100
	check(h(hero, foe, &"drain_claw", R.POINT, R.POINT) == 0 and hero.current_hp == 100, "a dodged claw drains and heals nothing")


# --------------------------------------------------------------------------- Weaken / Weakenen
func _weaken() -> void:
	reset()
	foe.stats.mef = 40
	var sp_before := foe.sp_base()
	h(hero, foe, &"weaken")
	# 5 + floor(0.5 * 20) = 15
	check(foe.weaken_mef_penalty == 15 and foe.effective_mef() == 25, "WEAKEN: MEF -(5 + 50%% of the user's MAK 20) = -15 (%d)" % foe.effective_mef())
	check(foe.stats.mef == 40 and foe.sp_base() == sp_before, "WEAKEN never mutates stats or sp_base()")
	check(foe.has_status(&"weaken_mef") and foe.weaken_mak_penalty == 0, "WEAKEN registers its status and leaves MAK alone")
	h(hero, foe, &"weaken")
	check(foe.weaken_mef_penalty == 20 and foe.effective_mef() == 20, "stacking is capped at -50%% of the base MEF (40 -> 20)")
	h(hero, foe, &"weaken")
	check(foe.effective_mef() == 20, "a third cast changes nothing at the cap")
	# piso 1
	reset()
	foe.stats.mef = 2
	h(hero, foe, &"weaken")
	check(foe.effective_mef() == 1, "effective floor 1 (base 2 -> 1)")
	reset()
	foe.stats.mef = 1
	h(hero, foe, &"weaken")
	check(foe.effective_mef() == 1 and foe.weaken_mef_penalty == 0, "a base of 1 cannot be lowered")
	# Weakenen: MAK e MEF
	reset()
	foe.stats.mef = 100
	foe.stats.mak = 100
	h(hero, foe, &"weakenen")
	check(foe.weaken_mef_penalty == 20 and foe.weaken_mak_penalty == 20, "WEAKENEN: MAK and MEF -(10 + 50%% MAK 20) = -20 each")
	check(foe.effective_mak() == 80.0 and foe.effective_mef() == 80, "effective MAK/MEF follow")
	h(hero, foe, &"weakenen")
	h(hero, foe, &"weakenen")
	h(hero, foe, &"weakenen")
	check(foe.effective_mak() == 50.0 and foe.effective_mef() == 50, "WEAKENEN caps at -50%% of both bases (100 -> 50)")
	# dano maior depois do Weaken (a MEF caiu)
	reset()
	hero.stats.mef = 40
	foe.stats.mak = 20
	var before_cut := h(foe, hero, &"ignoma")
	reset()
	hero.stats.mef = 40
	foe.stats.mak = 20
	h(foe, hero, &"weaken")
	var after_cut := h(foe, hero, &"ignoma")
	check(after_cut > before_cut, "a weakened target takes more magic damage (%d > %d)" % [after_cut, before_cut])
	# MAK baixa => o conjurador enfraquecido dá menos dano mágico
	reset()
	foe.stats.mak = 100
	var strong := h(foe, hero, &"ignoma")
	reset()
	foe.stats.mak = 100
	h(hero, foe, &"weakenen")
	var weak := h(foe, hero, &"ignoma")
	check(weak < strong, "WEAKENEN lowers the victim's own magic damage (%d < %d)" % [weak, strong])
	# Tahorah (cleanse_all) dispersa tudo
	reset()
	foe.stats.mef = 100
	foe.stats.mak = 100
	h(hero, foe, &"weakenen")
	var removed := SkillFx.cleanse_all(foe)
	check(removed >= 2 and foe.weaken_mef_penalty == 0 and foe.weaken_mak_penalty == 0, "Tahorah dispels WEAKEN/WEAKENEN whole (%d removed)" % removed)
	check(foe.effective_mef() == 100 and foe.effective_mak() == 100.0 and not foe.has_status(&"weaken_mef") and not foe.has_status(&"weaken_mak"), "the attributes are back")
	# Haganah / escudo de status bloqueia
	reset()
	foe.haganah = {"round": 1, "owner": &"x"}
	h(hero, foe, &"weaken")
	check(foe.weaken_mef_penalty == 0, "a status shield blocks WEAKEN")


# --------------------------------------------------------------------------- Mark of Sun
func _mark_of_sun() -> void:
	reset()
	h(hero, foe, &"mark_of_sun")
	check(foe.sun_mark_hits == 3 and foe.sun_mark_rounds == 2 and foe.has_status(&"mark_of_sun"), "MARK OF SUN: 3 charges, 2 round ticks")
	# o ataque "puro" (sem marca) para comparar
	reset()
	var plain := h(hero, foe, &"stone_crush")
	reset()
	foe.apply_sun_mark()
	var marked := h(hero, foe, &"stone_crush")
	check(marked == plain + 10, "a hit on a marked foe adds 20 - MEF(10) = 10 MAGI (%d vs %d+10)" % [marked, plain])
	check(foe.sun_mark_hits == 2, "one charge is spent")
	h(hero, foe, &"stone_crush")
	check(foe.sun_mark_hits == 1 and foe.has_status(&"mark_of_sun"), "second hit")
	h(hero, foe, &"stone_crush")
	check(foe.sun_mark_hits == 0 and not foe.has_status(&"mark_of_sun"), "the mark disappears on the 3rd hit")
	var after := h(hero, foe, &"stone_crush")
	check(after == plain, "no extra damage once the mark is gone")
	# piso 5 com MEF alta
	reset()
	foe.stats.mef = 100
	var plain_hi := h(hero, foe, &"stone_crush")
	reset()
	foe.stats.mef = 100
	foe.apply_sun_mark()
	check(h(hero, foe, &"stone_crush") == plain_hi + 5, "the extra damage never falls under 5 (MEF 100)")
	# Weaken + Mark of Sun: combo (a MEF baixa sobe o extra)
	reset()
	foe.stats.mef = 18
	foe.apply_sun_mark()
	var no_weak := h(hero, foe, &"stone_crush")
	reset()
	foe.stats.mef = 18
	h(hero, foe, &"weaken")  # MEF 18 -> cap 9 -> 9
	foe.apply_sun_mark()
	var with_weak := h(hero, foe, &"stone_crush")
	check(with_weak > no_weak, "WEAKEN raises the MARK OF SUN extra (%d > %d)" % [with_weak, no_weak])
	# sem contato / sem dano: nenhuma carga é gasta
	reset()
	foe.apply_sun_mark()
	h(hero, foe, &"stone_crush", R.POINT, R.POINT)
	check(foe.sun_mark_hits == 3, "a dodged hit spends no charge")
	h(hero, foe, &"weaken")
	check(foe.sun_mark_hits == 3, "a hit that deals no damage (a STAT skill) spends no charge")
	# renovar
	reset()
	foe.apply_sun_mark()
	h(hero, foe, &"stone_crush")
	h(hero, foe, &"mark_of_sun")
	check(foe.sun_mark_hits == 3 and foe.sun_mark_rounds == 2, "reapplying renews 3 charges and 2 ticks")
	# expira no fim do próximo round (2 ticks)
	reset()
	foe.apply_sun_mark()
	SkillFx.tick(foe)
	check(foe.sun_mark_hits == 3, "still marked after one round tick")
	SkillFx.tick(foe)
	check(foe.sun_mark_hits == 0 and not foe.has_status(&"mark_of_sun"), "the mark expires after the next round")
	# Tahorah
	reset()
	foe.apply_sun_mark()
	SkillFx.cleanse_all(foe)
	check(foe.sun_mark_hits == 0 and not foe.has_status(&"mark_of_sun"), "Tahorah dispels the mark")
	# multi-hit: cada acerto gatilha (Lunge: 2 acertos)
	reset()
	hero.apply_sun_mark()
	hero.stats.mef = 10
	b._second_target = null
	await b._skill_strike(foe, hero, &"lunge", false, false, true)
	check(hero.sun_mark_hits == 1, "each hit of a multi-hit skill triggers the mark (LUNGE: 3 -> 1, got %d)" % hero.sun_mark_hits)
	reset()
	hero.apply_sun_mark()
	await b._skill_strike(foe, hero, &"lunge", false, false, true)
	await b._skill_strike(foe, hero, &"lunge", false, false, true)
	check(hero.sun_mark_hits == 0 and not hero.has_status(&"mark_of_sun"), "the 3rd hit consumes the mark even mid-skill")
	# ataque simples também gatilha
	reset()
	foe.apply_sun_mark()
	b._strike(hero, foe, R.POINT, false)
	check(foe.sun_mark_hits == 2, "a plain attack triggers the mark too")
	# Dark Breath (sem dano) não gatilha
	reset()
	foe.apply_sun_mark()
	h(hero, foe, &"dark_breath")
	check(foe.sun_mark_hits == 3, "DARK BREATH (no damage) does not trigger it")
	# derrubar o alvo no golpe não explode
	reset()
	foe.apply_sun_mark()
	foe.current_hp = 1
	h(hero, foe, &"stone_crush")
	check(not foe.is_alive(), "sanity: the hit kills")


# --------------------------------------------------------------------------- 2T
func _two_target() -> void:
	# 2 alvos distintos (a IA ataca os dois heróis)
	reset()
	hero.stats.mef = 100
	ally.stats.mef = 100
	b._second_target = ally
	b._current_skill = &"weakenen"
	await b._skill_strike(foe, hero, &"weakenen", false, false, true)
	check(hero.weaken_mef_penalty == 20 and ally.weaken_mef_penalty == 20, "2T: each of the two distinct targets is weakened once (%d/%d)" % [hero.weaken_mef_penalty, ally.weaken_mef_penalty])
	# 1 alvo só vivo: aplica uma vez
	reset()
	hero.stats.mef = 100
	b._second_target = hero
	await b._skill_strike(foe, hero, &"weakenen", false, false, true)
	check(hero.weaken_mef_penalty == 20, "2T with a single target applies once (%d)" % hero.weaken_mef_penalty)
	reset()
	hero.stats.mef = 100
	b._second_target = null
	await b._skill_strike(foe, hero, &"weakenen", false, false, true)
	check(hero.weaken_mef_penalty == 20, "2T without a second target applies once")
	# a IA escolhe 2 alvos distintos (1, 2 e 3 vivos)
	reset()
	b._current_skill = &"weakenen"
	for _i in 30:
		check(b._enemy_second_target(hero) == ally, "AI 2T: with two living heroes the second target is the other one")
	ally.current_hp = 0
	check(b._enemy_second_target(hero) == hero, "AI 2T: with one living hero it lands on that one")
	ally.current_hp = 1000
	var third := BattleUnit.new(&"third", "Third", hero.stats, true)
	b.hud.players.append(third)
	var seen := {}
	for _i in 60:
		var pick: BattleUnit = b._enemy_second_target(hero)
		check(pick != hero, "AI 2T: never repeats the first target with three living")
		seen[pick.id] = true
	check(seen.size() == 2, "AI 2T: both other targets can be picked")
	b.hud.players.erase(third)
	# uma skill dual comum (FANG SPINE) continua podendo repetir o alvo
	b._current_skill = &"fang_spine"
	var again := {}
	for _i in 60:
		again[b._enemy_second_target(hero).id] = true
	check(again.size() == 2, "a plain dual skill may still repeat its first target")
	b._current_skill = &""
