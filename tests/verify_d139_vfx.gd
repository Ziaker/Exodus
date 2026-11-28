extends SceneTree
## D-139 Fase 3: verifica as 4 coreografias (Twin Fang, Blade Dance, Rock Body, Stone Body [ZAHAV]) +
## estado persistente STURDY + play_sturdy_hold + play_sturdy_break em modo Inimigos e 3 Aliados Survival,
## leis D-125 (ouro exclusivo em ZAHAV, zero hebraico) e guard geométrico D-137 (STURDY persistente
## no cartão aliado nunca invade o Battle Log, mesmo coexistindo com Mark of Sun).
const SANDBOX := preload("res://tests/progress_sandbox.gd")
const FX_SCRIPT := "res://scripts/battle/skill_grotesque_fx.gd"
const SKILLS: Array[StringName] = [&"twin_fang", &"blade_dance", &"rock_body", &"stone_body"]

class FxBattle extends "res://scripts/battle/playable_controller.gd":
	func _ai_roll(_a: BattleUnit, _b: BattleUnit) -> int: return BattleMath.RhythmResult.POINT
	func _defender_reaction(_a: BattleUnit, _b: BattleUnit) -> int: return BattleMath.RhythmResult.MISS
	func _zone_roll(_h: float) -> int: return BattleMath.RhythmResult.MISS
	func _enemy_counter_roll(_e: BattleUnit) -> bool: return false
	func _fx_roll(_c: int) -> bool: return true
	func _burn_roll(_c: int) -> bool: return true

var checks := 0
var b: FxBattle
var g: Node2D
var hero: BattleUnit
var ally: BattleUnit
var foe0: BattleUnit
var foe1: BattleUnit


func _initialize() -> void:
	SANDBOX.begin()
	call_deferred("_run")


func check(ok: bool, reason: String) -> void:
	if not ok:
		push_error("FAIL: " + reason)
		quit(1)
		assert(ok, reason)
	checks += 1


func frames(n: int) -> void:
	for _i in n:
		await process_frame


func idle(max_frames: int = 500) -> int:
	var n := 0
	while g.effect_count() > 0 and n < max_frames:
		await process_frame
		n += 1
	return n


func _body(src: String, fname: String) -> String:
	var i := src.find("func %s(" % fname)
	var j := src.find("\n\nfunc ", i + 5)
	var k := src.find("\n\n# ----", i + 5)
	var end := j if (k < 0 or (j >= 0 and j < k)) else k
	return src.substr(i, (end if end > 0 else src.length()) - i)


func _zahav_palette(body: String) -> bool:
	var re := RegEx.new()
	re.compile("palette_for\\(&\"\\w+\", true\\)")
	return re.search(body) != null


func _run() -> void:
	ProgressStore.save_path_override = "user://verify_d139_vfx_guard.json"
	ProgressStore.clear()
	b = FxBattle.new()
	b.offer_reserve = true
	root.add_child(b)
	await frames(15)
	b.hud.mode = "busy"
	g = b.grotesque_fx
	hero = b.hud.players[0]
	ally = b.hud.players[1]
	foe0 = b.hud.opponents[0]
	foe1 = b.hud.opponents[1]
	_laws()
	await _lifecycle()
	await _sturdy_persistent_and_geometry()
	print("VERIFY_D139_VFX_OK: %d checks; 4 choreographies + STURDY hold/break run clean in Enemy and Ally-card modes (Blade Dance 1/2/3 targets), gold only in Stone Body ZAHAV, zero Hebrew, persistent STURDY never touches Battle Log" % checks)
	ProgressStore.clear()
	b.queue_free()
	quit(0)


func _laws() -> void:
	var src := FileAccess.get_file_as_string(FX_SCRIPT).replace("\r\n", "\n")
	for fname in ["play_twin_fang", "play_blade_dance", "play_rock_body"]:
		var body := _body(src, fname)
		check(body.length() > 40 and not body.contains("GOLD") and not _zahav_palette(body) and not body.contains("PAL_ZAHAV"),
			"%s never uses ZAHAV gold (normal attack)" % fname)
	for fname in ["play_twin_fang", "play_blade_dance", "play_rock_body", "play_stone_body", "play_sturdy_hold", "play_sturdy_break"]:
		var body2 := _body(src, fname)
		check(not body2.contains("draw_hebrew_tri_word") and not body2.contains("HEBREW_ALPHABET") and not body2.contains("FIRE_HEBREW"),
			"%s has zero Hebrew letters" % fname)
	check(_body(src, "play_stone_body").contains("palette_for(&\"stone\", true)"), "Stone Body uses ZAHAV stone palette")
	check(g.PAL_BLADE.accent == Color("8c1d30") and g.PAL_BLADE.hi == Color("dfe4ee") and g.PAL_BLADE.deep == Color("17070c"), "PAL_BLADE matches D-139")
	check(g.PAL_ZAHAV_STONE.accent == Color("8c7252") and g.PAL_ZAHAV_STONE.hi == Color("ffd84a") and g.PAL_ZAHAV_STONE.deep == Color("1b140d"), "PAL_ZAHAV_STONE matches D-139")
	check(g.PAL_BLADE.hi != g.GOLD and SkillGrotesqueFX.palette_for(&"blade", false).hi != g.GOLD, "PAL_BLADE carries no gold")
	check(SkillGrotesqueFX.palette_for(&"stone", false).hi != g.GOLD and SkillGrotesqueFX.palette_for(&"stone", true).hi == g.GOLD, "stone normal has no gold; stone ZAHAV has gold")
	for id in SKILLS:
		check(bool(SkillBook.def(id).get("grotesque", false)), "%s flagged grotesque=true" % id)
	check(g.HIT_TWIN_FANG[0] == 0.28 and g.HIT_TWIN_FANG[1] == 0.86, "Twin Fang hit timings 0.28 / 0.86")
	check(is_equal_approx(g.blade_dance_hit_age(0), 0.34) and is_equal_approx(g.blade_dance_hit_age(4), 1.66), "Blade Dance hit cadence 0.34 + i*0.33")
	check(g.HIT_ROCK_BODY == 0.44 and g.HIT_STONE_BODY == 0.62, "Rock Body (0.44) and Stone Body (0.62) lock timings")


func _lifecycle() -> void:
	# 1) Twin Fang: enemy and ally card (combo true & false)
	g.play_twin_fang(hero, foe0, true)
	check(g.effect_count() == 1, "Twin Fang starts on enemy")
	await frames(4)
	check(await idle() < 500 and not g.is_busy(), "Twin Fang finishes cleanly on enemy")

	g.play_twin_fang(foe0, ally, false)
	await frames(4)
	check(await idle() < 500 and not g.is_busy(), "Twin Fang finishes cleanly on ally card")

	# 2) Blade Dance: 2 enemies (5 hits), 1 solo enemy (3 hits loop), and ally cards (5 hits)
	g.play_blade_dance(hero, [foe0, foe1, foe0, foe1, foe0])
	await frames(4)
	check(await idle() < 500 and not g.is_busy(), "Blade Dance (5 hits interleaved enemies) finishes cleanly")

	g.play_blade_dance(hero, [foe0, foe0, foe0])
	await frames(4)
	check(await idle() < 500 and not g.is_busy(), "Blade Dance (1 solo enemy loop) finishes cleanly")

	g.play_blade_dance(foe0, [hero, ally, hero, ally, hero])
	await frames(4)
	check(await idle() < 500 and not g.is_busy(), "Blade Dance (ally cards) finishes cleanly")

	# 3) Rock Body & Stone Body [ZAHAV]: enemy & ally card
	for pair in [[hero, false], [foe0, false], [hero, true], [foe0, true]]:
		var u: BattleUnit = pair[0]
		var z: bool = pair[1]
		if z: g.play_stone_body(u)
		else: g.play_rock_body(u)
		await frames(4)
		check(await idle() < 500 and not g.is_busy(), "%s finishes cleanly on %s" % ["Stone Body" if z else "Rock Body", u.display_name])

	# 4) STURDY hold & break on enemy and ally
	hero.apply_sturdy(15, 1, true)
	g.play_sturdy_hold(hero)
	await frames(4)
	check(await idle() < 500, "play_sturdy_hold finishes cleanly on ally")
	g.play_sturdy_break(hero, true)
	await frames(4)
	check(await idle() < 500, "play_sturdy_break finishes cleanly on ally")
	foe0.apply_sturdy(0, 1, false)
	g.play_sturdy_hold(foe0)
	await frames(4)
	check(await idle() < 500, "play_sturdy_hold finishes cleanly on enemy")
	g.play_sturdy_break(foe0, false)
	await frames(4)
	check(await idle() < 500, "play_sturdy_break finishes cleanly on enemy")


func _sturdy_persistent_and_geometry() -> void:
	var log_bottom: float = b.hud.BATTLE_LOG_RECT.end.y * g.DESIGN_SCALE
	for u in [hero, ally]:
		u.sun_mark_hits = 0
		u.apply_sturdy(0, 1, false)
		var spot: Dictionary = g.sturdy_spot(u)
		var badge: Vector2 = spot.badge
		var r: float = spot.r
		var card: Rect2 = spot.card
		check(badge.y - r * 1.15 >= log_bottom,
			"Persistent STURDY badge on %s stays strictly below Battle Log (top=%.1f >= log_bottom=%.1f)" % [u.display_name, badge.y - r * 1.15, log_bottom])
		check(card.position.y >= log_bottom or float(spot.min_y) >= log_bottom,
			"Persistent STURDY corners on %s never invade Battle Log" % u.display_name)
		# Coexistence with Mark of Sun: badge shifts left without overlapping sun
		u.sun_mark_hits = 3
		u.apply_sturdy(15, 1, true)
		var spot_co: Dictionary = g.sturdy_spot(u)
		var sun: Dictionary = g.sun_spot(u)
		check(absf(float(spot_co.badge.x) - float(sun.p.x)) >= 20.0,
			"When Mark of Sun and STURDY coexist on %s, badges separate horizontally (dx=%.1f)" % [u.display_name, absf(float(spot_co.badge.x) - float(sun.p.x))])
		u.sun_mark_hits = 0
		u.remove_status(&"sturdy")
	# Enemy persistent spot stays below top HUD
	foe0.apply_sturdy(15, 1, true)
	var es: Dictionary = g.sturdy_spot(foe0)
	check(float(es.badge.y) > g.STAGE_TOP * g.DESIGN_SCALE, "Enemy STURDY badge stays below top HUD")
	foe0.remove_status(&"sturdy")
