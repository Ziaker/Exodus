extends SceneTree
## D-129: captura visual das cenas reais de exploração (Floater Eyes voando junto de humano e
## de Mazik) e das duas batalhas de exemplo pedidas (1 humano + olhos; 1 Mazik + olhos),
## mostrando formação, silhuetas 2D verdes, alvo do buff e consumo de EN.

const OUT_DIR := "res://captures/floater_eyes"


func _initialize() -> void:
	call_deferred("_run")


func _find_seed(id: String, count: int) -> int:
	for seed in range(1, 5000):
		if SurvivalData.floater_eye_count(seed, id) == count:
			return seed
	return 1


func _snap(filename: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var full := ProjectSettings.globalize_path(OUT_DIR + "/" + filename)
	img.save_png(full)
	print("CAPTURED ", full, " size=", img.get_size())


func _wait_mode(b: Control, wanted: String, limit: int = 240) -> void:
	for _i in limit:
		if b.hud != null and b.hud.mode == wanted:
			return
		if b.hud != null and b.hud.mode == "react" and wanted != "react":
			b.handle_back()
		if b.hud != null and b.hud.mode in ["continue", "announce"] and wanted not in ["continue", "announce"]:
			b.proceed()
		await process_frame


func _capture_corridor(run_seed: int, enemy_id: String, filename: String) -> void:
	SurvivalState.reset()
	SurvivalState.patch({"seed": run_seed, "stratum": 1})
	var world: Control = load(SurvivalData.WORLD_SCENE).instantiate()
	world.battle_scene = ""
	world.enemies_enabled = false
	root.add_child(world)
	await process_frame
	await process_frame

	# Posiciona o jogador a 2 células de frente para o inimigo escolhido (com vista limpa)
	var target_cell := Vector2i(12, 8)
	for e in world.enemies.entries:
		if String(e.id) == enemy_id:
			e.cell = target_cell
			var sp: Sprite3D = world.enemy_sprites.get(enemy_id)
			if sp != null:
				sp.position = world._enemy_sprite_position(target_cell)
			break
	# Afasta o NPC do santuário se ocupar a célula intermediária
	world.cell = Vector2i(12, 10)
	world.facing = 0 # Norte -> olhando para (12, 8)
	world.npc_picture.visible = false
	world._snap_to_state()
	world._update_floater_sprites()
	world._redraw()
	await _snap(filename)
	world.queue_free()
	await process_frame


func _capture_battle_pair(enc_id: String, run_seed: int, stratum: int, start_file: String, buff_file: String, skill: StringName) -> void:
	SurvivalState.reset()
	SurvivalState.patch({
		"seed": run_seed,
		"encounter_id": enc_id,
		"stratum": stratum,
		"party": [],
		"gains": {"max_hp": 0, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": 30},
	})
	var b: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	b.suppress_scene_change = true
	root.add_child(b)
	await _wait_mode(b, "plan")
	# Frame 1: formação, silhuetas verdes e intenções apontando para o humano/Mazik
	await _snap(start_file)

	# Frame 2: Floater Eye A lança o buff no aliado principal, consumindo EN e registrando no log
	var eye: BattleUnit = b.hud.opponents[1]
	var host: BattleUnit = b.hud.opponents[0]
	var en_before := eye.current_en
	b.turn_owner = eye
	if b.intents.has(eye.id):
		b.intents[eye.id].used = true
	b.hud.page_log()
	await b._enemy_skill(eye, skill)
	b._refresh_all()
	for _f in 6:
		await process_frame
	print("EXAMPLE %s: host=%s eye=%s skill=%s EN %d->%d host_atk_stages=%d host_def_stages=%d" % [
		enc_id, host.display_name, eye.display_name, skill, en_before, eye.current_en,
		host.atk_stages.size(), host.def_round_stages.size()])
	await _snap(buff_file)
	b.queue_free()
	await process_frame


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var h_seed := _find_seed("humans_s1", 2)
	var m_seed := _find_seed("jack_frost", 2)
	var m5_seed := _find_seed("izanami", 2)

	await _capture_corridor(h_seed, "humans_s1", "01_dungeon_human_floaters.png")
	await _capture_corridor(m_seed, "jack_frost", "02_dungeon_mazik_floaters.png")
	await _capture_battle_pair("humans_s1", h_seed, 1, "03_battle_human_start.png", "04_battle_human_buff.png", &"verdant_might")
	await _capture_battle_pair("izanami", m5_seed, 5, "05_battle_mazik_start.png", "06_battle_mazik_buff.png", &"verdant_shell")

	SurvivalState.clear()
	quit(0)
