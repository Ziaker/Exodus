extends SceneTree
## D-048 Reza of Yoch (creator's answers of 2026-11-23): PP in place of EN (+2 SP each,
## cap 8, persisted, zeroed by a defeat), PRAY (+1 PP, enemies may attack it: any contact
## interrupts), Refuah / Haganah / Ra'am, PP paid when queued, +1 PP by re-selecting a queued
## spell on the same target, refunds on interruption, Ra'am counter-attack on two rails.
const SANDBOX := preload("res://tests/progress_sandbox.gd")

class PrayBattle extends "res://scripts/battle/playable_controller.gd":
	func _enemy_skill_pick(_n: int) -> int: return 0
	var enemy_timing := BattleMath.RhythmResult.MISS
	var pray_reaction := false
	var raam_counter := false
	var hero_timing := BattleMath.RhythmResult.POINT
	func _ai_roll(_a: BattleUnit, _b: BattleUnit) -> int: return enemy_timing
	func _defender_reaction(_a: BattleUnit, _b: BattleUnit) -> int: return BattleMath.RhythmResult.MISS
	## Enemy defense rolls on the skill rail (Ra'am) always miss: outcomes come from the test.
	func _zone_roll(_half: float) -> int: return BattleMath.RhythmResult.MISS
	func _enemy_counter_roll(_e: BattleUnit) -> bool: return false
	func _enemy_pray_reaction_roll(_e: BattleUnit) -> bool: return pray_reaction
	func _enemy_raam_counter_roll(_e: BattleUnit) -> bool: return raam_counter
	func _skill_attack_timing(attacker: BattleUnit, defender: BattleUnit, marks: Array[float], auto_hit: bool) -> Array[int]:
		if attacker.is_player:
			action_attacker = attacker
			action_defender = defender
			attack_result = hero_timing
			return [hero_timing]
		return await super._skill_attack_timing(attacker, defender, marks, auto_hit)

var checks := 0

func _initialize() -> void:
	SANDBOX.begin()
	call_deferred("_run")

func _finalize() -> void:
	SANDBOX.end()

func check(ok: bool, reason: String) -> void:
	if not ok:
		push_error(reason)
		quit(1)
		assert(ok, reason)
	checks += 1

func fresh(pp: int) -> Control:
	ProgressStore.clear()
	ProgressStore.save_pp(pp)
	var battle := PrayBattle.new()
	battle.offer_reserve = true  # creator 2026-11-24: REACT left the own-turn menu
	root.add_child(battle)
	return battle

func yoch(battle: Control) -> BattleUnit: return battle.hud.players[1]
func fallen(battle: Control) -> BattleUnit: return battle.hud.players[0]

## Fallen rests; Yoch (with `acts` acts) opens his plan.
## These cases test the prayer, not the turn order (verify_playable_reactions), so Yoch is
## moved right after Fallen: FOE B would otherwise win the AGI 5 tie on SP and play first.
func to_yoch(battle: Control, acts: int) -> void:
	var order: Array[BattleUnit] = battle.state.turn_order
	order.erase(yoch(battle))
	order.insert(order.find(fallen(battle)) + 1, yoch(battle))
	yoch(battle).acts_available = acts
	battle.submit_plan(battle.hud.plan_options.find("REST"))
	confirm(battle)
	check(battle.active_actor == yoch(battle) and battle.hud.mode == "plan", "Yoch's plan opens after Fallen rests")

## D-057: Z first pages the event lines still waiting beyond the two-row log, then goes on.
func confirm(battle: Control) -> void:
	for _i in 8:
		var paging: bool = battle.hud.mode in ["continue", "announce"] and battle.hud.log_hidden()
		battle.proceed()
		if not paging: return


func open_pray(battle: Control) -> void:
	battle.submit_plan(battle.hud.plan_options.find("PRAY"))
	check(battle.hud.mode == "pray", "PRAY opens the PRAY submenu")

func pick(battle: Control, row_prefix: String) -> void:
	var rows: Array[String] = battle.hud.command_options
	for i in rows.size():
		if rows[i].begins_with(row_prefix):
			battle.prayer.submit(i)
			return
	check(false, "PRAY submenu has no row %s (rows %s)" % [row_prefix, rows])

## PRAY submenu -> spell -> target (player side index or enemy index).
func queue_spell(battle: Control, spell: String, target: int) -> void:
	open_pray(battle)
	pick(battle, spell)
	check(battle.hud.mode == "target", "%s asks for a target in the plan" % spell)
	battle.submit_target(target)
	check(battle.hud.mode != "target" and battle.hud.mode != "pray", "The target choice closes the submenu (back to the plan, or the plan runs when nothing is left)")

## Ra'am waits for its approved thunder (0.7 s charge) before the damage lands.
func wait_mode(battle: Control, mode: String, seconds := 3.0) -> void:
	var waited := 0.0
	while battle.hud.mode != mode and waited < seconds:
		await process_frame
		waited += root.get_process_delta_time()

func last_line(battle: Control, needle: String) -> String:
	for i in range(battle.log_history.size() - 1, -1, -1):
		if battle.log_history[i].contains(needle): return battle.log_history[i]
	return ""

func _run() -> void:
	# ---- Pure rules.
	check(PrayerBook.refuah_heal(0) == 20 and PrayerBook.refuah_heal(1) == 30, "Refuah heals 20 + 10 per extra PP (3 PP = 30)")
	check(PrayerBook.raam_base(1, 2, 2) == 20 and PrayerBook.raam_base(0, 5, 3) == 12, "Ra'am base = 10 + MAK + 10/extra PP - MEF")
	check(PrayerBook.unlocked(1).is_empty() and PrayerBook.unlocked(2) == [PrayerBook.REFUAH, PrayerBook.HAGANAH] and PrayerBook.unlocked(3).has(PrayerBook.RAAM), "The tab lists spells with base cost <= current PP")
	check(PrayerBook.base_cost(PrayerBook.REFUAH) == 2 and PrayerBook.base_cost(PrayerBook.HAGANAH) == 2 and PrayerBook.base_cost(PrayerBook.RAAM) == 3, "Costs 2 / 2 / 3")
	check(PrayerBook.enemies_react_to(PrayerBook.PRAY) and PrayerBook.enemies_react_to(PrayerBook.RAAM) and not PrayerBook.enemies_react_to(PrayerBook.REFUAH) and not PrayerBook.enemies_react_to(PrayerBook.HAGANAH), "Enemies react to PRAY and Ra'am only")
	var sim := PrayerBook.simulate(0, [{"cmd": "PRAY"}, {"cmd": "PRAY"}, {"spell": PrayerBook.REFUAH, "cost": 2}])
	check(bool(sim.ok) and int(sim.pp) == 0, "Queued PRAYs fund a later spell")
	check(not bool(PrayerBook.simulate(1, [{"spell": PrayerBook.REFUAH, "cost": 2}, {"cmd": "PRAY"}]).ok), "A spell before its PRAY is not funded")
	check(int(PrayerBook.simulate(8, [{"cmd": "PRAY"}]).pp) == 8, "PP cap 8")
	var rng := RandomNumberGenerator.new()
	rng.seed = 48
	var angel := PrayerBook.raam_damage(2, 9, 5, 0, 30, 30, BattleMath.Affinity.NORMAL, PrayerBook.ANGEL, rng)
	check(int(angel.amount) == 0 and bool(angel.angel), "Ra'am has no effect on angels")
	var nulled := PrayerBook.raam_damage(2, 9, 5, 0, 30, 30, BattleMath.Affinity.NULL, &"", rng)
	check(int(nulled.amount) == 0, "NULL affinity zeroes Ra'am like ATTACK")
	for i in 200:
		var r := PrayerBook.raam_damage(0, 2, 0, 2, 30, 30, BattleMath.Affinity.NORMAL, &"", rng)
		check(int(r.amount) >= 9 and int(r.amount) <= 11 and not bool(r.crit), "Equal SP, AGI 0: 10 +/-10%% (got %d)" % int(r.amount))
	var unit_stats := UnitStats.new()
	unit_stats.max_hp = 11; unit_stats.max_en = 0; unit_stats.atk = 5; unit_stats.mak = 2
	unit_stats.defense = 4; unit_stats.mef = 2; unit_stats.agi = 5
	var u := BattleUnit.new(&"y", "Yoch", unit_stats, true)
	u.start_praying(3)
	check(u.current_pp == 3 and u.sp_base() == 35 and u.current_sp == 35, "SP base 29 + 2 per PP")
	check(u.change_pp(10) == 5 and u.current_pp == 8 and u.current_sp == 45, "PP cap 8 (+16 SP)")
	check(u.change_pp(-3) == -3 and u.current_sp == 39, "Spending PP lowers SP by 2 each")
	ProgressStore.clear()
	check(ProgressStore.load_pp() == 0, "No save: 0 PP")
	ProgressStore.save_pp(5)
	check(ProgressStore.load_pp() == 5, "PP persist in the save")
	ProgressStore.save_pp(99)
	check(ProgressStore.load_pp() == 8, "Saved PP are clamped to 8")

	# ---- Yoch in battle: name, no EN, PP from the save, PRAY after FIGHT.
	var battle := fresh(3)
	var y := yoch(battle)
	check(y.display_name == "Yoch" and y.prays and y.stats.max_en == 0 and y.race == &"human", "Ally is Yoch, human, no EN, prays")
	check(y.current_pp == 3 and y.current_sp == 29 + 6, "Saved PP loaded; SP 29 + 6")
	check(not fallen(battle).prays and not battle.hud.plan_options.has("PRAY"), "Fallen has no PRAY")
	to_yoch(battle, 3)
	check(battle.hud.plan_options.find("PRAY") == 1, "PRAY sits right after FIGHT (%s)" % [battle.hud.plan_options])
	open_pray(battle)
	check(battle.hud.command_options == ["PRAY  +1 PP", "Refuah  2 PP", "Haganah  2 PP", "Ra'am  3 PP"], "3 PP: PRAY and all three spells (%s)" % [battle.hud.command_options])
	check(battle.prayer.info(3).begins_with("Ra'am"), "The log line explains the highlighted row")
	battle.handle_back()
	check(battle.hud.mode == "plan" and battle._planned.is_empty(), "X leaves the submenu without queuing")
	battle.queue_free(); await process_frame

	# ---- PRAY with no enemy reaction: +1 PP, +2 SP, saved; line in #f5f58c.
	battle = fresh(0)
	y = yoch(battle)
	to_yoch(battle, 1)
	open_pray(battle)
	check(battle.hud.command_options == ["PRAY  +1 PP"], "0 PP: only PRAY")
	pick(battle, "PRAY")
	check(battle.hud.mode == "continue", "PRAY resolves (1 act = whole plan)")
	check(y.current_pp == 1 and y.current_sp == 31 and y.acts_available == 0, "PRAY: 1 act, +1 PP, +2 SP")
	check(ProgressStore.load_pp() == 1, "The new PP are saved")
	check(battle.prayer.fx.letters.size() == 14 and battle.prayer.fx.letters.all(func(l: Dictionary) -> bool: return float(l.bottom) == battle.hud.STATUS_RECTS[1].end.y - 6), "PRAY: 14 letters rise from the bottom of Yoch's card")
	# D-057: the log holds event sentences; prayer lines keep the D-048 ink.
	var pray_line: Dictionary = battle.hud.events.back()
	check(String(pray_line.text) == "Yoch gains 1 PP." and Color(pray_line.ink) == PrayerBook.INK, "Prayer log line is an event inked #f5f58c (%s)" % pray_line)
	battle.queue_free(); await process_frame

	# ---- Queued PRAYs fund a later Refuah; PP leave when queued (paid / owed).
	battle = fresh(0)
	y = yoch(battle)
	var f := fallen(battle)
	f.stats.max_hp = 50
	f.current_hp = 1
	to_yoch(battle, 3)
	open_pray(battle); pick(battle, "PRAY")
	open_pray(battle); pick(battle, "PRAY")
	open_pray(battle)
	check(battle.hud.command_options.has("Refuah  2 PP") and not battle.hud.command_options.has("Ra'am  3 PP"), "Two queued PRAYs unlock Refuah, not Ra'am")
	pick(battle, "Refuah")
	battle.submit_target(0)
	# Three acts committed: the plan runs. D-057: one command after the other, no Z in
	# between; the result pause comes after the last one.
	await wait_mode(battle, "continue")
	check(battle.hud.mode == "continue", "The full plan resolves")
	check(f.current_hp == 21 and y.current_pp == 0, "Refuah funded by the two PRAYs heals 20 (Fallen 1 -> 21), 0 PP left")
	check(last_line(battle, "Refuah").contains("+20 HP"), "Refuah logged")
	check(last_line(battle, "prays: +1 PP").contains("to the queued Refuah"), "A PRAY that pays a queued spell says so (%s)" % last_line(battle, "prays: +1 PP"))
	battle.queue_free(); await process_frame

	# ---- +1 PP: same spell, same target (no act); UNDO; another target = new cast.
	battle = fresh(6)
	y = yoch(battle)
	f = fallen(battle)
	f.stats.max_hp = 50
	f.current_hp = 1
	y.current_hp = 1
	to_yoch(battle, 2)
	queue_spell(battle, "Refuah", 0)
	check(y.current_pp == 4 and y.current_sp == 29 + 8, "Queued Refuah leaves at once: 6 -> 4 PP (SP follows)")
	queue_spell(battle, "Refuah", 0)
	check(battle._planned.size() == 1 and int(battle._planned_skills[0].extra) == 1 and y.current_pp == 3, "Same spell + target = +1 PP, no act")
	battle.undo_plan()
	check(battle._planned.size() == 1 and int(battle._planned_skills[0].extra) == 0 and y.current_pp == 4, "UNDO takes the +1 PP back first")
	queue_spell(battle, "Refuah", 0)
	queue_spell(battle, "Refuah", 1)
	check(battle._planned.size() == 2 and y.current_pp == 1, "Another target = a new cast (1 act, 2 PP)")
	# Both acts are committed: planning stays open for +1 PP only.
	check(battle.hud.mode == "plan", "With acts full the plan stays open while PP can still be added")
	open_pray(battle)
	check(battle.hud.command_options == ["Refuah  2 PP"], "Acts full: only queued spells (+1 PP) are offered (%s)" % [battle.hud.command_options])
	pick(battle, "Refuah"); battle.submit_target(1)
	check(y.current_pp == 0 and int(battle._planned_skills[1].extra) == 1, "+1 PP on the second Refuah")
	await wait_mode(battle, "continue")
	check(battle.hud.mode == "continue", "No act and no PP left: the plan runs by itself")
	check(f.current_hp == 31 and y.current_hp == 11, "Refuah 3 PP on Fallen heals 30; Refuah 3 PP on Yoch heals to his max")
	battle.queue_free(); await process_frame

	# ---- PRAY attacked: every enemy may attack; any contact interrupts; queue lost + refund.
	battle = fresh(2)
	y = yoch(battle)
	battle.pray_reaction = true
	battle.enemy_timing = BattleMath.RhythmResult.BEAM
	y.stats.max_hp = 999
	y.current_hp = 999
	to_yoch(battle, 3)
	open_pray(battle); pick(battle, "PRAY")
	queue_spell(battle, "Refuah", 0)
	check(y.current_pp == 0, "Queued Refuah paid with the 2 PP")
	var foes: Array = battle.hud.opponents.duplicate()
	var foe_acts := [foes[0].acts_available, foes[1].acts_available]
	var hp0 := y.current_hp
	battle.exec_plan()
	check(battle.hud.mode == "continue" and last_line(battle, "attacks Yoch's prayer") != "", "An enemy attacks the PRAY")
	confirm(battle)
	check(battle.hud.mode == "continue", "Every enemy that rolled attacks (second strike)")
	confirm(battle)
	check(y.current_hp < hp0, "Yoch has no defense rail: the strikes land")
	check(last_line(battle, "interrupted by").contains(foes[0].display_name) or last_line(battle, "interrupted by").contains(foes[1].display_name), "BEAM contact interrupts the PRAY")
	confirm(battle)
	check(y.current_pp == 2, "Interrupted PRAY gives no PP; the lost Refuah's 2 PP come back (pp %d)" % y.current_pp)
	check(last_line(battle, "queued command").contains("loses 1"), "The rest of Yoch's queue is lost")
	var first_hitter: BattleUnit = foes[1] if battle.log_history.find(last_line(battle, "%s attacks Yoch's prayer" % foes[1].display_name)) < battle.log_history.find(last_line(battle, "%s attacks Yoch's prayer" % foes[0].display_name)) else foes[0]
	check(last_line(battle, "queued command").contains("%s gains 1" % first_hitter.display_name), "The first enemy that hit gains the lost command's act (%s)" % last_line(battle, "queued command"))
	# D-057 (creator 2026-11-25): the act left after the interrupted queue is planned again
	# in the same turn; Yoch's turn only ends with 0 acts or REST.
	check(y.acts_available == 1 and battle.active_actor == y and battle.hud.mode == "plan", "After the interrupted queue Yoch plans the act left in the same turn (acts %d, actor %s, mode %s)" % [y.acts_available, battle.active_actor.display_name if battle.active_actor else "-", battle.hud.mode])
	check(foes[0].acts_available + foes[1].acts_available == foe_acts[0] + foe_acts[1] - 2 + 1, "Each attack spent 1 enemy act; +1 act to the first hitter")
	battle.queue_free(); await process_frame

	# ---- D-107 (criador 2026-11-25): o golpe do inimigo na trilha branca acerta (50%) e interrompe.
	battle = fresh(0)
	y = yoch(battle)
	battle.pray_reaction = true
	battle.enemy_timing = BattleMath.RhythmResult.MISS
	to_yoch(battle, 1)
	var y_hp: int = y.current_hp
	open_pray(battle); pick(battle, "PRAY")
	confirm(battle); confirm(battle)
	check(y.current_pp == 0 and y.current_hp < y_hp, "D-107: enemy white mark hits (50%%) and interrupts the PRAY (PP %d, HP %d -> %d)" % [y.current_pp, y_hp, y.current_hp])
	battle.queue_free(); await process_frame

	# ---- Ra'am, no counter: rail like ATTACK, base 10 + MAK - MEF, WEAK x1.5 and +1 act.
	battle = fresh(4)
	y = yoch(battle)
	foes = battle.hud.opponents.duplicate()
	var weak: BattleUnit = foes[0]
	weak.current_hp = 999
	weak.stats.max_hp = 999
	y.current_sp = weak.current_sp
	to_yoch(battle, 1)
	queue_spell(battle, "Ra'am", 0)
	check(y.current_pp == 1, "Ra'am queued: 4 -> 1 PP")
	open_pray(battle); pick(battle, "Ra'am"); battle.submit_target(0)
	check(int(battle._planned_skills[0].extra) == 1, "+1 PP on Ra'am")
	check(battle.prayer.fx.raam_busy(), "Ra'am plays the approved thunder before the damage")
	await wait_mode(battle, "continue")
	check(battle.hud.mode == "continue", "No act and no PP left: the plan runs")
	var line := last_line(battle, "Ra'am base")
	check(line.contains("Ra'am base %d" % (10 + y.stats.mak + 10 - weak.stats.mef)), "Ra'am base with 1 extra PP: %s" % line)
	check(line.contains("affinity WEAK") and 999 - weak.current_hp > 0 and y.acts_available == 1 and y.current_pp == 0, "WEAK: x1.5 damage and +1 act (%s, acts %d)" % [line, y.acts_available])
	battle.queue_free(); await process_frame

	# ---- Ra'am: D-107, trilha branca = 50%, lateral = 80%.
	battle = fresh(3)
	y = yoch(battle)
	battle.hero_timing = BattleMath.RhythmResult.MISS
	foes = battle.hud.opponents.duplicate()
	var hp_before: int = foes[1].current_hp
	to_yoch(battle, 1)
	queue_spell(battle, "Ra'am", 1)
	battle.exec_plan()
	await wait_mode(battle, "continue")
	check(foes[1].current_hp < hp_before and last_line(battle, "Ra'am base").contains("rhythm MISS") and last_line(battle, "Ra'am base").contains("HIT 50%"), "D-107: Ra'am on the white mark still hits for 50%% (%s)" % last_line(battle, "Ra'am base"))
	check(y.current_pp == 0, "A Ra'am on the white mark spent its PP")
	battle.queue_free(); await process_frame

	# ---- Ra'am counter-attacked: enemy wins -> interrupted, PP back, queue lost.
	battle = fresh(3)
	y = yoch(battle)
	battle.raam_counter = true
	foes = battle.hud.opponents.duplicate()
	to_yoch(battle, 2)
	queue_spell(battle, "Ra'am", 0)
	open_pray(battle); pick(battle, "PRAY")
	check(y.current_pp == 0, "Ra'am paid")
	var foe_hp: int = foes[0].current_hp
	battle.exec_plan()
	check(battle.hud.mode == "counter" and battle.counter.style == "enemy", "Ra'am counter: D-049 rails over the enemy")
	battle.counter.finish(BattleMath.RhythmResult.MISS, BattleMath.RhythmResult.POINT)
	check(foes[0].current_hp == foe_hp, "Interrupted Ra'am has no effect")
	check(y.current_pp == 3, "Interrupted Ra'am gives its 3 PP back (pp %d)" % y.current_pp)
	confirm(battle)
	check(last_line(battle, "queued command").contains("loses 1") and last_line(battle, "queued command").contains("%s gains 1" % foes[0].display_name), "The queued PRAY is lost; the interrupter gains 1 act")
	battle.queue_free(); await process_frame

	# ---- Ra'am counter-attacked: Yoch wins -> Ra'am lands with his timing, 4 SP stolen.
	battle = fresh(3)
	y = yoch(battle)
	battle.raam_counter = true
	foes = battle.hud.opponents.duplicate()
	foes[1].current_hp = 999
	to_yoch(battle, 1)
	queue_spell(battle, "Ra'am", 1)
	var foe_sp: int = foes[1].current_sp
	battle.exec_plan()
	battle.counter.finish(BattleMath.RhythmResult.POINT, BattleMath.RhythmResult.MISS)
	await wait_mode(battle, "continue")
	check(last_line(battle, "Ra'am base") != "" and foes[1].current_hp == 999 - int(last_line(battle, "Ra'am base").get_slice(": ", 1).get_slice(" dmg", 0).to_int()), "Winning the exchange: Ra'am lands (RESIST and the SP roll may leave 0) %s" % last_line(battle, "Ra'am base"))
	check(foes[1].current_sp <= foe_sp - 4 + 1, "Winning the exchange steals 4 SP")
	battle.queue_free(); await process_frame

	# ---- Haganah: set on the target, ends at the same point of the next round.
	battle = fresh(2)
	y = yoch(battle)
	to_yoch(battle, 1)
	queue_spell(battle, "Haganah", 1)
	battle.exec_plan()
	check(not y.haganah.is_empty() and int(y.haganah.round) == battle.state.round_number and StringName(y.haganah.owner) == y.id, "Haganah shields Yoch from this point")
	check(last_line(battle, "Haganah").contains("one round"), "Haganah logged")
	check(battle.prayer.fx.letters.size() == 14, "Haganah cast: letters rise from the target's card")
	battle.prayer.expire(y)
	check(not y.haganah.is_empty(), "Same round: still up")
	battle.state.round_number += 1
	battle.prayer.expire(fallen(battle))
	check(not y.haganah.is_empty(), "Next round, before Yoch's turn point: still up")
	battle.prayer.expire(y)
	check(y.haganah.is_empty(), "Next round at Yoch's turn: Haganah ends")
	await process_frame
	var fx_letters_left: int = battle.prayer.fx.letters.size()
	for i in 60: await process_frame
	check(battle.prayer.fx.letters.size() <= fx_letters_left and (battle.prayer.fx.letters.is_empty() or fx_letters_left > 0), "Rising letters expire")
	battle.state.round_number -= 1
	battle.queue_free(); await process_frame

	# ---- Yoch's REST only stores acts.
	battle = fresh(2)
	y = yoch(battle)
	to_yoch(battle, 2)
	battle.submit_plan(battle.hud.plan_options.find("REST"))
	check(last_line(battle, "Yoch rests").contains("2 act(s) stored") and not last_line(battle, "Yoch rests").contains("EN"), "Yoch's REST stores acts, no EN (%s)" % last_line(battle, "Yoch rests"))
	check(y.current_pp == 2, "REST gives no PP")
	battle.queue_free(); await process_frame

	# ---- Reaction: Yoch (not the target) may PRAY; +1 PP and +1 SP for reacting.
	battle = fresh(0)
	y = yoch(battle)
	f = fallen(battle)
	battle.submit_plan(battle.hud.plan_options.find("REACT"))
	battle.submit_plan(battle.hud.plan_options.find("REACT"))
	check(battle.hud.mode == "react", "Enemy announcement opens the reaction prompt")
	var defender: BattleUnit = battle.action_defender
	battle.select_reactor(1)
	battle.answer_reaction(true)
	check(battle.hud.command_options.has("PRAY"), "Yoch may PRAY as a reaction (target: %s)" % defender.display_name)
	var sp0 := y.current_sp
	battle.submit_command(battle.hud.command_options.find("PRAY"))
	check(battle.hud.mode == "pray", "Reaction PRAY opens the submenu")
	pick(battle, "PRAY")
	check(y.current_pp == 1 and y.current_sp == sp0 + 2 + 1, "Reaction PRAY: +1 PP (+2 SP) and +1 SP for reacting")
	battle.queue_free(); await process_frame

	# ---- Battle end: victory keeps the PP, defeat zeroes them.
	battle = fresh(5)
	battle.prayer.battle_end(true)
	check(ProgressStore.load_pp() == 5, "Victory keeps the PP")
	battle.prayer.battle_end(false)
	check(ProgressStore.load_pp() == 0, "Defeat zeroes the PP")
	battle.queue_free(); await process_frame

	# ---- Letter effects of the first-fight skills (creator 2026-11-23).
	battle = fresh(0)
	var lf: Node2D = battle.letter_fx
	var foe: BattleUnit = battle.hud.opponents[0]
	check(not FileAccess.get_file_as_string("res://scripts/battle/playable_controller.gd").contains("letter_fx.lunge_hit"), "Lunge (physical) plays no letters")
	battle.fx.play("HIT", foe, 1, battle.hud.players[0], true)
	check(battle.fx.effects.back().sprites.size() == 32 and bool(battle.fx.effects.back().cross), "Lunge hit: the normal hit cells plus a mirrored copy (an X)")
	battle.fx.play("HIT", foe, 1, battle.hud.players[0])
	check(battle.fx.effects.back().sprites.size() == 16, "A normal ATTACK hit is not mirrored")
	battle.fx.play("HIT", foe, 7, battle.hud.players[0], true)
	var first_fx: Dictionary = battle.fx.effects.back()
	battle.fx.play("HIT_NEXT", foe, 5, battle.hud.players[0])
	var next_fx: Dictionary = battle.fx.effects.back()
	check(next_fx.sprites.all(func(sp: Sprite2D) -> bool: return not sp.visible) and is_equal_approx(float(next_fx.duration), float(first_fx.duration) + battle.fx.NEXT_NUMBER_GAP), "Lunge 2nd hit: no new effect, its number right after the first")
	check(battle.fx.label_for("HIT_NEXT", 5) == "-5" and battle.fx.label_for("BLOCK_NEXT", 5) == "BLOCK -5", "Follow-up numbers read like the first")
	lf.heat_hit(foe, battle.hud.players[0])
	check(lf.parts.size() == 34 + 16, "Heat wave: a wave of letters plus flames on the target")
	lf.heat_hit(foe, battle.hud.players[1])
	check(lf.parts.size() == 34 + 32, "A second target in the same cast gets flames, not a second wave")
	lf.parts.clear()
	lf.burn(foe)
	check(lf.parts.size() == 6, "Burn tick: embers")
	lf.parts.clear()
	var card: Rect2 = battle.hud.STATUS_RECTS[0]
	for kind in ["buff", "heal"]:
		lf.self_skill(battle.hud.players[0], kind)
		check(lf.parts.all(func(q: Dictionary) -> bool: return card.grow(2).has_point(q.pos)) and lf.rings.size() == 1, "%s on a hero: letters start inside the card" % kind)
		check(lf.rings[0].rad.y <= card.size.y * 0.5, "%s ring fits the card height" % kind)
		lf.parts.clear(); lf.rings.clear()
	battle.queue_free(); await process_frame

	print("PLAYABLE_PRAYER_OK: %d checks; D-048 PP, PRAY, Refuah, Haganah, Ra'am, allocation, interruption refunds, persistence" % checks)
	quit(0)
