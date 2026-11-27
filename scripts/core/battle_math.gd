class_name BattleMath
extends RefCounted

## Pure combat formulas from docs/COMBAT_SPEC.md. No scene dependencies.

enum RhythmResult { POINT, BEAM, MISS }

const SP_GAIN_PER_EVENT: int = 1
const REST_EN_RECOVERY: int = 2
const BLOCK_ROLLS_PER_SP: int = 2
const THRESHOLD_RATIO: float = 0.7
const MAX_AVAILABLE_ACTS: int = 4
const MAX_STORED_ACTS: int = 4
## D-019 (implementada pela D-108): variação fixa de ±10%, sem depender da diferença de SP.
const BASE_VARIATION: float = 0.10
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
## D-049: counter-attack exchange on two rails (creator, 2026-11-22).
## Perfect interruption: a press while both moving pointers are within 2% of the bar.
const PERFECT_INTERRUPT_GAP: float = 0.02
const INTERRUPT_SP_PERFECT: int = 16
const INTERRUPT_SP_NORMAL: int = 4
## An attacked enemy with a reaction act counter-attacks 33% of the time.
const ENEMY_COUNTER_CHANCE: float = 0.33
enum CounterWinner { ENEMY = -1, TIE = 0, PLAYER = 1 }
## D-051 absorption (creator, 2026-11-22): SP dispute by mashing.
const ABSORB_MAX_PRESSES: int = 10
const ABSORB_SP_PER_PRESS: int = 2
const ABSORB_SECONDS: float = 2.0
const ABSORB_GAIN_POINTS: int = 2
const ABSORB_STATS: Array[StringName] = [&"atk", &"mak", &"defense", &"mef", &"agi"]
const STAT_LABELS := {&"atk": "ATK", &"mak": "MAK", &"defense": "DEF", &"mef": "MEF", &"agi": "AGI"}


## D-103 (creator, 2026-11-25): the mash result, resolved once when the time runs out
## or at the 10th press. Each counted press is worth 2 SP (D-051), taken from the
## target (only what it still has) and given to Fallen. ONE roll in [0, 100) against
## chance = max(0, start gap) + 1% per SP taken; a target drained to 0 SP is absorbed
## for sure. Zero presses never absorb (and take nothing).
static func absorb_result(target_sp: int, base_chance: int, presses: int, roll: float) -> Dictionary:
	var counted := clampi(presses, 0, ABSORB_MAX_PRESSES)
	var steal := mini(counted * ABSORB_SP_PER_PRESS, maxi(0, target_sp))
	var chance := maxi(0, base_chance) + steal
	return {"presses": counted, "steal": steal, "chance": chance,
		"absorbed": counted > 0 and (target_sp - steal <= 0 or roll < float(chance))}


## D-051: ATK/MAK/DEF/MEF/AGI whose value is a positive multiple of 8, highest first.
## Two or more: the player picks +2 in one or +1/+1 in two. One: +2 in it.
## None: +2 in the highest of those attributes.
static func absorb_gain_options(stats: UnitStats) -> Array[Dictionary]:
	var eligible: Array[StringName] = []
	for stat in ABSORB_STATS:
		var value := int(stats.get(stat))
		if value > 0 and value % 8 == 0:
			eligible.append(stat)
	eligible.sort_custom(func(a: StringName, b: StringName) -> bool: return int(stats.get(a)) > int(stats.get(b)))
	if eligible.is_empty():
		eligible.append(stats.highest_combat_stat())
	var options: Array[Dictionary] = []
	for stat in eligible:
		options.append({"label": "+2 %s" % STAT_LABELS[stat], "gains": {stat: ABSORB_GAIN_POINTS}})
	for i in eligible.size():
		for j in range(i + 1, eligible.size()):
			options.append({"label": "+1 %s / +1 %s" % [STAT_LABELS[eligible[i]], STAT_LABELS[eligible[j]]],
				"gains": {eligible[i]: 1, eligible[j]: 1}})
	return options

## D-021: +2 percentage points per SP advantage, capped at +20, and a final
## chance of at most 50%. A disadvantage never lowers the AGI base.
static func crit_chance(agi: int, sp_difference: int) -> float:
	var advantage := maxi(0, sp_difference)
	var sp_bonus := clampf(float(advantage) * CRIT_PER_SP_POINT, 0.0, CRIT_SP_BONUS_CAP)
	return clampf(float(agi) + sp_bonus, 0.0, CRIT_FINAL_CAP)


## D-109 (criador 2026-11-25): todo golpe com barra acerta. Só há desvio de verdade quando o
## alvo DEFENDE (paga 1 ACT) e para no centro da barra de defesa (D-015: a defesa perfeita
## prevalece sobre o ataque perfeito). Contato continua liberando dano, Press Turn e SP.
static func has_contact(_attack_timing: RhythmResult,
		defense_timing: RhythmResult) -> bool:
	return defense_timing != RhythmResult.POINT


## D-109: parte do dano que entra, pelo marco do ataque: trilha branca (pontas) 50%,
## faixa lateral (cinza na fala do criador) 80%, centro (amarelo) 100%. Se o alvo defendeu
## e parou na faixa lateral, entra metade, qualquer que seja o marco do ataque.
const ATTACK_MARK_WHITE: float = 0.5
const ATTACK_MARK_GRAY: float = 0.8
const ATTACK_MARK_YELLOW: float = 1.0
const DEFENSE_BLOCK: float = 0.5

static func strike_multiplier(attack_timing: int, defense_timing: int) -> float:
	if defense_timing == RhythmResult.BEAM:
		return DEFENSE_BLOCK
	match attack_timing:
		RhythmResult.POINT: return ATTACK_MARK_YELLOW
		RhythmResult.BEAM: return ATTACK_MARK_GRAY
	return ATTACK_MARK_WHITE


## D-109: o dano com o marco aplicado. Arredonda (não trunca) para um golpe de 1 não virar 0.
static func scaled_damage(amount: int, attack_timing: int, defense_timing: int) -> int:
	return maxi(0, int(round(float(amount) * strike_multiplier(attack_timing, defense_timing))))

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


## D-107 BLIND (SANVERIM): a blinded unit's POINT zone is smaller, so it misses more often.
const BLIND_POINT_MULT := 0.5
## D-112 ZOHAR: widens the unit's POINT zone (light counterpart to Sanverim).
const ZOHAR_POINT_MULT := 1.5


## POINT half-width of `own` against `rival`, with BLIND and ZOHAR applied.
static func unit_point_half(own: BattleUnit, rival: BattleUnit) -> float:
	var half := point_half_width(own.effective_agi(), rival.effective_agi(), own.current_sp, rival.current_sp)
	if own.has_status(&"blind"):
		half = maxf(POINT_MIN_HALF_WIDTH * 0.5, half * BLIND_POINT_MULT)
	if own.has_status(&"zohar"):
		half = minf(BEAM_HALF_WIDTH * 0.9, half * ZOHAR_POINT_MULT)
	return half


## D-049: the opponent's red pointer moves at base speed x AGI_opponent / AGI_player,
## so its crossing time is the base duration x AGI_player / AGI_opponent.
static func counter_red_duration(base_seconds: float, opponent_agi: int, player_agi: int) -> float:
	return base_seconds * float(maxi(1, player_agi)) / float(maxi(1, opponent_agi))


## D-049: only two moving pointers can align (the crossing); a stopped one never counts.
static func pointers_aligned(white_position: float, red_position: float) -> bool:
	return absf(white_position - red_position) <= PERFECT_INTERRUPT_GAP + 0.000001


static func rhythm_rank(result: int) -> int:
	match result:
		RhythmResult.POINT: return 2
		RhythmResult.BEAM: return 1
	return 0


## D-049 exchange. A perfect press wins as POINT and steals 16 SP. Otherwise the
## better result (POINT > BLAST > MISS) interrupts the other and steals 4 SP. Equal
## results (both hit or both miss) resolve both strikes and steal nothing.
static func resolve_counter(player_result: int, enemy_result: int,
		player_perfect: bool = false, enemy_perfect: bool = false) -> Dictionary:
	var outcome := {"winner": CounterWinner.TIE, "perfect": false, "steal": 0,
		"player_timing": player_result, "enemy_timing": enemy_result}
	if player_perfect: outcome.player_timing = RhythmResult.POINT
	if enemy_perfect: outcome.enemy_timing = RhythmResult.POINT
	if player_perfect != enemy_perfect:
		outcome.winner = CounterWinner.PLAYER if player_perfect else CounterWinner.ENEMY
		outcome.perfect = true
		outcome.steal = INTERRUPT_SP_PERFECT
		return outcome
	var mine := rhythm_rank(outcome.player_timing)
	var theirs := rhythm_rank(outcome.enemy_timing)
	if mine != theirs:
		outcome.winner = CounterWinner.PLAYER if mine > theirs else CounterWinner.ENEMY
		outcome.steal = INTERRUPT_SP_NORMAL
	return outcome


static func rhythm_zone(marker_position: float,
		point_half: float = POINT_HALF_WIDTH) -> RhythmResult:
	return rhythm_zone_at(marker_position, 0.5, point_half)


## Zone of a press against a hit mark centred at `center` (Lunge: 0.35 and 0.65).
static func rhythm_zone_at(marker_position: float, center: float,
		point_half: float = POINT_HALF_WIDTH) -> RhythmResult:
	var distance := absf(marker_position - center)
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

## Result keys: amount, crit, sp_roll, variation, base. D-119: no affinity.
## Magic damage uses the same formula with MAK for ATK and MEF for DEF (creator 2026-11-23).
## attacker_atk is a float so ATK stages (+25% each) keep their fraction.
static func physical_damage(power: int, attacker_atk: float, attacker_agi: int,
		defender_defense: int, attacker_sp: int, defender_sp: int,
		rng: RandomNumberGenerator, untyped: bool = false) -> Dictionary:
	var difference := attacker_sp - defender_sp
	var base := float(power) * float(attacker_atk) / maxf(float(defender_defense), 1.0)
	if untyped:
		# D-131 DMG ("25 DMG + MAK"): sem tipagem = poder + atributo, sem DEF/MEF (ritmo, SP e variacao continuam).
		base = float(power) + float(attacker_atk)

	var sp_roll := sp_bonus_roll(difference, rng)
	var variation := rng.randf_range(-BASE_VARIATION, BASE_VARIATION)

	var crit := critical_roll(attacker_agi, attacker_sp, defender_sp, rng)
	var amount := base + float(sp_roll)
	amount *= 1.0 + variation
	if crit:
		amount *= CRIT_MULTIPLIER

	return {
		"amount": maxi(0, int(round(amount))),
		"base": base,
		"crit": crit,
		"sp_roll": sp_roll,
		"variation": variation,
	}

## D-108 (criador 2026-11-25: "tira isso de NUNCA causar dano a inimigos com alta defesa"): só a
## vantagem de SP soma ao dano (1 a ΔSP). Ter menos SP não tira dano: o sorteio negativo saiu.
## Sem sorteio com SP igual ou menor, para não consumir o RNG.
static func sp_bonus_roll(difference: int, rng: RandomNumberGenerator) -> int:
	if difference <= 0:
		return 0
	return rng.randi_range(1, difference)

static func critical_roll(attacker_agi: int, attacker_sp: int, defender_sp: int,
		rng: RandomNumberGenerator) -> bool:
	return rng.randf_range(0.0, 100.0) < crit_chance(attacker_agi, attacker_sp - defender_sp)
