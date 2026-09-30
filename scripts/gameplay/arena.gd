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
@onready var health_bar: ProgressBar = $HUD/Status/KnightHealth
@onready var knight_label: Label = $HUD/Status/KnightLabel
@onready var horde_label: Label = $HUD/Status/HordeLabel
@onready var fight_label: Label = $HUD/Status/FightLabel
@onready var sprint_label: Label = $HUD/Status/SprintLabel
@onready var reserves_label: Label = $HUD/ReservesLabel
@onready var result_label: Label = $HUD/Result


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
	result_label.text = "Paused\nEsc: resume   R: restart"
	result_label.visible = get_tree().paused


func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _update_status() -> void:
	fight_label.text = "Click the floor to begin. Defeat the knight." if not battle_started else (
		"Phase %d/3  |  %d:%02d\n%s" % [survivor.phase, int(elapsed) / 60, int(elapsed) % 60, survivor.status_text()])
	sprint_label.text = "SPACE: sprint READY" if horde.sprint_cooldown_remaining <= 0.0 else (
		"SPACE: sprint %.1fs" % horde.sprint_cooldown_remaining)
	horde_label.text = "Permanent: %d  |  Temporary: %d\nTotal: %d / %d" % [
		horde.permanent_count(), horde.temporary_count(), horde.agents.size(), horde.max_agents]
	if horde.temporary_count() > 0:
		horde_label.text += "  |  Next expiry: %ds" % ceili(horde.next_expiration())
	reserves_label.text = "Reinforcements open\nwhen the fight starts."
	if active_site != null:
		reserves_label.text = "%s: %d temporary recruits\nNext site in %ds" % [
			active_site.name, active_site.remaining, ceili(site_interval - fmod(elapsed, site_interval))]


func _update_knight_health(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	knight_label.text = "Knight: %d / %d" % [current, maximum]


func _update_horde_count(_remaining: int) -> void:
	if horde.permanent_count() == 0:
		_finish_battle(false)
	_update_status()


func _finish_battle(won: bool) -> void:
	if battle_over:
		return
	battle_over = true
	horde.stop()
	survivor.stop_combat()
	result_label.text = ("Victory! The knight has fallen." if won else "Defeat! No permanent zombies remain.") + (
		"\nTime %d:%02d  |  Killed %d  |  Expired %d\nRecruited %d  |  Press R to play again" % [
			int(elapsed) / 60, int(elapsed) % 60, horde.casualties, horde.expired_count, horde.recruited])
	result_label.show()
