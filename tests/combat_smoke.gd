extends SceneTree

const MAIN: PackedScene = preload("res://scenes/main.tscn")
var _failures: int = 0
var _deaths: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var hp := Health.new()
	hp.max_health = 30
	root.add_child(hp)
	hp.died.connect(func() -> void: _deaths += 1)
	hp.take_damage(-5)
	_check(hp.current_health == 30, "negative damage is ignored")
	hp.take_damage(15)
	_check(hp.current_health == 15, "damage reduces health")
	hp.take_damage(100)
	hp.take_damage(100)
	_check(hp.current_health == 0 and _deaths == 1, "death is emitted once")
	hp.free()

	var scene: Node3D = _fixture()
	var knight: Survivor = scene.get_node("Survivor")
	var horde: HordeController = scene.get_node("Horde")
	var front: HordeAgent = horde.agents[0]
	var rear: HordeAgent = horde.agents[1]
	var outside: HordeAgent = horde.agents[2]
	front.global_position = knight.global_position + Vector3.FORWARD
	rear.global_position = knight.global_position + Vector3.BACK * 1.1
	outside.global_position = knight.global_position + Vector3.FORWARD * 4
	var initial_hp: int = knight.health.current_health
	outside.update_combat(knight, 1.0)
	_check(knight.health.current_health == initial_hp, "out-of-range bite misses")
	front.update_combat(knight, 0.01)
	front.update_combat(knight, 0.1)
	_check(knight.health.current_health == initial_hp - front.bite_damage, "bite respects cooldown")
	front.update_combat(knight, 1.0)
	_check(knight.health.current_health == initial_hp - front.bite_damage * 2, "bite repeats after cooldown")

	knight.update_combat(horde.agents, 0.01)
	_check(knight.state == Survivor.State.WINDUP and knight.attack_kind == Survivor.Attack.SWEEP, "first close attack is a warned sweep")
	_check(knight.attack_area.visible and front.health.current_health == 30, "warning precedes damage")
	knight.update_combat(horde.agents, knight.windup_time)
	_check(front.health.current_health == 15, "sweep hits front")
	_check(rear.health.current_health == 30 and outside.health.current_health == 30, "sweep respects arc and range")
	knight.update_combat(horde.agents, 0.1)
	_check(front.health.current_health == 15, "sweep damages once")
	knight.update_combat(horde.agents, knight.swing_time)
	_check(knight.state == Survivor.State.RECOVERY and not knight.attack_area.visible, "attack creates a safe recovery window")
	knight.update_combat(horde.agents, knight.recovery_time)
	knight.update_combat(horde.agents, 0.01)
	front.global_position += Vector3.FORWARD * 4
	knight.update_combat(horde.agents, knight.windup_time)
	_check(front.health.current_health == 15, "retreat after the tell avoids a locked sweep")
	scene.free()

	scene = _fixture()
	knight = scene.get_node("Survivor")
	horde = scene.get_node("Horde")
	front = horde.agents[0]
	rear = horde.agents[1]
	outside = horde.agents[2]
	var origin: Vector3 = knight.global_position
	front.global_position = origin + Vector3.FORWARD * 4
	rear.global_position = origin + Vector3.BACK * 0.5
	outside.global_position = origin + Vector3(1.2, 0, -4)
	knight._begin_attack(Survivor.Attack.CHARGE, front.global_position)
	var lane_origin: Vector3 = knight.attack_area.global_position
	knight.update_combat(horde.agents, knight.charge_windup)
	knight.update_combat(horde.agents, knight.charge_duration * 0.75)
	_check(knight.global_position.distance_to(origin) > 3, "charge moves knight along warned lane")
	_check(knight.attack_area.global_position == lane_origin, "charge warning remains fixed in world space")
	_check(front.health.current_health == 10, "charge hits a zombie it passes")
	_check(outside.health.current_health == 30 and rear.health.current_health == 30, "charge cannot hit outside its warned rectangle")
	knight.update_combat(horde.agents, knight.charge_duration * 0.25)
	_check(front.health.current_health == 10, "charge cannot repeatedly damage the same zombie")
	_check(horde.movement_bounds.has_point(Vector2(knight.position.x, knight.position.z)), "charging knight stays inside arena")
	scene.free()

	scene = _fixture()
	knight = scene.get_node("Survivor")
	horde = scene.get_node("Horde")
	front = horde.agents[0]
	rear = horde.agents[1]
	outside = horde.agents[2]
	knight.health.take_damage(ceili(knight.health.max_health / 3.0))
	_check(knight.phase == 2, "second phase starts at two-thirds health")
	knight.health.take_damage(ceili(knight.health.max_health / 3.0))
	_check(knight.phase == 3, "third phase starts at one-third health")
	front.global_position = knight.global_position + Vector3.FORWARD * 2
	rear.global_position = knight.global_position + Vector3.BACK * 2
	outside.global_position = knight.global_position + Vector3.RIGHT * 3.5
	knight._begin_attack(Survivor.Attack.SPIN, front.global_position)
	knight.update_combat(horde.agents, knight.spin_windup)
	_check(front.health.current_health == 10 and rear.health.current_health == 10, "spin hits every direction")
	_check(outside.health.current_health == 30, "spin respects displayed radius")
	front.health.take_damage(100)
	_check(horde.agents.size() == 39, "dead zombie leaves active crowd immediately")
	initial_hp = knight.health.current_health
	front.update_combat(knight, 10)
	_check(knight.health.current_health == initial_hp, "dead zombie cannot bite")
	await _frames(25)
	_check(not is_instance_valid(front), "dead zombie is freed after death feedback")
	scene.free()

	scene = _fixture()
	horde = scene.get_node("Horde")
	var site: ReinforcementSite = scene.get_node("Reinforcements/West")
	horde.command_move(site.global_position)
	site.update_recruitment(horde, 3.0)
	_check(site.remaining == 12 and site.progress == 0, "a command alone cannot recruit without a zombie reaching the site")
	horde.agents[0].global_position = site.global_position
	site.update_recruitment(horde, 1.0)
	_check(site.progress == 1.0, "occupying a reserve site charges recruitment")
	horde.agents[0].global_position += Vector3.RIGHT * 5
	site.update_recruitment(horde, 0.1)
	_check(site.progress == 0.0, "leaving interrupts recruitment")
	horde.agents[0].global_position = site.global_position
	site.update_recruitment(horde, 2.1)
	_check(horde.agents.size() == 52 and site.remaining == 0, "site adds its current batch to the horde")
	site.update_recruitment(horde, 100)
	_check(horde.agents.size() == 52, "spent site cannot recruit again in the same window")
	scene.elapsed = scene.site_interval
	scene._update_site_schedule()
	site = scene.get_node("Reinforcements/South")
	horde.command_move(site.global_position)
	horde.agents[0].global_position = site.global_position
	site.update_recruitment(horde, 2.1)
	_check(horde.agents.size() == 60 and site.remaining == 4, "horde cap preserves unused reserves")
	site.update_recruitment(horde, 100)
	_check(site.remaining == 4, "full horde cannot waste the remaining reserves")
	for index: int in range(3):
		horde.agents.back().health.take_damage(100)
	site.update_recruitment(horde, 2.1)
	_check(horde.agents.size() == 60 and site.remaining == 1, "casualties free capacity for later recruitment")
	_check(horde.recruited == 23 and horde.casualties == 3, "run statistics count recruits and losses")
	front = horde.agents[0]
	front.global_position = Vector3.ZERO
	front.move_toward_command(Vector3(10, 0, 0), [], horde.movement_bounds, 0.1, null, 1.0)
	var walking_distance: float = front.global_position.length()
	front.global_position = Vector3.ZERO
	front.move_toward_command(Vector3(10, 0, 0), [], horde.movement_bounds, 0.1, null, horde.sprint_multiplier)
	_check(front.global_position.length() > walking_distance * 1.8, "sprint changes actual movement speed")
	horde.command_sprint()
	horde._physics_process(horde.sprint_cooldown + 0.1)
	horde.command_sprint()
	_check(horde.sprint_remaining == horde.sprint_duration, "sprint becomes available again after cooldown")
	scene.free()

	# Real input/lifecycle checks with the normal main scene.
	scene = MAIN.instantiate()
	root.add_child(scene)
	current_scene = scene
	horde = scene.get_node("Horde")
	knight = scene.get_node("Survivor")
	origin = knight.position
	await _frames(30)
	_check(not scene.battle_started and knight.position == origin, "game waits for first command")
	_key(KEY_SPACE)
	_check(horde.sprint_remaining == 0, "sprint cannot start before a movement command")
	horde.command_move(Vector3(-12, 0, 10))
	_key(KEY_SPACE)
	_check(scene.battle_started and horde.sprint_remaining > 0, "first command starts run and space activates sprint")
	await _frames(10)
	var cooldown: float = horde.sprint_cooldown_remaining
	_key(KEY_SPACE)
	_check(horde.sprint_cooldown_remaining == cooldown, "sprint cannot be reset during cooldown")
	_key(KEY_ESCAPE)
	_check(paused, "escape pauses the scene tree")
	var elapsed: float = scene.elapsed
	var position_before: Vector3 = horde.agents[0].global_position
	await _frames(20)
	_check(scene.elapsed == elapsed and horde.agents[0].global_position == position_before, "pause freezes time and movement")
	_check(horde.sprint_cooldown_remaining == cooldown, "pause freezes ability cooldown")
	_key(KEY_ESCAPE)
	_check(not paused, "escape resumes")
	await _frames(90)
	_check(horde.sprint_remaining == 0 and horde.sprint_cooldown_remaining > 0, "sprint expires before it can be reused")
	knight.health.take_damage(10000)
	_check(scene.battle_over and scene.hud.result_label.text.begins_with("Victory"), "knight death ends the run in victory")
	var count: int = horde.agents.size()
	await _frames(30)
	_check(horde.agents.size() == count and not horde.commands_enabled, "outcome stops damage and movement commands")
	_key(KEY_R)
	await _frames(5)
	scene = current_scene
	horde = scene.get_node("Horde")
	knight = scene.get_node("Survivor")
	_check(not scene.battle_started and not scene.battle_over and knight.phase == 1, "restart resets the run and phases")
	_check(horde.agents.size() == 40 and horde.recruited == 0 and horde.sprint_cooldown_remaining == 0, "restart resets horde, statistics and sprint")
	_check(scene.active_site == null and scene.get_node("Reinforcements/West").remaining == 0, "restart resets sites to the waiting state")
	for agent: HordeAgent in horde.agents.duplicate():
		agent.health.take_damage(100)
	_check(scene.battle_over and scene.hud.result_label.text.begins_with("Defeat"), "zero zombies is defeat even with unused reserves")
	_key(KEY_R)
	await _frames(5)
	_key(KEY_ESCAPE)
	_key(KEY_Y, KEY_R)
	await _frames(5)
	_check(not paused and not current_scene.battle_started, "restart works from pause")
	print("Combat smoke: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)


func _fixture() -> Node3D:
	var scene: Node3D = MAIN.instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	var horde: HordeController = scene.get_node("Horde")
	horde.set_physics_process(false)
	for agent: HordeAgent in horde.agents:
		agent.global_position = Vector3(-18, 0, 12)
	return scene


func _key(code: Key, physical_code: Key = KEY_NONE) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = physical_code
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventKey
	event.pressed = false
	root.push_input(event, true)


func _frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame


func _check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		_failures += 1
