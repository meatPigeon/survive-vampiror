extends SceneTree

var _failures: int = 0
var _arena: Node3D
var _camera_transform: Transform3D
var _camera_size: float


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	_arena = load("res://scenes/main.tscn").instantiate()
	root.add_child(_arena)
	current_scene = _arena
	_camera_transform = _arena.get_node("Camera").transform
	_camera_size = _arena.get_node("Camera").size
	_arena.set_physics_process(false)
	_arena.horde.set_physics_process(false)
	_arena.battle_audio.stop_all()
	var knight: Survivor = _arena.survivor
	var agent: HordeAgent = _arena.horde.agents[0]
	knight.position = Vector3.ZERO
	agent.position = Vector3(4, 0, 0)
	await _frames(4)
	_check(not knight.visual.motion_air.visible and not agent.visual.motion_air.visible, "idle has no wind")
	var original_root: Transform3D = knight.transform
	knight._begin_attack(Survivor.Attack.SWEEP, Vector3.FORWARD * 4.0)
	await _frames(10)
	_check(not knight.visual.motion_air.visible, "warning remains separate from the slash")
	knight.update_combat([], knight.current_windup())
	await _frames(5)
	_check(knight.visual.motion_air.visible and knight.transform == original_root, "impact shows a visual-only crescent")
	await _capture("sweep", Vector3.ZERO, 7.0)
	paused = true
	var age: float = knight.visual.motion_air._slash_age
	await _frames(10)
	_check(knight.visual.motion_air._slash_age == age, "pause freezes the air ribbon")
	paused = false
	await _frames(25)
	_check(not knight.visual.motion_air.visible, "slash fades without a persistent ring")
	knight._begin_attack(Survivor.Attack.SPIN, Vector3.FORWARD)
	knight.update_combat([], knight.current_windup())
	await _frames(12)
	await _capture("spin", Vector3.ZERO, 7.0)
	_check(knight.visual.motion_air.visible, "spin has its own moving crescent")
	knight.stop_combat()
	_check(not knight.visual.motion_air.visible, "stopping combat clears remaining wind")
	knight.configure_wave(2, 1000)
	knight._begin_attack(Survivor.Attack.CROSSBOW, Vector3.FORWARD * 8.0)
	knight.update_combat([], knight.current_windup())
	await _frames(5)
	_check(not knight.visual.motion_air.visible, "crossbow never produces a melee arc")
	knight._begin_attack(Survivor.Attack.CHARGE, Vector3.FORWARD * 6.0)
	knight.update_combat([], knight.current_windup())
	for frame: int in range(12):
		knight.update_combat([], 1.0 / 60.0)
		await process_frame
	_check(knight.visual.motion_air.visible, "actual charge travel produces wind")
	await _capture("charge", knight.position, 7.0)
	knight.stop_combat()
	knight.configure_wave(3, 1200)
	knight.state = Survivor.State.HUNT
	agent.position = knight.position + Vector3.FORWARD * 20.0
	for frame: int in range(12):
		knight.update_combat([agent], 1.0 / 60.0)
		await process_frame
	_check(knight.visual.motion_air.visible, "mounted pursuit also cuts through the air")
	await _capture("mounted", knight.position, 7.0)
	knight.visual.die()
	_check(not knight.visual.motion_air.visible, "death immediately clears knight wind")
	knight.hide()
	agent.position = Vector3.ZERO
	await _frames(2)
	await _move_agent(agent, 1.0, 15)
	_check(not agent.visual.motion_air.visible, "ordinary zombie movement has no sprint streaks")
	await _move_agent(agent, 2.0, 15)
	_check(agent.visual.motion_air.visible, "actual zombie sprint shows wind")
	await _capture("sprint", agent.position, 4.0)
	# No root travel despite a held sprint: blocked movement must settle too.
	await _frames(15)
	_check(not agent.visual.motion_air.visible, "stationary sprint cannot leave wind hanging")
	await _move_agent(agent, 2.0, 12)
	agent.stop()
	_check(not agent.visual.motion_air.visible, "release/intermission clears zombie wind")
	await _move_agent(agent, 2.0, 12)
	agent.health.take_damage(100)
	_check(not agent.visual.motion_air.visible, "dying zombies clear sprint wind")
	await _frames(45)
	# Exercise the whole moving crowd at ordinary gameplay camera scale.
	_arena.horde.recruit(21, Vector3(-8, 0, 3))
	var index: int = 0
	for member: HordeAgent in _arena.horde.agents:
		member.position = Vector3(-10 + index % 10, 0, 1 + index / 10)
		index += 1
	_arena.horde.command_direction(Vector3.RIGHT)
	_arena.horde.grant_ability(HordeAbility.Upgrade.SPRINT)
	_arena.horde.command_sprint()
	for frame: int in range(20):
		_arena.horde._physics_process(1.0 / 60.0)
		await process_frame
	var visible_count: int = 0
	for member: HordeAgent in _arena.horde.agents:
		if member.visual.motion_air.visible:
			visible_count += 1
	_check(visible_count > 40, "a full moving horde has bounded per-character streaks")
	await _capture("crowd", Vector3(-6, 0, 3), 16.0)
	await _capture("arena", Vector3.ZERO, 39.0)
	_arena.horde.stop()
	for member: HordeAgent in _arena.horde.agents:
		_check(not member.visual.motion_air.visible, "outcome leaves no sprint trails")
	_arena.queue_free()
	await _frames(3)
	print("Motion air smoke: ", "PASS" if _failures == 0 else "FAIL")
	quit(0 if _failures == 0 else 1)


func _move_agent(agent: HordeAgent, multiplier: float, frames: int) -> void:
	for frame: int in range(frames):
		agent.move_in_direction(Vector3.RIGHT, [], Rect2(-100, -100, 200, 200), 1.0 / 60.0, null, multiplier)
		await process_frame


func _frames(count: int) -> void:
	for frame: int in range(count):
		await process_frame


func _capture(label: String, center: Vector3, size: float) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		return
	var camera: Camera3D = _arena.get_node("Camera")
	camera.set_process(false)
	camera.position = center + Vector3(2.5, 7, 8)
	camera.look_at(center + Vector3.UP * 0.5)
	camera.size = size
	if label == "arena":
		camera.transform = _camera_transform
		camera.size = _camera_size
	_arena.hud.visible = label == "arena"
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/survive_air_%s.png" % label)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failures += 1
