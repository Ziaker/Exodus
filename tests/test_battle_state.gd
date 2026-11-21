extends GutTest

func _make_unit(id: StringName, player_side: bool, sp: int, agi: int) -> BattleUnit:
	var stats := UnitStats.new()
	stats.max_hp = sp / 2
	stats.max_en = sp / 4
	stats.atk = sp / 4
	stats.mak = sp / 4
	stats.defense = sp / 4
	stats.mef = sp / 4
	stats.agi = agi
	var unit := BattleUnit.new(id, String(id), stats, player_side)
	unit.current_sp = sp
	return unit


func _take(state: BattleState) -> BattleUnit:
	var unit := state.next_actor()
	if unit != null:
		unit.spend_act()
	return unit


func _equal_state() -> BattleState:
	var state := BattleState.new()
	state.add_unit(_make_unit(&"fast", true, 20, 9))
	state.add_unit(_make_unit(&"slow", false, 20, 2))
	state.start_round()
	# The 70% rule grants a bonus to at least one side for any positive pair.
	# Neutralize it here to test act scheduling in isolation.
	for unit in state.units:
		unit.acts_available = 2
	return state


func test_two_acts_are_both_usable_in_agi_order() -> void:
	var state := _equal_state()
	assert_eq(state.units[0].acts_available, 2)
	assert_eq(state.units[1].acts_available, 2)
	assert_eq(_take(state), state.units[0])
	assert_eq(_take(state), state.units[1])
	assert_eq(_take(state), state.units[0])
	assert_eq(_take(state), state.units[1])
	assert_null(state.next_actor())


func test_stored_acts_are_consumed_as_extra_turns() -> void:
	var state := BattleState.new()
	var hero := _make_unit(&"hero", true, 20, 9)
	hero.store_acts(2)
	state.add_unit(hero)
	state.add_unit(_make_unit(&"foe", false, 20, 2))
	state.start_round()
	hero.acts_available = 4
	state.units[1].acts_available = 2
	var seen_hero := 0
	for _i in 6:
		if _take(state) == hero:
			seen_hero += 1
	assert_eq(seen_hero, 4)
	assert_null(state.next_actor())


func test_reaction_and_action_share_the_same_act_pool() -> void:
	var state := _equal_state()
	var unit := state.units[0]
	assert_true(unit.spend_act(), "reaction spends one act")
	assert_eq(unit.acts_available, 1)
	assert_eq(_take(state), unit, "remaining act is still offered")
	assert_eq(_take(state), state.units[1])
	assert_eq(_take(state), state.units[1])
	assert_null(state.next_actor())


func test_consecutive_attacks_spend_one_act_each() -> void:
	var state := _equal_state()
	for _i in 4:
		var unit := _take(state)
		assert_not_null(unit)
		assert_true(unit.acts_available >= 0)
	assert_null(state.next_actor())
	for unit in state.units:
		assert_eq(unit.acts_available, 0)


func test_unused_acts_are_stored_on_end_round() -> void:
	var state := _equal_state()
	var unit := state.units[0]
	unit.spend_act()
	state.end_round()
	assert_eq(unit.stored_acts, 1)
	assert_eq(unit.acts_available, 0)


func test_act_consumption_never_goes_negative() -> void:
	var unit := _make_unit(&"hero", true, 20, 5)
	unit.acts_available = 1
	assert_true(unit.spend_act())
	assert_false(unit.spend_act())
	assert_eq(unit.acts_available, 0)


func test_end_round_recovers_en_and_caps_at_maximum() -> void:
	var unit := _make_unit(&"hero", true, 400, 5)
	var state := BattleState.new()
	state.add_unit(unit)
	state.add_unit(_make_unit(&"foe", false, 400, 4))
	state.start_round()
	for member in state.units:
		member.acts_available = 2
	unit.current_en = 0
	unit.stats.max_en = 10
	state.end_round()
	assert_eq(unit.current_en, 2)
	unit.current_en = 9
	state.end_round()
	assert_eq(unit.current_en, 10)


func test_defeated_unit_does_not_take_remaining_acts() -> void:
	var state := _equal_state()
	var unit := state.units[0]
	unit.take_damage(9999)
	assert_false(unit.is_alive())
	assert_eq(_take(state), state.units[1])
	assert_eq(_take(state), state.units[1])
	assert_null(state.next_actor())


func test_no_infinite_turns_when_acts_are_exhausted() -> void:
	var state := _equal_state()
	var calls := 0
	while _take(state) != null and calls < 100:
		calls += 1
	assert_lt(calls, 100)
	assert_eq(calls, 4)
	assert_null(state.next_actor())


func test_rules_are_symmetric_for_player_and_enemy() -> void:
	var state := BattleState.new()
	var hero := _make_unit(&"hero", true, 20, 9)
	var foe := _make_unit(&"foe", false, 20, 2)
	state.add_unit(hero)
	state.add_unit(foe)
	state.start_round()
	hero.acts_available = 2
	foe.acts_available = 2
	assert_eq(_take(state), hero)
	assert_eq(_take(state), foe)
	assert_eq(_take(state), hero)
	assert_eq(_take(state), foe)
	assert_null(state.next_actor())


func test_superiority_bonus_still_grants_one_act() -> void:
	var state := BattleState.new()
	var strong := _make_unit(&"strong", true, 60, 5)
	var weak := _make_unit(&"weak", false, 10, 4)
	state.add_unit(strong)
	state.add_unit(weak)
	state.start_round()
	assert_eq(strong.acts_available, 3)
	assert_eq(weak.acts_available, 2)


func test_d005_cap_defers_surplus_acts() -> void:
	var state := BattleState.new()
	var hero := _make_unit(&"hero", true, 20, 9)
	hero.store_acts(4)
	state.add_unit(hero)
	state.add_unit(_make_unit(&"foe", false, 20, 2))
	state.start_round()
	assert_eq(hero.acts_available, 4)
	assert_eq(hero.stored_acts, 2, "2 fresh acts are deferred when stored is full")


func test_d005_grant_overflow_is_deferred() -> void:
	var unit := _make_unit(&"hero", true, 20, 5)
	unit.acts_available = 4
	unit.grant_acts(2)
	assert_eq(unit.acts_available, 4)
	assert_eq(unit.stored_acts, 2)


func test_d005_penalty_only_reduces_available_acts() -> void:
	var unit := _make_unit(&"hero", true, 20, 5)
	unit.acts_available = 2
	unit.grant_acts(-1)
	assert_eq(unit.acts_available, 1)
	unit.grant_acts(-5)
	assert_eq(unit.acts_available, 0)
	assert_eq(unit.stored_acts, 0)


func test_deferred_acts_reappear_next_round() -> void:
	var state := BattleState.new()
	var hero := _make_unit(&"hero", true, 20, 9)
	hero.store_acts(2)
	state.add_unit(hero)
	state.add_unit(_make_unit(&"foe", false, 20, 2))
	state.start_round()
	assert_eq(hero.acts_available, 4)
	assert_eq(hero.stored_acts, 0)
	hero.spend_act()
	hero.spend_act()
	state.end_round()
	assert_eq(hero.stored_acts, 2)
	state.start_round()
	assert_eq(hero.acts_available, 4)
	assert_eq(hero.stored_acts, 0)


func test_dominance_requires_real_superiority() -> void:
	var state := BattleState.new()
	var nearly_equal := _make_unit(&"a", true, 46, 9)
	state.add_unit(nearly_equal)
	state.add_unit(_make_unit(&"b", false, 45, 2))
	state.start_round()
	assert_eq(nearly_equal.acts_available, 2)


func test_battle_ends_when_one_side_is_down() -> void:
	var state := _equal_state()
	assert_false(state.is_over())
	state.units[1].take_damage(9999)
	assert_true(state.is_over())
	assert_true(state.player_victory())
