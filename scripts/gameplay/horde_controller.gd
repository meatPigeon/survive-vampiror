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
var move_direction := Vector3.ZERO
var movement_bounds: Rect2
var _has_command: bool = false
var commands_enabled: bool = true
var sprint_unlocked: bool = false
var sprint_remaining: float = 0.0
var sprint_cooldown_remaining: float = 0.0
var casualties: int = 0
var recruited: int = 0
var expired_count: int = 0

@onready var ability: HordeAbility = $Ability
@onready var abilities: Array[HordeAbility] = [$Ability, $SecondAbility]


func roll_rewards() -> Array[int]:
	var pool: Array[int] = []
	for upgrade: int in [HordeAbility.Upgrade.DETONATION, HordeAbility.Upgrade.SLING, HordeAbility.Upgrade.FEAST, HordeAbility.Upgrade.SPRINT]:
		if not has_upgrade(upgrade):
			pool.append(upgrade)
	pool.shuffle()
	return pool.slice(0, 2)


func has_upgrade(upgrade: int) -> bool:
	if upgrade == HordeAbility.Upgrade.SPRINT:
		return sprint_unlocked
	for current: HordeAbility in abilities:
		if upgrade != HordeAbility.Upgrade.NONE and current.upgrade == upgrade:
			return true
	return false


func grant_ability(upgrade: int) -> bool:
	if has_upgrade(upgrade):
		return false
	# Sprint is a reward that unlocks the existing Space action, not a Q/E slot.
	if upgrade == HordeAbility.Upgrade.SPRINT:
		sprint_unlocked = true
		return true
	if upgrade < HordeAbility.Upgrade.DETONATION or upgrade >= HordeAbility.Upgrade.NONE:
		return false
	for current: HordeAbility in abilities:
		if current.upgrade == HordeAbility.Upgrade.NONE:
			current.upgrade = upgrade as HordeAbility.Upgrade
			return true
	return false


func _ready() -> void:
	var ground_bounds: AABB = ground.mesh.get_aabb()
	var corner: Vector3 = ground.to_global(ground_bounds.position)
	movement_bounds = Rect2(Vector2(corner.x, corner.z), Vector2(ground_bounds.size.x, ground_bounds.size.z))
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


func add_permanent_reward(amount: int) -> void:
	if amount <= 0 or permanent_count() == 0:
		return
	var center := Vector3.ZERO
	for agent: HordeAgent in agents:
		center += agent.global_position
	center /= float(agents.size())
	# Round rewards grant their full amount; only grave recruits use max_agents.
	for index: int in range(amount):
		var angle: float = float(index + recruited) * 2.399963
		var radius: float = spawn_spacing * sqrt(float(index + 1))
		_spawn_agent(center + Vector3(cos(angle), 0.0, sin(angle)) * radius)
	recruited += amount
	count_changed.emit(agents.size())


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
	if not sprint_unlocked or get_tree().paused or not commands_enabled or not _has_command or sprint_cooldown_remaining > 0.0:
		return
	sprint_remaining = sprint_duration
	sprint_cooldown_remaining = sprint_cooldown
	sprint_started.emit()


func command_direction(direction: Vector3) -> void:
	if not commands_enabled:
		return
	var previous: Vector3 = move_direction
	move_direction = Vector3(direction.x, 0.0, direction.z).limit_length()
	if not move_direction.is_zero_approx():
		_has_command = true
		if not move_direction.is_equal_approx(previous):
			move_commanded.emit()


func _physics_process(delta: float) -> void:
	if not _has_command:
		return
	sprint_remaining = maxf(0.0, sprint_remaining - delta)
	sprint_cooldown_remaining = maxf(0.0, sprint_cooldown_remaining - delta)
	var speed_scale: float = sprint_multiplier if sprint_remaining > 0.0 else 1.0
	var distance: float = 0.0
	var center := Vector3.ZERO
	var moving_count: int = 0
	for agent: HordeAgent in agents:
		if not agent.ability_locked:
			center += agent.global_position
			moving_count += 1
	center /= maxf(1.0, moving_count)
	for agent: HordeAgent in agents:
		if agent.ability_locked:
			continue
		var previous: Vector3 = agent.global_position
		if move_direction.is_zero_approx():
			agent.stop()
		else:
			agent.move_in_direction(move_direction, agents, movement_bounds, delta, survivor, speed_scale, center)
		distance += previous.distance_to(agent.global_position)
	if not agents.is_empty():
		moved.emit(distance / float(agents.size()))


func stop() -> void:
	for current: HordeAbility in abilities:
		current.cancel()
	commands_enabled = false
	_has_command = false
	sprint_remaining = 0.0
	move_direction = Vector3.ZERO
	for agent: HordeAgent in agents:
		agent.stop()


func _on_agent_died(agent: HordeAgent) -> void:
	for current: HordeAbility in abilities:
		current.forget_agent(agent)
	agents.erase(agent)
	if agent.expired:
		expired_count += 1
	else:
		casualties += 1
	count_changed.emit(agents.size())
