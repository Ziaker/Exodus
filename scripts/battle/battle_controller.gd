extends Control

## Combate em primeira pessoa. A unica arte na cena e o oponente e o fundo;
## todo o HUD e desenhado em codigo, sem imagens da fangame.
## A logica de combate permanece a do primeiro slice.

signal command_chosen
signal rhythm_done
## D-103: wakes the absorption mash loop (every frame, or at once by the 10th press).
signal _mash_wake

const BATTLEBACK := "res://assets/graphics/parallaxes/BB01-001.png"
const ENEMY_SPRITES := [
	"res://assets/graphics/battle_sprites/Avatar Anubis.png",
	"res://assets/graphics/battle_sprites/Avatar Chimera.png",
]
const ENEMY_NAMES: Array[String] = ["GENETIC FOE A", "GENETIC FOE B"]
const ENEMY_KINDS: Array[StringName] = [&"genetic_foe_a", &"genetic_foe_b"]

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
var _planned: Array[int] = []
var _plan_cursor: int = 0
var _plan_active: bool = false
var _plan_options: Array[String] = []
var plan_label: Label
var plan_markers: Array[ColorRect] = []
var plan_buttons: Array[Button] = []
var _rhythm_result: int = BattleMath.RhythmResult.MISS
var _reaction_yes: bool = false
var _reaction_active: bool = false
var _mash_active: bool = false
var _mash_count: int = 0
## D-103: mash bookkeeping (letters already shown, who absorbs whom, wake-up signal).
var _mash_shown: int = 0
var _mash_actor: BattleUnit
var _mash_target: BattleUnit
## D-051: chance of the latest absorption roll, in percent (HUD feedback).
var absorb_chance: int = 0
## Label of the gain taken by the last successful absorption (e.g. "+2 ATK").
var absorb_gain_label := ""
## Creator 2026-11-23: counter shown under the gain ("3/4", "4/4" or "MAX") and,
## when the 4th absorption teaches a skill, "NEW SKILL: <name>" (else empty).
var absorb_count_label := ""
var absorb_skill_label := ""
var _absorb_counts: Dictionary = {}
var _feedback_token: int = 0
var _progress_gains: Dictionary = {}
## Saved gains applied to Fallen. Creator 2026-11-23: Fallen's death halves the saved
## gains instead of the old base-attribute restart (2026-11-21), so this stays true.
var apply_saved_gains := true
## Survival mode sets this to false so absorptions/PP never write to ProgressStore.
var persist_progress := true
## Potência do ataque básico (sem habilidade). D-031 / D-057 (criador 2026-11-25): o jogo
## principal usa poder 8 (antes 100, que matava quase tudo num golpe). O modo Survival
## usa 10 para caber nos status do seu próprio elenco.
var basic_power := 8
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


## Creator 2026-11-24 (fixes D-055): battles and their cutscenes are laid out at 544 x 416
## and shown 1.5x on the 816 x 624 screen. The window's content scale switches while the
## battle is in the tree (fractional, so 1.5x; text is rendered at the real size).
const LAYOUT_SCALE := preload("res://scripts/core/layout_scale.gd")
var _saved_scale := {}


func _enter_tree() -> void:
	_saved_scale = LAYOUT_SCALE.use(get_tree().root)


func _exit_tree() -> void:
	LAYOUT_SCALE.restore(get_tree().root, _saved_scale)


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
		row.setup("FALLEN" if i == 0 else "Yoch")
		add_child(row)
		ally_rows.append(row)

	var command_frame := BattleWidgets.window_frame(Vector2(352, 268), Vector2(184, 140))
	add_child(command_frame)
	command_box = HBoxContainer.new()
	command_box.position = Vector2(360, 274)
	command_box.add_theme_constant_override("separation", 2)
	add_child(command_box)

	# D-046: planned ACT markers stay green until their command resolves.
	plan_label = BattleWidgets.styled_label("PLAN: -", 9)
	plan_label.position = Vector2(360, 244)
	plan_label.size = Vector2(184, 16)
	add_child(plan_label)
	for i in BattleMath.MAX_AVAILABLE_ACTS:
		var marker := ColorRect.new()
		marker.color = Color(0.18, 0.20, 0.18, 1.0)
		marker.position = Vector2(360 + i * 42, 260)
		marker.size = Vector2(36, 6)
		add_child(marker)
		plan_markers.append(marker)

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
	# Creator 2026-11-23: learned skills are permanent, even after a defeat restart.
	_fallen.skills = ProgressStore.load_skills()
	_absorb_counts = ProgressStore.load_absorbs()

	var ally_stats := UnitStats.new()
	ally_stats.max_hp = 11
	# D-048 (creator 2026-11-23): Yoch is human, has no EN (SP base 29) and prays with PP,
	# +2 SP per current PP; unspent PP persist between battles (a defeat zeroes them).
	ally_stats.max_en = 0
	ally_stats.atk = 5
	ally_stats.mak = 2
	ally_stats.defense = 4
	ally_stats.mef = 2
	ally_stats.agi = 5
	_ally = BattleUnit.new(&"ally", "Yoch", ally_stats, true)
	_ally.race = &"human"
	_ally.start_praying(ProgressStore.load_pp())

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
		enemy.kind = ENEMY_KINDS[i]
		enemy.skills = SkillBook.skills_of(enemy.kind)
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
	if not actor.is_fallen:
		var choice := await _wait_command(["ATTACK", "ITEM", "REST"])
		if choice < 0:
			return
		await _execute_player_command(actor, choice, false)
		return

	# D-046: Fallen plans a sequence of up to four committed acts before any
	# command resolves. Green markers show what is already planned.
	var options: Array[String] = ["ATTACK", "ITEM", "REST", "ABSORB"]
	var max_acts := mini(BattleMath.MAX_AVAILABLE_ACTS, actor.acts_available)
	_planned.clear()
	while _planned.size() < max_acts:
		_refresh_plan_display()
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
		if choice == 2:  # REST ends participation immediately
			break

	var chain_used := false
	for i in _planned.size():
		if not actor.is_alive():
			break
		var chain := false
		if _planned[i] == 0:
			for j in range(i + 1, _planned.size()):
				if _planned[j] == 0:
					chain = true
					break
		chain_used = chain_used or chain
		await _execute_player_command(actor, _planned[i], chain)
	_clear_plan_display()
	if chain_used:
		rhythm.stop_chain()


func _execute_player_command(actor: BattleUnit, choice: int, chain: bool) -> void:
	var target := _first_alive_enemy()
	if target == null:
		return
	_append_log("%s acts." % actor.display_name)
	match choice:
		0:
			if not actor.spend_act():
				return
			await _perform_attack(actor, target, basic_power, false, false, false, chain)
		1:
			if not actor.spend_act():
				return
			var healed := actor.heal(6)
			if actor.is_fallen:
				actor.add_sp(-2)
			_append_log("%s uses item: +%d HP%s." % [
				actor.display_name, healed, " (-2 SP)" if actor.is_fallen else ""])
		2:
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
	await _perform_attack(actor, target, basic_power, false, reaction_declared,
			not reaction_declared)


## One attack, from declaration to state update. Input ownership is explicit:
## only a player-controlled attacker/defender uses the visible rhythm bar.
func _perform_attack(attacker: BattleUnit, defender: BattleUnit, power: int,
		is_reaction: bool, defense_act_paid: bool = false,
		auto_hit: bool = false, chain: bool = false) -> void:
	if not defender.is_alive():
		return
	var duration := BattleMath.rhythm_duration(attacker.stats.agi, defender.stats.agi,
		attacker.current_sp, defender.current_sp)

	var attack_timing := await _attack_timing(attacker, defender, duration, auto_hit, chain)
	var defense_timing := await _defense_timing(defender, attacker, duration, defense_act_paid)
	_apply_strike(attacker, defender, power, is_reaction, attack_timing, defense_timing)


## D-106: modifiers of the hit being resolved, set by the skill code just before it
## ("pierce": share of DEF ignored, "mult": extra damage multiplier) and cleared by it after.
var _hit_mods: Dictionary = {}


## Damage, Press Turn and SP rewards of one strike whose timings are already known.
## Shared by the single rail and by the D-049 counter-attack exchange.
## Returns the HP removed, or -1 when there was no contact.
func _apply_strike(attacker: BattleUnit, defender: BattleUnit, power: int,
		is_reaction: bool, attack_timing: int, defense_timing: int, magic: bool = false) -> int:
	if not defender.is_alive():
		return -1
	# No contact: skip damage, crit, affinity and SP rolls entirely. This also
	# avoids consuming random numbers for an outcome already determined.
	var contact := BattleMath.has_contact(attack_timing, defense_timing)
	if not contact:
		_append_log("%s -> %s: 0 dmg (rhythm %s, def %s, NO CONTACT)" % [
			attacker.display_name, defender.display_name,
			_rhythm_name(attack_timing), _rhythm_name(defense_timing)])
		_flash_feedback("DODGE")  # D-109: só o centro da defesa evita contato
		return -1

	# Creator 2026-11-23: magic = same formula with MAK/MEF; IGNI is normal (x1) for
	# everyone until elemental affinities exist. ATK stages raise physical ATK only.
	var affinity: BattleMath.Affinity = BattleMath.Affinity.NORMAL if magic else defender.affinity
	var defence_stat: int = defender.stats.mef if magic else defender.stats.defense
	var pierce := float(_hit_mods.get("pierce", 0.0))
	if pierce > 0.0:
		defence_stat = maxi(1, int(round(float(defence_stat) * (1.0 - pierce))))
	var result: Dictionary
	if bool(_hit_mods.get("prayer_base", false)):
		# D-107 CHERAV: the prayer formula (10 + MAK - MEF), like Ra'am.
		result = PrayerBook.raam_damage(0, attacker.stats.mak, attacker.stats.agi, defender.stats.mef,
			attacker.current_sp, defender.current_sp, affinity, defender.race, rng)
	else:
		result = BattleMath.physical_damage(power,
			float(attacker.stats.mak) if magic else attacker.effective_atk(), attacker.stats.agi,
			defence_stat, attacker.current_sp, defender.current_sp,
			affinity, rng)

	# D-109: the attack mark scales the hit (white 50%, grey 80%, yellow 100%; side defence halves).
	var amount := BattleMath.scaled_damage(int(result.amount), attack_timing, defense_timing)
	# D-106: CHILL / WEAKEN on the attacker, MARK on the defender, the skill's own multiplier.
	amount = int(round(float(amount) * SkillFx.out_mult(attacker) * float(_hit_mods.get("mult", 1.0)) * SkillFx.in_mult(defender)))
	SkillFx.consume_attack(attacker)

	var applied := defender.take_damage(amount)
	# Press Turn applies to a landed hit, not to a miss or a perfect dodge.
	attacker.grant_acts(BattleMath.press_turn_acts(affinity))
	if bool(result.crit):
		attacker.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	if affinity == BattleMath.Affinity.WEAK and applied > 0:
		attacker.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	if is_reaction:
		attacker.add_sp(BattleMath.SP_GAIN_PER_EVENT)

	var outcome := "FULL"
	if defense_timing == BattleMath.RhythmResult.BEAM:
		outcome = "BLOCK"
	elif attack_timing != BattleMath.RhythmResult.POINT:
		outcome = "HIT %d%%" % int(round(BattleMath.strike_multiplier(attack_timing, defense_timing) * 100.0))
	if bool(result.crit):
		outcome += " CRITICAL"
	_flash_feedback(outcome)

	_append_log("%s -> %s: %d dmg (%s, rhythm %s, def %s, crit %s, affinity %s, SP roll %+d)" % [
		attacker.display_name, defender.display_name, applied, outcome,
		_rhythm_name(attack_timing), _rhythm_name(defense_timing),
		"YES" if bool(result.crit) else "no", _affinity_name(affinity),
		int(result.sp_roll)])
	return applied


func _attack_timing(attacker: BattleUnit, defender: BattleUnit, duration: float,
		auto_hit: bool = false, chain: bool = false) -> int:
	if attacker.is_player:
		var point_half := BattleMath.unit_point_half(attacker, defender)
		return await _manual_rhythm(duration, point_half, chain)
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
		var point_half := BattleMath.unit_point_half(defender, attacker)
		return await _manual_rhythm(duration, point_half)
	# AI defense is resolved locally and spends one of its own acts.
	return _defender_reaction(defender, attacker)


func _manual_rhythm(duration: float, point_half: float,
		chain: bool = false) -> int:
	rhythm.configure(point_half)
	if chain:
		rhythm.start_chain(duration)
	else:
		rhythm.start(duration)
	return await _wait_rhythm()


## D-035: the AI rolls a position on the same bar the player sees, so AGI and
## SP change its POINT width too. Extra attempts still come only from the
## documented SP block-roll rule; AGI no longer grants extra attempts.
func _zone_roll(point_half: float) -> int:
	return BattleMath.rhythm_zone(rng.randf_range(0.0, 1.0), point_half)


func _ai_roll(attacker: BattleUnit, defender: BattleUnit) -> int:
	var point_half := BattleMath.unit_point_half(attacker, defender)
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
	# D-109: defender custa 1 ACT sempre, dê certo ou não (igual ao jogador).
	defender.spend_act()
	var point_half := BattleMath.unit_point_half(defender, attacker)
	var advantage := defender.current_sp - attacker.current_sp
	var rolls := BattleMath.extra_block_rolls(advantage) + 1
	for _i in rolls:
		var result := _zone_roll(point_half)
		if result != BattleMath.RhythmResult.MISS:
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
	# D-051 (creator, 2026-11-22): the mash is an SP dispute (2 SP per press, up to 10
	# presses, 2 s; chance = max(0, SP gap measured once at the start) + 1% per SP taken;
	# a target drained to 0 SP is absorbed for sure; on failure the SP stays taken).
	# D-103 (creator, 2026-11-25): presses only count; nothing is taken or rolled per
	# press. The result is resolved and applied once, when the 2 s run out or at the
	# 10th press, whichever comes first, with a single roll.
	_append_log("ABSORPTION: mash Z / ENTER!")
	var base_chance: int = maxi(0, actor.current_sp - target.current_sp)
	await _run_absorb_mash(actor, target)
	# Stop if the battle left the tree during the mash.
	if not is_inside_tree(): return
	var result := _resolve_absorb_mash(actor, target, base_chance)
	var presses := int(result.presses)
	var taken := int(result.steal)
	var absorbed := bool(result.absorbed)
	if presses <= 0:
		_append_log("ABSORB failed: no input.")
		_flash_feedback("ABSORB FAILED")
		return
	if not absorbed:
		_append_log("ABSORB failed: %s resisted (%d SP taken, chance %d%%)." % [target.display_name, taken, absorb_chance])
		_flash_feedback("ABSORB FAILED")
		return
	await _on_absorb_break(actor, target)
	if not is_inside_tree(): return
	var options := BattleMath.absorb_gain_options(target.stats)
	var pick: int = await _choose_absorb_gain(options)
	var chosen: Dictionary = options[clampi(pick, 0, options.size() - 1)]
	var gains: Dictionary = chosen["gains"]
	absorb_gain_label = str(chosen.get("label", ""))
	var base_before := actor.sp_base()
	var total := 0
	for stat in gains:
		_add_stat(actor.stats, stat, int(gains[stat]))
		_progress_gains[String(stat)] = int(_progress_gains.get(String(stat), 0)) + int(gains[stat])
		total += int(gains[stat])
	# D-051: +HP and +EN of the same amount as the attribute gain.
	actor.stats.max_hp += total
	actor.stats.max_en += total
	actor.current_hp = mini(actor.stats.max_hp, actor.current_hp + total)
	actor.current_en = mini(actor.stats.max_en, actor.current_en + total)
	actor.add_sp(actor.sp_base() - base_before)
	# D-028: persist the acquired stat deltas for the next battle.
	_progress_gains["max_hp"] = int(_progress_gains.get("max_hp", 0)) + total
	_progress_gains["max_en"] = int(_progress_gains.get("max_en", 0)) + total
	if persist_progress:
		ProgressStore.save_gains(_progress_gains)
	_count_absorption(actor, target)
	target.consume_by_absorption()
	_flash_feedback("ABSORBED")
	_append_log("Absorbed %s (+%d HP/EN) after %d press(es), %d SP taken; %s eliminated; SP base %d." % [
		options[clampi(pick, 0, options.size() - 1)].label, total, presses, taken, target.display_name, actor.sp_base()])


## Creator 2026-11-23: every 4 absorptions of one enemy kind, Fallen learns one random
## skill of that kind he does not know (PP skills never); with none left: MAX.
func _count_absorption(actor: BattleUnit, target: BattleUnit) -> void:
	absorb_skill_label = ""
	var pool := SkillBook.learnable(target.kind, actor.skills)
	if pool.is_empty():
		absorb_count_label = "MAX"
		return
	var key := String(target.kind)
	var count := int(_absorb_counts.get(key, 0)) + 1
	absorb_count_label = "%d/%d" % [count, SkillBook.ABSORBS_PER_SKILL]
	if count >= SkillBook.ABSORBS_PER_SKILL:
		var skill: StringName = pool[clampi(_skill_pick(pool.size()), 0, pool.size() - 1)]
		actor.skills.append(skill)
		absorb_skill_label = "NEW SKILL: " + SkillBook.display_name(skill)
		_append_log("%s learns %s (%d absorptions of %s)." % [actor.display_name,
			SkillBook.display_name(skill), count, target.display_name])
		count = 0
	_absorb_counts[key] = count
	if persist_progress:
		ProgressStore.save_skill_progress(_absorb_counts, actor.skills)


## Overridable by tests: index of the skill learned among the learnable ones.
func _skill_pick(choices: int) -> int:
	return rng.randi_range(0, choices - 1)


func _add_stat(stats: UnitStats, stat: StringName, amount: int) -> void:
	match stat:
		&"atk": stats.atk += amount
		&"mak": stats.mak += amount
		&"defense": stats.defense += amount
		&"mef": stats.mef += amount
		&"agi": stats.agi += amount


## Overridable: one absorption roll in [0, 100), compared with the chance.
func _absorb_roll() -> float:
	return rng.randf_range(0.0, 100.0)


## D-103: one counted mash press (keyboard/HUD input). Counts only while the mash is
## open and plays the D-052 letters at once; the 10th press closes the mash and wakes
## `_run_absorb_mash` in the same call, so the result is applied with that press and no
## later press is counted. Nothing is absorbed per press.
func register_mash_press() -> void:
	if not _mash_active or _mash_count >= BattleMath.ABSORB_MAX_PRESSES:
		return
	_mash_count += 1
	_emit_mash_letters()
	if _mash_count >= BattleMath.ABSORB_MAX_PRESSES:
		_mash_active = false
		_mash_wake.emit()


## D-052 letters for every press counted and not shown yet (also covers `_mash_count`
## written directly by tests/tools).
func _emit_mash_letters() -> void:
	while _mash_shown < mini(_mash_count, BattleMath.ABSORB_MAX_PRESSES):
		_mash_shown += 1
		_on_absorb_press(_mash_actor, _mash_target)


func _on_mash_frame() -> void:
	_mash_wake.emit()


## D-103: the mash window. Returns when the 2 s run out or as soon as 10 presses are
## counted, whichever comes first: woken every frame and, by the 10th press, at once.
## `_mash_count` may also be written directly (tests/tools); it is clamped to 10.
func _run_absorb_mash(actor: BattleUnit, target: BattleUnit) -> void:
	_mash_actor = actor
	_mash_target = target
	_mash_count = 0
	_mash_shown = 0
	_mash_active = true
	var tree := get_tree()
	var timer := tree.create_timer(BattleMath.ABSORB_SECONDS)
	tree.process_frame.connect(_on_mash_frame)
	while true:
		_emit_mash_letters()
		if _mash_count >= BattleMath.ABSORB_MAX_PRESSES or timer.time_left <= 0.0:
			break
		await _mash_wake
		if not is_inside_tree():
			break
	if tree.process_frame.is_connected(_on_mash_frame):
		tree.process_frame.disconnect(_on_mash_frame)
	_mash_active = false
	_mash_count = mini(_mash_count, BattleMath.ABSORB_MAX_PRESSES)


## D-103: applies the mash result once: moves the SP taken (kept on failure, D-051),
## records the chance for the HUD and makes the single roll (only with presses).
func _resolve_absorb_mash(actor: BattleUnit, target: BattleUnit, base_chance: int) -> Dictionary:
	var presses := mini(_mash_count, BattleMath.ABSORB_MAX_PRESSES)
	var roll: float = _absorb_roll() if presses > 0 else 100.0
	var result := BattleMath.absorb_result(target.current_sp, base_chance, presses, roll)
	target.add_sp(-int(result.steal))
	actor.add_sp(int(result.steal))
	absorb_chance = int(result.chance)
	_on_absorb_result(actor, target, result)
	return result


## Overridable presentation hook: the mash result was just applied (SP moved).
func _on_absorb_result(_actor: BattleUnit, _target: BattleUnit, _result: Dictionary) -> void:
	pass


## Overridable presentation hook: one counted mash press (D-052 letters only; since
## D-103 a press moves no SP, the result does).
func _on_absorb_press(_actor: BattleUnit, _target: BattleUnit) -> void:
	pass


## Overridable presentation hook: the absorption succeeded, before the gain choice
## (D-052 hit and break into letters). Awaited by _perform_absorption.
func _on_absorb_break(_actor: BattleUnit, _target: BattleUnit) -> void:
	pass


## Overridable: which gain option the player takes (the playable HUD asks).
func _choose_absorb_gain(_options: Array[Dictionary]) -> int:
	return 0


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


func _command_short(index: int) -> String:
	match index:
		0: return "ATK"
		1: return "ITM"
		2: return "RST"
		3: return "ABS"
	return "-"


func _refresh_plan_display() -> void:
	for i in plan_markers.size():
		plan_markers[i].color = Color(0.20, 0.85, 0.35, 1.0) \
			if i < _planned.size() else Color(0.18, 0.20, 0.18, 1.0)
	var names: Array[String] = []
	for command in _planned:
		names.append(_command_short(command))
	plan_label.text = "PLAN: " + (" > ".join(names) if not names.is_empty() else "-")


func _clear_plan_display() -> void:
	_planned.clear()
	_plan_active = false
	_refresh_plan_display()


func _refresh_plan_cursor() -> void:
	for i in plan_buttons.size():
		var prefix := "> " if i == _plan_cursor else ""
		plan_buttons[i].text = prefix + _command_short(i) if i < 4 \
			else prefix + ("EX" if i == _plan_options.size() - 2 else "UN")


func _wait_plan_command(options: Array[String]) -> int:
	_plan_options = options.duplicate()
	_plan_options.append("EXEC")
	_plan_options.append("UNDO")
	for child in command_box.get_children():
		child.queue_free()
	plan_buttons.clear()
	for i in _plan_options.size():
		var frame := BattleWidgets.window_frame(Vector2(i * 29, 0), Vector2(28, 40))
		command_box.add_child(frame)
		var button := Button.new()
		button.position = Vector2(i * 29 + 1, 2)
		button.size = Vector2(26, 36)
		button.flat = true
		button.add_theme_font_size_override("font_size", 8)
		button.add_theme_color_override("font_color", Color(0.93, 0.94, 0.90))
		button.pressed.connect(_on_command_pressed.bind(i))
		command_box.add_child(button)
		plan_buttons.append(button)
	_plan_cursor = 0
	_chosen = -99
	_plan_active = true
	_refresh_plan_cursor()
	await command_chosen
	_plan_active = false
	for child in command_box.get_children():
		child.queue_free()
	plan_buttons.clear()
	if _chosen == options.size():
		return -2
	if _chosen == options.size() + 1:
		return -3
	return _chosen


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
		if _plan_active:
			if key.keycode == KEY_X:
				_chosen = _plan_options.size() - 2
				command_chosen.emit()
			elif key.keycode == KEY_BACKSPACE:
				_chosen = _plan_options.size() - 1
				command_chosen.emit()
			elif key.keycode == KEY_UP or key.keycode == KEY_LEFT:
				_plan_cursor = (_plan_cursor - 1 + plan_buttons.size()) % maxi(1, plan_buttons.size())
				_refresh_plan_cursor()
			elif key.keycode == KEY_DOWN or key.keycode == KEY_RIGHT:
				_plan_cursor = (_plan_cursor + 1) % maxi(1, plan_buttons.size())
				_refresh_plan_cursor()
			elif confirm:
				_chosen = _plan_cursor
				command_chosen.emit()
			accept_event()
			return
		if _mash_active and confirm:
			register_mash_press()
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
	# D-106 TAUNT: a hero that taunted is the only one foes may attack.
	var heroes: Array = []
	for unit in state.units:
		if unit.is_player: heroes.append(unit)
	var taunter := SkillFx.taunter(heroes)
	if taunter != null:
		return taunter
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
