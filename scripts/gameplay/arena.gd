extends Node3D

@export_range(1.0, 300.0) var site_interval: float = 30.0

var battle_started: bool = false
var battle_over: bool = false
var elapsed: float = 0.0
var active_site: ReinforcementSite
var _site_window: int = -1

@onready var horde: HordeController = $Horde
@onready var survivor: Survivor = $Survivor
@onready var sites: Node3D = $Reinforcements
@onready var hud: BattleHUD = $HUD
@onready var battle_audio: BattleAudio = $BattleAudio


func _ready() -> void:
	process_physics_priority = 1
	survivor.movement_bounds = horde.movement_bounds
	survivor.health.changed.connect(_update_knight_health)
	survivor.health.died.connect(_finish_battle.bind(true))
	horde.count_changed.connect(_update_horde_count)
	horde.move_commanded.connect(_begin_battle)
	_update_knight_health(survivor.health.current_health, survivor.health.max_health)
	_update_horde_count(horde.agents.size())
	_update_status()
	battle_audio.setup(survivor, horde, sites)


func _begin_battle() -> void:
	if not battle_over and not battle_started:
		battle_started = true
		_update_site_schedule()
		_update_status()


func _physics_process(delta: float) -> void:
	if not battle_started or battle_over:
		return
	elapsed += delta
	horde.update_lifetimes(delta)
	_update_site_schedule()
	survivor.update_combat(horde.agents, delta)
	for agent: HordeAgent in horde.agents:
		if battle_over:
			break
		agent.update_combat(survivor, delta)
	if not battle_over:
		for site: ReinforcementSite in sites.get_children():
			site.update_recruitment(horde, delta)
	_update_status()


func _update_site_schedule() -> void:
	var window: int = floori(elapsed / site_interval)
	if window == _site_window:
		return
	_site_window = window
	var index: int = window % sites.get_child_count()
	active_site = sites.get_child(index) as ReinforcementSite
	for site: ReinforcementSite in sites.get_children():
		site.set_active(site == active_site)


func toggle_pause() -> void:
	if battle_over:
		return
	get_tree().paused = not get_tree().paused
	hud.set_paused(get_tree().paused)


func restart() -> void:
	battle_audio.stop_all()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _update_status() -> void:
	hud.update_status(horde, survivor, battle_started, elapsed, active_site, site_interval)


func _update_knight_health(current: int, maximum: int) -> void:
	hud.set_knight_health(current, maximum)


func _update_horde_count(_remaining: int) -> void:
	if horde.permanent_count() == 0:
		_finish_battle(false)
	_update_status()


func _finish_battle(won: bool) -> void:
	if battle_over:
		return
	battle_over = true
	battle_audio.finish(won)
	horde.stop()
	survivor.stop_combat()
	hud.show_result(won, elapsed, horde)
