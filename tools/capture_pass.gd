extends SceneTree
## D-065: windowed capture of PASS in the playable battle. Run WITHOUT --headless:
##   Godot --fixed-fps 60 --path . -s tools/capture_pass.gd
## Frames: 1 Fallen's menu with PASS; 2 the pass result; 3 Yoch's menu; 4 Fallen back in
## round 01 after both passed; 5 the round ending once everyone left passed (round 02).
const SANDBOX := preload("res://tests/progress_sandbox.gd")
const OUT := "res://captures/pass_%d.png"

var battle: Control
var shot := 0
var _stages := 0

func _initialize() -> void:
	SANDBOX.begin()
	call_deferred("_run")

func _finalize() -> void:
	SANDBOX.end()

func frames(n: int) -> void:
	for _i in n: await process_frame

func snap(label: String) -> void:
	await frames(20)
	shot += 1
	var path := ProjectSettings.globalize_path(OUT % shot)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	root.get_texture().get_image().save_png(path)
	print("CAPTURED %d %s: %s | round %d actor %s mode %s acts %s" % [shot, label, path,
		battle.state.round_number, battle.active_actor.display_name if battle.active_actor else "-",
		battle.hud.mode, battle.state.units.map(func(u): return u.acts_available)])

## Plays out enemy turns: pages results, declines reactions, finishes rhythm bars.
func until_menu(limit := 1800) -> void:
	for _i in limit:
		var foe_a: BattleUnit = battle.state.units[2]
		if foe_a.atk_stages.size() != _stages:
			_stages = foe_a.atk_stages.size()
			print("FOE A ATK stages -> %d at round %d" % [_stages, battle.state.round_number])
		var m: String = battle.hud.mode
		if m in ["plan", "command"] and not battle.hud.command_options.is_empty(): return
		if m in ["continue", "announce"]: battle.proceed()
		elif m == "react": battle.answer_reaction(false)
		await process_frame

func pick(command: String) -> void:
	var i: int = battle.hud.plan_options.find(command)
	battle.hud.plan_index = i
	await frames(10)

func _run() -> void:
	battle = load("res://scenes/battle/BattlePlayable.tscn").instantiate()
	root.add_child(battle)
	battle.rng.seed = int(OS.get_environment("PASS_SEED")) if OS.has_environment("PASS_SEED") else 913
	# Capture only: declined reactions are D-022 auto-hits; high HP keeps both heroes up.
	for u in [battle._fallen, battle._ally]:
		u.stats.max_hp = 99; u.current_hp = 99
	await until_menu()
	await pick("PASS")
	await snap("fallen-menu-pass-highlighted")
	battle.submit_command(battle.hud.command_options.find("PASS"))
	await snap("fallen-passed")
	await until_menu()
	await pick("PASS")
	await snap("yoch-menu")
	battle.submit_command(battle.hud.command_options.find("PASS"))
	await until_menu()
	await snap("fallen-again-same-round")
	battle.submit_command(battle.hud.command_options.find("PASS"))
	await until_menu()
	if battle.active_actor == battle._ally:
		battle.submit_command(battle.hud.command_options.find("PASS"))
		await until_menu()
	await snap("after-everyone-passed")
	print("BUFF LINES: ", battle.log_history.filter(func(l: String) -> bool: return l.contains("ATK")))
	print("PASS LINES: ", battle.log_history.filter(func(l: String) -> bool: return l.contains("passes the turn")))
	quit(0)
