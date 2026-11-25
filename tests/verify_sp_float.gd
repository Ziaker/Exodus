extends SceneTree
const SANDBOX := preload("res://tests/progress_sandbox.gd")

class ControlledBattle extends "res://scripts/battle/playable_controller.gd":
	func _enemy_skill_pick(_n: int) -> int: return 0
	func _ai_roll(_a: BattleUnit, _b: BattleUnit) -> int:
		return BattleMath.RhythmResult.MISS
	func _defender_reaction(_a: BattleUnit, _b: BattleUnit) -> int:
		return BattleMath.RhythmResult.MISS
	func _enemy_counter_roll(_e: BattleUnit) -> bool:
		return false

var checks := 0

func _initialize() -> void:
	SANDBOX.begin()
	call_deferred("_run")

func check(ok: bool, reason: String) -> void:
	if not ok:
		push_error(reason)
		quit(1)
		assert(ok, reason)
	checks += 1

func _run() -> void:
	var battle := ControlledBattle.new()
	battle.offer_reserve = true
	root.add_child(battle)
	for _i in 20:
		await process_frame
	var hud: Control = battle.hud
	var hero: BattleUnit = battle._fallen
	var foe: BattleUnit = hud.opponents[0]
	check(hud.sp_floats().is_empty(), "No SP letters float before any SP change")

	# D-100 (creator 2026-11-25): a gain floats green from its unit to that side's SP label.
	hero.add_sp(1)
	await process_frame
	check(hud.sp_floats().size() == 1, "A hero gaining SP starts one float")
	var gain: Dictionary = hud.sp_floats()[0]
	check(hud.sp_float_text(gain).length() == 1 and hud.SP_ALPHABET.contains(hud.sp_float_text(gain)), "A gain shows one Hebrew letter, never the value")
	check(gain.unit == hero and gain.to == hud._sp_label_own, "The hero's float ends at the left SP label")
	# Creator 2026-11-25: a hero's gain comes out of an enemy, never out of the hero's card.
	var foe_art: Rect2 = hud.enemy_sprite_rect(0).grow(10)
	check(foe_art.has_point(gain.from), "A hero's SP gain leaves from an enemy, not from the hero's card")
	check(gain.to.y > hud.HEADER_BASELINE and gain.to.y < hud.TURN_STRIP_TOP, "The letters land under the SP label, above the turn strip")
	check(hud.SP_FLOAT_INKS.gain == Color("81e6a8"), "Gains are green")

	# A hero losing SP still leaves from the hero's own side (top of the log above its window).
	hero.add_sp(-1)
	await process_frame
	var own_loss: Dictionary = hud.sp_floats()[hud.sp_floats().size() - 1]
	check(own_loss.unit == hero and is_equal_approx(own_loss.from.y, hud.BATTLE_LOG_RECT.position.y - 2.0), "A hero's loss leaves from the hero's side")

	# A loss floats red; an enemy's float ends at the right label.
	foe.add_sp(-2)
	await process_frame
	var loss: Dictionary = hud.sp_floats()[hud.sp_floats().size() - 1]
	check(loss.unit == foe and int(loss.amount) == -2, "An enemy losing SP starts a float for -2")
	check(hud.sp_float_text(loss).length() == 1 and hud.SP_ALPHABET.contains(hud.sp_float_text(loss)), "A loss shows one Hebrew letter, never the value")
	check(loss.to == hud._sp_label_foe, "The enemy's float ends at the right SP label")
	check(hud.SP_FLOAT_INKS.loss == Color("ff6b6b"), "Losses are red")
	check(loss.from.y < hud.SCREEN.y * 0.6, "The enemy's float starts at the enemy, above the heroes")

	# An enemy gaining and a hero losing show the same colours on the other sides.
	foe.add_sp(3)
	hero.add_sp(-1)
	await process_frame
	var kinds := {}
	for f in hud.sp_floats():
		kinds["%s:%d" % ["hero" if f.unit == hero else "foe", signi(int(f.amount))]] = true
	check(kinds.has("foe:1") and kinds.has("hero:-1"), "Enemy gains and hero losses float too")

	# A steal shows red on the loser and green on the winner in the same frame.
	var before: int = hud.sp_floats().size()
	var foe_b: BattleUnit = hud.opponents[1]
	var stolen := mini(2, foe_b.current_sp)
	foe_b.add_sp(-stolen)
	hero.add_sp(stolen)
	await process_frame
	var added: Array = hud.sp_floats().slice(before)
	var from_b := false
	for f in added:
		if f.unit == hero: from_b = hud.enemy_sprite_rect(1).grow(10).has_point(f.from)
	check(from_b, "In a steal the hero's letter leaves from the enemy that lost the SP")
	check(added.size() == 2, "A steal starts two floats")
	var winner_green := false
	var loser_red := false
	for f in added:
		if f.unit == hero and int(f.amount) > 0: winner_green = true
		if f.unit == foe_b and int(f.amount) < 0: loser_red = true
	check(winner_green and loser_red, "A steal is red on the loser and green on the winner")

	# The letter is random: over many changes more than one different letter shows up.
	var seen := {}
	for _k in 12:
		hero.add_sp(1)
		await process_frame
		seen[hud.sp_float_text(hud.sp_floats()[hud.sp_floats().size() - 1])] = true
	check(seen.size() > 3, "The letters vary from one SP change to the next")

	# Timing: the letters last SP_FLOAT_TIME, fade at the end, then are dropped.
	check(is_equal_approx(hud.SP_FLOAT_TIME, 0.5), "Floats last 0.5 s")
	# Arc: every letter bends away from the straight line, at its own speed, over the same time.
	var bent := 0
	var curves := {}
	for f in hud.sp_floats():
		var mid_age: float = hud.SP_FLOAT_TIME * 0.5
		var straight: Vector2 = f.from.lerp(f.to, 0.5)
		if hud.sp_float_pos(f, hud.SP_FLOAT_TIME * 0.0) == f.from and hud.sp_float_pos(f, hud.SP_FLOAT_TIME) == f.to: bent += 1
		curves[snappedf(float(f.curve), 0.01)] = true
		check(absf(float(f.arc)) >= hud.SP_ARC_MIN, "Every letter flies along an arc")
		check(hud.sp_float_pos(f, mid_age).distance_to(straight) > 1.0, "The middle of the flight is off the straight line")
	check(bent == hud.sp_floats().size() and curves.size() > 3, "Arcs start at the source, end at the label and have random speeds")
	check(hud.sp_float_alpha(0.0) == 1.0 and hud.sp_float_alpha(hud.SP_FLOAT_TIME) == 0.0, "Floats fade out at the end")
	await create_timer(1.0).timeout
	check(hud.sp_floats().is_empty(), "Finished floats are dropped")

	# No change, no float; a new battle's first reading is silent.
	await process_frame
	check(hud.sp_floats().is_empty(), "Nothing floats while SP is unchanged")

	print("verify_sp_float: %d checks OK" % checks)
	await process_frame
	quit(0)
