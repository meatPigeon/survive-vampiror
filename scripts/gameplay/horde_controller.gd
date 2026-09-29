class_name HordeController
extends Node3D

signal count_changed(remaining: int)

@export var agent_scene: PackedScene = preload("res://scenes/components/horde_agent.tscn")
@export var agent_count: int = 40
@export var spawn_center := Vector3(-8.0, 0.0, 3.0)
@export var spawn_spacing: float = 0.8
@export var ground: MeshInstance3D
@export var survivor: Survivor

var agents: Array[HordeAgent] = []
var command_position: Vector3
var movement_bounds: Rect2
var _has_command: bool = false
var commands_enabled: bool = true

@onready var target_marker: MeshInstance3D = $TargetMarker


func _ready() -> void:
	var ground_bounds: AABB = ground.mesh.get_aabb()
	var corner: Vector3 = ground.to_global(ground_bounds.position)
	movement_bounds = Rect2(Vector2(corner.x, corner.z), Vector2(ground_bounds.size.x, ground_bounds.size.z))
	command_position = spawn_center
	for index: int in range(agent_count):
		var agent: HordeAgent = agent_scene.instantiate() as HordeAgent
		add_child(agent)
		agent.died.connect(_on_agent_died)
		# A loose initial scatter; agents have no assigned formation or destination slot.
		var angle: float = float(index) * 2.399963
		var radius: float = spawn_spacing * sqrt(float(index))
		agent.global_position = spawn_center + Vector3(cos(angle), 0.0, sin(angle)) * radius
		agents.append(agent)


func command_move(position_on_ground: Vector3) -> void:
	if not commands_enabled:
		return
	command_position = Vector3(
		clampf(position_on_ground.x, movement_bounds.position.x, movement_bounds.end.x),
		ground.global_position.y,
		clampf(position_on_ground.z, movement_bounds.position.y, movement_bounds.end.y)
	)
	_has_command = true
	target_marker.global_position = command_position + Vector3.UP * 0.04
	target_marker.show()


func _physics_process(delta: float) -> void:
	if not _has_command:
		return
	for agent: HordeAgent in agents:
		agent.move_toward_command(command_position, agents, movement_bounds, delta, survivor)


func stop() -> void:
	commands_enabled = false
	_has_command = false
	target_marker.hide()
	for agent: HordeAgent in agents:
		agent.stop()


func _on_agent_died(agent: HordeAgent) -> void:
	agents.erase(agent)
	count_changed.emit(agents.size())
