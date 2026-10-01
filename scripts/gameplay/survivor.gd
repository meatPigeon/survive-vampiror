class_name Survivor
extends Node3D

signal phase_changed(phase: int)
signal attack_warned(kind: Attack)
signal attack_struck(kind: Attack)
signal attack_hit()

enum Attack { SWEEP, CHARGE, SPIN, CROSSBOW, RUSH }
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
@export var crossbow_range: float = 16.0
@export var crossbow_minimum_range: float = 3.5
@export var crossbow_windup: float = 1.2
@export var crossbow_recovery: float = 1.6
@export var crossbow_interval: float = 6.0
@export var mounted_speed_multiplier: float = 2.0
@export var mounted_charge_multiplier: float = 1.4
@export var rush_range: float = 16.0
@export var rush_windup: float = 1.4
@export var rush_duration: float = 4.2
@export var rush_recovery: float = 2.8
@export var rush_interval: float = 14.0
@export var rush_speed: float = 8.0
@export var rush_acceleration: float = 12.0
@export var rush_turn_speed: float = 50.0
@export var rush_turn_acceleration: float = 100.0
@export var rush_width: float = 2.0
@export var rush_damage: int = 20

var lethal_attacks: bool = false
var wave: int = 1
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
var _crossbow_cooldown: float = 0.0
var _rush_cooldown: float = 0.0
var _rush_speed: float = 0.0
var _rush_turn: float = 0.0

@onready var visual: KnightVisual = $Visual
@onready var animation_player: AnimationPlayer = $Visual/AnimationPlayer
@onready var health: Health = $Health
@onready var attack_area: AttackPreview = $AttackArea
@onready var bolt: CrossbowBolt = $CrossbowBolt
@onready var _base_speed: float = move_speed
@onready var _base_charge_duration: float = charge_duration
@onready var _base_body_radius: float = body_radius


func _ready() -> void:
	health.changed.connect(_on_health_changed)
	health.died.connect(_on_died)


func configure_wave(index: int, maximum_health: int) -> void:
	wave = index
	move_speed = _base_speed * (mounted_speed_multiplier if wave >= 3 else 1.0)
	charge_duration = _base_charge_duration / (mounted_charge_multiplier if wave >= 3 else 1.0)
	body_radius = 0.75 if wave >= 3 else _base_body_radius
	bolt.flight_height = 1.7 if wave >= 3 else 1.2
	health.max_health = maximum_health
	health.current_health = maximum_health
	phase = 1
	_crossbow_cooldown = 1.5
	_rush_cooldown = 3.0
	_rush_speed = 0.0
	_rush_turn = 0.0
	visual.set_equipment(wave)
	health.changed.emit(maximum_health, maximum_health)


func update_combat(agents: Array[HordeAgent], delta: float) -> void:
	if state == State.STOPPED or not health.is_alive():
		return
	_crossbow_cooldown = maxf(0.0, _crossbow_cooldown - delta)
	_rush_cooldown = maxf(0.0, _rush_cooldown - delta)
	if bolt.advance(agents, delta):
		attack_hit.emit()
	if state == State.STOPPED:
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
				attack_struck.emit(attack_kind)
				if attack_kind == Attack.CROSSBOW:
					bolt.launch(_origin, _attack_direction, crossbow_range)
				elif attack_kind not in [Attack.CHARGE, Attack.RUSH]:
					_hit_area(agents)
		State.STRIKE:
			if attack_kind == Attack.RUSH:
				_advance_rush(agents, minf(delta, maxf(0.0, rush_duration - _time)))
				if state != State.STRIKE:
					return
			_time += delta
			if attack_kind == Attack.CHARGE:
				var previous: Vector3 = global_position
				global_position = _origin.lerp(_charge_end, minf(_time / charge_duration, 1.0))
				_hit_charge(agents, previous, global_position)
			if state != State.STOPPED and _time >= current_strike():
				_begin_recovery()
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
	if wave >= 3 and _rush_cooldown <= 0.0 and nearest_distance <= rush_range:
		_begin_attack(Attack.RUSH, _horde_center(agents))
		return
	if wave >= 2 and _crossbow_cooldown <= 0.0 and nearest_distance >= crossbow_minimum_range and nearest_distance <= crossbow_range:
		_begin_attack(Attack.CROSSBOW, _choose_attack_target(Attack.CROSSBOW, agents, nearest.global_position))
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
	if kind == Attack.CROSSBOW:
		reach = crossbow_range
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
		var width: float = bolt.hit_radius * 2.0 if kind == Attack.CROSSBOW else charge_width
		var half_angle: float = deg_to_rad(attack_angle * 0.5) if kind == Attack.SWEEP else asin(minf(1.0, width * 0.5 / offset.length()))
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
	var width: float = charge_width
	if kind == Attack.CROSSBOW:
		lane_length = crossbow_range
		width = bolt.hit_radius * 2.0
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
			if along >= 0.0 and along <= lane_length and (offset - direction * along).length() <= width * 0.5:
				count += 1
	return count


func _charge_endpoint(target: Vector3) -> Vector3:
	var offset: Vector3 = target - global_position
	return _clamp_to_floor(global_position + offset.normalized() * minf(charge_range, offset.length() + 1.5))


func _begin_attack(kind: Attack, target: Vector3) -> void:
	if kind == Attack.RUSH and wave < 3:
		return
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
		Attack.RUSH:
			_rush_cooldown = rush_interval
			_rush_speed = move_speed
			_rush_turn = 0.0
			attack_area.show_rush(_origin, _attack_direction, rush_width)
		Attack.CROSSBOW:
			_crossbow_cooldown = crossbow_interval
			attack_area.show_lane(_origin, _attack_direction, crossbow_range, bolt.hit_radius * 2.0, Color(0.3, 0.85, 1.0, 0.5))
		Attack.SWEEP:
			attack_area.show_arc(_origin, _attack_direction, attack_range, attack_angle, Color(1, 0.3, 0.08, 0.5))
		Attack.CHARGE:
			_attack_direction = (_charge_end - _origin).normalized()
			attack_area.show_lane(_origin, _attack_direction, _origin.distance_to(_charge_end), charge_width, Color(1, 0.8, 0.1, 0.5))
		Attack.SPIN:
			attack_area.show_arc(_origin, _attack_direction, spin_radius, 360.0, Color(0.8, 0.2, 1, 0.45))
	visual.face(_attack_direction)
	visual.attack(StringName(Attack.keys()[kind].to_lower()), current_windup(), current_strike(), current_recovery())
	attack_warned.emit(kind)


func _horde_center(agents: Array[HordeAgent]) -> Vector3:
	var center := Vector3.ZERO
	var count: int = 0
	for agent: HordeAgent in agents:
		if agent.health.is_alive():
			center += agent.global_position
			count += 1
	return center / count if count > 0 else global_position + _attack_direction * rush_range


func _advance_rush(agents: Array[HordeAgent], delta: float) -> void:
	# Substeps retain the curved swept path even when a frame takes longer.
	var remaining: float = delta
	var turn_limit: float = deg_to_rad(rush_turn_speed)
	while remaining > 0.00001 and state == State.STRIKE:
		var step: float = minf(remaining, 1.0 / 60.0)
		remaining -= step
		var offset: Vector3 = _horde_center(agents) - global_position
		offset.y = 0.0
		var desired_turn: float = 0.0
		if offset.length_squared() > 0.25:
			var error: float = _attack_direction.signed_angle_to(offset.normalized(), Vector3.UP)
			desired_turn = clampf(error * 2.0, -turn_limit, turn_limit)
		_rush_turn = move_toward(_rush_turn, desired_turn, deg_to_rad(rush_turn_acceleration) * step)
		_attack_direction = _attack_direction.rotated(Vector3.UP, _rush_turn * step).normalized()
		_rush_speed = move_toward(_rush_speed, rush_speed, rush_acceleration * step)
		var previous: Vector3 = global_position
		var next: Vector3 = previous + _attack_direction * _rush_speed * step
		global_position = _clamp_to_floor(next)
		_hit_rush(agents, previous, global_position)
		if state == State.STOPPED:
			return
		if not global_position.is_equal_approx(next):
			_begin_recovery()
			return
	visual.steer_rush(_attack_direction, _rush_turn / maxf(turn_limit, 0.001))
	attack_area.follow_heading(global_position, _attack_direction)


func _hit_rush(agents: Array[HordeAgent], from: Vector3, to: Vector3) -> void:
	var hit: bool = false
	for agent: HordeAgent in agents.duplicate():
		if state == State.STOPPED:
			break
		if not agent.health.is_alive() or _hit_ids.has(agent.get_instance_id()):
			continue
		var closest: Vector3 = Geometry3D.get_closest_point_to_segment(agent.global_position, from, to)
		if agent.global_position.distance_to(closest) <= rush_width * 0.5:
			_hit_ids[agent.get_instance_id()] = true
			_damage_agent(agent, rush_damage)
			hit = true
	if hit:
		attack_hit.emit()


func _begin_recovery() -> void:
	state = State.RECOVERY
	_time = 0.0
	_rush_speed = 0.0
	_rush_turn = 0.0
	attack_area.hide()
	visual.recover()


func _hit_area(agents: Array[HordeAgent]) -> void:
	var hit: bool = false
	for agent: HordeAgent in agents.duplicate():
		if state == State.STOPPED:
			break
		var offset: Vector3 = agent.global_position - _origin
		var inside: bool = offset.length() <= spin_radius if attack_kind == Attack.SPIN else (
			offset.length() <= attack_range and offset.normalized().dot(_attack_direction) >= cos(deg_to_rad(attack_angle * 0.5)))
		if inside:
			_damage_agent(agent, spin_damage if attack_kind == Attack.SPIN else attack_damage)
			hit = true
	if hit:
		attack_hit.emit()


func _hit_charge(agents: Array[HordeAgent], from: Vector3, to: Vector3) -> void:
	var hit: bool = false
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
			_damage_agent(agent, charge_damage)
			hit = true
	if hit:
		attack_hit.emit()


func _damage_agent(agent: HordeAgent, damage: int) -> void:
	agent.health.take_damage(agent.health.current_health if lethal_attacks else damage)


func current_windup() -> float:
	if attack_kind == Attack.RUSH:
		return rush_windup
	if attack_kind == Attack.CROSSBOW:
		return crossbow_windup
	return charge_windup if attack_kind == Attack.CHARGE else (spin_windup if attack_kind == Attack.SPIN else windup_time)


func current_strike() -> float:
	if attack_kind == Attack.RUSH:
		return rush_duration
	if attack_kind == Attack.CROSSBOW:
		return 0.18
	return charge_duration if attack_kind == Attack.CHARGE else (0.5 if attack_kind == Attack.SPIN else swing_time)


func current_recovery() -> float:
	if attack_kind == Attack.RUSH:
		return rush_recovery
	if attack_kind == Attack.CROSSBOW:
		return crossbow_recovery
	return charge_recovery if attack_kind == Attack.CHARGE else (spin_recovery if attack_kind == Attack.SPIN else recovery_time)


func status_text() -> String:
	if state == State.STOPPED:
		return ""
	if state == State.RECOVERY:
		return "EXPOSED — bite now!"
	if state == State.HUNT:
		return "Hunting the horde"
	return ["SWEEP — move sideways", "CHARGE — leave the yellow lane", "SPIN — leave the purple circle", "CROSSBOW — leave the blue line", "STAMPEDE — bait the turn"][attack_kind]


func stop_combat() -> void:
	state = State.STOPPED
	_rush_speed = 0.0
	_rush_turn = 0.0
	bolt.stop()
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
