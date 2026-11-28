extends SceneTree
## Verificação headless dos dados, skills, mapa (25x21 + conectividade BFS) e estado do Survival Mode.

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


func _run() -> void:
	_check(SurvivalData.DEMONS.size() == 35,
			"Survival roster has exactly 35 SMT demons (got %d)" % SurvivalData.DEMONS.size())

	_check(SurvivalData.MAZE.size() == 21, "Maze height is 21 (got %d)" % SurvivalData.MAZE.size())
	var starts := 0
	var start_cell := Vector2i(-1, -1)
	for y in SurvivalData.MAZE.size():
		var row := SurvivalData.MAZE[y]
		_check(row.length() == 25, "Maze row %d width is 25 (got %d)" % [y, row.length()])
		for x in row.length():
			if row[x] == "S":
				starts += 1
				start_cell = Vector2i(x, y)
	_check(starts == 1, "Maze has exactly one start cell 'S' (got %d)" % starts)

	# BFS a partir de 'S' para garantir que o mapa é conectado e todo NPC/demônio é alcançável.
	var reachable := {}
	var queue: Array[Vector2i] = [start_cell]
	reachable[start_cell] = true
	var dirs := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		for d in dirs:
			var nxt: Vector2i = cur + d
			if nxt.y < 0 or nxt.y >= SurvivalData.MAZE.size():
				continue
			if nxt.x < 0 or nxt.x >= SurvivalData.MAZE[nxt.y].length():
				continue
			if SurvivalData.MAZE[nxt.y][nxt.x] == "#" or reachable.has(nxt):
				continue
			reachable[nxt] = true
			queue.append(nxt)

	# Verifica NPC curandeiro/vendedor.
	_check(SurvivalData.NPCS.size() == 1, "Sanctuary has unified healer+vendor NPC")
	var npc: Dictionary = SurvivalData.NPCS[0]
	_check(ResourceLoader.exists(String(npc.picture)), "Healer/vendor SMT sprite exists: %s" % npc.picture)
	_check(reachable.has(npc.cell), "Healer/vendor cell %s is reachable from start" % str(npc.cell))
	_check(SurvivalData.SAFE_ZONE.has_point(npc.cell), "Healer/vendor is inside SAFE_ZONE")
	_check(SurvivalData.SAFE_ZONE.has_point(start_cell), "Start cell is inside SAFE_ZONE")

	# Verifica os 20 demônios: IDs, nomes, sprites, stats distintos, skills válidas, células únicas e alcançáveis.
	var ids := {}
	var names := {}
	var cells := {}
	var stat_signatures := {}
	var skill_signatures := {}
	for entry in SurvivalData.DEMONS:
		var id := String(entry.id)
		var dname := String(entry.name)
		var c: Vector2i = entry.cell
		_check(not ids.has(id), "Unique demon id: %s" % id)
		ids[id] = true
		_check(not names.has(dname), "Unique demon name: %s" % dname)
		names[dname] = true
		_check(not cells.has(c), "Unique demon cell %s for %s" % [str(c), id])
		cells[c] = true
		_check(reachable.has(c), "Demon %s cell %s is walkable and reachable" % [id, str(c)])
		_check(not SurvivalData.SAFE_ZONE.has_point(c), "Demon %s starts outside SAFE_ZONE" % id)
		_check(ResourceLoader.exists(String(entry.picture)), "SMT battler exists: %s" % entry.picture)
		var stats: Dictionary = entry.stats
		var sig_parts: Array[String] = []
		for key in ProgressStore.STAT_KEYS:
			var val := int(stats.get(key, 0))
			_check(val > 0, "Demon %s stat %s > 0 (got %d)" % [id, key, val])
			sig_parts.append(str(val))
		stat_signatures[",".join(sig_parts)] = true
		var skills: Array = entry.skills
		_check(skills.size() >= 2, "Demon %s has at least 2 placeholder skills" % id)
		var sk_parts: Array[String] = []
		for sk in skills:
			var def := SkillBook.def(StringName(sk))
			_check(not def.is_empty(), "Skill %s for %s exists in SkillBook" % [str(sk), id])
			sk_parts.append(String(sk))
		skill_signatures[",".join(sk_parts)] = true

	_check(stat_signatures.size() == 35,
			"All 35 demons have distinct stat profiles (got %d)" % stat_signatures.size())
	_check(skill_signatures.size() >= 30,
			"Demons have distinct placeholder skill kits (got %d)" % skill_signatures.size())
	_check(SurvivalData.encounter_for("pixie").size() == 1
			and SurvivalData.encounter_for("ganesha").size() == 2
			and SurvivalData.encounter_for("beelzebub").size() == 3,
			"Encounters scale 1/2/3 demons by tier")
	_check(SurvivalData.encounter_for("beelzebub").has("beelzebub"),
			"The touched demon always leads its encounter")
	for required in [&"vuln_pierce", &"blade_dance", &"umbral_gaze", &"renew", &"rock_body", &"mazz_bite", &"fang_sting", &"dark_breath", &"ignoma"]:
		_check(not SkillBook.def(required).is_empty(), "New placeholder skill exists: %s" % required)

	# Verifica que KIND_SKILLS do jogo base não foi alterado.
	_check(SkillBook.skills_of(&"genetic_foe_a") == [&"lunge", &"bleedbuff"], "Main game foe A skills untouched")
	_check(SkillBook.skills_of(&"genetic_foe_b") == [&"heat_wave", &"energy_eat"], "Main game foe B skills untouched")

	# Verifica SurvivalState sem tocar no ProgressStore.
	var sandbox := "user://test_survival_data_guard.json"
	ProgressStore.save_path_override = sandbox
	ProgressStore.clear()
	ProgressStore.save_gains({"atk": 6})
	var before_gains := ProgressStore.load_gains()

	var s := SurvivalState.reset()
	_check(int(s.continues) == 3, "Survival starts with 3 continues")
	_check(int(s.macca) == SurvivalData.STARTING_MACCA, "Survival starts with expected Macca")
	_check(SurvivalState.buy_item("bead"), "Buying BEAD succeeds with starting Macca")
	_check(int(SurvivalState.data().macca) == SurvivalData.STARTING_MACCA - 20, "Macca deducted on purchase")
	_check(int(SurvivalState.data().bead) == SurvivalData.STARTING_BEADS + 1, "BEAD count incremented")
	_check(SurvivalState.consume_item("bead"), "Consuming BEAD succeeds")
	var hurt := SurvivalAllies.yoch_member("data_y")
	hurt["hp"] = 2
	SurvivalState.patch({"fallen_hp": 1, "fallen_en": 0, "party": [hurt]})
	SurvivalState.heal_party_full()
	_check(int(SurvivalState.data().fallen_hp) == SurvivalState.fallen_max_hp(), "Healer restores Fallen HP")
	_check(int(SurvivalState.data().fallen_en) == SurvivalState.fallen_max_en(), "Healer restores Fallen EN")
	var healed: Dictionary = SurvivalState.party()[0]
	_check(SurvivalState.member_hp(healed) == SurvivalState.member_max_hp(healed), "Healer restores the ally's HP")
	_check(SurvivalState.reset().party.is_empty(), "D-111: a new run starts with the Fallen alone")
	var left := SurvivalState.use_continue()
	_check(left == 2, "Using continue decrements 3 -> 2 (got %d)" % left)
	_check(ProgressStore.load_gains() == before_gains, "SurvivalState never modifies ProgressStore")

	# Persistência da run em user://, isolada do ProgressStore.
	SurvivalState.patch({"macca": 77, "continues": 2, "defeated": ["pixie"]})
	_check(SurvivalState.has_save(), "Run autosaves to user://")
	Engine.remove_meta(SurvivalState.META_KEY)
	_check(SurvivalState.load_from_file(), "Saved run loads back")
	_check(int(SurvivalState.data().macca) == 77, "Macca survives reload (got %d)" % int(SurvivalState.data().macca))
	_check(int(SurvivalState.data().continues) == 2, "Continues survive reload")
	_check((SurvivalState.data().defeated as Array).has("pixie"), "Defeated demons survive reload")
	_check(ProgressStore.load_gains() == before_gains, "Run save never touches ProgressStore")

	SurvivalState.clear()
	_check(not SurvivalState.has_save(), "clear() erases the run save")

	# Migração: save antigo sem o campo `seed` não pode perder a run.
	var legacy: Dictionary = SurvivalState.reset()
	legacy.erase("seed")
	var lf := FileAccess.open(SurvivalState.SAVE_PATH, FileAccess.WRITE)
	lf.store_string(JSON.stringify({"version": SurvivalState.SAVE_VERSION, "state": legacy}))
	lf.close()
	Engine.remove_meta(SurvivalState.META_KEY)
	_check(SurvivalState.load_from_file(), "Legacy save without seed is migrated, not rejected")
	_check(int(SurvivalState.data().get("seed", 0)) > 0, "Migrated run gets a valid seed")
	_check(int(SurvivalState.data().macca) == int(legacy.macca), "Migrated run keeps Macca")
	SurvivalState.clear()
	ProgressStore.clear()
	ProgressStore.save_path_override = ""

	print("SURVIVAL DATA CHECKS PASSED: %d FAILED: %d" % [checks, int(failed)])
	quit(1 if failed else 0)
