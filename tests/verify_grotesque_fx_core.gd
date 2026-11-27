extends SceneTree
## D-125 Fase 3: fundação visual dos ataques não-reza (SkillGrotesqueFX + shaders GPU). Prova só que o código roda
## e respeita as regras estruturais (ouro só em ZAHAV, camadas, recortes); a validação visual é do criador.
const SANDBOX := preload("res://tests/progress_sandbox.gd")
const PLAYABLE := preload("res://scenes/battle/BattlePlayable.tscn")
const FX := preload("res://scripts/battle/skill_grotesque_fx.gd")

var checks := 0


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


func _is_gold(c: Color) -> bool:
	return c.is_equal_approx(Color("ffd84a"))


func _run() -> void:
	_shaders()
	_hash_and_palettes()
	await _live()
	print("VERIFY_GROTESQUE_FX_CORE_OK: %d checks; hypnotic_moire + target_fever_warp shaders, sketch_hash/boil, palette_for (gold only with ZAHAV), primitives, Moire fields, veil/shake/warp and the PlayableController integration" % checks)
	quit(0)


# --------------------------------------------------------------------------- shaders
func _shaders() -> void:
	var moire: Shader = load("res://assets/shaders/hypnotic_moire.gdshader")
	var warp: Shader = load("res://assets/shaders/target_fever_warp.gdshader")
	check(moire != null and warp != null, "both .gdshader files load")
	check(moire.get_mode() == Shader.MODE_CANVAS_ITEM and warp.get_mode() == Shader.MODE_CANVAS_ITEM, "both are canvas_item shaders")
	var names_m: Array[String] = []
	for u in moire.get_shader_uniform_list():
		names_m.append(String(u.name))
	for need in ["mode", "time_val", "env", "dark_bias", "rect_size", "mouth_pos", "reach", "dir_x", "col_hi", "col_accent", "col_dark"]:
		check(names_m.has(need), "hypnotic_moire exposes the uniform %s" % need)
	var names_w: Array[String] = []
	for u in warp.get_shader_uniform_list():
		names_w.append(String(u.name))
	for need in ["warp_amp", "time_val", "invert_mix"]:
		check(names_w.has(need), "target_fever_warp exposes the uniform %s" % need)
	# the equations of docs/NON_PRAYER_VFX_STYLE.md §3.2 / HTML are in the source, character for character
	var src := moire.code
	for token in ["floor(p / STEP) * STEP", "const float STEP = 5.0",
			"sin(dist * 0.21 - time_val * 14.0 + sin(ang * 4.0 + time_val * 5.0) * 2.1)",
			"cos((dx * 0.1 - dy * 0.08) + sin(c.y * 0.08 + time_val * 8.0) * 1.9)",
			"float half_h = 16.0 + dx * 0.21;",
			"sin(dx * 0.095 - time_val * 19.0 + sin(c.y * 0.1 + time_val * 9.0) * 2.3)",
			"cos((c.y - mouth_pos.y) * 0.13 + sin(dx * 0.055 - time_val * 11.0) * 2.2)",
			"thr = 0.22;", "hi_v = 1.55;", "mid_v = 0.78;", "ak = 1.55;", "acap = 0.95;"]:
		check(src.contains(token), "moire source carries: %s" % token)
	var wsrc := warp.code
	for token in ["sin(band * 0.18 + time_val * 20.0) * warp_amp", "cos(band * 0.09 - time_val * 12.0) * warp_amp * 0.5", "/ 3.5"]:
		check(wsrc.contains(token), "warp source carries: %s" % token)


# --------------------------------------------------------------------------- hash, boil e paletas
func _hash_and_palettes() -> void:
	for n in [0.0, 1.0, 7.0, 31.5, 1234.0]:
		var s: float = sin(float(n) * 127.1 + 311.7) * 43758.5453
		var want: float = s - floor(s)
		check(is_equal_approx(FX.sketch_hash(float(n)), want) and FX.sketch_hash(float(n)) == FX.sketch_hash(float(n)), "sketch_hash(%s) is fract(sin(n*127.1+311.7)*43758.5453) and deterministic" % n)
		check(FX.sketch_hash(float(n)) >= 0.0 and FX.sketch_hash(float(n)) < 1.0, "sketch_hash is in [0,1)")
	check(FX.boil_index(0.0) == 0 and FX.boil_index(0.083) == 0 and FX.boil_index(0.0834) == 1 and FX.boil_index(1.0) == 12, "the boil runs at 12 FPS: f_idx = floor(t*12)")
	# ouro só com ZAHAV
	for family in [&"blood", &"abyss", &"fire"]:
		var normal: Dictionary = FX.palette_for(family, false)
		for k in normal:
			check(not _is_gold(normal[k]), "palette_for(%s, false).%s is never gold" % [family, k])
	for family in [&"blood", &"fire"]:
		check(_is_gold(FX.palette_for(family, true).hi), "palette_for(%s, true).hi is #ffd84a" % family)
	check(FX.palette_for(&"blood", false).accent == Color("a81c2e") and FX.palette_for(&"blood", false).hi == Color("efe6d5"), "blood: #a81c2e / #efe6d5")
	check(FX.palette_for(&"abyss", false).accent == Color("361c52") and FX.palette_for(&"abyss", false).hi == Color("9b8ab0"), "abyss: #361c52 / #9b8ab0")
	check(FX.palette_for(&"fire", false).accent == Color("c94c14") and FX.palette_for(&"fire", false).hi == Color("f2d9b6"), "fire: #c94c14 / #f2d9b6")
	check(FX.palette_for(&"fire", true).accent == Color("d95b16") and FX.palette_for(&"blood", true).accent == Color("a81c2e"), "ZAHAV accents: fire #d95b16, blood #a81c2e")
	check(FX.FIRE_HEBREW == [Color("ff7a1f"), Color("ffd84a"), Color("ffffff")], "FIRE_HEBREW is orange / yellow / white")
	# nenhuma paleta normal repete o ouro nas constantes
	for pal in [FX.PAL_BLOOD, FX.PAL_ABYSS_DARK, FX.PAL_FIRE_NORMAL]:
		for k in pal:
			check(not _is_gold(pal[k]), "a normal palette constant has no gold (%s)" % k)
	# o ouro é a única cor ZAHAV que difere da família normal
	check(FX.PAL_ZAHAV_BLOOD.hi != FX.PAL_BLOOD.hi and FX.PAL_ZAHAV_BLOOD.accent == FX.PAL_BLOOD.accent, "ZAHAV blood only swaps the outline to gold")
	check(FX.to_design(Vector2(544, 300)) == Vector2(816, 450) and FX.to_logical(Vector2(816, 450)) == Vector2(544, 300), "design space = logical x 1.5")


# --------------------------------------------------------------------------- ao vivo (integração)
func _live() -> void:
	ProgressStore.save_path_override = "user://verify_grotesque_guard.json"
	ProgressStore.clear()
	var b: Control = PLAYABLE.instantiate()
	root.add_child(b)
	await frames(10)
	var g: Node2D = b.grotesque_fx
	check(g != null and g is FX and g.get_parent() == b and g.hud == b.hud and g.battle == b, "SkillGrotesqueFX is created by the PlayableController and wired to the HUD")
	var damage_z: int = b.fx.z_index + b.fx.damage_layer.z_index
	check(g.z_index < damage_z and g.z_index < b.prayer.fx.z_index, "its z_index (%d) is strictly below the DamageLayer (%d) and the prayer layer" % [g.z_index, damage_z])
	check(g._fields_layer.z_index < 0, "the Moire layer sits behind the sketches the node draws")
	check(not g.is_busy(), "idle: not busy")

	# recorte do palco: entre o HUD superior (y=22) e o Battle Log
	var stage: Rect2 = g.stage_rect()
	check(stage.position.y == 22.0 and is_equal_approx(stage.end.y, b.hud.BATTLE_LOG_RECT.position.y), "the stage rect runs from y=22 to the Battle Log (%s)" % stage)

	# campos de Moiré
	var pal: Dictionary = FX.palette_for(&"blood", false)
	g.set_field(&"a", {"mode": 0, "cx": 400.0, "cy": 220.0, "rx": 150.0, "ry": 100.0, "env": 1.0, "pal": pal, "profile": &"v3"})
	g.set_field(&"cone", {"mode": 1, "mouth": Vector2(40.0, 200.0), "reach": 500.0, "dir_x": 1.0, "env": 1.0, "pal": FX.palette_for(&"abyss", false), "profile": &"v4"})
	check(g.field_count() == 2 and g.is_busy(), "two Moire fields are alive and the node is busy")
	for key in [&"a", &"cone"]:
		var rect: ColorRect = g._fields[key].rect
		var sr := Rect2(g.stage_rect().position, g.stage_rect().size)
		check(rect.visible and sr.encloses(Rect2(rect.position, rect.size)), "field %s is clipped inside the stage (%s)" % [key, Rect2(rect.position, rect.size)])
		check(rect.material is ShaderMaterial and (rect.material as ShaderMaterial).shader.resource_path.ends_with("hypnotic_moire.gdshader"), "field %s uses the GPU shader" % key)
	var mat: ShaderMaterial = g._fields[&"a"].rect.material
	check(float(mat.get_shader_parameter("threshold")) == 0.26 and mat.get_shader_parameter("col_hi") == pal.hi and mat.get_shader_parameter("col_accent") == pal.accent, "the field carries the v3 profile and the palette")
	var cone_mat: ShaderMaterial = g._fields[&"cone"].rect.material
	check(int(cone_mat.get_shader_parameter("mode")) == 1 and float(cone_mat.get_shader_parameter("dir_x")) == 1.0, "the cone field runs in breath_cone mode, dir +1")
	g.set_field(&"cone", {"mode": 1, "mouth": Vector2(776.0, 200.0), "reach": 500.0, "dir_x": -1.0, "env": 1.0, "pal": FX.palette_for(&"abyss", false), "profile": &"v4"})
	check(float((g._fields[&"cone"].rect.material as ShaderMaterial).get_shader_parameter("dir_x")) == -1.0, "the cone mirrors with dir_x = -1")
	g.set_field(&"dark", {"mode": 0, "cx": 400.0, "cy": 220.0, "rx": 100.0, "ry": 80.0, "env": 0.01, "pal": pal})
	check(not g._fields[&"dark"].rect.visible, "a field with env <= 0.02 is hidden")
	await frames(3)
	check(float(mat.get_shader_parameter("time_val")) > 0.0, "the shader time follows the node clock")
	g.clear_field(&"dark")
	g.clear_fields()
	await frames(2)
	check(g.field_count() == 0, "fields clear")

	# véu de escurecimento só no palco
	g.set_darken(0.5)
	check(g._veil.visible and is_equal_approx(g._veil.color.a, 0.5) and g._veil.position.y == 22.0 and is_equal_approx(g._veil.position.y + g._veil.size.y, 300.0), "the veil covers only the stage (y 22..300)")
	g.set_darken(0.0)
	check(not g._veil.visible, "no darkness: the veil is hidden")

	# primitivas desenhadas (sem erro, com os rabiscos em boil)
	var drawn := [0]
	var hi_pal: Dictionary = FX.palette_for(&"fire", true)
	g.add_effect(0.3, func(fx: Node2D, age: float) -> void:
		var f_idx := FX.boil_index(age)
		var pts := PackedVector2Array([Vector2(300, 200), Vector2(340, 190), Vector2(350, 240), Vector2(310, 250)])
		fx.draw_sketch_shape(pts, f_idx, FX.palette_for(&"blood", false))
		fx.draw_sketch_eye(420, 210, 28, 14, f_idx, FX.palette_for(&"abyss", false))
		fx.draw_sketch_eye(480, 210, 28, 14, f_idx, FX.palette_for(&"abyss", false), true)
		fx.draw_sketch_eye(540, 210, 28, 14, f_idx, FX.palette_for(&"abyss", false), false, true, 0.7)
		fx.draw_sketch_flame(300, 320, 1.0, f_idx, FX.palette_for(&"fire", false))
		fx.draw_sketch_flame(380, 320, 0.55, f_idx, hi_pal, FX.FILL_BODY, 1.0, &"v4")
		fx.draw_hebrew_tri_word("אש", Vector2(440, 330), 30, 1.0)
		drawn[0] += 1)
	await frames(4)
	check(drawn[0] >= 2, "all primitives drew in the same frame, repeatedly (%d draws) without errors" % drawn[0])
	check(g.is_busy() or g.effect_count() == 0, "effects expire by themselves")
	await frames(30)
	check(g.effect_count() == 0 and not g.is_busy(), "after its duration the effect is gone and the node is idle")

	# sketchy_pts: jitter limitado e determinístico
	var base := PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10)])
	var j1: PackedVector2Array = g.sketchy_pts(base, 5, 2.4)
	var j2: PackedVector2Array = g.sketchy_pts(base, 5, 2.4)
	var j3: PackedVector2Array = g.sketchy_pts(base, 6, 2.4)
	check(j1 == j2 and j1 != j3, "the jitter is deterministic per boil frame and changes with the frame")
	for i in base.size():
		check(absf(j1[i].x - base[i].x) <= 2.4 and absf(j1[i].y - base[i].y) <= 2.4, "the jitter of vertex %d stays within +-2.4" % i)
	check(g.flame_points(0, 0, 1.0).size() == 11 and g.flame_points(0, 0, 1.0, &"v4").size() == 11, "the flame has exactly 11 vertices (v3 and v4)")

	# distorção febril do alvo
	var foe: BattleUnit = b.hud.opponents[0]
	g.trigger_target_warp(foe, 11.0, 0.3, 0.14)
	check(g.warp_count() == 1 and b.hud.warp_hidden.has(foe.id), "an enemy under warp is replaced by the overlay (the HUD hides the plain silhouette)")
	await frames(3)
	var sprite: Sprite2D = g._warps[foe.id].sprite
	var wmat: ShaderMaterial = sprite.material
	check(wmat.shader.resource_path.ends_with("target_fever_warp.gdshader") and float(wmat.get_shader_parameter("warp_amp")) > 0.0 and float(wmat.get_shader_parameter("invert_mix")) == 1.0,
		"the overlay runs target_fever_warp with warp amplitude and the bone inversion flash")
	check(sprite.get_rect().size.x > 0.0 and sprite.global_position.is_equal_approx(b.hud.enemy_sprite_rect(0).position + b.hud.shake_offset(foe)), "the overlay sits exactly over the enemy sprite")
	await frames(30)
	check(float(wmat.get_shader_parameter("invert_mix")) == 0.0 or g.warp_count() == 0, "the inversion flash is brief")
	await frames(30)
	check(g.warp_count() == 0 and not b.hud.warp_hidden.has(foe.id), "the warp ends and the HUD draws the silhouette again")
	var hero: BattleUnit = b.hud.players[0]
	g.trigger_target_warp(hero, 8.0, 0.3, 0.0)
	await frames(3)
	check(b.hud.warp_card.has(hero.id) and not b.hud.warp_hidden.has(hero.id), "a hero under warp wobbles its card (no sprite overlay)")
	check(b.hud.shake_offset(hero) == b.hud.warp_card[hero.id] or b.hud.shake_offset(hero).y == 0.0, "the card wobble reaches shake_offset")
	await frames(40)
	check(not b.hud.warp_card.has(hero.id), "the card stops wobbling")

	# shake de tela
	var base_t: Transform2D = b.get_viewport().canvas_transform
	g.camera_shake(8.0, 0.2)
	check(g.is_busy(), "a shake keeps the node busy")
	await frames(6)
	await frames(40)
	check(b.get_viewport().canvas_transform == base_t and not g.is_busy(), "the shake restores the canvas transform and ends")

	# o fluxo de espera do controlador considera o motor
	g.set_darken(0.3)
	b.hud.mode = "continue"
	b.handle_confirm()
	check(b.hud.mode == "continue", "Z does not advance the result while the grotesque effects are busy")
	g.clear_all()
	check(not g.is_busy(), "clear_all leaves the node idle")
	ProgressStore.clear()
	b.queue_free()
	await process_frame
