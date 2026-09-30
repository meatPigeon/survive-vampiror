class_name ReinforcementSite
extends Node3D

@export var reserves: int = 12
@export var radius: float = 2.4
@export var summon_time: float = 2.0
var remaining: int = 0
var active: bool = false
var progress: float = 0.0
@onready var label: Label3D = $Label


func _ready() -> void:
	_update_label()


func set_active(value: bool) -> void:
	active = value
	remaining = reserves if active else 0
	progress = 0.0
	_update_label()


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
			remaining -= horde.recruit(remaining, global_position)
			progress = 0.0
	_update_label()


func _update_label() -> void:
	$Ring.visible = active and remaining > 0
	label.visible = active and remaining > 0
	if not active:
		label.text = ""
	elif remaining == 0:
		label.text = ""
	elif progress > 0.0:
		label.text = "+%d  %d%%" % [remaining, roundi(progress / summon_time * 100.0)]
	else:
		label.text = "%s  +%d" % [name, remaining]
