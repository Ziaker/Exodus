extends SceneTree

# Headless smoke test for the prepared Godot environment.
# Run with: Godot_v4.7.2-stable_win64_console.exe --headless --path . \
#               --script res://tests/verify_environment.gd

const EXPECTED_NAME := "Exodus"
## D-055 (criador, 2026-11-23): resolução base 816x624.
const EXPECTED_WIDTH := 816
const EXPECTED_HEIGHT := 624

func _initialize() -> void:
	var failures: Array[String] = []

	var project_name: String = String(ProjectSettings.get_setting("application/config/name", ""))
	if project_name != EXPECTED_NAME:
		failures.append("project name: got %s, expected %s" % [project_name, EXPECTED_NAME])

	var width := int(ProjectSettings.get_setting("display/window/size/viewport_width", 0))
	var height := int(ProjectSettings.get_setting("display/window/size/viewport_height", 0))
	if width != EXPECTED_WIDTH or height != EXPECTED_HEIGHT:
		failures.append("viewport: got %dx%d, expected %dx%d" % [width, height, EXPECTED_WIDTH, EXPECTED_HEIGHT])

	var main_scene := String(ProjectSettings.get_setting("application/run/main_scene", ""))
	if not ResourceLoader.exists(main_scene):
		failures.append("main scene missing: %s" % main_scene)
	elif not load(main_scene) is PackedScene:
		failures.append("main scene is not a PackedScene: %s" % main_scene)

	var plugins: PackedStringArray = PackedStringArray(ProjectSettings.get_setting("editor_plugins/enabled", PackedStringArray([])))
	for plugin_cfg in ["res://addons/gut/plugin.cfg", "res://addons/dialogue_manager/plugin.cfg"]:
		if not plugins.has(plugin_cfg):
			failures.append("plugin not enabled: %s" % plugin_cfg)
		if not FileAccess.file_exists(plugin_cfg):
			failures.append("plugin.cfg missing: %s" % plugin_cfg)

	if root.get_node_or_null("DialogueManager") == null:
		failures.append("DialogueManager autoload missing at runtime")

	for sample in [
		"res://assets/graphics/faces/001_daitenshi.png",
		"res://assets/graphics/characters/$door.png",
		"res://assets/audio/bgm/DDS1_01.ogg",
		"res://assets/fonts/msgothic.ttf",
	]:
		if not ResourceLoader.exists(sample):
			failures.append("asset not imported: %s" % sample)
		else:
			var res := load(sample)
			if res == null:
				failures.append("asset failed to load: %s" % sample)

	if failures.is_empty():
		print("ENVIRONMENT OK (Godot %s, %s, %dx%d)" % [
			Engine.get_version_info().get("string", "?"), project_name, width, height])
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
