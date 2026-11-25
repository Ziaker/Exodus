extends SceneTree
## Grava frames reais de gameplay: dungeon (pontos vermelhos) -> encontro -> combate novo.
## Rodar com janela e --fixed-fps 60. Os PNGs viram vídeo com ffmpeg:
##   ffmpeg -framerate 30 -i captures/video_frames/%04d.png -c:v libx264 -pix_fmt yuv420p captures/gameplay.mp4

const Proto := preload("res://prototypes/dungeon-crawler/dungeon_proto.gd")
const FRAMES_DIR := "res://captures/video_frames/"

var frame_index := 0
var last_action := -100
var result_since := -1


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FRAMES_DIR))
	call_deferred("_run")


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _record_frame() -> void:
	var image: Image = root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(FRAMES_DIR + "%04d.png" % frame_index))
	frame_index += 1


func _record(seconds: float) -> void:
	var count := int(seconds * 30.0)
	for _i in count:
		await _frames(2)
		_record_frame()


func _idle(d: Control) -> void:
	while is_instance_valid(d) and d.busy:
		await process_frame


func _drive_battle(b: Control) -> void:
	if b == null or b.get("hud") == null or not (b.hud.get("mode") != null):
		return
	if Engine.get_process_frames() - last_action < 10:
		return
	var mode: String = b.hud.mode
	match mode:
		"turn": b.handle_confirm()
		"plan":
			if b._planned.size() >= 2:
				b.exec_plan()
			else:
				var options: Array[String] = b.hud.command_options
				var idx := options.find("FIGHT")
				b.submit_plan(idx if idx >= 0 else 0)
		"skill": b.submit_skill(0)
		"target": b.submit_target(b.first_living_target())
		"timing": b.rhythm._finish(BattleMath.RhythmResult.POINT)
		"counter":
			if b.counter.white_position() >= 0.45:
				b.handle_confirm()
		"react":
			# Aceita a reação: o ataque anunciado vira contra-ataque no ritmo de duas pistas.
			b.answer_reaction(true)
		"absorb": b._mash_count = 12
		"continue", "announce": b.proceed()
		"en_extra", "pray": b.handle_back()
		"command": b.submit_command(0)
		"result":
			# Segura a tela de vitória antes de voltar ao dungeon pelo fade.
			if result_since < 0:
				result_since = Engine.get_process_frames()
			if Engine.get_process_frames() - result_since >= 60:
				b.handle_confirm()
			return
		_: return
	last_action = Engine.get_process_frames()


func _record_battle(max_seconds: float) -> void:
	var count := int(max_seconds * 30.0)
	var back_frames := 0
	for _i in count:
		await _frames(2)
		_drive_battle(current_scene)
		_record_frame()
		# Voltou ao mapa: grava mais um instante do dungeon restaurado e encerra.
		if not _is_battle(current_scene):
			back_frames += 1
			if back_frames >= 45:
				break


func _is_battle(node: Node) -> bool:
	return node != null and node.get("hud") != null and node.hud.get("mode") != null


func _run() -> void:
	var d: Control = load("res://prototypes/dungeon-crawler/DungeonProto.tscn").instantiate()
	root.add_child(d)
	await _frames(10)

	# 1) Vista inicial: inimigo vermelho no automapa e aviso no HUD.
	await _record(1.0)

	# 2) Caminha pelo corredor: os pontos vermelhos avançam a cada passo.
	d.request(Proto.Act.TURN_RIGHT)
	await _idle(d)
	for _i in 3:
		d.request(Proto.Act.FORWARD)
		await _idle(d)
		await _record(0.4)

	# 3) Meia-volta: mostra os inimigos mais perto.
	d.request(Proto.Act.TURN_BACK)
	await _idle(d)
	await _record(0.8)

	# 4) Vai ao encontro.
	for _i in 8:
		if d.encounter_pending:
			break
		d.request(Proto.Act.FORWARD)
		await _idle(d)
		await _record(0.35)
	# Se o percurso terminar sem contato, provoca o encontro pelo mesmo caminho do jogo.
	if is_instance_valid(d) and not d.encounter_pending:
		var enemy: Dictionary = {}
		for candidate in d.enemies.entries:
			enemy = candidate
			break
		if not enemy.is_empty():
			d._begin_battle(enemy)
	await _frames(10)

	# 5) Combate novo, jogado automaticamente até o resultado e a volta ao dungeon.
	await _record_battle(14.0)
	print("VIDEO FRAMES: ", frame_index)
	quit(0)
