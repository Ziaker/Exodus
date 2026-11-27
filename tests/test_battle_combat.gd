extends GutTest

## Integration coverage for the corrected attack / defense / action economy.

func _fresh_battle() -> Control:
	var packed: PackedScene = load("res://scenes/battle/Battle.tscn")
	var battle: Control = packed.instantiate()
	add_child_autofree(battle)
	for _i in range(60):
		if battle._fallen != null and battle.command_box.get_child_count() > 0:
			break
		await get_tree().process_frame
	return battle


func _choose(battle: Control, index: int) -> void:
	battle._chosen = index
	battle.command_chosen.emit()


## Feeds a planned sequence to the D-046 queue, one command per frame.
func _plan(battle: Control, commands: Array[int]) -> void:
	for command in commands:
		battle._chosen = command
		battle.command_chosen.emit()
		await get_tree().process_frame
	if battle._planned.is_empty():
		return
	if commands.has(2):  # REST already finalizes the plan.
		return
	battle._chosen = battle._plan_options.size() - 2  # EXEC
	battle.command_chosen.emit()


func test_player_attack_uses_manual_rhythm_and_spends_one_act() -> void:
	var battle := await _fresh_battle()
	battle._fallen.acts_available = 2
	var before: int = battle._fallen.acts_available
	await _plan(battle, [0])
	for _i in range(30):
		if battle.rhythm.visible:
			break
		await get_tree().process_frame
	assert_true(battle.rhythm.visible, "player attack opens the manual bar")
	battle._on_rhythm_finished(BattleMath.RhythmResult.POINT)
	for _i in range(20):
		await get_tree().process_frame
	# Acts are now spent by the chosen command, not on entering the menu.
	assert_eq(battle._fallen.acts_available, before - 1)
	var attacks := 0
	for line in battle.log_history:
		if line.contains("->"):
			attacks += 1
	assert_eq(attacks, 1, "one attack produces one resolution")


func test_enemy_attack_never_opens_an_attack_bar() -> void:
	var battle := await _fresh_battle()
	battle._fallen.acts_available = 0
	var enemy: BattleUnit = battle.state.units[2]
	var saw_bar := false
	battle._enemy_turn(enemy)
	for _i in range(20):
		if battle.rhythm.visible:
			saw_bar = true
		await get_tree().create_timer(0.05).timeout
	assert_false(saw_bar, "enemy attack is resolved by AI, not by player input")
	var has_damage := false
	for line in battle.log_history:
		if line.contains("dmg"):
			has_damage = true
	assert_true(has_damage, "enemy attack still resolves")


func test_enemy_attack_hits_when_no_reaction_is_possible() -> void:
	var battle := await _fresh_battle()
	battle._fallen.acts_available = 0
	battle.rng.seed = 999
	battle._enemy_turn(battle.state.units[2])
	for _i in range(40):
		await get_tree().create_timer(0.05).timeout
	var hit := false
	var no_contact := false
	for line in battle.log_history:
		if line.contains("NO CONTACT"):
			no_contact = true
		if line.contains("dmg") and line.contains("rhythm POINT"):
			hit = true
	assert_false(no_contact, "guaranteed hit cannot produce NO CONTACT")
	assert_true(hit, "enemy lands a normal hit without a possible reaction")


func test_enemy_attack_hits_when_player_declines_reaction() -> void:
	var battle := await _fresh_battle()
	battle._fallen.acts_available = 2
	battle.rng.seed = 1001
	battle._enemy_turn(battle.state.units[2])
	for _i in range(40):
		await get_tree().create_timer(0.05).timeout
	var hit := false
	for line in battle.log_history:
		if line.contains("dmg") and line.contains("rhythm POINT"):
			hit = true
	assert_true(hit, "declining a possible reaction still lets the enemy hit")


func test_player_defense_is_available_when_a_reaction_is_declared() -> void:
	var battle := await _fresh_battle()
	battle._fallen.acts_available = 1
	get_tree().create_timer(0.1).timeout.connect(func(): battle._reaction_yes = true)
	var enemy: BattleUnit = battle.state.units[2]
	var saw_bar := false
	battle._enemy_turn(enemy)
	for _i in range(30):
		if battle.rhythm.visible:
			saw_bar = true
		await get_tree().create_timer(0.05).timeout
	assert_true(saw_bar, "declared reaction opens the manual defense bar")
	var declared := false
	for line in battle.log_history:
		if line.contains("reacts to"):
			declared = true
	assert_true(declared, "reaction consumes an act")


func test_ai_defense_resolves_without_human_input() -> void:
	var battle := await _fresh_battle()
	var enemy: BattleUnit = battle.state.units[2]
	enemy.acts_available = 2
	battle.rng.seed = 4242
	var result: int = battle._defender_reaction(enemy, battle._fallen)
	var valid: bool = result == BattleMath.RhythmResult.POINT \
		or result == BattleMath.RhythmResult.BEAM \
		or result == BattleMath.RhythmResult.MISS
	assert_true(valid)
	# D-109: defender custa 1 ACT sempre, de certo ou nao.
	assert_eq(enemy.acts_available, 1)


func test_ai_attack_rolls_the_same_point_width_as_the_player() -> void:
	var battle := await _fresh_battle()
	var attacker: BattleUnit = battle.state.units[2]
	var defender: BattleUnit = battle._fallen
	attacker.current_sp = defender.current_sp
	var point_half := BattleMath.point_half_width(attacker.stats.agi,
		defender.stats.agi, attacker.current_sp, defender.current_sp)
	var expected_rng := RandomNumberGenerator.new()
	expected_rng.seed = 4242
	var expected: int = BattleMath.rhythm_zone(
		expected_rng.randf_range(0.0, 1.0), point_half)
	battle.rng.seed = 4242
	assert_eq(battle._ai_roll(attacker, defender), expected)


func test_ai_defense_uses_point_width_and_spends_act() -> void:
	var battle := await _fresh_battle()
	var defender: BattleUnit = battle.state.units[2]
	var attacker: BattleUnit = battle._fallen
	defender.current_sp = attacker.current_sp
	defender.acts_available = 2
	var point_half := BattleMath.point_half_width(defender.stats.agi,
		attacker.stats.agi, defender.current_sp, attacker.current_sp)
	var expected_rng := RandomNumberGenerator.new()
	expected_rng.seed = 777
	var expected: int = BattleMath.rhythm_zone(
		expected_rng.randf_range(0.0, 1.0), point_half)
	battle.rng.seed = 777
	assert_eq(battle._defender_reaction(defender, attacker), expected)
	# D-109: a tentativa de defesa custa 1 ACT mesmo quando falha.
	assert_eq(defender.acts_available, 1)


func test_rest_costs_no_act_stores_acts_and_restores_flat_en() -> void:
	var battle := await _fresh_battle()
	battle._fallen.current_en = 0
	battle._fallen.stored_acts = 0
	# REST spends nothing: both acts remain available and go to the stock.
	battle._fallen.acts_available = 2
	_choose(battle, 2)
	for _i in range(20):
		await get_tree().process_frame
	assert_eq(battle._fallen.acts_available, 0, "REST ends participation this round")
	assert_eq(battle._fallen.stored_acts, 2, "all acts are stored, none consumed")
	assert_eq(battle._fallen.current_en, 2, "REST restores exactly 2 EN")
	assert_false(battle._fallen.spend_act(), "REST cannot be repeated this round")


func test_rest_stores_at_most_four_acts() -> void:
	var battle := await _fresh_battle()
	battle._fallen.stored_acts = 0
	battle._fallen.acts_available = 4
	_choose(battle, 2)
	for _i in range(20):
		await get_tree().process_frame
	assert_eq(battle._fallen.stored_acts, 4)


func test_rest_en_is_capped_at_maximum() -> void:
	var battle := await _fresh_battle()
	battle._fallen.current_en = battle._fallen.stats.max_en - 1
	battle._fallen.stored_acts = 0
	battle._fallen.acts_available = 1
	_choose(battle, 2)
	for _i in range(20):
		await get_tree().process_frame
	assert_eq(battle._fallen.current_en, battle._fallen.stats.max_en)


func test_absorption_without_input_grants_nothing() -> void:
	var battle := await _fresh_battle()
	var before_hp: int = battle._fallen.stats.max_hp
	await _plan(battle, [3])
	await get_tree().create_timer(2.4).timeout
	var failed := false
	for line in battle.log_history:
		if line.contains("ABSORB failed: no input"):
			failed = true
	assert_true(failed)
	assert_eq(battle._fallen.stats.max_hp, before_hp)


func test_absorption_success_eliminates_target_once() -> void:
	var battle := await _fresh_battle()
	var target: BattleUnit = battle.state.units[2]
	target.current_sp = 10  # D-051: 5 presses drain it, so absorption is guaranteed
	get_tree().create_timer(0.1).timeout.connect(func(): battle._mash_count = 12)
	await _plan(battle, [3])
	await get_tree().create_timer(2.4).timeout
	assert_true(target.absorbed)
	assert_false(target.is_alive(), "a successful absorption consumes the target")
	var eliminated := 0
	for line in battle.log_history:
		if line.contains("eliminated"):
			eliminated += 1
	assert_eq(eliminated, 1)
	battle._perform_absorption(battle._fallen, target)
	await get_tree().process_frame
	var repeated := 0
	for line in battle.log_history:
		if line.contains("already absorbed"):
			repeated += 1
	assert_eq(repeated, 1)


func test_absorption_of_last_enemy_ends_battle() -> void:
	var battle := await _fresh_battle()
	var first: BattleUnit = battle.state.units[2]
	var last: BattleUnit = battle.state.units[3]
	last.take_damage(last.current_hp)
	assert_false(last.is_alive())
	first.current_sp = 10  # D-051: drained by 5 presses
	get_tree().create_timer(0.1).timeout.connect(func(): battle._mash_count = 12)
	await _plan(battle, [3])
	await get_tree().create_timer(2.4).timeout
	assert_false(first.is_alive())
	assert_true(battle.state.is_over())
	assert_true(battle.state.player_victory())


func test_ally_cannot_absorb() -> void:
	var battle := await _fresh_battle()
	var before: int = battle._ally.stats.max_hp
	battle._perform_absorption(battle._ally, battle.state.units[2])
	await get_tree().process_frame
	assert_eq(battle._ally.stats.max_hp, before)


func test_plan_markers_show_committed_acts_and_undo_clears_them() -> void:
	var battle := await _fresh_battle()
	battle._fallen.acts_available = 3
	for _i in range(20):
		if battle._plan_active:
			break
		await get_tree().process_frame
	assert_true(battle._plan_active, "fallen enters planning mode")
	battle._chosen = 0
	battle.command_chosen.emit()
	await get_tree().process_frame
	assert_eq(battle._planned.size(), 1)
	assert_gt(battle.plan_markers[0].color.g, 0.7, "planned ACT turns green")
	battle._chosen = battle._plan_options.size() - 1  # UNDO
	battle.command_chosen.emit()
	await get_tree().process_frame
	assert_eq(battle._planned.size(), 0)
	assert_lt(battle.plan_markers[0].color.g, 0.5, "undo clears the green marker")


func test_chain_bar_stays_visible_between_attacks() -> void:
	var bar := RhythmBar.new()
	add_child_autofree(bar)
	bar.start_chain(1.0)
	assert_true(bar.visible)
	bar._finish(BattleMath.RhythmResult.POINT)
	assert_true(bar.visible, "chain keeps the same line on screen")
	assert_eq(bar._elapsed, 0.0, "marker restarts from the left")
	bar.stop_chain()
	assert_false(bar.visible)


func test_chained_command_keeps_bar_and_restarts_marker() -> void:
	var battle := await _fresh_battle()
	var target: BattleUnit = battle.state.units[2]
	target.current_hp = 999
	target.stats.max_hp = 999
	battle._fallen.acts_available = 2
	battle._execute_player_command(battle._fallen, 0, true)
	for _i in range(40):
		if battle.rhythm._chain_mode:
			break
		await get_tree().process_frame
	assert_true(battle.rhythm.visible)
	assert_true(battle.rhythm._chain_mode, "chained attack keeps the bar visible")
	battle._on_rhythm_finished(BattleMath.RhythmResult.POINT)
	await get_tree().process_frame
	assert_true(battle.rhythm.visible, "bar persists after the first judgment")
	assert_lt(battle.rhythm._elapsed, 0.05, "next marker restarts near the left")
	rhythm_stop(battle)


func rhythm_stop(battle: Control) -> void:
	battle.rhythm.stop_chain()
	assert_false(battle.rhythm.visible, "stopping the chain hides the bar")


func test_menu_input_does_not_trigger_reaction_or_mash() -> void:
	var battle := await _fresh_battle()
	var event := InputEventKey.new()
	event.keycode = KEY_Z
	event.pressed = true
	battle._input(event)
	assert_false(battle._reaction_active)
	assert_false(battle._mash_active)
	assert_eq(battle._mash_count, 0)


func test_absorption_takes_sp_and_keeps_it_on_failure() -> void:
	var battle := await _fresh_battle()
	var target: BattleUnit = battle.state.units[2]
	target.current_sp = 500
	battle._fallen.current_sp = 0
	var fallen_sp: int = battle._fallen.current_sp
	get_tree().create_timer(0.1).timeout.connect(func(): battle._mash_count = 3)
	await _plan(battle, [3])
	await get_tree().create_timer(2.4).timeout
	# D-103: one roll at a 6% chance; the 6 SP move in the result either way.
	if target.absorbed:
		assert_true(battle._fallen.current_sp >= fallen_sp + 6, "the result moved 6 SP before the absorption")
	else:
		assert_eq(target.current_sp, 494, "three presses took 6 SP and failure keeps them taken")
		assert_eq(battle._fallen.current_sp, fallen_sp + 6, "the taken SP went to Fallen")
		assert_true(battle.log_history.any(func(l: String) -> bool: return l.contains("resisted")))


## D-103 (creator, 2026-11-25): real Z key events only count; nothing moves until the
## result, which comes at the 10th press without waiting for the 2 s; later presses
## are ignored.
func test_mash_presses_only_count_and_tenth_press_resolves_at_once() -> void:
	var battle := await _fresh_battle()
	var target: BattleUnit = battle.state.units[2]
	target.current_sp = 500
	battle._fallen.current_sp = 0
	await _plan(battle, [3])
	for _i in range(60):
		if battle._mash_active:
			break
		await get_tree().process_frame
	assert_true(battle._mash_active, "ABSORB opens the mash")
	var started := Time.get_ticks_msec()
	var event := InputEventKey.new()
	event.keycode = KEY_Z
	event.pressed = true
	for i in 9:
		battle._input(event)
		assert_eq(battle._mash_count, i + 1)
		assert_eq(target.current_sp, 500, "no SP taken per press")
		assert_eq(battle._fallen.current_sp, 0, "no SP given per press")
	await get_tree().process_frame
	assert_true(battle._mash_active, "nine presses keep waiting")
	assert_eq(target.current_sp, 500)
	battle._input(event)
	assert_false(battle._mash_active, "the 10th press closes the mash")
	assert_eq(target.current_sp, 480, "the 10th press applies the result in the same call")
	await get_tree().process_frame
	assert_lt(Time.get_ticks_msec() - started, 1500, "no wait for the 2 s window")
	assert_eq(target.current_sp, 480, "the result took 10 x 2 SP once")
	# The single 20% roll may absorb, whose gain can raise Fallen's SP base further.
	if target.absorbed:
		assert_true(battle._fallen.current_sp >= 20, "the 20 SP reached Fallen")
	else:
		assert_eq(battle._fallen.current_sp, 20, "the 20 SP reached Fallen")
	var sp_after: int = battle._fallen.current_sp
	for _i in 4:
		battle._input(event)
	battle.register_mash_press()
	assert_eq(battle._mash_count, 10, "presses after the 10th are not counted")
	assert_eq(target.current_sp, 480, "late presses move nothing")
	assert_eq(battle._fallen.current_sp, sp_after, "late presses give nothing")
