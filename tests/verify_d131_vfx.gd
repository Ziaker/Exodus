extends SceneTree
## D-131 Fase 3: as 7 coreografias do Lote 2 (+ a marca persistente de Mark of Sun) em SkillGrotesqueFX rodam limpas nos dois
## modos (Inimigos e cartões dos Aliados), acabam sozinhas, respeitam as leis (ouro só em ZAHAV, zero hebraico) e o dano da
## mecânica só cai no instante do impacto. O sol persistente no cartão aliado nunca invade o Battle Log. Só prova que o código
## roda; a validação visual é do criador.
const SANDBOX := preload("res://tests/progress_sandbox.gd")
const FX_SCRIPT := "res://scripts/battle/skill_grotesque_fx.gd"
const SKILLS: Array[StringName] = [&"stone_crush", &"energy_blow", &"drain_claw", &"vital_claws", &"weaken", &"weakenen", &"mark_of_sun"]
const NORMAL: Array[StringName] = [&"stone_crush", &"energy_blow", &"drain_claw", &"weaken", &"mark_of_sun"]

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
var _strike_done := false


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


func _run() -> void:
	ProgressStore.save_path_override = "user://verify_d131_vfx_guard.json"
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
	await _sun()
	await _sync()
	print("VERIFY_D131_VFX_OK: %d checks; 7 choreographies in Enemy and Ally-card modes run clean and end on their own, gold only on ZAHAV, zero Hebrew, impact moments sync the mechanics, the persistent sun never touches the Battle Log" % checks)
	ProgressStore.clear()
	b.queue_free()
	quit(0)


# --------------------------------------------------------------------------- leis (leitura do código)
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


func _laws() -> void:
	var src := FileAccess.get_file_as_string(FX_SCRIPT).replace("\r\n", "\n")
	for fname in ["play_stone_crush", "play_energy_blow", "play_drain_claw", "play_weaken", "play_mark_of_sun", "play_mark_of_sun_trigger"]:
		var body := _body(src, fname)
		check(body.length() > 150 and not body.contains("GOLD") and not _zahav_palette(body) and not body.contains("EN_DROP_PAL") and not body.contains("PAL_ZAHAV"),
			"%s never uses the ZAHAV gold (normal attack)" % fname)
	for fname in ["play_stone_crush", "play_energy_blow", "play_drain_claw", "play_vital_claws", "play_weaken", "play_weakenen", "play_mark_of_sun", "play_mark_of_sun_trigger"]:
		var body2 := _body(src, fname)
		check(not body2.contains("draw_hebrew_tri_word") and not body2.contains("HEBREW_ALPHABET") and not body2.contains("FIRE_HEBREW"), "%s has no Hebrew letters" % fname)
	check(_body(src, "play_vital_claws").contains("palette_for(&\"blood\", true)") and _body(src, "play_vital_claws").contains("EN_DROP_PAL"), "Vital Claws uses the ZAHAV blood palette (gold outline)")
	check(_body(src, "play_weakenen").contains("palette_for(&\"blue\", true)") and _body(src, "play_weakenen").contains("GOLD"), "Weakenen uses the ZAHAV blue palette (gold outline)")
	# paletas canônicas
	check(g.PAL_STONE.accent == Color("6d5e52") and g.PAL_STONE.hi == Color("d9cfc2") and g.PAL_STONE.deep == Color("16110e"), "stone palette")
	check(g.PAL_ENERGY.accent == Color("553675") and g.PAL_ENERGY.hi == Color("c9bde0") and g.PAL_ENERGY.deep == Color("0b0514"), "energy palette")
	check(g.PAL_BLUE_STAT.accent == Color("25568a") and g.PAL_BLUE_STAT.hi == Color("9fc9ec") and g.PAL_BLUE_STAT.deep == Color("061124"), "blue stat palette")
	check(g.PAL_ZAHAV_BLUE.accent == Color("2b669e") and g.PAL_ZAHAV_BLUE.hi == Color("ffd84a") and g.PAL_ZAHAV_BLUE.deep == Color("08162b"), "zahav blue palette")
	check(g.PAL_SUN_NORMAL.accent == Color("c94c14") and g.PAL_SUN_NORMAL.hi == Color("f2d9b6") and g.PAL_SUN_NORMAL.deep == Color("240903"), "sun palette")
	for pal in [g.PAL_STONE, g.PAL_ENERGY, g.PAL_BLUE_STAT, g.PAL_SUN_NORMAL, g.PAL_BLOOD]:
		check(pal.hi != g.GOLD and pal.accent != g.GOLD and pal.deep != g.GOLD, "a normal palette carries no gold")
	for fam in [&"stone", &"energy", &"blue", &"sun", &"blood"]:
		var pn: Dictionary = SkillGrotesqueFX.palette_for(fam, false)
		check(pn.hi != g.GOLD, "palette_for(%s, normal) has no gold" % fam)
	check(SkillGrotesqueFX.palette_for(&"blue", true).hi == g.GOLD and SkillGrotesqueFX.palette_for(&"blood", true).hi == g.GOLD, "ZAHAV palettes carry the gold")
	for id in SKILLS:
		check(bool(SkillBook.def(id).get("grotesque", false)), "%s is flagged as choreographed" % id)
	# tempos canônicos (README do canônico)
	check(g.HIT_STONE == 0.62 and g.HIT_ENERGY == 0.56 and g.HIT_DRAIN == 0.36 and g.HIT_WEAKEN == 0.58 and g.HIT_SUN == 0.65, "hit moments of the single-hit attacks")
	check(g.HIT_VITAL_CLAWS[0] == 0.34 and g.HIT_VITAL_CLAWS[1] == 0.48 and g.HIT_WEAKENEN[0] == 0.78 and g.HIT_WEAKENEN[1] == 0.90, "hit moments of the two ZAHAV attacks")
	var durations := {&"stone_crush": 2.55, &"energy_blow": 2.65, &"drain_claw": 2.25, &"vital_claws": 2.40, &"weaken": 2.45, &"weakenen": 2.50}
	for id in durations:
		check(is_equal_approx(float(g.DURATIONS[id]), float(durations[id])), "%s lasts %.2fs" % [id, durations[id]])
	check(g.DURATIONS[&"mark_of_sun"] >= g.HIT_SUN, "MARK OF SUN: the ignition effect covers the 0.65 s growth")
	# Drain Claw é CONTIDO: UMA garra; Vital Claws: DUAS; sem boca/costela
	var drain := _body(src, "play_drain_claw")
	check(drain.count("_draw_single_impale_claw(") == 1 and drain.count("_draw_drop(") == 1, "DRAIN CLAW draws a single claw and the 6 drops")
	check(_body(src, "play_vital_claws").count("_draw_single_impale_claw(") == 2, "VITAL CLAWS draws exactly two claws")
	check(not drain.contains("draw_sketch_eye") and not drain.contains("rib"), "DRAIN CLAW has no mouth/rib")
	check(_body(src, "play_weakenen").contains("_draw_sketch_orb(origin") and _body(src, "play_weakenen").count("_draw_sketch_orb(") == 2, "WEAKENEN: one big orb on the caster fires two orbs")
	# o sol e o clarão: SEM triângulos soltos, SEM cone
	var sun_src := _body(src, "_draw_solar_hit_flare") + _body(src, "_draw_sun_body")
	check(not sun_src.contains("draw_colored_polygon(PackedVector2Array([Vector2(0") and not sun_src.contains("cone"), "MARK OF SUN: no falling triangles, no trapezoid cone")


# --------------------------------------------------------------------------- ciclo de vida
func _start(id: StringName, caster: BattleUnit, t0: BattleUnit, t1: BattleUnit) -> float:
	match id:
		&"stone_crush": return g.play_stone_crush(caster, t0)
		&"energy_blow": return g.play_energy_blow(caster, t0)
		&"drain_claw": return g.play_drain_claw(caster, t0)
		&"vital_claws": return g.play_vital_claws(caster, t0)
		&"weaken": return g.play_weaken(caster, t0)
		&"weakenen": return g.play_weakenen(caster, [t0, t1])
	return g.play_mark_of_sun(caster, t0)


func _lifecycle() -> void:
	for mode in ["foes", "allies"]:
		for id in SKILLS:
			g.clear_all()
			var caster: BattleUnit = hero if mode == "foes" else foe0
			var t0: BattleUnit = foe0 if mode == "foes" else hero
			var t1: BattleUnit = foe1 if mode == "foes" else ally
			var started: float = _start(id, caster, t0, t1)
			check(g.effect_count() == 1 and g.is_busy() and started >= 0.0, "%s [%s]: starts one effect" % [id, mode])
			await frames(20)
			check(g.effect_count() == 1 or id == &"mark_of_sun", "%s [%s]: still running after 20 frames" % [id, mode])
			var screen_bottom: float = b.hud.SCREEN.y
			for key in g._fields:
				var r: ColorRect = g._fields[key].rect
				if r.visible:
					var r_end := r.position.y + r.size.y
					check(r.position.y >= g.STAGE_TOP - 0.5 and r_end <= screen_bottom + 0.5, "%s [%s]: the field %s stays on the screen" % [id, mode, key])
					if mode == "foes":
						check(r_end <= g.stage_rect().end.y + 0.5,"%s [%s]: the field %s stays on the stage (above the Battle Log)" % [id, mode, key])
			var frames_run: int = await idle()
			check(g.effect_count() == 0 and frames_run < 500, "%s [%s]: ends on its own (%d frames)" % [id, mode, frames_run])
			check(g.field_count() == 0 and g.warp_count() == 0 and g.darken() < 0.01 and b.hud.warp_hidden.is_empty() and b.hud.warp_card.is_empty(),
				"%s [%s]: leaves no field, warp or veil behind" % [id, mode])
			check(not g.is_busy(), "%s [%s]: the engine is idle again" % [id, mode])
	# Weakenen com um só alvo vivo: uma esfera
	g.clear_all()
	g.play_weakenen(hero, [foe0, foe0])
	await idle()
	check(g.field_count() == 0 and g.warp_count() == 0, "WEAKENEN with a single target ends clean")
	# 3 cartões: um dos alvos do Weakenen é o herói 0 e o outro o aliado 1 (caster inimigo)
	g.play_weakenen(foe0, [hero, ally])
	await frames(70)
	check(g.warp_count() >= 1, "WEAKENEN warps the targeted cards")
	await idle()
	check(g.warp_count() == 0 and b.hud.warp_card.is_empty(), "the card warps are released")


# --------------------------------------------------------------------------- marca persistente de Mark of Sun
func _sun() -> void:
	g.clear_all()
	foe0.sun_mark_hits = 0
	hero.sun_mark_hits = 0
	ally.sun_mark_hits = 0
	# inimigo: o sol fica acima da cabeça, abaixo do HUD superior
	foe0.apply_sun_mark()
	await frames(4)
	check(g.has_sun(foe0) and not g.is_busy(), "the persistent sun of a marked foe lives without keeping the engine busy")
	var spot: Dictionary = g.sun_spot(foe0)
	check(spot.p.y - float(spot.r) - float(spot.ray_min) - float(spot.ray_var) >= g.STAGE_TOP * g.DESIGN_SCALE - 1.0, "the enemy sun stays under the top HUD")
	check(spot.p.y < g.unit_geom(foe0).c.y, "the enemy sun is above the head")
	foe0.sun_mark_hits = 0
	await frames(4)
	check(not g.has_sun(foe0), "the sun goes away with the mark")
	# aliado: canto inferior-direito livre do cartão, 0 px sobre o Battle Log
	var log_bottom: float = b.hud.BATTLE_LOG_RECT.end.y * g.DESIGN_SCALE
	for unit in [hero, ally]:
		unit.apply_sun_mark()
		await frames(4)
		check(g.has_sun(unit), "%s: persistent sun on the card" % unit.display_name)
		var sp: Dictionary = g.sun_spot(unit)
		var card: Rect2 = sp.card
		var reach := float(sp.r) * 1.35 + float(sp.ray_min) + float(sp.ray_var) + 4.0
		check(sp.p.y - reach >= log_bottom, "%s: the sun and its rays are below the Battle Log (%.1f >= %.1f)" % [unit.display_name, sp.p.y - reach, log_bottom])
		check(absf(sp.p.x - card.get_center().x) < 1.0 and absf(sp.p.y - card.end.y) < 1.0, "%s: the sun sits in the middle of the card's bottom border, spilling out" % unit.display_name)
		var halo: ColorRect = g._fields[StringName("sunm_%s" % unit.id)].rect
		check(halo.position.y * g.DESIGN_SCALE >= log_bottom - 0.5, "%s: the sun halo (Moire) never reaches the Battle Log" % unit.display_name)
		unit.sun_mark_hits = 0
		await frames(3)
		check(not g.has_sun(unit), "%s: the sun goes away" % unit.display_name)
	# disparo +20 MAGI: clarão solar nos dois modos, nunca no Battle Log (aliado)
	for unit in [foe0, hero]:
		unit.apply_sun_mark()
		g.play_mark_of_sun_trigger(unit)
		await frames(6)
		check(g.effect_count() == 1, "%s: the trigger flare runs" % unit.display_name)
		if unit.is_player:
			for key in g._fields:
				var r: ColorRect = g._fields[key].rect
				if r.visible:
					check(r.position.y * g.DESIGN_SCALE >= log_bottom - 0.5, "the ally trigger field %s never touches the Battle Log" % key)
		await idle()
		check(g.field_count() == 0 and g._sun_pulse.is_empty(), "%s: the trigger flare cleans up" % unit.display_name)
		unit.sun_mark_hits = 0
	# a mecânica dispara o clarão
	g.clear_all()
	hero.sun_mark_hits = 0
	hero.current_hp = 1000
	hero.stats.max_hp = 1000
	hero.apply_sun_mark()
	b._sun_mark_trigger(foe0, hero, 10)
	check(hero.sun_mark_hits == 2 and g.effect_count() == 1, "a landed hit on a marked unit starts the trigger flare (3 -> 2 charges)")
	await idle()
	hero.sun_mark_hits = 0
	await frames(2)
	# ver a barreira: o limpar do motor também leva o sol
	foe1.apply_sun_mark()
	await frames(3)
	g.clear_all()
	check(not g.has_sun(foe1), "clear_all removes the persistent sun")
	foe1.sun_mark_hits = 0


# --------------------------------------------------------------------------- sincronismo com a mecânica
func _strike(skill: StringName, victim: BattleUnit, second: BattleUnit = null) -> void:
	b._second_target = second
	await b._skill_strike(foe0, victim, skill, false, false, true)
	_strike_done = true


func _sync() -> void:
	for pair in [[&"stone_crush", 0.62], [&"energy_blow", 0.56], [&"drain_claw", 0.36], [&"vital_claws", 0.48]]:
		var id: StringName = pair[0]
		var hit: float = pair[1]
		for victim in [hero, ally]:
			g.clear_all()
			for u in [hero, ally, foe0, foe1]:
				u.current_hp = 1000
				u.stats.max_hp = 1000
				u.statuses.clear()
				u.weaken_mef_penalty = 0
			var start: float = g.time
			var hp_before: int = victim.current_hp
			_strike_done = false
			_strike(id, victim)
			var dmg_age := -1.0
			var guard := 0
			while not _strike_done and guard < 600:
				await process_frame
				guard += 1
				if dmg_age < 0.0 and victim.current_hp < hp_before:
					dmg_age = g.time - start
			check(dmg_age >= hit - 0.04, "%s on %s: the damage lands at the impact moment (%.2fs >= %.2fs)" % [id, victim.display_name, dmg_age, hit])
			check(dmg_age <= hit + 0.12, "%s on %s: ...and right at it, not later (%.2fs)" % [id, victim.display_name, dmg_age])
			await idle()
	# Weaken / Mark of Sun / Weakenen: o efeito de status cai no instante
	for pair in [[&"weaken", 0.58], [&"mark_of_sun", 0.65]]:
		var id2: StringName = pair[0]
		var hit2: float = pair[1]
		g.clear_all()
		hero.weaken_mef_penalty = 0
		hero.sun_mark_hits = 0
		hero.statuses.clear()
		hero.stats.mef = 100
		var start2: float = g.time
		_strike_done = false
		_strike(id2, hero)
		var landed := -1.0
		var guard2 := 0
		while not _strike_done and guard2 < 600:
			await process_frame
			guard2 += 1
			if landed < 0.0 and (hero.weaken_mef_penalty > 0 or hero.sun_mark_hits > 0):
				landed = g.time - start2
		check(landed >= hit2 - 0.04 and landed <= hit2 + 0.12, "%s: the status lands at its impact moment (%.2fs vs %.2fs)" % [id2, landed, hit2])
		await idle()
		hero.sun_mark_hits = 0
		await frames(3)
	# Weakenen: dois alvos, um impacto por alvo
	g.clear_all()
	hero.weaken_mef_penalty = 0
	ally.weaken_mef_penalty = 0
	hero.stats.mef = 100
	ally.stats.mef = 100
	var start3: float = g.time
	_strike_done = false
	_strike(&"weakenen", hero, ally)
	var land_a := -1.0
	var land_b := -1.0
	var guard3 := 0
	while not _strike_done and guard3 < 600:
		await process_frame
		guard3 += 1
		if land_a < 0.0 and hero.weaken_mef_penalty > 0:
			land_a = g.time - start3
		if land_b < 0.0 and ally.weaken_mef_penalty > 0:
			land_b = g.time - start3
	check(land_a >= 0.74 and land_a <= 0.90, "WEAKENEN: the first target is hit at 0.78 s (%.2f)" % land_a)
	check(land_b >= 0.86 and land_b <= 1.02, "WEAKENEN: the second target is hit at 0.90 s (%.2f)" % land_b)
	check(land_b > land_a, "WEAKENEN: one impact per target")
	await idle()
	g.clear_all()
	for u in [hero, ally]:
		u.weaken_mef_penalty = 0
		u.statuses.clear()
	b._second_target = null
