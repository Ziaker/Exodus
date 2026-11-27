extends SceneTree
## D-129: grava vídeos REAIS (30 fps, 816x624) dos Floater Eyes na versão atual (main):
##   1) corridor -> exploração 3D na Necrópole Saturnina (Humano + 2 olhos e Mazik + 2 olhos)
##   2) human    -> batalha 1 Humano + 2 Floater Eyes (palco 3D, buffs, consumo EN, 1-hit kill)
##   3) mazik    -> batalha 1 Mazik + 2 Floater Eyes (AEGIS IRIS, VERDANT SHELL, REST, fuga órfã -> VICTORY)
##
## Uso:
##   .\Godot_v4.7.2-stable_win64_console.exe --path . --write-movie captures/floater_eyes/<nome>.avi \
##     --fixed-fps 30 --resolution 816x624 -s tools/record_floater_eyes.gd -- <corridor|human|mazik>

const R := BattleMath.RhythmResult


func _initialize() -> void:
	call_deferred("_run")


func _find_seed(id: String, count: int) -> int:
	for seed in range(1, 5000):
		if SurvivalData.floater_eye_count(seed, id) == count:
			return seed
	return 1


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _secs(s: float) -> void:
	await create_timer(s).timeout


func _wait_mode(b: Control, wanted: String, limit: int = 240) -> void:
	for _i in limit:
		if b.hud != null and b.hud.mode == wanted:
			return
		if b.hud != null and b.hud.mode == "react" and wanted != "react":
			b.handle_back()
		if b.hud != null and b.hud.mode in ["continue", "announce"] and wanted not in ["continue", "announce"]:
			b.proceed()
		await process_frame


func _wait_fx(b: Control, max_frames: int = 120) -> void:
	for _i in max_frames:
		var busy := false
		if b.fx != null and b.fx.is_busy():
			busy = true
		if b.grotesque_fx != null and b.grotesque_fx.is_busy():
			busy = true
		if not busy:
			break
		await process_frame


func _record_corridor() -> void:
	var h_seed := _find_seed("humans_s1", 2)
	var m_seed := _find_seed("jack_frost", 2)

	# Parte 1: Humano + 2 Floater Eyes voando no corredor 3D da Necrópole Saturnina
	SurvivalState.reset()
	SurvivalState.patch({"seed": h_seed, "stratum": 1})
	var world: Control = load(SurvivalData.WORLD_SCENE).instantiate()
	world.battle_scene = ""
	world.enemies_enabled = false
	root.add_child(world)
	await _frames(6)
	var target_cell := Vector2i(12, 8)
	for e in world.enemies.entries:
		if String(e.id) == "humans_s1":
			e.cell = target_cell
			var sp: Sprite3D = world.enemy_sprites.get("humans_s1")
			if sp != null:
				sp.position = world._enemy_sprite_position(target_cell)
			break
	world.cell = Vector2i(12, 10)
	world.facing = 0
	world.npc_picture.visible = false
	world._snap_to_state()
	world._update_floater_sprites()
	world._redraw()
	await _secs(1.6)
	# Aproxima 1 célula para mostrar os olhos flutuando de perto
	world.cell = Vector2i(12, 9)
	world._snap_to_state()
	world._update_floater_sprites()
	world._redraw()
	await _secs(1.8)
	world.queue_free()
	await _frames(4)

	# Parte 2: Mazik (Jack Frost) + 2 Floater Eyes voando no corredor 3D
	SurvivalState.reset()
	SurvivalState.patch({"seed": m_seed, "stratum": 1})
	world = load(SurvivalData.WORLD_SCENE).instantiate()
	world.battle_scene = ""
	world.enemies_enabled = false
	root.add_child(world)
	await _frames(6)
	for e in world.enemies.entries:
		if String(e.id) == "jack_frost":
			e.cell = target_cell
			var sp2: Sprite3D = world.enemy_sprites.get("jack_frost")
			if sp2 != null:
				sp2.position = world._enemy_sprite_position(target_cell)
			break
	world.cell = Vector2i(12, 10)
	world.facing = 0
	world.npc_picture.visible = false
	world._snap_to_state()
	world._update_floater_sprites()
	world._redraw()
	await _secs(1.6)
	world.cell = Vector2i(12, 9)
	world._snap_to_state()
	world._update_floater_sprites()
	world._redraw()
	await _secs(1.8)
	world.queue_free()
	await _frames(3)


func _record_human_battle() -> void:
	var h_seed := _find_seed("humans_s1", 2)
	SurvivalState.reset()
	SurvivalState.patch({
		"seed": h_seed,
		"encounter_id": "humans_s1",
		"stratum": 1,
		"party": [],
		"gains": {"max_hp": 0, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": 30},
	})
	var b: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	b.suppress_scene_change = true
	root.add_child(b)
	await _wait_mode(b, "plan")
	await _secs(1.5)

	var human: BattleUnit = b.hud.opponents[0]
	var eye_a: BattleUnit = b.hud.opponents[1]
	var eye_b: BattleUnit = b.hud.opponents[2]

	# Buff 1: Floater Eye A lança VERDANT MIGHT no Humano (EN 24 -> 16)
	b.hud.mode = "busy"
	b.turn_owner = eye_a
	b.hud.page_log()
	await b._enemy_skill(eye_a, &"verdant_might")
	b._refresh_all()
	await _wait_fx(b)
	await _secs(1.8)

	# Buff 2: Floater Eye B lança KEEN GAZE no Humano (EN 24 -> 16)
	b.turn_owner = eye_b
	b.hud.page_log()
	await b._enemy_skill(eye_b, &"keen_gaze")
	b._refresh_all()
	await _wait_fx(b)
	await _secs(1.8)

	# Fallen elimina Floater Eye A em 1 golpe (baixa durabilidade: HP 8)
	b.turn_owner = b._fallen
	b.hud.page_log()
	b._set_role(b._fallen, "ATTACK")
	b._set_role(eye_a, "TARGET")
	b._event("FALLEN attacks FLOATER EYE A.")
	var hp_before := eye_a.current_hp
	b._apply_strike(b._fallen, eye_a, b.basic_power, false, R.POINT, R.MISS, false)
	b._present_strike(b._fallen, eye_a, hp_before - eye_a.current_hp)
	b._refresh_all()
	await _wait_fx(b)
	await _secs(2.0)

	print("REC_HUMAN_OK: human_atk=%d human_agi=%d eye_a_alive=%s eye_a_en=%d eye_b_en=%d" % [
		human.atk_stages.size(), human.effective_agi(), str(eye_a.is_alive()), eye_a.current_en, eye_b.current_en])
	b.queue_free()
	await _frames(3)


func _record_mazik_battle() -> void:
	var m_seed := _find_seed("jack_frost", 2)
	SurvivalState.reset()
	SurvivalState.patch({
		"seed": m_seed,
		"encounter_id": "jack_frost",
		"stratum": 1,
		"party": [],
		"gains": {"max_hp": 0, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": 30},
	})
	var b: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	b.suppress_scene_change = true
	root.add_child(b)
	await _wait_mode(b, "plan")
	await _secs(1.5)

	var mazik: BattleUnit = b.hud.opponents[0]
	var eye_a: BattleUnit = b.hud.opponents[1]
	var eye_b: BattleUnit = b.hud.opponents[2]

	# Buff 1: Floater Eye A lança AEGIS IRIS (5o buff, status shield não-reza) no Mazik (EN 24 -> 16)
	b.hud.mode = "busy"
	b.turn_owner = eye_a
	b.hud.page_log()
	await b._enemy_skill(eye_a, &"aegis_iris")
	b._refresh_all()
	await _wait_fx(b)
	await _secs(1.8)

	# Buff 2: Floater Eye B lança VERDANT SHELL (+DEF/+MEF) no Mazik (EN 24 -> 16)
	b.turn_owner = eye_b
	b.hud.page_log()
	await b._enemy_skill(eye_b, &"verdant_shell")
	b._refresh_all()
	await _wait_fx(b)
	await _secs(1.8)

	# Sem EN suficiente (< 6 EN), Floater Eye A descansa (REST +2 EN, D-038)
	eye_a.current_en = 4
	b.turn_owner = eye_a
	b.hud.page_log()
	b._execute_rest(eye_a, false)
	b._refresh_all()
	await _wait_fx(b)
	await _secs(1.6)

	# Fallen derruba o Mazik principal -> Floater Eyes órfãos FOGEM automaticamente -> VICTORY
	b.turn_owner = b._fallen
	b.hud.page_log()
	b._set_role(b._fallen, "ATTACK")
	b._set_role(mazik, "TARGET")
	b._event("FALLEN strikes JACK FROST.")
	mazik.current_hp = 1
	b._apply_strike(b._fallen, mazik, b.basic_power, false, R.POINT, R.MISS, false)
	b._present_strike(b._fallen, mazik, 1)
	b._refresh_all()
	await _wait_fx(b)
	await _secs(1.4)

	b._clear_roles()
	b.turn_owner = eye_a
	b.hud.page_log()
	b._execute_flee(eye_a)
	await _secs(1.2)
	b.turn_owner = eye_b
	b._execute_flee(eye_b)
	await _secs(1.2)
	b.hud.announce("VICTORY")
	b._event("VICTORY.")
	b._refresh_all()
	await _secs(1.6)

	print("REC_MAZIK_OK: mazik_alive=%s eye_a_fled=%s eye_b_fled=%s eye_a_en=%d" % [
		str(mazik.is_alive()), str(eye_a.fled), str(eye_b.fled), eye_a.current_en])
	b.queue_free()
	await _frames(3)


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := String(args[0]) if args.size() > 0 else "human"
	match mode:
		"corridor": await _record_corridor()
		"human": await _record_human_battle()
		"mazik": await _record_mazik_battle()
		_:
			printerr("Modo desconhecido: ", mode)
			quit(1)
			return
	SurvivalState.clear()
	quit(0)
