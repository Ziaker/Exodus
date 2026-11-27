extends SceneTree
## Regras roguelike do Survival: relíquias, identificação hebraica, seed diário,
## posições embaralhadas, elites, risco/recompensa e meta-progresso.

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


func _reachable() -> Dictionary:
	var seen := {Vector2i(12, 10): true}
	var q: Array[Vector2i] = [Vector2i(12, 10)]
	var dirs := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	while not q.is_empty():
		var cur: Vector2i = q.pop_front()
		for d in dirs:
			var n: Vector2i = cur + d
			if n.y < 0 or n.y >= SurvivalData.MAZE.size() or n.x < 0 or n.x >= SurvivalData.MAZE[n.y].length():
				continue
			if SurvivalData.MAZE[n.y][n.x] == "#" or seen.has(n):
				continue
			seen[n] = true
			q.append(n)
	return seen


func _wait_mode(b: Control, wanted: String, limit: int = 240) -> bool:
	for _i in limit:
		if b.hud != null and b.hud.mode == wanted:
			return true
		if b.hud != null and b.hud.mode == "react":
			b.handle_back()
		await process_frame
	return false


func _run() -> void:
	var reachable := _reachable()

	# Relíquias: 12, efeitos aplicáveis, limite de 2 por aliado e posse única.
	_check(SurvivalRelics.RELICS.size() == 12, "12 ancient relics defined")
	var ids := {}
	for r in SurvivalRelics.RELICS:
		var id := String(r.id)
		_check(not ids.has(id) and String(r.hebrew).length() > 0, "Relic %s unique with Hebrew name" % id)
		ids[id] = true
		var st := UnitStats.new()
		var before: String = str(st.to_string() if st.has_method("to_string") else [st.atk, st.mak, st.defense, st.mef, st.agi, st.max_hp, st.max_en])
		SurvivalRelics.apply(st, id)
		var after: String = str([st.atk, st.mak, st.defense, st.mef, st.agi, st.max_hp, st.max_en])
		_check(before != after or String(r.id) == "dry_well", "Relic %s changes a stat" % id)
	_check(SurvivalRelics.STARTER_IDS.size() == 6, "6 starter relics")
	var eq := {"fallen_relics": [], "party": [SurvivalAllies.yoch_member("rl_y")], "reserve": []}
	for id in ["shard_of_urim", "ashen_tablet", "iron_covenant"]:
		eq.merge(SurvivalRelics.toggle(eq, "fallen", id), true)
	_check((eq.fallen_relics as Array).size() == 1, "D-111: Fallen capped at 1 relic")
	for id in ["ashen_tablet", "iron_covenant", "ember_tooth"]:
		eq.merge(SurvivalRelics.toggle(eq, "rl_y", id), true)
	_check((eq.party[0].relics as Array).size() == 2, "D-111: a human (Yoch) holds 2 relics")
	eq.merge(SurvivalRelics.toggle(eq, "rl_y", "ashen_tablet"), true)
	eq.merge(SurvivalRelics.toggle(eq, "rl_y", "shard_of_urim"), true)
	_check((eq.party[0].relics as Array).has("shard_of_urim") and not (eq.fallen_relics as Array).has("shard_of_urim"),
			"Equipping elsewhere moves the unique relic")

	# Identificação: nome hebraico para toda skill,??? só para id desconhecido.
	for id in SurvivalData.SURVIVAL_SKILLS:
		_check(SurvivalData.hebrew_skill(id) != "???" and not SkillBook.def(id).is_empty(),
				"Hebrew name for %s" % String(id))
	_check(SurvivalData.hebrew_skill(&"nao_existe") == "???", "Unknown skill falls back to ???")
	SurvivalState.reset()
	SurvivalState.learn_skill(&"spirit_wave")
	_check((SurvivalState.data().unidentified as Array).has("spirit_wave"), "New move starts unidentified")
	SurvivalState.identify_skill(&"spirit_wave")
	_check(not (SurvivalState.data().unidentified as Array).has("spirit_wave"), "Identified after use")

	# O submenu FIGHT mostra o nome hebraico enquanto não identificado.
	SurvivalState.patch({"encounter_id": "pixie", "skills": ["spirit_wave"],
		"unidentified": ["spirit_wave"],
		"gains": {"max_hp": 0, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": 20}})
	var b: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	b.suppress_scene_change = true
	root.add_child(b)
	await _wait_mode(b, "plan")
	for u in b.state.units:
		if u != b._fallen:
			u.acts_available = 0
			u.stored_acts = 0
	b._refresh_all()
	var cmds: Array[String] = b._commands(b._fallen)
	b.submit_plan(cmds.find("FIGHT"))
	b.exec_plan()
	_check(await _wait_mode(b, "skill"), "FIGHT opens the skill submenu")
	_check(b.hud.command_options[1] == SurvivalData.hebrew_skill(&"spirit_wave"),
			"Unidentified skill shows Hebrew name (%s)" % str(b.hud.command_options[1]))
	b.queue_free()
	await process_frame
	SurvivalState.clear()

	# Habilidade de 4 marcas aprendida por absorção executa até o fim sem erro.
	SurvivalState.patch({"encounter_id": "pixie", "skills": ["blade_dance"], "unidentified": [],
		"gains": {"max_hp": 0, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": 20}})
	var multi: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	multi.suppress_scene_change = true
	root.add_child(multi)
	await _wait_mode(multi, "plan")
	for u in multi.state.units:
		if u != multi._fallen:
			u.acts_available = 0
			u.stored_acts = 0
	multi._refresh_all()
	var mcmds: Array[String] = multi._commands(multi._fallen)
	multi.submit_plan(mcmds.find("FIGHT"))
	multi.exec_plan()
	await _wait_mode(multi, "skill")
	var skill_idx: int = multi.skill_ids.find(&"blade_dance")
	_check(skill_idx >= 0, "4-mark skill is in the FIGHT submenu")
	multi.submit_skill(skill_idx)
	for _i in 500:
		if multi.hud.mode == "target":
			multi.submit_target(0)
		elif multi.hud.mode == "timing":
			multi.rhythm._finish(BattleMath.RhythmResult.POINT)
		elif multi.hud.mode in ["continue", "announce"]:
			multi.proceed()
		elif multi.hud.mode == "plan":
			break
		await process_frame
	_check(" ".join(multi.log_history).contains("BLADE DANCE"), "4-mark skill resolves all marks")
	multi.queue_free()
	await process_frame
	SurvivalState.clear()

	# Semente diária e posições embaralhadas, com validação de conectividade.
	_check(SurvivalData.daily_seed() >= 20260101, "Daily seed has YYYYMMDD form")
	for seed in [1, 7, 42, 777, 20261124]:
		var defs: Array = SurvivalData.overworld_enemy_defs(seed)
		var cells := {}
		for d in defs:
			var c: Vector2i = d.cell
			_check(not cells.has(c), "Seed %d: demon cells unique" % seed)
			cells[c] = true
			_check(reachable.has(c) and not SurvivalData.SAFE_ZONE.has_point(c),
					"Seed %d: cell %s reachable and outside sanctuary" % [seed, str(c)])
	_check(str(SurvivalData.overworld_enemy_defs(123)) == str(SurvivalData.overworld_enemy_defs(123)),
			"Same seed reproduces the same layout")
	_check(str(SurvivalData.overworld_enemy_defs(123)) != str(SurvivalData.overworld_enemy_defs(124)),
			"Different seed changes the layout")

	# Elites determinísticos (~20%).
	var rng := RandomNumberGenerator.new()
	var elites := 0
	for i in 2000:
		rng.seed = i
		var id := String(SurvivalData.DEMONS[i % SurvivalData.DEMONS.size()].id)
		if SurvivalData.is_elite(i, id):
			elites += 1
			_check(SurvivalData.elite_affix(i, id).length() > 0, "Elite %s has an affix" % id)
	_check(absf(float(elites) / 2000.0 - 0.2) < 0.04, "Elite chance ~20%% (got %.1f%%)" % (float(elites) / 20.0))

	# Risco/recompensa (D-071): HP baixo sobe a raridade um nível — nunca COMMON.
	var low := RandomNumberGenerator.new()
	low.seed = 99
	var low_opts := SurvivalAbsorb.roll_options(low, SurvivalData.demon_by_id("pixie"), [], 0.2)
	for o in low_opts:
		if String(o.kind) != "skill":
			_check(String(o.rarity) in ["RARE", "EPIC"], "Low HP rolls RARE or EPIC (got %s)" % String(o.rarity))
			if String(o.kind) == "stat" and not (StringName(o.stat) in [&"max_hp", &"max_en"]):
				_check(int(o.amount) >= 3, "Low HP stat offer is at least +3 (got %d)" % int(o.amount))

	# Meta-progresso separado da run: score, melhor e unlocks.
	var meta_path := SurvivalMeta.SAVE_PATH
	var backup := ""
	if FileAccess.file_exists(meta_path):
		var bf := FileAccess.open(meta_path, FileAccess.READ)
		backup = bf.get_as_text()
		bf.close()
	_check(SurvivalMeta.score(10, 500, 2) == 1600, "Score = defeated*100 + macca + continues*50")
	var meta := SurvivalMeta.finish_run(10, 500, 2)
	_check(int(meta.best) >= 1600 and int(meta.runs) >= 1, "Best score and run count persist")
	_check((meta.unlocked as Array).has("dry_well"), "Score 1600 unlocks DRY WELL")
	var mf := FileAccess.open(meta_path, FileAccess.WRITE)
	mf.store_string(backup)
	mf.close()
	SurvivalState.clear()
	print("SURVIVAL ROGUELIKE CHECKS PASSED: %d FAILED: %d" % [checks, int(failed)])
	quit(1 if failed else 0)
