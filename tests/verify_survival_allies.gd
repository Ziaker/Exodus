extends SceneTree
## D-111 (criador 2026-11-26): aliados do Survival além do Yoch. Regras puras (SurvivalAllies),
## batalha com cenas reais (Fallen sozinho, 3 heróis, AUTO, PARTY, oferta ao vencer, luta-teste,
## crescimento, aliado caído) e mapa (recrutáveis, Yoch, menu C, HIRE, RESERVE, relíquias).
## Uso: Godot --headless --path . -s tests/verify_survival_allies.gd

var checks := 0
var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error("FAIL: " + text)
		print("FAIL: ", text)


func _wait_mode(b: Control, wanted: Array, limit: int = 600) -> bool:
	for _i in limit:
		if b.hud != null and b.hud.mode in wanted:
			return true
		if b.hud != null and b.hud.mode == "react" and not wanted.has("react"):
			b.handle_back()
		if b.hud != null and b.hud.mode in ["continue", "announce"] and not wanted.has(b.hud.mode):
			b.proceed()
		await process_frame
	return false


func _battle(encounter: String, patch: Dictionary) -> Control:
	SurvivalState.reset()
	var base := {"seed": 1, "encounter_id": encounter,
		"gains": {"max_hp": 0, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": 30}}
	for k in patch.keys():
		base[k] = patch[k]
	SurvivalState.patch(base)
	var b: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	b.suppress_scene_change = true
	root.add_child(b)
	return b


func _demon(id: String, uid: String) -> Dictionary:
	return SurvivalAllies.new_member(uid, id, SurvivalAllies.stats_like_battle(id, 73), 1)


func _run() -> void:
	var sandbox := "user://test_survival_allies_guard.json"
	ProgressStore.save_path_override = sandbox
	ProgressStore.clear()
	var gains_before := ProgressStore.load_gains()
	_rules()
	await _battle_solo()
	await _battle_three()
	await _battle_auto()
	await _battle_auto_prayers()
	await _battle_party_panel()
	await _battle_offer()
	await _battle_duel()
	await _world()
	_check(ProgressStore.load_gains() == gains_before, "Allies never touch the campaign ProgressStore")
	SurvivalState.clear()
	ProgressStore.clear()
	ProgressStore.save_path_override = ""
	print("SURVIVAL ALLIES CHECKS PASSED: %d FAILED: %d" % [checks, int(failed)])
	quit(1 if failed else 0)


# ------------------------------------------------------------------ regras puras

func _rules() -> void:
	SurvivalState.reset()
	_check(SurvivalState.party().is_empty() and SurvivalState.reserve().is_empty(), "A run starts with the Fallen alone")
	# Encontros por estrato: 0 (15%), 1 (35%), 2 (35%), 3 (15%).
	var counts := [0, 0, 0, 0]
	var demons := 0
	var humans := 0
	var kinds := {}
	var yoch := 0
	var n := 3000
	for seed in n:
		var c := SurvivalAllies.encounter_count(seed, 2)
		counts[c] += 1
		yoch += int(SurvivalAllies.yoch_in_stratum(seed, 3))
	for seed in 600:
		for e in SurvivalAllies.encounters(seed, 2):
			if SurvivalData.is_human_id(String(e.candidate)):
				humans += 1
			else:
				demons += 1
				_check(String(e.candidate) != SurvivalStrata.warden_of(2) and SurvivalStrata.stratum_of(String(e.candidate)) == 2, "Candidate demon from the stratum, never the warden")
			kinds[String(e.kind)] = int(kinds.get(String(e.kind), 0)) + 1
			if String(e.kind) == "item":
				_check(SurvivalAllies.ITEM_REQUESTS.has(String(e.item)), "Requested item is a consumable (%s)" % e.item)
	var expected := [0.15, 0.35, 0.35, 0.15]
	for i in 4:
		_check(absf(float(counts[i]) / n - expected[i]) < 0.03, "%d encounters ~%d%% (%.3f)" % [i, int(expected[i] * 100), float(counts[i]) / n])
	var share := float(demons) / float(demons + humans)
	_check(share > 0.70 and share < 0.80, "Candidates ~75%% demons (%.3f)" % share)
	_check(kinds.size() == 4, "All 4 encounter kinds appear (%s)" % str(kinds.keys()))
	_check(absf(float(yoch) / n - 0.15) < 0.025, "Yoch in ~15%% of strata (%.3f)" % (float(yoch) / n))
	# Células: livres, distintas, longe do santuário.
	for seed in 30:
		for st in range(1, 6):
			var lay := SurvivalStrata.layout(seed, st)
			var used := {}
			for id in lay.demons.keys():
				used[lay.demons[id]] = true
			for ev in lay.events:
				used[ev.cell] = true
			var mine := {}
			for e in SurvivalAllies.encounters(seed, st):
				_check(not used.has(e.cell) and not mine.has(e.cell), "Recruit cell is free (seed %d s%d)" % [seed, st])
				mine[e.cell] = true
			var yc := SurvivalAllies.yoch_cell(seed, st)
			_check(not used.has(yc) and not mine.has(yc), "Yoch cell is free (seed %d s%d)" % [seed, st])
	# Preços e ficha "como na luta".
	var stats := SurvivalAllies.stats_like_battle("pixie", 73)
	var expect_stats := SurvivalAllies.to_stats(SurvivalData.demon_by_id("pixie").stats)
	SurvivalData.follow_hero(expect_stats, 73, SurvivalStrata.par_sp(1))
	_check(SurvivalAllies.stats_dict(expect_stats) == stats, "Map/sanctuary stats = battle stats (follow_hero, no elite)")
	_check(SurvivalAllies.hire_price(stats) == SurvivalAllies.sp_of(stats) * 2 and SurvivalAllies.money_price(stats) == SurvivalAllies.sp_of(stats), "Hire SP x2, money SP x1")
	var stock := SurvivalAllies.hire_stock(9, 3)
	_check(stock.size() == 2 and stock[0] != stock[1] and not stock.has(SurvivalStrata.warden_of(3)), "Sanctuary sells 2 demons of the stratum, no warden")
	# Oferta: 25%.
	var offers := 0
	for i in 4000:
		offers += int(SurvivalAllies.offer_rolls(5, i))
	_check(absf(offers / 4000.0 - 0.25) < 0.025, "Join offer ~25%% (%.3f)" % (offers / 4000.0))
	# Crescimento: a cada 2 lutas, +1 65% / +2 20% / +3 15%.
	var amounts := {1: 0, 2: 0, 3: 0}
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 6000:
		var m := _demon("pixie", "g%d" % i)
		var sp0 := SurvivalAllies.sp_of(m.stats)
		var g1 := SurvivalAllies.grow(m, rng)
		var g2 := SurvivalAllies.grow(m, rng)
		if not g1.is_empty() or g2.is_empty() or SurvivalAllies.sp_of(m.stats) - sp0 != int(g2.amount):
			_check(false, "Growth only on the 2nd fight and it adds its amount (#%d)" % i)
			continue
		amounts[int(g2.amount)] = int(amounts.get(int(g2.amount), 0)) + 1
	var total := float(amounts[1] + amounts[2] + amounts[3])
	_check(absf(amounts[1] / total - 0.65) < 0.03 and absf(amounts[2] / total - 0.20) < 0.03 and absf(amounts[3] / total - 0.15) < 0.03,
			"Growth +1/+2/+3 = 65/20/15%% (%s)" % str(amounts))
	var y := SurvivalAllies.yoch_member("gy")
	_check(SurvivalAllies.grow(y, rng).is_empty() and SurvivalAllies.grow(y, rng).is_empty(), "Yoch does not grow (his SP is the Fallen's)")
	# Humano recrutado: 3 rezas do pool, nunca Ra'am.
	for i in 200:
		var h := SurvivalAllies.new_member("h%d" % i, "human_s2_b", SurvivalAllies.stats_like_battle("human_s2_b", 73), i)
		var all: Array = (h.spells as Array) + (h.skills as Array)
		_check(all.size() == 3 and not all.has("raam") and String(h.kind) == "human", "Human ally: 3 prayers, no Ra'am (%s)" % str(all))
		for p in all:
			_check(SurvivalAllies.HUMAN_PRAYER_POOL.has(p), "Prayer %s from the pool" % p)


# ------------------------------------------------------------------ batalha

func _battle_solo() -> void:
	var b := await _battle("pixie", {})
	_check(await _wait_mode(b, ["plan"]), "Solo battle reaches the plan")
	_check(b.hud.players.size() == 1 and b._ally == null, "The Fallen fights alone (%d heroes)" % b.hud.players.size())
	_check(b._commands(b._fallen).has("PARTY"), "Fallen's own turn lists PARTY")
	_check(not b._commands(b._fallen, true).has("PARTY"), "PARTY is not a reaction")
	b.queue_free()
	await process_frame


func _battle_three() -> void:
	var down := _demon("oni", "d1")
	down.down = true
	down.hp = 0
	var b := await _battle("pixie", {"party": [_demon("pixie", "a1"), SurvivalAllies.yoch_member("a2")], "reserve": [down]})
	_check(await _wait_mode(b, ["plan"]), "3-hero battle reaches the plan")
	_check(b.hud.players.size() == 3, "Fallen + 2 allies fight (%d)" % b.hud.players.size())
	var r0: Rect2 = b.hud.status_rect(0)
	var r1: Rect2 = b.hud.status_rect(1)
	var r2: Rect2 = b.hud.status_rect(2)
	var first: Rect2 = b.hud.STATUS_RECTS[0]
	var last: Rect2 = b.hud.STATUS_RECTS[1]
	_check(is_equal_approx(r0.position.x, first.position.x) and is_equal_approx(r2.end.x, last.end.x) and r0.end.x < r1.position.x and r1.end.x < r2.position.x,
			"3 narrow windows share the width of the 2 (\"3 estreitos\")")
	_check(r0.size.x < b.hud.NARROW_PANEL_LIMIT and is_equal_approx(r0.size.x, r2.size.x), "Narrow windows have the same width (%.1f)" % r0.size.x)
	var yoch: BattleUnit = b.hud.players[2]
	_check(yoch.stats.sp_value() == b._fallen.stats.sp_value() and yoch.prays, "Yoch has the Fallen's SP and prays")
	# Absorção do Fallen: o Yoch acompanha na hora.
	var before: int = b._fallen.stats.sp_value()
	b._fallen.stats.atk += 4
	b._follow_fallen_with_yoch(before)
	_check(yoch.stats.sp_value() == b._fallen.stats.sp_value(), "Yoch follows the Fallen's SP during the fight")
	b._fallen.stats.atk -= 4
	# Fim da luta: aliado caído fica caído; os vivos contam a luta.
	var pixie: BattleUnit = b.hud.players[1]
	pixie.current_hp = 0
	for foe in b.hud.opponents:
		foe.current_hp = 0
	SurvivalState.patch({"battles": 1})
	b._show_result()
	await process_frame
	var p0: Dictionary = SurvivalState.find_member("a1")
	_check(bool(p0.down) and int(p0.hp) == 0, "A fallen ally stays down after the fight")
	_check(int(SurvivalState.find_member("a2").fights) == 0, "Yoch's fight is not counted (no growth)")
	if b.offer_open:
		b.answer_offer(false)
	b.queue_free()
	await process_frame
	var b2 := await _battle("pixie", {"party": SurvivalState.party().duplicate(true)})
	await _wait_mode(b2, ["plan"])
	_check(b2.hud.players.size() == 2 and not b2.hud.players.any(func(u: BattleUnit) -> bool: return u.display_name == "PIXIE"), "A downed ally does not join the next fight")
	b2.queue_free()
	await process_frame


func _battle_auto() -> void:
	var fast := _demon("jack_frost", "auto1")
	fast.auto = true
	fast.stats.agi = 99
	# Fraco de propósito: a luta precisa durar até o plano do Fallen.
	for k in ["atk", "mak"]:
		fast.stats[k] = 1
	fast.skills = []
	var b := await _battle("oni", {"party": [fast], "gains": {"max_hp": 60, "max_en": 0, "atk": 0, "mak": 0, "defense": 0, "mef": 0, "agi": 0}})
	var reached := await _wait_mode(b, ["plan"], 3000)
	_check(reached, "Battle with an AUTO ally reaches the Fallen's plan (mode %s, log %s)" % [b.hud.mode, str(b.log_history.slice(maxi(0, b.log_history.size() - 6)))])
	var log_text := "\n".join(b.log_history)
	_check(log_text.contains("(AUTO)"), "The AUTO ally took its turn by itself")
	var ally: BattleUnit = b.hud.players[1]
	_check(b.is_auto(ally) and not b.eligible_reactors().has(ally), "An AUTO ally never reacts")
	_check(not log_text.contains("ATTACK: JACK FROST"), "AUTO ally never opened an attack bar")
	b.queue_free()
	await process_frame


## Auditoria: em AUTO um humano só recebe as rezas que a IA inimiga resolve (Refuah/Ra'am etc. gastavam PP sem efeito).
func _battle_auto_prayers() -> void:
	var h := SurvivalAllies.new_member("ap_h", "human_s1_a", SurvivalAllies.stats_like_battle("human_s1_a", 73), 1)
	h.spells = ["refuah", "raam", "sanverim", "magen"]
	h.skills = []
	h.auto = true
	var b := await _battle("oni", {"party": [h]})
	await _wait_mode(b, ["plan", "result"])
	var u: BattleUnit = b.hud.players[1]
	_check(u.skills.has(&"pray") and u.skills.has(&"sanverim") and not u.skills.has(&"refuah") and not u.skills.has(&"raam") and not u.skills.has(&"magen"),
			"AUTO human only gets PRAY and enemy-AI prayers (%s)" % str(u.skills))
	b.set_member_auto("ap_h", false)
	_check(not u.skills.has(&"pray") and not u.skills.has(&"sanverim"), "MANUAL removes the AUTO prayers again (%s)" % str(u.skills))
	b.queue_free()
	await process_frame


func _battle_party_panel() -> void:
	var b := await _battle("pixie", {"party": [_demon("pixie", "pp1")]})
	_check(await _wait_mode(b, ["plan"]), "PARTY test reaches the plan")
	var acts: int = b._fallen.acts_available
	b.open_party()
	await process_frame
	_check(b.hud.mode == "party" and b.party_open, "PARTY opens its panel")
	b.overlay_key(KEY_DOWN)
	b.overlay_key(KEY_Z)
	_check(bool(SurvivalState.find_member("pp1").auto) and b.is_auto(b.hud.players[1]), "Z switches the ally to AUTO (state and battle)")
	b.overlay_key(KEY_Z)
	_check(not bool(SurvivalState.find_member("pp1").auto) and not b.is_auto(b.hud.players[1]), "Z switches back to MANUAL")
	b.overlay_key(KEY_X)
	await process_frame
	_check(not b.party_open and b._fallen.acts_available == acts, "PARTY closes and costs no act")
	# Bug da auditoria: Tab na reação tem de pular o aliado em AUTO e chegar ao 3º herói.
	b.queue_free()
	await process_frame
	var auto_m := _demon("pixie", "tab_auto")
	auto_m.auto = true
	b = await _battle("oni", {"party": [auto_m, _demon("jack_frost", "tab_manual")]})
	await _wait_mode(b, ["plan"])
	for u in b.hud.players:
		u.acts_available = 2
	b.hud.mode = "react"
	b.hud.actor = 0
	var tab := InputEventKey.new()
	tab.pressed = true
	tab.keycode = KEY_TAB
	b.hud._input(tab)
	_check(b.reaction_actor == b.hud.players[2], "Tab skips the AUTO ally and reaches the 3rd hero")
	_check(b.hud.status_rect(0).get_center() != b.hud.STATUS_RECTS[0].get_center(), "Absorb particles aim at the Fallen's narrow window (3 heroes)")
	b.hud.mode = "busy"
	b.queue_free()
	await process_frame


func _battle_offer() -> void:
	# Procura uma luta (número) em que a semente 1 oferece.
	var number := 0
	# A oferta usa o número da luta já contada (battles + 1 na vitória).
	while not SurvivalAllies.offer_rolls(1, number + 1):
		number += 1
	var b := await _battle("cerberus", {"battles": number})
	_check(await _wait_mode(b, ["plan"]), "Offer test reaches the plan")
	var foe: BattleUnit = b.hud.opponents[0]
	var base: Dictionary = b._foe_base[foe.id]
	for f in b.hud.opponents:
		f.current_hp = 0
	b.state.round_number = 1
	b._show_result()
	for _i in 30:
		if b.offer_open:
			break
		await process_frame
	_check(b.offer_open and b.hud.mode == "offer", "A join offer opens on victory (battle #%d)" % number)
	var name: String = b.offer_name()
	b.overlay_key(KEY_Z)
	await process_frame
	var p := SurvivalState.party()
	_check(p.size() == 1 and String(p[0].name) == name, "Accepted ally joins the party (%s)" % name)
	if p.size() == 1:
		var joined: Dictionary = p[0]
		_check(int(joined.hp) == int(joined.stats.max_hp) and int(joined.en) == int(joined.stats.max_en), "Joins with full HP/EN")
		var offered: BattleUnit = b.offer_unit
		_check(joined.stats == b._foe_base[offered.id], "Joins with the same stats it had in the fight")
	var _unused := base
	b.queue_free()
	await process_frame


func _battle_duel() -> void:
	SurvivalState.reset()
	var keep := _demon("oni", "dk")
	SurvivalState.patch({"party": [keep], "fallen_hp": 20, "continues": 2, "bead": 1})
	var s := SurvivalState.data()
	SurvivalState.patch({"duel": {"encounter": "s1_r0", "candidate": "pixie", "stats": SurvivalAllies.stats_like_battle("pixie", 73),
		"snapshot": {"fallen_hp": 20, "fallen_en": int(s.fallen_en), "party": [keep.duplicate(true)], "continues": 2}},
		"encounter_id": "pixie", "seed": 1})
	var b: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	b.suppress_scene_change = true
	root.add_child(b)
	_check(await _wait_mode(b, ["plan"]), "Duel reaches the plan")
	_check(b.duel and not b._commands(b._fallen).has("ABSORB"), "No ABSORB in a test fight")
	_check(b.hud.opponents.size() == 1 and b.hud.opponents[0].display_name == "PIXIE", "Only the candidate, no elite label")
	SurvivalState.consume_item("bead")
	b._fallen.current_hp = 0
	b._finish_duel(false)
	var after := SurvivalState.data()
	_check(int(after.fallen_hp) == 20 and int(after.continues) == 2 and (after.duel as Dictionary).is_empty(), "Lost test: HP and continues restored")
	_check(int(after.bead) == 0, "Lost test: spent items stay spent")
	_check((after.recruits_done as Array).has("s1_r0") and SurvivalState.party().size() == 1, "Lost test: candidate leaves, nobody joins")
	b.queue_free()
	await process_frame
	SurvivalState.patch({"duel": {"encounter": "s1_r1", "candidate": "pixie", "stats": SurvivalAllies.stats_like_battle("pixie", 73),
		"snapshot": {"fallen_hp": 20, "fallen_en": 0, "party": SurvivalState.party().duplicate(true), "continues": 2}}, "encounter_id": "pixie"})
	var b2: Control = load(SurvivalData.BATTLE_SCENE).instantiate()
	b2.suppress_scene_change = true
	root.add_child(b2)
	await _wait_mode(b2, ["plan"])
	b2._finish_duel(true)
	_check(SurvivalState.party().size() == 2 and String(SurvivalState.party()[1].name) == "PIXIE", "Won test: the candidate joins")
	b2.queue_free()
	await process_frame


# ------------------------------------------------------------------ mapa

func _world() -> void:
	# Uma semente com recrutáveis no estrato 2 (labirinto gerado).
	var seed := 1
	while SurvivalAllies.encounters(seed, 2).size() < 2:
		seed += 1
	SurvivalState.reset()
	SurvivalState.patch({"seed": seed, "stratum": 2, "cell": [12, 10], "macca": 2000, "bead": 2, "chakra": 1})
	var w: Control = load(SurvivalData.WORLD_SCENE).instantiate()
	root.add_child(w)
	await process_frame
	var recruits: Array = w.npcs.filter(func(n: Dictionary) -> bool: return String(n.get("role", "")) == "recruit")
	_check(recruits.size() == SurvivalAllies.encounters(seed, 2).size(), "Recruitable figures on the map (%d)" % recruits.size())
	# Encontro "talk": entra.
	var npc: Dictionary = recruits[0]
	npc["kind"] = "talk"
	w.active_event = npc
	w.event_open = true
	w.event_index = 0
	_check(String(w.event_options()[0].id) == "join", "Talk encounter offers ACCEPT")
	w.confirm_event()
	_check(SurvivalState.party().size() == 1 and not w.npcs.has(npc), "Talk: joins and the figure leaves the map")
	# Encontro "item": gasta o item pedido.
	var npc2: Dictionary = recruits[1]
	npc2["kind"] = "item"
	npc2["item"] = "bead"
	w.active_event = npc2
	w.event_open = true
	w.event_index = 0
	w.confirm_event()
	_check(int(SurvivalState.data().bead) == 1 and SurvivalState.party().size() == 2, "Item: gives one BEAD and joins")
	# Encontro "money" (terceiro entra na reserva).
	var npc3 := {"id": "s2_rX", "role": "recruit", "kind": "money", "candidate": "pixie", "name": "PIXIE", "cell": Vector2i(0, 0), "picture": "", "pages": [""]}
	var price := SurvivalAllies.money_price(w.recruit_stats("pixie"))
	w.active_event = npc3
	w.event_open = true
	w.event_index = 0
	w.confirm_event()
	_check(int(SurvivalState.data().macca) == 2000 - price and SurvivalState.reserve().size() == 1, "Money: pays SP x1 and goes to the reserve")
	# Yoch amarelo.
	var tex: Texture2D = w.cutout(SurvivalAllies.YOCH_PICTURE, SurvivalAllies.YOCH_INK)
	var img := tex.get_image()
	var yellow := true
	var opaque := 0
	for yy in img.get_height():
		for xx in img.get_width():
			var c := img.get_pixel(xx, yy)
			if c.a > 0.05:
				opaque += 1
				var ink := SurvivalAllies.YOCH_INK
				if absf(c.r - ink.r) > 0.01 or absf(c.g - ink.g) > 0.01 or absf(c.b - ink.b) > 0.01 or c.a < 0.99:
					yellow = false
	_check(yellow and opaque > 2000, "Yoch figure is completely yellow (%d px)" % opaque)
	_check(img.get_pixel(0, 0).a < 0.05 or img.get_pixel(img.get_width() - 1, 0).a < 0.05, "Yoch figure has no VX background")
	# Menu C: alterna AUTO e usa item no mapa.
	w.toggle_menu()
	_check(w.menu_open and w._is_modal_open(), "C opens the status / items / settings menu")
	w.move_menu(1)
	w.confirm_menu()
	_check(bool(SurvivalState.party()[0].auto), "Menu: Z switches the ally to AUTO")
	var first_uid := String(SurvivalState.party()[0].uid)
	SurvivalState.update_member(first_uid, {"hp": 1})
	var bead_row := -1
	var rows: Array = w.menu_rows()
	for i in rows.size():
		if String(rows[i].type) == "item" and String(rows[i].id) == "bead":
			bead_row = i
	w.menu_index = bead_row
	w.confirm_menu()
	_check(w.menu_target == 0, "Menu: choosing an item asks for a target")
	w.move_menu(1)
	w.confirm_menu()
	_check(SurvivalState.member_hp(SurvivalState.find_member(first_uid)) == 1 + 20 or SurvivalState.member_hp(SurvivalState.find_member(first_uid)) == SurvivalState.member_max_hp(SurvivalState.find_member(first_uid)),
			"Menu: BEAD heals the ally on the map")
	_check(int(SurvivalState.data().bead) == 0, "Menu: the item is spent")
	SurvivalState.update_member(first_uid, {"down": true, "hp": 0})
	SurvivalState.patch({"chakra": 1})
	_check(w.use_item_on_map("chakra", first_uid).contains("down") and int(SurvivalState.data().chakra) == 1, "Items never revive; nothing spent")
	w.toggle_menu()
	_check(not w.menu_open, "C closes the menu")
	# HIRE.
	var macca_before := int(SurvivalState.data().macca)
	SurvivalState.patch({"reserve": []})
	w.open_hire()
	var row: Dictionary = w.hire_rows()[0]
	_check(w.confirm_hire() and int(SurvivalState.data().macca) == macca_before - int(row.price), "HIRE: pays SP x2 and the ally joins")
	_check(w.hire_rows().size() == 1, "HIRE: the hired demon leaves the stock")
	w.hire_open = false
	# RESERVE: troca com o grupo cheio.
	w.open_reserve()
	var reserve_uid := String(SurvivalState.reserve()[0].uid)
	var party_uid := String(SurvivalState.party()[0].uid)
	w.reserve_index = 2
	w.confirm_reserve()
	_check(w.reserve_pick == reserve_uid, "RESERVE: party full asks who leaves")
	w.reserve_index = 0
	w.confirm_reserve()
	_check(String(SurvivalState.party()[0].uid) == reserve_uid and String(SurvivalState.reserve()[0].uid) == party_uid, "RESERVE: swapped")
	w.reserve_open = false
	# Relíquias: o portador escolhido.
	SurvivalState.patch({"relics": ["shard_of_urim"]})
	w._open_relics()
	w.relic_wearer = 1
	w.relic_index = 0
	w._equip_relic()
	_check((SurvivalState.party()[0].relics as Array) == ["shard_of_urim"], "RELICS: equips on the chosen ally")
	w._close_relics()
	# HEAL revive o caído.
	SurvivalState.patch({"heals_used": 0})
	SurvivalState.sanctuary_heal()
	_check(not bool(SurvivalState.find_member(first_uid).down), "HEAL revives the downed ally")
	# Aviso de crescimento no mapa.
	SurvivalState.patch({"growth_toast": ["PIXIE +1 AGI"]})
	w._show_growth()
	_check(w.growth_lines == ["PIXIE +1 AGI"] and (SurvivalState.data().growth_toast as Array).is_empty(), "Growth toast shown once on the map")
	w.queue_free()
	await process_frame
	# Bug da auditoria: luta-teste esquecida no save (o jogo fechou no meio) é desfeita ao abrir o mapa.
	SurvivalState.reset()
	var keep := _demon("oni", "stale_k")
	SurvivalState.patch({"seed": seed, "stratum": 2, "cell": [12, 10], "fallen_hp": 3, "continues": 1, "party": [],
		"duel": {"encounter": "s2_r0", "candidate": "pixie", "stats": SurvivalAllies.stats_like_battle("pixie", 73),
			"snapshot": {"fallen_hp": 20, "fallen_en": 5, "party": [keep], "continues": 3}}})
	var w3: Control = load(SurvivalData.WORLD_SCENE).instantiate()
	root.add_child(w3)
	await process_frame
	var st3 := SurvivalState.data()
	_check((st3.duel as Dictionary).is_empty() and int(st3.fallen_hp) == 20 and int(st3.continues) == 3 and (st3.party as Array).size() == 1,
			"A stale test fight is undone when the map opens")
	_check(not (st3.recruits_done as Array).has("s2_r0"), "The stale candidate stays on the map")
	w3.queue_free()
	await process_frame
	# Auditoria: na Necrópole não se fala com uma figura através de uma parede fina (aresta fechada).
	SurvivalState.reset()
	var w4: Control = load(SurvivalData.WORLD_SCENE).instantiate()
	root.add_child(w4)
	await process_frame
	var nec := preload("res://scripts/survival/necropole_map.gd")
	var edge: Array = nec.DATA.data.closed_edges[0]
	var a_cell: Vector2i = nec.cell_at(edge[0])
	var b_cell: Vector2i = nec.cell_at(edge[1])
	w4.cell = a_cell
	w4.facing = w4.DIRS.find(b_cell - a_cell)
	w4.npcs.append({"id": "wall_test", "role": "event", "kind": "spirit", "cell": b_cell, "picture": "", "name": "X", "pages": [""]})
	_check(w4.facing >= 0 and w4.npc_near().is_empty(), "No talking through a closed Necropole edge")
	w4.npcs.pop_back()
	w4.queue_free()
	await process_frame
	# Aviso do Yoch no começo do estrato.
	var ys := 1
	while not SurvivalAllies.yoch_in_stratum(ys, 2):
		ys += 1
	SurvivalState.reset()
	SurvivalState.patch({"seed": ys, "stratum": 2, "cell": [12, 10]})
	var w2: Control = load(SurvivalData.WORLD_SCENE).instantiate()
	root.add_child(w2)
	await process_frame
	_check(w2.notice_text == SurvivalAllies.YOCH_NOTICE, "Notice banner: %s" % w2.notice_text)
	var ynpc: Array = w2.npcs.filter(func(n: Dictionary) -> bool: return String(n.get("role", "")) == "yoch")
	_check(ynpc.size() == 1, "Yoch is on the map")
	if ynpc.size() == 1:
		w2.active_event = ynpc[0]
		w2.event_open = true
		w2.event_index = 0
		w2.confirm_event()
		_check(String(SurvivalState.party()[0].kind) == "yoch" and bool(SurvivalState.data().yoch_joined), "Talking to Yoch: he joins")
	w2.queue_free()
	await process_frame
