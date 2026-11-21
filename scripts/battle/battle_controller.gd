extends Control

## Front-view combat prototype styled after the RPG Maker VX Ace battle screen.
## Gameplay logic is unchanged from the first slice; only the presentation layer
## was rebuilt using the fangame's temporary assets.

signal command_chosen
signal rhythm_done

const BATTLEBACK := "res://assets/graphics/parallaxes/BB01-001.png"
const ENEMY_SPRITES := [
	"res://assets/graphics/battlers/Avatar Anubis.png",
	"res://assets/graphics/battlers/Avatar Chimera.png",
]
const ALLY_FACES := "res://assets/graphics/faces/001_daitenshi.png"
const ENEMY_NAMES: Array[String] = ["GENETIC FOE A", "GENETIC FOE B"]

class StatusRow extends Control:
	var name_label: Label
	var number_label: Label
	var hp_gauge: PanelContainer
	var en_gauge: PanelContainer
	var sp_label: Label

	func setup(title: String, face_index: int) -> void:
		var face := TextureRect.new()
		face.texture = BattleWidgets.face_texture(ALLY_FACES, face_index)
		face.custom_minimum_size = Vector2(48, 48)
		face.stretch_mode = TextureRect.STRETCH_SCALE
		face.position = Vector2(6, 6)
		add_child(face)

		name_label = BattleWidgets.styled_label(title, 14)
		name_label.position = Vector2(58, 4)
		name_label.size = Vector2(130, 20)
		add_child(name_label)

		sp_label = BattleWidgets.styled_label("SP 0", 12)
		sp_label.position = Vector2(188, 5)
		sp_label.size = Vector2(120, 18)
		add_child(sp_label)

		hp_gauge = BattleWidgets.gauge(132, 10, Color(0.20, 0.78, 0.36))
		hp_gauge.position = Vector2(58, 27)
		add_child(hp_gauge)

		en_gauge = BattleWidgets.gauge(132, 10, Color(0.25, 0.55, 0.95))
		en_gauge.position = Vector2(58, 43)
		add_child(en_gauge)

		number_label = BattleWidgets.styled_label("", 11)
		number_label.position = Vector2(194, 26)
		number_label.size = Vector2(116, 30)
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
var _fallen: BattleUnit = null
var _ally: BattleUnit = null

class UnitCard extends Control:
	var name_label: Label
	var hp_label: Label
	var hp_gauge: PanelContainer

	func setup(title: String) -> void:
		name_label = BattleWidgets.styled_label(title, 12, HORIZONTAL_ALIGNMENT_CENTER)
		name_label.position = Vector2(0, 0)
		name_label.size = Vector2(120, 20)
		add_child(name_label)
		hp_gauge = BattleWidgets.gauge(96, 7, Color(0.80, 0.28, 0.28))
		hp_gauge.position = Vector2(12, 20)
		add_child(hp_gauge)
		hp_label = BattleWidgets.styled_label("", 10, HORIZONTAL_ALIGNMENT_CENTER)
		hp_label.position = Vector2(0, 28)
		hp_label.size = Vector2(120, 16)
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
	log_label = BattleWidgets.styled_label("Battle start. Front view. SP is the superiority meter.", 14)
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
		row.setup("FALLEN" if i == 0 else "ALLY", i)
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
	var frame := BattleWidgets.window_frame(Vector2(8, 6), Vector2(210, 28))
	add_child(frame)
	round_label = BattleWidgets.styled_label("ROUND 1", 14)
	round_label.position = Vector2(16, 10)
	round_label.size = Vector2(196, 20)
	add_child(round_label)


func _enemy_display() -> void:
	for i in ENEMY_NAMES.size():
		var card := UnitCard.new()
		card.custom_minimum_size = Vector2(120, 46)
		card.position = Vector2(110 + i * 170, 152)
		card.setup(ENEMY_NAMES[i])
		add_child(card)
		enemy_cards.append(card)

		var sprite := TextureRect.new()
		sprite.texture = BattleWidgets.pose_texture(ENEMY_SPRITES[i])
		sprite.custom_minimum_size = Vector2(93, 190)
		sprite.stretch_mode = TextureRect.STRETCH_SCALE
		sprite.position = Vector2(123 + i * 170, 18)
		add_child(sprite)
		enemy_sprites.append(sprite)


func _build_sp_bar() -> void:
	var frame := BattleWidgets.window_frame(Vector2(500, 52), Vector2(38, 152))
	add_child(frame)
	var holder := Control.new()
	holder.position = Vector2(505, 58)
	holder.custom_minimum_size = Vector2(26, 136)
	add_child(holder)
	foe_fill = ColorRect.new()
	foe_fill.color = Color(0.85, 0.25, 0.25, 0.95)
	holder.add_child(foe_fill)
	fallen_fill = ColorRect.new()
	fallen_fill.color = Color(0.30, 0.60, 0.95, 0.95)
	holder.add_child(fallen_fill)
	sp_caption = BattleWidgets.styled_label("SP", 10, HORIZONTAL_ALIGNMENT_CENTER)
	sp_caption.position = Vector2(500, 205)
	sp_caption.size = Vector2(38, 16)
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
	_append_log("Battle start. Front view. SP is the superiority meter.")
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
	if not actor.spend_act():
		return
	_append_log("%s acts." % actor.display_name)
	var target := _first_alive_enemy()
	if target == null:
		return
	var options: Array[String] = ["ATTACK", "ITEM", "REST", "ABSORB"]
	var choice := await _wait_command(options)
	match choice:
		0:
			await _perform_attack(actor, target, 100, false)
		1:
			var healed := actor.heal(6)
			if actor.is_fallen:
				actor.add_sp(-2)
			_append_log("%s uses item: +%d HP%s." % [
				actor.display_name, healed, " (-2 SP)" if actor.is_fallen else ""])
		2:
			if actor.spend_act():
				actor.recover_en(0.2)
				_append_log("%s rests: +20%% EN, action spent." % actor.display_name)
			else:
				_append_log("%s has no act left to rest." % actor.display_name)
		3:
			await _perform_absorption(actor, target)


func _enemy_turn(actor: BattleUnit) -> void:
	if not actor.spend_act():
		return
	var target := _player_with_most_sp()
	if target == null:
		return
	_append_log("%s announces an attack on %s." % [actor.display_name, target.display_name])
	await _maybe_player_reaction(target, actor)
	if not target.is_alive():
		return
	await _perform_attack(actor, target, 100, false)


func _perform_attack(attacker: BattleUnit, defender: BattleUnit, power: int,
		is_reaction: bool) -> void:
	if not defender.is_alive():
		return
	var duration := BattleMath.rhythm_duration(attacker.stats.agi, defender.stats.agi,
		attacker.current_sp, defender.current_sp)
	rhythm.start(duration)
	var attack_timing: int = await _wait_rhythm()

	var defense_timing := BattleMath.RhythmResult.MISS
	if attack_timing == BattleMath.RhythmResult.POINT:
		defense_timing = await _defender_reaction(defender, attacker)
	elif attack_timing == BattleMath.RhythmResult.BEAM:
		defense_timing = BattleMath.RhythmResult.BEAM

	var result := BattleMath.physical_damage(power, attacker.stats.atk, attacker.stats.agi,
		defender.stats.defense, attacker.current_sp, defender.current_sp,
		defender.affinity, rng)

	var amount := int(result.amount)
	if attack_timing == BattleMath.RhythmResult.MISS or defense_timing == BattleMath.RhythmResult.POINT:
		amount = 0
	elif attack_timing == BattleMath.RhythmResult.BEAM or defense_timing == BattleMath.RhythmResult.BEAM:
		amount = int(float(amount) * 0.5)

	var applied := defender.take_damage(amount)
	attacker.grant_acts(BattleMath.press_turn_acts(defender.affinity))
	if bool(result.crit):
		attacker.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	if defender.affinity == BattleMath.Affinity.WEAK and amount > 0:
		attacker.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	if is_reaction:
		attacker.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	if defense_timing == BattleMath.RhythmResult.POINT:
		defender.add_sp(BattleMath.SP_GAIN_PER_EVENT)

	_append_log("%s -> %s: %d dmg (rhythm %s, def %s, crit %s, affinity %s, SP roll %+d)" % [
		attacker.display_name, defender.display_name, applied,
		_rhythm_name(attack_timing), _rhythm_name(defense_timing),
		"YES" if bool(result.crit) else "no", _affinity_name(defender.affinity),
		int(result.sp_roll)])


func _maybe_player_reaction(defender: BattleUnit, attacker: BattleUnit) -> void:
	if defender.acts_available <= 0:
		return
	reaction_label.text = "REACT to %s? Press Z" % attacker.display_name
	_reaction_active = true
	_reaction_yes = false
	await get_tree().create_timer(0.8).timeout
	_reaction_active = false
	reaction_label.text = ""
	if _reaction_yes and defender.spend_act():
		_append_log("%s reacts to %s." % [defender.display_name, attacker.display_name])
		await _perform_attack(defender, attacker, 100, true)


func _defender_reaction(defender: BattleUnit, attacker: BattleUnit) -> int:
	if defender.acts_available <= 0:
		return BattleMath.RhythmResult.MISS
	if defender.is_player:
		return BattleMath.RhythmResult.MISS
	var rolls := BattleMath.extra_block_rolls(defender.current_sp - attacker.current_sp) + 1
	for _i in rolls:
		var roll := rng.randi_range(0, 2)
		if roll == 0:
			defender.spend_act()
			return BattleMath.RhythmResult.POINT
		if roll == 1:
			defender.spend_act()
			return BattleMath.RhythmResult.BEAM
	return BattleMath.RhythmResult.MISS


func _perform_absorption(actor: BattleUnit, target: BattleUnit) -> void:
	_append_log("ABSORPTION: mash Z / ENTER!")
	_mash_active = true
	_mash_count = 0
	for _i in 20:
		await get_tree().create_timer(0.1).timeout
	_mash_active = false
	var success := clampi(_mash_count / 4, 1, 3)
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
	_append_log("Absorbed %d %s (+HP/+EN); SP base recalculated to %d." % [
		gained, stat_name, actor.sp_base()])


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
		button.add_theme_font_override("font", BattleWidgets.make_font(11))
		button.add_theme_font_size_override("font_size", 11)
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
