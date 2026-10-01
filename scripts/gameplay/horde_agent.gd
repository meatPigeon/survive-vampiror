class_name HordeAgent
extends Node3D

signal died(agent: HordeAgent)

enum Kind { PERMANENT, TEMPORARY }

@export var move_speed: float = 3.6
@export_range(0.1, 10.0) var cohesion_radius: float = 4.0
@export var separation_radius: float = 1.2
@export var separation_strength: float = 7.0
@export var body_radius: float = 0.28
@export var turn_speed: float = 10.0
@export var animation_move_threshold: float = 0.15
@export var run_animation_speed: float = 1.5
@export var bite_range: float = 1.15
@export var bite_damage: int = 4
@export var bite_interval: float = 0.8
@export_range(0.1, 1.0) var feast_bite_interval_scale: float = 0.5
@export_range(0, 30) var feast_healing: int = 2

var _bite_cooldown: float = 0.0
var kind: Kind = Kind.PERMANENT
var lifetime_remaining: float = 0.0
var expired: bool = false
var ability_locked: bool = false
var feasting: bool = false

@onready var visual: ZombieVisual = $Visual
@onready var animation_player: AnimationPlayer = $Visual/AnimationPlayer
@onready var health: Health = $Health
@onready var kind_marker: ZombieKindMarker = $KindMarker
@onready var _last_health: int = health.current_health


func _ready() -> void:
	kind_marker.configure(kind == Kind.TEMPORARY)
	visual.set_temporary(kind == Kind.TEMPORARY)
	health.changed.connect(_on_health_changed)
	health.died.connect(_on_died)


func update_lifetime(delta: float) -> void:
	if kind != Kind.TEMPORARY or not health.is_alive():
		return
	lifetime_remaining = maxf(0.0, lifetime_remaining - delta)
	if lifetime_remaining <= 0.0:
		expired = true
		health.take_damage(health.current_health)


func move_in_direction(
	direction: Vector3, neighbours: Array[HordeAgent], bounds: Rect2, delta: float,
	survivor: Survivor = null, speed_multiplier: float = 1.0, crowd_center: Vector3 = Vector3.INF
) -> void:
	if not health.is_alive():
		return
	var steering: Vector3 = direction
	if crowd_center.is_finite():
		# Preserve the loose crowd while its shared direction changes.
		var toward_center: Vector3 = crowd_center - global_position
		toward_center.y = 0.0
		steering += toward_center / cohesion_radius
	var attraction: Vector3 = steering.limit_length() * move_speed * speed_multiplier
	var separation := Vector3.ZERO
	for neighbour: HordeAgent in neighbours:
		if neighbour == self:
			continue
		var away: Vector3 = global_position - neighbour.global_position
		away.y = 0.0
		var distance: float = away.length()
		if distance >= separation_radius:
			continue
		if distance < 0.001:
			# Opposite directions for an exactly overlapping pair.
			away = Vector3.RIGHT if get_index() > neighbour.get_index() else Vector3.LEFT
			distance = 0.001
		separation += away.normalized() * (separation_radius - distance) / maxf(distance * distance, 0.01)

	var velocity: Vector3 = (attraction + separation * separation_strength).limit_length(move_speed * speed_multiplier)
	var next_position: Vector3 = global_position + velocity * delta
	if survivor != null and survivor.health.is_alive():
		var away_from_survivor: Vector3 = next_position - survivor.global_position
		away_from_survivor.y = 0.0
		var minimum_distance: float = body_radius + survivor.body_radius
		if away_from_survivor.length() < minimum_distance:
			if away_from_survivor.is_zero_approx():
				away_from_survivor = Vector3.RIGHT
			next_position = survivor.global_position + away_from_survivor.normalized() * minimum_distance
	next_position.x = clampf(next_position.x, bounds.position.x + body_radius, bounds.end.x - body_radius)
	next_position.z = clampf(next_position.z, bounds.position.y + body_radius, bounds.end.y - body_radius)
	var actual_velocity: Vector3 = (next_position - global_position) / delta
	global_position = next_position
	visual.move(actual_velocity, delta, move_speed, turn_speed, animation_move_threshold, run_animation_speed, speed_multiplier > 1.0)


func update_combat(survivor: Survivor, delta: float) -> void:
	_bite_cooldown = maxf(0.0, _bite_cooldown - delta)
	if ability_locked or not health.is_alive() or not survivor.health.is_alive() or _bite_cooldown > 0.0:
		return
	if global_position.distance_to(survivor.global_position) > bite_range:
		return
	_bite_cooldown = bite_interval * (feast_bite_interval_scale if feasting else 1.0)
	visual.bite(survivor.global_position - global_position)
	if feasting:
		health.heal(feast_healing)
	survivor.health.take_damage(bite_damage)


func stop() -> void:
	visual.stop()


func set_ability_color(color: Color) -> void:
	if color.a == 0.0 and feasting:
		color = Color("c894e8")
	var material: StandardMaterial3D = $KindMarker.material_override
	material.albedo_color = color if color.a > 0.0 else kind_marker.base_color
	$KindMarker.scale = Vector3(1.8, 0.25, 1.8) if color.a > 0.0 else Vector3(1, 0.25, 1)


func _on_health_changed(current: int, _maximum: int) -> void:
	if not expired and current < _last_health:
		visual.hit()
	_last_health = current


func _on_died() -> void:
	$KindMarker.hide()
	died.emit(self)
	visual.die(expired).finished.connect(queue_free)
