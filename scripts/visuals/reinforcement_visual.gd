class_name ReinforcementVisual
extends Node3D

signal availability_changed(available: bool)

@export var rise_time: float = 0.55
@export var sink_time: float = 0.4
@export var stagger: float = 0.09
@export var buried_depth: float = 1.5
@export var ring_radius: float = 2.55
@export var ring_width: float = 0.28
@export var ring_height: float = 0.10

const RING_COLOR := Color("b7e4d5")
const TRACK_COLOR := Color("354b43")

var _available: bool = false
var _progress: float = 0.0
var _transition: Tween
var _rest_positions: Array[Vector3] = []
var _rest_rotations: Array[Vector3] = []

@onready var gravestones: Node3D = $Gravestones
@onready var indicator: Node3D = $Indicator
@onready var fill: MeshInstance3D = $Indicator/Fill


func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_BACK
	# This is a world-space UI indicator: a gathered horde must not hide it.
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	for mesh_instance: MeshInstance3D in indicator.get_children():
		var layer: StandardMaterial3D = material.duplicate() as StandardMaterial3D
		layer.render_priority = mesh_instance.get_index() + 1
		mesh_instance.material_override = layer
	$Indicator/Track.mesh = _ring_mesh(1.0, TRACK_COLOR)
	$Indicator/Marker.mesh = _marker_mesh()
	indicator.hide()
	fill.hide()
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
	indicator.visible = value
	set_progress(0.0)
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


func set_progress(value: float) -> void:
	var fraction: float = clampf(value, 0.0, 1.0) if _available else 0.0
	if is_equal_approx(fraction, _progress):
		return
	_progress = fraction
	fill.visible = fraction > 0.0
	if fill.visible:
		fill.mesh = _ring_mesh(fraction, RING_COLOR)


func _ring_mesh(fraction: float, color: Color) -> ArrayMesh:
	var vertices: Array[Vector3] = []
	var colors: Array[Color] = []
	var segments: int = ceili(72.0 * fraction)
	var top := Vector3.UP * ring_height
	for index: int in range(segments):
		var start: float = TAU * float(index) / 72.0
		var end: float = minf(TAU * fraction, TAU * float(index + 1) / 72.0)
		var from := Vector3(sin(start), 0.0, -cos(start))
		var to := Vector3(sin(end), 0.0, -cos(end))
		var inner_a: Vector3 = from * ring_radius
		var outer_a: Vector3 = from * (ring_radius + ring_width)
		var inner_b: Vector3 = to * ring_radius
		var outer_b: Vector3 = to * (ring_radius + ring_width)
		_add_quad(vertices, colors, inner_a + top, outer_a + top, outer_b + top, inner_b + top, color)
		_add_quad(vertices, colors, outer_a, outer_b, outer_b + top, outer_a + top, color.darkened(0.30))
		_add_quad(vertices, colors, inner_b, inner_a, inner_a + top, inner_b + top, color.darkened(0.42))
		if index == 0:
			_add_quad(vertices, colors, inner_a, outer_a, outer_a + top, inner_a + top, color.darkened(0.2))
		if index == segments - 1:
			_add_quad(vertices, colors, outer_b, inner_b, inner_b + top, outer_b + top, color.darkened(0.2))
	return _mesh(vertices, colors)


func _marker_mesh() -> ArrayMesh:
	var vertices: Array[Vector3] = []
	var colors: Array[Color] = []
	var center := Vector3(0.0, ring_height, -ring_radius - ring_width - 0.55)
	var points: Array[Vector3] = [Vector3(0, 0, -0.45), Vector3(0.32, 0, 0), Vector3(0, 0, 0.45), Vector3(-0.32, 0, 0)]
	for index: int in range(4):
		var a: Vector3 = points[index]
		var b: Vector3 = points[(index + 1) % 4]
		_add_quad(vertices, colors, center + a, center + b, center + b * 0.5, center + a * 0.5, RING_COLOR)
	return _mesh(vertices, colors)


func _add_quad(vertices: Array[Vector3], colors: Array[Color], a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
	vertices.append_array([a, b, c, a, c, d])
	for index: int in range(6):
		colors.append(color)


func _mesh(vertices: Array[Vector3], colors: Array[Color]) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(vertices)
	arrays[Mesh.ARRAY_COLOR] = PackedColorArray(colors)
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result


func _finish_transition() -> void:
	if not _available:
		for grave: Node3D in gravestones.get_children():
			grave.hide()
	_transition = null


func _buried_tilt(index: int) -> Vector3:
	return Vector3(0.12, 0.0, 0.1 if index % 2 == 0 else -0.1)
