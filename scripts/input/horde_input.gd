class_name HordeInput
extends Node

signal move_requested(direction: Vector3)
signal sprint_requested()
signal pause_requested()
signal restart_requested()
signal zoom_requested(steps: float)
signal ability_requested(slot: int)
signal aim_requested(position: Vector3, on_ground: bool)
signal fire_requested()
signal aim_cancel_requested()

@export var camera: Camera3D
var _held: Dictionary[Key, bool] = {}
var _pointer_position := Vector2.ZERO


func _ready() -> void:
	get_window().focus_exited.connect(clear_movement)
	get_window().focus_exited.connect(func() -> void: aim_cancel_requested.emit())
	_pointer_position = get_viewport().get_mouse_position()


func _process(_delta: float) -> void:
	if not get_tree().paused:
		refresh_aim()


func refresh_aim() -> void:
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(camera.project_ray_origin(_pointer_position), camera.project_ray_normal(_pointer_position))
	var on_ground: bool = hit != null and get_viewport().get_visible_rect().has_point(_pointer_position)
	aim_requested.emit(hit if hit != null else Vector3.ZERO, on_ground)


func clear_movement() -> void:
	if not _held.is_empty():
		_held.clear()
		move_requested.emit(Vector3.ZERO)


func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		_pointer_position = event.position
	# Releases must reach us even when a focused UI control consumes the event.
	if event is InputEventKey and not event.pressed:
		var key: Key = _physical_key(event)
		if _held.has(key):
			_held.erase(key)
			_emit_direction()


func _emit_direction() -> void:
	var horizontal: float = float(_held.has(KEY_D)) - float(_held.has(KEY_A))
	var vertical: float = float(_held.has(KEY_S)) - float(_held.has(KEY_W))
	var right: Vector3 = camera.global_basis.x
	var back: Vector3 = camera.global_basis.z
	right.y = 0.0
	back.y = 0.0
	move_requested.emit((right.normalized() * horizontal + back.normalized() * vertical).normalized())


func _physical_key(event: InputEventKey) -> Key:
	return event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and not get_tree().paused:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			get_viewport().set_input_as_handled()
			if event.button_index == MOUSE_BUTTON_LEFT:
				refresh_aim()
				fire_requested.emit()
			else:
				aim_cancel_requested.emit()
			return
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			get_viewport().set_input_as_handled()
			var steps: float = event.factor if event.factor > 0.0 else 1.0
			zoom_requested.emit(steps if event.button_index == MOUSE_BUTTON_WHEEL_UP else -steps)
			return
	if event is InputEventKey and event.pressed and not event.echo:
		var key: Key = _physical_key(event)
		if key in [KEY_W, KEY_A, KEY_S, KEY_D]:
			if not get_tree().paused:
				_held[key] = true
				_emit_direction()
			get_viewport().set_input_as_handled()
			return
		if key not in [KEY_ESCAPE, KEY_R, KEY_SPACE, KEY_Q, KEY_E]:
			return
		# Restart can remove this node from the tree synchronously.
		get_viewport().set_input_as_handled()
		if key == KEY_ESCAPE:
			pause_requested.emit()
		elif key == KEY_R:
			restart_requested.emit()
		elif key == KEY_SPACE and not get_tree().paused:
			sprint_requested.emit()
		elif key in [KEY_Q, KEY_E] and not get_tree().paused:
			ability_requested.emit(0 if key == KEY_Q else 1)
		else:
			return
		return
