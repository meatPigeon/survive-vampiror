extends Node3D

var battle_over: bool = false

@onready var horde: HordeController = $Horde
@onready var survivor: Survivor = $Survivor
@onready var health_bar: ProgressBar = $HUD/Status/KnightHealth
@onready var knight_label: Label = $HUD/Status/KnightLabel
@onready var horde_label: Label = $HUD/Status/HordeLabel
@onready var result_label: Label = $HUD/Result


func _ready() -> void:
	# Resolve combat after this frame's crowd movement.
	process_physics_priority = 1
	survivor.health.changed.connect(_update_knight_health)
	survivor.health.died.connect(_finish_battle.bind(true))
	horde.count_changed.connect(_update_horde_count)
	_update_knight_health(survivor.health.current_health, survivor.health.max_health)
	_update_horde_count(horde.agents.size())


func _physics_process(delta: float) -> void:
	if battle_over:
		return
	survivor.update_combat(horde.agents, delta)
	for agent: HordeAgent in horde.agents:
		if battle_over:
			break
		agent.update_combat(survivor, delta)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		get_tree().reload_current_scene()


func _update_knight_health(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	knight_label.text = "Knight: %d / %d" % [current, maximum]


func _update_horde_count(remaining: int) -> void:
	horde_label.text = "Zombies: %d / %d" % [remaining, horde.agent_count]
	if remaining == 0:
		_finish_battle(false)


func _finish_battle(won: bool) -> void:
	if battle_over:
		return
	battle_over = true
	horde.stop()
	survivor.stop_combat()
	result_label.text = ("Victory! The knight has fallen." if won else "Defeat! The horde is gone.") + "\nPress R to restart"
	result_label.show()
