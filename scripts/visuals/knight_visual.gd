class_name KnightVisual
extends Node3D

const HIT_FLASH: Material = preload("res://art/hit_flash.tres")
const SWORD: PackedScene = preload("res://scenes/components/sword.tscn")
var _flash_tween: Tween
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var skeleton: Skeleton3D = $CharacterRig/Skeleton3D
@onready var body: MeshInstance3D = $CharacterRig/Skeleton3D/MedievalKnight


func _ready() -> void:
	var hand := BoneAttachment3D.new()
	hand.bone_name = "Hand.R"
	skeleton.add_child(hand)
	var sword: Node3D = SWORD.instantiate()
	hand.add_child(sword)
	sword.position.y = 0.08
	var rest: Quaternion = skeleton.get_bone_global_rest(skeleton.find_bone("Hand.R")).basis.get_rotation_quaternion()
	sword.quaternion = Quaternion(Vector3.UP, rest.inverse() * Vector3.FORWARD)
	animation_player.add_animation_library(&"combat", AnimationLibrary.new())
	idle()


func face(direction: Vector3) -> void:
	if not direction.is_zero_approx():
		rotation.y = atan2(-direction.x, -direction.z)


func idle() -> void:
	if animation_player.current_animation != &"idle":
		animation_player.play(&"idle", 0.12)


func run(direction: Vector3) -> void:
	face(direction)
	if animation_player.current_animation != &"run":
		animation_player.play(&"run", 0.12)


func attack(clip: StringName, windup: float, strike: float, recovery: float) -> void:
	var library: AnimationLibrary = animation_player.get_animation_library(&"combat")
	if not library.has_animation(clip):
		var swing := Animation.new()
		swing.length = windup + strike + recovery
		var times: Array[float] = [0.0, windup * 0.75, windup, windup + strike, swing.length]
		var poses: Array[Vector3] = [Vector3.ZERO, Vector3(1.7, 0.8, 0), Vector3(1.7, 0.8, 0), Vector3(0.7, -0.9, 0), Vector3.ZERO]
		for bone_name: String in ["UpperArm.R", "LowerArm.R"]:
			var track: int = swing.add_track(Animation.TYPE_ROTATION_3D)
			swing.track_set_path(track, NodePath("CharacterRig/Skeleton3D:" + bone_name))
			var index: int = skeleton.find_bone(bone_name)
			var rest: Quaternion = skeleton.get_bone_global_rest(index).basis.get_rotation_quaternion()
			var local_rest: Quaternion = skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
			for key: int in range(times.size()):
				var angles: Vector3 = poses[key] if bone_name == "UpperArm.R" else Vector3(poses[key].x * 0.3, 0, 0)
				swing.rotation_track_insert_key(track, times[key], local_rest * rest.inverse() * Quaternion.from_euler(angles) * rest)
		library.add_animation(clip, swing)
	animation_player.play(StringName("combat/" + clip), 0.08)


func flash() -> void:
	if _flash_tween != null:
		_flash_tween.kill()
	body.material_overlay = HIT_FLASH
	_flash_tween = create_tween()
	_flash_tween.tween_interval(0.12)
	_flash_tween.tween_callback(func() -> void: body.material_overlay = null)


func die() -> void:
	animation_player.pause()
	create_tween().tween_property(self, "rotation:z", PI * 0.5, 0.4)
