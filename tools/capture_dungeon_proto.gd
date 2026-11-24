extends SceneTree
## Capturas do TESTE de dungeon em primeira pessoa. Rodar com janela (sem --headless)
## e --fixed-fps 60. Só registro visual: o julgamento é do criador.

const Proto := preload("res://prototypes/dungeon-crawler/dungeon_proto.gd")
var d: Control


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures"))
	call_deferred("_run")


func _save(name: String) -> void:
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	var path := "res://captures/dungeon_%s.png" % name
	image.save_png(ProjectSettings.globalize_path(path))
	print("CAPTURED: ", path, " cell=", d.cell, " facing=", d.facing)


func _place(c: Vector2i, f: int) -> void:
	d.cell = c
	d.facing = f
	d._snap_to_state()
	d._map_cell(c)


func _idle() -> void:
	while d.busy:
		await process_frame


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _run() -> void:
	d = load("res://prototypes/dungeon-crawler/DungeonProto.tscn").instantiate()
	root.add_child(d)
	await _frames(5)
	await _save("01_start_east")
	# meio do passo
	d.request(Proto.Act.FORWARD)
	await _frames(4)
	await _save("02_mid_step")
	await _idle()
	# meio do giro
	d.request(Proto.Act.TURN_RIGHT)
	await _frames(4)
	await _save("03_mid_turn")
	await _idle()
	# corredor longo para o sul (coluna 1)
	_place(Vector2i(1, 1), 2)
	await _save("04_long_corridor_south")
	# beco sem saída: (1,9) olhando oeste dá parede; (3,3) é curva
	_place(Vector2i(3, 9), 3)
	await _save("05_dead_end_west")
	# sala 5x3
	_place(Vector2i(5, 9), 0)
	await _save("06_room_north")
	_place(Vector2i(5, 8), 1)
	await _save("07_room_east")
	# parede colada à frente (tremor)
	_place(Vector2i(9, 9), 1)
	d.request(Proto.Act.FORWARD)
	await _frames(2)
	await _save("08_clash_shake")
	await _idle()
	await _frames(4)
	# percurso para o automapa
	_place(Vector2i(1, 1), 1)
	for a in [Proto.Act.FORWARD, Proto.Act.FORWARD, Proto.Act.FORWARD, Proto.Act.FORWARD,
			Proto.Act.TURN_RIGHT, Proto.Act.FORWARD, Proto.Act.FORWARD, Proto.Act.TURN_RIGHT,
			Proto.Act.FORWARD, Proto.Act.FORWARD]:
		d.request(a)
		await _idle()
	await _save("09_after_walk_automap")
	# D-055: NPCs no corredor inicial (humano em (3,1), demônio em (5,1)); como o VX, a
	# figura só aparece ao falar, centrada sobre a vista (1,5x).
	d.npc_seen.clear()
	_place(Vector2i(1, 1), 2)
	await _save("09b_automap_no_npc_seen_yet")
	_place(Vector2i(1, 1), 1)
	await _save("10_corridor_npcs_not_drawn")
	_place(Vector2i(2, 1), 1)
	await _save("10b_facing_human_before_z")
	d.talk()
	d.dialogue.shown_chars = 40.0
	await _save("11_talk_human_typing")
	d.dialogue.advance()
	await _save("12_talk_human_full")
	while d.dialogue.is_open:
		d.dialogue.advance()
	await _save("13_after_dialogue_closed")
	_place(Vector2i(4, 1), 1)
	d.talk()
	d.dialogue.advance()
	await _save("14_talk_demon_page1")
	d.dialogue.advance()
	d.dialogue.advance()
	await _save("15_talk_demon_page2")
	while d.dialogue.is_open:
		d.dialogue.advance()
	_place(Vector2i(5, 1), 2)
	await _save("16_on_demon_cell_automap")
	_place(Vector2i(4, 1), 3)
	await _save("17_between_npcs_facing_human")
	_place(Vector2i(3, 1), 0)
	await _save("18_on_human_cell_facing_wall")
	d.talk()
	d.dialogue.advance()
	await _save("19_talk_on_human_cell")
	while d.dialogue.is_open:
		d.dialogue.advance()
	d.queue_free()
	quit(0)
