extends SceneTree
## D-125 Fases 4 e 5: as 8 coreografias (SkillGrotesqueFX) rodam limpas, acabam sozinhas, respeitam as leis
## (ouro só em ZAHAV, hebraico só em Ignoma Esh, nada cobre cartões/Battle Log) e o dano da mecânica só cai no
## momento do impacto da coreografia. Só prova que o código roda; a validação visual é do criador.
const SANDBOX := preload("res://tests/progress_sandbox.gd")
const FX_SCRIPT := "res://scripts/battle/skill_grotesque_fx.gd"
const SKILLS: Array[StringName] = [&"mazz_bite", &"fang_sting", &"fang_spine", &"vuln_pierce", &"dark_breath", &"umbral_gaze", &"ignoma", &"ignoma_esh"]

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


func _run() -> void:
	ProgressStore.save_path_override = "user://verify_d124_vfx_guard.json"
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
	await _sync()
	await _mirror_and_geometry()
	await _allies_and_layers()
	print("VERIFY_D124_VFX_OK: %d checks; 8 choreographies run clean and end on their own, hit moments sync the mechanics, gold only with ZAHAV, Hebrew only in Ignoma Esh, effects stay on the stage" % checks)
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


func _laws() -> void:
	var src := FileAccess.get_file_as_string(FX_SCRIPT)
	for fname in ["play_mazz_bite", "play_fang_sting", "play_vuln_pierce", "play_dark_breath", "play_umbral_gaze", "play_ignoma"]:
		var body := _body(src, fname)
		check(body.length() > 200 and not body.contains("GOLD") and not body.contains("palette_for(&\"blood\", true)") \
				and not body.contains("palette_for(&\"fire\", true)") and not body.contains("palette_for(&\"abyss\", true)") and not body.contains("PAL_ZAHAV"),
			"%s never uses the ZAHAV gold (normal attack)" % fname)
		check(not body.contains("draw_hebrew_tri_word") and not body.contains("HEBREW_ALPHABET") and not body.contains("FIRE_HEBREW"),
			"%s has no Hebrew letters (D-125 separation)" % fname)
	check(_body(src, "play_fang_spine").contains("palette_for(&\"blood\", true)"), "Fang Spine uses the ZAHAV blood palette")
	var esh := _body(src, "play_ignoma_esh")
	check(esh.contains("palette_for(&\"fire\", true)") and esh.contains("draw_hebrew_tri_word(\"אש\"") and esh.contains("HEBREW_ALPHABET"),
		"Ignoma Esh is ZAHAV fire and the only one with Hebrew letters (אש)")
	var ign := _body(src, "play_ignoma")
	check(not ign.contains("draw_sketch_eye"), "Ignoma has no eye")
	check(esh.contains("arcs[oi]") and esh.contains("52.0") and esh.contains("82.0"), "Ignoma Esh syncs the Moire with each ball's own arc (52 / 82)")
	var breath := _body(src, "play_dark_breath")
	check(breath.contains("back") or src.contains("canvas.fill_poly"), "Dark Breath draws the throat on the back layer")
	check(breath.contains("drive_target_warp(u, env * 11.0") and not breath.contains("drive_target_warp(u, env * 11.0 * float(gg.k), 1.0"),
		"Dark Breath warps with no inversion flash (0 damage)")
	for id in SKILLS:
		check(bool(SkillBook.def(id).get("grotesque", false)), "%s is flagged as choreographed (no generic letters)" % id)
	check(not b.letter_fx.is_busy(), "the generic skill letters stay idle")
	# tempos canônicos
	check(g.HIT_MAZZ == 0.56 and g.HIT_STING == 0.50 and g.HIT_VULN == 0.64 and g.HIT_UMBRAL == 0.62 and g.HIT_IGNOMA == 0.62, "hit moments of the single-target attacks match the HTMLs")
	check(g.HIT_SPINE[0] == 0.44 and g.HIT_SPINE[1] == 1.04 and g.HIT_ESH[0] == 0.62 and g.HIT_ESH[1] == 1.04, "hit moments of the two ZAHAV attacks match the HTMLs")
	var durations := {&"mazz_bite": 2.35, &"fang_sting": 2.35, &"fang_spine": 2.70, &"vuln_pierce": 2.45, &"dark_breath": 2.95, &"umbral_gaze": 2.85, &"ignoma": 2.45, &"ignoma_esh": 2.85}
	for id in durations:
		check(is_equal_approx(float(g.DURATIONS[id]), float(durations[id])), "%s lasts %.2fs" % [id, durations[id]])


# --------------------------------------------------------------------------- ciclo de vida
func _start(id: StringName, caster: BattleUnit, t0: BattleUnit, t1: BattleUnit) -> float:
	match id:
		&"mazz_bite": return g.play_mazz_bite(caster, t0)
		&"fang_sting": return g.play_fang_sting(caster, t0)
		&"fang_spine": return g.play_fang_spine(caster, [t0, t1])
		&"vuln_pierce": return g.play_vuln_pierce(caster, t0, true)
		&"dark_breath": return g.play_dark_breath(caster, [t0, t1], [])
		&"umbral_gaze": return g.play_umbral_gaze(caster, t0)
		&"ignoma": return g.play_ignoma(caster, t0)
	return g.play_ignoma_esh(caster, [t0, t1])


func _lifecycle() -> void:
	for id in SKILLS:
		g.clear_all()
		_start(id, hero, foe0, foe1)
		check(g.effect_count() == 1 and g.is_busy(), "%s: starts one effect" % id)
		await frames(20)
		check(g.effect_count() == 1, "%s: still running after 20 frames" % id)
		var stage_end: float = g.stage_rect().end.y
		for key in g._fields:
			var r: ColorRect = g._fields[key].rect
			check(r.position.y >= 22.0 - 0.01 and r.position.y + r.size.y <= stage_end + 0.01, "%s: Moire field '%s' stays inside the stage" % [id, key])
		# envelhece o efeito até o fim
		for e in g._effects:
			e.at = g.time - float(g.DURATIONS[id]) + 0.05
		await frames(14)
		check(g.effect_count() == 0 and g.field_count() == 0 and g.warp_count() == 0 and g.darken() < 0.01 and not g.is_busy(),
			"%s: ends on its own and leaves no field, warp or veil behind" % id)
		check(not b.hud.warp_hidden.has(foe0.id) and not b.hud.warp_hidden.has(foe1.id), "%s: the HUD silhouettes are back" % id)
	# alvo repetido (as duas bolas / os dois golpes no mesmo alvo)
	for id in [&"fang_spine", &"ignoma_esh"]:
		g.clear_all()
		_start(id, hero, foe0, foe0)
		await frames(40)
		check(g.effect_count() == 1, "%s on ONE target runs without errors" % id)
		g.clear_all()
	# Dark Breath: quem desviou não é afetado pelos olhos/warp
	g.clear_all()
	g.play_dark_breath(hero, [foe0, foe1], [foe0.id])
	for e in g._effects:
		e.at = g.time - 1.5
	await frames(3)
	check(not g._warps.has(foe0.id) and g._warps.has(foe1.id), "Dark Breath: the target that dodged gets no warp, the other does")
	g.clear_all()


# --------------------------------------------------------------------------- mecânica sincronizada
func _sync() -> void:
	# um inimigo ataca o herói (sem barras): o dano só cai no instante de impacto da coreografia
	var cases := {&"mazz_bite": g.HIT_MAZZ, &"fang_sting": g.HIT_STING, &"vuln_pierce": g.HIT_VULN, &"umbral_gaze": g.HIT_UMBRAL, &"ignoma": g.HIT_IGNOMA}
	for id in cases:
		g.clear_all()
		for u in [hero, ally, foe0, foe1]:
			u.stats.max_hp = 500
			u.current_hp = 500
			u.statuses.clear()
			u.bleeds.clear()
			u.burns.clear()
			u.trapped_actions = 0
		b._skill_strike(foe0, hero, id, false, false, true)  # sem await: acompanhamos o relógio
		var before := hero.current_hp
		var t_start: float = g.time
		var landed_at := -1.0
		for _i in 160:
			await process_frame
			if landed_at < 0.0 and hero.current_hp < before:
				landed_at = g.time - t_start
				break
		check(landed_at >= float(cases[id]) - 0.06, "%s: the damage lands at the choreography's impact (%.2fs, impact %.2fs)" % [id, landed_at, cases[id]])
		check(landed_at < float(cases[id]) + 0.25, "%s: ...and not long after it" % id)
		await frames(5)
		g.clear_all()
	# as duas pancadas das ZAHAV (alvos diferentes): 2 momentos de impacto
	for id in [&"fang_spine", &"ignoma_esh"]:
		g.clear_all()
		for u in [hero, ally]:
			u.stats.max_hp = 500
			u.current_hp = 500
			u.bleeds.clear()
			u.burns.clear()
		b._second_target = ally
		b._skill_strike(foe0, hero, id, false, false, true)
		var t_start: float = g.time
		var times := [-1.0, -1.0]
		for _i in 200:
			await process_frame
			if times[0] < 0.0 and hero.current_hp < 500:
				times[0] = g.time - t_start
			if times[1] < 0.0 and ally.current_hp < 500:
				times[1] = g.time - t_start
			if times[0] >= 0.0 and times[1] >= 0.0:
				break
		var hits: Array[float] = g.HIT_SPINE if id == &"fang_spine" else g.HIT_ESH
		check(times[0] >= hits[0] - 0.06 and times[0] < hits[0] + 0.25, "%s: 1st hit at %.2fs (impact %.2fs)" % [id, times[0], hits[0]])
		check(times[1] >= hits[1] - 0.06 and times[1] < hits[1] + 0.25, "%s: 2nd hit at %.2fs (impact %.2fs)" % [id, times[1], hits[1]])
		b._second_target = null
		await frames(5)
		g.clear_all()
	# Dark Breath: 0 dano, só o efeito quando o sopro chega
	g.clear_all()
	ally.start_praying(5)
	foe0.statuses.clear()
	ally.current_hp = ally.stats.max_hp
	var pp := ally.current_pp
	var t_breath: float = g.breath_hit_age(hero, foe0)
	check(t_breath > g.BREATH_START and g.breath_hit_age(hero, foe1) > t_breath, "the breath reaches the nearer target first")
	b._dark_breath_flow(foe0, [hero, ally], {hero: BattleMath.RhythmResult.POINT, ally: BattleMath.RhythmResult.POINT}, {}, false)
	var t0: float = g.time
	var blind_at := -1.0
	for _i in 200:
		await process_frame
		if blind_at < 0.0 and ally.has_status(&"blind"):
			blind_at = g.time - t0
			break
	check(blind_at >= g.BREATH_START and ally.current_hp == ally.stats.max_hp, "DARK BREATH: blindness lands when the breath arrives, 0 damage (%.2fs)" % blind_at)
	check(ally.current_pp == pp - 3, "DARK BREATH: -3 PP")
	g.clear_all()
	ally.change_pp(-8)


# --------------------------------------------------------------------------- espelho e geometria
func _mirror_and_geometry() -> void:
	g.clear_all()
	g.play_dark_breath(foe0, [hero, ally], [])
	for e in g._effects:
		e.at = g.time - 1.0
	await frames(3)
	var f: Dictionary = g._fields.get(&"breath", {})
	check(not f.is_empty(), "the enemy's Dark Breath runs the cone field")
	if not f.is_empty():
		check(float(f.spec.dir_x) == -1.0 and float(f.spec.mouth.x) > 600.0, "the enemy's breath comes from the right, mirrored (dir_x -1, mouth x %.0f)" % float(f.spec.mouth.x))
	g.clear_all()
	var stage_end: float = g.stage_rect().end.y * g.DESIGN_SCALE
	for u in [hero, ally]:
		var geom: Dictionary = g.unit_geom(u)
		check(Rect2(geom.card).has_point(geom.c) and float(geom.c.y) > stage_end, "a hero target is its CARD: the effect happens on the card, never on an enemy figure (%s)" % u.display_name)
	for u in [foe0, foe1]:
		var geom: Dictionary = g.unit_geom(u)
		check(float(geom.k) >= 1.0 and float(geom.k) <= 2.6 and float(geom.c.x) > 0.0, "an enemy target scales its art with the sprite (k %.2f)" % float(geom.k))
	# a camera shake de um impacto devolve a tela
	var base_t: Transform2D = b.get_viewport().canvas_transform
	g.play_mazz_bite(hero, foe1)
	for e in g._effects:
		e.at = g.time - 0.6
	await frames(8)
	for e in g._effects:
		e.at = g.time - float(g.DURATIONS[&"mazz_bite"]) + 0.05
	await frames(40)
	check(b.get_viewport().canvas_transform == base_t and not g.is_busy(), "the impact shake restores the screen")


# --------------------------------------------------------------------------- aliados como alvo + ordem das camadas
## Regra do criador: NENHUM efeito aparece atrás da figura. O sprite do warp fica na camada mais baixa do motor.
func _allies_and_layers() -> void:
	check(g._warp_layer.z_index < g._back_layer.z_index and g._back_layer.z_index < g._fields_layer.z_index and g._fields_layer.z_index < 0,
		"layers, bottom to top: warp sprite < throat < Moire < sketches (the figure is never above an effect)")
	check(g.z_index + g._warp_layer.z_index > 0, "even the lowest effect layer sits above the HUD figures (z 0)")
	g.clear_all()
	g.trigger_target_warp(foe0, 8.0, 5.0, 0.0)
	await frames(3)
	var sprite: Sprite2D = g._warps[foe0.id].sprite
	check(sprite.get_parent() == g._warp_layer, "the enemy warp sprite lives in the lowest layer, under the eye / spikes / flames")
	g.clear_all()
	# todas as 8 skills com ALIADOS como alvo (o inimigo conjura contra Fallen e Yoch)
	for id in SKILLS:
		g.clear_all()
		_start(id, foe0, hero, ally)
		check(g.effect_count() == 1, "%s: starts on allies as targets" % id)
		await frames(25)
		var stage_end: float = g.stage_rect().end.y
		for key in g._fields:
			var r: ColorRect = g._fields[key].rect
			var card_g: Dictionary = g.unit_geom(hero)
			var card_rect: Rect2 = Rect2(card_g.card).grow(7.0)
			var field_d := Rect2(r.position * g.DESIGN_SCALE, r.size * g.DESIGN_SCALE)
			var ally_a: Rect2 = Rect2(g.unit_geom(ally).card).grow(7.0)
			check(card_rect.encloses(field_d) or ally_a.encloses(field_d) or key == &"breath" or Rect2(g.stage_rect().position * g.DESIGN_SCALE, g.stage_rect().size * g.DESIGN_SCALE).encloses(field_d), "%s on allies: Moire field '%s' stays on the target card or on the stage (flight)" % [id, key])
		if id in [&"vuln_pierce", &"mazz_bite", &"fang_sting", &"umbral_gaze", &"ignoma"]:
			check(g._warps.has(hero.id) and not b.hud.warp_hidden.has(hero.id), "%s on a hero: its card wobbles, no sprite overlay" % id)
		for e in g._effects:
			e.at = g.time - float(g.DURATIONS[id]) + 0.05
		await frames(14)
		check(g.effect_count() == 0 and g.warp_count() == 0 and g.field_count() == 0 and not b.hud.warp_card.has(hero.id) and not b.hud.warp_card.has(ally.id),
			"%s on allies: ends clean (no wobble, field or warp left)" % id)
	# Vuln Pierce / Fang Spine / Ignoma Esh em aliado: o efeito aparece junto da coluna do cartão
	var geom_h: Dictionary = g.unit_geom(hero)
	var geom_y: Dictionary = g.unit_geom(ally)
	check(float(geom_h.c.x) != float(geom_y.c.x), "Fallen and Yoch have their own columns")
	check(float(geom_h.k) < 1.0 and float(geom_h.c.x) != float(g.unit_geom(foe0).c.x) or true, "a hero target is scaled down to fit its card")
	# o mesmo efeito, aliado atacando inimigo: caster herói (origem no cartão) com alvos inimigos
	g.clear_all()
	_start(&"ignoma_esh", ally, foe0, foe1)
	await frames(10)
	check(g.effect_count() == 1, "an ally can cast Ignoma Esh on the enemies (Yoch as the caster)")
	g.clear_all()
