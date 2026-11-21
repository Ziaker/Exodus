class_name BattleUnit
extends RefCounted

var id: StringName
var display_name: String
var stats: UnitStats
var current_hp: int
var current_en: int
var current_sp: int
var acts_available: int = 0
var stored_acts: int = 0
var affinity: BattleMath.Affinity = BattleMath.Affinity.NORMAL
var is_player: bool = false
var is_fallen: bool = false
var sprite_path: String = ""

func _init(unit_id: StringName, unit_name: String, unit_stats: UnitStats,
		player_side: bool, fallen: bool = false) -> void:
	id = unit_id
	display_name = unit_name
	stats = unit_stats.duplicate_stats()
	current_hp = stats.max_hp
	current_en = stats.max_en
	current_sp = stats.sp_value()
	is_player = player_side
	is_fallen = fallen

func sp_base() -> int:
	return stats.sp_value()

func is_alive() -> bool:
	return current_hp > 0

func spend_act() -> bool:
	if acts_available <= 0:
		return false
	acts_available -= 1
	return true

func grant_acts(amount: int) -> void:
	acts_available = clampi(acts_available + amount, 0, 8)

func store_acts(amount: int) -> void:
	stored_acts = clampi(stored_acts + amount, 0, 4)

func add_sp(amount: int) -> void:
	current_sp = maxi(0, current_sp + amount)

func restore_sp() -> void:
	current_sp = sp_base()

func recover_en(fraction: float) -> void:
	current_en = mini(stats.max_en, current_en + int(float(stats.max_en) * fraction))

func take_damage(amount: int) -> int:
	var applied := mini(current_hp, maxi(0, amount))
	current_hp -= applied
	return applied

func heal(amount: int) -> int:
	var applied := mini(stats.max_hp - current_hp, maxi(0, amount))
	current_hp += applied
	return applied
