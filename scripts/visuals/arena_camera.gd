extends Camera3D

@export var ground: MeshInstance3D
@export var horde: HordeController
@export var framing_margin: float = 1.5
@export_range(0.1, 1.0) var minimum_zoom: float = 0.45
@export_range(1.0, 2.0) var maximum_zoom: float = 1.25
@export_range(0.01, 0.5) var zoom_step: float = 0.12
@export_range(1.0, 30.0) var zoom_response: float = 12.0
@export_range(1.0, 30.0) var follow_response: float = 8.0

var zoom_factor: float = 1.0
var _fitted_size: float = 1.0
var _overview_position := Vector3.ZERO


func _ready() -> void:
	_overview_position = global_position
	get_viewport().size_changed.connect(_frame_arena)
	_frame_arena()


func adjust_zoom(steps: float) -> void:
	zoom_factor = clampf(zoom_factor * pow(1.0 - zoom_step, steps), minimum_zoom, maximum_zoom)


func _process(delta: float) -> void:
	size = lerpf(size, _fitted_size * zoom_factor, 1.0 - exp(-zoom_response * delta))
	var destination: Vector3 = _overview_position
	if zoom_factor < 1.0:
		# Match the mobile crowd: planted mines and launched zombies stay behind.
		var center := Vector3.ZERO
		var count: int = 0
		for agent: HordeAgent in horde.agents:
			if not agent.ability_locked:
				center += agent.global_position
				count += 1
		if count == 0:
			return
		center /= float(count)
		var floor_center: Vector3 = ground.to_global(ground.mesh.get_aabb().get_center())
		destination += Vector3(center.x - floor_center.x, 0.0, center.z - floor_center.z)
	global_position = global_position.lerp(destination, 1.0 - exp(-follow_response * delta))


func _frame_arena() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.y <= 0.0:
		return
	var floor_size: Vector3 = ground.mesh.get_aabb().size
	var aspect: float = viewport_size.x / viewport_size.y
	# Orthographic projection compresses floor depth by the camera's tilt.
	var projected_depth: float = floor_size.z * absf(global_basis.y.z)
	_fitted_size = maxf((floor_size.x + framing_margin * 2.0) / aspect,
		projected_depth + framing_margin * 2.0)
	size = _fitted_size * zoom_factor
