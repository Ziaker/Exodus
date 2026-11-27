extends SceneTree
## D-124/D-125 Fases 4 e 5: quadros-chave reais das 8 coreografias (folhas 2x2) dentro da BattlePlayable real,
## para a auditoria do agente e o julgamento do criador. Janela real (não headless):
## Godot_v4.7.2-stable_win64_console.exe --path . -s tools/capture_d124_skills.gd [-- inimigo]
const PLAYABLE := preload("res://scenes/battle/BattlePlayable.tscn")
const SANDBOX := preload("res://tests/progress_sandbox.gd")
const OUT := "res://captures/d124_skills/"

var b: Control
var g: Node2D


func _initialize() -> void:
	call_deferred("_run")


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


## Renderiza os efeitos na idade `age` (as ações de cada efeito dependem só dela).
func _shot(age: float) -> Image:
	for e in g._effects:
		e.at = g.time - age
	await _frames(2)
	for e in g._effects:
		e.at = g.time - age - 0.03
	await process_frame
	return root.get_texture().get_image()


func _sheet(name: String, ages: Array) -> void:
	var first: Image = await _shot(float(ages[0]))
	var w := first.get_width()
	var h := first.get_height()
	var sheet := Image.create(w * 2, h * 2, false, first.get_format())
	for i in ages.size():
		var img: Image = first if i == 0 else await _shot(float(ages[i]))
		sheet.blit_rect(img, Rect2i(0, 0, w, h), Vector2i((i % 2) * w, (i / 2) * h))
	var path := ProjectSettings.globalize_path(OUT + name + ".png")
	sheet.save_png(path)
	print("CAPTURED: ", path, " ages=", ages)


func _reset() -> void:
	g.clear_all()
	await _frames(3)


func _run() -> void:
	SANDBOX.begin()
	ProgressStore.save_path_override = "user://capture_d124_guard.json"
	ProgressStore.clear()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	b = PLAYABLE.instantiate()
	root.add_child(b)
	await _frames(10)
	b.hud.mode = "busy"
	g = b.grotesque_fx
	var hero: BattleUnit = b.hud.players[0]
	var ally: BattleUnit = b.hud.players[1]
	var foe0: BattleUnit = b.hud.opponents[0]
	var foe1: BattleUnit = b.hud.opponents[1]
	var enemy_cast := OS.get_cmdline_user_args().has("inimigo")
	var caster: BattleUnit = foe0 if enemy_cast else hero
	var t_main: BattleUnit = hero if enemy_cast else foe1
	var t_a: BattleUnit = hero if enemy_cast else foe0
	var t_b: BattleUnit = ally if enemy_cast else foe1
	var sfx := "_inimigo" if enemy_cast else ""

	await _reset()
	g.play_mazz_bite(caster, t_main)
	await _sheet("1_mazz_bite" + sfx, [0.3, 0.6, 0.8, 1.3])
	await _reset()
	g.play_fang_sting(caster, t_main)
	await _sheet("2_fang_sting" + sfx, [0.3, 0.55, 0.8, 1.3])
	await _reset()
	g.play_fang_spine(caster, [t_a, t_b])
	await _sheet("3_fang_spine_zahav" + sfx, [0.6, 0.9, 1.3, 1.8])
	await _reset()
	g.play_vuln_pierce(caster, t_main, true)
	await _sheet("4_vuln_pierce" + sfx, [0.3, 0.7, 0.95, 1.5])
	await _reset()
	g.play_dark_breath(caster, [t_a, t_b] if not enemy_cast else [hero, ally], [])
	await _sheet("5_dark_breath" + sfx, [0.5, 0.9, 1.4, 2.3])
	await _reset()
	g.play_umbral_gaze(caster, t_main)
	await _sheet("6_umbral_gaze" + sfx, [0.4, 0.8, 1.2, 2.0])
	await _reset()
	g.play_ignoma(caster, t_main)
	await _sheet("7_ignoma" + sfx, [0.35, 0.65, 0.9, 1.4])
	await _reset()
	g.play_ignoma_esh(caster, [t_a, t_b])
	await _sheet("8_ignoma_esh_zahav" + sfx, [0.4, 0.75, 1.1, 1.6])
	await _reset()
	ProgressStore.clear()
	quit(0)
