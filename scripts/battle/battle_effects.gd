extends Control
## RGSS animation player: original 192px cells, transforms, blend modes and timings.
## Silent visual effects only: no sound loading or audio playback.
## Presentation only. Never changes battle resources or combat outcomes.

const FLASH_SHADER := "shader_type canvas_item; uniform vec4 flash_color : source_color = vec4(1.0); uniform float flash_mix = 0.0; void fragment(){vec4 c = texture(TEXTURE, UV) * COLOR; COLOR = vec4(mix(c.rgb, flash_color.rgb, flash_mix), c.a);}"

var battle: Control
var library: Dictionary
var effects: Array[Dictionary] = []
var screen_flashes: Array[Dictionary] = []
var textures: Dictionary = {}
var history: Array[String] = []
var played_cells := 0
var applied_flashes := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(544, 416)
	z_index = 3
	library = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/smt_combat_fx.json"))
	assert(not library.is_empty(), "Extract local SMT FX data before running")
	for profile in library.profiles.values():
		for sheet in profile.sheets:
			if not String(sheet).is_empty() and not textures.has(sheet):
				textures[sheet] = load("res://assets/graphics/animations/" + sheet + ".png")


func count_kind(kind: String) -> int:
	return history.count(kind)


func has_target_sprite(unit: BattleUnit) -> bool:
	for effect in effects:
		if effect.unit == unit and effect.ghost != null: return true
	return false


func is_busy() -> bool:
	for effect in effects:
		if effect.kind not in ["ANNOUNCE", "ATTACK", "ABSORB"]: return true
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
	return battle.hud._enemy_art_rect(168.0 + index * 208.0, battle.hud.battler_regions[index % 2])


func play(kind: String, unit: BattleUnit, amount: int = 0, source: BattleUnit = null) -> void:
	if unit == null: return
	history.append(kind)
	var profile_name := "target"
	match kind:
		"HIT", "CRITICAL", "BLOCK": profile_name = "bite" if battle.hud.opponents.find(source) == 1 else "claw"
		"ABSORB": profile_name = "absorb"
		"HEAL", "REST", "ABSORBED": profile_name = "heal_flash"
	var profile: Dictionary = library.profiles[profile_name]
	if kind in ["MISS", "DODGE"]:
		# No impact cells, hurt flashes or hit sounds for a non-contact result.
		profile = {"frames": [[], [], [], [], [], [], [], [], []], "sheets": ["", ""], "timings": []}
	var target_rect := _unit_rect(unit)
	var clip_rect := target_rect if unit.is_player else target_rect.grow(30).intersection(battle.hud.BACKGROUND_RECT)
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
		var atlas := AtlasTexture.new()
		atlas.atlas = battle.hud.battler_textures[index % 2]
		atlas.region = battle.hud.battler_regions[index % 2]
		ghost = Sprite2D.new()
		ghost.texture = atlas
		ghost.centered = false
		ghost.position = target_rect.position - clip_rect.position
		ghost.scale = target_rect.size / atlas.region.size
		ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var shader := Shader.new()
		shader.code = FLASH_SHADER
		var material := ShaderMaterial.new()
		material.shader = shader
		ghost.material = material
		container.add_child(ghost)
		container.move_child(ghost, 0)
	var effect := {"kind": kind, "unit": unit, "amount": amount, "age": 0.0, "duration": profile.frames.size() / float(library.fps), "profile": profile, "container": container, "sprites": cell_sprites, "target_rect": target_rect, "clip_rect": clip_rect, "last_frame": -1, "flash_left": 0.0, "flash_duration": 1.0, "flash_color": Color.WHITE, "ghost": ghost, "dying": not unit.is_alive(), "fit": minf(1.0, target_rect.size.y / 190.0)}
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
		else: _update_effect(effect, delta)
	for i in range(screen_flashes.size() - 1, -1, -1):
		screen_flashes[i].left -= delta
		if screen_flashes[i].left <= 0: screen_flashes.remove_at(i)
	queue_redraw()


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
	if effect.ghost != null:
		var ghost: Sprite2D = effect.ghost
		ghost.material.set_shader_parameter("flash_color", effect.flash_color)
		ghost.material.set_shader_parameter("flash_mix", intensity)
		ghost.modulate.a = clampf((effect.duration - effect.age) / 0.3, 0, 1) if effect.dying else intensity


func _draw() -> void:
	for flash in screen_flashes:
		var color: Color = flash.color
		color.a *= flash.left / maxf(0.001, flash.duration)
		draw_rect(battle.hud.BACKGROUND_RECT, color)
	for effect in effects:
		var r: Rect2 = effect.target_rect
		if effect.unit.is_player and effect.flash_left > 0:
			var color: Color = effect.flash_color
			color.a *= effect.flash_left / maxf(0.001, effect.flash_duration)
			draw_rect(r, color)
		var label := ""
		match effect.kind:
			"HIT", "CRITICAL": label = "-%d" % effect.amount
			"BLOCK": label = "BLOCK -%d" % effect.amount
			"MISS", "DODGE": label = effect.kind
			"HEAL": label = "+%d HP" % effect.amount
			"REST": label = "+%d EN" % effect.amount
			"ABSORBED": label = "ABSORBED"
		if label.is_empty(): continue
		var font: Font = battle.hud.font
		var pos := r.get_center() + Vector2(-label.length() * 4, -minf(16, effect.age * 18))
		pos.y = clampf(pos.y, r.position.y + 14, r.end.y - 2)
		draw_string(font, pos + Vector2.ONE, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.BLACK)
		draw_string(font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ece9dc"))
