class_name ZombieKindMarker
extends MeshInstance3D

const PERMANENT_COLOR := Color("edd9ad")
const TEMPORARY_COLOR := Color("78dfef")

var base_color: Color = PERMANENT_COLOR
static var _solid_ring: ArrayMesh
static var _broken_ring: ArrayMesh


func configure(temporary: bool) -> void:
	if _solid_ring == null:
		_solid_ring = _build_ring(false)
		_broken_ring = _build_ring(true)
	mesh = _broken_ring if temporary else _solid_ring
	base_color = TEMPORARY_COLOR if temporary else PERMANENT_COLOR
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = base_color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = material


static func _build_ring(broken: bool) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var sections: int = 4 if broken else 1
	var steps: int = 10 if broken else 48
	for section: int in range(sections):
		var start: float = float(section) * TAU / float(sections) + (0.18 if broken else 0.0)
		var span: float = TAU / float(sections) - (0.36 if broken else 0.0)
		for step: int in range(steps):
			var angle0: float = start + span * float(step) / float(steps)
			var angle1: float = start + span * float(step + 1) / float(steps)
			var a := Vector3(sin(angle0), 0, cos(angle0))
			var b := Vector3(sin(angle1), 0, cos(angle1))
			vertices.append_array(PackedVector3Array([a * 0.29, a * 0.39, b * 0.29, a * 0.39, b * 0.39, b * 0.29]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result
