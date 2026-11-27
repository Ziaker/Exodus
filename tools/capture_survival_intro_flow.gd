extends SceneTree
## Fluxo real da entrada do Survival (criador 2026-11-27: "é pra ter TUDO já no jogo"):
## título -> Survival sem run salva -> cutscene do Kazfiel (Z de verdade pula as falas) ->
## mapa real com a piscada de retorno. Também confere que com run salva o título vai direto
## ao mapa. Salva e restaura a run e o meta do jogador.
## Uso: Godot --path . -s tools/capture_survival_intro_flow.gd  (sem --headless)

const OUT := "res://captures/survival_intro/flow_"
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _shot(label: String) -> void:
	var path := OUT + label + ".png"
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("CAPTURED: ", path)


func _check(ok: bool, label: String) -> void:
	if not ok: failures += 1
	print(("PASS: " if ok else "FAIL: ") + label)


func _press_z() -> void:
	var down := InputEventKey.new()
	down.keycode = KEY_Z
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var up := InputEventKey.new()
	up.keycode = KEY_Z
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame


func _wait_scene(path: String, limit: int = 600) -> bool:
	for _i in limit:
		if current_scene != null and current_scene.scene_file_path == path:
			return true
		await process_frame
	return false


func _title_to_survival() -> void:
	change_scene_to_file("res://scenes/title/Title.tscn")
	await _wait_scene("res://scenes/title/Title.tscn")
	await _frames(3)
	var title: Node = current_scene
	title.index = title.COMMANDS.find("Survival")
	title.confirm()


func _run() -> void:
	var run_backup := FileAccess.get_file_as_string(SurvivalState.SAVE_PATH) if FileAccess.file_exists(SurvivalState.SAVE_PATH) else ""
	var meta_backup := FileAccess.get_file_as_string(SurvivalMeta.SAVE_PATH) if FileAccess.file_exists(SurvivalMeta.SAVE_PATH) else ""
	if FileAccess.file_exists(SurvivalState.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SurvivalState.SAVE_PATH))
	Engine.remove_meta(SurvivalState.META_KEY) if Engine.has_meta(SurvivalState.META_KEY) else null

	# 1) Sem run salva: título -> cutscene.
	await _title_to_survival()
	_check(await _wait_scene("res://scenes/survival/SurvivalIntro.tscn"), "New run from the title opens the Kazfiel cutscene")
	var intro: Node = current_scene
	# Espera a 1ª fala e usa Z de verdade: 1º mostra inteira, 2º pula.
	while intro.t < float(intro.TIMING.d.lines[0][0]) + 0.5:
		await process_frame
	_shot("01_line1_typing")
	await _press_z()
	await _frames(2)
	_shot("02_line1_full")
	_check(intro.skip_line == 0 and intro.skip_age < INF, "Z shows the whole first line")
	await _press_z()
	_check(absf(intro.t - float(intro.TIMING.d.lines[1][0])) < 0.2, "Second Z jumps to the next line (t=%.2f)" % intro.t)
	await _frames(20)
	_shot("03_line2")
	# Pula as falas restantes e deixa o desfecho correr sozinho.
	for _i in 4:
		await _press_z()
	_check(intro.t >= float(intro.TIMING.d.outro) - 0.01, "Skipping the last line goes to the outro")
	while is_instance_valid(intro) and intro == current_scene and intro.t < float(intro.TIMING.d.outro) + 2.4:
		await process_frame
	_shot("04_scatter")
	_check(await _wait_scene("res://scenes/survival/SurvivalWorld.tscn"), "Cutscene ends in the real Survival map")
	var world: Node = current_scene
	var blink := world.get_node_or_null("WakeBlink")
	_check(blink != null, "Map opens with the wake blink on top")
	await _frames(int(0.9 * 60))
	_shot("05_blink_half")
	await _frames(int(0.5 * 60))
	_shot("06_blink_closed_again")
	await _frames(int(1.2 * 60))
	_shot("07_blink_open")
	await _frames(60)
	_check(world.get_node_or_null("WakeBlink") == null or world.get_node("WakeBlink").get_child_count() == 0, "Blink overlay is gone after it ends")
	_shot("08_map_after")
	_check(not Engine.has_meta("exodus_survival_wake_blink"), "Wake flag is consumed")

	# 2) Com run salva: título -> mapa direto, sem cutscene e sem piscada.
	SurvivalState.save_to_file()
	await _title_to_survival()
	_check(await _wait_scene("res://scenes/survival/SurvivalWorld.tscn"), "Saved run from the title goes straight to the map")
	await _frames(3)
	_check(current_scene.get_node_or_null("WakeBlink") == null, "Resumed run has no wake blink")

	_restore(SurvivalState.SAVE_PATH, run_backup)
	_restore(SurvivalMeta.SAVE_PATH, meta_backup)
	print("FLOW FAILURES: ", failures)
	quit(1 if failures else 0)


func _restore(path: String, text: String) -> void:
	if text.is_empty():
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
