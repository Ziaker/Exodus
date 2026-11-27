extends SceneTree
## Captura real da Necrópole (estrato 1) parado de frente para a parede em células coladas nela, para auditar a vista.
## Janela real: Godot_v4.7.2-stable_win64_console.exe --path . -s tools/capture_necropole_walls.gd
const SANDBOX := preload("res://tests/progress_sandbox.gd")
const OUT := "res://captures/necropole_walls/"
var w: Node


func _initialize() -> void:
	SANDBOX.begin()
	call_deferred("_run")


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _shot(name: String) -> void:
	await _frames(4)
	var img := root.get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	img.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))


func _run() -> void:
	ProgressStore.save_path_override = "user://capture_necropole_guard.json"
	SurvivalState.reset()
	change_scene_to_file(SurvivalData.WORLD_SCENE)
	await _frames(30)
	w = current_scene
	# Posicoes pedidas pelo criador (auditoria): [x, y, facing]
	var spots := [[26, 169, 0, "start_ahead"], [26, 168, 0, "on_keeper"], [26, 164, 2], [26, 164, 0], [26, 164, 1], [26, 164, 3], [25, 164, 3], [26, 166, 2]]
	# NPCs de longe: 3 tiles antes de cada um, de frente
	print("NPCSPRITES ", w.npc_sprites.size(), " of ", w.npcs.size())
	for npc in w.npcs:
		print("NPC ", npc.get("id", "?"), " ", npc.cell)
		for d in 4:
			var ok := true
			for k in range(1, 4):
				if w.is_wall(npc.cell - w.DIRS[d] * k):
					ok = false
			if ok:
				var c: Vector2i = npc.cell - w.DIRS[d] * 3
				spots.append([c.x, c.y, d, "npc_%s" % String(npc.get("id", "x"))])
				break
	for sp in spots:
		w.cell = Vector2i(int(sp[0]), int(sp[1]))
		w.facing = int(sp[2])
		w._snap_to_state()
		w.refresh_front_picture()
		await _frames(30)
		await _shot(String(sp[3]) if sp.size() > 3 else "pos_%d_%d_f%d" % [sp[0], sp[1], sp[2]])

	# Fala do curandeiro com palavras coloridas
	w.cell = Vector2i(26, 167)
	w.facing = 2
	w._snap_to_state()
	w.refresh_front_picture()
	await _frames(5)
	w.meta()["keeper_intro"] = false
	w.talk()
	for page in 3:
		await _frames(140)
		await _shot("keeper_page%d" % page)
		w.dialogue.advance()
		await _frames(3)
		w.dialogue.advance()
	ProgressStore.clear()
	quit(0)
