class_name ReinforcementSite
extends Node3D

signal summoned()

@export var reserves: int = 12
@export var radius: float = 2.4
@export var summon_time: float = 2.0
var remaining: int = 0
var active: bool = false
var progress: float = 0.0
@onready var visual: ReinforcementVisual = $Visual


func _ready() -> void:
	_update_visuals()


func set_active(value: bool) -> void:
	active = value
	remaining = reserves if active else 0
	progress = 0.0
	_update_visuals()


func update_recruitment(horde: HordeController, delta: float) -> void:
	if not active or remaining <= 0 or not horde.commands_enabled:
		return
	var occupied: bool = false
	if horde.command_position.distance_to(global_position) <= radius:
		for agent: HordeAgent in horde.agents:
			if agent.global_position.distance_to(global_position) <= radius:
				occupied = true
				break
	if not occupied or horde.agents.size() >= horde.max_agents:
		progress = 0.0
	else:
		progress += delta
		if progress >= summon_time:
			if horde.recruit(remaining, global_position) > 0:
				# A successful visit consumes this activation, including excess stock.
				set_active(false)
				summoned.emit()
				return
			progress = 0.0
	_update_visuals()


func _update_visuals() -> void:
	visual.set_available(active and remaining > 0)
	visual.set_progress(progress / summon_time)
