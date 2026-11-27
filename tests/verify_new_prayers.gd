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
	for mark in [fx_node.MARK_GLYPH, fx_node.MARK_MAGEN, fx_node.MARK_GEVURAH, fx_node.MARK_ZOHAR, fx_node.MARK_SANVERIM, fx_node.MARK_NECHAMAH, fx_node.MARK_CHAKI, fx_node.MARK_SHACHAR, fx_node.MARK_LIOR]:
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
	var expected_shachar := PrayerBook.shachar_damage(yoch.stats.mak, foe.stats.mef, foe.affinity)
	check(foe.current_hp == hp_before_shachar - expected_shachar, "D-118 Shachar deals (30 + MAK - MEF) * affinity (%d) at start of next round (got %d)" % [expected_shachar, hp_before_shachar - foe.current_hp])
	check(not fx_node.shachar_pending and fx_node.shachar_rays.size() == 18, "D-118 Shachar clears pending mark and fires 18 Hebrew dawn rays")

	# D-118 Lehavah: 3 PP / 2 ACT, (40 + MAK - MEF) * affinity damage + blind + 3-color Hebrew VFX
	check(PrayerBook.base_cost(PrayerBook.LEHAVAH) == 3 and PrayerBook.act_cost(PrayerBook.LEHAVAH) == 2, "D-118 Lehavah: 3 PP / 2 ACT")
	foe.stats.max_hp = 500
	foe.current_hp = 500
	foe.remove_status(&"blind")
	foe.haganah = {}
	yoch.acts_available = 4
	await b.prayer.execute(yoch, {"pray": PrayerBook.LEHAVAH, "target": foe, "extra": 0, "paid": 3, "owed": 0}, false)
	var expected_lehavah := PrayerBook.lehavah_damage(yoch.stats.mak, foe.stats.mef, foe.affinity)
	check(500 - foe.current_hp == expected_lehavah, "D-118 Lehavah deals (40 + MAK - MEF) * affinity (%d, got %d)" % [expected_lehavah, 500 - foe.current_hp])
	check(foe.has_status(&"blind"), "D-118 Lehavah blinds target")
	check(yoch.acts_available == 2, "D-118 Lehavah spends 2 ACT")
	check(fx_node.lehavah_inward.size() == 28 and fx_node.lehavah_blast.size() == 48 and fx_node.lehavah_ring.size() == 20, "D-118 Lehavah builds spiral, 3-color blast, and blinding ring Hebrew VFX")
	foe.remove_status(&"blind")

	# D-118 Esh Sinai: 6 PP / 40 EN / 4 ACT, IMMEDIATE (30 - MEF) * affinity + 3 successive hits (never ignores defenses!)
	check(PrayerBook.base_cost(PrayerBook.ESH_SINAI) == 6 and PrayerBook.en_cost(PrayerBook.ESH_SINAI) == 40 and PrayerBook.act_cost(PrayerBook.ESH_SINAI) == 4, "D-118 Esh Sinai: 6 PP or 40 EN / 4 ACT")
	check(PrayerBook.is_immediate(PrayerBook.ESH_SINAI), "D-118 Esh Sinai is marked IMMEDIATE")
	check(fx_node.FIRE_PALETTE.size() == 3, "D-118 sacred fire uses 3-color palette (orange, yellow, white)")
	var orig_mef := foe.stats.mef
	var orig_aff := foe.affinity
	foe.stats.mef = 10
	foe.affinity = BattleMath.Affinity.RESIST
	foe.stats.max_hp = 500
	foe.current_hp = 500
	yoch.acts_available = 4
	await b.prayer.execute(yoch, {"pray": PrayerBook.ESH_SINAI, "target": foe, "extra": 0, "paid": 6, "owed": 0}, false)
	var expected_sinai_hit := PrayerBook.esh_sinai_hit_damage(10, BattleMath.Affinity.RESIST)
	check(expected_sinai_hit == 10 and 500 - foe.current_hp == 40, "D-118 Esh Sinai immediate + 3 hits respect MEF & affinity (10x4=40, got %d)" % (500 - foe.current_hp))
	check(yoch.acts_available == 0, "D-118 Esh Sinai spends 4 ACT")
	check(fx_node.esh_sinai_hits.size() == 4, "D-118 Esh Sinai schedules 4 fiery Hebrew-letter pillars")
	foe.stats.mef = orig_mef
	foe.affinity = orig_aff
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

	# D-118 Shalhevet: 4 PP / 3 ACT, (30 + MAK - MEF) * affinity fire wave on all living foes + 50% BURN
	check(PrayerBook.base_cost(PrayerBook.SHALHEVET) == 4 and PrayerBook.act_cost(PrayerBook.SHALHEVET) == 3, "D-118 Shalhevet: 4 PP / 3 ACT")
	for f in b.hud.opponents:
		(f as BattleUnit).stats.max_hp = 500
		(f as BattleUnit).current_hp = 500
		(f as BattleUnit).burns.clear()
		(f as BattleUnit).haganah = {}
	yoch.acts_available = 4
	await b.prayer.execute(yoch, {"pray": PrayerBook.SHALHEVET, "target": yoch, "extra": 0, "paid": 4, "owed": 0}, false)
	var expected_shalhevet := PrayerBook.shalhevet_damage(yoch.stats.mak, foe.stats.mef, foe.affinity)
	check(500 - foe.current_hp == expected_shalhevet and yoch.acts_available == 1, "D-118 Shalhevet hits all foes for (30 + MAK - MEF) * affinity (%d) and spends 3 ACT" % expected_shalhevet)
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
