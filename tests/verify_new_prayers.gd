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
	y.set_meta("spells", ["refuah", "haganah", "raam", "tahorah", "magen", "gevurah", "mishpat", "zohar", "sanverim", "nechamah", "cherav",
		"esh", "meir", "ur_esh", "seraf", "nitzotz", "esh_ochelet", "gever"])
	# Gabriel's skills (EN, no PP): the Fallen stands in for him in the tests.
	var g: BattleUnit = b.state.units[0]
	g.set_meta("spells", ["angel_hug", "gods_message", "adin", "ur_esh", "seraf", "nitzotz", "esh_ochelet", "gever", "esh"])
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
	for mark in [fx_node.MARK_MEIR, fx_node.MARK_GEVER, fx_node.MARK_ANGEL_HUG, fx_node.MARK_GODS_MESSAGE, fx_node.MARK_GLYPH, fx_node.MARK_MAGEN, fx_node.MARK_GEVURAH, fx_node.MARK_ZOHAR, fx_node.MARK_SANVERIM, fx_node.MARK_NECHAMAH, fx_node.MARK_CHAKI, fx_node.MARK_SHACHAR, fx_node.MARK_LIOR]:
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
		PrayerBook.CHAKI: &"play_chaki",
		PrayerBook.SHACHAR: &"play_shachar",
		PrayerBook.LEHAVAH: &"play_lehavah",
		PrayerBook.ESH_SINAI: &"play_esh_sinai",
		PrayerBook.HASNEH_HABOER: &"play_hasneh_haboer",
		PrayerBook.SHALHEVET: &"play_shalhevet",
		PrayerBook.NOGAH: &"play_nogah",
		PrayerBook.LIOR: &"play_lior",
		PrayerBook.ESH: &"play_esh",
		PrayerBook.MEIR: &"play_meir",
		PrayerBook.UR_ESH: &"play_ur_esh",
		PrayerBook.SERAF: &"play_seraf",
		PrayerBook.NITZOTZ: &"play_nitzotz",
		PrayerBook.ESH_OCHELET: &"play_esh_ochelet",
		PrayerBook.GEVER: &"play_gever",
		PrayerBook.ANGEL_HUG: &"play_angel_hug",
		PrayerBook.GODS_MESSAGE: &"play_gods_message",
		PrayerBook.ADIN: &"play_adin",
		PrayerBook.ADINA: &"play_adin",
		PrayerBook.ADINUT: &"play_adin",
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
	# D-118 Chaki & Shachar runtime mechanics + Hebrew VFX verification
	foe.current_hp = 500
	foe.acts_available = 2
	yoch.acts_available = 4
	await b.prayer.execute(yoch, {"pray": PrayerBook.CHAKI, "target": foe, "extra": 0, "paid": 3, "owed": 0}, false)
	check(foe.has_status(&"chaki") and foe.acts_available == 0, "D-118 Chaki binds foe and zeroes acts_available for the round")
	check(fx_node.chaki_busy() and fx_node.chaki_bars.size() == 6, "D-118 Chaki activates 6-column Hebrew light cage VFX")
	check(SkillFx.cleanse_all(foe) >= 1 and not foe.has_status(&"chaki"), "D-118 Chaki is cleanseable by Tahorah")
	foe.current_hp = 500
	var hp_before_shachar := foe.current_hp
	yoch.acts_available = 4
	await b.prayer.execute(yoch, {"pray": PrayerBook.SHACHAR, "target": yoch, "extra": 0, "paid": 3, "owed": 0}, false)
	check(fx_node.shachar_pending and fx_node.shachar_busy(), "D-118 Shachar queues dawn and plays cast arc VFX")
	check(foe.current_hp == hp_before_shachar, "D-118 Shachar does not deal damage before the next round")
	b.state.round_number += 1
	b.prayer.expire(yoch)
	var expected_shachar := PrayerBook.shachar_damage(yoch.stats.mak, foe.stats.mef)
	check(foe.current_hp == hp_before_shachar - expected_shachar, "D-118 Shachar deals (30 + MAK - MEF) (%d) at start of next round (got %d)" % [expected_shachar, hp_before_shachar - foe.current_hp])
	check(not fx_node.shachar_pending and fx_node.shachar_rays.size() == 18, "D-118 Shachar clears pending mark and fires 18 Hebrew dawn rays")

	# D-118 Lehavah: 3 PP / 2 ACT, (40 + MAK - MEF) damage + blind + 3-color Hebrew VFX
	check(PrayerBook.base_cost(PrayerBook.LEHAVAH) == 3 and PrayerBook.act_cost(PrayerBook.LEHAVAH) == 2, "D-118 Lehavah: 3 PP / 2 ACT")
	foe.stats.max_hp = 500
	foe.current_hp = 500
	foe.remove_status(&"blind")
	foe.haganah = {}
	yoch.acts_available = 4
	await b.prayer.execute(yoch, {"pray": PrayerBook.LEHAVAH, "target": foe, "extra": 0, "paid": 3, "owed": 0}, false)
	var expected_lehavah := PrayerBook.lehavah_damage(yoch.stats.mak, foe.stats.mef)
	check(500 - foe.current_hp == expected_lehavah, "D-118 Lehavah deals (40 + MAK - MEF) (%d, got %d)" % [expected_lehavah, 500 - foe.current_hp])
	check(foe.has_status(&"blind"), "D-118 Lehavah blinds target")
	check(yoch.acts_available == 2, "D-118 Lehavah spends 2 ACT")
	check(fx_node.lehavah_inward.size() == 28 and fx_node.lehavah_blast.size() == 48 and fx_node.lehavah_ring.size() == 20, "D-118 Lehavah builds spiral, 3-color blast, and blinding ring Hebrew VFX")
	foe.remove_status(&"blind")

	# D-118 Esh Sinai: 6 PP / 40 EN / 4 ACT, IMMEDIATE (30 - MEF) + 3 successive hits (never ignores defenses!)
	check(PrayerBook.base_cost(PrayerBook.ESH_SINAI) == 6 and PrayerBook.en_cost(PrayerBook.ESH_SINAI) == 40 and PrayerBook.act_cost(PrayerBook.ESH_SINAI) == 4, "D-118 Esh Sinai: 6 PP or 40 EN / 4 ACT")
	check(PrayerBook.is_immediate(PrayerBook.ESH_SINAI), "D-118 Esh Sinai is marked IMMEDIATE")
	check(fx_node.FIRE_PALETTE.size() == 3, "D-118 sacred fire uses 3-color palette (orange, yellow, white)")
	var orig_mef := foe.stats.mef
	foe.stats.mef = 10
	foe.stats.max_hp = 500
	foe.current_hp = 500
	yoch.acts_available = 4
	await b.prayer.execute(yoch, {"pray": PrayerBook.ESH_SINAI, "target": foe, "extra": 0, "paid": 6, "owed": 0}, false)
	var expected_sinai_hit := PrayerBook.esh_sinai_hit_damage(10)
	check(expected_sinai_hit == 20 and 500 - foe.current_hp == 80, "D-118 Esh Sinai immediate + 3 hits respect MEF (20x4=80, got %d)" % (500 - foe.current_hp))
	check(yoch.acts_available == 0, "D-118 Esh Sinai spends 4 ACT")
	check(fx_node.esh_sinai_hits.size() == 4, "D-118 Esh Sinai schedules 4 fiery Hebrew-letter pillars")
	foe.stats.mef = orig_mef
	# Early stop when target dies on hit 0
	foe.current_hp = 10
	yoch.acts_available = 4
	await b.prayer.execute(yoch, {"pray": PrayerBook.ESH_SINAI, "target": foe, "extra": 0, "paid": 6, "owed": 0}, false)
	check(not foe.is_alive() and fx_node.esh_sinai_max_hit == 0, "D-118 Esh Sinai stops follow-up hits if target falls on immediate strike")
	foe.current_hp = 500

	# D-118 Hasneh Habo'er: Gabriel 4 ACT / 30 EN, pre-checks EN before spending ACT, supports multiple 10 HP Burning Bushes
	check(PrayerBook.en_cost(PrayerBook.HASNEH_HABOER) == 30 and PrayerBook.act_cost(PrayerBook.HASNEH_HABOER) == 4, "D-118 Hasneh Habo'er: 30 EN / 4 ACT")
	fallen.stats.max_en = 90
	fallen.current_en = 10
	fallen.acts_available = 4
	b.prayer.burning_bushes.clear()
	fx_node.clear_hasneh_bushes()
	await b.prayer.execute(fallen, {"pray": PrayerBook.HASNEH_HABOER, "target": fallen, "extra": 0, "paid": 0, "owed": 0}, false)
	check(fallen.acts_available == 4 and b.prayer.living_burning_bushes().is_empty(), "D-118 Hasneh Habo'er does NOT spend ACTs when EN is insufficient")
	fallen.current_en = 75
	var units_before: int = b.state.units.size()
	var opps_before: int = b.hud.opponents.size()
	await b.prayer.execute(fallen, {"pray": PrayerBook.HASNEH_HABOER, "target": fallen, "extra": 0, "paid": 0, "owed": 0}, false)
	check(fallen.current_en == 45 and fallen.acts_available == 0, "D-118 Hasneh Habo'er spends 30 EN and 4 ACT")
	check(b.state.units.size() == units_before + 1 and b.hud.opponents.size() == opps_before + 1, "D-118 Hasneh Habo'er adds Burning Bush as a real extra enemy BattleUnit in BattleState and HUD opponents")
	var bush_u0: BattleUnit = b.hud.opponents[opps_before]
	check(not bush_u0.is_player and bush_u0.stats.max_hp == 10 and bush_u0.kind == &"burning_bush", "D-118 Burning Bush BattleUnit is an enemy summon with 10 HP")
	check(b.short_name(bush_u0) == "BURNING BUSH", "D-118 Burning Bush displays as BURNING BUSH in HUD/log (not generic FOE C)")
	fallen.stats.max_hp = 200
	fallen.current_hp = 200
	fallen.burns.clear()
	fallen.haganah = {}
	var ai_hit1: Dictionary = b.prayer.burning_bush_attack_unit(bush_u0, fallen)
	var ai_hit2: Dictionary = b.prayer.burning_bush_attack_unit(bush_u0, fallen)
	check(int(ai_hit1.damage) == 12 and bool(ai_hit1.burned) and int(ai_hit2.damage) == 24 and bool(ai_hit2.doubled), "D-118 Burning Bush AI attack_unit inflicts BURN and deals 2x (24) on burning target")
	fallen.burns.clear()
	fallen.acts_available = 4
	await b.prayer.execute(fallen, {"pray": PrayerBook.HASNEH_HABOER, "target": fallen, "extra": 0, "paid": 0, "owed": 0}, false)
	check(b.prayer.living_burning_bushes().size() == 2 and fx_node.hasneh_bushes.size() == 2 and fx_node.hasneh_hp == 20, "D-118 Hasneh Habo'er tracks and renders multiple simultaneous 10 HP Burning Bushes")
	foe.burns.clear()
	foe.haganah = {}
	foe.current_hp = 500
	var bush_hit1: Dictionary = b.prayer.burning_bush_attack(0, foe)
	check(int(bush_hit1.damage) == PrayerBook.HASNEH_BUSH_BASE_DAMAGE and not bool(bush_hit1.doubled) and bool(bush_hit1.burned) and not foe.burns.is_empty(), "D-118 Burning Bush first attack deals base damage (12) and inflicts BURN")
	var bush_hit2: Dictionary = b.prayer.burning_bush_attack(0, foe)
	check(int(bush_hit2.damage) == PrayerBook.HASNEH_BUSH_BASE_DAMAGE * 2 and bool(bush_hit2.doubled), "D-118 Burning Bush deals 2x damage (24) against an already burning target")
	# Direct combat damage on the BattleUnit extinguishes it and syncs VFX
	bush_u0.take_damage(10)
	fx_node._sync_hasneh_hp()
	check(not bush_u0.is_alive() and b.prayer.living_burning_bushes().size() == 1 and fx_node.hasneh_hp == 10, "Killing Burning Bush BattleUnit directly removes it from living bushes and updates VFX")
	var bush_dmg2: int = b.prayer.damage_burning_bush(1, 10)
	check(bush_dmg2 == 10 and b.prayer.living_burning_bushes().is_empty() and fx_node.hasneh_hp == 0, "Extinguishing all Burning Bushes clears VFX cleanly")
	# Remove test summons so subsequent AoE tests only see original foes
	b.hud.opponents.resize(opps_before)
	b.hud.silhouettes.resize(opps_before)
	b.state.units.resize(units_before)
	foe.burns.clear()
	# Lehavah respects Haganah (still deals damage, does not blind shielded foe)
	foe.haganah = {"round": b.state.round_number, "owner": yoch.id}
	foe.remove_status(&"blind")
	foe.current_hp = 500
	yoch.acts_available = 4
	await b.prayer.execute(yoch, {"pray": PrayerBook.LEHAVAH, "target": foe, "extra": 0, "paid": 3, "owed": 0}, false)
	check(foe.current_hp == 500 - expected_lehavah and not foe.has_status(&"blind"), "D-118 Lehavah respects Haganah shield (damage lands, blind blocked)")
	foe.haganah = {}

	# D-118 Shalhevet: 4 PP / 3 ACT, (30 + MAK - MEF) fire wave on all living foes + 50% BURN
	check(PrayerBook.base_cost(PrayerBook.SHALHEVET) == 4 and PrayerBook.act_cost(PrayerBook.SHALHEVET) == 3, "D-118 Shalhevet: 4 PP / 3 ACT")
	for f in b.hud.opponents:
		(f as BattleUnit).stats.max_hp = 500
		(f as BattleUnit).current_hp = 500
		(f as BattleUnit).burns.clear()
		(f as BattleUnit).haganah = {}
	yoch.acts_available = 4
	await b.prayer.execute(yoch, {"pray": PrayerBook.SHALHEVET, "target": yoch, "extra": 0, "paid": 4, "owed": 0}, false)
	var expected_shalhevet := PrayerBook.shalhevet_damage(yoch.stats.mak, foe.stats.mef)
	check(500 - foe.current_hp == expected_shalhevet and yoch.acts_available == 1, "D-118 Shalhevet hits all foes for (30 + MAK - MEF) (%d) and spends 3 ACT" % expected_shalhevet)
	check(fx_node.shalhevet_wave.size() == 110 and not fx_node.shalhevet_pillars.is_empty(), "D-118 Shalhevet builds 110-glyph fire wave and per-foe ember pillars")

	# D-118 Nogah: 2 PP / 3 ACT, blinds all living foes (respecting Haganah) + 24 starlight rays
	check(PrayerBook.base_cost(PrayerBook.NOGAH) == 2 and PrayerBook.act_cost(PrayerBook.NOGAH) == 3, "D-118 Nogah: 2 PP / 3 ACT")
	for f in b.hud.opponents:
		(f as BattleUnit).remove_status(&"blind")
		(f as BattleUnit).haganah = {}
	if b.hud.opponents.size() > 1:
		(b.hud.opponents[1] as BattleUnit).haganah = {"round": b.state.round_number, "owner": yoch.id}
	yoch.acts_available = 4
	await b.prayer.execute(yoch, {"pray": PrayerBook.NOGAH, "target": yoch, "extra": 0, "paid": 2, "owed": 0}, false)
	check(foe.has_status(&"blind") and yoch.acts_available == 1, "D-118 Nogah blinds unshielded foes and spends 3 ACT")
	if b.hud.opponents.size() > 1:
		check(not (b.hud.opponents[1] as BattleUnit).has_status(&"blind"), "D-118 Nogah respects Haganah shield on protected foe")
		(b.hud.opponents[1] as BattleUnit).haganah = {}
	check(fx_node.nogah_rays.size() == 24 and not fx_node.nogah_veils.is_empty(), "D-118 Nogah builds 24 starlight rays and per-foe blinding veils")
	for f in b.hud.opponents:
		(f as BattleUnit).remove_status(&"blind")

	# D-118 Lior: 2 PP / 1 ACT (+extra PP), heals 5 + 5/PP over 5 actions + 5 orbiting ליאור letters + persistent mark ל xN
	check(PrayerBook.base_cost(PrayerBook.LIOR) == 2 and PrayerBook.act_cost(PrayerBook.LIOR) == 1 and PrayerBook.accepts_extra_pp(PrayerBook.LIOR), "D-118 Lior: 2 PP / 1 ACT, accepts extra PP")
	check(PrayerBook.lior_heal(2) == 15 and PrayerBook.lior_heal(3) == 20, "D-118 Lior heals 5 + 5 per PP (15 at 2 PP, 20 at 3 PP)")
	yoch.stats.max_hp = 200
	yoch.current_hp = 50
	yoch.acts_available = 2
	await b.prayer.execute(yoch, {"pray": PrayerBook.LIOR, "target": yoch, "extra": 1, "paid": 3, "owed": 0}, false)
	var lior_st: Dictionary = b.prayer.lior_state(yoch)
	check(yoch.acts_available == 1 and int(lior_st.get("actions", 0)) == 5 and int(lior_st.get("heal", 0)) == 20, "D-118 Lior registers 5 actions at 20 HP (3 PP total) and spends 1 ACT")
	check(fx_node.lior_active.has(yoch) and (fx_node.lior_active[yoch].orbits as Array).size() == 5 and (fx_node.lior_active[yoch].shroud as Array).size() == 34, "D-118 Lior registers 34-letter shroud and 5 orbiting ליאור letters")
	var total_lior_healed := 0
	for _tick in 5:
		total_lior_healed += int(b.prayer.tick_lior(yoch))
	check(total_lior_healed == 100 and yoch.current_hp == 150, "D-118 Lior heals 20 HP across all 5 actions (100 HP total)")
	check(b.prayer.lior_state(yoch).is_empty() and not fx_node.lior_active.has(yoch), "D-118 Lior expires and clears VFX after 5th action")
	check(int(b.prayer.tick_lior(yoch)) == 0, "D-118 Lior does not heal after expiring")


	# ================= D-118 Lotes 2-4: Esh, Meir, Ur Esh, Seraf, Nitzotz, Esh Ochelet, Gever, Angel Hug, God's Message, Adin chain
	# ---- metadata
	var lote_meta := {
		PrayerBook.ESH: [1, 0, 2], PrayerBook.MEIR: [2, 0, 1], PrayerBook.UR_ESH: [3, 15, 2], PrayerBook.SERAF: [2, 10, 2],
		PrayerBook.NITZOTZ: [3, 15, 2], PrayerBook.ESH_OCHELET: [5, 30, 4], PrayerBook.GEVER: [4, 20, 3],
		PrayerBook.ANGEL_HUG: [0, 5, 2], PrayerBook.GODS_MESSAGE: [0, 5, 1], PrayerBook.ADIN: [0, 0, 2],
		PrayerBook.ADINA: [0, 0, 2], PrayerBook.ADINUT: [0, 0, 1],
	}
	for sid in lote_meta.keys():
		var row: Array = lote_meta[sid]
		check(PrayerBook.base_cost(sid) == int(row[0]) and PrayerBook.en_cost(sid) == int(row[1]) and PrayerBook.act_cost(sid) == int(row[2]),
			"D-118 %s costs PP %d / EN %d / ACT %d" % [sid, row[0], row[1], row[2]])
		check(String(PrayerBook.entry(sid).hebrew).length() > 0 and PrayerBook.is_prayer(sid), "D-118 %s is registered with Hebrew spelling" % sid)
	for sid in [PrayerBook.ESH_OCHELET, PrayerBook.ANGEL_HUG, PrayerBook.GODS_MESSAGE, PrayerBook.ADINUT]:
		check(PrayerBook.is_immediate(sid), "D-118 %s is IMMEDIATE" % sid)
	check(not PrayerBook.is_immediate(PrayerBook.ESH) and not PrayerBook.is_immediate(PrayerBook.ADIN), "D-118 Esh and Adin are not IMMEDIATE")
	check(PrayerBook.accepts_extra_pp(PrayerBook.ESH), "D-118 Esh accepts extra PP (BURN chance)")
	check(PrayerBook.uses_en(PrayerBook.UR_ESH, fallen) and not PrayerBook.uses_en(PrayerBook.UR_ESH, yoch), "D-118 angelic spells cost EN for non-praying units and PP for Yoch")
	check(PrayerBook.uses_en(PrayerBook.ANGEL_HUG, yoch), "D-118 Gabriel skills are EN-only")
	# ---- formulas
	check(PrayerBook.esh_damage(10, 3) == 27 and PrayerBook.esh_damage(0, 50) == 0, "D-118 Esh = 20 + MAK - MEF (floor 0)")
	check(PrayerBook.esh_burn_chance(0) == 30 and PrayerBook.esh_burn_chance(2) == 50 and PrayerBook.esh_burn_chance(9) == 100, "D-118 Esh BURN chance 30% +10% per extra PP (cap 100)")
	check(PrayerBook.ur_esh_damage(10, 3, false) == 27 and PrayerBook.ur_esh_damage(10, 3, true) == 67, "D-118 Ur Esh = 20 + MAK (+40 if burning) - MEF")
	check(PrayerBook.nitzotz_damage(5) == 15 and PrayerBook.esh_ochelet_damage(10) == 20 and PrayerBook.seraf_heal(12) == 12, "D-118 Nitzotz 20, Esh Ochelet 30 (MEF applies), Seraf heals MAK")
	check(PrayerBook.adin_recovery(PrayerBook.ADIN).en == 15 and PrayerBook.adin_recovery(PrayerBook.ADINA).hp == 25 and PrayerBook.adin_recovery(PrayerBook.ADINUT).en == 30, "D-118 Adin chain recovery 15 / 25+25 / 30+30")

	var lf: Node2D = b.prayer.fx
	for f in b.hud.opponents:
		var fu: BattleUnit = f
		fu.stats.max_hp = 900
		fu.current_hp = 900
		fu.burns.clear()
		fu.burn_power = 0
		fu.haganah = {}
		fu.statuses.clear()
		fu.paralyzed_acts = 0
		fu.atk_stages.clear()
	fallen.stats.max_hp = 500
	fallen.current_hp = 500
	fallen.stats.max_en = 120
	fallen.current_en = 120
	yoch.stats.max_hp = 200
	yoch.current_hp = 200
	var foe_mef := foe.stats.mef

	# ---- Esh: 2 ACT, 20 + MAK - MEF; extra PP 7 = 100% BURN; Haganah blocks BURN
	yoch.acts_available = 4
	await b.prayer.execute(yoch, {"pray": PrayerBook.ESH, "target": foe, "extra": 7, "paid": 8, "owed": 0}, false)
	check(900 - foe.current_hp == PrayerBook.esh_damage(yoch.stats.mak, foe_mef) and yoch.acts_available == 2, "D-118 Esh deals 20 + MAK - MEF and spends 2 ACT (%d)" % (900 - foe.current_hp))
	check(foe.burns.size() == 1, "D-118 Esh with 100% chance inflicts BURN")
	check(lf.d118.any(func(e: Dictionary) -> bool: return String(e.kind) == "esh"), "D-118 Esh registers its Hebrew arc VFX")
	foe.burns.clear()
	foe.haganah = {"round": b.state.round_number, "owner": yoch.id}
	yoch.acts_available = 4
	await b.prayer.execute(yoch, {"pray": PrayerBook.ESH, "target": foe, "extra": 7, "paid": 8, "owed": 0}, false)
	check(foe.burns.is_empty(), "D-118 Esh respects Haganah (no BURN)")
	foe.haganah = {}
	var burn_hits := 0
	for _t in 40:
		foe.burns.clear()
		yoch.acts_available = 4
		await b.prayer.execute(yoch, {"pray": PrayerBook.ESH, "target": foe, "extra": 0, "paid": 1, "owed": 0}, false)
		burn_hits += 1 if not foe.burns.is_empty() else 0
	check(burn_hits >= 3 and burn_hits <= 28, "D-118 Esh base BURN chance is ~30%% (%d/40)" % burn_hits)
	foe.current_hp = 900
	foe.burns.clear()

	# ---- Ur Esh: EN path for a non-praying unit; BURN guaranteed; +40 on a burning foe
	fallen.acts_available = 4
	fallen.current_en = 10
	await b.prayer.execute(fallen, {"pray": PrayerBook.UR_ESH, "target": foe, "extra": 0, "paid": 0, "owed": 0}, false)
	check(fallen.acts_available == 4 and foe.current_hp == 900 and fallen.current_en == 10, "D-118 Ur Esh with too little EN spends no ACT/EN and does nothing")
	fallen.current_en = 100
	await b.prayer.execute(fallen, {"pray": PrayerBook.UR_ESH, "target": foe, "extra": 0, "paid": 0, "owed": 0, "en_paid": true}, false)
	check(fallen.current_en == 85 and fallen.acts_available == 2, "D-118 Ur Esh costs 15 EN and 2 ACT")
	check(900 - foe.current_hp == PrayerBook.ur_esh_damage(fallen.stats.mak, foe_mef, false) and foe.burns.size() == 1, "D-118 Ur Esh deals 20 + MAK - MEF and ignites (%d)" % (900 - foe.current_hp))
	var hp_pre_ur := foe.current_hp
	fallen.acts_available = 4
	await b.prayer.execute(fallen, {"pray": PrayerBook.UR_ESH, "target": foe, "extra": 0, "paid": 0, "owed": 0, "en_paid": true}, false)
	check(hp_pre_ur - foe.current_hp == PrayerBook.ur_esh_damage(fallen.stats.mak, foe_mef, true), "D-118 Ur Esh deals +40 on an already burning foe (%d)" % (hp_pre_ur - foe.current_hp))
	check(foe.burns.size() == 2, "D-118 Ur Esh adds a BURN every cast")
	check(lf.d118.any(func(e: Dictionary) -> bool: return String(e.kind) == "ur_esh"), "D-118 Ur Esh registers its golden evolution VFX")

	# ---- Nitzotz: needs a burning foe; 20 - MEF; BURN rises to 10 per round
	foe.current_hp = 900
	foe.burns.clear()
	foe.burn_power = 0
	fallen.acts_available = 4
	fallen.current_en = 100
	await b.prayer.execute(fallen, {"pray": PrayerBook.NITZOTZ, "target": foe, "extra": 0, "paid": 0, "owed": 0, "en_paid": true}, false)
	check(foe.current_hp == 900 and fallen.acts_available == 4 and fallen.current_en == 100, "D-118 Nitzotz on a foe that is not burning costs nothing and does nothing")
	foe.burns.append(3)
	await b.prayer.execute(fallen, {"pray": PrayerBook.NITZOTZ, "target": foe, "extra": 0, "paid": 0, "owed": 0, "en_paid": true}, false)
	check(900 - foe.current_hp == PrayerBook.nitzotz_damage(foe_mef) and fallen.current_en == 85 and fallen.acts_available == 2, "D-118 Nitzotz deals 20 - MEF for 15 EN / 2 ACT (%d)" % (900 - foe.current_hp))
	check(foe.burn_power == 10 and foe.burn_round_damage() == 10, "D-118 Nitzotz raises BURN to 10 per round")
	var hp_pre_burn := foe.current_hp
	await b._burn_tick()
	check(hp_pre_burn - foe.current_hp == 10, "D-118 the round's BURN tick deals 10 after Nitzotz (%d)" % (hp_pre_burn - foe.current_hp))
	foe.burns.clear()
	foe.burns.append(1)
	await b._burn_tick()
	check(foe.burn_power == 0 and foe.burns.is_empty(), "D-118 superheated BURN resets when the burns end")
	foe.burns.append(3)
	foe.burn_power = 10
	SkillFx.cleanse_all(foe)
	check(foe.burn_power == 0 and foe.burns.is_empty(), "D-118 Tahorah-style cleanse also removes the superheat")

	# ---- Meir: taunt until the end of the round
	yoch.acts_available = 4
	await b.prayer.execute(yoch, {"pray": PrayerBook.MEIR, "target": yoch, "extra": 0, "paid": 2, "owed": 0}, false)
	check(yoch.acts_available == 3 and yoch.has_status(&"taunt") and SkillFx.taunter([fallen, yoch]) == yoch, "D-118 Meir spends 1 ACT and makes Yoch the only valid target")
	check(lf.d118.any(func(e: Dictionary) -> bool: return String(e.kind) == "meir"), "D-118 Meir registers the provocation VFX")
	SkillFx.tick(yoch)
	check(not yoch.has_status(&"taunt"), "D-118 Meir ends with the round")

	# ---- Seraf: heal MAK + 20 SP
	yoch.current_hp = 50
	var sp_pre := yoch.current_sp
	yoch.acts_available = 4
	await b.prayer.execute(yoch, {"pray": PrayerBook.SERAF, "target": yoch, "extra": 0, "paid": 2, "owed": 0}, false)
	check(yoch.current_hp == 50 + PrayerBook.seraf_heal(yoch.stats.mak) and yoch.current_sp == sp_pre + 20 and yoch.acts_available == 2, "D-118 Seraf heals MAK, grants +20 SP, 2 ACT (HP %d, SP +%d)" % [yoch.current_hp, yoch.current_sp - sp_pre])

	# ---- Gever: +4 ATK stages
	var atk0 := yoch.effective_atk()
	yoch.acts_available = 4
	await b.prayer.execute(yoch, {"pray": PrayerBook.GEVER, "target": yoch, "extra": 0, "paid": 4, "owed": 0}, false)
	check(yoch.atk_stages.size() == 4 and yoch.acts_available == 1 and is_equal_approx(yoch.effective_atk(), float(yoch.stats.atk) * 2.0) and yoch.effective_atk() > atk0, "D-118 Gever adds 4 ATK stages (x2.0) for 3 ACT")
	yoch.atk_stages.clear()

	# ---- Esh Ochelet: IMMEDIATE mark, 30 magic damage per action in the foe's next turn, never interrupts
	foe.current_hp = 900
	fallen.acts_available = 4
	fallen.current_en = 100
	await b.prayer.execute(fallen, {"pray": PrayerBook.ESH_OCHELET, "target": foe, "extra": 0, "paid": 0, "owed": 0, "en_paid": true}, false)
	check(fallen.current_en == 70 and fallen.acts_available == 0 and foe.current_hp == 900 and b.prayer.is_ochelet_marked(foe), "D-118 Esh Ochelet costs 30 EN / 4 ACT, deals nothing at once and marks the foe")
	var o1: int = b.prayer.tick_ochelet(foe)
	var o2: int = b.prayer.tick_ochelet(foe)
	check(o1 == PrayerBook.esh_ochelet_damage(foe_mef) and o2 == o1 and 900 - foe.current_hp == o1 * 2, "D-118 Esh Ochelet bites 30 - MEF per foe action (%d each)" % o1)
	check(lf.d118.any(func(e: Dictionary) -> bool: return String(e.kind) == "ochelet_bite"), "D-118 Esh Ochelet registers its bite VFX")
	b.prayer.turn_end(foe)
	check(not b.prayer.is_ochelet_marked(foe) and int(b.prayer.tick_ochelet(foe)) == 0, "D-118 Esh Ochelet ends with the foe's turn")

	# ---- Angel Hug: IMMEDIATE, 3 acts lost (current + next round), Haganah blocks
	foe.acts_available = 2
	fallen.acts_available = 4
	fallen.current_en = 100
	await b.prayer.execute(fallen, {"pray": PrayerBook.ANGEL_HUG, "target": foe, "extra": 0, "paid": 0, "owed": 0, "en_paid": true}, false)
	check(fallen.current_en == 95 and fallen.acts_available == 2, "D-118 Angel Hug costs 5 EN / 2 ACT")
	check(foe.acts_available == 0 and foe.paralyzed_acts == 1 and foe.has_status(&"paralyzed"), "D-118 Angel Hug strips the 2 acts the foe has and owes 1 more")
	foe.acts_available = 4
	b.prayer.round_start()
	check(foe.acts_available == 3 and foe.paralyzed_acts == 0 and not foe.has_status(&"paralyzed"), "D-118 the remaining paralysis takes 1 act at the next round start")
	foe.acts_available = 4
	foe.haganah = {"round": b.state.round_number, "owner": yoch.id}
	fallen.acts_available = 4
	await b.prayer.execute(fallen, {"pray": PrayerBook.ANGEL_HUG, "target": foe, "extra": 0, "paid": 0, "owed": 0, "en_paid": true}, false)
	check(foe.acts_available == 4 and foe.paralyzed_acts == 0, "D-118 Haganah blocks Angel Hug")
	foe.haganah = {}
	foe.acts_available = 4
	fallen.acts_available = 4
	await b.prayer.execute(fallen, {"pray": PrayerBook.ANGEL_HUG, "target": foe, "extra": 0, "paid": 0, "owed": 0, "en_paid": true}, false)
	check(foe.acts_available == 1 and foe.paralyzed_acts == 0, "D-118 Angel Hug removes 3 of 4 acts at once")
	check(lf.d118.any(func(e: Dictionary) -> bool: return String(e.kind) == "angel_hug"), "D-118 Angel Hug registers its wing-clap VFX")
	foe.paralyzed_acts = 2
	SkillFx.apply_status(foe, &"paralyzed", 4)
	check(SkillFx.cleanse_all(foe) >= 1 and foe.paralyzed_acts == 0, "D-118 Tahorah-style cleanse lifts paralysis")

	# ---- God's Message: IMMEDIATE mark; next turn -3 stages (3 x 25%) of a random stat until the round ends
	fallen.acts_available = 4
	fallen.current_en = 100
	await b.prayer.execute(fallen, {"pray": PrayerBook.GODS_MESSAGE, "target": foe, "extra": 0, "paid": 0, "owed": 0, "en_paid": true}, false)
	check(fallen.current_en == 95 and fallen.acts_available == 3 and foe.has_status(&"gods_message"), "D-118 God's Message costs 5 EN / 1 ACT and marks the foe")
	var stats_before := {"atk": foe.stats.atk, "defense": foe.stats.defense, "mak": foe.stats.mak, "mef": foe.stats.mef, "agi": foe.stats.agi}
	b.prayer.expire(foe)
	var lowered := 0
	for key in stats_before.keys():
		if int(foe.stats.get(String(key))) < int(stats_before[key]):
			lowered += 1
	check(not foe.has_status(&"gods_message") and foe.has_status(&"gm_debuff") and lowered == 1, "D-118 God's Message lowers exactly one random stat on the foe's next turn")
	SkillFx.tick(foe)
	var restored := true
	for key in stats_before.keys():
		restored = restored and int(foe.stats.get(String(key))) == int(stats_before[key])
	check(restored and not foe.has_status(&"gm_debuff"), "D-118 God's Message penalty ends with the round and restores the stat")
	check(lf.d118.any(func(e: Dictionary) -> bool: return String(e.kind) == "gm_fulfil") and lf.d118.any(func(e: Dictionary) -> bool: return String(e.kind) == "gods_message"), "D-118 God's Message registers scroll and fulfilment VFX")

	# ---- Adin -> Adina -> Adinut evolve one step per round
	fallen.current_hp = 100
	fallen.current_en = 10
	fallen.stats.max_en = 120
	b.prayer._build_menu(0, [], 4, fallen)
	check(b.prayer.menu_ids.has(PrayerBook.ADIN) and not b.prayer.menu_ids.has(PrayerBook.ADINA), "D-118 the menu shows Adin first")
	fallen.acts_available = 4
	await b.prayer.execute(fallen, {"pray": PrayerBook.ADIN, "target": fallen, "extra": 0, "paid": 0, "owed": 0}, false)
	check(fallen.current_en == 25 and fallen.current_hp == 100 and fallen.acts_available == 2, "D-118 Adin recovers 15 EN for 2 ACT and no HP")
	b.prayer._build_menu(0, [], 4, fallen)
	check(b.prayer.menu_ids.has(PrayerBook.ADIN) and not b.prayer.menu_ids.has(PrayerBook.ADINA), "D-118 Adin does not evolve in the same round")
	b.state.round_number += 1
	b.prayer._build_menu(0, [], 4, fallen)
	check(b.prayer.menu_ids.has(PrayerBook.ADINA) and not b.prayer.menu_ids.has(PrayerBook.ADIN), "D-118 next round Adin becomes Adina in the menu")
	fallen.acts_available = 4
	await b.prayer.execute(fallen, {"pray": PrayerBook.ADINA, "target": fallen, "extra": 0, "paid": 0, "owed": 0}, false)
	check(fallen.current_en == 50 and fallen.current_hp == 125 and fallen.acts_available == 2, "D-118 Adina recovers 25 EN + 25 HP")
	b.state.round_number += 1
	b.prayer._build_menu(0, [], 4, fallen)
	check(b.prayer.menu_ids.has(PrayerBook.ADINUT) and not b.prayer.menu_ids.has(PrayerBook.ADINA), "D-118 next round Adina becomes Adinut")
	fallen.acts_available = 4
	await b.prayer.execute(fallen, {"pray": PrayerBook.ADINUT, "target": fallen, "extra": 0, "paid": 0, "owed": 0}, false)
	check(fallen.current_en == 80 and fallen.current_hp == 155 and fallen.acts_available == 3, "D-118 Adinut recovers 30 EN + 30 HP for 1 ACT")
	b.state.round_number += 3
	b.prayer._build_menu(0, [], 4, fallen)
	check(b.prayer.menu_ids.has(PrayerBook.ADINUT), "D-118 Adinut is the end of the chain")
	# Esh -> Ur Esh only for a unit that knows Ur Esh (Gabriel's meta does)
	fallen.acts_available = 4
	fallen.current_en = 100
	foe.current_hp = 900
	await b.prayer.execute(fallen, {"pray": PrayerBook.ESH, "target": foe, "extra": 0, "paid": 0, "owed": 0}, false)
	b.state.round_number += 1
	b.prayer._build_menu(0, [], 4, fallen)
	check(b.prayer.menu_ids.has(PrayerBook.UR_ESH) and not b.prayer.menu_ids.has(PrayerBook.ESH), "D-118 Esh becomes Ur Esh in the round after its use (no duplicate entry)")

	# ---- Hebrew VFX smoke test: draw every new effect at several ages (draw errors would abort the run)
	lf.d118.clear()
	lf.play_esh(fallen, foe, true)
	lf.play_ur_esh(fallen, foe, true)
	lf.play_meir(yoch, b.hud.opponents)
	lf.play_seraf(yoch, 20)
	lf.play_nitzotz(yoch, foe)
	lf.play_esh_ochelet(foe)
	lf.play_ochelet_bite(foe)
	lf.play_gever(yoch)
	lf.play_angel_hug(fallen, yoch, true)
	lf.play_gods_message(fallen, yoch, true)
	lf.play_gods_message_fulfilled(yoch, "ATK")
	lf.play_adin(fallen, 0)
	lf.play_adin(fallen, 1)
	lf.play_adin(fallen, 2)
	check(lf.d118.size() == 14 and lf.d118_busy(), "D-118 all 14 Hebrew VFX registered")
	for age in [0.05, 0.3, 0.6, 0.9, 1.4, 2.0, 2.6]:
		for e in lf.d118:
			e.at = lf.time - float(age)
		lf.queue_redraw()
		await process_frame
	check(lf._d118_shake() >= 0.0, "D-118 shake layer evaluates cleanly")
	for u in [foe, yoch]:
		u.statuses.clear()
		u.paralyzed_acts = 0
	yoch.paralyzed_acts = 2
	SkillFx.apply_status(yoch, &"gods_message", 3)
	yoch.atk_stages.append({"round": 1, "owner": yoch.id})
	SkillFx.apply_status(yoch, &"taunt", 1)
	SkillFx.apply_status(foe, &"ochelet", 2)
	lf.queue_redraw()
	await process_frame
	yoch.paralyzed_acts = 0
	yoch.statuses.clear()
	yoch.atk_stages.clear()
	foe.statuses.clear()
	lf.d118.clear()
	await process_frame

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

	print("VERIFY_NEW_PRAYERS_OK: %d checks; D-112 Tahorah, Magen, Gevurah, Mishpat, Zohar + D-107 unified + D-118 lotes 1-4 + D-113 Hebrew VFX guard" % checks)
	ProgressStore.clear()
	b.queue_free()
	await process_frame
	quit(0)
