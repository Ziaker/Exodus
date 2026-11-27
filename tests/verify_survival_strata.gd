extends SceneTree
## D-066..D-076: verificação headless (lógica pura) do roguelike do Survival:
## estratos, guardiões, labirintos gerados, temperamentos, raridade/herança da
## absorção, relíquias com efeito e pactos, loja, cura paga, OMEN, meta e save v2.

var checks := 0
var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, description: String) -> void:
	if not ok:
		failed = true
		push_error("FAIL: " + description)
		print("FAIL: ", description)
	else:
		checks += 1


func _run() -> void:
	var meta_backup := ""
	if FileAccess.file_exists(SurvivalMeta.SAVE_PATH):
		meta_backup = FileAccess.get_file_as_string(SurvivalMeta.SAVE_PATH)
	_strata()
	_mazes()
	_temperaments()
	_absorb()
	_relics()
	_economy()
	_meta()
	_save()
	# Restaura o meta do jogador (os testes escrevem nele).
	if meta_backup.is_empty():
		if FileAccess.file_exists(SurvivalMeta.SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SurvivalMeta.SAVE_PATH))
	else:
		var f := FileAccess.open(SurvivalMeta.SAVE_PATH, FileAccess.WRITE)
		f.store_string(meta_backup)
		f.close()
	SurvivalState.clear()
	print("SURVIVAL STRATA CHECKS PASSED: %d FAILED: %d" % [checks, int(failed)])
	quit(1 if failed else 0)


func _strata() -> void:
	var all := {}
	var last_power := -1
	for s in range(1, SurvivalStrata.COUNT + 1):
		var ids := SurvivalStrata.ids_for(s)
		_check(ids.size() == 7, "Stratum %d has 7 demons" % s)
		for id in ids:
			_check(not all.has(id), "%s appears in one stratum only" % id)
			all[id] = s
			_check(SurvivalStrata.stratum_of(id) == s, "stratum_of(%s) == %d" % [id, s])
		var warden := SurvivalStrata.warden_of(s)
		_check(ids.has(warden) and SurvivalStrata.is_warden(warden), "Stratum %d warden %s" % [s, warden])
		var wd := SurvivalData.demon_by_id(warden)
		for id in ids:
			var d := SurvivalData.demon_by_id(id)
			_check(int(d.tier) < int(wd.tier) or (int(d.tier) == int(wd.tier) and SurvivalStrata.power(d) <= SurvivalStrata.power(wd)),
					"Warden %s is the strongest of stratum %d (vs %s)" % [warden, s, id])
		var min_tier := 99
		for id in ids:
			min_tier = mini(min_tier, int(SurvivalData.demon_by_id(id).tier))
		_check(min_tier >= last_power, "Stratum %d tiers never go down (%d >= %d)" % [s, min_tier, last_power])
		last_power = min_tier
	_check(all.size() == SurvivalData.DEMONS.size(), "All 35 demons are distributed (got %d)" % all.size())
	# Encontros: escoltas do mesmo estrato, guardião com 2 escoltas, derrotados fora.
	for demon in SurvivalData.DEMONS:
		var id := String(demon.id)
		var enc := SurvivalData.encounter_for(id)
		_check(enc[0] == id, "%s leads its encounter" % id)
		for other in enc:
			_check(SurvivalStrata.stratum_of(other) == SurvivalStrata.stratum_of(id), "%s escort %s is from the same stratum" % [id, other])
		if SurvivalStrata.is_warden(id):
			_check(enc.size() == 3, "Warden %s fights with 2 escorts" % id)
	var w2 := SurvivalStrata.warden_of(2)
	var mates := SurvivalStrata.ids_for(2)
	var gone: Array = []
	for m in mates:
		if m != w2:
			gone.append(m)
	_check(SurvivalData.encounter_for(w2, gone) == [w2], "Warden alone when every escort is defeated")
	_check(not SurvivalData.encounter_for(w2, [mates[0]]).has(mates[0]), "Defeated demon never escorts")


func _bfs_ok(rows: Array) -> bool:
	var dist := SurvivalStrata.distances(rows)
	for y in rows.size():
		for x in String(rows[y]).length():
			if String(rows[y])[x] != "#" and not dist.has(Vector2i(x, y)):
				return false
	return true


func _mazes() -> void:
	var different := 0
	var prev := ""
	for seed in 200:
		for s in [2, 3, 4, 5]:
			var rows := SurvivalStrata.maze(seed * 7919 + 3, s)
			if rows.size() != 21 or String(rows[0]).length() != 25:
				_check(false, "Generated maze is 25x21 (seed %d stratum %d)" % [seed, s])
				continue
			var border := true
			for x in 25:
				border = border and String(rows[0])[x] == "#" and String(rows[20])[x] == "#"
			for y in 21:
				border = border and String(rows[y])[0] == "#" and String(rows[y])[24] == "#"
			_check(border, "Maze border is closed (seed %d s%d)" % [seed, s])
			_check(_bfs_ok(rows), "Maze fully connected (seed %d s%d)" % [seed, s])
			_check(String(rows[10])[12] == "S", "Start S at (12,10) (seed %d s%d)" % [seed, s])
			var safe := true
			for y in range(9, 12):
				for x in range(10, 15):
					safe = safe and String(rows[y])[x] != "#"
			_check(safe, "Sanctuary 5x3 open (seed %d s%d)" % [seed, s])
			var lay := SurvivalStrata.layout(seed * 7919 + 3, s)
			var used := {}
			var dist := SurvivalStrata.distances(rows)
			for id in lay.demons.keys():
				var c: Vector2i = lay.demons[id]
				_check(SurvivalStrata.is_floor(rows, c) and not SurvivalData.SAFE_ZONE.has_point(c)
						and absi(c.x - 12) + absi(c.y - 10) >= SurvivalStrata.MIN_START_DISTANCE and not used.has(c),
						"Demon %s cell valid and unique (seed %d s%d)" % [id, seed, s])
				used[c] = true
			var deepest := 0
			for c in dist.keys():
				var cc: Vector2i = c
				if not SurvivalData.SAFE_ZONE.has_point(cc) and absi(cc.x - 12) + absi(cc.y - 10) >= SurvivalStrata.MIN_START_DISTANCE:
					deepest = maxi(deepest, int(dist[cc]))
			_check(int(dist[lay.demons[lay.warden]]) == deepest, "Warden waits at the deepest cell (seed %d s%d)" % [seed, s])
			_check(lay.events.size() == 3, "3 events (seed %d s%d)" % [seed, s])
			for ev in lay.events:
				_check(not used.has(ev.cell) and SurvivalStrata.is_floor(rows, ev.cell), "Event cell free (seed %d s%d)" % [seed, s])
				used[ev.cell] = true
			var joined := "".join(rows)
			if joined != prev:
				different += 1
			prev = joined
	_check(different > 700, "Generated mazes vary with seed/stratum (%d distinct of 800)" % different)
	var first := SurvivalStrata.maze(1, 1)
	var entrance := SurvivalStrata.entrance(1)
	_check(first[entrance.y][entrance.x] == "S" and first == SurvivalStrata.maze(42, 1),
		"Stratum 1 keeps the authored Necropolis across seeds")
	_check(SurvivalStrata.maze(42, 3) == SurvivalStrata.maze(42, 3), "Maze is deterministic per seed")
	_check(str(SurvivalStrata.layout(42, 1)) == str(SurvivalStrata.layout(42, 1)), "Layout is deterministic per seed")


func _temperaments() -> void:
	var counts := {}
	for demon in SurvivalData.DEMONS:
		var t := SurvivalStrata.temperament(String(demon.id))
		counts[t] = int(counts.get(t, 0)) + 1
		_check(SurvivalStrata.TEMPERAMENT_LABELS.has(t), "%s has a known temperament" % demon.id)
	for t in SurvivalStrata.TEMPERAMENT_LABELS.keys():
		_check(int(counts.get(t, 0)) >= 4, "Temperament %s used by >= 4 demons (%d)" % [t, int(counts.get(t, 0))])
	for s in range(1, 6):
		var kinds := {}
		for id in SurvivalStrata.ids_for(s):
			kinds[SurvivalStrata.temperament(id)] = true
		_check(kinds.size() >= 3, "Stratum %d mixes >= 3 temperaments (%d)" % [s, kinds.size()])
	# Elites com efeito real (D-070).
	var seen_affix := {}
	for seed in 400:
		for demon in SurvivalData.DEMONS:
			var id := String(demon.id)
			if not SurvivalData.is_elite(seed, id):
				continue
			var st := UnitStats.new()
			var ds: Dictionary = demon.stats
			st.max_hp = int(ds.max_hp); st.atk = int(ds.atk); st.agi = int(ds.agi); st.defense = int(ds.defense)
			var p := SurvivalData.empower(st, id, seed, 0)
			var affix := SurvivalData.elite_affix(seed, id)
			seen_affix[affix] = true
			match affix:
				"BRUTAL": _check(st.atk == int(ds.atk) + 7, "BRUTAL +3+4 ATK")
				"SWIFT": _check(st.agi == int(ds.agi) + 5, "SWIFT +5 AGI")
				"STONE": _check(int(p.affinity) == BattleMath.Affinity.RESIST and st.defense == int(ds.defense) + 6, "STONE resists, +6 DEF")
				"BURNING": _check((p.skills as Array).has(&"ember_touch"), "BURNING gains EMBER TOUCH")
				"VAMPIRIC": _check((p.skills as Array).has(&"life_drain"), "VAMPIRIC gains LIFE DRAIN")
	_check(seen_affix.size() == 5, "All 5 elite affixes occur (%d)" % seen_affix.size())
	for s in range(1, 6):
		var w := SurvivalStrata.warden_of(s)
		_check(not SurvivalData.is_elite(1, w), "Warden %s is never an elite" % w)
		var st := UnitStats.new()
		st.max_hp = 40; st.atk = 10
		var p := SurvivalData.empower(st, w, 1, 0)
		_check(st.max_hp == 60 and st.atk == 12 and String(p.tag) == "WARDEN", "Warden x1.5 HP, +2 ATK")
		var st5 := UnitStats.new()
		st5.max_hp = 40; st5.atk = 10
		SurvivalData.empower(st5, w, 1, 5)
		_check(st5.atk == 15 and st5.max_hp == 69, "OMEN 5 warden +3 ATK and OMEN 1 +15%% HP (%d/%d)" % [st5.atk, st5.max_hp])
		_check(SurvivalData.battle_label(w, 1, 0).begins_with("WARDEN "), "Warden battle label")
	var elites0 := 0
	var elites3 := 0
	for seed in 300:
		for demon in SurvivalData.DEMONS:
			elites0 += int(SurvivalData.is_elite(seed, String(demon.id), 0))
			elites3 += int(SurvivalData.is_elite(seed, String(demon.id), 3))
	_check(elites3 > elites0 * 1.4, "OMEN 3 raises elite rate (%d vs %d)" % [elites3, elites0])


func _absorb() -> void:
	var demon := SurvivalData.demon_by_id("lich") # MAK 12 / MEF 11 os mais fortes
	_check(SurvivalAbsorb.signature_stats(demon) == [&"mak", &"mef"], "Lich signature stats are MAK/MEF")
	var owned: Array[StringName] = []
	var rarity_by_stratum := {}
	var yoch := 0
	var skills := 0
	var total := 0
	for s in [1, 5]:
		var rare := 0
		for i in 2000:
			var rng := RandomNumberGenerator.new()
			rng.seed = i * 31 + s
			var opts := SurvivalAbsorb.roll_options(rng, demon, owned, 1.0, {"stratum": s})
			total += 1
			if opts.size() != 3:
				_check(false, "3 options (s%d #%d)" % [s, i])
			var first_stat := {}
			for o in opts:
				if String(o.kind) in ["stat", "stat2"]:
					first_stat = o
					break
			if not first_stat.is_empty():
				var head: StringName = first_stat.stat if String(first_stat.kind) == "stat" else first_stat.stats[0]
				if not [&"mak", &"mef"].has(head):
					_check(false, "First stat offer inherits MAK/MEF (got %s)" % head)
			var seen := {}
			for o in opts:
				match String(o.kind):
					"skill": skills += 1
					"yoch": yoch += 1
				if String(o.kind) in ["stat", "stat2", "yoch"]:
					if String(o.rarity) != "COMMON":
						rare += 1
					var keys: Array = [o.stat] if String(o.kind) != "stat2" else o.stats
					for k in keys:
						if String(o.kind) != "yoch":
							if seen.has(k):
								_check(false, "No duplicate stat in one offer")
							seen[k] = true
					var amt := int(o.amount)
					if String(o.kind) != "stat2" and StringName(o.stat) in [&"max_hp", &"max_en"]:
						if not (amt in [3, 5, 6, 8, 10, 16]):
							_check(false, "HP/EN amount from table (%d)" % amt)
					elif amt < 1 or amt > SurvivalAbsorb.MAX_POINTS:
						_check(false, "Stat amount within 1..6 (%d)" % amt)
		rarity_by_stratum[s] = rare
	_check(int(rarity_by_stratum[5]) > int(rarity_by_stratum[1]) * 1.5,
			"Deeper strata roll more RARE/EPIC (%d vs %d)" % [rarity_by_stratum[5], rarity_by_stratum[1]])
	var skill_share := float(skills) / float(total)
	_check(skill_share > 0.25 and skill_share < 0.35, "~30%% skill chance (%.3f)" % skill_share)
	# D-111: a absorção só melhora o Fallen; a oferta YOCH +n saiu.
	_check(yoch == 0, "D-111: no YOCH +n offer any more (%d)" % yoch)
	# Desespero sobe a raridade: nunca COMMON com HP < 35%.
	var common_desperate := 0
	for i in 500:
		var rng := RandomNumberGenerator.new()
		rng.seed = i
		for o in SurvivalAbsorb.roll_options(rng, demon, owned, 0.2, {"stratum": 1}):
			if String(o.get("rarity", "")) == "COMMON":
				common_desperate += 1
	_check(common_desperate == 0, "Desperate absorption never rolls COMMON (%d)" % common_desperate)
	# Relíquias: 4 opções e bônus de skill.
	var four := 0
	var bonus_skills := 0
	for i in 500:
		var rng := RandomNumberGenerator.new()
		rng.seed = i
		var opts := SurvivalAbsorb.roll_options(rng, demon, owned, 1.0, {"count": 4, "skill_bonus": 0.45})
		four += int(opts.size() == 4)
		for o in opts:
			bonus_skills += int(String(o.kind) == "skill")
	_check(four == 500, "PROPHET'S SCROLL gives 4 options (%d/500)" % four)
	_check(bonus_skills > 330, "Skill bonus raises the skill rate (%d/500)" % bonus_skills)
	# Aplicação pura de cada tipo.
	var st := UnitStats.new()
	var gains := {}
	var learned: Array[StringName] = []
	SurvivalAbsorb.apply_option(st, gains, learned, {"kind": "stat", "stat": &"max_hp", "amount": 10})
	_check(st.max_hp == 20 and int(gains.max_hp) == 10, "max_hp offer applies")
	SurvivalAbsorb.apply_option(st, gains, learned, {"kind": "stat2", "stats": [&"atk", &"agi"], "amount": 3})
	_check(st.atk == 8 and st.agi == 8 and int(gains.atk) == 3 and int(gains.agi) == 3, "EPIC dual offer applies")
	SurvivalAbsorb.apply_option(st, gains, learned, {"kind": "yoch", "stat": &"defense", "amount": 4})
	_check(st.defense == 5 and not gains.has("defense"), "D-111: an old YOCH offer changes nothing")
	SurvivalAbsorb.apply_option(st, gains, learned, {"kind": "skill", "skill": &"hellfire"})
	_check(learned == [&"hellfire"], "Skill offer learns")


func _relics() -> void:
	_check(SurvivalRelics.all_ids().size() == 23, "23 relics (12 stat + 11 effect)")
	for id in SurvivalRelics.all_ids():
		var r := SurvivalRelics.relic(id)
		_check(not String(r.hebrew).is_empty() and not String(r.info).is_empty(), "%s has hebrew name and info" % id)
	for c in SurvivalRelics.COVENANTS:
		for id in c.pair:
			_check(not SurvivalRelics.relic(String(id)).is_empty(), "Covenant %s uses known relic %s" % [c.id, id])
	var wrath := ["shard_of_urim", "ember_tooth"]
	_check(SurvivalRelics.covenants(wrath).size() == 1, "WRATH pair activates")
	_check(SurvivalRelics.bonus(wrath, "atk") == 3 + 2 + 4, "WRATH adds +4 ATK on top (%d)" % SurvivalRelics.bonus(wrath, "atk"))
	var st := UnitStats.new()
	SurvivalRelics.apply_all(st, wrath)
	_check(st.atk == 5 + 9 and st.agi == 7, "apply_all applies relics + covenant")
	_check(SurvivalRelics.covenants(["shard_of_urim"]).is_empty(), "Half a pair gives nothing")
	_check(SurvivalRelics.has_perk(["golden_calf", "merchant_seal"], "mammon"), "MAMMON perk from the pair")
	_check(SurvivalRelics.party_has({"fallen_relics": [], "party": [{"relics": ["raziel_book"]}]}, "identified"), "party_has sees an ally's relics")
	_check(not SurvivalRelics.party_has({"fallen_relics": [], "party": [], "reserve": [{"relics": ["raziel_book"]}]}, "identified"), "D-111: the reserve does not count")
	_check(SurvivalRelics.cap_of({"kind": "demon"}) == 1 and SurvivalRelics.cap_of({"kind": "human"}) == 2 and SurvivalRelics.cap_of({"kind": "yoch"}) == 2 and SurvivalRelics.cap_of("fallen") == 1, "D-111: 1 relic per unit, humans 2")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var drops := SurvivalRelics.roll(rng, SurvivalRelics.all_ids(), [], 3)
	_check(drops.is_empty(), "No drop when every relic is owned")
	var owned := ["shard_of_urim"]
	var three := SurvivalRelics.roll(rng, owned, [], 3)
	_check(three.size() == 3 and not three.has("shard_of_urim"), "Roll gives 3 distinct unowned relics")
	var starts := {}
	for seed in 200:
		var r0 := SurvivalRelics.starting_relic(seed)
		_check(SurvivalRelics.STARTER_IDS.has(r0), "Starting relic is a starter")
		starts[r0] = true
	_check(starts.size() == 6, "Every starter can be the starting relic (%d)" % starts.size())


func _economy() -> void:
	SurvivalState.reset()
	_check((SurvivalState.data().relics as Array).size() == 1, "Run starts with exactly one relic")
	SurvivalState.patch({"fallen_hp": 5, "macca": 100})
	_check(SurvivalState.heal_price() == 0, "First heal of the stratum is free")
	_check(SurvivalState.sanctuary_heal() and int(SurvivalState.data().macca) == 100, "Free heal costs nothing")
	_check(int(SurvivalState.data().fallen_hp) == SurvivalState.fallen_max_hp(), "Heal restores HP")
	_check(SurvivalState.heal_price() == 15, "Second heal on stratum 1 costs 15M")
	SurvivalState.patch({"macca": 10, "fallen_hp": 5})
	_check(not SurvivalState.sanctuary_heal() and int(SurvivalState.data().fallen_hp) == 5, "Heal refused without Macca, nothing spent")
	# Descida.
	_check(not SurvivalState.descend(), "Cannot descend with the warden alive")
	SurvivalState.patch({"defeated": [SurvivalStrata.warden_of(1)], "cell": [3, 5], "heals_used": 2})
	_check(SurvivalState.descend(), "Descend after the warden falls")
	var s := SurvivalState.data()
	_check(int(s.stratum) == 2 and int(s.heals_used) == 0 and (s.cell as Array) == [12, 10], "Descend resets position and heal")
	_check(SurvivalState.heal_price() == 0, "New stratum: heal free again")
	SurvivalState.patch({"heals_used": 1})
	_check(SurvivalState.heal_price() == 30, "Stratum 2 heal costs 30M")
	SurvivalState.patch({"omen": 2, "heals_used": 0})
	_check(SurvivalState.heal_price() == 30, "OMEN 2: heal never free")
	SurvivalState.patch({"omen": 0})
	# Preços: inflação e descontos.
	SurvivalState.patch({"stratum": 1, "fallen_relics": [], "party": []})
	_check(SurvivalState.item_price("bead") == 20, "BEAD 20M on stratum 1")
	SurvivalState.patch({"stratum": 3})
	_check(SurvivalState.item_price("bead") == 26, "BEAD inflates to 26M on stratum 3")
	SurvivalState.patch({"fallen_relics": ["merchant_seal"]})
	_check(SurvivalState.item_price("bead") == 20, "MERCHANT SEAL -25%")
	# D-111: 1 relíquia no Fallen; o par MAMMON precisa de um humano (2 relíquias).
	var keeper := SurvivalAllies.yoch_member("eco_yoch")
	keeper["relics"] = ["merchant_seal", "golden_calf"]
	SurvivalState.patch({"fallen_relics": [], "party": [keeper]})
	_check(SurvivalState.item_price("bead") == 13, "MAMMON -50% (pair on a human ally)")
	SurvivalState.patch({"party": []})
	var stock := SurvivalData.shop_stock(9, 2)
	_check(stock.size() == 4 and stock[0] == "bead" and stock[1] == "chakra", "Shop stock: 2 fixed + 2 rotating")
	var varied := {}
	for seed in 50:
		varied[str(SurvivalData.shop_stock(seed, 1))] = true
	_check(varied.size() == 3, "Rotating stock varies by seed (%d)" % varied.size())
	SurvivalState.patch({"macca": 500, "stratum": 1, "fallen_relics": []})
	for id in ["medicine", "soma", "blast"]:
		_check(SurvivalState.buy_item(id), "Buy %s" % id)
	_check(SurvivalState.total_items() == 1 + 1 + 3, "total_items counts every item key")
	# Identificação por relíquia.
	SurvivalState.patch({"fallen_relics": ["raziel_book"]})
	SurvivalState.learn_skill(&"hellfire")
	_check(not (SurvivalState.data().unidentified as Array).has("hellfire"), "BOOK OF RAZIEL: skill arrives identified")
	SurvivalState.patch({"fallen_relics": []})
	SurvivalState.learn_skill(&"mend")
	_check((SurvivalState.data().unidentified as Array).has("mend"), "Without it the skill is unidentified")
	# OMEN 4 = 2 continues.
	SurvivalState.patch({"omen": 4})
	_check(SurvivalState.max_continues() == 2, "OMEN 4 caps continues at 2")
	SurvivalState.patch({"omen": 0})
	# Run vencida.
	var wardens: Array = []
	for st in range(1, 6):
		wardens.append(SurvivalStrata.warden_of(st))
	SurvivalState.patch({"defeated": wardens, "stratum": 5})
	_check(SurvivalState.run_cleared(), "Run cleared when the stratum 5 warden falls")
	_check(not SurvivalState.descend(), "No descend past stratum 5")
	# D-111: o Yoch tem sempre o SP do Fallen; as relíquias dele somam por cima.
	SurvivalState.patch({"defeated": [], "stratum": 1})
	var y := SurvivalAllies.yoch_member("eco_y2")
	var fsp := SurvivalState.fallen_sp()
	_check(SurvivalState.member_stats(y).sp_value() == fsp and SurvivalState.member_stats(y).max_en == 0, "Yoch SP equals Fallen SP (%d) with no EN" % fsp)
	SurvivalState.patch({"gains": {"max_hp": 0, "max_en": 0, "atk": 5, "mak": 0, "defense": 0, "mef": 0, "agi": 0}})
	_check(SurvivalState.member_stats(y).sp_value() == SurvivalState.fallen_sp(), "Yoch follows the Fallen after an absorption")
	y["relics"] = ["blood_vessel"]
	_check(SurvivalState.member_stats(y).max_hp == SurvivalAllies.yoch_base_stats(SurvivalState.fallen_sp()).max_hp + 20, "Yoch's relic adds on top")
	SurvivalState.patch({"gains": SurvivalState._zero_gains()})
	# Grupo e reserva.
	SurvivalState.patch({"party": [], "reserve": []})
	var adds: Array[String] = []
	for i in 11:
		adds.append(SurvivalState.add_member(SurvivalAllies.new_member(SurvivalState.new_uid(), "pixie", SurvivalAllies.stats_like_battle("pixie", fsp))))
	_check(adds.slice(0, 2) == ["party", "party"] and adds.slice(2, 10).all(func(w: String) -> bool: return w == "reserve") and adds[10] == "", "2 in the party, 8 in the reserve, then no room (%s)" % str(adds))
	var p0 := String(SurvivalState.party()[0].uid)
	var r0 := String(SurvivalState.reserve()[0].uid)
	_check(not SurvivalState.move_member(p0), "Reserve full: a party member cannot go there")
	_check(SurvivalState.move_member(r0, p0) and String(SurvivalState.party()[0].uid) == r0 and SurvivalState.reserve().any(func(m: Dictionary) -> bool: return String(m.uid) == p0), "Swap party <-> reserve")
	# Relíquias: teto 1 no demônio, troca de dono.
	SurvivalState.patch({"relics": ["shard_of_urim", "ember_tooth"], "fallen_relics": []})
	SurvivalState.toggle_relic(r0, "shard_of_urim")
	SurvivalState.toggle_relic(r0, "ember_tooth")
	_check((SurvivalState.find_member(r0).relics as Array) == ["shard_of_urim"], "A demon ally keeps 1 relic")
	SurvivalState.toggle_relic("fallen", "shard_of_urim")
	_check((SurvivalState.data().fallen_relics as Array) == ["shard_of_urim"] and (SurvivalState.find_member(r0).relics as Array).is_empty(), "Equipping elsewhere moves the relic")
	# HEAL revive os caídos (grupo e reserva).
	SurvivalState.update_member(r0, {"down": true, "hp": 0})
	SurvivalState.patch({"heals_used": 0, "omen": 0})
	SurvivalState.sanctuary_heal()
	var healed := SurvivalState.find_member(r0)
	_check(not bool(healed.down) and SurvivalState.member_hp(healed) == SurvivalState.member_max_hp(healed), "HEAL revives a downed ally")
	SurvivalState.patch({"party": [], "reserve": [], "fallen_relics": []})


func _meta() -> void:
	if FileAccess.file_exists(SurvivalMeta.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SurvivalMeta.SAVE_PATH))
	var w5 := SurvivalStrata.warden_of(5)
	var st := {"defeated": ["pixie", w5], "stratum": 5, "macca": 101, "continues": 2, "omen": 0}
	var expected := 2 * 100 + 5 * 300 + 1 * 250 + 50 + 200
	_check(SurvivalMeta.run_score(st) == expected, "run_score formula (%d vs %d)" % [SurvivalMeta.run_score(st), expected])
	st["omen"] = 2
	_check(SurvivalMeta.run_score(st) == int(round(expected * 1.4)), "OMEN multiplies the score")
	st["omen"] = 0
	var m := SurvivalMeta.finish_run(2, 101, 2, st)
	_check(int(m.omen_unlocked) == 1 and int(m.clears) == 1, "Clearing OMEN 0 unlocks OMEN 1")
	_check((m.codex as Array).has("pixie") and (m.codex as Array).has(w5), "CODEX records defeated demons")
	st["omen"] = 1
	m = SurvivalMeta.finish_run(2, 101, 2, st)
	_check(int(m.omen_unlocked) == 2, "Clearing OMEN 1 unlocks OMEN 2")
	m = SurvivalMeta.finish_run(1, 0, 0, {"defeated": ["oni"], "stratum": 1, "omen": 2})
	_check(int(m.omen_unlocked) == 2 and (m.codex as Array).has("oni"), "A loss keeps OMEN, still fills CODEX")
	_check(int(m.runs) == 3, "Runs counted")


func _save() -> void:
	# D-111: saves antigos (v1/v2, com o Yoch fixo no grupo) são descartados.
	for old in [1, 2]:
		var f := FileAccess.open(SurvivalState.SAVE_PATH, FileAccess.WRITE)
		f.store_string(JSON.stringify({"version": old, "state": {"fallen_hp": 20}}))
		f.close()
		if Engine.has_meta(SurvivalState.META_KEY):
			Engine.remove_meta(SurvivalState.META_KEY)
		_check(not SurvivalState.has_save() and not SurvivalState.load_from_file(), "v%d save is discarded (run restarts)" % old)
	SurvivalState.reset()
	var yoch := SurvivalAllies.yoch_member("save_y")
	yoch["relics"] = ["blood_vessel", "manna_jar"]
	SurvivalState.patch({"party": [yoch]})
	Engine.remove_meta(SurvivalState.META_KEY)
	_check(SurvivalState.load_from_file(), "v3 save with an ally loads")
	var s := SurvivalState.data()
	_check((s.party as Array).size() == 1 and String(s.party[0].kind) == "yoch", "Ally kept in the save")
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SurvivalState.SAVE_PATH))
	_check(int(raw.version) == 3, "Save written as v3")
	var demon_two := SurvivalAllies.new_member("bad_d", "pixie", SurvivalAllies.stats_like_battle("pixie", 73))
	demon_two["relics"] = ["shard_of_urim", "ember_tooth"]
	var bads: Array = [{"stratum": 9}, {"relics": ["nope"]}, {"omen": 7}, {"medicine": -1},
		{"party": [demon_two]}, {"party": [{"uid": "x"}]}, {"fallen_relics": ["shard_of_urim", "ember_tooth"]},
		{"party": [yoch, yoch]}, {"reserve": [demon_two]}]
	for bad in bads:
		var copy: Dictionary = s.duplicate(true)
		for k in bad.keys():
			copy[k] = bad[k]
		var g := FileAccess.open(SurvivalState.SAVE_PATH, FileAccess.WRITE)
		g.store_string(JSON.stringify({"version": 3, "state": copy}))
		g.close()
		Engine.remove_meta(SurvivalState.META_KEY)
		_check(not SurvivalState.load_from_file(), "Invalid save refused: %s" % str(bad))
	var rows := SurvivalStrata.maze(77, 3)
	var wall := Vector2i(0, 0)
	for y in rows.size():
		for x in String(rows[y]).length():
			if String(rows[y])[x] == "#" and x > 0 and y > 0:
				wall = Vector2i(x, y)
				break
		if wall != Vector2i(0, 0):
			break
	var c2: Dictionary = s.duplicate(true)
	c2["stratum"] = 3
	c2["cell"] = [wall.x, wall.y]
	var h := FileAccess.open(SurvivalState.SAVE_PATH, FileAccess.WRITE)
	h.store_string(JSON.stringify({"version": 2, "state": c2}))
	h.close()
	Engine.remove_meta(SurvivalState.META_KEY)
	_check(not SurvivalState.load_from_file(), "Cell inside a wall of the stratum maze is refused")
