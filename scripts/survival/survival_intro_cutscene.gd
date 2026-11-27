extends "res://prototypes/survival-intro/survival_intro.gd"
## Cutscene de entrada do Survival no jogo (criador 2026-11-26/27: opção D — letras hebraicas,
## Kazfiel amarelo de letras, fala que adormece, letras se espalham e o Fallen acorda
## piscando na dungeon). Toca quando o Survival começa uma run nova pelo título.
## Z mostra a fala inteira e depois pula para a próxima. No fim troca para o mundo do
## Survival, que faz a piscada de retorno por cima do mapa real (SurvivalWakeBlink).

## Marca lida pelo mundo do Survival para tocar a piscada ao abrir.
const WAKE_META := "exodus_survival_wake_blink"

var _leaving := false


func _ready() -> void:
	super._ready()
	option = "d"
	show_label = false
	restart()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo): return
	if event.keycode in [KEY_Z, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		skip_text()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if frozen or _leaving: return
	t += delta
	# Quando a tela fica preta depois de as letras se espalharem, entra o mapa real.
	if t >= float(_timing().dungeon):
		_leaving = true
		Engine.set_meta(WAKE_META, true)
		get_tree().change_scene_to_file(SurvivalData.WORLD_SCENE)
		return
	queue_redraw()
