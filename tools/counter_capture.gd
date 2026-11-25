extends Node
## Dev capture driver for D-049: (A) hero counter with a perfect interruption at the
## pointer crossing, (B) hero counter won by a normal POINT, (C) enemy counter on the
## hero's own attack, with the rails over the enemy. Real speed; enemies get spare HP
## only so the shake on a surviving sprite stays visible.

class CaptureBattle extends "res://scripts/battle/playable_controller.gd":
	var force_enemy_counter := false
	var late_ai := true
	func _enemy_counter_roll(_e: BattleUnit) -> bool:
		return force_enemy_counter
	func _counter_ai_time(red_seconds: float) -> float:
		return red_seconds * 0.92 if late_ai else super._counter_ai_time(red_seconds)

const STEP_GAP := 0.9

var battle: Control
var scenario := 0
var wait := 1.0
var pressed := false
var exchanges := 0


func _ready() -> void:
	ProgressStore.save_path_override = "user://countercap_progress.json"
	ProgressStore.clear()


func _new_battle(enemy_counter: bool) -> void:
	if battle != null:
		battle.queue_free()
	battle = CaptureBattle.new()
	battle.offer_reserve = true  # creator 2026-11-24: REACT left the own-turn menu
	battle.force_enemy_counter = enemy_counter
	add_child(battle)
	for enemy in battle.state.units.slice(2):
		enemy.current_hp = 999
	pressed = false
	exchanges = 0


func _process(delta: float) -> void:
	wait -= delta
	if battle == null:
		if wait <= 0.0:
			_new_battle(false)
			wait = STEP_GAP
		return
	var mode: String = battle.hud.mode
	if mode == "counter":
		var bar: Control = battle.counter
		var at_crossing: bool = BattleMath.pointers_aligned(bar.white_position(), bar.red_position())
		var go: bool = at_crossing if scenario == 0 else bar.white_position() >= 0.5
		if not pressed and go:
			battle.handle_confirm()
			pressed = true
		return
	pressed = false
	if wait > 0.0:
		return
	wait = STEP_GAP
	match mode:
		"plan", "command":
			if scenario < 2:
				battle.submit_command(battle.hud.command_options.find("REACT"))
			else:
				battle.submit_plan(0); battle.submit_plan(0); battle.exec_plan()
		"target": battle.submit_target(0)
		"react":
			if exchanges < 1:
				battle.select_reactor(battle.hud.players.find(battle.action_defender))
				battle.answer_reaction(true)
				battle.submit_command(battle.hud.command_options.find("FIGHT"))
				exchanges += 1
			else:
				battle.answer_reaction(false)
		"continue", "announce":
			if battle.fx.is_busy():
				wait = 0.1
				return
			if exchanges >= 1 or scenario == 2:
				wait = 1.6
				_next_scenario()
				return
			battle.proceed()
		"timing": battle.handle_confirm()


func _next_scenario() -> void:
	scenario += 1
	if scenario > 2:
		get_tree().quit()
		return
	_new_battle(scenario == 2)
	battle.late_ai = scenario != 2
