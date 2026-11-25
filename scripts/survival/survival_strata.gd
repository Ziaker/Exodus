class_name SurvivalStrata
extends RefCounted
## D-066/D-067/D-069/D-074: estrutura roguelike do Survival.
## 5 estratos de 7 demônios (ordenados por tier e SP), um GUARDIÃO por estrato,
## labirinto do estrato (1 = feito à mão, 2..5 = gerado pela semente), posições
## dos demônios e eventos, e o temperamento de cada demônio. Tudo puro e
## determinístico pela semente da run: testável headless.

const COUNT := 5
const PER_STRATUM := 7
const EVENTS_PER_STRATUM := 3
const START := Vector2i(12, 10)
## Demônios e eventos não nascem colados ao santuário (emboscada na saída).
const MIN_START_DISTANCE := 5
## Fração dos becos sem saída abertos em laço nos labirintos gerados.
const BRAID := 0.35

const EVENT_KINDS := ["altar", "spirit", "oracle", "merchant"]

## D-069: temperamentos. Explícitos por demônio para que cada estrato misture estilos.
const TEMPERAMENTS := {
	"pixie": "support", "jack_frost": "caster", "pyro_jack": "caster", "cerberus": "brute",
	"oni": "brute", "garuda": "hunter", "anubis": "support", "chimera": "brute",
	"andras": "hunter", "succubus": "caster", "ganesha": "brute", "vritra": "caster",
	"wyvern": "hunter", "lich": "caster", "matador": "hunter", "mara": "brute",
	"loki": "trickster", "zouchouten": "brute", "lakshmi": "support", "hel": "caster",
	"high_pixie": "support", "nekomata": "hunter", "shuten_douji": "brute",
	"phoenix": "support", "barong": "brute", "orobas": "trickster", "incubus": "caster",
	"quetzalcoatl": "caster", "leviathan": "brute", "vampire": "hunter",
	"white_rider": "hunter", "beelzebub": "trickster", "pazuzu": "trickster",
	"isis": "support", "izanami": "caster",
}
const TEMPERAMENT_LABELS := {
	"brute": "BRUTE", "caster": "CASTER", "support": "SUPPORT",
	"hunter": "HUNTER", "trickster": "TRICKSTER",
}


static func temperament(id: String) -> String:
	return String(TEMPERAMENTS.get(id, "trickster"))


static func power(demon: Dictionary) -> int:
	var total := 0
	for v in (demon.get("stats", {}) as Dictionary).values():
		total += int(v)
	return total


## Ordem fixa dos 35 por (tier, SP, id): a partição não depende da semente.
static func ranked_ids() -> Array[String]:
	var list: Array = SurvivalData.DEMONS.duplicate()
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.tier) != int(b.tier):
			return int(a.tier) < int(b.tier)
		if power(a) != power(b):
			return power(a) < power(b)
		return String(a.id) < String(b.id))
	var out: Array[String] = []
	for d in list:
		out.append(String(d.id))
	return out


static func ids_for(stratum: int) -> Array[String]:
	var ranked := ranked_ids()
	var s := clampi(stratum, 1, COUNT)
	var out: Array[String] = []
	for i in range((s - 1) * PER_STRATUM, s * PER_STRATUM):
		out.append(ranked[i])
	return out


static func stratum_of(id: String) -> int:
	var idx := ranked_ids().find(id)
	return 0 if idx < 0 else idx / PER_STRATUM + 1


## SP médio dos demônios do estrato: o SP que o Fallen deve ter ao entrar nele (D-101).
static func par_sp(stratum: int) -> int:
	var ids := ids_for(stratum)
	var total := 0
	for id in ids:
		total += power(SurvivalData.demon_by_id(id))
	return int(round(float(total) / float(maxi(1, ids.size()))))


## O mais forte do grupo guarda o estrato.
static func warden_of(stratum: int) -> String:
	var ids := ids_for(stratum)
	return ids[ids.size() - 1]


static func is_warden(id: String) -> bool:
	var s := stratum_of(id)
	return s > 0 and warden_of(s) == id


static func _rng(seed: int, stratum: int, salt: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = (absi(seed) + stratum * 7_368_787 + salt * 104_729) % 2147483647
	return rng


# ------------------------------------------------------------------ labirintos

static func maze(seed: int, stratum: int) -> Array[String]:
	if stratum <= 1:
		return SurvivalData.MAZE.duplicate()
	return generate_maze(seed, stratum)


## 25x21, backtracker nas células ímpares + laços; santuário 5x3 e início fixos.
static func generate_maze(seed: int, stratum: int) -> Array[String]:
	var h := SurvivalData.MAZE.size()
	var w := SurvivalData.MAZE[0].length()
	var g: Array = []
	for y in h:
		var row: Array = []
		row.resize(w)
		row.fill("#")
		g.append(row)
	var rng := _rng(seed, stratum, 1)
	var stack: Array[Vector2i] = [Vector2i(1, 1)]
	g[1][1] = "."
	var dirs := [Vector2i(0, -2), Vector2i(2, 0), Vector2i(0, 2), Vector2i(-2, 0)]
	while not stack.is_empty():
		var c: Vector2i = stack[stack.size() - 1]
		var open: Array[Vector2i] = []
		for d in dirs:
			var n: Vector2i = c + d
			if n.x > 0 and n.y > 0 and n.x < w - 1 and n.y < h - 1 and g[n.y][n.x] == "#":
				open.append(n)
		if open.is_empty():
			stack.pop_back()
			continue
		var n: Vector2i = open[rng.randi_range(0, open.size() - 1)]
		var mid: Vector2i = (c + n) / 2
		g[mid.y][mid.x] = "."
		g[n.y][n.x] = "."
		stack.append(n)
	# Laços: abre parte dos becos para a perseguição não virar fila indiana.
	for y in range(1, h - 1, 2):
		for x in range(1, w - 1, 2):
			var walls: Array[Vector2i] = []
			var exits := 0
			for d in dirs:
				var mid: Vector2i = Vector2i(x, y) + d / 2
				var far: Vector2i = Vector2i(x, y) + d
				if g[mid.y][mid.x] == ".":
					exits += 1
				elif far.x > 0 and far.y > 0 and far.x < w - 1 and far.y < h - 1:
					walls.append(mid)
			if exits == 1 and not walls.is_empty() and rng.randf() < BRAID:
				var pick: Vector2i = walls[rng.randi_range(0, walls.size() - 1)]
				g[pick.y][pick.x] = "."
	# Santuário: mesmo retângulo seguro e mesma célula inicial do estrato 1.
	var safe := SurvivalData.SAFE_ZONE
	for y in range(safe.position.y, safe.end.y):
		for x in range(safe.position.x, safe.end.x):
			g[y][x] = "."
	g[START.y][START.x] = "S"
	var out: Array[String] = []
	for row in g:
		out.append("".join(row))
	return out


static func is_floor(rows: Array, c: Vector2i) -> bool:
	return c.y >= 0 and c.y < rows.size() and c.x >= 0 and c.x < String(rows[c.y]).length() \
			and String(rows[c.y])[c.x] != "#"


## Distância a pé (BFS) do início a cada célula de chão.
static func distances(rows: Array, from: Vector2i = START) -> Dictionary:
	var dist := {from: 0}
	var queue: Array[Vector2i] = [from]
	var head := 0
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var n: Vector2i = c + d
			if is_floor(rows, n) and not dist.has(n):
				dist[n] = int(dist[c]) + 1
				queue.append(n)
	return dist


# ------------------------------------------------------------------ posições

## Células do estrato: o guardião no ponto mais fundo (maior distância a pé),
## os demais demônios e os eventos espalhados pela semente.
static func layout(seed: int, stratum: int) -> Dictionary:
	var rows := maze(seed, stratum)
	var dist := distances(rows)
	var keeper: Vector2i = SurvivalData.NPCS[0].cell
	var candidates: Array[Vector2i] = []
	for key in dist.keys():
		var c: Vector2i = key
		if SurvivalData.SAFE_ZONE.has_point(c) or c == keeper:
			continue
		if absi(c.x - START.x) + absi(c.y - START.y) < MIN_START_DISTANCE:
			continue
		candidates.append(c)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y if a.y != b.y else a.x < b.x)
	var ids := ids_for(stratum)
	var warden := ids[ids.size() - 1]
	var deepest := candidates[0]
	for c in candidates:
		if int(dist[c]) > int(dist[deepest]):
			deepest = c
	candidates.erase(deepest)
	var rng := _rng(seed, stratum, 2)
	for i in range(candidates.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Vector2i = candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = tmp
	var demons := {warden: deepest}
	var k := 0
	for id in ids:
		if id == warden:
			continue
		demons[id] = candidates[k]
		k += 1
	var kinds: Array = EVENT_KINDS.duplicate()
	var krng := _rng(seed, stratum, 3)
	for i in range(kinds.size() - 1, 0, -1):
		var j := krng.randi_range(0, i)
		var tmp: String = kinds[i]
		kinds[i] = kinds[j]
		kinds[j] = tmp
	var events: Array = []
	for e in EVENTS_PER_STRATUM:
		events.append({"id": "s%d_e%d" % [stratum, e], "kind": String(kinds[e % kinds.size()]),
			"cell": candidates[k]})
		k += 1
	return {"maze": rows, "demons": demons, "events": events, "warden": warden}
