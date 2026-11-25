extends SceneTree
## D-101 (criador 2026-11-25: "SP parecido"): o Fallen nao pode ser "mil vezes mais forte". O dano soma um
## sorteio de ate a diferenca de SP; a ficha antiga (SP 205 contra 59..139) matava em menos de 1 golpe e
## ignorava 65 a 72% dos golpes. Aqui: ficha inicial, follow_hero e uma run simulada de 5 estratos.

const RUNS := 40
const SAMPLES := 120
const POWER := 10  # basic_power do survival (SURVIVAL_MODE.md)

var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, reason: String) -> void:
	if not ok:
		push_error("FAIL: " + reason)
		quit(1)
		assert(ok, reason)
	checks += 1


func _sheet(base: Dictionary) -> UnitStats:
	var s := UnitStats.new()
	for k in ["max_hp", "max_en", "atk", "mak", "defense", "mef", "agi"]:
		s.set(k, int(base[k]))
	return s


func _points(opt: Dictionary) -> int:
	match String(opt.get("kind", "")):
		"stat": return int(opt.amount)
		"stat2": return 6
	return 0


func _apply(stats: UnitStats, opt: Dictionary) -> void:
	match String(opt.get("kind", "")):
		"stat": SurvivalAbsorb._add(stats, StringName(opt.stat), int(opt.amount))
		"stat2":
			for s in opt.stats:
				SurvivalAbsorb._add(stats, StringName(s), 3)


func _run() -> void:
	# --- ficha inicial: SP do Fallen parecido com o dos inimigos do estrato 1 (media 72)
	var hero := _sheet(SurvivalData.FALLEN_BASE)
	var par1 := SurvivalStrata.par_sp(1)
	check(absi(hero.sp_value() - par1) <= 3, "Fallen starts with the SP of stratum 1 (%d vs %d)" % [hero.sp_value(), par1])
	var yoch := _sheet(SurvivalData.YOCH_BASE)
	check(yoch.sp_value() < hero.sp_value() and yoch.max_en == 0, "Yoch is weaker than Fallen and has no EN (%d)" % yoch.sp_value())
	# o SP esperado sobe a cada estrato, como o dos inimigos
	for s in range(2, 6):
		check(SurvivalStrata.par_sp(s) > SurvivalStrata.par_sp(s - 1), "Expected SP rises at stratum %d" % s)

	# --- follow_hero
	var base := UnitStats.new()
	for k in SurvivalData.demon_by_id("pixie").stats:
		base.set(k, int(SurvivalData.demon_by_id("pixie").stats[k]))
	var own := base.sp_value()
	var same := base.duplicate_stats()
	SurvivalData.follow_hero(same, 100, 100)
	check(same.sp_value() == own and same.max_hp == base.max_hp, "Hero at the expected SP: the enemy does not change")
	var up := base.duplicate_stats()
	SurvivalData.follow_hero(up, 100 + 30, 100)
	check(up.sp_value() == own + 30, "Hero 30 SP above par: the enemy gains exactly 30 SP (%d -> %d)" % [own, up.sp_value()])
	check(up.atk >= base.atk and up.defense >= base.defense and up.max_hp > base.max_hp, "Extra SP is spread over the stats the enemy already has")
	var down := base.duplicate_stats()
	SurvivalData.follow_hero(down, 100 - 500, 100)
	check(down.sp_value() == own / 2, "An enemy never falls below half of its own SP (%d)" % down.sp_value())
	var noen := base.duplicate_stats()
	noen.max_en = 0
	SurvivalData.follow_hero(noen, 150, 100)
	check(noen.max_en == 0, "An enemy without EN keeps 0 EN")
	for v in [noen.max_hp, noen.atk, noen.mak, noen.defense, noen.mef, noen.agi]:
		check(int(v) >= 1, "Every stat stays at 1 or more")

	# --- run simulada: absorve depois de cada batalha; inimigos ja ajustados
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261125
	var ranked := SurvivalStrata.ranked_ids()
	for mode in ["greedy", "random"]:
		var acc := {}
		for r in RUNS:
			var h := _sheet(SurvivalData.FALLEN_BASE)
			for stratum in range(1, 6):
				var par := SurvivalStrata.par_sp(stratum)
				for i in 7:
					var def := SurvivalData.demon_by_id(ranked[(stratum - 1) * 7 + i])
					var es := _sheet(def.stats)
					SurvivalData.follow_hero(es, h.sp_value(), par)
					var dealt := 0.0
					var taken := 0.0
					var zero := 0
					for n in SAMPLES:
						var a := BattleMath.physical_damage(POWER, float(h.atk), h.agi, es.defense, h.sp_value(), es.sp_value(), BattleMath.Affinity.NORMAL, rng)
						dealt += float(a.amount)
						var b := BattleMath.physical_damage(POWER, float(es.atk), es.agi, h.defense, es.sp_value(), h.sp_value(), BattleMath.Affinity.NORMAL, rng)
						taken += float(b.amount)
						if int(b.amount) == 0: zero += 1
					dealt /= SAMPLES
					taken /= SAMPLES
					if not acc.has(stratum): acc[stratum] = {"kill": 0.0, "die": 0.0, "zero": 0.0, "dsp": 0.0, "adsp": 0.0, "n": 0}
					acc[stratum].kill += float(es.max_hp) / maxf(dealt, 0.1)
					acc[stratum].die += float(h.max_hp) / maxf(taken, 0.1)
					acc[stratum].zero += float(zero) / SAMPLES
					acc[stratum].dsp += float(h.sp_value() - es.sp_value())
					acc[stratum].adsp += absf(float(h.sp_value() - es.sp_value()))
					acc[stratum].n += 1
					var offers := SurvivalAbsorb.roll_options(rng, def, [] as Array[StringName], 1.0, {"stratum": stratum, "yoch": false})
					var pick: Dictionary = {}
					var best := -1
					for o in offers:
						var p := _points(o)
						if mode == "greedy":
							if p > best:
								best = p
								pick = o
						elif p > 0 and pick.is_empty():
							pick = o
					if not pick.is_empty(): _apply(h, pick)
		for stratum in range(1, 6):
			var a: Dictionary = acc[stratum]
			var kill: float = a.kill / a.n
			var die: float = a.die / a.n
			var zero_share: float = a.zero / a.n
			var gap: float = a.dsp / a.n
			var spread: float = a.adsp / a.n
			print("%s E%d: golpes para matar %.1f | golpes que aguenta %.1f | golpes 0 dano %d%% | dSP medio %+.1f (|dSP| %.1f)" % [mode, stratum, kill, die, int(zero_share * 100.0), gap, spread])
			check(absf(gap) <= 3.0, "%s stratum %d: on average enemy SP equals the hero's (%+.1f)" % [mode, stratum, gap])
			check(spread <= 12.0, "%s stratum %d: no enemy strays far from the hero (|dSP| %.1f)" % [mode, stratum, spread])
			check(kill >= 1.5, "%s stratum %d: the hero does not one-shot (%.1f hits)" % [mode, stratum, kill])
			check(die >= 1.5, "%s stratum %d: the hero is not one-shot (%.1f hits)" % [mode, stratum, die])
			check(zero_share <= 0.25, "%s stratum %d: the hero is not immune (%d%% of blows deal 0)" % [mode, stratum, int(zero_share * 100.0)])

	print("verify_survival_balance: %d checks OK" % checks)
	await process_frame
	quit(0)
