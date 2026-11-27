extends SceneTree
## Mede a chance de 0 de dano do Fallen (golpe basico, power 10, FULL) contra cada inimigo do survival.

func _initialize() -> void:
	call_deferred("_run")

func _sheet(base: Dictionary) -> UnitStats:
	var s := UnitStats.new()
	for k in ["max_hp", "max_en", "atk", "mak", "defense", "mef", "agi"]:
		s.set(k, int(base[k]))
	return s

func _run() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for stratum in range(1, 6):
		var par := SurvivalStrata.par_sp(stratum)
		var hero := _sheet(SurvivalData.FALLEN_BASE)
		SurvivalData.follow_hero(hero, par, hero.sp_value())  # leva o heroi ao SP esperado do estrato
		print("== estrato %d  heroi SP %d ATK %d DEF %d" % [stratum, hero.sp_value(), hero.atk, hero.defense])
		for id in SurvivalStrata.ids_for(stratum):
			var e := _sheet(SurvivalData.demon_by_id(id).stats)
			SurvivalData.follow_hero(e, hero.sp_value(), par)
			SurvivalData.empower(e, id, 1, 0)
			var zero_h := 0; var sum_h := 0.0; var zero_e := 0; var sum_e := 0.0
			var n := 4000
			for i in n:
				var a := int(BattleMath.physical_damage(10, hero.atk, hero.agi, e.defense, hero.sp_value(), e.sp_value(), rng).amount)
				if a == 0: zero_h += 1
				sum_h += a
				var b := int(BattleMath.physical_damage(10, e.atk, e.agi, hero.defense, e.sp_value(), hero.sp_value(), rng).amount)
				if b == 0: zero_e += 1
				sum_e += b
			print("  %-12s SP %3d ATK %2d DEF %2d HP %3d | Fallen->: media %5.1f, ZERO %3d%% | ->Fallen: media %5.1f, ZERO %3d%%" % [id, e.sp_value(), e.atk, e.defense, e.max_hp, sum_h / n, 100 * zero_h / n, sum_e / n, 100 * zero_e / n])
	quit(0)
