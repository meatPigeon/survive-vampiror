extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	var arena: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	# Isolate camera/input from combat, while retaining ordinary horde movement.
	arena.set_physics_process(false)
	await _frames(4)
	var camera: Camera3D = arena.get_node("Camera")
	var fitted_size: float = camera.size
	var overview_position: Vector3 = camera.global_position
	var overview_rotation: Vector3 = camera.global_rotation
	await _capture("default")
	_wheel(MOUSE_BUTTON_WHEEL_UP)
	_check(camera.size == fitted_size, "zoom eases rather than snapping on input")
	_check(camera.global_position == overview_position, "follow does not snap on the wheel event")
	await _frames(45)
	_check(camera.size < fitted_size, "wheel up zooms in")
	_check(not arena.battle_started, "zoom does not start battle")
	for index: int in range(60):
		_wheel(MOUSE_BUTTON_WHEEL_UP)
	await _frames(60)
	_check(is_equal_approx(camera.get("zoom_factor"), camera.get("minimum_zoom")), "near zoom is bounded")
	_check(absf(camera.size - fitted_size * float(camera.get("minimum_zoom"))) < 0.05, "near zoom settles")
	_check(_view_center(camera).distance_to(_mobile_center(arena.horde)) < 0.08, "zoom centers the view on the horde instead of the arena")
	_check(camera.global_rotation.is_equal_approx(overview_rotation) and camera.global_position.y == overview_position.y, "follow preserves camera angle and height")
	await _capture("near")
	# Camera-relative movement direction must stay unchanged at a different scale.
	var agent: HordeAgent = arena.horde.agents[0]
	var initial: Vector3 = agent.global_position
	var camera_before: Vector3 = camera.global_position
	_key(KEY_D, true)
	await _frames(20)
	_key(KEY_D, false)
	_check(agent.global_position.x > initial.x and arena.horde.move_direction.is_zero_approx(), "movement and key release work while zoomed")
	_check(camera.global_position.x > camera_before.x, "camera follows actual horde travel")
	await _frames(35)
	_check(_view_center(camera).distance_to(_mobile_center(arena.horde)) < 0.08, "camera settles onto the stopped horde")
	await _capture("follow")
	# Detached mines must not pull the view away from the controlled crowd.
	arena.horde.grant_ability(HordeAbility.Upgrade.DETONATION)
	arena.command_ability()
	for mine: HordeAgent in arena.horde.ability.armed:
		mine.global_position += Vector3(-15, 0, 6)
	await _frames(40)
	_check(_view_center(camera).distance_to(_mobile_center(arena.horde)) < 0.08, "camera ignores detached ability agents")
	for mine: HordeAgent in arena.horde.ability.armed:
		mine.global_position -= Vector3(-15, 0, 6)
	arena.horde.ability.cancel()
	# No mobile member can briefly remain after casualties; hold a finite view.
	for member: HordeAgent in arena.horde.agents:
		member.ability_locked = true
	camera_before = camera.global_position
	await _frames(4)
	_check(camera.global_position.is_finite() and camera.global_position == camera_before, "no mobile agents holds the last view")
	for member: HordeAgent in arena.horde.agents:
		member.ability_locked = false
	_key(KEY_D, true)
	await _frames(8)
	arena.toggle_pause()
	camera_before = camera.global_position
	await _frames(8)
	_check(camera.global_position == camera_before, "pause freezes follow even while it is catching up")
	arena.toggle_pause()
	await _frames(40)
	root.size = Vector2i(960, 600)
	await _frames(4)
	_check(_view_center(camera).distance_to(_mobile_center(arena.horde)) < 0.08, "resize retains the followed horde center")
	await _capture("follow_small")
	arena.battle_audio.stop_all()
	for index: int in range(60):
		_wheel(MOUSE_BUTTON_WHEEL_DOWN)
	await _frames(60)
	_check(is_equal_approx(camera.get("zoom_factor"), camera.get("maximum_zoom")), "far zoom is bounded")
	_check(camera.size > fitted_size, "wheel down zooms out")
	_check(camera.global_position.distance_to(overview_position) < 0.08, "zooming out restores the overview position")
	await _capture("far")
	root.size = Vector2i(960, 720)
	await _frames(4)
	var resized: float = camera.size
	_check(is_equal_approx(camera.get("zoom_factor"), camera.get("maximum_zoom")) and not is_equal_approx(resized, fitted_size * float(camera.get("maximum_zoom"))), "resize recomputes framing and retains zoom")
	arena.toggle_pause()
	_wheel(MOUSE_BUTTON_WHEEL_UP)
	await _frames(4)
	_check(is_equal_approx(camera.size, resized), "pause blocks zoom")
	arena.toggle_pause()
	arena.battle_over = true
	_wheel(MOUSE_BUTTON_WHEEL_UP)
	await _frames(4)
	_check(is_equal_approx(camera.size, resized), "outcome blocks zoom even without a UI overlay")
	arena.restart()
	await _frames(6)
	_check(is_equal_approx(current_scene.get_node("Camera").get("zoom_factor"), 1.0), "restart resets zoom")
	_check(current_scene.get_node("Camera").global_position == overview_position, "restart resets camera position")
	current_scene.battle_audio.stop_all()
	current_scene.queue_free()
	await _frames(8)
	print("PASS: camera zoom smoke" if _failures == 0 else "FAIL: camera zoom smoke")
	quit(0 if _failures == 0 else 1)


func _mobile_center(horde: HordeController) -> Vector3:
	var center := Vector3.ZERO
	var count: int = 0
	for agent: HordeAgent in horde.agents:
		if not agent.ability_locked:
			center += agent.global_position
			count += 1
	return center / float(count)


func _view_center(camera: Camera3D) -> Vector3:
	var screen: Vector2 = root.get_visible_rect().size * 0.5
	return Plane(Vector3.UP, 0.0).intersects_ray(camera.project_ray_origin(screen), camera.project_ray_normal(screen))


func _wheel(button: MouseButton) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(root.get_visible_rect().size * 0.5)
	root.push_input(motion, true)
	var event := InputEventMouseButton.new()
	event.position = motion.position
	event.button_index = button
	event.factor = 1.0
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventMouseButton
	event.pressed = false
	root.push_input(event, true)


func _key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = pressed
	root.push_input(event, true)


func _frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame


func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/survive_zoom_%s.png" % label)


func _check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		_failures += 1
