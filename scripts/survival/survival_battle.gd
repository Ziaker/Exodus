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
## D-071: ganhos próprios da Yoch nesta luta (absorção pode fortalecê-la).
var _yoch_gains: Dictionary = {}
## D-069: intenção da primeira ação de cada inimigo na rodada (id -> dados).
var intents: Dictionary = {}
var _intent_round := -1
var _ai_unit: BattleUnit = null
var _forced_target: BattleUnit = null
var _intent_layer: CanvasLayer
var _intent_panel: Control
## Saque da vitória (relíquia de elite) para o log/testes.
var loot_relic := ""
## PP da Yoch salvo na run antes do bônus da ARK SHARD.
var _saved_yoch_pp := 0


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
	_yoch_gains = (s.get("yoch_gains", {}) as Dictionary).duplicate(true)
	var run_seed := int(s.get("seed", 1))
	var omen_level := int(s.get("omen", 0))

	# Base + absorções + relíquias + pactos (D-073), os mesmos números do mapa.
	_fallen = BattleUnit.new(&"fallen", "FALLEN", SurvivalState.fallen_stats(), true, true)
	_fallen.current_hp = clampi(int(s.get("fallen_hp", _fallen.stats.max_hp)), 1, _fallen.stats.max_hp)
	_fallen.current_en = clampi(int(s.get("fallen_en", _fallen.stats.max_en)), 0, _fallen.stats.max_en)
	var saved_skills: Array[StringName] = []
	for sk in s.get("skills", []):
		saved_skills.append(StringName(str(sk)))
	_fallen.skills = saved_skills
	_absorb_counts = (s.get("absorbs", {}) as Dictionary).duplicate(true)

	_ally = BattleUnit.new(&"ally", "Yoch", SurvivalState.yoch_stats(), true)
	_ally.race = &"human"
	var pp := int(s.get("yoch_pp", SurvivalData.YOCH_BASE.pp))
	_saved_yoch_pp = pp
	if SurvivalRelics.party_has(s, "yoch_pp"):
		pp += 2
	_ally.start_praying(clampi(pp, 0, PrayerBook.MAX_PP))
	_ally.current_hp = clampi(int(s.get("yoch_hp", _ally.stats.max_hp)), 1, _ally.stats.max_hp)

	var enc_id := String(s.get("encounter_id", "pixie"))
	# Uma run tem uma semente, mas cada encontro deve sortear uma oferta diferente:
	# deriva por id do encontro, derrotados e continues já gastos.
	var defeated: Array = s.get("defeated", [])
	var continues_used: int = SurvivalData.MAX_CONTINUES - int(s.get("continues", SurvivalData.MAX_CONTINUES))
	var derived: int = run_seed + absi(enc_id.hash()) + defeated.size() * 7919 + continues_used * 104729
	run_rng.seed = absi(derived) % 2147483647
	encounter_ids.assign(SurvivalData.encounter_for(enc_id, defeated))
	if encounter_ids.is_empty():
		encounter_ids.assign([String(SurvivalData.DEMONS[0].id)])
	demon_def = SurvivalData.demon_by_id(encounter_ids[0])

	# D-070/D-066: elite ou guardião na luta liga a SLING OF DAVID de quem a usa.
	var big_fight := false
	for id in encounter_ids:
		if SurvivalStrata.is_warden(id) or SurvivalData.is_elite(run_seed, id, omen_level):
			big_fight = true
	if big_fight:
		for pair in [[_fallen, "fallen_relics"], [_ally, "yoch_relics"]]:
			if SurvivalRelics.has_perk(s.get(pair[1], []), "giant_slayer"):
				var u: BattleUnit = pair[0]
				u.stats.atk += 4
				u.stats.mak += 4
				u.restore_sp()
	# AARON'S ROD: quem a usa abre a luta com +1 estágio de ATK (dura a rodada 1).
	for pair in [[_fallen, "fallen_relics"], [_ally, "yoch_relics"]]:
		if SurvivalRelics.has_perk(s.get(pair[1], []), "opening_stage"):
			(pair[0] as BattleUnit).atk_stages.append({"round": 1, "owner": (pair[0] as BattleUnit).id})

	state.add_unit(_fallen)
	state.add_unit(_ally)

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
		# D-101: os inimigos acompanham o SP atual do Fallen (com o herói no esperado, nada muda).
		SurvivalData.follow_hero(enemy_stats, _fallen.stats.sp_value(), SurvivalStrata.par_sp(maxi(1, SurvivalStrata.stratum_of(String(def.id)))))
		var power := SurvivalData.empower(enemy_stats, String(def.id), run_seed, omen_level)
		var label := SurvivalData.battle_label(String(def.id), run_seed, omen_level)
		var enemy := BattleUnit.new(StringName("foe_%d" % i), label, enemy_stats, false)
		enemy.kind = StringName(String(def.id))
		enemy.sprite_path = String(def.picture)
		var enemy_skills: Array[StringName] = []
		for sk in def.skills:
			enemy_skills.append(StringName(sk))
		for sk in power.skills:
			if not enemy_skills.has(sk):
				enemy_skills.append(sk)
		enemy.skills = enemy_skills
		enemy.affinity = int(power.affinity)
		if bool(def.get("human", false)):
			# D-107: humans pray with PP like Yoch (no EN), start with 0 PP and cannot be absorbed.
			enemy.race = &"human"
			enemy.start_praying(0)
		state.add_unit(enemy)
		paths.append(enemy.sprite_path)

	# O HUD exige Array[String] tipado, não um Array comum.
	hud.set_opponent_sprites(paths)
	_build_intent_layer()


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
	if state.round_number != _intent_round and state.round_number > 0:
		_intent_round = state.round_number
		roll_intents()
	if _intent_panel != null:
		_intent_panel.queue_redraw()


# ------------------------------------------------- D-069: temperaments & intents

func temperament_of(unit: BattleUnit) -> String:
	return SurvivalStrata.temperament(String(unit.kind))


## Peso de cada escolha conforme o temperamento (&"" = ATTACK).
func choice_weight(unit: BattleUnit, skill: StringName) -> float:
	var t := temperament_of(unit)
	var kind := "attack" if skill == &"" else String(SkillBook.def(skill).get("kind", "strike"))
	var hurt := float(unit.current_hp) / float(maxi(1, unit.stats.max_hp))
	if kind == "prayer" or skill == &"cherav":
		return _prayer_weight(unit, skill)
	if kind == "heal":
		if hurt >= 0.6:
			return 0.0
		return 6.0 if t == "support" else 2.0
	if kind == "buff" and not unit.atk_stages.is_empty() and t != "trickster":
		return 0.0
	if t == "trickster":
		return 1.0
	var table := {
		"brute": {"attack": 2.0, "strike": 4.0, "magic": 1.0, "buff": 1.5},
		"caster": {"attack": 1.0, "strike": 1.0, "magic": 5.0, "buff": 0.5},
		"support": {"attack": 2.0, "strike": 1.0, "magic": 2.0, "buff": 3.0},
		"hunter": {"attack": 2.0, "strike": 4.0, "magic": 1.0, "buff": 1.0},
	}
	return float((table.get(t, {}) as Dictionary).get(kind, 1.0))


## D-107: how a human weighs its prayers (PRAY while it has little PP, NECHAMAH only when an
## ally is hurt, SANVERIM only while some hero can still be blinded).
func _prayer_weight(unit: BattleUnit, skill: StringName) -> float:
	match skill:
		&"pray": return 3.0 if unit.current_pp < 3 else 1.0
		&"nechamah":
			for ally in _allies_of(unit):
				if float(ally.current_hp) < 0.8 * float(ally.stats.max_hp) and ally.mends.size() < 2:
					return 4.0
			return 0.0
		&"sanverim":
			for hero in state.units:
				if hero.is_player and hero.is_alive() and not hero.has_status(&"blind"):
					return 2.0
			return 0.0
		&"cherav": return 4.0
	return 1.0


func temperament_pick(unit: BattleUnit, budget: int) -> StringName:
	var choices: Array[StringName] = [&""]
	var acts := mini(budget, maxi(unit.acts_available, 0))
	for skill in unit.skills:
		if SkillBook.affordable(skill, acts, unit.current_en, unit.current_hp, unit.current_pp if unit.prays else 99):
			choices.append(skill)
	var total := 0.0
	for c in choices:
		total += choice_weight(unit, c)
	if total <= 0.0:
		return &""
	var r := rng.randf() * total
	for c in choices:
		r -= choice_weight(unit, c)
		if r < 0.0:
			return c
	return choices[choices.size() - 1]


## HUNTER persegue o herói com menor % de HP; os outros seguem a regra base (mais SP).
func temperament_target(unit: BattleUnit) -> BattleUnit:
	if unit != null and temperament_of(unit) == "hunter":
		var best: BattleUnit = null
		for hero in state.units:
			if hero.is_player and hero.is_alive():
				if best == null or float(hero.current_hp) / float(hero.stats.max_hp) \
						< float(best.current_hp) / float(best.stats.max_hp):
					best = hero
		if best != null:
			return best
	return super._player_with_most_sp()


## Sorteia e anuncia a primeira ação de cada inimigo vivo nesta rodada.
func roll_intents() -> void:
	intents.clear()
	for unit in state.units:
		if unit.is_player or not unit.is_alive():
			continue
		var skill := temperament_pick(unit, 2)
		var target: BattleUnit = null
		var kind := "attack" if skill == &"" else String(SkillBook.def(skill).get("kind", "strike"))
		if kind in ["attack", "strike"]:
			target = temperament_target(unit)
		intents[unit.id] = {"skill": skill, "kind": kind, "target": target, "used": false}


func intent_text(unit: BattleUnit) -> String:
	var it: Dictionary = intents.get(unit.id, {})
	if it.is_empty():
		return ""
	var skill: StringName = it.skill
	var name := "ATTACK" if skill == &"" else SkillBook.display_name(skill)
	match String(it.kind):
		"attack", "strike":
			var t: BattleUnit = it.target
			return "%s ▸ %s" % [name, t.display_name.to_upper() if t != null else "?"]
		"magic":
			return "%s ▸ ALL" % name
	return name


func _enemy_turn(unit: BattleUnit) -> void:
	_ai_unit = unit
	await super._enemy_turn(unit)
	_ai_unit = null
	_forced_target = null
	if intents.has(unit.id):
		intents[unit.id].used = true
	if _intent_panel != null:
		_intent_panel.queue_redraw()


## A primeira escolha do turno executa a intenção anunciada (se ainda der para pagar);
## as seguintes seguem o temperamento.
func _enemy_choice(unit: BattleUnit, budget: int) -> StringName:
	_ai_unit = unit
	var it: Dictionary = intents.get(unit.id, {})
	if not it.is_empty() and not bool(it.used):
		it.used = true
		var skill: StringName = it.skill
		if skill == &"" or SkillBook.affordable(skill, mini(budget, unit.acts_available), unit.current_en, unit.current_hp, unit.current_pp if unit.prays else 99):
			var t: BattleUnit = it.target
			_forced_target = t if t != null and t.is_alive() else null
			return skill
	_forced_target = null
	return temperament_pick(unit, budget)


func _player_with_most_sp() -> BattleUnit:
	# D-106 TAUNT beats the announced target and the temperament.
	var heroes: Array = []
	for u in state.units:
		if u.is_player: heroes.append(u)
	var taunter := SkillFx.taunter(heroes)
	if taunter != null:
		_forced_target = null
		return taunter
	if _forced_target != null and _forced_target.is_alive():
		var t := _forced_target
		_forced_target = null
		return t
	if _ai_unit != null and not _ai_unit.is_player:
		return temperament_target(_ai_unit)
	return super._player_with_most_sp()


func _build_intent_layer() -> void:
	_intent_layer = CanvasLayer.new()
	_intent_layer.name = "IntentLayer"
	_intent_layer.layer = 4
	_intent_panel = Control.new()
	_intent_panel.name = "Intents"
	_intent_panel.size = HUD_SCRIPT.SCREEN
	_intent_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intent_panel.draw.connect(_draw_intents)
	_intent_layer.add_child(_intent_panel)
	add_child(_intent_layer)


const INTENT_INK := {"attack": Color("ff8a7a"), "strike": Color("ff8a7a"),
	"magic": Color("c9a2ff"), "heal": Color("81e6a8"), "buff": Color("f5e08e")}


## Rótulo sob a sombra de cada inimigo (o nome do HUD fica acima da arte):
## ação anunciada + temperamento. Coordenadas do HUD (544×416, ×1,5 na tela).
func intent_rect(index: int) -> Rect2:
	var art: Rect2 = hud.enemy_sprite_rect(index)
	var w := 150.0
	return Rect2(art.get_center().x - w * 0.5, art.end.y + 11.0, w, 24.0)


func _draw_intents() -> void:
	if _intent_panel == null or hud == null or hud.mode in ["result", "death", "absorb_choice"]:
		return
	var font: Font = hud.ui_bold
	var regular: Font = hud.ui_font
	for i in hud.opponents.size():
		var unit: BattleUnit = hud.opponents[i]
		if not unit.is_alive():
			continue
		var r := intent_rect(i)
		var it: Dictionary = intents.get(unit.id, {})
		var tag: String = String(SurvivalStrata.TEMPERAMENT_LABELS.get(temperament_of(unit), ""))
		_draw_centered(_intent_panel, regular, tag, r.get_center().x, r.position.y + 22.0, 8, Color(1, 1, 1, 0.72))
		if it.is_empty() or bool(it.used):
			continue
		var text := intent_text(unit)
		var px := 8
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		var box := Rect2(r.get_center().x - tw * 0.5 - 4.0, r.position.y, tw + 8.0, 12.0)
		_intent_panel.draw_rect(box, Color(0.04, 0.02, 0.04, 0.85))
		var ink: Color = INTENT_INK.get(String(it.kind), Color.WHITE)
		_intent_panel.draw_rect(box, ink, false, 1.0)
		_draw_centered(_intent_panel, font, text, r.get_center().x, box.position.y + 9.0, px, ink)


## D-073 LEVIATHAN SCALE: quem a usa não queima (as queimaduras somem antes do tique).
func _burn_tick() -> void:
	var s := SurvivalState.data()
	if SurvivalRelics.has_perk(s.get("fallen_relics", []), "burn_immune"):
		_fallen.burns.clear()
	if SurvivalRelics.has_perk(s.get("yoch_relics", []), "burn_immune"):
		_ally.burns.clear()
	await super._burn_tick()


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


## Quantidade real do item: SHEPHERD'S STAFF faz HP/EN de itens render +50%.
func item_amount(item_id: String) -> int:
	var def := SurvivalData.shop_item(item_id)
	var amount := int(def.get("amount", 0))
	if String(def.get("kind", "")) in ["hp", "en"] \
			and SurvivalRelics.party_has(SurvivalState.data(), "item_boost"):
		amount = int(round(float(amount) * 1.5))
	return amount


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
	var kind := String(item_def.kind)
	# D-072: BLAST STONE mira um inimigo; os outros itens miram um aliado.
	var recipient := await _wait_target("enemy" if kind == "damage" else "player")
	if recipient == null:
		return false
	# Não gasta item nem ato num alvo já cheio: o Macca do vendedor vale.
	var wasted := false
	var en_full := recipient.current_pp >= PrayerBook.MAX_PP if recipient.prays \
			else recipient.current_en >= recipient.stats.max_en
	if kind == "hp":
		wasted = recipient.current_hp >= recipient.stats.max_hp
	elif kind == "full":
		wasted = recipient.current_hp >= recipient.stats.max_hp and en_full
	elif kind == "damage":
		wasted = not recipient.is_alive()
	else:
		wasted = en_full
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
	var amount := item_amount(chosen_id)
	if kind == "damage":
		var dealt := recipient.take_damage(amount)
		fx.play("MAGIC", recipient, dealt, unit)
		_append_log("%s throws %s at %s: -%d HP." % [
			unit.display_name, String(item_def.name), recipient.display_name, dealt])
		_event("%s throws %s at %s: %d damage." % [short_name(unit), String(item_def.name), short_name(recipient), dealt])
		if not recipient.is_alive():
			_event("%s is down." % short_name(recipient))
		hud.feedback = "%s: HP %d/%d | 1 ACT spent" % [recipient.display_name, recipient.current_hp, recipient.stats.max_hp]
		if reacting:
			unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
		_refresh_all()
		return true
	if kind == "full":
		var healed_full := recipient.heal(recipient.stats.max_hp)
		var restored := 0
		if recipient.prays:
			restored = recipient.change_pp(PrayerBook.MAX_PP)
		else:
			var en_before := recipient.current_en
			recipient.recover_en_flat(recipient.stats.max_en)
			restored = recipient.current_en - en_before
		fx.play("HEAL", recipient, healed_full)
		if unit.is_fallen:
			unit.add_sp(-2)
		_append_log("%s uses %s on %s: +%d HP, +%d %s%s." % [
			unit.display_name, String(item_def.name), recipient.display_name, healed_full, restored,
			"PP" if recipient.prays else "EN", " (-2 SP)" if unit.is_fallen else ""])
		_event("%s uses %s on %s: fully restored." % [short_name(unit), String(item_def.name), short_name(recipient)])
		hud.feedback = "%s: HP %d/%d | 1 ACT spent" % [recipient.display_name, recipient.current_hp, recipient.stats.max_hp]
		if reacting:
			unit.add_sp(BattleMath.SP_GAIN_PER_EVENT)
		_refresh_all()
		return true
	if kind == "hp":
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


## D-071/D-073: contexto da oferta (estrato, relíquias de skill e de 4 opções).
func absorb_context() -> Dictionary:
	var s := SurvivalState.data()
	var bonus := 0.0
	if SurvivalRelics.party_has(s, "skill_chance"):
		bonus += 0.25
	if SurvivalRelics.party_has(s, "revelation"):
		bonus += 0.20
	return {
		"stratum": int(s.get("stratum", 1)),
		"skill_bonus": bonus,
		"count": 4 if SurvivalRelics.party_has(s, "absorb_four") else SurvivalAbsorb.OPTION_COUNT,
		"yoch": _ally != null and _ally.is_alive(),
	}

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
	# D-103 (criador, 2026-11-25): os apertos só contam; o resultado (SP tirado e um
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
	var options := SurvivalAbsorb.roll_options(run_rng, demon, owned, hp_share, absorb_context())
	var pick: int = await _wait_absorb_choice(options)
	pick = clampi(pick, 0, options.size() - 1)
	var chosen: Dictionary = options[pick]
	var owned_before: Array[StringName] = owned.duplicate()
	var base_before := unit.sp_base()
	var ally_before := _ally.sp_base()
	var hp_before := unit.stats.max_hp
	var en_before := unit.stats.max_en
	var ally_hp_before := _ally.stats.max_hp
	SurvivalAbsorb.apply_option(unit.stats, _progress_gains, _fallen.skills, chosen, _ally.stats, _yoch_gains)
	unit.add_sp(unit.sp_base() - base_before)
	_ally.add_sp(_ally.sp_base() - ally_before)
	# HP/EN máximos novos chegam cheios (o ganho também entra no atual).
	unit.current_hp += unit.stats.max_hp - hp_before
	unit.current_en += unit.stats.max_en - en_before
	if _ally.is_alive():
		_ally.current_hp += _ally.stats.max_hp - ally_hp_before
	absorb_gain_label = String(chosen.label)
	absorb_count_label = String(chosen.get("rarity", "RUN"))
	absorb_skill_label = ""
	if String(chosen.get("kind", "")) == "skill":
		absorb_skill_label = "NEW SKILL: " + SkillBook.display_name(StringName(chosen.get("skill", &"")))
	var skill_names: Array[String] = []
	for sk in _fallen.skills:
		skill_names.append(String(sk))
	var unknown: Array = SurvivalState.data().get("unidentified", []).duplicate()
	if String(chosen.get("kind", "")) == "skill":
		var learned := StringName(chosen.get("skill", &""))
		# BOOK OF RAZIEL: a skill chega identificada.
		if not owned_before.has(learned) and not unknown.has(String(learned)) \
				and not SurvivalRelics.party_has(SurvivalState.data(), "identified"):
			unknown.append(String(learned))
	SurvivalState.patch({
		"gains": _progress_gains.duplicate(true),
		"yoch_gains": _yoch_gains.duplicate(true),
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
## Coordenadas do HUD de batalha (544×416, escalado ×1,5 para a tela 816×624 da
## D-055). Cabe 4 opções (PROPHET'S SCROLL); a fonte encolhe para caber.
const ABSORB_BOUNDS := Rect2(20, 110, 504, 128)


func absorb_option_rect(index: int) -> Rect2:
	var count := maxi(1, absorb_options.size())
	var bounds := ABSORB_BOUNDS
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


const RARITY_INK := {"COMMON": Color("f7f3ed"), "RARE": Color("7fd4ff"),
	"EPIC": Color("e7a6ff"), "SKILL": Color("f5e08e")}


func _draw_absorb_overlay() -> void:
	if _absorb_panel == null or absorb_options.is_empty():
		return
	var bounds := ABSORB_BOUNDS
	_absorb_panel.draw_rect(Rect2(Vector2.ZERO, HUD_SCRIPT.SCREEN), Color(0.02, 0.01, 0.03, 0.72))
	_absorb_panel.draw_rect(bounds, Color(0.06, 0.03, 0.05, 0.98))
	_absorb_panel.draw_rect(bounds, Color("81e6a8"), false, 1.5)
	var bold: Font = hud.ui_bold
	var count := absorb_options.size()
	_draw_centered(_absorb_panel, bold, "ABSORPTION REWARD — choose 1 of %d" % count,
			bounds.get_center().x, bounds.position.y + 20, 13, Color("81e6a8"))
	for i in count:
		var rect := absorb_option_rect(i)
		var active := i == absorb_index
		var rarity := String(absorb_options[i].get("rarity", "COMMON"))
		var ink: Color = RARITY_INK.get(rarity, Color.WHITE)
		_absorb_panel.draw_rect(rect, Color(1, 1, 1, 0.16) if active else Color(1, 1, 1, 0.04))
		_absorb_panel.draw_rect(rect, Color.WHITE if active else ink.darkened(0.35),
				false, 1.5 if active else 1.0)
		_draw_centered(_absorb_panel, bold, rarity, rect.get_center().x, rect.position.y + 18.0, 10, ink)
		var label := String(absorb_options[i].label)
		var text := ("> " if active else "") + label
		var font_px := 13
		while font_px > 9 and hud.ui_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_px).x > rect.size.x - 10.0:
			font_px -= 1
		_draw_centered(_absorb_panel, hud.ui_font, text, rect.get_center().x,
				rect.position.y + 44.0, font_px, Color.WHITE if active else Color("f7f3ed"))
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
		_append_log("CONTINUE USED (%d/%d left). Full HP/EN restored, stats kept!" % [remaining, SurvivalState.max_continues()])
		_event("Continue used: %d left." % remaining)
		hud.mode = "busy"
		_refresh_all()
		if is_inside_tree():
			await run_battle()
		return

	var st := SurvivalState.data()
	SurvivalMeta.finish_run((st.get("defeated", []) as Array).size(),
			int(st.get("macca", 0)), int(st.get("continues", 0)), st)
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
		_draw_centered(_continue_panel, font, "CONTINUE?  (%d/%d LEFT)" % [continues_left, SurvivalState.max_continues()], cx, box.position.y + 66, 15, Color("f5e08e"))
		_draw_centered(_continue_panel, regular, "Full HP & EN restored. All stats are kept.", cx, box.position.y + 96, 11, Color("f7f3ed"))
		_draw_centered(_continue_panel, font, "Z / Enter: CONTINUE     X / Esc: TITLE", cx, box.position.y + 136, 12, Color("81e6a8"))
	else:
		var st := SurvivalState.data()
		var def_n := (st.get("defeated", []) as Array).size()
		_draw_centered(_continue_panel, font, "SURVIVAL OVER", cx, box.position.y + 36, 18, Color("ff9a92"))
		_draw_centered(_continue_panel, font, "NO CONTINUES LEFT (0/%d)" % SurvivalState.max_continues(), cx, box.position.y + 66, 13, Color("f5e08e"))
		_draw_centered(_continue_panel, regular, "STRATUM %d/%d   Demons defeated: %d/%d   Macca: %dM" % [int(st.get("stratum", 1)), SurvivalStrata.COUNT, def_n, SurvivalData.DEMONS.size(), int(st.get("macca", 0))], cx, box.position.y + 98, 11, Color("f7f3ed"))
		_draw_centered(_continue_panel, font, "Z / Enter / X: RETURN TO TITLE", cx, box.position.y + 136, 12, Color("f7f3ed"))


static func _draw_centered(canvas: Control, f: Font, text: String, cx: float, y: float, px: int, color: Color) -> void:
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	canvas.draw_string(f, Vector2(cx - w * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)


# ------------------------------------------------- Victory persistence (SurvivalState only)

func _show_result() -> void:
	if state.player_victory() and not _result_recorded:
		_result_recorded = true
		var reward := 0
		var s0 := SurvivalState.data()
		var run_seed := int(s0.get("seed", 1))
		var omen_level := int(s0.get("omen", 0))
		# D-073: GOLDEN CALF +50%; pacto MAMMON dobra.
		var macca_mult := 1.0
		if SurvivalRelics.party_has(s0, "mammon"):
			macca_mult = 2.0
		elif SurvivalRelics.party_has(s0, "macca_up"):
			macca_mult = 1.5
		var elite_beaten := false
		var warden_beaten := false
		for id in encounter_ids:
			var def := SurvivalData.demon_by_id(id)
			var gain := int(def.get("macca", 25))
			if SurvivalData.is_elite(run_seed, id, omen_level):
				gain *= 2
				elite_beaten = true
			if SurvivalStrata.is_warden(id):
				gain *= 2
				warden_beaten = true
			gain = int(round(float(gain) * macca_mult))
			reward += gain
			# D-107: um grupo de humanos conta como uma derrota só, no id do grupo do mapa.
			SurvivalState.record_victory(SurvivalData.human_group_of(id) if SurvivalData.is_human_id(id) else id, gain)
		var skill_names: Array[String] = []
		for sk in _fallen.skills:
			skill_names.append(String(sk))
		# D-073 MANNA JAR: cura pós-vitória de 15 HP em cada aliado.
		var bonus_heal := 15 if SurvivalRelics.party_has(s0, "victory_heal") else 0
		SurvivalState.patch({
			"fallen_hp": clampi(_fallen.current_hp + bonus_heal, 1, _fallen.stats.max_hp),
			"fallen_en": clampi(_fallen.current_en, 0, _fallen.stats.max_en),
			"yoch_hp": clampi(_ally.current_hp + bonus_heal, 1, _ally.stats.max_hp),
			# ARK SHARD: os +2 PP da luta são gastos primeiro e não ficam na run.
			"yoch_pp": clampi(mini(_ally.current_pp, _saved_yoch_pp) if SurvivalRelics.party_has(s0, "yoch_pp") else _ally.current_pp, 0, PrayerBook.MAX_PP),
			"gains": _progress_gains.duplicate(true),
			"yoch_gains": _yoch_gains.duplicate(true),
			"skills": skill_names,
			"absorbs": _absorb_counts.duplicate(true),
			"battles": int(s0.get("battles", 0)) + 1,
		})
		# D-070: elite deixa 1 relíquia; guardião deixa escolher 1 entre 3 (no mapa).
		var meta_unlocked: Array = SurvivalMeta.data().get("unlocked", [])
		var loot_rng := RandomNumberGenerator.new()
		loot_rng.seed = absi(run_seed + int(SurvivalState.data().get("battles", 0)) * 6151) % 2147483647
		if warden_beaten:
			var offer := SurvivalRelics.roll(loot_rng, SurvivalState.data().get("relics", []), meta_unlocked, 3)
			SurvivalState.patch({"pending_relic_choice": offer})
			if not offer.is_empty():
				_append_log("WARDEN DOWN: choose a relic in the arena.")
		if elite_beaten:
			var drop := SurvivalRelics.roll(loot_rng, SurvivalState.data().get("relics", []), meta_unlocked, 1)
			if not drop.is_empty():
				loot_relic = drop[0]
				SurvivalState.grant_relic(loot_relic)
				SurvivalState.patch({"last_loot": loot_relic})
				_append_log("RELIC FOUND: %s." % SurvivalRelics.name_of(loot_relic))
				_event("Relic found: %s." % SurvivalRelics.name_of(loot_relic))
		Engine.set_meta(DUNGEON_RETURN_META, SurvivalData.WORLD_SCENE)
		_append_log("Earned +%d MACCA (total %dM)." % [reward, int(SurvivalState.data().macca)])
		_event("Earned %d MACCA." % reward)
	super._show_result()
	if hud != null:
		hud.feedback = "Battle finished. Z / Enter: return to the Survival Arena."
