extends "res://scripts/battle/battle_controller.gd"
## Live presentation adapter. Combat formulas, AI and rewards remain in the existing controller.

signal target_selected
signal reaction_answered
signal continue_requested
signal skill_chosen
signal en_extra_chosen

const HUD_SCRIPT = preload("res://scripts/battle/playable_hud.gd")
const COMPACT_RHYTHM = preload("res://scripts/battle/compact_rhythm_bar.gd")
const EFFECTS_SCRIPT = preload("res://scripts/battle/battle_effects.gd")
const COUNTER_RHYTHM = preload("res://scripts/battle/counter_rhythm_bar.gd")
const PRAYER_FLOW = preload("res://scripts/battle/prayer_flow.gd")
const SKILL_LETTERS = preload("res://scripts/battle/skill_letters.gd")
var hud: Control
var fx: Control
const ABSORB_VFX = preload("res://scripts/battle/absorb_vfx.gd")
const STAGE_SHADER = preload("res://scenes/battle/battle_stage.gdshader")
const ENEMY_DEPTH := 0.85
## The HUD's SP green, also used by the D-052 mash letters.
const ABSORBED_INK := Color("81e6a8")
var stage: ColorRect
var absorb_fx: Node2D
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
## Creator 2026-11-23: Fallen's death plays this cutscene, halves the stat gains of
## absorptions and returns to the title screen (no save points exist yet).
const DEATH_CUTSCENE = preload("res://scripts/battle/death_cutscene.gd")
const DEATH_SCENE := "res://scenes/title/Title.tscn"
## Encontro no dungeon: o mapa grava a cena de volta antes de trocar de cena.
const DUNGEON_RETURN_META := &"exodus_dungeon_return_scene"
var death_cutscene: Node2D
var reaction_attacker: BattleUnit
var reaction_defender: BattleUnit
var reaction_actor: BattleUnit
## Creator 2026-11-24: REACT left the own-turn menu. Test drivers turn this on to reserve
## acts and reach an enemy announcement quickly (the old D-047 flow).
var offer_reserve := false
var target_side := "enemy"
var action_attacker: BattleUnit
var action_defender: BattleUnit
var phase_text := "PLAYER COMMAND"
var timing_role := "ATTACK"
var attack_result := BattleMath.RhythmResult.MISS
var defense_result := BattleMath.RhythmResult.MISS
## Creator 2026-11-23: the ATTACK command is now FIGHT; with learned skills it opens a
## submenu (ATTACK + skills, dimmed when HP/EN/acts are short), the battle log line
## explains the highlighted entry.
const FIGHT := "FIGHT"
const ATTACK_INFO := "ATTACK 1 ACT: normal physical attack."
## Gap between hits on different targets (Heat wave) so each impact reads.
const MULTI_HIT_GAP := 0.3
## Indicador visual: quantos atos já foram apontados para cada inimigo nesta rodada.
var queued_acts_by_foe: Dictionary = {}
var _indicator_round := -1
## D-057 (creator 2026-11-25): who does what in the action on screen, by unit id:
## "ATTACK", "TARGET", "DEFEND", "COUNTER" or "REACT". Set from the announcement (or the
## start of the hero's command) and cleared once the result is confirmed.
var roles: Dictionary = {}
## D-057: the target of each planned command, chosen while planning (null = none).
var _planned_targets: Array = []
## D-057: index of the planned command being executed (-1 = still planning).
var _exec_index := -1
## D-057: true while a queued ATTACK continues a chain on the same target.
var _chain_continues := false
## D-057: during a D-049 tie the falls are told after both blows (_release_down).
var _hold_down := false
var _pending_down: Array[BattleUnit] = []
## submit_command() keeps its "execute now" meaning for drivers and tests: when the
## command still needs its target, the plan runs as soon as that target is chosen.
var _auto_exec := false


func queued_acts_for(unit: BattleUnit) -> int:
	return int(queued_acts_by_foe.get(unit.id, 0))


var skill_ids: Array[StringName] = []
var skill_unit: BattleUnit
var skill_disabled: Array[int] = []
var skill_reasons: Dictionary = {}
var _skill_choice := -1
var en_extra := 0
var en_extra_max := 0
var _en_extra_ok := false
## Parallel to _planned: {} for a plain command, {"skill", "extra"} for a skill.
var _planned_skills: Array[Dictionary] = []
var _rhythm_marks: Array[float] = [0.5]
## Whose turn it is (ATK stage expiry: "the same point of the next round").
var turn_owner: BattleUnit
## Skill of the enemy announcement being reacted to (&"" = ATTACK).
var _announced_skill: StringName = &""
## D-048: Yoch's prayer (PRAY command, PP, Refuah / Haganah / Ra'am).
var prayer: RefCounted
## Hebrew-letter effects of Lunge, Heat wave, Bleedbuff and Energy Eat (creator 2026-11-23).
var letter_fx: Node2D
## Creator 2026-11-23: a Lunge hit shows the normal hit effect normal + mirrored (an X).
var cross_hit := false
## Creator 2026-11-23: the Lunge's second hit is part of the same effect: only its number.
var next_hit := false


func _build_ui() -> void:
	# Approved battle layout (creator 2026-11-22, prototype battle-bg; "always use the new
	# one" 2026-11-23): the stage is background D, an animated plasma sky shader painted
	# behind the HUD, and the enemies are 15% smaller with their feet on the same ground line.
	stage = ColorRect.new()
	stage.name = "Stage"
	# Creator 2026-11-24: the stage art drawn STAGE_SHIFT higher. The scene goes on behind
	# the HUD windows down to SCENE_BOTTOM (the bottom of the screen), the floor continuing.
	stage.position = Vector2(0, HUD_SCRIPT.STAGE_SHIFT)
	stage.size = Vector2(HUD_SCRIPT.SCREEN.x, HUD_SCRIPT.SCENE_BOTTOM - HUD_SCRIPT.STAGE_SHIFT)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stage_material := ShaderMaterial.new()
	stage_material.shader = STAGE_SHADER
	stage_material.set_shader_parameter("stage_size", stage.size)
	stage.material = stage_material
	add_child(stage)
	hud = HUD_SCRIPT.new()
	hud.battle = self
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hud)
	hud.stage_backdrop = false
	hud.enemy_horizon = hud.enemy_sprite_rect(0).end.y
	hud.enemy_depth = ENEMY_DEPTH
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
	absorb_fx = ABSORB_VFX.new()
	absorb_fx.name = "AbsorbVFX"
	absorb_fx.battle = self
	absorb_fx.hud = hud
	add_child(absorb_fx)
	prayer = PRAYER_FLOW.new(self)
	letter_fx = SKILL_LETTERS.new()
	letter_fx.name = "SkillLetters"
	letter_fx.battle = self
	letter_fx.hud = hud
	add_child(letter_fx)


func _refresh_all() -> void:
	if state.units.size() < 4:
		return
	if state.round_number != _indicator_round:
		_indicator_round = state.round_number
		queued_acts_by_foe.clear()
	hud.players.assign([_fallen, _ally])
	hud.opponents.assign([state.units[2], state.units[3]])
	hud.actor = 0 if active_actor == null or active_actor == _fallen else 1
	hud.queue_redraw()


## Complete diagnostics (rhythm, defense, crit, affinity, SP roll) for tests and debugging.
## D-057: it is no longer what the Battle Log shows; the player sees _event() lines.
func _append_log(text: String) -> void:
	log_history.append(text)
	_refresh_all()


## D-057 (creator 2026-11-25, "só frases de evento"): one plain event sentence in the
## Battle Log, no instructions and no internal numbers.
func _event(text: String, ink: Color = Color(0, 0, 0, 0)) -> void:
	hud.push_event(text, ink)
	_refresh_all()


func _set_role(unit: BattleUnit, role: String) -> void:
	if unit != null:
		roles[unit.id] = role
		# D-059: every new blow runs its arrow again from the attacker.
		if role == "ATTACK" and hud != null: hud.restart_arrows(unit.id)
		_refresh_all()


func _clear_roles() -> void:
	if not roles.is_empty():
		roles.clear()
		_refresh_all()


## D-057: before the battle waits for another input, event lines that do not fit the
## two-row log are paged with Z, so none scrolls away unread. What fits stays on screen.
func _flush_log() -> void:
	if not is_inside_tree():
		return
	while hud.log_hidden():
		var previous: String = hud.mode
		hud.mode = "continue"
		_refresh_all()
		await continue_requested
		hud.page_log()
		hud.mode = previous
	hud.page_log()
	_refresh_all()


func _flash_feedback(text: String) -> void:
	hud.feedback = text
	hud.queue_redraw()


func _input(_event: InputEvent) -> void:
	# One input owner: the HUD forwards events, avoiding double mash/rhythm presses.
	pass


func _wait_command(options: Array[String]) -> int:
	await _flush_log()
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
		elif hud.mode in ["target", "skill"]:
			# D-057: the command asks for its target first; the plan runs right after.
			_auto_exec = true
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
	# D-057: EXEC sent while the command being planned still picks its target (or skill)
	# runs the plan right after that choice (drivers and tests).
	if hud.mode in ["target", "skill"] and _exec_index < 0 and not in_reaction:
		_auto_exec = true
		return
	if hud.mode != "plan" or _planned.is_empty():
		return
	_chosen = _plan_options.size() - 2
	command_chosen.emit()


## D-046: UNDO retira o último comando comprometido, sem gastar ato.
func undo_plan() -> void:
	if hud.mode != "plan" or _planned.is_empty():
		return
	_chosen = _plan_options.size() - 1
	command_chosen.emit()


## Usado pelo HUD para acender os marcadores verde dos atos comprometidos.
## D-046 / D-057: during the execution only the commands not started yet stay green, so
## the green pips never outnumber the acts left ("ACT 1/4" with two green was a bug).
func planned_acts_for(unit: BattleUnit) -> int:
	if unit == null or unit != active_actor:
		return 0
	if _exec_index < 0:
		return _planned_cost()
	var total := 0
	for i in range(_exec_index + 1, _planned.size()):
		total += _entry_cost(_planned_skills[i] if i < _planned_skills.size() else {})
	return total


func _entry_cost(detail: Dictionary) -> int:
	if detail.is_empty() or not detail.has("skill"): return 1
	return int(SkillBook.def(StringName(detail.skill)).get("acts", 1))


func _planned_cost() -> int:
	var total := 0
	for i in _planned.size():
		total += _entry_cost(_planned_skills[i] if i < _planned_skills.size() else {})
	return total


func _planned_en() -> int:
	var total := 0
	for detail in _planned_skills:
		if detail.has("skill") and StringName(detail.skill) != &"":
			total += int(SkillBook.def(StringName(detail.skill)).en) + int(detail.get("extra", 0))
	return total


func _planned_hp() -> int:
	var total := 0
	for detail in _planned_skills:
		if detail.has("skill") and StringName(detail.skill) != &"":
			total += int(SkillBook.def(StringName(detail.skill)).hp)
	return total


func _wait_plan_command(options: Array[String]) -> int:
	await _flush_log()
	_plan_options = options.duplicate()
	# Creator 2026-11-24: EXEC and UNDO only show once something is queued.
	if not _planned.is_empty():
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
	await _flush_log()
	var same_side := target_side == side
	target_side = side
	# D-057: queuing several commands on one target keeps the cursor on the last target.
	var units := target_units()
	if not same_side or hud.target < 0 or hud.target >= units.size() or not units[hud.target].is_alive():
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
		if state.round_number > 1:
			hud.announce("ROUND %02d" % state.round_number)
			_event("ROUND %02d" % state.round_number)
		_refresh_all()
		await _burn_tick()
		if not is_inside_tree(): return
		if state.is_over(): break
		var unit := _next_live_actor()
		while unit != null:
			turn_owner = unit
			_expire_stages(unit)
			prayer.expire(unit)
			if unit.is_player:
				await _player_turn(unit)
			else:
				await _enemy_turn(unit)
			_refresh_all()
			if state.is_over(): break
			unit = _next_live_actor()
		# D-058: between rounds nobody owns the turn (the HUD turn strip shows no one).
		turn_owner = null
		if state.is_over(): break
		_expire_stages(null)
		prayer.expire(null)
		state.end_round()
		_append_log("End of round %d: +20%% EN." % state.round_number)
		_event("End of round %d: +20%% EN." % state.round_number)
	if state.fallen_fell():
		await _play_death()
	else:
		await _flush_log()
		if not is_inside_tree(): return
		_show_result()


## Creator 2026-11-23: Fallen died. The penalty is stored first (half of every stat gain,
## the odd half kept; counters and skills stay), then the cutscene plays over the battle
## and the game goes back to the title screen. A defeat also zeroes Yoch's PP (D-048).
func _play_death() -> void:
	prayer.battle_end(false)
	var before := ProgressStore.load_gains()
	var after := ProgressStore.halve_gains()
	ProgressStore.add_death()
	var losses := {}
	for stat in before.keys():
		losses[stat] = int(before[stat]) - int(after[stat])
	_append_log("DEFEAT.")
	_event("DEFEAT.")
	phase_text = "DEFEAT"
	hud.mode = "death"
	hud.feedback = ""
	_refresh_all()
	var layer := CanvasLayer.new()
	layer.name = "DeathLayer"
	layer.layer = 50
	add_child(layer)
	death_cutscene = DEATH_CUTSCENE.new()
	death_cutscene.name = "DeathCutscene"
	death_cutscene.losses = losses
	layer.add_child(death_cutscene)
	await death_cutscene.finished
	if is_inside_tree():
		_leave_after_death()


## Overridden by tests, which must not change the scene.
func _leave_after_death() -> void:
	get_tree().change_scene_to_file(DEATH_SCENE)


func _next_live_actor() -> BattleUnit:
	# Reserving acts changes presentation scheduling, not the shared resource pool.
	for i in state.turn_order.size():
		var unit := state.next_actor()
		if unit == null: return null
		# D-047: REACT reserves acts without spending them; skip that player's turns
		# so the enemy still gets its turn instead of skipping to the next round.
		if not waiting_players.has(unit.id): return unit
	return null


func _commands(unit: BattleUnit, reacting: bool = false) -> Array[String]:
	var options: Array[String] = [FIGHT, "ITEM", "REST"]
	if unit.is_fallen: options.append("ABSORB")
	if reacting:
		# D-045: only the attacked character may block (DEFEND) or use any command;
		# another reactor may only counter-attack or use an item.
		if unit != reaction_defender:
			var limited: Array[String] = [FIGHT, "ITEM"]
			return prayer.commands_for(unit, limited)
		options.append("DEFEND")
	else:
		# Creator 2026-11-24: REACT is only offered when an enemy action is announced (the
		# reaction prompt), not in the own-turn menu. Tests can still reserve acts.
		if offer_reserve: options.append("REACT")
	return prayer.commands_for(unit, options)


func _execute_command(unit: BattleUnit, command: String, reacting: bool = false, chain: bool = false, skill: Dictionary = {}, planned: BattleUnit = null) -> bool:
	if command == "PRAY":
		return await prayer.execute(unit, skill, reacting)
	if command == FIGHT and not skill.is_empty():
		return await _execute_skill(unit, skill, reacting, planned)
	phase_text = "SELECT " + command + " TARGET"
	action_attacker = unit
	action_defender = null
	attack_result = BattleMath.RhythmResult.MISS
	defense_result = BattleMath.RhythmResult.MISS
	var defender: BattleUnit = null
	if command in [FIGHT, "ABSORB"]:
		defender = await _planned_or_new_target(planned)
		if defender == null: return false
	elif command == "ITEM" and reacting:
		defender = await _wait_target("player")
		if defender == null: return false
	# D-038: REST never spends an act — it ends participation and stores the
	# remaining ones. Handle it before the shared spend_act() gate below.
	if command == "REST":
		return _execute_rest(unit, reacting)
	if not unit.spend_act():
		_event("%s has no act left." % short_name(unit))
		return false
	action_attacker = unit
	action_defender = defender if defender != null else unit
	phase_text = "REACTION " + command if reacting else command
	_refresh_all()
	match command:
		FIGHT:
			_clear_roles()
			_set_role(unit, "ATTACK")
			_set_role(defender, "TARGET")
			if not _chain_continues:
				_event("%s attacks %s." % [short_name(unit), short_name(defender)])
			await _perform_attack(unit, defender, basic_power, reacting, false, false, chain)
		"ITEM":
			var recipient: BattleUnit = defender if defender != null else unit
			if reacting: _set_role(unit, "REACT")
			var healed := recipient.heal(6)
			fx.play("HEAL", recipient, healed)
			if unit.is_fallen: unit.add_sp(-2)
			_append_log("%s uses item on %s: +%d HP%s." % [unit.display_name, recipient.display_name, healed, " (-2 SP)" if unit.is_fallen else ""])
			_event("%s uses an item on %s: +%d HP." % [short_name(unit), short_name(recipient), healed])
			if reacting: unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
		"ABSORB":
			_clear_roles()
			_event("%s tries to absorb %s." % [short_name(unit), short_name(defender)])
			var was_absorbed := defender.absorbed
			await _perform_absorption(unit, defender)
			if reacting and not was_absorbed and defender.absorbed:
				unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
		"DEFEND":
			unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
			_set_role(unit, "DEFEND")
			_append_log("%s reacts with DEFEND (1 act spent)." % unit.display_name)
			_event("%s defends." % short_name(unit))
	if command == "ITEM":
		hud.feedback = "%s: HP %d/%d | 1 ACT spent" % [action_defender.display_name, action_defender.current_hp, action_defender.stats.max_hp]
	_refresh_all()
	return true


## D-057 (creator 2026-11-25): the target was chosen when the command was planned and is
## used without asking. Only when it fell meanwhile does the game ask for another one;
## X declines and the command's act is not spent (it goes back to the hero).
func _planned_or_new_target(planned: BattleUnit, side: String = "enemy") -> BattleUnit:
	if planned != null and planned.is_alive():
		return planned
	if planned != null:
		# The fall and the rest of the result are read first; then the banner and the prompt.
		await _flush_log()
		_clear_roles()
		hud.announce("CHOOSE ANOTHER TARGET")
	return await _wait_target(side)


## D-038: REST consome zero ACT, encerra a participação na rodada, guarda os
## atos restantes (teto D-005) e recupera exatamente 2 EN — a mesma regra do
## controlador base e da interface jogável.
func _execute_rest(unit: BattleUnit, reacting: bool) -> bool:
	if unit.prays:
		return prayer.rest(unit, reacting)
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
	if reacting: _set_role(unit, "REACT")
	_event("%s rests: +%d EN, %d act(s) stored." % [short_name(unit), unit.current_en - before, remaining])
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
	_clear_roles()
	_event("%s's turn." % short_name(unit))
	var options := _commands(unit)
	# D-046: o jogador compromete até quatro atos antes da resolução; os marcadores verdes
	# mostram os comandos que ainda vão rodar.
	# D-057 (criador 2026-11-25): o alvo de cada comando é escolhido no plano e a fila roda
	# inteira, um comando depois do outro, sem perguntar nada; só se o alvo cair o jogo
	# pede outro alvo (X recusa e o ato não é gasto). Atos que sobram depois da fila (não
	# planejados, ganhos com WEAK +1 ou devolvidos) são planejados de novo no mesmo turno:
	# o turno só acaba com 0 atos ou com REST.
	while unit.is_alive() and not state.is_over() and unit.acts_available > 0:
		active_actor = unit
		var max_acts := mini(BattleMath.MAX_AVAILABLE_ACTS, unit.acts_available)
		_planned.clear()
		_planned_skills.clear()
		_planned_targets.clear()
		_exec_index = -1
		_auto_exec = false
		prayer.begin_plan(unit)
		while _planned_cost() < max_acts or prayer.can_continue(unit, _planned_skills):
			var choice := await _wait_plan_command(options)
			if choice == -2:  # EXEC
				break
			if choice == -3:  # UNDO
				if prayer.undo_allocation(unit, _planned_skills):
					continue
				if not _planned.is_empty():
					_mark_target(_planned_targets.back(), -1)
					_planned.remove_at(_planned.size() - 1)
					_planned_skills.remove_at(_planned_skills.size() - 1)
					_planned_targets.remove_at(_planned_targets.size() - 1)
					prayer.recharge(unit, _planned_skills)
				continue
			if choice < 0:
				break
			var chosen: String = options[choice]
			var detail: Dictionary = {}
			# D-048: with every act committed only +1 PP on a queued spell is left.
			if chosen != "PRAY" and _planned_cost() >= max_acts:
				_auto_exec = false
				continue
			if chosen == "PRAY":
				detail = await prayer.plan_pick(unit, _planned_skills, max_acts - _planned_cost())
				if detail.is_empty() or detail.has("allocated"):
					_auto_exec = false
					continue
			if chosen == FIGHT and not unit.skills.is_empty():
				detail = await _wait_skill_menu(unit, max_acts - _planned_cost(),
					unit.current_en - _planned_en(), unit.current_hp - _planned_hp())
				if detail.is_empty():
					_auto_exec = false
					continue
				if StringName(detail.skill) == &"":
					detail = {}
			var target: BattleUnit = null
			if _needs_enemy_target(chosen, detail):
				target = await _wait_target()
				if target == null:
					_auto_exec = false
					continue
			_planned.append(choice)
			_planned_skills.append(detail)
			_planned_targets.append(target)
			# Indicador em tempo real: atos da fila apontados para cada inimigo.
			_mark_target(target, 1)
			prayer.after_append(unit, _planned_skills)
			# REST (D-038) encerra a participação; REACT reserva os atos restantes.
			if chosen in ["REST", "REACT"]:
				break
			if _auto_exec:
				_auto_exec = false
				break
		if _planned.is_empty():
			return
		if options[_planned.back()] == "REACT":
			waiting_players[unit.id] = true
			_append_log("%s reserves %d acts for enemy announcements." % [unit.display_name, unit.acts_available])
			prayer.release_unresolved(unit, _planned_skills)
			_planned.clear()
			_planned_skills.clear()
			_planned_targets.clear()
			return
		# The lines on screen while planning (turn, queued spells) were read: EXEC starts a
		# fresh page, so they never cost an extra Z before the first command.
		hud.page_log()
		var chain_open := false
		var chain_target: BattleUnit = null
		for i in _planned.size():
			if not unit.is_alive() or state.is_over():
				break
			_exec_index = i
			var command: String = options[_planned[i]]
			var detail: Dictionary = _planned_skills[i]
			var target: BattleUnit = _planned_targets[i]
			# D-043: consecutive ATTACKs on the same target share one rhythm line; it closes
			# when the next command changes target or the target fell.
			if chain_open and (target != chain_target or target == null or not target.is_alive()):
				rhythm.stop_chain()
				chain_open = false
			var chain: bool = command == FIGHT and detail.is_empty() and target != null \
				and i + 1 < _planned.size() and options[_planned[i + 1]] == FIGHT \
				and _planned_skills[i + 1].is_empty() and _planned_targets[i + 1] == target
			_player_interrupted = false
			_interrupt_gainer = null
			# A chained ATTACK on the same target is not announced again ("attacks" once).
			_chain_continues = chain_open and target == chain_target
			var done := await _execute_command(unit, command, false, chain, detail, target)
			_chain_continues = false
			if not done:
				# D-057: declined (the target fell and X was pressed): this command and the
				# following ones do not run and spend no act; the hero plans again.
				break
			# Creator 2026-11-25: the rail leaves the screen as soon as no hit follows on it
			# (the target died, the hero was interrupted or this was the last command); it
			# used to stay through the result pause, over the empty spot of a dead enemy.
			if chain and (target == null or not target.is_alive() or _player_interrupted \
					or i == _planned.size() - 1 or not unit.is_alive() or state.is_over()):
				rhythm.stop_chain()
				chain = false
			chain_open = chain
			chain_target = target if chain else null
			# D-057 (creator 2026-11-25): the queued commands run one after the other with
			# no Z in between; the queue only lets the hit and its number finish. The result
			# pause comes after the last command (or after an interruption).
			var last := i == _planned.size() - 1 or not unit.is_alive() or state.is_over()
			if _player_interrupted:
				# D-049: an interrupted hero loses every following command of the plan,
				# with its act; the interrupter gains +1 act per lost command (D-005 cap).
				# D-057: told inside the same result, before its Z.
				var lost_acts := 0
				for j in range(i + 1, _planned.size()):
					if options[_planned[j]] not in ["REST", "REACT"]:
						lost_acts += _entry_cost(_planned_skills[j])
				_lose_queue(unit, _planned.slice(i + 1).map(func(c: int) -> String: return options[c]), _interrupt_gainer, lost_acts)
				await _pause_result()
				break
			if last:
				await _pause_result()
			elif not chain:
				# Creator 2026-11-25: chained hits on the same target restart the pointer at
				# once; only a change of command or target waits for the hit to finish.
				await _next_hit_on_same_target()
				if not is_inside_tree(): return
		_exec_index = -1
		prayer.release_unresolved(unit, _planned_skills)
		_planned.clear()
		_planned_skills.clear()
		_planned_targets.clear()
		# Whatever path ended the queue, no chained rail outlives it.
		if chain_open or rhythm._chain_mode:
			rhythm.stop_chain()
		_refresh_all()


## D-057: commands whose enemy target is chosen in the plan: ATTACK, a strike skill
## (Lunge) and ABSORB. Heat wave hits every enemy; ITEM / REST / PRAY choose their own.
func _needs_enemy_target(command: String, detail: Dictionary) -> bool:
	if command == "ABSORB":
		return true
	if command != FIGHT:
		return false
	if detail.is_empty():
		return true
	return String(SkillBook.def(StringName(detail.skill)).kind) == "strike"


func _mark_target(target: BattleUnit, delta: int) -> void:
	if target == null or target.is_player:
		return
	queued_acts_by_foe[target.id] = maxi(0, queued_acts_for(target) + delta)
	_refresh_all()


func _enemy_turn(unit: BattleUnit) -> void:
	active_actor = null
	# D-047 (decisão do criador): o inimigo resolve seus atos em bloco contínuo —
	# dois ataques anunciados, cada um com sua própria reação e seu próprio número
	# de dano na camada principal. A cadeia para se o combatente cair ou o duelo acabar.
	# Creator 2026-11-23: each choice is an equal draw between ATTACK and every skill the
	# enemy can pay with the acts left in this two-act block, its EN and its HP.
	var used := 0
	while used < 2:
		if not unit.is_alive() or state.is_over():
			break
		_counter_resolved = false
		_enemy_interrupted = false
		_interrupt_gainer = null
		_clear_roles()
		var skill := _enemy_choice(unit, 2 - used)
		if skill != &"":
			used += int(SkillBook.def(skill).acts)
			await _enemy_skill(unit, skill)
			if _enemy_interrupted:
				var lost: Array[String] = []
				for _rest in mini(2 - used, unit.acts_available):
					lost.append(FIGHT)
				_lose_queue(unit, lost, _interrupt_gainer)
			await _pause_result()
			if _enemy_interrupted:
				break
			continue
		used += 1
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
		_set_role(unit, "ATTACK")
		_set_role(defender, "TARGET")
		_event("%s attacks %s." % [short_name(unit), short_name(defender)])
		hud.announce_attack("NO REACTION AVAILABLE" if eligible_reactors().is_empty() else "%s → %s" % [short_name(unit), short_name(defender)], unit)
		if eligible_reactors().is_empty():
			hud.feedback = "No reaction acts left. Z / Enter: resolve attack"
			await _await_confirm("announce")
		reaction_declared = false
		var defense_paid := await _maybe_player_reaction(defender, unit)
		# A reaction can defeat the announced attacker before its action resolves.
		# D-049: a counter-attack exchange already resolved (or interrupted) this attack.
		if not _counter_resolved and unit.is_alive() and defender.is_alive():
			await _perform_attack(unit, defender, basic_power, false, defense_paid, not reaction_declared)
		if _enemy_interrupted:
			var following: Array[String] = []
			for _rest in mini(2 - used, unit.acts_available):
				following.append(FIGHT)
			_lose_queue(unit, following, _interrupt_gainer)
		await _pause_result()
		if _enemy_interrupted:
			break


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
		# The two counter rails replace the attack rail, including a line still kept from the
		# previous chained hit (that hit's own chain flag is false when it ends the queue).
		rhythm.stop_chain()
		await _enemy_counter(attacker, defender)
		return
	var hp_before := defender.current_hp
	await super._perform_attack(attacker, defender, power, is_reaction, defense_act_paid, auto_hit, chain)
	_present_strike(attacker, defender, hp_before - defender.current_hp)


func _present_strike(attacker: BattleUnit, defender: BattleUnit, damage: int, magic: bool = false) -> void:
	var outcome := "HIT"
	# D-109: todo golpe com barra acerta; só a defesa paga desvia (centro) ou bloqueia (lateral).
	if defense_result == BattleMath.RhythmResult.POINT: outcome = "DODGE"
	elif defense_result == BattleMath.RhythmResult.BEAM: outcome = "BLOCK"
	var source: String = log_history.back()
	if source.contains("crit YES"): outcome += " / CRITICAL"
	var contact := not source.contains("NO CONTACT")
	hud.message = "%s -> %s: %s, %d damage" % [short_name(attacker), short_name(defender), outcome, damage]
	hud.feedback = "%s | %s HP %d/%d%s | %s: %d ACTS left" % [outcome, short_name(defender), defender.current_hp, defender.stats.max_hp, " DOWN" if not defender.is_alive() else "", short_name(attacker), attacker.acts_available]
	# D-057: the result as plain event sentences (who dodged, who blocked, who hit whom,
	# who fell, who gained an act); the old rhythm/def/crit/affinity/SP numbers stay only
	# in log_history.
	if defense_result != BattleMath.RhythmResult.MISS and (not defender.is_player or roles.get(defender.id, "") == "DEFEND"):
		_set_role(defender, "DEFEND")
	if outcome.begins_with("DODGE"):
		_event("%s dodges." % short_name(defender))
	elif outcome.begins_with("MISS"):
		_event("%s misses." % short_name(attacker))
	elif defense_result == BattleMath.RhythmResult.BEAM:
		_event("%s blocks: %d damage." % [short_name(defender), damage])
	else:
		_event("%s hits %s: %d damage." % [short_name(attacker), short_name(defender), damage])
	if contact and not defender.is_alive():
		if _hold_down:
			_pending_down.append(defender)
		else:
			_event("%s is down." % short_name(defender))
	if contact and not magic and BattleMath.press_turn_acts(defender.affinity) > 0 and attacker.is_alive():
		_event("%s gains %d act." % [short_name(attacker), BattleMath.press_turn_acts(defender.affinity)])
	phase_text = "RESULT: " + outcome
	fx.stop_cues()
	var cue := "DODGE" if outcome.begins_with("DODGE") else ("MISS" if outcome.begins_with("MISS") else ("BLOCK" if outcome.begins_with("BLOCK") else ("CRITICAL" if outcome.contains("CRITICAL") else "HIT")))
	# Magic: the letter effect is the impact, so the effect layer shows only the number.
	if magic and cue in ["HIT", "CRITICAL", "BLOCK"]:
		cue = "MAGIC_BLOCK" if cue == "BLOCK" else "MAGIC"
	if next_hit and cue in ["HIT", "CRITICAL", "BLOCK"]:
		cue = "BLOCK_NEXT" if cue == "BLOCK" else "HIT_NEXT"
	fx.play(cue, defender, damage, attacker, cross_hit and not magic and not next_hit)
	_refresh_all()


func _attack_timing(attacker: BattleUnit, defender: BattleUnit, duration: float, auto_hit: bool = false, chain: bool = false) -> int:
	timing_role = "ATTACK"
	phase_text = "ATTACK" if attacker.is_player else "ENEMY ATTACK"
	attack_result = await super._attack_timing(attacker, defender, duration, auto_hit, chain)
	return attack_result


func _manual_rhythm(duration: float, point_half: float, chain: bool = false) -> int:
	await _flush_log()
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
	rhythm.set_marks(_rhythm_marks)
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
	await _flush_log()
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
	var skill := _announced_skill
	if not enemy.is_alive() or not reactor.spend_act():
		return false
	action_attacker = reactor
	action_defender = enemy
	phase_text = "COUNTER"
	_append_log("%s counter-attacks %s (1 act spent)." % [reactor.display_name, enemy.display_name])
	_set_role(reactor, "COUNTER")
	_event("%s counter-attacks %s." % [short_name(reactor), short_name(enemy)])
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
			# Creator 2026-11-23: an announced Lunge lands whole (2 hits) on the reactor; a
			# Heat wave lands on every hero.
			if skill == &"": _strike(enemy, reactor, o.enemy_timing, false)
			else: await _enemy_skill_lands(enemy, reactor, skill, o.enemy_timing)
			_interrupt(enemy, reactor, o)
		_:
			# D-049 tie: both blows resolve at once, so a fall is told after both.
			_hold_down = true
			_strike(reactor, enemy, o.player_timing, true)
			if skill == &"": _strike(enemy, target, o.enemy_timing, false)
			else: await _enemy_skill_lands(enemy, target, skill, o.enemy_timing)
			_release_down()
			_enemy_interrupted = true
			_interrupt_gainer = null
			_tie_report(reactor, enemy)
	return true


## An attacked enemy counter-attacks the hero's own attack (bars over the enemy).
func _enemy_counter(hero: BattleUnit, enemy: BattleUnit, skill: StringName = &"") -> void:
	enemy.spend_act()
	action_attacker = hero
	action_defender = enemy
	phase_text = "ENEMY COUNTER"
	_append_log("%s counter-attacks %s (1 act spent)." % [enemy.display_name, hero.display_name])
	# D-057: the enemy's counter is announced (it used to be overwritten in the same frame).
	_set_role(hero, "ATTACK")
	_set_role(enemy, "COUNTER")
	_event("%s counter-attacks!" % short_name(enemy))
	var o := await _counter_exchange(hero, enemy, "enemy")
	match int(o.winner):
		BattleMath.CounterWinner.PLAYER:
			if skill == &"": _strike(hero, enemy, o.player_timing, false)
			else: await _hero_skill_lands(hero, enemy, skill, o.player_timing)
			_interrupt(hero, enemy, o)
		BattleMath.CounterWinner.ENEMY:
			_strike(enemy, hero, o.enemy_timing, true)
			_interrupt(enemy, hero, o)
			_player_interrupted = true
			_interrupt_gainer = enemy
		_:
			# D-049 tie: both blows resolve at once, so a fall is told after both.
			_hold_down = true
			if skill == &"": _strike(hero, enemy, o.player_timing, false)
			else: await _hero_skill_lands(hero, enemy, skill, o.player_timing)
			_strike(enemy, hero, o.enemy_timing, true)
			_release_down()
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
	_apply_strike(attacker, defender, basic_power, is_reaction, timing, BattleMath.RhythmResult.MISS)
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
	_event("%s%s interrupts %s%s." % ["Perfect! " if bool(o.perfect) else "", short_name(winner), short_name(loser),
		" and steals %d SP" % stolen if stolen > 0 else ""])
	hud.message = "%s: %s interrupts %s | +%d SP" % [kind, short_name(winner), short_name(loser), stolen]


func _release_down() -> void:
	_hold_down = false
	for unit in _pending_down:
		_event("%s is down." % short_name(unit))
	_pending_down.clear()


func _tie_report(hero: BattleUnit, enemy: BattleUnit) -> void:
	_append_log("COUNTER TIE: %s and %s interrupt each other (no SP)." % [hero.display_name, enemy.display_name])
	_event("%s and %s interrupt each other." % [short_name(hero), short_name(enemy)])
	hud.message = "COUNTER TIE: %s and %s interrupt each other" % [short_name(hero), short_name(enemy)]


## D-049: the interrupted side loses the following commands of its queue with their
## acts; a winning interrupter gains +1 act per lost command (D-005 cap, rest stored).
func _lose_queue(unit: BattleUnit, commands: Array, gainer: BattleUnit, acts_override: int = -1) -> void:
	if commands.is_empty():
		return
	var acts := 0
	for command in commands:
		if String(command) not in ["REST", "REACT"]:
			acts += 1
	if acts_override >= 0:
		acts = acts_override
	unit.acts_available = maxi(0, unit.acts_available - acts)
	if gainer != null and gainer.is_alive():
		gainer.grant_acts(commands.size())
	_append_log("%s loses %d queued command(s)%s." % [unit.display_name, commands.size(),
		"; %s gains %d act(s)" % [gainer.display_name, commands.size()] if gainer != null and gainer.is_alive() else ""])
	# D-057: a queued command never vanishes silently.
	_event("%s loses %d queued command%s." % [short_name(unit), commands.size(), "" if commands.size() == 1 else "s"])
	if gainer != null and gainer.is_alive():
		_event("%s gains %d act%s." % [short_name(gainer), commands.size(), "" if commands.size() == 1 else "s"])
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
		await _flush_log()
		active_actor = reaction_actor
		action_attacker = attacker
		action_defender = defender
		phase_text = "ENEMY ATTACK"
		_reaction_active = true
		hud.mode = "react"
		hud.react_index = 0
		hud.message = ("%s ATTACKS %s" % [short_name(attacker), short_name(defender)]) if _announced_skill == &"" \
			else ("%s USES %s ON %s" % [short_name(attacker), SkillBook.display_name(_announced_skill), short_name(defender)])
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
			if command == FIGHT and not reaction_actor.skills.is_empty():
				# Creator 2026-11-23: skills may be used as reactions too.
				var detail := await _wait_skill_menu(reaction_actor, reaction_actor.acts_available,
					reaction_actor.current_en, reaction_actor.current_hp)
				if detail.is_empty():
					continue
				if StringName(detail.skill) != &"":
					if await _execute_command(reaction_actor, FIGHT, true, false, detail):
						in_reaction = false
						reaction_declared = true
						return false
					continue
			if command == FIGHT:
				# D-049: a counter-attack always aims at the announcing enemy and
				# resolves both strikes on the two-rail exchange.
				if await _execute_counter(reaction_actor, attacker, defender):
					in_reaction = false
					reaction_declared = true
					return false
				continue
			if command not in ["DEFEND", FIGHT]:
				_set_role(reaction_actor, "REACT")
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
	# D-052: the old SMT absorb animation is replaced by absorb_vfx (letters per press,
	# hit and break on success).
	var skills_before := unit.skills.size()
	await super._perform_absorption(unit, defender)
	if not was_absorbed and defender.absorbed:
		_event("%s absorbs %s." % [short_name(unit), short_name(defender)])
		if unit.skills.size() > skills_before:
			_event("%s learns %s." % [short_name(unit), SkillBook.display_name(unit.skills.back())])
	elif defender.is_alive():
		_event("%s resists the absorption." % short_name(defender))
	if not was_absorbed and defender.absorbed:
		fx.play("ABSORBED", unit)
		# Creator 2026-11-23: the ABSORBED label stays, in green, with the gain taken,
		# where the absorbed enemy stood (not over the log line above Fallen's card).
		# Creator 2026-11-23: under the gain, the absorption counter of that enemy kind
		# ("3/4", "MAX") and, on the 4th, the skill learned.
		fx.label_override(unit, ["ABSORBED", absorb_gain_label, absorb_count_label, absorb_skill_label], hud.enemy_sprite_rect(hud.opponents.find(defender)), ABSORBED_INK)
	hud.mode = "busy"


func _on_absorb_press(_unit: BattleUnit, defender: BattleUnit) -> void:
	absorb_fx.mash_press(defender)
	_refresh_all()


func _on_absorb_break(_unit: BattleUnit, defender: BattleUnit) -> void:
	await absorb_fx.play_break(defender)


## D-051: with two or more eligible attributes the player picks the gain.
func _choose_absorb_gain(options: Array[Dictionary]) -> int:
	if options.size() <= 1:
		return 0
	var labels: Array[String] = []
	for option in options:
		labels.append(String(option.label))
	var pick := -1
	while pick < 0:
		hud.message = "ABSORBED: choose the gain. Z: confirm."
		pick = await _wait_command(labels)
	return pick


func _pause_result() -> void:
	await _await_confirm("continue")
	# D-057: the roles belong to the action whose result was just confirmed.
	_clear_roles()


## D-057: a Z pause that first pages the event lines still waiting beyond the two-row
## log (each Z shows the next ones); only the Z after the last line goes on.
func _await_confirm(mode_name: String) -> void:
	hud.mode = mode_name
	_refresh_all()
	while is_inside_tree():
		await continue_requested
		if hud.log_hidden():
			hud.page_log()
			_refresh_all()
			continue
		break
	hud.page_log()
	hud.mode = "busy"


func proceed() -> void:
	if hud.mode in ["continue", "announce"]:
		continue_requested.emit()


func _show_result() -> void:
	prayer.battle_end(state.player_victory())
	_append_log("VICTORY." if state.player_victory() else "DEFEAT.")
	_event("VICTORY." if state.player_victory() else "DEFEAT.")
	phase_text = "VICTORY" if state.player_victory() else "DEFEAT"
	hud.announce(phase_text)
	hud.feedback = "Battle finished. Z / Enter: return to the dungeon." if Engine.has_meta(DUNGEON_RETURN_META) else "Battle finished. Z / Enter: play again. X: stay."
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
				rhythm.press()
		"skill": submit_skill(hud.command_index)
		"pray": prayer.submit(hud.command_index)
		"en_extra": confirm_en_extra()
		"counter": counter.press_player()
		"react": answer_reaction(hud.react_index == 0)
		"absorb":
			if _mash_active:
				_mash_count += 1
		"continue", "announce": proceed()
		"result":
			# Volta ao dungeon quando a batalha veio de um encontro no mapa.
			var return_scene := String(Engine.get_meta(DUNGEON_RETURN_META, ""))
			if not return_scene.is_empty():
				Engine.remove_meta(DUNGEON_RETURN_META)
				var fader := get_tree().root.get_node_or_null("SceneFader")
				if fader != null:
					fader.fade_to(return_scene)
				else:
					get_tree().change_scene_to_file(return_scene)
			else:
				get_tree().reload_current_scene()


func handle_back() -> void:
	match hud.mode:
		"target":
			hud.press_command(hud.command_index, "reject")
			cancel_target()
		"react": answer_reaction(false)
		"plan": undo_plan()
		"skill":
			hud.press_command(hud.command_index, "reject")
			cancel_skill()
		"en_extra": cancel_en_extra()
		"pray":
			hud.press_command(hud.command_index, "reject")
			prayer.cancel()
		"command":
			if in_reaction: cancel_reaction_command()
			else:
				hud.mode = "turn"
				hud.feedback = "Command menu closed. Z / Enter: reopen. No act spent."
		"continue":
			if not fx.is_busy(): proceed()
		"timing", "absorb", "counter": hud.feedback = "Action committed. Z / Enter: finish input."
		"announce": hud.feedback = "No acts to react. Z / Enter: resolve enemy attack."
		"result": hud.feedback = "Battle finished. Z / Enter: return to the dungeon." if Engine.has_meta(DUNGEON_RETURN_META) else "Battle finished. Z / Enter: play again."
		"turn": hud.feedback = "Z / Enter: choose command."
	hud.queue_redraw()


# ------------------------------------------------- skills (creator 2026-11-23)

## FIGHT submenu: ATTACK + the unit's skills. Rows it cannot pay now (acts left in the
## plan, EN, HP) are dimmed and refuse confirmation. Returns {} when cancelled,
## {"skill": &""} for ATTACK, or {"skill": id, "extra": EN} for a skill.
## Sobrescrito pelo Survival enquanto a habilidade não foi identificada.
func skill_label(skill: StringName) -> String:
	return SkillBook.display_name(skill)


func _wait_skill_menu(unit: BattleUnit, acts_left: int, en_left: int, hp_left: int) -> Dictionary:
	await _flush_log()
	while true:
		var labels: Array[String] = ["ATTACK"]
		skill_ids.assign([&""])
		skill_disabled.clear()
		skill_reasons.clear()
		skill_unit = unit
		for skill in unit.skills:
			labels.append(skill_label(skill))
			skill_ids.append(skill)
			if not SkillBook.affordable(skill, acts_left, en_left, hp_left):
				skill_disabled.append(labels.size() - 1)
				skill_reasons[labels.size() - 1] = _short_reason(skill, acts_left, en_left, hp_left)
		hud.command_options = labels
		hud.command_index = 0
		hud.mode = "skill"
		hud.feedback = "Z: confirm | X: back"
		_skill_choice = -2
		_refresh_all()
		await skill_chosen
		hud.mode = "busy"
		if _skill_choice < 0:
			return {}
		var skill: StringName = skill_ids[_skill_choice]
		if skill == &"":
			return {"skill": &""}
		if skill == SkillBook.ENERGY_EAT:
			var extra := await _wait_en_extra(en_left - int(SkillBook.def(skill).en))
			if extra < 0:
				continue
			return {"skill": skill, "extra": extra}
		return {"skill": skill, "extra": 0}
	return {}


func _short_reason(skill: StringName, acts_left: int, en_left: int, _hp_left: int) -> String:
	var d := SkillBook.def(skill)
	if int(d.acts) > acts_left: return "NO ACT"
	if int(d.en) > en_left: return "NO EN"
	return "NO HP"


## Battle log text for the highlighted FIGHT submenu row.
func skill_info(index: int) -> String:
	if index < 0 or index >= skill_ids.size(): return ""
	var skill: StringName = skill_ids[index]
	var text: String = ATTACK_INFO if skill == &"" else String(SkillBook.def(skill).info)
	if skill_reasons.has(index):
		text += " | " + String(skill_reasons[index])
	return text


func submit_skill(index: int) -> void:
	if hud.mode != "skill" or index < 0 or index >= skill_ids.size():
		return
	if skill_disabled.has(index):
		hud.press_command(index, "reject")
		return
	_skill_choice = index
	hud.command_index = index
	hud.press_command(index, "confirm")
	skill_chosen.emit()


func cancel_skill() -> void:
	if hud.mode == "skill":
		_skill_choice = -1
		skill_chosen.emit()


## Energy Eat: one line "EXTRA EN < n >", Left/Right adjust, Z confirms, X goes back.
func _wait_en_extra(maximum: int) -> int:
	await _flush_log()
	en_extra = 0
	en_extra_max = maxi(0, maximum)
	_en_extra_ok = false
	hud.mode = "en_extra"
	hud.feedback = "Left / Right: extra EN | Z: confirm | X: back"
	_refresh_all()
	await en_extra_chosen
	hud.mode = "busy"
	return en_extra if _en_extra_ok else -1


func adjust_en_extra(delta: int) -> void:
	if hud.mode == "en_extra":
		en_extra = clampi(en_extra + delta, 0, en_extra_max)
		hud.queue_redraw()


func confirm_en_extra() -> void:
	if hud.mode == "en_extra":
		_en_extra_ok = true
		en_extra_chosen.emit()


func cancel_en_extra() -> void:
	if hud.mode == "en_extra":
		_en_extra_ok = false
		en_extra_chosen.emit()


func en_extra_info() -> String:
	var heal := int(SkillBook.def(SkillBook.ENERGY_EAT).heal) + en_extra
	return "ENERGY EAT: +%d extra EN -> heals %d HP | costs %d EN (max extra %d)" % [
		en_extra, heal, int(SkillBook.def(SkillBook.ENERGY_EAT).en) + en_extra, en_extra_max]


## A hero uses a skill (action or reaction). Costs are paid when it resolves.
func _execute_skill(unit: BattleUnit, detail: Dictionary, reacting: bool, planned: BattleUnit = null) -> bool:
	var skill := StringName(detail.skill)
	var d := SkillBook.def(skill)
	var extra := int(detail.get("extra", 0))
	if not SkillBook.affordable(skill, unit.acts_available, unit.current_en - extra, unit.current_hp):
		_append_log("%s cannot pay %s any more." % [unit.display_name, d.name])
		_event("%s cannot pay %s." % [short_name(unit), d.name])
		return true
	var target: BattleUnit = null
	if d.kind == "strike":
		phase_text = "SELECT %s TARGET" % d.name
		# D-057: the target chosen in the plan (a reaction chooses it here).
		target = await _planned_or_new_target(planned)
		if target == null: return false
	_pay_skill(unit, skill, extra)
	phase_text = ("REACTION " if reacting else "") + String(d.name)
	_append_log("%s uses %s." % [unit.display_name, d.name])
	if not reacting: _clear_roles()
	if reacting: _set_role(unit, "REACT")
	match String(d.kind):
		"strike":
			if not reacting: _set_role(unit, "ATTACK")
			_set_role(target, "TARGET")
			_event("%s uses %s on %s." % [short_name(unit), d.name, short_name(target)])
		"magic":
			if not reacting: _set_role(unit, "ATTACK")
			for foe in hud.opponents:
				if foe.is_alive(): _set_role(foe, "TARGET")
			_event("%s uses %s." % [short_name(unit), d.name])
		_:
			_event("%s uses %s." % [short_name(unit), d.name])
	match String(d.kind):
		"strike": await _skill_strike(unit, target, skill, reacting)
		"magic": await _hero_magic(unit, skill, reacting)
		_: _self_skill(unit, skill, extra, reacting)
	_refresh_all()
	return true


func _pay_skill(unit: BattleUnit, skill: StringName, extra: int) -> void:
	var d := SkillBook.def(skill)
	for _i in int(d.acts):
		unit.spend_act()
	unit.current_en = maxi(0, unit.current_en - int(d.en) - extra)
	unit.current_hp = maxi(1, unit.current_hp - int(d.hp))
	_refresh_all()


## Bleedbuff / Energy Eat on the user itself.
func _self_skill(unit: BattleUnit, skill: StringName, extra: int, reacting: bool) -> void:
	var d := SkillBook.def(skill)
	action_attacker = unit
	action_defender = unit
	if d.kind == "buff":
		_add_stage(unit)
		fx.play("BUFF", unit, int(d.hp))
		letter_fx.self_skill(unit, "buff")
		_append_log("%s: -%d HP, +1 ATK stage (%d active, ATK x%.2f)." % [unit.display_name, int(d.hp),
			unit.atk_stages.size(), 1.0 + SkillBook.ATK_STAGE_BONUS * unit.atk_stages.size()])
		_event("%s's ATK rises." % short_name(unit))
	else:
		var healed := unit.heal(int(d.heal) + extra)
		fx.play("HEAL", unit, healed)
		letter_fx.self_skill(unit, "heal")
		_append_log("%s eats energy: +%d HP (%d extra EN)." % [unit.display_name, healed, extra])
		_event("%s recovers %d HP." % [short_name(unit), healed])
	if reacting: unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	hud.feedback = "%s: HP %d/%d | EN %d/%d" % [short_name(unit), unit.current_hp, unit.stats.max_hp, unit.current_en, unit.stats.max_en]


func _add_stage(unit: BattleUnit) -> void:
	# Owner kept as an id: a BattleUnit reference here would be a RefCounted cycle.
	unit.atk_stages.append({"round": state.round_number, "owner": turn_owner.id if turn_owner != null else &""})


## A stage lasts 1 full round: it ends when, in a later round, the turn of the unit that
## owned the turn at cast time comes back; `owner == null` = end of round (the owner
## never came back in the following round).
func _expire_stages(owner: BattleUnit) -> void:
	for unit in state.units:
		for i in range(unit.atk_stages.size() - 1, -1, -1):
			var stage_info: Dictionary = unit.atk_stages[i]
			if int(stage_info.round) >= state.round_number:
				continue
			if owner == null or StringName(stage_info.owner) == owner.id:
				unit.atk_stages.remove_at(i)
				_append_log("%s: ATK stage ended (%d active)." % [unit.display_name, unit.atk_stages.size()])
				_event("%s's ATK boost ends." % short_name(unit))


## Burns: 3 damage per stacked burn at the start of each round, 3 rounds each.
func _burn_tick() -> void:
	var burned := false
	for unit in state.units:
		if not unit.is_alive() or unit.burns.is_empty():
			continue
		var applied := unit.take_damage(SkillBook.BURN_DAMAGE * unit.burns.size())
		for i in range(unit.burns.size() - 1, -1, -1):
			unit.burns[i] -= 1
			if unit.burns[i] <= 0:
				unit.burns.remove_at(i)
		action_attacker = unit
		action_defender = unit
		fx.play("BURN", unit, applied)
		letter_fx.burn(unit)
		_append_log("%s burns: -%d HP (%d burn(s) left)." % [unit.display_name, applied, unit.burns.size()])
		_event("%s burns: %d damage." % [short_name(unit), applied])
		if not unit.is_alive():
			_event("%s is down." % short_name(unit))
		burned = true
	if burned:
		_refresh_all()
		await get_tree().create_timer(0.8).timeout
		if not is_inside_tree(): return


## Overridable by tests: 25% burn roll of Heat wave (true = burn).
func _burn_roll(chance: int) -> bool:
	return rng.randf() * 100.0 < float(chance)


## Overridable by tests: which of the enemy's choices it takes (equal draw).
func _enemy_skill_pick(choices: int) -> int:
	return rng.randi_range(0, choices - 1)


## Overridable by tests: Energy Eat extra EN chosen by the AI (random 0..max).
func _enemy_en_extra(maximum: int) -> int:
	return rng.randi_range(0, maxi(0, maximum))


## &"" = ATTACK, else the skill drawn among the payable ones.
func _enemy_choice(unit: BattleUnit, budget: int) -> StringName:
	var choices: Array[StringName] = [&""]
	var acts := mini(budget, unit.acts_available)
	for skill in unit.skills:
		if SkillBook.affordable(skill, acts, unit.current_en, unit.current_hp):
			choices.append(skill)
	return choices[clampi(_enemy_skill_pick(choices.size()), 0, choices.size() - 1)]


## Enemy uses a skill. Lunge and Heat wave are announced and can be reacted to like an
## ATTACK (creator 2026-11-23); Bleedbuff and Energy Eat resolve at once.
func _enemy_skill(unit: BattleUnit, skill: StringName) -> void:
	var d := SkillBook.def(skill)
	var extra := 0
	if skill == SkillBook.ENERGY_EAT:
		var room := maxi(0, unit.current_en - int(d.en))
		extra = clampi(_enemy_en_extra(room), 0, room)
	_pay_skill(unit, skill, extra)
	action_attacker = unit
	phase_text = "ENEMY " + String(d.name)
	fx.play("WHITEN", unit)
	hud.feedback = ""
	if d.kind in ["buff", "heal"]:
		_append_log("%s uses %s." % [unit.display_name, d.name])
		_event("%s uses %s." % [short_name(unit), d.name])
		_self_skill(unit, skill, extra, false)
		hud.message = "%s USES %s" % [short_name(unit), d.name]
		_refresh_all()
		return
	var targets: Array[BattleUnit] = []
	if d.kind == "strike":
		var defender := _player_with_most_sp()
		if defender != null: targets.append(defender)
	else:
		for hero in hud.players:
			if hero.is_alive(): targets.append(hero)
	if targets.is_empty():
		return
	_announced_skill = skill
	var paid := {}
	var declared := {}
	for target in targets:
		if not target.is_alive() or not unit.is_alive() or _counter_resolved:
			continue
		action_attacker = unit
		action_defender = target
		_append_log("%s announces %s on %s." % [unit.display_name, d.name, target.display_name])
		_set_role(unit, "ATTACK")
		if not roles.has(target.id): _set_role(target, "TARGET")
		_event("%s uses %s on %s." % [short_name(unit), d.name, short_name(target)])
		hud.announce_attack("NO REACTION AVAILABLE" if eligible_reactors().is_empty() else "%s %s → %s" % [short_name(unit), d.name, short_name(target)], unit)
		if eligible_reactors().is_empty():
			hud.feedback = "No reaction acts left. Z / Enter: resolve %s" % d.name
			await _await_confirm("announce")
		reaction_declared = false
		paid[target] = await _maybe_player_reaction(target, unit)
		declared[target] = reaction_declared
	_announced_skill = &""
	if _counter_resolved or not unit.is_alive():
		return
	if d.kind == "strike":
		var target: BattleUnit = targets[0]
		if target.is_alive():
			await _skill_strike(unit, target, skill, false, bool(paid.get(target, false)), not bool(declared.get(target, false)))
		return
	var roll := _ai_roll(unit, targets[0])
	var first := true
	for target in targets:
		if not target.is_alive(): continue
		if not first:
			await get_tree().create_timer(MULTI_HIT_GAP).timeout
			if not is_inside_tree(): return
		first = false
		var timing: int = roll if bool(declared.get(target, false)) else BattleMath.RhythmResult.POINT
		var defense: Array[int] = await _skill_defense_timing(target, unit, [0.5], bool(paid.get(target, false)))
		_magic_hit(unit, target, skill, false, timing, defense[0])


## Lunge: one rail with two marks for the attacker and for the defender, then 2 hits.
func _skill_strike(attacker: BattleUnit, defender: BattleUnit, skill: StringName, reacting: bool,
		defense_paid: bool = false, auto_hit: bool = false) -> void:
	var d := SkillBook.def(skill)
	var marks: Array[float] = []
	marks.assign(d.marks)
	action_attacker = attacker
	action_defender = defender
	# Creator 2026-11-23: an attacked enemy may counter-attack a hero's Lunge (33%).
	if attacker.is_player and not reacting and not defender.is_player and defender.is_alive() \
			and defender.acts_available > 0 and _enemy_counter_roll(defender):
		await _enemy_counter(attacker, defender, skill)
		return
	var attack := await _skill_attack_timing(attacker, defender, marks, auto_hit)
	var defense := await _skill_defense_timing(defender, attacker, marks, defense_paid)
	for i in marks.size():
		if not defender.is_alive(): break
		cross_hit = true
		next_hit = i > 0
		_skill_hit(attacker, defender, int(d.power), reacting, attack[i], defense[i], false)
		cross_hit = false
		next_hit = false


## Heat wave by a hero: one attack rail, then each enemy defends on its own; each enemy
## hit may counter-attack first (33% each, the first that passes).
func _hero_magic(attacker: BattleUnit, skill: StringName, reacting: bool) -> void:
	var targets: Array[BattleUnit] = []
	for foe in hud.opponents:
		if foe.is_alive(): targets.append(foe)
	if targets.is_empty(): return
	if not reacting:
		for foe in targets:
			if foe.acts_available > 0 and _enemy_counter_roll(foe):
				await _enemy_counter(attacker, foe, skill)
				return
	action_attacker = attacker
	action_defender = targets[0]
	var attack := await _skill_attack_timing(attacker, targets[0], [0.5], false)
	var first := true
	for foe in targets:
		if not foe.is_alive(): continue
		if not first:
			await get_tree().create_timer(MULTI_HIT_GAP).timeout
			if not is_inside_tree(): return
		first = false
		var defense := await _skill_defense_timing(foe, attacker, [0.5], false)
		_magic_hit(attacker, foe, skill, reacting, attack[0], defense[0])


## The hero's skill after winning (or tying) an enemy counter-attack exchange: it lands
## with the exchange timing; the counter-attacker does not defend.
func _hero_skill_lands(hero: BattleUnit, counterer: BattleUnit, skill: StringName, timing: int) -> void:
	var d := SkillBook.def(skill)
	if d.kind == "strike":
		for i in d.marks.size():
			if not counterer.is_alive(): break
			cross_hit = true
			next_hit = i > 0
			_skill_hit(hero, counterer, int(d.power), false, timing, BattleMath.RhythmResult.MISS, false)
			cross_hit = false
			next_hit = false
		return
	var first := true
	for foe in hud.opponents.duplicate():
		if not foe.is_alive(): continue
		if not first:
			await get_tree().create_timer(MULTI_HIT_GAP).timeout
			if not is_inside_tree(): return
		first = false
		var defense: int = BattleMath.RhythmResult.MISS
		if foe != counterer:
			var rolled: Array[int] = await _skill_defense_timing(foe, hero, [0.5], false)
			defense = rolled[0]
		_magic_hit(hero, foe, skill, false, timing, defense)


## The enemy's announced skill after winning (or tying) the hero's counter-attack:
## Lunge whole on `target`, Heat wave on every hero, no defense rail.
func _enemy_skill_lands(enemy: BattleUnit, target: BattleUnit, skill: StringName, timing: int) -> void:
	var d := SkillBook.def(skill)
	if d.kind == "strike":
		for i in d.marks.size():
			if not target.is_alive(): break
			cross_hit = true
			next_hit = i > 0
			_skill_hit(enemy, target, int(d.power), false, timing, BattleMath.RhythmResult.MISS, false)
			cross_hit = false
			next_hit = false
		return
	var first := true
	for hero in hud.players.duplicate():
		if not hero.is_alive(): continue
		if not first:
			await get_tree().create_timer(MULTI_HIT_GAP).timeout
			if not is_inside_tree(): return
		first = false
		_magic_hit(enemy, hero, skill, false, timing, BattleMath.RhythmResult.MISS)


## Lunge's second hit waits until the first impact and its number are gone, so the two
## numbers never overlap on the same target (presentation only).
func _next_hit_on_same_target() -> void:
	var left := 3.0
	while is_inside_tree() and fx.is_busy() and left > 0.0:
		await get_tree().process_frame
		left -= get_process_delta_time()
	if not is_inside_tree(): return
	await get_tree().create_timer(0.1).timeout


func _skill_hit(attacker: BattleUnit, defender: BattleUnit, power: int, is_reaction: bool,
		attack: int, defense: int, magic: bool) -> int:
	if not defender.is_alive():
		return -1
	action_attacker = attacker
	action_defender = defender
	attack_result = attack
	defense_result = defense
	var hp_before := defender.current_hp
	var applied := _apply_strike(attacker, defender, power, is_reaction, attack, defense, magic)
	_present_strike(attacker, defender, hp_before - defender.current_hp, magic)
	return applied


func _magic_hit(attacker: BattleUnit, defender: BattleUnit, skill: StringName, is_reaction: bool,
		attack: int, defense: int) -> void:
	var d := SkillBook.def(skill)
	var applied := _skill_hit(attacker, defender, int(d.power), is_reaction, attack, defense, true)
	if applied >= 0:
		letter_fx.heat_hit(attacker, defender)
	if applied >= 0 and defender.is_alive() and _burn_roll(int(d.get("burn_chance", 0))):
		defender.burns.append(SkillBook.BURN_ROUNDS)
		_append_log("%s is burning (%d burn(s))." % [defender.display_name, defender.burns.size()])
		_event("%s is burning." % short_name(defender))


## Attack timing per mark: the hero presses on the rail; an enemy rolls each mark (or
## lands every mark when no reaction was declared, D-022).
## Creator 2026-11-23: a multi-hit skill (Lunge: 2) uses one normal bar PER HIT, one after
## the other (never one bar with several marks); one press per bar, attack or defense.
func _skill_bars(count: int, point_half: float) -> Array[int]:
	var results: Array[int] = []
	_rhythm_marks = [0.5]
	for i in count:
		# A chained bar stays on screen between the hits of the same skill.
		results.append(await _manual_rhythm(BattleMath.RHYTHM_FIXED_SECONDS, point_half, count > 1))
	if count > 1:
		rhythm.stop_chain()
	return results


func _skill_attack_timing(attacker: BattleUnit, defender: BattleUnit, marks: Array[float], auto_hit: bool) -> Array[int]:
	var results: Array[int] = []
	action_attacker = attacker
	action_defender = defender
	if attacker.is_player:
		timing_role = "ATTACK"
		phase_text = "ATTACK"
		var point_half := BattleMath.point_half_width(attacker.stats.agi, defender.stats.agi, attacker.current_sp, defender.current_sp)
		results = await _skill_bars(marks.size(), point_half)
	else:
		for _m in marks:
			results.append(BattleMath.RhythmResult.POINT if auto_hit else _ai_roll(attacker, defender))
	while results.size() < marks.size():
		results.append(BattleMath.RhythmResult.MISS)
	attack_result = results[0]
	return results


## Defense per mark: a hero who paid DEFEND presses on its rail (same marks); an enemy
## rolls each mark and spends one act for the whole rail (D-109: always, defended or not).
func _skill_defense_timing(defender: BattleUnit, attacker: BattleUnit, marks: Array[float], paid: bool) -> Array[int]:
	var results: Array[int] = []
	if defender.is_player:
		if paid:
			action_attacker = attacker
			action_defender = defender
			timing_role = "DEFEND"
			phase_text = "DEFENDING"
			var point_half := BattleMath.point_half_width(defender.stats.agi, attacker.stats.agi, defender.current_sp, attacker.current_sp)
			results = await _skill_bars(marks.size(), point_half)
			for r in results:
				if r == BattleMath.RhythmResult.POINT:
					defender.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	elif defender.acts_available > 0:
		var point_half := BattleMath.point_half_width(defender.stats.agi, attacker.stats.agi, defender.current_sp, attacker.current_sp)
		var rolls := BattleMath.extra_block_rolls(defender.current_sp - attacker.current_sp) + 1
		for _m in marks:
			var result: int = BattleMath.RhythmResult.MISS
			for _i in rolls:
				result = _zone_roll(point_half)
				if result != BattleMath.RhythmResult.MISS: break
			results.append(result)
		# D-109: defender custa 1 ACT sempre, dê certo ou não.
		defender.spend_act()
	while results.size() < marks.size():
		results.append(BattleMath.RhythmResult.MISS)
	defense_result = results[0]
	return results


# ------------------------------------------------- D-048 prayer (rules in prayer_flow.gd)

## Overridable by tests: does this enemy attack Yoch's PRAY (33%)?
func _enemy_pray_reaction_roll(_enemy: BattleUnit) -> bool:
	return rng.randf() < PrayerBook.ENEMY_PRAY_REACTION_CHANCE


## Overridable by tests: does the enemy struck by Ra'am counter-attack it (33%)?
func _enemy_raam_counter_roll(_enemy: BattleUnit) -> bool:
	return rng.randf() < PrayerBook.ENEMY_RAAM_COUNTER_CHANCE
