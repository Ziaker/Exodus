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
const SKILL_GROTESQUE = preload("res://scripts/battle/skill_grotesque_fx.gd")
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
## D-105 (creator 2026-11-25): PASS hands the turn over without spending acts. Units that
## passed with no real turn taken since, by id; coming back to one of them means everyone
## left with a turn passed, so the round ends (leftover acts go to the stock).
var _pass_streak: Dictionary = {}
## D-105: set when the turn being played ended with PASS.
var _turn_passed := false
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
## D-104 (creator 2026-11-25): ABSORB is an immediate action of the hero's own turn. It
## costs 2 ACT, puts nothing in the queue and resolves the moment it is chosen; it is
## never offered as a reaction.
const ABSORB_ACTS := 2
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
## D-125: Anatômico Grotesco + Moiré dos ataques não-reza (z_index 50, abaixo do DamageLayer).
var grotesque_fx: Node2D
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
	grotesque_fx = SKILL_GROTESQUE.new()
	grotesque_fx.name = "SkillGrotesqueFX"
	grotesque_fx.battle = self
	grotesque_fx.hud = hud
	add_child(grotesque_fx)


func _refresh_all() -> void:
	if state.units.size() < 4:
		return
	if state.round_number != _indicator_round:
		_indicator_round = state.round_number
		queued_acts_by_foe.clear()
	hud.players.assign([_fallen, _ally])
	var opps: Array[BattleUnit] = []
	for u in state.units:
		if not u.is_player:
			opps.append(u)
	hud.opponents.assign(opps)
	hud.actor = 0 if active_actor == null or active_actor == _fallen else 1
	hud.queue_redraw()


## Complete diagnostics (rhythm, defense, crit, SP roll) for tests and debugging.
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


## D-110 (criador 2026-11-26): o log rola sozinho, sem paginação com Z; a batalha nunca
## espera por ele. Mantida como ponto único caso o log volte a precisar de uma pausa.
func _flush_log() -> void:
	if not is_inside_tree():
		return
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
		# D-104: a refused (dimmed) row must not run the commands already queued.
		if plan_row_disabled(index):
			submit_plan(index)
			return
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
	# D-104: like a skill the hero cannot pay (creator 2026-11-23), a dimmed row refuses.
	if plan_row_disabled(index):
		hud.press_command(index, "reject")
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


## D-104: acts of the plan not committed to a queued command (the queue keeps its own).
func _free_plan_acts(unit: BattleUnit) -> int:
	return mini(BattleMath.MAX_AVAILABLE_ACTS, unit.acts_available) - _planned_cost()


## D-104: ABSORB can be paid now: Fallen, own turn (never a reaction), 2 free acts.
func absorb_affordable(unit: BattleUnit) -> bool:
	return unit != null and unit.is_fallen and not in_reaction and _exec_index < 0 \
		and _free_plan_acts(unit) >= ABSORB_ACTS


## D-104: the HUD dims the plan rows that refuse confirmation (ABSORB without 2 free acts),
## the same treatment as the FIGHT submenu rows the hero cannot pay.
func plan_row_disabled(index: int) -> bool:
	if hud == null or hud.mode != "plan" or index < 0 or index >= _plan_options.size():
		return false
	return _plan_options[index] == "ABSORB" and not absorb_affordable(active_actor)


func _entry_cost(detail: Dictionary) -> int:
	# D-105: PASS spends no act.
	if detail.get("pass", false): return 0
	if detail.has("pray"):
		return PrayerBook.act_cost(StringName(detail.pray))
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
			total += SkillBook.hp_cost_of(StringName(detail.skill), active_actor.stats.max_hp if active_actor != null else 0)
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
		for u in state.units:
			u.passive_stance = false  # D-124: the stance lasts only through the round it was taken
		prayer.round_start()
		if state.round_number > 1:
			hud.announce("ROUND %02d" % state.round_number)
			_event("ROUND %02d" % state.round_number)
		_refresh_all()
		await _burn_tick()
		if not is_inside_tree(): return
		await _status_tick()
		if not is_inside_tree(): return
		if state.is_over(): break
		var unit := _next_live_actor()
		while unit != null:
			turn_owner = unit
			_expire_stages(unit)
			prayer.expire(unit)
			if _skip_if_asleep(unit):
				pass
			elif unit.trapped_actions > 0:
				_auto_pass_trapped(unit)
			elif unit.is_player:
				await _player_turn(unit)
			else:
				await _enemy_turn(unit)
			prayer.turn_end(unit)
			_refresh_all()
			if state.is_over(): break
			unit = _next_live_actor()
		# D-058: between rounds nobody owns the turn (the HUD turn strip shows no one).
		turn_owner = null
		if state.is_over(): break
		_expire_stages(null)
		prayer.expire(null)
		# D-124: a round with only auto-PASSes would never free anyone; it counts as one action.
		if _round_actions == 0:
			_global_action_done(true)
		_round_actions = 0
		state.end_round()
		_append_log("End of round %d: +20%% EN." % state.round_number)
		_event("ROUND %d END  +20%% EN" % state.round_number)
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
	_event("DEFEAT")
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
	# D-105: a turn ended with PASS joins the streak; any other turn breaks it. Between
	# rounds nobody owns the turn, so the streak starts empty each round.
	if turn_owner == null:
		_pass_streak.clear()
	elif _turn_passed:
		_pass_streak[turn_owner.id] = true
	else:
		_pass_streak.clear()
	_turn_passed = false
	# Reserving acts changes presentation scheduling, not the shared resource pool.
	for i in state.turn_order.size():
		var unit := state.next_actor()
		if unit == null: return null
		# D-047: REACT reserves acts without spending them; skip that player's turns
		# so the enemy still gets its turn instead of skipping to the next round.
		if waiting_players.has(unit.id): continue
		# D-105: back to someone who passed with no real turn since: everyone left with a
		# turn passed too, so the round ends.
		if _pass_streak.has(unit.id): return null
		return unit
	return null


func _commands(unit: BattleUnit, reacting: bool = false) -> Array[String]:
	# D-105 (creator 2026-11-25): PASS sits right before REST on the own turn; neither
	# REST nor PASS is a reaction. D-104: ABSORB is an action of the hero's own turn, never a reaction.
	var options: Array[String] = [FIGHT, "ITEM"]
	if not reacting: options.append_array(["PASS", "REST"])
	if unit.is_fallen and not reacting: options.append("ABSORB")
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
	_high_speed = false
	if command == "PRAY":
		return await prayer.execute(unit, skill, reacting)
	if command == FIGHT and not skill.is_empty():
		return await _execute_skill(unit, skill, reacting, planned)
	phase_text = "SELECT " + command + " TARGET"
	action_attacker = unit
	action_defender = null
	attack_result = BattleMath.RhythmResult.MISS
	defense_result = BattleMath.RhythmResult.MISS
	if command == "ABSORB":
		return await _execute_absorb(unit, planned, reacting)
	var defender: BattleUnit = null
	if command == FIGHT:
		defender = await _planned_or_new_target(planned)
		if defender == null: return false
	elif command == "ITEM" and reacting:
		defender = await _wait_target("player")
		if defender == null: return false
	# D-038: REST never spends an act — it ends participation and stores the
	# remaining ones. Handle it before the shared spend_act() gate below.
	if command == "REST":
		unit.passive_stance = true
		return _execute_rest(unit, reacting)
	if command == "PASS":
		return _execute_pass(unit)
	if not unit.spend_act():
		_event("%s  NO ACT" % short_name(unit))
		return false
	action_attacker = unit
	action_defender = defender if defender != null else unit
	phase_text = "REACTION " + command if reacting else command
	_refresh_all()
	unit.passive_stance = command in ["ITEM", "DEFEND"]
	match command:
		FIGHT:
			_clear_roles()
			_set_role(unit, "ATTACK")
			_set_role(defender, "TARGET")
			# D-110: o anúncio do golpe saiu do log (setas e cartões mostram quem ataca).
			await _perform_attack(unit, defender, basic_power, reacting, false, false, chain)
		"ITEM":
			var recipient: BattleUnit = defender if defender != null else unit
			if reacting: _set_role(unit, "REACT")
			var healed := recipient.heal(6)
			fx.play("HEAL", recipient, healed)
			if unit.is_fallen: unit.add_sp(-2)
			_append_log("%s uses item on %s: +%d HP%s." % [unit.display_name, recipient.display_name, healed, " (-2 SP)" if unit.is_fallen else ""])
			_event("%s ITEM → %s  +%d HP" % [short_name(unit), short_name(recipient), healed])
			if reacting: unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
		"DEFEND":
			unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
			_set_role(unit, "DEFEND")
			_append_log("%s reacts with DEFEND (1 act spent)." % unit.display_name)
			_event("%s  DEFEND" % short_name(unit))
	if command == "ITEM":
		hud.feedback = "%s: HP %d/%d | 1 ACT spent" % [action_defender.display_name, action_defender.current_hp, action_defender.stats.max_hp]
	_refresh_all()
	return true


## D-104 (creator 2026-11-25): ABSORB spends exactly 2 ACT and resolves at once on the
## target just chosen. Refused (false, nothing spent) as a reaction, for anyone but Fallen
## or without 2 acts free of the queue.
func _execute_absorb(unit: BattleUnit, target: BattleUnit, reacting: bool) -> bool:
	if reacting or not absorb_affordable(unit):
		return false
	var defender := await _planned_or_new_target(target)
	if defender == null:
		return false
	# D-107 (creator 2026-11-25): humans cannot be absorbed; nothing is spent.
	if defender.race == &"human":
		_append_log("%s cannot absorb a human." % unit.display_name)
		_event("NO ABSORB: HUMAN")
		hud.feedback = "Humans cannot be absorbed."
		return false
	unit.acts_available -= ABSORB_ACTS
	action_attacker = unit
	action_defender = defender
	phase_text = "ABSORB"
	_clear_roles()
	_event("%s ABSORB → %s" % [short_name(unit), short_name(defender)])
	await _perform_absorption(unit, defender)
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
	unit.passive_stance = true
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
	_event("%s  REST  +%d EN  %d ACT KEPT" % [short_name(unit), unit.current_en - before, remaining])
	if reacting: unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	hud.feedback = "%s: EN %d/%d | 0 ACT spent, %d stored" % [
		unit.display_name, unit.current_en, unit.stats.max_en, remaining]
	_refresh_all()
	return true


## D-105 (creator 2026-11-25): PASS spends no act and hands the turn over; the hero keeps
## the acts left, takes later turns of the same round normally (acting or reacting) and
## whatever is still unused at the end of the round goes to the stock (D-005). No EN, no SP.
func _execute_pass(unit: BattleUnit) -> bool:
	unit.passive_stance = true
	_turn_passed = true
	action_attacker = unit
	action_defender = null
	phase_text = "PASS"
	_append_log("%s passes the turn: %d act(s) kept." % [unit.display_name, unit.acts_available])
	_event("%s  PASS" % short_name(unit))
	hud.feedback = "%s: 0 ACT spent, %d kept" % [unit.display_name, unit.acts_available]
	_refresh_all()
	return true


func _player_turn(unit: BattleUnit) -> void:
	_turn_passed = false
	active_actor = unit
	action_attacker = unit
	action_defender = null
	phase_text = "PLAYER COMMAND"
	hud.feedback = ""
	if unit.acts_available <= 0: return
	_append_log("%s: %d acts available." % [unit.display_name, unit.acts_available])
	_clear_roles()
	_event("%s  TURN" % short_name(unit))
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
			# D-104 (creator 2026-11-25): ABSORB is not queued. Its target is chosen and it
			# resolves now for 2 ACT; the queue stays as it was and the plan goes on.
			if chosen == "ABSORB":
				_auto_exec = false
				if not absorb_affordable(unit):
					continue
				var absorb_target := await _wait_target()
				_auto_exec = false
				if absorb_target == null:
					continue
				hud.page_log()
				if await _execute_command(unit, "ABSORB", false, false, {}, absorb_target):
					await _pause_result()
				_auto_exec = false
				if not is_inside_tree(): return
				if not unit.is_alive() or state.is_over():
					break
				max_acts = mini(BattleMath.MAX_AVAILABLE_ACTS, unit.acts_available)
				continue
			# D-111: commands a mode resolves at once without queueing or spending an act
			# (Survival PARTY). The base battle has none.
			if await _immediate_command(unit, chosen):
				_auto_exec = false
				if not is_inside_tree(): return
				continue
			# D-105: the PASS entry costs no act (see _entry_cost).
			var detail: Dictionary = {"pass": true} if chosen == "PASS" else {}
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
			# REST (D-038) encerra a participação; REACT reserva os atos restantes; PASS
			# (D-105) fecha a fila e passa a vez com os atos que sobrarem.
			if chosen in ["REST", "REACT", "PASS"]:
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
			# D-118 Lior: heal on each completed action (not on the cast of Lior itself).
			var is_lior_cast: bool = command == "PRAY" and StringName(detail.get("pray", &"")) == PrayerBook.LIOR
			if not _player_interrupted and not is_lior_cast and unit.is_alive():
				prayer.tick_lior(unit)
			_global_action_done()
			# D-118 Esh Ochelet: the marked hero is bitten after each action it completes.
			if not _player_interrupted and unit.is_alive():
				prayer.tick_ochelet(unit)
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
					if options[_planned[j]] not in ["REST", "REACT", "PASS"]:
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
		# D-105: PASS ends this turn with the acts left; they wait for a later turn.
		if _turn_passed:
			return


## D-111: a plan command handled at once by a mode (true = handled, nothing queued). Base: none.
func _immediate_command(_unit: BattleUnit, _command: String) -> bool:
	return false


## D-057: commands whose enemy target is chosen in the plan: ATTACK and a strike skill
## (Lunge). Heat wave hits every enemy; ITEM / REST / PRAY choose their own. D-104: ABSORB
## is not queued; it picks its target and resolves on its own branch of the plan loop.
func _needs_enemy_target(command: String, detail: Dictionary) -> bool:
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
		var skill := &"" if unit.kind == &"burning_bush" else _enemy_choice(unit, 2 - used)
		if skill == &"flee":
			# D-129: orphan Floater Eye (accompanied human/Mazik is down) flees automatically.
			_execute_flee(unit)
			_global_action_done()
			await _pause_result()
			break
		if skill == &"rest":
			# D-129: Floater Eye out of EN (with living ally) rests via D-038.
			_execute_rest(unit, false)
			_global_action_done()
			prayer.tick_ochelet(unit)
			await _pause_result()
			break
		if skill != &"":
			used += int(SkillBook.def(skill).acts)
			await _enemy_skill(unit, skill)
			_global_action_done()
			prayer.tick_ochelet(unit)
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
		# D-110: o anúncio do golpe saiu do log (setas e cartões mostram quem ataca).
		hud.announce_attack("NO REACTION AVAILABLE" if eligible_reactors().is_empty() else "%s → %s" % [short_name(unit), short_name(defender)], unit)
		if eligible_reactors().is_empty():
			hud.feedback = "No reaction acts left. Z / Enter: resolve attack"
			await _await_confirm("announce")
		reaction_declared = false
		var defense_paid := await _maybe_player_reaction(defender, unit)
		# A reaction can defeat the announced attacker before its action resolves.
		# D-049: a counter-attack exchange already resolved (or interrupted) this attack.
		if not _counter_resolved and unit.is_alive() and defender.is_alive():
			if unit.kind == &"burning_bush":
				var res: Dictionary = prayer.burning_bush_attack_unit(unit, defender)
				fx.play("RAAM", defender, int(res.get("damage", 0)), unit)
			else:
				await _perform_attack(unit, defender, basic_power, false, defense_paid, not reaction_declared)
		_global_action_done()
		prayer.tick_ochelet(unit)
		if _enemy_interrupted:
			var following: Array[String] = []
			for _rest in mini(2 - used, unit.acts_available):
				following.append(FIGHT)
			_lose_queue(unit, following, _interrupt_gainer)
		await _pause_result()
		if _enemy_interrupted:
			break


## D-129: an orphan Floater Eye (no living non-floater ally left) flees immediately.
func _execute_flee(unit: BattleUnit) -> void:
	action_attacker = unit
	action_defender = null
	phase_text = "FLEE"
	unit.fled = true
	unit.current_hp = 0
	unit.acts_available = 0
	unit.stored_acts = 0
	_append_log("%s flees without its ally." % unit.display_name)
	_event("%s  FLEE" % short_name(unit))
	hud.feedback = "%s fled." % short_name(unit)
	_refresh_all()


func short_name(unit: BattleUnit) -> String:
	if unit == null: return ""
	if unit.kind == &"burning_bush":
		return unit.display_name
	var index: int = hud.opponents.find(unit)
	# D-110: names on screen keep only the first letter in upper case ("Foe A", "Fallen").
	return NameCase.of("FOE " + char(65 + index) if index >= 0 else unit.display_name)


func _perform_attack(attacker: BattleUnit, defender: BattleUnit, power: int, is_reaction: bool, defense_act_paid: bool = false, auto_hit: bool = false, chain: bool = false) -> void:
	_high_speed = attacker.next_attack_high_speed
	attacker.next_attack_high_speed = false
	attacker.passive_stance = false
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


## `tell` false: the caller already wrote the result line (D-110: one line per blow).
func _present_strike(attacker: BattleUnit, defender: BattleUnit, damage: int, magic: bool = false, tell: bool = true) -> void:
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
	# who fell, who gained an act); the old rhythm/def/crit/SP numbers stay only
	# in log_history.
	if defense_result != BattleMath.RhythmResult.MISS and (not defender.is_player or roles.get(defender.id, "") == "DEFEND"):
		_set_role(defender, "DEFEND")
	var line := ""
	# D-110 (criador 2026-11-26): estilo telegráfico, "A → B  N  BLOCK/DODGE/MISS".
	var pair := "%s → %s" % [short_name(attacker), short_name(defender)]
	if outcome.begins_with("DODGE"):
		line = pair + "  DODGE"
	elif outcome.begins_with("MISS"):
		line = pair + "  MISS"
	elif defense_result == BattleMath.RhythmResult.BEAM:
		line = "%s  %d  BLOCK" % [pair, damage]
	else:
		line = "%s  %d" % [pair, damage]
	# D-110: a queda e o ato ganho entram na linha do resultado (a queda adiada de _hold_down sai depois, sozinha).
	var fell := contact and not defender.is_alive()
	line += result_suffix(defender, attacker, fell and not _hold_down, 0)
	if fell and _hold_down:
		_pending_down.append(defender)
	if tell:
		_event(line)
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
	duration = SkillBook.bar_seconds(duration, _high_speed)
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
func _enemy_counter_roll(enemy: BattleUnit) -> bool:
	if enemy != null and enemy.race == &"floater_eye":
		return false
	return rng.randf() < BattleMath.ENEMY_COUNTER_CHANCE


## Overridable by tests: the random moment the enemy AI presses on its red rail.
func _counter_ai_time(red_seconds: float) -> float:
	return rng.randf_range(0.0, red_seconds)


## `fast_side`: "white" (the hero's pointer) or "red" (the enemy's) runs 20% faster when that side's
## attack is HIGH SPEED (D-124); "" keeps both at the normal speed.
func _counter_exchange(hero: BattleUnit, enemy: BattleUnit, kind: String, fast_side: String = "") -> Dictionary:
	await _flush_log()
	var index: int = hud.players.find(hero) if kind == "panel" else hud.opponents.find(enemy)
	var rails: Array[Rect2] = hud.counter_rail_rects(kind, index)
	var white_half := BattleMath.unit_point_half(hero, enemy)
	var red_half := BattleMath.unit_point_half(enemy, hero)
	var red_seconds := BattleMath.counter_red_duration(BattleMath.RHYTHM_FIXED_SECONDS, enemy.effective_agi(), hero.effective_agi())
	timing_role = "COUNTER"
	hud.mode = "counter"
	hud.message = "COUNTER: %s x %s | Z" % [short_name(hero), short_name(enemy)]
	hud.feedback = "Z / Enter or click: stop the white pointer"
	var white_seconds := SkillBook.bar_seconds(BattleMath.RHYTHM_FIXED_SECONDS, fast_side == "white")
	red_seconds = SkillBook.bar_seconds(red_seconds, fast_side == "red")
	counter.start(kind, rails[0], rails[1], white_seconds, red_seconds, white_half, red_half, _counter_ai_time(red_seconds))
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
	var o := await _counter_exchange(reactor, enemy, "panel", "red" if SkillBook.is_high_speed(skill) else "")
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
	var o := await _counter_exchange(hero, enemy, "enemy", "white" if SkillBook.is_high_speed(skill) else "")
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
	_event("%s ✖ %s%s%s" % [short_name(winner), short_name(loser), "  PERFECT" if bool(o.perfect) else "",
		"  +%d SP" % stolen if stolen > 0 else ""])
	hud.message = "%s: %s interrupts %s | +%d SP" % [kind, short_name(winner), short_name(loser), stolen]


func _release_down() -> void:
	_hold_down = false
	_pending_down.clear()


## D-110: "  DOWN" when the blow felled the target and "  +N ACT" when the attacker
## gained acts, appended to the blow's own result line (no separate lines).
func result_suffix(target: BattleUnit, attacker: BattleUnit, fell: bool, acts: int) -> String:
	var suffix := ""
	if fell:
		suffix += "  DOWN"
	if acts > 0 and attacker != null and attacker.is_alive():
		suffix += "  +%d ACT" % acts
	return suffix


func _tie_report(hero: BattleUnit, enemy: BattleUnit) -> void:
	_append_log("COUNTER TIE: %s and %s interrupt each other (no SP)." % [hero.display_name, enemy.display_name])
	_event("%s ✖ %s  TIE" % [short_name(hero), short_name(enemy)])
	hud.message = "COUNTER TIE: %s and %s interrupt each other" % [short_name(hero), short_name(enemy)]


## D-049: the interrupted side loses the following commands of its queue with their
## acts; a winning interrupter gains +1 act per lost command (D-005 cap, rest stored).
func _lose_queue(unit: BattleUnit, commands: Array, gainer: BattleUnit, acts_override: int = -1) -> void:
	if commands.is_empty():
		return
	var acts := 0
	# D-105 (creator 2026-11-25): a lost PASS gives the interrupter no act.
	var gained := 0
	for command in commands:
		if String(command) not in ["REST", "REACT", "PASS"]:
			acts += 1
		if String(command) != "PASS":
			gained += 1
	if acts_override >= 0:
		acts = acts_override
	unit.acts_available = maxi(0, unit.acts_available - acts)
	if gainer != null and gainer.is_alive():
		gainer.grant_acts(gained)
	_append_log("%s loses %d queued command(s)%s." % [unit.display_name, commands.size(),
		"; %s gains %d act(s)" % [gainer.display_name, gained] if gainer != null and gainer.is_alive() and gained > 0 else ""])
	# D-057: a queued command never vanishes silently.
	_event("%s  −%d COMMAND%s" % [short_name(unit), commands.size(), "" if commands.size() == 1 else "S"])
	if gainer != null and gainer.is_alive() and gained > 0:
		_event("%s  +%d ACT" % [short_name(gainer), gained])
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
			else ("%s USES %s ON %s" % [short_name(attacker), NameCase.of(SkillBook.display_name(_announced_skill)), short_name(defender)])
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
		_event("%s ABSORBED %s" % [short_name(unit), short_name(defender)])
		if unit.skills.size() > skills_before:
			_event("%s  NEW SKILL: %s" % [short_name(unit), NameCase.of(SkillBook.display_name(unit.skills.back()))])
	elif defender.is_alive():
		_event("%s  RESISTS ABSORB" % short_name(defender))
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


## D-103: the mash result moved the SP once; show it on the cards.
func _on_absorb_result(_unit: BattleUnit, _defender: BattleUnit, _result: Dictionary) -> void:
	_refresh_all()


func _on_absorb_break(_unit: BattleUnit, defender: BattleUnit) -> void:
	await absorb_fx.play_break(defender)


## D-051: with two or more eligible attributes the player picks the gain.
func _choose_absorb_gain(options: Array[Dictionary]) -> void:
	_absorb_gain_pick = 0
	if options.size() <= 1:
		return
	var labels: Array[String] = []
	for option in options:
		labels.append(String(option.label))
	var pick := -1
	while pick < 0 and is_inside_tree():
		hud.message = "ABSORBED: choose the gain. Z: confirm."
		pick = await _wait_command(labels)
	_absorb_gain_pick = maxi(0, pick)


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
	_event("VICTORY" if state.player_victory() else "DEFEAT")
	phase_text = "VICTORY" if state.player_victory() else "DEFEAT"
	hud.announce(phase_text)
	hud.feedback = "Battle finished. Z / Enter: return to the dungeon." if Engine.has_meta(DUNGEON_RETURN_META) else "Battle finished. Z / Enter: play again. X: stay."
	hud.mode = "result"
	_refresh_all()


func handle_confirm() -> void:
	if hud.mode == "continue" and (fx.is_busy() or grotesque_fx.is_busy()): return
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
			register_mash_press()
		"continue", "announce": proceed()
		"result":
			# Volta ao dungeon quando a batalha veio de um encontro no mapa.
			var return_scene := String(Engine.get_meta(DUNGEON_RETURN_META, ""))
			if not return_scene.is_empty():
				var fader := get_tree().root.get_node_or_null("SceneFader")
				# Auditoria 2026-11-26: Z during the fade-in of this battle was ignored by the
				# fader but the return scene was already forgotten, so the battle never left.
				# Keep it until the fader is free; the next Z leaves.
				if fader != null and String(fader.get("_phase")) != "":
					return
				Engine.remove_meta(DUNGEON_RETURN_META)
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
			if not fx.is_busy() and not grotesque_fx.is_busy(): proceed()
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
	return NameCase.of(SkillBook.display_name(skill))


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
			# D-111: a hero who prays pays prayer skills with PP (Survival human allies).
			if not SkillBook.affordable(skill, acts_left, en_left, hp_left, unit.current_pp if unit.prays else 99, unit.stats.max_hp):
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
	if skill_unit != null and skill_unit.prays and int(d.get("pp", 0)) > skill_unit.current_pp: return "NO PP"
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
	if not SkillBook.affordable(skill, unit.acts_available, unit.current_en - extra, unit.current_hp, unit.current_pp if unit.prays else 99, unit.stats.max_hp):
		_append_log("%s cannot pay %s any more." % [unit.display_name, d.name])
		_event("%s  CAN'T PAY %s" % [short_name(unit), NameCase.of(String(d.name))])
		return true
	var target: BattleUnit = null
	if d.kind == "strike":
		phase_text = "SELECT %s TARGET" % NameCase.of(String(d.name))
		# D-057: the target chosen in the plan (a reaction chooses it here).
		target = await _planned_or_new_target(planned)
		if target == null: return false
	var ally_target: BattleUnit = null
	if (d.kind == "heal" and bool(SkillFx.fx_of(skill).get("ally", false))) \
			or (d.kind == "buff" and bool(SkillFx.fx_of(skill).get("ally_only", false))):
		# D-106 DARK BOON / D-129 Floater Eye buffs learned by Fallen: pick an ally (solo defaults to self).
		if _allies_of(unit).size() > 1:
			ally_target = await _wait_target("player")
			target_side = "enemy"
			if ally_target == null: return false
		else:
			ally_target = unit
	# D-124 FANG SPINE / IGNOMA ESH: the second hit goes to a second target (the same foe or another).
	_second_target = null
	if bool(d.get("dual", false)):
		phase_text = "SELECT %s 2ND TARGET" % d.name
		_second_target = await _wait_target("enemy")
		if _second_target == null: return false
	_current_skill = skill
	_high_speed = SkillBook.is_high_speed(skill) or (d.kind in ["strike", "magic"] and unit.next_attack_high_speed)
	if d.kind in ["strike", "magic"]:
		unit.next_attack_high_speed = false
	_pay_skill(unit, skill, extra)
	unit.passive_stance = d.kind in ["buff", "heal"]
	phase_text = ("REACTION " if reacting else "") + NameCase.of(String(d.name))
	_append_log("%s uses %s." % [unit.display_name, d.name])
	if not reacting: _clear_roles()
	if reacting: _set_role(unit, "REACT")
	match String(d.kind):
		"strike":
			if not reacting: _set_role(unit, "ATTACK")
			_set_role(target, "TARGET")
			# D-110: o anúncio do golpe saiu do log (setas e cartões mostram quem ataca).
		"magic":
			if not reacting: _set_role(unit, "ATTACK")
			for foe in hud.opponents:
				if foe.is_alive(): _set_role(foe, "TARGET")
		_:
			_event("%s  %s" % [short_name(unit), NameCase.of(String(d.name))])
	match String(d.kind):
		"strike": await _skill_strike(unit, target, skill, reacting)
		"magic": await _hero_magic(unit, skill, reacting)
		_: _self_skill(unit, skill, extra, reacting, ally_target)
	_second_target = null
	_refresh_all()
	return true


func _pay_skill(unit: BattleUnit, skill: StringName, extra: int) -> void:
	var d := SkillBook.def(skill)
	for _i in int(d.acts):
		unit.spend_act()
	unit.current_en = maxi(0, unit.current_en - int(d.en) - extra)
	unit.current_hp = maxi(1, unit.current_hp - SkillBook.hp_cost_of(skill, unit.stats.max_hp))
	if unit.prays and int(d.get("pp", 0)) > 0:
		unit.change_pp(-int(d.pp))
	_refresh_all()


## Bleedbuff / Energy Eat on the user itself.
func _self_skill(unit: BattleUnit, skill: StringName, extra: int, reacting: bool, ally_target: BattleUnit = null) -> void:
	var d := SkillBook.def(skill)
	var fxd := SkillFx.fx_of(skill)
	action_attacker = unit
	action_defender = unit
	if d.kind == "prayer":
		_enemy_prayer(unit, skill)
		return
	if d.kind == "buff":
		# D-129: ally-targeted support buffs (VERDANT MIGHT, VERDANT SHELL, KEEN GAZE, ETHER LINK).
		# Floater Eyes NEVER target themselves or other Floater Eyes — only the accompanied human/Mazik.
		if bool(fxd.get("ally_only", false)):
			var recipient: BattleUnit = null
			if unit.race == &"floater_eye":
				recipient = _buff_ally_target(unit)
			elif not unit.is_player:
				recipient = _buff_ally_target(unit)
				if recipient == null:
					recipient = unit
			else:
				recipient = ally_target if ally_target != null else unit
			if recipient == null or (unit.race == &"floater_eye" and recipient.race == &"floater_eye"):
				_append_log("%s has no valid ally for %s." % [unit.display_name, d.name])
				_event("%s  NO ALLY" % short_name(unit))
				return
			action_defender = recipient
			var notes: Array[String] = []
			var tags: Array[String] = []
			for _s in int(fxd.get("atk_stages", 0)):
				_add_stage(recipient)
			if int(fxd.get("atk_stages", 0)) > 0:
				notes.append("+%d ATK stage" % int(fxd.atk_stages))
				tags.append("ATK ↑" if int(fxd.atk_stages) == 1 else "+%d ATK" % int(fxd.atk_stages))
			for _s in int(fxd.get("mak_stages", 0)):
				_add_mak_stage(recipient)
			if int(fxd.get("mak_stages", 0)) > 0:
				notes.append("+%d MAK stage" % int(fxd.mak_stages))
				tags.append("MAK ↑" if int(fxd.mak_stages) == 1 else "+%d MAK" % int(fxd.mak_stages))
			for _s in int(fxd.get("def_stages", 0)):
				_add_def_stage(recipient)
			if int(fxd.get("def_stages", 0)) > 0:
				notes.append("+%d DEF stage" % int(fxd.def_stages))
				tags.append("DEF ↑" if int(fxd.def_stages) == 1 else "+%d DEF" % int(fxd.def_stages))
			for _s in int(fxd.get("mef_stages", 0)):
				_add_mef_stage(recipient)
			if int(fxd.get("mef_stages", 0)) > 0:
				notes.append("+%d MEF stage" % int(fxd.mef_stages))
				tags.append("MEF ↑" if int(fxd.mef_stages) == 1 else "+%d MEF" % int(fxd.mef_stages))
			var agi_delta := int(fxd.get("agi_bonus", 0))
			if agi_delta > 0:
				recipient.agi_buffs.append({"round": state.round_number, "owner": turn_owner.id if turn_owner != null else &"", "amount": agi_delta})
				notes.append("+%d AGI" % agi_delta)
				tags.append("+%d AGI" % agi_delta)
			if bool(fxd.get("high_speed_next", false)):
				recipient.next_attack_high_speed = true
				notes.append("HIGH SPEED")
				tags.append("HIGH SPEED")
			var sp_amt := int(fxd.get("sp_bonus", 0))
			if sp_amt > 0:
				recipient.add_sp(sp_amt)
				recipient.sp_buffs.append({"round": state.round_number, "owner": turn_owner.id if turn_owner != null else &"", "amount": sp_amt})
				notes.append("+%d SP" % sp_amt)
				tags.append("+%d SP" % sp_amt)
			if bool(fxd.get("status_shield", false)):
				recipient.haganah = {"round": state.round_number, "owner": turn_owner.id if turn_owner != null else &"", "non_prayer": true}
				notes.append("STATUS SHIELD")
				tags.append("STATUS SHIELD")
			fx.play("BUFF", recipient, 0)
			var popup_lines: Array[String] = []
			if int(fxd.get("atk_stages", 0)) > 0 and int(fxd.get("mak_stages", 0)) > 0:
				popup_lines.append("ATK/MAK UP")
			elif int(fxd.get("def_stages", 0)) > 0 and int(fxd.get("mef_stages", 0)) > 0:
				popup_lines.append("DEF/MEF UP")
			elif agi_delta > 0:
				popup_lines.append("AGI +%d" % agi_delta)
				if bool(fxd.get("high_speed_next", false)):
					popup_lines.append("HIGH SPEED")
			elif sp_amt > 0:
				popup_lines.append("SP +%d" % sp_amt)
			elif bool(fxd.get("status_shield", false)):
				popup_lines.append("STATUS SHIELD")
			if not popup_lines.is_empty():
				fx.label_override(recipient, popup_lines, fx._unit_rect(recipient), HUD_SCRIPT.FLOATER_EYE_GREEN)
			_append_log("%s casts %s on %s: %s (EN %d/%d)." % [
				unit.display_name, d.name, recipient.display_name, ", ".join(notes), unit.current_en, unit.stats.max_en])
			# D-110: telegraphic Battle Log line matching the rest of the combat events.
			_event("%s → %s  %s" % [short_name(unit), short_name(recipient), "  ".join(tags)])
		else:
			# D-106: HOWL taunts, PRIMAL ROAR is berserk (2 stages, DEF down), WAR CRY buffs the team.
			var receivers: Array[BattleUnit] = [unit]
			if bool(fxd.get("team", false)):
				receivers = _allies_of(unit)
			for receiver in receivers:
				for _s in int(fxd.get("stages", 1)):
					_add_stage(receiver)
			if bool(fxd.get("taunt", false)):
				SkillFx.apply_status(unit, &"taunt", 1)
				_append_log("%s taunts: foes can only attack it until the next round." % unit.display_name)
			if fxd.has("status") and not fxd.has("chance"):
				SkillFx.apply_status(unit, StringName(fxd.status), int(fxd.get("rounds", 1)))
				_append_log("%s: DEF falls (%s)." % [unit.display_name, String(fxd.status).to_upper()])
			fx.play("BUFF", unit, int(d.hp))
			letter_fx.self_skill(unit, "buff")
			_append_log("%s: -%d HP, +%d ATK stage(s) (%d active, ATK x%.2f)." % [unit.display_name, int(d.hp),
				int(fxd.get("stages", 1)), unit.atk_stages.size(), 1.0 + SkillBook.ATK_STAGE_BONUS * unit.atk_stages.size()])
			_event("%s  ATK ↑" % short_name(unit))
	else:
		var patient := unit
		if bool(fxd.get("ally", false)):
			patient = ally_target if ally_target != null else _weakest_ally(unit)
		var healed := patient.heal(int(d.heal) + extra)
		if bool(fxd.get("cleanse", false)):
			SkillFx.cleanse(patient)
		if fxd.has("regen"):
			patient.regen_amount = int(fxd.regen)
			patient.regen_rounds = int(fxd.get("rounds", 3))
		fx.play("HEAL", patient, healed)
		letter_fx.self_skill(patient, "heal")
		_append_log("%s uses %s on %s: +%d HP%s." % [unit.display_name, d.name, patient.display_name, healed,
			" (%d extra EN)" % extra if skill == SkillBook.ENERGY_EAT else ""])
		_event("%s  +%d HP" % [short_name(patient), healed])
	if reacting: unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	hud.feedback = "%s: HP %d/%d | EN %d/%d" % [short_name(unit), unit.current_hp, unit.stats.max_hp, unit.current_en, unit.stats.max_en]


func _add_stage(unit: BattleUnit) -> void:
	# Owner kept as an id: a BattleUnit reference here would be a RefCounted cycle.
	unit.atk_stages.append({"round": state.round_number, "owner": turn_owner.id if turn_owner != null else &""})


func _add_mak_stage(unit: BattleUnit) -> void:
	unit.mak_stages.append({"round": state.round_number, "owner": turn_owner.id if turn_owner != null else &""})


func _add_def_stage(unit: BattleUnit) -> void:
	unit.def_round_stages.append({"round": state.round_number, "owner": turn_owner.id if turn_owner != null else &""})


func _add_mef_stage(unit: BattleUnit) -> void:
	unit.mef_stages.append({"round": state.round_number, "owner": turn_owner.id if turn_owner != null else &""})


## D-129: living non-Floater-Eye ally on the same side (never self, never another Floater Eye).
func _buff_ally_target(unit: BattleUnit) -> BattleUnit:
	var best: BattleUnit = null
	for other in state.units:
		if other == unit or not other.is_alive() or other.is_player != unit.is_player:
			continue
		if other.race == &"floater_eye":
			continue
		if best == null or other.current_sp > best.current_sp:
			best = other
	return best


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
				_event("%s  ATK ↑ END" % short_name(unit))
		for i in range(unit.mak_stages.size() - 1, -1, -1):
			var info: Dictionary = unit.mak_stages[i]
			if int(info.round) >= state.round_number:
				continue
			if owner == null or StringName(info.owner) == owner.id:
				unit.mak_stages.remove_at(i)
				_append_log("%s: MAK stage ended (%d active)." % [unit.display_name, unit.mak_stages.size()])
		for i in range(unit.def_round_stages.size() - 1, -1, -1):
			var info: Dictionary = unit.def_round_stages[i]
			if int(info.round) >= state.round_number:
				continue
			if owner == null or StringName(info.owner) == owner.id:
				unit.def_round_stages.remove_at(i)
				_append_log("%s: DEF stage ended (%d active)." % [unit.display_name, unit.def_round_stages.size()])
		for i in range(unit.mef_stages.size() - 1, -1, -1):
			var info: Dictionary = unit.mef_stages[i]
			if int(info.round) >= state.round_number:
				continue
			if owner == null or StringName(info.owner) == owner.id:
				unit.mef_stages.remove_at(i)
				_append_log("%s: MEF stage ended (%d active)." % [unit.display_name, unit.mef_stages.size()])
		for i in range(unit.agi_buffs.size() - 1, -1, -1):
			var info: Dictionary = unit.agi_buffs[i]
			if int(info.round) >= state.round_number:
				continue
			if owner == null or StringName(info.owner) == owner.id:
				unit.agi_buffs.remove_at(i)
				_append_log("%s: AGI boost ended." % unit.display_name)
		for i in range(unit.sp_buffs.size() - 1, -1, -1):
			var info: Dictionary = unit.sp_buffs[i]
			if int(info.round) >= state.round_number:
				continue
			if owner == null or StringName(info.owner) == owner.id:
				unit.add_sp(-int(info.get("amount", 0)))
				unit.sp_buffs.remove_at(i)
				_append_log("%s: SP boost ended." % unit.display_name)
		if not unit.haganah.is_empty() and bool(unit.haganah.get("non_prayer", false)):
			if int(unit.haganah.round) < state.round_number \
					and (owner == null or StringName(unit.haganah.owner) == owner.id):
				unit.haganah = {}
				_append_log("%s: Aegis Iris ended." % unit.display_name)
				_event("%s  AEGIS END" % short_name(unit))


## Burns: 3 damage per stacked burn at the start of each round, 3 rounds each.
func _burn_tick() -> void:
	var burned := false
	for unit in state.units:
		if not unit.is_alive() or unit.burns.is_empty():
			continue
		var applied := unit.take_damage(unit.burn_round_damage())
		for i in range(unit.burns.size() - 1, -1, -1):
			unit.burns[i] -= 1
			if unit.burns[i] <= 0:
				unit.burns.remove_at(i)
		if unit.burns.is_empty():
			unit.burn_power = 0
		action_attacker = unit
		action_defender = unit
		fx.play("BURN", unit, applied)
		letter_fx.burn(unit)
		_append_log("%s burns: -%d HP (%d burn(s) left)." % [unit.display_name, applied, unit.burns.size()])
		_event("%s  BURN  %d" % [short_name(unit), applied])
		if not unit.is_alive():
			_event("%s  DOWN" % short_name(unit))
		burned = true
	if burned:
		_refresh_all()
		await get_tree().create_timer(0.8).timeout
		if not is_inside_tree(): return


## D-106 SLEEP: a sleeping unit loses its turn (all its acts) and wakes up.
## D-124 temporização de ação: actions completed in this round (a turn of auto-PASS is not one).
var _round_actions := 0


## D-124: one global action was completed; every trapped unit counts it down and is freed at 0.
## `forced` is the stalemate guard (a whole round with no action).
func _global_action_done(forced: bool = false) -> void:
	if not forced:
		_round_actions += 1
	for unit in state.units:
		if unit.is_alive() and unit.trapped_actions > 0 and unit.tick_trap():
			_append_log("%s is freed." % unit.display_name)
			_event("%s is freed." % short_name(unit))


## D-124: a trapped unit's turn is an automatic PASS: the unused acts and reactions stay and
## the turn is skipped (D-105). Its queued acts are lost when it is trapped (see trap_unit).
func _auto_pass_trapped(unit: BattleUnit) -> void:
	_turn_passed = true
	action_attacker = unit
	action_defender = null
	phase_text = "PASS"
	_append_log("%s is trapped and passes the turn (%d act(s) kept)." % [unit.display_name, unit.acts_available])
	_event("%s is trapped." % short_name(unit))


## D-124: traps `unit` for `actions` global actions; the acts it had queued in its running turn are lost.
func trap_unit(unit: BattleUnit, actions: int) -> void:
	unit.trap(actions)
	_append_log("%s is trapped for %d action(s)." % [unit.display_name, actions])
	_event("%s is trapped." % short_name(unit))
	if unit == turn_owner:
		if unit.is_player: _player_interrupted = true
		else: _enemy_interrupted = true


func _skip_if_asleep(unit: BattleUnit) -> bool:
	if not unit.has_status(SkillFx.SLEEP_ID):
		return false
	unit.remove_status(SkillFx.SLEEP_ID)
	unit.acts_available = 0
	unit.stored_acts = 0
	_append_log("%s is asleep and loses the turn." % unit.display_name)
	_event("%s  SLEEP" % short_name(unit))
	return true


## D-106: round start. Bleeds hurt, REGEN heals, statuses count down (SkillFx.tick).
func _status_tick() -> void:
	var changed := false
	for unit in state.units:
		if not unit.is_alive():
			continue
		var res := SkillFx.tick(unit)
		if int(res.mend) > 0:
			fx.play("HEAL", unit, int(res.mend))
			if prayer != null:
				prayer.fx.play_nechamah_tick(unit, maxi(1, unit.mends.size() + 1))
			_append_log("%s is mended: +%d HP." % [unit.display_name, int(res.mend)])
			_event("%s  MEND +%d HP" % [short_name(unit), int(res.mend)])
			changed = true
		if int(res.regen) > 0:
			fx.play("HEAL", unit, int(res.regen))
			_append_log("%s regenerates: +%d HP." % [unit.display_name, int(res.regen)])
			_event("%s  REGEN +%d HP" % [short_name(unit), int(res.regen)])
			changed = true
	if changed:
		_refresh_all()
		await get_tree().create_timer(0.8).timeout


## D-107: a human enemy's prayer that resolves at once (PRAY, SANVERIM, NECHAMAH).
func _enemy_prayer(unit: BattleUnit, skill: StringName) -> void:
	var fxd := SkillFx.fx_of(skill)
	if bool(fxd.get("pray", false)):
		var gained := unit.change_pp(1)
		_append_log("%s prays: +%d PP (%d)." % [unit.display_name, gained, unit.current_pp])
		_event("%s  PRAY" % short_name(unit))
	elif bool(fxd.get("blind", false)):
		var seen: BattleUnit = null
		for hero in hud.players:
			if hero.is_alive() and not hero.has_status(&"blind") and (seen == null or hero.current_sp > seen.current_sp):
				seen = hero
		if seen == null:
			seen = _player_with_most_sp()
		if seen != null:
			if not seen.haganah.is_empty():
				_append_log("%s's shield blocks SANVERIM." % seen.display_name)
				_event("%s  RESISTS BLIND" % short_name(seen))
			else:
				SkillFx.apply_status(seen, &"blind", SkillFx.BLIND_ROUNDS)
				if prayer != null:
					prayer.fx.play_sanverim(seen)
				_append_log("%s is blinded by %s (smaller POINT zone until the end of the next round)." % [seen.display_name, unit.display_name])
				_event("%s  BLIND" % short_name(seen))
	elif bool(fxd.get("mend", false)):
		var patient := _weakest_ally(unit)
		patient.mends.append(SkillFx.MEND_ROUNDS)
		if prayer != null:
			prayer.fx.play_nechamah(patient, patient.mends.size())
		_append_log("%s mends %s (%d mend(s))." % [unit.display_name, patient.display_name, patient.mends.size()])
		_event("%s  MEND" % short_name(patient))
	hud.message = "%s USES %s" % [short_name(unit), NameCase.of(SkillBook.display_name(skill))]
	_refresh_all()


## Living units on the same side as `unit`, itself first.
func _allies_of(unit: BattleUnit) -> Array[BattleUnit]:
	var result: Array[BattleUnit] = [unit]
	for other in state.units:
		if other != unit and other.is_alive() and other.is_player == unit.is_player:
			result.append(other)
	return result


## The living ally (or the unit itself) with the lowest share of HP: the AI's DARK BOON target.
func _weakest_ally(unit: BattleUnit) -> BattleUnit:
	var best := unit
	for other in _allies_of(unit):
		if float(other.current_hp) / float(maxi(1, other.stats.max_hp)) < float(best.current_hp) / float(maxi(1, best.stats.max_hp)):
			best = other
	return best


## Overridable by tests: chance (0..100) of a skill status or effect.
func _fx_roll(chance: int) -> bool:
	return rng.randf() * 100.0 < float(chance)


## The skill being resolved (UNBLOCKABLE reads it); stale between skills, which is harmless.
var _current_skill: StringName = &""
## D-124 VULN PIERCE: the struck hero declared DEFEND against the skill being resolved.
var _defender_defending := false
## D-124 HIGH SPEED: the attack being resolved has a 20% faster pointer (reset by every plain attack / command).
var _high_speed := false


## D-106: one hit of a skill with its signature effect. `prev_applied` is the result of the
## previous hit of the same skill (COMBO). Returns the HP removed, -1 when there was no contact.
func _skill_hit_fx(attacker: BattleUnit, defender: BattleUnit, skill: StringName, index: int,
		reacting: bool, attack: int, defense: int, magic: bool, prev_applied: int = -1) -> int:
	var fxd := SkillFx.fx_of(skill)
	var mult := 1.0
	# D-124/D-131 VULN PIERCE: x2 against any vulnerable target (non-offensive action, defending,
	# or under an effect that forces PASS such as trap/paralysis/sleep).
	if fxd.has("vs_passive") and defender.is_vulnerable(_defender_defending):
		mult *= float(fxd.vs_passive)
	if fxd.has("combo") and index > 0 and prev_applied >= 0:
		mult *= 1.0 + float(fxd.combo)
	if fxd.has("execute") and float(defender.current_hp) < float(defender.stats.max_hp) * float(fxd.below):
		mult *= float(fxd.execute)
	_hit_mods = {"mult": mult}
	if fxd.has("prayer_base"):
		_hit_mods["prayer_base"] = true
	if fxd.has("pierce"):
		_hit_mods["pierce"] = float(fxd.pierce)
	if fxd.has("no_damage"):
		_hit_mods["no_damage"] = true
	var was_burning := not defender.burns.is_empty()
	var applied := _skill_hit(attacker, defender, SkillFx.hit_power(skill, index, attacker), reacting, attack, defense, magic)
	_hit_mods = {}
	if applied < 0:
		return applied
	var shielded := not defender.haganah.is_empty()  # Haganah blocks status conditions
	if fxd.has("steal_sp"):
		var stolen := mini(int(fxd.steal_sp), defender.current_sp)
		defender.add_sp(-stolen)
		attacker.add_sp(stolen)
	if fxd.has("sp_drain"):
		defender.add_sp(-int(fxd.sp_drain))
	if fxd.has("en_drain"):
		defender.current_en = maxi(0, defender.current_en - int(fxd.en_drain))
	if fxd.has("pp_drain") and defender.prays and defender.is_alive():
		var drained_pp := -defender.change_pp(-int(fxd.pp_drain))
		if drained_pp > 0:
			_append_log("%s loses %d PP." % [defender.display_name, drained_pp])
			_event("%s  -%d PP" % [short_name(defender), drained_pp])
	var is_point := attack == BattleMath.RhythmResult.POINT
	var bleed_stacks := int(fxd.get("bleed_point", fxd.get("bleed", 0))) if is_point else int(fxd.get("bleed", 0))
	if bool(fxd.get("bleed_point_only", false)) and not is_point:
		bleed_stacks = 0  # D-124 FANG STING: BLEED only on POINT
	if bleed_stacks > 0 and defender.is_alive() and not shielded:
		defender.add_bleed(bleed_stacks)
		_append_log("%s bleeds (%d stack(s): -%d%% healing)." % [defender.display_name, defender.bleeds.size(), int(round((1.0 - defender.heal_factor()) * 100.0))])
		_event("%s  BLEED" % short_name(defender))
	if fxd.has("leech"):
		attacker.heal(int(fxd.leech))
	if fxd.has("lifesteal"):
		var drained := attacker.heal(int(round(float(applied) * float(fxd.lifesteal))))
		if drained > 0:
			_append_log("%s drains %d HP." % [attacker.display_name, drained])
	if fxd.get("detonate", false) and was_burning and defender.is_alive():
		var blast := defender.take_damage(defender.burn_round_damage())
		_append_log("%s detonates: %s burns for %d now." % [attacker.display_name, defender.display_name, blast])
		_event("%s  BURN BLAST  %d" % [short_name(defender), blast])
	# D-124 UMBRAL GAZE: trapped for X global actions (the unit's queued acts are lost).
	if fxd.has("trap") and defender.is_alive() and not shielded:
		trap_unit(defender, int(fxd.trap))
	# D-124 IGNOMA / IGNOMA ESH: a single-target magic strike burns like HEAT WAVE (35%).
	var strike_def := SkillBook.def(skill)
	if String(strike_def.get("kind", "")) == "strike" and int(strike_def.get("burn_chance", 0)) > 0 \
			and defender.is_alive() and not shielded and _burn_roll(int(strike_def.burn_chance)):
		defender.burns.append(int(fxd.get("burn_rounds", SkillBook.BURN_ROUNDS)))
		_append_log("%s is burning (%d burn(s))." % [defender.display_name, defender.burns.size()])
		_event("%s  BURN" % short_name(defender))
	if defender.is_alive() and not shielded:
		if fxd.has("sleep_chance") and _fx_roll(int(fxd.sleep_chance)):
			SkillFx.apply_status(defender, SkillFx.SLEEP_ID, 1)
			_append_log("%s falls asleep." % defender.display_name)
			_event("%s  SLEEP" % short_name(defender))
		if fxd.has("status") and _fx_roll(int(fxd.get("chance", 100))):
			SkillFx.apply_status(defender, StringName(fxd.status), int(fxd.get("rounds", 1)))
			_append_log("%s: %s." % [defender.display_name, String(fxd.status).to_upper()])
			_event("%s  %s" % [short_name(defender), String(fxd.status).to_upper()])
	return applied


## Overridable by tests: 25% burn roll of Heat wave (true = burn).
func _burn_roll(chance: int) -> bool:
	return rng.randf() * 100.0 < float(chance)


## Overridable by tests: which of the enemy's choices it takes (equal draw).
func _enemy_skill_pick(choices: int) -> int:
	return rng.randi_range(0, choices - 1)


## Overridable by tests: Energy Eat extra EN chosen by the AI (random 0..max).
func _enemy_en_extra(maximum: int) -> int:
	return rng.randi_range(0, maxi(0, maximum))


## &"" = ATTACK, &"flee" / &"rest" = D-129 Floater Eye fallback, else the skill drawn among the payable ones.
func _enemy_choice(unit: BattleUnit, budget: int) -> StringName:
	if unit.race == &"floater_eye":
		if _buff_ally_target(unit) == null:
			return &"flee"
		var buffs: Array[StringName] = []
		var f_acts := mini(budget, unit.acts_available)
		for skill in unit.skills:
			if SkillBook.affordable(skill, f_acts, unit.current_en, unit.current_hp, 99, unit.stats.max_hp):
				buffs.append(skill)
		if buffs.is_empty():
			return &"rest"
		return buffs[clampi(_enemy_skill_pick(buffs.size()), 0, buffs.size() - 1)]
	var choices: Array[StringName] = [&""]
	var acts := mini(budget, unit.acts_available)
	for skill in unit.skills:
		if SkillBook.affordable(skill, acts, unit.current_en, unit.current_hp, unit.current_pp if unit.prays else 99, unit.stats.max_hp):
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
	_current_skill = skill
	_high_speed = SkillBook.is_high_speed(skill) or (d.kind in ["strike", "magic"] and unit.next_attack_high_speed)
	if d.kind in ["strike", "magic"]:
		unit.next_attack_high_speed = false
	_pay_skill(unit, skill, extra)
	unit.passive_stance = d.kind in ["buff", "heal"] or (d.kind == "prayer" and String(PrayerBook.entry(skill).get("target", "self")) in ["ally", "allies", "self"])
	action_attacker = unit
	phase_text = "ENEMY " + NameCase.of(String(d.name))
	fx.play("WHITEN", unit)
	hud.feedback = ""
	if d.kind in ["buff", "heal", "prayer"]:
		_append_log("%s uses %s." % [unit.display_name, d.name])
		_event("%s  %s" % [short_name(unit), NameCase.of(String(d.name))])
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
		# D-110: o anúncio do golpe saiu do log (setas e cartões mostram quem ataca).
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
		_second_target = _enemy_second_target(target) if bool(d.get("dual", false)) else null
		if target.is_alive():
			await _skill_strike(unit, target, skill, false, bool(paid.get(target, false)), not bool(declared.get(target, false)))
		_second_target = null
		return
	var roll := _ai_roll(unit, targets[0])
	if skill == &"dark_breath":
		var enemy_timings := {}
		for target in targets:
			enemy_timings[target] = roll if bool(declared.get(target, false)) else BattleMath.RhythmResult.POINT
		await _dark_breath_flow(unit, targets, enemy_timings, paid, false)
		return
	if skill == PrayerBook.CHEREV and prayer != null:
		await prayer.fx.play_cherev(false)
		if not is_inside_tree(): return
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


## D-125: starts the grotesque choreography of `skill` on `victims` and returns its start time (-1 = none).
func _gfx_start(attacker: BattleUnit, skill: StringName, victims: Array) -> float:
	if grotesque_fx == null or victims.is_empty() or not bool(SkillBook.def(skill).get("grotesque", false)):
		return -1.0
	var first: BattleUnit = victims[0]
	match skill:
		&"mazz_bite": return grotesque_fx.play_mazz_bite(attacker, first)
		&"fang_sting": return grotesque_fx.play_fang_sting(attacker, first)
		&"fang_spine": return grotesque_fx.play_fang_spine(attacker, victims)
		&"vuln_pierce": return grotesque_fx.play_vuln_pierce(attacker, first, first.is_vulnerable(_defender_defending))
		&"umbral_gaze": return grotesque_fx.play_umbral_gaze(attacker, first)
		&"ignoma": return grotesque_fx.play_ignoma(attacker, first)
		&"ignoma_esh": return grotesque_fx.play_ignoma_esh(attacker, victims)
	return -1.0


## Waits for the impact moment of hit `index` of the choreography started at `start`, then the hit lands.
func _gfx_wait(start: float, skill: StringName, index: int) -> void:
	if start < 0.0:
		return
	var age := 0.0
	match skill:
		&"mazz_bite": age = grotesque_fx.HIT_MAZZ
		&"fang_sting": age = grotesque_fx.HIT_STING
		&"fang_spine": age = grotesque_fx.HIT_SPINE[mini(index, 1)]
		&"vuln_pierce": age = grotesque_fx.HIT_VULN
		&"umbral_gaze": age = grotesque_fx.HIT_UMBRAL
		&"ignoma": age = grotesque_fx.HIT_IGNOMA
		&"ignoma_esh": age = grotesque_fx.HIT_ESH[mini(index, 1)]
	await grotesque_fx.wait_age(start, age)


## D-125 DARK BREATH: every target defends first (a perfect dodge keeps its eyes open and loses nothing), then the
## breath reaches each target in turn and its effects land at that moment. `timings`: target -> attack timing.
func _dark_breath_flow(caster: BattleUnit, targets: Array, timings: Dictionary, paid: Dictionary, reacting: bool,
		no_rail: BattleUnit = null) -> void:
	var live: Array = []
	var defs := {}
	for t in targets:
		if not t.is_alive(): continue
		live.append(t)
		if t == no_rail:
			defs[t] = BattleMath.RhythmResult.MISS
		else:
			var rolled: Array[int] = await _skill_defense_timing(t, caster, [0.5], bool(paid.get(t, false)))
			defs[t] = rolled[0]
	if live.is_empty(): return
	var dodged: Array = []
	for t in live:
		if not BattleMath.has_contact(int(timings.get(t, BattleMath.RhythmResult.POINT)), int(defs[t])):
			dodged.append(t.id)
	var start: float = grotesque_fx.play_dark_breath(caster, live, dodged) if grotesque_fx != null else -1.0
	for t in live:
		if start >= 0.0:
			await grotesque_fx.wait_age(start, grotesque_fx.breath_hit_age(caster, t))
		_magic_hit(caster, t, &"dark_breath", reacting, int(timings.get(t, BattleMath.RhythmResult.POINT)), int(defs[t]))


## D-124: the second target of a dual skill (FANG SPINE / IGNOMA ESH); null = the same target.
var _second_target: BattleUnit = null


## Overridable by tests: the enemy AI's second target (a random living hero, possibly the first).
func _enemy_second_target(first: BattleUnit) -> BattleUnit:
	var heroes: Array[BattleUnit] = []
	for hero in hud.players:
		if hero.is_alive(): heroes.append(hero)
	if heroes.is_empty(): return first
	return heroes[rng.randi_range(0, heroes.size() - 1)]


## Lunge: one rail with two marks for the attacker and for the defender, then 2 hits.
## D-124: a "dual" skill sends hit 2 at `_second_target` (own defense rail), a "magic" strike uses MAK/MEF.
func _skill_strike(attacker: BattleUnit, defender: BattleUnit, skill: StringName, reacting: bool,
		defense_paid: bool = false, auto_hit: bool = false) -> void:
	var d := SkillBook.def(skill)
	var magic := bool(d.get("magic", false))
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
	var second: BattleUnit = _second_target if bool(d.get("dual", false)) and marks.size() > 1 else null
	var defense: Array[int] = []
	if second != null and second != defender and second.is_alive():
		var d0 := await _skill_defense_timing(defender, attacker, [0.5], defense_paid)
		var d1 := await _skill_defense_timing(second, attacker, [0.5], false)
		defense = [d0[0], d1[0]]
	else:
		second = null
		defense = await _skill_defense_timing(defender, attacker, marks, defense_paid)
	_defender_defending = defense_paid
	var gstart := _gfx_start(attacker, skill, [defender, second if second != null else defender])
	var prev := -1
	for i in marks.size():
		var victim: BattleUnit = second if (second != null and i == 1) else defender
		if not victim.is_alive():
			if i > 0 or second == null: break
			continue
		await _gfx_wait(gstart, skill, i)
		cross_hit = true
		next_hit = i > 0
		prev = _skill_hit_fx(attacker, victim, skill, i, reacting, attack[i], defense[i], magic, prev)
		cross_hit = false
		next_hit = false
	_defender_defending = false


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
	if skill == &"dark_breath":
		var all_timings := {}
		for foe in targets: all_timings[foe] = attack[0]
		await _dark_breath_flow(attacker, targets, all_timings, {}, reacting)
		return
	if skill == PrayerBook.CHEREV and prayer != null:
		await prayer.fx.play_cherev(true)
		if not is_inside_tree(): return
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
		var prev := -1
		var gstart := _gfx_start(hero, skill, [counterer, counterer])
		for i in d.marks.size():
			if not counterer.is_alive(): break
			await _gfx_wait(gstart, skill, i)
			cross_hit = true
			next_hit = i > 0
			prev = _skill_hit_fx(hero, counterer, skill, i, false, timing, BattleMath.RhythmResult.MISS, bool(d.get("magic", false)), prev)
			cross_hit = false
			next_hit = false
		return
	if skill == &"dark_breath":
		var landed := {}
		for foe in hud.opponents: landed[foe] = timing
		await _dark_breath_flow(hero, hud.opponents.duplicate(), landed, {}, false, counterer)
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
		var prev := -1
		var gstart := _gfx_start(enemy, skill, [target, target])
		for i in d.marks.size():
			if not target.is_alive(): break
			await _gfx_wait(gstart, skill, i)
			cross_hit = true
			next_hit = i > 0
			prev = _skill_hit_fx(enemy, target, skill, i, false, timing, BattleMath.RhythmResult.MISS, bool(d.get("magic", false)), prev)
			cross_hit = false
			next_hit = false
		return
	if skill == &"dark_breath":
		var landed_on := {}
		for hero in hud.players: landed_on[hero] = timing
		await _dark_breath_flow(enemy, hud.players.duplicate(), landed_on, {}, false, target)
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
	var applied := _skill_hit_fx(attacker, defender, skill, 0, is_reaction, attack, defense, true)
	if applied >= 0:
		if PrayerBook.is_prayer(skill):
			if prayer != null and not prayer.fx.cherev_busy():
				prayer.fx.play_cherev(not defender.is_player)
		elif not bool(d.get("grotesque", false)):
			letter_fx.heat_hit(attacker, defender)
		# D-106 STORM: a second bolt on the same foe, 50% of the time, with the same timing.
		if bool(SkillFx.fx_of(skill).get("storm", false)) and defender.is_alive() and _fx_roll(50):
			_skill_hit_fx(attacker, defender, skill, 1, is_reaction, attack, defense, true)
			_append_log("%s is struck twice." % defender.display_name)
	if applied >= 0 and defender.is_alive() and _burn_roll(int(d.get("burn_chance", 0))):
		defender.burns.append(int(SkillFx.fx_of(skill).get("burn_rounds", SkillBook.BURN_ROUNDS)))
		_append_log("%s is burning (%d burn(s))." % [defender.display_name, defender.burns.size()])
		_event("%s  BURN" % short_name(defender))


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
		var point_half := BattleMath.unit_point_half(attacker, defender)
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
	# D-106 UNBLOCKABLE (VOID GAZE): there is no defense rail and nobody rolls a defense.
	if bool(SkillFx.fx_of(_current_skill).get("unblockable", false)):
		for _m in marks:
			results.append(BattleMath.RhythmResult.MISS)
		defense_result = BattleMath.RhythmResult.MISS
		return results
	if defender.is_player:
		if paid:
			action_attacker = attacker
			action_defender = defender
			timing_role = "DEFEND"
			phase_text = "DEFENDING"
			var point_half := BattleMath.unit_point_half(defender, attacker)
			results = await _skill_bars(marks.size(), point_half)
			for r in results:
				if r == BattleMath.RhythmResult.POINT:
					defender.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	elif defender.acts_available > 0:
		var point_half := BattleMath.unit_point_half(defender, attacker)
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
