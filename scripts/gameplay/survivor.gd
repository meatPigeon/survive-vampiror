class_name Survivor
extends Node3D

const HIT_FLASH: Material = preload("res://art/hit_flash.tres")
const SWORD: PackedScene = preload("res://scenes/components/sword.tscn")

@export var body_radius: float = 0.55
@export var attack_range: float = 2.2
@export var attack_angle: float = 160.0
@export var attack_damage: int = 15
@export var windup_time: float = 1.3
@export var swing_time: float = 0.18
@export var recovery_time: float = 1.2

var _attack_elapsed: float = -1.0
var _dealt_damage: bool = false
var _attack_direction := Vector3.FORWARD
var _combat_enabled: bool = true
var _flash_tween: Tween

@onready var visual: Node3D = $Visual
@onready var animation_player: AnimationPlayer = $Visual/AnimationPlayer
@onready var skeleton: Skeleton3D = $Visual/CharacterRig/Skeleton3D
@onready var body: MeshInstance3D = $Visual/CharacterRig/Skeleton3D/MedievalKnight
@onready var health: Health = $Health
@onready var attack_area: MeshInstance3D = $AttackArea


func _ready() -> void:
	_add_sword_and_swing()
	_build_attack_area()
	animation_player.play(&"idle")
	health.changed.connect(_on_health_changed)
	health.died.connect(_on_died)


func update_combat(agents: Array[HordeAgent], delta: float) -> void:
	if not _combat_enabled or not health.is_alive():
		return
	if _attack_elapsed < 0.0:
		var nearest: HordeAgent
		var nearest_distance: float = attack_range
		for agent: HordeAgent in agents:
			var distance: float = global_position.distance_to(agent.global_position)
			if agent.health.is_alive() and distance <= nearest_distance:
				nearest = agent
				nearest_distance = distance
		if nearest == null:
			return
		_attack_direction = (nearest.global_position - global_position).normalized()
		visual.rotation.y = atan2(-_attack_direction.x, -_attack_direction.z)
		attack_area.rotation.y = visual.rotation.y
		attack_area.show()
		_attack_elapsed = 0.0
		_dealt_damage = false
		animation_player.play(&"combat/swing", 0.08)
		return

	_attack_elapsed += delta
	if not _dealt_damage and _attack_elapsed >= windup_time:
		_dealt_damage = true
		# Death signals remove agents from the live list during this loop.
		for agent: HordeAgent in agents.duplicate():
			var offset: Vector3 = agent.global_position - global_position
			if offset.length() <= attack_range and offset.normalized().dot(_attack_direction) >= cos(deg_to_rad(attack_angle * 0.5)):
				agent.health.take_damage(attack_damage)
	if _attack_elapsed >= windup_time + swing_time:
		attack_area.hide()
	if _attack_elapsed >= windup_time + swing_time + recovery_time:
		_attack_elapsed = -1.0
		animation_player.play(&"idle", 0.12)


func stop_combat() -> void:
	_combat_enabled = false
	attack_area.hide()
	if health.is_alive():
		animation_player.play(&"idle", 0.12)


func _on_health_changed(_current: int, _maximum: int) -> void:
	if _flash_tween != null:
		_flash_tween.kill()
	body.material_overlay = HIT_FLASH
	_flash_tween = create_tween()
	_flash_tween.tween_interval(0.12)
	_flash_tween.tween_callback(func() -> void: body.material_overlay = null)


func _on_died() -> void:
	stop_combat()
	animation_player.pause()
	create_tween().tween_property(visual, "rotation:z", PI * 0.5, 0.4)


func _build_attack_area() -> void:
	var vertices := PackedVector3Array()
	var half_angle: float = deg_to_rad(attack_angle * 0.5)
	for index: int in range(16):
		var start: float = lerpf(-half_angle, half_angle, float(index) / 16.0)
		var end: float = lerpf(-half_angle, half_angle, float(index + 1) / 16.0)
		vertices.append(Vector3.ZERO)
		vertices.append(Vector3(sin(start), 0.0, -cos(start)) * attack_range)
		vertices.append(Vector3(sin(end), 0.0, -cos(end)) * attack_range)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	attack_area.mesh = mesh


func _add_sword_and_swing() -> void:
	var hand := BoneAttachment3D.new()
	hand.bone_name = "Hand.R"
	skeleton.add_child(hand)
	var sword: Node3D = SWORD.instantiate()
	hand.add_child(sword)
	sword.position.y = 0.08
	var hand_rest: Quaternion = skeleton.get_bone_global_rest(skeleton.find_bone("Hand.R")).basis.get_rotation_quaternion()
	sword.quaternion = Quaternion(Vector3.UP, hand_rest.inverse() * Vector3.FORWARD)

	# A small runtime arm swing; the source idle/run clips remain reusable.
	var swing := Animation.new()
	swing.length = windup_time + swing_time + recovery_time
	var times: Array[float] = [0.0, windup_time * 0.75, windup_time, windup_time + swing_time, swing.length]
	var poses: Array[Vector3] = [Vector3.ZERO, Vector3(1.7, 0.8, 0.0), Vector3(1.7, 0.8, 0.0), Vector3(0.7, -0.9, 0.0), Vector3.ZERO]
	for bone_name: String in ["UpperArm.R", "LowerArm.R"]:
		var track: int = swing.add_track(Animation.TYPE_ROTATION_3D)
		swing.track_set_path(track, NodePath("CharacterRig/Skeleton3D:" + bone_name))
		var bone_index: int = skeleton.find_bone(bone_name)
		var rest: Quaternion = skeleton.get_bone_global_rest(bone_index).basis.get_rotation_quaternion()
		var local_rest: Quaternion = skeleton.get_bone_rest(bone_index).basis.get_rotation_quaternion()
		for index: int in range(times.size()):
			var angles: Vector3 = poses[index] if bone_name == "UpperArm.R" else Vector3(poses[index].x * 0.3, 0.0, 0.0)
			swing.rotation_track_insert_key(track, times[index], local_rest * rest.inverse() * Quaternion.from_euler(angles) * rest)
	var library := AnimationLibrary.new()
	library.add_animation(&"swing", swing)
	animation_player.add_animation_library(&"combat", library)
