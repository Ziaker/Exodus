extends SceneTree
## D-066..D-075 integrados nas cenas: batalha (guardião, intenções, temperamentos,
## relíquias de batalha, itens novos, saque de elite/guardião) e mapa (estrato
## gerado, eventos, loja, cura paga, OMEN, descida, escolha da relíquia, fim de run).

var checks := 0
var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, description: String) -> void:
	if not ok:
		failed = true
		push_error("FAIL: " + description)
		print("FAIL: ", description)
	else:
		checks += 1


func _wait_mode(b: Control, wanted: String, limit: int = 300) -> bool:
	for _i in limit:
		if b.hud != null and b.hud.mode == wanted:
			return true
		if b.hud != null and b.hud.mode == "react" and wanted != "react":
			b.handle_back()
		if b.hud != null and b.hud.mode in ["continue", "announce"] and wanted not in ["continue", "announce"]:
			b.proceed()
		await process_frame
	return false


func _freeze(b: Control) -> void:
	for unit in b.state.units:
		if unit != b._fallen:
			unit.acts_available = 0
			unit.stored_acts = 0
	b._refresh_all()


func _battle(encounter: String, patch: Dictionary = {}) -> Control:
	SurvivalState.reset()
	var base := {"seed": 1, "encounter_id": encounter,
		"gains": {"max_hp": 0, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": 30}}
	for k in patch.keys():
		base[k] = patch[k]
	SurvivalState.patch(base)
	var b: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	b.suppress_scene_change = true
	root.add_child(b)
	await _wait_mode(b, "plan")
	return b


func _run() -> void:
	var meta_backup := ""
	if FileAccess.file_exists(SurvivalMeta.SAVE_PATH):
		meta_backup = FileAccess.get_file_as_string(SurvivalMeta.SAVE_PATH)
	ProgressStore.save_path_override = "user://test_survival_run_guard.json"
	ProgressStore.clear()
	var gains_before := ProgressStore.load_gains()

	await _battle_warden()
	await _battle_ai()
	await _battle_items()
	await _battle_loot()
	await _world()

	_check(ProgressStore.load_gains() == gains_before, "Survival never touched the campaign ProgressStore")
	if meta_backup.is_empty():
		if FileAccess.file_exists(SurvivalMeta.SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SurvivalMeta.SAVE_PATH))
	else:
		var f := FileAccess.open(SurvivalMeta.SAVE_PATH, FileAccess.WRITE)
		f.store_string(meta_backup)
		f.close()
	SurvivalState.clear()
	ProgressStore.clear()
	ProgressStore.save_path_override = ""
	print("SURVIVAL RUN CHECKS PASSED: %d FAILED: %d" % [checks, int(failed)])
	quit(1 if failed else 0)


func _battle_warden() -> void:
	var b := await _battle("lakshmi", {"fallen_relics": ["sling_of_david", "aaron_rod"],
		"yoch_relics": ["ark_shard"], "yoch_pp": 2})
	_check(b.hud.opponents.size() == 3, "Warden LAKSHMI fights with 2 escorts (%d)" % b.hud.opponents.size())
	var lead: BattleUnit = b.hud.opponents[0]
	_check(lead.display_name == "WARDEN LAKSHMI", "Warden label (%s)" % lead.display_name)
	# D-101: os inimigos acompanham o SP do Fallen (aqui 73 + 30 de AGI), depois o guardiao ganha HP x1,5.
	var expected := UnitStats.new()
	for k in SurvivalData.demon_by_id("lakshmi").stats: expected.set(k, int(SurvivalData.demon_by_id("lakshmi").stats[k]))
	SurvivalData.follow_hero(expected, b._fallen.stats.sp_value(), SurvivalStrata.par_sp(3))
	SurvivalData.empower(expected, "lakshmi", 1, 0)
	_check(lead.stats.max_hp == expected.max_hp, "Warden HP follows the hero then x1.5 (%d, expected %d)" % [lead.stats.max_hp, expected.max_hp])
	for foe in b.hud.opponents:
		_check(SurvivalStrata.stratum_of(String(foe.kind)) == 3, "Escort %s from stratum 3" % foe.kind)
	_check(b._fallen.stats.atk == int(SurvivalData.FALLEN_BASE.atk) + 4, "SLING OF DAVID +4 ATK vs warden (%d)" % b._fallen.stats.atk)
	_check(b._fallen.atk_stages.size() == 1, "AARON'S ROD opens with +1 ATK stage")
	_check(b._ally.current_pp == 4, "ARK SHARD: Yoch starts with +2 PP (%d)" % b._ally.current_pp)
	_check(b.intents.size() == 3, "Every living foe announces an intent (%d)" % b.intents.size())
	for foe in b.hud.opponents:
		var it: Dictionary = b.intents.get(foe.id, {})
		_check(String(it.get("kind", "")) in ["attack", "strike", "magic", "heal", "buff"], "%s intent kind %s" % [foe.kind, it.get("kind")])
		_check(not b.intent_text(foe).is_empty(), "%s intent text: %s" % [foe.kind, b.intent_text(foe)])
		if String(it.kind) in ["attack", "strike"]:
			_check(it.target != null and (it.target as BattleUnit).is_player, "%s intent targets a hero" % foe.kind)
		var r: Rect2 = b.intent_rect(b.hud.opponents.find(foe))
		# HUD em 544×416 (×1,5 na tela): o rótulo fica entre os pés e o Battle Log.
		var art: Rect2 = b.hud.enemy_sprite_rect(b.hud.opponents.find(foe))
		_check(r.position.x >= 0 and r.end.x <= b.HUD_SCRIPT.SCREEN.x and r.position.y > art.end.y
				and r.end.y <= b.HUD_SCRIPT.BATTLE_LOG_RECT.position.y, "Intent label between the feet and the log (%s)" % str(r))
	# Nova rodada => novas intenções.
	var round_before: int = b._intent_round
	# Painel de absorção cabe no HUD (544 px) mesmo com 4 opções.
	b.absorb_options.assign([{}, {}, {}, {}])
	_check(b.ABSORB_BOUNDS.end.x <= b.HUD_SCRIPT.SCREEN.x and b.absorb_option_rect(3).end.x <= b.ABSORB_BOUNDS.end.x,
			"Absorb panel and its 4th option fit the HUD width")
	b.absorb_options.clear()
	b.state.round_number += 1
	b._refresh_all()
	_check(b._intent_round == round_before + 1, "Intents re-roll on a new round")
	# Gastou 3 dos 4: os 2 do bônus saem primeiro, então a run guarda 1 (não 0, nem 4).
	b._ally.change_pp(-3)
	for foe in b.hud.opponents:
		foe.current_hp = 0
	b._show_result()
	_check(int(SurvivalState.data().yoch_pp) == 1, "ARK SHARD bonus PP is spent first and not banked (%d)" % int(SurvivalState.data().yoch_pp))
	b.queue_free()
	await process_frame


func _battle_ai() -> void:
	var b := await _battle("cerberus")
	_freeze(b)
	var foe: BattleUnit = b.hud.opponents[0]
	foe.acts_available = 2
	# A intenção anunciada é a ação executada, com o alvo anunciado.
	b.intents[foe.id] = {"skill": &"", "kind": "attack", "target": b._ally, "used": false}
	b._ai_unit = foe
	_check(b._enemy_choice(foe, 2) == &"", "Announced ATTACK is what the enemy picks")
	_check(b._player_with_most_sp() == b._ally, "Announced target is the one attacked")
	_check(bool(b.intents[foe.id].used), "Intent consumed")
	# Intenção impagável cai no temperamento (não trava).
	foe.current_en = 0
	b.intents[foe.id] = {"skill": &"fang_flurry", "kind": "strike", "target": b._fallen, "used": false}
	var pick: StringName = b._enemy_choice(foe, 2)
	_check(pick == &"" or SkillBook.affordable(pick, 2, 0, foe.current_hp), "Unpayable intent falls back to a payable choice")
	# Pesos por temperamento.
	_check(b.temperament_of(foe) == "brute", "Cerberus is a BRUTE")
	_check(b.choice_weight(foe, &"fang_flurry") > b.choice_weight(foe, &""), "BRUTE prefers strikes over ATTACK")
	foe.atk_stages.append({"round": 99, "owner": foe.id})
	_check(b.choice_weight(foe, &"primal_roar") == 0.0, "No second buff while one is active")
	foe.atk_stages.clear()
	foe.current_hp = foe.stats.max_hp
	_check(b.choice_weight(foe, &"mend") == 0.0, "Healthy demons never heal")
	foe.kind = &"lakshmi" # SUPPORT
	foe.current_hp = 5
	_check(b.choice_weight(foe, &"mend") == 6.0, "Hurt SUPPORT strongly prefers healing")
	foe.kind = &"lich" # CASTER
	_check(b.choice_weight(foe, &"hellfire") > b.choice_weight(foe, &"fang_flurry"), "CASTER prefers magic")
	foe.kind = &"garuda" # HUNTER
	b._fallen.current_hp = b._fallen.stats.max_hp
	b._ally.current_hp = 10
	_check(b.temperament_target(foe) == b._ally, "HUNTER chases the hero with the lowest HP share")
	b._ally.current_hp = b._ally.stats.max_hp
	b._fallen.current_hp = 10
	_check(b.temperament_target(foe) == b._fallen, "HUNTER switches when Fallen is the weakest")
	# Distribuição: um CASTER escolhe magia na maioria das vezes.
	b.rng.seed = 3
	foe.kind = &"lich"
	foe.current_en = 99
	foe.acts_available = 2
	foe.skills.assign([&"hellfire", &"fang_flurry"])
	var magic := 0
	for i in 400:
		if b.temperament_pick(foe, 2) == &"hellfire":
			magic += 1
	_check(magic > 220, "CASTER picks magic most of the time (%d/400)" % magic)
	# LEVIATHAN SCALE: o portador não queima.
	SurvivalState.patch({"fallen_relics": ["leviathan_scale"]})
	b._fallen.burns.assign([3, 2])
	var hp_before: int = b._fallen.current_hp
	await b._burn_tick()
	_check(b._fallen.burns.is_empty() and b._fallen.current_hp == hp_before, "LEVIATHAN SCALE blocks burns")
	b.queue_free()
	await process_frame


func _use_item(b: Control, item: String, target_index: int) -> bool:
	_freeze(b)
	var cmds: Array[String] = b._commands(b._fallen)
	b.submit_plan(cmds.find("ITEM"))
	b.exec_plan()
	if not await _wait_mode(b, "item"):
		return false
	b.submit_item(b.item_ids.find(item))
	if not await _wait_mode(b, "target"):
		return false
	b.submit_target(target_index)
	for _i in 30:
		await process_frame
	return true


func _battle_items() -> void:
	var b := await _battle("pixie", {"blast": 1, "soma": 1, "medicine": 1, "bead": 1, "chakra": 0,
		"fallen_hp": 20, "fallen_en": 1, "yoch_relics": ["shepherd_staff"]})
	_freeze(b)
	var foe: BattleUnit = b.hud.opponents[0]
	foe.stats.max_hp = 200
	foe.current_hp = 200
	_check(await _use_item(b, "blast", 0), "BLAST STONE targets an enemy")
	_check(foe.current_hp == 182, "BLAST STONE deals 18 (%d)" % foe.current_hp)
	_check(int(SurvivalState.data().blast) == 0, "BLAST STONE consumed")
	await _wait_mode(b, "plan")
	_check(await _use_item(b, "bead", 0), "BEAD on Fallen")
	_check(b._fallen.current_hp == mini(b._fallen.stats.max_hp, 20 + 30), "SHEPHERD'S STAFF: BEAD heals 30 up to the max (20 -> %d)" % b._fallen.current_hp)
	await _wait_mode(b, "plan")
	_check(await _use_item(b, "soma", 0), "SOMA on Fallen")
	_check(b._fallen.current_hp == b._fallen.stats.max_hp and b._fallen.current_en == b._fallen.stats.max_en, "SOMA fully restores HP and EN")
	await _wait_mode(b, "plan")
	# MEDICINE num alvo cheio é recusada sem gastar nada.
	_freeze(b)
	var cmds: Array[String] = b._commands(b._fallen)
	b.submit_plan(cmds.find("ITEM"))
	b.exec_plan()
	await _wait_mode(b, "item")
	b.submit_item(b.item_ids.find("medicine"))
	await _wait_mode(b, "target")
	b.submit_target(0)
	for _i in 20:
		await process_frame
	_check(int(SurvivalState.data().medicine) == 1, "MEDICINE on a full ally is refused and kept")
	b.queue_free()
	await process_frame


func _elite_seed(id: String) -> int:
	for seed in 5000:
		if SurvivalData.is_elite(seed, id):
			return seed
	return -1


func _battle_loot() -> void:
	# Elite: dobra a Macca, solta 1 relíquia; GOLDEN CALF +50%; MANNA JAR cura 15.
	var seed := _elite_seed("cerberus")
	_check(seed >= 0, "Found an elite Cerberus seed")
	var b := await _battle("cerberus", {"seed": seed, "macca": 0, "fallen_relics": ["golden_calf", "manna_jar"],
		"fallen_hp": 8})
	_freeze(b)
	_check(b.hud.opponents[0].display_name.begins_with("ELITE CERBERUS"), "Elite label (%s)" % b.hud.opponents[0].display_name)
	var relics_before: int = (SurvivalState.data().relics as Array).size()
	for foe in b.hud.opponents:
		foe.current_hp = 0
	b._fallen.current_hp = 8
	b._show_result()
	var s := SurvivalState.data()
	_check(int(s.macca) == int(round(35 * 2 * 1.5)), "Elite x2 and GOLDEN CALF x1.5 Macca (%d)" % int(s.macca))
	_check((s.relics as Array).size() == relics_before + 1 and not String(s.last_loot).is_empty(), "Elite drops a relic (%s)" % s.last_loot)
	_check(int(s.fallen_hp) == 8 + 15, "MANNA JAR heals 15 after victory (%d)" % int(s.fallen_hp))
	_check(int(s.battles) == 1, "Battle counter")
	b.queue_free()
	await process_frame
	# Guardião: Macca x2 e escolha de 3 relíquias pendente.
	var w := await _battle("succubus", {"macca": 0})
	_freeze(w)
	for foe in w.hud.opponents:
		foe.current_hp = 0
	w._show_result()
	s = SurvivalState.data()
	_check((s.pending_relic_choice as Array).size() == 3, "Warden leaves a 1-of-3 relic choice")
	_check((s.defeated as Array).has("succubus") and SurvivalState.warden_down(1), "Warden recorded as defeated")
	var expected := 0
	for id in w.encounter_ids:
		var gain := int(SurvivalData.demon_by_id(id).macca)
		if SurvivalStrata.is_warden(id):
			gain *= 2
		if SurvivalData.is_elite(1, id):
			gain *= 2
		expected += gain
	_check(int(s.macca) == expected, "Warden Macca doubled (%d vs %d)" % [int(s.macca), expected])
	w.queue_free()
	await process_frame


func _world_instance() -> Node:
	var w: Node = load(SurvivalData.WORLD_SCENE).instantiate()
	w.battle_scene = ""
	root.add_child(w)
	await process_frame
	await process_frame
	return w


func _world() -> void:
	SurvivalState.reset()
	SurvivalState.patch({"seed": 4321, "stratum": 2, "cell": [12, 10], "macca": 1000})
	var w := await _world_instance()
	_check(w.grid == SurvivalStrata.maze(4321, 2), "Stratum 2 uses its generated maze")
	_check(w.enemies.entries.size() == 7, "7 demons on the stratum map (%d)" % w.enemies.entries.size())
	var warden: Dictionary = {}
	for e in w.enemies.entries:
		_check(SurvivalStrata.stratum_of(String(e.id)) == 2, "%s belongs to stratum 2" % e.id)
		if bool(e.get("warden", false)):
			warden = e
	_check(String(warden.get("id", "")) == SurvivalStrata.warden_of(2), "Warden flagged on the map")
	_check(w.npcs.size() == 4, "Keeper + 3 events on the map (%d)" % w.npcs.size())
	_check(w._location_title().contains("STRATUM 2/5"), "Location line shows the stratum")
	# Guardião não persegue.
	var wc: Vector2i = warden.cell
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var near: Vector2i = wc + d * 2
		if SurvivalStrata.is_floor(w.grid, near) and SurvivalStrata.is_floor(w.grid, wc + d):
			w.cell = near
			break
	w._step_nearby_demons()
	_check(warden.cell == wc, "Warden holds its post instead of chasing")
	w.cell = Vector2i(12, 10)
	# Barra do santuário.
	w.service_open = true
	var ids: Array[String] = []
	for o in w.service_options():
		ids.append(String(o.id))
	_check(ids == ["heal", "shop", "relics", "new_run", "daily", "title", "leave"], "Service options before the warden falls: %s" % str(ids))
	_check(String(w.service_options()[0].label) == "HEAL FREE", "HEAL FREE label")
	w.service_index = 0
	SurvivalState.patch({"fallen_hp": 10})
	w.confirm_service_option()
	_check(int(SurvivalState.data().fallen_hp) == SurvivalState.fallen_max_hp() and int(SurvivalState.data().macca) == 1000, "Free heal")
	_check(String(w.service_options()[0].label) == "HEAL 30M", "Next heal costs 30M on stratum 2")
	SurvivalState.patch({"fallen_hp": 10})
	w.service_open = true
	w.service_index = 0
	w.confirm_service_option()
	_check(int(SurvivalState.data().macca) == 970, "Paid heal costs 30M")
	# Loja.
	w.service_open = true
	w.service_index = w.service_index_of("shop")
	w.confirm_service_option()
	_check(w.shop_open and not w.service_open, "SHOP opens its panel")
	var rows: Array = w.shop_rows()
	_check(rows.size() == 5 and String(rows[4].kind) == "relic", "Shop: 4 items + 1 relic (%d)" % rows.size())
	await process_frame
	w.shop_index = 2
	var item_id := String(rows[2].id)
	var before := int(SurvivalState.data().get(item_id, 0))
	_check(w.confirm_shop() and int(SurvivalState.data().get(item_id, 0)) == before + 1, "Buying a rotating item")
	w.shop_index = 4
	var relic_id := String(rows[4].id)
	_check(w.confirm_shop() and (SurvivalState.data().relics as Array).has(relic_id), "Buying the shop relic")
	_check(w.shop_rows().size() == 4, "Shop relic sells once per stratum")
	w.close_shop()
	# Eventos (cada tipo, de forma determinística).
	for kind in ["altar", "spirit", "oracle", "merchant"]:
		var npc := {"id": "test_" + kind, "role": "event", "kind": kind, "cell": Vector2i(1, 1),
			"name": String(SurvivalData.EVENT_DEFS[kind].name), "picture": String(SurvivalData.EVENT_DEFS[kind].picture), "pages": ["x"]}
		w.npcs.append(npc)
		w.active_event = npc
		w.event_open = true
		w.event_index = 0
		await process_frame
		var s0: Dictionary = SurvivalState.data().duplicate(true)
		var chosen: String = w.confirm_event()
		var s1 := SurvivalState.data()
		match kind:
			"altar":
				_check(chosen == "offer" and int(s1.fallen_hp) < int(s0.fallen_hp) and (s1.relics as Array).size() == (s0.relics as Array).size() + 1, "ALTAR trades HP for a relic")
			"spirit":
				_check(chosen == "rest" and int(s1.fallen_hp) >= int(s0.fallen_hp), "SPIRIT rest heals")
			"oracle":
				_check(chosen == "secret" and (s1.skills as Array).size() == (s0.skills as Array).size() + 1 and int(s1.macca) < int(s0.macca), "ORACLE sells a skill")
			"merchant":
				_check(chosen == "buy" and (s1.relics as Array).size() == (s0.relics as Array).size() + 1, "MERCHANT sells a relic")
		_check((s1.events_done as Array).has("test_" + kind), "%s is resolved and recorded" % kind)
		_check(not w.npcs.has(npc) and not w.event_open, "%s disappears from the map" % kind)
	# Gamble e commune por id.
	for opt in ["commune", "gamble"]:
		var kind := "spirit" if opt == "commune" else "oracle"
		var npc := {"id": "t2_" + opt, "role": "event", "kind": kind, "cell": Vector2i(1, 1), "name": "X", "picture": "", "pages": ["x"]}
		w.active_event = npc
		w.event_open = true
		w.event_index = 1
		var g0 := str(SurvivalState.data().gains)
		var hp0 := int(SurvivalState.data().fallen_hp)
		_check(w.confirm_event() == opt, "%s option" % opt)
		_check(str(SurvivalState.data().gains) != g0 or int(SurvivalState.data().fallen_hp) < hp0, "%s changes stats or HP" % opt)
	# Altar recusa matar.
	SurvivalState.patch({"fallen_hp": 5})
	w.active_event = {"id": "t3", "role": "event", "kind": "altar", "cell": Vector2i(1, 1), "name": "X", "picture": "", "pages": ["x"]}
	w.event_open = true
	w.event_index = 0
	w.confirm_event()
	_check(w.event_open and int(SurvivalState.data().fallen_hp) == 5, "ALTAR refuses to kill a weak Fallen")
	w.close_event()
	# Talk real num evento do mapa.
	var real_event: Dictionary = {}
	for npc in w.npcs:
		if String(npc.get("role", "")) == "event":
			real_event = npc
	w.cell = real_event.cell
	_check(w.talk() and w.event_open and w.active_event.id == real_event.id, "Talking on an event cell opens it")
	w.hud.queue_redraw()
	await process_frame
	w.close_event()
	# DESCEND aparece com o guardião morto, pede confirmação e desce.
	SurvivalState.patch({"defeated": [SurvivalStrata.warden_of(2)]})
	w.service_open = true
	_check(w.service_index_of("descend") == 3, "DESCEND appears after the warden falls")
	w.service_index = 3
	_check(w.confirm_service_option() == "descend" and SurvivalState.stratum() == 2, "First Z only asks to confirm")
	w.hud.queue_redraw()
	await process_frame
	w.confirm_service_option()
	_check(SurvivalState.stratum() == 3, "Second Z descends to stratum 3")
	w.queue_free()
	await process_frame
	await process_frame
	if current_scene != null:
		current_scene.queue_free()
		await process_frame
	# OMEN: só antes da primeira luta, até o nível desbloqueado.
	SurvivalMeta.save({"omen_unlocked": 2})
	SurvivalState.reset()
	var o := await _world_instance()
	o.service_open = true
	var omen_idx: int = o.service_index_of("omen")
	_check(omen_idx >= 0, "OMEN option before the first battle")
	o.service_index = omen_idx
	o.confirm_service_option()
	_check(SurvivalState.omen() == 1, "OMEN 1")
	o.confirm_service_option()
	o.confirm_service_option()
	_check(SurvivalState.omen() == 0, "OMEN wraps at the unlocked level")
	SurvivalState.patch({"battles": 1})
	_check(o.service_index_of("omen") < 0, "OMEN locked after the first battle")
	o.queue_free()
	await process_frame
	# Escolha da relíquia do guardião ao voltar ao mapa + fim de run.
	SurvivalState.reset()
	var wardens: Array = []
	for st in range(1, 6):
		wardens.append(SurvivalStrata.warden_of(st))
	SurvivalState.patch({"stratum": 5, "defeated": wardens, "pending_relic_choice": ["golden_calf", "raziel_book", "ark_shard"]})
	var runs_before := int(SurvivalMeta.data().runs)
	var c := await _world_instance()
	_check(c.relic_choice_open and not c.cleared_open, "Warden hoard opens before the clear screen")
	c.move_relic_choice(1)
	_check(c.confirm_relic_choice() == "raziel_book" and (SurvivalState.data().relics as Array).has("raziel_book"), "Relic choice grants the picked relic")
	_check(c.cleared_open, "Clearing stratum 5 opens SURVIVAL CLEARED")
	c._check_cleared()
	c.cleared_open = false
	c._check_cleared()
	_check(int(SurvivalMeta.data().runs) == runs_before + 1, "A cleared run is counted once")
	c.queue_free()
	await process_frame
