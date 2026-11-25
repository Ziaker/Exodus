extends Node
## Exports what the HTML HUD prototypes (prototypes/combat-hud-html) draw under their HUD:
## the real stage D frame (816 x 624, HUD hidden), each enemy silhouette PNG and where the
## battle places them, plus a full frame of the current HUD for comparison.

const OUT := "res://prototypes/combat-hud-html/assets/"

class QuietBattle extends "res://scripts/battle/playable_controller.gd":
	func _enemy_counter_roll(_e: BattleUnit) -> bool: return false


func _ready() -> void:
	ProgressStore.save_path_override = "user://export_hud_proto.json"
	ProgressStore.clear()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var battle := QuietBattle.new()
	battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(battle)
	for i in 20: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(OUT + "current_hud.png")
	var hud: Control = battle.hud
	var info := {"scale": 1.5, "enemies": []}
	for i in hud.opponents.size():
		var img: Image = hud.silhouettes[i % hud.silhouettes.size()].get_image()
		img.save_png(OUT + "enemy_%d.png" % i)
		var r: Rect2 = hud.enemy_sprite_rect(i)
		info.enemies.append({"name": battle.short_name(hud.opponents[i]), "x": r.position.x, "y": r.position.y, "w": r.size.x, "h": r.size.y})
	hud.visible = false
	# The scene continues down to the bottom of the screen (the HTML draws its own HUD).
	battle.stage.size = Vector2(544, 416 - battle.stage.position.y)
	battle.stage.material.set_shader_parameter("stage_size", battle.stage.size)
	for node in [battle.rhythm, battle.counter, battle.fx]:
		if node != null: node.visible = false
	for i in 4: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(OUT + "stage.png")
	var f := FileAccess.open(OUT + "layout.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(info, "  "))
	f.close()
	print("EXPORTED ", info)
	get_tree().quit()
