class_name AttackPreview
extends MeshInstance3D


func show_arc(origin: Vector3, direction: Vector3, radius: float, angle: float, color: Color) -> void:
	var vertices := PackedVector3Array()
	var half_angle: float = deg_to_rad(angle * 0.5)
	for index: int in range(32):
		var start: float = lerpf(-half_angle, half_angle, float(index) / 32.0)
		var end: float = lerpf(-half_angle, half_angle, float(index + 1) / 32.0)
		vertices.append(Vector3.ZERO)
		vertices.append(Vector3(sin(start), 0, -cos(start)) * radius)
		vertices.append(Vector3(sin(end), 0, -cos(end)) * radius)
	_show_vertices(vertices, origin, direction, color)


func show_lane(origin: Vector3, direction: Vector3, distance: float, width: float, color: Color) -> void:
	var left := Vector3(-width * 0.5, 0, 0)
	var right := Vector3(width * 0.5, 0, 0)
	var end := Vector3(0, 0, -distance)
	_show_vertices(PackedVector3Array([left, right, left + end, right, right + end, left + end]), origin, direction, color)


func _show_vertices(vertices: PackedVector3Array, origin: Vector3, direction: Vector3, color: Color) -> void:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var preview_mesh := ArrayMesh.new()
	preview_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = preview_mesh
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = color
	material_override = material
	global_position = origin + Vector3.UP * 0.05
	global_rotation = Vector3(0, atan2(-direction.x, -direction.z), 0)
	show()
