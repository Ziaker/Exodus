extends Control
## RGSS animation player: original 192px cells, transforms, blend modes and timings.
## Silent visual effects only: no sound loading or audio playback.
## Presentation only. Never changes battle resources or combat outcomes.

## Enemies are black silhouettes (exodus_feedback_lab.html): the ghost flashes from black.
const FLASH_SHADER := "shader_type canvas_item; uniform vec4 flash_color : source_color = vec4(1.0); uniform float flash_mix = 0.0; void fragment(){vec4 c = texture(TEXTURE, UV) * COLOR; COLOR = vec4(mix(vec3(0.0), flash_color.rgb, flash_mix), c.a);}"
## RPG Maker XP RPG::Sprite#whiten: color (255,255,255,128), alpha -10 per frame, 16 frames at 40 fps.
const WHITEN_FRAMES := 16
const WHITEN_FPS := 40.0

var battle: Control
var library: Dictionary
var effects: Array[Dictionary] = []
var screen_flashes: Array[Dictionary] = []
var textures: Dictionary = {}
var history: Array[String] = []
var played_cells := 0
var applied_flashes := 0
var damage_layer: Control = null
## Labels whose impact animation already ended; each lives as long as that animation did.
var numbers: Array[Dictionary] = []

## Numbers live on their own node above containers and sprites, so they are
## never hidden by the RGXP cells or the silhouette ghost.
class DamageLayer extends Control:
	var fx: Control

	func _draw() -> void:
		if fx == null or fx.battle == null or fx.battle.hud == null:
			return
		var font: Font = fx.battle.hud.font
		if font == null:
			return
		# MISS/DODGE have no impact animation and show at once; every other label
		# waits in fx.numbers until its hit animation has ended.
		var shown: Array[Dictionary] = []
		for effect in fx.effects:
			if effect.kind in fx.IMMEDIATE_LABELS: shown.append(effect)
		shown.append_array(fx.numbers)
		for effect in shown:
			if effect.has("lines"):
				_draw_lines(font, effect)
				continue
			var r: Rect2 = fx.number_rect(effect)
			var label: String = fx.label_for(effect.kind, effect.amount)
			if label.is_empty():
				continue
			var size: int = 30 if label.begins_with("-") or label.begins_with("+") else 20
			var pos := r.get_center() + Vector2(-label.length() * (size * 0.29),
				-minf(34, effect.age * 34) - 10)
			pos.y = clampf(pos.y, r.position.y + 16, r.end.y - size)
			if effect.unit != null and effect.unit.is_player:
				# Creator 2026-11-22: just above the hero's card; its bottom touches the card.
				pos.y = r.end.y - fx.HERO_NUMBER_GAP
			var alpha: float = fx.number_alpha(effect.age, effect.duration)
			if alpha <= 0.0:
				continue
			for offset in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
				draw_string(font, pos + offset, label, HORIZONTAL_ALIGNMENT_LEFT, -1,
					size, Color(0, 0, 0, 0.95 * alpha))
			var ink: Color = fx.number_color(effect)
			ink.a *= alpha
			draw_string(font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, ink)

	## Label with custom lines, rect and ink (label_override): lines centred in the
	## rect, rising like the other numbers, same outline and fade.
	func _draw_lines(font: Font, effect: Dictionary) -> void:
		var alpha: float = fx.number_alpha(effect.age, effect.duration)
		if alpha <= 0.0: return
		var r: Rect2 = effect.label_rect
		var lines: Array = effect.lines
		var size := 20
		var line_h := size + 4
		var top: float = r.get_center().y - lines.size() * line_h * 0.5 - minf(34, effect.age * 34)
		var ink: Color = effect.ink
		for i in lines.size():
			var text := String(lines[i])
			if text.is_empty(): continue
			var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			var pos := Vector2(r.get_center().x - w * 0.5, top + (i + 1) * line_h)
			for offset in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
				draw_string(font, pos + offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.95 * alpha))
			draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(ink, ink.a * alpha))


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(544, 416)
	z_index = 3
	damage_layer = DamageLayer.new()
	damage_layer.fx = self
	damage_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_layer.z_index = 100
	add_child(damage_layer)
	library = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/smt_combat_fx.json"))
	assert(not library.is_empty(), "Extract local SMT FX data before running")
	for profile in library.profiles.values():
		for sheet in profile.sheets:
			if not String(sheet).is_empty() and not textures.has(sheet):
				textures[sheet] = load("res://assets/graphics/animations/" + sheet + ".png")


## Replaces the label of unit's latest effect: custom text lines, drawn centred in rect
## with ink (creator 2026-11-23: green ABSORBED + gain where the enemy stood).
func label_override(unit: BattleUnit, lines: Array, rect: Rect2, ink: Color) -> void:
	for i in range(effects.size() - 1, -1, -1):
		if effects[i].unit == unit:
			effects[i].lines = lines
			effects[i].label_rect = rect
			effects[i].ink = ink
			return


func count_kind(kind: String) -> int:
	return history.count(kind)


func has_target_sprite(unit: BattleUnit) -> bool:
	for effect in effects:
		if effect.unit == unit and effect.ghost != null: return true
	return false


func is_busy() -> bool:
	if not numbers.is_empty(): return true
	for effect in effects:
		if effect.kind not in ["ANNOUNCE", "ATTACK", "ABSORB", "WHITEN"]: return true
	return false


func stop_cues() -> void:
	for i in range(effects.size() - 1, -1, -1):
		if effects[i].kind in ["ANNOUNCE", "ATTACK"]:
			effects[i].container.queue_free()
			effects.remove_at(i)


func _unit_rect(unit: BattleUnit) -> Rect2:
	var index: int = battle.hud.players.find(unit)
	if index >= 0: return battle.hud.STATUS_RECTS[index]
	index = battle.hud.opponents.find(unit)
	return battle.hud.enemy_sprite_rect(index)


## Creator decision (2026-11-22): numbers on a hero sit just above that hero's
## card (status panel), in the strip between the stage and the card, never over
## FALLEN/ACT/HP. Baseline 2 px above the card top.
const HERO_NUMBER_GAP := 2.0
## Labels without an impact animation; all others appear only after it ends
## (creator 2026-11-22: a number must never show before the hit effect is over).
const IMMEDIATE_LABELS := ["MISS", "DODGE"]


## Creator 2026-11-22: a number for a lethal hit is painted #ff3b3b.
const NUMBER_INK := Color("fff3d0")
const LETHAL_INK := Color("ff3b3b")
## D-048 RAAM / RAAM_BLOCK: the approved thunder (pray_fx.gd) is the impact; only the number here.
const LETHAL_KINDS := ["HIT", "CRITICAL", "BLOCK", "RAAM", "RAAM_BLOCK"]


## Creator 2026-11-22: every number stays opaque for the first half of its life
## and loses opacity linearly over the second half.
static func number_alpha(age: float, duration: float) -> float:
	var half := maxf(0.001, duration * 0.5)
	if age <= half: return 1.0
	return clampf(1.0 - (age - half) / half, 0.0, 1.0)


static func number_color(effect: Dictionary) -> Color:
	var lethal: bool = effect.kind in LETHAL_KINDS and int(effect.amount) > 0 and bool(effect.get("dying", false))
	return LETHAL_INK if lethal else NUMBER_INK


static func label_for(kind: String, amount: int) -> String:
	match kind:
		"HIT", "CRITICAL": return "-%d" % amount
		"BLOCK": return "BLOCK -%d" % amount
		"MISS", "DODGE": return kind
		"HEAL": return "+%d HP" % amount
		"REST": return "+%d EN" % amount
		"ABSORBED": return "ABSORBED"
		"BURN", "RAAM": return "-%d" % amount
		"RAAM_BLOCK": return "BLOCK -%d" % amount
		"BUFF": return "ATK UP"
	return ""


func number_rect(effect: Dictionary) -> Rect2:
	var r: Rect2 = effect.target_rect
	if effect.unit != null and effect.unit.is_player:
		var top: float = battle.hud.STAGE_RECT.end.y
		return Rect2(r.position.x, top, r.size.x, r.position.y - top)
	return r


func play(kind: String, unit: BattleUnit, amount: int = 0, source: BattleUnit = null) -> void:
	if unit == null: return
	history.append(kind)
	var profile_name := "target"
	match kind:
		"HIT", "CRITICAL", "BLOCK": profile_name = "bite" if battle.hud.opponents.find(source) == 1 else "claw"
		"ABSORB": profile_name = "absorb"
		"HEAL", "REST", "ABSORBED", "BUFF": profile_name = "heal_flash"
	var profile: Dictionary = library.profiles[profile_name]
	if kind in ["MISS", "DODGE", "WHITEN", "BURN", "RAAM", "RAAM_BLOCK"]:
		# No impact cells, hurt flashes or hit sounds for a non-contact result.
		profile = {"frames": [[], [], [], [], [], [], [], [], []], "sheets": ["", ""], "timings": []}
	var target_rect := _unit_rect(unit)
	var clip_rect := target_rect if unit.is_player else target_rect.grow(30).intersection(battle.hud.STAGE_RECT)
	var container := Control.new()
	container.position = clip_rect.position
	container.size = clip_rect.size
	container.clip_contents = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	var cell_sprites: Array[Sprite2D] = []
	for i in 16:
		var sprite := Sprite2D.new()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.hide()
		container.add_child(sprite)
		cell_sprites.append(sprite)
	var ghost: Sprite2D = null
	if not unit.is_player:
		var index: int = battle.hud.opponents.find(unit)
		var silhouette: Texture2D = battle.hud.silhouettes[index % battle.hud.silhouettes.size()]
		ghost = Sprite2D.new()
		ghost.texture = silhouette
		ghost.centered = false
		ghost.position = target_rect.position - clip_rect.position
		ghost.scale = target_rect.size / silhouette.get_size()
		ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var shader := Shader.new()
		shader.code = FLASH_SHADER
		var material := ShaderMaterial.new()
		material.shader = shader
		ghost.material = material
		container.add_child(ghost)
		container.move_child(ghost, 0)
	var effect := {"kind": kind, "unit": unit, "amount": amount, "age": 0.0, "duration": profile.frames.size() / float(library.fps), "profile": profile, "container": container, "sprites": cell_sprites, "target_rect": target_rect, "clip_rect": clip_rect, "last_frame": -1, "flash_left": 0.0, "flash_duration": 1.0, "flash_color": Color.WHITE, "ghost": ghost, "dying": not unit.is_alive(), "fit": minf(1.0, target_rect.size.y / 190.0)}
	if kind == "WHITEN":
		effect.duration = WHITEN_FRAMES / WHITEN_FPS
	effects.append(effect)
	_update_effect(effect, 0.0)
	queue_redraw()


func _process(delta: float) -> void:
	for i in range(effects.size() - 1, -1, -1):
		var effect := effects[i]
		effect.age += delta
		if effect.age >= effect.duration:
			effect.container.queue_free()
			effects.remove_at(i)
			if effect.kind not in IMMEDIATE_LABELS and not label_for(effect.kind, effect.amount).is_empty():
				var number := {"kind": effect.kind, "amount": effect.amount, "unit": effect.unit,
					"target_rect": effect.target_rect, "age": 0.0, "duration": effect.duration,
					"dying": effect.dying}
				for key in ["lines", "label_rect", "ink"]:
					if effect.has(key): number[key] = effect[key]
				numbers.append(number)
		else: _update_effect(effect, delta)
	for i in range(numbers.size() - 1, -1, -1):
		numbers[i].age += delta
		if numbers[i].age >= numbers[i].duration: numbers.remove_at(i)
	for i in range(screen_flashes.size() - 1, -1, -1):
		screen_flashes[i].left -= delta
		if screen_flashes[i].left <= 0: screen_flashes.remove_at(i)
	queue_redraw()
	if damage_layer != null:
		damage_layer.queue_redraw()


func _update_effect(effect: Dictionary, delta: float) -> void:
	var frame_index := mini(int(effect.age * library.fps), effect.profile.frames.size() - 1)
	effect.flash_left = maxf(0, effect.flash_left - delta)
	if frame_index != effect.last_frame:
		for timing in effect.profile.timings:
			if timing.frame <= effect.last_frame or timing.frame > frame_index: continue
			var color := Color(timing.color[0] / 255.0, timing.color[1] / 255.0, timing.color[2] / 255.0, timing.color[3] / 255.0)
			var duration: float = timing.duration / float(library.fps)
			if int(timing.scope) == 1:
				effect.flash_color = color
				effect.flash_left = duration
				effect.flash_duration = duration
				applied_flashes += 1
			elif int(timing.scope) == 2:
				# Original viewport flash restricted to artwork; the HUD/log stay legible.
				screen_flashes.append({"color": color, "left": duration, "duration": duration})
				applied_flashes += 1
		var cells: Array = effect.profile.frames[frame_index]
		for i in effect.sprites.size():
			var sprite: Sprite2D = effect.sprites[i]
			if i >= cells.size():
				sprite.hide()
				continue
			var cell: Array = cells[i]
			var pattern := int(cell[0])
			var sheet: String = effect.profile.sheets[0 if pattern < 100 else 1]
			if sheet.is_empty() or not textures.has(sheet):
				sprite.hide()
				continue
			var tile := pattern % 100
			var atlas := AtlasTexture.new()
			atlas.atlas = textures[sheet]
			atlas.region = Rect2((tile % 5) * 192, (tile / 5) * 192, 192, 192)
			sprite.texture = atlas
			sprite.position = effect.target_rect.get_center() - effect.clip_rect.position + Vector2(cell[1], cell[2]) * effect.fit
			sprite.scale = Vector2.ONE * (float(cell[3]) / 100.0) * effect.fit
			sprite.rotation_degrees = -float(cell[4])
			sprite.flip_h = bool(cell[5])
			sprite.modulate.a = float(cell[6]) / 255.0
			var material := CanvasItemMaterial.new()
			material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD if int(cell[7]) == 1 else (CanvasItemMaterial.BLEND_MODE_SUB if int(cell[7]) == 2 else CanvasItemMaterial.BLEND_MODE_MIX)
			sprite.material = material
			sprite.show()
			played_cells += 1
		effect.last_frame = frame_index
	var intensity: float = effect.flash_color.a * effect.flash_left / maxf(0.001, effect.flash_duration)
	if effect.kind == "WHITEN":
		effect.flash_color = Color.WHITE
		intensity = whiten_alpha(effect.age)
	if effect.ghost != null:
		var ghost: Sprite2D = effect.ghost
		ghost.material.set_shader_parameter("flash_color", effect.flash_color)
		ghost.material.set_shader_parameter("flash_mix", intensity)
		# Opaque silhouette while flashing (RMXP Sprite#color blends over the sprite itself).
		ghost.modulate.a = clampf((effect.duration - effect.age) / 0.3, 0, 1) if effect.dying else (1.0 if intensity > 0.0 else 0.0)


## Displayed whiten alpha for an age in seconds: 128, 118, ... clamped at 0.
static func whiten_alpha(age: float) -> float:
	var frame := int(age * WHITEN_FPS)
	if frame >= WHITEN_FRAMES: return 0.0
	return maxf(0.0, 128.0 - 10.0 * frame) / 255.0


func _draw() -> void:
	for flash in screen_flashes:
		var color: Color = flash.color
		color.a *= flash.left / maxf(0.001, flash.duration)
		draw_rect(battle.hud.STAGE_RECT, color)
	for effect in effects:
		var r: Rect2 = effect.target_rect
		if effect.unit.is_player and effect.flash_left > 0:
			var color: Color = effect.flash_color
			color.a *= effect.flash_left / maxf(0.001, effect.flash_duration)
			draw_rect(r, color)
		# Labels are drawn by damage_layer, above all sprites and containers.
