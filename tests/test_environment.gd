extends GutTest

func test_project_identity() -> void:
	assert_eq(ProjectSettings.get_setting("application/config/name"), "Exodus")
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 816)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 624)

func test_required_plugins_are_enabled() -> void:
	var enabled: PackedStringArray = PackedStringArray(
		ProjectSettings.get_setting("editor_plugins/enabled", PackedStringArray([])))
	assert_true(enabled.has("res://addons/gut/plugin.cfg"))
	assert_true(enabled.has("res://addons/dialogue_manager/plugin.cfg"))

func test_temporary_assets_are_imported() -> void:
	assert_true(ResourceLoader.exists("res://assets/graphics/faces/001_daitenshi.png"))
	assert_true(ResourceLoader.exists("res://assets/audio/bgm/DDS1_01.ogg"))
	assert_true(ResourceLoader.exists("res://assets/fonts/msgothic.ttf"))
