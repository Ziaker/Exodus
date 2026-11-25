extends SceneTree
## Headless: regras roguelike de absorção do Survival (RNG semeado, 30% de
## habilidade nova, 3 opções, +1..4 num atributo) e persistência na run.

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


func _wait_mode(b: Control, wanted: String, limit: int = 240) -> bool:
	for _i in limit:
		if b.hud != null and b.hud.mode == wanted:
			return true
		if b.hud != null and b.hud.mode == "react":
			b.handle_back()
		await process_frame
	return false


## O mash é por tempo: bombeia os apertos enquanto a janela ABSORB está aberta.
func _pump_mash(b: Control) -> void:
	var seen := false
	for _i in 900:
		if not is_instance_valid(b) or b.hud == null:
			return
		if b.hud.mode == "absorb":
			seen = true
			b._mash_count = 12
		elif seen and b.hud.mode == "command":
			return
		await process_frame


func _run() -> void:
	var demon: Dictionary = SurvivalData.demon_by_id("cerberus")
	var owned: Array[StringName] = [&"lunge"]

	# 1000 sementes: ~30% das rolagens trazem habilidade nova; sempre 3 opções.
	var rng := RandomNumberGenerator.new()
	var skills := 0
	for seed in 1000:
		rng.seed = seed
		var options := SurvivalAbsorb.roll_options(rng, demon, owned)
		_check(options.size() == SurvivalAbsorb.OPTION_COUNT, "Seed %d offers exactly 3 options" % seed)
		var skill_options := 0
		var stats_seen := {}
		for option in options:
			if String(option.kind) == "skill":
				skill_options += 1
				_check(not owned.has(StringName(option.skill)), "New skill is not already owned")
				_check(not SkillBook.def(StringName(option.skill)).is_empty(), "New skill exists in SkillBook")
			else:
				_check(int(option.amount) >= 1 and int(option.amount) <= 4,
						"Stat amount in 1..4 (got %d)" % int(option.amount))
				_check(not stats_seen.has(String(option.stat)), "Stat options are distinct")
				stats_seen[String(option.stat)] = true
		skills += skill_options
	_check(absf(float(skills) / 1000.0 - SurvivalAbsorb.SKILL_CHANCE) < 0.05,
			"Skill chance is ~30%% (got %.1f%%)" % (float(skills) / 10.0))

	# Mesma semente => mesmas opções (reprodutível).
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 4242
	b.seed = 4242
	_check(str(SurvivalAbsorb.roll_options(a, demon, owned)) == str(SurvivalAbsorb.roll_options(b, demon, owned)),
			"Same run seed gives the same absorption draft")

	# Aplicação pura sem cena.
	var stats := UnitStats.new()
	var gains := {}
	var learned: Array[StringName] = []
	SurvivalAbsorb.apply_option(stats, gains, learned, {"kind": "stat", "stat": "atk", "amount": 4})
	_check(stats.atk == UnitStats.new().atk + 4 and int(gains.get("atk", 0)) == 4, "Stat choice adds up to +4")
	SurvivalAbsorb.apply_option(stats, gains, learned, {"kind": "skill", "skill": "hellfire"})
	_check(learned.size() == 1 and learned[0] == &"hellfire", "Skill choice learns the move")
	SurvivalAbsorb.apply_option(stats, gains, learned, {"kind": "skill", "skill": "hellfire"})
	_check(learned.size() == 1, "The same move is not learned twice")

	# Cada encontro da mesma run deve sortear uma oferta diferente (RNG derivado).
	SurvivalState.reset()
	SurvivalState.patch({"seed": 12345, "encounter_id": "pixie"})
	var s1: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	root.add_child(s1)
	SurvivalState.patch({"encounter_id": "beelzebub"})
	var s2: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	root.add_child(s2)
	SurvivalState.patch({"encounter_id": "pixie"})
	var b3: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	root.add_child(b3)
	await process_frame
	_check(s1.run_rng.get_state() != s2.run_rng.get_state(),
			"Different encounters in one run start with different RNG states")
	_check(s1.run_rng.get_state() == b3.run_rng.get_state(),
			"Same encounter and progress reproduce the same RNG state")
	# A rolagem de absorção usa o RNG da run, não o global da batalha.
	var rng_before: int = s1.run_rng.get_state()
	var battle_rng_before: int = s1.rng.get_state()
	s1._absorb_roll()
	_check(s1.run_rng.get_state() != rng_before and s1.rng.get_state() == battle_rng_before,
			"Absorb roll advances only the run RNG")
	s1.queue_free(); s2.queue_free(); b3.queue_free()
	await process_frame

	# Integração: absorver de verdade escolhe 1 de 3 e grava na run, sem tocar no ProgressStore.
	var sandbox := "user://test_survival_absorb_guard.json"
	ProgressStore.save_path_override = sandbox
	ProgressStore.clear()
	var gains_before := ProgressStore.load_gains()

	SurvivalState.reset()
	SurvivalState.patch({
		"seed": 777,
		"encounter_id": "cerberus",
		"gains": {"max_hp": 0, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": 20},
		"skills": [],
	})
	var battle: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	battle.suppress_scene_change = true
	root.add_child(battle)
	await _wait_mode(battle, "plan")
	for unit in battle.state.units:
		if unit != battle._fallen:
			unit.acts_available = 0
			unit.stored_acts = 0
	battle._refresh_all()

	var foe: BattleUnit = battle.hud.opponents[0]
	foe.current_sp = 0 # primeira pressão absorve
	var cmds: Array[String] = battle._commands(battle._fallen)
	_check(cmds.has("ABSORB"), "Fallen has the ABSORB command in Survival")
	_pump_mash(battle)
	battle.submit_plan(cmds.find("ABSORB"))
	battle.exec_plan()
	_check(await _wait_mode(battle, "target", 400), "ABSORB asks for a demon target")
	battle.submit_target(0)
	_check(await _wait_mode(battle, "absorb_choice", 600), "Absorption opens the 3-option reward panel")
	_check(battle.absorb_options.size() == 3, "Three reward rows on screen (%s)" % str(battle.absorb_options))
	var snapshot: Dictionary = SurvivalState.data().duplicate(true)
	battle.absorb_index = 0
	battle.absorb_chosen.emit()
	for _i in 240:
		if battle.hud.mode == "busy" or battle.hud.mode == "plan":
			break
		await process_frame
	var after: Dictionary = SurvivalState.data()
	var changed: bool = str(snapshot.get("gains")) != str(after.get("gains")) or str(snapshot.get("skills")) != str(after.get("skills"))
	_check(changed, "Chosen reward is written to the run immediately")
	_check(ProgressStore.load_gains() == gains_before, "Survival absorption never touches main ProgressStore")
	battle.queue_free()
	await process_frame

	SurvivalState.clear()
	ProgressStore.clear()
	ProgressStore.save_path_override = ""
	print("SURVIVAL ABSORB CHECKS PASSED: %d FAILED: %d" % [checks, int(failed)])
	quit(1 if failed else 0)
