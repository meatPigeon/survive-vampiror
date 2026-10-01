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


func show_ring(origin: Vector3, radius: float, width: float, color: Color) -> void:
	var vertices := PackedVector3Array()
	for index: int in range(48):
		var start: float = TAU * float(index) / 48.0
		var end: float = TAU * float(index + 1) / 48.0
		var a := Vector3(cos(start), 0, sin(start))
		var b := Vector3(cos(end), 0, sin(end))
		var inner: float = maxf(0.0, radius - width)
		vertices.append_array(PackedVector3Array([a * inner, a * radius, b * radius, a * inner, b * radius, b * inner]))
	_show_vertices(vertices, origin, Vector3.FORWARD, color)


func show_lane(origin: Vector3, direction: Vector3, distance: float, width: float, color: Color) -> void:
	var left := Vector3(-width * 0.5, 0, 0)
	var right := Vector3(width * 0.5, 0, 0)
	var end := Vector3(0, 0, -distance)
	_show_vertices(PackedVector3Array([left, right, left + end, right, right + end, left + end]), origin, direction, color)


func show_rush(origin: Vector3, direction: Vector3, width: float) -> void:
	# Two open chevrons show a changing heading, not a promised straight lane.
	var vertices := PackedVector3Array()
	for distance: float in [1.0, 2.5]:
		var tip := Vector3(0, 0, -distance - 1.0)
		var inner := Vector3(0, 0, -distance - 0.62)
		for side: float in [-1.0, 1.0]:
			var edge := Vector3(side * width * 0.5, 0, -distance)
			var inset := edge + Vector3(0, 0, 0.38)
			vertices.append_array(PackedVector3Array([tip, edge, inner, inner, edge, inset]))
	_show_vertices(vertices, origin, direction, Color(1.0, 0.32, 0.22, 0.72))


func follow_heading(origin: Vector3, direction: Vector3) -> void:
	global_position = origin + Vector3.UP * 0.05
	global_rotation = Vector3(0, atan2(-direction.x, -direction.z), 0)


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
	follow_heading(origin, direction)
	show()
