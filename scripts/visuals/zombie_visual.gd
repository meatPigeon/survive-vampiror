class_name ZombieVisual
extends Node3D

const HIT_FLASH: Material = preload("res://art/hit_flash.tres")
static var _bite_animation: Animation

var _moving: bool = false
var _dead: bool = false
var _speed: float = 0.0
var _speed_target: float = 0.0
var _bank: float = 0.0
var _bank_target: float = 0.0
var _hit_remaining: float = 0.0
var _run_playback: float = 1.0
var _phase_offset: float = 0.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var rig: Node3D = $CharacterRig
@onready var skeleton: Skeleton3D = $CharacterRig/Skeleton3D
@onready var body: MeshInstance3D = $CharacterRig/Skeleton3D/Zombie


func _ready() -> void:
	_phase_offset = float(get_parent().get_index()) * 0.37
	if _bite_animation == null:
		_bite_animation = _build_bite()
	var library := AnimationLibrary.new()
	library.add_animation(&"bite", _bite_animation)
	animation_player.add_animation_library(&"combat", library)
	animation_player.animation_finished.connect(_on_animation_finished)
	_play_locomotion()


func move(actual_velocity: Vector3, delta: float, move_speed: float, turn_speed: float, threshold: float, playback: float) -> void:
	if _dead:
		return
	var speed: float = actual_velocity.length()
	_moving = speed > threshold * (0.5 if _moving else 1.0)
	_speed_target = clampf(speed / move_speed, 0.0, 2.0) if _moving else 0.0
	_run_playback = playback * clampf(speed / move_speed, 0.5, 2.0)
	_bank_target = 0.0
	if _moving and animation_player.current_animation != &"combat/bite":
		var target_yaw: float = atan2(-actual_velocity.x, -actual_velocity.z)
		_bank_target = clampf(angle_difference(rotation.y, target_yaw), -1.0, 1.0) * _speed_target
		rotation.y = lerp_angle(rotation.y, target_yaw, minf(turn_speed * delta, 1.0))
	if animation_player.current_animation != &"combat/bite":
		_play_locomotion()


func bite(direction: Vector3) -> void:
	if _dead:
		return
	if not direction.is_zero_approx():
		rotation.y = atan2(-direction.x, -direction.z)
	animation_player.speed_scale = 1.0
	animation_player.play(&"combat/bite", 0.025)


func hit() -> void:
	if not _dead:
		_hit_remaining = 0.18
		body.material_overlay = HIT_FLASH


func stop() -> void:
	if _dead:
		return
	_moving = false
	_speed_target = 0.0
	_bank_target = 0.0
	_play_locomotion()


func _process(delta: float) -> void:
	if _dead:
		return
	_speed = lerpf(_speed, _speed_target, 1.0 - exp(-12.0 * delta))
	_bank = lerpf(_bank, _bank_target, 1.0 - exp(-10.0 * delta))
	_hit_remaining = maxf(0.0, _hit_remaining - delta)
	if _hit_remaining < 0.11:
		body.material_overlay = null
	var recoil: float = sin(_hit_remaining / 0.18 * PI) if _hit_remaining > 0.0 else 0.0
	var gait: float = 0.0
	if animation_player.current_animation == &"run":
		gait = cos(animation_player.current_animation_position / 0.8 * TAU * 2.0)
	var weight: float = minf(_speed, 1.5)
	rig.rotation = Vector3(-0.10 * _speed + recoil * 0.16, 0.0, -0.10 * _bank)
	rig.position = Vector3(0.0, maxf(0.0, -gait) * 0.10 * weight, recoil * 0.13)
	rig.scale = Vector3(1.0 - gait * 0.025 * weight + recoil * 0.05,
		1.0 + gait * 0.045 * weight - recoil * 0.08, 1.0 - gait * 0.025 * weight)


func die(expired: bool) -> Tween:
	_dead = true
	animation_player.pause()
	body.material_overlay = null
	var death: Tween = create_tween()
	if expired:
		death.tween_property(rig, "scale", Vector3(1.15, 0.22, 1.15), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	else:
		var side: float = 1.0 if get_parent().get_index() % 2 == 0 else -1.0
		death.set_parallel(true)
		death.tween_property(rig, "rotation", Vector3(0.18, 0.0, side * 1.55), 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		death.tween_property(rig, "position:y", 0.5, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		death.chain().tween_property(rig, "position:y", 0.34, 0.07).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	death.chain().tween_interval(0.07)
	death.chain().tween_property(rig, "scale", Vector3.ONE * 0.03, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return death


func _play_locomotion() -> void:
	var clip: StringName = &"run" if _moving else &"idle"
	animation_player.speed_scale = _run_playback if _moving else 1.0
	if animation_player.current_animation == clip:
		return
	animation_player.play(clip, 0.12)
	animation_player.seek(fmod(_phase_offset, animation_player.get_animation(clip).length), true)


func _on_animation_finished(clip: StringName) -> void:
	if clip == &"combat/bite" and not _dead:
		_play_locomotion()


func _build_bite() -> Animation:
	var animation := Animation.new()
	animation.length = 0.36
	var times: Array[float] = [0.0, 0.04, 0.10, 0.20, 0.36]
	# Contact is already resolved by gameplay: snap into the bite, then recoil.
	var weights: Array[float] = [0.45, 1.0, 0.85, -0.15, 0.0]
	var poses: Dictionary[String, Vector3] = {
		"Hips": Vector3(-0.08, 0.0, 0.0), "Spine": Vector3(-0.24, 0.0, 0.0),
		"Chest": Vector3(-0.20, 0.08, 0.0), "Head": Vector3(0.27, -0.08, 0.0),
		"UpperArm.L": Vector3(0.85, 0.0, -0.25), "UpperArm.R": Vector3(0.85, 0.0, 0.25),
		"LowerArm.L": Vector3(0.3, 0.0, 0.0), "LowerArm.R": Vector3(0.3, 0.0, 0.0)
	}
	for name: String in poses:
		var bone: int = skeleton.find_bone(name)
		var rest: Quaternion = skeleton.get_bone_global_rest(bone).basis.get_rotation_quaternion()
		var local_rest: Quaternion = skeleton.get_bone_rest(bone).basis.get_rotation_quaternion()
		var track: int = animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track, NodePath("CharacterRig/Skeleton3D:" + name))
		for key: int in range(times.size()):
			animation.rotation_track_insert_key(track, times[key], local_rest * rest.inverse() * Quaternion.from_euler(poses[name] * weights[key]) * rest)
	var lunge: int = animation.add_track(Animation.TYPE_POSITION_3D)
	animation.track_set_path(lunge, NodePath("CharacterRig/Skeleton3D:Hips"))
	var hips_rest: Vector3 = skeleton.get_bone_rest(skeleton.find_bone("Hips")).origin
	for key: int in range(times.size()):
		animation.position_track_insert_key(lunge, times[key], hips_rest + Vector3(0.0, 0.025, -0.22) * weights[key])
	return animation
