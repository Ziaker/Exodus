extends SceneTree
## Capturas do protótipo da transição para o Survival (prototypes/survival-intro).
## 1) Gera o quadro do início real do Survival (run nova, semente fixa) em
##    prototypes/survival-intro/art/dungeon_start.png, salvando e restaurando a run e o
##    meta do jogador.
## 2) Captura as 3 opções em vários instantes em captures/survival_intro/.
## Uso: Godot --path . -s tools/capture_survival_intro.gd  (sem --headless)

const OUT := "res://captures/survival_intro/"
const ART := "res://prototypes/survival-intro/art/dungeon_start.png"
const INSTANTS := {
	"a": [0.3, 1.8, 5.0, 8.6, 9.8, 13.0, 16.4, 21.0, 25.2, 27.0, 28.6, 31.0],
	"b": [1.2, 4.0, 9.5, 13.6, 17.0, 21.5, 22.8, 24.0, 25.4, 26.6, 27.8, 30.0],
	"c": [1.0, 4.0, 7.3, 10.0, 14.5, 15.1, 18.0, 21.8, 22.3, 23.0, 23.8, 26.0],
	"d": [1.2, 2.4, 3.6, 4.4, 5.4, 8.0, 11.2, 15.0, 18.2, 22.0, 25.2, 26.6, 27.6, 28.6, 29.4, 30.4, 31.4, 33.5],
}


func _initialize() -> void:
	call_deferred("_run")


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ART.get_base_dir()))
	var run_backup := FileAccess.get_file_as_string(SurvivalState.SAVE_PATH) if FileAccess.file_exists(SurvivalState.SAVE_PATH) else ""
	var meta_backup := FileAccess.get_file_as_string(SurvivalMeta.SAVE_PATH) if FileAccess.file_exists(SurvivalMeta.SAVE_PATH) else ""
	SurvivalState.reset()
	SurvivalState.patch({"seed": 4321})
	var w: Node = load(SurvivalData.WORLD_SCENE).instantiate()
	w.battle_scene = ""
	root.add_child(w)
	await _frames(20)
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(ART))
	print("CAPTURED: ", ART)
	w.queue_free()
	await _frames(3)
	_restore(SurvivalState.SAVE_PATH, run_backup)
	_restore(SurvivalMeta.SAVE_PATH, meta_backup)

	var p: Node = load("res://prototypes/survival-intro/SurvivalIntro.tscn").instantiate()
	root.add_child(p)
	await _frames(3)
	p.frozen = true
	for opt in ["a", "b", "c", "d"]:
		p.option = opt
		p.restart()
		for at in INSTANTS[opt]:
			p.t = at
			p.queue_redraw()
			await _frames(2)
			var path := OUT + "%s_%05.1f.png" % [opt, at]
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
			print("CAPTURED: ", path)
	# Z (skip): 1º aperto mostra a fala inteira, 2º pula para a próxima; na última vai
	# para o desfecho. Testa as 4 opções com o mesmo caminho da tecla (skip_text).
	var failures := 0
	for opt in ["a", "b", "c", "d"]:
		p.option = opt
		p.restart()
		var spans: Array = p.TIMING[opt].lines
		for i in spans.size():
			p.t = float(spans[i][0]) + 0.6
			p.skip_text()
			var full: bool = p.skip_line == i and p.skip_age < INF
			p.queue_redraw()
			await _frames(2)
			var path := OUT + "skip_%s_line%d.png" % [opt, i + 1]
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
			p.skip_text()
			var want: float = float(spans[i + 1][0]) if i + 1 < spans.size() else float(p.TIMING[opt].outro)
			var ok: bool = full and is_equal_approx(p.t, want)
			if not ok: failures += 1
			print("SKIP %s line %d: full=%s jump_to=%.1f want=%.1f %s" % [opt, i + 1, full, p.t, want, "OK" if ok else "FAIL"])
	print("SKIP FAILURES: ", failures)
	quit()


func _restore(path: String, text: String) -> void:
	if text.is_empty():
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
