extends SceneTree
## Verificação headless do protótipo de navegação placeholder (sem assets).

var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, description: String) -> void:
	if not ok:
		push_error("FAIL: " + description)
		quit(1)
		assert(ok, description)
	checks += 1


func _new_map() -> Node2D:
	var packed: PackedScene = load("res://scenes/map/Map.tscn")
	var map: Node2D = packed.instantiate()
	root.add_child(map)
	return map


func _hold(code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	Input.parse_input_event(e)


func _release(code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = false
	Input.parse_input_event(e)


func _key(code: Key) -> void:
	_hold(code)
	_release(code)


func _close_dialogue(map: Node2D) -> void:
	for _i in 6:
		if not map.dialogue.is_open:
			break
		map.dialogue.advance()


func _run() -> void:
	_check(ResourceLoader.exists("res://scenes/map/Map.tscn"), "Map scene must exist")
	var map := _new_map()
	_check(map.current_id == "outskirts", "First map is the placeholder outskirts")
	_check(map.tiles.size() == PlaceholderMaps.MAP_H, "Map rows follow the 16 px grid")
	_check(map.tiles[0].length() == PlaceholderMaps.MAP_W, "Map columns follow the 16 px grid")
	_check(map.player.tile == Vector2i(3, 13), "Placeholder spawn tile")
	_check(map._tile_char(Vector2i(0, 0)) == PlaceholderMaps.WALL, "Border is a wall")
	_check(map._tile_char(map.player.tile) == PlaceholderMaps.SAND, "Spawn stands on sand")

	# Movement: one held direction = one tile; pressing into a wall only turns.
	_hold(KEY_RIGHT)
	map._process(0.016)
	_release(KEY_RIGHT)
	_check(map.player.moving and map.player.facing == MapPlayer.Facing.RIGHT,
			"Arrow key starts a grid step and sets facing")
	map._process(1.0)
	_check(map.player.tile == Vector2i(4, 13), "One press moves exactly one tile")
	map.player.place(Vector2i(1, 13))
	_hold(KEY_LEFT)
	map._process(0.016)
	_release(KEY_LEFT)
	_check(not map.player.moving and map.player.facing == MapPlayer.Facing.LEFT,
			"A wall blocks the step but still turns the character")
	map._process(1.0)
	_check(map.player.tile == Vector2i(1, 13), "Blocked step does not move the character")

	# Dialogue: pages, typewriter, advance and input lock.
	map.player.place(Vector2i(11, 8))
	map.player.set_facing(MapPlayer.Facing.UP)
	var e := InputEventKey.new()
	e.keycode = KEY_Z
	e.pressed = true
	map._unhandled_input(e)
	_check(map.dialogue.is_open and map.dialogue.speaker == "NPC-01",
			"Z on the faced NPC opens the dialogue box")
	_check(map.dialogue.pages.size() == 2, "Placeholder NPC has two dialogue pages")
	map.dialogue.process_text(0.1)
	_check(map.dialogue.shown_chars > 0.0 and not map.dialogue.fully_shown(),
			"Dialogue text is typed, not shown all at once")
	map.dialogue.advance()
	_check(map.dialogue.fully_shown(), "First advance reveals the whole page")
	_hold(KEY_RIGHT)
	map._process(1.0)
	_release(KEY_RIGHT)
	_check(map.player.tile == Vector2i(11, 8), "Dialogue locks movement")
	map.dialogue.advance()
	_check(map.dialogue.is_open and map.dialogue.page_index == 1, "Second advance goes to page two")
	map.dialogue.advance()
	_check(not map.dialogue.is_open, "Last advance closes the dialogue")

	# Chest: grants a placeholder item once and remembers it between areas.
	map.player.place(Vector2i(22, 6))
	map.player.set_facing(MapPlayer.Facing.UP)
	map.interact()
	_check(int(map.inventory.get("POTION", 0)) == 1, "Opening the chest grants one placeholder item")
	_check(map.opened_chests.has("outskirts:chest_01"), "Chest open state is remembered")
	_close_dialogue(map)
	map.interact()
	_check(map.dialogue.current_page().begins_with("Empty"), "An opened chest reports empty")

	# Doors: interaction and stepping both transfer, with a spawn away from the door.
	_close_dialogue(map)
	map.player.place(Vector2i(31, 13))
	map.player.set_facing(MapPlayer.Facing.RIGHT)
	map.interact()
	_check(map.current_id == "ruins" and map.player.tile == Vector2i(3, 13),
			"Door transfer opens the second placeholder area")
	_check(map._tile_char(map.player.tile) == PlaceholderMaps.FLOOR, "Second area uses ruin floor")
	_check(map.opened_chests.has("outskirts:chest_01"), "Chest state survives the transfer")
	map.player.place(Vector2i(27, 8))
	map.player.set_facing(MapPlayer.Facing.UP)
	map.interact()
	_check(int(map.inventory.get("ETHER", 0)) == 1, "Second area has its own placeholder chest")
	_close_dialogue(map)
	map.player.place(Vector2i(2, 13))
	map.player.set_facing(MapPlayer.Facing.LEFT)
	map.interact()
	_check(map.current_id == "outskirts" and map.player.tile == Vector2i(30, 13),
			"Return door goes back to the sand sea")
	map.player.place(Vector2i(30, 13))
	map.player.step(Vector2i(1, 0))
	map._process(1.0)
	_check(map.player.tile == Vector2i(31, 13), "Stepping toward the door lands on the next tile")
	map.player.step(Vector2i(1, 0))
	map._process(1.0)
	_check(map.current_id == "ruins", "Stepping onto a door transfers automatically")

	# Enemy placeholder only talks: no combat transition was invented.
	var enemy: Dictionary = {}
	for item in PlaceholderMaps.get_map("outskirts").get("objects", []):
		if String(item.get("kind", "")) == "enemy":
			enemy = item
	_check(not enemy.is_empty() and String(enemy.get("name", "")) == "ENEMY",
			"An enemy placeholder object exists")
	map.queue_free()
	await process_frame
	print("MAP NAVIGATION OK: %d checks" % checks)
	quit(0)
