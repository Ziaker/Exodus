extends SceneTree
## Capturas reais (janela aberta) do roguelike do Survival (D-066..D-075) para a
## auditoria visual: estrato gerado, barra do santuário (OMEN / DESCEND), loja,
## relíquias com pacto, eventos no corredor, guardião no automapa, escolha da
## relíquia do guardião, fim de run e batalhas com intenções e raridade.
## Uso: Godot --path . -s tools/capture_survival_roguelike.gd  (sem --headless)

const CAPTURE_DIR := "res://captures/"
const SEED := 4321

var index := 0
var meta_backup := ""


func _initialize() -> void:
	call_deferred("_run")


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _shot(label: String) -> void:
	index += 1
	var img: Image = root.get_texture().get_image()
	var path := CAPTURE_DIR + "survrl_%02d_%s.png" % [index, label]
	img.save_png(ProjectSettings.globalize_path(path))
	print("CAPTURED: ", path)


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


func _world() -> Node:
	var w: Node = load(SurvivalData.WORLD_SCENE).instantiate()
	w.battle_scene = ""
	root.add_child(w)
	await _frames(14)
	return w


## Põe o jogador num tile vizinho, olhando para `target`.
func _face(w: Node, target: Vector2i, distance: int = 1) -> bool:
	for f in 4:
		var d: Vector2i = w.DIRS[f]
		var from: Vector2i = target - d * distance
		var clear := true
		for step in range(0, distance):
			clear = clear and not w.is_wall(target - d * step) and not w.is_wall(from)
		if clear and w.npc_at(from).is_empty() and w.enemies.at(from).is_empty():
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


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	if FileAccess.file_exists(SurvivalMeta.SAVE_PATH):
		meta_backup = FileAccess.get_file_as_string(SurvivalMeta.SAVE_PATH)
	var run_backup := ""
	if FileAccess.file_exists(SurvivalState.SAVE_PATH):
		run_backup = FileAccess.get_file_as_string(SurvivalState.SAVE_PATH)

	# 1) Estrato 1 com OMEN desbloqueado: barra com OMEN.
	SurvivalMeta.save({"omen_unlocked": 3, "best": 4200, "runs": 4, "codex": ["pixie", "oni"]})
	SurvivalState.reset()
	SurvivalState.patch({"seed": SEED})
	var w := await _world()
	_shot("s1_start")
	w.talk()
	w.service_index = w.service_index_of("omen")
	w.confirm_service_option()
	await _frames(3)
	_shot("s1_service_omen")
	w.set_omen(0)
	w.close_service()
	await _close(w)

	# 2) Estrato 2 gerado, com relíquias, itens e o guardião morto (DESCEND).
	SurvivalState.reset()
	SurvivalState.patch({"seed": SEED, "stratum": 2, "macca": 340, "medicine": 1, "blast": 2,
		"relics": ["shard_of_urim", "ember_tooth", "golden_calf", "manna_jar", "raziel_book", "iron_covenant", "sling_of_david"],
		"fallen_relics": ["shard_of_urim", "ember_tooth"], "yoch_relics": ["golden_calf"],
		"fallen_hp": 120, "yoch_hp": 70, "heals_used": 1, "battles": 6,
		"yoch_gains": {"max_hp": 10, "max_en": 0, "atk": 2, "mak": 0, "defense": 3, "mef": 0, "agi": 0}})
	w = await _world()
	_shot("s2_generated_start")
	w.talk()
	await _frames(3)
	_shot("s2_service_heal_paid")
	w.close_service()
	SurvivalState.patch({"defeated": [SurvivalStrata.warden_of(2)]})
	w.talk()
	w.service_index = w.service_index_of("descend")
	w.confirm_service_option()
	await _frames(3)
	_shot("s2_service_descend_confirm")
	w.service_pending = ""
	w.close_service()
	SurvivalState.patch({"defeated": []})
	w.talk()
	w.service_index = w.service_index_of("shop")
	w.confirm_service_option()
	w.move_shop_cursor(4)
	await _frames(3)
	_shot("shop_panel")
	w.close_shop()
	w._open_relics()
	w.relic_index = 1
	await _frames(3)
	_shot("relics_covenant")
	w._close_relics()
	await _frames(2)
	# Eventos reais do estrato: de frente para cada um, depois a barra aberta.
	for npc in w.npcs.duplicate():
		if String(npc.get("role", "")) != "event":
			continue
		if not _face(w, npc.cell):
			continue
		await _frames(4)
		_shot("event_%s_front" % String(npc.kind))
		w.talk()
		await _frames(3)
		_shot("event_%s_open" % String(npc.kind))
		w.close_event()
		await _frames(2)
	# Guardião no corredor e no automapa.
	var warden: Dictionary = {}
	for e in w.enemies.entries:
		if bool(e.get("warden", false)):
			warden = e
	if not warden.is_empty() and (_face(w, warden.cell, 2) or _face(w, warden.cell, 1)):
		w._update_enemy_seen()
		await _frames(6)
		_shot("warden_corridor_automap")
	await _close(w)

	# 3) Escolha da relíquia do guardião e fim de run.
	SurvivalState.reset()
	var wardens: Array = []
	for st in range(1, 6):
		wardens.append(SurvivalStrata.warden_of(st))
	SurvivalState.patch({"seed": SEED, "stratum": 5, "defeated": wardens, "macca": 812, "omen": 1,
		"pending_relic_choice": ["prophet_scroll", "leviathan_scale", "merchant_seal"]})
	w = await _world()
	_shot("warden_hoard")
	w.move_relic_choice(1)
	w.confirm_relic_choice()
	await _frames(4)
	_shot("survival_cleared")
	await _close(w)

	# 4) Batalhas: guardião com 2 escoltas, elite, 2 inimigos, recompensa com raridade.
	await _battle("lakshmi", "battle_warden_intents", {})
	var elite_seed := 0
	for s in 5000:
		if SurvivalData.is_elite(s, "cerberus"):
			elite_seed = s
			break
	await _battle("cerberus", "battle_elite_intent", {"seed": elite_seed})
	await _battle("ganesha", "battle_two_foes_intents", {})
	await _absorb_panel()
	await _merchant()
	await _continue_overlays()

	# Restaura saves do jogador.
	_restore(SurvivalMeta.SAVE_PATH, meta_backup)
	_restore(SurvivalState.SAVE_PATH, run_backup)
	quit()


func _restore(path: String, content: String) -> void:
	if content.is_empty():
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(content)
	f.close()


func _battle(encounter: String, label: String, patch: Dictionary) -> void:
	SurvivalState.reset()
	var base := {"seed": SEED, "encounter_id": encounter, "stratum": SurvivalStrata.stratum_of(encounter),
		"gains": {"max_hp": 0, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": 30}}
	for k in patch.keys():
		base[k] = patch[k]
	SurvivalState.patch(base)
	var b: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	b.suppress_scene_change = true
	root.add_child(b)
	await _wait_mode(b, "plan")
	await _frames(40)
	_shot(label)
	await _close(b)


## Primeiro estrato desta semente que sorteou o FROST MERCHANT.
func _merchant() -> void:
	for st in range(1, 6):
		for ev in SurvivalStrata.layout(SEED, st).events:
			if String(ev.kind) != "merchant":
				continue
			SurvivalState.reset()
			SurvivalState.patch({"seed": SEED, "stratum": st, "macca": 340})
			var w := await _world()
			for npc in w.npcs:
				if String(npc.id) == String(ev.id) and _face(w, npc.cell):
					await _frames(4)
					w.talk()
					await _frames(3)
					_shot("event_merchant_open")
			await _close(w)
			return


func _continue_overlays() -> void:
	SurvivalState.reset()
	SurvivalState.patch({"seed": SEED, "encounter_id": "oni", "stratum": 2, "defeated": ["pixie", "succubus"], "macca": 210})
	var b: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	b.suppress_scene_change = true
	root.add_child(b)
	await _wait_mode(b, "plan")
	b._show_continue_overlay(2)
	await _frames(4)
	_shot("continue_overlay")
	b._show_continue_overlay(0)
	await _frames(4)
	_shot("survival_over_overlay")
	b._hide_continue_overlay()
	await _close(b)


func _absorb_panel() -> void:
	SurvivalState.reset()
	SurvivalState.patch({"seed": SEED, "encounter_id": "lich", "stratum": 3, "fallen_relics": ["prophet_scroll"],
		"gains": {"max_hp": 0, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": 30}})
	var b: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	b.suppress_scene_change = true
	root.add_child(b)
	await _wait_mode(b, "plan")
	var owned: Array[StringName] = []
	var rng := RandomNumberGenerator.new()
	var opts: Array[Dictionary] = []
	# Procura uma oferta que mostre skill + raridades diferentes (amostra representativa).
	for s in 400:
		rng.seed = s
		opts = SurvivalAbsorb.roll_options(rng, SurvivalData.demon_by_id("lich"), owned, 1.0, b.absorb_context())
		var kinds := {}
		for o in opts:
			kinds[String(o.rarity)] = true
		if kinds.has("SKILL") and kinds.has("EPIC") and kinds.size() >= 3:
			break
	b.absorb_options = opts
	b.absorb_index = 1
	b.hud.message = ""
	b.hud.mode = "absorb_choice"
	b._show_absorb_overlay()
	await _frames(6)
	_shot("absorb_rarity_4_options")
	b._hide_absorb_overlay()
	b.hud.mode = "busy"
	await _close(b)
