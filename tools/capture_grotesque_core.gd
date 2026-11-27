extends SceneTree
## D-125 Fase 3: captura quadros reais do motor SkillGrotesqueFX (shaders GPU de Moiré e de warp, rabiscos,
## véu, paleta ZAHAV) dentro da BattlePlayable real, para a auditoria do agente e o julgamento do criador.
## Uso (janela real, não headless): Godot_v4.7.2-stable_win64_console.exe --path . -s tools/capture_grotesque_core.gd
const PLAYABLE := preload("res://scenes/battle/BattlePlayable.tscn")
const SANDBOX := preload("res://tests/progress_sandbox.gd")
const FX := preload("res://scripts/battle/skill_grotesque_fx.gd")
const OUT := "res://captures/grotesque_core/"

var b: Control
var g: Node2D


func _initialize() -> void:
	call_deferred("_run")


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _shot(name: String) -> void:
	await _frames(3)
	var img := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path(OUT + name + ".png")
	img.save_png(path)
	print("CAPTURED: ", path, " ", img.get_size())


func _foe_center_design(i: int) -> Vector2:
	return FX.to_design(b.hud.enemy_sprite_rect(i).get_center())


func _run() -> void:
	SANDBOX.begin()
	ProgressStore.save_path_override = "user://capture_grotesque_guard.json"
	ProgressStore.clear()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	b = PLAYABLE.instantiate()
	root.add_child(b)
	await _frames(10)
	b.hud.mode = "busy"
	g = b.grotesque_fx
	var c0 := _foe_center_design(0)
	var c1 := _foe_center_design(1)

	# 01 — Moiré radial sangue sobre o inimigo + olho + chama normal
	g.set_field(&"r", {"mode": 0, "cx": c0.x, "cy": c0.y, "rx": 130.0, "ry": 110.0, "env": 1.0, "pal": FX.palette_for(&"blood", false), "profile": &"v3"})
	g.set_darken(0.16)
	g.add_effect(30.0, func(fx: Node2D, age: float) -> void:
		var f := FX.boil_index(age)
		fx.draw_sketch_eye(c0.x, c0.y - 40.0, 26.0, 13.0, f, FX.palette_for(&"blood", false))
		fx.draw_sketch_flame(c1.x, c1.y + 20.0, 1.0, f, FX.palette_for(&"fire", false)))
	await _shot("01_moire_radial_blood")
	await _frames(20)
	await _shot("01b_moire_radial_blood_later")
	g.clear_all()

	# 02 — Umbral (dark_bias) sob o alvo
	g.set_field(&"d", {"mode": 0, "cx": c0.x, "cy": c0.y + 30.0, "rx": 150.0, "ry": 90.0, "env": 0.9, "pal": FX.palette_for(&"abyss", false), "profile": &"v3", "dark_bias": true})
	g.set_darken(0.5)
	g.add_effect(30.0, func(fx: Node2D, age: float) -> void:
		fx.draw_sketch_eye(c0.x, c0.y + 40.0, 76.0, 17.0, FX.boil_index(age), FX.palette_for(&"abyss", false), false, true))
	await _shot("02_umbral_dark_moire_eye")
	g.clear_all()

	# 03 — cone exalado da boca (dir +1) e espelhado (dir -1)
	g.set_field(&"cone", {"mode": 1, "mouth": Vector2(80.0, 190.0), "reach": 520.0, "dir_x": 1.0, "env": 1.0, "pal": FX.palette_for(&"abyss", false), "profile": &"v4"})
	g.set_darken(0.48)
	await _shot("03_breath_cone_right")
	g.set_field(&"cone", {"mode": 1, "mouth": Vector2(740.0, 190.0), "reach": 520.0, "dir_x": -1.0, "env": 1.0, "pal": FX.palette_for(&"abyss", false), "profile": &"v4"})
	await _shot("03b_breath_cone_mirrored")
	g.clear_all()

	# 04 — warp febril + inversão no inimigo 0 (e cartão do herói ondulando)
	g.trigger_target_warp(b.hud.opponents[0], 14.0, 30.0, 0.0)
	g.trigger_target_warp(b.hud.players[0], 10.0, 30.0, 0.0)
	await _shot("04_warp_enemy_and_hero_card")
	g.trigger_target_warp(b.hud.opponents[0], 14.0, 30.0, 30.0)
	await _shot("04b_warp_inversion_flash")
	g.clear_all()

	# 05 — ZAHAV: chama com outline dourado + palavra hebraica אש (híbrido)
	g.set_darken(0.22)
	g.add_effect(30.0, func(fx: Node2D, age: float) -> void:
		var f := FX.boil_index(age)
		var pal: Dictionary = FX.palette_for(&"fire", true)
		fx.draw_sketch_flame(c0.x, c0.y, 1.0, f, pal, Color("290d04"), 1.0, &"v4")
		fx.draw_hebrew_tri_word("אש", Vector2(c0.x, c0.y + 6.0), 22, 1.0)
		fx.draw_sketch_flame(c1.x, c1.y, 1.0, f, FX.palette_for(&"fire", false)))
	await _shot("05_zahav_flame_gold_vs_normal")
	g.clear_all()
	ProgressStore.clear()
	quit(0)
