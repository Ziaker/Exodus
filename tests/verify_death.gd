extends SceneTree
## Creator 2026-11-23: Fallen's death. The battle ends as soon as Fallen falls (even with
## the ally up), half of every stat gain is lost (odd gains keep the larger half),
## counters and skills are kept, the cutscene plays and the game goes to the title.
const SANDBOX := preload("res://tests/progress_sandbox.gd")
const CUTSCENE := preload("res://scripts/battle/death_cutscene.gd")

var checks := 0


class DeathBattle extends "res://scripts/battle/playable_controller.gd":
	var left := false
	func _leave_after_death() -> void:
		left = true


func _initialize() -> void:
	SANDBOX.begin()
	call_deferred("_run")


func _finalize() -> void:
	SANDBOX.end()


func check(ok: bool, description: String) -> void:
	if not ok:
		push_error(description)
		quit(1)
		assert(ok, description)
	checks += 1


## True when the next laid-out piece continues this word (a Hebrew word's comma).
func words_joined_next(words: Array[Dictionary], word: Dictionary) -> bool:
	var i := words.find(word)
	return i + 1 < words.size() and bool(words[i + 1].get("joined", false))


func _run() -> void:
	# ---- BattleState: Fallen down with the ally alive ends the battle as a defeat.
	var state := BattleState.new()
	var stats := UnitStats.new()
	stats.max_hp = 10
	var fallen := BattleUnit.new(&"fallen", "FALLEN", stats, true, true)
	var ally := BattleUnit.new(&"ally", "ALLY", stats, true)
	var foe := BattleUnit.new(&"foe", "FOE", stats, false)
	for unit in [fallen, ally, foe]:
		state.add_unit(unit)
	check(not state.is_over() and not state.fallen_fell(), "Everyone up: the battle goes on")
	ally.current_hp = 0
	check(not state.is_over(), "Only the ally down: the battle goes on")
	ally.current_hp = 5
	fallen.current_hp = 0
	check(state.fallen_fell() and state.is_over() and not state.player_victory(), "Fallen down with the ally up ends the battle as a defeat")
	foe.current_hp = 0
	check(not state.player_victory(), "Fallen down and every foe down is still Fallen's death")

	# ---- ProgressStore.halve_gains: odd gains keep the larger half; the rest is kept.
	ProgressStore.save_gains({"max_hp": 3, "max_en": 4, "atk": 1, "mak": 0, "defense": 7, "mef": 2, "agi": 5})
	var learned: Array[StringName] = [&"lunge"]
	ProgressStore.save_skill_progress({"genetic_foe_a": 3}, learned)
	ProgressStore.save_pp(4)
	var halved := ProgressStore.halve_gains()
	var expected := {"max_hp": 2, "max_en": 2, "atk": 1, "mak": 0, "defense": 4, "mef": 1, "agi": 3}
	check(halved == expected and ProgressStore.load_gains() == expected, "Half of each gain is lost, +3 keeps +2 (got %s)" % ProgressStore.load_gains())
	check(ProgressStore.load_skills() == learned and int(ProgressStore.load_absorbs().get("genetic_foe_a", 0)) == 3, "Counters and skills are kept")

	# ---- Live battle: Fallen falls, the penalty is stored and the cutscene plays.
	var battle := DeathBattle.new()
	root.add_child(battle)
	await process_frame
	check(battle._fallen.stats.max_hp == 14 + 2, "The halved gains are applied to the next battle (got %d)" % battle._fallen.stats.max_hp)
	check(battle._ally.prays and battle._ally.current_pp == 4, "Yoch starts with the stored PP")
	battle._fallen.current_hp = 0
	battle._play_death()
	check(battle.hud.mode == "death" and battle.phase_text == "DEFEAT" and battle.log_history.has("DEFEAT."), "Death mode and DEFEAT in the log")
	check(ProgressStore.load_gains() == {"max_hp": 1, "max_en": 1, "atk": 1, "mak": 0, "defense": 2, "mef": 1, "agi": 2}, "The death halves the stored gains again (got %s)" % ProgressStore.load_gains())
	check(ProgressStore.load_pp() == 0, "A defeat zeroes Yoch's PP (D-048)")
	check(ProgressStore.load_deaths() == 1, "The death is counted (got %d)" % ProgressStore.load_deaths())
	ProgressStore.save_gains(ProgressStore.load_gains())
	check(ProgressStore.load_deaths() == 1, "Other saves keep the death count")
	check(ProgressStore.load_skills() == learned, "Skills survive the death")
	var cut: Node2D = battle.death_cutscene
	check(cut != null and cut.is_inside_tree() and (cut.get_parent() as CanvasLayer).layer == 50, "The cutscene is drawn above the battle")
	# Creator 2026-11-23: SMT VX "Law" from t = 0 at 100%, 1 s fade to silence at the end.
	var music: AudioStreamPlayer = cut.get_node("Law")
	check(music.stream != null and music.stream.resource_path == "res://assets/audio/bgm/DDS2_law.ogg", "The cutscene plays DDS2_law.ogg")
	check(not music.playing and is_equal_approx(CUTSCENE.MUSIC_START, 0.8), "Law waits 0.8 s after the death")
	check(CUTSCENE.music_volume(0.0) == 1.0 and CUTSCENE.music_volume(12.99) == 1.0, "Full volume until the last second")
	check(is_equal_approx(CUTSCENE.music_volume(13.5), 0.5) and CUTSCENE.music_volume(14.0) == 0.0, "Linear 1 s fade to silence at 14 s")
	check(cut.line.begins_with("Levanta-te, ") and cut.line.ends_with(", que a ti não é dada a bênção da morte. Do que te fortaleceu, parte perderás, como punição."), "The angel's line (got %s)" % cut.line)
	var figure := 0
	for letter in cut.letters:
		var rest: Vector2 = letter.rest
		check(rest.x >= 0 and rest.x <= CUTSCENE.W and rest.y >= 0 and rest.y <= CUTSCENE.H, "Every letter rests on screen")
		check(float(letter.appear) < CUTSCENE.ENTER_END, "Every letter appears within the 3 s")
		if letter.figure: figure += 1
	check(figure > 300 and cut.letters.size() > figure, "Letters form the figure and the box (%d / %d)" % [figure, cut.letters.size()])
	check(cut.INK == Color("a8182a"), "Letters in #a8182a")
	# Losses of this death: {max_hp 2->1, max_en 2->1, atk 1->1, defense 4->2, mef 1->1, agi 3->2}.
	var texts: Array[String] = []
	for label in cut.loss_labels:
		texts.append(label.text)
		check(float(label.start) >= CUTSCENE.TEXT_END and float(label.start) + CUTSCENE.LOSS_FLIGHT <= CUTSCENE.LOSS_END + 0.001, "Each loss flies inside the 5 s after the line")
		check(CUTSCENE.CORNERS.has(label.from), "Each loss starts at a screen corner")
	check(texts == ["-1 HP", "-1 EN", "-2 DEF", "-1 AGI"], "Loss labels (got %s)" % [texts])
	var corners := {}
	for label in cut.loss_labels: corners[label.from] = true
	check(corners.size() == 4, "The losses come from the four corners")
	var green := ""
	var joined := ""
	for word in cut.words:
		green += String(word.text).substr(0, int(word.green))
		joined += String(word.text) + ("" if words_joined_next(cut.words, word) else " ")
	check(green == "Doquetefortaleceu,parteperderás", "Green part of the line (got %s)" % green)
	check(joined.strip_edges() == cut.line, "Laid-out words rebuild the line")
	for word in cut.words:
		var p: Vector2 = word.pos
		check(p.y < CUTSCENE.BOX.end.y - 4 and p.x + cut.font.get_string_size(word.text, HORIZONTAL_ALIGNMENT_LEFT, -1, CUTSCENE.TEXT_PX).x <= CUTSCENE.BOX.end.x - 17, "Every word fits in the box")
	battle.handle_confirm()
	battle.handle_back()
	check(battle.hud.mode == "death", "Input does nothing during the cutscene")
	# Runs the cutscene to its end in real time.
	var deadline := Time.get_ticks_msec() + 30000
	var mid_fade := -1.0
	var still_playing := true
	var started_at := -1.0
	var full_volume := true
	while not battle.left and Time.get_ticks_msec() < deadline:
		if started_at < 0.0 and music.playing:
			started_at = cut.t
			full_volume = is_equal_approx(music.volume_linear, 1.0)
		if cut.t < CUTSCENE.MUSIC_START: still_playing = still_playing and not music.playing
		elif cut.t > CUTSCENE.MUSIC_START + 0.1 and cut.t < 13.0: still_playing = still_playing and music.playing
		if mid_fade < 0.0 and cut.t >= 13.4 and cut.t <= 13.6: mid_fade = music.volume_linear
		await process_frame
	check(started_at >= 0.8 and started_at < 0.9 and full_volume, "Law starts 0.8 s after the death, at the file's volume (t=%.2f)" % started_at)
	check(still_playing, "Silent for the first 0.8 s, then Law plays through the cutscene")
	check(mid_fade > 0.3 and mid_fade < 0.7, "Live volume is fading at 13.5 s (got %.2f)" % mid_fade)
	check(not music.playing, "Law is silent when the cutscene ends")
	check(battle.left and cut.t >= CUTSCENE.END, "After the cutscene the game leaves for the title (t=%.2f)" % cut.t)
	check(is_equal_approx(CUTSCENE.ENTER_END, 3.0) and is_equal_approx(CUTSCENE.FLY_END - CUTSCENE.ENTER_END, 2.0)
		and is_equal_approx(CUTSCENE.TEXT_END - CUTSCENE.TEXT_START, 5.0) and is_equal_approx(CUTSCENE.LOSS_END - CUTSCENE.TEXT_END, 3.0)
		and is_equal_approx(CUTSCENE.SCATTER_END - CUTSCENE.LOSS_END, 1.0)
		and is_equal_approx(CUTSCENE.END, 14.0), "Timeline 3 + 2 + 5 + 3 + 1 = 14 s")
	check(cut.line.length() / CUTSCENE.CHARS_PER_SECOND < CUTSCENE.TEXT_END - CUTSCENE.TEXT_START, "The whole line is typed within its 5 s")
	battle.queue_free()
	await process_frame

	# ---- Title: deaths in Roman numerals under the title.
	const TITLE := preload("res://scripts/title/title_screen.gd")
	var numerals := {1: "I", 2: "II", 4: "IV", 9: "IX", 14: "XIV", 40: "XL", 90: "XC", 400: "CD", 1994: "MCMXCIV"}
	for n in numerals.keys():
		check(TITLE.roman(n) == numerals[n], "Roman %d = %s (got %s)" % [n, numerals[n], TITLE.roman(n)])
	var title: Control = load("res://scenes/title/Title.tscn").instantiate()
	root.add_child(title)
	await process_frame
	check(title.deaths == 1, "The title reads the death count (got %d)" % title.deaths)
	var mid: float = title.deaths_center_y()
	check(mid > TITLE.WINDOW_Y / 2.0 + TITLE.TITLE_PX / 3.0 and mid < title.window_rect().position.y, "The numeral sits between the title and the menu")
	title.queue_free()
	ProgressStore.clear()
	title = load("res://scenes/title/Title.tscn").instantiate()
	root.add_child(title)
	await process_frame
	check(title.deaths == 0, "No death yet: no numeral")
	title.queue_free()
	await process_frame

	# ---- Prologue: Law plays nonstop, looping, and the animation loop does not restart it.
	var prologue: Node2D = load("res://prototypes/hebrew-transition/HebrewTransition.tscn").instantiate()
	root.add_child(prologue)
	await process_frame
	var law: AudioStreamPlayer = prologue.get_node("Law")
	check(law.stream.resource_path == "res://assets/audio/bgm/DDS2_law.ogg" and law.playing and is_equal_approx(law.volume_linear, 1.0), "The prologue plays Law at 100%")
	check(law.finished.is_connected(law.play), "Law starts over when the track ends")
	var plays := [0]
	law.finished.connect(func() -> void: plays[0] += 1)
	prologue.t = 15.49
	await process_frame
	await process_frame
	check(prologue.t < 1.0 and law.playing and plays[0] == 0, "The 15.5 s animation loop does not restart the music")
	law.finished.emit()
	check(law.playing and plays[0] == 1, "After the track ends it plays again")
	# Stop before freeing so the audio server releases the playback before the test quits.
	law.finished.disconnect(law.play)
	law.stop()
	prologue.queue_free()
	# The audio thread releases stopped Ogg playbacks a little later; quitting at once
	# reports them as leaked.
	await create_timer(0.5).timeout
	print("DEATH_OK: %d checks" % checks)
	quit(0)
