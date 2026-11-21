extends "res://prototypes/combat-ui/preview-xp.gd"
## Keeps the reviewed geometry and artwork; all displayed resources come from BattleUnit.

const COMMAND_RECT := Rect2(6, 337, 110, 75)
const STATUS_RECTS := [Rect2(124, 338, 204, 48), Rect2(334, 338, 204, 48)]
const RHYTHM_RECT := Rect2(92, 234, 360, 52)

var battle: Control
var players: Array[BattleUnit] = []
var opponents: Array[BattleUnit] = []
var command_options: Array[String] = []
var command_index := 0
var feedback := ""


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if font == null: return
	hitboxes.clear()
	ink = Color("f0eadd")
	accent = Color("e8ca99")
	_world()
	_text(_round_caption(), 12, 12, ink, 11)
	for i in opponents.size():
		_enemy(168.0 + i * 208.0, i)
	draw_rect(LOG_RECT, Color.BLACK)
	_text(message, 12, 297, ink, 10)
	_text(feedback, 12, 308, accent, 10)
	_sp_meter()
	_box(Rect2(0, STAGE_HEIGHT, 544, 83))
	for who in players.size():
		_character(who, STATUS_RECTS[who])
	draw_line(Vector2(120, 337), Vector2(120, 412), Color("62616d"))
	draw_line(Vector2(331, 342), Vector2(331, 383), Color("62616d"))
	draw_line(Vector2(130, 388), Vector2(532, 388), Color("62616d"))
	_text(_footer_caption(), 132, 404, Color("cecad0"), 10)
	if mode == "command": _command_window()
	else: _overlay()


func _round_caption() -> String:
	var context: String = battle.phase_text
	if mode in ["react", "announce"]:
		context = "ENEMY ATTACK: %s -> %s" % [battle.short_name(battle.action_attacker), battle.short_name(battle.action_defender)]
	elif mode == "timing":
		context = "DEFEND: %s vs %s" % [battle.short_name(battle.action_defender), battle.short_name(battle.action_attacker)] if battle.timing_role == "DEFEND" else "ATTACK: %s -> %s" % [battle.short_name(battle.action_attacker), battle.short_name(battle.action_defender)]
	elif mode == "target":
		context = "%s -> %s | SELECT TARGET" % [battle.short_name(battle.active_actor), battle.short_name(battle.target_units()[target])]
	elif mode in ["command", "turn"] and battle.active_actor != null:
		context = "%s | %s: %d ACTS" % [battle.phase_text, battle.active_actor.display_name, battle.active_actor.acts_available]
	return "TURN %d | %s" % [battle.state.round_number, context]


func _target_caption() -> String:
	# Target is already named in the top status line and next to the sprite.
	return ""


func _footer_caption() -> String:
	match mode:
		"command":
			if command_options[command_index] == "REACT": return "REACT: reserve acts    Z: choose    X: back"
			return "REACTION: Z confirm | X back" if battle.in_reaction else "Up / Down: command    Z: choose    X: back"
		"turn": return "Z / Enter: commands    X: back"
		"target": return "Left / Right: target    Z: confirm    X: back"
		"react": return "Tab: reactor    Z: react    X: deny"
		"continue": return "Resolving effect..." if battle.fx.is_busy() else "Z / Enter / X or click to continue"
		"announce": return "ENEMY ATTACK | Z / Enter: resolve"
		"timing": return "Z / Enter: stop marker"
		"result": return "Z / Enter or click: play again"
	return ""


func _text(value: String, x: float, y: float, color: Color = Color.WHITE, px: int = 13) -> void:
	var visible_text := value
	if y in [297, 303, 308]:
		while font.get_string_size(visible_text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > 518:
			visible_text = visible_text.left(visible_text.length() - 4) + "..."
	super._text(visible_text, x, y, color, px)


func _enemy(x: float, index: int) -> void:
	if index >= opponents.size() or not opponents[index].is_alive():
		return
	var saved_mode := mode
	if mode == "target" and battle.target_side == "player": mode = "busy"
	super._enemy(x, index)
	mode = saved_mode
	var role := unit_role(opponents[index])
	if not role.is_empty():
		var art_rect := _enemy_art_rect(x, battler_regions[index % 2])
		_text(role, maxf(12, x - role.length() * 3), art_rect.position.y - 6, accent, 11)
	if mode == "target" and battle.target_side == "enemy" and target == index:
		var art_rect := _enemy_art_rect(x, battler_regions[index % 2])
		var label := "%s  HP %d/%d" % [opponents[index].display_name, opponents[index].current_hp, opponents[index].stats.max_hp]
		_text(label, maxf(12, x - 96), art_rect.end.y + 14, ink, 10)


func _character(who: int, r: Rect2) -> void:
	if who >= players.size():
		return
	var unit := players[who]
	var x := r.position.x + 9
	var role := unit_role(unit)
	var badge: String = {"DEFENDING": "DEF", "DODGED": "DEF", "BLOCKED": "DEF", "ATTACKER": "ATK", "TARGET": "TARGET", "HEALING": "HEAL", "RESTING": "REST", "ABSORBING": "ABS"}.get(role, "")
	var title := unit.display_name + (" [DOWN]" if not unit.is_alive() else (" [" + badge + "]" if not badge.is_empty() else ""))
	_text(title, x, 351, accent if who == actor or not role.is_empty() else ink, 12)
	_text("HP %d/%d" % [unit.current_hp, unit.stats.max_hp], x, 369, Color("a4c7b4"), 12)
	_text("EN %d/%d" % [unit.current_en, unit.stats.max_en], x + 100, 369, Color("aebcd6"), 12)
	_text("ACTS", x + 115, 351, Color("c4bec4"), 10)
	for i in 4:
		var pip := Rect2(x + 145 + i * 10, 344, 6, 6)
		if i < unit.acts_available:
			draw_rect(pip, accent if who == actor else ink)
		else:
			draw_rect(pip, Color("827d8a"), false, 1)
	_text("SP %d    STOCK %d" % [unit.current_sp, unit.stored_acts], x, 382, Color("b7b0b7"), 10)
	if mode == "target" and battle.target_side == "player":
		if target == who: draw_rect(r, accent, false, 1)
		hitboxes.append({"rect": r, "key": "player-target:" + str(who)})
	elif mode == "react":
		if unit == battle.reaction_actor: draw_rect(r.grow(-1), accent, false, 1)
		hitboxes.append({"rect": r, "key": "reactor:" + str(who)})


func _sp_meter() -> void:
	if players.is_empty():
		return
	var own: int = players[0].current_sp
	var rival: int = battle._strongest_enemy_sp()
	var share := float(own) / maxi(1, own + rival)
	draw_rect(Rect2(0, 310, 544, 23), Color("181622cc"))
	_text("SP", 10, 322, ink, 11)
	_text("FALLEN %d" % own, 33, 322, ink, 10)
	_text("ENEMY %d" % rival, 464, 322, ink, 10)
	draw_rect(Rect2(33, 325, 500, 4), Color("3c2830"))
	for i in 50:
		draw_rect(Rect2(34 + i * 10, 326, 9, 2), GREEN if (i + 0.5) / 50.0 < share else RED)


func _command_window() -> void:
	# Fixed footer column. Never repositioned over the battlefield or the log.
	_box(COMMAND_RECT)
	for i in command_options.size():
		var row := Rect2(COMMAND_RECT.position + Vector2(5, 5 + i * 13), Vector2(100, 13))
		if i == command_index:
			draw_rect(row, Color("5c546d99"))
			draw_rect(row, Color("a7a0b466"), false, 1)
		_text(command_options[i].capitalize(), row.position.x + 8, row.position.y + 10, ink, 11)
		hitboxes.append({"rect": row, "key": "live-command:" + str(i)})


func _overlay() -> void:
	# Context controls use the same reserved footer column, never cover status text.
	_box(COMMAND_RECT)
	match mode:
		"react":
			_button(Rect2(11, 342, 100, 22), "REACT [Z]", "live-react")
			_button(Rect2(11, 367, 100, 22), "DENY [X]", "live-pass")
			_text("Tab: reactor", 14, 405, accent, 10)
		"timing":
			_text(battle.timing_role, 16, 356, ink, 11)
			_text("[Z] STOP", 16, 375, accent, 11)
			hitboxes.append({"rect": COMMAND_RECT, "key": "live-confirm"})
			hitboxes.append({"rect": RHYTHM_RECT, "key": "live-confirm"})
		"absorb":
			_text("ABSORB [Z]", 16, 355, ink, 11)
			_text("Mash!", 16, 374, accent, 11)
			_text("Presses: %d" % battle._mash_count, 16, 397, ink, 10)
			hitboxes.append({"rect": COMMAND_RECT, "key": "live-confirm"})
		"target":
			_text("CHOOSE", 16, 355, ink, 11)
			_text("TARGET", 16, 370, ink, 11)
			_text("[X] BACK", 16, 397, accent, 11)
			hitboxes.append({"rect": COMMAND_RECT, "key": "live-back"})
		_:
			_text("[Z]", 16, 355, accent, 12)
			_text("Commands" if mode == "turn" else ("Play again" if mode == "result" else "Continue"), 16, 376, ink, 11)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		if mode in ["continue", "result", "announce", "turn"]:
			battle.handle_confirm()
			return
		for hit in hitboxes:
			if not hit.rect.has_point(get_local_mouse_position()):
				continue
			var key: String = hit.key
			if key.begins_with("live-command:"):
				command_index = int(key.split(":")[1])
				battle.submit_command(command_index)
			elif key.begins_with("target:") and mode == "target":
				if battle.target_side == "enemy": battle.submit_target(int(key.split(":")[1]))
			elif key.begins_with("player-target:") and mode == "target":
				battle.submit_target(int(key.split(":")[1]))
			elif key.begins_with("reactor:"):
				battle.select_reactor(int(key.split(":")[1]))
			elif key == "live-react": battle.answer_reaction(true)
			elif key == "live-pass": battle.answer_reaction(false)
			elif key == "live-confirm": battle.handle_confirm()
			elif key == "live-back": battle.handle_back()
			break
	elif event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if event.keycode in [KEY_Z, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			battle.handle_confirm()
		elif event.keycode in [KEY_X, KEY_ESCAPE]:
			battle.handle_back()
		elif mode == "react" and event.keycode in [KEY_TAB, KEY_LEFT, KEY_RIGHT]:
			for i in players.size():
				var next := (actor + i + 1) % players.size()
				if players[next].is_alive() and players[next].acts_available > 0:
					battle.select_reactor(next)
					break
		elif mode == "command" and event.keycode in [KEY_UP, KEY_DOWN]:
			command_index = posmod(command_index + (1 if event.keycode == KEY_DOWN else -1), command_options.size())
		elif mode == "target" and event.keycode in [KEY_LEFT, KEY_RIGHT]:
			var units: Array[BattleUnit] = battle.target_units()
			for i in units.size():
				target = posmod(target + (1 if event.keycode == KEY_RIGHT else -1), units.size())
				if units[target].is_alive(): break
	queue_redraw()


func unit_role(unit: BattleUnit) -> String:
	if mode in ["command", "turn", "target", "result"]: return ""
	if battle.phase_text in ["ITEM", "REACTION ITEM"]:
		return "HEALING" if unit == battle.action_attacker else ("HEAL TARGET" if unit == battle.action_defender else "")
	if battle.phase_text in ["REST", "REACTION REST"]:
		return "RESTING" if unit == battle.action_attacker else ""
	if battle.phase_text in ["ABSORB", "REACTION ABSORB"]:
		return "ABSORBING" if unit == battle.action_attacker else ("ABSORB TARGET" if unit == battle.action_defender else "")
	if unit == battle.action_attacker: return "ATTACKER"
	if unit == battle.action_defender:
		if mode == "continue":
			if battle.defense_result == BattleMath.RhythmResult.POINT: return "DODGED"
			if battle.defense_result == BattleMath.RhythmResult.BEAM: return "BLOCKED"
		return "DEFENDING" if mode == "timing" and battle.timing_role == "DEFEND" else "TARGET"
	return ""
