extends GutTest

func _make_unit(id: StringName, player_side: bool, sp: int, agi: int) -> BattleUnit:
	var stats := UnitStats.new()
	stats.max_hp = sp / 4
	stats.max_en = sp / 4
	stats.atk = sp / 4
	stats.mak = sp / 4
	stats.defense = sp / 4
	stats.mef = sp / 4
	stats.agi = agi
	var unit := BattleUnit.new(id, String(id), stats, player_side)
	unit.current_sp = sp
	return unit


func test_round_grants_two_acts_and_sorts_by_agi() -> void:
	var state := BattleState.new()
	var slow := _make_unit(&"slow", true, 20, 2)
	var fast := _make_unit(&"fast", false, 5, 9)
	state.add_unit(slow)
	state.add_unit(fast)
	state.start_round()
	assert_eq(slow.acts_available, 3)
	assert_eq(fast.acts_available, 2)
	assert_eq(state.next_actor(), fast)
	assert_eq(state.next_actor(), slow)
	assert_null(state.next_actor())


func test_stored_acts_are_consumed_and_capped_at_four() -> void:
	var unit := _make_unit(&"hero", true, 20, 5)
	unit.current_sp = 3
	unit.store_acts(9)
	assert_eq(unit.stored_acts, 4)
	var state := BattleState.new()
	state.add_unit(unit)
	state.add_unit(_make_unit(&"foe", false, 20, 4))
	state.start_round()
	assert_eq(unit.acts_available, 6)
	assert_eq(unit.stored_acts, 0)


func test_threshold_grants_extra_act() -> void:
	var state := BattleState.new()
	var strong := _make_unit(&"strong", true, 60, 5)
	var weak := _make_unit(&"weak", false, 10, 4)
	state.add_unit(strong)
	state.add_unit(weak)
	state.start_round()
	assert_eq(strong.acts_available, 3)
	assert_eq(weak.acts_available, 2)


func test_end_round_recovers_en_and_stores_unused_acts() -> void:
	var unit := _make_unit(&"hero", true, 20, 5)
	var state := BattleState.new()
	state.add_unit(unit)
	state.add_unit(_make_unit(&"foe", false, 20, 4))
	state.start_round()
	unit.current_en = 0
	unit.stats.max_en = 10
	unit.acts_available = 2
	state.end_round()
	assert_eq(unit.current_en, 2)
	assert_eq(unit.stored_acts, 2)
	assert_eq(unit.acts_available, 0)


func test_battle_ends_when_one_side_is_down() -> void:
	var state := BattleState.new()
	var hero := _make_unit(&"hero", true, 20, 5)
	var foe := _make_unit(&"foe", false, 20, 4)
	state.add_unit(hero)
	state.add_unit(foe)
	assert_false(state.is_over())
	foe.take_damage(999)
	assert_true(state.is_over())
	assert_true(state.player_victory())
