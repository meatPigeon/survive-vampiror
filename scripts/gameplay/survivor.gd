class_name Survivor
extends Node3D

signal phase_changed(phase: int)

enum Attack { SWEEP, CHARGE, SPIN }
enum State { HUNT, WINDUP, STRIKE, RECOVERY, STOPPED }

@export var body_radius: float = 0.55
@export var move_speed: float = 1.5
@export var attack_range: float = 2.2
@export var attack_angle: float = 160.0
@export var attack_damage: int = 15
@export var windup_time: float = 1.3
@export var swing_time: float = 0.18
@export var recovery_time: float = 1.4
@export var charge_range: float = 8.0
@export var charge_width: float = 2.0
@export var charge_damage: int = 20
@export var charge_windup: float = 1.5
@export var charge_duration: float = 0.7
@export var charge_recovery: float = 2.0
@export var spin_radius: float = 3.2
@export var spin_damage: int = 20
@export var spin_windup: float = 1.8
@export var spin_recovery: float = 2.4

var phase: int = 1
var state: State = State.HUNT
var attack_kind: Attack = Attack.SWEEP
var movement_bounds := Rect2(-22, -16, 44, 32)
var _time: float = 0.0
var _attack_number: int = 0
var _attack_direction := Vector3.FORWARD
var _origin: Vector3
var _charge_end: Vector3
var _hit_ids: Dictionary = {}

@onready var visual: KnightVisual = $Visual
@onready var animation_player: AnimationPlayer = $Visual/AnimationPlayer
@onready var health: Health = $Health
@onready var attack_area: AttackPreview = $AttackArea


func _ready() -> void:
	health.changed.connect(_on_health_changed)
	health.died.connect(_on_died)


func update_combat(agents: Array[HordeAgent], delta: float) -> void:
	if state == State.STOPPED or not health.is_alive():
		return
	match state:
		State.HUNT:
			_hunt(agents, delta)
		State.WINDUP:
			_time += delta
			if _time >= current_windup():
				state = State.STRIKE
				_time = 0.0
				visual.strike()
				if attack_kind != Attack.CHARGE:
					_hit_area(agents)
		State.STRIKE:
			_time += delta
			if attack_kind == Attack.CHARGE:
				var previous: Vector3 = global_position
				global_position = _origin.lerp(_charge_end, minf(_time / charge_duration, 1.0))
				_hit_charge(agents, previous, global_position)
			if state != State.STOPPED and _time >= current_strike():
				state = State.RECOVERY
				_time = 0.0
				attack_area.hide()
				visual.recover()
		State.RECOVERY:
			_time += delta
			if _time >= current_recovery():
				state = State.HUNT
				_time = 0.0


func _hunt(agents: Array[HordeAgent], delta: float) -> void:
	var nearest: HordeAgent
	var nearest_distance: float = INF
	for agent: HordeAgent in agents:
		var distance: float = global_position.distance_to(agent.global_position)
		if agent.health.is_alive() and distance < nearest_distance:
			nearest = agent
			nearest_distance = distance
	if nearest == null:
		visual.idle()
		return
	var pattern: Array[Attack] = [Attack.SWEEP, Attack.SWEEP, Attack.CHARGE]
	if phase == 2:
		pattern = [Attack.SWEEP, Attack.CHARGE, Attack.SPIN]
	elif phase == 3:
		pattern = [Attack.CHARGE, Attack.SPIN, Attack.SWEEP, Attack.SPIN]
	var next: Attack = pattern[_attack_number % pattern.size()]
	# A distant horde is pursued with a warned charge, rather than allowed to wait forever.
	if nearest_distance > attack_range and nearest_distance <= charge_range:
		next = Attack.CHARGE
	var reach: float = charge_range if next == Attack.CHARGE else (spin_radius if next == Attack.SPIN else attack_range)
	if nearest_distance <= reach:
		_begin_attack(next, _choose_attack_target(next, agents, nearest.global_position))
		return
	var direction: Vector3 = (nearest.global_position - global_position).normalized()
	global_position = _clamp_to_floor(global_position + direction * move_speed * delta)
	visual.run(direction)


func _choose_attack_target(kind: Attack, agents: Array[HordeAgent], fallback: Vector3) -> Vector3:
	# Spin has no aiming direction. Pursuit still follows the nearest zombie.
	if kind == Attack.SPIN:
		return fallback
	var reach: float = sqrt(charge_range * charge_range + charge_width * charge_width * 0.25) if kind == Attack.CHARGE else attack_range
	var targets: Array[Vector3] = []
	for agent: HordeAgent in agents:
		if agent.health.is_alive() and global_position.distance_to(agent.global_position) <= reach:
			targets.append(agent.global_position)
	var best_target: Vector3 = fallback
	var best_count: int = _count_targets(kind, fallback, targets)
	for target: Vector3 in targets:
		var offset: Vector3 = target - global_position
		if offset.is_zero_approx():
			continue
		# Also consider the edges: the best sector/lane can lie between zombies.
		var half_angle: float = deg_to_rad(attack_angle * 0.5) if kind == Attack.SWEEP else asin(minf(1.0, charge_width * 0.5 / offset.length()))
		half_angle = maxf(0.0, half_angle - 0.0001)
		for angle: float in [0.0, -half_angle, half_angle]:
			var aim: Vector3 = global_position + offset.rotated(Vector3.UP, angle)
			var count: int = _count_targets(kind, aim, targets)
			if count > best_count:
				best_count = count
				best_target = aim
	return best_target


func _count_targets(kind: Attack, target: Vector3, targets: Array[Vector3]) -> int:
	var direction: Vector3 = (target - global_position).normalized()
	var lane_length: float = 0.0
	if kind == Attack.CHARGE:
		var end: Vector3 = _charge_endpoint(target)
		lane_length = global_position.distance_to(end)
		if lane_length < 0.1:
			return 0
		direction = (end - global_position).normalized()
	var count: int = 0
	for position: Vector3 in targets:
		var offset: Vector3 = position - global_position
		if kind == Attack.SWEEP:
			if offset.normalized().dot(direction) >= cos(deg_to_rad(attack_angle * 0.5)):
				count += 1
		else:
			var along: float = offset.dot(direction)
			if along >= 0.0 and along <= lane_length and (offset - direction * along).length() <= charge_width * 0.5:
				count += 1
	return count


func _charge_endpoint(target: Vector3) -> Vector3:
	var offset: Vector3 = target - global_position
	return _clamp_to_floor(global_position + offset.normalized() * minf(charge_range, offset.length() + 1.5))


func _begin_attack(kind: Attack, target: Vector3) -> void:
	attack_kind = kind
	_attack_number += 1
	_attack_direction = (target - global_position).normalized()
	if _attack_direction.is_zero_approx():
		_attack_direction = Vector3.FORWARD
	_origin = global_position
	_charge_end = _charge_endpoint(target)
	if kind == Attack.CHARGE and _origin.distance_to(_charge_end) < 0.1:
		kind = Attack.SWEEP
		attack_kind = kind
	_hit_ids.clear()
	state = State.WINDUP
	_time = 0.0
	match kind:
		Attack.SWEEP:
			attack_area.show_arc(_origin, _attack_direction, attack_range, attack_angle, Color(1, 0.3, 0.08, 0.5))
		Attack.CHARGE:
			_attack_direction = (_charge_end - _origin).normalized()
			attack_area.show_lane(_origin, _attack_direction, _origin.distance_to(_charge_end), charge_width, Color(1, 0.8, 0.1, 0.5))
		Attack.SPIN:
			attack_area.show_arc(_origin, _attack_direction, spin_radius, 360.0, Color(0.8, 0.2, 1, 0.45))
	visual.face(_attack_direction)
	visual.attack(StringName(Attack.keys()[kind].to_lower()), current_windup(), current_strike(), current_recovery())


func _hit_area(agents: Array[HordeAgent]) -> void:
	for agent: HordeAgent in agents.duplicate():
		if state == State.STOPPED:
			break
		var offset: Vector3 = agent.global_position - _origin
		var inside: bool = offset.length() <= spin_radius if attack_kind == Attack.SPIN else (
			offset.length() <= attack_range and offset.normalized().dot(_attack_direction) >= cos(deg_to_rad(attack_angle * 0.5)))
		if inside:
			agent.health.take_damage(spin_damage if attack_kind == Attack.SPIN else attack_damage)


func _hit_charge(agents: Array[HordeAgent], from: Vector3, to: Vector3) -> void:
	for agent: HordeAgent in agents.duplicate():
		if state == State.STOPPED:
			break
		if _hit_ids.has(agent.get_instance_id()):
			continue
		var along_lane: float = (agent.global_position - _origin).dot(_attack_direction)
		if along_lane < 0.0 or along_lane > _origin.distance_to(_charge_end):
			continue
		var closest: Vector3 = Geometry3D.get_closest_point_to_segment(agent.global_position, from, to)
		if agent.global_position.distance_to(closest) <= charge_width * 0.5:
			_hit_ids[agent.get_instance_id()] = true
			agent.health.take_damage(charge_damage)


func current_windup() -> float:
	return charge_windup if attack_kind == Attack.CHARGE else (spin_windup if attack_kind == Attack.SPIN else windup_time)


func current_strike() -> float:
	return charge_duration if attack_kind == Attack.CHARGE else (0.5 if attack_kind == Attack.SPIN else swing_time)


func current_recovery() -> float:
	return charge_recovery if attack_kind == Attack.CHARGE else (spin_recovery if attack_kind == Attack.SPIN else recovery_time)


func status_text() -> String:
	if state == State.STOPPED:
		return ""
	if state == State.RECOVERY:
		return "EXPOSED — bite now!"
	if state == State.HUNT:
		return "Hunting the horde"
	return ["SWEEP — move sideways", "CHARGE — leave the yellow lane", "SPIN — leave the purple circle"][attack_kind]


func stop_combat() -> void:
	state = State.STOPPED
	attack_area.hide()
	if health.is_alive():
		visual.idle()


func _clamp_to_floor(point: Vector3) -> Vector3:
	point.x = clampf(point.x, movement_bounds.position.x + body_radius, movement_bounds.end.x - body_radius)
	point.z = clampf(point.z, movement_bounds.position.y + body_radius, movement_bounds.end.y - body_radius)
	return point


func _on_health_changed(current: int, maximum: int) -> void:
	visual.flash()
	var next_phase: int = 3 if current * 3 <= maximum else (2 if current * 3 <= maximum * 2 else 1)
	if next_phase > phase:
		phase = next_phase
		phase_changed.emit(phase)


func _on_died() -> void:
	stop_combat()
	visual.die()
