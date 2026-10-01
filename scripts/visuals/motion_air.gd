class_name MotionAir
extends MeshInstance3D

@export var air_color := Color(0.9, 0.97, 0.92, 0.65)
@export_range(0.05, 0.4) var slash_width: float = 0.22
@export_range(0.02, 0.2) var stream_width: float = 0.08

var phase_offset: float = 0.0
var _geometry := ImmediateMesh.new()
var _streaming: bool = false
var _stream_weight: float = 0.0
var _stream_size: float = 1.0
var _stream_height: float = 1.0
var _back := Vector3.BACK
var _previous_position := Vector3.ZERO
var _clock: float = 0.0
var _slash_age: float = -1.0
var _slash_duration: float = 0.18
var _slash_height: float = 1.0
var _spinning: bool = false
static var _material: StandardMaterial3D


func _ready() -> void:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.vertex_color_use_as_albedo = true
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh = _geometry
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_previous_position = global_position
	hide()


func stream(enabled: bool, size: float = 1.0, height: float = 1.0) -> void:
	_streaming = enabled
	_stream_size = size
	_stream_height = height


func slash(spinning: bool, duration: float, height: float) -> void:
	_spinning = spinning
	_slash_duration = maxf(duration, 0.05)
	_slash_height = height
	_slash_age = 0.0


func clear() -> void:
	_streaming = false
	_stream_weight = 0.0
	_slash_age = -1.0
	_geometry.clear_surfaces()
	hide()


func _process(delta: float) -> void:
	var travel: Vector3 = global_position - _previous_position
	_previous_position = global_position
	travel.y = 0.0
	# Actual travel gates wind: no streaks from a blocked sprint or spawn teleport.
	var moving: bool = travel.length() > delta * 0.3 and travel.length() < 2.0
	if moving:
		_back = (global_basis.inverse() * -travel).normalized()
	_stream_weight = move_toward(_stream_weight, 1.0 if _streaming and moving else 0.0, delta * 9.0)
	_clock += delta
	if _slash_age >= 0.0:
		_slash_age += delta
		if _slash_age >= _slash_duration + 0.14:
			_slash_age = -1.0
	if _stream_weight <= 0.0 and _slash_age < 0.0:
		if visible:
			_geometry.clear_surfaces()
			hide()
		return
	show()
	_geometry.clear_surfaces()
	_geometry.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	if _stream_weight > 0.0:
		_draw_streams()
	if _slash_age >= 0.0:
		_draw_slash()
	_geometry.surface_end()


func _draw_streams() -> void:
	var side: Vector3 = _back.cross(Vector3.UP).normalized()
	for index: int in range(2):
		var cycle: float = fposmod(_clock * 2.6 + phase_offset + index * 0.5, 1.0)
		var sign_side: float = -1.0 if index == 0 else 1.0
		var points := PackedVector3Array()
		for step: int in range(11):
			var t: float = float(step) / 10.0
			var offset: float = (0.66 + sin(t * PI) * 0.17) * sign_side * _stream_size
			var behind: float = (-0.35 + t * 1.65 + cycle * 0.55) * _stream_size
			points.append(side * offset + _back * behind + Vector3.UP * (_stream_height + sin(t * PI) * 0.12))
		_ribbon(points, stream_width * _stream_size, _stream_weight * sin(cycle * PI) * 0.75)


func _draw_slash() -> void:
	var progress: float = minf(_slash_age / _slash_duration, 1.0)
	var fade: float = 1.0 - clampf((_slash_age - _slash_duration) / 0.14, 0.0, 1.0)
	var head: float = lerpf(1.35, 1.35 - (TAU if _spinning else 2.7), progress)
	var arc: float = 2.2 if _spinning else 1.65
	for line: int in range(2):
		var radius: float = (2.65 if _spinning else 2.25) + line * 0.2
		var points := PackedVector3Array()
		for step: int in range(19):
			var t: float = float(step) / 18.0
			var angle: float = head + arc * (1.0 - t)
			points.append(Vector3(sin(angle) * radius, _slash_height + cos(angle) * 0.12, -cos(angle) * radius))
		_ribbon(points, slash_width * (1.0 if line == 0 else 0.22), fade * (1.0 if line == 0 else 0.55))


func _ribbon(points: PackedVector3Array, width: float, opacity: float) -> void:
	var edges := PackedVector3Array()
	for index: int in range(points.size()):
		var t: float = float(index) / float(points.size() - 1)
		var tangent: Vector3 = points[mini(index + 1, points.size() - 1)] - points[maxi(index - 1, 0)]
		edges.append(tangent.cross(Vector3.UP).normalized() * width * sin(t * PI))
	for index: int in range(points.size() - 1):
		var a: Vector3 = points[index] - edges[index]
		var b: Vector3 = points[index] + edges[index]
		var c: Vector3 = points[index + 1] - edges[index + 1]
		var d: Vector3 = points[index + 1] + edges[index + 1]
		_geometry.surface_set_color(Color(air_color, air_color.a * opacity))
		for vertex: Vector3 in [a, b, c, b, d, c]:
			_geometry.surface_add_vertex(vertex)
