extends SceneTree

const MAIN: PackedScene = preload("res://scenes/main.tscn")
var _failures: int = 0
var _pilot := preload("res://tests/support/horde_pilot.gd").new()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	for wave: int in [1, 2, 3]:
		var scene: Node3D = _fixture(wave)
		var knight: Survivor = scene.survivor
		var target: HordeAgent = scene.horde.agents[0]
		target.position = Vector3.FORWARD * 6.0
		knight._crossbow_cooldown = 100.0
		knight._rush_cooldown = 0.0
		knight.update_combat([target], 0.01)
		_check((knight.attack_kind == Survivor.Attack.RUSH) == (wave == 3), "only the mounted wave selects stampede")
		scene.battle_audio.stop_all()
		scene.free()

	var scene: Node3D = _fixture(3)
	var knight: Survivor = scene.survivor
	var target: HordeAgent = scene.horde.agents[0]
	target.position = Vector3.FORWARD * 8.0
	knight.movement_bounds = Rect2(-100, -100, 200, 200)
	knight._begin_attack(Survivor.Attack.RUSH, target.position)
	var heading: Vector3 = knight._attack_direction
	var warning_position: Vector3 = knight.attack_area.global_position
	var mesh: Mesh = knight.attack_area.mesh
	target.position = Vector3.RIGHT * 10.0
	knight.update_combat([target], knight.rush_windup * 0.5)
	_check(knight.position == Vector3.ZERO and knight._attack_direction == heading, "windup is stationary and locks its initial heading")
	_check(target.health.current_health == 30 and knight.attack_area.visible, "warning is visible and deals no contact damage")
	knight.update_combat([target], knight.rush_windup * 0.5)
	_check(knight.state == Survivor.State.STRIKE and target.health.current_health == 30, "launch does not accidentally apply a melee sector")
	_check(knight.visual.horse.moving and knight.visual.motion_air._streaming, "stampede starts gallop and air trails")
	knight.update_combat([target], 0.1)
	_check(knight._rush_speed > knight.move_speed and knight._rush_speed < knight.rush_speed, "speed accelerates rather than jumping straight to maximum")
	_check(heading.angle_to(knight._attack_direction) < deg_to_rad(2.0), "initial steering has angular inertia")
	var previous_turn: float = knight._rush_turn
	for tick: int in range(45):
		heading = knight._attack_direction
		knight.update_combat([target], 1.0 / 60.0)
		_check(heading.angle_to(knight._attack_direction) <= deg_to_rad(knight.rush_turn_speed) / 60.0 + 0.001, "turn speed stays bounded")
		_check(absf(knight._rush_turn - previous_turn) <= deg_to_rad(knight.rush_turn_acceleration) / 60.0 + 0.0001, "angular acceleration stays bounded")
		previous_turn = knight._rush_turn
	_check(knight._attack_direction.x > 0.25 and is_equal_approx(knight._rush_speed, knight.rush_speed), "pursuit actually curves toward the live target while maintaining speed")
	target.position = knight.position + Vector3.LEFT * 20.0
	knight.update_combat([target], 0.1)
	_check(signf(knight._rush_turn) == signf(previous_turn), "a sharp direction reversal first has to shed existing turn momentum")
	_check(knight.attack_area.mesh == mesh and knight.attack_area.global_position != warning_position, "heading chevrons move without rebuilding their mesh")
	_check((-knight.attack_area.global_basis.z).is_equal_approx(knight._attack_direction), "moving marker agrees with the real travel direction")
	knight.update_combat([target], 10.0)
	_check(knight.state == Survivor.State.RECOVERY and knight._time == 0.0, "a large tick ends the timed pursuit with a complete recovery window")
	_check(not knight.attack_area.visible and not knight.visual.horse.moving and not knight.visual.motion_air._streaming, "recovery clears moving telegraph and gallop")
	var recovery_position: Vector3 = knight.position
	knight.update_combat([target], knight.rush_recovery - 0.01)
	_check(knight.state == Survivor.State.RECOVERY and knight.position == recovery_position, "knight stays exposed for the longer recovery")
	knight.update_combat([target], 0.02)
	_check(knight.state == Survivor.State.HUNT, "recovery restores normal combat selection")
	scene.free()

	# Real swept contact: several targets, one damage event each, no line-of-aim hit.
	scene = _fixture(3)
	knight = scene.survivor
	var first: HordeAgent = scene.horde.agents[0]
	var second: HordeAgent = scene.horde.agents[1]
	var outside: HordeAgent = scene.horde.agents[2]
	first.position = Vector3.FORWARD * 2.0
	second.position = Vector3.FORWARD * 4.0
	outside.position = Vector3(2.0, 0, -3.0)
	knight._begin_attack(Survivor.Attack.RUSH, Vector3.FORWARD * 8.0)
	knight.update_combat([first, second], knight.rush_windup)
	knight.update_combat([first, second], 0.8)
	_check(first.health.current_health == 10 and second.health.current_health == 10, "swept movement hits multiple crossed zombies even across a long tick")
	_check(knight.position.z < second.position.z, "the horse runs past a reached target without stopping")
	knight._hit_rush([first, second, outside], Vector3.ZERO, Vector3.FORWARD * 6.0)
	_check(first.health.current_health == 10 and second.health.current_health == 10 and outside.health.current_health == 30, "repeat overlap cannot hit twice and lateral distance matters")
	knight._begin_attack(Survivor.Attack.RUSH, Vector3.FORWARD)
	knight.update_combat([], knight.rush_windup)
	knight._hit_rush([first], first.position, first.position + Vector3.FORWARD)
	_check(not first.health.is_alive(), "hit memory resets for the next stampede")
	scene.free()

	# Steering integration is stable across fine versus coarse caller ticks.
	var a: Node3D = _fixture(3)
	var b: Node3D = _fixture(3)
	var ka: Survivor = a.survivor
	var kb: Survivor = b.survivor
	var ta: HordeAgent = a.horde.agents[0]
	var tb: HordeAgent = b.horde.agents[0]
	ta.position = Vector3(12, 0, -10)
	tb.position = ta.position
	ka._begin_attack(Survivor.Attack.RUSH, Vector3.FORWARD)
	kb._begin_attack(Survivor.Attack.RUSH, Vector3.FORWARD)
	ka.update_combat([ta], ka.rush_windup)
	kb.update_combat([tb], kb.rush_windup)
	ka.update_combat([ta], 1.0)
	for tick: int in range(60):
		kb.update_combat([tb], 1.0 / 60.0)
	_check(ka.position.distance_to(kb.position) < 0.001 and ka._attack_direction.distance_to(kb._attack_direction) < 0.001, "coarse and fine ticks trace the same curved path")
	a.free()
	b.free()

	scene = _fixture(3)
	knight = scene.survivor
	knight.position = Vector3(knight.movement_bounds.end.x - knight.body_radius - 0.5, 0, 0)
	knight._begin_attack(Survivor.Attack.RUSH, knight.position + Vector3.RIGHT * 10.0)
	knight.update_combat([], knight.rush_windup)
	knight.update_combat([], 1.0)
	_check(knight.state == Survivor.State.RECOVERY and knight.position.x <= knight.movement_bounds.end.x - knight.body_radius, "arena edge cancels pursuit inside bounds instead of wall sliding or snapping around")
	_check(knight._rush_speed == 0.0 and knight._rush_turn == 0.0, "wall recovery clears pursuit momentum")
	scene.free()

	# A terminal casualty must stop all later contact in the same combat tick.
	scene = _fixture(3)
	knight = scene.survivor
	first = scene.horde.agents[0]
	for agent: HordeAgent in scene.horde.agents.duplicate():
		if agent != first:
			agent.health.take_damage(agent.health.current_health)
	first.health.take_damage(15)
	first.position = Vector3.FORWARD * 2.0
	scene.horde.recruit(1, Vector3.FORWARD * 5.0)
	second = scene.horde.agents.back()
	second.position = Vector3.FORWARD * 5.0
	knight._begin_attack(Survivor.Attack.RUSH, second.position)
	knight.update_combat(scene.horde.agents, knight.rush_windup)
	knight.update_combat(scene.horde.agents, 2.0)
	_check(scene.battle_over and knight.state == Survivor.State.STOPPED and second.health.current_health == 30, "permanent wipe stops the moving hitbox before later targets")
	_check(not knight.attack_area.visible and not knight.visual.motion_air.visible, "terminal outcome cannot restore the stampede marker or trails")
	scene.battle_audio.stop_all()
	scene.free()

	await _lifecycle_and_render()
	print("Mounted rush smoke: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)


func _lifecycle_and_render() -> void:
	var scene: Node3D = _fixture(3)
	var knight: Survivor = scene.survivor
	var horde: HordeController = scene.horde
	knight.position = Vector3(-7, 0, -6)
	_pilot.move(root, Vector2.RIGHT)
	_pilot.move(root, Vector2.ZERO)
	knight._begin_attack(Survivor.Attack.RUSH, _pilot.center(horde))
	scene._update_status()
	_check(scene.hud.threat.text.contains("Stampede"), "HUD identifies the new attack")
	_check(scene.battle_audio.warning.stream == BattleAudio.WARNINGS[Survivor.Attack.RUSH] and is_equal_approx(scene.battle_audio.warning.pitch_scale, 0.7), "stampede uses its lower warning cue")
	await _capture("warning")
	knight.update_combat(horde.agents, knight.rush_windup)
	scene.set_physics_process(true)
	horde.set_physics_process(true)
	_pilot.move(root, Vector2.RIGHT)
	await _frames(35)
	await _capture("pursuit")
	scene.toggle_pause()
	var position: Vector3 = knight.position
	var heading: Vector3 = knight._attack_direction
	var speed: float = knight._rush_speed
	var timer: float = knight._time
	var cooldown: float = knight._rush_cooldown
	await _frames(12)
	_check(knight.position == position and knight._attack_direction == heading and knight._rush_speed == speed and knight._time == timer and knight._rush_cooldown == cooldown, "tree pause freezes pursuit, inertia and both timers")
	scene.toggle_pause()
	_pilot.move(root, Vector2.LEFT)
	await _frames(35)
	await _capture("turn")
	_check(knight.position != position, "pursuit resumes after pause")
	_pilot.move(root, Vector2.UP)
	await _frames(85)
	await _capture("overshoot")
	_check(knight.state == Survivor.State.STRIKE, "pursuit continues for several seconds through successive direction changes")
	_pilot.move(root, Vector2.ZERO)
	knight.health.take_damage(knight.health.current_health)
	position = knight.position
	knight.update_combat(horde.agents, 5.0)
	_check(knight.state == Survivor.State.STOPPED and knight.position == position and not knight.attack_area.visible and not knight.visual.motion_air.visible, "death cancels pursuit and its visuals")
	scene.restart()
	await _frames(5)
	scene = current_scene
	_check(scene.survivor.wave == 1 and scene.survivor._rush_speed == 0.0 and not scene.survivor.visual.horse.visible, "restart clears mounted attack state")
	scene.battle_audio.stop_all()
	scene.queue_free()
	await _frames(8)


func _fixture(wave: int) -> Node3D:
	var scene: Node3D = MAIN.instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.set_physics_process(false)
	scene.horde.set_physics_process(false)
	scene.wave_index = wave
	scene.survivor.configure_wave(wave, 1200)
	scene.survivor.position = Vector3.ZERO
	return scene


func _frames(count: int) -> void:
	for tick: int in range(count):
		await physics_frame
		await process_frame


func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/survive_rush_%s.png" % label)


func _check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		_failures += 1
