extends SceneTree
## Capturas reais (janela aberta) do modo Survival para auditoria visual:
## overworld grande, barra única de cura/loja, silhueta no corredor, batalha
## com 1 demônio, overlay de CONTINUE e vitória.

const CAPTURE_DIR := "res://captures/"
const FRAMES_DIR := "res://captures/survival_frames/"

var index := 0
var frame_index := 0


func _initialize() -> void:
	call_deferred("_run")


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _record_frame() -> void:
	var img: Image = root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(FRAMES_DIR + "%04d.png" % frame_index))
	frame_index += 1


func _record(seconds: float) -> void:
	var count := int(seconds * 30.0)
	for _i in count:
		await _frames(2)
		_record_frame()


func _shot(label: String) -> void:
	index += 1
	var img: Image = root.get_texture().get_image()
	var path := CAPTURE_DIR + "survival_%02d_%s.png" % [index, label]
	img.save_png(ProjectSettings.globalize_path(path))
	print("CAPTURED: ", path)


func _wait_mode(b: Control, wanted: String, limit: int = 240) -> bool:
	for _i in limit:
		if b.hud != null and b.hud.mode == wanted:
			return true
		if b.hud != null and b.hud.mode == "react" and wanted != "react":
			b.handle_back()
		if b.hud != null and b.hud.mode in ["continue", "announce"] \
				and wanted not in ["continue", "announce"]:
			b.proceed()
		await process_frame
	return false


func _freeze(b: Control) -> void:
	for unit in b.state.units:
		if unit != b._fallen:
			unit.acts_available = 0
			unit.stored_acts = 0
	b._refresh_all()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FRAMES_DIR))
	SurvivalState.reset()

	var world: Control = load(SurvivalData.WORLD_SCENE).instantiate()
	world.battle_scene = "" # não troca de cena: queremos a silhueta no corredor
	root.add_child(world)
	await _frames(12)
	_shot("overworld_start")
	await _record(1.0)

	# Curandeiro + Vendedor na mesma barra de opções.
	world.talk()
	await _frames(3)
	_shot("service_bar")
	await _record(0.8)
	world.move_service_cursor(1)
	world.confirm_service_option()
	await _frames(2)
	_shot("service_buy")
	world.move_service_cursor(4) # BEAD -> NEW RUN
	world.confirm_service_option()
	await _frames(2)
	_shot("confirm_new_run")
	world.service_pending = "" # cancela: a captura não deve apagar a run
	world.close_service()
	await _frames(2)

	# Relíquias antigas na mesma barra (índice 3).
	world.talk()
	world.service_index = 3
	var relic_option: String = world.confirm_service_option()
	await _frames(3)
	_shot("relics_panel")
	world._close_relics()

	# Dois passos: Pixie persegue e encosta no santuário.
	world.request(world.Act.FORWARD)
	while world.busy:
		await process_frame
	world.request(world.Act.FORWARD)
	while world.busy:
		await process_frame
	await _frames(6)
	_shot("enemy_corridor")
	await _record(1.2)

	# Batalha com o demônio encontrado, sem trocar de cena (o fader é outro teste).
	SurvivalState.patch({"encounter_id": "pixie"})
	var battle: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	battle.suppress_scene_change = true
	root.add_child(battle)
	await _wait_mode(battle, "plan")
	await _frames(4)
	_shot("battle_pixie")
	await _record(1.0)

	# Morte: overlay de CONTINUE (3 -> 2) sem perder metade dos status.
	_freeze(battle)
	await _wait_mode(battle, "plan")
	battle._fallen.current_hp = 0
	battle._chosen = -1
	battle.command_chosen.emit()
	for _i in 120:
		if battle.continue_prompt_open:
			break
		await process_frame
	await _frames(4)
	_shot("continue_overlay")
	await _record(1.2)

	battle.answer_continue(true)
	await _wait_mode(battle, "plan")
	await _frames(4)
	_shot("after_continue")

	# Vitória e retorno.
	_freeze(battle)
	await _wait_mode(battle, "plan")
	var foe: BattleUnit = battle.hud.opponents[0]
	foe.current_hp = 0
	battle._chosen = -1
	battle.command_chosen.emit()
	await _wait_mode(battle, "result")
	await _frames(4)
	_shot("victory")
	await _record(1.2)

	# Um combate com 3 demônios para mostrar o modo de teste com reforços.
	battle.queue_free()
	await _frames(2)
	SurvivalState.patch({"encounter_id": "beelzebub"})
	var triple: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	triple.suppress_scene_change = true
	root.add_child(triple)
	await _wait_mode(triple, "plan")
	await _frames(4)
	_shot("triple_battle")
	await _record(1.2)
	triple.queue_free()

	# Absorção roguelike: mash e escolha de 1 entre 3 recompensas.
	SurvivalState.reset()
	SurvivalState.patch({
		"seed": 0, # semente que produz uma opção LEARN, para auditar o rótulo longo
		"encounter_id": "pixie", "skills": [],
		"gains": {"max_hp": 0, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": 20},
	})
	var absorb_battle: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	absorb_battle.suppress_scene_change = true
	root.add_child(absorb_battle)
	await _wait_mode(absorb_battle, "plan")
	_freeze(absorb_battle)
	absorb_battle.hud.opponents[0].current_sp = 0
	var absorb_cmds: Array[String] = absorb_battle._commands(absorb_battle._fallen)
	absorb_battle.submit_plan(absorb_cmds.find("ABSORB"))
	absorb_battle.exec_plan()
	await _wait_mode(absorb_battle, "target")
	absorb_battle.submit_target(0)
	for _i in 600:
		if absorb_battle.hud.mode == "absorb":
			absorb_battle._mash_count = 12
		elif absorb_battle.hud.mode == "absorb_choice":
			break
		await process_frame
	await _frames(3)
	_shot("absorb_draft")
	absorb_battle.absorb_index = 0
	absorb_battle.absorb_chosen.emit()
	await _frames(3)
	_shot("absorb_applied")
	absorb_battle.queue_free()
	await _frames(2)

	# Habilidade não identificada: o submenu mostra o nome hebraico.
	SurvivalState.reset()
	SurvivalState.patch({
		"seed": 0, "encounter_id": "pixie",
		"skills": ["spirit_wave"], "unidentified": ["spirit_wave"],
		"gains": {"max_hp": 0, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": 20},
	})
	var hebrew: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	hebrew.suppress_scene_change = true
	root.add_child(hebrew)
	await _wait_mode(hebrew, "plan")
	_freeze(hebrew)
	var hcmds: Array[String] = hebrew._commands(hebrew._fallen)
	hebrew.submit_plan(hcmds.find("FIGHT"))
	hebrew.exec_plan()
	await _wait_mode(hebrew, "skill")
	await _frames(3)
	_shot("skill_hebrew")
	hebrew.queue_free()
	await _frames(2)

	# Demônio elite com afixo (seed escolhida deterministicamente).
	var elite_seed := -1
	for candidate in 100:
		if SurvivalData.is_elite(candidate, "pixie"):
			elite_seed = candidate
			break
	SurvivalState.reset()
	SurvivalState.patch({
		"seed": elite_seed, "encounter_id": "pixie",
		"gains": {"max_hp": 0, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": 20},
	})
	var elite: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	elite.suppress_scene_change = true
	root.add_child(elite)
	await _wait_mode(elite, "plan")
	_freeze(elite)
	await _frames(3)
	_shot("elite_battle")
	elite.queue_free()
	await _frames(2)

	# Tela de conclusão com os 35 derrotados.
	var all_ids: Array[String] = []
	for d in SurvivalData.DEMONS:
		all_ids.append(String(d.id))
	SurvivalState.patch({"defeated": all_ids})
	world._check_cleared()
	await _frames(4)
	_shot("cleared")
	await _record(1.2)
	SurvivalState.clear()

	print("SURVIVAL CAPTURES: ", index, " FRAMES: ", frame_index)
	quit(0)
