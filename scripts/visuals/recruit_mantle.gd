extends MeshInstance3D

static var _mantle: ArrayMesh


func _ready() -> void:
	if _mantle == null:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		# Short shoulder cloth with an open chest and a torn, pointed back hem.
		for panel: int in range(10):
			var a: float = lerpf(-2.25, 2.25, float(panel) / 10.0)
			var b: float = lerpf(-2.25, 2.25, float(panel + 1) / 10.0)
			var top_a := Vector3(sin(a) * 0.22, 0.28, cos(a) * 0.22)
			var top_b := Vector3(sin(b) * 0.22, 0.28, cos(b) * 0.22)
			var shoulder_a := Vector3(sin(a) * 0.62, 0.07, cos(a) * 0.43)
			var shoulder_b := Vector3(sin(b) * 0.62, 0.07, cos(b) * 0.43)
			var hem_a := Vector3(sin(a) * 0.65, -0.34 if panel % 2 == 0 else -0.12, cos(a) * 0.52)
			var hem_b := Vector3(sin(b) * 0.65, -0.34 if (panel + 1) % 2 == 0 else -0.12, cos(b) * 0.52)
			for vertex: Vector3 in [top_a, shoulder_a, top_b, top_b, shoulder_a, shoulder_b,
				shoulder_a, hem_a, shoulder_b, shoulder_b, hem_a, hem_b]:
				surface.add_vertex(vertex)
		surface.generate_normals()
		_mantle = surface.commit()
	mesh = _mantle
