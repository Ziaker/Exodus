extends Control
## Piscada de quem acorda (criador 2026-11-26: "a piscada pro retorno"), por cima do mapa
## real do Survival depois da cutscene de entrada: o olho abre um pouco, fecha de novo e
## abre de vez. Mesma curva e mesma pálpebra do protótipo (prototypes/survival-intro).

const SCREEN := Vector2(816, 624)
const DURATION := 2.9
const AMEIXA := Color("1c0e11")

var age := 0.0


func _ready() -> void:
	size = SCREEN
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	age += delta
	if age >= DURATION:
		queue_free()
		return
	queue_redraw()


static func _ease(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


static func openness(a: float) -> float:
	if a < 0.4: return 0.0
	if a < 1.2: return 0.5 * _ease((a - 0.4) / 0.8)
	if a < 1.5: return 0.5 - 0.42 * _ease((a - 1.2) / 0.3)
	return minf(1.0, 0.08 + 0.92 * _ease((a - 1.5) / 1.3))


func _draw() -> void:
	var open := openness(age)
	if open >= 1.0: return
	draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(AMEIXA, (1.0 - open) * 0.45))
	var half := SCREEN.y * 0.5
	var k := 1.6
	var reach := (half + 4.0) / sqrt(1.0 - 1.0 / (k * k))
	var strips := 102
	var sw := SCREEN.x / strips
	for i in strips:
		var u := ((i + 0.5) * sw - SCREEN.x * 0.5) / (SCREEN.x * 0.5 * k)
		var edge := maxf(0.0, half - reach * open * sqrt(1.0 - u * u))
		if edge > 0.0:
			draw_rect(Rect2(i * sw - 0.5, 0, sw + 1.0, edge), Color.BLACK)
			draw_rect(Rect2(i * sw - 0.5, SCREEN.y - edge, sw + 1.0, edge), Color.BLACK)
