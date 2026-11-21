extends "res://scripts/battle/battle_controller.gd"
## Live presentation adapter. Combat formulas, AI and rewards remain in the existing controller.

signal target_selected
signal reaction_answered
signal continue_requested

const HUD_SCRIPT = preload("res://scripts/battle/playable_hud.gd")
const COMPACT_RHYTHM = preload("res://scripts/battle/compact_rhythm_bar.gd")
const EFFECTS_SCRIPT = preload("res://scripts/battle/battle_effects.gd")
var hud: Control
var fx: Control
var active_actor: BattleUnit
var _selected_target := -1
var _reaction_decision := false
var waiting_players: Dictionary = {}
var in_reaction := false
## D-022: set when the player actually executes any reaction command to an
## announced enemy attack; without it the enemy attack is an automatic hit.
var reaction_declared := false
## Survives reload_current_scene(): the next battle starts at base attributes.
static var _restart_at_base := false
var reaction_attacker: BattleUnit
var reaction_defender: BattleUnit
var reaction_actor: BattleUnit
var target_side := "enemy"
var action_attacker: BattleUnit
var action_defender: BattleUnit
var phase_text := "PLAYER COMMAND"
var timing_role := "ATTACK"
var attack_result := BattleMath.RhythmResult.MISS
var defense_result := BattleMath.RhythmResult.MISS


func _build_ui() -> void:
	hud = HUD_SCRIPT.new()
	hud.battle = self
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hud)
	rhythm = COMPACT_RHYTHM.new()
	add_child(rhythm)
	# Its own black-space slot keeps the log, menu and both status rows visible.
	rhythm.z_index = 2
	fx = EFFECTS_SCRIPT.new()
	fx.name = "BattleEffects"
	fx.battle = self
	add_child(fx)


func _refresh_all() -> void:
	if state.units.size() < 4:
		return
	hud.players.assign([_fallen, _ally])
	hud.opponents.assign([state.units[2], state.units[3]])
	hud.actor = 0 if active_actor == null or active_actor == _fallen else 1
	hud.queue_redraw()


func _append_log(text: String) -> void:
	log_history.append(text)
	# Keep complete diagnostics in history, readable action/outcome text in the black strip.
	hud.message = text.get_slice(" (", 0)
	if text.contains("dmg") and not text.contains("NO CONTACT"):
		if text.contains("affinity RESIST") or text.contains("affinity NULL") or text.contains("affinity ABSORB"):
			hud.message += " | RESIST/NULL/ABSORB: -1 ACT"
		elif text.contains("affinity WEAK"):
			hud.message += " | WEAK: +1 ACT"
	_refresh_all()


func _flash_feedback(text: String) -> void:
	hud.feedback = text
	hud.queue_redraw()


func _input(_event: InputEvent) -> void:
	# One input owner: the HUD forwards events, avoiding double mash/rhythm presses.
	pass


func _wait_command(options: Array[String]) -> int:
	hud.command_options = options
	hud.command_index = clampi(hud.command_index, 0, options.size() - 1)
	hud.mode = "command"
	phase_text = "REACTION COMMAND" if in_reaction else "PLAYER COMMAND"
	hud.feedback = "Z: confirm | X: back"
	_chosen = -1
	_refresh_all()
	await command_chosen
	hud.mode = "busy"
	return _chosen


func submit_command(index: int) -> void:
	if hud.mode != "command" or index < 0 or index >= hud.command_options.size():
		return
	_chosen = index
	command_chosen.emit()


func target_units() -> Array[BattleUnit]:
	return hud.players if target_side == "player" else hud.opponents


func first_living_target() -> int:
	var units := target_units()
	for i in units.size():
		if units[i].is_alive():
			return i
	return -1


func _wait_target(side: String = "enemy") -> BattleUnit:
	target_side = side
	hud.target = first_living_target()
	if hud.target < 0:
		return null
	hud.mode = "target"
	hud.message = "Choose %s: Left / Right or click. Z: confirm. X: back." % ("ally" if target_side == "player" else "enemy")
	_selected_target = -1
	await target_selected
	hud.mode = "busy"
	return target_units()[_selected_target] if _selected_target >= 0 else null


func submit_target(index: int) -> void:
	if hud.mode != "target" or index < 0 or index >= target_units().size():
		return
	if not target_units()[index].is_alive():
		return
	_selected_target = index
	hud.target = index
	target_selected.emit()


func cancel_target() -> void:
	if hud.mode == "target":
		_selected_target = -1
		target_selected.emit()


func run_battle() -> void:
	_append_log("Battle start.")
	while not state.is_over():
		waiting_players.clear()
		state.start_round()
		_refresh_all()
		var unit := _next_live_actor()
		while unit != null:
			if unit.is_player:
				await _player_turn(unit)
			else:
				await _enemy_turn(unit)
			_refresh_all()
			if state.is_over(): break
			unit = _next_live_actor()
		if state.is_over(): break
		state.end_round()
		_append_log("End of round %d: +20%% EN." % state.round_number)
	_show_result()


func _next_live_actor() -> BattleUnit:
	# Reserving acts changes presentation scheduling, not the shared resource pool.
	for i in state.turn_order.size():
		var unit := state.next_actor()
		if unit == null: return null
		if not waiting_players.has(unit.id): return unit
	return null


func _commands(unit: BattleUnit, reacting: bool = false) -> Array[String]:
	var options: Array[String] = ["ATTACK", "ITEM", "REST"]
	if unit.is_fallen: options.append("ABSORB")
	if reacting:
		if unit == reaction_defender: options.append("DEFEND")
	else:
		options.append("REACT")
	return options


func _execute_command(unit: BattleUnit, command: String, reacting: bool = false) -> bool:
	phase_text = "SELECT " + command + " TARGET"
	action_attacker = unit
	action_defender = null
	attack_result = BattleMath.RhythmResult.MISS
	defense_result = BattleMath.RhythmResult.MISS
	var defender: BattleUnit = null
	if command in ["ATTACK", "ABSORB"]:
		defender = await _wait_target()
		if defender == null: return false
	elif command == "ITEM" and reacting:
		defender = await _wait_target("player")
		if defender == null: return false
	if not unit.spend_act(): return false
	action_attacker = unit
	action_defender = defender if defender != null else unit
	phase_text = "REACTION " + command if reacting else command
	_refresh_all()
	match command:
		"ATTACK": await _perform_attack(unit, defender, 100, reacting)
		"ITEM":
			var recipient: BattleUnit = defender if defender != null else unit
			var healed := recipient.heal(6)
			fx.play("HEAL", recipient, healed)
			if unit.is_fallen: unit.add_sp(-2)
			_append_log("%s uses item on %s: +%d HP%s." % [unit.display_name, recipient.display_name, healed, " (-2 SP)" if unit.is_fallen else ""])
			if reacting: unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
		"REST":
			var before := unit.current_en
			unit.recover_en(0.2)
			fx.play("REST", unit, unit.current_en - before)
			_append_log("%s %s: +20%% EN (1 act spent)." % [unit.display_name, "reacts with REST" if reacting else "rests"])
			if reacting: unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
		"ABSORB":
			var was_absorbed := defender.absorbed
			await _perform_absorption(unit, defender)
			if reacting and not was_absorbed and defender.absorbed:
				unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
		"DEFEND":
			unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
			_append_log("%s reacts with DEFEND (1 act spent)." % unit.display_name)
	if command != "ATTACK":
		if command == "REST": hud.feedback = "%s: EN %d/%d | 1 ACT spent" % [unit.display_name, unit.current_en, unit.stats.max_en]
		elif command == "ITEM": hud.feedback = "%s: HP %d/%d | 1 ACT spent" % [action_defender.display_name, action_defender.current_hp, action_defender.stats.max_hp]
	_refresh_all()
	return true


func _player_turn(unit: BattleUnit) -> void:
	active_actor = unit
	action_attacker = unit
	action_defender = null
	phase_text = "PLAYER COMMAND"
	hud.feedback = ""
	if unit.acts_available <= 0: return
	_append_log("%s: %d acts available." % [unit.display_name, unit.acts_available])
	var options := _commands(unit)
	while true:
		var choice := await _wait_command(options)
		var command := options[choice]
		if command == "REACT":
			waiting_players[unit.id] = true
			_append_log("%s reserves %d acts for enemy announcements." % [unit.display_name, unit.acts_available])
			return
		if await _execute_command(unit, command): break
	await _pause_result()


func _enemy_turn(unit: BattleUnit) -> void:
	active_actor = null
	if not unit.spend_act(): return
	var defender := _player_with_most_sp()
	if defender == null: return
	action_attacker = unit
	action_defender = defender
	phase_text = "ENEMY ATTACK"
	fx.play("ANNOUNCE", unit)
	hud.feedback = ""
	_append_log("%s announces an attack on %s." % [unit.display_name, defender.display_name])
	if eligible_reactors().is_empty():
		hud.mode = "announce"
		hud.feedback = "No reaction acts left. Z / Enter: resolve attack"
		await continue_requested
		hud.mode = "busy"
	reaction_declared = false
	var defense_paid := await _maybe_player_reaction(defender, unit)
	# A reaction can defeat the announced attacker before its action resolves.
	if unit.is_alive() and defender.is_alive():
		await _perform_attack(unit, defender, 100, false, defense_paid, not reaction_declared)
	await _pause_result()


func _create_units() -> void:
	apply_saved_gains = not _restart_at_base
	_restart_at_base = false
	super._create_units()


func short_name(unit: BattleUnit) -> String:
	if unit == null: return ""
	var index: int = hud.opponents.find(unit)
	return "FOE " + char(65 + index) if index >= 0 else unit.display_name


func _perform_attack(attacker: BattleUnit, defender: BattleUnit, power: int, is_reaction: bool, defense_act_paid: bool = false, auto_hit: bool = false) -> void:
	action_attacker = attacker
	action_defender = defender
	phase_text = "ATTACK" if attacker.is_player else "ENEMY ATTACK"
	if is_reaction: phase_text = "REACTION ATTACK"
	hud.feedback = ""
	var hp_before := defender.current_hp
	await super._perform_attack(attacker, defender, power, is_reaction, defense_act_paid, auto_hit)
	var damage := hp_before - defender.current_hp
	var outcome := "HIT"
	if defense_result == BattleMath.RhythmResult.POINT: outcome = "DODGE"
	elif attack_result == BattleMath.RhythmResult.MISS: outcome = "MISS"
	elif attack_result == BattleMath.RhythmResult.BEAM or defense_result == BattleMath.RhythmResult.BEAM: outcome = "BLOCK"
	var source: String = log_history.back()
	if source.contains("crit YES"): outcome += " / CRITICAL"
	var penalty := ""
	if not source.contains("NO CONTACT"):
		if defender.affinity == BattleMath.Affinity.WEAK: penalty = " | WEAK +1 ACT"
		elif defender.affinity in [BattleMath.Affinity.RESIST, BattleMath.Affinity.NULL, BattleMath.Affinity.ABSORB]: penalty = " | RESIST -1 ACT"
	hud.message = "%s -> %s: %s, %d damage%s" % [short_name(attacker), short_name(defender), outcome, damage, penalty]
	hud.feedback = "%s | %s HP %d/%d%s | %s: %d ACTS left" % [outcome, short_name(defender), defender.current_hp, defender.stats.max_hp, " DOWN" if not defender.is_alive() else "", short_name(attacker), attacker.acts_available]
	phase_text = "RESULT: " + outcome
	fx.stop_cues()
	fx.play("DODGE" if outcome.begins_with("DODGE") else ("MISS" if outcome.begins_with("MISS") else ("BLOCK" if outcome.begins_with("BLOCK") else ("CRITICAL" if outcome.contains("CRITICAL") else "HIT"))), defender, damage, attacker)
	_refresh_all()


func _attack_timing(attacker: BattleUnit, defender: BattleUnit, duration: float, auto_hit: bool = false) -> int:
	timing_role = "ATTACK"
	phase_text = "ATTACK" if attacker.is_player else "ENEMY ATTACK"
	if attacker.is_player: fx.play("ATTACK", attacker)
	attack_result = await super._attack_timing(attacker, defender, duration, auto_hit)
	return attack_result


func _manual_rhythm(duration: float, point_half: float) -> int:
	hud.mode = "timing"
	if timing_role == "DEFEND":
		rhythm._label.text = "DEFEND: %s vs %s | Z" % [short_name(action_defender), short_name(action_attacker)]
	else:
		rhythm._label.text = "ATTACK: %s -> %s | Z" % [short_name(action_attacker), short_name(action_defender)]
	hud.message = rhythm._label.text
	hud.feedback = "Z / Enter or click: stop marker in the center"
	var result: int = await super._manual_rhythm(duration, point_half)
	hud.feedback = timing_role + ": " + _rhythm_name(result)
	hud.mode = "busy"
	return result


func eligible_reactors() -> Array[BattleUnit]:
	var result: Array[BattleUnit] = []
	for unit in hud.players:
		if unit.is_alive() and unit.acts_available > 0: result.append(unit)
	return result


func select_reactor(index: int) -> void:
	if hud.mode != "react" or index < 0 or index >= hud.players.size(): return
	var unit: BattleUnit = hud.players[index]
	if not unit.is_alive() or unit.acts_available <= 0: return
	reaction_actor = unit
	active_actor = unit
	_refresh_all()


func _maybe_player_reaction(defender: BattleUnit, attacker: BattleUnit) -> bool:
	var candidates := eligible_reactors()
	if candidates.is_empty(): return false
	reaction_attacker = attacker
	reaction_defender = defender
	reaction_actor = defender if candidates.has(defender) else candidates[0]
	while true:
		active_actor = reaction_actor
		action_attacker = attacker
		action_defender = defender
		phase_text = "ENEMY ATTACK"
		_reaction_active = true
		hud.mode = "react"
		hud.message = "%s ATTACKS %s" % [short_name(attacker), short_name(defender)]
		hud.feedback = "Tab: choose reactor | Z: reaction commands | X: deny"
		_refresh_all()
		await reaction_answered
		_reaction_active = false
		if not _reaction_decision:
			hud.mode = "busy"
			return false
		in_reaction = true
		var options := _commands(reaction_actor, true)
		var back_to_prompt := false
		while true:
			var choice := await _wait_command(options)
			if choice < 0:
				in_reaction = false
				back_to_prompt = true
				break
			var command := options[choice]
			if await _execute_command(reaction_actor, command, true):
				in_reaction = false
				reaction_declared = true
				return command == "DEFEND"
		if back_to_prompt: continue
	return false


func cancel_reaction_command() -> void:
	if hud.mode == "command" and in_reaction:
		_chosen = -1
		command_chosen.emit()


func _defense_timing(defender: BattleUnit, attacker: BattleUnit, duration: float, act_paid: bool) -> int:
	if defender.is_player and act_paid:
		timing_role = "DEFEND"
		phase_text = "DEFENDING"
	var result: int = await super._defense_timing(defender, attacker, duration, act_paid)
	defense_result = result
	if defender.is_player and act_paid and result == BattleMath.RhythmResult.POINT:
		defender.add_sp(BattleMath.SP_GAIN_PER_EVENT)
		_refresh_all()
	return result


func answer_reaction(yes: bool) -> void:
	if hud.mode != "react":
		return
	_reaction_decision = yes
	reaction_answered.emit()


func _perform_absorption(unit: BattleUnit, defender: BattleUnit) -> void:
	hud.mode = "absorb"
	var was_absorbed := defender.absorbed
	fx.play("ABSORB", defender)
	await super._perform_absorption(unit, defender)
	if not was_absorbed and defender.absorbed: fx.play("ABSORBED", unit)
	hud.mode = "busy"


func _pause_result() -> void:
	hud.mode = "continue"
	_refresh_all()
	await continue_requested
	hud.mode = "busy"


func proceed() -> void:
	if hud.mode in ["continue", "announce"]:
		continue_requested.emit()


func _show_result() -> void:
	_append_log("VICTORY." if state.player_victory() else "DEFEAT.")
	phase_text = "VICTORY" if state.player_victory() else "DEFEAT"
	hud.feedback = "Battle finished. Z / Enter: play again. X: stay."
	hud.mode = "result"
	_refresh_all()


func handle_confirm() -> void:
	if hud.mode == "continue" and fx.is_busy(): return
	match hud.mode:
		"turn":
			hud.mode = "command"
			hud.feedback = "Z: confirm | X: back"
		"command": submit_command(hud.command_index)
		"target": submit_target(hud.target)
		"timing":
			if rhythm._running:
				rhythm._finish(BattleMath.rhythm_zone(rhythm._elapsed / rhythm.duration, rhythm._point_half_width))
		"react": answer_reaction(true)
		"absorb":
			if _mash_active:
				_mash_count += 1
		"continue", "announce": proceed()
		"result":
			_restart_at_base = not state.player_victory()
			get_tree().reload_current_scene()


func handle_back() -> void:
	match hud.mode:
		"target": cancel_target()
		"react": answer_reaction(false)
		"command":
			if in_reaction: cancel_reaction_command()
			else:
				hud.mode = "turn"
				hud.feedback = "Command menu closed. Z / Enter: reopen. No act spent."
		"continue":
			if not fx.is_busy(): proceed()
		"timing", "absorb": hud.feedback = "Action committed. Z / Enter: finish input."
		"announce": hud.feedback = "No acts to react. Z / Enter: resolve enemy attack."
		"result": hud.feedback = "Battle finished. Z / Enter: play again."
		"turn": hud.feedback = "Z / Enter: choose command."
	hud.queue_redraw()
