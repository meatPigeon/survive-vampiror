extends SceneTree

var _failures: int = 0
var _horde: HordeController
var _pilot := preload("res://tests/support/horde_pilot.gd").new()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	var scene: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	_horde = scene.horde
	var camera: Camera3D = scene.get_node("Camera")
	await _frames(3)
	_check(_horde.agents.size() == 40, "40 individual agents spawn")
	for agent: HordeAgent in _horde.agents:
		_check(agent.visual.scene_file_path == "res://assets/characters/zombie.glb" and agent.animation_player.current_animation == &"idle", "zombies start with their idle model animation")
	var before: Vector3 = _pilot.center(_horde)
	await _frames(30)
	_check(_pilot.center(_horde) == before and not scene.battle_started, "ready horde waits for WASD")
	await _capture("initial")
	for button: MouseButton in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		var event := InputEventMouseButton.new()
		event.position = camera.unproject_position(Vector3.ZERO)
		event.button_index = button
		event.pressed = true
		root.push_input(event, true)
		event.pressed = false
		root.push_input(event, true)
	_check(not scene.battle_started and _horde.move_direction == Vector3.ZERO, "floor clicks cannot move or start the horde")
	_pilot.move(root, Vector2.RIGHT)
	await _frames(120)
	_check(scene.battle_started and _pilot.center(_horde).x > before.x + 4.0, "held D moves the whole horde right and starts battle")
	for agent: HordeAgent in _horde.agents:
		_check(agent.animation_player.current_animation == &"run", "moving zombies run")
	await _capture("moving")
	_pilot.move(root, Vector2(1, -1))
	_check(is_equal_approx(_horde.move_direction.length(), 1.0) and _horde.move_direction.z < 0.0, "W+D gives normalized screen-relative diagonal movement")
	await _frames(60)
	_pilot.move(root, Vector2.ZERO)
	await _frames(2)
	var positions: Array[Vector3] = []
	for agent: HordeAgent in _horde.agents:
		positions.append(agent.global_position)
	await _frames(30)
	for index: int in range(_horde.agents.size()):
		_check(_horde.agents[index].global_position == positions[index] and _horde.agents[index].animation_player.current_animation == &"idle", "releasing WASD stops every zombie and restores idle")
	await _capture("stopped")
	# Physical positions work on non-English layouts; opposing keys cancel.
	var physical := InputEventKey.new()
	physical.keycode = KEY_Z
	physical.physical_keycode = KEY_W
	physical.pressed = true
	root.push_input(physical, true)
	_check(_horde.move_direction.is_equal_approx(Vector3.FORWARD), "physical W works independently of the printed letter")
	_pilot.key(root, KEY_S, true)
	_check(_horde.move_direction == Vector3.ZERO, "W+S cancel")
	_pilot.key(root, KEY_W, false)
	_check(_horde.move_direction.is_equal_approx(Vector3.BACK), "releasing one opposing key preserves the other")
	_pilot.key(root, KEY_S, false)
	_pilot.move(root, Vector2.LEFT)
	_pilot.key(root, KEY_SPACE, true)
	_pilot.key(root, KEY_SPACE, false)
	_check(_horde.sprint_remaining == 0.0, "Space stays locked without the sprint perk")
	_horde.grant_ability(HordeAbility.Upgrade.SPRINT)
	_pilot.key(root, KEY_SPACE, true)
	_pilot.key(root, KEY_SPACE, false)
	_check(_horde.sprint_remaining > 0.0, "Space sprints during WASD movement")
	await _frames(5)
	scene.toggle_pause()
	before = _pilot.center(_horde)
	await _frames(20)
	_check(_pilot.center(_horde) == before and _horde.move_direction == Vector3.ZERO, "pause freezes movement and clears held intent")
	_pilot.move(root, Vector2.ZERO)
	_pilot.move(root, Vector2.RIGHT)
	_check(_horde.move_direction == Vector3.ZERO, "WASD is ignored on pause")
	_pilot.move(root, Vector2.ZERO)
	scene.toggle_pause()
	_pilot.move(root, Vector2.RIGHT)
	await _frames(5)
	root.focus_exited.emit()
	_check(_horde.move_direction == Vector3.ZERO, "focus loss clears held keys")
	_pilot.move(root, Vector2.ZERO)
	_pilot.move(root, Vector2(1, 1))
	await _frames(1100)
	for agent: HordeAgent in _horde.agents:
		_check(_horde.movement_bounds.grow(-agent.body_radius + 0.001).has_point(Vector2(agent.global_position.x, agent.global_position.z)), "WASD crowd stays inside the arena at a corner")
	_pilot.move(root, Vector2.ZERO)
	await _capture("corner")
	for window_size: Vector2i in [Vector2i(1280, 800), Vector2i(1152, 648), Vector2i(960, 720), Vector2i(1120, 480)]:
		root.size = window_size
		await _frames(3)
		var viewport_rect: Rect2 = root.get_visible_rect()
		_check((root.get_stretch_transform() * viewport_rect).size.is_equal_approx(Vector2(root.size)), "viewport fills resized window")
		for x: float in [_horde.movement_bounds.position.x, _horde.movement_bounds.end.x]:
			for z: float in [_horde.movement_bounds.position.y, _horde.movement_bounds.end.y]:
				for y: float in [0.0, 2.3]:
					_check(viewport_rect.has_point(camera.unproject_position(Vector3(x, y, z))), "arena and heads remain visible")
		_pilot.move(root, Vector2.LEFT)
		_check(_horde.move_direction.is_equal_approx(Vector3.LEFT), "WASD direction survives resizing")
		_pilot.move(root, Vector2.ZERO)
		await _capture("viewport_%dx%d" % [window_size.x, window_size.y])
	scene.free()
	await process_frame
	print("Prototype smoke: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)


func _frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame


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
