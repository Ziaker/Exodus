extends CanvasLayer
## Transição de cena estilo RPG Maker, persistente entre cenas (autoload):
## flash vermelho curto -> fade preto -> troca de cena -> fade in.
## A sobreposição vive neste autoload, então não há buraco entre as duas cenas.

const FLASH_TIME := 0.08
const OUT_TIME := 0.26
const IN_TIME := 0.30
const FLASH_COLOR := Color(1.0, 0.23, 0.28)

var overlay: ColorRect
var _phase := ""
var _time := 0.0
var _target := ""
var _flash := false


func _ready() -> void:
	layer = 100
	overlay = ColorRect.new()
	overlay.name = "FadeOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	set_process(false)


func is_busy() -> bool:
	return not _phase.is_empty()


## Inicia a transição. `flash` é o lampejo vermelho do encontro no overworld.
func fade_to(path: String, flash: bool = false) -> void:
	if _phase != "" or path.is_empty():
		return
	_target = path
	_flash = flash
	_phase = "flash" if flash else "out"
	_time = 0.0
	overlay.color = Color(0, 0, 0, 0)
	set_process(true)


func _process(delta: float) -> void:
	match _phase:
		"flash":
			_time += delta
			var k: float = clampf(_time / FLASH_TIME, 0.0, 1.0)
			overlay.color = Color(FLASH_COLOR.r, FLASH_COLOR.g, FLASH_COLOR.b, sin(k * PI) * 0.82)
			if _time >= FLASH_TIME:
				_phase = "out"
				_time = 0.0
		"out":
			_time += delta
			var k: float = clampf(_time / OUT_TIME, 0.0, 1.0)
			overlay.color = Color(0, 0, 0, k)
			if _time >= OUT_TIME:
				var next := _target
				_target = ""
				_phase = "in"
				_time = 0.0
				get_tree().change_scene_to_file(next)
		"in":
			_time += delta
			var k: float = clampf(_time / IN_TIME, 0.0, 1.0)
			overlay.color = Color(0, 0, 0, 1.0 - k)
			if _time >= IN_TIME:
				_phase = ""
				overlay.color = Color(0, 0, 0, 0)
				set_process(false)
