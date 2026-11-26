extends SceneTree
## D-112 (creator 2026-11-26): verifies the 5 new Hebrew prayers:
## Tahorah (2 PP / 1 ACT), Magen (2 PP / 2 ACT), Gevurah (1 PP / 1 ACT, +15% +5%/extra PP),
## Mishpat (2 PP / 2 ACT, last_damage_dealt + 15), Zohar (3 PP / 1 ACT, wider POINT zone).
const SANDBOX := preload("res://tests/progress_sandbox.gd")
const R := BattleMath.RhythmResult

class TestBattle extends "res://scripts/battle/playable_controller.gd":
	var hero_timing := BattleMath.RhythmResult.POINT
	func _zone_roll(_half: float) -> int: return BattleMath.RhythmResult.MISS
	func _skill_attack_timing(attacker: BattleUnit, defender: BattleUnit, marks: Array[float], auto_hit: bool) -> Array[int]:
		if attacker.is_player:
			action_attacker = attacker
			action_defender = defender
			attack_result = hero_timing
			return [hero_timing]
		return await super._skill_attack_timing(attacker, defender, marks, auto_hit)

var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, reason: String) -> void:
	if not ok:
		push_error("FAIL: " + reason)
		quit(1)
		assert(ok, reason)
	checks += 1


func _fresh_battle(pp: int) -> Control:
	ProgressStore.clear()
	ProgressStore.save_pp(pp)
	var b := TestBattle.new()
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(b)
	for _i in 6:
		await process_frame
	# Give Yoch access to all new + D-107 prayers via the D-111 "spells" meta for testing.
	var y: BattleUnit = b.state.units[1]
	y.set_meta("spells", ["refuah", "haganah", "raam", "tahorah", "magen", "gevurah", "mishpat", "zohar", "sanverim", "nechamah", "cherav"])
	return b


func _run() -> void:
	SANDBOX.begin()
	ProgressStore.save_path_override = "user://test_new_prayers_guard.json"
	ProgressStore.clear()

	# ---- 1. Pure metadata & formulas in PrayerBook
	check(PrayerBook.base_cost(PrayerBook.TAHORAH) == 2 and PrayerBook.act_cost(PrayerBook.TAHORAH) == 1, "Tahorah: 2 PP / 1 ACT")
	check(PrayerBook.base_cost(PrayerBook.MAGEN) == 2 and PrayerBook.act_cost(PrayerBook.MAGEN) == 2, "Magen: 2 PP / 2 ACT")
	check(PrayerBook.base_cost(PrayerBook.GEVURAH) == 1 and PrayerBook.act_cost(PrayerBook.GEVURAH) == 1, "Gevurah: 1 PP / 1 ACT")
	check(PrayerBook.base_cost(PrayerBook.MISHPAT) == 2 and PrayerBook.act_cost(PrayerBook.MISHPAT) == 2, "Mishpat: 2 PP / 2 ACT")
	check(PrayerBook.base_cost(PrayerBook.ZOHAR) == 3 and PrayerBook.act_cost(PrayerBook.ZOHAR) == 1, "Zohar: 3 PP / 1 ACT")
	check(PrayerBook.accepts_extra_pp(PrayerBook.GEVURAH) and not PrayerBook.accepts_extra_pp(PrayerBook.MAGEN), "Gevurah accepts extra PP; Magen does not")
	check(is_equal_approx(PrayerBook.gevurah_bonus(0), 0.15) and is_equal_approx(PrayerBook.gevurah_bonus(3), 0.30), "Gevurah bonus: 15% + 5% per extra PP")
	check(PrayerBook.mishpat_damage(0) == 15 and PrayerBook.mishpat_damage(27) == 42, "Mishpat: last_damage_dealt + 15")
	for id in [PrayerBook.TAHORAH, PrayerBook.MAGEN, PrayerBook.GEVURAH, PrayerBook.MISHPAT, PrayerBook.ZOHAR]:
		check(PrayerBook.is_prayer(id) and PrayerBook.is_book_spell(id), "%s registered in PrayerBook" % id)
		check(String(PrayerBook.entry(id).get("hebrew", "")).length() > 0, "%s has Hebrew spelling" % id)
		check(PrayerBook.human_pool_ids().has(String(id)), "%s is in Survival human prayer pool" % id)
	check(SurvivalAllies.HUMAN_PRAYER_POOL == PrayerBook.human_pool_ids(), "SurvivalAllies.HUMAN_PRAYER_POOL synced with PrayerBook")

	# ---- 2. Live battle execution of all 5 prayers
	var b := await _fresh_battle(8)
	var fallen: BattleUnit = b.state.units[0]
	var yoch: BattleUnit = b.state.units[1]
	var foe: BattleUnit = b.hud.opponents[0]

	# Menu respects act_cost (with 1 ACT left, Magen and Mishpat are hidden; with 2 ACT, shown)
	b.prayer._build_menu(8, [], 1, yoch)
	check(not b.prayer.menu_ids.has(PrayerBook.MAGEN) and not b.prayer.menu_ids.has(PrayerBook.MISHPAT), "With 1 ACT, 2-ACT prayers are not castable")
	check(b.prayer.menu_ids.has(PrayerBook.TAHORAH) and b.prayer.menu_ids.has(PrayerBook.GEVURAH) and b.prayer.menu_ids.has(PrayerBook.ZOHAR), "With 1 ACT, 1-ACT prayers are listed")
	b.prayer._build_menu(8, [], 2, yoch)
	check(b.prayer.menu_ids.has(PrayerBook.MAGEN) and b.prayer.menu_ids.has(PrayerBook.MISHPAT), "With 2 ACT, Magen and Mishpat are listed")
	check(b._entry_cost({"pray": PrayerBook.MAGEN}) == 2 and b._entry_cost({"pray": PrayerBook.MISHPAT}) == 2, "_entry_cost counts 2 ACT for Magen/Mishpat")
	check(b._entry_cost({"pray": PrayerBook.GEVURAH}) == 1, "_entry_cost counts 1 ACT for Gevurah")

	# Tahorah: cleanses burns, bleeds, and negative statuses, preserving positive statuses (zohar)
	fallen.burns = [3, 2]
	fallen.bleeds = [3]
	SkillFx.apply_status(fallen, &"blind", 2)
	SkillFx.apply_status(fallen, &"snare", 2)
	SkillFx.apply_status(fallen, &"zohar", 2)
	yoch.acts_available = 2
	await b.prayer.execute(yoch, {"pray": PrayerBook.TAHORAH, "target": fallen, "extra": 0, "paid": 2, "owed": 0}, false)
	check(yoch.acts_available == 1, "Tahorah spends 1 ACT")
	check(fallen.burns.is_empty() and fallen.bleeds.is_empty() and not fallen.has_status(&"blind") and not fallen.has_status(&"snare"), "Tahorah clears burns, bleeds, and negative statuses")
	check(fallen.has_status(&"zohar"), "Tahorah preserves positive statuses (Zohar)")
	fallen.remove_status(&"zohar")

	# Magen: spends 2 ACT, gives +1 physical DEF stage to ALL living allies until end of next round
	var f_def0 := fallen.stats.defense
	var y_def0 := yoch.stats.defense
	yoch.acts_available = 2
	await b.prayer.execute(yoch, {"pray": PrayerBook.MAGEN, "target": yoch, "extra": 0, "paid": 2, "owed": 0}, false)
	check(yoch.acts_available == 0, "Magen spends 2 ACT")
	check(fallen.def_stages.size() == 1 and yoch.def_stages.size() == 1, "Magen buffs all living allies")
	check(fallen.effective_def() > f_def0 and yoch.effective_def() > y_def0, "effective_def() rises with Magen stage")
	SkillFx.tick(fallen)
	check(fallen.def_stages.size() == 1, "Magen lasts through the next round")
	SkillFx.tick(fallen)
	check(fallen.def_stages.is_empty() and fallen.effective_def() == f_def0, "Magen expires after the next round")

	# Gevurah: +15% + 5% per extra PP on next attack, consumed after attacking
	yoch.acts_available = 2
	await b.prayer.execute(yoch, {"pray": PrayerBook.GEVURAH, "target": fallen, "extra": 2, "paid": 3, "owed": 0}, false)
	check(yoch.acts_available == 1, "Gevurah spends 1 ACT")
	check(is_equal_approx(fallen.gevurah_bonus, 0.25), "Gevurah with +2 extra PP grants +25% bonus")
	check(is_equal_approx(SkillFx.out_mult(fallen), 1.25), "SkillFx.out_mult applies Gevurah bonus")
	SkillFx.consume_attack(fallen)
	check(is_equal_approx(fallen.gevurah_bonus, 0.0) and is_equal_approx(SkillFx.out_mult(fallen), 1.0), "Gevurah is consumed by the next attack")

	# Mishpat: spends 2 ACT, deals foe.last_damage_dealt + 15
	foe.stats.max_hp = 500
	foe.current_hp = 500
	foe.last_damage_dealt = 0
	yoch.acts_available = 2
	await b.prayer.execute(yoch, {"pray": PrayerBook.MISHPAT, "target": foe, "extra": 0, "paid": 2, "owed": 0}, false)
	check(yoch.acts_available == 0, "Mishpat spends 2 ACT")
	check(500 - foe.current_hp == 15, "Mishpat with 0 last damage deals 15 (%d)" % (500 - foe.current_hp))
	# Simulate foe dealing damage via _skill_hit, then cast Mishpat again
	fallen.stats.max_hp = 500
	fallen.current_hp = 500
	var foe_hit: int = b._skill_hit(foe, fallen, 10, false, R.POINT, R.MISS, false)
	check(foe.last_damage_dealt == foe_hit and foe_hit > 0, "Enemy damage is tracked in last_damage_dealt (%d)" % foe.last_damage_dealt)
	var hp_before := foe.current_hp
	yoch.acts_available = 2
	await b.prayer.execute(yoch, {"pray": PrayerBook.MISHPAT, "target": foe, "extra": 0, "paid": 2, "owed": 0}, false)
	check(hp_before - foe.current_hp == foe_hit + 15, "Mishpat deals foe.last_damage_dealt + 15 (%d vs %d)" % [hp_before - foe.current_hp, foe_hit + 15])

	# Zohar: spends 1 ACT, widens POINT zone until the end of the next round
	var base_half := BattleMath.unit_point_half(fallen, foe)
	yoch.acts_available = 2
	await b.prayer.execute(yoch, {"pray": PrayerBook.ZOHAR, "target": fallen, "extra": 0, "paid": 3, "owed": 0}, false)
	check(yoch.acts_available == 1, "Zohar spends 1 ACT")
	check(fallen.has_status(&"zohar"), "Zohar applies zohar status")
	var wide_half := BattleMath.unit_point_half(fallen, foe)
	check(wide_half > base_half and wide_half < BattleMath.BEAM_HALF_WIDTH, "Zohar widens POINT zone safely (%.3f > %.3f)" % [wide_half, base_half])
	# VFX checks: Tahorah, Magen, Gevurah (16-letter ring), Zohar, Mishpat all register and draw cleanly
	b.prayer.fx.play_tahorah(fallen)
	b.prayer.fx.play_magen([fallen, yoch])
	b.prayer.fx.play_gevurah(fallen)
	b.prayer.fx.play_zohar(fallen)
	var kinds: Array = b.prayer.fx.card_fx.map(func(e: Dictionary) -> StringName: return StringName(e.kind))
	check(kinds.has(&"tahorah") and kinds.has(&"magen") and kinds.has(&"gevurah") and kinds.has(&"zohar"), "All 4 card prayer VFX registered in PrayFX")
	var gev_list: Array = b.prayer.fx.card_fx.filter(func(e: Dictionary) -> bool: return StringName(e.kind) == &"gevurah")
	check(not gev_list.is_empty() and (gev_list[0].ring as Array).size() == 16, "Gevurah VFX uses a 16-letter ring")
	check(b.prayer.fx.m_crush.size() == 16 and b.prayer.fx.m_return.size() == 14, "Mishpat VFX built retribution arc and letter walls")
	b.prayer.fx.queue_redraw()
	await process_frame
	SkillFx.tick(fallen)
	check(fallen.has_status(&"zohar"), "Zohar lasts through the next round")
	SkillFx.tick(fallen)
	check(not fallen.has_status(&"zohar") and is_equal_approx(BattleMath.unit_point_half(fallen, foe), base_half), "Zohar expires after the next round")

	# D-107 prayers unified into PrayerBook (no duplicate DEFS in SkillBook), PrayerFlow, and PrayFX
	for id in [PrayerBook.SANVERIM, PrayerBook.NECHAMAH, PrayerBook.CHEREV]:
		check(PrayerBook.is_book_spell(id) and PrayerBook.is_prayer(id), "%s is unified in PrayerBook.SPELLS" % id)
		check(not SkillBook.DEFS.has(id) and not SkillBook.def(id).is_empty(), "%s is derived from PrayerBook (not duplicated in SkillBook.DEFS)" % id)
	var human_ally := SurvivalAllies.new_member("h_test", "human_s1_1", {"max_hp": 20, "max_en": 0, "atk": 6, "mak": 8, "defense": 6, "mef": 6, "agi": 6}, 42)
	check((human_ally.spells as Array).size() == 3 and (human_ally.skills as Array).is_empty(), "Recruited human gets all 3 prayers in PrayerBook spells, none in FIGHT skills")
	b.letter_fx.parts.clear()
	b.prayer.fx.card_fx.clear()
	foe.stats.max_hp = 500
	foe.current_hp = 500
	yoch.acts_available = 3
	await b.prayer.execute(yoch, {"pray": PrayerBook.SANVERIM, "target": foe, "extra": 0, "paid": 2, "owed": 0}, false)
	check(foe.has_status(&"blind"), "Sanverim via PrayerFlow blinds foe")
	await b.prayer.execute(yoch, {"pray": PrayerBook.NECHAMAH, "target": fallen, "extra": 0, "paid": 1, "owed": 0}, false)
	check(fallen.mends.size() >= 1, "Nechamah via PrayerFlow applies mend")
	await b.prayer.execute(yoch, {"pray": PrayerBook.CHEREV, "target": yoch, "extra": 0, "paid": 3, "owed": 0}, false)
	check(foe.current_hp < 500 and b.letter_fx.parts.is_empty(), "Cherev via PrayerFlow hits foes using PrayFX (no heat_hit fire)")
	var d107_kinds: Array = b.prayer.fx.card_fx.map(func(e: Dictionary) -> StringName: return StringName(e.kind))
	check(b.prayer.fx.s_curtains.size() == 20 and d107_kinds.has(&"nechamah") and b.prayer.fx.c_trail.size() == 30, "PrayFX drew Sanverim, Nechamah, and Cherev")
	b.letter_fx.parts.clear()
	b._magic_hit(foe, fallen, &"cherav", false, R.POINT, R.MISS)
	check(b.letter_fx.parts.is_empty(), "Enemy Cherev via _magic_hit uses PrayFX, never skill_letters.heat_hit")

	# D-113 guard: EVERY prayer in PrayerBook.SPELLS must have dedicated Hebrew-letter VFX in PrayFX
	var fx_node: Node2D = b.prayer.fx
	var is_hebrew := func(s: String) -> bool:
		if s.is_empty():
			return false
		for i in s.length():
			var cp := s.unicode_at(i)
			if cp < 0x0590 or cp > 0x05FF:
				return false
		return true
	check(is_hebrew.call(fx_node.ALPHABET) and fx_node.ALPHABET.length() == 22, "D-113: PrayFX.ALPHABET contains the 22 Hebrew letters")
	for mark in [fx_node.MARK_GLYPH, fx_node.MARK_MAGEN, fx_node.MARK_GEVURAH, fx_node.MARK_ZOHAR, fx_node.MARK_SANVERIM, fx_node.MARK_NECHAMAH]:
		check(is_hebrew.call(mark), "D-113: Persistent prayer mark '%s' is a valid Hebrew glyph" % mark)
	var d113_methods := {
		PrayerBook.REFUAH: &"play_refuah",
		PrayerBook.HAGANAH: &"_draw",
		PrayerBook.RAAM: &"play_raam",
		PrayerBook.SANVERIM: &"play_sanverim",
		PrayerBook.NECHAMAH: &"play_nechamah",
		PrayerBook.CHEREV: &"play_cherev",
		PrayerBook.TAHORAH: &"play_tahorah",
		PrayerBook.MAGEN: &"play_magen",
		PrayerBook.GEVURAH: &"play_gevurah",
		PrayerBook.MISHPAT: &"play_mishpat",
		PrayerBook.ZOHAR: &"play_zohar",
	}
	for spell_id in PrayerBook.SPELLS.keys():
		check(d113_methods.has(spell_id), "D-113: Prayer '%s' must be registered in the Hebrew VFX coverage map" % spell_id)
		if d113_methods.has(spell_id):
			var m: StringName = d113_methods[spell_id]
			check(fx_node.has_method(m), "D-113: PrayFX implements '%s' for prayer '%s'" % [m, spell_id])
	# Smoke-verify Refuah, Nechamah tick, and Ra'am also populate Hebrew VFX state cleanly
	fx_node.card_fx.clear()
	fx_node.play_refuah(fallen, 2)
	fx_node.play_nechamah_tick(fallen, 2)
	fx_node.play_raam(foe)
	var extra_kinds: Array = fx_node.card_fx.map(func(e: Dictionary) -> StringName: return StringName(e.kind))
	check(extra_kinds.has(&"refuah") and extra_kinds.has(&"nechamah_tick"), "D-113: Refuah and Nechamah tick register Hebrew VFX in PrayFX.card_fx")
	check(fx_node.raam_busy(), "D-113: Ra'am activates Hebrew lightning VFX in PrayFX")
	fx_node.queue_redraw()
	await process_frame

	# D-113 static source guard: PrayFX must stay 100% typographic (no geometric primitives or stroked borders)
	var fx_src := FileAccess.get_file_as_string("res://scripts/battle/pray_fx.gd")
	check(not fx_src.is_empty(), "D-113: pray_fx.gd source readable for static guard")
	var strip_comments := func(src: String) -> String:
		var out_lines: PackedStringArray = []
		for raw_line in src.split("\n"):
			var in_quote := ""
			var cut := raw_line.length()
			for i in raw_line.length():
				var ch := raw_line.substr(i, 1)
				if in_quote.is_empty():
					if ch == "\"" or ch == "'":
						in_quote = ch
					elif ch == "#":
						cut = i
						break
				elif ch == in_quote and (i == 0 or raw_line.substr(i - 1, 1) != "\\"):
					in_quote = ""
			out_lines.append(raw_line.substr(0, cut))
		return "\n".join(out_lines)
	var has_stroked_draw_rect := func(clean_src: String) -> bool:
		var idx := clean_src.find("draw_rect(")
		while idx >= 0:
			var depth := 0
			var arg_idx := 0
			var cur_arg := ""
			var in_q := ""
			for i in range(idx + 9, clean_src.length()):
				var ch := clean_src.substr(i, 1)
				if not in_q.is_empty():
					cur_arg += ch
					if ch == in_q and clean_src.substr(i - 1, 1) != "\\":
						in_q = ""
					continue
				if ch == "\"" or ch == "'":
					in_q = ch
					cur_arg += ch
				elif ch == "(":
					depth += 1
					if depth > 1:
						cur_arg += ch
				elif ch == ")":
					depth -= 1
					if depth == 0:
						if arg_idx == 2 and cur_arg.strip_edges() == "false":
							return true
						break
					cur_arg += ch
				elif ch == "," and depth == 1:
					if arg_idx == 2 and cur_arg.strip_edges() == "false":
						return true
					arg_idx += 1
					cur_arg = ""
				else:
					cur_arg += ch
			idx = clean_src.find("draw_rect(", idx + 10)
		return false
	var fx_clean: String = strip_comments.call(fx_src)
	var forbidden_draws: Array[String] = [
		"draw_circle(", "draw_arc(", "draw_line(", "draw_polyline(",
		"draw_polygon(", "draw_colored_polygon(", "draw_multiline(", "draw_dashed_line(",
	]
	for prim in forbidden_draws:
		check(not fx_clean.contains(prim), "D-113: pray_fx.gd must not use geometric primitive '%s'" % prim)
	check(not has_stroked_draw_rect.call(fx_clean), "D-113: pray_fx.gd must not draw stroked geometric borders with draw_rect(..., false)")
	# Self-test the stroked-rect detector on nested-paren and multi-line negative samples
	check(has_stroked_draw_rect.call(strip_comments.call("draw_rect(r, Color(\"#f5f58c\"), false, 2.0)")), "D-113 guard catches nested-paren draw_rect with hex color")
	check(has_stroked_draw_rect.call(strip_comments.call("draw_rect(\n\tr,\n\tColor(1, 1, 1),\n\tfalse\n)")), "D-113 guard catches multi-line stroked draw_rect")
	check(fx_clean.contains("draw_string("), "D-113: pray_fx.gd renders Hebrew glyphs via draw_string(")
	# D-113 BiDi/RTL guard: never concatenate Hebrew glyph with ASCII 'xN' suffix inside the same draw_string call
	var bidi_concat_re := RegEx.new()
	bidi_concat_re.compile("draw_string\\s*\\([^\\n]*(MARK_[A-Z_]+|[\\x{0590}-\\x{05FF}])[^\\n]*\\+\\s*\"x")
	check(bidi_concat_re.search(fx_clean) == null, "D-113: pray_fx.gd must not concatenate Hebrew glyphs with ASCII 'x' suffix in one draw_string")

	print("VERIFY_NEW_PRAYERS_OK: %d checks; D-112 Tahorah, Magen, Gevurah, Mishpat, Zohar + D-107 unified + D-113 Hebrew VFX guard" % checks)
	ProgressStore.clear()
	b.queue_free()
	await process_frame
	quit(0)
