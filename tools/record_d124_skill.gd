extends SceneTree
## D-124/D-125: grava o vídeo REAL de uma skill no jogo (fluxo do controlador: custo, log, barra de ritmo,
## dano, status e a coreografia grotesca). Uso (janela real):
##   Godot_v4.7.2-stable_win64_console.exe --path . --write-movie captures/d124_videos/mazz_bite.avi --fixed-fps 30 \
##     --resolution 816x624 -s tools/record_d124_skill.gd -- mazz_bite [inimigo]
## O herói aperta a barra no centro (POINT) e o alvo não defende, para a execução ser determinística.
const SANDBOX := preload("res://tests/progress_sandbox.gd")

class RecBattle extends "res://scripts/battle/playable_controller.gd":
	var scripted_targets: Array[BattleUnit] = []
	func _enemy_counter_roll(_e: BattleUnit) -> bool: return false
	func _enemy_skill_pick(_n: int) -> int: return 0
	func _zone_roll(_h: float) -> int: return BattleMath.RhythmResult.MISS
	func _ai_roll(_a: BattleUnit, _d: BattleUnit) -> int: return BattleMath.RhythmResult.POINT
	func _defender_reaction(_a: BattleUnit, _d: BattleUnit) -> int: return BattleMath.RhythmResult.MISS
	func _fx_roll(_c: int) -> bool: return true
	func _burn_roll(_c: int) -> bool: return true
	func _counter_ai_time(_s: float) -> float: return 99.0
	func _wait_target(_side: String = "enemy") -> BattleUnit:
		return scripted_targets.pop_front() if not scripted_targets.is_empty() else null
	## O jogador aperta a barra no centro (POINT) no meio da passagem.
	func _wait_rhythm() -> int:
		_rhythm_result = BattleMath.RhythmResult.MISS
		get_tree().create_timer(rhythm.duration * 0.5).timeout.connect(func() -> void: rhythm.press())
		await rhythm_done
		return _rhythm_result

var b: RecBattle
var _done := false


func _run_enemy(unit: BattleUnit, skill: StringName) -> void:
	await b._enemy_skill(unit, skill)
	_done = true


func _initialize() -> void:
	SANDBOX.begin()
	call_deferred("_run")


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _secs(s: float) -> void:
	await create_timer(s).timeout


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var skill := StringName(args[0]) if args.size() > 0 else &"mazz_bite"
	var enemy_cast := args.has("inimigo")
	ProgressStore.save_path_override = "user://record_d124_guard.json"
	ProgressStore.clear()
	b = RecBattle.new()
	b.offer_reserve = true
	root.add_child(b)
	await _frames(15)
	b.hud.mode = "busy"
	var hero: BattleUnit = b.hud.players[0]
	var ally: BattleUnit = b.hud.players[1]
	var foe0: BattleUnit = b.hud.opponents[0]
	var foe1: BattleUnit = b.hud.opponents[1]
	for f in b.hud.opponents:
		(f as BattleUnit).stats.max_hp = 400
		(f as BattleUnit).current_hp = 400
	for h in [hero, ally]:
		(h as BattleUnit).stats.max_hp = 90
		(h as BattleUnit).current_hp = 90
	hero.stats.max_en = 40
	hero.current_en = 40
	hero.acts_available = 4
	foe0.stats.max_en = 40
	foe0.current_en = 40
	foe0.acts_available = 4
	ally.start_praying(5)
	await _secs(0.9)
	var d := SkillBook.def(skill)
	if enemy_cast:
		# o inimigo usa a skill contra os heróis (espelhado)
		foe0.skills.assign([skill])
		_done = false
		_run_enemy(foe0, skill)
		while not _done:
			if b.hud.mode in ["continue", "announce"]: b.proceed()
			elif b.hud.mode == "react": b.answer_reaction(false)
			await process_frame
	else:
		hero.skills.assign([skill])
		if bool(d.get("dual", false)):
			b.scripted_targets = [foe1] as Array[BattleUnit]
		await b._execute_skill(hero, {"skill": skill}, false, foe0 if bool(d.get("dual", false)) else foe1)
	await _frames(3)
	while b.grotesque_fx.is_busy() or b.fx.is_busy():
		await process_frame
	await _secs(1.6)
	ProgressStore.clear()
	quit(0)
