extends SceneTree
## D-129 (criador 2026-11-27): verificação completa dos Floater Eyes —
## sprite 2D em silhueta completamente verde, aparição 35% (1–2 olhos, nunca em Guardiões),
## formação que impede duplas/trios de humanos ou Maziks, 3D no corredor da dungeon,
## atributos base (HP 8 / EN 24 / SP 54), 4 magias novas de buff (VERDANT MIGHT,
## VERDANT SHELL, KEEN GAZE, ETHER LINK) exclusivamente no aliado principal (nunca em
## Floater Eyes), duração de 1 rodada cheia, consumo de EN, fallback REST (D-038),
## absorção (+EN / buffs) e exclusão de oferta/defeated/CODEX.

const SANDBOX := preload("res://tests/progress_sandbox.gd")
const R := BattleMath.RhythmResult

var checks := 0
var failed := false


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, reason: String) -> void:
	if not ok:
		failed = true
		push_error("FAIL: " + reason)
		print("FAIL: ", reason)
	else:
		checks += 1


func _wait_mode(b: Control, wanted: String, limit: int = 240) -> bool:
	for _i in limit:
		if b.hud != null and b.hud.mode == wanted:
			return true
		if b.hud != null and b.hud.mode == "react" and wanted != "react":
			b.handle_back()
		if b.hud != null and b.hud.mode in ["continue", "announce"] and wanted not in ["continue", "announce"]:
			b.proceed()
		await process_frame
	return false


func _find_seed(id: String, wanted_count: int) -> int:
	for seed in range(1, 5000):
		if SurvivalData.floater_eye_count(seed, id) == wanted_count:
			return seed
	return -1


func _battle(encounter: String, run_seed: int, stratum: int = 1, fallen_agi: int = 30) -> Control:
	SurvivalState.reset()
	SurvivalState.patch({
		"seed": run_seed,
		"encounter_id": encounter,
		"stratum": stratum,
		"party": [SurvivalAllies.yoch_member("test_yoch")],
		"gains": {"max_hp": 0, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": fallen_agi},
	})
	var b: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	b.suppress_scene_change = true
	root.add_child(b)
	await _wait_mode(b, "plan")
	return b


func _run() -> void:
	SANDBOX.begin()
	ProgressStore.save_path_override = "user://test_floater_eyes_guard.json"
	ProgressStore.clear()

	_verify_sprite_and_data()
	_verify_spawn_rate_and_formations()
	await _verify_dungeon_world_3d()
	await _verify_human_example_battle()
	await _verify_mazik_example_battle()
	_verify_absorption_and_save()

	SurvivalState.clear()
	ProgressStore.clear()
	ProgressStore.save_path_override = ""
	print("FLOATER EYES CHECKS PASSED: %d FAILED: %d" % [checks, int(failed)])
	await process_frame
	quit(1 if failed else 0)


func _verify_sprite_and_data() -> void:
	# 1. Sprite 2D em silhueta completamente verde
	check(ResourceLoader.exists(SurvivalData.FLOATER_EYE_PICTURE),
			"Floater Eye sprite exists at %s" % SurvivalData.FLOATER_EYE_PICTURE)
	var tex: Texture2D = load(SurvivalData.FLOATER_EYE_PICTURE)
	check(tex != null, "Floater Eye sprite loads as Texture2D")
	if tex != null:
		var img := tex.get_image()
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		var opaque := 0
		var non_green := 0
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.05:
					opaque += 1
					if not (c.g > 0.6 and c.g > c.r * 2.0 and c.g > c.b * 1.4):
						non_green += 1
		check(opaque > 200, "Floater Eye sprite has substantial opaque silhouette (%d px)" % opaque)
		check(non_green == 0, "Floater Eye sprite is 100%% pure green silhouette (%d non-green px)" % non_green)

	# 2. Atributos numéricos D-129
	var def := SurvivalData.demon_by_id(SurvivalData.FLOATER_EYE_ID)
	check(not def.is_empty() and bool(def.get("floater_eye", false)), "demon_by_id resolves floater_eye")
	var st: Dictionary = def.stats
	check(int(st.max_hp) == 8 and int(st.max_en) == 24 and int(st.atk) == 2 and int(st.mak) == 4
			and int(st.defense) == 3 and int(st.mef) == 3 and int(st.agi) == 10,
			"Floater Eye base stats match D-129 (HP 8, EN 24, ATK 2, MAK 4, DEF 3, MEF 3, AGI 10)")
	var sp := int(st.max_hp) + int(st.max_en) + int(st.atk) + int(st.mak) + int(st.defense) + int(st.mef) + int(st.agi)
	check(sp == 54, "Floater Eye base SP is 54 (got %d)" % sp)
	check(not SurvivalData.is_elite(1, SurvivalData.FLOATER_EYE_ID, 5), "Floater Eye is never an elite")

	# 3. As 5 novas magias de buff com custos exatos D-129
	var expected_costs := {
		&"verdant_might": [1, 8],
		&"verdant_shell": [1, 8],
		&"keen_gaze": [1, 6],
		&"ether_link": [2, 10],
		&"aegis_iris": [1, 8],
	}
	for sk in expected_costs.keys():
		var sd := SkillBook.def(sk)
		check(not sd.is_empty(), "Skill %s exists in SkillBook" % sk)
		check(String(sd.kind) == "buff", "Skill %s is a buff" % sk)
		check(int(sd.acts) == int(expected_costs[sk][0]) and int(sd.en) == int(expected_costs[sk][1]),
				"Skill %s costs %d ACT / %d EN (got %d / %d)" % [sk, expected_costs[sk][0], expected_costs[sk][1], int(sd.acts), int(sd.en)])
		check(bool(SkillFx.fx_of(sk).get("ally_only", false)), "Skill %s is ally_only" % sk)
		check(SurvivalData.hebrew_skill(sk) != "???", "Skill %s has Hebrew unidentified name" % sk)


func _verify_spawn_rate_and_formations() -> void:
	# Estatística sobre 2000 pares (seed, id): ~35% de geração, ~50/50 entre 1 e 2 olhos.
	var total := 0
	var spawned := 0
	var one_eye := 0
	var two_eyes := 0
	var sample_ids: Array[String] = ["pixie", "jack_frost", "cerberus", "ganesha", "vritra", "mara", "leviathan", "izanami", "humans_s1", "humans_s3"]
	for seed in range(100, 300):
		for id in sample_ids:
			total += 1
			var c := SurvivalData.floater_eye_count(seed, id)
			check(c in [0, 1, 2], "floater_eye_count in 0..2 (got %d)" % c)
			if c > 0:
				spawned += 1
				if c == 1:
					one_eye += 1
				else:
					two_eyes += 1
	var rate := float(spawned) / float(total)
	var share_one := float(one_eye) / float(maxi(1, spawned))
	check(rate >= 0.31 and rate <= 0.39, "Spawn frequency ~35%% over %d rolls (got %.1f%%)" % [total, rate * 100.0])
	check(share_one >= 0.43 and share_one <= 0.57, "1 vs 2 eye split ~50/50 (1-eye=%.1f%%)" % (share_one * 100.0))

	# Guardiões nunca trazem Floater Eyes.
	for st in range(1, SurvivalStrata.COUNT + 1):
		var warden := SurvivalStrata.warden_of(st)
		for seed in range(1, 100):
			check(SurvivalData.floater_eye_count(seed, warden) == 0,
					"Warden %s never gets Floater Eyes (seed %d)" % [warden, seed])

	# Formação: presença de olhos IMPEDE duplas ou trios de humanos e Maziks.
	for st in range(1, SurvivalStrata.COUNT + 1):
		var hid := SurvivalData.human_group_id(st)
		check(SurvivalData.encounter_for(hid, [], -1, 0).size() == 3, "Without eyes, %s has 3 humans" % hid)
		for eyes in [1, 2]:
			var enc := SurvivalData.encounter_for(hid, [], -1, eyes)
			var humans := 0
			var floaters := 0
			for eid in enc:
				if SurvivalData.is_human_id(eid): humans += 1
				elif SurvivalData.is_floater_eye_id(eid): floaters += 1
			check(humans == 1 and floaters == eyes and enc.size() == 1 + eyes,
					"Human + %d eye(s) in stratum %d has EXACTLY 1 human + %d eye(s) (got %s)" % [eyes, st, eyes, str(enc)])

	# Maziks de tier 3, 4 e 5 (normalmente duplas ou trios) ficam sozinhos quando acompanhados por olhos.
	for mazik_id in ["ganesha", "vritra", "mara", "leviathan", "white_rider", "izanami"]:
		var normal := SurvivalData.encounter_for(mazik_id, [], -1, 0)
		check(normal.size() >= 2, "Normally %s forms a duo/trio (%s)" % [mazik_id, str(normal)])
		for eyes in [1, 2]:
			var enc := SurvivalData.encounter_for(mazik_id, [], -1, eyes)
			var maziks := 0
			var floaters := 0
			for eid in enc:
				if SurvivalData.is_floater_eye_id(eid): floaters += 1
				else: maziks += 1
			check(maziks == 1 and floaters == eyes and enc[0] == mazik_id and enc.size() == 1 + eyes,
					"Mazik %s + %d eye(s) has EXACTLY 1 Mazik + %d eye(s), never duo/trio (got %s)" % [mazik_id, eyes, eyes, str(enc)])


func _verify_dungeon_world_3d() -> void:
	# Encontra uma semente onde tanto humans_s1 quanto pelo menos um Mazik do estrato 1 têm Floater Eyes.
	var picked_seed := -1
	var picked_mazik := ""
	for seed in range(1, 500):
		if SurvivalData.floater_eye_count(seed, "humans_s1") <= 0:
			continue
		for id in SurvivalStrata.ids_for(1):
			if not SurvivalStrata.is_warden(id) and SurvivalData.floater_eye_count(seed, id) > 0:
				picked_seed = seed
				picked_mazik = id
				break
		if picked_seed >= 0:
			break
	check(picked_seed > 0, "Found stratum 1 seed with Floater Eyes on both human and Mazik (seed=%d, mazik=%s)" % [picked_seed, picked_mazik])

	SurvivalState.reset()
	SurvivalState.patch({"seed": picked_seed, "stratum": 1})
	var world: Control = load(SurvivalData.WORLD_SCENE).instantiate()
	world.battle_scene = ""
	root.add_child(world)
	await process_frame
	await process_frame

	var expected_human_eyes := SurvivalData.floater_eye_count(picked_seed, "humans_s1")
	var expected_mazik_eyes := SurvivalData.floater_eye_count(picked_seed, picked_mazik)
	check(world.floater_sprites.has("humans_s1") and (world.floater_sprites["humans_s1"] as Array).size() == expected_human_eyes,
			"Dungeon 3D spawns %d Floater Eye sprite(s) flying with humans_s1" % expected_human_eyes)
	check(world.floater_sprites.has(picked_mazik) and (world.floater_sprites[picked_mazik] as Array).size() == expected_mazik_eyes,
			"Dungeon 3D spawns %d Floater Eye sprite(s) flying with %s" % [expected_mazik_eyes, picked_mazik])
	check(not world.floater_sprites.has(SurvivalStrata.warden_of(1)), "Dungeon 3D spawns no Floater Eyes on Warden")

	# Confere posição flutuante e cor verde no corredor 3D
	var host_sprite: Sprite3D = world.enemy_sprites["humans_s1"]
	var eye_sprite: Sprite3D = (world.floater_sprites["humans_s1"] as Array)[0]
	check(eye_sprite.position.y > host_sprite.position.y, "Floater Eye hovers above host center in corridor")
	check(eye_sprite.modulate == world.FLOATER_EYE_INK, "Floater Eye 3D billboard uses pure green tint")

	# Iniciar batalha remove os sprites dos Floater Eyes junto com o inimigo
	for e in world.enemies.entries:
		if String(e.id) == "humans_s1":
			world._begin_battle(e)
			break
	check(not world.floater_sprites.has("humans_s1"), "Starting battle clears accompanying Floater Eye sprites")
	world.queue_free()
	await process_frame


func _verify_human_example_battle() -> void:
	var h_seed := _find_seed("humans_s1", 2)
	check(h_seed > 0, "Found real seed with 2 Floater Eyes on humans_s1 (seed=%d)" % h_seed)
	var b := await _battle("humans_s1", h_seed, 1, 30)
	var foes: Array = b.hud.opponents
	check(foes.size() == 3, "Human + 2 Floater Eyes battle has 3 foes (got %d)" % foes.size())
	var human: BattleUnit = foes[0]
	var eye_a: BattleUnit = foes[1]
	var eye_b: BattleUnit = foes[2]
	check(human.race == &"human" and human.display_name == "HUMAN A", "Slot 0 is single HUMAN A (got %s / %s)" % [human.display_name, human.race])
	check(eye_a.race == &"floater_eye" and eye_a.display_name == "FLOATER EYE A", "Slot 1 is FLOATER EYE A (got %s)" % eye_a.display_name)
	check(eye_b.race == &"floater_eye" and eye_b.display_name == "FLOATER EYE B", "Slot 2 is FLOATER EYE B (got %s)" % eye_b.display_name)
	check(eye_a.stats.max_hp == 8 and eye_a.stats.max_en == 24 and eye_a.current_en == 24,
			"Floater Eye A starts with HP 8 / EN 24")

	# Palco 3D da Necrópole Saturnina no Estrato 1, sem IntentLayer morto e sem nomes inimigos na faixa superior
	check(b.stage.material == null and b.stage.get_node_or_null("NecropoleViewport") != null,
			"Stratum 1 SurvivalBattle installs the Saturnine Necropolis 3D stage")
	check(b.get_node_or_null("IntentLayer") == null, "Unused IntentLayer node is removed")
	for entry in b.hud.turn_strip_entries():
		if not (entry.unit as BattleUnit).is_player:
			check(String(entry.text) == "FOE", "Turn strip hides enemy name (got %s)" % String(entry.text))

	# Intenção dos olhos mira o humano, nunca eles mesmos
	for eye in [eye_a, eye_b]:
		var it: Dictionary = b.intents.get(eye.id, {})
		check(String(it.get("kind", "")) == "buff", "%s intent is buff (got %s)" % [eye.display_name, it.get("kind")])
		check(it.get("target") == human, "%s intent targets HUMAN A" % eye.display_name)
		check(b.intent_text(eye).contains("Human A"), "%s intent text names HUMAN A (%s)" % [eye.display_name, b.intent_text(eye)])

	# Executa os 5 buffs e verifica alvo = HUMAN A, olhos NUNCA buffados, consumo exato de EN e efeito real
	b.turn_owner = eye_a
	var en0 := eye_a.current_en
	await b._enemy_skill(eye_a, &"verdant_might")
	check(eye_a.current_en == en0 - 8, "VERDANT MIGHT consumes 8 EN (%d -> %d)" % [en0, eye_a.current_en])
	check(human.atk_stages.size() == 1 and human.mak_stages.size() == 1, "VERDANT MIGHT gives HUMAN A +1 ATK & +1 MAK stage")
	check(eye_a.atk_stages.is_empty() and eye_b.atk_stages.is_empty() and eye_a.mak_stages.is_empty() and eye_b.mak_stages.is_empty(),
			"Floater Eyes NEVER receive VERDANT MIGHT")
	check(String(b.hud.events.back().text) == "Floater Eye A → Human A  ATK ↑  MAK ↑",
			"D-110 telegraphic log for VERDANT MIGHT (got %s)" % String(b.hud.events.back().text))

	var en1 := eye_a.current_en
	await b._enemy_skill(eye_a, &"verdant_shell")
	check(eye_a.current_en == en1 - 8, "VERDANT SHELL consumes 8 EN (%d -> %d)" % [en1, eye_a.current_en])
	check(human.def_round_stages.size() == 1 and human.mef_stages.size() == 1, "VERDANT SHELL gives HUMAN A +1 DEF & +1 MEF stage")
	check(human.effective_def() > human.stats.defense and human.effective_mef() > human.stats.mef,
			"VERDANT SHELL raises HUMAN A effective DEF/MEF (%d>%d, %d>%d)" % [human.effective_def(), human.stats.defense, human.effective_mef(), human.stats.mef])
	check(eye_a.def_round_stages.is_empty() and eye_b.def_round_stages.is_empty(), "Floater Eyes NEVER receive VERDANT SHELL")
	check(String(b.hud.events.back().text) == "Floater Eye A → Human A  DEF ↑  MEF ↑",
			"D-110 telegraphic log for VERDANT SHELL (got %s)" % String(b.hud.events.back().text))

	var agi_before := human.stats.agi
	var sp_base_before := human.sp_base()
	var en2 := eye_a.current_en
	await b._enemy_skill(eye_a, &"keen_gaze")
	check(eye_a.current_en == en2 - 6, "KEEN GAZE consumes 6 EN (%d -> %d)" % [en2, eye_a.current_en])
	check(human.stats.agi == agi_before and human.sp_base() == sp_base_before,
			"KEEN GAZE does NOT mutate base stats.agi or sp_base() (stats.agi=%d, sp_base=%d)" % [human.stats.agi, human.sp_base()])
	check(human.effective_agi() == agi_before + 4 and human.next_attack_high_speed,
			"KEEN GAZE raises effective_agi() by +4 (%d -> %d) and grants HIGH SPEED" % [agi_before, human.effective_agi()])
	check(eye_a.agi_buffs.is_empty() and eye_b.agi_buffs.is_empty() and not eye_a.next_attack_high_speed,
			"Floater Eyes NEVER receive KEEN GAZE")
	check(String(b.hud.events.back().text) == "Floater Eye A → Human A  +4 AGI  HIGH SPEED",
			"D-110 telegraphic log for KEEN GAZE (got %s)" % String(b.hud.events.back().text))

	var sp_before := human.current_sp
	var en_b0 := eye_b.current_en
	b.turn_owner = eye_b
	await b._enemy_skill(eye_b, &"ether_link")
	check(eye_b.current_en == en_b0 - 10, "ETHER LINK consumes 10 EN (%d -> %d)" % [en_b0, eye_b.current_en])
	check(human.current_sp == sp_before + 6 and human.sp_buffs.size() == 1, "ETHER LINK grants HUMAN A +6 temporary SP")
	check(eye_a.sp_buffs.is_empty() and eye_b.sp_buffs.is_empty(), "Floater Eyes NEVER receive ETHER LINK")
	check(String(b.hud.events.back().text) == "Floater Eye B → Human A  +6 SP",
			"D-110 telegraphic log for ETHER LINK (got %s)" % String(b.hud.events.back().text))

	# 5º buff: AEGIS IRIS (1 ACT / 8 EN, escudo de status não-reza por 1 rodada cheia)
	var en_b1 := eye_b.current_en
	await b._enemy_skill(eye_b, &"aegis_iris")
	check(eye_b.current_en == en_b1 - 8, "AEGIS IRIS consumes 8 EN (%d -> %d)" % [en_b1, eye_b.current_en])
	check(not human.haganah.is_empty() and bool(human.haganah.get("non_prayer", false)),
			"AEGIS IRIS grants HUMAN A non-prayer status shield (haganah)")
	check(eye_a.haganah.is_empty() and eye_b.haganah.is_empty(), "Floater Eyes NEVER receive AEGIS IRIS")
	check(String(b.hud.events.back().text) == "Floater Eye B → Human A  STATUS SHIELD",
			"D-110 telegraphic log for AEGIS IRIS (got %s)" % String(b.hud.events.back().text))
	# Prova que o escudo bloqueia status (WEAKEN / BLEED)
	human.current_hp = 999
	human.stats.max_hp = 999
	b._skill_hit_fx(b._fallen, human, &"venom_cloud", 0, false, R.POINT, R.MISS, true)
	b._skill_hit_fx(b._fallen, human, &"fang_sting", 0, false, R.POINT, R.MISS, false)
	check(not human.has_status(&"weaken") and human.bleeds.is_empty(),
			"AEGIS IRIS blocks WEAKEN and BLEED status conditions")

	# Verifica que MAK buffado aumenta de fato o dano de CHEREV do humano
	var unbuffed_mak := human.stats.mak
	check(int(round(human.effective_mak())) > unbuffed_mak, "HUMAN A effective MAK raised for CHEREV (%d -> %d)" % [unbuffed_mak, int(round(human.effective_mak()))])

	# Verifica expiração após 1 rodada cheia
	b.state.round_number += 1
	b._expire_stages(eye_a)
	check(human.atk_stages.is_empty() and human.mak_stages.is_empty() and human.def_round_stages.is_empty()
			and human.mef_stages.is_empty() and human.effective_agi() == agi_before and human.stats.agi == agi_before,
			"All eye_a buffs expire after 1 full round (ATK/MAK/DEF/MEF/AGI restored)")
	b._expire_stages(eye_b)
	check(human.sp_buffs.is_empty() and human.current_sp == sp_before and human.haganah.is_empty(),
			"ETHER LINK +6 SP and AEGIS IRIS expire after 1 full round (SP restored to %d)" % sp_before)

	b.queue_free()
	await process_frame


func _verify_mazik_example_battle() -> void:
	# Tier-5 Mazik (normalmente trio!) acompanhado por 2 Floater Eyes -> 1 Mazik + 2 olhos
	var m_seed := _find_seed("izanami", 2)
	check(m_seed > 0, "Found real seed with 2 Floater Eyes on tier-5 Mazik izanami (seed=%d)" % m_seed)
	var b := await _battle("izanami", m_seed, 5, 40)
	var foes: Array = b.hud.opponents
	check(foes.size() == 3, "Tier-5 Mazik + 2 Floater Eyes has 3 foes (got %d)" % foes.size())
	var mazik: BattleUnit = foes[0]
	var eye_a: BattleUnit = foes[1]
	var eye_b: BattleUnit = foes[2]
	check(String(mazik.kind) == "izanami" and mazik.race != &"floater_eye", "Slot 0 is single Mazik IZANAMI")
	check(eye_a.race == &"floater_eye" and eye_b.race == &"floater_eye", "Slots 1 & 2 are Floater Eyes (no duo/trio of Maziks)")
	check(not b._enemy_counter_roll(eye_a), "Floater Eyes never counter-attack")

	# Buffa o Mazik e drena EN até ficar abaixo do custo mínimo (6 EN) -> fallback REST (D-038: +2 EN)
	eye_a.current_en = 4
	eye_a.acts_available = 2
	check(b.temperament_pick(eye_a, 2) == &"rest", "Floater Eye with 4 EN (< 6) chooses REST")
	b._execute_rest(eye_a, false)
	check(eye_a.current_en == 6 and eye_a.acts_available == 0 and eye_a.stored_acts == 2,
			"Floater Eye REST recovers +2 EN flat (4 -> 6) and stores 2 acts")

	# Quando o Mazik principal morre, Floater Eyes NUNCA buffam a si mesmos e FOGEM automaticamente
	mazik.current_hp = 0
	eye_b.current_en = 24
	eye_b.acts_available = 2
	check(b._buff_ally_target(eye_b) == null, "No valid buff target when accompanied Mazik is down")
	check(b.temperament_pick(eye_b, 2) == &"flee", "Orphan Floater Eye chooses FLEE when main ally is down")
	check(b._enemy_choice(eye_b, 2) == &"flee", "Orphan Floater Eye overrides pending buff intent with FLEE")
	b._self_skill(eye_b, &"verdant_might", 0, false)
	check(eye_a.atk_stages.is_empty() and eye_b.atk_stages.is_empty(),
			"Even forced cast never buffs a Floater Eye")
	check(String(b.hud.events.back().text) == "Floater Eye B  NO ALLY",
			"D-110 telegraphic log when no valid buff ally exists (got %s)" % String(b.hud.events.back().text))
	b._execute_flee(eye_a)
	check(String(b.hud.events.back().text) == "Floater Eye A  FLEE",
			"D-110 telegraphic log for orphan Floater Eye flee (got %s)" % String(b.hud.events.back().text))
	b._execute_flee(eye_b)
	check(eye_a.fled and eye_b.fled and not eye_a.is_alive() and not eye_b.is_alive(),
			"Orphan Floater Eyes mark fled=true and leave combat")
	check(b.state.is_over() and b.state.player_victory(),
			"Battle ends in victory once all orphan Floater Eyes have fled")
	var flee_macca_before := int(SurvivalState.data().macca)
	b._show_result()
	var iz_macca := int(SurvivalData.demon_by_id("izanami").macca)
	if SurvivalData.is_elite(m_seed, "izanami", 0):
		iz_macca *= 2
	check(int(SurvivalState.data().macca) == flee_macca_before + iz_macca,
			"Fled Floater Eyes yield 0 Macca (earned %d, expected %d for host only)" % [int(SurvivalState.data().macca) - flee_macca_before, iz_macca])

	# Baixa durabilidade: Fallen no Estrato 1 derruba Floater Eye em 1 golpe normal
	b.queue_free()
	await process_frame
	var s1_seed := _find_seed("jack_frost", 1)
	var b1 := await _battle("jack_frost", s1_seed, 1, 0)
	var jf_eye: BattleUnit = b1.hud.opponents[1]
	check(jf_eye.race == &"floater_eye" and jf_eye.current_hp == 8, "Stratum 1 Floater Eye has 8 HP")
	b1._apply_strike(b1._fallen, jf_eye, b1.basic_power, false, R.POINT, R.MISS, false)
	check(not jf_eye.is_alive(), "Fallen base kills Stratum 1 Floater Eye in 1 normal hit (HP=%d)" % jf_eye.current_hp)

	# Vitória: Floater Eye nunca entra em offer_pool nem em defeated, mas dá Macca
	b1.hud.opponents[0].current_hp = 0
	var pool: Array = b1.offer_pool()
	for u in pool:
		check((u as BattleUnit).race != &"floater_eye", "Floater Eye never appears in recruitment offer_pool")
	var macca_before := int(SurvivalState.data().macca)
	b1._show_result()
	var defeated: Array = SurvivalState.data().defeated
	check(defeated.has("jack_frost") and not defeated.has(SurvivalData.FLOATER_EYE_ID),
			"Victory records jack_frost in defeated, never floater_eye")
	check(int(SurvivalState.data().macca) >= macca_before + 25 + SurvivalData.FLOATER_EYE_MACCA,
			"Victory awards Macca for host + Floater Eye")
	check(SurvivalState._valid_state(SurvivalState.data()), "Save state remains valid after Floater Eye battle")

	b1.queue_free()
	await process_frame


func _verify_absorption_and_save() -> void:
	var fdef := SurvivalData.floater_eye_def()
	var sig := SurvivalAbsorb.signature_stats(fdef)
	check(sig[0] == &"max_en", "Absorbing Floater Eye inherits max_en as top signature stat (got %s)" % sig[0])
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var saw_en := false
	var saw_buff_skill := false
	for _i in 40:
		var opts := SurvivalAbsorb.roll_options(rng, fdef, [], 1.0, {"stratum": 1, "skill_bonus": 0.5, "count": 3})
		for opt in opts:
			if String(opt.get("kind", "")) == "stat" and StringName(opt.get("stat", &"")) == &"max_en":
				saw_en = true
			if String(opt.get("kind", "")) == "skill" and SurvivalData.FLOATER_EYE_SKILLS.has(StringName(opt.get("skill", &""))):
				saw_buff_skill = true
	check(saw_en, "Absorbing Floater Eye offers +EN reward")
	check(saw_buff_skill, "Absorbing Floater Eye can teach its new buff spells")
