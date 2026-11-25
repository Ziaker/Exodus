extends "res://prototypes/dungeon-crawler/dungeon_proto.gd"
## Overworld do Survival Mode (25x21): santuário central com Curandeiro + Vendedor na
## mesma barra de opções, e 35 demônios de SMT espalhados pelas 4 alas.
## Totalmente isolado da lore e do ProgressStore do jogo principal.

const SERVICE_OPTIONS := [
	{"id": "heal", "label": "HEAL"},
	{"id": "bead", "label": "BEAD 20M"},
	{"id": "chakra", "label": "CHAKRA 20M"},
	{"id": "relics", "label": "RELICS"},
	{"id": "daily", "label": "DAILY SEED"},
	{"id": "new_run", "label": "NEW RUN"},
	{"id": "title", "label": "TITLE"},
	{"id": "leave", "label": "LEAVE"},
]

const SURVIVAL_PANEL_RECT := Rect2(362, 540, 444, 77)
const SERVICE_BAR_RECT := Rect2(6, 502, 804, 116)
const GOLD_INK := Color("f5e08e")
const GREEN_INK := Color("81e6a8")

const TITLE_SCENE := "res://scenes/title/Title.tscn"

var service_open := false
var service_index := 0
var service_feedback := ""
var service_pending := ""
var relic_open := false
var relic_index := 0
var _relic_layer: CanvasLayer
var _relic_panel: Control
var cleared_open := false
var _cleared_layer: CanvasLayer
var _cleared_panel: Control


func _init() -> void:
	battle_scene = SurvivalData.BATTLE_SCENE


func _maze_rows() -> Array:
	return SurvivalData.MAZE


func _npc_defs() -> Array:
	return SurvivalData.NPCS


func _enemy_defs() -> Array:
	# Posições embaralhadas pela semente da run; a run antiga sem seed usa o mapa fixo.
	return SurvivalData.overworld_enemy_defs(int(SurvivalState.data().get("seed", -1)))


func _location_title() -> String:
	return SurvivalData.LOCATION_NAME


func _default_facing() -> int:
	return 0 # Norte: começa olhando de frente para o Curandeiro/Vendedor.


func _ready() -> void:
	super._ready()
	_cleared_layer = CanvasLayer.new()
	_cleared_layer.layer = 60
	_cleared_panel = Control.new()
	_cleared_panel.name = "SurvivalCleared"
	_cleared_panel.size = SCREEN
	_cleared_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cleared_panel.draw.connect(_draw_cleared)
	_cleared_layer.add_child(_cleared_panel)
	add_child(_cleared_layer)
	_check_cleared()


func _map_cell(c: Vector2i) -> void:
	super._map_cell(c)
	_check_cleared()


func _is_modal_open() -> bool:
	return super._is_modal_open() or service_open or relic_open or cleared_open


func _build_party() -> void:
	var s := SurvivalState.data()
	var gains: Dictionary = s.get("gains", {})
	var fs := UnitStats.new()
	fs.max_hp = int(SurvivalData.FALLEN_BASE.max_hp) + int(gains.get("max_hp", 0))
	fs.max_en = int(SurvivalData.FALLEN_BASE.max_en) + int(gains.get("max_en", 0))
	fs.atk = int(SurvivalData.FALLEN_BASE.atk) + int(gains.get("atk", 0))
	fs.mak = int(SurvivalData.FALLEN_BASE.mak) + int(gains.get("mak", 0))
	fs.defense = int(SurvivalData.FALLEN_BASE.defense) + int(gains.get("defense", 0))
	fs.mef = int(SurvivalData.FALLEN_BASE.mef) + int(gains.get("mef", 0))
	fs.agi = int(SurvivalData.FALLEN_BASE.agi) + int(gains.get("agi", 0))
	var fallen := BattleUnit.new(&"fallen", "FALLEN", fs, true, true)
	fallen.current_hp = clampi(int(s.get("fallen_hp", fs.max_hp)), 1, fs.max_hp)
	fallen.current_en = clampi(int(s.get("fallen_en", fs.max_en)), 0, fs.max_en)

	var ys := UnitStats.new()
	ys.max_hp = int(SurvivalData.YOCH_BASE.max_hp)
	ys.max_en = 0
	ys.atk = int(SurvivalData.YOCH_BASE.atk)
	ys.mak = int(SurvivalData.YOCH_BASE.mak)
	ys.defense = int(SurvivalData.YOCH_BASE.defense)
	ys.mef = int(SurvivalData.YOCH_BASE.mef)
	ys.agi = int(SurvivalData.YOCH_BASE.agi)
	var yoch := BattleUnit.new(&"ally", "Yoch", ys, true)
	yoch.race = &"human"
	yoch.start_praying(int(s.get("yoch_pp", SurvivalData.YOCH_BASE.pp)))
	yoch.current_hp = clampi(int(s.get("yoch_hp", ys.max_hp)), 1, ys.max_hp)
	party = [fallen, yoch]


func _sync_party_from_state() -> void:
	_build_party()
	if hud != null:
		hud.queue_redraw()


func talk() -> bool:
	if busy or _is_modal_open():
		return false
	var npc := npc_near()
	if npc.is_empty():
		return false
	if String(npc.get("role", "")) == "sanctuary":
		talk_count += 1
		talking_npc = npc
		_show_picture(npc)
		service_open = true
		service_index = 0
		service_pending = ""
		service_feedback = "HEAL is free. Buy BEAD (HP) or CHAKRA (EN) for battle.  Left/Right: select  Z: confirm  X: leave"
		if hud != null:
			hud.queue_redraw()
		return true
	return super.talk()


func close_service() -> void:
	if not service_open:
		return
	service_open = false
	service_pending = ""
	talking_npc = {}
	_up_needs_release = true
	refresh_front_picture()
	if hud != null:
		hud.queue_redraw()


func move_service_cursor(delta: int) -> void:
	if not service_open:
		return
	service_pending = ""
	service_index = posmod(service_index + delta, SERVICE_OPTIONS.size())
	if hud != null:
		hud.queue_redraw()


func confirm_service_option() -> String:
	if not service_open:
		return ""
	var opt_id := String(SERVICE_OPTIONS[service_index].id)
	if opt_id in ["new_run", "daily"] and service_pending != opt_id:
		service_pending = opt_id
		service_feedback = ("RESET THE RUN? Press Z again to confirm. X cancels."
				if opt_id == "new_run" else "DAILY SEED? Restarts with today's layout. Z again confirms, X cancels.")
		if hud != null:
			hud.queue_redraw()
		return opt_id
	service_pending = ""
	match opt_id:
		"heal":
			SurvivalState.heal_party_full()
			_sync_party_from_state()
			service_feedback = "Party HP and EN fully restored!"
		"bead":
			if SurvivalState.buy_item("bead"):
				service_feedback = "Bought BEAD (+20 HP). Bag: BEAD x%d" % int(SurvivalState.data().bead)
			else:
				service_feedback = "NOT ENOUGH MACCA (need 20M)."
		"chakra":
			if SurvivalState.buy_item("chakra"):
				service_feedback = "Bought CHAKRA (+10 EN). Bag: CHAKRA x%d" % int(SurvivalState.data().chakra)
			else:
				service_feedback = "NOT ENOUGH MACCA (need 20M)."
		"relics":
			_open_relics()
		"daily":
			close_service()
			SurvivalState.reset()
			SurvivalState.patch({"seed": SurvivalData.daily_seed()})
			_reload_world()
		"new_run":
			close_service()
			SurvivalState.reset()
			_reload_world()
		"title":
			close_service()
			var fader := get_tree().root.get_node_or_null("SceneFader")
			if fader != null:
				fader.fade_to(TITLE_SCENE)
			else:
				get_tree().change_scene_to_file(TITLE_SCENE)
		"leave":
			close_service()
	if hud != null:
		hud.queue_redraw()
	return opt_id


func _owned_relics() -> Array[String]:
	var out: Array[String] = []
	for id in SurvivalState.data().get("relics", []):
		out.append(String(id))
	return out


func _open_relics() -> void:
	close_service()
	relic_open = true
	relic_index = 0
	_relic_layer = CanvasLayer.new()
	_relic_layer.layer = 62
	_relic_panel = Control.new()
	_relic_panel.name = "RelicEquipment"
	_relic_panel.size = SCREEN
	_relic_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_relic_panel.draw.connect(_draw_relics)
	_relic_layer.add_child(_relic_panel)
	add_child(_relic_layer)
	_relic_panel.queue_redraw()


func _close_relics() -> void:
	relic_open = false
	if _relic_layer != null:
		_relic_layer.queue_free()
	_relic_layer = null
	_relic_panel = null
	if hud != null:
		hud.queue_redraw()


func _equip_relic(who: String) -> void:
	var owned := _owned_relics()
	if owned.is_empty():
		return
	var id := owned[clampi(relic_index, 0, owned.size() - 1)]
	SurvivalState.toggle_relic(who, id)
	_sync_party_from_state()
	if _relic_panel != null:
		_relic_panel.queue_redraw()


func _draw_relics() -> void:
	if _relic_panel == null or not relic_open:
		return
	var s := SurvivalState.data()
	var bounds := Rect2(20, 90, 500, 300)
	_relic_panel.draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0.02, 0.01, 0.03, 0.86))
	_relic_panel.draw_rect(bounds, Color(0.06, 0.03, 0.05, 0.98))
	_relic_panel.draw_rect(bounds, Color("f5e08e"), false, 1.5)
	_draw_relic_text(bold_font(), "ANCIENT RELICS", bounds.get_center().x, bounds.position.y + 18, 15, Color("f5e08e"))
	var f: Array = s.get("fallen_relics", [])
	var y: Array = s.get("yoch_relics", [])
	_draw_relic_text(bold_font(), "FALLEN %d/2: %s" % [f.size(), ", ".join(_ids(f))],
			bounds.position.x + 12, bounds.position.y + 44, 11, Color("81e6a8"))
	_draw_relic_text(bold_font(), "YOCH %d/2: %s" % [y.size(), ", ".join(_ids(y))],
			bounds.position.x + 12, bounds.position.y + 62, 11, Color("7fd4ff"))
	_relic_panel.draw_line(Vector2(bounds.position.x + 10, bounds.position.y + 76),
			Vector2(bounds.end.x - 10, bounds.position.y + 76), Color(1, 1, 1, 0.25))
	var owned := _owned_relics()
	for i in owned.size():
		var row_y := bounds.position.y + 88 + i * 18
		if row_y > bounds.end.y - 60:
			break
		var selected := i == relic_index
		if selected:
			_relic_panel.draw_rect(Rect2(bounds.position.x + 10, row_y - 2, bounds.size.x - 20, 17), Color(1, 1, 1, 0.16))
		_draw_relic_text(ui_font_regular(), ("> " if selected else "  ") + SurvivalRelics.label(owned[i]),
				bounds.position.x + 16, row_y + 11, 10, Color.WHITE if selected else Color("f7f3ed"))
	_draw_relic_text(bold_font(), "Left/Right: select   Z: Fallen   X: Yoch   Esc: close",
			bounds.get_center().x, bounds.end.y - 16, 10, Color("f7f3ed"))


func _ids(arr: Array) -> Array[String]:
	var out: Array[String] = []
	for id in arr:
		out.append(String(id))
	return out


func bold_font() -> Font:
	return ui_bold if ui_bold != null else ui_font


func ui_font_regular() -> Font:
	return ui_font


func _draw_relic_text(font: Font, text: String, x: float, y: float, px: int, color: Color) -> void:
	_relic_panel.draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)


func _reload_world() -> void:
	# No jogo current_scene é o próprio SurvivalWorld; testes instanciam a cena
	# à mão, então não há current_scene e o reload faria nada/geraria erro.
	if get_tree().current_scene != null:
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file(SurvivalData.WORLD_SCENE)


func _check_cleared() -> void:
	if cleared_open or _cleared_panel == null:
		return
	var defeated: Array = SurvivalState.data().get("defeated", [])
	if defeated.size() < SurvivalData.DEMONS.size():
		return
	cleared_open = true
	_cleared_panel.show()
	_cleared_panel.queue_redraw()
	if hud != null:
		hud.queue_redraw()


func _draw_cleared() -> void:
	if _cleared_panel == null or not cleared_open:
		return
	var s := SurvivalState.data()
	var box := Rect2(92, 116, 440, 196)
	_cleared_panel.draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0.02, 0.01, 0.03, 0.88))
	_cleared_panel.draw_rect(box, Color(0.06, 0.03, 0.05, 0.97))
	_cleared_panel.draw_rect(box, Color("f5e08e"), false, 1.5)
	var cx := box.get_center().x
	var bold: Font = ui_bold if ui_bold != null else ui_font
	_centered(bold, "SURVIVAL CLEARED", cx, box.position.y + 36, 22, Color("f5e08e"))
	_centered(ui_font, "All %d demons defeated." % SurvivalData.DEMONS.size(),
			cx, box.position.y + 76, 14, Color("f7f3ed"))
	_centered(ui_font, "MACCA %dM   |   CONTINUES %d/%d" % [
			int(s.get("macca", 0)), int(s.get("continues", 0)), SurvivalData.MAX_CONTINUES],
			cx, box.position.y + 106, 13, GOLD_INK)
	var meta := SurvivalMeta.data()
	_centered(ui_font_regular(), "SCORE %d   BEST %d" % [int(meta.last_score), int(meta.best)],
			cx, box.position.y + 132, 11, Color("f7f3ed"))
	_centered(bold, "Z: NEW RUN     X: TITLE", cx, box.position.y + 154, 13, GREEN_INK)


func _centered(font: Font, text: String, cx: float, y: float, px: int, color: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	_cleared_panel.draw_string(font, Vector2(cx - w * 0.5, y), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)


func _unhandled_input(event: InputEvent) -> void:
	if relic_open:
		if not (event is InputEventKey) or event.echo or not event.pressed:
			return
		var k := event as InputEventKey
		match k.keycode:
			KEY_LEFT, KEY_UP:
				relic_index = posmod(relic_index - 1, maxi(1, _owned_relics().size()))
				_relic_panel.queue_redraw()
			KEY_RIGHT, KEY_DOWN:
				relic_index = posmod(relic_index + 1, maxi(1, _owned_relics().size()))
				_relic_panel.queue_redraw()
			KEY_Z, KEY_ENTER, KEY_KP_ENTER:
				_equip_relic("fallen")
			KEY_X:
				_equip_relic("yoch")
			KEY_ESCAPE:
				_close_relics()
		get_viewport().set_input_as_handled()
		return
	if cleared_open:
		if not (event is InputEventKey) or event.echo or not event.pressed:
			return
		var k := event as InputEventKey
		if k.keycode in [KEY_Z, KEY_ENTER, KEY_KP_ENTER]:
			SurvivalState.reset()
			_reload_world()
		elif k.keycode in [KEY_X, KEY_ESCAPE]:
			var fader := get_tree().root.get_node_or_null("SceneFader")
			if fader != null:
				fader.fade_to(TITLE_SCENE)
			else:
				get_tree().change_scene_to_file(TITLE_SCENE)
		get_viewport().set_input_as_handled()
		return
	if service_open:
		if not (event is InputEventKey) or event.echo or not event.pressed:
			return
		var k := event as InputEventKey
		match k.keycode:
			KEY_LEFT, KEY_UP:
				move_service_cursor(-1)
			KEY_RIGHT, KEY_DOWN:
				move_service_cursor(1)
			KEY_Z, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				confirm_service_option()
			KEY_X, KEY_ESCAPE:
				if service_pending != "":
					service_pending = ""
					service_feedback = "CANCELLED — run kept."
					if hud != null:
						hud.queue_redraw()
				else:
					close_service()
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)


## Direção e distância até o demônio vivo mais próximo (labirinto é grande).
func nearest_demon_hint() -> String:
	if enemies == null or enemies.entries.is_empty():
		return "ALL CLEAR"
	var best := 1 << 30
	var best_delta := Vector2i.ZERO
	for enemy in enemies.entries:
		var delta: Vector2i = enemy.cell - cell
		var dist := absi(delta.x) + absi(delta.y)
		if dist < best:
			best = dist
			best_delta = delta
	var arrow := "N"
	if absi(best_delta.x) >= absi(best_delta.y):
		arrow = "E" if best_delta.x > 0 else "W"
	else:
		arrow = "S" if best_delta.y > 0 else "N"
	return "%s %d" % [arrow, best]


func _draw_extra_hud() -> void:
	var s := SurvivalState.data()
	var defeated_count := (s.get("defeated", []) as Array).size()
	var macca := int(s.get("macca", 0))
	var continues := int(s.get("continues", SurvivalData.MAX_CONTINUES))
	var beads := int(s.get("bead", 0))
	var chakras := int(s.get("chakra", 0))

	if not service_open:
		var npc := npc_near()
		if not npc.is_empty() and String(npc.get("role", "")) == "sanctuary":
			_str("Z: HEAL & SHOP", 420, LOCATION_LINE_Y + 15.5, GREEN_INK, 12, true)
		var r := SURVIVAL_PANEL_RECT
		hud.draw_line(Vector2(r.position.x, r.position.y + 0.5), Vector2(r.end.x, r.position.y + 0.5), Color(1, 1, 1, 0.35))
		var x := r.position.x + 8
		var right := r.end.x - 8
		_str("SURVIVAL SEED %d" % int(s.get("seed", 0)), x, r.position.y + 18, Color.WHITE, 13, true)
		var status_text := "ALL %d CLEARED!" % SurvivalData.DEMONS.size() if defeated_count >= SurvivalData.DEMONS.size() else "DEMONS %d/%d" % [defeated_count, SurvivalData.DEMONS.size()]
		var status_col := GREEN_INK if defeated_count >= SurvivalData.DEMONS.size() else INK
		_str(status_text, right, r.position.y + 18, status_col, 12, true, HORIZONTAL_ALIGNMENT_RIGHT)
		_str("MACCA %dM" % macca, x, r.position.y + 40, GOLD_INK, 12, true)
		_str("CONTINUES %d/%d" % [continues, SurvivalData.MAX_CONTINUES], right, r.position.y + 40, INK, 11, true, HORIZONTAL_ALIGNMENT_RIGHT)
		_str("BAG: BEAD x%d   CHAKRA x%d" % [beads, chakras], x, r.position.y + 61, INK, 11)
		_str("NEXT: %s" % nearest_demon_hint(), right, r.position.y + 61, ENEMY_INK, 11, true, HORIZONTAL_ALIGNMENT_RIGHT)
		return

	# Barra unificada de Curandeiro + Vendedor sobre o painel inferior.
	var bar := SERVICE_BAR_RECT
	# Fundo opaco: o HUD base desenha o painel antes desta barra e o texto vazaria.
	hud.draw_rect(bar, Color(0.03, 0.03, 0.04, 1.0))
	hud.draw_rect(Rect2(bar.position + Vector2(0.5, 0.5), bar.size - Vector2.ONE), Color(1, 1, 1, 0.65), false, 1)
	_str("SANCTUARY KEEPER  |  HEAL & SHOP", bar.position.x + 12, bar.position.y + 20, Color.WHITE, 13, true)
	_str("MACCA: %dM   BEAD x%d   CHAKRA x%d" % [macca, beads, chakras], bar.end.x - 12, bar.position.y + 20, GOLD_INK, 12, true, HORIZONTAL_ALIGNMENT_RIGHT)
	hud.draw_line(Vector2(bar.position.x + 10, bar.position.y + 29), Vector2(bar.end.x - 10, bar.position.y + 29), Color(1, 1, 1, 0.28))

	var opt_count := SERVICE_OPTIONS.size()
	var margin_x := 12.0
	var gap := 8.0
	var cell_w := (bar.size.x - margin_x * 2.0 - gap * float(opt_count - 1)) / float(opt_count)
	var opt_y := bar.position.y + 39.0
	var opt_h := 36.0
	for i in opt_count:
		var rx := bar.position.x + margin_x + float(i) * (cell_w + gap)
		var cell_rect := Rect2(rx, opt_y, cell_w, opt_h)
		var selected := (i == service_index)
		hud.draw_rect(cell_rect, Color(1, 1, 1, 0.16) if selected else Color(1, 1, 1, 0.04))
		hud.draw_rect(cell_rect, Color.WHITE if selected else Color(1, 1, 1, 0.32), false, 1.5 if selected else 1.0)
		var label := ("> " if selected else "  ") + String(SERVICE_OPTIONS[i].label)
		_str(label, cell_rect.get_center().x, opt_y + 23.0, Color.WHITE if selected else INK, 12, selected, HORIZONTAL_ALIGNMENT_CENTER)

	hud.draw_line(Vector2(bar.position.x + 10, bar.position.y + 84), Vector2(bar.end.x - 10, bar.position.y + 84), Color(1, 1, 1, 0.2))
	_str(service_feedback, bar.position.x + 12, bar.position.y + 103, INK, 11)


func _after_player_step() -> void:
	if not enemies_enabled or encounter_pending or enemies == null:
		return
	var before := {}
	for enemy in enemies.entries:
		before[String(enemy.id)] = enemy.cell
	var hit: Dictionary = enemies.at(cell)
	if hit.is_empty():
		hit = _step_nearby_demons()
	for enemy in enemies.entries:
		var id := String(enemy.id)
		if before.has(id) and before[id] != enemy.cell:
			_animate_enemy_sprite(id, before[id], enemy.cell)
	if not hit.is_empty():
		_begin_battle(hit)
	else:
		_update_enemy_seen()


## Demônios próximos (<= CHASE_RADIUS) perseguem o jogador, mas nunca invadem o santuário seguro.
func _step_nearby_demons() -> Dictionary:
	for enemy in enemies.entries:
		var delta: Vector2i = cell - enemy.cell
		if delta == Vector2i.ZERO:
			return enemy
		var dist := absi(delta.x) + absi(delta.y)
		if dist > SurvivalData.CHASE_RADIUS:
			continue
		var horizontal := Vector2i(int(signf(float(delta.x))), 0)
		var vertical := Vector2i(0, int(signf(float(delta.y))))
		var options: Array[Vector2i] = []
		if absi(delta.x) >= absi(delta.y):
			options = [horizontal, vertical]
		else:
			options = [vertical, horizontal]
		for direction in options:
			if direction == Vector2i.ZERO:
				continue
			var target: Vector2i = enemy.cell + direction
			if target == cell and not SurvivalData.SAFE_ZONE.has_point(target):
				enemy.cell = target
				return enemy
			if is_wall(target) or SurvivalData.SAFE_ZONE.has_point(target) or not enemies.at(target).is_empty():
				continue
			enemy.cell = target
			break
		if enemy.cell == cell:
			return enemy
	return {}


func _begin_battle(enemy: Dictionary) -> void:
	SurvivalState.patch({"encounter_id": String(enemy.get("id", ""))})
	super._begin_battle(enemy)


func _save_state() -> void:
	var route: Array = []
	for key in visited.keys():
		var c: Vector2i = key
		route.append([c.x, c.y])
	SurvivalState.patch({
		"cell": [cell.x, cell.y],
		"facing": facing,
		"enemies": enemies.serialise(),
		"visited": route,
		"seen": enemies.seen.keys(),
	})
	Engine.set_meta(DUNGEON_RETURN_META, SurvivalData.WORLD_SCENE)


func _restore_state() -> void:
	var saved := SurvivalState.data()
	var pos: Array = saved.get("cell", [])
	if pos.size() == 2:
		cell = Vector2i(int(pos[0]), int(pos[1]))
	facing = int(saved.get("facing", facing))
	var defeated: Array = saved.get("defeated", [])
	var saved_enemies: Array = saved.get("enemies", [])
	if not saved_enemies.is_empty():
		enemies.restore(saved_enemies)
	# Reforços e derrotados de qualquer save não voltam ao mapa (mesmo quando a
	# lista salva está vazia e o estado foi gravado à mão ou ficou inconsistente).
	for entry in enemies.entries.duplicate():
		if defeated.has(String(entry.id)):
			enemies.entries.erase(entry)
	if defeated.size() >= SurvivalData.DEMONS.size():
		# Se já derrotou todos os 35, nenhum inimigo volta.
		enemies.entries.clear()
	for item in saved.get("visited", []):
		var c: Array = item
		if c.size() == 2:
			visited[Vector2i(int(c[0]), int(c[1]))] = true
	for id in saved.get("seen", []):
		enemies.seen[String(id)] = true
