extends Node
## Battle background prototype: the real playable battle with the stage painted by
## one of three shader options behind the HUD. Keys 1/2/3/4 switch A/B/C/D.
## For captures pass a user arg: `-- --bg=a|b|c|d`.

const OPTIONS := {
	"a": "res://prototypes/battle-bg/bg_a_wave.gdshader",
	"b": "res://prototypes/battle-bg/bg_b_interlace.gdshader",
	"c": "res://prototypes/battle-bg/bg_c_plasma.gdshader",
	"d": "res://prototypes/battle-bg/bg_d_plasma_sky.gdshader",
}

var battle: Control
var stage: ColorRect


func _ready() -> void:
	ProgressStore.save_path_override = "user://bgproto_progress.json"
	ProgressStore.clear()
	battle = load("res://scenes/battle/BattlePlayable.tscn").instantiate()
	add_child(battle)
	# The game now builds the approved stage (D) and the 15% smaller enemies itself;
	# this prototype only swaps the stage shader to compare the four options.
	stage = battle.stage
	var choice := "a"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--bg="):
			choice = arg.trim_prefix("--bg=")
	use(choice)


func use(choice: String) -> void:
	if not OPTIONS.has(choice):
		return
	(stage.material as ShaderMaterial).shader = load(OPTIONS[choice])
	battle.hud.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: use("a")
			KEY_2: use("b")
			KEY_3: use("c")
			KEY_4: use("d")
