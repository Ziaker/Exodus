extends SceneTree
## D-100: capturas das letras hebraicas de SP flutuando (ganho verde, perda vermelha).

const OUT := "res://docs/plans/sp-float/"


func _initialize() -> void:
	call_deferred("_run")


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _shot(label: String) -> void:
	var img: Image = root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + "sp_%s.png" % label))
	print("CAPTURED: ", label)


func _run() -> void:
	var b: Control = load("res://scenes/battle/BattlePlayable.tscn").instantiate()
	root.add_child(b)
	await _frames(30)
	var hud: Control = b.hud
	var hero: BattleUnit = b._fallen
	var foe: BattleUnit = hud.opponents[0]
	# A steal: red on the enemy, green on the hero, at the same time.
	foe.add_sp(-3)
	hero.add_sp(3)
	await _frames(2)
	for step in [["a_0.10s", 1], ["b_0.20s", 3], ["c_0.30s", 3], ["d_0.43s", 4]]:
		await _frames(step[1])
		_shot(step[0])
	await _frames(40)
	# An enemy gains and a hero loses.
	foe.add_sp(2)
	hero.add_sp(-1)
	await _frames(2)
	for step in [["e_0.10s", 1], ["f_0.20s", 3], ["g_0.30s", 3], ["h_0.43s", 4]]:
		await _frames(step[1])
		_shot(step[0])
	quit(0)
