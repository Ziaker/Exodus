extends SceneTree
## Captura do HUD com ícones de status (opção C): 2 heróis e 3 heróis, inimigos com ícones.
## Uso: Godot --path . --resolution 816x624 -s tools/capture_status_icons.gd
const SANDBOX := preload("res://tests/progress_sandbox.gd")
const OUT := "res://captures/status_icons/"


func _initialize() -> void:
	SANDBOX.begin()
	call_deferred("_run")


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


var b_ref: Node


func _shot(name: String) -> void:
	await _frames(150)
	b_ref.hud._sp_floats.clear()
	await _frames(3)
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var b := preload("res://scripts/battle/playable_controller.gd").new()
	b.offer_reserve = true
	root.add_child(b)
	b_ref = b
	await _frames(20)
	var hero: BattleUnit = b.hud.players[0]
	var ally: BattleUnit = b.hud.players[1]
	var foe0: BattleUnit = b.hud.opponents[0]
	var foe1: BattleUnit = b.hud.opponents[1]
	b.hud.mode = "busy"
	hero.atk_stages.append({"round": 1, "owner": &"x"})
	hero.def_stages.append(2)
	hero.weaken_mef_penalty = 5
	hero.apply_sun_mark()
	hero.add_bleed(2)
	hero.burns.append(3)
	hero.haganah = {"round": 1, "owner": &"x"}
	ally.sun_mark_hits = 2
	ally.add_status(&"blind", 2)
	foe0.weaken_mef_penalty = 4
	foe0.apply_sun_mark()
	foe0.add_bleed(1)
	foe1.atk_stages.append({"round": 1, "owner": &"x"})
	await _shot("dois_herois")
	var third := BattleUnit.new(&"third", "Pixie", hero.stats, true)
	third.start_praying(3)
	third.atk_stages.append({"round": 1, "owner": &"x"})
	third.apply_sun_mark()
	third.weaken_mak_penalty = 3
	b.hud.players.append(third)
	await _shot("tres_herois")
	quit(0)
