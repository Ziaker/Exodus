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
		# ACT_CAP_CONFLICT: 2 fresh acts + stored (<=4) + superiority bonus.
		# The maximum total remains pending a director decision; no new cap is
		# introduced here. Only the scheduling defect is fixed.
		var acts := 2 + unit.stored_acts
		unit.stored_acts = 0
		var rival := strongest_opposite(unit)
		if rival != null and float(unit.current_sp) > float(rival.current_sp) * BattleMath.THRESHOLD_RATIO:
			acts += 1
		unit.acts_available = clampi(acts, 0, 8)
		turn_order.append(unit)
	turn_order.sort_custom(_faster_first)
	turn_index = 0


func _faster_first(a: BattleUnit, b: BattleUnit) -> bool:
	return a.stats.agi > b.stats.agi


## Returns the next unit that still has an act. Each unit is offered once per
## pass in AGI order, so 2 acts produce A,B,A,B rather than A,A,B,B.
## Reactions spend acts through BattleUnit.spend_act() and are skipped here.
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


func is_over() -> bool:
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
	for unit in units:
		if not unit.is_player and unit.is_alive():
			return false
	return true
