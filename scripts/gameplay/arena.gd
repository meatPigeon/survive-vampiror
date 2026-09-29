extends Node3D

var battle_started: bool = false
var battle_over: bool = false
var elapsed: float = 0.0

@onready var horde: HordeController = $Horde
@onready var survivor: Survivor = $Survivor
@onready var sites: Node3D = $Reinforcements
@onready var health_bar: ProgressBar = $HUD/Status/KnightHealth
@onready var knight_label: Label = $HUD/Status/KnightLabel
@onready var horde_label: Label = $HUD/Status/HordeLabel
@onready var fight_label: Label = $HUD/Status/FightLabel
@onready var sprint_label: Label = $HUD/Status/SprintLabel
@onready var reserves_label: Label = $HUD/Status/ReservesLabel
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
	if not battle_over:
		battle_started = true


func _physics_process(delta: float) -> void:
	if not battle_started or battle_over:
		return
	elapsed += delta
	survivor.update_combat(horde.agents, delta)
	for agent: HordeAgent in horde.agents:
		if battle_over:
			break
		agent.update_combat(survivor, delta)
	if not battle_over:
		for site: ReinforcementSite in sites.get_children():
			site.update_recruitment(horde, delta)
	_update_status()


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
	var reserves: int = 0
	for site: ReinforcementSite in sites.get_children():
		reserves += site.remaining
	reserves_label.text = "Reserve zombies: %d (green circles)" % reserves


func _update_knight_health(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	knight_label.text = "Knight: %d / %d" % [current, maximum]


func _update_horde_count(remaining: int) -> void:
	horde_label.text = "Zombies: %d / %d" % [remaining, horde.max_agents]
	if remaining == 0:
		_finish_battle(false)


func _finish_battle(won: bool) -> void:
	if battle_over:
		return
	battle_over = true
	horde.stop()
	survivor.stop_combat()
	result_label.text = ("Victory! The knight has fallen." if won else "Defeat! The horde is gone.") + (
		"\nTime %d:%02d  |  Lost %d  |  Recruited %d\nPress R to play again" % [int(elapsed) / 60, int(elapsed) % 60, horde.casualties, horde.recruited])
	result_label.show()
