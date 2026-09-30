class_name KnightVisual
extends Node3D

const HIT_FLASH: Material = preload("res://art/hit_flash.tres")
const HALBERD: PackedScene = preload("res://scenes/components/halberd.tscn")

var _flash_tween: Tween
var _recoil_tween: Tween
var _flash_cooldown: float = 0.0
var _dead: bool = false
var _attacking: bool = false
var _windup: float = 0.0
var _strike: float = 0.0
var _hit_recoil: float = 0.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var rig: Node3D = $CharacterRig
@onready var skeleton: Skeleton3D = $CharacterRig/Skeleton3D
@onready var body: MeshInstance3D = $CharacterRig/Skeleton3D/MedievalKnight


func _ready() -> void:
	var hand := BoneAttachment3D.new()
	hand.name = "WeaponHand"
	hand.bone_name = "Hand.R"
	skeleton.add_child(hand)
	var halberd: Node3D = HALBERD.instantiate()
	hand.add_child(halberd)
	halberd.position.y = 0.08
	var rest: Quaternion = skeleton.get_bone_global_rest(skeleton.find_bone("Hand.R")).basis.get_rotation_quaternion()
	halberd.quaternion = Quaternion(Vector3.UP, rest.inverse() * Vector3.FORWARD)
	animation_player.add_animation_library(&"combat", AnimationLibrary.new())
	# Duplicate source clips in this instance; their reset tracks restore the rig
	# after attacks without modifying imported animation resources.
	var library: AnimationLibrary = animation_player.get_animation_library(&"").duplicate(true)
	animation_player.remove_animation_library(&"")
	animation_player.add_animation_library(&"", library)
	for name: StringName in [&"idle", &"run"]:
		var clip: Animation = library.get_animation(name).duplicate()
		_rig_track(clip, "rotation", [0.0], [Vector3.ZERO])
		_rig_track(clip, "position", [0.0], [Vector3.ZERO])
		library.remove_animation(name)
		library.add_animation(name, clip)
	idle()


func _process(delta: float) -> void:
	_flash_cooldown = maxf(0.0, _flash_cooldown - delta)
	if not _dead:
		# Recoil sits below the authored rig: bites never cancel an attack.
		skeleton.position.z = _hit_recoil


func face(direction: Vector3) -> void:
	if not _dead and not direction.is_zero_approx():
		rotation.y = atan2(-direction.x, -direction.z)


func idle() -> void:
	if _dead:
		return
	_attacking = false
	animation_player.speed_scale = 1.0
	if animation_player.current_animation != &"idle":
		animation_player.play(&"idle", 0.2)


func run(direction: Vector3) -> void:
	if _dead:
		return
	_attacking = false
	face(direction)
	animation_player.speed_scale = 0.9
	if animation_player.current_animation != &"run":
		animation_player.play(&"run", 0.16)


func attack(clip: StringName, windup: float, strike_time: float, recovery: float) -> void:
	if _dead:
		return
	_attacking = true
	_windup = windup
	_strike = strike_time
	animation_player.speed_scale = 1.0
	var library: AnimationLibrary = animation_player.get_animation_library(&"combat")
	var key: StringName = StringName("%s_%.3f_%.3f_%.3f" % [clip, windup, strike_time, recovery])
	if not library.has_animation(key):
		library.add_animation(key, _build_attack(clip, windup, strike_time, recovery))
	animation_player.play(StringName("combat/" + key), 0.1)


func strike() -> void:
	if _attacking and not _dead:
		# Gameplay owns impact time. The blade arrives when damage resolves.
		animation_player.seek(_windup, true)


func recover() -> void:
	if _attacking and not _dead:
		animation_player.seek(_windup + _strike, true)


func _build_attack(kind: StringName, windup: float, strike_time: float, recovery: float) -> Animation:
	var clip := Animation.new()
	clip.length = windup + strike_time + recovery
	var times: Array[float] = [0.0, windup * 0.55, maxf(windup * 0.55, windup - 0.12),
		windup, windup + strike_time * 0.55, windup + strike_time,
		windup + strike_time + recovery * 0.3, clip.length]
	var loaded: Dictionary[String, Vector3]
	var impact: Dictionary[String, Vector3]
	var turn: Array[Vector3]
	var height: Array[Vector3]
	match kind:
		&"charge":
			loaded = {"Spine": Vector3(-0.35, 0, 0), "Head": Vector3(0.25, 0, 0),
				"UpperArm.R": Vector3(0.8, -0.4, -0.2), "LowerArm.R": Vector3(0.65, 0, 0),
				"UpperArm.L": Vector3(0.45, 0.1, 0.2), "LowerArm.L": Vector3(0.6, 0, 0)}
			impact = {"Spine": Vector3(-0.5, 0, 0), "Head": Vector3(0.34, 0, 0),
				"UpperArm.R": Vector3(1.3, -0.22, 0), "LowerArm.R": Vector3(0.14, 0, 0),
				"UpperArm.L": Vector3(0.9, 0.2, 0.15), "LowerArm.L": Vector3(0.85, 0, 0)}
			turn = [Vector3.ZERO, Vector3(0.1, 0, 0), Vector3(0.13, 0, 0), Vector3(-0.12, 0, 0), Vector3(-0.12, 0, 0), Vector3(-0.06, 0, 0), Vector3(0.07, 0, 0), Vector3.ZERO]
			height = [Vector3.ZERO, Vector3(0, -0.06, 0.07), Vector3(0, -0.09, 0.1), Vector3(0, 0.02, -0.06), Vector3(0, 0.02, -0.06), Vector3(0, -0.1, -0.04), Vector3(0, 0.02, 0), Vector3.ZERO]
		&"spin":
			loaded = {"Spine": Vector3(-0.2, 0.5, 0), "Head": Vector3(0.12, -0.32, 0),
				"UpperArm.R": Vector3(0.8, 0.8, -0.12), "LowerArm.R": Vector3(0.8, 0, 0),
				"UpperArm.L": Vector3(0.6, -0.4, 0.15), "UpperLeg.L": Vector3(0.24, 0, 0.15), "UpperLeg.R": Vector3(-0.16, 0, -0.15)}
			impact = {"Spine": Vector3(0.04, -0.28, 0), "Head": Vector3(-0.08, 0.15, 0),
				"UpperArm.R": Vector3(0.05, -0.1, -1.0), "LowerArm.R": Vector3(0.08, 0, 0),
				"UpperArm.L": Vector3(0, 0.1, 0.65), "UpperLeg.L": Vector3(-0.18, 0, 0.08), "UpperLeg.R": Vector3(0.2, 0, -0.08)}
			# Intermediate keys keep each part of the full turn below a half-turn.
			turn = [Vector3.ZERO, Vector3(0, 0.28, 0), Vector3(0, 0.46, 0), Vector3(0, -0.7, 0), Vector3(0, -3.8, 0), Vector3(0, -TAU - 0.25, 0), Vector3(0, -TAU + 0.07, 0), Vector3(0, -TAU, 0)]
			height = [Vector3.ZERO, Vector3(0, -0.04, 0), Vector3(0, -0.09, 0), Vector3(0, 0.07, 0), Vector3(0, 0.06, 0), Vector3(0, -0.06, 0), Vector3(0, 0.02, 0), Vector3.ZERO]
		_:
			loaded = {"Spine": Vector3(-0.12, 0.48, -0.1), "Chest": Vector3(0, 0.22, 0), "Head": Vector3(0.1, -0.42, 0.08),
				"UpperArm.R": Vector3(1.35, 1.0, -0.2), "LowerArm.R": Vector3(0.7, 0, 0), "UpperArm.L": Vector3(0.42, -0.35, 0.2),
				"UpperLeg.L": Vector3(-0.2, 0, 0.08), "UpperLeg.R": Vector3(0.2, 0, -0.08)}
			impact = {"Spine": Vector3(-0.18, -0.5, 0.08), "Chest": Vector3(0, -0.2, 0), "Head": Vector3(0.1, 0.28, -0.04),
				"UpperArm.R": Vector3(0.75, -0.75, -0.25), "LowerArm.R": Vector3(0.12, 0, 0), "UpperArm.L": Vector3(-0.15, 0.2, 0.25),
				"UpperLeg.L": Vector3(0.22, 0, 0.08), "UpperLeg.R": Vector3(-0.12, 0, -0.08)}
			turn = [Vector3.ZERO, Vector3(0, 0.08, -0.04), Vector3(0, 0.13, -0.06), Vector3(0, -0.1, 0.08), Vector3(0, -0.16, 0.1), Vector3(0, -0.12, 0.08), Vector3(0, 0.02, -0.03), Vector3.ZERO]
			height = [Vector3.ZERO, Vector3(0, -0.025, 0.02), Vector3(0, -0.04, 0.04), Vector3(0, -0.025, -0.08), Vector3(0, -0.05, -0.1), Vector3(0, -0.04, -0.07), Vector3(0, 0.01, -0.015), Vector3.ZERO]
	for index: int in range(skeleton.get_bone_count()):
		var bone: String = skeleton.get_bone_name(index)
		if kind == &"charge" and (bone.begins_with("UpperLeg") or bone.begins_with("LowerLeg") or bone.begins_with("Foot")):
			continue
		var load_pose: Vector3 = loaded.get(bone, Vector3.ZERO)
		var hit_pose: Vector3 = impact.get(bone, Vector3.ZERO)
		var follow: float = 1.15 if kind == &"sweep" else 1.0
		_bone_track(clip, bone, times, [Vector3.ZERO, load_pose * 0.8, load_pose, hit_pose,
			hit_pose * follow, hit_pose * 0.75, hit_pose * 0.18, Vector3.ZERO])
	if kind == &"charge":
		_charge_legs(clip, windup, strike_time, recovery)
	_rig_track(clip, "rotation", times, turn)
	_rig_track(clip, "position", times, height)
	return clip


func _bone_track(clip: Animation, bone_name: String, times: Array[float], angles: Array[Vector3]) -> void:
	var track: int = clip.add_track(Animation.TYPE_ROTATION_3D)
	clip.track_set_path(track, NodePath("CharacterRig/Skeleton3D:" + bone_name))
	var index: int = skeleton.find_bone(bone_name)
	var rest: Quaternion = skeleton.get_bone_global_rest(index).basis.get_rotation_quaternion()
	var local_rest: Quaternion = skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
	for key: int in range(times.size()):
		clip.rotation_track_insert_key(track, times[key], local_rest * rest.inverse() * Quaternion.from_euler(angles[key]) * rest)


func _rig_track(clip: Animation, property: String, times: Array[float], values: Array[Vector3]) -> void:
	if property == "rotation":
		var rotation_track: int = clip.add_track(Animation.TYPE_ROTATION_3D)
		clip.track_set_path(rotation_track, NodePath("CharacterRig"))
		for key: int in range(times.size()):
			clip.rotation_track_insert_key(rotation_track, times[key], Quaternion.from_euler(values[key]))
		return
	var track: int = clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(track, NodePath("CharacterRig:" + property))
	for key: int in range(times.size()):
		clip.track_insert_key(track, times[key], values[key])


func _charge_legs(clip: Animation, windup: float, strike_time: float, recovery: float) -> void:
	# Reuse the source run's planted-foot/knee motion below the charging torso.
	var source: Animation = animation_player.get_animation(&"run")
	for bone: String in ["UpperLeg.L", "UpperLeg.R", "LowerLeg.L", "LowerLeg.R", "Foot.L", "Foot.R"]:
		var path := NodePath("CharacterRig/Skeleton3D:" + bone)
		var source_track: int = source.find_track(path, Animation.TYPE_ROTATION_3D)
		var track: int = clip.add_track(Animation.TYPE_ROTATION_3D)
		clip.track_set_path(track, path)
		var rest: Quaternion = skeleton.get_bone_rest(skeleton.find_bone(bone)).basis.get_rotation_quaternion()
		clip.rotation_track_insert_key(track, 0.0, rest)
		clip.rotation_track_insert_key(track, windup - 0.12, rest)
		for step: int in range(29):
			var elapsed: float = strike_time * float(step) / 28.0
			var pose: Quaternion = source.rotation_track_interpolate(source_track, fmod(elapsed * 1.8, source.length))
			clip.rotation_track_insert_key(track, windup + elapsed, pose)
		clip.rotation_track_insert_key(track, windup + strike_time + recovery * 0.2, rest)
		clip.rotation_track_insert_key(track, clip.length, rest)


func flash() -> void:
	if _dead or _flash_cooldown > 0.0:
		return
	_flash_cooldown = 0.18
	if _flash_tween != null:
		_flash_tween.kill()
	body.material_overlay = HIT_FLASH
	_flash_tween = create_tween()
	_flash_tween.tween_interval(0.055)
	_flash_tween.tween_callback(func() -> void: body.material_overlay = null)
	if _recoil_tween != null:
		_recoil_tween.kill()
	_hit_recoil = 0.055 if _attacking else 0.1
	_recoil_tween = create_tween()
	_recoil_tween.tween_property(self, "_hit_recoil", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func die() -> void:
	if _dead:
		return
	_dead = true
	_attacking = false
	animation_player.pause()
	if _recoil_tween != null:
		_recoil_tween.kill()
	skeleton.position = Vector3.ZERO
	var fall := create_tween()
	fall.set_parallel(true)
	fall.tween_property(rig, "rotation:z", -0.14, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fall.tween_property(rig, "position:y", -0.1, 0.12)
	fall.chain().tween_property(rig, "rotation:z", 1.5, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.parallel().tween_property(rig, "position:y", 0.1, 0.34)
	fall.chain().tween_property(rig, "rotation:z", 1.4, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fall.parallel().tween_property(rig, "position:y", 0.025, 0.12)
