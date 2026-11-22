extends Control

## Combate em primeira pessoa. A unica arte na cena e o oponente e o fundo;
## todo o HUD e desenhado em codigo, sem imagens da fangame.
## A logica de combate permanece a do primeiro slice.

signal command_chosen
signal rhythm_done

const BATTLEBACK := "res://assets/graphics/parallaxes/BB01-001.png"
const ENEMY_SPRITES := [
	"res://assets/graphics/battle_sprites/Avatar Anubis.png",
	"res://assets/graphics/battle_sprites/Avatar Chimera.png",
]
const ENEMY_NAMES: Array[String] = ["GENETIC FOE A", "GENETIC FOE B"]

class StatusRow extends Control:
	var name_label: Label
	var number_label: Label
	var hp_gauge: PanelContainer
	var en_gauge: PanelContainer
	var sp_label: Label

	func setup(title: String) -> void:
		name_label = BattleWidgets.styled_label(title, 14)
		name_label.position = Vector2(8, 4)
		name_label.size = Vector2(130, 20)
		add_child(name_label)

		sp_label = BattleWidgets.styled_label("SP 0", 12)
		sp_label.position = Vector2(140, 5)
		sp_label.size = Vector2(180, 18)
		add_child(sp_label)

		hp_gauge = BattleWidgets.gauge(130, 10, Color(0.20, 0.78, 0.36))
		hp_gauge.position = Vector2(8, 27)
		add_child(hp_gauge)

		en_gauge = BattleWidgets.gauge(130, 10, Color(0.25, 0.55, 0.95))
		en_gauge.position = Vector2(8, 43)
		add_child(en_gauge)

		number_label = BattleWidgets.styled_label("", 11)
		number_label.position = Vector2(144, 26)
		number_label.size = Vector2(176, 30)
		add_child(number_label)

	func refresh(unit: BattleUnit) -> void:
		name_label.text = unit.display_name + (" [DOWN]" if not unit.is_alive() else "")
		sp_label.text = "SP %d  A%d  S%d" % [unit.current_sp, unit.acts_available, unit.stored_acts]
		number_label.text = "HP %d/%d\nEN %d/%d" % [
			unit.current_hp, unit.stats.max_hp, unit.current_en, unit.stats.max_en]
		BattleWidgets.set_gauge(hp_gauge, float(unit.current_hp) / float(maxi(1, unit.stats.max_hp)))
		BattleWidgets.set_gauge(en_gauge, float(unit.current_en) / float(maxi(1, unit.stats.max_en)))

var state := BattleState.new()
var rng := RandomNumberGenerator.new()
var log_history: Array[String] = []
var rhythm: RhythmBar
var log_label: Label
var round_label: Label
var command_box: HBoxContainer
var reaction_label: Label
var fallen_fill: ColorRect
var foe_fill: ColorRect
var sp_caption: Label

var enemy_cards: Array[UnitCard] = []
var ally_rows: Array[StatusRow] = []
var enemy_sprites: Array[TextureRect] = []

var _chosen: int = -1
var _rhythm_result: int = BattleMath.RhythmResult.MISS
var _reaction_yes: bool = false
var _reaction_active: bool = false
var _mash_active: bool = false
var _mash_count: int = 0
var _feedback_token: int = 0
var _progress_gains: Dictionary = {}
## Creator decision (2026-11-21): a Restart after DEFEAT starts Fallen at base
## attributes; the saved gains are ignored for that battle but kept in the save.
var apply_saved_gains := true
var _fallen: BattleUnit = null
var _ally: BattleUnit = null

class UnitCard extends Control:
	var name_label: Label
	var hp_label: Label
	var hp_gauge: PanelContainer

	func setup(title: String) -> void:
		name_label = BattleWidgets.styled_label(title, 10, HORIZONTAL_ALIGNMENT_CENTER)
		name_label.position = Vector2(0, 0)
		name_label.size = Vector2(130, 18)
		add_child(name_label)
		hp_gauge = BattleWidgets.gauge(110, 7, Color(0.80, 0.28, 0.28))
		hp_gauge.position = Vector2(10, 18)
		add_child(hp_gauge)
		hp_label = BattleWidgets.styled_label("", 9, HORIZONTAL_ALIGNMENT_CENTER)
		hp_label.position = Vector2(0, 26)
		hp_label.size = Vector2(130, 14)
		add_child(hp_label)

	func refresh(unit: BattleUnit) -> void:
		name_label.text = unit.display_name + ("" if unit.is_alive() else " [DOWN]")
		hp_label.text = "HP %d/%d" % [unit.current_hp, unit.stats.max_hp]
		BattleWidgets.set_gauge(hp_gauge, float(unit.current_hp) / float(maxi(1, unit.stats.max_hp)))


func _ready() -> void:
	rng.randomize()
	_build_ui()
	rhythm.finished.connect(_on_rhythm_finished)
	_create_units()
	_refresh_all()
	await run_battle()


func _build_ui() -> void:
	var back := TextureRect.new()
	back.texture = load(BATTLEBACK)
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(back)

	_round_header()
	_enemy_display()

	var message_frame := BattleWidgets.window_frame(Vector2(8, 210), Vector2(528, 48))
	add_child(message_frame)
	log_label = BattleWidgets.styled_label("Battle start. First person. SP is the superiority meter.", 14)
	log_label.position = Vector2(20, 218)
	log_label.size = Vector2(504, 34)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(log_label)

	reaction_label = BattleWidgets.styled_label("", 13)
	reaction_label.position = Vector2(20, 262)
	reaction_label.size = Vector2(330, 18)
	add_child(reaction_label)

	var status_frame := BattleWidgets.window_frame(Vector2(8, 268), Vector2(340, 140))
	add_child(status_frame)
	for i in 2:
		var row := StatusRow.new()
		row.position = Vector2(12, 272 + i * 66)
		row.custom_minimum_size = Vector2(330, 64)
		row.setup("FALLEN" if i == 0 else "ALLY")
		add_child(row)
		ally_rows.append(row)

	var command_frame := BattleWidgets.window_frame(Vector2(352, 268), Vector2(184, 140))
	add_child(command_frame)
	command_box = HBoxContainer.new()
	command_box.position = Vector2(360, 274)
	command_box.add_theme_constant_override("separation", 2)
	add_child(command_box)

	_build_sp_bar()

	rhythm = RhythmBar.new()
	add_child(rhythm)


func _round_header() -> void:
	var frame := BattleWidgets.window_frame(Vector2(8, 6), Vector2(300, 28))
	add_child(frame)
	round_label = BattleWidgets.styled_label("ROUND 1", 13)
	round_label.position = Vector2(16, 10)
	round_label.size = Vector2(284, 20)
	add_child(round_label)


func _enemy_display() -> void:
	# Primeira pessoa: o oponente ocupa o campo a frente do jogador.
	# Nao ha retratos de aliados na cena — apenas texto no HUD.
	for i in ENEMY_NAMES.size():
		var sprite := TextureRect.new()
		sprite.texture = load(ENEMY_SPRITES[i])
		sprite.custom_minimum_size = Vector2(210, 200)
		sprite.stretch_mode = TextureRect.STRETCH_SCALE
		sprite.position = Vector2(72 + i * 200, 4)
		add_child(sprite)
		enemy_sprites.append(sprite)

		var card := UnitCard.new()
		card.custom_minimum_size = Vector2(130, 44)
		card.position = Vector2(90 + i * 200, 162)
		card.setup(ENEMY_NAMES[i])
		enemy_cards.append(card)
		add_child(card)


func _build_sp_bar() -> void:
	var frame := BattleWidgets.window_frame(Vector2(468, 52), Vector2(70, 152))
	add_child(frame)
	var holder := Control.new()
	holder.position = Vector2(490, 58)
	holder.custom_minimum_size = Vector2(26, 136)
	add_child(holder)
	foe_fill = ColorRect.new()
	foe_fill.color = Color(0.85, 0.25, 0.25, 0.95)
	holder.add_child(foe_fill)
	fallen_fill = ColorRect.new()
	fallen_fill.color = Color(0.30, 0.60, 0.95, 0.95)
	holder.add_child(fallen_fill)
	sp_caption = BattleWidgets.styled_label("SP", 10, HORIZONTAL_ALIGNMENT_CENTER)
	sp_caption.position = Vector2(468, 205)
	sp_caption.size = Vector2(70, 16)
	add_child(sp_caption)


func _create_units() -> void:
	var fallen_stats := UnitStats.new()
	fallen_stats.max_hp = 14
	fallen_stats.max_en = 8
	fallen_stats.atk = 7
	fallen_stats.mak = 3
	fallen_stats.defense = 5
	fallen_stats.mef = 3
	fallen_stats.agi = 6
	# D-028: restore absorption gains from the previous battles.
	# Always loaded, so new absorptions add to the stored gains instead of
	# overwriting them, even when this battle does not apply them.
	_progress_gains = ProgressStore.load_gains()
	if apply_saved_gains:
		for key in _progress_gains.keys():
			fallen_stats.set(key, int(fallen_stats.get(key)) + int(_progress_gains[key]))
	_fallen = BattleUnit.new(&"fallen", "FALLEN", fallen_stats, true, true)

	var ally_stats := UnitStats.new()
	ally_stats.max_hp = 11
	ally_stats.max_en = 7
	ally_stats.atk = 5
	ally_stats.mak = 2
	ally_stats.defense = 4
	ally_stats.mef = 2
	ally_stats.agi = 5
	_ally = BattleUnit.new(&"ally", "ALLY", ally_stats, true)

	state.add_unit(_fallen)
	state.add_unit(_ally)
	for i in ENEMY_NAMES.size():
		var enemy_stats := UnitStats.new()
		enemy_stats.max_hp = 12 + i * 3
		enemy_stats.max_en = 6
		enemy_stats.atk = 5 + i
		enemy_stats.mak = 2
		enemy_stats.defense = 4 + i
		enemy_stats.mef = 2
		enemy_stats.agi = 4 + i
		var enemy := BattleUnit.new(StringName("foe_%d" % i), ENEMY_NAMES[i], enemy_stats, false)
		enemy.affinity = BattleMath.Affinity.WEAK if i == 0 else BattleMath.Affinity.RESIST
		state.add_unit(enemy)


func run_battle() -> void:
	_append_log("Battle start. First person. SP is the superiority meter.")
	while not state.is_over():
		state.start_round()
		_refresh_all()
		var actor := state.next_actor()
		while actor != null:
			if actor.is_player:
				await _player_turn(actor)
			else:
				await _enemy_turn(actor)
			_refresh_all()
			if state.is_over():
				break
			actor = state.next_actor()
		if state.is_over():
			break
		state.end_round()
		_append_log("End of round %d: +20%% EN." % state.round_number)
	_show_result()


func _player_turn(actor: BattleUnit) -> void:
	if actor.acts_available <= 0:
		return
	var target := _first_alive_enemy()
	if target == null:
		return
	var options: Array[String] = ["ATTACK", "ITEM", "REST"]
	if actor.is_fallen:
		options.append("ABSORB")
	var choice := await _wait_command(options)
	if choice < 0:
		return
	_append_log("%s acts." % actor.display_name)
	match choice:
		0:
			if not actor.spend_act():
				return
			await _perform_attack(actor, target, 100, false)
		1:
			if not actor.spend_act():
				return
			var healed := actor.heal(6)
			if actor.is_fallen:
				actor.add_sp(-2)
			_append_log("%s uses item: +%d HP%s." % [
				actor.display_name, healed, " (-2 SP)" if actor.is_fallen else ""])
		2:
			# D-038: REST costs no act. All remaining acts go to the stock and
			# the unit stops participating this round.
			var remaining := actor.acts_available
			actor.store_acts(remaining)
			actor.acts_available = 0
			actor.recover_en_flat(BattleMath.REST_EN_RECOVERY)
			_append_log("%s rests: +%d EN, %d act(s) stored; round participation ended." % [
				actor.display_name, BattleMath.REST_EN_RECOVERY, remaining])
		3:
			if not actor.spend_act():
				return
			await _perform_absorption(actor, target)


func _enemy_turn(actor: BattleUnit) -> void:
	if not actor.spend_act():
		return
	var target := _player_with_most_sp()
	if target == null:
		return
	_append_log("%s announces an attack on %s." % [actor.display_name, target.display_name])
	var reaction_declared := await _maybe_player_reaction(target, actor)
	if not target.is_alive():
		return
	# D-022: no declared reaction means the enemy attack is guaranteed to hit,
	# whether the player had no acts or simply chose not to react.
	await _perform_attack(actor, target, 100, false, reaction_declared,
			not reaction_declared)


## One attack, from declaration to state update. Input ownership is explicit:
## only a player-controlled attacker/defender uses the visible rhythm bar.
func _perform_attack(attacker: BattleUnit, defender: BattleUnit, power: int,
		is_reaction: bool, defense_act_paid: bool = false,
		auto_hit: bool = false) -> void:
	if not defender.is_alive():
		return
	var duration := BattleMath.rhythm_duration(attacker.stats.agi, defender.stats.agi,
		attacker.current_sp, defender.current_sp)

	var attack_timing := await _attack_timing(attacker, defender, duration, auto_hit)
	var defense_timing := await _defense_timing(defender, attacker, duration, defense_act_paid)

	# No contact: skip damage, crit, affinity and SP rolls entirely. This also
	# avoids consuming random numbers for an outcome already determined.
	var contact := BattleMath.has_contact(attack_timing, defense_timing)
	if not contact:
		_append_log("%s -> %s: 0 dmg (rhythm %s, def %s, NO CONTACT)" % [
			attacker.display_name, defender.display_name,
			_rhythm_name(attack_timing), _rhythm_name(defense_timing)])
		_flash_feedback("DODGE" if defense_timing == BattleMath.RhythmResult.POINT else "MISS")
		return

	var result := BattleMath.physical_damage(power, attacker.stats.atk, attacker.stats.agi,
		defender.stats.defense, attacker.current_sp, defender.current_sp,
		defender.affinity, rng)

	var amount := int(result.amount)
	if attack_timing == BattleMath.RhythmResult.BEAM \
		or defense_timing == BattleMath.RhythmResult.BEAM:
		amount = int(float(amount) * 0.5)

	var applied := defender.take_damage(amount)
	# Press Turn applies to a landed hit, not to a miss or a perfect dodge.
	attacker.grant_acts(BattleMath.press_turn_acts(defender.affinity))
	if bool(result.crit):
		attacker.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	if defender.affinity == BattleMath.Affinity.WEAK and applied > 0:
		attacker.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	if is_reaction:
		attacker.add_sp(BattleMath.SP_GAIN_PER_EVENT)

	var outcome := "FULL"
	if defense_timing == BattleMath.RhythmResult.BEAM \
		or attack_timing == BattleMath.RhythmResult.BEAM:
		outcome = "BLOCK"
	if bool(result.crit):
		outcome += " CRITICAL"
	_flash_feedback(outcome)

	_append_log("%s -> %s: %d dmg (%s, rhythm %s, def %s, crit %s, affinity %s, SP roll %+d)" % [
		attacker.display_name, defender.display_name, applied, outcome,
		_rhythm_name(attack_timing), _rhythm_name(defense_timing),
		"YES" if bool(result.crit) else "no", _affinity_name(defender.affinity),
		int(result.sp_roll)])


func _attack_timing(attacker: BattleUnit, defender: BattleUnit, duration: float,
		auto_hit: bool = false) -> int:
	if attacker.is_player:
		var point_half := BattleMath.point_half_width(attacker.stats.agi,
			defender.stats.agi, attacker.current_sp, defender.current_sp)
		return await _manual_rhythm(duration, point_half)
	# D-014/D-022: without a declared reaction the hit is guaranteed. POINT is a
	# normal landed hit — it grants no automatic critical and no extra bonus.
	if auto_hit:
		return BattleMath.RhythmResult.POINT
	# AI resolves its own timing; no human input is requested for an enemy attack.
	return _ai_roll(attacker, defender)


func _defense_timing(defender: BattleUnit, attacker: BattleUnit, duration: float,
		act_paid: bool) -> int:
	if defender.is_player:
		if not act_paid:
			return BattleMath.RhythmResult.MISS
		var point_half := BattleMath.point_half_width(defender.stats.agi,
			attacker.stats.agi, defender.current_sp, attacker.current_sp)
		return await _manual_rhythm(duration, point_half)
	# AI defense is resolved locally and spends one of its own acts.
	return _defender_reaction(defender, attacker)


func _manual_rhythm(duration: float, point_half: float) -> int:
	rhythm.configure(point_half)
	rhythm.start(duration)
	return await _wait_rhythm()


## D-035: the AI rolls a position on the same bar the player sees, so AGI and
## SP change its POINT width too. Extra attempts still come only from the
## documented SP block-roll rule; AGI no longer grants extra attempts.
func _zone_roll(point_half: float) -> int:
	return BattleMath.rhythm_zone(rng.randf_range(0.0, 1.0), point_half)


func _ai_roll(attacker: BattleUnit, defender: BattleUnit) -> int:
	var point_half := BattleMath.point_half_width(attacker.stats.agi,
		defender.stats.agi, attacker.current_sp, defender.current_sp)
	var advantage := attacker.current_sp - defender.current_sp
	var rolls := BattleMath.extra_block_rolls(advantage) + 1
	for _i in rolls:
		var result := _zone_roll(point_half)
		if result != BattleMath.RhythmResult.MISS:
			return result
	return BattleMath.RhythmResult.MISS


func _maybe_player_reaction(defender: BattleUnit, attacker: BattleUnit) -> bool:
	if defender.acts_available <= 0:
		return false
	_feedback_token += 1
	reaction_label.text = "REACT to %s? Press Z" % attacker.display_name
	_reaction_active = true
	_reaction_yes = false
	await get_tree().create_timer(0.8).timeout
	_reaction_active = false
	reaction_label.text = ""
	if not _reaction_yes or not defender.spend_act():
		return false
	_append_log("%s reacts to %s (1 act spent)." % [
		defender.display_name, attacker.display_name])
	return true


func _defender_reaction(defender: BattleUnit, attacker: BattleUnit) -> int:
	if defender.acts_available <= 0:
		return BattleMath.RhythmResult.MISS
	var point_half := BattleMath.point_half_width(defender.stats.agi,
		attacker.stats.agi, defender.current_sp, attacker.current_sp)
	var advantage := defender.current_sp - attacker.current_sp
	var rolls := BattleMath.extra_block_rolls(advantage) + 1
	for _i in rolls:
		var result := _zone_roll(point_half)
		if result != BattleMath.RhythmResult.MISS:
			defender.spend_act()
			return result
	return BattleMath.RhythmResult.MISS


func _flash_feedback(text: String) -> void:
	_feedback_token += 1
	var token := _feedback_token
	reaction_label.text = text
	await get_tree().create_timer(0.7).timeout
	if _feedback_token == token and reaction_label.text == text:
		reaction_label.text = ""


func _perform_absorption(actor: BattleUnit, target: BattleUnit) -> void:
	if not actor.is_fallen:
		_append_log("ABSORB failed: only Fallen can absorb.")
		return
	if target.absorbed:
		_append_log("ABSORB failed: %s was already absorbed." % target.display_name)
		return
	if not target.is_alive():
		_append_log("ABSORB failed: %s is already defeated." % target.display_name)
		return
	_append_log("ABSORPTION: mash Z / ENTER!")
	_mash_active = true
	_mash_count = 0
	for _i in 20:
		await get_tree().create_timer(0.1).timeout
	_mash_active = false

	# Zero presses means no success. The previous clamp awarded +1 for free.
	var success := clampi(_mash_count / 4, 0, 3)
	if success <= 0:
		_append_log("ABSORB failed: no input.")
		_flash_feedback("ABSORB FAILED")
		return

	var stat_name := target.stats.highest_combat_stat()
	var gained: int = rng.randi_range(1, success)
	match stat_name:
		&"atk":
			actor.stats.atk += gained
		&"mak":
			actor.stats.mak += gained
		&"defense":
			actor.stats.defense += gained
		&"mef":
			actor.stats.mef += gained
		&"agi":
			actor.stats.agi += gained
	actor.stats.max_hp += gained
	actor.stats.max_en += gained
	actor.current_hp = mini(actor.stats.max_hp, actor.current_hp + gained)
	actor.current_en = mini(actor.stats.max_en, actor.current_en + gained)
	actor.restore_sp()
	# D-028: persist the acquired stat deltas for the next battle.
	_progress_gains[String(stat_name)] = int(_progress_gains.get(String(stat_name), 0)) + gained
	_progress_gains["max_hp"] = int(_progress_gains.get("max_hp", 0)) + gained
	_progress_gains["max_en"] = int(_progress_gains.get("max_en", 0)) + gained
	ProgressStore.save_gains(_progress_gains)
	target.consume_by_absorption()
	_flash_feedback("ABSORBED")
	_append_log("Absorbed %d %s (+HP/+EN); %s eliminated; SP base %d." % [
		gained, stat_name, target.display_name, actor.sp_base()])


func _wait_command(options: Array[String]) -> int:
	for child in command_box.get_children():
		child.queue_free()
	for i in options.size():
		var frame := BattleWidgets.window_frame(Vector2(i * 44, 0), Vector2(42, 40))
		command_box.add_child(frame)
		var button := Button.new()
		button.text = options[i]
		button.position = Vector2(i * 44 + 2, 2)
		button.size = Vector2(38, 36)
		button.flat = true
		button.add_theme_font_size_override("font_size", 9)
		button.add_theme_color_override("font_color", Color(0.93, 0.94, 0.90))
		button.pressed.connect(_on_command_pressed.bind(i))
		command_box.add_child(button)
	_chosen = -1
	await command_chosen
	for child in command_box.get_children():
		child.queue_free()
	return _chosen


func _on_command_pressed(index: int) -> void:
	_chosen = index
	command_chosen.emit()


func _wait_rhythm() -> int:
	_rhythm_result = BattleMath.RhythmResult.MISS
	await rhythm_done
	return _rhythm_result


func _on_rhythm_finished(result: int) -> void:
	_rhythm_result = result
	rhythm_done.emit()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		var confirm := key.keycode == KEY_Z or key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER
		if _mash_active and confirm:
			_mash_count += 1
			accept_event()
		elif _reaction_active and confirm:
			_reaction_yes = true
			accept_event()


func _first_alive_enemy() -> BattleUnit:
	for unit in state.units:
		if not unit.is_player and unit.is_alive():
			return unit
	return null


func _player_with_most_sp() -> BattleUnit:
	var best: BattleUnit = null
	for unit in state.units:
		if unit.is_player and unit.is_alive():
			if best == null or unit.current_sp > best.current_sp:
				best = unit
	return best


func _strongest_enemy_sp() -> int:
	var best := 0
	for unit in state.units:
		if not unit.is_player and unit.is_alive():
			best = maxi(best, unit.current_sp)
	return best


func _refresh_all() -> void:
	round_label.text = "ROUND %d   (acts A=%d / Ally=%d)" % [
		state.round_number, _fallen.acts_available, _ally.acts_available]
	for i in enemy_cards.size():
		enemy_cards[i].refresh(state.units[2 + i])
	ally_rows[0].refresh(_fallen)
	ally_rows[1].refresh(_ally)
	_refresh_sp_bar()


func _refresh_sp_bar() -> void:
	var enemy_sp := _strongest_enemy_sp()
	var total := maxi(1, _fallen.current_sp + enemy_sp)
	var fallen_ratio := float(_fallen.current_sp) / float(total)
	var foe_ratio := float(enemy_sp) / float(total)
	fallen_fill.position = Vector2(0, 136 * (1.0 - fallen_ratio))
	fallen_fill.size = Vector2(26, 136 * fallen_ratio)
	foe_fill.position = Vector2(0, 0)
	foe_fill.size = Vector2(26, 136 * foe_ratio)
	sp_caption.text = "SP %d / %d" % [_fallen.current_sp, enemy_sp]


func _append_log(text: String) -> void:
	log_label.text = text
	log_history.append(text)


func _rhythm_name(result: int) -> String:
	match result:
		BattleMath.RhythmResult.POINT:
			return "POINT"
		BattleMath.RhythmResult.BEAM:
			return "BEAM"
		_:
			return "MISS"


func _affinity_name(affinity: BattleMath.Affinity) -> String:
	match affinity:
		BattleMath.Affinity.WEAK:
			return "WEAK"
		BattleMath.Affinity.RESIST:
			return "RESIST"
		BattleMath.Affinity.NULL:
			return "NULL"
		BattleMath.Affinity.ABSORB:
			return "ABSORB"
		_:
			return "NORMAL"


func _show_result() -> void:
	for child in command_box.get_children():
		child.queue_free()
	_append_log("VICTORY." if state.player_victory() else "DEFEAT.")
