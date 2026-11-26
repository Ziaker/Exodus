extends SceneTree
## Demonstração visual no controller real do Survival, com saves isolados.

const MAP := preload("res://scripts/survival/necropole_map.gd")
const VISUAL := preload("res://scripts/survival/necropole_visual.gd")
const DUNGEON := preload("res://prototypes/dungeon-crawler/dungeon_proto.gd")

var output: String
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _verify(ok: bool, context: String) -> void:
	if not ok:
		printerr("FAIL: ", context)
		failures += 1


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var captures := ProjectSettings.globalize_path("res://captures/").replace("\\", "/")
	var user_data := OS.get_user_data_dir().replace("\\", "/").simplify_path()
	var captures_prefix := captures.simplify_path().trim_suffix("/") + "/"
	if not user_data.to_lower().begins_with(captures_prefix.to_lower()):
		printerr("Abra Jogar.cmd ou configure o diretório de dados do Godot dentro de captures/.")
		quit(1)
		return
	output = captures.path_join("necropole-battle")
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		printerr("Não foi possível criar ", output)
		quit(1)
		return
	SurvivalState.reset()
	if "--auditar" in args:
		await _audit()
		quit(0 if failures == 0 else 1)
		return
	var warden := SurvivalStrata.warden_of(1)
	SurvivalState.patch({"encounter_id": warden})
	if change_scene_to_file(SurvivalData.BATTLE_SCENE) != OK:
		quit(1)
		return
	await scene_changed
	var battle := current_scene
	_verify(battle != null and battle.has_method("run_battle") and battle.encounter_ids.has(warden),
		"batalha real do guardião")
	if failures:
		quit(1)
		return
	_install_stage(battle.stage)
	_verify(battle.hud.opponents.size() == 3, "guardião e duas escoltas no HUD")
	if "--jogar" in args:
		print("BATALHA SATURNINA ", battle.encounter_ids)
		return
	await create_timer(2.0).timeout
	await _capture("01_batalha_saturnina.png")
	await create_timer(2.6).timeout
	await _capture("02_batalha_saturnina.png")
	await create_timer(2.0).timeout
	await _capture("03_batalha_saturnina.png")
	print("BATALHA SATURNINA ", battle.encounter_ids, " / 3 quadros / ", failures, " falhas")
	quit(0 if failures == 0 else 1)


func _install_stage(stage: ColorRect) -> void:
	var sub := SubViewport.new()
	sub.size = Vector2i(stage.size * (DUNGEON.SCREEN.x / stage.size.x))
	sub.own_world_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	stage.add_child(sub)
	var world := Node3D.new()
	sub.add_child(world)
	var pivot := Node3D.new()
	var view := MAP.sepulchre() + Vector2i(0, 2)
	pivot.position = Vector3(view.x, 0.0, view.y)
	world.add_child(pivot)
	var camera := Camera3D.new()
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.fov = rad_to_deg(2.0 * atan(sub.size.y * 0.5 / DUNGEON.PX_PER_TILE))
	camera.position = Vector3(0.0, DUNGEON.EYE_HEIGHT, 0.5)
	camera.near = 0.01
	camera.far = DUNGEON.FAR_TILES
	pivot.add_child(camera)
	camera.current = true
	var visual := VISUAL.new()
	world.add_child(visual)
	visual.install(pivot, camera)
	stage.material = null
	var image := TextureRect.new()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.texture = sub.get_texture()
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.size = stage.size
	stage.add_child(image)
	var copy := BackBufferCopy.new()
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	stage.add_child(copy)
	var style := ShaderMaterial.new()
	style.shader = DUNGEON.MIXED_FILTER
	style.set_shader_parameter("mixed_palette", DUNGEON.MIXED_PALETTE)
	style.set_shader_parameter("frame_height", sub.size.y)
	var filter := ColorRect.new()
	filter.size = stage.size
	filter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	filter.material = style
	stage.add_child(filter)


func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_verify(image.save_png(output.path_join(name)) == OK, name)


func _audit() -> void:
	if change_scene_to_file(SurvivalData.WORLD_SCENE) != OK:
		_verify(false, "carregar o mapa do Survival")
		return
	await scene_changed
	var world := current_scene
	_verify(world != null and world.has_method("request"), "SurvivalWorld com script ativo")
	if failures:
		return
	var counts := {}
	var occupied := {}
	var start := MAP.entrance()
	var reachable := SurvivalStrata.distances(world.grid, start, 1)
	for npc: Dictionary in world.npcs:
		var role := String(npc.role)
		counts[role] = int(counts.get(role, 0)) + 1
		_verify(reachable.has(npc.cell) and not occupied.has(npc.cell), String(npc.id))
		occupied[npc.cell] = true
	for enemy: Dictionary in world.enemies.entries:
		_verify(reachable.has(enemy.cell) and not occupied.has(enemy.cell), String(enemy.id))
		occupied[enemy.cell] = true
	_verify(counts.get("sanctuary", 0) == 1 and counts.get("event", 0) == SurvivalStrata.EVENTS_PER_STRATUM,
		"santuário e três eventos")
	_verify(world.enemies.entries.size() == SurvivalStrata.PER_STRATUM + 1, "demônios e grupo humano")
	_verify(world.enemies.at(MAP.sepulchre()).get("id", "") == SurvivalStrata.warden_of(1),
		"guardião no Sepulcro")
	var titles: Array[String] = []
	for npc: Dictionary in world.npcs:
		if npc.role == "event":
			titles.append(npc.name)
	var s := SurvivalState.data()
	print("NECROPOLE SPAWN ", JSON.stringify({"seed": s.seed, "npcs": counts, "eventos": titles,
		"inimigos": world.enemies.entries.size(), "casas_distintas": occupied.size(),
		"celulas_alcancaveis": reachable.size(), "falhas": failures}))
