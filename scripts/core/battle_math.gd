class_name BattleMath
extends RefCounted

## Pure combat formulas from docs/COMBAT_SPEC.md. No scene dependencies.

enum Affinity { WEAK, NORMAL, RESIST, NULL, ABSORB }
enum RhythmResult { POINT, BEAM, MISS }

const SP_GAIN_PER_EVENT: int = 1
const BLOCK_ROLLS_PER_SP: int = 2
const THRESHOLD_RATIO: float = 0.7
const BASE_VARIATION: float = 0.10
const VARIATION_PER_SP: float = 0.02
const CRIT_MULTIPLIER: float = 1.5
const MAX_RHYTHM_SECONDS: float = 1.0
const MIN_RHYTHM_SECONDS: float = 0.2
const RHYTHM_SECONDS_PER_POINT: float = 0.05
const POINT_HALF_WIDTH: float = 0.05
const BEAM_HALF_WIDTH: float = 0.15

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

static func crit_chance(agi: int, sp_difference: int) -> float:
	var chance := float(agi) + float(sp_difference) * 10.0
	return clampf(chance, 0.0, 100.0)

static func rhythm_duration(attacker_agi: int, defender_agi: int,
		attacker_sp: int, defender_sp: int) -> float:
	var advantage := (attacker_agi - defender_agi) + (attacker_sp - defender_sp)
	var duration := MAX_RHYTHM_SECONDS - float(advantage) * RHYTHM_SECONDS_PER_POINT
	return clampf(duration, MIN_RHYTHM_SECONDS, MAX_RHYTHM_SECONDS)

static func rhythm_zone(marker_position: float) -> RhythmResult:
	var distance := absf(marker_position - 0.5)
	if distance <= POINT_HALF_WIDTH:
		return RhythmResult.POINT
	if distance <= BEAM_HALF_WIDTH:
		return RhythmResult.BEAM
	return RhythmResult.MISS

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
