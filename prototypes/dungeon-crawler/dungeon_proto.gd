extends Control
## TESTE de overworld em primeira pessoa (dungeon crawler) no estilo SMT VX The Genesis.
## Inimigos vermelhos no automapa avançam um tile por passo do jogador e iniciam o
## combate novo (BattlePlayable, com habilidades/reza/contra-ataque).
## Visual do OVERWORLD trocado em 2026-11-24: texturas/fundo gerados por
## tools/generate_dungeon_art.py, na paleta do fundo D da batalha. Os assets SMT
## continuam intactos na BATALHA — este arquivo não os lê.
##
## Decisões do criador (2026-11-23): referência SMT VX The Genesis; render 3D real no
## Godot; passo com deslize animado de 0,15 s; giro animado de 90° em 0,15 s; texturas
## do VX só neste teste (não versionadas, pasta de referência ignorada no git); layout
## igual ao VX; labirinto de teste pequeno; automapa; tremor ao bater na parede como no
## VX; só setas, sem strafe. Depois: passo reto 30% mais lento (0,214 s) e X segurado
## corre a 0,15 s; o giro continua em 0,15 s.
##
## Geometria copiada do script "3Dダンジョン" (さば缶) usado pelo VX:
##   DISPLAY 532x336 em (6, -47); parede da frente a 1 tile = 304x192 px; olho a 1/3 da
##   altura da parede; horizonte na tela em y = 177; escurecimento alpha 50 por tile.
##   Automapa: janela 128x128 em (416, 0), margem 12, célula 16 px.
##   Tremor: start_shake(3, 10, 10) com a fórmula do Game_Screen do VX.
##   Seta para baixo: meia-volta (dois giros à direita), como no VX.
##
## D-055 (criador, 2026-11-23): tela 816x624. A geometria do VX fica (parede a 1 tile =
## 304x192, olho a 1/3, escurecimento, corte); a vista 3D ganha a área extra e o
## horizonte fica no centro dela. NPCs atravessáveis (criador); de frente + Z abre a
## caixa de diálogo de 2 linhas de 20 px (criador; a D-055 pedia 3) (só nome e texto) sobre o painel de baixo e mostra a
## figura do NPC como o VX: "Mostrar Imagem" com origem no centro em (272, 170) da tela
## 544x416 (7 px acima do horizonte), aqui 1,5x (criador, 2026-11-23) e centrada na vista.
## No VX não há NPC desenhado no corredor (nenhum evento visível em 3D nos mapas). Figuras do VX (Pictures/P15 e D_Brute Onia; o criador deixou a escolha ao
## agente) só no teste. Paredes, piso e fundo do overworld são gerados; personagens e
## inimigos voltam a usar os assets SMT como placeholder, por decisão do criador.

const REF := "res://Shin Megami Tensei VX The Genesis/Shin Megami Tensei The Genesis/Graphics/"
const ART := "res://assets/generated/dungeon/"
const WALL_TEX_PATH := ART + "wall.png"
const PARALLAX_PATH := ART + "backdrop.png"
const FLOOR_TILE_PATH := ART + "floor_tile.png"
const FLOOR_SHADER := preload("res://prototypes/dungeon-crawler/dungeon_floor.gdshader")
const MIXED_FILTER := preload("res://prototypes/dungeon-crawler/dungeon_mixed_filter.gdshader")
const MIXED_PALETTE := preload("res://prototypes/dungeon-crawler/dungeon_mixed_palette.res")
const NPCS := [
	{"id": "human", "cell": Vector2i(3, 1), "picture": REF + "Pictures/P15.png", "name": "[PLACEHOLDER] HUMAN",
		"pages": ["[PLACEHOLDER] Human NPC line. Filler that only fills the two lines of the dialogue box; the real text is still to be written by the creator."]},
	{"id": "demon", "cell": Vector2i(5, 1), "picture": REF + "Pictures/D_Brute Onia.png", "name": "[PLACEHOLDER] DEMON",
		"pages": ["[PLACEHOLDER] Demon NPC line. Filler that only fills the two lines of the dialogue box; the real text is still to be written by the creator.", "[PLACEHOLDER] Second page."]},
]
## Criador 2026-11-23: figura como no VX (centrada sobre a vista), 1,5x o tamanho original
## (a mesma proporção da tela 544x416 do VX). Centro: x da vista, 7 x 1,5 px acima do horizonte.
const NPC_PICTURE_SCALE := 1.5
const NPC_PICTURE_CENTER := Vector2(408, 251.0 - 7.0 * 1.5)
## Marca do NPC no automapa (criador, 2026-11-23): o círculo do AutoMapMarker do VX
## (célula 16x16 em (0, 32)) em P&B — corpo branco, o brilho do VX em preto —, que
## aparece quando a célula do NPC entra na vista 3D (até o corte de 5,5 tiles).
const MARKER_PATH := REF + "System/AutoMapMarker.png"
const MARKER_REGION := Rect2i(0, 32, 16, 16)

## Inimigos de exploração: pontos vermelhos que avançam um tile por passo do jogador.
## Ao alcançar o jogador (ou ao serem alcançados) iniciam o combate novo.
const ENEMY_DEFS := [
	{"id": "stalker", "name": "CRIMSON STALKER", "cell": Vector2i(4, 1),
		"picture": ART + "enemy_stalker.png"},
	{"id": "hound", "name": "ASH HOUND", "cell": Vector2i(7, 3),
		"picture": ART + "enemy_hound.png"},
	{"id": "wraith", "name": "CINDER WRAITH", "cell": Vector2i(7, 7),
		"picture": ART + "enemy_wraith.png"},
]
const ENEMY_INK := Color("bb3d48")
const ENEMY_DARK := Color("5c1c2b")
## Volta ao dungeon depois de uma vitória; o motor de batalha lê este meta.
const DUNGEON_RETURN_META := &"exodus_dungeon_return_scene"
const DUNGEON_STATE_META := &"exodus_dungeon_state"
const BATTLE_SCENE := "res://scenes/battle/BattlePlayable.tscn"
const DUNGEON_SCENE := "res://prototypes/dungeon-crawler/DungeonProto.tscn"

# Passo reto: velocidade normal 30% menor que a corrida (0,15 s / 0,7 = 0,214 s) e, por
# ordem do criador (2026-11-23), mais 30% menor: 0,214 s / 0,7 = 0,306 s.
# Segurando X corre: 0,15 s, a velocidade original (criador, 2026-11-23).
const RUN_STEP_TIME := 0.15
const STEP_TIME := RUN_STEP_TIME / 0.7 / 0.7
const RUN_KEY := KEY_X
const TURN_TIME := 0.15

# Geometria (1 tile = 1 unidade). Pixels por unidade a 1 tile de distância = 304.
const PX_PER_TILE := 304.0
const WALL_HEIGHT := 192.0 / PX_PER_TILE
const EYE_HEIGHT := 64.0 / PX_PER_TILE
const SCREEN := Vector2(816, 624)
# Interface (criador, 2026-11-23): estilo do HUD de batalha, porém preto e branco; painel
# de baixo com status + nome do local; automapa no canto superior direito; moldura de
# linha fina na vista 3D. D-055: o painel de baixo mantém o tamanho (128 px) e a vista
# 3D fica com o resto da tela.
const FRAME_RECT := Rect2(6, 6, 804, 490) # moldura fina em volta da vista 3D
const LOCATION_LINE_Y := 511.5            # moldura + 15,5, como antes
const STATUS_RECTS := [Rect2(8, 540, 168, 77), Rect2(182, 540, 168, 77)] # iguais à batalha
# Horizonte no centro da vista (moldura). Largura = moldura + 12 de cada lado: a moldura
# recorta, e o tremor (até 9 px) nunca abre vão.
const VIEW_SIZE := Vector2i(828, 490)
const VIEW_POS := Vector2(-6, 6)
const PARALLAX_OVERSCAN := 12.0
const HORIZON_Y := 251.0
## D-055: caixa de diálogo sobre o painel de baixo (cobre nome do local e status).
const DIALOGUE_RECT := Rect2(6, 502, 804, 116)
const LOCATION_NAME := "[PLACEHOLDER] TEST LABYRINTH"
const INK := Color("f7f3ed") # texto claro do HUD de batalha
# O VX desenha paredes até ~5,3 tiles (front45: 59x36 px). Corte em 5,5 para nenhuma
# parede (sempre a distância inteira em vista reta) cair exatamente no plano de corte.
const FAR_TILES := 5.5
# "Visão mais distante" do VX: BG_COLOR = Color.new(10, 10, 10), na faixa chão-teto.
const BG_COLOR := Color8(10, 10, 10)
const BACKDROP_DIST := 5.45

# Automapa: tamanho, margem e célula do VX (128x128, 12, 16 px), desenhado em P&B,
# no canto superior direito por dentro da moldura.
const AUTOMAP_RECT := Rect2(676, 12, 128, 128)
const AUTOMAP_MARGIN := 12
const CELL_PX := 16

# Tremor do VX: start_shake(SHAKE_POWER, SHAKE_SPEED, SHAKE_DURATION).
const SHAKE_POWER := 3
const SHAKE_SPEED := 10
const SHAKE_DURATION := 10

enum Act { NONE, FORWARD, TURN_LEFT, TURN_RIGHT, TURN_BACK }

signal encounter_started(id: String)

## Labirinto de teste: '#' parede, '.' chão, 'S' início (olhando para o leste).
const MAZE := [
	"###########",
	"#S....#...#",
	"#.###.#.#.#",
	"#.#...#.#.#",
	"#.#.###.#.#",
	"#.#.....#.#",
	"#.#####...#",
	"#...#.....#",
	"###.#.....#",
	"#...#.....#",
	"###########",
]
const DIRS := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)] # N, L, S, O

var grid: Array[String] = []
var cell := Vector2i.ZERO
var facing := 1
var visited := {}
var busy := false
var clash_count := 0
var shake := 0.0
var wall_quads := 0

var _shake_duration := 0
var _shake_power := SHAKE_POWER
var _shake_speed := SHAKE_SPEED
var _shake_direction := 1
var _shake_acc := 0.0
var _queued := Act.NONE
var _up_needs_release := false

var npcs: Array[Dictionary] = []
var npc_picture: TextureRect
var npc_seen := {}
var marker_tex: Texture2D
var talking_npc: Dictionary = {}
var dialogue: DialogueBox
var talk_count := 0

## Inimigos do mapa. `enemies_enabled` existe para os testes de geometria/UI poderem
## andar pelo labirinto sem disparar combate; o jogo usa o padrão (ligado).
var enemies: DungeonEnemies
var enemy_sprites := {}
var enemies_enabled := true
var encounter_pending := false
var battle_scene := BATTLE_SCENE
var _last_action_was_step := false
var viewport: SubViewport
var view_container: SubViewportContainer
var pivot: Node3D
var camera: Camera3D
## Fundo gerado (backdrop.png, 544x416): faixa preta do horizonte em 1:1, teto e chão esticados
## até a borda da vista nova (são degradês verticais; as cores das pontas ficam).
var parallax: Control
var parallax_texture: Texture2D
var automap: Control
var hud: Control
var party: Array = []
var ui_font: SystemFont
var ui_bold: SystemFont


func _maze_rows() -> Array:
	return MAZE


func _npc_defs() -> Array:
	return NPCS


func _enemy_defs() -> Array:
	return ENEMY_DEFS


func _location_title() -> String:
	return LOCATION_NAME


func _default_facing() -> int:
	return 1


func _is_modal_open() -> bool:
	return dialogue != null and dialogue.is_open


func _draw_extra_hud() -> void:
	pass


func _ready() -> void:
	for row in _maze_rows():
		grid.append(row)
	for y in grid.size():
		var x := grid[y].find("S")
		if x >= 0:
			cell = Vector2i(x, y)
	facing = _default_facing()
	for npc in _npc_defs():
		npcs.append(npc.duplicate())
	enemies = DungeonEnemies.new(_enemy_defs())
	_restore_state()
	_build_ui()
	_build_world()
	_snap_to_state()
	_map_cell(cell)


# ---------------------------------------------------------------- construção

func _build_ui() -> void:
	size = SCREEN
	ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray(["Tahoma", "Arial", "sans-serif"])
	ui_bold = SystemFont.new()
	ui_bold.font_names = ui_font.font_names
	ui_bold.font_weight = 700
	_build_party()

	var black := ColorRect.new()
	black.color = Color.BLACK
	black.size = size
	add_child(black)

	parallax_texture = load(PARALLAX_PATH)
	parallax = Control.new()
	parallax.name = "Parallax"
	parallax.position = Vector2(-PARALLAX_OVERSCAN, 0)
	parallax.size = Vector2(SCREEN.x + PARALLAX_OVERSCAN * 2.0, SCREEN.y)
	parallax.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(parallax)
	# backdrop gerado: teto 0..166, faixa preta 166..183 em volta do horizonte (177), chão 183..288
	# (abaixo disso fica escondido pelo painel). Gradiente vertical: esticar na
	# horizontal não muda nada.
	var band_top := HORIZON_Y - 11.0
	var band_bottom := HORIZON_Y + 6.0
	for slice in [[Rect2(0, 0, 544, 166), 0.0, band_top], [Rect2(0, 166, 544, 17), band_top, band_bottom],
			[Rect2(0, 183, 544, 105), band_bottom, FRAME_RECT.end.y]]:
		var atlas := AtlasTexture.new()
		atlas.atlas = parallax_texture
		atlas.region = slice[0]
		var tr := TextureRect.new()
		tr.texture = atlas
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.position = Vector2(0, slice[1])
		tr.size = Vector2(parallax.size.x, float(slice[2]) - float(slice[1]))
		parallax.add_child(tr)

	view_container = SubViewportContainer.new()
	view_container.position = VIEW_POS
	view_container.size = Vector2(VIEW_SIZE)
	view_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(view_container)
	viewport = SubViewport.new()
	viewport.size = VIEW_SIZE
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view_container.add_child(viewport)
	_add_overworld_filter()

	hud = Control.new()
	hud.size = size
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.draw.connect(_draw_hud)
	add_child(hud)

	marker_tex = _bw_marker()
	npc_picture = TextureRect.new()
	npc_picture.name = "NpcPicture"
	npc_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	npc_picture.stretch_mode = TextureRect.STRETCH_SCALE
	npc_picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	npc_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	npc_picture.visible = false
	add_child(npc_picture)

	automap = Control.new()
	automap.position = AUTOMAP_RECT.position + Vector2.ONE * (AUTOMAP_MARGIN / 2.0)
	automap.size = AUTOMAP_RECT.size - Vector2.ONE * AUTOMAP_MARGIN
	automap.clip_contents = true
	automap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	automap.draw.connect(_draw_automap)
	add_child(automap)

	dialogue = DialogueBox.new()
	dialogue.name = "DialogueBox"
	dialogue.use_mono(DIALOGUE_RECT)
	add_child(dialogue)
	dialogue.opened.connect(_on_dialogue_toggled)
	dialogue.closed.connect(_on_dialogue_toggled)


func _add_overworld_filter() -> void:
	# Capture the parallax and the transparent 3D viewport together, before the UI.
	var world_copy := BackBufferCopy.new()
	# Whole-viewport copy: a COPY_MODE_RECT region is taken in window pixels, not scaled
	# by the content scale, so in any window other than 816 x 624 (e.g. back from a
	# battle) only the top-left part of the view was copied and the rest went black.
	world_copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(world_copy)

	var filter_material := ShaderMaterial.new()
	filter_material.shader = MIXED_FILTER
	filter_material.set_shader_parameter("mixed_palette", MIXED_PALETTE)
	filter_material.set_shader_parameter("frame_height", FRAME_RECT.size.y)
	var filter_rect := ColorRect.new()
	filter_rect.name = "OverworldFilter"
	filter_rect.position = FRAME_RECT.position
	filter_rect.size = FRAME_RECT.size
	filter_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	filter_rect.material = filter_material
	add_child(filter_rect)


## Grupo com os mesmos atributos do BattleController (FALLEN com os ganhos de absorção
## salvos; Yoch humano, sem EN, com os PP salvos). Só leitura do save.
func _build_party() -> void:
	var fs := UnitStats.new()
	fs.max_hp = 14
	fs.max_en = 8
	fs.atk = 7
	fs.mak = 3
	fs.defense = 5
	fs.mef = 3
	fs.agi = 6
	var gains := ProgressStore.load_gains()
	for key in gains.keys():
		fs.set(key, int(fs.get(key)) + int(gains[key]))
	var fallen := BattleUnit.new(&"fallen", "FALLEN", fs, true, true)
	var ys := UnitStats.new()
	ys.max_hp = 11
	ys.max_en = 0
	ys.atk = 5
	ys.mak = 2
	ys.defense = 4
	ys.mef = 2
	ys.agi = 5
	var yoch := BattleUnit.new(&"ally", "Yoch", ys, true)
	yoch.race = &"human"
	yoch.start_praying(ProgressStore.load_pp())
	party = [fallen, yoch]


func _str(value: String, x: float, baseline: float, color: Color, px: int, bold := false, align := HORIZONTAL_ALIGNMENT_LEFT) -> float:
	var f: Font = ui_bold if bold else ui_font
	var w := f.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var dx := x
	if align == HORIZONTAL_ALIGNMENT_RIGHT:
		dx = x - w
	elif align == HORIZONTAL_ALIGNMENT_CENTER:
		dx = x - w / 2.0
	hud.draw_string(f, Vector2(dx, baseline), value, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)
	return w


func _draw_hud() -> void:
	# Faixas pretas fora da moldura (cobrem o parallax/3D também durante o tremor).
	var f := FRAME_RECT
	hud.draw_rect(Rect2(0, 0, SCREEN.x, f.position.y), Color.BLACK)
	hud.draw_rect(Rect2(0, f.end.y, SCREEN.x, SCREEN.y - f.end.y), Color.BLACK)
	hud.draw_rect(Rect2(0, 0, f.position.x, SCREEN.y), Color.BLACK)
	hud.draw_rect(Rect2(f.end.x, 0, SCREEN.x - f.end.x, SCREEN.y), Color.BLACK)
	# Moldura de linha fina (mesmo traço das barras do HUD de batalha).
	hud.draw_rect(Rect2(f.position - Vector2(0.5, 0.5), f.size + Vector2.ONE), Color(1, 1, 1, 0.58), false, 1)
	# Automapa: fundo preto e a mesma linha fina.
	hud.draw_rect(AUTOMAP_RECT, Color(0, 0, 0, 0.85))
	hud.draw_rect(Rect2(AUTOMAP_RECT.position + Vector2(0.5, 0.5), AUTOMAP_RECT.size - Vector2.ONE), Color(1, 1, 1, 0.58), false, 1)
	# Nome do local, na linha e na posição do Battle Log.
	hud.draw_line(Vector2(8, LOCATION_LINE_Y), Vector2(SCREEN.x - 8, LOCATION_LINE_Y), Color(1, 1, 1, 0.38))
	hud.draw_rect(Rect2(11, LOCATION_LINE_Y + 8.5, 5, 5), INK)
	_str(_location_title(), 23, LOCATION_LINE_Y + 15.5, INK, 12)
	# Feedback de passo: coordenada e direção mudam a cada movimento.
	var headings := ["N", "E", "S", "W"]
	_str("POS %d,%d  %s" % [cell.x, cell.y, headings[facing]], SCREEN.x - 23,
			LOCATION_LINE_Y + 15.5, INK, 12, true, HORIZONTAL_ALIGNMENT_RIGHT)
	if enemies_enabled and enemies != null:
		var threat: Dictionary = enemies.in_front(cell, DIRS[facing], 3)
		if not threat.is_empty():
			_str("! HOSTILE AHEAD", 250, LOCATION_LINE_Y + 15.5, ENEMY_INK, 12, true)
	for i in party.size():
		_draw_status(party[i], STATUS_RECTS[i])
	_draw_extra_hud()


func _draw_status(unit: BattleUnit, r: Rect2) -> void:
	hud.draw_line(Vector2(r.position.x, r.position.y + 0.5), Vector2(r.end.x, r.position.y + 0.5), Color(1, 1, 1, 0.35))
	var x := r.position.x + 7
	var right := r.end.x - 7
	_str(unit.display_name, x, r.position.y + 18, Color.WHITE, 13, true)
	var hp_w := _str("HP ", x, r.position.y + 40, INK, 11)
	_str("%d/%d" % [unit.current_hp, unit.stats.max_hp], x + hp_w, r.position.y + 40, Color.WHITE, 11, true)
	if unit.prays:
		_str("PP %d/%d" % [unit.current_pp, PrayerBook.MAX_PP], right, r.position.y + 40, INK, 11, false, HORIZONTAL_ALIGNMENT_RIGHT)
	else:
		_str("EN %d/%d" % [unit.current_en, unit.stats.max_en], right, r.position.y + 40, INK, 11, false, HORIZONTAL_ALIGNMENT_RIGHT)
	var sp_w := _str("SP ", x, r.position.y + 61, Color.WHITE, 12, true)
	_str(str(unit.current_sp), x + sp_w, r.position.y + 61, Color.WHITE, 12, true)


func _build_world() -> void:
	var world := Node3D.new()
	viewport.add_child(world)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://prototypes/dungeon-crawler/dungeon_wall.gdshader")
	mat.set_shader_parameter("wall_tex", load(WALL_TEX_PATH))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	wall_quads = 0
	for y in grid.size():
		for x in grid[y].length():
			if is_wall(Vector2i(x, y)):
				continue
			for d in 4:
				if is_wall(Vector2i(x, y) + DIRS[d]):
					_add_wall_quad(st, Vector2i(x, y), d)
	var mesh := st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	world.add_child(mi)

	# Piso real em 3D: lajes quadradas com perspectiva, em vez de só degradê no fundo.
	var floor_span := maxf(40.0, float(maxi(grid.size(), grid[0].length() if not grid.is_empty() else 11)) + 16.0)
	var floor_plane := PlaneMesh.new()
	floor_plane.size = Vector2(floor_span, floor_span)
	var floor_mi := MeshInstance3D.new()
	floor_mi.name = "FloorGrid"
	floor_mi.mesh = floor_plane
	var floor_mat := ShaderMaterial.new()
	floor_mat.shader = FLOOR_SHADER
	floor_mat.set_shader_parameter("floor_tex", load(FLOOR_TILE_PATH))
	floor_mat.set_shader_parameter("tiles", Vector2(floor_span, floor_span))
	floor_mi.material_override = floor_mat
	# PlaneMesh já é horizontal no Godot 4: girar 90° o transformaria numa parede.
	var center_x := float(grid[0].length()) * 0.5 if not grid.is_empty() else 5.0
	var center_z := float(grid.size()) * 0.5 if not grid.is_empty() else 5.0
	floor_mi.position = Vector3(center_x, 0.0, center_z)
	world.add_child(floor_mi)

	pivot = Node3D.new()
	world.add_child(pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, EYE_HEIGHT, 0.5) # borda de trás da célula
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.fov = rad_to_deg(2.0 * atan((VIEW_SIZE.y / 2.0) / PX_PER_TILE))
	camera.near = 0.01
	camera.far = FAR_TILES
	camera.current = true
	pivot.add_child(camera)
	# As silhuetas usam material padrão iluminado; sem luz elas ficam pretas.
	var lamp := OmniLight3D.new()
	lamp.light_color = Color("ffd2c4")
	lamp.light_energy = 3.5
	lamp.omni_range = 9.0
	camera.add_child(lamp)

	var backdrop := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(40.0, WALL_HEIGHT)
	backdrop.mesh = quad
	var bg_mat := StandardMaterial3D.new()
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mat.albedo_color = BG_COLOR
	backdrop.material_override = bg_mat
	backdrop.position = Vector3(0, WALL_HEIGHT / 2.0 - EYE_HEIGHT, -BACKDROP_DIST)
	backdrop.name = "FarBackdrop"
	camera.add_child(backdrop)

	_build_enemy_sprites(world)


## Altura da silhueta no mundo. As células têm centro em coordenadas inteiras e as
## paredes ficam nas bordas (meio-inteiro), com WALL_HEIGHT de altura; a silhueta tem
## que caber no corredor e ficar de pé sobre o piso.
const ENEMY_HEIGHT := 0.56


## Silhuetas dos inimigos no corredor, em billboard: o jogador vê onde eles estão
## e vê cada um deles avançar um tile quando dá um passo.
func _build_enemy_sprites(world: Node3D) -> void:
	for enemy in enemies.entries:
		var tex: Texture2D = load(String(enemy.picture))
		var sprite := Sprite3D.new()
		sprite.name = "Enemy:" + String(enemy.id)
		# Forma extraída do battler SMT, sem a arte colorida nem a moldura: só silhueta.
		sprite.texture = tex
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.centered = true
		# Escala uniforme para a altura fixa, em vez de um fator solto que
		# ultrapassava a parede e deixava a figura flutuando.
		var fit := ENEMY_HEIGHT / (float(tex.get_height()) * sprite.pixel_size)
		sprite.scale = Vector3(fit, fit, fit)
		var c: Vector2i = enemy.cell
		sprite.position = _enemy_sprite_position(c)
		world.add_child(sprite)
		enemy_sprites[String(enemy.id)] = sprite


## Centro da célula (os inimigos vivem no centro do corredor, nunca na borda da parede),
## com a base da silhueta no piso.
func _enemy_sprite_position(c: Vector2i) -> Vector3:
	return Vector3(float(c.x), ENEMY_HEIGHT * 0.5, float(c.y))


func _animate_enemy_sprite(id: String, from: Vector2i, to: Vector2i) -> void:
	var sprite: Sprite3D = enemy_sprites.get(id)
	if sprite == null:
		return
	sprite.position = _enemy_sprite_position(from)
	var tw := create_tween()
	tw.tween_property(sprite, "position", _enemy_sprite_position(to), minf(0.16, step_time()))


func _add_wall_quad(st: SurfaceTool, c: Vector2i, d: int) -> void:
	var v := Vector2(DIRS[d])
	var r := Vector2(-v.y, v.x) # direita de quem olha para a parede
	var center := Vector2(c) + v * 0.5
	var bl := center - r * 0.5
	var br := center + r * 0.5
	var p_bl := Vector3(bl.x, 0, bl.y)
	var p_br := Vector3(br.x, 0, br.y)
	var p_tl := Vector3(bl.x, WALL_HEIGHT, bl.y)
	var p_tr := Vector3(br.x, WALL_HEIGHT, br.y)
	for pair in [[p_tl, Vector2(0, 0)], [p_tr, Vector2(1, 0)], [p_br, Vector2(1, 1)],
			[p_tl, Vector2(0, 0)], [p_br, Vector2(1, 1)], [p_bl, Vector2(0, 1)]]:
		st.set_uv(pair[1])
		st.add_vertex(pair[0])
	wall_quads += 1


# ---------------------------------------------------------------- estado

func is_wall(c: Vector2i) -> bool:
	if c.y < 0 or c.y >= grid.size() or c.x < 0 or c.x >= grid[c.y].length():
		return true
	return grid[c.y][c.x] == "#"


func npc_at(c: Vector2i) -> Dictionary:
	for npc in npcs:
		if npc.cell == c:
			return npc
	return {}


## NPC com quem o jogador interage: o da própria célula (criador, 2026-11-23: "devia dar
## pra falar e ver eles quando está em cima") ou, se não houver, o do tile logo à frente.
func npc_near() -> Dictionary:
	var here := npc_at(cell)
	return here if not here.is_empty() else npc_at(cell + DIRS[facing])


## Z em cima de um NPC ou de frente para ele abre a caixa de diálogo (D-055).
func talk() -> bool:
	if busy or dialogue.is_open:
		return false
	var npc := npc_near()
	if npc.is_empty():
		return false
	var pages: Array[String] = []
	pages.assign(npc.pages)
	talk_count += 1
	talking_npc = npc
	_show_picture(npc)
	dialogue.open(npc.name, pages)
	return true


## "Mostrar Imagem" do VX: origem no centro da imagem inteira (185 px de altura).
func _show_picture(npc: Dictionary) -> void:
	var tex: Texture2D = load(npc.picture)
	var sz := tex.get_size() * NPC_PICTURE_SCALE
	npc_picture.texture = tex
	npc_picture.size = sz
	npc_picture.position = (NPC_PICTURE_CENTER - sz / 2.0).floor()
	npc_picture.visible = true


func _on_dialogue_toggled() -> void:
	if not dialogue.is_open:
		talking_npc = {}
		refresh_front_picture()
	hud.queue_redraw()


## Criador 2026-11-23 ("é impossível saber que tem um NPC assim"): parado de frente para
## o NPC (tile logo à frente), a figura 1,5x centrada já aparece, antes do Z. Mais longe,
## nada na vista (só a marca no automapa). Some ao andar ou girar.
func refresh_front_picture() -> void:
	if dialogue.is_open:
		return
	var npc := npc_near()
	if busy or npc.is_empty():
		npc_picture.visible = false
	else:
		_show_picture(npc)


static func yaw_for(f: int) -> float:
	return -f * PI / 2.0


func _snap_to_state() -> void:
	pivot.position = Vector3(cell.x, 0, cell.y)
	pivot.rotation.y = yaw_for(facing)
	pivot.rotation.z = 0.0
	camera.position.y = EYE_HEIGHT


func _map_cell(c: Vector2i) -> void:
	visited[c] = true
	_update_npc_seen()
	_update_enemy_seen()
	if npc_picture != null:
		refresh_front_picture()
	automap.queue_redraw()
	if hud != null:
		hud.queue_redraw()


## Círculo do VX em P&B: pixels brancos do original (o brilho) viram pretos, o resto branco.
func _bw_marker() -> Texture2D:
	var src: Image = (load(MARKER_PATH) as Texture2D).get_image().get_region(MARKER_REGION)
	src.convert(Image.FORMAT_RGBA8)
	for y in src.get_height():
		for x in src.get_width():
			var px := src.get_pixel(x, y)
			if px.a > 0.0:
				var shine := px.r > 0.99 and px.g > 0.99 and px.b > 0.99
				src.set_pixel(x, y, Color.BLACK if shine else Color.WHITE)
	return ImageTexture.create_from_image(src)


## A célula do NPC está na vista 3D: na frente da câmera, até o corte, dentro da largura
## da moldura e sem parede no caminho (raio na grade do centro da câmera ao centro da célula).
func npc_cell_in_view(c: Vector2i) -> bool:
	var target := Vector3(c.x, 0.0, c.y)
	var local := camera.global_transform.affine_inverse() * target
	var depth := -local.z
	if depth <= 0.01 or depth > FAR_TILES:
		return false
	if absf(local.x) / depth > (FRAME_RECT.size.x / 2.0) / PX_PER_TILE:
		return false
	var from := Vector2(camera.global_position.x, camera.global_position.z)
	var to := Vector2(c.x, c.y)
	var steps := int(from.distance_to(to) / 0.05)
	for i in range(1, steps):
		var q := from.lerp(to, float(i) / steps)
		if is_wall(Vector2i(roundi(q.x), roundi(q.y))):
			return false
	return true


## Células com a marca de NPC. Na célula do jogador a marca branca esconderia a seta
## branca: lá só a seta.
func marked_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for npc in npcs:
		if npc_seen.has(npc.id) and npc.cell != cell:
			out.append(npc.cell)
	return out


func _update_npc_seen() -> void:
	if camera == null:
		return
	for npc in npcs:
		if not npc_seen.has(npc.id) and npc_cell_in_view(npc.cell):
			npc_seen[npc.id] = true


# ---------------------------------------------------------------- inimigos (combate novo)

func _update_enemy_seen() -> void:
	if enemies == null or camera == null:
		return
	enemies.observe(func(c: Vector2i) -> bool: return npc_cell_in_view(c))
	automap.queue_redraw()


## Chamado só depois de um passo (não de um giro): cada inimigo avança um tile.
func _after_player_step() -> void:
	if not enemies_enabled or encounter_pending or enemies == null:
		return
	var before := {}
	for enemy in enemies.entries:
		before[String(enemy.id)] = enemy.cell
	var hit: Dictionary = enemies.at(cell)
	if hit.is_empty():
		hit = enemies.step_toward(cell, func(c: Vector2i) -> bool: return not is_wall(c))
	# A silhueta desliza até a nova célula no mesmo passo do jogador.
	for enemy in enemies.entries:
		var id := String(enemy.id)
		if before.has(id) and before[id] != enemy.cell:
			_animate_enemy_sprite(id, before[id], enemy.cell)
	if not hit.is_empty():
		_begin_battle(hit)
	else:
		_update_enemy_seen()


func _begin_battle(enemy: Dictionary) -> void:
	if encounter_pending:
		return
	encounter_pending = true
	var id := String(enemy.get("id", ""))
	encounter_started.emit(id)
	# A silhueta some junto com o inimigo encontrado.
	var sprite: Sprite3D = enemy_sprites.get(id)
	if sprite != null:
		sprite.queue_free()
		enemy_sprites.erase(id)
	# O inimigo encontrado sai do mapa: voltar da batalha não dispara outra luta.
	enemies.entries.erase(enemy)
	_save_state()
	if battle_scene.is_empty():
		return
	# Busca em runtime: scripts -s compilam antes dos autoloads.
	var fader := get_tree().root.get_node_or_null("SceneFader")
	if fader != null:
		fader.fade_to(battle_scene, true)
	else:
		get_tree().change_scene_to_file(battle_scene)


func _save_state() -> void:
	var route: Array = []
	for key in visited.keys():
		var c: Vector2i = key
		route.append([c.x, c.y])
	Engine.set_meta(DUNGEON_STATE_META, {
		"cell": [cell.x, cell.y],
		"facing": facing,
		"enemies": enemies.serialise(),
		"visited": route,
		"seen": enemies.seen.keys(),
	})
	Engine.set_meta(DUNGEON_RETURN_META, DUNGEON_SCENE)


func _restore_state() -> void:
	if not Engine.has_meta(DUNGEON_STATE_META):
		return
	var saved: Dictionary = Engine.get_meta(DUNGEON_STATE_META)
	Engine.remove_meta(DUNGEON_STATE_META)
	var pos: Array = saved.get("cell", [])
	if pos.size() == 2:
		cell = Vector2i(int(pos[0]), int(pos[1]))
	facing = int(saved.get("facing", facing))
	enemies.restore(saved.get("enemies", []))
	for item in saved.get("visited", []):
		var c: Array = item
		if c.size() == 2:
			visited[Vector2i(int(c[0]), int(c[1]))] = true
	for id in saved.get("seen", []):
		enemies.seen[String(id)] = true


# ---------------------------------------------------------------- entrada

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or event.echo:
		return
	var k := event as InputEventKey
	if k.keycode == KEY_UP and not k.pressed:
		_up_needs_release = false
	if not k.pressed:
		return
	# Diálogo aberto: só Z / Enter / Espaço (avançam); o resto não anda nem gira.
	if dialogue.is_open:
		if k.keycode in [KEY_Z, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			dialogue.advance()
			if not dialogue.is_open:
				_up_needs_release = true
		get_viewport().set_input_as_handled()
		return
	match k.keycode:
		KEY_Z, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			talk()
		KEY_LEFT:
			request(Act.TURN_LEFT)
		KEY_RIGHT:
			request(Act.TURN_RIGHT)
		KEY_DOWN:
			request(Act.TURN_BACK)
		KEY_UP:
			_up_needs_release = false
			request(Act.FORWARD)


func _process(delta: float) -> void:
	_update_shake(delta)
	dialogue.process_text(delta)
	if _is_modal_open() or encounter_pending:
		return
	# Seta para cima segurada continua andando (Input.press? no VX). Contra a parede,
	# só bate de novo depois de soltar e apertar (Input.trigger? no VX).
	if not busy and _queued == Act.NONE and Input.is_key_pressed(KEY_UP) and not _up_needs_release:
		request(Act.FORWARD)


## Pede uma ação. Durante um movimento, guarda uma entrada (set_next_input do VX).
func request(act: int) -> void:
	if _is_modal_open() or encounter_pending:
		return
	if busy:
		if _queued == Act.NONE:
			_queued = act
		return
	# A figura do NPC à frente sai assim que o jogador anda ou gira.
	npc_picture.visible = false
	match act:
		Act.FORWARD:
			_step_forward()
		Act.TURN_LEFT:
			_turn(-1, false)
		Act.TURN_RIGHT:
			_turn(1, false)
		Act.TURN_BACK:
			_turn(1, true)


func _step_forward() -> void:
	var target: Vector2i = cell + DIRS[facing]
	if is_wall(target):
		_clash()
		return
	busy = true
	_last_action_was_step = true
	cell = target
	var tw := create_tween()
	tw.tween_property(pivot, "position", Vector3(cell.x, 0, cell.y), step_time())
	tw.finished.connect(_on_action_done)
	# Balanço de câmera e leve rolagem: o passo precisa ser perceptível.
	var bob := create_tween()
	bob.tween_property(camera, "position:y", EYE_HEIGHT + 0.06, step_time() * 0.45)
	bob.tween_property(camera, "position:y", EYE_HEIGHT, step_time() * 0.55)
	var roll := create_tween()
	roll.tween_property(pivot, "rotation:z", 0.012, step_time() * 0.5)
	roll.tween_property(pivot, "rotation:z", 0.0, step_time() * 0.5)


## Duração do passo: corre (0,15 s) enquanto X estiver segurado.
func step_time() -> float:
	return RUN_STEP_TIME if Input.is_key_pressed(RUN_KEY) else STEP_TIME


func _turn(step: int, then_again: bool) -> void:
	busy = true
	_last_action_was_step = false
	var from_yaw := pivot.rotation.y
	facing = posmod(facing + step, 4)
	automap.queue_redraw()
	if hud != null:
		hud.queue_redraw()
	var tw := create_tween()
	tw.tween_property(pivot, "rotation:y", from_yaw - step * PI / 2.0, TURN_TIME)
	if then_again:
		tw.finished.connect(func() -> void:
			pivot.rotation.y = yaw_for(facing)
			busy = false
			_turn(step, false))
	else:
		tw.finished.connect(_on_action_done)


func _clash() -> void:
	clash_count += 1
	_up_needs_release = true
	_last_action_was_step = false
	busy = true
	start_shake(SHAKE_POWER, SHAKE_SPEED, SHAKE_DURATION)


func _on_action_done() -> void:
	_snap_to_state()
	_map_cell(cell)
	busy = false
	refresh_front_picture()
	if _last_action_was_step:
		_last_action_was_step = false
		_after_player_step()
	if not encounter_pending:
		_flush_queue()


func _flush_queue() -> void:
	if _queued != Act.NONE:
		var a := _queued
		_queued = Act.NONE
		request(a)


# ---------------------------------------------------------------- tremor (Game_Screen do VX)

func start_shake(power: int, speed: int, duration: int) -> void:
	_shake_duration = duration
	_shake_direction = 1
	shake = 0.0
	_shake_acc = 0.0
	_shake_power = power
	_shake_speed = speed


func _update_shake(delta: float) -> void:
	_shake_acc += delta
	var frame := 1.0 / 60.0
	while _shake_acc >= frame:
		_shake_acc -= frame
		_shake_frame()
	view_container.position.x = VIEW_POS.x - int(shake)
	parallax.position.x = -PARALLAX_OVERSCAN - int(shake)


func _shake_frame() -> void:
	if _shake_duration >= 1 or shake != 0.0:
		var power := _shake_power
		var speed := _shake_speed
		var d := (power * speed * _shake_direction) / 10.0
		if _shake_duration <= 1 and shake * (shake + d) < 0.0:
			shake = 0.0
		else:
			shake += d
		if shake > power * 2:
			_shake_direction = -1
		if shake < -power * 2:
			_shake_direction = 1
		if _shake_duration >= 1:
			_shake_duration -= 1
		if _shake_duration == 0 and shake == 0.0 and busy and not _is_tweening():
			busy = false
			_flush_queue()


func _is_tweening() -> bool:
	return pivot.position != Vector3(cell.x, 0, cell.y) or not is_equal_approx(pivot.rotation.y, yaw_for(facing))


# ---------------------------------------------------------------- automapa

func _draw_automap() -> void:
	# Mesma lógica de células do automapa do VX (9x9 de 16 px, jogador no centro),
	# desenhada em P&B: não explorado = preto; explorado = cinza; paredes = linha branca;
	# grade fina; jogador = seta branca.
	var inner := automap.size
	var center := Vector2(floor(inner.x / 2.0) - CELL_PX / 2.0, floor(inner.y / 2.0) - CELL_PX / 2.0)
	var count := int(inner.x / CELL_PX) + 2
	var start := -count / 2
	var ends := [[Vector2(0, 0.5), Vector2(16, 0.5)], [Vector2(15.5, 0), Vector2(15.5, 16)],
		[Vector2(0, 15.5), Vector2(16, 15.5)], [Vector2(0.5, 0), Vector2(0.5, 16)]]
	for pass_i in 2:
		for ox in count:
			for oy in count:
				var off := Vector2i(start + ox, start + oy)
				var m := cell + off
				var p := center + Vector2(off * CELL_PX)
				if pass_i == 0:
					if visited.has(m):
						automap.draw_rect(Rect2(p, Vector2(CELL_PX, CELL_PX)), Color(1, 1, 1, 0.22))
					automap.draw_rect(Rect2(p + Vector2(0.5, 0.5), Vector2(CELL_PX - 1, CELL_PX - 1)), Color(1, 1, 1, 0.08), false, 1)
				elif visited.has(m):
					for d in 4:
						if is_wall(m + DIRS[d]):
							automap.draw_line(p + ends[d][0], p + ends[d][1], Color(1, 1, 1, 0.9), 1)
	for m in marked_cells():
		automap.draw_texture(marker_tex, center + Vector2((m - cell) * CELL_PX))
	# Inimigos vistos: pontos vermelhos com contorno escuro, distintos da marca P&B.
	if enemies_enabled and enemies != null:
		for enemy in enemies.entries:
			var m: Vector2i = enemy.cell
			if not enemies.seen.has(enemy.id) or m == cell:
				continue
			var p := center + Vector2((m - cell) * CELL_PX)
			automap.draw_rect(Rect2(p + Vector2(3, 3), Vector2(10, 10)), ENEMY_DARK)
			automap.draw_rect(Rect2(p + Vector2(5, 5), Vector2(6, 6)), ENEMY_INK)
			automap.draw_rect(Rect2(p + Vector2(6, 6), Vector2(2, 2)), Color("f2b9b2"))
	var c := center + Vector2(CELL_PX / 2.0, CELL_PX / 2.0)
	var fwd := Vector2(DIRS[facing])
	var side := Vector2(-fwd.y, fwd.x)
	automap.draw_colored_polygon(PackedVector2Array([c + fwd * 6, c - fwd * 5 + side * 5, c - fwd * 2, c - fwd * 5 - side * 5]), Color.WHITE)
