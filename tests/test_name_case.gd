extends GutTest

## D-110 (criador 2026-11-26): names on the battle screen keep only the first letter upper.

func test_all_caps_names_keep_only_the_first_letter() -> void:
	assert_eq(NameCase.of("FALLEN"), "Fallen")
	assert_eq(NameCase.of("FOE A"), "Foe A")
	assert_eq(NameCase.of("HEAT WAVE"), "Heat Wave")
	assert_eq(NameCase.of("SHUTEN-DOUJI"), "Shuten-Douji")
	assert_eq(NameCase.of("AARON'S ROD"), "Aaron's Rod")


func test_mixed_case_names_are_left_alone() -> void:
	assert_eq(NameCase.of("Yoch"), "Yoch")
	assert_eq(NameCase.of("Ra'am"), "Ra'am")
	assert_eq(NameCase.of(""), "")
