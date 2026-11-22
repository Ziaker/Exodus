extends "res://prototypes/combat-ui/preview-xp.gd"
## Playable battle HUD following exodus_feedback_lab.html (544 x 416, theme "A · XP"
## readability pass): drawn red/brown backdrop, black enemy silhouettes generated from
## the local SMT battlers, line-only windows. All displayed resources come from BattleUnit.
## Creator decisions (2026-11-21): no HTML pop-up texts (the existing SMT effects stay),
## the command title is hidden when five commands are listed, the TARGET01 "SEARCH" cue
## is replaced by its four green diagonal brackets only (they also replace the white HTML
## corners), and an announcing enemy shows a red "!" (#bb3d48) to the left of its art.

const STAGE_RECT := Rect2(0, 0, 544, 298)
const FIELD_RECT := Rect2(7, 82, 530, 210)
const BATTLE_LOG_RECT := Rect2(8, 303, 528, 21)
const STATUS_RECTS := [Rect2(8, 332, 168, 77), Rect2(182, 332, 168, 77)]
const COMMAND_RECT := Rect2(356, 332, 180, 77)
const COLUMN_SIZE := Vector2(220, 206)
const SPRITE_BOX := Vector2(156, 166)
const SVG_SCALE_Y := 298.0 / 251.0

const TEXT := Color("f7f3ed")
const GREEN_TEXT := Color("81e6a8")
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
const ARROW_HEIGHT := 30.0
const ARROW_HEAD := Vector2(22.5, 15)
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

var battle: Control
var players: Array[BattleUnit] = []
var opponents: Array[BattleUnit] = []
var command_options: Array[String] = []
var command_index := 0
## D-046: linhas do plano (comandos + EXEC + UNDO) no mesmo menu desenhado.
var plan_options: Array[String] = []
var plan_index := 0
var react_index := 0
## Kept for the controller and diagnostics; only the log line is drawn (HTML has one line).
var feedback := ""
var ui_font: SystemFont
var ui_bold: SystemFont
## Solid white silhouettes (alpha mask, enclosed holes filled) cut from the SMT battlers.
var silhouettes: Array[ImageTexture] = []
var target_sheet: Texture2D
var marks: Node2D
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
var shake_unit: BattleUnit = null
var shake_age := 99.0


func _ready() -> void:
	super._ready()
	ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray(["Tahoma", "Arial", "sans-serif"])
	ui_bold = SystemFont.new()
	ui_bold.font_names = ui_font.font_names
	ui_bold.font_weight = 700
	target_sheet = load(TARGET_SHEET) as Texture2D
	marks = Node2D.new()
	marks.name = "TargetMarks"
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	marks.material = additive
	marks.draw.connect(_draw_marks)
	add_child(marks)
	for i in battler_textures.size():
		silhouettes.append(ImageTexture.create_from_image(make_silhouette(battler_textures[i].get_image().get_region(Rect2i(battler_regions[i])))))


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
	impact_left = maxf(0.0, impact_left - delta)
	shake_age += delta
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
		result["player:%d" % target] = STATUS_RECTS[target]
	var chosen: BattleUnit = null
	if battle.in_reaction: chosen = battle.reaction_defender
	elif mode in ["react", "announce"] or (mode == "timing" and battle.timing_role == "DEFEND"): chosen = battle.action_defender
	if chosen != null and players.has(chosen):
		result["player:%d" % players.find(chosen)] = STATUS_RECTS[players.find(chosen)]
	return result


func enemy_mark_rect(index: int) -> Rect2:
	var column := enemy_column(index)
	return Rect2(column.position + Vector2(24, 8), Vector2(COLUMN_SIZE.x - 48, COLUMN_SIZE.y - 30))


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
	shake_unit = unit
	shake_age = 0.0


## Horizontal shake offset for a unit's sprite or card.
func shake_offset(unit: BattleUnit) -> Vector2:
	if unit == null or unit != shake_unit or shake_age >= SHAKE_SECONDS: return Vector2.ZERO
	return Vector2(SHAKE_PX if int(shake_age * SHAKE_HZ) % 2 == 0 else -SHAKE_PX, 0)


## D-049 rails: [top = opponent (red), bottom = player (white)].
func counter_rail_rects(kind: String, index: int) -> Array[Rect2]:
	var bottom: Rect2 = defense_rail_rect(index) if kind == "panel" else attack_rail_rect(index)
	var top := Rect2(bottom.position - Vector2(0, bottom.size.y + 3), bottom.size)
	var rails: Array[Rect2] = [top, bottom]
	return rails


func announce(text: String) -> void:
	announcement_text = text
	announcement_age = 0.0
	alert_unit = null # only announce_attack() shows the red "!"


func press_command(row: int, kind: String) -> void:
	_press_row = row
	_press_kind = kind
	_press_age = 0.0


func enemy_column(index: int) -> Rect2:
	var count := maxi(1, opponents.size())
	var gap := (FIELD_RECT.size.x - count * COLUMN_SIZE.x) / (count + 1)
	var left := FIELD_RECT.position.x + gap + index * (COLUMN_SIZE.x + gap)
	return Rect2(Vector2(left, FIELD_RECT.end.y - COLUMN_SIZE.y), COLUMN_SIZE)


func enemy_sprite_rect(index: int) -> Rect2:
	# The HTML sprite box (156 x 166) at the top of the column; the SMT art keeps its
	# aspect and stands on the box floor, like the HTML silhouettes and their shadows.
	var column := enemy_column(index)
	var region: Rect2 = battler_regions[index % battler_regions.size()]
	var factor := minf(SPRITE_BOX.x / region.size.x, SPRITE_BOX.y / region.size.y)
	var art := region.size * factor
	var box := Rect2(column.position + Vector2((COLUMN_SIZE.x - SPRITE_BOX.x) * 0.5, 0), SPRITE_BOX)
	var rect := Rect2(Vector2(box.get_center().x - art.x * 0.5, box.end.y - art.y), art)
	var top := _depth_point(rect.position, rect.get_center().x)
	return Rect2(top, rect.size * enemy_depth)


## Perspective push: scale about the horizon point straight above/below `pivot_x`.
func _depth_point(p: Vector2, pivot_x: float) -> Vector2:
	var pivot := Vector2(pivot_x, enemy_horizon)
	return pivot + (p - pivot) * enemy_depth


func attack_rail_rect(index: int) -> Rect2:
	var column := enemy_column(maxi(0, index))
	return Rect2(column.position + Vector2(34, 86), Vector2(COLUMN_SIZE.x - 68, 13))


func defense_rail_rect(index: int) -> Rect2:
	var panel: Rect2 = STATUS_RECTS[clampi(index, 0, 1)]
	return Rect2(panel.position.x + 7, panel.end.y - 13, panel.size.x - 14, 10)


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


func _ellipsis(value: String, px: int, max_width: float) -> String:
	var shown := value
	while shown.length() > 1 and _width(shown, px) > max_width:
		shown = shown.left(shown.length() - 2) + "…"
	return shown


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
	if font == null or ui_font == null or battle == null: return
	hitboxes.clear()
	_backdrop()
	_header()
	_sp_window()
	var selected := _selected_enemy()
	if selected != _corner_index:
		_corner_index = selected
		_corner_age = 0.0
	for i in opponents.size():
		_enemy(0, i)
	_announcement()
	_log_line()
	for who in players.size():
		_character(who, STATUS_RECTS[who])
	_menu()
	if mode in ["timing", "counter", "absorb", "continue", "announce", "turn", "result"]:
		hitboxes.append({"rect": Rect2(0, 0, 544, 416), "key": "live-confirm"})


func _backdrop() -> void:
	if impact_left > 0.0:
		draw_rect(STAGE_RECT, Color.WHITE)
		draw_polygon(PackedVector2Array([Vector2(0, 297), Vector2(544, 297), Vector2(544, 416), Vector2(0, 416)]), PackedColorArray([Color("2a111a"), Color("2a111a"), Color("210d16"), Color("210d16")]))
		return
	if not stage_backdrop:
		# Prototype hook: a node behind the HUD paints the stage; keep only the footer.
		draw_polygon(PackedVector2Array([Vector2(0, 297), Vector2(544, 297), Vector2(544, 416), Vector2(0, 416)]), PackedColorArray([Color("2a111a"), Color("2a111a"), Color("210d16"), Color("210d16")]))
		return
	# exodus_feedback_lab.html .bg svg (viewBox 544 x 251 stretched to 298 px).
	var sky := [Color("280b14"), Color("5c1c2b"), Color("431a26")]
	var mid := 298.0 * 0.54
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(544, 0), Vector2(544, mid), Vector2(0, mid)]), PackedColorArray([sky[0], sky[0], sky[1], sky[1]]))
	draw_polygon(PackedVector2Array([Vector2(0, mid), Vector2(544, mid), Vector2(544, 298), Vector2(0, 298)]), PackedColorArray([sky[1], sky[1], sky[2], sky[2]]))
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, SVG_SCALE_Y))
	draw_circle(Vector2(426, 85), 37, Color("ae565d", 0.22))
	draw_set_transform(Vector2.ZERO)
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
	# .game::before — the command area below the battlefield.
	draw_polygon(PackedVector2Array([Vector2(0, 297), Vector2(544, 297), Vector2(544, 416), Vector2(0, 416)]), PackedColorArray([Color("2a111a"), Color("2a111a"), Color("210d16"), Color("210d16")]))


func _svg_points(spec: String) -> PackedVector2Array:
	var values := spec.split(" ", false)
	var points := PackedVector2Array()
	for i in range(0, values.size(), 2):
		points.append(Vector2(float(values[i]), float(values[i + 1]) * SVG_SCALE_Y))
	return points


func _svg_poly(spec: String, color: Color) -> void:
	draw_colored_polygon(_svg_points(spec), color)


func _header() -> void:
	# Creator 2026-11-21: no "Exodus" title; the header line carries the announcements.
	draw_line(Vector2(8, 29.5), Vector2(536, 29.5), Color(1, 1, 1, 0.32))
	_str(_round_caption(), 534, 20, TEXT, 12, true, HORIZONTAL_ALIGNMENT_RIGHT)


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
	_str("%s · %d SP" % [own.display_name, own.current_sp], 8, 51, GREEN_TEXT, 12, true)
	_str("%s · %d SP" % [battle.short_name(foe), foe.current_sp], 536, 51, RED_TEXT, 12, true, HORIZONTAL_ALIGNMENT_RIGHT)
	var share := float(own.current_sp) / maxf(1.0, own.current_sp + foe.current_sp)
	if not is_equal_approx(share, _sp_anim.to):
		var current := lerpf(_sp_anim.from, _sp_anim.to, _stepped(_sp_anim.age, 0.36, 9))
		_sp_anim = {"from": current, "to": share, "age": 0.0}
	var shown := lerpf(_sp_anim.from, _sp_anim.to, _stepped(_sp_anim.age, 0.36, 9))
	var track := Rect2(8, 59, 528, 8)
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
	if not unit.is_alive(): return
	var column := enemy_column(index)
	var art := enemy_sprite_rect(index)
	art.position += shake_offset(unit)
	var texture := silhouettes[index % silhouettes.size()]
	var region := Rect2(Vector2.ZERO, texture.get_size())
	var box := Rect2(column.position + Vector2((COLUMN_SIZE.x - SPRITE_BOX.x) * 0.5, 0), SPRITE_BOX)
	# Ground shadow from the HTML silhouettes (ellipse rx 44 ry 6 at 111/119), filled black.
	var k := SPRITE_BOX.x / 112.0
	var shadow_x := box.position.x + 55 * k
	draw_set_transform(_depth_point(Vector2(shadow_x, box.position.y + 111 * k + 8), shadow_x), 0, Vector2(1, 6.0 / 44.0))
	draw_circle(Vector2.ZERO, 44 * k * enemy_depth, Color(24 / 255.0, 17 / 255.0, 26 / 255.0, 0.45))
	draw_set_transform(_depth_point(Vector2(shadow_x, box.position.y + 111 * k), shadow_x), 0, Vector2(1, 6.0 / 44.0))
	draw_circle(Vector2.ZERO, 44 * k * enemy_depth, Color.BLACK)
	draw_set_transform(Vector2.ZERO)
	# drop-shadow(0 8px 2px rgba(24,17,26,.45)) and the silhouette (fill:#000).
	draw_texture_rect_region(texture, Rect2(art.position + Vector2(0, 8), art.size), region, Color(24 / 255.0, 17 / 255.0, 26 / 255.0, 0.45))
	draw_texture_rect_region(texture, art, region, Color.BLACK)
	var selected := _selected_enemy() == index
	if alert_visible() and alert_unit == unit:
		var t := announcement_age / 0.75
		var alpha := _ease(t / 0.23) if t < 0.23 else (1.0 if t < 0.8 else 1.0 - _ease((t - 0.8) / 0.2))
		_str("!", art.position.x - 4, art.position.y + SIGN_HEIGHT, Color(ALERT_RED, alpha), ALERT_PX, true, HORIZONTAL_ALIGNMENT_RIGHT, Color(0, 0, 0, 0.65 * alpha))
	# Creator 2026-11-21: SP arrows hide while a field announcement is on screen.
	var announcing := not announcement_text.is_empty() and announcement_age < 0.75
	if not selected and not announcing:
		var own: BattleUnit = _sp_pair()[0]
		if own != null:
			var left := art.end.x + SIGN_GAP
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
	_str(battle.short_name(unit), column.get_center().x, column.end.y - 30, Color("fffaf5"), 13, true, HORIZONTAL_ALIGNMENT_CENTER, Color("1f0e14"))
	# Creator 2026-11-22: enemy HP is never shown (no bar, no value).
	if mode == "target" and battle.target_side == "enemy":
		hitboxes.append({"rect": Rect2(column.position, Vector2(COLUMN_SIZE.x, COLUMN_SIZE.y)), "key": "target:" + str(index)})


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
	_str(announcement_text, 272, 20, Color("fff9f2", alpha), 12, true, HORIZONTAL_ALIGNMENT_CENTER, Color("14080a", alpha))


func _log_text() -> String:
	match mode:
		"turn", "react", "announce": return feedback if not feedback.is_empty() else message
		"result": return message + " " + feedback
		"absorb": return "ABSORB [Z]  Mash!  Presses: %d/%d" % [mini(battle._mash_count, BattleMath.ABSORB_MAX_PRESSES), BattleMath.ABSORB_MAX_PRESSES]
	return message


func _log_line() -> void:
	var text := _log_text()
	if text != _log_shown:
		_log_shown = text
		_log_age = 0.0
	var alpha := lerpf(0.55, 1.0, _ease(_log_age / 0.38))
	draw_line(Vector2(8, 303.5), Vector2(536, 303.5), Color(1, 1, 1, 0.38))
	draw_rect(Rect2(11, 312, 5, 5), Color("f6e7df", alpha))
	_str(_ellipsis(text, 12, 508), 23, 319, Color("f8f1ea", alpha), 12)


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
	var top := Color(1, 1, 1, 1) if highlighted or defending else Color(1, 1, 1, 0.35)
	draw_line(Vector2(r.position.x, r.position.y + 0.5), Vector2(r.end.x, r.position.y + 0.5), top)
	if defending:
		var swing := absf(fmod(time / 0.7, 2.0) - 1.0)
		var glow := lerpf(0.95, 0.38, _bezier(swing, 0.42, 0, 0.58, 1))
		draw_line(Vector2(r.position.x, r.position.y + 1.5), Vector2(r.end.x, r.position.y + 1.5), Color(1, 1, 1, glow))
	var x := r.position.x + 7
	var right := r.end.x - 7
	_str(unit.display_name, x, r.position.y + 18, Color.WHITE, 13, true)
	if not unit.is_alive():
		_str("[DOWN]", right, r.position.y + 18, Color("ede7e1"), 11, false, HORIZONTAL_ALIGNMENT_RIGHT)
	var act_w := _width("/4", 11) + _width(str(unit.acts_available), 11, true)
	if unit.is_alive():
		_str("/4", right, r.position.y + 18, Color("ede7e1"), 11, false, HORIZONTAL_ALIGNMENT_RIGHT)
		_str(str(unit.acts_available), right - _width("/4", 11), r.position.y + 18, Color.WHITE, 11, true, HORIZONTAL_ALIGNMENT_RIGHT)
		_str("ACT ", right - act_w, r.position.y + 18, Color("ede7e1"), 11, false, HORIZONTAL_ALIGNMENT_RIGHT)
	var vitals_alpha := 0.58 if defending else 1.0
	var hp_w := _str("HP ", x, r.position.y + 40, Color(TEXT, vitals_alpha), 11)
	_str("%d/%d" % [unit.current_hp, unit.stats.max_hp], x + hp_w, r.position.y + 40, Color(1, 1, 1, vitals_alpha), 11, true)
	_str("EN %d/%d" % [unit.current_en, unit.stats.max_en], right, r.position.y + 40, Color(TEXT, vitals_alpha), 11, false, HORIZONTAL_ALIGNMENT_RIGHT)
	# stat-gain: .65s steps(4) — opacity 1, .55, 1, .55 then back to 1.
	var sp_alpha: float = _keyframes(seen.sp_age, 0.65, [0.0, 0.25, 0.5, 0.7, 1.0], [1.0, 0.55, 1.0, 0.55, 1.0], 4)
	var sp_w := _str("SP ", x, r.position.y + 61, Color(GREEN_TEXT, sp_alpha), 12, true)
	_str(str(unit.current_sp), x + sp_w, r.position.y + 61, Color(GREEN_TEXT, sp_alpha), 12, true)
	for i in 4:
		var pip := Rect2(right - 52 + i * 14, r.position.y + 52, 10, 9)
		var on := i < unit.acts_available
		var earning: bool = seen.acts_age < 0.5 and i >= seen.acts_from and i < seen.acts
		if earning:
			var scale: float = _keyframes(seen.acts_age, 0.5, [0.0, 0.25, 1.0], [1.0, 1.28, 1.0], 3)
			var fill: Color = _keyframes(seen.acts_age, 0.5, [0.0, 0.25, 1.0], [Color(1, 1, 1, 0), Color.WHITE, Color("e7ddd4")], 3)
			pip = Rect2(pip.get_center() - pip.size * scale * 0.5, pip.size * scale)
			draw_rect(pip, fill)
			draw_rect(Rect2(pip.position + Vector2(0.5, 0.5), pip.size - Vector2.ONE), Color("e7ddd4"), false, 1)
		elif on:
			draw_rect(pip, Color("e7ddd4"))
		else:
			draw_rect(Rect2(pip.position + Vector2(0.5, 0.5), pip.size - Vector2.ONE), Color(1, 1, 1, 0.66), false, 1)
	# D-046: atos comprometidos no plano ficam verdes acima dos pips de ACT.
	var planned: int = battle.planned_acts_for(unit)
	if planned > 0:
		for i in mini(planned, 4):
			draw_rect(Rect2(right - 52 + i * 14, r.position.y + 49, 10, 3), Color("36aa6d"))
	draw_set_transform(Vector2.ZERO)
	if mode == "target" and battle.target_side == "player":
		hitboxes.append({"rect": r, "key": "player-target:" + str(who)})
	elif mode == "react":
		hitboxes.append({"rect": r, "key": "reactor:" + str(who)})


func _panel_highlighted(unit: BattleUnit, who: int) -> bool:
	match mode:
		"react": return unit == battle.reaction_actor
	return false


func _menu_rows() -> Array[String]:
	var rows: Array[String] = []
	if mode == "react": rows.assign(["REACT", "DENY"])
	elif mode == "plan": rows.assign(plan_options)
	elif mode in ["command", "target"]: rows.assign(command_options)
	return rows


func _menu() -> void:
	var rows := _menu_rows()
	var expanded := not rows.is_empty()
	var goal := 77.0 if expanded else 22.0
	if goal != _menu_to:
		_menu_from = _menu_height
		_menu_to = goal
		_menu_age = 0.0
	_menu_height = lerpf(_menu_from, _menu_to, _stepped(_menu_age, 0.14, 4))
	var r := COMMAND_RECT
	draw_line(Vector2(r.position.x, r.position.y + 0.5), Vector2(r.end.x, r.position.y + 0.5), Color(1, 1, 1, 0.35))
	var who: BattleUnit = null
	if not players.is_empty(): who = players[clampi(actor, 0, players.size() - 1)]
	var show_title := rows.size() < 5
	if show_title and who != null:
		_str("Command / %s" % who.display_name, r.position.x + 7, r.position.y + 17, TEXT, 12, true)
	if not expanded: return
	var visible_bottom := r.position.y + _menu_height
	var y0 := r.position.y + (3 if mode == "plan" else 5) + (16 if show_title else 0)
	# D-046: sete linhas (comandos + EXEC + UNDO) cabem na janela de 77 px com passo 10.
	var row_h := 10.0 if mode == "plan" else 14.0
	var row_px := 9 if mode == "plan" else 11
	var current := react_index if mode == "react" else (plan_index if mode == "plan" else command_index)
	for i in rows.size():
		var row := Rect2(r.position.x + 3, y0 + i * row_h, r.size.x - 6, row_h)
		if row.end.y > visible_bottom: break
		var shift := 0.0
		var press_bg := 0.0
		if i == _press_row and _press_kind == "confirm" and _press_age < 0.34:
			shift = _keyframes(_press_age, 0.34, [0.0, 0.25, 0.6, 1.0], [0.0, 1.0, 2.0, 0.0], 4)
			press_bg = _keyframes(_press_age, 0.34, [0.0, 0.25, 0.6, 1.0], [0.0, 0.14, 0.08, 0.0], 4)
		elif i == _press_row and _press_kind == "reject" and _press_age < 0.30:
			shift = _keyframes(_press_age, 0.30, [0.0, 0.25, 0.75, 1.0], [0.0, -3.0, 3.0, 0.0], 4)
		if i == current:
			draw_rect(row, Color(1, 1, 1, 0.18))
		if press_bg > 0:
			draw_rect(row, Color(0, 0, 0, press_bg))
		if i == current:
			var bob := 1.5 if fmod(time + 0.325, 1.3) >= 0.65 else 0.0
			_str("›", row.position.x + 6 + bob + shift, row.position.y + row_h - 3, Color.WHITE, row_px)
		_str(rows[i], row.position.x + 19 + shift, row.position.y + row_h - 3, Color.WHITE, row_px)
		var key_prefix := "live-react-row:" if mode == "react" else ("live-plan:" if mode == "plan" else "live-command:")
		hitboxes.append({"rect": row, "key": key_prefix + str(i)})


# ---------------------------------------------------------------- input

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		var point := get_local_mouse_position()
		for hit in hitboxes:
			if not hit.rect.has_point(point): continue
			var key: String = hit.key
			if key.begins_with("live-command:") and mode == "command":
				command_index = int(key.split(":")[1])
				battle.submit_command(command_index)
			elif key.begins_with("live-plan:") and mode == "plan":
				battle.submit_plan(int(key.split(":")[1]))
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
		elif mode == "plan" and event.keycode == KEY_BACKSPACE:
			battle.undo_plan()
		elif mode == "plan" and event.keycode in [KEY_UP, KEY_DOWN]:
			plan_index = posmod(plan_index + (1 if event.keycode == KEY_DOWN else -1), plan_options.size())
		elif mode == "react" and event.keycode in [KEY_UP, KEY_DOWN]:
			react_index = 1 - react_index
		elif mode == "react" and event.keycode in [KEY_TAB, KEY_LEFT, KEY_RIGHT]:
			for i in players.size():
				var next := (actor + i + 1) % players.size()
				if players[next].is_alive() and players[next].acts_available > 0:
					battle.select_reactor(next)
					break
		elif mode == "command" and event.keycode in [KEY_UP, KEY_DOWN]:
			command_index = posmod(command_index + (1 if event.keycode == KEY_DOWN else -1), command_options.size())
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
