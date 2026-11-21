class_name UnitStats
extends Resource

## Base attributes. SP is derived from the sum of all seven (never stored as truth).
@export var max_hp: int = 10
@export var max_en: int = 10
@export var atk: int = 5
@export var mak: int = 5
@export var defense: int = 5
@export var mef: int = 5
@export var agi: int = 5

func sp_value() -> int:
	return max_hp + max_en + atk + mak + defense + mef + agi

func highest_combat_stat() -> StringName:
	var best: StringName = &"atk"
	var best_value: int = atk
	if mak > best_value:
		best = &"mak"
		best_value = mak
	if defense > best_value:
		best = &"defense"
		best_value = defense
	if mef > best_value:
		best = &"mef"
		best_value = mef
	if agi > best_value:
		best = &"agi"
	return best

func duplicate_stats() -> UnitStats:
	var copy := UnitStats.new()
	copy.max_hp = max_hp
	copy.max_en = max_en
	copy.atk = atk
	copy.mak = mak
	copy.defense = defense
	copy.mef = mef
	copy.agi = agi
	return copy
