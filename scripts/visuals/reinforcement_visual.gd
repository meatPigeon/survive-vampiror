class_name ReinforcementVisual
extends Node3D

signal availability_changed(available: bool)

@export var rise_time: float = 0.55
@export var sink_time: float = 0.4
@export var stagger: float = 0.09
@export var buried_depth: float = 1.5

var _available: bool = false
var _transition: Tween
var _rest_positions: Array[Vector3] = []
var _rest_rotations: Array[Vector3] = []

@onready var gravestones: Node3D = $Gravestones


func _ready() -> void:
	for grave: Node3D in gravestones.get_children():
		_rest_positions.append(grave.position)
		_rest_rotations.append(grave.rotation)
		grave.position.y -= buried_depth
		grave.rotation += _buried_tilt(grave.get_index())
		grave.hide()


func set_available(value: bool) -> void:
	if value == _available:
		return
	_available = value
	availability_changed.emit(_available)
	if _transition != null:
		_transition.kill()
	_transition = create_tween().set_parallel(true)
	_transition.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	for grave: Node3D in gravestones.get_children():
		var index: int = grave.get_index()
		var delay: float = float(index) * stagger
		var destination: Vector3 = _rest_positions[index]
		var rotation_target: Vector3 = _rest_rotations[index]
		if _available:
			grave.show()
			_transition.tween_property(grave, "position", destination, rise_time).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_transition.tween_property(grave, "rotation", rotation_target, rise_time).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			destination.y -= buried_depth
			rotation_target += _buried_tilt(index)
			_transition.tween_property(grave, "position", destination, sink_time).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			_transition.tween_property(grave, "rotation", rotation_target, sink_time).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_transition.finished.connect(_finish_transition)


func _finish_transition() -> void:
	if not _available:
		for grave: Node3D in gravestones.get_children():
			grave.hide()
	_transition = null


func _buried_tilt(index: int) -> Vector3:
	return Vector3(0.12, 0.0, 0.1 if index % 2 == 0 else -0.1)
