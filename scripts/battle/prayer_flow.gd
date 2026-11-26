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
		if _is_spell(detail) and PrayerBook.accepts_extra_pp(StringName((detail as Dictionary).pray)):
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
		_build_menu(avail, details, acts_left, unit)
		if menu_rows.is_empty():
			_say("No act left and no queued spell to raise.")
			return {}
		var pick := await _wait_menu("PRAY  %d PP | Z: confirm | X: back" % avail)
		if pick == &"":
			return {}
		if pick == PrayerBook.PRAY:
			return {"pray": PrayerBook.PRAY}
		var target: BattleUnit = unit
		if not PrayerBook.targets_allies(pick) and not PrayerBook.targets_enemies(pick):
			var side := "enemy" if PrayerBook.targets_enemy(pick) else "player"
			target = await battle._wait_target(side)
			if target == null:
				continue
		# Creator 2026-11-23: the same spell on the same target = +1 PP on it (no act);
		# another target = a new cast. Only spells with extra PP scaling (Refuah, Ra'am, Gevurah).
		var same := -1
		if PrayerBook.accepts_extra_pp(pick):
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
		var acts_needed := PrayerBook.act_cost(pick)
		if acts_left < acts_needed:
			_say("Need %d ACT for %s." % [acts_needed, PrayerBook.spell_name(pick)])
			continue
		var entry := {"spell": pick, "cost": PrayerBook.base_cost(pick)}
		if not bool(PrayerBook.simulate(_plan_start_pp, _queue(details, -1, 0, entry)).ok):
			_say("NO PP: %s" % PrayerBook.spell_name(pick))
			continue
		if PrayerBook.targets_allies(pick):
			_say("%s → All allies  %d PP" % [PrayerBook.spell_name(pick), PrayerBook.base_cost(pick)])
		elif PrayerBook.targets_enemies(pick):
			_say("%s → All foes  %d PP" % [PrayerBook.spell_name(pick), PrayerBook.base_cost(pick)])
		else:
			_say("%s → %s  %d PP" % [PrayerBook.spell_name(pick), battle.short_name(target), PrayerBook.base_cost(pick)])
		return {"pray": pick, "target": target, "extra": 0, "paid": 0, "owed": 0}
	return {}


## D-111: a unit with the "spells" meta (Survival human allies) only lists the spells it knows.
func _build_menu(avail: int, details: Array, acts_left: int, unit: BattleUnit = null) -> void:
	menu_rows.clear()
	menu_ids.clear()
	menu_info.clear()
	if acts_left > 0:
		menu_rows.append("PRAY  +1 PP")
		menu_ids.append(PrayerBook.PRAY)
		menu_info.append("PRAY 1 ACT: +1 PP (max %d)." % PrayerBook.MAX_PP)
	var has_meta := unit != null and unit.has_meta("spells")
	var known: Array = unit.get_meta("spells") as Array if has_meta else []
	var order: Array[StringName] = PrayerBook.ALL_BOOK_ORDER if has_meta else PrayerBook.SPELL_ORDER
	for id in order:
		if has_meta and not known.has(String(id)):
			continue
		var queued := false
		for d in details:
			if (d as Dictionary).get("pray", &"") == id:
				queued = true
		var acts_needed := PrayerBook.act_cost(id)
		var castable := acts_left >= acts_needed and PrayerBook.base_cost(id) <= avail
		var allocatable := queued and avail >= 1 and PrayerBook.accepts_extra_pp(id)
		if castable or allocatable:
			var label := "%s  %d PP" % [PrayerBook.spell_name(id), PrayerBook.base_cost(id)]
			if acts_needed > 1:
				label += " / %d ACT" % acts_needed
			menu_rows.append(label)
			menu_ids.append(id)
			var extra_hint := " | queued: same target = +1 PP" if (queued and PrayerBook.accepts_extra_pp(id)) else ""
			menu_info.append(String(PrayerBook.spell(id).info) + extra_hint)


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
	var id := StringName(d.pray)
	var acts_needed := PrayerBook.act_cost(id)
	if unit.acts_available < acts_needed:
		_release(unit, d, "no act left")
		return true
	for _a in acts_needed:
		unit.spend_act()
	d["done"] = true
	var hud: Control = battle.hud
	battle.action_attacker = unit
	battle.action_defender = d.get("target", unit)
	battle.phase_text = ("REACTION " if reacting else "") + ("PRAY" if id == PrayerBook.PRAY else PrayerBook.spell_name(id))
	if id == PrayerBook.PRAY:
		await _pray(unit, reacting)
	elif id == PrayerBook.MAGEN:
		var allies: Array = battle._allies_of(unit)
		for ally in allies:
			(ally as BattleUnit).def_stages.append(SkillFx.MAGEN_ROUNDS)
		fx.play_magen(allies)
		_log("%s prays Magen: all allies +1 DEF stage until the end of the next round (%d PP)." % [unit.display_name, _cost(d)])
		_event("%s Magen → All allies  DEF ↑" % battle.short_name(unit))
		if reacting:
			unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	elif id == PrayerBook.CHEREV:
		var foes: Array[BattleUnit] = []
		for foe in battle.hud.opponents.duplicate():
			if (foe as BattleUnit).is_alive():
				foes.append(foe)
		if foes.is_empty():
			_release(unit, d, "no foe left")
		else:
			await _cherev(unit, foes, d, reacting)
	else:
		var target: BattleUnit = d.target
		if not target.is_alive():
			# The target fell before the cast resolved: no effect, the PP come back.
			_release(unit, d, "%s is down" % target.display_name)
		elif id == PrayerBook.RAAM:
			await _raam(unit, target, d, reacting)
		elif id == PrayerBook.REFUAH:
			var healed := target.heal(PrayerBook.refuah_heal(int(d.extra)))
			fx.play_refuah(target, int(d.extra))
			_log("%s prays Refuah on %s: +%d HP (%d PP)." % [unit.display_name, target.display_name, healed, _cost(d)])
			_event("%s REFUAH → %s  +%d HP" % [battle.short_name(unit), battle.short_name(target), healed])
			hud.feedback = "%s: HP %d/%d | PP %d/%d" % [battle.short_name(target), target.current_hp,
				target.stats.max_hp, unit.current_pp, PrayerBook.MAX_PP]
		elif id == PrayerBook.HAGANAH:
			fx.cast(target)
			target.haganah = {"round": battle.state.round_number,
				"owner": battle.turn_owner.id if battle.turn_owner != null else &""}
			_log("%s prays Haganah on %s: shielded from status conditions for one round (%d PP)." % [
				unit.display_name, target.display_name, _cost(d)])
			_event("%s Haganah → %s" % [battle.short_name(unit), battle.short_name(target)])
		elif id == PrayerBook.TAHORAH:
			var cleared := SkillFx.cleanse_all(target)
			fx.play_tahorah(target)
			_log("%s prays Tahorah on %s: %d condition(s) cleansed (%d PP)." % [unit.display_name, target.display_name, cleared, _cost(d)])
			_event("%s Tahorah → %s" % [battle.short_name(unit), battle.short_name(target)])
		elif id == PrayerBook.GEVURAH:
			var bonus := PrayerBook.gevurah_bonus(int(d.extra))
			target.gevurah_bonus = maxf(target.gevurah_bonus, bonus)
			fx.play_gevurah(target)
			var pct := int(round(bonus * 100.0))
			_log("%s prays Gevurah on %s: next attack +%d%% damage (%d PP)." % [unit.display_name, target.display_name, pct, _cost(d)])
			_event("%s Gevurah → %s  +%d%%" % [battle.short_name(unit), battle.short_name(target), pct])
		elif id == PrayerBook.MISHPAT:
			await fx.play_mishpat(unit, target)
			if not battle.is_inside_tree() or not target.is_alive():
				return true
			var dmg := PrayerBook.mishpat_damage(target.last_damage_dealt)
			var applied := target.take_damage(dmg)
			unit.last_damage_dealt = applied
			battle.fx.play("RAAM", target, applied, unit)
			_log("%s prays Mishpat on %s: %d damage (last dealt %d + 15, %d PP)." % [
				unit.display_name, target.display_name, applied, target.last_damage_dealt, _cost(d)])
			_event("%s Mishpat → %s  %d%s" % [battle.short_name(unit), battle.short_name(target), applied,
				battle.result_suffix(target, unit, not target.is_alive(), 0)])
		elif id == PrayerBook.ZOHAR:
			SkillFx.apply_status(target, &"zohar", SkillFx.ZOHAR_ROUNDS)
			fx.play_zohar(target)
			_log("%s prays Zohar on %s: POINT zone widened until the end of the next round (%d PP)." % [
				unit.display_name, target.display_name, _cost(d)])
			_event("%s Zohar → %s" % [battle.short_name(unit), battle.short_name(target)])
		elif id == PrayerBook.SANVERIM:
			SkillFx.apply_status(target, &"blind", SkillFx.BLIND_ROUNDS)
			fx.play_sanverim(target)
			_log("%s prays Sanverim on %s: blinded until the end of the next round (%d PP)." % [
				unit.display_name, target.display_name, _cost(d)])
			_event("%s Sanverim → %s" % [battle.short_name(unit), battle.short_name(target)])
		elif id == PrayerBook.NECHAMAH:
			target.mends.append(SkillFx.MEND_ROUNDS)
			fx.play_nechamah(target, target.mends.size())
			_log("%s prays Nechamah on %s: +%d HP per round for %d rounds (%d PP)." % [
				unit.display_name, target.display_name, SkillFx.MEND_HEAL, SkillFx.MEND_ROUNDS, _cost(d)])
			_event("%s Nechamah → %s" % [battle.short_name(unit), battle.short_name(target)])
		if reacting and id in [PrayerBook.REFUAH, PrayerBook.HAGANAH, PrayerBook.TAHORAH, PrayerBook.GEVURAH, PrayerBook.MISHPAT, PrayerBook.ZOHAR, PrayerBook.SANVERIM, PrayerBook.NECHAMAH]:
			unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	save(unit)
	battle._refresh_all()
	return true


func _reaction_pick(unit: BattleUnit) -> Dictionary:
	_plan_start_pp = unit.current_pp
	while true:
		_build_menu(unit.current_pp, [], unit.acts_available, unit)
		var pick := await _wait_menu("PRAY  %d PP | Z: confirm | X: back" % unit.current_pp)
		if pick == &"":
			return {}
		if pick == PrayerBook.PRAY:
			return {"pray": PrayerBook.PRAY}
		var target: BattleUnit = unit
		if not PrayerBook.targets_allies(pick) and not PrayerBook.targets_enemies(pick):
			target = await battle._wait_target("enemy" if PrayerBook.targets_enemy(pick) else "player")
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
	_event("%s  PRAY" % battle.short_name(unit))
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
		# D-110: o anúncio do golpe saiu do log (setas e cartões mostram quem ataca).
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
		_event("%s  PRAYER BROKEN" % battle.short_name(unit))
		return
	var gained := unit.change_pp(1)
	fx.cast(unit)
	var paid := _settle_owed(unit)
	_log("%s prays: +%d PP (%d/%d%s)." % [unit.display_name, gained, unit.current_pp, PrayerBook.MAX_PP, paid])
	_event("%s  +%d PP" % [battle.short_name(unit), gained])
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


## D-107 / D-109 Cherev (ally cast): uses the rhythm bar like Ra'am and enemy Cherev,
## then slices every living foe with the prayer formula (10 + MAK - MEF).
func _cherev(unit: BattleUnit, foes: Array[BattleUnit], d: Dictionary, reacting: bool) -> void:
	_log("%s prays Cherev on all foes (%d PP)." % [unit.display_name, _cost(d)])
	if not reacting:
		battle._clear_roles()
	battle._set_role(unit, "REACT" if reacting else "ATTACK")
	for foe in foes:
		battle._set_role(foe, "TARGET")
	_event("%s Cherev → All foes" % battle.short_name(unit))
	var marks: Array[float] = [0.5]
	var attack: Array[int] = await battle._skill_attack_timing(unit, foes[0], marks, false)
	await fx.play_cherev(true)
	if not battle.is_inside_tree():
		return
	var gained_react_sp := false
	for foe in foes:
		if not foe.is_alive():
			continue
		var defense: Array[int] = await battle._skill_defense_timing(foe, unit, marks, false)
		battle.action_attacker = unit
		battle.action_defender = foe
		battle.attack_result = attack[0]
		battle.defense_result = defense[0]
		if not BattleMath.has_contact(attack[0], defense[0]):
			if defense[0] != BattleMath.RhythmResult.MISS:
				battle._set_role(foe, "DEFEND")
			_log("%s -> %s: 0 dmg (Cherev, NO CONTACT)" % [unit.display_name, foe.display_name])
			_event("%s → %s  DODGE" % [battle.short_name(unit), battle.short_name(foe)])
			battle._present_strike(unit, foe, 0)
			continue
		var r := PrayerBook.raam_damage(0, unit.stats.mak, unit.stats.agi, foe.stats.mef,
			unit.current_sp, foe.current_sp, foe.affinity, foe.race, battle.rng)
		if bool(r.angel):
			_log("%s -> %s: 0 dmg (Cherev has no effect on angels)" % [unit.display_name, foe.display_name])
			_event("%s → %s  NO EFFECT" % [battle.short_name(unit), battle.short_name(foe)])
			battle._present_strike(unit, foe, 0, true)
			continue
		var amount := BattleMath.scaled_damage(int(r.amount), attack[0], defense[0])
		var beam := defense[0] == BattleMath.RhythmResult.BEAM
		var applied := foe.take_damage(amount)
		unit.last_damage_dealt = applied
		unit.grant_acts(BattleMath.press_turn_acts(foe.affinity))
		if bool(r.crit):
			unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
		if foe.affinity == BattleMath.Affinity.WEAK and applied > 0:
			unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
		if reacting and not gained_react_sp:
			unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
			gained_react_sp = true
		if defense[0] != BattleMath.RhythmResult.MISS:
			battle._set_role(foe, "DEFEND")
		battle.fx.play("RAAM_BLOCK" if beam else "RAAM", foe, applied, unit)
		_log("%s -> %s: %d dmg (Cherev, rhythm %s, def %s)" % [unit.display_name, foe.display_name, applied,
			battle._rhythm_name(attack[0]), battle._rhythm_name(defense[0])])
		# D-110: one telegraphic line per foe, the fall inside it.
		_event("%s → %s  %d%s%s" % [battle.short_name(unit), battle.short_name(foe), applied, "  BLOCK" if beam else "",
			battle.result_suffix(foe, unit, not foe.is_alive(), 0)])


## Ra'am: the struck enemy may counter-attack it on the D-049 two rails (33%); otherwise
## Yoch's attack rail against the enemy's defense, like ATTACK.
func _raam(unit: BattleUnit, target: BattleUnit, d: Dictionary, reacting: bool) -> void:
	_log("%s prays Ra'am on %s (%d PP)." % [unit.display_name, target.display_name, _cost(d)])
	if not reacting: battle._clear_roles()
	battle._set_role(unit, "REACT" if reacting else "ATTACK")
	battle._set_role(target, "TARGET")
	# D-110: o anúncio do golpe saiu do log (setas e cartões mostram quem ataca).
	var extra := int(d.extra)
	if target.acts_available > 0 and battle._enemy_raam_counter_roll(target):
		target.spend_act()
		battle._append_log("%s counter-attacks %s's Ra'am (1 act spent)." % [target.display_name, unit.display_name])
		battle._set_role(target, "COUNTER")
		# D-110: o anúncio do golpe saiu do log (setas e cartões mostram quem ataca).
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
		_event("%s → %s  DODGE" % [battle.short_name(unit), battle.short_name(target)])
		battle._present_strike(unit, target, 0, false, false)
		return
	# Approved thunder (2026-11-23): the damage lands at the strike.
	await fx.play_raam(target)
	if not battle.is_inside_tree() or not target.is_alive():
		return
	var r := PrayerBook.raam_damage(extra, unit.stats.mak, unit.stats.agi, target.stats.mef,
		unit.current_sp, target.current_sp, target.affinity, target.race, battle.rng)
	if bool(r.angel):
		_log("%s -> %s: 0 dmg (Ra'am has no effect on angels)" % [unit.display_name, target.display_name])
		_event("%s → %s  NO EFFECT" % [battle.short_name(unit), battle.short_name(target)])
		battle._present_strike(unit, target, 0, true, false)
		return
	var amount := int(r.amount)
	# D-109: marco do ataque 50/80/100%; defesa na lateral = metade.
	amount = BattleMath.scaled_damage(amount, attack, defense)
	var beam := defense == BattleMath.RhythmResult.BEAM
	var applied := target.take_damage(amount)
	unit.last_damage_dealt = applied
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
	var line := "%s → %s  %d%s" % [battle.short_name(unit), battle.short_name(target), dealt,
		"  BLOCK" if defense == BattleMath.RhythmResult.BEAM else ""]
	# D-110: a queda e o ato ganho entram na linha do resultado.
	_event(line + battle.result_suffix(target, unit, not target.is_alive(), BattleMath.press_turn_acts(target.affinity)))
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
		_event("%s NOT CAST  +%d PP" % [PrayerBook.spell_name(StringName(d.pray)), back])


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
	battle._event("%s  REST  %d ACT KEPT" % [battle.short_name(unit), remaining])
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
			_event("%s  HAGANAH END" % battle.short_name(unit))


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
