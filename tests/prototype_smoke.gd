extends SceneTree

var _failures: int = 0
var _horde: HordeController
var _camera: Camera3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	var scene: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	# This fixture isolates crowd controls; combat has its own smoke test.
	scene.set_physics_process(false)
	_horde = scene.get_node("Horde") as HordeController
	_camera = scene.get_node("Camera") as Camera3D
	await _frames(2)
	_check(_horde.agents.size() == 40, "40 individual agents spawn")
	var survivor_visual: Node3D = scene.get_node("Survivor/Visual") as Node3D
	var survivor_animator: AnimationPlayer = survivor_visual.get_node("AnimationPlayer") as AnimationPlayer
	_check(survivor_visual.scene_file_path == "res://assets/characters/medieval_knight.glb", "survivor uses knight model")
	_check(survivor_animator.current_animation == &"idle", "knight plays idle")
	for agent: HordeAgent in _horde.agents:
		_check(agent.visual.scene_file_path == "res://assets/characters/zombie.glb", "agent uses zombie model")
		_check(agent.animation_player.current_animation == &"idle", "zombie starts idle")
	var survivor_position: Vector3 = scene.get_node("Survivor").global_position
	var initial_position: Vector3 = _horde.agents[0].global_position
	await _frames(30)
	_check(_horde.agents[0].global_position == initial_position, "horde waits for a command")
	await _capture("initial")

	_click(Vector2(2, 2))
	_click(_camera.unproject_position(Vector3(12, 0, -7)), MOUSE_BUTTON_RIGHT)
	await _frames(2)
	_check(not _horde.target_marker.visible, "off-floor and right clicks are ignored")

	var target := Vector3(12, 0, -7)
	_click(_camera.unproject_position(target))
	await _frames(2)
	_check(_horde.command_position.distance_to(target) < 0.01, "screen click projects onto ground")
	_check(_horde.target_marker.visible, "command marker appears")
	await _frames(120)
	_check(_horde.agents[0].global_position.distance_to(target) < initial_position.distance_to(target) - 4.0,
		"horde flows toward the command")
	for agent: HordeAgent in _horde.agents:
		_check(agent.animation_player.current_animation == &"run", "moving zombie plays run")
	var moving_agent: HordeAgent = _horde.agents[0]
	var previous_position: Vector3 = moving_agent.global_position
	await _frames(2)
	var movement_direction: Vector3 = (moving_agent.global_position - previous_position).normalized()
	_check((-moving_agent.visual.global_basis.z.normalized()).dot(movement_direction) > 0.9,
		"zombie faces its movement direction")
	await _capture("moving")

	# Redirect the moving crowd, then let it gather at the new target.
	target = Vector3(-12, 0, -8)
	_click(_camera.unproject_position(target))
	await _frames(900)
	_check_gathering(target, "redirect")
	for agent: HordeAgent in _horde.agents:
		_check(agent.animation_player.current_animation == &"idle", "gathered zombie returns to idle")
	await _capture("gathered")

	target = Vector3(21.8, 0, 15.8)
	_click(_camera.unproject_position(target))
	await _frames(1200)
	_check_gathering(target, "corner")
	for agent: HordeAgent in _horde.agents:
		var safe_bounds: Rect2 = _horde.movement_bounds.grow(-agent.body_radius + 0.001)
		_check(safe_bounds.has_point(Vector2(agent.global_position.x, agent.global_position.z)), "agent stays on floor")
	_check(scene.get_node("Survivor").global_position == survivor_position, "survivor stays stationary")
	_check(survivor_animator.current_animation == &"idle", "knight remains idle while horde moves")
	await _capture("corner")

	# The same screen-to-ground path must work after resizing the window.
	root.size = Vector2i(960, 720)
	await _frames(2)
	target = Vector3(6, 0, -3)
	_click(_camera.unproject_position(target))
	await _frames(1000)
	_check(_horde.command_position.distance_to(target) < 0.01, "click projection survives resize")
	_check_gathering(target, "survivor")
	await _capture("survivor")

	# Fit the whole arena after resize, including character heads near its edges.
	for window_size: Vector2i in [Vector2i(1280, 800), Vector2i(1152, 648), Vector2i(960, 720), Vector2i(1120, 480)]:
		root.size = window_size
		await _frames(3)
		var viewport_rect: Rect2 = root.get_visible_rect()
		var rendered_rect: Rect2 = root.get_stretch_transform() * viewport_rect
		_check(rendered_rect.size.is_equal_approx(Vector2(root.size)), "viewport fills resized window without letterboxing")
		for x: float in [-22.0, 22.0]:
			for z: float in [-16.0, 16.0]:
				for y: float in [0.0, 2.3]:
					_check(viewport_rect.has_point(_camera.unproject_position(Vector3(x, y, z))), "playable edges and character heads stay visible after resize")
		_click(_camera.unproject_position(target))
		await _frames(2)
		_check(_horde.command_position.distance_to(target) < 0.01, "ground command remains accurate at each aspect ratio")
		_click(Vector2(2, 2))
		await _frames(2)
		_check(_horde.command_position.distance_to(target) < 0.01, "visual surround does not expand command bounds")
		await _capture("viewport_%dx%d" % [window_size.x, window_size.y])
	print("Prototype smoke: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)


func _click(screen_position: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.position = screen_position
	event.button_index = button
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventMouseButton
	event.pressed = false
	root.push_input(event, true)


func _frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame


func _check_gathering(target: Vector3, label: String) -> void:
	var largest_distance: float = 0.0
	var nearest_pair: float = INF
	for agent: HordeAgent in _horde.agents:
		largest_distance = maxf(largest_distance, agent.global_position.distance_to(target))
		for other: HordeAgent in _horde.agents:
			if agent != other:
				nearest_pair = minf(nearest_pair, agent.global_position.distance_to(other.global_position))
	print("%s: furthest from target %.2f, nearest pair %.2f" % [label, largest_distance, nearest_pair])
	_check(largest_distance < 5.0, label + ": every agent reaches the commanded area")
	_check(nearest_pair > 0.56, label + ": crowd bodies remain separate")


func _check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		_failures += 1


func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/survive_vampiror_%s.png" % label)
