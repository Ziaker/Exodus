extends RefCounted
## Keeps verify_* scripts independent of the player's real D-024 save.
## begin(): point ProgressStore at a test-only file and start from no gains.
## end(): discard the test file and point ProgressStore back at the real save.
## Call end() from SceneTree._finalize() so it also runs after a failed check.
##
## 2026-11-25: the old sandbox backed up the real user://exodus_progress.json, cleared it
## and restored it at the end. A test killed before end() (timeout, crash, two suites at
## once) lost the backup and left test data in the player's save. The real file is now
## never opened by the tests.

const TEST_PATH := "user://exodus_progress_verify.json"


static func begin() -> void:
	ProgressStore.save_path_override = TEST_PATH
	ProgressStore.clear()


static func end() -> void:
	ProgressStore.clear()
	ProgressStore.save_path_override = ""
