extends SceneTree
## Verificação headless do TESTE de dungeon em primeira pessoa (prototypes/dungeon-crawler).
## Prova lógica, geometria projetada e tempos. NÃO prova que o visual está bom: isso é do criador.

const SCENE := "res://prototypes/dungeon-crawler/DungeonProto.tscn"
const Proto := preload("res://prototypes/dungeon-crawler/dungeon_proto.gd")

var checks := 0
var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, description: String) -> void:
	if not ok:
		failed = true
		push_error("FAIL: " + description)
		print("FAIL: ", description)
	else:
		checks += 1


func _near(a: float, b: float, tol: float) -> bool:
	return absf(a - b) <= tol


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _key(code: Key, pressed: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = pressed
	Input.parse_input_event(e)


## Conta quadros até o fim da ação. Rodar com --fixed-fps 60: cada quadro = 1/60 s de jogo.
func _frames_until_idle(d: Control, already: int = 0) -> int:
	var n := already
	while d.busy:
		await process_frame
		n += 1
	return n


func _new() -> Control:
	var d: Control = load(SCENE).instantiate()
	# Este teste é de geometria/UI: os inimigos são verificados em verify_dungeon_encounters.gd.
	d.enemies_enabled = false
	root.add_child(d)
	return d


func _place(d: Control, c: Vector2i, f: int) -> void:
	d.cell = c
	d.facing = f
	d._snap_to_state()
	d._map_cell(c)


func _screen(d: Control, p: Vector3) -> Vector2:
	return d.camera.unproject_position(p) + d.VIEW_POS


func _run() -> void:
	# --- labirinto
	var g: Array = Proto.MAZE
	var open := []
	for y in g.size():
		for x in g[y].length():
			if g[y][x] != "#":
				open.append(Vector2i(x, y))
	for y in g.size():
		_check(g[y].length() == g[0].length(), "maze row %d has the same width" % y)
		_check(g[y][0] == "#" and g[y][g[y].length() - 1] == "#", "maze row %d closed at the sides" % y)
	_check(not g[0].contains(".") and not g[g.size() - 1].contains("."), "maze closed top/bottom")
	var start := Vector2i(-1, -1)
	for c in open:
		if g[c.y][c.x] == "S":
			start = c
	var seen := {start: true}
	var frontier := [start]
	while not frontier.is_empty():
		var c: Vector2i = frontier.pop_back()
		for dv in Proto.DIRS:
			var n: Vector2i = c + dv
			if g[n.y][n.x] != "#" and not seen.has(n):
				seen[n] = true
				frontier.append(n)
	_check(seen.size() == open.size(), "every open cell reachable (%d/%d)" % [seen.size(), open.size()])
	var dead_ends := 0
	var room := false
	for c in open:
		var walls := 0
		for dv in Proto.DIRS:
			if g[c.y + dv.y][c.x + dv.x] == "#":
				walls += 1
		if walls == 3:
			dead_ends += 1
		if g[c.y][c.x + 1] != "#" and g[c.y + 1][c.x] != "#" and g[c.y + 1][c.x + 1] != "#":
			room = true
	_check(dead_ends >= 1, "maze has a dead end (%d)" % dead_ends)
	_check(room, "maze has a room (2x2 open block)")

	# --- cena
	var d := _new()
	await process_frame
	_check(d.cell == Vector2i(1, 1) and d.facing == 1, "starts at S facing east")
	_check(d.visited.has(Vector2i(1, 1)) and d.visited.size() == 1, "automap starts with only the start cell")
	_check(d.size == Vector2(816, 624), "screen 816x624 (D-055)")
	_check(d.parallax_texture != null and d.parallax_texture.get_width() == 544, "VX parallax MP001 loaded")
	var slices: Array = d.parallax.get_children()
	_check(slices.size() == 3 and _near(slices[0].position.y, 0.0, 0.01) and _near(slices[2].position.y + slices[2].size.y, d.FRAME_RECT.end.y, 0.01), "parallax slices cover the whole 3D view height")
	_check(_near(slices[1].size.y, 17.0, 0.01) and _near(slices[1].position.y, Proto.HORIZON_Y - 11.0, 0.01), "black horizon band kept 1:1 around the horizon")
	_check(d.party.size() == 2 and d.party[0].display_name == "FALLEN" and d.party[1].display_name == "Yoch", "status shows FALLEN and Yoch")
	_check(d.party[1].prays and d.party[1].stats.max_en == 0, "Yoch shows PP, not EN (D-048)")
	_check(d.party[0].stats.max_hp >= 14 and d.party[1].stats.max_hp == 11, "party HP from the battle values")
	_check(d.FRAME_RECT.encloses(d.AUTOMAP_RECT), "automap sits inside the thin frame")
	_check(d.FRAME_RECT.end.y <= d.STATUS_RECTS[0].position.y and d.FRAME_RECT.end.y <= d.LOCATION_LINE_Y, "3D frame ends above the location line and status")
	var vr := Rect2(d.view_container.position, d.view_container.size)
	var max_shift := Proto.SHAKE_POWER * 3.0
	_check(vr.position.x + max_shift <= d.FRAME_RECT.position.x and vr.end.x - max_shift >= d.FRAME_RECT.end.x, "3D view covers the frame even at max shake")
	_check(d.parallax.position.x + max_shift <= d.FRAME_RECT.position.x and d.parallax.position.x + d.parallax.size.x - max_shift >= d.FRAME_RECT.end.x, "parallax covers the frame even at max shake")
	_check(_near(d.FRAME_RECT.position.y + (d.FRAME_RECT.size.y / 2.0), Proto.HORIZON_Y, 0.5), "horizon at the centre of the 3D view (D-055)")
	_check(Rect2(Vector2.ZERO, d.SCREEN).encloses(d.FRAME_RECT) and d.STATUS_RECTS[1].end.y <= d.SCREEN.y, "frame and status fit the 816x624 screen")
	_check(d.STATUS_RECTS[0] == Rect2(8, 540, 168, 77) and d.STATUS_RECTS[1] == Rect2(182, 540, 168, 77), "status panels keep the battle size and position (D-055)")
	var expected_quads := 0
	for c in open:
		for dv in Proto.DIRS:
			if g[c.y + dv.y][c.x + dv.x] == "#":
				expected_quads += 1
	_check(d.wall_quads == expected_quads, "one wall quad per open-cell/wall face (%d == %d)" % [d.wall_quads, expected_quads])

	# --- geometria do VX: parede da frente a 1 tile = 304x192 (D-055: horizonte em 251 ->
	# topo 123, base 315; centro da vista em x = 408 -> x 256..560)
	_place(d, Vector2i(5, 1), 1) # (5,1) olhando para leste: (6,1) é parede
	await process_frame
	_check(d.is_wall(Vector2i(6, 1)), "(6,1) is a wall for the projection check")
	var tl := _screen(d, Vector3(5.5, Proto.WALL_HEIGHT, 0.5))
	var br := _screen(d, Vector3(5.5, 0.0, 1.5))
	print("front wall 1 tile: tl=", tl, " br=", br)
	_check(_near(br.x - tl.x, 304.0, 1.0), "front wall width 304 px (%.2f)" % (br.x - tl.x))
	_check(_near(br.y - tl.y, 192.0, 1.0), "front wall height 192 px (%.2f)" % (br.y - tl.y))
	_check(_near(tl.y, 123.0, 1.0) and _near(br.y, 315.0, 1.0), "front wall top 123 / bottom 315 (eye at 1/3: 128 above, 64 below the horizon)")
	_check(_near(tl.x, 256.0, 1.0) and _near(br.x, 560.0, 1.0), "front wall x 256..560 (centered at 408)")
	var hz := _screen(d, Vector3(50.0, Proto.EYE_HEIGHT, 1.0))
	_check(_near(hz.y, Proto.HORIZON_Y, 0.5), "horizon at y=251 (%.2f)" % hz.y)
	# 2 tiles: VX desenha 152 px; perspectiva real dá 152 (mesma conta 304/2)
	var tl2 := _screen(d, Vector3(6.5, Proto.WALL_HEIGHT, 0.5))
	var br2 := _screen(d, Vector3(6.5, 0.0, 1.5))
	_check(_near(br2.x - tl2.x, 152.0, 1.0), "wall at 2 tiles 152 px wide (%.2f)" % (br2.x - tl2.x))
	_check(d.camera.far > 5.3 and d.camera.far < 6.0, "far plane keeps VX's ~5.3-tile deepest wall")
	var bd: Node3D = d.camera.get_node("FarBackdrop")
	var bd_top := _screen(d, bd.global_position + Vector3(0, Proto.WALL_HEIGHT / 2.0, 0))
	var bd_bot := _screen(d, bd.global_position - Vector3(0, Proto.WALL_HEIGHT / 2.0, 0))
	var far_top := _screen(d, Vector3(d.camera.global_position.x + Proto.BACKDROP_DIST, Proto.WALL_HEIGHT, 1.0))
	_check(_near(bd_top.y, far_top.y, 0.5), "backdrop band top matches the ceiling line at its depth")
	_check(bd_top.y < Proto.HORIZON_Y and bd_bot.y > Proto.HORIZON_Y, "backdrop band straddles the horizon")
	_check(_near(d.camera.fov, rad_to_deg(2.0 * atan(245.0 / 304.0)), 0.01), "vertical FOV keeps 304 px per tile at 1 tile")

	# --- passo
	_place(d, Vector2i(1, 1), 1)
	var t0 := Time.get_ticks_msec()
	_check(_near(d.get_process_delta_time(), 1.0 / 60.0, 0.0005), "test runs at --fixed-fps 60 (delta %.4f)" % d.get_process_delta_time())
	d.request(Proto.Act.FORWARD)
	_check(d.busy and d.cell == Vector2i(2, 1), "forward starts toward (2,1)")
	for _i in 9:
		await process_frame
	var mid: float = d.pivot.position.x
	_check(mid > 1.3 and mid < 1.7, "slide is animated, ~halfway at frame 9 of 19 (x=%.3f)" % mid)
	var step_f: int = await _frames_until_idle(d, 9)
	_check(_near(Proto.STEP_TIME, 0.15 / 0.7 / 0.7, 0.0001), "walk speed: 30%% below the run, then 30%% lower again (creator) (%.4f s)" % Proto.STEP_TIME)
	_check(step_f >= 18 and step_f <= 19, "walk step lasts 0.306 s = 18-19 frames (%d)" % step_f)
	# correr: X segurado volta ao passo de 0,15 s
	_key(KEY_X, true)
	await process_frame
	d.request(Proto.Act.FORWARD)
	var run_f: int = await _frames_until_idle(d)
	_check(run_f >= 9 and run_f <= 10, "holding X runs: step 0.15 s = 9 frames (%d)" % run_f)
	d.request(Proto.Act.TURN_RIGHT)
	var run_turn_f: int = await _frames_until_idle(d)
	_check(run_turn_f >= 9 and run_turn_f <= 10, "turn stays 0.15 s while running (%d)" % run_turn_f)
	d.request(Proto.Act.TURN_LEFT)
	await _frames_until_idle(d)
	_key(KEY_X, false)
	await process_frame
	_place(d, Vector2i(2, 1), 1)
	_check(d.pivot.position == Vector3(2, 0, 1), "pivot ends on the new cell")
	_check(d.visited.has(Vector2i(2, 1)), "automap marks the cell walked into")
	_check(not d.visited.has(Vector2i(4, 1)), "automap does not reveal cells not walked")

	# --- giro
	d.request(Proto.Act.TURN_RIGHT)
	for _i in 4:
		await process_frame
	var yaw_mid: float = d.pivot.rotation.y
	_check(yaw_mid < -PI / 2.0 - 0.3 and yaw_mid > -PI + 0.3, "turn is animated, ~halfway (yaw=%.3f)" % yaw_mid)
	var turn_f: int = await _frames_until_idle(d, 4)
	_check(d.facing == 2, "turn right: east -> south")
	_check(turn_f >= 9 and turn_f <= 10, "turn lasts 0.15 s = 9 frames (%d)" % turn_f)
	_check(is_equal_approx(d.pivot.rotation.y, Proto.yaw_for(2)), "yaw snapped to south")
	var cam_g: Vector3 = d.camera.global_position
	_check(_near(cam_g.z, 0.5, 0.001) and _near(cam_g.x, 2.0, 0.001), "camera sits on the back edge after turning (z=%.3f)" % cam_g.z)
	d.request(Proto.Act.TURN_LEFT)
	while d.busy:
		await process_frame
	_check(d.facing == 1, "turn left: south -> east")

	# --- meia-volta (seta para baixo, como no VX: dois giros à direita)
	d.request(Proto.Act.TURN_BACK)
	_check(d.facing == 2 and d.busy, "U-turn first passes through south (turns right)")
	var back_f: int = await _frames_until_idle(d)
	_check(d.facing == 3, "U-turn ends facing west")
	_check(back_f >= 18 and back_f <= 20, "U-turn = two 0.15 s turns = 18 frames (%d)" % back_f)

	# --- parede: tremor do VX e não anda
	_place(d, Vector2i(1, 1), 3)
	var clashes: int = d.clash_count
	d.request(Proto.Act.FORWARD)
	_check(d.cell == Vector2i(1, 1), "wall blocks the step")
	_check(d.clash_count == clashes + 1, "clash registered")
	var max_shake := 0.0
	while d.busy:
		max_shake = maxf(max_shake, absf(d.shake))
		await process_frame
	_check(max_shake >= 6.0 and max_shake <= 9.0, "shake amplitude follows VX power 3 (max %.1f)" % max_shake)
	_check(d.shake == 0.0 and d.view_container.position.x == Proto.VIEW_POS.x, "shake returns to rest")
	d.start_shake(3, 10, 10)
	var seq := []
	for _i in 14:
		d._shake_frame()
		seq.append(int(d.shake))
	d.busy = false
	_check(seq == [3, 6, 9, 6, 3, 0, -3, -6, -9, -6, -3, 0, 0, 0], "shake frames match VX Game_Screen formula: %s" % str(seq))

	# --- fila de entrada durante movimento
	_place(d, Vector2i(1, 1), 1)
	t0 = Time.get_ticks_msec()
	d.request(Proto.Act.FORWARD)
	d.request(Proto.Act.FORWARD)
	while d.busy or d.cell != Vector2i(3, 1):
		await process_frame
		if Time.get_ticks_msec() - t0 > 8000:
			break
	while d.busy:
		await process_frame
	_check(d.cell == Vector2i(3, 1), "input pressed during a step is queued (VX next_input)")

	# --- seta para cima segurada: anda até a parede, bate uma vez só
	_place(d, Vector2i(1, 1), 1)
	clashes = d.clash_count
	_key(KEY_UP, true)
	t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 1500:
		await process_frame
	_check(d.cell == Vector2i(5, 1), "holding up walks to the end of the corridor (%s)" % str(d.cell))
	_check(d.clash_count == clashes + 1, "holding up against a wall clashes only once (%d)" % (d.clash_count - clashes))
	_key(KEY_UP, false)
	await process_frame
	while d.busy:
		await process_frame
	_key(KEY_UP, true)
	await process_frame
	await process_frame
	_check(d.clash_count == clashes + 2, "re-pressing up clashes again")
	_key(KEY_UP, false)
	while d.busy:
		await process_frame

	# --- setas de giro pelo teclado
	_key(KEY_RIGHT, true)
	await process_frame
	_key(KEY_RIGHT, false)
	while d.busy:
		await process_frame
	_check(d.facing == 2, "right arrow turns right")
	_key(KEY_DOWN, true)
	await process_frame
	_key(KEY_DOWN, false)
	while d.busy:
		await process_frame
	_check(d.facing == 0, "down arrow turns around")

	# --- automapa em percurso maior
	_place(d, Vector2i(1, 1), 2)
	for _i in 6:
		d.request(Proto.Act.FORWARD)
		while d.busy:
			await process_frame
	_check(d.cell == Vector2i(1, 7), "walked down the west corridor")
	for y in range(1, 8):
		_check(d.visited.has(Vector2i(1, y)), "automap revealed (1,%d)" % y)
	_check(not d.visited.has(Vector2i(2, 7)), "automap keeps (2,7) hidden")

	await _npcs_and_dialogue(d)

	d.queue_free()
	print("CHECKS PASSED: ", checks, " FAILED: ", failed)


## D-055: NPCs como sprites no corredor, atravessáveis; de frente + Z abre o diálogo de
## 3 linhas sobre o painel de baixo.
func _npcs_and_dialogue(d: Control) -> void:
	_check(d.npcs.size() == 2, "two NPCs (human, demon)")
	_check(d.npc_at(Vector2i(3, 1)).get("id", "") == "human" and d.npc_at(Vector2i(5, 1)).get("id", "") == "demon", "both NPCs in the starting corridor, one behind the other")
	# Nenhum NPC desenhado no corredor; as únicas Sprite3D são as silhuetas dos inimigos.
	var sprites := 0
	for n in d.viewport.find_children("*", "Sprite3D", true, false):
		sprites += 1
	_check(sprites == d.enemies.entries.size(),
			"only roaming enemy silhouettes in the 3D corridor (no NPC sprites)")
	# Criador: parado de frente para o NPC a figura já aparece; mais longe, não.
	_place(d, Vector2i(1, 1), 1)
	_check(not d.npc_picture.visible, "NPC 2 tiles ahead: no picture (only the automap mark)")
	_place(d, Vector2i(2, 1), 1)
	_check(d.npc_picture.visible and d.npc_picture.texture.resource_path.ends_with("P15.png"), "facing the human in the tile in front shows its picture before Z")
	d.request(Proto.Act.TURN_LEFT)
	_check(not d.npc_picture.visible, "picture leaves as soon as the player turns")
	while d.busy:
		await process_frame
	_check(not d.npc_picture.visible, "facing north (wall): no picture")
	d.request(Proto.Act.TURN_RIGHT)
	while d.busy:
		await process_frame
	_check(d.npc_picture.visible, "turning back to the human shows it again")
	d.request(Proto.Act.FORWARD)
	_check(not d.npc_picture.visible, "picture leaves as soon as the player steps")
	while d.busy:
		await process_frame
	_check(d.cell == Vector2i(3, 1) and d.npc_picture.visible and d.npc_picture.texture.resource_path.ends_with("P15.png"), "standing on the human's cell shows the human (creator)")
	for f in 4:
		_place(d, Vector2i(3, 1), f)
		_check(d.npc_picture.visible and d.npc_near().get("id", "") == "human", "on the human's cell, any facing (%d), the human is shown" % f)
	_place(d, Vector2i(3, 1), 0)
	_check(d.talk() and d.dialogue.speaker == "[PLACEHOLDER] HUMAN", "Z on the human's cell talks to the human, even facing a wall")
	while d.dialogue.is_open:
		d.dialogue.advance()
	_check(d.npc_picture.visible, "after talking on its cell the human stays shown")
	_place(d, Vector2i(3, 1), 1)
	d.request(Proto.Act.FORWARD)
	while d.busy:
		await process_frame
	_check(d.cell == Vector2i(4, 1) and d.npc_picture.visible and d.npc_picture.texture.resource_path.ends_with("D_Brute Onia.png"), "walking up to the demon shows its picture")
	# Marca no automapa: aparece quando a célula entra na vista 3D (criador).
	var fresh := _new()
	await process_frame
	_check(fresh.npc_seen.has("human") and fresh.npc_seen.has("demon"), "start facing east sees both NPC cells (2 and 4 tiles ahead)")
	fresh.queue_free()
	# Na célula do demônio: a seta do jogador continua visível (sem marca branca por cima).
	_place(d, Vector2i(5, 1), 2)
	_check(d.npc_seen.has("demon") and not d.marked_cells().has(Vector2i(5, 1)) and d.marked_cells().has(Vector2i(3, 1)), "no marker under the player arrow; other seen NPCs stay marked")
	d.npc_seen.clear()
	_place(d, Vector2i(1, 1), 2) # olhando para o sul: corredor oeste, sem NPC
	_check(d.npc_seen.is_empty(), "facing away: no NPC marked")
	_check(not d.npc_cell_in_view(Vector2i(3, 1)), "cell behind/aside is not in view")
	_place(d, Vector2i(1, 7), 0) # olhando para o norte de (1,7): (1,1) a 6 tiles, além do corte
	_check(d.npc_seen.is_empty(), "nothing marked from the far end of the west corridor")
	_place(d, Vector2i(5, 3), 0) # de (5,3) para o norte: (5,2), (5,1) = demônio a 2 tiles
	_check(d.npc_seen.has("demon") and not d.npc_seen.has("human"), "demon seen up the side corridor; human (around the corner) not")
	_check(not d.npc_cell_in_view(Vector2i(3, 1)), "wall blocks the line of sight to the human")
	var mk: Texture2D = d.marker_tex
	var img := mk.get_image()
	_check(mk.get_width() == 16 and img.get_pixel(8, 8) == Color.WHITE and img.get_pixel(9, 4) == Color.BLACK and img.get_pixel(0, 0).a == 0.0, "marker = VX circle in B&W (white body, black shine)")
	d.npc_seen.clear()
	# Falar: Z de frente.
	_place(d, Vector2i(2, 1), 1)
	await process_frame
	_key(KEY_Z, true)
	await process_frame
	_key(KEY_Z, false)
	await process_frame
	var box: DialogueBox = d.dialogue
	_check(box.is_open and box.speaker == "[PLACEHOLDER] HUMAN", "Z facing the human opens its dialogue")
	_check(box.style == "mono" and box.window_rect == d.DIALOGUE_RECT, "first-person dialogue uses the B&W box")
	var pic: TextureRect = d.npc_picture
	_check(pic.visible and pic.texture != null and pic.texture.get_height() == 185, "talking shows the VX picture (185 px source)")
	_check(pic.size == pic.texture.get_size() * 1.5, "picture drawn 1.5x (creator) (%s)" % str(pic.size))
	var pc := pic.position + pic.size / 2.0
	_check(_near(pc.x, 408.0, 1.0) and _near(pc.y, Proto.HORIZON_Y - 10.5, 1.0), "picture centred like VX (272,170 -> 7 px above the horizon, x1.5) (%s)" % str(pc))
	_check(d.FRAME_RECT.encloses(Rect2(pic.position, pic.size)), "picture inside the 3D view")
	_check(not Rect2(pic.position, pic.size).intersects(d.AUTOMAP_RECT) and not Rect2(pic.position, pic.size).intersects(d.DIALOGUE_RECT), "picture clear of automap and dialogue box")
	_check(d.DIALOGUE_RECT.encloses(d.STATUS_RECTS[0]) and d.DIALOGUE_RECT.encloses(d.STATUS_RECTS[1]), "dialogue box covers both status panels")
	_check(d.DIALOGUE_RECT.position.y < d.LOCATION_LINE_Y and d.DIALOGUE_RECT.end.y > d.LOCATION_LINE_Y + 16.0, "dialogue box covers the location name")
	_check(d.DIALOGUE_RECT.position.y >= d.FRAME_RECT.end.y and Rect2(Vector2.ZERO, d.SCREEN).encloses(d.DIALOGUE_RECT), "dialogue box sits below the 3D view, inside the screen")
	var origin: Vector2 = box.text_origin()
	_check(origin.y + (box.lines_per_page - 1) * box.line_height() + 4 <= d.DIALOGUE_RECT.end.y - 6, "last text line fits inside the box")
	_check(box.lines_per_page == 2 and box.text_size == 20, "dialogue: 2 lines of 20 px (creator)")
	_check(box.pages.size() == 1 and box.wrap_text(box.current_page()).size() == 2, "human page fills exactly 2 lines (%d)" % box.wrap_text(box.current_page()).size())
	for line in box.wrap_text(box.current_page()):
		_check(box.font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, box.text_px()).x <= box.text_width(), "dialogue line fits the box width")
	# Datilografia não reflui: as linhas visíveis são prefixos das linhas finais.
	box.shown_chars = 60.0
	var partial: Array[String] = box.visible_lines()
	var full := box.wrap_text(box.current_page())
	_check(partial.size() >= 1 and full[0].begins_with(partial[0]), "typing never moves a word to another line")
	# Aberto: não anda nem gira.
	var c0: Vector2i = d.cell
	d.request(Proto.Act.FORWARD)
	d.request(Proto.Act.TURN_LEFT)
	await process_frame
	_check(d.cell == c0 and d.facing == 1 and not d.busy, "movement locked while the dialogue is open")
	_key(KEY_UP, true)
	for _i in 20:
		await process_frame
	_key(KEY_UP, false)
	_check(d.cell == c0, "held up arrow does not walk during the dialogue")
	# Z: completa, depois fecha.
	for _i in 2:
		_key(KEY_Z, true)
		await process_frame
		_key(KEY_Z, false)
		await process_frame
	_check(not box.is_open, "Z completes then closes a one-page dialogue")
	_check(d.npc_picture.visible, "after the dialogue the NPC in front stays shown")
	# Atravessável: anda para a célula do humano.
	d.request(Proto.Act.FORWARD)
	while d.busy:
		await process_frame
	_check(d.cell == Vector2i(3, 1), "NPCs are passable (creator)")
	# Demônio: duas páginas (a segunda é a curta), Enter também avança.
	_place(d, Vector2i(4, 1), 1)
	_check(d.talk() and box.speaker == "[PLACEHOLDER] DEMON", "talk() facing the demon")
	_check(box.pages.size() == 2, "demon has two pages (%d)" % box.pages.size())
	_check(d.npc_picture.visible and d.npc_picture.texture.resource_path.ends_with("D_Brute Onia.png"), "demon picture shown")
	var guard := 0
	while box.is_open and guard < 10:
		box.advance()
		guard += 1
	_check(not box.is_open and guard == 4, "two pages: reveal, next, reveal, close (%d)" % guard)
	# De costas para o NPC ou de frente para a parede: nada.
	_place(d, Vector2i(4, 1), 0)
	_check(not d.talk() and not box.is_open, "turned away from the demon (north) does not talk")
	_place(d, Vector2i(4, 1), 3)
	_check(d.talk() and box.speaker == "[PLACEHOLDER] HUMAN", "turning back west faces the human again")
	while box.is_open:
		box.advance()
	_place(d, Vector2i(1, 1), 3)
	_check(not d.talk(), "facing a wall does not talk")
	# Página longa vira várias de 3 linhas (nada cortado).
	var long_page: Array[String] = ["[PLACEHOLDER] " + "word ".repeat(120)]
	box.open("TEST", long_page)
	_check(box.pages.size() >= 2, "a page longer than 2 lines is split (%d pages)" % box.pages.size())
	var all_ok := true
	for page in box.pages:
		if box.wrap_text(page).size() > 2:
			all_ok = false
	_check(all_ok, "every split page has at most 2 lines")
	while box.is_open:
		box.advance()
	quit(1 if failed else 0)
