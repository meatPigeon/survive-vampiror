class_name HorseVisual
extends Node3D

var moving: bool = false
var _stride: float = 0.0

@onready var body: Node3D = $Body
@onready var legs: Array[Node3D] = [$FrontLeft, $FrontRight, $RearLeft, $RearRight]


func _process(delta: float) -> void:
	if moving:
		_stride += delta * 12.0
	for index: int in range(legs.size()):
		var angle: float = sin(_stride + (PI if index in [1, 2] else 0.0)) * 0.6 if moving else 0.0
		legs[index].rotation.x = lerpf(legs[index].rotation.x, angle, 1.0 - exp(-delta * 18.0))
	body.position.y = sin(_stride * 2.0) * 0.035 if moving else 0.0
