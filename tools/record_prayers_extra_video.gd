extends SceneTree
## Grava vídeos reais em 30fps (--fixed-fps 60, gravando a cada 2 frames) dos 4 novos efeitos
## de reza no BattlePlayable.tscn: Sanverim, Nechamah (+ tick), Cherev e Refuah.
## Uso: Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 60 -s res://tools/record_prayers_extra_video.gd
const PLAYABLE := preload("res://scenes/battle/BattlePlayable.tscn")
const SANDBOX := preload("res://tests/progress_sandbox.gd")
const BASE := "res://captures/prayers_extra/"

var _dir := ""
var _idx := 0


func _initialize() -> void:
	call_deferred("_run")


func _start_clip(name: String) -> void:
	_dir = ProjectSettings.globalize_path(BASE + "frames_" + name + "/")
	DirAccess.make_dir_recursive_absolute(_dir)
	_idx = 0


func _record(seconds: float) -> void:
	var frames := int(round(seconds * 30.0))
	for _i in frames:
		await process_frame
		await process_frame
		var img: Image = root.get_texture().get_image()
		img.save_png(_dir + "%04d.png" % _idx)
		_idx += 1


func _run() -> void:
	SANDBOX.begin()
	ProgressStore.save_path_override = "user://record_prayers_extra_guard.json"
	ProgressStore.clear()
	ProgressStore.save_pp(8)

	var b: Control = PLAYABLE.instantiate()
	root.add_child(b)
	for _i in 10:
		await process_frame
	var fallen: BattleUnit = b.state.units[0]
	var yoch: BattleUnit = b.state.units[1]
	var foe: BattleUnit = b.hud.opponents[0]
	var pfx: Node2D = b.prayer.fx

	# ---- 1. SANVERIM (on FOE A)
	_start_clip("sanverim")
	b._event("Yoch prays Sanverim on FOE A.", PrayerBook.INK)
	b._refresh_all()
	await _record(0.25)
	SkillFx.apply_status(foe, &"blind", 2)
	pfx.play_sanverim(foe)
	await _record(1.75)
	foe.remove_status(&"blind")

	# ---- 2. NECHAMAH (cast + round tick on Yoch)
	_start_clip("nechamah")
	b._event("Yoch prays Nechamah on Yoch.", PrayerBook.INK)
	b._refresh_all()
	await _record(0.2)
	yoch.mends = [3, 3]
	pfx.play_nechamah(yoch, 2)
	await _record(1.55)
	b._event("Yoch is mended for 10 HP.", PrayerBook.INK)
	b.fx.play("HEAL", yoch, 10)
	pfx.play_nechamah_tick(yoch, 2)
	await _record(1.15)
	yoch.mends.clear()

	# ---- 3. CHEREV (AoE slash across enemies)
	_start_clip("cherev")
	b._event("Yoch prays Cherev!", PrayerBook.INK)
	b._refresh_all()
	await _record(0.2)
	pfx.play_cherev(true) # starts 0.48s charge; we record continuously through charge + slash + fall
	await _record(0.48)
	for f in b.hud.opponents:
		if (f as BattleUnit).is_alive():
			b.fx.play("RAAM", f, 24, yoch)
	await _record(1.35)

	# ---- 4. REFUAH (+2 extra PP helix on Fallen)
	_start_clip("refuah")
	b._event("Yoch prays Refuah on FALLEN: +40 HP.", PrayerBook.INK)
	b._refresh_all()
	await _record(0.2)
	pfx.play_refuah(fallen, 2)
	b.fx.play("HEAL", fallen, 40)
	await _record(1.65)

	ProgressStore.clear()
	b.queue_free()
	await process_frame
	print("RECORD_PRAYERS_EXTRA_OK")
	quit(0)
