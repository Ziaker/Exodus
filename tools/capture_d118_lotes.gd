extends SceneTree
## D-118 lotes 2-4: captures live Godot frames (contact sheets of 2x2 ages) of Esh, Ur Esh, Meir, Seraf,
## Nitzotz, Esh Ochelet, Gever, Angel Hug, God's Message and Adin -> Adina -> Adinut, inside the real
## BattlePlayable scene, for the agent audit and the creator's judgment.
## Usage: Godot_v4.7.2-stable_win64_console.exe --path . -s tools/capture_d118_lotes.gd
const PLAYABLE := preload("res://scenes/battle/BattlePlayable.tscn")
const SANDBOX := preload("res://tests/progress_sandbox.gd")
const OUT := "res://captures/d118_lotes/"

var pfx: Node2D
var b: Control


func _initialize() -> void:
	call_deferred("_run")


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


## Renders the effects at `age` seconds after their start and returns the viewport image.
func _shot(age: float) -> Image:
	for e in pfx.d118:
		e.at = pfx.time - age
	pfx.queue_redraw()
	await _frames(2)
	for e in pfx.d118:
		e.at = pfx.time - age - 0.034
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
	print("CAPTURED: ", path, "  ages=", ages)


func _reset(foe: BattleUnit, yoch: BattleUnit) -> void:
	pfx.d118.clear()
	foe.statuses.clear()
	yoch.statuses.clear()
	foe.burns.clear()
	foe.paralyzed_acts = 0
	yoch.paralyzed_acts = 0
	yoch.atk_stages.clear()
	await _frames(2)


func _run() -> void:
	SANDBOX.begin()
	ProgressStore.save_path_override = "user://capture_d118_lotes_guard.json"
	ProgressStore.clear()
	ProgressStore.save_pp(8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	b = PLAYABLE.instantiate()
	root.add_child(b)
	await _frames(10)
	var fallen: BattleUnit = b.state.units[0]
	var yoch: BattleUnit = b.state.units[1]
	var foe: BattleUnit = b.hud.opponents[0]
	var foe2: BattleUnit = b.hud.opponents[1] if b.hud.opponents.size() > 1 else foe
	pfx = b.prayer.fx
	b.hud.mode = "busy"
	for f in b.hud.opponents:
		(f as BattleUnit).stats.max_hp = 900
		(f as BattleUnit).current_hp = 900
	yoch.current_hp = 40

	await _reset(foe, yoch)
	pfx.play_esh(yoch, foe, true)
	await _sheet("01_esh", [0.22, 0.44, 0.62, 1.3])

	await _reset(foe, yoch)
	foe.burns.append(3)
	pfx.play_ur_esh(yoch, foe, true)
	await _sheet("02_ur_esh", [0.3, 0.75, 0.95, 1.5])

	await _reset(foe, yoch)
	SkillFx.apply_status(yoch, &"taunt", 1)
	pfx.play_meir(yoch, b.hud.opponents)
	await _sheet("03_meir", [0.25, 0.7, 1.3, 2.3])

	await _reset(foe, yoch)
	pfx.play_seraf(yoch, 30)
	await _sheet("04_seraf", [0.4, 0.95, 1.4, 2.0])

	await _reset(foe, yoch)
	foe.burns.append(3)
	pfx.play_nitzotz(yoch, foe)
	await _sheet("05_nitzotz", [0.2, 0.5, 0.62, 1.1])

	await _reset(foe, yoch)
	SkillFx.apply_status(foe, &"ochelet", 2)
	pfx.play_esh_ochelet(foe)
	pfx.play_ochelet_bite(foe)
	await _sheet("06_esh_ochelet", [0.08, 0.3, 0.7, 1.5])

	await _reset(foe, yoch)
	for _s in 4:
		yoch.atk_stages.append({"round": 1, "owner": yoch.id})
	pfx.play_gever(yoch)
	await _sheet("07_gever", [0.3, 0.8, 1.3, 2.0])

	await _reset(foe, yoch)
	yoch.paralyzed_acts = 3
	pfx.play_angel_hug(foe, yoch, true)
	await _sheet("08_angel_hug_foe_to_hero", [0.2, 0.55, 0.78, 1.2])

	await _reset(foe, yoch)
	foe.paralyzed_acts = 3
	pfx.play_angel_hug(yoch, foe, true)
	await _sheet("09_angel_hug_hero_to_foe", [0.2, 0.55, 0.78, 1.2])

	await _reset(foe, yoch)
	SkillFx.apply_status(yoch, &"gods_message", 3)
	pfx.play_gods_message(foe, yoch, true)
	await _sheet("10_gods_message", [0.3, 0.9, 1.4, 1.8])

	await _reset(foe, yoch)
	pfx.play_gods_message_fulfilled(yoch, "DEF")
	await _sheet("11_gods_message_fulfilled", [0.05, 0.2, 0.5, 1.0])

	await _reset(foe, yoch)
	pfx.play_adin(yoch, 0)
	pfx.play_adin(foe2, 1)
	await _sheet("12_adin_adina", [0.3, 0.7, 1.0, 1.4])

	await _reset(foe, yoch)
	pfx.play_adin(yoch, 2)
	await _sheet("13_adinut", [0.04, 0.3, 0.7, 1.2])

	# Persistent marks on cards and foes
	await _reset(foe, yoch)
	SkillFx.apply_status(yoch, &"taunt", 1)
	for _s in 4:
		yoch.atk_stages.append({"round": 1, "owner": yoch.id})
	yoch.paralyzed_acts = 2
	SkillFx.apply_status(yoch, &"gods_message", 3)
	foe.paralyzed_acts = 3
	SkillFx.apply_status(foe, &"gods_message", 3)
	SkillFx.apply_status(foe, &"ochelet", 2)
	await _frames(4)
	pfx.queue_redraw()
	await _frames(2)
	var marks_img := root.get_texture().get_image()
	marks_img.save_png(ProjectSettings.globalize_path(OUT + "14_marks.png"))
	print("CAPTURED: marks")
	ProgressStore.clear()
	quit(0)
