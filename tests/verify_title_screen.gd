extends SceneTree
## Headless checks for the XP-style title screen (proposal 1).

var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, description: String) -> void:
	if not ok:
		push_error("FAIL: " + description)
		quit(1)
		assert(ok, description)
	checks += 1

func _key(code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	Input.parse_input_event(e)
	var up := e.duplicate()
	up.pressed = false
	Input.parse_input_event(up)

func _run() -> void:
	_check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/title/Title.tscn",
			"Title must be the main scene")
	var title: Control = load("res://scenes/title/Title.tscn").instantiate()
	root.add_child(title)
	await process_frame
	_check(title.COMMANDS == ["New Game", "Continue", "Survival", "Shutdown"], "XP command list + Survival")
	_check(title.index == 0, "Without a save the cursor starts on New Game")
	_check(not title.is_enabled(1), "Continue disabled without a save")
	_check(title.is_enabled(0) and title.is_enabled(2) and title.is_enabled(3),
			"New Game, Survival and Shutdown enabled")
	var w: Rect2 = title.window_rect()
	_check(is_equal_approx(w.position.x + w.size.x / 2.0, title.size.x / 2.0), "Window centered horizontally")
	_check(w.end.y <= title.size.y, "Window fits the viewport (%s in %s)" % [w, title.size])
	for i in 4:
		_check(w.encloses(title.row_rect(i)), "Row %d inside window" % i)
	_key(KEY_UP)
	await process_frame
	_check(title.index == 3, "Up from first row wraps to Shutdown")
	_key(KEY_DOWN)
	await process_frame
	_check(title.index == 0, "Down from last row wraps to New Game")
	_key(KEY_DOWN)
	await process_frame
	_check(title.index == 1, "Cursor can rest on disabled Continue")
	_key(KEY_Z)
	await process_frame
	_check(not title.busy and title.fade_alpha == 0.0, "Confirming disabled Continue does nothing")
	_key(KEY_UP)
	await process_frame
	_check(title.index == 0, "Back to New Game")
	_key(KEY_ENTER)
	await process_frame
	_check(title.busy, "Enter starts New Game")
	_key(KEY_DOWN)
	await process_frame
	_check(title.index == 0, "Input locked during fade")
	await create_timer(title.FADE_TIME + 0.3).timeout
	await process_frame
	_check(current_scene != null and current_scene.scene_file_path == "res://prototypes/dungeon-crawler/DungeonProto.tscn",
			"New Game opens the first-person dungeon test (got %s)" % (current_scene.scene_file_path if current_scene else "null"))
	# O modo Survival entra pelo menu do título e zera a run (3 continues).
	title.queue_free()
	await process_frame
	SurvivalState.clear()
	var survival_title: Control = load("res://scenes/title/Title.tscn").instantiate()
	root.add_child(survival_title)
	await process_frame
	_key(KEY_DOWN)
	await process_frame
	_key(KEY_DOWN)
	await process_frame
	_check(survival_title.index == 2, "Cursor reaches Survival")
	_key(KEY_Z)
	await process_frame
	_check(survival_title.busy, "Survival starts the mode")
	await create_timer(survival_title.FADE_TIME + 0.3).timeout
	await process_frame
	# D-121: run nova abre primeiro a cutscene do Kazfiel; ela termina no mapa
	# (fluxo completo em tools/capture_survival_intro_flow.gd).
	_check(current_scene != null and current_scene.scene_file_path == "res://scenes/survival/SurvivalIntro.tscn",
			"New Survival run opens the Kazfiel cutscene (got %s)" % (current_scene.scene_file_path if current_scene else "null"))
	_check(int(SurvivalState.data().continues) == SurvivalData.MAX_CONTINUES, "A new run starts with 3 continues")
	_check(int(SurvivalState.data().macca) == SurvivalData.STARTING_MACCA, "A new run resets Macca")
	SurvivalState.clear()
	print("TITLE CHECKS PASSED: ", checks)
	quit(0)
