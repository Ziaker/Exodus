extends SceneTree
## Creator 2026-11-23: absorption counter per enemy kind, a skill learned every 4
## absorptions, FIGHT + skills submenu, and the four first-fight skills (Lunge,
## Bleedbuff, Heat wave, Energy Eat) used by Fallen and by the enemies.
const SANDBOX := preload("res://tests/progress_sandbox.gd")

## Deterministic battle: enemy rolls and defenses MISS, no counters unless forced, the
## enemy AI draws `enemy_pick` (0 = ATTACK, 1.. = its skills in sheet order).
class SkillBattle extends "res://scripts/battle/playable_controller.gd":
	var enemy_pick := 0
	var force_enemy_counter := false
	var burn := true
	var ai_extra := 0
	var learn_pick := 0
	func _ai_roll(_a: BattleUnit, _b: BattleUnit) -> int: return BattleMath.RhythmResult.MISS
	func _defender_reaction(_a: BattleUnit, _b: BattleUnit) -> int: return BattleMath.RhythmResult.MISS
	func _zone_roll(_h: float) -> int: return BattleMath.RhythmResult.MISS
	func _enemy_counter_roll(_e: BattleUnit) -> bool: return force_enemy_counter
	func _enemy_skill_pick(n: int) -> int: return mini(enemy_pick, n - 1)
	func _burn_roll(_c: int) -> bool: return burn
	func _enemy_en_extra(_m: int) -> int: return ai_extra
	func _skill_pick(_n: int) -> int: return learn_pick

var checks := 0
const R := BattleMath.RhythmResult

func _initialize() -> void:
	SANDBOX.begin()
	call_deferred("_run")

func check(ok: bool, reason: String) -> void:
	if not ok:
		push_error(reason)
		quit(1)
		assert(ok, reason)
	checks += 1

func fresh(skills: Array[StringName] = []) -> Control:
	var battle := SkillBattle.new()
	root.add_child(battle)
	battle._fallen.skills.assign(skills)
	return battle

func wait_seconds(seconds: float) -> void:
	var waited := 0.0
	while waited < seconds:
		await process_frame
		waited += root.get_process_delta_time()

func wait_mode(battle: Control, mode: String, seconds: float = 4.0) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while battle.hud.mode != mode and Time.get_ticks_msec() < deadline:
		await process_frame

func dmg_lines(battle: Control, from: int, prefix: String) -> Array:
	return battle.log_history.slice(from).filter(func(l: String) -> bool: return l.begins_with(prefix) and l.contains(" dmg ("))

## Presses the live rail at the given fractions of the pass.
func press_at(battle: Control, fractions: Array) -> void:
	for f in fractions:
		battle.rhythm._elapsed = float(f) * battle.rhythm.duration
		battle.handle_confirm()

func _run() -> void:
	# ---- Pure rules.
	check(SkillBook.learnable(&"genetic_foe_a", []) == [&"lunge", &"bleedbuff"], "FOE A teaches Lunge and Bleedbuff")
	check(SkillBook.learnable(&"genetic_foe_b", [&"heat_wave"]) == [&"energy_eat"], "Known skills are skipped")
	check(SkillBook.learnable(&"genetic_foe_b", [&"heat_wave", &"energy_eat"]).is_empty(), "Nothing left to learn")
	check(not SkillBook.affordable(&"bleedbuff", 2, 10, 4) and SkillBook.affordable(&"bleedbuff", 2, 0, 5), "Bleedbuff needs more than 4 HP")
	check(not SkillBook.affordable(&"heat_wave", 1, 10, 10) and SkillBook.affordable(&"heat_wave", 2, 6, 1), "Heat wave needs 2 acts and 6 EN")
	check(not SkillBook.affordable(&"lunge", 1, 3, 10), "Lunge needs 4 EN")
	for skill in SkillBook.DEFS:
		check(int(SkillBook.DEFS[skill].pp) == 0, "First-fight skills use no PP")
	check(BattleMath.rhythm_zone_at(0.35, 0.35) == R.POINT and BattleMath.rhythm_zone_at(0.48, 0.35) == R.BEAM and BattleMath.rhythm_zone_at(0.65, 0.35) == R.MISS, "Zones around a 35% mark")

	# ---- Save: counters and skills persist next to the gains.
	ProgressStore.save_skill_progress({"genetic_foe_a": 3}, [&"lunge"])
	ProgressStore.save_gains({"atk": 2})
	check(ProgressStore.load_absorbs().get("genetic_foe_a", 0) == 3 and ProgressStore.load_skills() == [&"lunge"], "save_gains keeps counters and skills")
	check(int(ProgressStore.load_gains().get("atk", 0)) == 2, "save_skill_progress keeps gains")
	ProgressStore.clear()

	# ---- Counter: 1/4 .. 4/4 + NEW SKILL, then the next skill, then MAX.
	var battle := fresh()
	var foe_a: BattleUnit = battle.hud.opponents[0]
	var fallen: BattleUnit = battle._fallen
	battle.learn_pick = 1
	for n in range(1, 4):
		battle._count_absorption(fallen, foe_a)
		check(battle.absorb_count_label == "%d/4" % n and battle.absorb_skill_label == "", "Absorption %d of FOE A: %d/4" % [n, n])
	battle._count_absorption(fallen, foe_a)
	check(battle.absorb_count_label == "4/4" and battle.absorb_skill_label == "NEW SKILL: BLEEDBUFF", "4th absorption teaches the drawn skill (got %s / %s)" % [battle.absorb_count_label, battle.absorb_skill_label])
	check(fallen.skills == [&"bleedbuff"] and ProgressStore.load_skills() == [&"bleedbuff"], "The skill is learned and saved")
	check(int(ProgressStore.load_absorbs().get("genetic_foe_a", -1)) == 0, "The counter restarts after a skill")
	for n in range(1, 5):
		battle._count_absorption(fallen, foe_a)
	check(battle.absorb_skill_label == "NEW SKILL: LUNGE" and fallen.skills.has(&"lunge"), "Next 4 absorptions teach the remaining skill")
	battle._count_absorption(fallen, foe_a)
	check(battle.absorb_count_label == "MAX" and battle.absorb_skill_label == "", "All FOE A skills known: MAX")
	var foe_b: BattleUnit = battle.hud.opponents[1]
	battle._count_absorption(fallen, foe_b)
	check(battle.absorb_count_label == "1/4", "FOE B counts on its own (got %s)" % battle.absorb_count_label)
	battle.queue_free(); await process_frame

	# ---- Skills survive a defeat restart (gains do not).
	Engine.set_meta(&"exodus_restart_at_base", true)
	battle = SkillBattle.new()
	root.add_child(battle)
	check(battle._fallen.skills == [&"bleedbuff", &"lunge"] and not battle.apply_saved_gains, "Learned skills are kept after a defeat restart")
	check(int(ProgressStore.load_absorbs().get("genetic_foe_b", 0)) == 1, "Counters are loaded from the save")
	battle.queue_free(); await process_frame
	ProgressStore.clear()

	# ---- FIGHT replaces ATTACK; without skills it goes straight to the target.
	battle = fresh()
	check(battle.hud.mode == "plan" and battle.hud.plan_options[0] == "FIGHT" and not battle.hud.plan_options.has("ATTACK"), "The command is FIGHT")
	battle.submit_plan(0)
	check(battle.hud.mode == "plan", "Without skills FIGHT is committed like the old ATTACK")
	battle.exec_plan()
	check(battle.hud.mode == "target", "FIGHT without skills goes to the target")
	battle.queue_free(); await process_frame

	# ---- Submenu: ATTACK + skills, dimmed rows, log text, reject, Energy Eat extra.
	battle = fresh([&"lunge", &"heat_wave", &"energy_eat", &"bleedbuff"])
	fallen = battle._fallen
	fallen.current_en = 6
	fallen.current_hp = 4
	battle.submit_plan(0)
	check(battle.hud.mode == "skill" and battle.hud.command_options == ["ATTACK", "LUNGE", "HEAT WAVE", "ENERGY EAT", "BLEEDBUFF"], "FIGHT opens ATTACK + skills (got %s)" % [battle.hud.command_options])
	check(battle.skill_disabled == [4], "Only Bleedbuff (4 HP) is dimmed with 2 acts / 6 EN (got %s)" % [battle.skill_disabled])
	battle.hud.command_index = 1
	check(battle.hud._log_text().begins_with("LUNGE 1 ACT / 4 EN"), "The log explains the highlighted skill")
	battle.hud.command_index = 4
	check(battle.hud._log_text().ends_with("| NO HP"), "A dimmed skill says why")
	battle.submit_skill(4)
	check(battle.hud.mode == "skill", "A dimmed skill is refused")
	battle.submit_skill(3)
	check(battle.hud.mode == "en_extra" and battle.en_extra_max == 0, "Energy Eat asks the extra EN (none left above its 6)")
	battle.cancel_en_extra()
	check(battle.hud.mode == "skill", "X on the extra EN line goes back to the submenu")
	battle.cancel_skill()
	check(battle.hud.mode == "plan" and battle._planned.is_empty(), "X on the submenu goes back to the plan, nothing committed")
	fallen.current_en = 10
	battle.submit_plan(0)
	battle.submit_skill(3)
	battle.adjust_en_extra(1); battle.adjust_en_extra(1); battle.adjust_en_extra(5)
	check(battle.en_extra == 4 and battle.hud._menu_rows() == ["EXTRA EN  < 4 >"], "Left/Right set the extra EN up to the EN left")
	battle.adjust_en_extra(-1)
	battle.confirm_en_extra()
	check(battle.hud.mode == "plan" and battle._planned_skills == [{"skill": &"energy_eat", "extra": 3}], "Energy Eat +3 EN is committed")
	battle.submit_plan(0)
	check(battle.skill_disabled.has(2) and battle.skill_disabled.has(1), "1 act left and 1 EN left: Heat wave (2 ACT) and Lunge (4 EN) are dimmed (got %s)" % [battle.skill_disabled])
	battle.cancel_skill()
	battle.undo_plan()
	check(battle._planned.is_empty() and battle._planned_skills.is_empty(), "UNDO removes the last command and its skill")
	battle.submit_plan(0)
	battle.submit_skill(0)
	check(battle._planned_skills.size() == 1 and battle._planned_skills[0].is_empty() and battle.planned_acts_for(fallen) == 1, "ATTACK from the submenu is a plain FIGHT (1 act)")
	battle.queue_free(); await process_frame

	# ---- Energy Eat: heals 5 + extra, pays 6 + extra EN, 1 act.
	battle = fresh([&"energy_eat"])
	fallen = battle._fallen
	fallen.current_hp = 2
	fallen.current_en = 10
	battle.submit_plan(0)
	battle.submit_skill(1)
	battle.adjust_en_extra(1); battle.adjust_en_extra(1)
	battle.confirm_en_extra()
	var acts0: int = fallen.acts_available
	battle.exec_plan()
	check(fallen.current_hp == 9 and fallen.current_en == 2 and fallen.acts_available == acts0 - 1, "Energy Eat +2: +7 HP, -8 EN, 1 act (HP %d EN %d)" % [fallen.current_hp, fallen.current_en])
	battle.queue_free(); await process_frame

	# ---- Bleedbuff: 2 acts, -4 HP, +25% ATK per stage, stacking, expires 1 round later.
	battle = fresh([&"bleedbuff"])
	fallen = battle._fallen
	fallen.current_hp = 14
	battle.submit_plan(0)
	battle.submit_skill(1)
	check(battle.hud.mode != "plan", "Bleedbuff fills both planned acts: the plan executes at once")
	await wait_mode(battle, "continue")
	check(fallen.current_hp == 10 and fallen.atk_stages.size() == 1, "Bleedbuff costs 4 HP and adds one ATK stage")
	check(is_equal_approx(fallen.effective_atk(), fallen.stats.atk * 1.25), "One stage = +25% ATK")
	fallen.atk_stages.append({"round": battle.state.round_number, "owner": fallen.id})
	check(is_equal_approx(fallen.effective_atk(), fallen.stats.atk * 1.5), "Stages stack (+50%)")
	battle.state.round_number += 1
	battle._expire_stages(battle._ally)
	check(fallen.atk_stages.size() == 2, "Another unit's turn does not end Fallen's stage")
	battle._expire_stages(fallen)
	check(fallen.atk_stages.is_empty(), "Next round, at Fallen's turn again, the stages end")
	fallen.atk_stages.append({"round": battle.state.round_number - 1, "owner": battle.hud.opponents[0].id})
	battle._expire_stages(null)
	check(fallen.atk_stages.is_empty(), "If the owner never came back, the stage ends at the end of the next round")
	battle.queue_free(); await process_frame

	# ---- Lunge by Fallen: TWO normal bars, one per hit, one after the other (creator
	# 2026-11-23: "it was never one bar"), two hits of power 5.
	battle = fresh([&"lunge"])
	fallen = battle._fallen
	foe_a = battle.hud.opponents[0]
	foe_a.current_hp = 999
	battle.submit_plan(0)
	battle.submit_skill(1)
	battle.exec_plan()
	check(battle.hud.mode == "target", "Lunge asks for a target")
	var from: int = battle.log_history.size()
	battle.submit_target(0)
	check(battle.hud.mode == "timing" and battle.rhythm.marks == [0.5], "Lunge: the first bar is a normal bar (got %s)" % [battle.rhythm.marks])
	press_at(battle, [0.5])
	await wait_mode(battle, "timing")
	check(battle.hud.mode == "timing" and battle.rhythm.marks == [0.5], "Lunge: a second normal bar follows the first")
	press_at(battle, [0.5])
	await wait_mode(battle, "continue")
	check(battle.attack_result == R.POINT, "Both bars judged POINT")
	check(dmg_lines(battle, from, "FALLEN -> GENETIC FOE A").size() == 2, "Lunge lands twice")
	check(fallen.current_en == fallen.stats.max_en - 4, "Lunge costs 4 EN")
	battle.proceed()
	await wait_mode(battle, "plan")
	battle.submit_plan(0)
	battle.submit_skill(0)
	battle.exec_plan()
	battle.submit_target(0)
	check(battle.rhythm.marks == [0.5], "A plain ATTACK after Lunge is back to one centre mark")
	battle.queue_free(); await process_frame

	# ---- Each bar is judged on its own: a missed first bar, a POINT on the second.
	battle = fresh([&"lunge"])
	battle.hud.opponents[0].current_hp = 999
	from = battle.log_history.size()
	battle.submit_plan(0); battle.submit_skill(1); battle.exec_plan(); battle.submit_target(0)
	press_at(battle, [0.95])
	await wait_mode(battle, "timing")
	press_at(battle, [0.5])
	await wait_mode(battle, "continue")
	var lunge_lines: Array = battle.log_history.slice(from).filter(func(l: String) -> bool: return l.begins_with("FALLEN -> GENETIC FOE A"))
	check(lunge_lines.size() == 2 and lunge_lines[0].contains("NO CONTACT") and not lunge_lines[1].contains("NO CONTACT"), "First bar MISS, second bar POINT (got %s)" % [lunge_lines])
	battle.queue_free(); await process_frame

	# ---- Heat wave by Fallen: MAK vs MEF on every enemy, burn, burn ticks next round.
	battle = fresh([&"heat_wave"])
	fallen = battle._fallen
	for foe in battle.hud.opponents: foe.current_hp = 999
	battle.submit_plan(0); battle.submit_skill(1); battle.exec_plan()
	check(battle.hud.mode == "timing" and battle.rhythm.marks == [0.5], "Heat wave: one attack rail, no target choice")
	from = battle.log_history.size()
	press_at(battle, [0.5])
	await wait_mode(battle, "continue")
	check(dmg_lines(battle, from, "FALLEN -> GENETIC FOE A").size() == 1 and dmg_lines(battle, from, "FALLEN -> GENETIC FOE B").size() == 1, "Heat wave hits both enemies")
	check(dmg_lines(battle, from, "FALLEN -> GENETIC FOE A")[0].contains("affinity NORMAL"), "IGNI is normal for everyone (FOE A is WEAK physically)")
	check(battle.hud.opponents[0].burns == [3] and battle.hud.opponents[1].burns == [3], "Burn applied for 3 rounds")
	check(fallen.acts_available == 0 and fallen.current_en == fallen.stats.max_en - 6, "Heat wave costs 2 acts and 6 EN")
	var hp_a: int = battle.hud.opponents[0].current_hp
	battle.hud.opponents[0].burns.append(3)
	await battle._burn_tick()
	check(battle.hud.opponents[0].current_hp == hp_a - 6 and battle.hud.opponents[0].burns == [2, 2], "Two stacked burns: -6 HP, one round less each")
	battle.queue_free(); await process_frame

	# ---- Magic formula: power 5 x MAK / MEF (variation only, no crit / SP roll here).
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var magic := BattleMath.physical_damage(5, 8.0, 0, 2, 10, 10, BattleMath.Affinity.NORMAL, rng)
	check(is_equal_approx(float(magic.base), 20.0), "5 x MAK 8 / MEF 2 = base 20")

	# ---- Enemy Lunge with no reaction: guaranteed two hits on the hero.
	battle = fresh()
	battle.enemy_pick = 1
	battle._fallen.current_hp = 999; battle._ally.current_hp = 999
	battle.hud.opponents[1].current_hp = 0  # FOE B down: FOE A (Lunge) acts
	from = battle.log_history.size()
	battle.submit_command(battle.hud.command_options.find("REACT"))
	battle.submit_command(battle.hud.command_options.find("REACT"))
	await wait_mode(battle, "react")
	check(battle.log_history.any(func(l: String) -> bool: return l.contains("announces LUNGE on")), "The enemy announces LUNGE")
	check(battle.hud.message.contains("USES LUNGE ON"), "The reaction prompt names the skill")
	var hero: BattleUnit = battle.action_defender
	var lunger: BattleUnit = battle.action_attacker
	battle.answer_reaction(false)
	await wait_mode(battle, "continue")
	check(dmg_lines(battle, from, lunger.display_name + " -> " + hero.display_name).size() == 2, "Unanswered Lunge lands twice")
	check(lunger.current_en == lunger.stats.max_en - 4, "The enemy pays Lunge's EN")
	battle.queue_free(); await process_frame

	# ---- Enemy Lunge answered by DEFEND: the defense rail has the two marks.
	battle = fresh()
	battle.enemy_pick = 1
	battle._fallen.current_hp = 999; battle._ally.current_hp = 999
	battle.hud.opponents[1].current_hp = 0  # FOE B down: FOE A (Lunge) acts
	battle.submit_command(battle.hud.command_options.find("REACT"))
	battle.submit_command(battle.hud.command_options.find("REACT"))
	await wait_mode(battle, "react")
	hero = battle.action_defender
	battle.select_reactor(battle.hud.players.find(hero))
	battle.answer_reaction(true)
	battle.submit_command(battle.hud.command_options.find("DEFEND"))
	await wait_mode(battle, "timing")
	check(battle.timing_role == "DEFEND" and battle.rhythm.marks == [0.5] and battle.rhythm.style == "defense", "DEFEND against Lunge: a normal defense bar")
	var hp_before: int = hero.current_hp
	press_at(battle, [0.5])
	await wait_mode(battle, "timing")
	check(battle.timing_role == "DEFEND", "DEFEND against Lunge: a second defense bar follows")
	press_at(battle, [0.5])
	await wait_mode(battle, "continue")
	check(hero.current_hp == hp_before, "Two perfect defenses: both Lunge hits dodged")
	battle.queue_free(); await process_frame

	# ---- Counter against an enemy Lunge: a winning enemy lands the whole Lunge.
	battle = fresh()
	battle.enemy_pick = 1
	battle._fallen.current_hp = 999; battle._ally.current_hp = 999
	battle.hud.opponents[1].current_hp = 0  # FOE B down: FOE A (Lunge) acts
	battle.submit_command(battle.hud.command_options.find("REACT"))
	battle.submit_command(battle.hud.command_options.find("REACT"))
	await wait_mode(battle, "react")
	hero = battle.action_defender
	lunger = battle.action_attacker
	battle.select_reactor(battle.hud.players.find(hero))
	battle.answer_reaction(true)
	battle.submit_command(battle.hud.command_options.find("FIGHT"))
	check(battle.hud.mode == "counter", "A hero without skills counters a Lunge on the two rails")
	from = battle.log_history.size()
	battle.counter.finish(R.MISS, R.POINT)
	await wait_mode(battle, "continue")
	check(dmg_lines(battle, from, lunger.display_name + " -> " + hero.display_name).size() == 2, "Enemy wins the exchange: both Lunge hits land on the reactor")
	battle.queue_free(); await process_frame

	# ---- Enemy Heat wave: announced to each hero, hits both, burns.
	battle = fresh()
	battle.enemy_pick = 1
	battle._fallen.current_hp = 999; battle._ally.current_hp = 999
	battle.hud.opponents[0].current_hp = 0  # FOE A down: FOE B (Heat wave) acts
	battle.submit_command(battle.hud.command_options.find("REACT"))
	battle.submit_command(battle.hud.command_options.find("REACT"))
	from = battle.log_history.size()
	await wait_mode(battle, "react")
	check(battle.log_history.any(func(l: String) -> bool: return l.contains("announces HEAT WAVE on")), "The enemy announces HEAT WAVE")
	battle.answer_reaction(false)
	await wait_mode(battle, "react")
	check(battle.hud.mode == "react" and battle.action_defender != null, "Heat wave is announced to the second hero too")
	battle.answer_reaction(false)
	await wait_mode(battle, "continue")
	check(dmg_lines(battle, from, "GENETIC FOE B -> FALLEN").size() == 1 and dmg_lines(battle, from, "GENETIC FOE B -> " + battle._ally.display_name).size() == 1, "Heat wave hits both heroes")
	check(battle._fallen.burns == [3] and battle._ally.burns == [3], "Both heroes burn")
	battle.queue_free(); await process_frame

	# ---- Enemy Energy Eat and Bleedbuff resolve without announcement.
	battle = fresh()
	battle.enemy_pick = 2
	battle.ai_extra = 2
	battle.hud.opponents[0].current_hp = 0
	var eater: BattleUnit = battle.hud.opponents[1]
	eater.current_hp = 1
	eater.stats.max_en = 16  # room for extra EN (FOE B has only 6 EN in the game)
	eater.current_en = 16
	battle.submit_command(battle.hud.command_options.find("REACT"))
	battle.submit_command(battle.hud.command_options.find("REACT"))
	await wait_mode(battle, "continue")
	check(eater.current_hp == 8 and eater.current_en == 8, "Enemy Energy Eat +2 EN: +7 HP, -8 EN (HP %d EN %d)" % [eater.current_hp, eater.current_en])
	battle.queue_free(); await process_frame

	# ---- Skill as a reaction: Fallen reacts with Energy Eat.
	battle = fresh([&"energy_eat"])
	battle.submit_command(battle.hud.command_options.find("REACT"))
	battle.submit_command(battle.hud.command_options.find("REACT"))
	await wait_mode(battle, "react")
	battle.select_reactor(0)
	battle.answer_reaction(true)
	battle.submit_command(battle.hud.command_options.find("FIGHT"))
	check(battle.hud.mode == "skill", "In a reaction, FIGHT with skills opens the submenu")
	battle._fallen.current_hp = 3
	var sp0: int = battle._fallen.current_sp
	battle.submit_skill(1)
	battle.confirm_en_extra()
	check(battle._fallen.current_hp == 8 and battle._fallen.current_sp == sp0 + 1, "Reaction Energy Eat heals and gives the reaction SP")
	battle.queue_free(); await process_frame

	# ---- Enemy counter against Fallen's Lunge: winning hero lands both hits.
	battle = fresh([&"lunge"])
	battle.force_enemy_counter = true
	battle._fallen.current_hp = 999
	battle.hud.opponents[0].current_hp = 999
	battle.submit_plan(0); battle.submit_skill(1); battle.exec_plan(); battle.submit_target(0)
	check(battle.hud.mode == "counter" and battle.counter.style == "enemy", "The enemy may counter Fallen's Lunge")
	from = battle.log_history.size()
	battle.counter.finish(R.POINT, R.MISS)
	await wait_mode(battle, "continue")
	check(dmg_lines(battle, from, "FALLEN -> GENETIC FOE A").size() == 2, "Fallen wins: the whole Lunge lands")
	battle.queue_free(); await process_frame

	# ---- Counter against an enemy Heat wave: a winning enemy burns every hero.
	battle = fresh()
	battle.enemy_pick = 1
	battle._fallen.current_hp = 999; battle._ally.current_hp = 999
	battle.hud.opponents[0].current_hp = 0
	battle.submit_command(battle.hud.command_options.find("REACT"))
	battle.submit_command(battle.hud.command_options.find("REACT"))
	await wait_mode(battle, "react")
	hero = battle.action_defender
	battle.select_reactor(battle.hud.players.find(hero))
	battle.answer_reaction(true)
	battle.submit_command(battle.hud.command_options.find("FIGHT"))
	from = battle.log_history.size()
	battle.counter.finish(R.MISS, R.POINT)
	await wait_mode(battle, "continue")
	check(dmg_lines(battle, from, "GENETIC FOE B -> FALLEN").size() == 1 and dmg_lines(battle, from, "GENETIC FOE B -> " + battle._ally.display_name).size() == 1, "Enemy wins the exchange: Heat wave lands on every hero")
	battle.queue_free(); await process_frame

	# ---- Counter against an enemy Heat wave: a winning hero cancels it for everyone.
	battle = fresh()
	battle.enemy_pick = 1
	battle._fallen.current_hp = 999; battle._ally.current_hp = 999
	battle.hud.opponents[0].current_hp = 0
	battle.hud.opponents[1].current_hp = 999
	battle.submit_command(battle.hud.command_options.find("REACT"))
	battle.submit_command(battle.hud.command_options.find("REACT"))
	await wait_mode(battle, "react")
	hero = battle.action_defender
	battle.select_reactor(battle.hud.players.find(hero))
	battle.answer_reaction(true)
	battle.submit_command(battle.hud.command_options.find("FIGHT"))
	from = battle.log_history.size()
	battle.counter.finish(R.POINT, R.MISS)
	await wait_mode(battle, "continue")
	check(dmg_lines(battle, from, "GENETIC FOE B -> ").is_empty() and battle._fallen.burns.is_empty() and battle._ally.burns.is_empty(), "Hero wins: the Heat wave is interrupted")
	battle.queue_free(); await process_frame

	# ---- Fallen's Heat wave countered (first enemy that rolls): hero loses -> no wave.
	battle = fresh([&"heat_wave"])
	battle.force_enemy_counter = true
	battle._fallen.current_hp = 999
	for foe in battle.hud.opponents: foe.current_hp = 999
	battle.submit_plan(0); battle.submit_skill(1); battle.exec_plan()
	check(battle.hud.mode == "counter" and battle.action_defender == battle.hud.opponents[0], "The first enemy that rolls counters Fallen's Heat wave")
	from = battle.log_history.size()
	battle.counter.finish(R.MISS, R.POINT)
	await wait_mode(battle, "continue")
	check(dmg_lines(battle, from, "FALLEN -> ").is_empty() and dmg_lines(battle, from, "GENETIC FOE A -> FALLEN").size() == 1, "Enemy wins: no Heat wave, the enemy strikes Fallen")
	battle.queue_free(); await process_frame

	# ---- Enemy Bleedbuff: -4 HP, +1 ATK stage, no announcement.
	battle = fresh()
	battle.enemy_pick = 2
	battle.hud.opponents[1].current_hp = 0
	var buffer: BattleUnit = battle.hud.opponents[0]
	buffer.current_hp = 10
	battle.submit_command(battle.hud.command_options.find("REACT"))
	battle.submit_command(battle.hud.command_options.find("REACT"))
	await wait_mode(battle, "continue")
	check(buffer.current_hp == 6 and buffer.atk_stages.size() == 1 and buffer.acts_available == 0, "Enemy Bleedbuff: -4 HP, +1 stage, both acts")
	battle.queue_free(); await process_frame

	# ---- Absorption label: counter line under the gain, NEW SKILL on the 4th.
	ProgressStore.save_skill_progress({"genetic_foe_a": 3}, [])
	battle = fresh()
	battle.learn_pick = 0
	battle.hud.opponents[0].current_sp = 4
	battle.submit_command(battle.hud.command_options.find("ABSORB"))
	battle.submit_target(0)
	for i in 3: battle.handle_confirm()
	var deadline := Time.get_ticks_msec() + 6000
	while not battle.hud.opponents[0].absorbed and Time.get_ticks_msec() < deadline:
		await process_frame
	await wait_seconds(0.1)
	var label_fx: Array = battle.fx.effects.filter(func(e: Dictionary) -> bool: return e.kind == "ABSORBED")
	check(label_fx.size() == 1 and label_fx[0].lines == ["ABSORBED", "+2 ATK", "4/4", "NEW SKILL: LUNGE"], "ABSORBED / gain / 4/4 / NEW SKILL (got %s)" % [label_fx[0].lines if label_fx.size() > 0 else []])
	check(battle._fallen.skills == [&"lunge"], "Fallen learned Lunge in the battle")
	battle.queue_free(); await process_frame

	print("PLAYABLE_SKILLS_OK: %d checks; counter/MAX, learning, save, FIGHT submenu, Lunge, Bleedbuff, Heat wave, burn, Energy Eat, enemy skills, reactions, counters" % checks)
	await process_frame
	await process_frame
	quit(0)

func _finalize() -> void:
	SANDBOX.end()
