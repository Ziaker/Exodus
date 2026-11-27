extends SceneTree
## Regressão do Battle Log: nenhuma mensagem é cortada nem vaza da janela.
## O log quebra a frase em linhas inteiras dentro de BATTLE_LOG_RECT (D-056: 2 linhas),
## na fonte cheia, e só descarta uma mensagem antiga se ela não couber por inteiro.

var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, description: String) -> void:
	if not ok:
		push_error(description)
		quit(1)
		assert(ok, description)
	checks += 1


func _inner(hud) -> float:
	var text_x: float = hud.BATTLE_LOG_RECT.position.x + 31.0 / 3.0
	var text_start: float = text_x + hud._width("*", hud.LOG_PX, true) + 4.0
	return hud.BATTLE_LOG_RECT.end.x - 5.0 - text_start


func _rows_text(hud, rows: Array) -> String:
	var parts: PackedStringArray = []
	for entry in rows:
		parts.append(String(entry.text))
	return " ".join(parts)


func _run() -> void:
	var battle: Control = load("res://scenes/battle/BattlePlayable.tscn").instantiate()
	root.add_child(battle)
	for _i in 300:
		if battle.hud != null and battle.hud.mode != "":
			break
		await process_frame
	_check(battle.hud != null, "Battle HUD must exist")
	var hud = battle.hud
	var inner: float = _inner(hud)
	_check(inner > 300.0, "Log inner width must be usable (got %s)" % inner)
	_check(hud.LOG_LINES == 3, "D-110: the battle log shows three lines")

	# 1. Frase longa: quebra em linhas que caibam, sem perder palavra alguma.
	var long_line := "PIXIE -> YOCH: HIT, 13 DAMAGE (FULL, RHYTHM POINT, DEF MISS, CRIT NO, AFFINITY WEAK, SP ROLL -3)"
	var rows: Array = hud._log_rows([long_line] as Array[String], inner)
	_check(rows.size() == 2, "A long log line fills the two rows")
	var rebuilt := _rows_text(hud, rows)
	for word in long_line.split(" ", false):
		_check(rebuilt.contains(word), "Wrapped log keeps every word (%s)" % word)
	for entry in rows:
		_check(hud._width(String(entry.text), int(entry.px)) <= inner + 0.01,
			"Log row must fit the window: %s" % String(entry.text))
		_check(int(entry.px) >= hud.LOG_PX, "Long lines wrap instead of shrinking the font")

	# 2. Duas mensagens curtas: as duas aparecem.
	var short_rows: Array = hud._log_rows(["A", "B"] as Array[String], inner)
	_check(short_rows.size() == 2 and String(short_rows[1].text) == "B", "Two short lines fill the two log rows")

	# 3. Mensagem de 2 linhas + duas curtas mais novas (D-110: 3 linhas): as mais novas
	# entram inteiras e a antiga, que não cabe inteira, sai inteira (nunca pela metade).
	var mixed: Array = hud._log_rows([long_line, "SHORT ONE", "SHORT TWO"] as Array[String], inner)
	_check(mixed.size() == 2 and String(mixed[0].text) == "SHORT ONE" and String(mixed[1].text) == "SHORT TWO", "The newest messages enter whole; an older one that no longer fits leaves whole")
	_check(not _rows_text(hud, mixed).contains("PIXIE"), "No half of the older wrapped message is left behind")
	var fits: Array = hud._log_rows([long_line, "SHORT ONE"] as Array[String], inner)
	_check(fits.size() == 3 and String(fits[2].text) == "SHORT ONE", "D-110: a 2-row message and a short one share the 3 rows")

	# 4. Quatro mensagens curtas: só as três mais novas entram, inteiras (D-110).
	var three: Array = hud._log_rows(["A", "B", "C", "D"] as Array[String], inner)
	_check(three.size() == 3 and String(three[0].text) == "B" and String(three[2].text) == "D", "Only the newest whole messages are drawn")

	# 5. Nunca passa do retângulo nem por 1 px.
	for entry in mixed:
		var w: float = hud._width(String(entry.text), int(entry.px))
		_check(w <= inner + 0.01, "No log row leaks past the window border")

	# 6. Fonte cheia: nenhuma linha real precisa descer até o mínimo.
	_check(int(rows[0].px) == hud.LOG_PX, "Normal messages keep the full log font size")

	# 7. Mensagem patológica (maior que a janela em 2 linhas): o log nunca fica vazio.
	var huge := ""
	for i in 40:
		huge += "WORD%d " % i
	var huge_rows: Array = hud._log_rows([huge] as Array[String], inner)
	_check(not huge_rows.is_empty(), "An oversized message still fills the log")
	for entry in huge_rows:
		_check(hud._width(String(entry.text), int(entry.px)) <= inner + 0.01,
			"Even the oversized message respects the window width")

	print("LOG_WRAP_OK: %d checks, inner=%.1f" % [checks, inner])
	quit(0)
