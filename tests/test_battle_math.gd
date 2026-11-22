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
	assert_almost_eq(BattleMath.crit_chance(6, 2), 10.0, 0.001)
	assert_almost_eq(BattleMath.crit_chance(6, -3), 6.0, 0.001)


func test_rhythm_duration_is_fixed_at_one_second() -> void:
	assert_almost_eq(BattleMath.rhythm_duration(6, 4, 20, 10), 1.0, 0.001)
	assert_almost_eq(BattleMath.rhythm_duration(100, 1, 100, 1), 1.0, 0.001)
	assert_almost_eq(BattleMath.rhythm_duration(1, 100, 1, 100), 1.0, 0.001)


func test_point_width_uses_agi_advantage_and_sp_bands() -> void:
	# Creator decision D-033: +1 p.p. of POINT per AGI advantage, SP keeps D-021.
	assert_almost_eq(BattleMath.point_half_width(10, 5, 20, 20), 0.075, 0.001)
	assert_almost_eq(BattleMath.point_half_width(5, 5, 20, 20), 0.05, 0.001)
	assert_almost_eq(BattleMath.point_half_width(6, 10, 20, 20), 0.05, 0.001)
	assert_almost_eq(BattleMath.point_half_width(5, 5, 25, 20), 0.055, 0.001)
	assert_almost_eq(BattleMath.point_half_width(5, 5, 40, 20), 0.06, 0.001)


func test_point_width_is_bounded_and_changes_the_zone() -> void:
	assert_almost_eq(BattleMath.point_half_width(100, 0, 20, 20), 0.08, 0.001)
	assert_almost_eq(BattleMath.point_half_width(0, 100, 0, 100), 0.04, 0.001)
	assert_eq(BattleMath.rhythm_zone(0.44, 0.075), BattleMath.RhythmResult.POINT)
	assert_eq(BattleMath.rhythm_zone(0.42, 0.075), BattleMath.RhythmResult.BEAM)


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
	assert_almost_eq(BattleMath.crit_chance(6, 2), 10.0, 0.001)
	assert_almost_eq(BattleMath.crit_chance(6, -3), 6.0, 0.001)
	assert_almost_eq(BattleMath.crit_chance(1000, 100), 50.0, 0.001)


func test_critical_uses_d021_bonus_and_final_caps() -> void:
	assert_almost_eq(BattleMath.crit_chance(6, 3), 12.0, 0.001)
	assert_almost_eq(BattleMath.crit_chance(6, 10), 26.0, 0.001)
	assert_almost_eq(BattleMath.crit_chance(6, 100), 26.0, 0.001)
	assert_almost_eq(BattleMath.crit_chance(0, 2), 4.0, 0.001)
	assert_almost_eq(BattleMath.crit_chance(0, -5), 0.0, 0.001)
	assert_almost_eq(BattleMath.crit_chance(40, 10), 50.0, 0.001)


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


## D-049: counter-attack exchange rules.
func test_counter_better_result_interrupts_and_steals_four() -> void:
	var R := BattleMath.RhythmResult
	var o := BattleMath.resolve_counter(R.POINT, R.BEAM)
	assert_eq(o.winner, BattleMath.CounterWinner.PLAYER)
	assert_eq(o.steal, BattleMath.INTERRUPT_SP_NORMAL)
	o = BattleMath.resolve_counter(R.MISS, R.BEAM)
	assert_eq(o.winner, BattleMath.CounterWinner.ENEMY)
	assert_false(o.perfect)


func test_counter_equal_results_tie_without_theft() -> void:
	var R := BattleMath.RhythmResult
	for r in [R.POINT, R.BEAM, R.MISS]:
		var o := BattleMath.resolve_counter(r, r)
		assert_eq(o.winner, BattleMath.CounterWinner.TIE)
		assert_eq(o.steal, 0)


func test_counter_perfect_press_wins_as_point_and_steals_sixteen() -> void:
	var R := BattleMath.RhythmResult
	var o := BattleMath.resolve_counter(R.MISS, R.POINT, false, true)
	assert_eq(o.winner, BattleMath.CounterWinner.ENEMY)
	assert_true(o.perfect)
	assert_eq(o.steal, 16)
	assert_eq(o.enemy_timing, R.POINT)


func test_counter_red_pointer_speed_follows_agi_ratio() -> void:
	assert_almost_eq(BattleMath.counter_red_duration(1.0, 6, 6), 1.0, 0.0001)
	assert_almost_eq(BattleMath.counter_red_duration(1.0, 4, 6), 1.5, 0.0001)
	assert_almost_eq(BattleMath.counter_red_duration(1.0, 12, 6), 0.5, 0.0001)
	assert_true(BattleMath.pointers_aligned(0.4, 0.42))
	assert_false(BattleMath.pointers_aligned(0.4, 0.425))


## D-051: absorption as an SP dispute.
func test_absorb_press_moves_two_sp_and_adds_one_percent_per_sp() -> void:
	var step := BattleMath.absorb_press(30, 11, 0, 99.0)
	assert_eq(step.steal, 2)
	assert_eq(step.taken, 2)
	assert_eq(step.chance, 13)
	assert_false(step.absorbed)
	step = BattleMath.absorb_press(28, 11, 2, 14.9)
	assert_eq(step.chance, 15)
	assert_true(step.absorbed, "a roll under the chance absorbs")


func test_absorb_press_negative_gap_is_zero_and_drain_is_guaranteed() -> void:
	var step := BattleMath.absorb_press(50, -40, 0, 1.0)
	assert_eq(step.chance, 2, "a negative SP gap counts as 0%")
	assert_true(step.absorbed)
	step = BattleMath.absorb_press(2, 0, 18, 99.9)
	assert_true(step.absorbed, "draining the target to 0 SP absorbs for sure")
	step = BattleMath.absorb_press(1, 0, 18, 99.9)
	assert_eq(step.steal, 1, "only the SP the target still has can be taken")
	assert_true(step.absorbed)


func test_absorb_gain_options_follow_multiples_of_eight() -> void:
	var stats := UnitStats.new()
	stats.max_hp = 16
	stats.max_en = 8
	stats.atk = 6
	stats.mak = 3
	stats.defense = 2
	stats.mef = 8
	stats.agi = 3
	var options := BattleMath.absorb_gain_options(stats)
	assert_eq(options.size(), 1, "HP and EN never count; MEF 8 is the only eligible stat")
	assert_eq(options[0].gains, {&"mef": 2})
	stats.mak = 16
	options = BattleMath.absorb_gain_options(stats)
	assert_eq(options.size(), 3, "two eligible stats: +2 in either or +1/+1")
	assert_eq(options[0].gains, {&"mak": 2}, "highest multiple of 8 first")
	assert_eq(options[2].gains, {&"mak": 1, &"mef": 1})
	stats.mak = 3
	stats.mef = 5
	options = BattleMath.absorb_gain_options(stats)
	assert_eq(options.size(), 1)
	assert_eq(options[0].gains, {&"atk": 2}, "no multiple of 8: +2 in the highest attribute")
