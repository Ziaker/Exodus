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
	assert_almost_eq(BattleMath.crit_chance(6, -3), 0.0, 0.001)


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
