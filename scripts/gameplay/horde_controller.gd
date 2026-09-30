class_name HordeController
extends Node3D

signal count_changed(remaining: int)
signal move_commanded()
signal sprint_started()
signal moved(mean_distance: float)

@export var agent_scene: PackedScene = preload("res://scenes/components/horde_agent.tscn")
@export var agent_count: int = 40
@export var spawn_center := Vector3(-8.0, 0.0, 3.0)
@export var spawn_spacing: float = 0.8
@export var ground: MeshInstance3D
@export var survivor: Survivor
@export var max_agents: int = 60
@export_range(1.0, 300.0) var temporary_lifetime: float = 45.0
@export var sprint_duration: float = 1.4
@export var sprint_cooldown: float = 7.0
@export var sprint_multiplier: float = 2.0

var agents: Array[HordeAgent] = []
var command_position: Vector3
var movement_bounds: Rect2
var _has_command: bool = false
var commands_enabled: bool = true
var sprint_remaining: float = 0.0
var sprint_cooldown_remaining: float = 0.0
var casualties: int = 0
var recruited: int = 0
var expired_count: int = 0

@onready var target_marker: MeshInstance3D = $TargetMarker


func _ready() -> void:
	var ground_bounds: AABB = ground.mesh.get_aabb()
	var corner: Vector3 = ground.to_global(ground_bounds.position)
	movement_bounds = Rect2(Vector2(corner.x, corner.z), Vector2(ground_bounds.size.x, ground_bounds.size.z))
	command_position = spawn_center
	for index: int in range(agent_count):
		# A loose initial scatter; agents have no assigned formation or destination slot.
		var angle: float = float(index) * 2.399963
		var radius: float = spawn_spacing * sqrt(float(index))
		_spawn_agent(spawn_center + Vector3(cos(angle), 0.0, sin(angle)) * radius)


func _spawn_agent(spawn_position: Vector3, kind: HordeAgent.Kind = HordeAgent.Kind.PERMANENT) -> void:
	var agent: HordeAgent = agent_scene.instantiate() as HordeAgent
	agent.kind = kind
	agent.lifetime_remaining = temporary_lifetime if kind == HordeAgent.Kind.TEMPORARY else 0.0
	add_child(agent)
	agent.died.connect(_on_agent_died)
	spawn_position.x = clampf(spawn_position.x, movement_bounds.position.x + agent.body_radius, movement_bounds.end.x - agent.body_radius)
	spawn_position.z = clampf(spawn_position.z, movement_bounds.position.y + agent.body_radius, movement_bounds.end.y - agent.body_radius)
	agent.global_position = spawn_position
	agents.append(agent)


func recruit(amount: int, location: Vector3) -> int:
	if not commands_enabled or permanent_count() == 0:
		return 0
	var added: int = maxi(0, mini(amount, max_agents - agents.size()))
	for index: int in range(added):
		var angle: float = float(index + recruited) * 2.399963
		var radius: float = spawn_spacing * sqrt(float(index + 1))
		_spawn_agent(location + Vector3(cos(angle), 0.0, sin(angle)) * radius, HordeAgent.Kind.TEMPORARY)
	recruited += added
	if added > 0:
		count_changed.emit(agents.size())
	return added


func permanent_count() -> int:
	var count: int = 0
	for agent: HordeAgent in agents:
		if agent.kind == HordeAgent.Kind.PERMANENT:
			count += 1
	return count


func temporary_count() -> int:
	return agents.size() - permanent_count()


func next_expiration() -> float:
	var remaining: float = INF
	for agent: HordeAgent in agents:
		if agent.kind == HordeAgent.Kind.TEMPORARY:
			remaining = minf(remaining, agent.lifetime_remaining)
	return remaining


func update_lifetimes(delta: float) -> void:
	if not commands_enabled or not _has_command:
		return
	for agent: HordeAgent in agents.duplicate():
		agent.update_lifetime(delta)


func command_sprint() -> void:
	if not commands_enabled or not _has_command or sprint_cooldown_remaining > 0.0:
		return
	sprint_remaining = sprint_duration
	sprint_cooldown_remaining = sprint_cooldown
	sprint_started.emit()


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
	move_commanded.emit()


func _physics_process(delta: float) -> void:
	if not _has_command:
		return
	sprint_remaining = maxf(0.0, sprint_remaining - delta)
	sprint_cooldown_remaining = maxf(0.0, sprint_cooldown_remaining - delta)
	var speed_scale: float = sprint_multiplier if sprint_remaining > 0.0 else 1.0
	var distance: float = 0.0
	for agent: HordeAgent in agents:
		var previous: Vector3 = agent.global_position
		agent.move_toward_command(command_position, agents, movement_bounds, delta, survivor, speed_scale)
		distance += previous.distance_to(agent.global_position)
	if not agents.is_empty():
		moved.emit(distance / float(agents.size()))


func stop() -> void:
	commands_enabled = false
	_has_command = false
	sprint_remaining = 0.0
	target_marker.hide()
	for agent: HordeAgent in agents:
		agent.stop()


func _on_agent_died(agent: HordeAgent) -> void:
	agents.erase(agent)
	if agent.expired:
		expired_count += 1
	else:
		casualties += 1
	count_changed.emit(agents.size())
