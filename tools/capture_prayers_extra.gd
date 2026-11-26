extends SceneTree
## Captures live Godot frames of the 4 newly ported prayer VFX (Sanverim, Nechamah, Cherev, Refuah)
## inside the real BattlePlayable scene so the creator can inspect them in-engine.
## Usage: Godot_v4.7.2-stable_win64_console.exe --path . -s tools/capture_prayers_extra.gd
const PLAYABLE := preload("res://scenes/battle/BattlePlayable.tscn")
const SANDBOX := preload("res://tests/progress_sandbox.gd")
const OUT := "res://captures/prayers_extra/"


func _initialize() -> void:
	call_deferred("_run")


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _save(name: String) -> void:
	var path := OUT + name + ".png"
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("CAPTURED: ", path)


func _run() -> void:
	SANDBOX.begin()
	ProgressStore.save_path_override = "user://capture_prayers_extra_guard.json"
	ProgressStore.clear()
	ProgressStore.save_pp(8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	var b: Control = PLAYABLE.instantiate()
	root.add_child(b)
	await _frames(10)
	var fallen: BattleUnit = b.state.units[0]
	var yoch: BattleUnit = b.state.units[1]
	var foe: BattleUnit = b.hud.opponents[0]
	var pfx: Node2D = b.prayer.fx

	# 1. Sanverim (closing curtains + impact flares + persistent ס mark)
	SkillFx.apply_status(foe, &"blind", 2)
	pfx.play_sanverim(foe)
	pfx.time = pfx.sanverim_at - 0.10
	pfx.queue_redraw()
	await _frames(2)
	_save("01_sanverim_charge")
	pfx.time = pfx.sanverim_at + 0.18
	pfx.queue_redraw()
	await _frames(2)
	_save("02_sanverim_impact")
	pfx.sanverim_at = -99.0

	# 2. Nechamah (dew falling + persistent נx2 mark + green tick)
	foe.remove_status(&"blind")
	yoch.mends = [3, 3]
	pfx.play_nechamah(yoch, 2)
	pfx.time += 0.65
	pfx.queue_redraw()
	await _frames(2)
	_save("03_nechamah_cast")
	pfx.card_fx.clear()
	pfx.play_nechamah_tick(yoch, 2)
	pfx.time += 0.35
	pfx.queue_redraw()
	await _frames(2)
	_save("04_nechamah_tick")
	pfx.card_fx.clear()
	yoch.mends.clear()

	# 3. Cherev (blade charge + diagonal light slash across enemies)
	pfx.c_on_enemies = true
	pfx.c_x_start = 24.0
	pfx.c_x_end = b.hud.SCREEN.x - 24.0
	pfx.c_y_mid = b.hud.enemy_sprite_rect(0).get_center().y
	pfx.play_cherev(true) # starts timer, we advance time manually for deterministic frames
	pfx.time = pfx.cherev_at - 0.08
	pfx.queue_redraw()
	await _frames(2)
	_save("05_cherev_charge")
	pfx.time = pfx.cherev_at + 0.14
	pfx.queue_redraw()
	await _frames(2)
	_save("06_cherev_slash")
	pfx.cherev_at = -99.0

	# 4. Refuah (double helix with +2 extra PP)
	pfx.play_refuah(fallen, 2)
	pfx.time += 0.55
	pfx.queue_redraw()
	await _frames(2)
	_save("07_refuah_helix")

	ProgressStore.clear()
	b.queue_free()
	await _frames(2)
	quit(0)
