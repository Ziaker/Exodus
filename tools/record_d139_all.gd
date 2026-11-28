extends SceneTree
## D-139: grava vídeo e/ou quadros PNG reais no Godot dos 4 ataques do Lote 3 (Twin Fang, Blade Dance,
## Rock Body, Stone Body [ZAHAV]) + STURDY hold/break, em modo Inimigos e Aliados. Uso:
##   Godot_v4.7.2-stable_win64_console.exe --path . --resolution 816x624 -s tools/record_d139_all.gd -- pngs
##   Godot_v4.7.2-stable_win64_console.exe --path . --write-movie captures/d139_videos/d139_todas.avi --fixed-fps 30 --resolution 816x624 -s tools/record_d139_all.gd
const SANDBOX := preload("res://tests/progress_sandbox.gd")

class RecBattle extends "res://scripts/battle/playable_controller.gd":
	func _enemy_counter_roll(_e: BattleUnit) -> bool: return false
	func _enemy_skill_pick(_n: int) -> int: return 0
	func _zone_roll(_h: float) -> int: return BattleMath.RhythmResult.MISS
	func _ai_roll(_a: BattleUnit, _d: BattleUnit) -> int: return BattleMath.RhythmResult.POINT
	func _defender_reaction(_a: BattleUnit, _d: BattleUnit) -> int: return BattleMath.RhythmResult.MISS
	func _fx_roll(_c: int) -> bool: return true
	func _burn_roll(_c: int) -> bool: return true
	func _skill_bars(count: int, _point_half: float) -> Array[int]:
		var out: Array[int] = []
		for _i in count: out.append(BattleMath.RhythmResult.POINT)
		return out

var b: RecBattle
var g: Node2D
var _out_dir := "captures/d139_frames"
var _save_pngs := false


func _initialize() -> void:
	SANDBOX.begin()
	call_deferred("_run")


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _wait_fx_age(start_t: float, target_age: float) -> void:
	var guard := 0
	while g.time - start_t < target_age and guard < 600:
		guard += 1
		await process_frame


func _snap(name: String) -> void:
	if not _save_pngs:
		return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img != null:
		img.save_png("%s/%s.png" % [_out_dir, name])
		print("SNAP ", name)


func _settle() -> void:
	var guard := 0
	while g.is_busy() and guard < 600:
		guard += 1
		await process_frame
	await _frames(6)


func _reset(units: Array) -> void:
	g.clear_all()
	for u in units:
		var bu: BattleUnit = u
		bu.statuses.clear()
		bu.bleeds.clear()
		bu.burns.clear()
		bu.sun_mark_hits = 0
		bu.sturdy_def_bonus = 0
		bu.sturdy_zahav = false
		bu.stats.max_hp = 400
		bu.current_hp = 400
		bu.stats.max_en = 40
		bu.current_en = 40
		bu.acts_available = 4
	b.hud.mode = "busy"
	b._clear_roles()
	b._refresh_all()


func _run() -> void:
	ProgressStore.save_path_override = "user://record_d139_guard.json"
	ProgressStore.clear()
	_save_pngs = Array(OS.get_cmdline_user_args()).has("pngs")
	if _save_pngs:
		DirAccess.make_dir_recursive_absolute(_out_dir)
	b = RecBattle.new()
	b.offer_reserve = true
	root.add_child(b)
	await _frames(15)
	g = b.grotesque_fx
	var hero: BattleUnit = b.hud.players[0]
	var ally: BattleUnit = b.hud.players[1]
	var foe0: BattleUnit = b.hud.opponents[0]
	var foe1: BattleUnit = b.hud.opponents[1]
	var all: Array = [hero, ally, foe0, foe1]

	# 1. Twin Fang (enemy + ally)
	_reset(all)
	var s: float = g.play_twin_fang(hero, foe1, true)
	await _wait_fx_age(s, 0.90)
	await _snap("01_twin_fang_enemy")
	await _settle()

	_reset(all)
	s = g.play_twin_fang(foe0, ally, true)
	await _wait_fx_age(s, 0.90)
	await _snap("02_twin_fang_ally")
	await _settle()

	# 2. Blade Dance (interleaved enemies + allies)
	_reset(all)
	s = g.play_blade_dance(hero, [foe0, foe1, foe0, foe1, foe0])
	await _wait_fx_age(s, 1.05)
	await _snap("03_blade_dance_enemies")
	await _settle()

	_reset(all)
	s = g.play_blade_dance(foe0, [hero, ally, hero, ally, hero])
	await _wait_fx_age(s, 1.05)
	await _snap("04_blade_dance_allies")
	await _settle()

	# 3. Rock Body + STURDY persistent & hold (enemy + ally)
	_reset(all)
	foe1.apply_sturdy(0, 1, false)
	s = g.play_rock_body(foe1)
	await _wait_fx_age(s, 0.48)
	await _snap("05_rock_body_enemy")
	await _settle()

	_reset(all)
	hero.apply_sturdy(0, 1, false)
	s = g.play_rock_body(hero)
	await _wait_fx_age(s, 0.48)
	await _snap("06_rock_body_ally")
	await _settle()

	# 4. Stone Body [ZAHAV] + STURDY +15 DEF & hold (enemy + ally)
	_reset(all)
	foe1.apply_sturdy(15, 1, true)
	s = g.play_stone_body(foe1)
	await _wait_fx_age(s, 0.66)
	await _snap("07_stone_body_zahav_enemy")
	await _settle()

	_reset(all)
	hero.apply_sturdy(15, 1, true)
	s = g.play_stone_body(hero)
	await _wait_fx_age(s, 0.66)
	await _snap("08_stone_body_zahav_ally")
	await _settle()

	# 5. STURDY hold & break on ally card
	s = g.play_sturdy_hold(hero)
	await _wait_fx_age(s, 0.16)
	await _snap("09_sturdy_hold_ally")
	await _settle()

	hero.remove_status(&"sturdy")
	s = g.play_sturdy_break(hero, true)
	await _wait_fx_age(s, 0.18)
	await _snap("10_sturdy_break_zahav_ally")
	await _settle()

	print("RECORD_D139_ALL_OK")
	ProgressStore.clear()
	b.queue_free()
	quit(0)
