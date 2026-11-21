class_name BattleMath
extends RefCounted

## Pure combat formulas from docs/COMBAT_SPEC.md. No scene dependencies.

enum Affinity { WEAK, NORMAL, RESIST, NULL, ABSORB }
enum RhythmResult { POINT, BEAM, MISS }

const SP_GAIN_PER_EVENT: int = 1
const REST_EN_RECOVERY: int = 2
const BLOCK_ROLLS_PER_SP: int = 2
const THRESHOLD_RATIO: float = 0.7
const MAX_AVAILABLE_ACTS: int = 4
const MAX_STORED_ACTS: int = 4
const BASE_VARIATION: float = 0.10
const VARIATION_PER_SP: float = 0.02
const CRIT_MULTIPLIER: float = 1.5
const CRIT_PER_SP_POINT: float = 2.0
const CRIT_SP_BONUS_CAP: float = 20.0
const CRIT_FINAL_CAP: float = 50.0
const RHYTHM_FIXED_SECONDS: float = 1.0
const POINT_HALF_WIDTH: float = 0.05
const BEAM_HALF_WIDTH: float = 0.15
## D-034: AGI advantage widens POINT by 1 percentage point per point; SP keeps
## the D-021 band adjustment (1 point per 5 SP, up to +/-2). Total coverage is
## bounded by the already approved D-023 range of 8% to 16%.
const POINT_PP_PER_AGI: float = 0.01
const POINT_SP_STEP: int = 5
const POINT_SP_MAX_STEPS: int = 2
const POINT_MIN_HALF_WIDTH: float = 0.04
const POINT_MAX_HALF_WIDTH: float = 0.08

static func affinity_multiplier(affinity: Affinity) -> float:
	match affinity:
		Affinity.WEAK:
			return 1.5
		Affinity.RESIST:
			return 0.5
		Affinity.NULL, Affinity.ABSORB:
			return 0.0
		_:
			return 1.0

## D-021: +2 percentage points per SP advantage, capped at +20, and a final
## chance of at most 50%. A disadvantage never lowers the AGI base.
static func crit_chance(agi: int, sp_difference: int) -> float:
	var advantage := maxi(0, sp_difference)
	var sp_bonus := clampf(float(advantage) * CRIT_PER_SP_POINT, 0.0, CRIT_SP_BONUS_CAP)
	return clampf(float(agi) + sp_bonus, 0.0, CRIT_FINAL_CAP)


## D-015: a perfect defense overrides a perfect attack. Contact is the only
## gate for damage, Press Turn and SP rewards.
static func has_contact(attack_timing: RhythmResult,
		defense_timing: RhythmResult) -> bool:
	return attack_timing != RhythmResult.MISS \
		and defense_timing != RhythmResult.POINT

## D-034: the bar has its own fixed speed. AGI and SP no longer change time.
static func rhythm_duration(_attacker_agi: int, _defender_agi: int,
		_attacker_sp: int, _defender_sp: int) -> float:
	return RHYTHM_FIXED_SECONDS


## Half-width of POINT for the combatant controlling the bar.
static func point_half_width(own_agi: int, rival_agi: int,
		own_sp: int, rival_sp: int) -> float:
	var total := 2.0 * POINT_HALF_WIDTH
	total += float(maxi(0, own_agi - rival_agi)) * POINT_PP_PER_AGI
	var sp_steps := clampi((own_sp - rival_sp) / POINT_SP_STEP,
		-POINT_SP_MAX_STEPS, POINT_SP_MAX_STEPS)
	total += float(sp_steps) * POINT_PP_PER_AGI
	return clampf(total * 0.5, POINT_MIN_HALF_WIDTH, POINT_MAX_HALF_WIDTH)


static func rhythm_zone(marker_position: float,
		point_half: float = POINT_HALF_WIDTH) -> RhythmResult:
	var distance := absf(marker_position - 0.5)
	if distance <= point_half:
		return RhythmResult.POINT
	if distance <= BEAM_HALF_WIDTH:
		return RhythmResult.BEAM
	return RhythmResult.MISS

## Dominance ratio: share of the combined SP held by one combatant.
## Two positive values cannot both exceed the threshold (ratios sum to 1).
static func dominance_ratio(own_sp: int, rival_sp: int) -> float:
	var total := own_sp + rival_sp
	if total <= 0:
		return 0.0
	return float(own_sp) / float(total)


static func extra_block_rolls(advantage: int) -> int:
	if advantage <= 0:
		return 0
	return advantage / BLOCK_ROLLS_PER_SP

## Result keys: amount, crit, affinity, sp_roll, variation, base.
static func physical_damage(power: int, attacker_atk: int, attacker_agi: int,
		defender_defense: int, attacker_sp: int, defender_sp: int,
		affinity: Affinity, rng: RandomNumberGenerator) -> Dictionary:
	var difference := attacker_sp - defender_sp
	var base := float(power) * float(attacker_atk) / maxf(float(defender_defense), 1.0)

	var sp_roll := 0
	var magnitude := absi(difference)
	if magnitude > 0:
		sp_roll = rng.randi_range(1, magnitude)
		if difference < 0:
			sp_roll = -sp_roll

	var variation_span := BASE_VARIATION + VARIATION_PER_SP * float(magnitude)
	var variation := rng.randf_range(-variation_span, variation_span)

	var crit := critical_roll(attacker_agi, attacker_sp, defender_sp, rng)
	var multiplier := affinity_multiplier(affinity)
	var amount := base + float(sp_roll)
	amount *= 1.0 + variation
	if crit:
		amount *= CRIT_MULTIPLIER
	amount *= multiplier

	return {
		"amount": maxi(0, int(round(amount))),
		"base": base,
		"crit": crit,
		"affinity": affinity,
		"sp_roll": sp_roll,
		"variation": variation,
	}

static func critical_roll(attacker_agi: int, attacker_sp: int, defender_sp: int,
		rng: RandomNumberGenerator) -> bool:
	return rng.randf_range(0.0, 100.0) < crit_chance(attacker_agi, attacker_sp - defender_sp)

static func press_turn_acts(affinity: Affinity) -> int:
	match affinity:
		Affinity.WEAK:
			return 1
		Affinity.RESIST, Affinity.NULL, Affinity.ABSORB:
			return -1
		_:
			return 0
