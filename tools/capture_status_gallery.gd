extends SceneTree
## Captura a galeria completa das 27 gravuras/tags de StatusIcons usando o render real do PlayableHUD
## (816x624 = escala 1.5x do espaço lógico 544x416), exibindo cada status em ICON, SHORT e FULL.
## Uso: Godot --path . --resolution 816x624 -s tools/capture_status_gallery.gd
const SANDBOX := preload("res://tests/progress_sandbox.gd")
const OUT := "res://captures/status_icons/galeria_27_gravuras.png"


class GalleryCanvas extends "res://scripts/battle/playable_hud.gd":
	var entries: Array[Dictionary] = []

	func _ready() -> void:
		ui_font = SystemFont.new()
		ui_font.font_names = PackedStringArray(["Tahoma", "Arial", "sans-serif"])
		ui_bold = SystemFont.new()
		ui_bold.font_names = ui_font.font_names
		ui_bold.font_weight = 700
		var symbols := SystemFont.new()
		symbols.font_names = PackedStringArray(["Segoe UI Symbol", "DejaVu Sans", "Noto Sans Symbols 2"])
		ui_font.fallbacks = [symbols]
		ui_bold.fallbacks = [symbols]

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, SCREEN), Color("160d10"))
		_str("STATUS ICONS — 28 GRAVURAS (ICON · SHORT · FULL)", 14.0, 18.0, Color("f7f3ed"), 11, true)
		_str("Fundo escuro do cartao (#0a0407) · gravura monocromatica osso (#ede3d8) · filete sutil", 14.0, 29.0, Color("b9a995"), 7, false)
		var col_w := 174.0
		var start_x := 14.0
		var start_y := 40.0
		var row_h := 36.0
		for idx in entries.size():
			var e: Dictionary = entries[idx]
			var col := idx / 10
			var row := idx % 10
			var x := start_x + float(col) * col_w
			var y := start_y + float(row) * row_h
			# Fundo sutil de célula para separar cada status
			draw_rect(Rect2(x - 3.0, y - 3.0, col_w - 8.0, row_h - 4.0), Color(10 / 255.0, 4 / 255.0, 7 / 255.0, 0.55))
			draw_rect(Rect2(x - 2.5, y - 2.5, col_w - 9.0, row_h - 5.0), Color(240 / 255.0, 225 / 255.0, 228 / 255.0, 0.16), false, 1.0)
			_str(String(e.id), x, y + 7.0, Color("cfc7e2"), 6, false)
			var by := y + 12.0
			# 1) ICON
			_draw_status_badge(Rect2(x, by, STATUS_ICON_BOX, STATUS_TAG_H), e, StatusIcons.Density.ICON)
			# 2) SHORT
			var sw := _status_tag_width(e, StatusIcons.Density.SHORT)
			_draw_status_badge(Rect2(x + STATUS_ICON_BOX + 5.0, by, sw, STATUS_TAG_H), e, StatusIcons.Density.SHORT)
			# 3) FULL
			var fw := _status_tag_width(e, StatusIcons.Density.FULL)
			_draw_status_badge(Rect2(x + STATUS_ICON_BOX + 5.0 + sw + 5.0, by, fw, STATUS_TAG_H), e, StatusIcons.Density.FULL)


func _initialize() -> void:
	SANDBOX.begin()
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures/status_icons/"))
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = Vector2i(544, 416)
	# Monta uma unidade com TODOS os 27 status do catálogo StatusIcons.of()
	var u := BattleUnit.new(&"gal", "Gallery", UnitStats.new(), true)
	u.add_status(&"mark", 2)
	u.add_status(&"gods_message", 2)
	u.add_bleed(2)
	u.burns.append(3)
	u.burns.append(2)
	u.add_status(&"sleep", 2)
	u.trapped_actions = 2
	u.paralyzed_acts = 2
	u.add_status(&"blind", 2)
	u.add_status(&"chaki", 2)
	u.weaken_mef_penalty = 5
	u.weaken_mak_penalty = 3
	u.add_status(&"weaken", 2)
	u.add_status(&"chill", 2)
	u.add_status(&"snare", 2)
	u.add_status(&"break", 2)
	u.add_status(&"slow", 2)
	u.atk_stages.append({"round": 1, "owner": &"x"})
	u.mak_stages.append({"round": 1, "owner": &"x"})
	u.def_stages.append(2)
	u.mef_stages.append({"round": 1, "owner": &"x"})
	u.agi_buffs.append({"amount": 4, "round": 1})
	u.sp_buffs.append({"amount": 6, "round": 1})
	u.haganah = {"round": 1, "owner": &"x"}
	u.gevurah_bonus = 0.2
	u.add_status(&"taunt", 2)
	u.add_status(&"zohar", 2)
	u.regen_rounds = 3
	u.next_attack_high_speed = true
	var gal := GalleryCanvas.new()
	gal.entries = StatusIcons.of(u)
	print("GALLERY_ENTRIES: %d" % gal.entries.size())
	root.add_child(gal)
	gal.queue_redraw()
	for _i in 6:
		await process_frame
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT))
	quit(0)
