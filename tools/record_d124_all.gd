extends SceneTree
## D-124/D-125: grava UM vídeo REAL com as 8 skills, cada uma no inimigo e depois no aliado (close-up) (fluxo do controlador: custo, log, barra de ritmo,
## dano, status e a coreografia grotesca). Uso (janela real):
##   Godot_v4.7.2-stable_win64_console.exe --path . --write-movie captures/d124_videos/d124_todas.avi --fixed-fps 30 \
##     --resolution 816x624 -s tools/record_d124_all.gd
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
	func _enemy_second_target(first: BattleUnit) -> BattleUnit:
		return hud.players[1] if first == hud.players[0] else hud.players[0]
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
const SKILLS: Array[StringName] = [&"mazz_bite", &"fang_sting", &"fang_spine", &"vuln_pierce", &"dark_breath", &"umbral_gaze", &"ignoma", &"ignoma_esh"]


func _initialize() -> void:
	SANDBOX.begin()
	call_deferred("_run")


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _secs(s: float) -> void:
	await create_timer(s).timeout


func _run_enemy(unit: BattleUnit, skill: StringName) -> void:
	await b._enemy_skill(unit, skill)
	_done = true


func _run_hero(unit: BattleUnit, skill: StringName, target: BattleUnit) -> void:
	await b._execute_skill(unit, {"skill": skill}, false, target)
	_done = true


## Aperta Z (paginação do log, confirmações) até a ação terminar.
func _pump() -> void:
	var guard := 0
	while not _done and guard < 1800:
		guard += 1
		if b.hud.mode in ["continue", "announce"]: b.proceed()
		elif b.hud.mode == "react": b.answer_reaction(false)
		await process_frame


func _reset(units: Array) -> void:
	b.grotesque_fx.clear_all()
	for u in units:
		var bu: BattleUnit = u
		bu.statuses.clear()
		bu.bleeds.clear()
		bu.burns.clear()
		bu.trapped_actions = 0
		bu.stats.max_hp = 400 if bu.is_player else 80  # heróis aguentam; o inimigo é fraco (o Mazz Bite dele custa 30% do HP máx.)
		bu.current_hp = bu.stats.max_hp
		bu.stats.max_en = 40
		bu.current_en = 40
		bu.acts_available = 4
		bu.passive_stance = false
	b.hud.mode = "busy"
	b._clear_roles()


func _settle() -> void:
	await _frames(3)
	var guard := 0
	while (b.grotesque_fx.is_busy() or b.fx.is_busy()) and guard < 1200:
		guard += 1
		if b.hud.mode in ["continue", "announce"]: b.proceed()
		await process_frame
	if guard >= 1200:
		var g := b.grotesque_fx
		print("  BUSY? effects=", g.effect_count(), " fields=", g.field_count(), " warps=", g.warp_count(), " dark=", g.darken(), " fx=", b.fx.is_busy())
	await _secs(0.9)


func _run() -> void:
	ProgressStore.save_path_override = "user://record_d124_guard.json"
	ProgressStore.clear()
	b = RecBattle.new()
	b.offer_reserve = true
	root.add_child(b)
	await _frames(15)
	var hero: BattleUnit = b.hud.players[0]
	var ally: BattleUnit = b.hud.players[1]
	var foe0: BattleUnit = b.hud.opponents[0]
	var foe1: BattleUnit = b.hud.opponents[1]
	var all: Array = [hero, ally, foe0, foe1]
	ally.start_praying(5)
	_reset(all)
	await _secs(0.8)
	var only := OS.get_cmdline_user_args()
	for skill in SKILLS:
		if not only.is_empty() and not only.has(String(skill)): continue
		var d := SkillBook.def(skill)
		var dual := bool(d.get("dual", false))
		print("SEG ", skill, " herói")
		# 1) o herói usa a skill no inimigo
		_reset(all)
		ally.start_praying(5)
		hero.skills.assign([skill])
		if dual:
			b.scripted_targets = [foe1] as Array[BattleUnit]
		_done = false
		_run_hero(hero, skill, foe0 if dual else foe1)
		await _pump()
		await _settle()
		print("SEG ", skill, " aliado")
		# 2) o inimigo usa a mesma skill nos aliados (close-up: figura-substituta do tamanho de um inimigo)
		_reset(all)
		ally.start_praying(5)
		foe0.skills.assign([skill])
		_done = false
		_run_enemy(foe0, skill)
		await _pump()
		await _settle()
	ProgressStore.clear()
	quit(0)
