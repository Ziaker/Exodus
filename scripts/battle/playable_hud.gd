extends "res://prototypes/combat-ui/preview-xp.gd"
## Playable battle HUD following exodus_feedback_lab.html (544 x 416, theme "A · XP"
## readability pass): drawn red/brown backdrop, black enemy silhouettes generated from
## the local SMT battlers, line-only windows. All displayed resources come from BattleUnit.
## Creator decisions (2026-11-21): no HTML pop-up texts (the existing SMT effects stay),
## the command title is hidden when five commands are listed, the TARGET01 "SEARCH" cue
## is replaced by its four green diagonal brackets only (they also replace the white HTML
## corners), and an announcing enemy shows a red "!" (#bb3d48) to the left of its art.

## Creator 2026-11-24 (fixes D-055): the battle keeps its 544 x 416 layout and the game
## shows it 1.5x on the 816 x 624 screen (BattleController sets the window's content
## scale), so every panel, text and sprite is 1.5x with sharp text.
## Creator 2026-11-24, HUD option 13 (prototypes/combat-hud-html, "Janelas baixas"):
## the round, both SP names and the SP bar share one thin line at the top; the scene runs
## to the bottom of the screen; the log, each hero and the commands sit in their own
## windows (thin light border, dark translucent fill). Values below are the prototype's
## 816 x 624 pixels divided by 1.5.
const SCREEN := Vector2(544, 416)
const STAGE_SCALE := 1.0
const STAGE_SHIFT := -32.0 / 1.5
## Battlefield (effects clip here): from the top down to the log window.
const STAGE_RECT := Rect2(0, 0, 544, 300.0)
## Option 13 moved the enemies 36 screen px (24 here) down.
const FIELD_RECT := Rect2(7, 82 + STAGE_SHIFT + 24, 530, 210)
## D-110 (criador 2026-11-26): 3 linhas, alinhadas no topo e à esquerda (revoga as 2
## linhas centradas da D-056); a primeira linha começa no alto da janela.
const LOG_LINES := 3
const LOG_STEP := 14.0
const LOG_PX := 11
## Faixa fixa de estado dentro da janela do log: de quem é a vez, o que está
## acontecendo e o que fazer. Nunca some após 0,75 s como o announce antigo.
const PHASE_STRIP_HEIGHT := 16.0
const LOG_FIRST_BASELINE := 316.0
## The strip is 88 screen px tall: top at 450, bottom at 538 (8 px above the panels).
const BATTLE_LOG_RECT := Rect2(16.0 / 3.0, 300.0, 1600.0 / 3.0, 176.0 / 3.0)
## Old log lines at 80% (the prototype's .old lines).
const LOG_OLD_ALPHA := 0.8
const WINDOW_FILL := Color(10 / 255.0, 4 / 255.0, 7 / 255.0, 0.72)
const CARD_FILL := Color(10 / 255.0, 4 / 255.0, 7 / 255.0, 0.78)
const WINDOW_BORDER := Color(240 / 255.0, 225 / 255.0, 228 / 255.0, 0.55)
const LOG_BACKGROUND := WINDOW_FILL
## The scene is not covered by a footer any more (the windows are translucent).
const SCENE_BOTTOM := 416.0
const STATUS_RECTS := [Rect2(16.0 / 3.0, 364, 586.0 / 3.0, 44), Rect2(206, 364, 586.0 / 3.0, 44)]
## D-111 (creator 2026-11-26, Survival): with 3 heroes the 3 windows share the width of the 2
## ("3 estreitos").
const NARROW_PANEL_LIMIT := 160.0
## Creator 2026-11-26: the choice menu is one vertical column right above the log
## (left edge on the log's); COMMAND_RECT is its bottom anchor (height 0) and the
## window grows upwards from it, whatever the number of rows.
const COMMAND_RECT := Rect2(16.0 / 3.0, 300.0 - 3.0, 132, 0)
const COMMAND_COLUMNS := 1
const COMMAND_NARROW_WIDTH := 64.0
const COMMAND_ROW := 11.0
const COMMAND_PX := 9
## Cursor "›" at the cell's left edge, the label right after it (ABSORB bold fits).
const MENU_TEXT_X := 4.5
const SP_TRACK := Rect2(151, 6, 242, 7)
const HEADER_BASELINE := 13.0
const HP_FILL := Color("d9584f")
const EN_FILL := Color("5f8fd6")
## Creator 2026-11-24: only coloured numbers in the hero windows (no HP/EN/PP bars).
const HP_NUMBER := Color("ff9a92")
const EN_NUMBER := Color("9fc5ff")
## Creator 2026-11-24: clear space between the SP value and ACT in the hero window.
const SP_ACT_GAP := 12.0
const COLUMN_SIZE := Vector2(220, 206)
const SPRITE_BOX := Vector2(156, 166)
const SVG_SCALE_Y := 298.0 / 251.0

const TEXT := Color("f7f3ed")
const GREEN_TEXT := Color("81e6a8")
const FLOATER_EYE_GREEN := Color("36ce72")
## D-132 (criador 2026-11-26): the other hero's card at 50% while one hero chooses; the
## active hero's border pulses in GREEN_TEXT (the turn queue's green), 1.5 s there and back.
const INACTIVE_CARD_DIM := 0.5
const ACTIVE_PULSE_PERIOD := 1.5
const RED_TEXT := Color("ff9a92")
const OWN_FILL := Color("36aa6d")
const FOE_FILL := Color("bb3d48")
const UP_MARK := Color("b5efc4")
const ALERT_RED := Color("bb3d48")
## Creator 2026-11-21: SP arrows drawn as shapes, green #36aa6d up / red #bb3d48 down,
## then reduced 25% (40 -> 30 px tall, head 30 -> 22.5 px); the alert "!" stays 40 px.
const SP_UP := Color("36aa6d")
const SP_DOWN := Color("bb3d48")
const SIGN_HEIGHT := 40.0
## Setas de comparação de SP 10 px menores em altura e largura.
const ARROW_HEIGHT := 20.0
const ARROW_HEAD := Vector2(12.5, 6)
const ARROW_SHAFT := 7.5
## Creator 2026-11-21: the arrow sits 4 px right of the art, top-aligned with it, and is
## labelled "SP" (bold 12 px, arrow colour) to its right.
const SIGN_GAP := 4.0
## Tahoma bold cap height is ~0.727 em, so this size draws a 40 px tall "!".
const ALERT_PX := 55
const TARGET_SHEET := "res://assets/graphics/animations/TARGET01.png"
## TARGET01 bracket cells (192 px tiles): 7 top-left, 8 top-right, 5 bottom-left, 6 bottom-right.
## Only the stroke band (y 73..119) is drawn; additive blend, opacity 200/255 as in the source.
const BRACKET_TILES := [7, 8, 5, 6]
const BRACKET_BAND := Vector2(73, 46)
## Creator 2026-11-21: smaller brackets on status panels. 7 px tall keeps each stroke
## inside the panel's 7 px padding, clear of the name, ACT, SP and pip text.
const PANEL_BRACKET_HEIGHT := 7.0
## Drawn at rest (the source converge frames spilled over the log on small panels).
const DOWN_MARK := Color("f2a7a5")

## TESTE pedido pelo criador: trilhas de timing, ponteiros e disputas de ataque
## passam a ocorrer dentro da faixa do battlelog em vez de dentro do cartão.
## Desligada por default: o layout normal continua exatamente como antes.
var timing_at_log := false

var battle: Control
var players: Array[BattleUnit] = []
var opponents: Array[BattleUnit] = []
## D-052: opponents already broken into letters by absorb_vfx (not drawn any more).
var broken_units: Array[BattleUnit] = []
var command_options: Array[String] = []
var command_index := 0
## D-046: linhas do plano (comandos + EXEC + UNDO) no mesmo menu desenhado.
var plan_options: Array[String] = []
var plan_index := 0
var react_index := 0
## Kept for the controller and diagnostics only: D-057 draws neither `message` nor
## `feedback` in the log (the log shows event lines, see push_event).
var feedback := ""
var ui_font: SystemFont
var ui_bold: SystemFont
## Solid white silhouettes (alpha mask, enclosed holes filled) cut from the SMT battlers.
var silhouettes: Array[ImageTexture] = []
var target_sheet: Texture2D
var marks: Node2D
var role_layer: Node2D
## Role tags gathered by _draw (role, x, top, centered) and drawn by role_layer on top.
var _role_tags: Array[Dictionary] = []
var alert_unit: BattleUnit

# Presentation-only animation state (HTML keyframes).
var time := 0.0
## Background prototypes (prototypes/battle-bg) turn this off and paint the stage
## from a node behind the HUD. The game itself always draws the lab backdrop.
var stage_backdrop := true
## Background prototypes: enemies drawn farther away in perspective. 1.0 = as
## designed; below 1.0 the art and its shadow shrink towards enemy_horizon.
var enemy_depth := 1.0
var enemy_horizon := 214.0
var announcement_text := ""
var announcement_age := 99.0
var _log_shown := ""
var _log_age := 99.0
## D-057 (creator 2026-11-25): the Battle Log holds only event sentences, one per line
## ({"text", "ink"}), pushed by the controller; no instructions and no internal numbers.
## Menu explanations (skill/pray/EN/absorb/item) stay transient: they show as the newest
## line only while their menu is open.
var events: Array[Dictionary] = []
## D-110 (criador 2026-11-26): sem paginação com Z. O log rola sozinho: cada frase nova
## entra embaixo e as antigas sobem e saem na hora; a batalha nunca espera pelo log.
var events_read := 0
const EVENT_CAP := 64
const NO_INK := Color(0, 0, 0, 0)
const TRANSIENT_LOG_MODES := ["skill", "pray", "en_extra", "absorb", "item"]
## D-057 / D-135 / D-136: enemy roles use plain bold text (ROLE_ARROW_INKS); hero roles
## live inside the hero card (options 2 + 3: left inner strip + subtle horizontal tint +
## right-aligned plain text on the HP/EN row when width allows).
const ROLE_PX := 9
const HERO_ROLE_STRIP_WIDTH := 2.0
const HERO_ROLE_TINT_SHARE := 0.38
const HERO_ROLE_TINT_ALPHA := 0.14
const HERO_ROLE_PX := 8
## D-058 turn strip under the top line (layout chosen by the agent, pending the creator's
## visual judgment).
const TURN_STRIP_TOP := 38.0  # under the announcement line (baseline 30, 12 px)
## D-058: half the distance between the two counter rails inside the log.
const LOG_RAIL_PAIR_OFFSET := 9.0
const TURN_STRIP_HEIGHT := 13.0
const TURN_STRIP_PX := 9
const TURN_STRIP_GAP := 10.0
var _menu_height := 77.0
var _menu_from := 77.0
var _menu_to := 77.0
var _menu_age := 99.0
var _press_kind := ""
var _press_row := -1
var _press_age := 99.0
var _corner_index := -2
var _corner_age := 99.0
var _sp_anim := {"from": 0.5, "to": 0.5, "age": 99.0}
var _unit_seen: Dictionary = {}
## D-049 perfect interruption (creator 2026-11-22): the scenery flashes white for 3
## frames (enemy silhouettes stay drawn over it) and the interrupted sprite/card
## shakes horizontally 4 px, alternating every ~2 frames (30 Hz), for 0.4 s.
const IMPACT_SECONDS := 3.0 / 60.0
const SHAKE_SECONDS := 0.4
const SHAKE_PX := 4.0
const SHAKE_HZ := 30.0
var impact_left := 0.0
## Per-unit shake ages (seconds) so several units can shake at once. A unit also shakes
## whenever its HP drops (damage from any source), with the same 4 px / 30 Hz / 0.4 s.
var _shakes: Dictionary = {}
var _hp_last: Dictionary = {}


func _ready() -> void:
	super._ready()
	# O preview isolado troca o título da janela; na batalha real isso fazia o
	# jogo aparecer como "XP HUD interactive preview" (visto na captura do autor).
	DisplayServer.window_set_title(String(ProjectSettings.get_setting("application/config/name", "Exodus")))
	ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray(["Tahoma", "Arial", "sans-serif"])
	ui_bold = SystemFont.new()
	ui_bold.font_names = ui_font.font_names
	ui_bold.font_weight = 700
	# D-110: Tahoma has no ✖; without this the system falls back to the colour emoji
	# font and the log's ✖ came out purple. A monochrome symbol font draws it in the ink.
	var symbols := SystemFont.new()
	symbols.font_names = PackedStringArray(["Segoe UI Symbol", "DejaVu Sans", "Noto Sans Symbols 2"])
	ui_font.fallbacks = [symbols]
	ui_bold.fallbacks = [symbols]
	target_sheet = load(TARGET_SHEET) as Texture2D
	marks = Node2D.new()
	marks.name = "TargetMarks"
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	marks.material = additive
	marks.draw.connect(_draw_marks)
	add_child(marks)
	# D-057: the role tags go above the green TARGET01 brackets, whose line ran over the
	# tag text on a hero window's top border (creator 2026-11-25).
	role_layer = Node2D.new()
	role_layer.name = "RoleTags"
	role_layer.draw.connect(_draw_role_tags)
	add_child(role_layer)
	for i in battler_textures.size():
		silhouettes.append(ImageTexture.create_from_image(make_silhouette(battler_textures[i].get_image().get_region(Rect2i(battler_regions[i])))))


## Replaces the battler art and silhouettes for dynamic encounters (e.g. Survival Mode).
## Handles both alpha PNGs and opaque VX battlers (solid background color around the demon).
func set_opponent_sprites(paths: Array[String]) -> void:
	if paths.is_empty():
		return
	battler_textures.clear()
	battler_regions.clear()
	silhouettes.clear()
	for path in paths:
		var texture := load(path) as Texture2D
		if texture == null:
			continue
		var image := texture.get_image()
		if image.get_format() != Image.FORMAT_RGBA8:
			image.convert(Image.FORMAT_RGBA8)
		var w := image.get_width()
		var h := image.get_height()
		# Figuras já recortadas (PNG com alfa, como os humanos) não têm moldura de VX: cortar 2 px da
		# borda e as linhas largas da base comia os pés (criador 2026-11-26).
		var framed := image.get_pixel(0, 0).a > 0.15 or image.get_pixel(w - 1, h - 1).a > 0.15
		var interior: Image = image.get_region(Rect2i(2, 2, maxi(1, w - 4), maxi(1, h - 4))) if (framed and w > 8 and h > 8) else image.duplicate() as Image
		_strip_opaque_bg(interior)
		var used: Rect2i = interior.get_used_rect()
		if used.size.x <= 0 or used.size.y <= 0:
			used = Rect2i(0, 0, interior.get_width(), interior.get_height())
		var cropped: Image = interior.get_region(used)
		var sil: Image = make_silhouette(cropped)
		# VX battlers trazem uma moldura fina na borda: sem removê-la o crop
		# inclui dezenas de linhas vazias abaixo do demônio e a sombra descola.
		if framed:
			strip_frame_lines(sil)
		var visible := alpha_used_rect(sil)
		if visible.size.x > 0 and visible.size.y > 0:
			cropped = cropped.get_region(visible)
			sil = sil.get_region(visible)
		battler_textures.append(ImageTexture.create_from_image(cropped))
		battler_regions.append(Rect2(Vector2.ZERO, Vector2(cropped.get_size())))
		silhouettes.append(ImageTexture.create_from_image(sil))
	if not battler_regions.is_empty():
		# enemy_sprite_rect() já aplica enemy_depth: usá-la aqui faria a linha de
		# pé subir e a sombra ficar descolada. A linha é o piso da caixa (depth 1).
		var column := enemy_column(0)
		var box := Rect2(column.position + Vector2(maxf(0.0, (column.size.x - SPRITE_BOX.x) * 0.5), 0), SPRITE_BOX)
		enemy_horizon = box.end.y
	queue_redraw()


static func strip_frame_lines(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	if w <= 0 or h <= 0:
		return
	for y in range(mini(4, h)):
		if _opaque_row_share(img, y) > 0.8:
			_clear_row(img, y)
	for y in range(maxi(0, h - 5), h):
		# A moldura do VX é uma linha horizontal larga; corta a partir de 40%.
		if _opaque_row_share(img, y) > 0.4:
			_clear_row(img, y)


static func _opaque_row_share(img: Image, y: int) -> float:
	var solid := 0
	for x in img.get_width():
		if img.get_pixel(x, y).a > 0.5:
			solid += 1
	return float(solid) / float(maxi(1, img.get_width()))


static func _clear_row(img: Image, y: int) -> void:
	for x in img.get_width():
		img.set_pixel(x, y, Color(1, 1, 1, 0))


static func alpha_used_rect(img: Image) -> Rect2i:
	var min_x := img.get_width()
	var min_y := img.get_height()
	var max_x := -1
	var max_y := -1
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.01:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < 0:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


static func _strip_opaque_bg(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	if w <= 1 or h <= 1:
		return
	var corners := [img.get_pixel(0, 0).a, img.get_pixel(w - 1, 0).a,
		img.get_pixel(0, h - 1).a, img.get_pixel(w - 1, h - 1).a]
	var transparent_corners := 0
	for a in corners:
		if a < 0.15:
			transparent_corners += 1
	if transparent_corners >= 3:
		return
	var bg := img.get_pixel(0, 0)
	var tol := 0.06
	var visited := PackedByteArray()
	visited.resize(w * h)
	var stack: Array[Vector2i] = []
	for x in w:
		stack.append(Vector2i(x, 0))
		stack.append(Vector2i(x, h - 1))
	for y in h:
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(w - 1, y))
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h:
			continue
		var idx := p.y * w + p.x
		if visited[idx] == 1:
			continue
		var c := img.get_pixel(p.x, p.y)
		if c.a >= 0.15 and (absf(c.r - bg.r) > tol or absf(c.g - bg.g) > tol or absf(c.b - bg.b) > tol):
			continue
		visited[idx] = 1
		img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
		stack.append(Vector2i(p.x + 1, p.y))
		stack.append(Vector2i(p.x - 1, p.y))
		stack.append(Vector2i(p.x, p.y + 1))
		stack.append(Vector2i(p.x, p.y - 1))


## HTML silhouettes are solid black shapes: every opaque pixel becomes the mask and
## transparent pixels not reachable from the image border (dither holes) are filled.
static func make_silhouette(source: Image) -> Image:
	var w := source.get_width()
	var h := source.get_height()
	var outside := PackedByteArray()
	outside.resize(w * h)
	var stack: Array[Vector2i] = []
	for x in w:
		stack.append(Vector2i(x, 0)); stack.append(Vector2i(x, h - 1))
	for y in h:
		stack.append(Vector2i(0, y)); stack.append(Vector2i(w - 1, y))
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h: continue
		var i := p.y * w + p.x
		if outside[i] == 1 or source.get_pixel(p.x, p.y).a > 0.0: continue
		outside[i] = 1
		stack.append(Vector2i(p.x + 1, p.y)); stack.append(Vector2i(p.x - 1, p.y))
		stack.append(Vector2i(p.x, p.y + 1)); stack.append(Vector2i(p.x, p.y - 1))
	var mask := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			mask.set_pixel(x, y, Color(1, 1, 1, 0) if outside[y * w + x] == 1 else Color.WHITE)
	return mask


func _process(delta: float) -> void:
	time += delta
	announcement_age += delta
	_log_age += delta
	_menu_age += delta
	_press_age += delta
	_corner_age += delta
	_sp_anim.age += delta
	track_sp()
	impact_left = maxf(0.0, impact_left - delta)
	for sid in _shakes.keys():
		_shakes[sid] += delta
		if _shakes[sid] >= SHAKE_SECONDS: _shakes.erase(sid)
	_track_hp_shake()
	for key in _unit_seen:
		_unit_seen[key].sp_age += delta
		_unit_seen[key].acts_age += delta
	queue_redraw()
	if marks != null: marks.queue_redraw()


# ---------------------------------------------------------------- public hooks

## Enemy attack announcement: field text plus the red "!" beside the attacker.
func announce_attack(text: String, attacker: BattleUnit) -> void:
	announce(text)
	alert_unit = attacker


func alert_visible() -> bool:
	return alert_unit != null and announcement_age < 0.75


## Rects marked with the green TARGET01 brackets: the enemy the player is choosing,
## the ally being chosen for an item, and the player the enemy has chosen.
func mark_targets() -> Dictionary:
	var result := {}
	var sel := _selected_enemy()
	if sel >= 0:
		result["enemy:%d" % sel] = enemy_mark_rect(sel)
	if mode == "target" and battle.target_side == "player" and target >= 0 and target < players.size():
		result["player:%d" % target] = status_rect(target)
	var chosen: BattleUnit = null
	if battle.in_reaction: chosen = battle.reaction_defender
	elif mode in ["react", "announce"] or (mode == "timing" and battle.timing_role == "DEFEND"): chosen = battle.action_defender
	if chosen != null and players.has(chosen):
		result["player:%d" % players.find(chosen)] = status_rect(players.find(chosen))
	return result


func enemy_mark_rect(index: int) -> Rect2:
	var column := enemy_column(index)
	return Rect2(column.position + Vector2(8, 8), Vector2(maxf(8.0, column.size.x - 16), COLUMN_SIZE.y - 30))


func _draw_marks() -> void:
	if battle == null or target_sheet == null: return
	var targets := mark_targets()
	for key in targets:
		var r: Rect2 = targets[key]
		var s := PANEL_BRACKET_HEIGHT / BRACKET_BAND.y if String(key).begins_with("player:") else r.size.x / 448.0
		var piece := Vector2(192, BRACKET_BAND.y) * s
		var corners := [r.position, Vector2(r.end.x - piece.x, r.position.y), Vector2(r.position.x, r.end.y - piece.y), r.end - piece]
		for i in 4:
			var tile: int = BRACKET_TILES[i]
			var source := Rect2((tile % 5) * 192, (tile / 5) * 192 + BRACKET_BAND.x, 192, BRACKET_BAND.y)
			marks.draw_texture_rect_region(target_sheet, Rect2(corners[i], piece), source, Color(1, 1, 1, 200.0 / 255.0))

func impact_flash() -> void:
	impact_left = IMPACT_SECONDS


func shake(unit: BattleUnit) -> void:
	if unit != null: _shakes[unit.id] = 0.0


## Damage shake: any unit whose HP went down since the last frame shakes.
func _track_hp_shake() -> void:
	for unit in players + opponents:
		var last: int = int(_hp_last.get(unit.id, unit.current_hp))
		_hp_last[unit.id] = unit.current_hp
		if unit.current_hp < last: shake(unit)


## D-125 (SkillGrotesqueFX): units whose enemy silhouette is replaced by the fever-warp overlay (the HUD
## skips the plain black silhouette) and the horizontal wobble of a hero card under the same warp.
var warp_hidden: Dictionary = {}
var warp_card: Dictionary = {}


## Horizontal shake offset for a unit's sprite or card.
func shake_offset(unit: BattleUnit) -> Vector2:
	if unit == null: return Vector2.ZERO
	var wobble: Vector2 = warp_card.get(unit.id, Vector2.ZERO)
	if not _shakes.has(unit.id): return wobble
	var age: float = _shakes[unit.id]
	return wobble + Vector2(SHAKE_PX if int(age * SHAKE_HZ) % 2 == 0 else -SHAKE_PX, 0)


## D-049 rails: [top = opponent (red), bottom = player (white)].
func counter_rail_rects(kind: String, index: int) -> Array[Rect2]:
	if timing_at_log:
		var strip := _log_rail_strip()
		# Duas trilhas separadas dentro do battlelog, uma para cada ponteiro.
		var top := Rect2(strip.position + Vector2(0, 4), Vector2(strip.size.x, 13))
		var bottom := Rect2(strip.position + Vector2(0, 32), Vector2(strip.size.x, 13))
		return [top, bottom]
	if kind == "panel":
		# D-058: a hero's counter-attack runs inside the battle log, not over the hero.
		var single := defense_rail_rect(index)
		return [Rect2(single.position - Vector2(0, LOG_RAIL_PAIR_OFFSET), single.size),
				Rect2(single.position + Vector2(0, LOG_RAIL_PAIR_OFFSET), single.size)]
	var bottom: Rect2 = attack_rail_rect(index)
	var top := Rect2(bottom.position - Vector2(0, bottom.size.y + 3), bottom.size)
	var rails: Array[Rect2] = [top, bottom]
	return rails


## Faixa interna do battlelog usada pelo teste de disputas no log.
func _log_rail_strip() -> Rect2:
	return Rect2(BATTLE_LOG_RECT.position + Vector2(8, 0),
			Vector2(BATTLE_LOG_RECT.size.x - 16, BATTLE_LOG_RECT.size.y))


func announce(text: String) -> void:
	announcement_text = text
	announcement_age = 0.0
	alert_unit = null # only announce_attack() shows the red "!"
	# D-057: the banner no longer writes the log; ROUND / VICTORY / DEFEAT are pushed as
	# events by the controller, so they still stay in the log after the banner fades.


## D-057: one event sentence enters the log (prayer lines keep their #f5f58c ink).
func push_event(text: String, ink: Color = NO_INK) -> void:
	if text.is_empty():
		return
	events.append({"text": text, "ink": ink, "names": _role_name_inks()})
	while events.size() > EVENT_CAP:
		events.pop_front()
	events_read = events.size()


## D-060 (creator 2026-11-25): in the log, each name takes the colour of its role at the
## moment of the event (attacker red, target yellow, defender blue, counter orange, reaction
## green, the D-059 arrow inks); the rest of the sentence stays as it was.
func _role_name_inks() -> Dictionary:
	var result := {}
	if battle == null or not ("roles" in battle): return result
	for unit in players + opponents:
		var role := role_of(unit)
		if not role.is_empty() and ROLE_ARROW_INKS.has(role):
			result[String(battle.short_name(unit))] = ROLE_ARROW_INKS[role]
	return result


## Draws `text` with the names in `names` in their own colour; returns the width.
func _str_named(text: String, x: float, baseline: float, ink: Color, px: int, names: Dictionary) -> float:
	if names.is_empty():
		return _str(text, x, baseline, ink, px)
	var keys: Array = names.keys()
	keys.sort_custom(func(a, b): return String(a).length() > String(b).length())
	var cursor := x
	var i := 0
	var plain := ""
	while i < text.length():
		var hit := ""
		for key in keys:
			var k := String(key)
			if text.substr(i, k.length()) == k:
				var after := text.substr(i + k.length(), 1)
				# Whole names only ("FOE A" must not colour the start of "FOE AB").
				if after.is_empty() or not (after[0] >= "A" and after[0] <= "Z") and not (after[0] >= "a" and after[0] <= "z"):
					hit = k
					break
		if hit.is_empty():
			plain += text[i]
			i += 1
			continue
		if not plain.is_empty():
			cursor += _str(plain, cursor, baseline, ink, px)
			plain = ""
		cursor += _str(hit, cursor, baseline, Color(names[hit], ink.a), px)
		i += hit.length()
	if not plain.is_empty():
		cursor += _str(plain, cursor, baseline, ink, px)
	return cursor - x


## D-110: the window always shows the newest lines (no unread page waits).
func _events_end() -> int:
	return events.size()


## D-110: nothing ever waits beyond the window, so the battle never pages the log.
func log_hidden() -> bool:
	return false


func page_log() -> void:
	events_read = events.size()


func press_command(row: int, kind: String) -> void:
	_press_row = row
	_press_kind = kind
	_press_age = 0.0


func enemy_column(index: int) -> Rect2:
	var count := maxi(1, opponents.size())
	# Com 3 demônios as colunas de 220 px vazavam da janela: encolhe a coluna.
	var gap := 10.0
	var col_w := mini(COLUMN_SIZE.x, (FIELD_RECT.size.x - gap * (count + 1)) / count)
	var left := FIELD_RECT.position.x + gap + index * (col_w + gap)
	return Rect2(Vector2(left, FIELD_RECT.end.y - COLUMN_SIZE.y), Vector2(col_w, COLUMN_SIZE.y))


func enemy_sprite_rect(index: int) -> Rect2:
	# The HTML sprite box (156 x 166) at the top of the column; the SMT art keeps its
	# aspect and stands on the box floor, like the HTML silhouettes and their shadows.
	var column := enemy_column(index)
	var region: Rect2 = battler_regions[index % battler_regions.size()]
	var factor := minf(SPRITE_BOX.x / region.size.x, SPRITE_BOX.y / region.size.y)
	var art := region.size * factor
	var box := Rect2(column.position + Vector2(maxf(0.0, (column.size.x - SPRITE_BOX.x) * 0.5), 0), SPRITE_BOX)
	var rect := Rect2(Vector2(box.get_center().x - art.x * 0.5, box.end.y - art.y), art)
	var top := _depth_point(rect.position, rect.get_center().x)
	var out := Rect2(top, rect.size * enemy_depth)
	if index >= 0 and index < opponents.size() and opponents[index].race == &"floater_eye":
		# D-129: Floater Eyes are smaller hovering 2D silhouettes; keeping this in enemy_sprite_rect
		# aligns SP arrows, intent tags, WHITEN ghosts, hit VFX and absorption fragments cleanly.
		var eye_size := out.size * 0.72
		var hover_y := sin(time * 3.0 + float(index) * 1.9) * 4.0
		out = Rect2(Vector2(out.get_center().x - eye_size.x * 0.5,
				out.position.y + out.size.y * 0.14 + hover_y), eye_size)
	return out


## Perspective push: scale about the horizon point straight above/below `pivot_x`.
func _depth_point(p: Vector2, pivot_x: float) -> Vector2:
	var pivot := Vector2(pivot_x, enemy_horizon)
	return pivot + (p - pivot) * enemy_depth


func attack_rail_rect(index: int) -> Rect2:
	if timing_at_log:
		var strip := _log_rail_strip()
		return Rect2(strip.position + Vector2(0, 8), Vector2(strip.size.x, 13))
	var column := enemy_column(maxi(0, index))
	return Rect2(column.position + Vector2(34, 86), Vector2(COLUMN_SIZE.x - 68, 13))


## D-058 (creator 2026-11-25): defenses and a hero's reactions run inside the battle log
## window, not over the hero's window; the log text gives way while the rail runs.
func defense_rail_rect(_index: int) -> Rect2:
	var strip := _log_rail_strip()
	return Rect2(strip.position.x, strip.get_center().y - 4.0, strip.size.x, 8)


## The rails on screen right now sit in the battle log window (its text is hidden).
func rails_in_log() -> bool:
	if battle == null: return false
	if mode == "timing":
		return timing_at_log or battle.timing_role == "DEFEND"
	if mode == "counter":
		return timing_at_log or battle.counter.style == "panel"
	return false


func _round_caption() -> String:
	var shown: int = battle.state.round_number
	if announcement_text == "ROUND %02d" % shown and announcement_age < 0.4: shown -= 1
	return "ROUND %02d" % maxi(1, shown)


func _target_caption() -> String:
	return ""


func _footer_caption() -> String:
	return ""


# ---------------------------------------------------------------- text helpers

func _str(value: String, x: float, baseline: float, color: Color, px: int, bold := false, align := HORIZONTAL_ALIGNMENT_LEFT, shadow := Color(0, 0, 0, 0)) -> float:
	var f: Font = ui_bold if bold else ui_font
	var w := f.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var left := x
	if align == HORIZONTAL_ALIGNMENT_RIGHT: left = x - w
	elif align == HORIZONTAL_ALIGNMENT_CENTER: left = x - w * 0.5
	if shadow.a > 0:
		draw_string(f, Vector2(left, baseline + 1), value, HORIZONTAL_ALIGNMENT_LEFT, -1, px, shadow)
	draw_string(f, Vector2(left, baseline), value, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)
	return w


func _width(value: String, px: int, bold := false) -> float:
	return (ui_bold if bold else ui_font).get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x


## Nunca corta o texto: reduza a fonte até a frase inteira caber no espaço.
## D-111: the 3 narrow windows (Survival) share one name size, the largest that fits every hero
## (the chooser's arrow and each one's SP included), so no name looks bigger than the others.
func _narrow_name_px(r: Rect2) -> int:
	var px := 12
	var pips := 4 * (20.0 / 3.0) + 3 * 2.0
	for unit in players:
		var limit := r.size.x - 18.0 - pips - 16.0 / 3.0 - _width("SP %d" % unit.current_sp, 9) - 6.0 - 9.0
		px = mini(px, _fit_px(unit.display_name, 12, maxf(12.0, limit), true))
	return px


func _fit_px(value: String, px: int, max_width: float, bold := false, min_px := 7) -> int:
	var size := px
	while size > min_px and _width(value, size, bold) > max_width:
		size -= 1
	return size


# CSS "ease" (cubic-bezier(.25,.1,.25,1)) and "ease-out" (0,0,.58,1).
func _bezier(x: float, x1: float, y1: float, x2: float, y2: float) -> float:
	var lo := 0.0
	var hi := 1.0
	var t := x
	for i in 18:
		t = (lo + hi) * 0.5
		var bx := 3.0 * (1.0 - t) * (1.0 - t) * t * x1 + 3.0 * (1.0 - t) * t * t * x2 + t * t * t
		if bx < x: lo = t
		else: hi = t
	return 3.0 * (1.0 - t) * (1.0 - t) * t * y1 + 3.0 * (1.0 - t) * t * t * y2 + t * t * t


func _ease(x: float) -> float:
	return _bezier(clampf(x, 0, 1), 0.25, 0.1, 0.25, 1.0)


func _stepped(age: float, duration: float, steps: int) -> float:
	return floorf(clampf(age / duration, 0, 1) * steps) / steps


## CSS keyframes with a steps(n, end) timing function applied per keyframe segment.
func _keyframes(age: float, duration: float, stops: Array, values: Array, steps: int) -> Variant:
	var p := clampf(age / duration, 0, 1)
	if p >= 1.0: return values[values.size() - 1]
	for i in stops.size() - 1:
		if p < stops[i + 1]:
			var local: float = (p - stops[i]) / (stops[i + 1] - stops[i])
			var q := floorf(local * steps) / steps
			var a: Variant = values[i]
			var b: Variant = values[i + 1]
			if a is Color: return (a as Color).lerp(b, q)
			return lerpf(a, b, q)
	return values[values.size() - 1]


# ---------------------------------------------------------------- draw

func _draw() -> void:
	_role_tags.clear()
	if role_layer != null: role_layer.queue_redraw()
	if font == null or ui_font == null or battle == null: return
	hitboxes.clear()
	_backdrop()
	_header()
	_sp_window()
	_turn_strip()
	var selected := _selected_enemy()
	if selected != _corner_index:
		_corner_index = selected
		_corner_age = 0.0
	for i in opponents.size():
		_enemy(0, i)
	_announcement()
	_log_line()
	for who in players.size():
		_character(who, status_rect(who))
		# D-132 (criador 2026-11-26): while one hero's options are being chosen, the other
		# hero's card is darkened to 50% so it is clear who is playing.
		if card_dimmed(players[who]):
			draw_set_transform(shake_offset(players[who]))
			draw_rect(status_rect(who), Color(0, 0, 0, INACTIVE_CARD_DIM))
			draw_set_transform(Vector2.ZERO)
	_menu()
	if mode in ["timing", "counter", "absorb", "continue", "announce", "turn", "result"]:
		hitboxes.append({"rect": Rect2(Vector2.ZERO, SCREEN), "key": "live-confirm"})


func _backdrop() -> void:
	if impact_left > 0.0:
		draw_rect(STAGE_RECT, Color.WHITE)
		_footer()
		return
	if not stage_backdrop:
		# Prototype hook: a node behind the HUD paints the stage; keep only the footer.
		_footer()
		return
	# exodus_feedback_lab.html .bg svg (viewBox 544 x 251 stretched to 298 px), drawn
	# STAGE_SHIFT higher like the shader stage.
	draw_set_transform(Vector2(0, STAGE_SHIFT), 0, Vector2.ONE * STAGE_SCALE)
	var sky := [Color("280b14"), Color("5c1c2b"), Color("431a26")]
	var mid := 298.0 * 0.54
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(544, 0), Vector2(544, mid), Vector2(0, mid)]), PackedColorArray([sky[0], sky[0], sky[1], sky[1]]))
	draw_polygon(PackedVector2Array([Vector2(0, mid), Vector2(544, mid), Vector2(544, 298), Vector2(0, 298)]), PackedColorArray([sky[1], sky[1], sky[2], sky[2]]))
	draw_set_transform(Vector2(0, STAGE_SHIFT), 0, Vector2(STAGE_SCALE, STAGE_SCALE * SVG_SCALE_Y))
	draw_circle(Vector2(426, 85), 37, Color("ae565d", 0.22))
	draw_set_transform(Vector2(0, STAGE_SHIFT), 0, Vector2.ONE * STAGE_SCALE)
	_svg_poly("0 168 62 138 95 143 131 108 170 134 227 130 268 94 307 141 371 127 417 100 460 131 505 116 544 145 544 251 0 251", Color("351924"))
	_svg_poly("0 202 84 188 120 198 187 169 243 195 315 181 374 192 437 162 500 189 544 174 544 251 0 251", Color("3b2728"))
	_svg_poly("10 221 84 205 152 223 239 205 318 221 394 207 481 222 544 210 544 251 0 251", Color("61442e"))
	_svg_poly("68 190 68 139 76 139 76 128 94 128 94 137 102 137 102 184", Color.BLACK)
	_svg_poly("462 191 462 149 471 149 471 134 489 134 489 143 500 143 500 186", Color.BLACK)
	var line := _svg_points("0 238 47 228 92 238 167 221 226 241 312 224 396 239 464 220 544 235")
	draw_polyline(line, Color(0, 0, 0, 0.4), 2.0)
	# Grit pattern: 13 x 11 tiles with two dark specks.
	for gx in range(0, 544, 13):
		for gy in range(0, 251, 11):
			draw_rect(Rect2(gx, gy * SVG_SCALE_Y, 1, SVG_SCALE_Y), Color(0, 0, 0, 0.10))
			draw_rect(Rect2(gx + 7, (gy + 8) * SVG_SCALE_Y, 2, SVG_SCALE_Y), Color(0, 0, 0, 0.18))
	# .bg:after — warm shade rising from the floor to 60% of the height.
	var top := 298.0 * 0.4
	draw_polygon(PackedVector2Array([Vector2(0, top), Vector2(544, top), Vector2(544, 298), Vector2(0, 298)]), PackedColorArray([Color(0.141, 0.067, 0.051, 0), Color(0.141, 0.067, 0.051, 0), Color(0.141, 0.067, 0.051, 0.18), Color(0.141, 0.067, 0.051, 0.18)]))
	draw_set_transform(Vector2.ZERO)
	_footer()


## .game::before — the command area under the panels (the log has no background).
func _footer() -> void:
	var y := SCENE_BOTTOM
	draw_polygon(PackedVector2Array([Vector2(0, y), Vector2(SCREEN.x, y), SCREEN, Vector2(0, SCREEN.y)]), PackedColorArray([Color("2a111a"), Color("2a111a"), Color("210d16"), Color("210d16")]))


func _svg_points(spec: String) -> PackedVector2Array:
	var values := spec.split(" ", false)
	var points := PackedVector2Array()
	for i in range(0, values.size(), 2):
		points.append(Vector2(float(values[i]), float(values[i + 1]) * SVG_SCALE_Y))
	return points


func _svg_poly(spec: String, color: Color) -> void:
	draw_colored_polygon(_svg_points(spec), color)


func _header() -> void:
	# Option 13: the round at the left of the single top line, no rule under it.
	_str(_round_caption(), 20.0 / 3.0, HEADER_BASELINE, Color("e8e0dc"), 9, true, HORIZONTAL_ALIGNMENT_LEFT, Color(0, 0, 0, 0.85))


## D-058 (creator 2026-11-25): the round's turn order (BattleState.turn_order, fastest
## first) as a row of name chips under the top line. The unit whose turn it is now is
## filled; units with no act left this round are dimmed; fallen units leave the row.
func turn_strip_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if battle == null or not ("state" in battle) or battle.state == null: return result
	var owner: BattleUnit = battle.turn_owner if "turn_owner" in battle else null
	for unit in battle.state.turn_order:
		if not unit.is_alive(): continue
		result.append({
			"unit": unit,
			"text": NameCase.of(unit.display_name) if unit.is_player else "FOE",
			"current": unit == owner,
			"done": unit != owner and unit.acts_available <= 0,
		})
	return result


func turn_strip_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var entries := turn_strip_entries()
	var widths: Array[float] = []
	var total := 0.0
	for e in entries:
		var w := _width(e.text, TURN_STRIP_PX, true) + 10.0
		widths.append(w)
		total += w
	total += TURN_STRIP_GAP * maxf(0.0, entries.size() - 1)
	var x := (SCREEN.x - total) * 0.5
	for w in widths:
		rects.append(Rect2(x, TURN_STRIP_TOP, w, TURN_STRIP_HEIGHT))
		x += w + TURN_STRIP_GAP
	return rects


func _turn_strip() -> void:
	var entries := turn_strip_entries()
	var rects := turn_strip_rects()
	for i in entries.size():
		var e: Dictionary = entries[i]
		var r := rects[i]
		var unit: BattleUnit = e.unit
		var ink: Color = GREEN_TEXT if unit.is_player else (FLOATER_EYE_GREEN if unit.race == &"floater_eye" else RED_TEXT)
		if e.current:
			draw_rect(r, ink)
			draw_rect(Rect2(r.position + Vector2(0.5, 0.5), r.size - Vector2.ONE), Color.WHITE, false, 1)
			_str(e.text, r.get_center().x, r.position.y + 10.0, Color("1f0e14"), TURN_STRIP_PX, true, HORIZONTAL_ALIGNMENT_CENTER)
		else:
			var alpha := 0.4 if e.done else 1.0
			draw_rect(r, Color(CARD_FILL, CARD_FILL.a * alpha))
			draw_rect(Rect2(r.position + Vector2(0.5, 0.5), r.size - Vector2.ONE), Color(WINDOW_BORDER, WINDOW_BORDER.a * alpha), false, 1)
			_str(e.text, r.get_center().x, r.position.y + 10.0, Color(ink, alpha), TURN_STRIP_PX, true, HORIZONTAL_ALIGNMENT_CENTER)
		if i < entries.size() - 1:
			_str("›", r.end.x + TURN_STRIP_GAP * 0.5, r.position.y + 10.0, Color(TEXT, 0.7), TURN_STRIP_PX, true, HORIZONTAL_ALIGNMENT_CENTER)


func _sp_pair() -> Array:
	var own: BattleUnit = players[clampi(actor, 0, players.size() - 1)] if not players.is_empty() else null
	var foe: BattleUnit = null
	if mode == "target" and battle.target_side == "enemy":
		pass # the selected target below
	elif mode in ["react", "announce"]:
		if opponents.has(battle.action_attacker): foe = battle.action_attacker
	elif battle.in_reaction and mode in ["command", "turn", "target"]:
		if opponents.has(battle.reaction_attacker): foe = battle.reaction_attacker
	elif mode not in ["command", "turn"]:
		if opponents.has(battle.action_attacker): foe = battle.action_attacker
		elif opponents.has(battle.action_defender): foe = battle.action_defender
	var sel := _selected_enemy()
	if foe == null and sel >= 0: foe = opponents[sel]
	if foe == null:
		for unit in opponents:
			if unit.is_alive():
				foe = unit
				break
	return [own, foe]


func _sp_window() -> void:
	var pair := _sp_pair()
	var own: BattleUnit = pair[0]
	var foe: BattleUnit = pair[1]
	if own == null or foe == null: return
	var own_text := "%s · %d SP" % [NameCase.of(own.display_name), own.current_sp]
	var foe_text := "FOE · %d SP" % foe.current_sp
	# Texto nunca invade a barra: cada lado tem seu espaço reservado antes dela.
	var own_limit := SP_TRACK.position.x - 64.0 - 6.0
	var foe_limit := (SCREEN.x - 20.0 / 3.0) - SP_TRACK.end.x - 6.0
	var own_px := _fit_px(own_text, 10, own_limit, true)
	var foe_px := _fit_px(foe_text, 10, foe_limit, true)
	_str(own_text, 64, HEADER_BASELINE, GREEN_TEXT, own_px,
			true, HORIZONTAL_ALIGNMENT_LEFT, Color(0, 0, 0, 0.85))
	_str(foe_text, SCREEN.x - 20.0 / 3.0, HEADER_BASELINE, RED_TEXT, foe_px, true,
			HORIZONTAL_ALIGNMENT_RIGHT, Color(0, 0, 0, 0.85))
	# Where the floating SP letters (D-100) land: the middle of each label.
	_sp_label_own = Vector2(64.0 + _width(own_text, own_px, true) * 0.5, HEADER_BASELINE + SP_FLOAT_LAND)
	_sp_label_foe = Vector2(SCREEN.x - 20.0 / 3.0 - _width(foe_text, foe_px, true) * 0.5, HEADER_BASELINE + SP_FLOAT_LAND)
	var share := float(own.current_sp) / maxf(1.0, own.current_sp + foe.current_sp)
	if not is_equal_approx(share, _sp_anim.to):
		var current := lerpf(_sp_anim.from, _sp_anim.to, _stepped(_sp_anim.age, 0.36, 9))
		_sp_anim = {"from": current, "to": share, "age": 0.0}
	var shown := lerpf(_sp_anim.from, _sp_anim.to, _stepped(_sp_anim.age, 0.36, 9))
	var track := SP_TRACK
	draw_rect(track, Color(8 / 255.0, 8 / 255.0, 8 / 255.0, 0.5))
	var inner := track.grow(-1)
	draw_rect(Rect2(inner.position, Vector2(roundf(inner.size.x * shown), inner.size.y)), OWN_FILL)
	draw_rect(Rect2(inner.position + Vector2(roundf(inner.size.x * shown), 0), Vector2(inner.size.x - roundf(inner.size.x * shown), inner.size.y)), FOE_FILL)
	draw_rect(Rect2(track.position + Vector2(0.5, 0.5), track.size - Vector2.ONE), Color(1, 1, 1, 0.58), false, 1)


func _selected_enemy() -> int:
	if opponents.is_empty(): return -1
	var showing: bool = mode in ["command", "target", "turn"] and not (mode == "target" and battle.target_side == "player")
	if mode in ["command", "turn"] and battle.in_reaction: showing = false
	if mode == "timing" and battle.timing_role == "ATTACK" and opponents.has(battle.action_defender):
		return opponents.find(battle.action_defender)
	if not showing: return -1
	if target >= 0 and target < opponents.size() and opponents[target].is_alive(): return target
	# The remembered target fell: HTML always keeps one enemy selected.
	for i in opponents.size():
		if opponents[i].is_alive(): return i
	return -1


func _enemy(_x: float, index: int) -> void:
	if index >= opponents.size(): return
	var unit := opponents[index]
	if not unit.is_alive() or broken_units.has(unit): return
	var column := enemy_column(index)
	var art := enemy_sprite_rect(index)
	art.position += shake_offset(unit)
	var texture := silhouettes[index % silhouettes.size()]
	var region := Rect2(Vector2.ZERO, texture.get_size())
	var box := Rect2(column.position + Vector2(maxf(0.0, (column.size.x - SPRITE_BOX.x) * 0.5), 0), SPRITE_BOX)
	# D-125: while the fever-warp overlay draws this silhouette, the plain black one is transparent.
	var ink := Color(0, 0, 0, 0) if warp_hidden.has(unit.id) else Color.BLACK
	if unit.race == &"floater_eye":
		# D-129: Floater Eyes are 2D completely green silhouettes hovering beside their ally.
		draw_texture_rect_region(texture, art, region, Color(0, 0, 0, 0) if warp_hidden.has(unit.id) else FLOATER_EYE_GREEN)
	elif unit.race == &"human":
		# D-107 (creator 2026-11-25): only mazikim are silhouettes; a human is drawn with its own
		# colours and has no ground shadow.
		# Criador 2026-11-26: humano = silhueta preta como a dos mazikim, mas sem sombra no chão.
		draw_texture_rect_region(texture, art, region, ink)
	else:
		# Ground shadow from the HTML silhouettes (ellipse rx 44 ry 6 at 111/119), filled black.
		var k := SPRITE_BOX.x / 112.0
		var shadow_x := box.position.x + 55 * k
		# A sombra fica exatamente na linha dos pés da arte (art.end.y), que é a
		# mesma com qualquer depth/horizonte — antes usava a caixa e descolava.
		draw_set_transform(Vector2(shadow_x, art.end.y + 8), 0, Vector2(1, 6.0 / 44.0))
		draw_circle(Vector2.ZERO, 44 * k * enemy_depth, Color(24 / 255.0, 17 / 255.0, 26 / 255.0, 0.45))
		draw_set_transform(Vector2(shadow_x, art.end.y), 0, Vector2(1, 6.0 / 44.0))
		draw_circle(Vector2.ZERO, 44 * k * enemy_depth, Color.BLACK)
		draw_set_transform(Vector2.ZERO)
		# drop-shadow(0 8px 2px rgba(24,17,26,.45)) and the silhouette (fill:#000).
		draw_texture_rect_region(texture, Rect2(art.position + Vector2(0, 8), art.size), region, Color(24 / 255.0, 17 / 255.0, 26 / 255.0, 0.45))
		draw_texture_rect_region(texture, art, region, ink)
	_status_icon_row(unit, box.position.x + SPRITE_BOX.x * 0.5, art.end.y + 14.0, SPRITE_BOX.x, true)
	var selected := _selected_enemy() == index
	if alert_visible() and alert_unit == unit:
		var t := announcement_age / 0.75
		var alpha := _ease(t / 0.23) if t < 0.23 else (1.0 if t < 0.8 else 1.0 - _ease((t - 0.8) / 0.2))
		# O "!" do anúncio também vazava para fora da tela na primeira coluna.
		var bang_x := maxf(_width("!", ALERT_PX) + 4.0, art.position.x - 4.0)
		_str("!", bang_x, art.position.y + SIGN_HEIGHT, Color(ALERT_RED, alpha), ALERT_PX, true, HORIZONTAL_ALIGNMENT_RIGHT, Color(0, 0, 0, 0.65 * alpha))
	# Creator 2026-11-21: SP arrows hide while a field announcement is on screen.
	var announcing := not announcement_text.is_empty() and announcement_age < 0.75
	if not selected and not announcing:
		var own: BattleUnit = _sp_pair()[0]
		if own != null:
			var left := art.end.x + SIGN_GAP
			# O 3º demônio empurrava a seta/SP para fora da tela: espelha para
			# a esquerda da arte quando não cabe no lado direito.
			if left + ARROW_HEAD.x + SIGN_GAP + _width("SP", 12) > SCREEN.x - 6.0:
				left = maxf(4.0, art.position.x - SIGN_GAP - ARROW_HEAD.x - _width("SP", 12))
			var color: Color = UP_MARK
			var label_x := left
			if own.current_sp == unit.current_sp:
				label_x += _str("=", left, art.position.y + 20, UP_MARK, 20, true, HORIZONTAL_ALIGNMENT_LEFT, Color(0, 0, 0, 0.65))
			else:
				var up := own.current_sp > unit.current_sp
				color = SP_UP if up else SP_DOWN
				_sp_arrow(Vector2(left + ARROW_HEAD.x * 0.5, art.position.y), up)
				label_x += ARROW_HEAD.x
			_str("SP", label_x + SIGN_GAP, art.position.y + ARROW_HEIGHT * 0.5 + 4, color, 12, true, HORIZONTAL_ALIGNMENT_LEFT, Color(0, 0, 0, 0.65))
	# D-135 (criador 2026-11-26): o nome do inimigo não é mais desenhado acima da arte (o
	# nome segue no cabeçalho e na fila). `name_y` é a linha onde ele ficava.
	var name_y := maxf(FIELD_RECT.position.y + 16.0, art.position.y - 16.0)
	var role := role_of(unit)
	# D-057/D-135: the enemy's role in the action on screen is plain upper-case text, in
	# the role's colour, on the line where the name used to be (the queued-acts arrows give
	# way to it while the action runs).
	if not role.is_empty():
		_role_tag(role, column.get_center().x, name_y - 9.5, true)
		_role_tags[-1]["unit"] = unit
		_role_tags[-1]["side"] = "enemy"
		_role_tags[-1]["anchor"] = Vector2(column.get_center().x, name_y + 2.0)
	# Atos já planejados com este inimigo como alvo: setas verdes sem cabo.
	var queued: int = battle.queued_acts_for(unit) if battle.has_method("queued_acts_for") and role.is_empty() else 0
	for i in mini(queued, 4):
		var cx := column.get_center().x + (float(i) - float(mini(queued, 4) - 1) * 0.5) * 11.0
		var head := PackedVector2Array([
			Vector2(cx, name_y - 18.0), Vector2(cx - 5.0, name_y - 9.0), Vector2(cx + 5.0, name_y - 9.0)])
		draw_colored_polygon(head, SP_UP)
		draw_polyline(PackedVector2Array([head[0], head[1], head[2], head[0]]),
				Color(0.05, 0.1, 0.06, 0.8), 1.0)
	# Creator 2026-11-22: enemy HP is never shown (no bar, no value).
	if mode == "target" and battle.target_side == "enemy":
		hitboxes.append({"rect": column, "key": "target:" + str(index)})


## D-057: the unit's role in the action on screen ("" = none): ATTACK, TARGET, DEFEND,
## COUNTER or REACT, from the announcement until the result is confirmed.
func role_of(unit: BattleUnit) -> String:
	if battle == null or unit == null or not ("roles" in battle):
		return ""
	return String(battle.roles.get(unit.id, ""))


## D-057: queues one role tag; role_layer draws it above the HUD and the brackets.
func _role_tag(role: String, x: float, top: float, centered: bool) -> Rect2:
	var r := role_tag_rect(role, x, top, centered)
	_role_tags.append({"role": role, "rect": r})
	return r


## Rect of a role tag: bold caps plus 4 px each side, 12 px tall, kept on screen.
func role_tag_rect(role: String, x: float, top: float, centered: bool) -> Rect2:
	var w := _width(role, ROLE_PX, true) + 8.0
	var left := x - w * 0.5 if centered else x
	left = clampf(left, 2.0, SCREEN.x - w - 2.0)
	return Rect2(left, top, w, 12.0)


## Role tags visible this frame: [{role, rect}].
func role_tags() -> Array[Dictionary]:
	return _role_tags


## D-059 (creator 2026-11-25): role boxes plus animated arrows. Each blow draws an arrow
## that runs from the attacker to its target in ROLE_ARROW_RUN seconds and then fades out
## fast (ROLE_ARROW_FADE). A counter-attack sends one arrow from each side; they meet in the
## middle and a spark marks the clash. Fade and spark sizes were set by the agent (the
## creator said "perdendo opacidade bem rapido" / "faisca"), pending his visual judgment.
const ROLE_ARROW_RUN := 0.55
const ROLE_ARROW_FADE := 0.15
const ROLE_SPARK_TIME := 0.25
const ROLE_SPARK_RADIUS := 11.0
const ROLE_ARROW_INKS := {
	"ATTACK": Color("ff6b6b"), "TARGET": Color("ffe08a"), "DEFEND": Color("7fb2ff"),
	"COUNTER": Color("ffa04d"), "REACT": Color("6fe39a"),
}
## Arrow key -> time it started (HUD time); keys leave when their roles leave the screen.
var _arrow_started := {}


## The arrows the current roles call for: [{key, from, to, ink, head, clash}].
## ATTACK -> each TARGET / DEFEND unit on the other side; a COUNTER unit and the ATTACK
## unit it answers clash instead (one arrow from each, meeting in the middle).
func role_arrows() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var by_role := {}
	for tag in _role_tags:
		if not tag.has("anchor"): continue
		if not by_role.has(tag.role): by_role[tag.role] = []
		by_role[tag.role].append(tag)
	var receivers: Array = by_role.get("TARGET", []) + by_role.get("DEFEND", [])
	for src in by_role.get("ATTACK", []):
		for dst in receivers:
			if dst.side == src.side: continue
			result.append({"key": "%s>%s" % [src.unit.id, dst.unit.id], "from": src.anchor, "to": dst.anchor,
					"ink": ROLE_ARROW_INKS.ATTACK, "head": ROLE_ARROW_INKS.get(dst.role, Color.WHITE), "clash": false})
	for counter_tag in by_role.get("COUNTER", []):
		for atk in by_role.get("ATTACK", []):
			if atk.side == counter_tag.side: continue
			result.append({"key": "%s<>%s" % [atk.unit.id, counter_tag.unit.id], "from": atk.anchor, "to": counter_tag.anchor,
					"ink": ROLE_ARROW_INKS.ATTACK, "head": ROLE_ARROW_INKS.COUNTER, "clash": true})
	return result


## Age of each arrow on screen (seconds since it started); starts new ones, forgets gone ones.
func _age_arrows(arrows: Array[Dictionary]) -> void:
	var seen := {}
	for a in arrows:
		seen[a.key] = true
		if not _arrow_started.has(a.key): _arrow_started[a.key] = time
	for key in _arrow_started.keys():
		if not seen.has(key): _arrow_started.erase(key)


## A new blow by `unit_id` runs its arrows again from the start.
func restart_arrows(unit_id: StringName) -> void:
	for key in _arrow_started.keys():
		if String(key).begins_with(String(unit_id) + ">") or String(key).begins_with(String(unit_id) + "<>"):
			_arrow_started.erase(key)


func arrow_age(key: String) -> float:
	return time - float(_arrow_started[key]) if _arrow_started.has(key) else -1.0


func _draw_role_tags() -> void:
	var arrows := role_arrows()
	_age_arrows(arrows)
	for a in arrows:
		_draw_moving_arrow(a, arrow_age(a.key))
	_draw_role_boxes()
	_draw_sp_floats()


## How far an arrow has run (0..1) and how visible it is, by its age in seconds.
func arrow_run(age: float) -> float:
	return clampf(age / ROLE_ARROW_RUN, 0.0, 1.0)


func arrow_alpha(age: float) -> float:
	return 1.0 - clampf((age - ROLE_ARROW_RUN) / ROLE_ARROW_FADE, 0.0, 1.0)


func _draw_moving_arrow(a: Dictionary, age: float) -> void:
	var run := arrow_run(age)
	var alpha := arrow_alpha(age)
	var from: Vector2 = a.from
	var to: Vector2 = a.to
	var p := _ease(run)
	if not a.clash:
		if alpha > 0.0:
			_role_arrow(from, from.lerp(to, p), Color(a.ink, alpha), Color(a.head, alpha))
		return
	# Clash: each side runs to the middle; the spark starts when they meet.
	var middle := from.lerp(to, 0.5)
	if alpha > 0.0:
		_role_arrow(from, from.lerp(middle, p), Color(a.ink, alpha), Color(a.ink, alpha))
		_role_arrow(to, to.lerp(middle, p), Color(a.head, alpha), Color(a.head, alpha))
	var spark := (age - ROLE_ARROW_RUN) / ROLE_SPARK_TIME
	if spark >= 0.0 and spark < 1.0:
		var r := ROLE_SPARK_RADIUS * _ease(spark)
		var fade := 1.0 - spark
		role_layer.draw_circle(middle, r * 0.55, Color(1, 1, 0.9, fade))
		for i in 8:
			var dir := Vector2.RIGHT.rotated(TAU * i / 8.0 + 0.2)
			role_layer.draw_line(middle + dir * r * 0.5, middle + dir * r * (1.4 if i % 2 == 0 else 1.0),
					Color(1, 0.85, 0.45, fade), 2.0)


func _role_arrow(from: Vector2, tip: Vector2, ink: Color, head_ink: Color) -> void:
	var length := from.distance_to(tip)
	if length < 1.0: return
	var dir := (tip - from) / length
	var base := tip - dir * minf(7.0, length)
	var side := Vector2(-dir.y, dir.x) * 4.0
	var shadow := Color(0.06, 0.02, 0.04, 0.8 * ink.a)
	role_layer.draw_line(from + Vector2(1, 1), base + Vector2(1, 1), shadow, 2.0)
	role_layer.draw_line(from, base, ink, 2.0)
	role_layer.draw_colored_polygon(PackedVector2Array([tip + Vector2(1, 1), base + side + Vector2(1, 1), base - side + Vector2(1, 1)]), shadow)
	role_layer.draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), head_ink)


## Roles of the boxes painted by the last role-layer draw (tests read it).
var drawn_role_boxes: Array[String] = []


## D-135 (criador 2026-11-26, revoga os blocos da D-057): the role is plain bold upper-case
## text in the role's colour (ROLE_ARROW_INKS) with a shadow, no box; only enemies have it.
func _draw_role_boxes() -> void:
	# D-102 (creator 2026-11-25, revokes D-061): the text stays while its role exists; it goes
	# away when the controller clears the roles (result confirmed).
	drawn_role_boxes.clear()
	for tag in _role_tags:
		if bool(tag.get("hidden", false)):
			continue
		var role: String = tag.role
		var r: Rect2 = tag.rect
		drawn_role_boxes.append(role)
		var w := _width(role, ROLE_PX, true)
		var at := Vector2(r.get_center().x - w * 0.5, r.position.y + 9.5)
		role_layer.draw_string(ui_bold, at + Vector2(0, 1), role, HORIZONTAL_ALIGNMENT_LEFT, -1, ROLE_PX, Color(0, 0, 0, 0.6))
		role_layer.draw_string(ui_bold, at, role, HORIZONTAL_ALIGNMENT_LEFT, -1, ROLE_PX, ROLE_ARROW_INKS.get(role, Color.WHITE))


## D-100 (creator 2026-11-25): every SP change floats ONE random Hebrew letter (never the value)
## from the unit that gained or lost it up to that side's SP label in the header — green for a
## gain, red for a loss, for heroes and enemies alike (a steal shows red on the loser, green on
## the winner). The alphabet is the one of the absorption letters (D-052).
const SP_ALPHABET := "אבגדהוזחטיכלמנסעפצקרשת"
var _sp_font: SystemFont
var _sp_rng := RandomNumberGenerator.new()
## Every letter takes the same quick SP_FLOAT_TIME, along an arc, at its own random speed curve.
const SP_FLOAT_TIME := 0.5
const SP_FLOAT_FADE := 0.12
const SP_ARC_MIN := 18.0
const SP_ARC_MAX := 46.0
const SP_CURVE_MIN := 0.55
const SP_CURVE_MAX := 1.9
const SP_FLOAT_PX := 14
## The letters stop this far under the label's baseline so they never print over its text.
const SP_FLOAT_LAND := 7.0
const SP_FLOAT_INKS := {"gain": Color("81e6a8"), "loss": Color("ff6b6b")}
## unit id -> SP last seen; unit ids are never reused inside a battle.
var _sp_last := {}
var _sp_floats: Array[Dictionary] = []
var _sp_label_own := Vector2(100, 20)
var _sp_label_foe := Vector2(440, 20)


## Looks for SP changes since the last call and starts one float for each.
func track_sp() -> void:
	if battle == null: return
	var changes: Array[Dictionary] = []
	for unit in players + opponents:
		if not _sp_last.has(unit.id):
			_sp_last[unit.id] = unit.current_sp
			continue
		var delta: int = unit.current_sp - int(_sp_last[unit.id])
		_sp_last[unit.id] = unit.current_sp
		if delta != 0: changes.append({"unit": unit, "delta": delta})
	if changes.is_empty(): return
	if _sp_font == null:
		_sp_font = SystemFont.new()
		_sp_font.font_names = PackedStringArray(["Tahoma", "Arial", "David Libre"])
		_sp_font.font_weight = 800
		_sp_rng.seed = 100
	# An enemy that lost SP in the same moment is the source of a steal.
	var loser: BattleUnit = null
	for c in changes:
		if int(c.delta) < 0 and opponents.has(c.unit): loser = c.unit
	for c in changes:
		var unit: BattleUnit = c.unit
		var hero := players.has(unit)
		var origin := Vector2.ZERO
		if hero and int(c.delta) > 0:
			# Creator 2026-11-25: a hero's SP gain comes OUT OF THE ENEMY it was earned against
			# (the one hit or interrupted), not out of the hero's card.
			var art := enemy_sprite_rect(maxi(0, opponents.find(_sp_source(loser))))
			origin = art.get_center() + Vector2(_sp_rng.randf_range(-8.0, 8.0), _sp_rng.randf_range(-8.0, 8.0))
		elif hero:
			# A hero's loss leaves from the top edge of the log above its window (like the role
			# arrows, D-059) so the letter never runs across the log's text.
			var r: Rect2 = status_rect(maxi(0, players.find(unit)))
			origin = Vector2(r.get_center().x, BATTLE_LOG_RECT.position.y - 2.0)
		else:
			var art := enemy_sprite_rect(opponents.find(unit))
			origin = Vector2(art.get_center().x, art.position.y)
		var glyph := SP_ALPHABET[_sp_rng.randi_range(0, SP_ALPHABET.length() - 1)]
		# Arc: the middle of the flight is pushed sideways (random side and height); the speed
		# curve (exponent) is random too, but the flight always lasts SP_FLOAT_TIME.
		var arc := _sp_rng.randf_range(SP_ARC_MIN, SP_ARC_MAX) * (1.0 if _sp_rng.randf() < 0.5 else -1.0)
		var curve := _sp_rng.randf_range(SP_CURVE_MIN, SP_CURVE_MAX)
		_sp_floats.append({"unit": unit, "amount": int(c.delta), "glyph": glyph, "started": time, "from": origin,
				"to": _sp_label_own if hero else _sp_label_foe, "arc": arc, "curve": curve})


## The enemy a hero's SP gain comes out of: the one that lost SP at the same time, else the
## enemy of the action on screen, else the selected one, else the first one alive.
func _sp_source(loser: BattleUnit) -> BattleUnit:
	if loser != null: return loser
	if battle.action_defender != null and opponents.has(battle.action_defender): return battle.action_defender
	if battle.action_attacker != null and opponents.has(battle.action_attacker): return battle.action_attacker
	var selected := _selected_enemy()
	if selected >= 0: return opponents[selected]
	for foe in opponents:
		if foe.is_alive(): return foe
	return opponents[0]


func sp_floats() -> Array[Dictionary]:
	return _sp_floats


func sp_float_age(f: Dictionary) -> float:
	return time - float(f.started)


## Position of a float by its age: a quadratic arc from its source to the SP label; the speed
## curve is random per letter and the duration is the same for all.
func sp_float_pos(f: Dictionary, age: float) -> Vector2:
	var t := pow(clampf(age / SP_FLOAT_TIME, 0.0, 1.0), float(f.curve))
	var from: Vector2 = f.from
	var to: Vector2 = f.to
	var dir := (to - from).normalized()
	var control := from.lerp(to, 0.5) + Vector2(-dir.y, dir.x) * float(f.arc)
	return from.lerp(control, t).lerp(control.lerp(to, t), t)


func sp_float_alpha(age: float) -> float:
	return 1.0 - clampf((age - (SP_FLOAT_TIME - SP_FLOAT_FADE)) / SP_FLOAT_FADE, 0.0, 1.0)


func sp_float_text(f: Dictionary) -> String:
	return String(f.glyph)


func _draw_sp_floats() -> void:
	_sp_floats = _sp_floats.filter(func(f: Dictionary) -> bool: return sp_float_age(f) < SP_FLOAT_TIME)
	for f in _sp_floats:
		var age := sp_float_age(f)
		var at := sp_float_pos(f, age)
		var ink: Color = SP_FLOAT_INKS.gain if int(f.amount) > 0 else SP_FLOAT_INKS.loss
		var alpha := sp_float_alpha(age)
		var text := sp_float_text(f)
		var w := _sp_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, SP_FLOAT_PX).x
		var left := Vector2(at.x - w * 0.5, at.y)
		role_layer.draw_string(_sp_font, left + Vector2(0, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, SP_FLOAT_PX, Color(0, 0, 0, 0.85 * alpha))
		role_layer.draw_string(_sp_font, left, text, HORIZONTAL_ALIGNMENT_LEFT, -1, SP_FLOAT_PX, Color(ink, alpha))


## SP comparison arrow: top-centre anchor, ARROW_HEIGHT tall, head ARROW_HEAD, shaft ARROW_SHAFT.
func _sp_arrow(top: Vector2, up: bool) -> void:
	var h := ARROW_HEIGHT
	var head := ARROW_HEAD
	var w := ARROW_SHAFT * 0.5
	var pts := PackedVector2Array()
	if up:
		pts = PackedVector2Array([top, top + Vector2(head.x * 0.5, head.y), top + Vector2(w, head.y), top + Vector2(w, h), top + Vector2(-w, h), top + Vector2(-w, head.y), top + Vector2(-head.x * 0.5, head.y)])
	else:
		var tip := top + Vector2(0, h)
		pts = PackedVector2Array([tip, tip + Vector2(-head.x * 0.5, -head.y), tip + Vector2(-w, -head.y), top + Vector2(-w, 0), top + Vector2(w, 0), tip + Vector2(w, -head.y), tip + Vector2(head.x * 0.5, -head.y)])
	var shadow := PackedVector2Array()
	for point in pts: shadow.append(point + Vector2(0, 1))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.65))
	draw_colored_polygon(pts, SP_UP if up else SP_DOWN)


## Creator 2026-11-21: announcements sit centred in the header line, fade only (same
## 0.75 s keyframe opacity), no slide and no underline.
func _announcement() -> void:
	var t := announcement_age / 0.75
	if t >= 1.0 or announcement_text.is_empty(): return
	var alpha := _ease(t / 0.23) if t < 0.23 else (1.0 if t < 0.8 else 1.0 - _ease((t - 0.8) / 0.2))
	# Option 13: the top line is full, so announcements sit centred just under it.
	_str(announcement_text, SCREEN.x * 0.5, 30, Color("fff9f2", alpha), 12, true, HORIZONTAL_ALIGNMENT_CENTER, Color("14080a", alpha))


## D-057: the transient explanation of the highlighted menu row (skill, prayer, EN,
## item) or the absorb mash counter. Every other mode shows only event lines: the old
## instructions ("Choose enemy: Left / Right...", "Z: confirm") left the log.
func _log_text() -> String:
	match mode:
		"absorb": return "ABSORB [Z]  Mash!  Presses: %d/%d" % [mini(battle._mash_count, BattleMath.ABSORB_MAX_PRESSES), BattleMath.ABSORB_MAX_PRESSES]
		# Creator 2026-11-23: the log line explains the highlighted FIGHT entry.
		"skill": return battle.skill_info(command_index)
		"pray": return battle.prayer.info(command_index)
		"en_extra": return battle.en_extra_info()
		"item": return battle.item_info(command_index) if battle.has_method("item_info") else ""
	return ""


## Rows an event sentence takes at the full log font (at most LOG_LINES).
func _rows_needed(text: String) -> int:
	return clampi(_wrap_text(text, maxf(24.0, _log_inner()), LOG_PX).size(), 1, LOG_LINES)


func _log_inner() -> float:
	var text_x := BATTLE_LOG_RECT.position.x + 31.0 / 3.0
	return BATTLE_LOG_RECT.end.x - 5.0 - (text_x + _width("*", LOG_PX, true) + 4.0)


## D-057 / D-056: the entries the Battle Log shows now, oldest first. While lines are
## unread the window starts at the oldest unread one and takes whole lines up to the
## two rows; once everything was read it shows the newest lines. A menu explanation is
## the newest line while its menu is open.
func visible_log_entries() -> Array[Dictionary]:
	var end := _events_end()
	var shown: Array[Dictionary] = []
	shown.assign(events.slice(maxi(0, end - LOG_LINES), end))
	var text := _log_text()
	if not text.is_empty():
		shown.append({"text": text, "ink": NO_INK, "transient": true})
	return shown.slice(maxi(0, shown.size() - LOG_LINES))


func visible_log_lines() -> Array[String]:
	var lines: Array[String] = []
	for entry in visible_log_entries():
		lines.append(String(entry.text))
	return lines


## Creator 2026-11-24: the log never cuts or leaks text. Every message wraps into
## as many rows as it needs inside the window at the full font size; only whole
## messages enter, newest last (D-056 keeps two rows).
func _log_line() -> void:
	# Teste das disputas no log: a faixa é ocupada pelas trilhas, então o texto
	# do log sai apenas enquanto a disputa está acontecendo.
	if rails_in_log():
		_window(BATTLE_LOG_RECT, WINDOW_FILL, WINDOW_BORDER)
		return
	var entries := visible_log_entries()
	var newest_text := String(entries[-1].text) if not entries.is_empty() else ""
	if newest_text != _log_shown:
		_log_shown = newest_text
		_log_age = 0.0
	var lines: Array[String] = []
	var inks: Dictionary = {}
	var name_inks: Dictionary = {}
	for entry in entries:
		lines.append(String(entry.text))
		if Color(entry.ink).a > 0.0:
			inks[lines.size() - 1] = Color(entry.ink)
		name_inks[lines.size() - 1] = entry.get("names", {})
	_window(BATTLE_LOG_RECT, WINDOW_FILL, WINDOW_BORDER)
	var text_x := BATTLE_LOG_RECT.position.x + 31.0 / 3.0
	var text_start := text_x + _width("*", LOG_PX, true) + 4.0
	var rows := _log_rows(lines, _log_inner())
	for i in rows.size():
		# D-110: the rows start at the top of the window, newest last.
		var row := i
		var entry: Dictionary = rows[i]
		var baseline := LOG_FIRST_BASELINE + row * LOG_STEP
		var newest: bool = entry.newest
		var alpha := lerpf(0.55, 1.0, _ease(_log_age / 0.38)) if newest else LOG_OLD_ALPHA
		var px: int = entry.px
		# Creator 2026-11-24: an asterisk instead of the square bullet, only on
		# the first row of each message (continuation rows stay aligned).
		if entry.first:
			_str("*", text_x, baseline + 1, Color("f6e7df", alpha), px, true)
		# D-048: prayer lines are drawn in #f5f58c.
		var log_ink: Color = inks.get(int(entry.index), Color("f8f1ea"))
		_str_named(entry.text, text_start, baseline, Color(log_ink, alpha), px, name_inks.get(int(entry.index), {}))


## Breaks the value into rows that fit max_width, never dropping characters.
func _wrap_text(value: String, max_width: float, px: int) -> Array[String]:
	var rows: Array[String] = []
	var current := ""
	# D-110: the telegraphic lines separate fields with two spaces; keep them (an empty
	# token is an extra space), but never start or end a row with one.
	for word in value.split(" ", true):
		if word.is_empty():
			if not current.is_empty():
				current += " "
			continue
		var candidate := word if current.is_empty() else current + " " + word
		if _width(candidate, px) <= max_width:
			current = candidate
			continue
		if not current.is_empty():
			rows.append(current.strip_edges(false, true))
		# A single word wider than the window is split by characters, never lost.
		var rest := word
		while _width(rest, px) > max_width and rest.length() > 1:
			var cut := rest.length() - 1
			while cut > 1 and _width(rest.left(cut), px) > max_width:
				cut -= 1
			rows.append(rest.left(cut))
			rest = rest.substr(cut)
		current = rest
	current = current.strip_edges(false, true)
	if not current.is_empty():
		rows.append(current)
	return rows


## Visible log rows: from the newest message back, each message enters whole.
func _log_rows(lines: Array[String], inner: float) -> Array[Dictionary]:
	var chunks: Array[Array] = []
	var total := 0
	for index in range(lines.size() - 1, -1, -1):
		var px := LOG_PX
		var wrapped := _wrap_text(lines[index], maxf(24.0, inner), px)
		while wrapped.size() > LOG_LINES and px > 7:
			px -= 1
			wrapped = _wrap_text(lines[index], maxf(24.0, inner), px)
		if total + wrapped.size() > LOG_LINES:
			break
		var chunk: Array[Dictionary] = []
		for j in wrapped.size():
			chunk.append({
				"text": wrapped[j], "first": j == 0, "newest": index == lines.size() - 1,
				"line": lines[index], "px": px, "index": index,
			})
		chunks.push_front(chunk)
		total += wrapped.size()
	var rows: Array[Dictionary] = []
	for chunk in chunks:
		rows.append_array(chunk)
	if rows.is_empty() and not lines.is_empty():
		# Safety net: a message too long even at the minimum size still fills the log
		# (the tail is shown) instead of leaving it blank.
		var px := 7
		var newest_index := lines.size() - 1
		var wrapped := _wrap_text(lines[newest_index], maxf(24.0, inner), px)
		for j in range(maxi(0, wrapped.size() - LOG_LINES), wrapped.size()):
			rows.append({
				"text": wrapped[j], "first": j == 0, "newest": true,
				"line": lines[newest_index], "px": px, "index": newest_index,
			})
	return rows


## Option 13 window: translucent fill and a 1 px light border.
func _window(r: Rect2, fill: Color, border: Color) -> void:
	draw_rect(r, fill)
	draw_rect(Rect2(r.position + Vector2(0.5, 0.5), r.size - Vector2.ONE), border, false, 1)


## The window of hero `i`: the two windows of the base battle, or 3 narrower ones (D-111).
func status_rect(i: int) -> Rect2:
	if players.size() >= 3:
		var first: Rect2 = STATUS_RECTS[0]
		var second: Rect2 = STATUS_RECTS[1]
		var gap := second.position.x - first.end.x
		var w := (second.end.x - first.position.x - gap * 2.0) / 3.0
		return Rect2(first.position.x + clampi(i, 0, 2) * (w + gap), first.position.y, w, first.size.y)
	return STATUS_RECTS[clampi(i, 0, STATUS_RECTS.size() - 1)]


## D-136 (creator 2026-11-27): geometry and visibility of the hero's in-card role cue
## (options 2 + 3: left inner strip + subtle tint, plus right-aligned plain text on the
## HP/EN row on non-narrow cards). Returns {} when the hero has no active role.
func hero_role_cue(who: int) -> Dictionary:
	if who < 0 or who >= players.size() or ui_font == null or ui_bold == null:
		return {}
	var unit := players[who]
	var role := role_of(unit)
	if role.is_empty() or not ROLE_ARROW_INKS.has(role):
		return {}
	var r := status_rect(who)
	var inner := Rect2(r.position + Vector2.ONE, r.size - Vector2(2.0, 2.0))
	var strip_rect := Rect2(inner.position, Vector2(HERO_ROLE_STRIP_WIDTH, inner.size.y))
	var tint_rect := Rect2(inner.position, Vector2(inner.size.x * HERO_ROLE_TINT_SHARE, inner.size.y))
	var narrow := r.size.x < NARROW_PANEL_LIMIT
	var x := r.position.x + 9.0
	var right := r.end.x - 9.0
	var sec_label := "PP" if unit.prays else "EN"
	var sec_value := "%d/%d" % [unit.current_pp, PrayerBook.MAX_PP] if unit.prays else "%d/%d" % [unit.current_en, unit.effective_max_en()]
	var hp_value := "%d/%d" % [unit.current_hp, unit.stats.max_hp]
	var sec_label_x := x + _width("HP", 9) + 4.0 + _width(hp_value, 9, true) + 10.0
	var sec_end_x := sec_label_x + _width(sec_label, 9) + 4.0 + _width(sec_value, 9, true)
	var avail := right - (sec_end_x + 6.0)
	var px := _fit_px(role, HERO_ROLE_PX, maxf(1.0, avail), true, 6)
	var show_label := (not narrow) and avail >= _width(role, px, true)
	return {
		"role": role,
		"ink": ROLE_ARROW_INKS[role],
		"strip_rect": strip_rect,
		"tint_rect": tint_rect,
		"show_label": show_label,
		"label_px": px,
		"label_right": right,
		"label_avail": avail,
	}


func _character(who: int, r: Rect2) -> void:
	if who >= players.size(): return
	var unit := players[who]
	var key := unit.id
	if not _unit_seen.has(key):
		_unit_seen[key] = {"sp": unit.current_sp, "sp_age": 99.0, "acts": unit.acts_available, "acts_from": unit.acts_available, "acts_age": 99.0}
	var seen: Dictionary = _unit_seen[key]
	if unit.current_sp != seen.sp:
		seen.sp = unit.current_sp
		seen.sp_age = 0.0
	if unit.acts_available != seen.acts:
		seen.acts_from = seen.acts
		seen.acts = unit.acts_available
		seen.acts_age = 0.0
	var highlighted := _panel_highlighted(unit, who)
	var defending: bool = (mode == "timing" and battle.timing_role == "DEFEND" and unit == battle.action_defender) \
		or (mode == "counter" and battle.counter.style == "panel" and unit == battle.action_attacker)
	draw_set_transform(shake_offset(unit))
	# Option 13 hero window: two rows. Top: (arrow) name, SP, ACT and the four act pips.
	# Bottom: HP and EN (PP for Yoch) as coloured numbers only (creator 2026-11-24).
	var border := WINDOW_BORDER
	if highlighted or defending: border = Color(1, 1, 1, 1)
	if defending:
		var swing := absf(fmod(time / 0.7, 2.0) - 1.0)
		border = Color(1, 1, 1, lerpf(0.95, 0.38, _bezier(swing, 0.42, 0, 0.58, 1)))
	elif _choosing_unit() == unit and unit.is_player:
		border = active_border(time)
	_window(r, CARD_FILL, border)
	# D-136 (options 2 + 3): subtle left tint and vertical inner strip stay strictly inside the
	# 1 px border and shake together with the card.
	var role_cue := hero_role_cue(who)
	if not role_cue.is_empty():
		var tint: Rect2 = role_cue.tint_rect
		var role_ink: Color = role_cue.ink
		draw_polygon(
			PackedVector2Array([
				tint.position,
				Vector2(tint.end.x, tint.position.y),
				tint.end,
				Vector2(tint.position.x, tint.end.y),
			]),
			PackedColorArray([
				Color(role_ink, HERO_ROLE_TINT_ALPHA),
				Color(role_ink, 0.0),
				Color(role_ink, 0.0),
				Color(role_ink, HERO_ROLE_TINT_ALPHA),
			])
		)
		draw_rect(role_cue.strip_rect, role_ink)
	var x := r.position.x + 9
	var right := r.end.x - 9
	var top_line := r.position.y + 16
	var name_x := x
	# Creator 2026-11-24: an arrow before the name of the hero who is choosing.
	if _choosing_unit() == unit:
		name_x += _str("▸", x - 1, top_line, Color.WHITE, 10, true) + 1
	var down := not unit.is_alive()
	var pip_w := 20.0 / 3.0
	var pip_gap := 2.0
	var pips_left := right - 4 * pip_w - 3 * pip_gap
	var act_right := pips_left - 16.0 / 3.0
	# D-111: a narrow window (3 heroes) keeps the four pips but drops the "ACT n/4" text.
	var narrow := r.size.x < NARROW_PANEL_LIMIT
	var act_text := "" if narrow else "ACT %d/4" % unit.acts_available
	var sp_text := "SP %d" % unit.current_sp
	var name_limit := right - name_x
	if not down:
		# Nome, SP e ACT dividem a mesma linha: o nome encolhe antes de colidir.
		name_limit = act_right - _width(act_text, 9) - (0.0 if narrow else SP_ACT_GAP) - _width(sp_text, 9) - (6.0 if narrow else 32.0 / 3.0) - name_x
	var label := NameCase.of(unit.display_name) + (" [DOWN]" if down else "")
	_str(label, name_x, top_line,
			Color("ede7e1") if down else Color.WHITE,
			_narrow_name_px(r) if narrow and not down else _fit_px(label, 12, maxf(12.0, name_limit), true), true)
	if not down:
		var planned: int = battle.planned_acts_for(unit)
		for i in 4:
			var pip := Rect2(pips_left + i * (pip_w + pip_gap), top_line - pip_w, pip_w, pip_w)
			var on := i < unit.acts_available
			var earning: bool = seen.acts_age < 0.5 and i >= seen.acts_from and i < seen.acts
			# D-046: acts committed in the plan are green.
			var fill := Color("36aa6d") if i < planned else Color("e7ddd4")
			if earning:
				var scale: float = _keyframes(seen.acts_age, 0.5, [0.0, 0.25, 1.0], [1.0, 1.28, 1.0], 3)
				fill = _keyframes(seen.acts_age, 0.5, [0.0, 0.25, 1.0], [Color(1, 1, 1, 0), Color.WHITE, Color("e7ddd4")], 3)
				pip = Rect2(pip.get_center() - pip.size * scale * 0.5, pip.size * scale)
				draw_rect(pip, fill)
			elif on or i < planned:
				draw_rect(pip, fill)
			else:
				draw_rect(Rect2(pip.position + Vector2(0.5, 0.5), pip.size - Vector2.ONE), Color(1, 1, 1, 0.66), false, 1)
		if not narrow:
			_str(act_text, act_right, top_line, Color.WHITE, 9, true, HORIZONTAL_ALIGNMENT_RIGHT)
		# stat-gain: .65s steps(4) — opacity 1, .55, 1, .55 then back to 1.
		var sp_alpha: float = _keyframes(seen.sp_age, 0.65, [0.0, 0.25, 0.5, 0.7, 1.0], [1.0, 0.55, 1.0, 0.55, 1.0], 4)
		_str(sp_text, act_right - (0.0 if narrow else _width(act_text, 9) + SP_ACT_GAP), top_line,
				Color(GREEN_TEXT, sp_alpha), 9, true, HORIZONTAL_ALIGNMENT_RIGHT)
	var vitals_alpha := 0.58 if defending else 1.0
	var bottom_line := r.position.y + 35
	var sec_label := "PP" if unit.prays else "EN"  # EN is the magic resource (the creator's "MP").
	var sec_ink: Color = Color(PrayerBook.INK, vitals_alpha) if unit.prays else Color(EN_NUMBER, vitals_alpha)
	var sec_value := "%d/%d" % [unit.current_pp, PrayerBook.MAX_PP] if unit.prays else "%d/%d" % [unit.current_en, unit.effective_max_en()]
	var hp_value := "%d/%d" % [unit.current_hp, unit.stats.max_hp]
	# Creator 2026-11-24: no bars, just the coloured numbers (HP red, EN blue, PP yellow).
	var hp_label_w := _str("HP", x, bottom_line, Color(TEXT, vitals_alpha), 9)
	var hp_value_x := x + hp_label_w + 4
	_str(hp_value, hp_value_x, bottom_line, Color(HP_NUMBER, vitals_alpha), 9, true)
	var sec_label_x := hp_value_x + _width(hp_value, 9, true) + 10
	_str(sec_label, sec_label_x, bottom_line, Color(TEXT, vitals_alpha), 9)
	# O número fica logo após o rótulo, não encostado na borda direita do painel.
	_str(sec_value, sec_label_x + _width(sec_label, 9) + 4, bottom_line, sec_ink, 9, true)
	# D-136 (option 3): plain role text at bottom-right of the HP/EN row when width allows.
	if not role_cue.is_empty() and bool(role_cue.show_label):
		_str(String(role_cue.role), float(role_cue.label_right), bottom_line, Color(role_cue.ink),
				int(role_cue.label_px), true, HORIZONTAL_ALIGNMENT_RIGHT, Color(0, 0, 0, 0.75))
	# Opção C do protótipo de ícones de status: fileira sobre a borda inferior do cartão (4 px dentro, 6 fora),
	# desenhada dentro do transform do cartão para tremer junto no impacto.
	if unit.is_alive():
		_status_icon_row(unit, r.end.x - 6.0, r.end.y - STATUS_ICON_INSET, r.size.x - 12.0, false)
	draw_set_transform(Vector2.ZERO)
	# D-057 / D-135 / D-136: the hero's role cue lives inside the hero card now; the hidden
	# _role_tags entry stays only as the animated arrows' endpoint (D-059).
	var role := role_of(unit)
	if not role.is_empty():
		_role_tag(role, r.position.x + 6.0, r.position.y - 6.0, false)
		_role_tags[-1]["unit"] = unit
		_role_tags[-1]["side"] = "hero"
		_role_tags[-1]["hidden"] = true
		# Arrows stop at the top edge of the log, above this hero, so they never cross its text.
		_role_tags[-1]["anchor"] = Vector2(r.get_center().x, BATTLE_LOG_RECT.position.y - 2.0)
	if mode == "target" and battle.target_side == "player":
		hitboxes.append({"rect": r, "key": "player-target:" + str(who)})
	elif mode == "react":
		hitboxes.append({"rect": r, "key": "reactor:" + str(who)})


## Indicadores adaptativos de status (StatusIcons: gravura monocromática + tags escuras progressivas).
## `anchor_x` é a borda direita (herói) ou o centro (inimigo); `top` o y da caixa.
const STATUS_ICON_BOX := 11.0
const STATUS_TAG_H := 11.0
const STATUS_ICON_GAP := 2.0
const STATUS_ICON_INSET := 4.5   # quanto entra no cartão do herói (sobram 6.5 px abaixo da borda, 1.5 px acima da base da tela)
const STATUS_TAG_PX := 6
const STATUS_TAG_FILL := Color(10 / 255.0, 4 / 255.0, 7 / 255.0, 0.96)
const STATUS_TAG_BORDER := Color(240 / 255.0, 225 / 255.0, 228 / 255.0, 0.50)


func status_icon_row_rect(count: int, anchor_x: float, top: float, centered: bool) -> Rect2:
	var w := float(count) * STATUS_ICON_BOX + float(maxi(0, count - 1)) * STATUS_ICON_GAP
	var x := anchor_x - w * 0.5 if centered else anchor_x - w
	return Rect2(x, top, w, STATUS_TAG_H)


func _status_tag_width(icon: Dictionary, density: int) -> float:
	if density == StatusIcons.Density.ICON:
		return STATUS_ICON_BOX
	var txt := StatusIcons.text_for(icon, density)
	var pad := 14.5 if density == StatusIcons.Density.FULL else 13.0
	return ceilf(pad + _width(txt, STATUS_TAG_PX, true))


func _status_icon_row(unit: BattleUnit, anchor_x: float, top: float, max_w: float, centered: bool) -> void:
	var icons := StatusIcons.of(unit)
	if icons.is_empty():
		return
	var plan := StatusIcons.layout(icons, max_w, _status_tag_width, STATUS_ICON_GAP, STATUS_ICON_BOX)
	var density: int = int(plan.density)
	var shown: Array = plan.shown
	var widths: Array = plan.widths
	var more: int = int(plan.more)
	var total_w: float = float(plan.total_w)
	var x := anchor_x - total_w * 0.5 if centered else anchor_x - total_w
	for i in shown.size():
		var w: float = float(widths[i])
		_draw_status_badge(Rect2(x, top, w, STATUS_TAG_H), shown[i], density)
		x += w + STATUS_ICON_GAP
	if more > 0:
		_draw_status_more(Rect2(x, top, STATUS_ICON_BOX, STATUS_TAG_H), more)


func _draw_status_badge(r: Rect2, icon: Dictionary, density: int) -> void:
	var kind := int(icon.kind)
	var accent: Color = StatusIcons.ACCENTS.get(kind, StatusIcons.MORE_ACCENT)
	var text_ink: Color = StatusIcons.TEXT_INKS.get(kind, StatusIcons.MORE_TEXT)
	draw_rect(r, STATUS_TAG_FILL)
	draw_rect(Rect2(r.position + Vector2(0.5, 0.5), r.size - Vector2.ONE), STATUS_TAG_BORDER, false, 1.0)
	if density == StatusIcons.Density.ICON:
		# Modo mais compacto: só a gravura monocromática + filete sutil de 1 px na base
		draw_rect(Rect2(r.position.x + 1.0, r.end.y - 2.0, r.size.x - 2.0, 1.0), accent)
		_draw_status_glyph(String(icon.id), Rect2(r.position.x + 1.0, r.position.y + 0.5, r.size.x - 2.0, r.size.y - 2.0))
		var ct := int(icon.get("count", 0))
		if ct > 1:
			var ct_str := str(ct)
			var cw := _width(ct_str, 5, true)
			draw_rect(Rect2(r.end.x - cw - 1.5, r.end.y - 5.5, cw + 1.5, 5.5), STATUS_TAG_FILL)
			_str(ct_str, r.end.x - cw - 0.5, r.end.y - 0.5, Color("f7f3ed"), 5, true)
		return
	# Modos FULL e SHORT: filete fino esquerdo + gravura + rótulo legível
	draw_rect(Rect2(r.position.x + 1.0, r.position.y + 1.0, 1.5, r.size.y - 2.0), accent)
	_draw_status_glyph(String(icon.id), Rect2(r.position.x + 2.8, r.position.y + 1.0, 8.0, r.size.y - 2.0))
	var txt := StatusIcons.text_for(icon, density)
	var tx := r.position.x + (11.8 if density == StatusIcons.Density.FULL else 11.2)
	_str(txt, tx, r.end.y - 2.8, text_ink, STATUS_TAG_PX, true)


func _draw_status_more(r: Rect2, more: int) -> void:
	draw_rect(r, STATUS_TAG_FILL)
	draw_rect(Rect2(r.position + Vector2(0.5, 0.5), r.size - Vector2.ONE), Color(STATUS_TAG_BORDER, 0.38), false, 1.0)
	var lbl := "+%d" % more
	var tw := _width(lbl, 5, true)
	_str(lbl, r.position.x + (r.size.x - tw) * 0.5, r.end.y - 2.8, StatusIcons.MORE_TEXT, 5, true)


## Gravuras monocromáticas minimalistas desenhadas em espaço lógico (escala 1.5x na tela).
func _draw_status_glyph(id: String, box: Rect2) -> void:
	var c := box.get_center()
	var s := minf(box.size.x, box.size.y)
	var ink := StatusIcons.GLYPH_INK
	match id:
		"bleed":
			draw_colored_polygon(PackedVector2Array([
				Vector2(c.x, box.position.y + 1.0),
				Vector2(c.x + s * 0.30, c.y + s * 0.08),
				Vector2(c.x + s * 0.22, box.end.y - 1.5),
				Vector2(c.x, box.end.y - 0.8),
				Vector2(c.x - s * 0.22, box.end.y - 1.5),
				Vector2(c.x - s * 0.30, c.y + s * 0.08),
			]), ink)
		"burn":
			# Chama assimétrica com língua principal e base cheia (evita silhueta de folha)
			draw_colored_polygon(PackedVector2Array([
				Vector2(c.x + 0.4, box.position.y + 0.7),
				Vector2(c.x + 2.6, c.y - 0.2),
				Vector2(c.x + 2.2, box.end.y - 1.4),
				Vector2(c.x, box.end.y - 0.7),
				Vector2(c.x - 2.3, box.end.y - 1.5),
				Vector2(c.x - 2.6, c.y + 0.3),
				Vector2(c.x - 1.5, c.y - 1.6),
				Vector2(c.x - 0.5, c.y - 0.2),
			]), ink)
			draw_colored_polygon(PackedVector2Array([
				Vector2(c.x + 0.2, c.y + 0.2),
				Vector2(c.x + 1.1, box.end.y - 1.7),
				Vector2(c.x, box.end.y - 1.2),
				Vector2(c.x - 1.0, box.end.y - 1.7),
			]), STATUS_TAG_FILL)
		"blind":
			var pts := PackedVector2Array([
				Vector2(box.position.x + 1.0, c.y),
				Vector2(c.x, box.position.y + 2.0),
				Vector2(box.end.x - 1.0, c.y),
				Vector2(c.x, box.end.y - 2.0),
				Vector2(box.position.x + 1.0, c.y),
			])
			draw_polyline(pts, ink, 0.9)
			draw_circle(c, 1.0, ink)
			draw_line(Vector2(box.position.x + 1.4, box.end.y - 1.4), Vector2(box.end.x - 1.4, box.position.y + 1.4), ink, 1.0)
		"sleep":
			draw_arc(c, s * 0.34, 0.6, PI * 1.65, 8, ink, 1.1)
			draw_arc(c + Vector2(1.2, -0.6), s * 0.24, 0.8, PI * 1.55, 6, STATUS_TAG_FILL, 1.2)
		"trapped":
			draw_rect(Rect2(c.x - 2.6, c.y - 2.6, 5.2, 5.2), ink, false, 0.9)
			draw_line(Vector2(c.x - 2.6, c.y - 2.6), Vector2(c.x + 2.6, c.y + 2.6), ink, 0.85)
			draw_line(Vector2(c.x + 2.6, c.y - 2.6), Vector2(c.x - 2.6, c.y + 2.6), ink, 0.85)
		"paralyzed":
			draw_polyline(PackedVector2Array([
				Vector2(c.x + 1.2, box.position.y + 1.0),
				Vector2(c.x - 1.6, c.y),
				Vector2(c.x + 1.4, c.y),
				Vector2(c.x - 1.2, box.end.y - 1.0),
			]), ink, 1.05)
		"chaki":
			var tw := _width("ח", 6, true)
			_str("ח", c.x - tw * 0.5, box.end.y - 1.5, ink, 6, true)
		"gods_message":
			var tw := _width("ד", 6, true)
			_str("ד", c.x - tw * 0.5, box.end.y - 1.5, ink, 6, true)
		"mark":
			draw_circle(c, s * 0.30, ink, false, 0.9)
			draw_line(Vector2(c.x, box.position.y + 1.0), Vector2(c.x, box.end.y - 1.0), ink, 0.8)
			draw_line(Vector2(box.position.x + 1.0, c.y), Vector2(box.end.x - 1.0, c.y), ink, 0.8)
		"shield":
			# Haganah (הֲגָנָה): glifo hebraico ה para diferenciar claramente de DEF+ (escudo)
			var tw := _width("ה", 7, true)
			_str("ה", c.x - tw * 0.5, box.end.y - 1.2, ink, 7, true)
		"atk_up", "weaken":
			draw_line(Vector2(box.position.x + 1.8, box.end.y - 1.8), Vector2(box.end.x - 1.5, box.position.y + 1.5), ink, 1.05)
			draw_line(Vector2(box.position.x + 2.0, box.end.y - 3.6), Vector2(box.position.x + 3.8, box.end.y - 1.8), ink, 0.9)
			_draw_glyph_arrow(box, id == "atk_up")
		"def_up", "break":
			draw_polyline(PackedVector2Array([
				Vector2(c.x - 2.0, box.position.y + 2.0),
				Vector2(c.x + 2.6, box.position.y + 2.0),
				Vector2(c.x + 2.6, c.y + 0.8),
				Vector2(c.x + 0.3, box.end.y - 1.4),
				Vector2(c.x - 2.0, c.y + 0.8),
				Vector2(c.x - 2.0, box.position.y + 2.0),
			]), ink, 0.9)
			_draw_glyph_arrow(box, id == "def_up")
		"mef_up", "weaken_mef":
			draw_polyline(PackedVector2Array([
				Vector2(c.x + 0.4, box.position.y + 1.4),
				Vector2(box.end.x - 1.2, c.y),
				Vector2(c.x + 0.4, box.end.y - 1.4),
				Vector2(box.position.x + 2.0, c.y),
				Vector2(c.x + 0.4, box.position.y + 1.4),
			]), ink, 0.9)
			_draw_glyph_arrow(box, id == "mef_up")
		"mak_up", "weaken_mak":
			draw_line(Vector2(c.x + 0.4, box.position.y + 1.4), Vector2(c.x + 0.4, box.end.y - 1.4), ink, 0.95)
			draw_line(Vector2(box.position.x + 1.8, c.y), Vector2(box.end.x - 1.0, c.y), ink, 0.95)
			_draw_glyph_arrow(box, id == "mak_up")
		"agi_up", "high_speed":
			draw_polyline(PackedVector2Array([Vector2(c.x - 2.4, c.y - 2.2), Vector2(c.x - 0.2, c.y), Vector2(c.x - 2.4, c.y + 2.2)]), ink, 0.95)
			draw_polyline(PackedVector2Array([Vector2(c.x + 0.2, c.y - 2.2), Vector2(c.x + 2.4, c.y), Vector2(c.x + 0.2, c.y + 2.2)]), ink, 0.95)
		"sp_up":
			draw_circle(c + Vector2(0.5, 0.2), s * 0.26, ink, false, 0.9)
			_draw_glyph_arrow(box, true)
		"chill":
			# Cristal de gelo (6 pontas) + seta vermelha
			draw_line(Vector2(c.x + 0.4, box.position.y + 1.4), Vector2(c.x + 0.4, box.end.y - 1.4), ink, 0.85)
			draw_line(Vector2(c.x - 2.0, c.y - 1.4), Vector2(c.x + 2.8, c.y + 1.4), ink, 0.85)
			draw_line(Vector2(c.x - 2.0, c.y + 1.4), Vector2(c.x + 2.8, c.y - 1.4), ink, 0.85)
			_draw_glyph_arrow(box, false)
		"snare":
			# Armadilha/laço fechado + seta vermelha
			draw_polyline(PackedVector2Array([
				Vector2(c.x - 1.8, box.position.y + 2.0),
				Vector2(c.x + 0.5, c.y + 0.4),
				Vector2(c.x + 2.8, box.position.y + 2.0),
			]), ink, 0.95)
			draw_line(Vector2(c.x - 2.0, box.end.y - 1.8), Vector2(c.x + 2.8, box.end.y - 1.8), ink, 0.95)
			_draw_glyph_arrow(box, false)
		"slow":
			# Ampulheta fechada (dois triângulos opostos) + seta vermelha
			draw_polyline(PackedVector2Array([
				Vector2(c.x - 1.8, box.position.y + 1.5),
				Vector2(c.x + 2.6, box.position.y + 1.5),
				Vector2(c.x + 0.4, c.y),
				Vector2(c.x - 1.8, box.position.y + 1.5),
			]), ink, 0.85)
			draw_polyline(PackedVector2Array([
				Vector2(c.x + 0.4, c.y),
				Vector2(c.x + 2.6, box.end.y - 1.5),
				Vector2(c.x - 1.8, box.end.y - 1.5),
				Vector2(c.x + 0.4, c.y),
			]), ink, 0.85)
			_draw_glyph_arrow(box, false)
		"gevurah":
			draw_polyline(PackedVector2Array([Vector2(c.x - 2.4, c.y + 0.5), Vector2(c.x, c.y - 2.2), Vector2(c.x + 2.4, c.y + 0.5)]), ink, 0.95)
			draw_polyline(PackedVector2Array([Vector2(c.x - 2.4, c.y + 2.8), Vector2(c.x, c.y + 0.2), Vector2(c.x + 2.4, c.y + 2.8)]), ink, 0.95)
		"taunt":
			draw_line(Vector2(c.x, box.position.y + 1.2), Vector2(c.x, c.y + 1.4), ink, 1.2)
			draw_circle(Vector2(c.x, box.end.y - 1.6), 0.75, ink)
		"zohar":
			draw_polyline(PackedVector2Array([
				Vector2(c.x, box.position.y + 1.2), Vector2(box.end.x - 1.2, c.y),
				Vector2(c.x, box.end.y - 1.2), Vector2(box.position.x + 1.2, c.y), Vector2(c.x, box.position.y + 1.2),
			]), ink, 0.9)
			draw_circle(c, 0.9, ink)
		"regen":
			draw_line(Vector2(c.x, box.position.y + 1.5), Vector2(c.x, box.end.y - 1.5), ink, 1.1)
			draw_line(Vector2(box.position.x + 1.5, c.y), Vector2(box.end.x - 1.5, c.y), ink, 1.1)
		"sturdy":
			# D-139 STURDY: escudo hexagonal de pedra com fissura central
			draw_polyline(PackedVector2Array([
				Vector2(c.x, box.position.y + 1.2),
				Vector2(box.end.x - 1.5, c.y - 1.4),
				Vector2(box.end.x - 1.8, c.y + 1.5),
				Vector2(c.x, box.end.y - 1.2),
				Vector2(box.position.x + 1.8, c.y + 1.5),
				Vector2(box.position.x + 1.5, c.y - 1.4),
				Vector2(c.x, box.position.y + 1.2),
			]), ink, 0.95)
			draw_polyline(PackedVector2Array([
				Vector2(c.x, box.position.y + 2.6),
				Vector2(c.x + 0.8, c.y),
				Vector2(c.x - 0.6, box.end.y - 2.4),
			]), ink, 0.8)
		_:
			draw_circle(c, 1.6, ink)


func _draw_glyph_arrow(box: Rect2, is_up: bool) -> void:
	if is_up:
		var tip := Vector2(box.position.x + 2.1, box.position.y + 0.9)
		draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(1.8, 2.2), tip + Vector2(-1.8, 2.2)]), StatusIcons.UP_INK)
	else:
		var tip := Vector2(box.position.x + 2.1, box.end.y - 0.9)
		draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(1.8, -2.2), tip + Vector2(-1.8, -2.2)]), StatusIcons.DOWN_INK)


## Small bar of a hero window: dark track with a light border, filled by `share`.
func _bar(r: Rect2, share: float, fill: Color, alpha: float) -> void:
	draw_rect(r, Color(0, 0, 0, 0.55 * alpha))
	var inner := r.grow(-1)
	draw_rect(Rect2(inner.position, Vector2(inner.size.x * clampf(share, 0.0, 1.0), inner.size.y)), Color(fill, alpha))
	draw_rect(Rect2(r.position + Vector2(0.5, 0.5), r.size - Vector2.ONE), Color(1, 1, 1, 0.25 * alpha), false, 1)


## The hero whose menu is open (arrow before the name), or null.
func _choosing_unit() -> BattleUnit:
	if mode == "react": return battle.reaction_actor
	if mode in ["plan", "command", "target", "skill", "pray", "en_extra", "item"]:
		return battle.reaction_actor if battle.in_reaction else battle.active_actor
	return null


## D-132: true for the hero whose card is darkened (another hero is choosing).
func card_dimmed(unit: BattleUnit) -> bool:
	var chooser := _choosing_unit()
	return chooser != null and chooser.is_player and unit != chooser


## D-132: the active hero's border pulses in the turn queue's green, 1.5 s there and back.
func active_border(t: float) -> Color:
	var swing := absf(fmod(t / (ACTIVE_PULSE_PERIOD * 0.5), 2.0) - 1.0)
	return Color(GREEN_TEXT, lerpf(0.3, 1.0, _bezier(swing, 0.42, 0, 0.58, 1)))


func _panel_highlighted(unit: BattleUnit, who: int) -> bool:
	match mode:
		"react": return unit == battle.reaction_actor
	return false


func _menu_rows() -> Array[String]:
	var rows: Array[String] = []
	if mode == "react": rows.assign(["REACT", "DENY"])
	elif mode == "plan": rows.assign(plan_options)
	elif mode in ["command", "target", "skill", "pray", "item"]: rows.assign(command_options)
	elif mode == "en_extra": rows.assign(["EXTRA EN  < %d >" % battle.en_extra])
	return rows


## Option 13: the plan, command and reaction menus are a 3-column grid in the command
## window; long lists (skills, prayers, extra EN) use one column and the window grows
## upwards from the same bottom edge.
func menu_columns() -> int:
	return COMMAND_COLUMNS


func menu_rect(count: int) -> Rect2:
	if count <= 0:
		return Rect2()
	var r := COMMAND_RECT
	var columns := menu_columns()
	var rows := ceili(float(count) / columns)
	var height := rows * COMMAND_ROW + 6.0
	# Creator 2026-11-26: short menus stay compact; long labels (skills, prayers, items) keep the wide window.
	if mode in ["plan", "command", "react", "target"]:
		return Rect2(r.position.x, r.position.y - height, COMMAND_NARROW_WIDTH, height)
	return Rect2(r.position.x, r.end.y - height, r.size.x, height)


func menu_cell(i: int, count: int) -> Rect2:
	var w := menu_rect(count)
	var columns := menu_columns()
	var inner := w.grow(-2)
	var cell_w := inner.size.x / columns
	return Rect2(inner.position.x + (i % columns) * cell_w, inner.position.y + (i / columns) * COMMAND_ROW, cell_w, COMMAND_ROW)


func _menu() -> void:
	var rows := _menu_rows()
	# D-136 (creator 2026-11-27): hide the command window when no menu is open (no empty 9 px strip above the log).
	if rows.is_empty():
		return
	var w := menu_rect(rows.size())
	_window(w, CARD_FILL, WINDOW_BORDER)
	var current := react_index if mode == "react" else (plan_index if mode == "plan" else (0 if mode == "en_extra" else command_index))
	for i in rows.size():
		var cell := menu_cell(i, rows.size())
		var shift := 0.0
		var press_bg := 0.0
		if i == _press_row and _press_kind == "confirm" and _press_age < 0.34:
			shift = _keyframes(_press_age, 0.34, [0.0, 0.25, 0.6, 1.0], [0.0, 1.0, 2.0, 0.0], 4)
			press_bg = _keyframes(_press_age, 0.34, [0.0, 0.25, 0.6, 1.0], [0.0, 0.14, 0.08, 0.0], 4)
		elif i == _press_row and _press_kind == "reject" and _press_age < 0.30:
			shift = _keyframes(_press_age, 0.30, [0.0, 0.25, 0.75, 1.0], [0.0, -3.0, 3.0, 0.0], 4)
		var selected := i == current
		if selected:
			draw_rect(cell, Color(1, 1, 1, 0.16))
		if press_bg > 0:
			draw_rect(cell, Color(0, 0, 0, press_bg))
		var baseline := cell.position.y + COMMAND_ROW - 3.5
		if selected:
			_str("›", cell.position.x + 0.5 + shift, baseline, Color.WHITE, COMMAND_PX, true)
		# Creator 2026-11-23: skills the unit cannot pay now are dimmed.
		# D-104: so is ABSORB in the plan without 2 free acts.
		var ink := Color(1, 1, 1, 0.35) if (mode == "skill" and battle.skill_disabled.has(i)) \
			or (mode == "plan" and battle.plan_row_disabled(i)) else Color.WHITE
		var label := rows[i]
		# Rótulo centrado na célula; a seta de seleção fica na borda esquerda.
		_str(label, cell.get_center().x + shift, baseline, ink,
				_fit_px(label, COMMAND_PX, maxf(8.0, cell.size.x - MENU_TEXT_X - 1.0), selected),
				selected, HORIZONTAL_ALIGNMENT_CENTER)
		var key_prefix := "live-react-row:" if mode == "react" else ("live-plan:" if mode == "plan" else ("live-skill:" if mode == "skill" else ("live-pray:" if mode == "pray" else ("live-item:" if mode == "item" else ("live-en:" if mode == "en_extra" else "live-command:")))))
		hitboxes.append({"rect": cell, "key": key_prefix + str(i)})


## Arrow keys in the 3-column grid: left/right step one cell, up/down one row.
func _grid_step(index: int, count: int, keycode: int) -> int:
	if count <= 0: return 0
	var columns := menu_columns()
	match keycode:
		KEY_LEFT: return posmod(index - 1, count)
		KEY_RIGHT: return posmod(index + 1, count)
		KEY_UP: return posmod(index - columns, count) if columns > 1 else posmod(index - 1, count)
		KEY_DOWN: return posmod(index + columns, count) if columns > 1 else posmod(index + 1, count)
	return index


# ---------------------------------------------------------------- input

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		var point := get_local_mouse_position()
		# O painel de recompensa da absorção vive numa CanvasLayer acima do HUD:
		# testar as opções antes dos hitboxes evita que um clique seja engolido.
		if mode == "absorb_choice" and battle.has_method("absorb_option_at"):
			var option: int = battle.absorb_option_at(point)
			if option >= 0:
				battle.submit_absorb_choice(option)
			return
		for hit in hitboxes:
			if not hit.rect.has_point(point): continue
			var key: String = hit.key
			if key.begins_with("live-command:") and mode == "command":
				command_index = int(key.split(":")[1])
				battle.submit_command(command_index)
			elif key.begins_with("live-plan:") and mode == "plan":
				battle.submit_plan(int(key.split(":")[1]))
			elif key.begins_with("live-pray:") and mode == "pray":
				command_index = int(key.split(":")[1])
				battle.prayer.submit(command_index)
			elif key.begins_with("live-skill:") and mode == "skill":
				command_index = int(key.split(":")[1])
				battle.submit_skill(command_index)
			elif key.begins_with("live-item:") and mode == "item":
				command_index = int(key.split(":")[1])
				if battle.has_method("submit_item"):
					battle.submit_item(command_index)
			elif key.begins_with("live-en:") and mode == "en_extra":
				battle.confirm_en_extra()
			elif key.begins_with("target:") and mode == "target":
				battle.submit_target(int(key.split(":")[1]))
			elif key.begins_with("player-target:") and mode == "target":
				battle.submit_target(int(key.split(":")[1]))
			elif key.begins_with("reactor:"):
				battle.select_reactor(int(key.split(":")[1]))
			elif key.begins_with("live-react-row:"):
				react_index = int(key.split(":")[1])
				battle.answer_reaction(react_index == 0)
			elif key == "live-confirm":
				battle.handle_confirm()
			else:
				continue
			break
	elif event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if event.keycode in [KEY_Z, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			battle.handle_confirm()
		elif event.keycode in [KEY_X, KEY_ESCAPE]:
			if mode == "plan":
				battle.exec_plan()
			else:
				battle.handle_back()
		elif mode in ["party", "offer"] and battle.has_method("overlay_key"):
			# D-111 (Survival): the PARTY panel and the join offer read their own arrows.
			battle.overlay_key(event.keycode)
		elif mode == "absorb_choice" and event.keycode in [KEY_LEFT, KEY_UP]:
			if battle.has_method("move_absorb_cursor"):
				battle.move_absorb_cursor(-1)
		elif mode == "absorb_choice" and event.keycode in [KEY_RIGHT, KEY_DOWN]:
			if battle.has_method("move_absorb_cursor"):
				battle.move_absorb_cursor(1)
		elif mode == "plan" and event.keycode == KEY_BACKSPACE:
			battle.undo_plan()
		elif mode == "plan" and event.keycode in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
			plan_index = _grid_step(plan_index, plan_options.size(), event.keycode)
		elif mode == "react" and event.keycode in [KEY_UP, KEY_DOWN]:
			react_index = 1 - react_index
		elif mode == "react" and event.keycode in [KEY_TAB, KEY_LEFT, KEY_RIGHT]:
			for i in players.size():
				var next := (actor + i + 1) % players.size()
				# D-111: skip heroes that cannot react (a Survival ally in AUTO never reacts).
				if players[next].is_alive() and players[next].acts_available > 0 						and battle.eligible_reactors().has(players[next]):
					battle.select_reactor(next)
					break
		elif mode == "command" and event.keycode in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
			command_index = _grid_step(command_index, command_options.size(), event.keycode)
		elif mode in ["skill", "pray", "item"] and event.keycode in [KEY_UP, KEY_DOWN]:
			command_index = posmod(command_index + (1 if event.keycode == KEY_DOWN else -1), command_options.size())
		elif mode == "en_extra" and event.keycode in [KEY_LEFT, KEY_RIGHT]:
			battle.adjust_en_extra(1 if event.keycode == KEY_RIGHT else -1)
		elif mode == "target" and event.keycode in [KEY_LEFT, KEY_RIGHT]:
			var units: Array[BattleUnit] = battle.target_units()
			for i in units.size():
				target = posmod(target + (1 if event.keycode == KEY_RIGHT else -1), units.size())
				if units[target].is_alive(): break
	queue_redraw()


func unit_role(unit: BattleUnit) -> String:
	# Diagnostics only: the HTML layout shows roles through panel borders and rails.
	if mode in ["command", "turn", "target", "result"]: return ""
	if unit == battle.action_attacker: return "ATTACKER"
	if unit == battle.action_defender: return "TARGET"
	return ""
