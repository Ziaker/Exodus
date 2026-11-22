extends "res://scripts/battle/battle_controller.gd"
## Live presentation adapter. Combat formulas, AI and rewards remain in the existing controller.

signal target_selected
signal reaction_answered
signal continue_requested

const HUD_SCRIPT = preload("res://scripts/battle/playable_hud.gd")
const COMPACT_RHYTHM = preload("res://scripts/battle/compact_rhythm_bar.gd")
const EFFECTS_SCRIPT = preload("res://scripts/battle/battle_effects.gd")
const COUNTER_RHYTHM = preload("res://scripts/battle/counter_rhythm_bar.gd")
var hud: Control
var fx: Control
## D-049: two-rail counter-attack exchange and its interruption bookkeeping.
var counter: Control
var last_counter: Dictionary = {}
var _counter_resolved := false
var _enemy_interrupted := false
var _player_interrupted := false
var _interrupt_gainer: BattleUnit = null
var active_actor: BattleUnit
var _selected_target := -1
var _reaction_decision := false
var waiting_players: Dictionary = {}
var in_reaction := false
## D-022: set when the player actually executes any reaction command to an
## announced enemy attack; without it the enemy attack is an automatic hit.
var reaction_declared := false
## Survives reload_current_scene(): the next battle starts at base attributes.
## Kept as Engine metadata, not a static var: a static var on this script made
## Godot 4.7.2 crash at shutdown whenever a subclass of it had been loaded.
const RESTART_AT_BASE_META := &"exodus_restart_at_base"
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
	counter = COUNTER_RHYTHM.new()
	counter.name = "CounterRhythm"
	add_child(counter)
	counter.z_index = 2
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
	# HTML renderMenu: keep the cursor on the same command name, else the first row.
	var previous: String = hud.command_options[hud.command_index] if hud.command_index >= 0 and hud.command_index < hud.command_options.size() else ""
	hud.command_options = options
	hud.command_index = maxi(0, options.find(previous))
	hud.mode = "command"
	phase_text = "REACTION COMMAND" if in_reaction else "PLAYER COMMAND"
	hud.feedback = "Z: confirm | X: back"
	_chosen = -1
	_refresh_all()
	await command_chosen
	hud.mode = "busy"
	return _chosen


func submit_command(index: int) -> void:
	# No modo de planejamento, manter a API "execute já" permite que drivers e
	# testes continuem usando submit_command(); a interface usa submit_plan().
	if hud.mode == "plan":
		submit_plan(index)
		if hud.mode == "plan":
			exec_plan()
		return
	if hud.mode != "command" or index < 0 or index >= hud.command_options.size():
		return
	_chosen = index
	hud.command_index = index
	hud.press_command(index, "confirm")
	command_chosen.emit()


## D-046: um comando escolhido no plano é comprometido, não executado na hora.
func submit_plan(index: int) -> void:
	if hud.mode != "plan" or index < 0 or index >= _plan_options.size():
		return
	_chosen = index
	hud.plan_index = index
	hud.press_command(index, "confirm")
	command_chosen.emit()


## D-046: EXEC encerra o planejamento e começa a resolução do bloco.
func exec_plan() -> void:
	if hud.mode != "plan" or _planned.is_empty():
		return
	_chosen = _plan_options.size() - 2
	command_chosen.emit()


## D-046: UNDO retira o último comando comprometido, sem gastar ato.
func undo_plan() -> void:
	if hud.mode != "plan":
		return
	_chosen = _plan_options.size() - 1
	command_chosen.emit()


## Usado pelo HUD para acender os marcadores verde dos atos comprometidos.
func planned_acts_for(unit: BattleUnit) -> int:
	if unit == null or unit != active_actor:
		return 0
	return _planned.size()


func _wait_plan_command(options: Array[String]) -> int:
	_plan_options = options.duplicate()
	_plan_options.append("EXEC")
	_plan_options.append("UNDO")
	hud.mode = "plan"
	hud.plan_index = 0
	hud.plan_options = _plan_options
	hud.command_options = _plan_options
	hud.feedback = "Z: add command | X: EXEC | Backspace: UNDO"
	_chosen = -99
	_refresh_all()
	await command_chosen
	hud.mode = "busy"
	if _chosen == options.size():
		return -2
	if _chosen == options.size() + 1:
		return -3
	return _chosen


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
		if state.round_number > 1: hud.announce("ROUND %02d" % state.round_number)
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
		# D-047: REACT reserves acts without spending them; release the scheduler
		# so the enemy still gets its turn instead of skipping to the next round.
		state.skip_active_actor()
	return null


func _commands(unit: BattleUnit, reacting: bool = false) -> Array[String]:
	var options: Array[String] = ["ATTACK", "ITEM", "REST"]
	if unit.is_fallen: options.append("ABSORB")
	if reacting:
		# D-045: only the attacked character may block (DEFEND) or use any command;
		# another reactor may only counter-attack or use an item.
		if unit != reaction_defender:
			var limited: Array[String] = ["ATTACK", "ITEM"]
			return limited
		options.append("DEFEND")
	else:
		options.append("REACT")
	return options


func _execute_command(unit: BattleUnit, command: String, reacting: bool = false, chain: bool = false) -> bool:
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
	# D-038: REST never spends an act — it ends participation and stores the
	# remaining ones. Handle it before the shared spend_act() gate below.
	if command == "REST":
		return _execute_rest(unit, reacting)
	if not unit.spend_act(): return false
	action_attacker = unit
	action_defender = defender if defender != null else unit
	phase_text = "REACTION " + command if reacting else command
	_refresh_all()
	match command:
		"ATTACK": await _perform_attack(unit, defender, 100, reacting, false, false, chain)
		"ITEM":
			var recipient: BattleUnit = defender if defender != null else unit
			var healed := recipient.heal(6)
			fx.play("HEAL", recipient, healed)
			if unit.is_fallen: unit.add_sp(-2)
			_append_log("%s uses item on %s: +%d HP%s." % [unit.display_name, recipient.display_name, healed, " (-2 SP)" if unit.is_fallen else ""])
			if reacting: unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
		"ABSORB":
			var was_absorbed := defender.absorbed
			await _perform_absorption(unit, defender)
			if reacting and not was_absorbed and defender.absorbed:
				unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
		"DEFEND":
			unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
			_append_log("%s reacts with DEFEND (1 act spent)." % unit.display_name)
	if command == "ITEM":
		hud.feedback = "%s: HP %d/%d | 1 ACT spent" % [action_defender.display_name, action_defender.current_hp, action_defender.stats.max_hp]
	_refresh_all()
	return true


## D-038: REST consome zero ACT, encerra a participação na rodada, guarda os
## atos restantes (teto D-005) e recupera exatamente 2 EN — a mesma regra do
## controlador base e da interface jogável.
func _execute_rest(unit: BattleUnit, reacting: bool) -> bool:
	var remaining: int = unit.acts_available
	unit.store_acts(remaining)
	unit.acts_available = 0
	var before: int = unit.current_en
	unit.recover_en_flat(BattleMath.REST_EN_RECOVERY)
	action_attacker = unit
	action_defender = unit
	phase_text = "REST"
	fx.play("REST", unit, unit.current_en - before)
	_append_log("%s %s: +%d EN, %d act(s) stored; round participation ended." % [
		unit.display_name, "reacts with REST" if reacting else "rests",
		BattleMath.REST_EN_RECOVERY, remaining])
	if reacting: unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	hud.feedback = "%s: EN %d/%d | 0 ACT spent, %d stored" % [
		unit.display_name, unit.current_en, unit.stats.max_en, remaining]
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
	# D-046: o jogador compromete até quatro atos antes da resolução. Os marcadores
	# verdes permanecem acesos até o bloco inteiro ser resolvido. Um alvo cancelado
	# devolve ao planejamento sem gastar o ato daquele comando.
	while unit.is_alive() and not state.is_over() and unit.acts_available > 0:
		var max_acts := mini(BattleMath.MAX_AVAILABLE_ACTS, unit.acts_available)
		_planned.clear()
		while _planned.size() < max_acts:
			var choice := await _wait_plan_command(options)
			if choice == -2:  # EXEC
				break
			if choice == -3:  # UNDO
				if not _planned.is_empty():
					_planned.remove_at(_planned.size() - 1)
				continue
			if choice < 0:
				break
			_planned.append(choice)
			var chosen: String = options[choice]
			# REST (D-038) encerra a participação; REACT reserva os atos restantes.
			if chosen in ["REST", "REACT"]:
				break
		if _planned.is_empty():
			_planned.clear()
			return
		if options[_planned.back()] == "REACT":
			waiting_players[unit.id] = true
			_append_log("%s reserves %d acts for enemy announcements." % [unit.display_name, unit.acts_available])
			_planned.clear()
			return
		var cancelled := false
		var chain_used := false
		for i in _planned.size():
			if not unit.is_alive() or state.is_over():
				break
			var command: String = options[_planned[i]]
			var chain := false
			if command == "ATTACK":
				for j in range(i + 1, _planned.size()):
					if options[_planned[j]] == "ATTACK":
						chain = true
						break
			chain_used = chain_used or chain
			_player_interrupted = false
			_interrupt_gainer = null
			if not await _execute_command(unit, command, false, chain):
				cancelled = true
				break
			await _pause_result()
			if _player_interrupted:
				# D-049: an interrupted hero loses every following command of the plan,
				# with its act; the interrupter gains +1 act per lost command (D-005 cap).
				_lose_queue(unit, _planned.slice(i + 1).map(func(c: int) -> String: return options[c]), _interrupt_gainer)
				break
		_planned.clear()
		if chain_used:
			rhythm.stop_chain()
		if not cancelled:
			return


func _enemy_turn(unit: BattleUnit) -> void:
	active_actor = null
	# D-047 (decisão do criador): o inimigo resolve seus atos em bloco contínuo —
	# dois ataques anunciados, cada um com sua própria reação e seu próprio número
	# de dano na camada principal. A cadeia para se o combatente cair ou o duelo acabar.
	for _hit in 2:
		if not unit.is_alive() or state.is_over():
			break
		_counter_resolved = false
		_enemy_interrupted = false
		_interrupt_gainer = null
		if not unit.spend_act():
			break
		var defender := _player_with_most_sp()
		if defender == null:
			break
		action_attacker = unit
		action_defender = defender
		phase_text = "ENEMY ATTACK"
		# Creator decision 2026-11-21: no TARGET01 "SEARCH" cue; the attacker whitens and
		# shows a red "!" while the announcement is on screen.
		# Creator decision 2026-11-21: RPG Maker XP whiten on the attacker at the announcement.
		fx.play("WHITEN", unit)
		hud.feedback = ""
		_append_log("%s announces an attack on %s." % [unit.display_name, defender.display_name])
		hud.announce_attack("NO REACTION AVAILABLE" if eligible_reactors().is_empty() else "%s → %s" % [short_name(unit), short_name(defender)], unit)
		if eligible_reactors().is_empty():
			hud.mode = "announce"
			hud.feedback = "No reaction acts left. Z / Enter: resolve attack"
			await continue_requested
			hud.mode = "busy"
		reaction_declared = false
		var defense_paid := await _maybe_player_reaction(defender, unit)
		# A reaction can defeat the announced attacker before its action resolves.
		# D-049: a counter-attack exchange already resolved (or interrupted) this attack.
		if not _counter_resolved and unit.is_alive() and defender.is_alive():
			await _perform_attack(unit, defender, 100, false, defense_paid, not reaction_declared)
		await _pause_result()
		if _enemy_interrupted:
			var following: Array[String] = []
			for _rest in mini(1 - _hit, unit.acts_available):
				following.append("ATTACK")
			_lose_queue(unit, following, _interrupt_gainer)
			break


func _create_units() -> void:
	apply_saved_gains = not bool(Engine.get_meta(RESTART_AT_BASE_META, false))
	Engine.remove_meta(RESTART_AT_BASE_META)
	super._create_units()


func short_name(unit: BattleUnit) -> String:
	if unit == null: return ""
	var index: int = hud.opponents.find(unit)
	return "FOE " + char(65 + index) if index >= 0 else unit.display_name


func _perform_attack(attacker: BattleUnit, defender: BattleUnit, power: int, is_reaction: bool, defense_act_paid: bool = false, auto_hit: bool = false, chain: bool = false) -> void:
	action_attacker = attacker
	action_defender = defender
	phase_text = "ATTACK" if attacker.is_player else "ENEMY ATTACK"
	if is_reaction: phase_text = "REACTION ATTACK"
	hud.feedback = ""
	# D-049: an attacked enemy with a reaction act may counter-attack (33%).
	if attacker.is_player and not is_reaction and not defender.is_player and defender.is_alive() \
			and defender.acts_available > 0 and _enemy_counter_roll(defender):
		if chain: rhythm.stop_chain()
		await _enemy_counter(attacker, defender)
		return
	var hp_before := defender.current_hp
	await super._perform_attack(attacker, defender, power, is_reaction, defense_act_paid, auto_hit, chain)
	_present_strike(attacker, defender, hp_before - defender.current_hp)


func _present_strike(attacker: BattleUnit, defender: BattleUnit, damage: int) -> void:
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


func _attack_timing(attacker: BattleUnit, defender: BattleUnit, duration: float, auto_hit: bool = false, chain: bool = false) -> int:
	timing_role = "ATTACK"
	phase_text = "ATTACK" if attacker.is_player else "ENEMY ATTACK"
	attack_result = await super._attack_timing(attacker, defender, duration, auto_hit, chain)
	return attack_result


func _manual_rhythm(duration: float, point_half: float, chain: bool = false) -> int:
	hud.mode = "timing"
	if timing_role == "DEFEND":
		rhythm.place(hud.defense_rail_rect(hud.players.find(action_defender)), "defense")
	else:
		rhythm.place(hud.attack_rail_rect(hud.opponents.find(action_defender)), "attack")
	if timing_role == "DEFEND":
		rhythm._label.text = "DEFEND: %s vs %s | Z" % [short_name(action_defender), short_name(action_attacker)]
	else:
		rhythm._label.text = "ATTACK: %s -> %s | Z" % [short_name(action_attacker), short_name(action_defender)]
	hud.message = rhythm._label.text
	hud.feedback = "Z / Enter or click: stop marker in the center"
	rhythm.configure(point_half)
	if chain:
		rhythm.start_chain(duration)
	else:
		rhythm.start(duration)
	var result: int = await _wait_rhythm()
	hud.feedback = timing_role + ": " + _rhythm_name(result)
	hud.mode = "busy"
	return result


# ------------------------------------------------- D-049 counter-attack exchange

## Overridable by tests: does an attacked enemy counter-attack instead of defending?
func _enemy_counter_roll(_enemy: BattleUnit) -> bool:
	return rng.randf() < BattleMath.ENEMY_COUNTER_CHANCE


## Overridable by tests: the random moment the enemy AI presses on its red rail.
func _counter_ai_time(red_seconds: float) -> float:
	return rng.randf_range(0.0, red_seconds)


func _counter_exchange(hero: BattleUnit, enemy: BattleUnit, kind: String) -> Dictionary:
	var index: int = hud.players.find(hero) if kind == "panel" else hud.opponents.find(enemy)
	var rails: Array[Rect2] = hud.counter_rail_rects(kind, index)
	var white_half := BattleMath.point_half_width(hero.stats.agi, enemy.stats.agi, hero.current_sp, enemy.current_sp)
	var red_half := BattleMath.point_half_width(enemy.stats.agi, hero.stats.agi, enemy.current_sp, hero.current_sp)
	var red_seconds := BattleMath.counter_red_duration(BattleMath.RHYTHM_FIXED_SECONDS, enemy.stats.agi, hero.stats.agi)
	timing_role = "COUNTER"
	hud.mode = "counter"
	hud.message = "COUNTER: %s x %s | Z" % [short_name(hero), short_name(enemy)]
	hud.feedback = "Z / Enter or click: stop the white pointer"
	counter.start(kind, rails[0], rails[1], BattleMath.RHYTHM_FIXED_SECONDS, red_seconds, white_half, red_half, _counter_ai_time(red_seconds))
	_refresh_all()
	var raw: Dictionary = await counter.finished
	hud.mode = "busy"
	var outcome := BattleMath.resolve_counter(raw.player, raw.enemy, raw.player_perfect, raw.enemy_perfect)
	last_counter = outcome.duplicate()
	last_counter.merge(raw)
	last_counter["hero"] = hero
	last_counter["enemy"] = enemy
	return outcome


## The hero counter-attacks an announced enemy attack (bars in the hero's panel).
func _execute_counter(reactor: BattleUnit, enemy: BattleUnit, target: BattleUnit) -> bool:
	if not enemy.is_alive() or not reactor.spend_act():
		return false
	action_attacker = reactor
	action_defender = enemy
	phase_text = "COUNTER"
	_append_log("%s counter-attacks %s (1 act spent)." % [reactor.display_name, enemy.display_name])
	var o := await _counter_exchange(reactor, enemy, "panel")
	_counter_resolved = true
	match int(o.winner):
		BattleMath.CounterWinner.PLAYER:
			_strike(reactor, enemy, o.player_timing, true)
			_interrupt(reactor, enemy, o)
			_enemy_interrupted = true
			_interrupt_gainer = reactor
		BattleMath.CounterWinner.ENEMY:
			# Creator 2026-11-22: a losing counter-attacker takes the hit in the target's place.
			_strike(enemy, reactor, o.enemy_timing, false)
			_interrupt(enemy, reactor, o)
		_:
			_strike(reactor, enemy, o.player_timing, true)
			_strike(enemy, target, o.enemy_timing, false)
			_enemy_interrupted = true
			_interrupt_gainer = null
			_tie_report(reactor, enemy)
	return true


## An attacked enemy counter-attacks the hero's own attack (bars over the enemy).
func _enemy_counter(hero: BattleUnit, enemy: BattleUnit) -> void:
	enemy.spend_act()
	action_attacker = hero
	action_defender = enemy
	phase_text = "ENEMY COUNTER"
	_append_log("%s counter-attacks %s (1 act spent)." % [enemy.display_name, hero.display_name])
	var o := await _counter_exchange(hero, enemy, "enemy")
	match int(o.winner):
		BattleMath.CounterWinner.PLAYER:
			_strike(hero, enemy, o.player_timing, false)
			_interrupt(hero, enemy, o)
		BattleMath.CounterWinner.ENEMY:
			_strike(enemy, hero, o.enemy_timing, true)
			_interrupt(enemy, hero, o)
			_player_interrupted = true
			_interrupt_gainer = enemy
		_:
			_strike(hero, enemy, o.player_timing, false)
			_strike(enemy, hero, o.enemy_timing, true)
			_player_interrupted = true
			_interrupt_gainer = null
			_tie_report(hero, enemy)


## One strike of the exchange with its known timing (no defense rail).
func _strike(attacker: BattleUnit, defender: BattleUnit, timing: int, is_reaction: bool) -> void:
	if not defender.is_alive():
		return
	action_attacker = attacker
	action_defender = defender
	attack_result = timing
	defense_result = BattleMath.RhythmResult.MISS
	var hp_before := defender.current_hp
	_apply_strike(attacker, defender, 100, is_reaction, timing, BattleMath.RhythmResult.MISS)
	_present_strike(attacker, defender, hp_before - defender.current_hp)


## The winner steals SP; a perfect interruption also flashes the stage and shakes the loser.
func _interrupt(winner: BattleUnit, loser: BattleUnit, o: Dictionary) -> void:
	var stolen := mini(int(o.steal), loser.current_sp)
	loser.add_sp(-stolen)
	winner.add_sp(stolen)
	if bool(o.perfect):
		hud.impact_flash()
		hud.shake(loser)
	var kind := "PERFECT INTERRUPTION" if bool(o.perfect) else "INTERRUPTION"
	_append_log("%s: %s interrupts %s (+%d SP stolen)." % [kind, winner.display_name, loser.display_name, stolen])
	hud.message = "%s: %s interrupts %s | +%d SP" % [kind, short_name(winner), short_name(loser), stolen]


func _tie_report(hero: BattleUnit, enemy: BattleUnit) -> void:
	_append_log("COUNTER TIE: %s and %s interrupt each other (no SP)." % [hero.display_name, enemy.display_name])
	hud.message = "COUNTER TIE: %s and %s interrupt each other" % [short_name(hero), short_name(enemy)]


## D-049: the interrupted side loses the following commands of its queue with their
## acts; a winning interrupter gains +1 act per lost command (D-005 cap, rest stored).
func _lose_queue(unit: BattleUnit, commands: Array, gainer: BattleUnit) -> void:
	if commands.is_empty():
		return
	var acts := 0
	for command in commands:
		if String(command) not in ["REST", "REACT"]:
			acts += 1
	unit.acts_available = maxi(0, unit.acts_available - acts)
	if gainer != null and gainer.is_alive():
		gainer.grant_acts(commands.size())
	_append_log("%s loses %d queued command(s)%s." % [unit.display_name, commands.size(),
		"; %s gains %d act(s)" % [gainer.display_name, commands.size()] if gainer != null and gainer.is_alive() else ""])
	_refresh_all()


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
		hud.react_index = 0
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
			if command == "ATTACK":
				# D-049: a counter-attack always aims at the announcing enemy and
				# resolves both strikes on the two-rail exchange.
				if await _execute_counter(reaction_actor, attacker, defender):
					in_reaction = false
					reaction_declared = true
					return false
				continue
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
	hud.announce("ABSORB")
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
	hud.announce(phase_text)
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
		"plan": submit_plan(hud.plan_index)
		"target": submit_target(hud.target)
		"timing":
			if rhythm._running:
				rhythm._finish(BattleMath.rhythm_zone(rhythm._elapsed / rhythm.duration, rhythm._point_half_width))
		"counter": counter.press_player()
		"react": answer_reaction(hud.react_index == 0)
		"absorb":
			if _mash_active:
				_mash_count += 1
		"continue", "announce": proceed()
		"result":
			Engine.set_meta(RESTART_AT_BASE_META, not state.player_victory())
			get_tree().reload_current_scene()


func handle_back() -> void:
	match hud.mode:
		"target":
			hud.press_command(hud.command_index, "reject")
			cancel_target()
		"react": answer_reaction(false)
		"plan": undo_plan()
		"command":
			if in_reaction: cancel_reaction_command()
			else:
				hud.mode = "turn"
				hud.feedback = "Command menu closed. Z / Enter: reopen. No act spent."
		"continue":
			if not fx.is_busy(): proceed()
		"timing", "absorb", "counter": hud.feedback = "Action committed. Z / Enter: finish input."
		"announce": hud.feedback = "No acts to react. Z / Enter: resolve enemy attack."
		"result": hud.feedback = "Battle finished. Z / Enter: play again."
		"turn": hud.feedback = "Z / Enter: choose command."
	hud.queue_redraw()
