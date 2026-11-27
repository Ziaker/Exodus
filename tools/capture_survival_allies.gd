extends SceneTree
## Capturas reais (janela aberta) dos aliados do Survival (D-111) para a auditoria visual:
## batalha só com o Fallen, batalha com 3 heróis (3 janelas estreitas), painel PARTY, oferta ao
## vencer, luta-teste, mapa com o Yoch amarelo, candidato de encontro, aviso do Yoch, crescimento,
## menu C, HIRE, RESERVE e RELICS. O julgamento visual é do criador.
## Uso: Godot --path . -s tools/capture_survival_allies.gd  (sem --headless)

const CAPTURE_DIR := "res://captures/allies/"

var index := 0


func _initialize() -> void:
	call_deferred("_run")


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _shot(label: String) -> void:
	await _frames(4)
	index += 1
	var img: Image = root.get_texture().get_image()
	var path := CAPTURE_DIR + "allies_%02d_%s.png" % [index, label]
	img.save_png(ProjectSettings.globalize_path(path))
	print("CAPTURED: ", path)


func _wait_mode(b: Control, wanted: Array, limit: int = 3000) -> bool:
	for _i in limit:
		if b.hud != null and b.hud.mode in wanted:
			return true
		if b.hud != null and b.hud.mode == "react" and not wanted.has("react"):
			b.handle_back()
		if b.hud != null and b.hud.mode in ["continue", "announce"] and not wanted.has(b.hud.mode):
			b.proceed()
		await process_frame
	return false


func _battle(encounter: String, patch: Dictionary) -> Control:
	SurvivalState.reset()
	var base := {"seed": 7, "encounter_id": encounter,
		"gains": {"max_hp": 0, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": 30}}
	for k in patch.keys():
		base[k] = patch[k]
	SurvivalState.patch(base)
	var b: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	b.suppress_scene_change = true
	root.add_child(b)
	return b


func _world(patch: Dictionary) -> Node:
	SurvivalState.reset()
	SurvivalState.patch(patch)
	var w: Node = load(SurvivalData.WORLD_SCENE).instantiate()
	w.battle_scene = ""
	root.add_child(w)
	await _frames(14)
	return w


func _face(w: Node, target: Vector2i) -> bool:
	for f in 4:
		var d: Vector2i = w.DIRS[f]
		var from: Vector2i = target - d
		if not w.is_wall(from) and w.npc_at(from).is_empty() and w.enemies.at(from).is_empty():
			w.cell = from
			w.facing = f
			w._snap_to_state()
			w._map_cell(from)
			w.refresh_front_picture()
			return true
	return false


func _close(n: Node) -> void:
	n.queue_free()
	await _frames(3)


func _member(id: String, uid: String) -> Dictionary:
	return SurvivalAllies.new_member(uid, id, SurvivalAllies.stats_like_battle(id, 73), 3)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	var run_backup := ""
	if FileAccess.file_exists(SurvivalState.SAVE_PATH):
		run_backup = FileAccess.get_file_as_string(SurvivalState.SAVE_PATH)

	# 1) Batalha só com o Fallen.
	var b := await _battle("oni", {})
	await _wait_mode(b, ["plan"])
	await _shot("battle_solo")
	await _close(b)

	# 2) Batalha com 3 heróis (PIXIE + YOCH) e o painel PARTY.
	var yoch := SurvivalAllies.yoch_member("cap_y")
	var pix := _member("pixie", "cap_p")
	pix.auto = true
	b = await _battle("oni", {"party": [_member("high_pixie", "cap_h"), yoch], "reserve": [pix]})
	await _wait_mode(b, ["plan"])
	await _shot("battle_three_heroes")
	b.open_party()
	await _shot("battle_party_panel")
	b.overlay_key(KEY_DOWN)
	b.overlay_key(KEY_Z)
	await _shot("battle_party_auto")
	b.overlay_key(KEY_X)
	await _frames(4)
	await _close(b)

	# 3) Oferta ao vencer.
	var number := 0
	while not SurvivalAllies.offer_rolls(7, number + 1):
		number += 1
	b = await _battle("cerberus", {"battles": number})
	await _wait_mode(b, ["plan"])
	for f in b.hud.opponents:
		f.current_hp = 0
	b._show_result()
	for _i in 60:
		if b.offer_open:
			break
		await process_frame
	await _shot("battle_join_offer")
	b.answer_offer(true)
	await _frames(6)
	await _shot("battle_after_join")
	await _close(b)

	# 4) Luta-teste.
	SurvivalState.reset()
	SurvivalState.patch({"seed": 7, "encounter_id": "jack_frost", "duel": {"encounter": "s1_r0", "candidate": "jack_frost",
		"stats": SurvivalAllies.stats_like_battle("jack_frost", 73),
		"snapshot": {"fallen_hp": 26, "fallen_en": 12, "party": [], "continues": 3}}})
	b = load(SurvivalData.BATTLE_SCENE).instantiate()
	b.suppress_scene_change = true
	root.add_child(b)
	await _wait_mode(b, ["plan"])
	await _shot("battle_duel")
	for f in b.hud.opponents:
		f.current_hp = 0
	b._refresh_all()
	b._finish_duel(true)
	await _shot("battle_duel_won")
	await _close(b)

	# 5) Mapa: Yoch amarelo e o aviso do estrato.
	var ys := 1
	while not SurvivalAllies.yoch_in_stratum(ys, 2):
		ys += 1
	var w := await _world({"seed": ys, "stratum": 2, "cell": [12, 10]})
	await _shot("map_yoch_notice")
	_face(w, SurvivalAllies.yoch_cell(ys, 2))
	await _shot("map_yoch_front")
	w.talk()
	await _shot("map_yoch_talk")
	w.close_event()
	await _close(w)

	# 6) Candidatos dos 4 tipos de encontro.
	var seed := 1
	while SurvivalAllies.encounters(seed, 2).size() < 3:
		seed += 1
	w = await _world({"seed": seed, "stratum": 2, "cell": [12, 10], "macca": 500, "bead": 1,
		"growth_toast": ["PIXIE +1 AGI", "ONI +3 HP"]})
	await _shot("map_growth_toast")
	var recruits: Array = w.npcs.filter(func(n: Dictionary) -> bool: return String(n.get("role", "")) == "recruit")
	var kinds_shot := {}
	for npc in recruits:
		for kind in ["talk", "item", "money", "duel"]:
			if kinds_shot.has(kind):
				continue
			npc["kind"] = kind
			if kind == "item":
				npc["item"] = "bead"
			_face(w, npc.cell)
			w.talk()
			await _shot("map_recruit_" + kind)
			w.close_event()
			kinds_shot[kind] = true
			break
	# Menu C, HIRE, RESERVE, RELICS com um grupo montado.
	var a := _member("pixie", "m_a")
	var h := SurvivalAllies.new_member("m_h", "human_s2_b", SurvivalAllies.stats_like_battle("human_s2_b", 73), 5)
	h.down = true
	h.hp = 0
	SurvivalState.patch({"party": [a, SurvivalAllies.yoch_member("m_y")], "reserve": [h, _member("oni", "m_o")],
		"relics": ["shard_of_urim", "ember_tooth", "blood_vessel"], "chakra": 2, "medicine": 1})
	w._sync_party_from_state()
	await _shot("map_party_three_panels")
	w.toggle_menu()
	await _shot("map_menu_c")
	w.toggle_menu()
	w.open_hire()
	await _shot("map_hire")
	w.hire_open = false
	w.open_reserve()
	await _shot("map_reserve")
	w.reserve_open = false
	w._open_relics()
	w.relic_wearer = 2
	await _shot("map_relics_wearer")
	w._close_relics()
	w.talk()
	await _close(w)

	if run_backup.is_empty():
		SurvivalState.clear()
	else:
		var f := FileAccess.open(SurvivalState.SAVE_PATH, FileAccess.WRITE)
		f.store_string(run_backup)
		f.close()
	print("CAPTURES: %d" % index)
	quit()
