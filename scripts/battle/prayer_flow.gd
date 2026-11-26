extends RefCounted
## D-048 Reza of Yoch inside the playable battle (creator's answers of 2026-11-23).
## The playable controller only calls hooks; the rules live in PrayerBook.
##
## Plan entries (in BattlePlayable._planned_skills) for PRAY rows:
##   {"pray": &"pray"}                                    the PRAY command (+1 PP)
##   {"pray": spell, "target": unit, "extra": n, "paid": n, "owed": n}  a spell
## PP leave Yoch when a spell is queued ("ao enfileirar"): what the current PP cover is
## paid at once, the rest is owed and paid when an earlier queued PRAY resolves. PP of a
## spell that does not resolve (interrupted, lost, cancelled plan) come back.

signal chosen

const PRAY_FX = preload("res://scripts/battle/pray_fx.gd")

var battle: Node
var menu_rows: Array[String] = []
var menu_ids: Array[StringName] = []
var menu_info: Array[String] = []
var _choice := -1
var _plan_start_pp := 0
## Undo stack of the plan: "entry" for an appended command, or the index of the queued
## spell that got +1 PP.
var _history: Array = []
## Rising letters on cast and the Haganah mark (creator's choices of 2026-11-23).
var fx: Node2D


func _init(owner_battle: Node) -> void:
	battle = owner_battle
	fx = PRAY_FX.new()
	fx.name = "PrayFX"
	fx.hud = battle.hud
	battle.add_child(fx)


# ------------------------------------------------------------------ commands / plan

func commands_for(unit: BattleUnit, options: Array[String]) -> Array[String]:
	if unit == null or not unit.prays or options.has("PRAY"):
		return options
	var result: Array[String] = options.duplicate()
	# Creator 2026-11-23: PRAY comes right after the first command (FIGHT/ATTACK).
	result.insert(mini(1, result.size()), "PRAY")
	return result


func begin_plan(unit: BattleUnit) -> void:
	_plan_start_pp = unit.current_pp
	_history.clear()


## With every act committed, planning stays open while a queued spell can still take
## +1 PP (the extra costs no act).
func can_continue(unit: BattleUnit, details: Array) -> bool:
	if unit == null or not unit.prays or projected_pp(details) < 1:
		return false
	for detail in details:
		if _is_spell(detail):
			return true
	return false


func after_append(unit: BattleUnit, details: Array) -> void:
	_history.append("entry")
	recharge(unit, details)


## UNDO: when the last plan step was a +1 PP allocation, take it back and say so.
func undo_allocation(unit: BattleUnit, details: Array) -> bool:
	if _history.is_empty():
		return false
	var last: Variant = _history.pop_back()
	if last is int:
		var detail: Dictionary = details[int(last)]
		detail.extra = maxi(0, int(detail.extra) - 1)
		recharge(unit, details)
		return true
	return false


## Re-charges every queued spell from the PP Yoch had when the plan began.
func recharge(unit: BattleUnit, details: Array) -> void:
	if not unit.prays:
		return
	var avail := _plan_start_pp
	for detail in details:
		var d: Dictionary = detail
		if not _is_spell(d):
			continue
		var cost := _cost(d)
		d.paid = mini(avail, cost)
		d.owed = cost - int(d.paid)
		avail -= int(d.paid)
	unit.change_pp(avail - unit.current_pp)
	battle._refresh_all()


func _is_spell(d: Dictionary) -> bool:
	return d.has("pray") and StringName(d.pray) != PrayerBook.PRAY


func _cost(d: Dictionary) -> int:
	return PrayerBook.base_cost(StringName(d.pray)) + int(d.get("extra", 0))


func _queue(details: Array, override_index := -1, extra_delta := 0, appended: Dictionary = {}) -> Array:
	var queue: Array = []
	for i in details.size():
		var d: Dictionary = details[i]
		if not d.has("pray"):
			continue
		if StringName(d.pray) == PrayerBook.PRAY:
			queue.append({"cmd": "PRAY"})
		else:
			queue.append({"spell": d.pray, "cost": _cost(d) + (extra_delta if i == override_index else 0)})
	if not appended.is_empty():
		queue.append(appended)
	return queue


## PP the plan will have after its queued commands (the list shows spells up to it).
func projected_pp(details: Array) -> int:
	return int(PrayerBook.simulate(_plan_start_pp, _queue(details)).pp)


## The PRAY submenu during planning. Returns {} when cancelled, {"allocated": true} when
## +1 PP went to a queued spell (no act), or the detail of a new entry.
func plan_pick(unit: BattleUnit, details: Array, acts_left: int) -> Dictionary:
	while true:
		var avail := projected_pp(details)
		_build_menu(avail, details, acts_left)
		if menu_rows.is_empty():
			_say("No act left and no queued spell to raise.")
			return {}
		var pick := await _wait_menu("PRAY  %d PP | Z: confirm | X: back" % avail)
		if pick == &"":
			return {}
		if pick == PrayerBook.PRAY:
			return {"pray": PrayerBook.PRAY}
		var side := "enemy" if PrayerBook.targets_enemy(pick) else "player"
		var target: BattleUnit = await battle._wait_target(side)
		if target == null:
			continue
		# Creator 2026-11-23: the same spell on the same target = +1 PP on it (no act);
		# another target = a new cast.
		var same := -1
		for i in details.size():
			var d: Dictionary = details[i]
			if d.has("pray") and StringName(d.pray) == pick and d.get("target") == target:
				same = i
		if same >= 0:
			if not bool(PrayerBook.simulate(_plan_start_pp, _queue(details, same, 1)).ok):
				_say("Not enough PP for +1 on %s." % PrayerBook.spell_name(pick))
				continue
			details[same].extra = int(details[same].extra) + 1
			_history.append(same)
			recharge(unit, details)
			_say("%s on %s: +1 PP (%d PP in total)." % [PrayerBook.spell_name(pick),
				target.display_name, _cost(details[same])])
			return {"allocated": true}
		if acts_left <= 0:
			_say("No act left for a new cast; pick a queued spell and target for +1 PP.")
			continue
		var entry := {"spell": pick, "cost": PrayerBook.base_cost(pick)}
		if not bool(PrayerBook.simulate(_plan_start_pp, _queue(details, -1, 0, entry)).ok):
			_say("Not enough PP for %s." % PrayerBook.spell_name(pick))
			continue
		_say("%s queued on %s: %d PP." % [PrayerBook.spell_name(pick), target.display_name, PrayerBook.base_cost(pick)])
		return {"pray": pick, "target": target, "extra": 0, "paid": 0, "owed": 0}
	return {}


func _build_menu(avail: int, details: Array, acts_left: int) -> void:
	menu_rows.clear()
	menu_ids.clear()
	menu_info.clear()
	if acts_left > 0:
		menu_rows.append("PRAY  +1 PP")
		menu_ids.append(PrayerBook.PRAY)
		menu_info.append("PRAY 1 ACT: +1 PP (max %d)." % PrayerBook.MAX_PP)
	for id in PrayerBook.SPELL_ORDER:
		var queued := false
		for d in details:
			if (d as Dictionary).get("pray", &"") == id:
				queued = true
		var castable := acts_left > 0 and PrayerBook.base_cost(id) <= avail
		var allocatable := queued and avail >= 1
		if castable or allocatable:
			menu_rows.append("%s  %d PP" % [PrayerBook.spell_name(id), PrayerBook.base_cost(id)])
			menu_ids.append(id)
			menu_info.append(String(PrayerBook.spell(id).info) + (" | queued: same target = +1 PP" if queued else ""))


func _wait_menu(feedback: String) -> StringName:
	await battle._flush_log()
	var hud: Control = battle.hud
	hud.command_options = menu_rows
	hud.command_index = 0
	hud.mode = "pray"
	hud.feedback = feedback
	_choice = -2
	battle._refresh_all()
	await chosen
	hud.mode = "busy"
	return menu_ids[_choice] if _choice >= 0 and _choice < menu_ids.size() else &""


func info(index: int) -> String:
	return menu_info[index] if index >= 0 and index < menu_info.size() else ""


func submit(index: int) -> void:
	if battle.hud.mode != "pray" or index < 0 or index >= menu_ids.size():
		return
	_choice = index
	battle.hud.command_index = index
	battle.hud.press_command(index, "confirm")
	chosen.emit()


func cancel() -> void:
	if battle.hud.mode == "pray":
		_choice = -1
		chosen.emit()


# ------------------------------------------------------------------ execution

## Runs one PRAY row (action or reaction). A reaction opens the submenu here; its spell is
## paid at once (no queue). Returns false when the player backed out.
func execute(unit: BattleUnit, detail: Dictionary, reacting: bool) -> bool:
	var d := detail
	if d.is_empty() or not d.has("pray"):
		d = await _reaction_pick(unit)
		if d.is_empty():
			return false
	if not unit.spend_act():
		_release(unit, d, "no act left")
		return true
	d["done"] = true
	var id := StringName(d.pray)
	var hud: Control = battle.hud
	battle.action_attacker = unit
	battle.action_defender = d.get("target", unit)
	battle.phase_text = ("REACTION " if reacting else "") + ("PRAY" if id == PrayerBook.PRAY else PrayerBook.spell_name(id).to_upper())
	if id == PrayerBook.PRAY:
		await _pray(unit, reacting)
	else:
		var target: BattleUnit = d.target
		if not target.is_alive():
			# The target fell before the cast resolved: no effect, the PP come back.
			_release(unit, d, "%s is down" % target.display_name)
		elif id == PrayerBook.RAAM:
			await _raam(unit, target, d, reacting)
		elif id == PrayerBook.REFUAH:
			var healed := target.heal(PrayerBook.refuah_heal(int(d.extra)))
			fx.cast(target)
			_log("%s prays Refuah on %s: +%d HP (%d PP)." % [unit.display_name, target.display_name, healed, _cost(d)])
			_event("%s prays Refuah on %s: +%d HP." % [battle.short_name(unit), battle.short_name(target), healed])
			hud.feedback = "%s: HP %d/%d | PP %d/%d" % [battle.short_name(target), target.current_hp,
				target.stats.max_hp, unit.current_pp, PrayerBook.MAX_PP]
		elif id == PrayerBook.HAGANAH:
			fx.cast(target)
			target.haganah = {"round": battle.state.round_number,
				"owner": battle.turn_owner.id if battle.turn_owner != null else &""}
			_log("%s prays Haganah on %s: shielded from status conditions for one round (%d PP)." % [
				unit.display_name, target.display_name, _cost(d)])
			_event("%s prays Haganah on %s." % [battle.short_name(unit), battle.short_name(target)])
		if reacting and id in [PrayerBook.REFUAH, PrayerBook.HAGANAH]:
			unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	save(unit)
	battle._refresh_all()
	return true


func _reaction_pick(unit: BattleUnit) -> Dictionary:
	_plan_start_pp = unit.current_pp
	while true:
		_build_menu(unit.current_pp, [], 1)
		var pick := await _wait_menu("PRAY  %d PP | Z: confirm | X: back" % unit.current_pp)
		if pick == &"":
			return {}
		if pick == PrayerBook.PRAY:
			return {"pray": PrayerBook.PRAY}
		var target: BattleUnit = await battle._wait_target("enemy" if PrayerBook.targets_enemy(pick) else "player")
		if target == null:
			continue
		var cost := PrayerBook.base_cost(pick)
		unit.change_pp(-cost)
		battle._refresh_all()
		return {"pray": pick, "target": target, "extra": 0, "paid": cost, "owed": 0}
	return {}


## PRAY: every enemy with a reaction act may attack it (33% each). Yoch has no defense
## rail; any contact (POINT or BEAM) interrupts: no PP and the rest of the queue is lost.
## The first enemy that hit gains the lost commands' acts.
func _pray(unit: BattleUnit, reacting: bool) -> void:
	_log("%s prays." % unit.display_name)
	_event("%s prays." % battle.short_name(unit))
	var first_hitter: BattleUnit = null
	for foe in battle.hud.opponents.duplicate():
		if not foe.is_alive() or foe.acts_available <= 0 or not unit.is_alive():
			continue
		if not battle._enemy_pray_reaction_roll(foe):
			continue
		foe.spend_act()
		battle.action_attacker = foe
		battle.action_defender = unit
		battle.phase_text = "ENEMY REACTION"
		battle._append_log("%s attacks %s's prayer (1 act spent)." % [foe.display_name, unit.display_name])
		battle._clear_roles()
		battle._set_role(foe, "REACT")
		battle._set_role(unit, "TARGET")
		battle._event("%s attacks %s's prayer." % [battle.short_name(foe), battle.short_name(unit)])
		var timing: int = battle._ai_roll(foe, unit)
		# D-057: a basic attack uses the basic power (D-031: 8), not the old fixed 100.
		var applied: int = battle._skill_hit(foe, unit, battle.basic_power, true, timing, BattleMath.RhythmResult.MISS, false)
		if applied >= 0 and first_hitter == null:
			first_hitter = foe
		await battle._pause_result()
	if not unit.is_alive():
		return
	if first_hitter != null:
		battle._player_interrupted = true
		battle._interrupt_gainer = first_hitter
		_log("%s's prayer is interrupted by %s: no PP." % [unit.display_name, first_hitter.display_name])
		_event("%s's prayer is interrupted." % battle.short_name(unit))
		return
	var gained := unit.change_pp(1)
	fx.cast(unit)
	var paid := _settle_owed(unit)
	_log("%s prays: +%d PP (%d/%d%s)." % [unit.display_name, gained, unit.current_pp, PrayerBook.MAX_PP, paid])
	_event("%s gains %d PP." % [battle.short_name(unit), gained])
	if reacting:
		unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	battle.hud.feedback = "%s: PP %d/%d | SP %d" % [battle.short_name(unit), unit.current_pp, PrayerBook.MAX_PP, unit.current_sp]


## Pays queued spells' debts with the PP Yoch has now; returns a log note.
func _settle_owed(unit: BattleUnit) -> String:
	var note := ""
	for detail in battle._planned_skills:
		var d: Dictionary = detail
		if not _is_spell(d) or bool(d.get("done", false)) or int(d.get("owed", 0)) <= 0:
			continue
		var pay := mini(unit.current_pp, int(d.owed))
		unit.change_pp(-pay)
		d.paid = int(d.paid) + pay
		d.owed = int(d.owed) - pay
		if pay > 0:
			note += ", %d to the queued %s" % [pay, PrayerBook.spell_name(StringName(d.pray))]
	return note


## Ra'am: the struck enemy may counter-attack it on the D-049 two rails (33%); otherwise
## Yoch's attack rail against the enemy's defense, like ATTACK.
func _raam(unit: BattleUnit, target: BattleUnit, d: Dictionary, reacting: bool) -> void:
	_log("%s prays Ra'am on %s (%d PP)." % [unit.display_name, target.display_name, _cost(d)])
	if not reacting: battle._clear_roles()
	battle._set_role(unit, "REACT" if reacting else "ATTACK")
	battle._set_role(target, "TARGET")
	_event("%s prays Ra'am on %s." % [battle.short_name(unit), battle.short_name(target)])
	var extra := int(d.extra)
	if target.acts_available > 0 and battle._enemy_raam_counter_roll(target):
		target.spend_act()
		battle._append_log("%s counter-attacks %s's Ra'am (1 act spent)." % [target.display_name, unit.display_name])
		battle._set_role(target, "COUNTER")
		battle._event("%s counter-attacks!" % battle.short_name(target))
		var o: Dictionary = await battle._counter_exchange(unit, target, "enemy")
		match int(o.winner):
			BattleMath.CounterWinner.PLAYER:
				await raam_hit(unit, target, extra, reacting, int(o.player_timing), BattleMath.RhythmResult.MISS)
				battle._interrupt(unit, target, o)
			BattleMath.CounterWinner.ENEMY:
				battle._strike(target, unit, int(o.enemy_timing), true)
				battle._interrupt(target, unit, o)
				battle._player_interrupted = true
				battle._interrupt_gainer = target
				_release(unit, d, "Ra'am interrupted")
			_:
				await raam_hit(unit, target, extra, reacting, int(o.player_timing), BattleMath.RhythmResult.MISS)
				battle._strike(target, unit, int(o.enemy_timing), true)
				battle._player_interrupted = true
				battle._interrupt_gainer = null
				battle._tie_report(unit, target)
		return
	var marks: Array[float] = [0.5]
	var attack: Array[int] = await battle._skill_attack_timing(unit, target, marks, false)
	var defense: Array[int] = await battle._skill_defense_timing(target, unit, marks, false)
	await raam_hit(unit, target, extra, reacting, attack[0], defense[0])


## One Ra'am hit with known timings: damage, BEAM halving, Press Turn and SP like ATTACK.
func raam_hit(unit: BattleUnit, target: BattleUnit, extra: int, reacting: bool, attack: int, defense: int) -> void:
	if not target.is_alive():
		return
	battle.action_attacker = unit
	battle.action_defender = target
	battle.attack_result = attack
	battle.defense_result = defense
	var hp_before := target.current_hp
	if not BattleMath.has_contact(attack, defense):
		_log("%s -> %s: 0 dmg (Ra'am, rhythm %s, def %s, NO CONTACT)" % [unit.display_name,
			target.display_name, battle._rhythm_name(attack), battle._rhythm_name(defense)])
		if defense != BattleMath.RhythmResult.MISS:
			battle._set_role(target, "DEFEND")
		# D-109: sem contato só existe com defesa no centro.
		_event("%s dodges." % battle.short_name(target))
		battle._present_strike(unit, target, 0)
		return
	# Approved thunder (2026-11-23): the damage lands at the strike.
	await fx.play_raam(target)
	if not battle.is_inside_tree() or not target.is_alive():
		return
	var r := PrayerBook.raam_damage(extra, unit.stats.mak, unit.stats.agi, target.stats.mef,
		unit.current_sp, target.current_sp, target.affinity, target.race, battle.rng)
	if bool(r.angel):
		_log("%s -> %s: 0 dmg (Ra'am has no effect on angels)" % [unit.display_name, target.display_name])
		_event("Ra'am has no effect on %s." % battle.short_name(target))
		battle._present_strike(unit, target, 0, true)
		return
	var amount := int(r.amount)
	# D-109: marco do ataque 50/80/100%; defesa na lateral = metade.
	amount = BattleMath.scaled_damage(amount, attack, defense)
	var beam := defense == BattleMath.RhythmResult.BEAM
	var applied := target.take_damage(amount)
	unit.grant_acts(BattleMath.press_turn_acts(target.affinity))
	if bool(r.crit):
		unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	if target.affinity == BattleMath.Affinity.WEAK and applied > 0:
		unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	if reacting:
		unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	_log("%s -> %s: %d dmg (Ra'am base %d, %s, rhythm %s, def %s, crit %s, affinity %s, SP roll %+d)" % [
		unit.display_name, target.display_name, applied, int(r.base), "BLOCK" if beam else ("FULL" if attack == BattleMath.RhythmResult.POINT else "HIT %d%%" % int(round(BattleMath.strike_multiplier(attack, defense) * 100.0))),
		battle._rhythm_name(attack), battle._rhythm_name(defense), "YES" if bool(r.crit) else "no",
		battle._affinity_name(target.affinity), int(r.sp_roll)])
	var dealt := hp_before - target.current_hp
	if defense != BattleMath.RhythmResult.MISS:
		battle._set_role(target, "DEFEND")
	if defense == BattleMath.RhythmResult.BEAM:
		_event("%s blocks: %d damage." % [battle.short_name(target), dealt])
	else:
		_event("Ra'am strikes %s: %d damage." % [battle.short_name(target), dealt])
	if not target.is_alive():
		_event("%s is down." % battle.short_name(target))
	if BattleMath.press_turn_acts(target.affinity) > 0 and unit.is_alive():
		_event("%s gains %d act." % [battle.short_name(unit), BattleMath.press_turn_acts(target.affinity)])
	_present_raam(unit, target, dealt, beam, bool(r.crit))


## Like BattlePlayable._present_strike, but the approved thunder is the impact: the
## effect layer shows only the damage number (cue RAAM / RAAM_BLOCK, no claw cells).
func _present_raam(unit: BattleUnit, target: BattleUnit, damage: int, beam: bool, crit: bool) -> void:
	var outcome := ("BLOCK" if beam else "HIT") + (" / CRITICAL" if crit else "")
	var hud: Control = battle.hud
	hud.message = "%s -> %s: RA'AM %s, %d damage" % [battle.short_name(unit), battle.short_name(target), outcome, damage]
	hud.feedback = "%s | %s HP %d/%d%s | %s: %d ACTS left" % [outcome, battle.short_name(target), target.current_hp,
		target.stats.max_hp, " DOWN" if not target.is_alive() else "", battle.short_name(unit), unit.acts_available]
	battle.phase_text = "RESULT: " + outcome
	battle.fx.stop_cues()
	battle.fx.play("RAAM_BLOCK" if beam else "RAAM", target, damage, unit)
	battle._refresh_all()


## PP of a spell that will not resolve come back (paid part); its debt is cancelled.
func _release(unit: BattleUnit, d: Dictionary, why: String) -> void:
	d["done"] = true
	var back := int(d.get("paid", 0))
	d.paid = 0
	d.owed = 0
	if back > 0:
		unit.change_pp(back)
		_log("%s: %s, %d PP back to %s." % [PrayerBook.spell_name(StringName(d.pray)), why, back, unit.display_name])
		_event("%s is not cast: %d PP back." % [PrayerBook.spell_name(StringName(d.pray)), back])


## After a plan block: queued spells that never resolved give their PP back.
func release_unresolved(unit: BattleUnit, details: Array) -> void:
	if unit == null or not unit.prays:
		return
	for detail in details:
		var d: Dictionary = detail
		if _is_spell(d) and not bool(d.get("done", false)):
			_release(unit, d, "not cast")
	_history.clear()
	save(unit)
	battle._refresh_all()


# ------------------------------------------------------------------ round / persistence

## Yoch's REST: only stores the acts (no EN, no PP).
func rest(unit: BattleUnit, reacting: bool) -> bool:
	var remaining: int = unit.acts_available
	unit.store_acts(remaining)
	unit.acts_available = 0
	battle.action_attacker = unit
	battle.action_defender = unit
	battle.phase_text = "REST"
	battle._append_log("%s %s: %d act(s) stored; round participation ended." % [
		unit.display_name, "reacts with REST" if reacting else "rests", remaining])
	if reacting: battle._set_role(unit, "REACT")
	battle._event("%s rests: %d act(s) stored." % [battle.short_name(unit), remaining])
	if reacting:
		unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	battle.hud.feedback = "%s: 0 ACT spent, %d stored" % [unit.display_name, remaining]
	battle._refresh_all()
	return true


## Haganah lasts one full round: it ends when, in a later round, the turn of the unit that
## owned the turn at cast time comes back; `owner == null` = end of that later round.
func expire(owner: BattleUnit) -> void:
	for unit in battle.state.units:
		var h: Dictionary = unit.haganah
		if h.is_empty() or int(h.round) >= battle.state.round_number:
			continue
		if owner == null or StringName(h.owner) == owner.id:
			unit.haganah = {}
			_log("%s: Haganah ended." % unit.display_name)
			_event("%s's Haganah ends." % battle.short_name(unit))


func save(unit: BattleUnit) -> void:
	if battle.persist_progress and unit != null and unit.prays:
		ProgressStore.save_pp(unit.current_pp)


## Creator 2026-11-23: a defeat zeroes the PP; otherwise they persist.
func battle_end(victory: bool) -> void:
	if not battle.persist_progress:
		return
	for unit in battle.state.units:
		if unit.prays:
			ProgressStore.save_pp(unit.current_pp if victory else 0)


## Diagnostics only (log_history); the Battle Log line is _event() (D-057).
func _log(text: String) -> void:
	battle._append_log(text)


## D-057: a prayer event sentence; D-048: prayer lines are shown in #f5f58c.
func _event(text: String) -> void:
	battle._event(text, PrayerBook.INK)


## Planning feedback of the PRAY menu (queued spell, not enough PP), in the prayer ink.
func _say(text: String) -> void:
	battle.hud.message = text
	_event(text)
