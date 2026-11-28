extends SceneTree
## D-139 (criador 2026-11-27/28), Fase 2: catálogo canônico (Twin Fang, Blade Dance, Rock Body, Stone Body [ZAHAV]),
## remoção global de Frost Lance, migração `stone_grasp -> rock_body` + descarte de `frost_lance` em saves,
## kits de PAZUZU e BARONG no Survival, e ícone adaptativo de STURDY no HUD (`StatusIcons`).
const SANDBOX := preload("res://tests/progress_sandbox.gd")

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


func _run() -> void:
	# 1. Catálogo canônico D-139 (taxonomia oficial, grotesque, ZERO affinity D-119)
	var specs := {
		&"twin_fang":   {"cat": "PHYS", "dmg_type": "PHYS", "targets": "1T",          "acts": 2, "en": 5,  "power": 5},
		&"blade_dance": {"cat": "PHYS", "dmg_type": "PHYS", "targets": "interleaved", "acts": 1, "en": 0,  "power": 15},
		&"rock_body":   {"cat": "STAT", "dmg_type": "",     "targets": "SELF",        "acts": 1, "en": 10, "power": 0},
		&"stone_body":  {"cat": "STAT", "dmg_type": "",     "targets": "SELF",        "acts": 1, "en": 25, "power": 0},
	}
	for id in specs:
		var d := SkillBook.def(id)
		var ex: Dictionary = specs[id]
		check(not d.is_empty(), "%s exists in SkillBook.DEFS" % id)
		check(bool(d.get("grotesque", false)), "%s has grotesque=true" % id)
		check(not d.has("affinity"), "%s has NO affinity field (D-119/D-138)" % id)
		check(String(d.get("cat", "")) == ex.cat and String(d.get("dmg_type", "")) == ex.dmg_type
			and String(d.get("targets", "")) == ex.targets, "%s taxonomy matches D-131/D-139" % id)
		check(int(d.get("acts", 0)) == ex.acts and int(d.get("en", 0)) == ex.en and int(d.get("power", 0)) == ex.power,
			"%s cost/power matches spec" % id)

	# Detalhes específicos de Blade Dance, Rock Body e Stone Body [ZAHAV]
	var bd := SkillBook.def(&"blade_dance")
	check(bool(bd.get("all_acts", false)) and int(bd.get("extra_hit", 0)) == 1
		and bool(bd.get("no_counter", false)) and int(bd.get("cooldown_rounds", 0)) == 2,
		"BLADE DANCE metadata: all_acts, extra_hit=1, no_counter, cooldown_rounds=2")
	var rb := SkillBook.def(&"rock_body")
	var sb := SkillBook.def(&"stone_body")
	check(SkillBook.is_immediate(&"rock_body") and SkillBook.is_immediate(&"stone_body"), "ROCK BODY and STONE BODY are IMEDIATO")
	check(rb.get("zahav_to", &"") == &"stone_body" and bool(sb.get("zahav", false)) and sb.get("zahav_of", &"") == &"rock_body",
		"ROCK BODY <-> STONE BODY ZAHAV link intact")

	# 2. Remoção global de FROST LANCE e substituição de STONE GRASP
	check(SkillBook.def(&"frost_lance").is_empty(), "FROST LANCE removed from SkillBook.DEFS")
	check(SkillBook.def(&"stone_grasp").is_empty(), "STONE GRASP replaced in SkillBook.DEFS")
	check(not SurvivalData.SURVIVAL_SKILLS.has(&"frost_lance"), "FROST LANCE removed from SurvivalData.SURVIVAL_SKILLS")
	check(not SurvivalData.HEBREW_SKILLS.has(&"frost_lance"), "FROST LANCE removed from SurvivalData.HEBREW_SKILLS")
	check(not SurvivalData.SURVIVAL_SKILLS.has(&"stone_grasp") and SurvivalData.SURVIVAL_SKILLS.has(&"rock_body"),
		"STONE GRASP replaced by ROCK BODY in SurvivalData.SURVIVAL_SKILLS")

	# Migração de saves antigos
	check(SkillBook.migrate_id(&"stone_grasp") == &"rock_body", "migrate_id(stone_grasp) -> rock_body")
	check(SkillBook.migrate_id(&"frost_lance") == &"", "migrate_id(frost_lance) -> empty (removed)")
	var migrated := SkillBook.migrate_ids(["twin_fang", "frost_lance", "stone_grasp", "rock_body"])
	check(migrated == ["twin_fang", "rock_body"], "migrate_ids drops frost_lance and deduplicates stone_grasp->rock_body (got %s)" % str(migrated))

	# 3. Kits de PAZUZU e BARONG no Survival
	var pazuzu := SurvivalData.demon_by_id("pazuzu")
	var barong := SurvivalData.demon_by_id("barong")
	check(pazuzu.skills == [&"ember_touch", &"ignoma", &"twin_fang", &"rock_body"],
		"PAZUZU kit updated cleanly without frost_lance (got %s)" % str(pazuzu.skills))
	check(barong.skills == [&"rock_body", &"war_cry"],
		"BARONG kit migrated from stone_grasp to rock_body (got %s)" % str(barong.skills))
	for entry in SurvivalData.DEMONS:
		check(not (entry.skills as Array).has(&"frost_lance") and not (entry.skills as Array).has(&"stone_grasp"),
			"Demon %s carries neither frost_lance nor stone_grasp" % entry.id)

	# 4. Ícone adaptativo de STURDY no HUD (StatusIcons)
	var u := BattleUnit.new(&"test", "Fallen", UnitStats.new(), true, true)
	u.apply_sturdy(0, 1, false)
	var icons_rock := StatusIcons.of(u)
	check(icons_rock.size() == 1 and icons_rock[0].id == "sturdy" and icons_rock[0].full == "STURDY" and icons_rock[0].kind == StatusIcons.Kind.BUFF,
		"StatusIcons renders STURDY (Rock Body) as BUFF")
	u.apply_sturdy(15, 1, true)
	var icons_stone := StatusIcons.of(u)
	check(icons_stone.size() == 1 and icons_stone[0].id == "sturdy" and StatusIcons.text_for(icons_stone[0], StatusIcons.Density.FULL) == "STURDY+15",
		"StatusIcons renders STURDY+15 (Stone Body ZAHAV) as BUFF")

	print("VERIFY_D139_SKILLS_OK: %d checks; 4 D-139 skills catalogued, frost_lance removed globally + migrated out of saves, stone_grasp->rock_body migrated, PAZUZU/BARONG updated, STURDY HUD icon ready" % checks)
	quit(0)
