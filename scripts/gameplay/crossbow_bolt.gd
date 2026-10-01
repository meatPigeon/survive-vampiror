class_name CrossbowBolt
extends Node3D

@export var speed: float = 16.0
@export var hit_radius: float = 0.4
@export var flight_height: float = 1.2

var flying: bool = false
var _direction := Vector3.FORWARD
var _remaining: float = 0.0


func launch(origin: Vector3, direction: Vector3, distance: float) -> void:
	global_position = origin
	$Shaft.position.y = flight_height
	$Tip.position.y = flight_height
	_direction = direction.normalized()
	rotation.y = atan2(-_direction.x, -_direction.z)
	_remaining = distance
	flying = true
	show()


func advance(agents: Array[HordeAgent], delta: float) -> bool:
	if not flying:
		return false
	var travel: float = minf(speed * delta, _remaining)
	var origin: Vector3 = global_position
	var end: Vector3 = origin + _direction * travel
	var hits: Array[HordeAgent] = []
	var entries: Dictionary[HordeAgent, float] = {}
	# Sweep the whole segment, so a fast bolt cannot tunnel through a zombie.
	for agent: HordeAgent in agents:
		if not agent.health.is_alive():
			continue
		var offset: Vector3 = agent.global_position - origin
		offset.y = 0.0
		var along: float = offset.dot(_direction)
		var side_squared: float = maxf(0.0, offset.length_squared() - along * along)
		if side_squared > hit_radius * hit_radius:
			continue
		var half_chord: float = sqrt(hit_radius * hit_radius - side_squared)
		var entry: float = maxf(0.0, along - half_chord)
		if along + half_chord >= 0.0 and entry <= travel:
			hits.append(agent)
			entries[agent] = entry
	# Death removes zombies from the live horde. Resolve a separate, ordered list
	# so piercing is stable even over a large tick and stops at a terminal defeat.
	hits.sort_custom(func(a: HordeAgent, b: HordeAgent) -> bool: return entries[a] < entries[b])
	var hit: bool = false
	for agent: HordeAgent in hits:
		if not flying:
			return hit
		if not is_instance_valid(agent) or not agent.health.is_alive():
			continue
		global_position = origin + _direction * entries[agent]
		hit = true
		agent.health.take_damage(agent.health.current_health)
	if not flying:
		return hit
	global_position = end
	_remaining -= travel
	if _remaining <= 0.0:
		stop()
	return hit


func stop() -> void:
	flying = false
	hide()
