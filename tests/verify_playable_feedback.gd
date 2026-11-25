extends SceneTree
const SANDBOX := preload("res://tests/progress_sandbox.gd")

class ControlledBattle extends "res://scripts/battle/playable_controller.gd":
	## ATTACK-flow checks: the enemy AI never draws a skill here (skills: verify_playable_skills).
	func _enemy_skill_pick(_n: int) -> int: return 0
	func _ai_roll(_a: BattleUnit, _b: BattleUnit) -> int:
		return BattleMath.RhythmResult.MISS
	func _defender_reaction(_a: BattleUnit, _b: BattleUnit) -> int:
		return BattleMath.RhythmResult.MISS
	func _enemy_counter_roll(_e: BattleUnit) -> bool:
		return false  # D-049 counters are covered by verify_playable_counter.gd

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

func fresh() -> Control:
	var battle := ControlledBattle.new()
	battle.offer_reserve = true  # creator 2026-11-24: REACT left the own-turn menu
	root.add_child(battle)
	return battle

func key(battle: Control, code: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = code
	battle.hud._input(event)

## Creator 2026-11-23: FOE B plays right after Fallen, before Yoch, so once Fallen reserves
## the enemy announces at once; a second call (Yoch's REACT) then has no own turn to use.
func reserve(battle: Control) -> void:
	if battle.hud.mode not in ["plan", "command"]: return
	battle.submit_command(battle.hud.command_options.find("REACT"))

func _run() -> void:
	var battle := fresh()
	# D-046: sete linhas (5 comandos + EXEC + UNDO) precisam da animação do menu.
	for _i in 20:
		await process_frame
	var rows := 0
	for hit in battle.hud.hitboxes:
		if not (String(hit.key).begins_with("live-command:") or String(hit.key).begins_with("live-plan:")): continue
		rows += 1
		check(not hit.rect.intersects(battle.hud.BATTLE_LOG_RECT), "Battle log must not cover any command cell")
		check(battle.hud.COMMAND_RECT.encloses(hit.rect), "Every command cell must stay inside the command window")
		check(hit.rect.end.y <= battle.hud.SCREEN.y, "Every command must fit inside the screen")
		for who in battle.hud.STATUS_RECTS:
			check(not hit.rect.intersects(who), "Commands must not cover either character's status")
	# D-058 (creator 2026-11-25): the round's turn order sits under the top line, fastest
	# first, with the unit whose turn it is filled.
	var strip: Array = battle.hud.turn_strip_entries()
	var strip_rects: Array = battle.hud.turn_strip_rects()
	check(strip.size() == battle.state.turn_order.size(), "Every combatant alive is in the turn strip")
	for i in strip.size():
		check(strip[i].unit == battle.state.turn_order[i], "The strip follows the round's AGI order")
		check(Rect2(Vector2.ZERO, battle.hud.SCREEN).encloses(strip_rects[i]), "Each turn chip stays on screen")
		check(strip_rects[i].position.y > 34.0, "The strip sits under the top line and the announcement line (baseline 30, 12 px)")
		if i > 0: check(strip_rects[i].position.x > strip_rects[i - 1].end.x, "Turn chips never overlap")
		var tag_top: float = battle.hud.FIELD_RECT.position.y + 16.0 - 25.0
		check(strip_rects[i].end.y < tag_top, "The strip stays above the enemy names and role tags")
	var currents: Array = strip.filter(func(e): return e.current)
	check(currents.size() == 1 and currents[0].unit == battle._fallen, "Fallen's chip is the one marked as the current turn")
	# Creator 2026-11-24: nothing queued yet, so no EXEC/UNDO (REACT is on: test driver).
	check(rows == 5 and not battle.hud.plan_options.has("EXEC"), "Fallen's empty plan: the commands only, no EXEC or UNDO (%d)" % rows)
	battle.submit_command(0)
	check(battle.hud.mark_targets().keys() == ["enemy:0"], "The enemy being chosen must carry the green brackets")
	key(battle, KEY_X)
	check(battle.hud.mode == "plan", "X must return from target selection to D-046 planning")
	check(battle._fallen.acts_available == 2, "X must not consume an uncommitted act")
	key(battle, KEY_X)
	check(battle.hud.mode == "plan", "X with an empty plan must not end the turn")
	key(battle, KEY_Z)
	# D-057 (creator 2026-11-25): the target is chosen while planning, not mid-execution.
	check(battle.hud.mode == "target", "D-057: Z on FIGHT asks for its target while planning")
	key(battle, KEY_Z)
	check(battle._planned.size() == 1 and battle._planned_targets[0] == battle.hud.opponents[0], "Z must commit one command, with its target, to the D-046 plan")
	battle.exec_plan()
	check(battle.hud.mode == "timing", "D-057: EXEC runs the plan without asking for the target again")
	# HTML lab: the attack rail sits over the targeted enemy, above its name, clear of the log.
	check(battle.rhythm.style == "attack", "Player attack must use the attack rail")
	check(battle.hud.enemy_column(0).encloses(battle.rhythm.get_rect()), "Attack rail must sit inside the targeted enemy column")
	check(not battle.rhythm.get_rect().intersects(battle.hud.BATTLE_LOG_RECT), "Rhythm must not cover the log")
	check(battle.rhythm._label.text.contains("ATTACK"), "Attack timing must be labeled ATTACK")
	check(battle.rhythm._label.text.contains("FALLEN") and battle.rhythm._label.text.contains("FOE A"), "Timing must identify attacker and target")
	battle.rhythm._finish(BattleMath.RhythmResult.MISS)
	# D-057: the log shows event sentences, not instructions or rhythm internals.
	check(battle.hud.visible_log_lines() == ["FALLEN attacks FOE A.", "FALLEN misses."], "Resolved miss must be told as events in the drawn log (%s)" % [battle.hud.visible_log_lines()])
	check(battle.roles.get(battle._fallen.id, "") == "ATTACK" and battle.roles.get(battle.hud.opponents[0].id, "") == "TARGET", "D-057: attacker and target carry their role tags until the result is confirmed")
	# D-060 (creator 2026-11-25): the names in the log take the colour of their role.
	var attack_line: Dictionary = battle.hud.events.filter(func(e): return e.text == "FALLEN attacks FOE A.").back()
	check(attack_line.names.get("FALLEN") == battle.hud.ROLE_ARROW_INKS.ATTACK and attack_line.names.get("FOE A") == battle.hud.ROLE_ARROW_INKS.TARGET, "Log names: the attacker in red, the target in yellow (%s)" % str(attack_line.names))
	var turn_line: Dictionary = battle.hud.events.filter(func(e): return e.text == "FALLEN's turn.").back()
	check(turn_line.names.is_empty(), "A line with no action on screen keeps plain names")
	check(battle.hud.message.contains("FALLEN") and battle.hud.message.contains("FOE A"), "Result must preserve both combatants")
	# D-059 (creator 2026-11-25): an arrow runs from the attacker to the target in 0.55 s,
	# then fades out fast.
	await process_frame
	var arrow_key := "%s>%s" % [battle._fallen.id, battle.hud.opponents[0].id]
	var arrows: Array = battle.hud.role_arrows()
	check(arrows.size() == 1 and arrows[0].key == arrow_key and not arrows[0].clash, "One arrow from Fallen to FOE A (%s)" % str(arrows.map(func(a): return a.key)))
	check(arrows[0].to.y < arrows[0].from.y, "The arrow points from the hero up to the enemy")
	check(not battle.hud.BATTLE_LOG_RECT.has_point(arrows[0].from) and not battle.hud.BATTLE_LOG_RECT.has_point(arrows[0].to), "The arrow ends never sit inside the log text")
	check(battle.hud.arrow_age(arrow_key) >= 0.0, "The arrow has started")
	check(is_equal_approx(battle.hud.ROLE_ARROW_RUN, 0.55), "The arrow runs for 0.55 s")
	check(battle.hud.arrow_run(0.275) > 0.0 and battle.hud.arrow_run(0.275) < 1.0 and battle.hud.arrow_alpha(0.275) == 1.0, "Halfway: half run, fully visible")
	check(battle.hud.arrow_run(0.55) == 1.0 and battle.hud.arrow_alpha(0.6) < 1.0 and battle.hud.arrow_alpha(0.55 + battle.hud.ROLE_ARROW_FADE) == 0.0, "At the target it fades out fast")
	var waited := 0
	while battle.hud.arrow_age(arrow_key) < 0.75 and waited < 600:
		await process_frame
		waited += 1
	check(battle.hud.arrow_alpha(battle.hud.arrow_age(arrow_key)) == 0.0, "After the run and the fade the arrow is gone")
	# D-062 (creator 2026-11-25, revokes D-061): the role boxes stay while the role exists,
	# well past 0.3 s and past the arrow's fade; they go only when the roles are cleared.
	check(not ("ROLE_BOX_TIME" in battle.hud) and not battle.hud.has_method("role_box_visible"), "D-062: no timed cut of the role boxes is left")
	# drawn_role_boxes is what the role layer actually painted on its last draw.
	var box_roles := func() -> Array: return battle.hud.drawn_role_boxes.duplicate()
	var expected_boxes := ["ATTACK", "TARGET"]
	await process_frame
	var boxes_now: Array = box_roles.call()
	check(expected_boxes.all(func(b): return boxes_now.has(b)), "D-062: after the arrow fades the ATTACK and TARGET boxes are still drawn (%s)" % str(boxes_now))
	for i in 60: await process_frame
	boxes_now = box_roles.call()
	check(expected_boxes.all(func(b): return boxes_now.has(b)), "D-062: a second later the boxes are still drawn (%s)" % str(boxes_now))
	check(battle.roles.get(battle._fallen.id, "") == "ATTACK", "The role stays while its box is drawn")
	for i in 120:
		if not battle.fx.is_busy(): break
		await process_frame
	key(battle, KEY_X)
	await process_frame
	# D-057 (creator 2026-11-25): an act left after the queue is planned again in the same
	# turn; the turn only ends with 0 acts or REST.
	check(battle.hud.mode == "plan" and battle.active_actor == battle._fallen and battle._fallen.acts_available == 1, "X must dismiss feedback and let Fallen plan the act left in the same turn")
	check(battle.roles.is_empty(), "D-057: the role tags go away once the result is confirmed")
	await process_frame
	check(box_roles.call().is_empty(), "D-062: the role boxes go away when the roles are cleared (%s)" % str(box_roles.call()))
	battle.queue_free(); await process_frame
	battle = fresh()
	reserve(battle); reserve(battle)
	check(battle.hud.announcement_text.contains("→ ") and battle.hud.announcement_text.begins_with("FOE "), "Enemy announcement must name attacker and defender on the field")
	check(battle.hud.announcement_age < 0.75, "Enemy announcement must be animating")
	check(battle.fx.count_kind("WHITEN") == 1, "Attacking enemy must flash (RMXP whiten) at its announcement")
	check(battle.hud.alert_visible() and battle.hud.alert_unit == battle.action_attacker, "Announcing enemy must show the red alert")
	battle.hud.announce("ROUND 02")
	check(not battle.hud.alert_visible(), "Other announcements must not show the red alert")
	var marked: Dictionary = battle.hud.mark_targets()
	check(marked.has("player:%d" % battle.hud.players.find(battle.action_defender)), "The player chosen by the enemy must carry the green brackets")
	check(not marked.keys().any(func(k: String) -> bool: return k.begins_with("enemy:")), "No enemy is marked while the enemy attack is announced")
	battle.answer_reaction(true)
	key(battle, KEY_X)
	check(battle.hud.mode == "react", "X must go back from reaction commands to the reaction question")
	check(battle._fallen.acts_available == 2 and battle._ally.acts_available == 2, "Returning must not spend a reaction act")
	key(battle, KEY_X)
	check(battle.hud.mode == "continue", "X at reaction prompt must deny the reaction")
	check(battle._fallen.acts_available == 2 and battle._ally.acts_available == 2, "Deny must not spend a reaction act")
	battle.queue_free(); await process_frame
	battle = fresh()
	reserve(battle); reserve(battle)
	battle.select_reactor(0); battle.answer_reaction(true)
	battle.submit_command(battle.hud.command_options.find("DEFEND"))
	check(battle.rhythm.style == "defense", "Defense must use the panel rail")
	# D-058 (creator 2026-11-25): defenses run inside the battle log, not over the hero.
	check(battle.hud.BATTLE_LOG_RECT.encloses(battle.rhythm.get_rect()), "Defense rail must sit inside the battle log")
	check(battle.hud.rails_in_log(), "The log text gives way to the defense rail")
	check(battle.rhythm._label.text.contains("DEFEND"), "Defensive rhythm must not look like an attack")
	check(battle.rhythm._label.text.contains("FALLEN"), "Defensive rhythm must identify the defender")
	battle.rhythm._finish(BattleMath.RhythmResult.POINT)
	check(battle.hud.visible_log_lines().back() == "FALLEN dodges.", "Perfect defense must be told in the log (%s)" % [battle.hud.visible_log_lines()])
	check(battle.roles.get(battle._fallen.id, "") == "DEFEND", "D-057: the defending hero carries the DEFEND tag")
	battle.queue_free(); await process_frame
	battle = fresh()
	# Creator 2026-11-23: FOE B plays right after Fallen, so nobody may hold an act then.
	battle._ally.acts_available = 0
	battle.submit_command(battle.hud.command_options.find("REST")); battle.proceed()
	check(battle.hud.mode == "announce", "Enemy attack must be announced even if nobody can react")
	check(battle.hud.announcement_text == "NO REACTION AVAILABLE", "No-act announcement must say no reaction is available")
	key(battle, KEY_Z)
	check(battle.hud.mode == "continue", "Announced attack must resolve only after confirmation")
	battle.queue_free(); await process_frame
	# Creator 2026-11-25: two attacks queued on one enemy share the rail (D-043); when the
	# first hit kills it, the rail leaves the screen at once instead of staying over the
	# empty spot through the next prompt / result.
	battle = fresh()
	var doomed: BattleUnit = battle.hud.opponents[0]
	doomed.current_hp = 1
	# The last enemy standing: the kill ends the battle, so the result pause comes at once.
	for other in battle.hud.opponents:
		if other != doomed: other.current_hp = 0
	battle.basic_power = 999
	battle.submit_plan(0); battle.submit_target(0)
	battle.submit_plan(0); battle.submit_target(0)
	battle.exec_plan()
	check(battle.hud.mode == "timing" and battle.rhythm.visible, "The chained rail is on screen for the first hit")
	battle.rhythm._finish(BattleMath.RhythmResult.POINT)
	for i in 240:
		if battle.hud.mode in ["target", "continue", "plan"]: break
		await process_frame
	check(not doomed.is_alive(), "The first hit kills the enemy")
	check(not battle.rhythm.visible, "The rail disappears when its enemy dies (mode %s)" % battle.hud.mode)
	battle.queue_free(); await process_frame
	print("PLAYABLE_FEEDBACK_OK: %d checks; X back/deny, actor/target labels, attack/defense, enemy announcements, outcomes" % checks)
	# Let queued battle nodes and their pending coroutines release before exit
	# (quitting in the same frame crashed Godot at shutdown ~1 run in 7).
	await process_frame
	await process_frame
	quit(0)

func _finalize() -> void:
	SANDBOX.end()
