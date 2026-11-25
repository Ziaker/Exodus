extends "res://scripts/battle/playable_controller.gd"
## Batalha do modo Survival: 1 a 3 demônios SMT da lista de 35, itens compráveis
## (BEAD para HP / CHAKRA para EN) e sistema de 3 continues sem perder metade dos status.
## Nunca lê nem escreve no ProgressStore do jogo principal.

signal item_chosen
signal continue_answered
signal absorb_chosen

var demon_def: Dictionary = {}
## Demônios desta luta (o tocado no mapa + reforços por tier).
var encounter_ids: Array[String] = []
## RNG semeado pela run: mesmas escolhas de absorção para a mesma semente.
var run_rng := RandomNumberGenerator.new()

## Painel largo das 3 recompensas de absorção (a barra de comando é só 132 px).
var absorb_options: Array[Dictionary] = []
var absorb_index := 0
var _absorb_layer: CanvasLayer
var _absorb_panel: Control
var item_ids: Array[String] = []
var _item_choice := -1

var continue_prompt_open := false
var _continue_yes := false
var _continue_layer: CanvasLayer
var _continue_panel: Control
var _survival_gameover := false
var _result_recorded := false
var suppress_scene_change := false
var left_to_title := false


func _init() -> void:
	persist_progress = false
	apply_saved_gains = false
	# Os status do elenco Survival são bem menores que os da campanha: um ataque
	# básico de potência 100 daria 100+ de dano e mataria um demônio ou herói
	# num golpe. Aqui a escala é a mesma das habilidades placeholder (4..11).
	basic_power = 10


func _create_units() -> void:
	var s := SurvivalState.data()
	var gains: Dictionary = s.get("gains", {})
	_progress_gains = gains.duplicate(true)

	var fs := UnitStats.new()
	fs.max_hp = int(SurvivalData.FALLEN_BASE.max_hp) + int(gains.get("max_hp", 0))
	fs.max_en = int(SurvivalData.FALLEN_BASE.max_en) + int(gains.get("max_en", 0))
	fs.atk = int(SurvivalData.FALLEN_BASE.atk) + int(gains.get("atk", 0))
	fs.mak = int(SurvivalData.FALLEN_BASE.mak) + int(gains.get("mak", 0))
	fs.defense = int(SurvivalData.FALLEN_BASE.defense) + int(gains.get("defense", 0))
	fs.mef = int(SurvivalData.FALLEN_BASE.mef) + int(gains.get("mef", 0))
	fs.agi = int(SurvivalData.FALLEN_BASE.agi) + int(gains.get("agi", 0))
	for id in s.get("fallen_relics", []):
		SurvivalRelics.apply(fs, String(id))
	_fallen = BattleUnit.new(&"fallen", "FALLEN", fs, true, true)
	_fallen.current_hp = clampi(int(s.get("fallen_hp", fs.max_hp)), 1, fs.max_hp)
	_fallen.current_en = clampi(int(s.get("fallen_en", fs.max_en)), 0, fs.max_en)
	var saved_skills: Array[StringName] = []
	for sk in s.get("skills", []):
		saved_skills.append(StringName(str(sk)))
	_fallen.skills = saved_skills
	_absorb_counts = (s.get("absorbs", {}) as Dictionary).duplicate(true)

	var ys := UnitStats.new()
	ys.max_hp = int(SurvivalData.YOCH_BASE.max_hp)
	ys.max_en = 0
	ys.atk = int(SurvivalData.YOCH_BASE.atk)
	ys.mak = int(SurvivalData.YOCH_BASE.mak)
	ys.defense = int(SurvivalData.YOCH_BASE.defense)
	ys.mef = int(SurvivalData.YOCH_BASE.mef)
	ys.agi = int(SurvivalData.YOCH_BASE.agi)
	for id in s.get("yoch_relics", []):
		SurvivalRelics.apply(ys, String(id))
	_ally = BattleUnit.new(&"ally", "Yoch", ys, true)
	_ally.race = &"human"
	_ally.start_praying(int(s.get("yoch_pp", SurvivalData.YOCH_BASE.pp)))
	_ally.current_hp = clampi(int(s.get("yoch_hp", ys.max_hp)), 1, ys.max_hp)

	state.add_unit(_fallen)
	state.add_unit(_ally)

	var enc_id := String(s.get("encounter_id", "pixie"))
	# Uma run tem uma semente, mas cada encontro deve sortear uma oferta diferente:
	# deriva por id do encontro, derrotados e continues já gastos.
	var defeated_count: int = (s.get("defeated", []) as Array).size()
	var continues_used: int = SurvivalData.MAX_CONTINUES - int(s.get("continues", SurvivalData.MAX_CONTINUES))
	var derived: int = int(s.get("seed", 1)) + absi(enc_id.hash()) \
			+ defeated_count * 7919 + continues_used * 104729
	run_rng.seed = absi(derived) % 2147483647
	encounter_ids.assign(SurvivalData.encounter_for(enc_id))
	if encounter_ids.is_empty():
		encounter_ids.assign([String(SurvivalData.DEMONS[0].id)])
	demon_def = SurvivalData.demon_by_id(encounter_ids[0])

	# 1 a 3 demônios por luta, conforme o tier do encontrado (ver SurvivalData).
	var paths: Array[String] = []
	for i in encounter_ids.size():
		var def := SurvivalData.demon_by_id(encounter_ids[i])
		if def.is_empty():
			continue
		var ds: Dictionary = def.stats
		var enemy_stats := UnitStats.new()
		enemy_stats.max_hp = int(ds.max_hp)
		enemy_stats.max_en = int(ds.max_en)
		enemy_stats.atk = int(ds.atk)
		enemy_stats.mak = int(ds.mak)
		enemy_stats.defense = int(ds.defense)
		enemy_stats.mef = int(ds.mef)
		enemy_stats.agi = int(ds.agi)
		var elite := SurvivalData.is_elite(int(s.get("seed", 1)), String(def.id))
		if elite:
			enemy_stats.max_hp += 12
			enemy_stats.atk += 3
			enemy_stats.mak += 2
			enemy_stats.defense += 2
		var label := String(def.name)
		if elite:
			label = "ELITE %s [%s]" % [label, SurvivalData.elite_affix(int(s.get("seed", 1)), String(def.id))]
		var enemy := BattleUnit.new(StringName("foe_%d" % i), label, enemy_stats, false)
		enemy.kind = StringName(String(def.id))
		enemy.sprite_path = String(def.picture)
		var enemy_skills: Array[StringName] = []
		for sk in def.skills:
			enemy_skills.append(StringName(sk))
		enemy.skills = enemy_skills
		enemy.affinity = def.affinity
		state.add_unit(enemy)
		paths.append(enemy.sprite_path)

	# O HUD exige Array[String] tipado, não um Array comum.
	hud.set_opponent_sprites(paths)


func _refresh_all() -> void:
	if state.units.size() < 3 or hud == null:
		return
	if state.round_number != _indicator_round:
		_indicator_round = state.round_number
		queued_acts_by_foe.clear()
	hud.players.assign([_fallen, _ally])
	var foes: Array[BattleUnit] = []
	for u in state.units:
		if not u.is_player:
			foes.append(u)
	hud.opponents.assign(foes)
	hud.actor = 0 if active_actor == null or active_actor == _fallen else 1
	hud.queue_redraw()


func short_name(unit: BattleUnit) -> String:
	return unit.display_name if unit != null else ""


func _commands(unit: BattleUnit, reacting: bool = false) -> Array[String]:
	var options := super._commands(unit, reacting)
	if SurvivalState.total_items() <= 0 and options.has("ITEM"):
		options.erase("ITEM")
	return options


# ------------------------------------------------- Skill identification

func skill_label(skill: StringName) -> String:
	var unknown: Array = SurvivalState.data().get("unidentified", [])
	if unknown.has(String(skill)):
		return SurvivalData.hebrew_skill(skill)
	return super.skill_label(skill)


func skill_info(index: int) -> String:
	if index >= 0 and index < skill_ids.size():
		var sk := skill_ids[index]
		var unknown: Array = SurvivalState.data().get("unidentified", [])
		if unknown.has(String(sk)):
			return "UNKNOWN EFFECT — use it once to reveal its name and power."
	return super.skill_info(index)


func submit_skill(index: int) -> void:
	var sk := StringName(skill_ids[index]) if index >= 0 and index < skill_ids.size() else &""
	super.submit_skill(index)
	if sk != &"":
		SurvivalState.identify_skill(sk)
		_append_log("IDENTIFIED: %s" % SkillBook.display_name(sk))
		_event("%s identified." % SkillBook.display_name(sk))


# ------------------------------------------------- Survival items (BEAD / CHAKRA)

func _wait_item_menu() -> String:
	var s := SurvivalState.data()
	var labels: Array[String] = []
	item_ids.clear()
	for entry in SurvivalData.SHOP_ITEMS:
		var id := String(entry.id)
		var count := int(s.get(id, 0))
		if count > 0:
			labels.append("%s x%d" % [String(entry.name), count])
			item_ids.append(id)
	if labels.is_empty():
		return ""
	hud.command_options = labels
	hud.command_index = 0
	hud.mode = "item"
	hud.feedback = "Z: confirm | X: back"
	_item_choice = -2
	_refresh_all()
	await item_chosen
	hud.mode = "busy"
	if _item_choice < 0 or _item_choice >= item_ids.size():
		return ""
	return item_ids[_item_choice]


func item_info(index: int) -> String:
	if index < 0 or index >= item_ids.size():
		return ""
	var def := SurvivalData.shop_item(item_ids[index])
	if def.is_empty():
		return ""
	return "%s: %s" % [String(def.name), String(def.info)]


func submit_item(index: int) -> void:
	if hud.mode != "item" or index < 0 or index >= item_ids.size():
		return
	_item_choice = index
	hud.command_index = index
	hud.press_command(index, "confirm")
	item_chosen.emit()


func cancel_item() -> void:
	if hud.mode == "item":
		_item_choice = -1
		item_chosen.emit()


func _execute_command(unit: BattleUnit, command: String, reacting: bool = false, chain: bool = false, skill: Dictionary = {}, planned: BattleUnit = null) -> bool:
	if command != "ITEM":
		return await super._execute_command(unit, command, reacting, chain, skill, planned)
	var chosen_id := await _wait_item_menu()
	if chosen_id.is_empty():
		return false
	var item_def := SurvivalData.shop_item(chosen_id)
	if item_def.is_empty():
		return false
	phase_text = "SELECT ITEM TARGET"
	var recipient := await _wait_target("player")
	if recipient == null:
		return false
	# Não gasta item nem ato num alvo já cheio: o Macca do vendedor vale.
	var kind := String(item_def.kind)
	var wasted := false
	if kind == "hp":
		wasted = recipient.current_hp >= recipient.stats.max_hp
	elif recipient.prays:
		wasted = recipient.current_pp >= PrayerBook.MAX_PP
	else:
		wasted = recipient.current_en >= recipient.stats.max_en
	if wasted:
		_append_log("%s ignores %s: %s is full; item kept." % [
			unit.display_name, String(item_def.name), recipient.display_name])
		hud.feedback = "NO EFFECT — item and ACT kept. Choose another ally or item."
		return false
	# Gasta o ato antes de mexer na bolsa: se não houver ato, o item não some.
	if not unit.spend_act():
		return false
	if not SurvivalState.consume_item(chosen_id):
		unit.grant_acts(1)
		return false
	if reacting: _set_role(unit, "REACT")
	action_attacker = unit
	action_defender = recipient
	phase_text = "REACTION ITEM" if reacting else "ITEM"
	var amount := int(item_def.amount)
	if String(item_def.kind) == "hp":
		var healed := recipient.heal(amount)
		fx.play("HEAL", recipient, healed)
		if unit.is_fallen:
			unit.add_sp(-2)
		_append_log("%s uses %s on %s: +%d HP%s." % [
			unit.display_name, String(item_def.name), recipient.display_name, healed,
			" (-2 SP)" if unit.is_fallen else ""])
		_event("%s uses %s on %s: +%d HP." % [short_name(unit), String(item_def.name), short_name(recipient), healed])
		hud.feedback = "%s: HP %d/%d | 1 ACT spent" % [recipient.display_name, recipient.current_hp, recipient.stats.max_hp]
	else:
		if recipient.prays:
			var gained := recipient.change_pp(2)
			fx.play("REST", recipient, gained)
			_append_log("%s uses %s on %s: +%d PP." % [unit.display_name, String(item_def.name), recipient.display_name, gained])
			_event("%s uses %s on %s: +%d PP." % [short_name(unit), String(item_def.name), short_name(recipient), gained])
			hud.feedback = "%s: PP %d/%d | 1 ACT spent" % [recipient.display_name, recipient.current_pp, PrayerBook.MAX_PP]
		else:
			var before := recipient.current_en
			recipient.recover_en_flat(amount)
			var gained := recipient.current_en - before
			fx.play("REST", recipient, gained)
			if unit.is_fallen:
				unit.add_sp(-2)
			_append_log("%s uses %s on %s: +%d EN%s." % [
				unit.display_name, String(item_def.name), recipient.display_name, gained,
				" (-2 SP)" if unit.is_fallen else ""])
			_event("%s uses %s on %s: +%d EN." % [short_name(unit), String(item_def.name), short_name(recipient), gained])
			hud.feedback = "%s: EN %d/%d | 1 ACT spent" % [recipient.display_name, recipient.current_en, recipient.stats.max_en]
	if reacting:
		unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
	_refresh_all()
	return true


func handle_confirm() -> void:
	if continue_prompt_open:
		answer_continue(true)
		return
	# O HUD é filho do controller e marca o evento como handled no _input dele;
	# por isso o _input() deste script nunca recebe as teclas no jogo real.
	# Toda confirmação precisa passar por aqui (o caminho que o HUD usa).
	if hud != null and hud.mode == "absorb_choice":
		submit_absorb_choice(absorb_index)
		return
	if hud.mode == "item":
		submit_item(hud.command_index)
		return
	super.handle_confirm()


func handle_back() -> void:
	if continue_prompt_open:
		answer_continue(false)
		return
	if hud != null and hud.mode == "absorb_choice":
		submit_absorb_choice(0)
		return
	if hud.mode == "item":
		hud.press_command(hud.command_index, "reject")
		cancel_item()
		return
	super.handle_back()


# ------------------------------------------------- Roguelike absorption

## A rolagem de sucesso também vem do RNG da run (não do rng global da batalha),
## para que a mesma run/progresso reproduza o mesmo resultado.
func _absorb_roll() -> float:
	return run_rng.randf() * 100.0

## Regra própria do Survival: 30% de uma habilidade nova; sempre 3 opções na
## mesma barra de comandos; atributo sorteado vale 1..4 pontos. Nada disso
## escreve no ProgressStore da campanha.
func _perform_absorption(unit: BattleUnit, defender: BattleUnit) -> void:
	if not unit.is_fallen or hud == null or not is_instance_valid(hud):
		return
	hud.mode = "absorb"
	hud.announce("ABSORB")
	var was_absorbed := defender.absorbed
	_append_log("ABSORPTION: mash Z / ENTER!")
	# D-063 (criador, 2026-11-25): os apertos só contam; o resultado (SP tirado e um
	# único sorteio) é aplicado uma vez, ao acabar o tempo ou no 10º aperto.
	var base_chance: int = maxi(0, unit.current_sp - defender.current_sp)
	await _run_absorb_mash(unit, defender)
	if not is_inside_tree():
		return
	var result := _resolve_absorb_mash(unit, defender, base_chance)
	var presses := int(result.presses)
	var taken := int(result.steal)
	var absorbed := bool(result.absorbed)
	if presses <= 0:
		_append_log("ABSORB failed: no input.")
		_event("%s resists the absorption." % short_name(defender))
		_flash_feedback("ABSORB FAILED")
		hud.mode = "busy"
		return
	if not absorbed:
		_append_log("ABSORB failed: %s resisted (%d SP taken, chance %d%%)." % [
			defender.display_name, taken, absorb_chance])
		_event("%s resists the absorption." % short_name(defender))
		_flash_feedback("ABSORB FAILED")
		hud.mode = "busy"
		return
	await _on_absorb_break(unit, defender)
	if not is_inside_tree():
		return

	var demon := SurvivalData.demon_by_id(String(defender.kind))
	var owned: Array[StringName] = []
	for sk in _fallen.skills:
		owned.append(sk)
	var hp_share := float(unit.current_hp) / float(maxi(1, unit.stats.max_hp))
	var options := SurvivalAbsorb.roll_options(run_rng, demon, owned, hp_share)
	var pick: int = await _wait_absorb_choice(options)
	pick = clampi(pick, 0, options.size() - 1)
	var chosen: Dictionary = options[pick]
	var owned_before: Array[StringName] = owned.duplicate()
	var base_before := unit.sp_base()
	SurvivalAbsorb.apply_option(unit.stats, _progress_gains, _fallen.skills, chosen)
	unit.add_sp(unit.sp_base() - base_before)
	absorb_gain_label = String(chosen.label)
	absorb_count_label = "RUN"
	absorb_skill_label = ""
	if String(chosen.get("kind", "")) == "skill":
		absorb_skill_label = "NEW SKILL: " + SkillBook.display_name(StringName(chosen.get("skill", &"")))
	var skill_names: Array[String] = []
	for sk in _fallen.skills:
		skill_names.append(String(sk))
	var unknown: Array = SurvivalState.data().get("unidentified", []).duplicate()
	if String(chosen.get("kind", "")) == "skill":
		var learned := StringName(chosen.get("skill", &""))
		if not owned_before.has(learned) and not unknown.has(String(learned)):
			unknown.append(String(learned))
	SurvivalState.patch({
		"gains": _progress_gains.duplicate(true),
		"skills": skill_names,
		"unidentified": unknown,
	})
	defender.consume_by_absorption()
	if not was_absorbed and defender.absorbed:
		fx.play("ABSORBED", unit)
		fx.label_override(unit, ["ABSORBED", absorb_gain_label, absorb_count_label, absorb_skill_label],
				hud.enemy_sprite_rect(hud.opponents.find(defender)), ABSORBED_INK)
	_flash_feedback("ABSORBED")
	_append_log("Absorbed %s: %s (%d presses, %d SP taken); %s eliminated." % [
		defender.display_name, absorb_gain_label, presses, taken, defender.display_name])
	_event("%s absorbs %s: %s." % [short_name(unit), short_name(defender), absorb_gain_label])
	hud.mode = "busy"


# ------------------------------------------------- Absorption reward panel

func _wait_absorb_choice(options: Array[Dictionary]) -> int:
	absorb_options = options.duplicate(true)
	absorb_index = 0
	# A mensagem de seleção de alvo ficava presa no log durante a recompensa.
	hud.message = ""
	hud.mode = "absorb_choice"
	if is_inside_tree():
		_show_absorb_overlay()
		await absorb_chosen
		_hide_absorb_overlay()
	var chosen := absorb_index
	absorb_options.clear()
	return chosen


func move_absorb_cursor(delta: int) -> void:
	if hud == null or hud.mode != "absorb_choice" or absorb_options.is_empty():
		return
	absorb_index = posmod(absorb_index + delta, absorb_options.size())
	if _absorb_panel != null:
		_absorb_panel.queue_redraw()


func submit_absorb_choice(index: int) -> void:
	if hud == null or hud.mode != "absorb_choice":
		return
	absorb_index = clampi(index, 0, absorb_options.size() - 1)
	absorb_chosen.emit()


func _input(event: InputEvent) -> void:
	if hud == null or not is_instance_valid(hud) or hud.mode != "absorb_choice" or not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_LEFT, KEY_UP:
			move_absorb_cursor(-1)
		KEY_RIGHT, KEY_DOWN:
			move_absorb_cursor(1)
		KEY_Z, KEY_ENTER, KEY_KP_ENTER:
			submit_absorb_choice(absorb_index)
		KEY_X, KEY_ESCAPE:
			submit_absorb_choice(0)
		_:
			return
	get_viewport().set_input_as_handled()


func _show_absorb_overlay() -> void:
	_hide_absorb_overlay()
	_absorb_layer = CanvasLayer.new()
	_absorb_layer.layer = 61
	_absorb_panel = Control.new()
	_absorb_panel.name = "AbsorbReward"
	_absorb_panel.size = HUD_SCRIPT.SCREEN
	_absorb_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_absorb_panel.draw.connect(_draw_absorb_overlay)
	_absorb_layer.add_child(_absorb_panel)
	add_child(_absorb_layer)
	_absorb_panel.queue_redraw()


func _hide_absorb_overlay() -> void:
	if _absorb_layer != null:
		_absorb_layer.queue_free()
	_absorb_layer = null
	_absorb_panel = null


## Mesmo retângulo usado para desenhar e para o clique do mouse no HUD.
func absorb_option_rect(index: int) -> Rect2:
	var count := maxi(1, absorb_options.size())
	var bounds := Rect2(20, 118, 504, 118)
	var margin := 10.0
	var gap := 6.0
	var cell_w := (bounds.size.x - margin * 2.0 - gap * float(count - 1)) / float(count)
	return Rect2(bounds.position.x + margin + float(index) * (cell_w + gap),
			bounds.position.y + 34.0, cell_w, 62.0)


## Puro (testável sem janela): qual opção está sob este ponto do HUD.
func absorb_option_at(point: Vector2) -> int:
	for i in absorb_options.size():
		if absorb_option_rect(i).has_point(point):
			return i
	return -1


func _draw_absorb_overlay() -> void:
	if _absorb_panel == null or absorb_options.is_empty():
		return
	var bounds := Rect2(20, 118, 504, 118)
	_absorb_panel.draw_rect(Rect2(Vector2.ZERO, HUD_SCRIPT.SCREEN), Color(0.02, 0.01, 0.03, 0.72))
	_absorb_panel.draw_rect(bounds, Color(0.06, 0.03, 0.05, 0.98))
	_absorb_panel.draw_rect(bounds, Color("81e6a8"), false, 1.5)
	var bold: Font = hud.ui_bold
	_draw_centered(_absorb_panel, bold, "ABSORPTION REWARD — choose 1 of 3",
			bounds.get_center().x, bounds.position.y + 20, 13, Color("81e6a8"))
	var count := absorb_options.size()
	for i in count:
		var rect := absorb_option_rect(i)
		var active := i == absorb_index
		_absorb_panel.draw_rect(rect, Color(1, 1, 1, 0.16) if active else Color(1, 1, 1, 0.04))
		_absorb_panel.draw_rect(rect, Color.WHITE if active else Color(1, 1, 1, 0.32),
				false, 1.5 if active else 1.0)
		var text := ("> " if active else "  ") + String(absorb_options[i].label)
		var font_px := 11 if String(absorb_options[i].label).length() > 13 else 13
		_draw_centered(_absorb_panel, hud.ui_font, text, rect.get_center().x,
				rect.position.y + 40.0, font_px, Color.WHITE if active else Color("f7f3ed"))
	_draw_centered(_absorb_panel, bold, "Z / Enter: choose    Left / Right: select",
			bounds.get_center().x, bounds.end.y - 12.0, 10, Color("f7f3ed"))


# ------------------------------------------------- 3 Continues (no stat loss)

func _play_death() -> void:
	# Survival Mode: NUNCA chama ProgressStore.halve_gains() nem ProgressStore.add_death().
	var left := int(SurvivalState.data().get("continues", 0))
	_append_log("FALLEN FELL.")
	phase_text = "CONTINUE" if left > 0 else "SURVIVAL OVER"
	hud.mode = "death"
	hud.feedback = ""
	_refresh_all()

	_survival_gameover = (left <= 0)
	_show_continue_overlay(left)
	continue_prompt_open = true
	_continue_yes = false
	await continue_answered
	continue_prompt_open = false
	_hide_continue_overlay()

	if not _survival_gameover and _continue_yes:
		var remaining := SurvivalState.use_continue()
		_revive_party_for_continue()
		_append_log("CONTINUE USED (%d/%d left). Full HP/EN restored, stats kept!" % [remaining, SurvivalData.MAX_CONTINUES])
		_event("Continue used: %d left." % remaining)
		hud.mode = "busy"
		_refresh_all()
		if is_inside_tree():
			await run_battle()
		return

	var st := SurvivalState.data()
	SurvivalMeta.finish_run((st.get("defeated", []) as Array).size(),
			int(st.get("macca", 0)), int(st.get("continues", 0)))
	SurvivalState.clear()
	if is_inside_tree():
		_leave_after_death()


func _leave_after_death() -> void:
	left_to_title = true
	if suppress_scene_change:
		return
	super._leave_after_death()


func answer_continue(yes: bool) -> void:
	if not continue_prompt_open:
		return
	_continue_yes = yes
	continue_answered.emit()


func _revive_party_for_continue() -> void:
	_fallen.current_hp = _fallen.stats.max_hp
	_fallen.current_en = _fallen.stats.max_en
	_fallen.burns.clear()
	_fallen.restore_sp()
	_ally.current_hp = _ally.stats.max_hp
	_ally.burns.clear()
	_ally.restore_sp()
	waiting_players.clear()
	_planned.clear()
	_planned_skills.clear()
	in_reaction = false
	_counter_resolved = false


func _show_continue_overlay(continues_left: int) -> void:
	_hide_continue_overlay()
	_continue_layer = CanvasLayer.new()
	_continue_layer.name = "ContinueLayer"
	_continue_layer.layer = 50
	add_child(_continue_layer)
	_continue_panel = Control.new()
	_continue_panel.name = "ContinueOverlay"
	_continue_panel.size = HUD_SCRIPT.SCREEN
	_continue_panel.draw.connect(_draw_continue_overlay.bind(continues_left))
	_continue_layer.add_child(_continue_panel)
	_continue_panel.queue_redraw()


func _hide_continue_overlay() -> void:
	if _continue_layer != null:
		_continue_layer.queue_free()
		_continue_layer = null
		_continue_panel = null


func _draw_continue_overlay(continues_left: int) -> void:
	if _continue_panel == null:
		return
	var s := HUD_SCRIPT.SCREEN
	_continue_panel.draw_rect(Rect2(Vector2.ZERO, s), Color(0.02, 0.01, 0.02, 0.86))
	var box := Rect2(92, 126, 360, 164)
	_continue_panel.draw_rect(box, Color(0.06, 0.03, 0.05, 0.96))
	_continue_panel.draw_rect(box, Color(0.95, 0.90, 0.91, 0.7), false, 1.5)
	var font: Font = hud.ui_bold
	var regular: Font = hud.ui_font
	var cx := box.get_center().x
	if continues_left > 0:
		_draw_centered(_continue_panel, font, "FALLEN DEFEATED", cx, box.position.y + 34, 18, Color("ff9a92"))
		_draw_centered(_continue_panel, font, "CONTINUE?  (%d/%d LEFT)" % [continues_left, SurvivalData.MAX_CONTINUES], cx, box.position.y + 66, 15, Color("f5e08e"))
		_draw_centered(_continue_panel, regular, "Full HP & EN restored. All stats are kept.", cx, box.position.y + 96, 11, Color("f7f3ed"))
		_draw_centered(_continue_panel, font, "Z / Enter: CONTINUE     X / Esc: TITLE", cx, box.position.y + 136, 12, Color("81e6a8"))
	else:
		var st := SurvivalState.data()
		var def_n := (st.get("defeated", []) as Array).size()
		_draw_centered(_continue_panel, font, "SURVIVAL OVER", cx, box.position.y + 36, 18, Color("ff9a92"))
		_draw_centered(_continue_panel, font, "NO CONTINUES LEFT (0/%d)" % SurvivalData.MAX_CONTINUES, cx, box.position.y + 66, 13, Color("f5e08e"))
		_draw_centered(_continue_panel, regular, "Demons defeated: %d/20   Macca: %dM" % [def_n, int(st.get("macca", 0))], cx, box.position.y + 98, 11, Color("f7f3ed"))
		_draw_centered(_continue_panel, font, "Z / Enter / X: RETURN TO TITLE", cx, box.position.y + 136, 12, Color("f7f3ed"))


static func _draw_centered(canvas: Control, f: Font, text: String, cx: float, y: float, px: int, color: Color) -> void:
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	canvas.draw_string(f, Vector2(cx - w * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)


# ------------------------------------------------- Victory persistence (SurvivalState only)

func _show_result() -> void:
	if state.player_victory() and not _result_recorded:
		_result_recorded = true
		var reward := 0
		var run_seed := int(SurvivalState.data().get("seed", 1))
		for id in encounter_ids:
			var def := SurvivalData.demon_by_id(id)
			var gain := int(def.get("macca", 25))
			if SurvivalData.is_elite(run_seed, id):
				gain *= 2
			reward += gain
			SurvivalState.record_victory(id, gain)
		var skill_names: Array[String] = []
		for sk in _fallen.skills:
			skill_names.append(String(sk))
		SurvivalState.patch({
			"fallen_hp": maxi(1, _fallen.current_hp),
			"fallen_en": clampi(_fallen.current_en, 0, _fallen.stats.max_en),
			"yoch_hp": maxi(1, _ally.current_hp),
			"yoch_pp": _ally.current_pp,
			"gains": _progress_gains.duplicate(true),
			"skills": skill_names,
			"absorbs": _absorb_counts.duplicate(true),
		})
		Engine.set_meta(DUNGEON_RETURN_META, SurvivalData.WORLD_SCENE)
		_append_log("Earned +%d MACCA (total %dM)." % [reward, int(SurvivalState.data().macca)])
		_event("Earned %d MACCA." % reward)
		var finished: Array = SurvivalState.data().get("defeated", [])
		if finished.size() >= SurvivalData.DEMONS.size():
			SurvivalMeta.finish_run(finished.size(), int(SurvivalState.data().macca),
					int(SurvivalState.data().continues))
	super._show_result()
	if hud != null:
		hud.feedback = "Battle finished. Z / Enter: return to the Survival Arena."
