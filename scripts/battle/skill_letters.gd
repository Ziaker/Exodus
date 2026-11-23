extends Node2D
## Hebrew-letter effects for the first-fight skills (creator 2026-11-23: "letter effects for
## the other new skills, on the player and on the enemy"), in the language of the approved
## absorption letters (D-052) and Ra'am thunder (D-048):
##   Lunge      - no letters (creator 2026-11-23: normal/physical attacks need no letters);
##                lunge_hit() is kept but no longer called;
##   Heat wave  - a wave of orange letters rolls across the targets' row, and flames of letters
##                rise from every target hit; each burn tick sends embers up;
##   Bleedbuff  - red letters drip from the user and are pulled back into it, then a red ring;
##   Energy Eat - cyan letters spiral into the user, then a soft ring.
## On a hero the effect plays on the status card; on an enemy, on its art. Colours, sizes and
## timings are proposals for the creator to judge.

const ALPHABET := "אבגדהוזחטיכלמנסעפצקרשת"
const OUTLINE := Color(0.08, 0.04, 0.02)
const SLASH_INK := Color(1, 1, 1)
const FIRE_INK := Color("ff9a3d")
const FIRE_HOT := Color("ffe08a")
const BLOOD_INK := Color("ff4a5a")
const ENERGY_INK := Color("7fd4ff")

var battle: Node
var hud: Control
var font: SystemFont
var rng := RandomNumberGenerator.new()
var time := 0.0
## Letter particles: glyph, pos, vel, acc, born, life, px, ink, ink2 (fades to), spin, angle.
var parts: Array[Dictionary] = []
## Rings: center, born, life, r0, r1, ink.
var rings: Array[Dictionary] = []
## Slash lines: a, b, born, life.
var lines: Array[Dictionary] = []
var _slash_side: Dictionary = {}
var _wave_at := -99.0


func _ready() -> void:
	z_index = 99
	rng.seed = 2026
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Tahoma", "Arial", "David Libre"])
	font.font_weight = 800


func _process(delta: float) -> void:
	time += delta
	for p in parts:
		var age := time - float(p.born)
		if age < 0.0: continue
		p.vel += p.acc * delta
		p.pos += p.vel * delta
		p.angle += float(p.spin) * delta
	parts = parts.filter(func(p: Dictionary) -> bool: return time - float(p.born) < float(p.life))
	rings = rings.filter(func(r: Dictionary) -> bool: return time - float(r.born) < float(r.life))
	lines = lines.filter(func(l: Dictionary) -> bool: return time - float(l.born) < float(l.life))
	queue_redraw()


func is_busy() -> bool:
	return not parts.is_empty() or not rings.is_empty() or not lines.is_empty()


func _rect(unit: BattleUnit) -> Rect2:
	var i: int = hud.players.find(unit)
	if i >= 0:
		return hud.STATUS_RECTS[i]
	i = hud.opponents.find(unit)
	return hud.enemy_sprite_rect(i) if i >= 0 else Rect2()


func _letter() -> String:
	return ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)]


func _add(pos: Vector2, vel: Vector2, life: float, px: int, ink: Color, ink2: Color, delay := 0.0,
		acc := Vector2.ZERO, spin := 0.0) -> void:
	parts.append({"glyph": _letter(), "pos": pos, "vel": vel, "acc": acc, "born": time + delay,
		"life": life + delay, "delay": delay, "px": px, "ink": ink, "ink2": ink2, "spin": spin,
		"angle": rng.randf_range(-0.3, 0.3)})


# ---------------------------------------------------------------- skills

## Lunge: one hit = one slash of letters across the target; hits alternate direction.
func lunge_hit(target: BattleUnit) -> void:
	var r := _rect(target)
	if r.size == Vector2.ZERO: return
	var side: int = _slash_side.get(target.id, 0)
	_slash_side[target.id] = 1 - side
	var inset := r.grow(-minf(r.size.x, r.size.y) * 0.18)
	var a := inset.position if side == 0 else Vector2(inset.end.x, inset.position.y)
	var b := inset.end if side == 0 else Vector2(inset.position.x, inset.end.y)
	lines.append({"a": a, "b": b, "born": time, "life": 0.16})
	var n := int(a.distance_to(b) / 9.0)
	var normal := (b - a).orthogonal().normalized()
	for i in n:
		var k := float(i) / maxf(1.0, n - 1)
		var push := normal * rng.randf_range(40, 90) * (1.0 if i % 2 == 0 else -1.0)
		_add(a.lerp(b, k), push + (b - a).normalized() * 30.0, 0.55, 18, SLASH_INK, Color(SLASH_INK, 0.0),
			k * 0.1, Vector2(0, 160), rng.randf_range(-6, 6))


## Heat wave: a rolling wave of letters across the row, then flames on the target.
func heat_hit(caster: BattleUnit, target: BattleUnit) -> void:
	if time - _wave_at > 0.6:
		_wave_at = time
		_wave(caster, target)
	_flames(target, 16, 0.85)


func _wave(caster: BattleUnit, target: BattleUnit) -> void:
	var r := _rect(target)
	var on_heroes: bool = target.is_player
	var y := r.get_center().y if not on_heroes else r.position.y - 6.0
	var from_left: bool = caster.is_player or on_heroes
	var x0 := 0.0 if from_left else 544.0
	var dir := 1.0 if from_left else -1.0
	for i in 34:
		var lane := float(i % 3) - 1.0
		_add(Vector2(x0 - dir * rng.randf_range(0, 60), y + lane * 14.0 + rng.randf_range(-4, 4)),
			Vector2(dir * rng.randf_range(520, 640), rng.randf_range(-12, 12)), 1.0, 14 + int(rng.randi_range(0, 4)),
			FIRE_HOT, Color(FIRE_INK, 0.0), float(i) * 0.012, Vector2(0, -40), rng.randf_range(-2, 2))


func _flames(target: BattleUnit, count: int, life: float) -> void:
	var r := _rect(target)
	if r.size == Vector2.ZERO: return
	var base := r.end.y - (6.0 if target.is_player else r.size.y * 0.12)
	for i in count:
		_add(Vector2(rng.randf_range(r.position.x + r.size.x * 0.15, r.end.x - r.size.x * 0.15), base),
			Vector2(rng.randf_range(-14, 14), -rng.randf_range(50, 110)), life, 13 + rng.randi_range(0, 5),
			FIRE_HOT, Color(Color("ff3b3b"), 0.0), rng.randf_range(0.0, 0.35), Vector2(0, -30), rng.randf_range(-3, 3))


## Burn tick: a few embers rise from the burning unit.
func burn(target: BattleUnit) -> void:
	_flames(target, 6, 0.7)


## Bleedbuff: blood letters drip from the user and are pulled back in; a red ring.
## Energy Eat: energy letters spiral into the user; a soft ring.
func self_skill(unit: BattleUnit, kind: String) -> void:
	var r := _rect(unit)
	if r.size == Vector2.ZERO: return
	var c := r.get_center()
	# Elliptic radii follow the target's shape, so on a status card nothing leaves the card.
	var rad := Vector2(r.size.x * 0.5, r.size.y * 0.5)
	if kind == "buff":
		for i in 20:
			var x := rng.randf_range(r.position.x + r.size.x * 0.1, r.end.x - r.size.x * 0.1)
			var y := rng.randf_range(r.position.y + 4.0, c.y)
			# Drip down, then the pull back to the centre (spring towards c).
			_add(Vector2(x, y), Vector2(0, rng.randf_range(20, 45)), 0.9, 17, BLOOD_INK, Color(BLOOD_INK, 0.0),
				rng.randf_range(0.0, 0.2), Vector2(0, 220), 0.0)
		for i in 12:
			var a := TAU * i / 12.0
			var from := c + Vector2(cos(a) * rad.x, sin(a) * rad.y) * 0.9
			_add(from, (c - from) / 0.45, 0.45, 16, Color(BLOOD_INK, 0.2), BLOOD_INK, 0.45, Vector2.ZERO, rng.randf_range(-4, 4))
		rings.append({"center": c, "born": time + 0.9, "life": 0.4, "r0": 0.1, "r1": 0.95, "rad": rad, "ink": BLOOD_INK})
	else:
		for i in 24:
			var a := TAU * i / 24.0 + rng.randf_range(-0.2, 0.2)
			var from := c + Vector2(cos(a) * rad.x, sin(a) * rad.y) * rng.randf_range(0.75, 0.95)
			var to_c := (c - from)
			# Tangential + radial velocity: a spiral that ends at the centre.
			_add(from, to_c / 0.7 + to_c.orthogonal().normalized() * 30.0, 0.7, 17, Color(ENERGY_INK, 0.45), ENERGY_INK,
				float(i) * 0.02, Vector2.ZERO, rng.randf_range(-5, 5))
		rings.append({"center": c, "born": time + 0.75, "life": 0.45, "r0": 0.95, "r1": 0.1, "rad": rad, "ink": ENERGY_INK})


# ---------------------------------------------------------------- draw

func _draw() -> void:
	for l in lines:
		var k := (time - float(l.born)) / float(l.life)
		var tip: Vector2 = l.a.lerp(l.b, clampf(k * 1.6, 0.0, 1.0))
		draw_line(l.a, tip, Color(1, 1, 1, 1.0 - k), 3.0)
	for r in rings:
		var k := (time - float(r.born)) / float(r.life)
		if k < 0.0: continue
		var rad: Vector2 = r.rad * lerpf(float(r.r0), float(r.r1), k)
		var pts := PackedVector2Array()
		for i in 41:
			var a := TAU * i / 40.0
			pts.append(r.center + Vector2(cos(a) * rad.x, sin(a) * rad.y))
		draw_polyline(pts, Color(r.ink, 1.0 - k), 3.0)
	for p in parts:
		var age := time - float(p.born)
		if age < 0.0: continue
		var k := age / maxf(0.001, float(p.life) - float(p.delay))
		var ink: Color = (p.ink as Color).lerp(p.ink2, k * k)
		if ink.a <= 0.01: continue
		draw_set_transform(p.pos, float(p.angle))
		draw_string_outline(font, Vector2.ZERO, p.glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, int(p.px), 3, Color(OUTLINE, ink.a))
		draw_string(font, Vector2.ZERO, p.glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, int(p.px), ink)
	draw_set_transform(Vector2.ZERO)
