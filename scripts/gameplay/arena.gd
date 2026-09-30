extends Node3D

@export_range(1.0, 300.0) var site_interval: float = 30.0
@export_range(0.0, 60.0, 0.5) var site_respawn_delay: float = 5.0

var battle_started: bool = false
var battle_over: bool = false
var elapsed: float = 0.0
var active_site: ReinforcementSite
var _last_site: ReinforcementSite
var _next_site_at: float = 0.0
var _site_random := RandomNumberGenerator.new()

@onready var horde: HordeController = $Horde
@onready var survivor: Survivor = $Survivor
@onready var sites: Node3D = $Reinforcements
@onready var hud: BattleHUD = $HUD
@onready var battle_audio: BattleAudio = $BattleAudio


func _ready() -> void:
	process_physics_priority = 1
	_site_random.randomize()
	for site: ReinforcementSite in sites.get_children():
		site.summoned.connect(_on_site_summoned.bind(site))
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
		battle_audio.start_music()
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
	if not battle_over and active_site != null:
		# A successful summon may switch sites synchronously; tick only this one.
		active_site.update_recruitment(horde, delta)
	_update_status()


func _update_site_schedule() -> void:
	if not battle_started or battle_over:
		return
	if elapsed >= _next_site_at:
		_open_next_site()


func _open_next_site() -> void:
	var candidates: Array[ReinforcementSite] = []
	for site: ReinforcementSite in sites.get_children():
		if site != _last_site:
			candidates.append(site)
	if candidates.is_empty():
		return
	# Preserve the authored opening; later destinations cannot repeat immediately.
	active_site = candidates[0] if _last_site == null else candidates[_site_random.randi_range(0, candidates.size() - 1)]
	_last_site = active_site
	_next_site_at = elapsed + site_interval
	for site: ReinforcementSite in sites.get_children():
		site.set_active(site == active_site)


func _on_site_summoned(site: ReinforcementSite) -> void:
	if battle_started and not battle_over and site == active_site:
		active_site = null
		_next_site_at = elapsed + site_respawn_delay
		_update_site_schedule()
		_update_status()


func site_time_left() -> float:
	return maxf(0.0, _next_site_at - elapsed) if battle_started else 0.0


func toggle_pause() -> void:
	if battle_over:
		return
	get_tree().paused = not get_tree().paused
	hud.set_paused(get_tree().paused)


func restart() -> void:
	battle_audio.stop_all()
	hud.audio_controls.stop_preview()
	get_tree().paused = false
	get_tree().reload_current_scene()


func return_to_menu() -> void:
	battle_audio.stop_all()
	hud.audio_controls.stop_preview()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _update_status() -> void:
	hud.update_status(horde, survivor, battle_started, elapsed, active_site, site_time_left())


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
