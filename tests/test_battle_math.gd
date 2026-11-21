extends GutTest

var _rng: RandomNumberGenerator

func before_each() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 12345


func test_sp_is_sum_of_seven_stats() -> void:
	var stats := UnitStats.new()
	stats.max_hp = 14
	stats.max_en = 8
	stats.atk = 7
	stats.mak = 3
	stats.defense = 5
	stats.mef = 3
	stats.agi = 6
	assert_eq(stats.sp_value(), 46)


func test_crit_chance_uses_agi_and_sp_difference() -> void:
	assert_almost_eq(BattleMath.crit_chance(6, 0), 6.0, 0.001)
	assert_almost_eq(BattleMath.crit_chance(6, 2), 26.0, 0.001)
	assert_almost_eq(BattleMath.crit_chance(6, -3), 6.0, 0.001)


func test_rhythm_duration_is_bounded() -> void:
	assert_almost_eq(BattleMath.rhythm_duration(6, 4, 20, 10), 0.4, 0.001)
	assert_almost_eq(BattleMath.rhythm_duration(100, 1, 100, 1), 0.2, 0.001)
	assert_almost_eq(BattleMath.rhythm_duration(1, 100, 1, 100), 1.0, 0.001)


func test_rhythm_zones() -> void:
	assert_eq(BattleMath.rhythm_zone(0.5), BattleMath.RhythmResult.POINT)
	assert_eq(BattleMath.rhythm_zone(0.45), BattleMath.RhythmResult.POINT)
	assert_eq(BattleMath.rhythm_zone(0.60), BattleMath.RhythmResult.BEAM)
	assert_eq(BattleMath.rhythm_zone(0.10), BattleMath.RhythmResult.MISS)


func test_physical_damage_uses_ratio_and_affinity() -> void:
	var result: Dictionary = BattleMath.physical_damage(100, 10, 6, 5, 10, 5,
		BattleMath.Affinity.NORMAL, _rng)
	assert_gt(int(result.amount), 0)
	assert_eq(int(result.base), 200)

	var nullified: Dictionary = BattleMath.physical_damage(100, 10, 6, 5, 10, 5,
		BattleMath.Affinity.NULL, _rng)
	assert_eq(int(nullified.amount), 0)


func test_press_turn_act_delta() -> void:
	assert_eq(BattleMath.press_turn_acts(BattleMath.Affinity.WEAK), 1)
	assert_eq(BattleMath.press_turn_acts(BattleMath.Affinity.RESIST), -1)
	assert_eq(BattleMath.press_turn_acts(BattleMath.Affinity.NULL), -1)
	assert_eq(BattleMath.press_turn_acts(BattleMath.Affinity.NORMAL), 0)


func test_extra_block_rolls() -> void:
	assert_eq(BattleMath.extra_block_rolls(0), 0)
	assert_eq(BattleMath.extra_block_rolls(2), 1)
	assert_eq(BattleMath.extra_block_rolls(5), 2)


func test_critical_chance_positive_negative_and_zero_sp_gap() -> void:
	assert_almost_eq(BattleMath.crit_chance(6, 0), 6.0, 0.001)
	assert_almost_eq(BattleMath.crit_chance(6, 2), 26.0, 0.001)
	assert_almost_eq(BattleMath.crit_chance(6, -3), 6.0, 0.001)
	assert_almost_eq(BattleMath.crit_chance(1000, 100), 100.0, 0.001)


func test_critical_sp_bonus_is_capped_at_thirty_points() -> void:
	assert_almost_eq(BattleMath.crit_chance(6, 3), 36.0, 0.001)
	assert_almost_eq(BattleMath.crit_chance(6, 10), 36.0, 0.001)
	assert_almost_eq(BattleMath.crit_chance(6, 100), 36.0, 0.001)
	assert_almost_eq(BattleMath.crit_chance(0, 2), 20.0, 0.001)
	assert_almost_eq(BattleMath.crit_chance(0, -5), 0.0, 0.001)


func test_point_against_point_gives_no_contact() -> void:
	var p := BattleMath.RhythmResult.POINT
	var b := BattleMath.RhythmResult.BEAM
	var m := BattleMath.RhythmResult.MISS
	assert_false(BattleMath.has_contact(p, p), "defense prevails on POINT vs POINT")
	assert_true(BattleMath.has_contact(p, b))
	assert_true(BattleMath.has_contact(p, m))
	assert_false(BattleMath.has_contact(b, p))
	assert_true(BattleMath.has_contact(b, b))
	assert_false(BattleMath.has_contact(m, b))


func test_critical_roll_is_deterministic_with_seed() -> void:
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 777
	b.seed = 777
	assert_eq(BattleMath.critical_roll(6, 46, 35, a),
		BattleMath.critical_roll(6, 46, 35, b))


func test_sp_roll_sign_follows_superiority() -> void:
	var stronger := BattleMath.physical_damage(100, 10, 6, 5, 40, 10,
		BattleMath.Affinity.NORMAL, _rng)
	assert_gt(int(stronger.sp_roll), 0)
	var weaker := BattleMath.physical_damage(100, 10, 6, 5, 10, 40,
		BattleMath.Affinity.NORMAL, _rng)
	assert_lt(int(weaker.sp_roll), 0)
	var equal := BattleMath.physical_damage(100, 10, 6, 5, 20, 20,
		BattleMath.Affinity.NORMAL, _rng)
	assert_eq(int(equal.sp_roll), 0)


func test_affinity_interacts_with_damage() -> void:
	var weak := BattleMath.physical_damage(100, 10, 6, 5, 20, 20,
		BattleMath.Affinity.WEAK, _rng)
	var resist := BattleMath.physical_damage(100, 10, 6, 5, 20, 20,
		BattleMath.Affinity.RESIST, _rng)
	assert_gt(int(weak.amount), int(resist.amount))


func test_dominance_ratio_requires_seventy_percent_share() -> void:
	assert_almost_eq(BattleMath.dominance_ratio(20, 20), 0.5, 0.001)
	assert_almost_eq(BattleMath.dominance_ratio(46, 45), 0.5056, 0.001)
	assert_almost_eq(BattleMath.dominance_ratio(60, 10), 0.8571, 0.001)
	assert_almost_eq(BattleMath.dominance_ratio(10, 60), 0.1429, 0.001)
	assert_almost_eq(BattleMath.dominance_ratio(0, 0), 0.0, 0.001)


func test_press_turn_uses_contact_semantics() -> void:
	# The formula itself is unchanged; the controller applies it only on contact.
	assert_eq(BattleMath.press_turn_acts(BattleMath.Affinity.WEAK), 1)
	assert_eq(BattleMath.press_turn_acts(BattleMath.Affinity.NULL), -1)
