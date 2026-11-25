extends SceneTree
## D-100: video curto das letras hebraicas de SP (roubo, ganho contra o inimigo B, ganho e perda de inimigo, perda de herói).
## Uso: godot --path . --fixed-fps 30 --write-movie X.avi -s tools/video_sp_float.gd

func _initialize() -> void:
	call_deferred("_run")


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _run() -> void:
	var b: Control = load("res://scenes/battle/BattlePlayable.tscn").instantiate()
	root.add_child(b)
	await _frames(20)
	var hero: BattleUnit = b._fallen
	var foe_a: BattleUnit = b.hud.opponents[0]
	var foe_b: BattleUnit = b.hud.opponents[1]
	for round in 2:
		foe_a.add_sp(-2)  # roubo do FOE A
		hero.add_sp(2)
		await _frames(24)
		hero.add_sp(1)    # ganho contra o inimigo em ação
		await _frames(24)
		foe_b.add_sp(-1)  # roubo do FOE B
		hero.add_sp(1)
		await _frames(24)
		foe_a.add_sp(2)   # inimigo ganha
		await _frames(24)
		hero.add_sp(-1)   # herói perde
		await _frames(24)
		hero.add_sp(1)
		foe_b.add_sp(1)
		await _frames(30)
	quit(0)
