class_name GroundCommand
extends Node

signal move_requested(position: Vector3)
signal sprint_requested()
signal pause_requested()
signal restart_requested()

@export var camera: Camera3D
@export var ground: MeshInstance3D


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
		if key not in [KEY_ESCAPE, KEY_R, KEY_SPACE]:
			return
		# Restart can remove this node from the tree synchronously.
		get_viewport().set_input_as_handled()
		if key == KEY_ESCAPE:
			pause_requested.emit()
		elif key == KEY_R:
			restart_requested.emit()
		elif key == KEY_SPACE and not get_tree().paused:
			sprint_requested.emit()
		else:
			return
		return
	if get_tree().paused:
		return
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
