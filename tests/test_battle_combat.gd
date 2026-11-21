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


func test_player_attack_uses_manual_rhythm_and_spends_one_act() -> void:
	var battle := await _fresh_battle()
	battle.state.units[2].affinity = BattleMath.Affinity.NORMAL
	battle._fallen.acts_available = 2
	var before: int = battle._fallen.acts_available
	_choose(battle, 0)
	for _i in range(30):
		if battle.rhythm.visible:
			break
		await get_tree().process_frame
	assert_true(battle.rhythm.visible, "player attack opens the manual bar")
	battle._on_rhythm_finished(BattleMath.RhythmResult.POINT)
	for _i in range(20):
		await get_tree().process_frame
	# The act was spent before the menu opened; no second spend occurs.
	assert_eq(battle._fallen.acts_available, before)
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
	if result == BattleMath.RhythmResult.MISS:
		assert_eq(enemy.acts_available, 2)
	else:
		assert_lt(enemy.acts_available, 2)


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
	if expected == BattleMath.RhythmResult.MISS:
		assert_eq(defender.acts_available, 2)
	else:
		assert_eq(defender.acts_available, 1)


func test_rest_spends_exactly_one_act() -> void:
	var battle := await _fresh_battle()
	battle._fallen.current_en = 0
	# The act is already spent when the menu opens; set a known value here.
	battle._fallen.acts_available = 2
	_choose(battle, 2)
	for _i in range(20):
		await get_tree().process_frame
	# The act was spent before the menu opened; REST must not spend a second one.
	assert_eq(battle._fallen.acts_available, 2)
	assert_eq(battle._fallen.current_en, int(float(battle._fallen.stats.max_en) * 0.2))


func test_absorption_without_input_grants_nothing() -> void:
	var battle := await _fresh_battle()
	var before_hp: int = battle._fallen.stats.max_hp
	_choose(battle, 3)
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
	get_tree().create_timer(0.1).timeout.connect(func(): battle._mash_count = 12)
	_choose(battle, 3)
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
	get_tree().create_timer(0.1).timeout.connect(func(): battle._mash_count = 12)
	_choose(battle, 3)
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


func test_menu_input_does_not_trigger_reaction_or_mash() -> void:
	var battle := await _fresh_battle()
	var event := InputEventKey.new()
	event.keycode = KEY_Z
	event.pressed = true
	battle._input(event)
	assert_false(battle._reaction_active)
	assert_false(battle._mash_active)
	assert_eq(battle._mash_count, 0)
