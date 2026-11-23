class_name BattleState
extends RefCounted

## Round/act bookkeeping. Pure logic so it can be exercised headless.

var units: Array[BattleUnit] = []
var round_number: int = 0
var turn_order: Array[BattleUnit] = []
var turn_index: int = 0

func add_unit(unit: BattleUnit) -> void:
	units.append(unit)

func alive_units() -> Array[BattleUnit]:
	var result: Array[BattleUnit] = []
	for unit in units:
		if unit.is_alive():
			result.append(unit)
	return result

func strongest_opposite(unit: BattleUnit) -> BattleUnit:
	var best: BattleUnit = null
	for other in units:
		if not other.is_alive() or other.is_player == unit.is_player:
			continue
		if best == null or other.current_sp > best.current_sp:
			best = other
	return best

func start_round() -> void:
	round_number += 1
	turn_order.clear()
	for unit in units:
		if not unit.is_alive():
			continue
		# D-005: 2 fresh acts + stored acts + dominance bonus, capped at 4.
		# Excess is deferred back into the stock instead of being discarded.
		var acts := 2 + unit.stored_acts
		var rival := strongest_opposite(unit)
		if rival != null and BattleMath.dominance_ratio(unit.current_sp, rival.current_sp) \
			> BattleMath.THRESHOLD_RATIO:
			acts += 1
		unit.stored_acts = 0
		unit.acts_available = clampi(acts, 0, BattleMath.MAX_AVAILABLE_ACTS)
		unit.store_acts(maxi(0, acts - BattleMath.MAX_AVAILABLE_ACTS))
		turn_order.append(unit)
	turn_order.sort_custom(_faster_first)
	turn_index = 0


## Creator 2026-11-23: fastest first; equal AGI goes to the higher SP at the start of
## the round. Equal AGI and SP has no rule yet (PENDENTE).
func _faster_first(a: BattleUnit, b: BattleUnit) -> bool:
	if a.stats.agi != b.stats.agi:
		return a.stats.agi > b.stats.agi
	return a.current_sp > b.current_sp


## Creator 2026-11-23 (replaces D-044's A,A,B,B): each call is a new turn. The next
## combatant in speed order with acts left takes it, runs the whole queue it plans
## (two queued attacks spend both acts in that one turn) and hands over; the cycle
## repeats until nobody has acts, e.g. Fallen > enemy > Yoch > enemy > Fallen.
## Reactions still spend from the same act pool.
func next_actor() -> BattleUnit:
	var scanned: int = 0
	while scanned < turn_order.size():
		if turn_index >= turn_order.size():
			turn_index = 0
		var unit := turn_order[turn_index]
		turn_index += 1
		scanned += 1
		if unit.is_alive() and unit.acts_available > 0:
			return unit
	return null


func end_round() -> void:
	for unit in units:
		if unit.is_alive():
			unit.recover_en(0.2)
			if unit.acts_available > 0:
				unit.store_acts(unit.acts_available)
				unit.acts_available = 0


## Creator 2026-11-23: the battle ends as soon as Fallen falls, even with the ally up
## (death cutscene, then the title screen).
func fallen_fell() -> bool:
	for unit in units:
		if unit.is_fallen and not unit.is_alive():
			return true
	return false


func is_over() -> bool:
	if fallen_fell():
		return true
	var players_alive := false
	var enemies_alive := false
	for unit in units:
		if not unit.is_alive():
			continue
		if unit.is_player:
			players_alive = true
		else:
			enemies_alive = true
	return not players_alive or not enemies_alive


func player_victory() -> bool:
	if fallen_fell():
		return false
	for unit in units:
		if not unit.is_player and unit.is_alive():
			return false
	return true
