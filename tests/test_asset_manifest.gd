extends GutTest

## Verifies the reproducibility manifest without depending on the assets themselves.

func _manifest() -> Dictionary:
	var file := FileAccess.open("res://assets/ASSET_MANIFEST.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return {}
	return parsed


func test_manifest_is_readable_and_declares_requirements() -> void:
	var manifest := _manifest()
	assert_true(manifest.has("required"))
	assert_true(manifest.has("mappings"))
	assert_true(manifest.has("default_source"))


func test_manifest_covers_paths_used_by_environment_tests() -> void:
	var required: Array = _manifest().get("required", [])
	for path in [
		"assets/graphics/faces/001_daitenshi.png",
		"assets/audio/bgm/DDS1_01.ogg",
		"assets/fonts/msgothic.ttf",
		"assets/graphics/parallaxes/BB01-001.png",
		"assets/graphics/system/Window.png",
	]:
		assert_true(required.has(path), "manifest must list %s" % path)


func test_manifest_lists_derived_battle_sprites() -> void:
	var required: Array = _manifest().get("required", [])
	assert_true(required.has("assets/graphics/battle_sprites/Avatar Anubis.png"))
	assert_true(required.has("assets/graphics/battle_sprites/Avatar Chimera.png"))
