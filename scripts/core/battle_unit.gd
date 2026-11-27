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
var is_player: bool = false
var is_fallen: bool = false
var absorbed: bool = false
## D-129: true when an orphan Floater Eye fled the battle (yields no Macca).
var fled: bool = false
var sprite_path: String = ""
## Enemy kind for the absorption counter (SkillBook.KIND_SKILLS); empty for heroes.
var kind: StringName = &""
## Skills this unit can use (Fallen: learned by absorption; enemies: their sheet).
var skills: Array[StringName] = []
## ATK stages (SkillBook.ATK_STAGE_BONUS each): {"round": cast round, "owner": turn owner id}.
var atk_stages: Array[Dictionary] = []
## Burns: remaining rounds of each one (they stack).
var burns: Array[int] = []
## D-048: humans pray instead of using EN (Yoch). Every current PP is worth +2 SP.
var prays: bool = false
var current_pp: int = 0
## D-048: race (Ra'am has no effect on PrayerBook.ANGEL). Effects beyond that: PENDING.
var race: StringName = &""
## D-048 Haganah: {"round": cast round, "step": cast step} while the shield is up, else {}.
var haganah: Dictionary = {}
## D-106 (Survival skills, see SkillFx): id -> {"rounds": int, "mod": {"stat","delta"}}.
var statuses: Dictionary = {}
## D-124 BLEED: remaining rounds of each stack (up to SkillFx.BLEED_MAX_STACKS); each stack cuts
## the healing received by 20%.
var bleeds: Array[int] = []
## D-124 VULN PIERCE: set when the unit's last action this round was non-offensive (PASS, REST, ITEM, buff,
## heal, a non-hostile prayer) or when it is defending; cleared by an offensive action and every round.
var passive_stance: bool = false
## D-124 temporização de ação: global actions left before a trapped unit is freed (0 = free).
var trapped_actions: int = 0
## REGEN: HP restored at the start of each of the next `regen_rounds` rounds.
var regen_amount: int = 0
var regen_rounds: int = 0
## D-107 NECHAMAH: remaining rounds of each mend (they stack, SkillFx.MEND_HEAL HP each per round).
var mends: Array[int] = []
## D-112 MAGEN: remaining rounds of each physical DEF stage (+25% physical DEF each).
var def_stages: Array[int] = []
## D-129 Floater Eye buffs (1 full round each, {"round": cast round, "owner": turn owner id}).
var mak_stages: Array[Dictionary] = []
var def_round_stages: Array[Dictionary] = []
var mef_stages: Array[Dictionary] = []
var agi_buffs: Array[Dictionary] = []
var sp_buffs: Array[Dictionary] = []
## D-129 KEEN GAZE: the unit's next offensive attack gains HIGH SPEED (consumed on attack).
var next_attack_high_speed: bool = false
## D-112 GEVURAH: damage bonus fraction on the next attack (0.15 + 0.05 per extra PP); consumed on attack.
var gevurah_bonus: float = 0.0
## D-112 MISHPAT: damage dealt by this unit in its last offensive action.
var last_damage_dealt: int = 0
## D-118 NITZOTZ: damage of each burn per round while superheated (0 = the default SkillBook.BURN_DAMAGE).
var burn_power: int = 0
## D-118 ANGEL HUG: acts this unit still has to lose (paralysis); taken from every grant of acts.
var paralyzed_acts: int = 0

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
	return stats.sp_value() + (PrayerBook.SP_PER_PP * current_pp if prays else 0)


## D-048: enables prayer with `pp` stored PP (0..8); the SP follows the PP.
func start_praying(pp: int) -> void:
	prays = true
	current_pp = 0
	change_pp(pp)


## D-048: adds (or removes) PP within 0..8 and moves the SP by 2 per PP actually
## changed. Returns the PP actually applied.
func change_pp(amount: int) -> int:
	var before := current_pp
	current_pp = clampi(current_pp + amount, 0, PrayerBook.MAX_PP)
	var applied := current_pp - before
	add_sp(PrayerBook.SP_PER_PP * applied)
	return applied

## D-118: damage of one round of burns (NITZOTZ raises each burn from 3 to 10).
func burn_round_damage() -> int:
	var per_burn := burn_power if burn_power > 0 else SkillBook.BURN_DAMAGE
	return per_burn * burns.size()


## D-118 ANGEL HUG: removes up to `paralyzed_acts` of the acts available now; returns how many were lost.
func apply_paralysis() -> int:
	if paralyzed_acts <= 0:
		return 0
	var lost := mini(paralyzed_acts, acts_available)
	acts_available -= lost
	paralyzed_acts -= lost
	if paralyzed_acts <= 0:
		remove_status(&"paralyzed")
	return lost


## ATK with the active stages applied (+25% per stage).
func effective_atk() -> float:
	return float(stats.atk) * (1.0 + SkillBook.ATK_STAGE_BONUS * float(atk_stages.size()))


## MAK with the active stages applied (+25% per stage, D-129 VERDANT MIGHT).
func effective_mak() -> float:
	return float(stats.mak) * (1.0 + SkillBook.ATK_STAGE_BONUS * float(mak_stages.size()))


## Physical DEF with active Magen and Verdant Shell stages applied (+25% per stage).
func effective_def() -> int:
	if def_stages.is_empty() and def_round_stages.is_empty():
		return stats.defense
	return maxi(1, int(round(float(stats.defense) * (1.0 + SkillBook.ATK_STAGE_BONUS * float(def_stages.size() + def_round_stages.size())))))


## Magic DEF (MEF) with active Verdant Shell stages applied (+25% per stage, D-129).
func effective_mef() -> int:
	if mef_stages.is_empty():
		return stats.mef
	return maxi(1, int(round(float(stats.mef) * (1.0 + SkillBook.ATK_STAGE_BONUS * float(mef_stages.size())))))


## AGI with active Keen Gaze buffs applied (D-129: never mutates stats.agi or sp_base()).
func effective_agi() -> int:
	if agi_buffs.is_empty():
		return stats.agi
	var bonus := 0
	for info in agi_buffs:
		bonus += int(info.get("amount", 0))
	return maxi(1, stats.agi + bonus)

## D-106: adds a status (a repeat refreshes it); `mod` changes a stat until it ends.
func add_status(id: StringName, rounds: int, mod: Dictionary = {}) -> void:
	if statuses.has(id):
		remove_status(id)
	if not mod.is_empty():
		stats.set(String(mod.stat), int(stats.get(String(mod.stat))) + int(mod.delta))
	statuses[id] = {"rounds": rounds, "mod": mod}


func has_status(id: StringName) -> bool:
	return statuses.has(id)


## D-131: unified definition of a vulnerable target (performing a non-offensive action /
## defending, or under an effect that forces PASS such as trap, paralysis or sleep).
func is_vulnerable(defending: bool = false) -> bool:
	return passive_stance or defending or trapped_actions > 0 or paralyzed_acts > 0 \
		or has_status(&"trapped") or has_status(&"paralyzed") or has_status(&"sleep")


## Ends a status and gives its stat back.
func remove_status(id: StringName) -> void:
	if not statuses.has(id):
		return
	var mod: Dictionary = statuses[id].mod
	if not mod.is_empty():
		stats.set(String(mod.stat), int(stats.get(String(mod.stat))) - int(mod.delta))
	statuses.erase(id)


func is_alive() -> bool:
	return current_hp > 0

func spend_act() -> bool:
	if acts_available <= 0:
		return false
	acts_available -= 1
	return true

## D-005: at most 4 acts may be available at once. Positive overflow is
## deferred to the act stock; negative values only reduce available acts.
func grant_acts(amount: int) -> void:
	if amount < 0:
		acts_available = maxi(0, acts_available + amount)
		return
	var room := BattleMath.MAX_AVAILABLE_ACTS - acts_available
	var applied := clampi(amount, 0, maxi(0, room))
	acts_available += applied
	var overflow := amount - applied
	if overflow > 0:
		store_acts(overflow)

func store_acts(amount: int) -> void:
	stored_acts = clampi(stored_acts + amount, 0, BattleMath.MAX_STORED_ACTS)

func add_sp(amount: int) -> void:
	current_sp = maxi(0, current_sp + amount)

func restore_sp() -> void:
	current_sp = sp_base()

func recover_en(fraction: float) -> void:
	current_en = mini(stats.max_en, current_en + int(float(stats.max_en) * fraction))


## D-038: REST restores a fixed amount, never a percentage.
func recover_en_flat(amount: int) -> void:
	current_en = mini(stats.max_en, current_en + maxi(0, amount))

## D-017: a successful absorption consumes the target. It cannot act again,
## cannot be absorbed twice and no longer counts as a living enemy.
func consume_by_absorption() -> void:
	absorbed = true
	current_hp = 0


func take_damage(amount: int) -> int:
	var applied := mini(current_hp, maxi(0, amount))
	current_hp -= applied
	return applied

## D-124: share of the healing that gets through (BLEED: -20% per stack, 4 stacks at most).
func heal_factor() -> float:
	return 1.0 - SkillFx.BLEED_HEAL_CUT * float(mini(SkillFx.BLEED_MAX_STACKS, bleeds.size()))


## D-124 BLEED: adds `stacks` stacks (4 at most; at the cap every stack is refreshed). Returns the stack count.
func add_bleed(stacks: int = 1) -> int:
	for _i in maxi(0, stacks):
		if bleeds.size() < SkillFx.BLEED_MAX_STACKS:
			bleeds.append(SkillFx.BLEED_ROUNDS)
		else:
			for j in bleeds.size():
				bleeds[j] = SkillFx.BLEED_ROUNDS
	return bleeds.size()


## D-124: traps the unit for `actions` global actions (keeps the larger value). Its queued acts are lost
## by the controller; the acts it did not use stay (the trap acts as an automatic PASS).
func trap(actions: int) -> void:
	trapped_actions = maxi(trapped_actions, maxi(0, actions))
	if trapped_actions > 0:
		add_status(&"trapped", 99, {})


## D-124: one global action was completed in the battle. Returns true when this frees the unit.
func tick_trap() -> bool:
	if trapped_actions <= 0:
		return false
	trapped_actions -= 1
	if trapped_actions > 0:
		return false
	remove_status(&"trapped")
	return true


func heal(amount: int) -> int:
	amount = maxi(0, int(round(float(amount) * heal_factor())))
	var applied := mini(stats.max_hp - current_hp, maxi(0, amount))
	current_hp += applied
	return applied
