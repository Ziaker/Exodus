extends "res://prototypes/dungeon-crawler/dungeon_proto.gd"
## Overworld do Survival Mode. D-066: a run tem 5 estratos; cada um tem um
## labirinto, 7 demônios e um GUARDIÃO
## no ponto mais fundo. Santuário central com o atendente (cura, loja, relíquias,
## descida) e, D-074, 3 eventos por estrato como figuras SMT no corredor.
## Totalmente isolado da lore e do ProgressStore do jogo principal.

const SURVIVAL_PANEL_RECT := Rect2(362, 540, 444, 77)
const SERVICE_BAR_RECT := Rect2(6, 502, 804, 116)
const GOLD_INK := Color("f5e08e")
const GREEN_INK := Color("81e6a8")
const BLUE_INK := Color("7fd4ff")
const PANEL_RECT := Rect2(108, 56, 600, 400)

const TITLE_SCENE := "res://scenes/title/Title.tscn"
const NECROPOLE_VISUAL := preload("res://scripts/survival/necropole_visual.gd")

var service_open := false
var service_index := 0
var service_feedback := ""
var service_pending := ""
var relic_open := false
var relic_index := 0
var shop_open := false
var shop_index := 0
var shop_feedback := ""
var event_open := false
var event_index := 0
var event_feedback := ""
var active_event: Dictionary = {}
var relic_choice_open := false
var relic_choice_index := 0
var cleared_open := false
var loot_toast := ""
## Meta lido do disco uma vez (o HUD redesenha muito; recarrega após finish_run).
var _meta_cache: Dictionary = {}
## Um único overlay para relíquias, loja, escolha do guardião e fim de run.
var _overlay_layer: CanvasLayer
var _overlay: Control


func _init() -> void:
	battle_scene = SurvivalData.BATTLE_SCENE


func _maze_rows() -> Array:
	return SurvivalState.maze_rows()


func _build_world() -> void:
	if SurvivalState.stratum() != 1:
		super._build_world()
		return
	parallax.hide()
	viewport.transparent_bg = false
	var world := Node3D.new()
	viewport.add_child(world)
	_build_camera(world)
	var necropole := NECROPOLE_VISUAL.new()
	world.add_child(necropole)
	necropole.install(pivot, camera)
	_build_enemy_sprites(world)


func _can_step(from: Vector2i, to: Vector2i) -> bool:
	return super._can_step(from, to) and SurvivalStrata.edge_is_open(from, to, SurvivalState.stratum())


## Atendente + eventos ainda não resolvidos do estrato.
func _npc_defs() -> Array:
	var out: Array = SurvivalData.NPCS.duplicate(true)
	out[0].cell = SurvivalStrata.entrance(SurvivalState.stratum()) + Vector2i.UP
	var s := SurvivalState.data()
	var done: Array = s.get("events_done", [])
	for ev in SurvivalStrata.layout(int(s.get("seed", 1)), SurvivalState.stratum()).events:
		if done.has(String(ev.id)):
			continue
		var def: Dictionary = SurvivalData.EVENT_DEFS[String(ev.kind)]
		out.append({"id": String(ev.id), "role": "event", "kind": String(ev.kind),
			"cell": ev.cell, "picture": String(def.picture), "name": String(def.name),
			"pages": [String(def.text)]})
	return out


func _enemy_defs() -> Array:
	var s := SurvivalState.data()
	var defeated: Array = s.get("defeated", [])
	var out: Array = []
	for e in SurvivalData.stratum_enemy_defs(int(s.get("seed", 1)), SurvivalState.stratum()):
		if not defeated.has(String(e.id)):
			out.append(e)
	return out


func _location_title() -> String:
	var stratum := SurvivalState.stratum()
	var name := "NECRÓPOLE SATURNINA" if stratum == 1 else SurvivalData.LOCATION_NAME
	return "%s — STRATUM %d/%d" % [name, stratum, SurvivalStrata.COUNT]


func _default_facing() -> int:
	return 0 # Norte: começa olhando de frente para o Curandeiro/Vendedor.


func meta() -> Dictionary:
	if _meta_cache.is_empty():
		_meta_cache = SurvivalMeta.data()
	return _meta_cache


func _ready() -> void:
	super._ready()
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 60
	_overlay = Control.new()
	_overlay.name = "SurvivalOverlay"
	_overlay.size = SCREEN
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	_overlay_layer.add_child(_overlay)
	add_child(_overlay_layer)
	var s := SurvivalState.data()
	if not String(s.get("last_loot", "")).is_empty():
		loot_toast = "RELIC FOUND: %s — equip it at RELICS" % SurvivalRelics.name_of(String(s.last_loot))
		SurvivalState.patch({"last_loot": ""})
	if not (s.get("pending_relic_choice", []) as Array).is_empty():
		relic_choice_open = true
		relic_choice_index = 0
	_check_cleared()
	_redraw()


func _redraw() -> void:
	if _overlay != null:
		_overlay.queue_redraw()
	if hud != null:
		hud.queue_redraw()


func _map_cell(c: Vector2i) -> void:
	super._map_cell(c)
	_check_cleared()


func _is_modal_open() -> bool:
	return super._is_modal_open() or service_open or relic_open or cleared_open \
			or shop_open or event_open or relic_choice_open


func _build_party() -> void:
	var s := SurvivalState.data()
	var fallen := BattleUnit.new(&"fallen", "FALLEN", SurvivalState.fallen_stats(), true, true)
	fallen.current_hp = clampi(int(s.get("fallen_hp", fallen.stats.max_hp)), 1, fallen.stats.max_hp)
	fallen.current_en = clampi(int(s.get("fallen_en", fallen.stats.max_en)), 0, fallen.stats.max_en)
	var yoch := BattleUnit.new(&"ally", "Yoch", SurvivalState.yoch_stats(), true)
	yoch.race = &"human"
	yoch.start_praying(int(s.get("yoch_pp", SurvivalData.YOCH_BASE.pp)))
	yoch.current_hp = clampi(int(s.get("yoch_hp", yoch.stats.max_hp)), 1, yoch.stats.max_hp)
	party = [fallen, yoch]


func _sync_party_from_state() -> void:
	_build_party()
	_redraw()


# ------------------------------------------------------------ santuário (barra)

## D-066/D-068/D-075: a barra muda com o estado (preço da cura, descida, OMEN).
func service_options() -> Array[Dictionary]:
	var s := SurvivalState.data()
	var price := SurvivalState.heal_price()
	var out: Array[Dictionary] = [
		{"id": "heal", "label": "HEAL FREE" if price == 0 else "HEAL %dM" % price},
		{"id": "shop", "label": "SHOP"},
		{"id": "relics", "label": "RELICS"},
	]
	if SurvivalState.warden_down() and SurvivalState.stratum() < SurvivalStrata.COUNT:
		out.append({"id": "descend", "label": "DESCEND"})
	if int(s.get("battles", 0)) == 0 and SurvivalState.stratum() == 1 \
			and int(meta().omen_unlocked) > 0:
		out.append({"id": "omen", "label": "OMEN %d" % SurvivalState.omen()})
	out.append_array([
		{"id": "new_run", "label": "NEW RUN"},
		{"id": "daily", "label": "DAILY"},
		{"id": "title", "label": "TITLE"},
		{"id": "leave", "label": "LEAVE"},
	])
	return out


func service_index_of(id: String) -> int:
	var opts := service_options()
	for i in opts.size():
		if String(opts[i].id) == id:
			return i
	return -1


func talk() -> bool:
	if busy or _is_modal_open():
		return false
	var npc := npc_near()
	if npc.is_empty():
		return false
	var role := String(npc.get("role", ""))
	if role == "sanctuary":
		talk_count += 1
		talking_npc = npc
		_show_picture(npc)
		service_open = true
		service_index = 0
		service_pending = ""
		service_feedback = "%s. SHOP sells items and relics.  Left/Right: select  Z: confirm  X: leave" % (
				"HEAL is free once per stratum" if SurvivalState.heal_price() == 0 else "HEAL costs Macca now")
		_redraw()
		return true
	if role == "event":
		talk_count += 1
		talking_npc = npc
		_show_picture(npc)
		active_event = npc
		event_open = true
		event_index = 0
		event_feedback = String((npc.pages as Array)[0])
		_redraw()
		return true
	return super.talk()


var _trimmed_pictures := {}


## As figuras dos eventos (D-074) não têm todas 185 px como as do VX: a do Jack Frost
## mercador tem 216 px com espaço vazio embaixo e flutuava. Aqui a figura é recortada
## na parte opaca e os pés ficam na mesma linha de chão de uma figura de 185 px.
func _show_picture(npc: Dictionary) -> void:
	if String(npc.get("role", "")) != "event":
		super._show_picture(npc)
		return
	var path := String(npc.picture)
	if not _trimmed_pictures.has(path):
		var src: Texture2D = load(path)
		var atlas := AtlasTexture.new()
		atlas.atlas = src
		atlas.region = Rect2(src.get_image().get_used_rect())
		_trimmed_pictures[path] = atlas
	var tex: Texture2D = _trimmed_pictures[path]
	var sz := tex.get_size() * NPC_PICTURE_SCALE
	var floor_y := NPC_PICTURE_CENTER.y + 185.0 * NPC_PICTURE_SCALE * 0.5
	npc_picture.texture = tex
	npc_picture.size = sz
	npc_picture.position = Vector2(NPC_PICTURE_CENTER.x - sz.x * 0.5, floor_y - sz.y).floor()
	npc_picture.visible = true


func close_service() -> void:
	if not service_open:
		return
	service_open = false
	service_pending = ""
	talking_npc = {}
	_up_needs_release = true
	refresh_front_picture()
	_redraw()


func move_service_cursor(delta: int) -> void:
	if not service_open:
		return
	service_pending = ""
	service_index = posmod(service_index + delta, service_options().size())
	_redraw()


func confirm_service_option() -> String:
	if not service_open:
		return ""
	var opts := service_options()
	service_index = clampi(service_index, 0, opts.size() - 1)
	var opt_id := String(opts[service_index].id)
	if opt_id in ["new_run", "daily", "descend"] and service_pending != opt_id:
		service_pending = opt_id
		match opt_id:
			"new_run": service_feedback = "RESET THE RUN? Press Z again to confirm. X cancels."
			"daily": service_feedback = "DAILY SEED? Restarts with today's layout. Z again confirms, X cancels."
			"descend": service_feedback = "DESCEND TO STRATUM %d? Demons left here stay behind. Z again confirms." % (SurvivalState.stratum() + 1)
		_redraw()
		return opt_id
	service_pending = ""
	match opt_id:
		"heal":
			var price := SurvivalState.heal_price()
			if SurvivalState.sanctuary_heal():
				_sync_party_from_state()
				service_feedback = "Party HP and EN fully restored%s!" % ("" if price == 0 else " (-%dM)" % price)
			else:
				service_feedback = "NOT ENOUGH MACCA (heal costs %dM)." % price
		"shop":
			open_shop()
		"relics":
			_open_relics()
		"descend":
			close_service()
			if SurvivalState.descend():
				_reload_world()
		"omen":
			var top := int(meta().omen_unlocked)
			var next := posmod(SurvivalState.omen() + 1, top + 1)
			set_omen(next)
			service_feedback = String(SurvivalMeta.OMEN_INFO[next])
		"daily":
			close_service()
			_start_run(SurvivalData.daily_seed())
		"new_run":
			close_service()
			_start_run(-1)
		"title":
			close_service()
			_go_title()
		"leave":
			close_service()
	_redraw()
	return opt_id


## D-075: OMEN só muda antes da primeira luta; OMEN 4 tira um continue.
func set_omen(level: int) -> void:
	var lv := clampi(level, 0, int(meta().omen_unlocked))
	SurvivalState.patch({"omen": lv})
	SurvivalState.patch({"continues": SurvivalState.max_continues()})


func _start_run(seed: int) -> void:
	SurvivalState.reset()
	if seed >= 0:
		SurvivalState.patch({"seed": seed, "relics": [SurvivalRelics.starting_relic(seed)]})
	_reload_world()


func _go_title() -> void:
	var fader := get_tree().root.get_node_or_null("SceneFader")
	if fader != null:
		fader.fade_to(TITLE_SCENE)
	else:
		get_tree().change_scene_to_file(TITLE_SCENE)


# ------------------------------------------------------------ D-072: loja

func shop_rows() -> Array[Dictionary]:
	var s := SurvivalState.data()
	var rows: Array[Dictionary] = []
	for id in SurvivalData.shop_stock(int(s.get("seed", 1)), SurvivalState.stratum()):
		var item := SurvivalData.shop_item(id)
		rows.append({"kind": "item", "id": id, "price": SurvivalState.item_price(id),
			"label": String(item.name), "info": String(item.info), "owned": int(s.get(id, 0))})
	var relic := shop_relic()
	if not relic.is_empty() and not bool(s.get("shop_relic_sold", false)):
		rows.append({"kind": "relic", "id": relic, "price": relic_price(),
			"label": SurvivalRelics.name_of(relic), "info": String(SurvivalRelics.relic(relic).info), "owned": 0})
	return rows


## Relíquia à venda no estrato (semente + estrato; some se já possuída).
func shop_relic() -> String:
	var s := SurvivalState.data()
	var rng := RandomNumberGenerator.new()
	rng.seed = (absi(int(s.get("seed", 1))) + SurvivalState.stratum() * 48_271) % 2147483647
	var pick := SurvivalRelics.roll(rng, [], meta().get("unlocked", []), 1)
	if pick.is_empty() or (s.get("relics", []) as Array).has(pick[0]):
		return ""
	return pick[0]


func relic_price() -> int:
	return SurvivalData.price(SurvivalData.RELIC_BASE_PRICE, SurvivalState.stratum(), SurvivalState.data())


func open_shop() -> void:
	close_service()
	shop_open = true
	shop_index = 0
	shop_feedback = "Up/Down: select   Z: buy   X: back"
	_redraw()


func close_shop() -> void:
	shop_open = false
	_redraw()


func move_shop_cursor(delta: int) -> void:
	if shop_open:
		shop_index = posmod(shop_index + delta, maxi(1, shop_rows().size()))
		_redraw()


func confirm_shop() -> bool:
	if not shop_open:
		return false
	var rows := shop_rows()
	if rows.is_empty():
		return false
	var row: Dictionary = rows[clampi(shop_index, 0, rows.size() - 1)]
	var ok := false
	if String(row.kind) == "item":
		ok = SurvivalState.buy_item(String(row.id))
		shop_feedback = ("Bought %s. Bag: x%d" % [String(row.label), int(SurvivalState.data().get(String(row.id), 0))]) \
				if ok else "NOT ENOUGH MACCA (need %dM)." % int(row.price)
	else:
		var s := SurvivalState.data()
		if int(s.get("macca", 0)) >= int(row.price):
			SurvivalState.patch({"macca": int(s.macca) - int(row.price), "shop_relic_sold": true})
			SurvivalState.grant_relic(String(row.id))
			ok = true
			shop_feedback = "Bought %s. Equip it at RELICS." % String(row.label)
			shop_index = 0
		else:
			shop_feedback = "NOT ENOUGH MACCA (need %dM)." % int(row.price)
	_redraw()
	return ok


# ------------------------------------------------------------ D-074: eventos

func event_options() -> Array[Dictionary]:
	if active_event.is_empty():
		return []
	var max_hp := SurvivalState.fallen_max_hp()
	match String(active_event.kind):
		"altar":
			return [{"id": "offer", "label": "OFFER BLOOD: -%d HP → RELIC" % _altar_cost()}, {"id": "leave", "label": "LEAVE"}]
		"spirit":
			return [{"id": "rest", "label": "REST: party +50% HP"},
				{"id": "commune", "label": "COMMUNE: -15 HP, +2 STAT"}, {"id": "leave", "label": "LEAVE"}]
		"oracle":
			return [{"id": "secret", "label": "SECRET %dM → NEW SKILL" % _oracle_price()},
				{"id": "gamble", "label": "GAMBLE: +3 STAT or -30 HP"}, {"id": "leave", "label": "LEAVE"}]
		"merchant":
			return [{"id": "buy", "label": "BUY %s %dM" % [SurvivalRelics.name_of(_merchant_relic()), _merchant_price()]},
				{"id": "leave", "label": "LEAVE"}]
	var _unused := max_hp
	return [{"id": "leave", "label": "LEAVE"}]


func _event_rng(salt: int = 0) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = (absi(int(SurvivalState.data().get("seed", 1))) + absi(String(active_event.get("id", "")).hash()) + salt) % 2147483647
	return rng


func _altar_cost() -> int:
	return int(ceil(float(SurvivalState.fallen_max_hp()) * 0.25))


func _oracle_price() -> int:
	return SurvivalData.price(40, SurvivalState.stratum(), SurvivalState.data())


func _merchant_relic() -> String:
	var pick := SurvivalRelics.roll(_event_rng(7), SurvivalState.data().get("relics", []),
			meta().get("unlocked", []), 1)
	return "" if pick.is_empty() else pick[0]


func _merchant_price() -> int:
	return int(round(float(relic_price()) * 0.8))


func move_event_cursor(delta: int) -> void:
	if event_open:
		event_index = posmod(event_index + delta, maxi(1, event_options().size()))
		_redraw()


func close_event() -> void:
	event_open = false
	active_event = {}
	talking_npc = {}
	_up_needs_release = true
	refresh_front_picture()
	_redraw()


## Resolve a escolha. Retorna o id; um evento usado some do mapa (LEAVE mantém).
func confirm_event() -> String:
	if not event_open:
		return ""
	var opts := event_options()
	var opt: Dictionary = opts[clampi(event_index, 0, opts.size() - 1)]
	var id := String(opt.id)
	var s := SurvivalState.data()
	var done := false
	match id:
		"leave":
			close_event()
			return id
		"offer":
			var cost := _altar_cost()
			if int(s.fallen_hp) <= cost:
				event_feedback = "Too weak: the altar would kill you (need more than %d HP)." % cost
			else:
				var drop := SurvivalRelics.roll(_event_rng(1), s.get("relics", []), meta().get("unlocked", []), 1)
				SurvivalState.patch({"fallen_hp": int(s.fallen_hp) - cost})
				if not drop.is_empty():
					SurvivalState.grant_relic(drop[0])
					event_feedback = "The altar drinks. RELIC: %s." % SurvivalRelics.name_of(drop[0])
				else:
					SurvivalState.patch({"macca": int(s.macca) + 100})
					event_feedback = "No relic left to give: +100M instead."
				done = true
		"rest":
			SurvivalState.patch({
				"fallen_hp": mini(SurvivalState.fallen_max_hp(), int(s.fallen_hp) + SurvivalState.fallen_max_hp() / 2),
				"yoch_hp": mini(SurvivalState.yoch_max_hp(), int(s.yoch_hp) + SurvivalState.yoch_max_hp() / 2)})
			event_feedback = "The spirit's rest mends the party."
			done = true
		"commune":
			var stat := String(SurvivalAbsorb.STAT_KEYS[_event_rng(2).randi_range(0, SurvivalAbsorb.STAT_KEYS.size() - 1)])
			var gains: Dictionary = (s.gains as Dictionary).duplicate()
			gains[stat] = int(gains.get(stat, 0)) + 2
			SurvivalState.patch({"gains": gains, "fallen_hp": maxi(1, int(s.fallen_hp) - 15)})
			event_feedback = "Cold communion: -15 HP, +2 %s." % String(SurvivalAbsorb.LABELS[StringName(stat)])
			done = true
		"secret":
			var price := _oracle_price()
			var owned: Array[StringName] = []
			for sk in s.get("skills", []):
				owned.append(StringName(sk))
			var pool := SurvivalAbsorb.available_skills({}, owned)
			if int(s.macca) < price:
				event_feedback = "NOT ENOUGH MACCA (need %dM)." % price
			elif pool.is_empty():
				event_feedback = "You already know every secret."
			else:
				var skill: StringName = pool[_event_rng(3).randi_range(0, pool.size() - 1)]
				SurvivalState.patch({"macca": int(s.macca) - price})
				SurvivalState.learn_skill(skill)
				var known := not (SurvivalState.data().get("unidentified", []) as Array).has(String(skill))
				event_feedback = "Learned %s." % (SkillBook.display_name(skill) if known else SurvivalData.hebrew_skill(skill))
				done = true
		"gamble":
			var rng := _event_rng(4)
			if rng.randf() < 0.5:
				var stat := String(SurvivalAbsorb.STAT_KEYS[rng.randi_range(0, SurvivalAbsorb.STAT_KEYS.size() - 1)])
				var gains: Dictionary = (s.gains as Dictionary).duplicate()
				gains[stat] = int(gains.get(stat, 0)) + 3
				SurvivalState.patch({"gains": gains})
				event_feedback = "Fortune smiles: +3 %s." % String(SurvivalAbsorb.LABELS[StringName(stat)])
			else:
				SurvivalState.patch({"fallen_hp": maxi(1, int(s.fallen_hp) - 30)})
				event_feedback = "Fortune bites: -30 HP."
			done = true
		"buy":
			var relic := _merchant_relic()
			var price := _merchant_price()
			if relic.is_empty():
				event_feedback = "Hee-ho... nothing left to sell."
				done = true
			elif int(s.macca) < price:
				event_feedback = "NOT ENOUGH MACCA (need %dM)." % price
			else:
				SurvivalState.patch({"macca": int(s.macca) - price})
				SurvivalState.grant_relic(relic)
				event_feedback = "Bought %s. Hee-ho!" % SurvivalRelics.name_of(relic)
				done = true
	if done:
		var list: Array = SurvivalState.data().get("events_done", [])
		if not list.has(String(active_event.id)):
			list.append(String(active_event.id))
		SurvivalState.patch({"events_done": list})
		for npc in npcs.duplicate():
			if String(npc.id) == String(active_event.id):
				npcs.erase(npc)
		event_open = false
		active_event = {}
		talking_npc = {}
		_up_needs_release = true
		refresh_front_picture()
		loot_toast = event_feedback
		_sync_party_from_state()
	_redraw()
	return id


# ------------------------------------------------------------ relíquias

func _owned_relics() -> Array[String]:
	var out: Array[String] = []
	for id in SurvivalState.data().get("relics", []):
		out.append(String(id))
	return out


func _open_relics() -> void:
	close_service()
	relic_open = true
	relic_index = 0
	_redraw()


func _close_relics() -> void:
	relic_open = false
	_redraw()


func _equip_relic(who: String) -> void:
	var owned := _owned_relics()
	if owned.is_empty():
		return
	var id := owned[clampi(relic_index, 0, owned.size() - 1)]
	SurvivalState.toggle_relic(who, id)
	_sync_party_from_state()


## D-070: escolha de 1 entre 3 relíquias do guardião (abre ao voltar ao mapa).
func move_relic_choice(delta: int) -> void:
	var offer: Array = SurvivalState.data().get("pending_relic_choice", [])
	if relic_choice_open and not offer.is_empty():
		relic_choice_index = posmod(relic_choice_index + delta, offer.size())
		_redraw()


func confirm_relic_choice() -> String:
	var offer: Array = SurvivalState.data().get("pending_relic_choice", [])
	if not relic_choice_open:
		return ""
	var picked := ""
	if not offer.is_empty():
		picked = String(offer[clampi(relic_choice_index, 0, offer.size() - 1)])
		SurvivalState.grant_relic(picked)
		loot_toast = "RELIC TAKEN: %s — equip it at RELICS" % SurvivalRelics.name_of(picked)
	SurvivalState.patch({"pending_relic_choice": []})
	relic_choice_open = false
	_check_cleared()
	_redraw()
	return picked


# ------------------------------------------------------------ overlays

func bold_font() -> Font:
	return ui_bold if ui_bold != null else ui_font


func ui_font_regular() -> Font:
	return ui_font


func _text(font: Font, text: String, x: float, y: float, px: int, color: Color,
		align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var dx := x
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		dx = x - w * 0.5
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		dx = x - w
	_overlay.draw_string(font, Vector2(dx, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)


func _panel(bounds: Rect2, border: Color) -> void:
	_overlay.draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0.02, 0.01, 0.03, 0.86))
	_overlay.draw_rect(bounds, Color(0.06, 0.03, 0.05, 0.98))
	_overlay.draw_rect(bounds, border, false, 1.5)


func _draw_overlay() -> void:
	if _overlay == null:
		return
	if cleared_open:
		_draw_cleared()
	elif relic_choice_open:
		_draw_relic_choice()
	elif relic_open:
		_draw_relics()
	elif shop_open:
		_draw_shop()


func _ally_line(label: String, list: Array) -> String:
	var names: Array[String] = []
	for id in list:
		names.append(SurvivalRelics.name_of(String(id)))
	return "%s %d/2: %s" % [label, list.size(), ", ".join(names) if not names.is_empty() else "-"]


func _covenant_line(list: Array) -> String:
	var parts: Array[String] = []
	for c in SurvivalRelics.covenants(list):
		parts.append("%s (%s)" % [String(c.name), String(c.info)])
	return "COVENANT: " + ", ".join(parts) if not parts.is_empty() else ""


func _draw_relics() -> void:
	var s := SurvivalState.data()
	var b := PANEL_RECT
	_panel(b, GOLD_INK)
	_text(bold_font(), "ANCIENT RELICS", b.get_center().x, b.position.y + 22, 15, GOLD_INK, HORIZONTAL_ALIGNMENT_CENTER)
	var f: Array = s.get("fallen_relics", [])
	var y: Array = s.get("yoch_relics", [])
	_text(bold_font(), _ally_line("FALLEN", f), b.position.x + 14, b.position.y + 48, 11, GREEN_INK)
	_text(ui_font, _covenant_line(f), b.position.x + 24, b.position.y + 63, 10, GOLD_INK)
	_text(bold_font(), _ally_line("YOCH", y), b.position.x + 14, b.position.y + 82, 11, BLUE_INK)
	_text(ui_font, _covenant_line(y), b.position.x + 24, b.position.y + 97, 10, GOLD_INK)
	_overlay.draw_line(Vector2(b.position.x + 10, b.position.y + 106), Vector2(b.end.x - 10, b.position.y + 106), Color(1, 1, 1, 0.25))
	var owned := _owned_relics()
	var rows := 12
	var first := clampi(relic_index - rows / 2, 0, maxi(0, owned.size() - rows))
	for i in range(first, mini(owned.size(), first + rows)):
		var row_y := b.position.y + 118 + (i - first) * 19
		var selected := i == relic_index
		var id := owned[i]
		if selected:
			_overlay.draw_rect(Rect2(b.position.x + 10, row_y - 2, b.size.x - 20, 18), Color(1, 1, 1, 0.16))
		var who := ""
		if f.has(id):
			who = "[F]"
		elif y.has(id):
			who = "[Y]"
		var ink := Color.WHITE if selected else INK
		_text(ui_font, ("> " if selected else "  ") + SurvivalRelics.name_of(id), b.position.x + 16, row_y + 11, 11, ink)
		_text(ui_font, String(SurvivalRelics.relic(id).info), b.position.x + 220, row_y + 11, 10,
				GOLD_INK if SurvivalRelics.relic(id).has("perk") else ink)
		_text(bold_font(), who, b.end.x - 16, row_y + 11, 10, GREEN_INK if who == "[F]" else BLUE_INK, HORIZONTAL_ALIGNMENT_RIGHT)
	if owned.size() > rows:
		_text(ui_font, "%d/%d" % [relic_index + 1, owned.size()], b.end.x - 16, b.end.y - 34, 10, INK, HORIZONTAL_ALIGNMENT_RIGHT)
	_text(bold_font(), "Up/Down: select   Z: Fallen   X: Yoch   Esc: close", b.get_center().x, b.end.y - 14, 10, INK, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_shop() -> void:
	var s := SurvivalState.data()
	var b := Rect2(158, 96, 500, 300)
	_panel(b, GOLD_INK)
	_text(bold_font(), "SANCTUARY SHOP — STRATUM %d" % SurvivalState.stratum(), b.get_center().x, b.position.y + 22, 14, GOLD_INK, HORIZONTAL_ALIGNMENT_CENTER)
	_text(bold_font(), "MACCA %dM" % int(s.get("macca", 0)), b.end.x - 14, b.position.y + 44, 11, GOLD_INK, HORIZONTAL_ALIGNMENT_RIGHT)
	var rows := shop_rows()
	for i in rows.size():
		var row: Dictionary = rows[i]
		var row_y := b.position.y + 62 + i * 36
		var selected := i == shop_index
		if selected:
			_overlay.draw_rect(Rect2(b.position.x + 10, row_y - 4, b.size.x - 20, 34), Color(1, 1, 1, 0.16))
		var ink := Color.WHITE if selected else INK
		var name := String(row.label) + ("  (RELIC)" if String(row.kind) == "relic" else "  x%d" % int(row.owned))
		_text(bold_font(), ("> " if selected else "  ") + name, b.position.x + 16, row_y + 10, 12,
				GOLD_INK if String(row.kind) == "relic" else ink)
		_text(bold_font(), "%dM" % int(row.price), b.end.x - 16, row_y + 10, 12,
				GREEN_INK if int(s.get("macca", 0)) >= int(row.price) else ENEMY_INK, HORIZONTAL_ALIGNMENT_RIGHT)
		_text(ui_font, String(row.info), b.position.x + 30, row_y + 25, 10, INK)
	_text(ui_font, shop_feedback, b.get_center().x, b.end.y - 14, 11, INK, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_relic_choice() -> void:
	var offer: Array = SurvivalState.data().get("pending_relic_choice", [])
	var b := Rect2(108, 150, 600, 190)
	_panel(b, GOLD_INK)
	_text(bold_font(), "WARDEN'S HOARD — take 1 of %d" % offer.size(), b.get_center().x, b.position.y + 24, 15, GOLD_INK, HORIZONTAL_ALIGNMENT_CENTER)
	var count := maxi(1, offer.size())
	var cell_w := (b.size.x - 20.0 - 8.0 * float(count - 1)) / float(count)
	for i in offer.size():
		var r := Rect2(b.position.x + 10 + i * (cell_w + 8.0), b.position.y + 44, cell_w, 104)
		var active := i == relic_choice_index
		var id := String(offer[i])
		_overlay.draw_rect(r, Color(1, 1, 1, 0.16) if active else Color(1, 1, 1, 0.04))
		_overlay.draw_rect(r, Color.WHITE if active else Color(1, 1, 1, 0.32), false, 1.5 if active else 1.0)
		_text(ui_font, String(SurvivalRelics.relic(id).hebrew), r.get_center().x, r.position.y + 24, 14, GOLD_INK, HORIZONTAL_ALIGNMENT_CENTER)
		_text(bold_font(), ("> " if active else "") + SurvivalRelics.name_of(id), r.get_center().x, r.position.y + 52, 12, Color.WHITE if active else INK, HORIZONTAL_ALIGNMENT_CENTER)
		_text(ui_font, String(SurvivalRelics.relic(id).info), r.get_center().x, r.position.y + 76, 10, INK, HORIZONTAL_ALIGNMENT_CENTER)
	if offer.is_empty():
		_text(ui_font, "Every relic is already yours.", b.get_center().x, b.position.y + 96, 12, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_text(bold_font(), "Left/Right: select   Z: take", b.get_center().x, b.end.y - 14, 10, INK, HORIZONTAL_ALIGNMENT_CENTER)


func _reload_world() -> void:
	# No jogo current_scene é o próprio SurvivalWorld; testes instanciam a cena
	# à mão, então não há current_scene e o reload faria nada/geraria erro.
	if get_tree().current_scene != null:
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file(SurvivalData.WORLD_SCENE)


## D-066: a run termina vencida ao derrotar o guardião do estrato 5.
func _check_cleared() -> void:
	if cleared_open or relic_choice_open or _overlay == null:
		return
	if not SurvivalState.run_cleared():
		return
	var s := SurvivalState.data()
	if not bool(s.get("finished", false)):
		SurvivalMeta.finish_run((s.get("defeated", []) as Array).size(), int(s.get("macca", 0)),
				int(s.get("continues", 0)), s)
		SurvivalState.patch({"finished": true})
		_meta_cache = SurvivalMeta.data()
	cleared_open = true
	_redraw()


func _draw_cleared() -> void:
	var s := SurvivalState.data()
	var box := Rect2(188, 130, 440, 236)
	_panel(box, GOLD_INK)
	var cx := box.get_center().x
	_text(bold_font(), "SURVIVAL CLEARED", cx, box.position.y + 38, 22, GOLD_INK, HORIZONTAL_ALIGNMENT_CENTER)
	_text(ui_font, "All %d wardens fell. %d/%d demons defeated." % [SurvivalStrata.COUNT,
			(s.get("defeated", []) as Array).size(), SurvivalData.DEMONS.size()], cx, box.position.y + 76, 13, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_text(ui_font, "MACCA %dM   |   CONTINUES %d/%d   |   OMEN %d" % [
			int(s.get("macca", 0)), int(s.get("continues", 0)), SurvivalState.max_continues(), SurvivalState.omen()],
			cx, box.position.y + 104, 12, GOLD_INK, HORIZONTAL_ALIGNMENT_CENTER)
	var md := meta()
	_text(ui_font, "SCORE %d   BEST %d   CODEX %d/%d" % [int(md.last_score), int(md.best),
			(md.codex as Array).size(), SurvivalData.DEMONS.size()], cx, box.position.y + 130, 11, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_text(ui_font, "OMEN UNLOCKED: %d/%d" % [int(md.omen_unlocked), SurvivalMeta.MAX_OMEN],
			cx, box.position.y + 152, 11, BLUE_INK, HORIZONTAL_ALIGNMENT_CENTER)
	_text(bold_font(), "Z: NEW RUN     X: TITLE", cx, box.position.y + 200, 13, GREEN_INK, HORIZONTAL_ALIGNMENT_CENTER)


# ------------------------------------------------------------ entrada

func _key(event: InputEvent) -> InputEventKey:
	if not (event is InputEventKey) or event.echo or not event.pressed:
		return null
	return event as InputEventKey


func _unhandled_input(event: InputEvent) -> void:
	if cleared_open:
		var k := _key(event)
		if k == null:
			return
		if k.keycode in [KEY_Z, KEY_ENTER, KEY_KP_ENTER]:
			_start_run(-1)
		elif k.keycode in [KEY_X, KEY_ESCAPE]:
			_go_title()
		get_viewport().set_input_as_handled()
		return
	if relic_choice_open:
		var k := _key(event)
		if k == null:
			return
		match k.keycode:
			KEY_LEFT, KEY_UP: move_relic_choice(-1)
			KEY_RIGHT, KEY_DOWN: move_relic_choice(1)
			KEY_Z, KEY_ENTER, KEY_KP_ENTER: confirm_relic_choice()
		get_viewport().set_input_as_handled()
		return
	if relic_open:
		var k := _key(event)
		if k == null:
			return
		match k.keycode:
			KEY_LEFT, KEY_UP:
				relic_index = posmod(relic_index - 1, maxi(1, _owned_relics().size()))
				_redraw()
			KEY_RIGHT, KEY_DOWN:
				relic_index = posmod(relic_index + 1, maxi(1, _owned_relics().size()))
				_redraw()
			KEY_Z, KEY_ENTER, KEY_KP_ENTER:
				_equip_relic("fallen")
			KEY_X:
				_equip_relic("yoch")
			KEY_ESCAPE:
				_close_relics()
		get_viewport().set_input_as_handled()
		return
	if shop_open:
		var k := _key(event)
		if k == null:
			return
		match k.keycode:
			KEY_UP, KEY_LEFT: move_shop_cursor(-1)
			KEY_DOWN, KEY_RIGHT: move_shop_cursor(1)
			KEY_Z, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE: confirm_shop()
			KEY_X, KEY_ESCAPE: close_shop()
		get_viewport().set_input_as_handled()
		return
	if event_open:
		var k := _key(event)
		if k == null:
			return
		match k.keycode:
			KEY_LEFT, KEY_UP: move_event_cursor(-1)
			KEY_RIGHT, KEY_DOWN: move_event_cursor(1)
			KEY_Z, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE: confirm_event()
			KEY_X, KEY_ESCAPE: close_event()
		get_viewport().set_input_as_handled()
		return
	if service_open:
		var k := _key(event)
		if k == null:
			return
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
					_redraw()
				else:
					close_service()
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)


# ------------------------------------------------------------ HUD

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


func _draw_choice_bar(title: String, right_text: String, labels: Array[String], index: int, feedback: String) -> void:
	var bar := SERVICE_BAR_RECT
	# Fundo opaco: o HUD base desenha o painel antes desta barra e o texto vazaria.
	hud.draw_rect(bar, Color(0.03, 0.03, 0.04, 1.0))
	hud.draw_rect(Rect2(bar.position + Vector2(0.5, 0.5), bar.size - Vector2.ONE), Color(1, 1, 1, 0.65), false, 1)
	_str(title, bar.position.x + 12, bar.position.y + 20, Color.WHITE, 13, true)
	_str(right_text, bar.end.x - 12, bar.position.y + 20, GOLD_INK, 12, true, HORIZONTAL_ALIGNMENT_RIGHT)
	hud.draw_line(Vector2(bar.position.x + 10, bar.position.y + 29), Vector2(bar.end.x - 10, bar.position.y + 29), Color(1, 1, 1, 0.28))
	var opt_count := maxi(1, labels.size())
	var margin_x := 12.0
	var gap := 8.0
	var cell_w := (bar.size.x - margin_x * 2.0 - gap * float(opt_count - 1)) / float(opt_count)
	var opt_y := bar.position.y + 39.0
	var opt_h := 36.0
	for i in labels.size():
		var rx := bar.position.x + margin_x + float(i) * (cell_w + gap)
		var cell_rect := Rect2(rx, opt_y, cell_w, opt_h)
		var selected := (i == index)
		hud.draw_rect(cell_rect, Color(1, 1, 1, 0.16) if selected else Color(1, 1, 1, 0.04))
		hud.draw_rect(cell_rect, Color.WHITE if selected else Color(1, 1, 1, 0.32), false, 1.5 if selected else 1.0)
		var label := ("> " if selected else "") + labels[i]
		var px := 12
		var font := ui_bold if selected and ui_bold != null else ui_font
		while px > 9 and font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > cell_w - 6.0:
			px -= 1
		_str(label, cell_rect.get_center().x, opt_y + 23.0, Color.WHITE if selected else INK, px, selected, HORIZONTAL_ALIGNMENT_CENTER)
	hud.draw_line(Vector2(bar.position.x + 10, bar.position.y + 84), Vector2(bar.end.x - 10, bar.position.y + 84), Color(1, 1, 1, 0.2))
	_str(feedback, bar.position.x + 12, bar.position.y + 103, INK, 11)


func _draw_extra_hud() -> void:
	var s := SurvivalState.data()
	var macca := int(s.get("macca", 0))
	if service_open:
		var labels: Array[String] = []
		for o in service_options():
			labels.append(String(o.label))
		_draw_choice_bar("SANCTUARY KEEPER  |  SEED %d" % int(s.get("seed", 0)),
				"MACCA: %dM   ITEMS x%d" % [macca, SurvivalState.total_items()], labels, service_index, service_feedback)
		return
	if event_open and not active_event.is_empty():
		var labels: Array[String] = []
		for o in event_options():
			labels.append(String(o.label))
		_draw_choice_bar(String(active_event.name), "HP %d/%d   MACCA %dM" % [int(s.get("fallen_hp", 0)),
				SurvivalState.fallen_max_hp(), macca], labels, event_index, event_feedback)
		return
	var npc := npc_near()
	if not npc.is_empty() and String(npc.get("role", "")) == "sanctuary":
		_str("Z: HEAL & SHOP", 420, LOCATION_LINE_Y + 15.5, GREEN_INK, 12, true)
	elif not npc.is_empty() and String(npc.get("role", "")) == "event":
		_str("Z: " + String(npc.name), 420, LOCATION_LINE_Y + 15.5, GOLD_INK, 12, true)
	elif not loot_toast.is_empty():
		_str(loot_toast, 420, LOCATION_LINE_Y + 15.5, GOLD_INK, 11, true)
	var r := SURVIVAL_PANEL_RECT
	hud.draw_line(Vector2(r.position.x, r.position.y + 0.5), Vector2(r.end.x, r.position.y + 0.5), Color(1, 1, 1, 0.35))
	var x := r.position.x + 8
	var right := r.end.x - 8
	var stratum_txt := "STRATUM %d/%d" % [SurvivalState.stratum(), SurvivalStrata.COUNT]
	if SurvivalState.omen() > 0:
		stratum_txt += "  OMEN %d" % SurvivalState.omen()
	_str(stratum_txt, x, r.position.y + 18, Color.WHITE, 13, true)
	var warden_txt := "WARDEN DOWN — DESCEND" if SurvivalState.warden_down() else "WARDEN AWAITS"
	if SurvivalState.run_cleared():
		warden_txt = "ALL WARDENS DOWN!"
	_str(warden_txt, right, r.position.y + 18, GREEN_INK if SurvivalState.warden_down() else ENEMY_INK, 12, true, HORIZONTAL_ALIGNMENT_RIGHT)
	_str("MACCA %dM" % macca, x, r.position.y + 40, GOLD_INK, 12, true)
	_str("CONTINUES %d/%d" % [int(s.get("continues", 0)), SurvivalState.max_continues()], right, r.position.y + 40, INK, 11, true, HORIZONTAL_ALIGNMENT_RIGHT)
	_str("ITEMS x%d   RELICS %d" % [SurvivalState.total_items(), (s.get("relics", []) as Array).size()], x, r.position.y + 61, INK, 11)
	_str("NEXT: %s" % nearest_demon_hint(), right, r.position.y + 61, ENEMY_INK, 11, true, HORIZONTAL_ALIGNMENT_RIGHT)


## D-066: o guardião visto ganha uma moldura dourada no automapa (o ponto vermelho
## de inimigo continua igual por baixo), para o jogador saber onde está o chefe.
func _draw_automap() -> void:
	super._draw_automap()
	if not enemies_enabled or enemies == null:
		return
	var inner := automap.size
	var center := Vector2(floor(inner.x / 2.0) - CELL_PX / 2.0, floor(inner.y / 2.0) - CELL_PX / 2.0)
	for enemy in enemies.entries:
		if not bool(enemy.get("warden", false)) or not enemies.seen.has(enemy.id) or enemy.cell == cell:
			continue
		var p := center + Vector2((enemy.cell - cell) * CELL_PX)
		automap.draw_rect(Rect2(p + Vector2(1.5, 1.5), Vector2(13, 13)), GOLD_INK, false, 1.0)


# ------------------------------------------------------------ demônios

func _after_player_step() -> void:
	loot_toast = ""
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


## Demônios próximos (<= CHASE_RADIUS) perseguem o jogador, mas nunca invadem o santuário
## seguro. D-066: o GUARDIÃO não persegue — espera no ponto mais fundo do estrato.
func _step_nearby_demons() -> Dictionary:
	var safe := SurvivalStrata.sanctuary_zone(SurvivalState.stratum())
	for enemy in enemies.entries:
		var delta: Vector2i = cell - enemy.cell
		if delta == Vector2i.ZERO:
			return enemy
		if bool(enemy.get("warden", false)):
			continue
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
			if not _can_step(enemy.cell, target) or safe.has_point(target):
				continue
			if target == cell:
				enemy.cell = target
				return enemy
			if not enemies.at(target).is_empty() or not npc_at(target).is_empty():
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
		var c := Vector2i(int(pos[0]), int(pos[1]))
		if SurvivalStrata.is_floor(grid, c):
			cell = c
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
	for item in saved.get("visited", []):
		var c: Array = item
		if c.size() == 2:
			visited[Vector2i(int(c[0]), int(c[1]))] = true
	for id in saved.get("seen", []):
		enemies.seen[String(id)] = true
