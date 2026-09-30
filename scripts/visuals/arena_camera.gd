extends Camera3D

@export var ground: MeshInstance3D
@export var framing_margin: float = 1.5


func _ready() -> void:
	get_viewport().size_changed.connect(_frame_arena)
	_frame_arena()


func _frame_arena() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.y <= 0.0:
		return
	var floor_size: Vector3 = ground.mesh.get_aabb().size
	var aspect: float = viewport_size.x / viewport_size.y
	# Orthographic projection compresses floor depth by the camera's tilt.
	var projected_depth: float = floor_size.z * absf(global_basis.y.z)
	size = maxf((floor_size.x + framing_margin * 2.0) / aspect,
		projected_depth + framing_margin * 2.0)
