extends SceneTree
## Registro visual da dungeon (assets SMT como placeholder) e do encontro que abre o combate.
## Rodar com janela e --fixed-fps 60. O julgamento visual é do criador.

const Proto := preload("res://prototypes/dungeon-crawler/dungeon_proto.gd")


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://captures")
	call_deferred("_run")


func _save(name: String) -> void:
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	var path := "res://captures/dungeon_%s.png" % name
	image.save_png(ProjectSettings.globalize_path(path))
	print("CAPTURED: ", path)


func _idle(d: Control) -> void:
	while is_instance_valid(d) and d.busy:
		await process_frame


func _run() -> void:
	var d: Control = load("res://prototypes/dungeon-crawler/DungeonProto.tscn").instantiate()
	root.add_child(d)
	for _i in 10:
		await process_frame
	await _save("encounter_01_start")
	d.request(Proto.Act.FORWARD)
	await _idle(d)
	await _save("encounter_02_red_dot")
	d.request(Proto.Act.FORWARD)
	await _idle(d)
	for _i in 10:
		await process_frame
	await _save("encounter_03_battle")
	quit(0)
