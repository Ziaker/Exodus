extends SceneTree
## DEBUG (D-111): soak / fuzz do Survival com aliados. Um bot joga lutas inteiras e ações de mapa
## aleatórias (grupos de 0 a 2 aliados, AUTO/MANUAL, caídos, reserva, humanos, Yoch, luta-teste,
## oferta ao vencer, continues) e, depois de cada passo, verifica invariantes do save e da cena.
## Todo erro de script/push_error é capturado por um Logger e conta como falha.
##
## Uso: Godot --headless --path . -s tools/debug_survival_soak.gd -- [lutas] [semente] [mapas]
##   padrão: 40 lutas, semente 1, 40 rodadas de mapa. Imprime cada falha com a semente que a reproduz.

const FRAME_LIMIT := 12000

var failures: Array[String] = []
var errors: Array[String] = []
var rng := RandomNumberGenerator.new()
var logger: SoakLogger
var stats := {"battles": 0, "victories": 0, "deaths": 0, "continues": 0, "offers": 0, "joined": 0,
	"duels": 0, "auto_turns": 0, "three_heroes": 0, "map_steps": 0, "timeouts": 0}


class SoakLogger extends Logger:
	var sink: Array[String]

	func _init(target: Array[String]) -> void:
		sink = target

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		# Ruído conhecido do motor ao sair (não é do jogo).
		if file.begins_with("core/") or file.begins_with("servers/") or file.begins_with("./core"):
			return
		sink.append("[%d] %s:%d %s %s %s" % [error_type, file, line, function, code, rationale])

	func _log_message(_message: String, _error: bool) -> void:
		pass


func _initialize() -> void:
	call_deferred("_run")


func _fail(text: String) -> void:
	failures.append(text)
	print("SOAK FAIL: ", text)


func _run() -> void:
	logger = SoakLogger.new(errors)
	OS.add_logger(logger)
	var args := OS.get_cmdline_user_args()
	var battles := int(args[0]) if args.size() > 0 else 40
	var seed := int(args[1]) if args.size() > 1 else 1
	var maps := int(args[2]) if args.size() > 2 else 40
	var sandbox := "user://soak_progress_guard.json"
	ProgressStore.save_path_override = sandbox
	ProgressStore.clear()
	var gains_before := ProgressStore.load_gains()
	var run_backup := FileAccess.get_file_as_string(SurvivalState.SAVE_PATH) if FileAccess.file_exists(SurvivalState.SAVE_PATH) else ""
	for i in battles:
		await _soak_battle(seed * 100_003 + i)
	for i in maps:
		await _soak_map(seed * 7_919 + i)
	if ProgressStore.load_gains() != gains_before:
		_fail("campaign ProgressStore changed")
	OS.remove_logger(logger)
	ProgressStore.clear()
	ProgressStore.save_path_override = ""
	if run_backup.is_empty():
		SurvivalState.clear()
	else:
		var f := FileAccess.open(SurvivalState.SAVE_PATH, FileAccess.WRITE)
		f.store_string(run_backup)
		f.close()
	for e in errors:
		_fail("script error: " + e)
	print("SOAK STATS: ", stats)
	print("SOAK RESULT: %d battles, %d map rounds, %d failures" % [battles, maps, failures.size()])
	quit(1 if not failures.is_empty() else 0)


# ------------------------------------------------------------------ invariantes

func _check_state(where: String) -> void:
	var s := SurvivalState.data()
	if not SurvivalState._valid_state(s.duplicate(true)):
		_fail("%s: save state is invalid (_valid_state): culprit %s" % [where, _invalid_keys(s)])
	var party: Array = s.get("party", [])
	var reserve: Array = s.get("reserve", [])
	if party.size() > SurvivalAllies.PARTY_MAX or reserve.size() > SurvivalAllies.RESERVE_MAX:
		_fail("%s: party %d / reserve %d over the cap" % [where, party.size(), reserve.size()])
	var owners := {}
	for id in s.get("fallen_relics", []):
		owners[id] = int(owners.get(id, 0)) + 1
	for list in [party, reserve]:
		for m in list:
			var top := SurvivalState.member_max_hp(m)
			var hp := SurvivalState.member_hp(m)
			if bool(m.get("down", false)) != (hp == 0):
				_fail("%s: %s down=%s but hp=%d" % [where, m.name, m.down, hp])
			if hp > top or hp < 0:
				_fail("%s: %s hp %d outside 0..%d" % [where, m.name, hp, top])
			if (m.relics as Array).size() > SurvivalRelics.cap_of(m):
				_fail("%s: %s over the relic cap" % [where, m.name])
			for id in m.relics:
				owners[id] = int(owners.get(id, 0)) + 1
				if not (s.get("relics", []) as Array).has(id):
					_fail("%s: %s wears unowned relic %s" % [where, m.name, id])
			if String(m.kind) == "yoch" and SurvivalAllies.yoch_base_stats(SurvivalState.fallen_sp()).sp_value() != SurvivalState.fallen_sp():
				_fail("%s: Yoch SP drifted from the Fallen's" % where)
	for id in owners.keys():
		if int(owners[id]) > 1:
			_fail("%s: relic %s worn twice" % [where, id])
	if int(s.get("fallen_hp", 0)) < 1 or int(s.get("fallen_hp", 0)) > SurvivalState.fallen_max_hp():
		_fail("%s: fallen_hp %d outside 1..%d" % [where, int(s.fallen_hp), SurvivalState.fallen_max_hp()])


# ------------------------------------------------------------------ batalha

func _random_member(uid: String) -> Dictionary:
	var roll := rng.randi_range(0, 9)
	var st := rng.randi_range(1, 5)
	var m: Dictionary
	if roll == 0:
		m = SurvivalAllies.yoch_member(uid)
	elif roll <= 2:
		var hid: String = SurvivalData.human_unit_ids(st)[rng.randi_range(0, 2)]
		m = SurvivalAllies.new_member(uid, hid, SurvivalAllies.stats_like_battle(hid, 73), rng.randi())
	else:
		var ids := SurvivalStrata.ids_for(st)
		var id: String = ids[rng.randi_range(0, ids.size() - 1)]
		m = SurvivalAllies.new_member(uid, id, SurvivalAllies.stats_like_battle(id, 73), rng.randi())
	m["auto"] = rng.randf() < 0.5
	if rng.randf() < 0.15:
		m["down"] = true
		m["hp"] = 0
	return m


func _soak_battle(seed: int) -> void:
	rng.seed = seed
	SurvivalState.reset()
	var stratum := rng.randi_range(1, 5)
	var ids := SurvivalStrata.ids_for(stratum)
	var enc: String = ids[rng.randi_range(0, ids.size() - 1)]
	if rng.randf() < 0.15:
		enc = SurvivalData.human_group_id(stratum)
	var party: Array = []
	for i in rng.randi_range(0, 2):
		party.append(_random_member("s%d_%d" % [seed, i]))
	var ent := SurvivalStrata.entrance(stratum)
	var patch := {"seed": seed, "stratum": stratum, "cell": [ent.x, ent.y], "encounter_id": enc, "party": party,
		"battles": rng.randi_range(0, 30), "bead": rng.randi_range(0, 2), "chakra": rng.randi_range(0, 2),
		"gains": {"max_hp": rng.randi_range(0, 60), "max_en": 0, "atk": rng.randi_range(0, 12), "mak": rng.randi_range(0, 6),
			"defense": rng.randi_range(0, 6), "mef": 0, "agi": rng.randi_range(0, 10)}}
	# Luta-teste às vezes.
	if rng.randf() < 0.2:
		var cand: String = ids[rng.randi_range(0, ids.size() - 2)]
		patch["encounter_id"] = cand
		patch["duel"] = {"encounter": "s%d_r0" % stratum, "candidate": cand,
			"stats": SurvivalAllies.stats_like_battle(cand, 73),
			"snapshot": {"fallen_hp": 26, "fallen_en": 12, "party": party.duplicate(true), "continues": 3}}
		stats.duels += 1
	SurvivalState.patch(patch)
	var errors_before := errors.size()
	var b: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	b.suppress_scene_change = true
	root.add_child(b)
	stats.battles += 1
	var fighting := 0
	for u in party:
		if not bool(u.down): fighting += 1
	if fighting == 2:
		stats.three_heroes += 1
	var frames := 0
	var tag := "battle seed %d (%s, %d allies)" % [seed, patch.encounter_id, party.size()]
	while frames < FRAME_LIMIT:
		frames += 1
		await process_frame
		if not is_instance_valid(b) or b.hud == null:
			break
		if b.left_to_title:
			stats.deaths += 1
			break
		if b.hud.mode == "result":
			stats.victories += int(b.state.player_victory())
			break
		_bot_step(b)
	if frames >= FRAME_LIMIT:
		stats.timeouts += 1
		_fail("%s: no end after %d frames (mode %s, log %s)" % [tag, FRAME_LIMIT, b.hud.mode, str(b.log_history.slice(maxi(0, b.log_history.size() - 4)))])
	if is_instance_valid(b):
		stats.auto_turns += "\n".join(b.log_history).count("(AUTO)")
		# Aliados em AUTO nunca abrem barra de ataque.
		for line in b.log_history:
			for u in b._members:
				if b.is_auto(u) and line.begins_with("ATTACK: %s" % u.display_name):
					_fail("%s: AUTO %s opened an attack bar" % [tag, u.display_name])
		if not b.duel and b.hud.players.size() != 1 + fighting:
			_fail("%s: %d heroes on screen, expected %d" % [tag, b.hud.players.size(), 1 + fighting])
		b.queue_free()
	await process_frame
	if errors.size() > errors_before:
		_fail("%s: %d script error(s), first: %s" % [tag, errors.size() - errors_before, errors[errors_before]])
	if not left_or_cleared():
		_check_state(tag)


func left_or_cleared() -> bool:
	return not Engine.has_meta(SurvivalState.META_KEY)


## Uma decisão do bot para o modo atual do HUD.
func _bot_step(b: Control) -> void:
	var hud: Control = b.hud
	if rng.randf() < 0.35:
		return # deixa animações e esperas rodarem
	match String(hud.mode):
		"plan":
			var n: int = hud.plan_options.size()
			if n == 0 or rng.randf() < 0.25:
				b.exec_plan()
			else:
				var i := rng.randi_range(0, n - 1)
				if String(hud.plan_options[i]) == "PARTY":
					stats["party_opened"] = int(stats.get("party_opened", 0)) + 1
				b.submit_plan(i)
		"command":
			var n: int = hud.command_options.size()
			if n > 0:
				b.submit_command(rng.randi_range(0, n - 1))
			else:
				b.handle_back()
		"target":
			var units: Array = b.target_units()
			var alive: Array[int] = []
			for i in units.size():
				if units[i].is_alive(): alive.append(i)
			if alive.is_empty() or rng.randf() < 0.05:
				b.handle_back()
			else:
				b.submit_target(alive[rng.randi_range(0, alive.size() - 1)])
		"timing":
			if b.rhythm._running and rng.randf() < 0.3:
				b.rhythm.press()
		"counter":
			if rng.randf() < 0.3:
				b.counter.press_player()
		"skill", "pray", "item":
			var n: int = hud.command_options.size()
			if n == 0 or rng.randf() < 0.1:
				b.handle_back()
			else:
				hud.command_index = rng.randi_range(0, n - 1)
				b.handle_confirm()
		"en_extra":
			b.handle_confirm()
		"react":
			if rng.randf() < 0.2:
				hud.react_index = 0
				b.handle_confirm()
			else:
				b.handle_back()
		"absorb":
			b.register_mash_press()
		"absorb_choice":
			b.submit_absorb_choice(rng.randi_range(0, maxi(0, b.absorb_options.size() - 1)))
		"continue", "announce", "turn":
			b.handle_confirm()
		"death":
			if b.continue_prompt_open:
				stats.continues += 1
				b.answer_continue(rng.randf() < 0.8)
		"party":
			b.overlay_key([KEY_UP, KEY_DOWN, KEY_Z, KEY_X][rng.randi_range(0, 3)])
		"offer":
			stats.offers += 1
			var yes := rng.randf() < 0.6
			stats.joined += int(yes)
			b.answer_offer(yes)
		_:
			pass


# ------------------------------------------------------------------ mapa

func _soak_map(seed: int) -> void:
	rng.seed = seed
	SurvivalState.reset()
	var stratum := rng.randi_range(2, 5)
	var party: Array = []
	for i in rng.randi_range(0, 2):
		party.append(_random_member("w%d_%d" % [seed, i]))
	var reserve: Array = []
	for i in rng.randi_range(0, 8):
		reserve.append(_random_member("r%d_%d" % [seed, i]))
	SurvivalState.patch({"seed": seed, "stratum": stratum, "cell": [12, 10], "macca": rng.randi_range(0, 3000),
		"party": party, "reserve": reserve, "bead": rng.randi_range(0, 3), "chakra": rng.randi_range(0, 3),
		"medicine": rng.randi_range(0, 2), "soma": rng.randi_range(0, 1),
		"relics": SurvivalRelics.all_ids().slice(0, rng.randi_range(1, 10))})
	_check_state("map seed %d start" % seed)
	var errors_before := errors.size()
	var w: Node = load(SurvivalData.WORLD_SCENE).instantiate()
	w.battle_scene = ""
	root.add_child(w)
	await process_frame
	var tag := "map seed %d (s%d)" % [seed, stratum]
	for step in 60:
		stats.map_steps += 1
		_map_action(w)
		await process_frame
		_check_state("%s step %d" % [tag, step])
	w.queue_free()
	await process_frame
	if errors.size() > errors_before:
		_fail("%s: %d script error(s), first: %s" % [tag, errors.size() - errors_before, errors[errors_before]])


func _map_action(w: Node) -> void:
	# Fecha o que estiver aberto às vezes; senão age dentro do painel.
	if w.event_open:
		var opts: Array = w.event_options()
		if opts.is_empty() or rng.randf() < 0.2:
			w.close_event()
		else:
			w.event_index = rng.randi_range(0, opts.size() - 1)
			var id := String(opts[w.event_index].id)
			if id != "duel": # a luta-teste troca de cena; a batalha do soak cobre o duel
				w.confirm_event()
		return
	if w.menu_open:
		match rng.randi_range(0, 3):
			0: w.move_menu(1)
			1: w.move_menu(-1)
			2: w.confirm_menu()
			3: w.toggle_menu()
		return
	if w.hire_open:
		if rng.randf() < 0.5: w.confirm_hire()
		else: w.hire_open = false
		return
	if w.reserve_open:
		w.reserve_index = rng.randi_range(0, maxi(0, w.reserve_rows().size() - 1))
		if rng.randf() < 0.7: w.confirm_reserve()
		else: w.reserve_open = false
		return
	if w.relic_open:
		w.relic_index = rng.randi_range(0, maxi(0, w._owned_relics().size() - 1))
		w.relic_wearer = rng.randi_range(0, w.relic_wearers().size() - 1)
		if rng.randf() < 0.7: w._equip_relic()
		else: w._close_relics()
		return
	if w.shop_open:
		w.close_shop()
		return
	if w.service_open:
		w.close_service()
		return
	match rng.randi_range(0, 7):
		0: w.toggle_menu()
		1: w.open_hire()
		2: w.open_reserve()
		3: w._open_relics()
		4:
			SurvivalState.patch({"heals_used": 0})
			SurvivalState.sanctuary_heal()
			w._sync_party_from_state()
		5, 6:
			var npcs: Array = w.npcs.filter(func(n: Dictionary) -> bool: return String(n.get("role", "")) in ["recruit", "yoch"])
			if not npcs.is_empty():
				var npc: Dictionary = npcs[rng.randi_range(0, npcs.size() - 1)]
				w.cell = npc.cell
				w.talk()
		7:
			var m: Array = SurvivalState.party()
			if not m.is_empty():
				w.use_item_on_map(["bead", "chakra", "medicine", "soma"][rng.randi_range(0, 3)], String(m[rng.randi_range(0, m.size() - 1)].uid))


## Debug: quais chaves, trocadas pelo padrão, tornam o save válido de novo.
func _invalid_keys(s: Dictionary) -> String:
	var defaults := SurvivalState._default_state()
	var out: Array[String] = []
	for k in defaults.keys():
		var copy := s.duplicate(true)
		copy[k] = defaults[k]
		if SurvivalState._valid_state(copy):
			out.append("%s=%s" % [k, str(s.get(k)).left(160)])
	return str(out) if not out.is_empty() else "(several keys)"
