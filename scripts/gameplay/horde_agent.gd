class_name HordeAgent
extends Node3D

signal died(agent: HordeAgent)

enum Kind { PERMANENT, TEMPORARY }

const HIT_FLASH: Material = preload("res://art/hit_flash.tres")

@export var move_speed: float = 3.6
@export var slowdown_radius: float = 4.0
@export var separation_radius: float = 1.2
@export var separation_strength: float = 7.0
@export var body_radius: float = 0.28
@export var turn_speed: float = 10.0
@export var animation_move_threshold: float = 0.15
@export var run_animation_speed: float = 1.5
@export var bite_range: float = 1.15
@export var bite_damage: int = 4
@export var bite_interval: float = 0.8

var _bite_cooldown: float = 0.0
var _flash_tween: Tween
var kind: Kind = Kind.PERMANENT
var lifetime_remaining: float = 0.0
var expired: bool = false

@onready var visual: Node3D = $Visual
@onready var animation_player: AnimationPlayer = $Visual/AnimationPlayer
@onready var health: Health = $Health
@onready var body: MeshInstance3D = $Visual/CharacterRig/Skeleton3D/Zombie


func _ready() -> void:
	var marker_material := StandardMaterial3D.new()
	marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker_material.albedo_color = Color(0.1, 0.8, 1.0) if kind == Kind.TEMPORARY else Color.WHITE
	$KindMarker.material_override = marker_material
	_play_animation(&"idle")
	health.changed.connect(_on_health_changed)
	health.died.connect(_on_died)


func update_lifetime(delta: float) -> void:
	if kind != Kind.TEMPORARY or not health.is_alive():
		return
	lifetime_remaining = maxf(0.0, lifetime_remaining - delta)
	if lifetime_remaining <= 0.0:
		expired = true
		health.take_damage(health.current_health)


func move_toward_command(
	target: Vector3, neighbours: Array[HordeAgent], bounds: Rect2, delta: float,
	survivor: Survivor = null, speed_multiplier: float = 1.0
) -> void:
	if not health.is_alive():
		return
	var offset: Vector3 = target - global_position
	offset.y = 0.0
	var attraction: Vector3 = (offset / slowdown_radius).limit_length() * move_speed * speed_multiplier
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
	_update_visuals(actual_velocity, delta)


func update_combat(survivor: Survivor, delta: float) -> void:
	_bite_cooldown = maxf(0.0, _bite_cooldown - delta)
	if not health.is_alive() or not survivor.health.is_alive() or _bite_cooldown > 0.0:
		return
	if global_position.distance_to(survivor.global_position) > bite_range:
		return
	_bite_cooldown = bite_interval
	survivor.health.take_damage(bite_damage)


func stop() -> void:
	if health.is_alive():
		_update_visuals(Vector3.ZERO, 0.0)


func _on_health_changed(_current: int, _maximum: int) -> void:
	if _flash_tween != null:
		_flash_tween.kill()
	body.material_overlay = HIT_FLASH
	_flash_tween = create_tween()
	_flash_tween.tween_interval(0.12)
	_flash_tween.tween_callback(func() -> void: body.material_overlay = null)


func _on_died() -> void:
	$KindMarker.hide()
	animation_player.pause()
	died.emit(self)
	var death_tween: Tween = create_tween().set_parallel(true)
	death_tween.tween_property(visual, "rotation:z", PI * 0.5, 0.25)
	death_tween.tween_property(visual, "scale", Vector3.ONE * 0.05, 0.3)
	death_tween.chain().tween_callback(queue_free)


func _update_visuals(actual_velocity: Vector3, delta: float) -> void:
	var speed: float = actual_velocity.length()
	var threshold: float = animation_move_threshold
	if animation_player.current_animation == &"run":
		threshold *= 0.5
	if speed > threshold:
		visual.rotation.y = lerp_angle(
			visual.rotation.y, atan2(-actual_velocity.x, -actual_velocity.z),
			minf(turn_speed * delta, 1.0)
		)
		animation_player.speed_scale = run_animation_speed * clampf(speed / move_speed, 0.5, 2.0)
		_play_animation(&"run")
	else:
		animation_player.speed_scale = 1.0
		_play_animation(&"idle")


func _play_animation(clip: StringName) -> void:
	if animation_player.current_animation == clip:
		return
	animation_player.play(clip, 0.15)
	# Offset each creature's cycle so the crowd does not march in lockstep.
	animation_player.seek(fmod(float(get_index()) * 0.37, animation_player.get_animation(clip).length), true)
