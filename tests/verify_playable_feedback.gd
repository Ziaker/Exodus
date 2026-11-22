extends SceneTree
const SANDBOX := preload("res://tests/progress_sandbox.gd")

class ControlledBattle extends "res://scripts/battle/playable_controller.gd":
	func _ai_roll(_a: BattleUnit, _b: BattleUnit) -> int:
		return BattleMath.RhythmResult.MISS
	func _defender_reaction(_a: BattleUnit, _b: BattleUnit) -> int:
		return BattleMath.RhythmResult.MISS

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
	root.add_child(battle)
	return battle

func key(battle: Control, code: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = code
	battle.hud._input(event)

func reserve(battle: Control) -> void:
	battle.submit_command(battle.hud.command_options.find("REACT"))

func _run() -> void:
	var battle := fresh()
	await process_frame
	await process_frame
	var rows := 0
	for hit in battle.hud.hitboxes:
		if not String(hit.key).begins_with("live-command:"): continue
		rows += 1
		check(not hit.rect.intersects(battle.hud.BATTLE_LOG_RECT), "Battle log must not cover any command row")
		check(battle.hud.COMMAND_RECT.encloses(hit.rect), "Every command row must stay inside the HTML command window")
		check(hit.rect.position.y >= 333, "Every command must be below the battlefield, in the footer")
		check(hit.rect.end.y <= 416, "Every command must fit inside the screen")
		for who in battle.hud.STATUS_RECTS:
			check(not hit.rect.intersects(who), "Commands must not cover either character's status")
	check(rows == 5, "All five Fallen commands must be visible and clickable")
	battle.submit_command(0)
	check(battle.hud.mark_targets().keys() == ["enemy:0"], "The enemy being chosen must carry the green brackets")
	key(battle, KEY_X)
	check(battle.hud.mode == "command", "X must return from target selection")
	check(battle._fallen.acts_available == 2, "X must not consume an uncommitted act")
	key(battle, KEY_X)
	check(battle.hud.mode == "turn", "X must close the own-turn command window")
	key(battle, KEY_Z)
	check(battle.hud.mode == "command", "Z must reopen the same own-turn menu")
	battle.submit_command(0); battle.submit_target(0)
	# HTML lab: the attack rail sits over the targeted enemy, above its name, clear of the log.
	check(battle.rhythm.style == "attack", "Player attack must use the attack rail")
	check(battle.hud.enemy_column(0).encloses(battle.rhythm.get_rect()), "Attack rail must sit inside the targeted enemy column")
	check(not battle.rhythm.get_rect().intersects(battle.hud.BATTLE_LOG_RECT), "Rhythm must not cover the log")
	check(battle.rhythm._label.text.contains("ATTACK"), "Attack timing must be labeled ATTACK")
	check(battle.rhythm._label.text.contains("FALLEN") and battle.rhythm._label.text.contains("FOE A"), "Timing must identify attacker and target")
	battle.rhythm._finish(BattleMath.RhythmResult.MISS)
	check(battle.hud._log_text().contains("MISS"), "Resolved miss must be visible in the drawn log")
	check(battle.hud.message.contains("FALLEN") and battle.hud.message.contains("FOE A"), "Result must preserve both combatants")
	for i in 120:
		if not battle.fx.is_busy(): break
		await process_frame
	key(battle, KEY_X)
	check(battle.hud.mode == "command" and battle.active_actor == battle._ally, "X must dismiss feedback and proceed")
	battle.queue_free(); await process_frame
	battle = fresh()
	reserve(battle); reserve(battle)
	check(battle.hud.announcement_text.contains("→ ") and battle.hud.announcement_text.begins_with("FOE "), "Enemy announcement must name attacker and defender on the field")
	check(battle.hud.announcement_age < 0.75, "Enemy announcement must be animating")
	check(battle.fx.count_kind("WHITEN") == 1, "Attacking enemy must flash (RMXP whiten) at its announcement")
	check(battle.hud.alert_visible() and battle.hud.alert_unit == battle.action_attacker, "Announcing enemy must show the red alert")
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
	check(battle.hud.STATUS_RECTS[battle.hud.players.find(battle.action_defender)].encloses(battle.rhythm.get_rect()), "Defense rail must sit inside the defender's status panel")
	check(battle.rhythm._label.text.contains("DEFEND"), "Defensive rhythm must not look like an attack")
	check(battle.rhythm._label.text.contains("FALLEN"), "Defensive rhythm must identify the defender")
	battle.rhythm._finish(BattleMath.RhythmResult.POINT)
	check(battle.hud._log_text().contains("DODGE"), "Perfect defense feedback must remain visible in the log")
	battle.queue_free(); await process_frame
	battle = fresh()
	reserve(battle)
	battle._fallen.acts_available = 0
	battle._ally.acts_available = 1
	battle.submit_command(2); battle.proceed()
	check(battle.hud.mode == "announce", "Enemy attack must be announced even if nobody can react")
	check(battle.hud.announcement_text == "NO REACTION AVAILABLE", "No-act announcement must say no reaction is available")
	key(battle, KEY_Z)
	check(battle.hud.mode == "continue", "Announced attack must resolve only after confirmation")
	battle.queue_free(); await process_frame
	print("PLAYABLE_FEEDBACK_OK: %d checks; X back/deny, actor/target labels, attack/defense, enemy announcements, outcomes" % checks)
	quit(0)

func _finalize() -> void:
	SANDBOX.end()
