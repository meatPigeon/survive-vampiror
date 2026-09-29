class_name GroundCommand
extends Node

signal move_requested(position: Vector3)

@export var camera: Camera3D
@export var ground: MeshInstance3D


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	var ground_plane := Plane(Vector3.UP, ground.global_position.y)
	var hit: Variant = ground_plane.intersects_ray(
		camera.project_ray_origin(event.position),
		camera.project_ray_normal(event.position)
	)
	if hit == null:
		return

	var local_hit: Vector3 = ground.to_local(hit)
	var bounds: AABB = ground.mesh.get_aabb()
	if local_hit.x < bounds.position.x or local_hit.x > bounds.end.x:
		return
	if local_hit.z < bounds.position.z or local_hit.z > bounds.end.z:
		return

	move_requested.emit(hit)
	get_viewport().set_input_as_handled()
