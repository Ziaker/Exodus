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
	if bool(d.get("en_paid", false)):
		return 0
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
		if not PrayerBook.targets_allies(pick) and not PrayerBook.targets_enemies(pick) and not PrayerBook.targets_self(pick):
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
		var en_paid := PrayerBook.uses_en(pick, unit)
		var entry := {"spell": pick, "cost": 0 if en_paid else PrayerBook.base_cost(pick)}
		if not bool(PrayerBook.simulate(_plan_start_pp, _queue(details, -1, 0, entry)).ok):
			_say("NO PP: %s" % PrayerBook.spell_name(pick))
			continue
		if PrayerBook.targets_allies(pick):
			_say("%s → All allies  %d PP" % [PrayerBook.spell_name(pick), PrayerBook.base_cost(pick)])
		elif PrayerBook.targets_enemies(pick):
			_say("%s → All foes  %d PP" % [PrayerBook.spell_name(pick), PrayerBook.base_cost(pick)])
		elif PrayerBook.targets_self(pick):
			_say("%s → Self" % PrayerBook.spell_name(pick))
		else:
			_say("%s → %s  %d PP" % [PrayerBook.spell_name(pick), battle.short_name(target), PrayerBook.base_cost(pick)])
		return {"pray": pick, "target": target, "extra": 0, "paid": 0, "owed": 0, "en_paid": en_paid}
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
	var seen: Array[StringName] = []
	for base_id in order:
		if has_meta and not known.has(String(base_id)):
			continue
		# D-118: Esh -> Ur Esh and Adin -> Adina -> Adinut evolve in the round after their use.
		var id := resolve_evolution(unit, base_id)
		if seen.has(id):
			continue
		seen.append(id)
		var queued := false
		for d in details:
			if (d as Dictionary).get("pray", &"") == id:
				queued = true
		var acts_needed := PrayerBook.act_cost(id)
		var pp_needed := PrayerBook.base_cost(id)
		var en_needed := PrayerBook.en_cost(id)
		var use_en := PrayerBook.uses_en(id, unit) or (pp_needed == 0 and en_needed > 0)
		var free_skill := pp_needed == 0 and en_needed == 0
		var has_resource := free_skill or ((unit != null and unit.current_en >= en_needed) if use_en else (pp_needed <= avail))
		var castable := acts_left >= acts_needed and has_resource
		var allocatable := queued and avail >= 1 and PrayerBook.accepts_extra_pp(id)
		if castable or allocatable:
			var label := "%s  %d EN" % [PrayerBook.spell_name(id), en_needed] if (use_en or free_skill) else "%s  %d PP" % [PrayerBook.spell_name(id), pp_needed]
			if acts_needed > 1:
				label += " / %d ACT" % acts_needed
			if PrayerBook.is_immediate(id):
				label += "  IMMEDIATE"
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
	# Pre-check EN cost before spending ACTs (Hasneh Habo'er, or angels using Esh Sinai).
	var needs_en := PrayerBook.uses_en(id, unit)
	if needs_en and unit.current_en < PrayerBook.en_cost(id):
		_release(unit, d, "not enough EN")
		return true
	# D-118 Nitzotz only works on a foe that is already burning (checked before any cost is paid).
	if id == PrayerBook.NITZOTZ:
		var nit_target: BattleUnit = d.get("target", null)
		if nit_target == null or not nit_target.is_alive() or nit_target.burns.is_empty():
			_release(unit, d, "the target is not burning")
			return true
	for _a in acts_needed:
		unit.spend_act()
	# D-124 VULN PIERCE: a prayer on allies / the caster itself is a non-offensive action.
	unit.passive_stance = String(PrayerBook.entry(id).get("target", "self")) in ["ally", "allies", "self"]
	if needs_en:
		unit.current_en -= PrayerBook.en_cost(id)
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
	elif id == PrayerBook.SHACHAR:
		_pending_shachar.append({"caster": unit, "round": battle.state.round_number,
			"caster_mak": unit.stats.mak})
		fx.play_shachar()
		_log("%s invokes Shachar: radiant dawn will strike all foes (30 + %d MAK - MEF) at the start of the next round (%d PP)." % [
			unit.display_name, unit.stats.mak, _cost(d)])
		_event("%s invokes Shachar: dawn gathers above." % battle.short_name(unit))
		if reacting:
			unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	elif id == PrayerBook.HASNEH_HABOER:
		var en_needed := PrayerBook.en_cost(id)
		var bush := _summon_burning_bush(unit)
		var bush_unit: BattleUnit = bush.unit
		fx.play_hasneh_haboer(unit, bush_unit.current_hp, bush_unit)
		_log("%s invokes Hasneh Habo'er: Burning Bush (%d HP) enters battle as an enemy summon (%d EN)." % [
			unit.display_name, bush_unit.current_hp, en_needed])
		_event("%s summons the Burning Bush (%d HP)!" % [battle.short_name(unit), bush_unit.current_hp])
		if reacting:
			unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	elif id == PrayerBook.SHALHEVET:
		var foes: Array[BattleUnit] = []
		for foe in battle.hud.opponents.duplicate():
			if (foe as BattleUnit).is_alive():
				foes.append(foe)
		if foes.is_empty():
			_release(unit, d, "no foe left")
		else:
			await _shalhevet(unit, foes, d, reacting)
	elif id == PrayerBook.NOGAH:
		var foes: Array[BattleUnit] = []
		for foe in battle.hud.opponents.duplicate():
			if (foe as BattleUnit).is_alive():
				foes.append(foe)
		if foes.is_empty():
			_release(unit, d, "no foe left")
		else:
			await _nogah(unit, foes, d, reacting)
	elif id == PrayerBook.LIOR:
		var total_pp := _cost(d)
		var heal_amt := PrayerBook.lior_heal(total_pp)
		_lior_states[unit] = {"actions": PrayerBook.LIOR_ACTIONS, "heal": heal_amt}
		fx.play_lior(unit, PrayerBook.LIOR_ACTIONS)
		_log("%s prays Lior: heals %d HP per action for the next %d actions (%d PP)." % [
			unit.display_name, heal_amt, PrayerBook.LIOR_ACTIONS, total_pp])
		_event("%s is wrapped in Lior (%d HP x%d)." % [battle.short_name(unit), heal_amt, PrayerBook.LIOR_ACTIONS])
		if reacting:
			unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	elif id == PrayerBook.MEIR:
		SkillFx.apply_status(unit, &"taunt", 1)
		fx.play_meir(unit, battle.hud.opponents)
		_log("%s prays Meir: every foe can only attack it until the end of the round (%d PP)." % [unit.display_name, _cost(d)])
		_event("%s prays Meir: all foes turn to it!" % battle.short_name(unit))
		if reacting:
			unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	elif id == PrayerBook.SERAF:
		var seraf_healed := unit.heal(PrayerBook.seraf_heal(unit.stats.mak))
		unit.add_sp(PrayerBook.SERAF_SP)
		fx.play_seraf(unit, seraf_healed)
		_log("%s invokes Seraf: +%d HP, +%d SP." % [unit.display_name, seraf_healed, PrayerBook.SERAF_SP])
		_event("%s invokes Seraf: +%d HP, +%d SP." % [battle.short_name(unit), seraf_healed, PrayerBook.SERAF_SP])
		if reacting:
			unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	elif id == PrayerBook.GEVER:
		for _s in PrayerBook.GEVER_STAGES:
			battle._add_stage(unit)
		fx.play_gever(unit)
		_log("%s invokes Gever: +%d ATK stages until the end of the next round (%d active)." % [
			unit.display_name, PrayerBook.GEVER_STAGES, unit.atk_stages.size()])
		_event("%s invokes Gever: ATK +%d stages!" % [battle.short_name(unit), PrayerBook.GEVER_STAGES])
		if reacting:
			unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	elif id == PrayerBook.ADIN or id == PrayerBook.ADINA or id == PrayerBook.ADINUT:
		var rec := PrayerBook.adin_recovery(id)
		var en_before := unit.current_en
		unit.recover_en_flat(int(rec.en))
		var adin_hp := unit.heal(int(rec.hp))
		fx.play_adin(unit, [PrayerBook.ADIN, PrayerBook.ADINA, PrayerBook.ADINUT].find(id))
		_log("%s casts %s: +%d EN, +%d HP." % [unit.display_name, PrayerBook.spell_name(id), unit.current_en - en_before, adin_hp])
		_event("%s casts %s: +%d EN%s." % [battle.short_name(unit), PrayerBook.spell_name(id), unit.current_en - en_before,
			", +%d HP" % adin_hp if int(rec.hp) > 0 else ""])
		if reacting:
			unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
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
		elif id == PrayerBook.CHAKI:
			SkillFx.apply_status(target, &"chaki", 1)
			target.acts_available = 0
			fx.play_chaki(target)
			_log("%s prays Chaki on %s: bound in light, cannot act until round end (%d PP)." % [
				unit.display_name, target.display_name, _cost(d)])
			_event("%s Chaki → %s" % [battle.short_name(unit), battle.short_name(target)])
		elif id == PrayerBook.LEHAVAH:
			await _lehavah(unit, target, d, reacting)
		elif id == PrayerBook.ESH_SINAI:
			await _esh_sinai(unit, target, d, reacting)
		elif id == PrayerBook.ESH:
			await _esh(unit, target, d, reacting)
		elif id == PrayerBook.UR_ESH:
			await _ur_esh(unit, target, d, reacting)
		elif id == PrayerBook.NITZOTZ:
			await _nitzotz(unit, target, d, reacting)
		elif id == PrayerBook.ESH_OCHELET:
			_esh_ochelet(unit, target, d, reacting)
		elif id == PrayerBook.ANGEL_HUG:
			await _angel_hug(unit, target, d, reacting)
		elif id == PrayerBook.GODS_MESSAGE:
			await _gods_message(unit, target, d, reacting)
		if reacting and id in [PrayerBook.REFUAH, PrayerBook.HAGANAH, PrayerBook.TAHORAH, PrayerBook.GEVURAH, PrayerBook.MISHPAT, PrayerBook.ZOHAR, PrayerBook.SANVERIM, PrayerBook.NECHAMAH, PrayerBook.CHAKI]:
			unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	_register_evolution(unit, id)
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
		if not PrayerBook.targets_allies(pick) and not PrayerBook.targets_enemies(pick) and not PrayerBook.targets_self(pick):
			target = await battle._wait_target("enemy" if PrayerBook.targets_enemy(pick) else "player")
			if target == null:
				continue
		var en_paid := PrayerBook.uses_en(pick, unit)
		var cost := 0 if en_paid else PrayerBook.base_cost(pick)
		unit.change_pp(-cost)
		battle._refresh_all()
		return {"pray": pick, "target": target, "extra": 0, "paid": cost, "owed": 0, "en_paid": en_paid}
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
		var r := PrayerBook.raam_damage(0, int(round(unit.effective_mak())), unit.effective_agi(), foe.effective_mef(),
			unit.current_sp, foe.current_sp, foe.race, battle.rng)
		if bool(r.angel):
			_log("%s -> %s: 0 dmg (Cherev has no effect on angels)" % [unit.display_name, foe.display_name])
			_event("%s → %s  NO EFFECT" % [battle.short_name(unit), battle.short_name(foe)])
			battle._present_strike(unit, foe, 0, true)
			continue
		var amount := BattleMath.scaled_damage(int(r.amount), attack[0], defense[0])
		var beam := defense[0] == BattleMath.RhythmResult.BEAM
		var applied := foe.take_damage(amount)
		unit.last_damage_dealt = applied
		if bool(r.crit):
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
	var r := PrayerBook.raam_damage(extra, int(round(unit.effective_mak())), unit.effective_agi(), target.effective_mef(),
		unit.current_sp, target.current_sp, target.race, battle.rng)
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
	if bool(r.crit):
		unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	if reacting:
		unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	_log("%s -> %s: %d dmg (Ra'am base %d, %s, rhythm %s, def %s, crit %s, SP roll %+d)" % [
		unit.display_name, target.display_name, applied, int(r.base), "BLOCK" if beam else ("FULL" if attack == BattleMath.RhythmResult.POINT else "HIT %d%%" % int(round(BattleMath.strike_multiplier(attack, defense) * 100.0))),
		battle._rhythm_name(attack), battle._rhythm_name(defense), "YES" if bool(r.crit) else "no",
		int(r.sp_roll)])
	var dealt := hp_before - target.current_hp
	if defense != BattleMath.RhythmResult.MISS:
		battle._set_role(target, "DEFEND")
	var line := "%s → %s  %d%s" % [battle.short_name(unit), battle.short_name(target), dealt,
		"  BLOCK" if defense == BattleMath.RhythmResult.BEAM else ""]
	# D-110: a queda e o ato ganho entram na linha do resultado.
	_event(line + battle.result_suffix(target, unit, not target.is_alive(), 0))
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


## D-118 Shachar: pending dawn casts that detonate at the start of the next round.
var _pending_shachar: Array[Dictionary] = []
## D-118 Hasneh Habo'er: living Burning Bushes summoned by Gabriel (10 HP each; BURN + 2x vs burning).
var burning_bushes: Array[Dictionary] = []
## D-118 Lior: unit -> {"actions": int, "heal": int} healing shroud over 5 actions.
var _lior_states: Dictionary = {}


## D-118 Shalhevet: sweeping fire wave dealing (30 + MAK - MEF) to all foes with 50% BURN.
func _shalhevet(unit: BattleUnit, foes: Array[BattleUnit], d: Dictionary, reacting: bool) -> void:
	await fx.play_shalhevet(foes)
	if not battle.is_inside_tree():
		return
	var burned_count := 0
	for foe in foes:
		if not foe.is_alive():
			continue
		var dmg := PrayerBook.shalhevet_damage(unit.stats.mak, foe.stats.mef)
		var applied := foe.take_damage(dmg)
		unit.last_damage_dealt = applied
		var burned := false
		if foe.is_alive() and foe.haganah.is_empty() and battle.rng.randi_range(0, 99) < PrayerBook.SHALHEVET_BURN_CHANCE:
			foe.burns.append(SkillBook.BURN_ROUNDS)
			burned = true
			burned_count += 1
		battle.fx.play("RAAM", foe, applied, unit)
		_log("%s prays Shalhevet -> %s: %d damage%s (%d PP)." % [
			unit.display_name, foe.display_name, applied, ", BURN" if burned else "", _cost(d)])
		if not foe.is_alive():
			_event("%s is down." % battle.short_name(foe))
	_event("Shalhevet scorches all foes%s!" % (" (%d burned)" % burned_count if burned_count > 0 else ""))
	if reacting:
		unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)


## D-118 Nogah: blinding starlight across all foes until end of next round (respecting Haganah).
func _nogah(unit: BattleUnit, foes: Array[BattleUnit], d: Dictionary, reacting: bool) -> void:
	await fx.play_nogah(foes)
	if not battle.is_inside_tree():
		return
	var blinded_count := 0
	for foe in foes:
		if not foe.is_alive():
			continue
		if foe.haganah.is_empty():
			SkillFx.apply_status(foe, &"blind", SkillFx.BLIND_ROUNDS)
			blinded_count += 1
	_log("%s prays Nogah: %d foe(s) blinded until the end of the next round (%d PP)." % [
		unit.display_name, blinded_count, _cost(d)])
	_event("Nogah blinds all foes!" if blinded_count > 0 else "Nogah flashes across the stage.")
	if reacting:
		unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)


func lior_state(unit: BattleUnit) -> Dictionary:
	return _lior_states.get(unit, {})


## D-118 Lior: heals `unit` by 5 + 5/PP on action completion and decrements remaining actions.
func tick_lior(unit: BattleUnit) -> int:
	if unit == null or not unit.is_alive() or not _lior_states.has(unit):
		return 0
	var st: Dictionary = _lior_states[unit]
	var actions := int(st.get("actions", 0))
	if actions <= 0:
		_lior_states.erase(unit)
		fx.set_lior_actions(unit, 0)
		return 0
	var healed := unit.heal(int(st.get("heal", 0)))
	actions -= 1
	st.actions = actions
	if actions <= 0:
		_lior_states.erase(unit)
	fx.play_lior_tick(unit, healed, actions)
	_log("Lior heals %s: +%d HP (%d action(s) left)." % [unit.display_name, healed, actions])
	_event("Lior heals %s: +%d HP." % [battle.short_name(unit), healed])
	battle._refresh_all()
	return healed


## D-118 Lehavah: (40 + MAK - MEF) light-and-fire explosion + blind (respecting Haganah).
func _lehavah(unit: BattleUnit, target: BattleUnit, d: Dictionary, reacting: bool) -> void:
	await fx.play_lehavah(target)
	if not battle.is_inside_tree() or not target.is_alive():
		return
	var dmg := PrayerBook.lehavah_damage(unit.stats.mak, target.stats.mef)
	var applied := target.take_damage(dmg)
	unit.last_damage_dealt = applied
	var blinded := false
	if target.is_alive() and target.haganah.is_empty():
		SkillFx.apply_status(target, &"blind", SkillFx.BLIND_ROUNDS)
		blinded = true
	battle.fx.play("RAAM", target, applied, unit)
	_log("%s prays Lehavah on %s: %d damage%s (%d PP)." % [
		unit.display_name, target.display_name, applied, ", blinded" if blinded else "", _cost(d)])
	_event("Lehavah explodes on %s: %d damage%s!" % [
		battle.short_name(target), applied, " (BLIND)" if blinded else ""])
	if not target.is_alive():
		_event("%s is down." % battle.short_name(target))
	if reacting:
		unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)


## D-118 Esh Sinai: IMMEDIATE (30 - MEF) magic damage (does NOT ignore defenses),
## followed by 3 successive reactable hits. Angels pay 40 EN; Yoch pays 6 PP.
func _esh_sinai(unit: BattleUnit, target: BattleUnit, _d: Dictionary, reacting: bool) -> void:
	fx.play_esh_sinai(target)
	# Hit 0: IMMEDIATE (no delay, no reaction window; respects MEF)
	var hit_dmg := PrayerBook.esh_sinai_hit_damage(target.stats.mef)
	var applied0 := target.take_damage(hit_dmg)
	unit.last_damage_dealt = applied0
	battle.fx.play("RAAM", target, applied0, unit)
	_log("%s casts Esh Sinai (IMMEDIATE) on %s: %d damage." % [unit.display_name, target.display_name, applied0])
	_event("Esh Sinai (IMMEDIATE) strikes %s: %d damage!" % [battle.short_name(target), applied0])
	if reacting:
		unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	battle._refresh_all()
	if not target.is_alive():
		fx.cancel_esh_sinai_after(0)
		_event("%s is down." % battle.short_name(target))
		return
	# Hits 1..3: successive reactable strikes synchronized with PrayFX pillars
	var delays: Array[float] = [0.72, 0.60, 0.60]
	var tags: Array[String] = ["I", "II", "III"]
	for idx in PrayerBook.ESH_SINAI_FOLLOWUP_HITS:
		await battle.get_tree().create_timer(delays[idx]).timeout
		if not battle.is_inside_tree():
			return
		if not target.is_alive():
			fx.cancel_esh_sinai_after(idx)
			return
		var follow_dmg := PrayerBook.esh_sinai_hit_damage(target.stats.mef)
		var applied := target.take_damage(follow_dmg)
		unit.last_damage_dealt = applied
		battle.fx.play("RAAM", target, applied, unit)
		_log("%s's Esh Sinai (%s) hits %s: %d damage." % [unit.display_name, tags[idx], target.display_name, applied])
		_event("Esh Sinai (%s) strikes %s: %d damage!" % [tags[idx], battle.short_name(target), applied])
		battle._refresh_all()
		if not target.is_alive():
			fx.cancel_esh_sinai_after(idx + 1)
			_event("%s is down." % battle.short_name(target))
			return


## D-118 Hasneh Habo'er: summons a real 10 HP Burning Bush BattleUnit into BattleState & HUD opponents.
func _summon_burning_bush(caster: BattleUnit) -> Dictionary:
	var idx := burning_bushes.size() + 1
	var st := UnitStats.new()
	st.max_hp = PrayerBook.HASNEH_BUSH_HP
	st.max_en = 0
	st.atk = PrayerBook.HASNEH_BUSH_BASE_DAMAGE
	st.mak = PrayerBook.HASNEH_BUSH_BASE_DAMAGE
	st.defense = 6
	st.mef = 6
	st.agi = 8
	var bush_unit := BattleUnit.new(StringName("burning_bush_%d" % idx), "BURNING BUSH", st, false, false)
	bush_unit.kind = &"burning_bush"
	bush_unit.race = &"summon"
	bush_unit.acts_available = 2
	battle.state.add_unit(bush_unit)
	battle.state.turn_order.append(bush_unit)
	# Keep silhouettes array aligned with opponents using a 1x1 transparent texture (body is 100% Hebrew letters in PrayFX).
	while battle.hud.silhouettes.size() < battle.hud.opponents.size():
		battle.hud.silhouettes.append(_transparent_tex())
	battle.hud.opponents.append(bush_unit)
	battle.hud.silhouettes.append(_transparent_tex())
	var bush := {
		"caster": caster,
		"unit": bush_unit,
		"hp": bush_unit.current_hp,
		"max_hp": bush_unit.stats.max_hp,
		"alive": true,
	}
	burning_bushes.append(bush)
	battle._refresh_all()
	return bush


func _transparent_tex() -> ImageTexture:
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


func living_burning_bushes() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for b in burning_bushes:
		var u: BattleUnit = b.get("unit", null)
		if u != null:
			b.hp = u.current_hp
			b.alive = u.is_alive()
		if bool(b.get("alive", false)) and int(b.get("hp", 0)) > 0:
			out.append(b)
	return out


## Damages a summoned Burning Bush BattleUnit directly; updates its VFX entry and clears it at 0 HP.
func damage_burning_bush(index: int, amount: int) -> int:
	if index < 0 or index >= burning_bushes.size():
		return 0
	var bush: Dictionary = burning_bushes[index]
	var u: BattleUnit = bush.get("unit", null)
	if u != null:
		if not u.is_alive():
			return 0
		var applied := u.take_damage(amount)
		bush.hp = u.current_hp
		bush.alive = u.is_alive()
		if not u.is_alive():
			_log("The Burning Bush is extinguished.")
			_event("The Burning Bush fades.")
		fx.set_hasneh_bush_hp(index, u.current_hp)
		battle._refresh_all()
		return applied
	if not bool(bush.get("alive", false)):
		return 0
	var fallback_applied := mini(int(bush.hp), maxi(0, amount))
	bush.hp = int(bush.hp) - fallback_applied
	if int(bush.hp) <= 0:
		bush.alive = false
		_log("The Burning Bush is extinguished.")
		_event("The Burning Bush fades.")
	fx.set_hasneh_bush_hp(index, int(bush.hp))
	return fallback_applied


## Convenience wrapper for AI turns: resolves the Burning Bush attack by its BattleUnit reference.
func burning_bush_attack_unit(bush_unit: BattleUnit, target: BattleUnit,
		base_dmg: int = PrayerBook.HASNEH_BUSH_BASE_DAMAGE) -> Dictionary:
	for i in burning_bushes.size():
		if burning_bushes[i].get("unit", null) == bush_unit:
			return burning_bush_attack(i, target, base_dmg)
	return {"damage": 0, "doubled": false, "burned": false}


## Executes a Burning Bush attack on `target`: 2x damage if target is already burning, then inflicts BURN.
func burning_bush_attack(index: int, target: BattleUnit, base_dmg: int = PrayerBook.HASNEH_BUSH_BASE_DAMAGE) -> Dictionary:
	if index < 0 or index >= burning_bushes.size() or target == null or not target.is_alive():
		return {"damage": 0, "doubled": false, "burned": false}
	var bush: Dictionary = burning_bushes[index]
	if not bool(bush.get("alive", false)) or int(bush.get("hp", 0)) <= 0:
		return {"damage": 0, "doubled": false, "burned": false}
	var was_burning := not target.burns.is_empty()
	var dmg := PrayerBook.hasneh_bush_damage(was_burning, base_dmg)
	var applied := target.take_damage(dmg)
	var burned := false
	if target.is_alive() and target.haganah.is_empty():
		target.burns.append(SkillBook.BURN_ROUNDS)
		burned = true
	_log("Burning Bush attacks %s: %d damage%s%s." % [
		target.display_name, applied, " (2x BURNING)" if was_burning else "", ", BURN applied" if burned else ""])
	_event("Burning Bush sears %s: %d damage%s!" % [
		battle.short_name(target), applied, " (2x)" if was_burning else ""])
	if not target.is_alive():
		_event("%s is down." % battle.short_name(target))
	battle._refresh_all()
	return {"damage": applied, "doubled": was_burning, "burned": burned}


## D-118 evolutions: unit -> {root id -> {"stage": last cast id, "round": round of that cast}}.
var _evo: Dictionary = {}
## D-118 Esh Ochelet: marked foe -> caster (30 magic damage per action it takes in its next turn).
var _ochelet: Dictionary = {}
const STAT_NAMES := {"atk": "ATK", "defense": "DEF", "mak": "MAK", "mef": "MEF", "agi": "AGI"}


func _evolution_root(id: StringName) -> StringName:
	if id == PrayerBook.ESH or id == PrayerBook.UR_ESH:
		return PrayerBook.ESH
	if id == PrayerBook.ADIN or id == PrayerBook.ADINA or id == PrayerBook.ADINUT:
		return PrayerBook.ADIN
	return &""


func _knows(unit: BattleUnit, id: StringName) -> bool:
	if id == PrayerBook.ADINA or id == PrayerBook.ADINUT:
		return true
	return unit != null and unit.has_meta("spells") and (unit.get_meta("spells") as Array).has(String(id))


## D-118: the skill that `base_id` currently is for `unit` (Esh -> Ur Esh, Adin -> Adina -> Adinut),
## one step further in the round after each use.
func resolve_evolution(unit: BattleUnit, base_id: StringName) -> StringName:
	if unit == null or not PrayerBook.EVOLUTIONS.has(base_id) or not _evo.has(unit):
		return base_id
	var entry: Dictionary = (_evo[unit] as Dictionary).get(_evolution_root(base_id), {})
	if entry.is_empty():
		return base_id
	var stage := StringName(entry.stage)
	var nxt: StringName = PrayerBook.EVOLUTIONS.get(stage, &"")
	if nxt != &"" and int(entry.round) < battle.state.round_number and _knows(unit, nxt):
		return nxt
	return stage


func _register_evolution(unit: BattleUnit, id: StringName) -> void:
	var root := _evolution_root(id)
	if root == &"" or unit == null:
		return
	if root == PrayerBook.ESH and not _knows(unit, PrayerBook.UR_ESH):
		return
	if not _evo.has(unit):
		_evo[unit] = {}
	var chain: Dictionary = _evo[unit]
	var entry: Dictionary = chain.get(root, {})
	# Casting the same stage twice in a round keeps the first cast's round (it evolves once).
	if not entry.is_empty() and StringName(entry.stage) == id and int(entry.round) <= battle.state.round_number:
		return
	chain[root] = {"stage": id, "round": battle.state.round_number}


## Applies a BURN unless Haganah shields the target; returns true when the burn was applied.
func _ignite(target: BattleUnit) -> bool:
	if not target.is_alive() or not target.haganah.is_empty():
		return false
	target.burns.append(SkillBook.BURN_ROUNDS)
	return true


## D-118 Esh: (20 + MAK - MEF) magic damage, 30% (+10% per extra PP) BURN.
func _esh(unit: BattleUnit, target: BattleUnit, d: Dictionary, reacting: bool) -> void:
	var chance := PrayerBook.esh_burn_chance(int(d.get("extra", 0)))
	var roll_burn: bool = int(battle.rng.randi_range(0, 99)) < chance
	await fx.play_esh(unit, target, roll_burn)
	if not battle.is_inside_tree() or not target.is_alive():
		return
	var applied := target.take_damage(PrayerBook.esh_damage(unit.stats.mak, target.stats.mef))
	unit.last_damage_dealt = applied
	var burned: bool = roll_burn and _ignite(target)
	battle.fx.play("RAAM", target, applied, unit)
	_log("%s prays Esh on %s: %d damage%s (%d PP, %d%% BURN)." % [
		unit.display_name, target.display_name, applied, ", BURN" if burned else "", _cost(d), chance])
	_event("Esh scorches %s: %d damage%s!" % [battle.short_name(target), applied, " (BURN)" if burned else ""])
	if not target.is_alive():
		_event("%s is down." % battle.short_name(target))
	if reacting:
		unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)


## D-118 Ur Esh: (20 + MAK - MEF) magic damage, guaranteed BURN, +40 damage if already burning.
func _ur_esh(unit: BattleUnit, target: BattleUnit, d: Dictionary, reacting: bool) -> void:
	var was_burning := not target.burns.is_empty()
	await fx.play_ur_esh(unit, target, was_burning)
	if not battle.is_inside_tree() or not target.is_alive():
		return
	var applied := target.take_damage(PrayerBook.ur_esh_damage(unit.stats.mak, target.stats.mef, was_burning))
	unit.last_damage_dealt = applied
	var burned := _ignite(target)
	battle.fx.play("RAAM", target, applied, unit)
	_log("%s casts Ur Esh on %s: %d damage%s%s (%s)." % [unit.display_name, target.display_name, applied,
		" (+40 vs BURN)" if was_burning else "", ", BURN" if burned else "", "%d PP" % _cost(d) if unit.prays else "EN"])
	_event("Ur Esh detonates on %s: %d damage%s!" % [battle.short_name(target), applied, " (BURNING +40)" if was_burning else ""])
	if not target.is_alive():
		_event("%s is down." % battle.short_name(target))
	if reacting:
		unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)


## D-118 Nitzotz: 20 magic damage on a burning foe and its BURN rises to 10 damage per round.
func _nitzotz(unit: BattleUnit, target: BattleUnit, _d: Dictionary, reacting: bool) -> void:
	await fx.play_nitzotz(unit, target)
	if not battle.is_inside_tree() or not target.is_alive():
		return
	var applied := target.take_damage(PrayerBook.nitzotz_damage(target.stats.mef))
	unit.last_damage_dealt = applied
	var superheated := target.is_alive() and not target.burns.is_empty()
	if superheated:
		target.burn_power = PrayerBook.NITZOTZ_BURN_POWER
	battle.fx.play("RAAM", target, applied, unit)
	_log("%s casts Nitzotz on %s: %d damage%s." % [unit.display_name, target.display_name, applied,
		", BURN now %d per round" % PrayerBook.NITZOTZ_BURN_POWER if superheated else ""])
	_event("Nitzotz strikes %s: %d damage%s!" % [battle.short_name(target), applied, " (BURN %d/round)" % PrayerBook.NITZOTZ_BURN_POWER if superheated else ""])
	if not target.is_alive():
		_event("%s is down." % battle.short_name(target))
	if reacting:
		unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)


## D-118 Esh Ochelet: IMMEDIATE mark; the foe takes 30 magic damage per action it takes in its next turn.
func _esh_ochelet(unit: BattleUnit, target: BattleUnit, _d: Dictionary, reacting: bool) -> void:
	SkillFx.apply_status(target, &"ochelet", 2)
	_ochelet[target] = unit
	fx.play_esh_ochelet(target)
	_log("%s casts Esh Ochelet (IMMEDIATE) on %s: 30 magic damage for each action it takes in its next turn." % [
		unit.display_name, target.display_name])
	_event("Esh Ochelet latches onto %s!" % battle.short_name(target))
	if reacting:
		unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)


func is_ochelet_marked(unit: BattleUnit) -> bool:
	return unit != null and _ochelet.has(unit) and unit.has_status(&"ochelet")


## D-118 Esh Ochelet: one bite after each action `unit` completes (never interrupts it).
func tick_ochelet(unit: BattleUnit) -> int:
	if unit == null or not unit.is_alive() or not is_ochelet_marked(unit):
		return 0
	var caster: BattleUnit = _ochelet[unit]
	var applied := unit.take_damage(PrayerBook.esh_ochelet_damage(unit.stats.mef))
	if caster != null:
		caster.last_damage_dealt = applied
	fx.play_ochelet_bite(unit)
	battle.fx.play("RAAM", unit, applied, caster)
	_log("Esh Ochelet bites %s: %d damage." % [unit.display_name, applied])
	_event("Esh Ochelet bites %s: %d damage." % [battle.short_name(unit), applied])
	if not unit.is_alive():
		_event("%s is down." % battle.short_name(unit))
	battle._refresh_all()
	return applied


## End of `unit`'s turn: its Esh Ochelet mark is spent.
func turn_end(unit: BattleUnit) -> void:
	if unit != null and _ochelet.has(unit):
		_ochelet.erase(unit)
		unit.remove_status(&"ochelet")


## D-118 Angel Hug: IMMEDIATE; the target loses its next 3 acts (cannot act or react). Haganah blocks it.
func _angel_hug(unit: BattleUnit, target: BattleUnit, _d: Dictionary, reacting: bool) -> void:
	var blocked := not target.haganah.is_empty()
	if not blocked:
		SkillFx.apply_status(target, &"paralyzed", 4)
		target.paralyzed_acts = PrayerBook.ANGEL_HUG_ACTS
		target.apply_paralysis()
	await fx.play_angel_hug(unit, target, not blocked)
	if not battle.is_inside_tree():
		return
	if blocked:
		_log("%s uses Angel Hug on %s: blocked by Haganah." % [unit.display_name, target.display_name])
		_event("Haganah protects %s from Angel Hug." % battle.short_name(target))
	else:
		_log("%s uses Angel Hug (IMMEDIATE) on %s: paralyzed for %d acts." % [unit.display_name, target.display_name, PrayerBook.ANGEL_HUG_ACTS])
		_event("Angel Hug paralyzes %s for %d acts!" % [battle.short_name(target), PrayerBook.ANGEL_HUG_ACTS])
	if reacting:
		unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)


## Start of a round (after the acts were granted): paralysed units lose the acts they still owe.
func round_start() -> void:
	for u in battle.state.units:
		var unit: BattleUnit = u
		if unit.is_alive() and unit.paralyzed_acts > 0:
			var lost := unit.apply_paralysis()
			if lost > 0:
				_log("%s is paralyzed: -%d act(s) (%d left to lose)." % [unit.display_name, lost, unit.paralyzed_acts])
				_event("%s is paralyzed and loses %d act(s)." % [battle.short_name(unit), lost])


## D-118 God's Message: IMMEDIATE; marks the target, which loses 3 stages of a random stat on its next turn.
func _gods_message(unit: BattleUnit, target: BattleUnit, _d: Dictionary, reacting: bool) -> void:
	var blocked := not target.haganah.is_empty()
	if not blocked:
		SkillFx.apply_status(target, &"gods_message", 3)
	await fx.play_gods_message(unit, target, not blocked)
	if not battle.is_inside_tree():
		return
	if blocked:
		_log("%s speaks God's Message to %s: blocked by Haganah." % [unit.display_name, target.display_name])
		_event("Haganah protects %s from God's Message." % battle.short_name(target))
	else:
		_log("%s speaks God's Message (IMMEDIATE) to %s: next turn it loses %d stages of a random stat." % [
			unit.display_name, target.display_name, PrayerBook.GODS_MESSAGE_STAGES])
		_event("God's Message is inscribed on %s." % battle.short_name(target))
	if reacting:
		unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)


## Start of `unit`'s turn: a pending God's Message is fulfilled (3 stages = 3 x 25% off a random stat, until round end).
func fulfil_gods_message(unit: BattleUnit) -> bool:
	if unit == null or not unit.is_alive() or not unit.has_status(&"gods_message"):
		return false
	unit.remove_status(&"gods_message")
	var stats_pool: Array[String] = ["atk", "defense", "mak", "mef", "agi"]
	var stat_key: String = stats_pool[battle.rng.randi_range(0, stats_pool.size() - 1)]
	var current := int(unit.stats.get(stat_key))
	var loss := mini(int(round(float(current) * SkillBook.ATK_STAGE_BONUS * float(PrayerBook.GODS_MESSAGE_STAGES))), maxi(0, current - 1))
	unit.add_status(&"gm_debuff", 1, {"stat": stat_key, "delta": -loss})
	fx.play_gods_message_fulfilled(unit, String(STAT_NAMES[stat_key]))
	_log("God's Message is fulfilled: %s loses %d stages of %s (-%d)." % [
		unit.display_name, PrayerBook.GODS_MESSAGE_STAGES, STAT_NAMES[stat_key], loss])
	_event("God's Message: %s loses %d stages of %s." % [battle.short_name(unit), PrayerBook.GODS_MESSAGE_STAGES, STAT_NAMES[stat_key]])
	battle._refresh_all()
	return true


## Haganah lasts one full round: it ends when, in a later round, the turn of the unit that
## owned the turn at cast time comes back; `owner == null` = end of that later round.
## D-118: also triggers any pending Shachar dawn at the start of the next round.
func expire(owner: BattleUnit) -> void:
	resolve_pending_shachar()
	if owner != null:
		fulfil_gods_message(owner)
	for unit in battle.state.units:
		var h: Dictionary = unit.haganah
		if h.is_empty() or int(h.round) >= battle.state.round_number:
			continue
		if owner == null or StringName(h.owner) == owner.id:
			var is_aegis := bool(h.get("non_prayer", false))
			unit.haganah = {}
			if is_aegis:
				_log("%s: Aegis Iris ended." % unit.display_name)
				_event("%s  AEGIS END" % battle.short_name(unit))
			else:
				_log("%s: Haganah ended." % unit.display_name)
				_event("%s  HAGANAH END" % battle.short_name(unit))


## D-118 Shachar: detonates every pending dawn from an earlier round across all living foes.
func resolve_pending_shachar() -> int:
	if _pending_shachar.is_empty():
		return 0
	var total_dealt := 0
	var remaining: Array[Dictionary] = []
	for entry in _pending_shachar:
		if int(entry.round) >= battle.state.round_number:
			remaining.append(entry)
			continue
		var caster: BattleUnit = entry.caster
		var caster_mak := int(entry.get("caster_mak", caster.stats.mak if caster != null else 0))
		var foes: Array[BattleUnit] = []
		for foe in battle.hud.opponents.duplicate():
			if (foe as BattleUnit).is_alive():
				foes.append(foe)
		if foes.is_empty():
			continue
		fx.play_shachar_dawn()
		_log("Shachar dawn strikes all foes (30 + %d MAK - MEF)!" % caster_mak)
		_event("Shachar radiates across all foes!")
		for foe in foes:
			var dmg := PrayerBook.shachar_damage(caster_mak, foe.stats.mef)
			var applied := foe.take_damage(dmg)
			total_dealt += applied
			if caster != null:
				caster.last_damage_dealt = applied
			battle.fx.play("RAAM", foe, applied, caster)
			if not foe.is_alive():
				_event("%s is down." % battle.short_name(foe))
		battle._refresh_all()
	_pending_shachar = remaining
	fx.shachar_pending = not _pending_shachar.is_empty()
	return total_dealt


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
