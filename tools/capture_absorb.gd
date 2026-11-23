extends Node
## Capture of the D-052 absorption VFX in the real BattlePlayable: Fallen picks ABSORB on
## FOE A and mashes 10 presses inside the 2 s window. FOE A starts at 20 SP so the 10
## presses drain it (guaranteed success, D-051); every roll misses so the whole mash plays.

class CaptureBattle extends "res://scripts/battle/playable_controller.gd":
	func _absorb_roll() -> float: return 100.0

var battle: Control
var t := 0.0
var step := 0
var presses := 0


func _ready() -> void:
	ProgressStore.save_path_override = "user://capture_absorb_progress.json"
	ProgressStore.clear()
	battle = CaptureBattle.new()
	# Same layout as scenes/battle/BattlePlayable.tscn (full-rect root), so the HUD has
	# the real 544x416 size instead of the zero size of a bare .new() Control.
	battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(battle)


func _process(delta: float) -> void:
	t += delta
	match step:
		0:
			if t > 0.8 and battle.hud.mode in ["command", "plan"]:
				battle.state.units[2].current_sp = 20
				battle._refresh_all()
				battle.submit_command(3)  # ABSORB (plan mode: plans it and runs EXEC)
				step = 1; t = 0.0
		1:
			if t > 0.6 and battle.hud.mode == "target":
				battle.submit_target(0)
				step = 2; t = 0.0
		2:
			if battle._mash_active and presses < 10 and t > 0.05 + presses * 0.18:
				battle.handle_confirm()
				presses += 1
			if presses >= 10 and not battle._mash_active:
				step = 3; t = 0.0
		3:
			# Gain choice (if any) after the break; confirm the first option.
			if battle.hud.mode == "command" and t > 0.6:
				battle.handle_confirm()
				step = 4; t = 0.0
			elif battle.state.units[2].absorbed and battle.hud.mode != "command":
				step = 4; t = 0.0
