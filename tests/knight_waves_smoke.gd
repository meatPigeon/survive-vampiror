extends SceneTree

var _failures: int = 0
var _pilot := preload("res://tests/support/horde_pilot.gd").new()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	var arena: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	arena.horde.set_physics_process(false)
	await _frames(3)
	var knight: Survivor = arena.survivor
	var horde: HordeController = arena.horde
	_check(arena.wave_count == 3 and knight.health.current_health == 800, "default run starts at wave one of three with configured health")
	_check(not knight.visual.crossbow.visible and not knight.visual.horse.visible, "first wave has only the halberd")
	_pilot.move(root, Vector2.RIGHT)
	_pilot.move(root, Vector2.ZERO)
	horde.recruit(2, horde.spawn_center)
	var permanent: HordeAgent = horde.agents[0]
	var temporary: HordeAgent = horde.agents.back()
	permanent.health.take_damage(7)
	horde.grant_ability(HordeAbility.Upgrade.SPRINT) # This fixture checks carryover of an existing cooldown.
	horde.command_sprint()
	var lifetime: float = temporary.lifetime_remaining
	var sprint: float = horde.sprint_cooldown_remaining
	var site_timer: float = arena.site_time_left()
	var original_speed: float = knight.move_speed
	await _capture(arena, "wave_one")
	var previous: WeakRef = weakref(knight)
	knight.health.take_damage(knight.health.current_health)
	_check(arena.between_waves and not arena.battle_over and not arena.hud.overlay.visible, "first kill enters a break rather than final victory")
	_check(not horde.commands_enabled and not horde.is_physics_processing(), "intermission disables horde movement and abilities")
	arena._physics_process(1.0)
	_check(temporary.lifetime_remaining == lifetime and horde.sprint_cooldown_remaining == sprint and arena.site_time_left() == site_timer, "intermission freezes recruit lifetimes, sprint and site countdown")
	arena.toggle_pause()
	var delay: float = arena.wave_time_left
	await _frames(10)
	_check(arena.wave_time_left == delay and paused, "pause freezes the wave countdown")
	arena.toggle_pause()
	await _capture(arena, "between_waves")
	arena.choose_reward(0)
	arena._physics_process(delay)
	await _frames(2)
	knight = arena.survivor
	horde.set_physics_process(false)
	_check(previous.get_ref() == null and arena.wave_index == 2 and not arena.between_waves, "next wave replaces the fallen knight once")
	_check(horde == arena.horde and permanent.health.current_health == 23 and horde.agents.has(temporary), "the same surviving horde and its health carry over")
	_check(knight.health.current_health == 1000 and horde.survivor == knight, "new full-health knight is the horde's live target")
	_check(knight.visual.crossbow.visible and not knight.visual.horse.visible, "wave two visibly equips a crossbow")
	_check(arena.battle_audio.music.playing and horde.commands_enabled, "music and horde controls continue on the next wave")
	# Isolate projectile geometry from horde steering and automatic bites.
	for agent: HordeAgent in horde.agents:
		agent.global_position = Vector3(-25, 0, 20)
	var first: HordeAgent = horde.agents[0]
	var second: HordeAgent = horde.agents[1]
	var origin: Vector3 = knight.global_position
	first.global_position = origin + Vector3.FORWARD * 4.0
	second.global_position = origin + Vector3.FORWARD * 7.0
	knight._crossbow_cooldown = 0.0
	knight.update_combat(horde.agents, 0.01)
	_check(knight.attack_kind == Survivor.Attack.CROSSBOW and knight.state == Survivor.State.WINDUP and not knight.bolt.flying, "crossbow is selected at range and warns before firing")
	var direction: Vector3 = knight._attack_direction
	first.global_position += Vector3.RIGHT * 2.0
	var before: int = first.health.current_health
	await _frames(8)
	knight.animation_player.play(knight.animation_player.current_animation, 0.0)
	knight.animation_player.seek(knight.crossbow_windup * 0.7, true)
	await _capture(arena, "crossbow", true)
	knight.update_combat(horde.agents, knight.crossbow_windup)
	_check(knight.bolt.flying and knight._attack_direction == direction and first.health.current_health == before, "shot locks its aim and launches without instant damage")
	var bolt_position: Vector3 = knight.bolt.global_position
	arena.set_physics_process(true)
	arena.toggle_pause()
	await _frames(10)
	_check(knight.bolt.global_position == bolt_position and knight.bolt.flying, "pause freezes a bolt in flight")
	arena.toggle_pause()
	arena.set_physics_process(false)
	knight.update_combat(horde.agents, 0.6)
	_check(first.health.current_health == before and not second.health.is_alive() and knight.bolt.flying, "moving off the line dodges; a hit kills instantly and the bolt continues")
	var casualties: int = horde.casualties
	knight.update_combat(horde.agents, 0.2)
	_check(horde.casualties == casualties and not horde.agents.has(second), "the same corpse cannot count as another kill")
	second = horde.agents[1]
	var third: HordeAgent = temporary
	var beside: HordeAgent = horde.agents[2]
	var beyond: HordeAgent = horde.agents[3]
	second.health.max_health = 120
	second.health.current_health = 120
	first.global_position = origin + Vector3.FORWARD * 4.0
	second.global_position = origin + Vector3.FORWARD * 7.0
	third.global_position = origin + Vector3.FORWARD * 11.0
	beside.global_position = origin + Vector3.FORWARD * 6.0 + Vector3.RIGHT * 1.0
	beyond.global_position = origin + Vector3.FORWARD * 18.0
	var hit_order: Array[int] = []
	first.health.died.connect(func() -> void: hit_order.append(1))
	second.health.died.connect(func() -> void: hit_order.append(2))
	third.health.died.connect(func() -> void: hit_order.append(3))
	horde.agents.reverse()
	knight.bolt.launch(origin, Vector3.FORWARD, 16.0)
	await _capture_piercing(arena, "before")
	knight.bolt.advance(horde.agents, 1.0)
	_check(not first.health.is_alive() and not second.health.is_alive() and not third.health.is_alive(), "one bolt kills multiple permanent/temporary targets, including increased HP")
	_check(hit_order == [1, 2, 3] and horde.casualties == casualties + 3, "large-tick piercing resolves front to back despite live-list removal and reversed order")
	_check(beside.health.is_alive() and beyond.health.is_alive(), "piercing spares zombies beside the line or beyond its finite range")
	_check(not knight.bolt.flying, "piercing still stops at maximum range")
	await _capture_piercing(arena, "after")
	knight.bolt.launch(origin, Vector3.FORWARD, 16.0)
	knight.bolt.advance([], 2.0)
	_check(not knight.bolt.flying and is_equal_approx(knight.bolt.global_position.distance_to(origin), 16.0), "missed bolt expires at its finite range")
	knight.bolt.launch(origin, Vector3.FORWARD, 16.0)
	knight.health.take_damage(knight.health.current_health)
	_check(not knight.bolt.flying and arena.between_waves, "knight death cancels in-flight bolts before the break")
	arena.choose_reward(0)
	arena._physics_process(arena.wave_break_duration)
	await _frames(2)
	knight = arena.survivor
	horde.set_physics_process(false)
	_check(arena.wave_index == 3 and knight.health.current_health == 1200, "third wave gains health again")
	_check(knight.visual.horse.visible and knight.visual.crossbow.visible, "mounted wave retains the crossbow")
	_check(knight.move_speed == original_speed * 2.0 and knight.charge_duration < 0.7, "mount increases pursuit and charge speed")
	await _frames(15)
	await _capture(arena, "mounted", true)
	for agent: HordeAgent in horde.agents:
		agent.global_position = knight.global_position + Vector3.FORWARD * 25.0
	origin = knight.global_position
	knight.update_combat(horde.agents, 0.2)
	_check(knight.global_position.distance_to(origin) > 0.5 and knight.visual.horse.moving, "mounted speed and gallop affect real pursuit")
	knight.health.take_damage(knight.health.current_health)
	_check(arena.battle_over and not arena.between_waves and arena.hud.result_label.text == "Victory", "only the third kill ends the run in victory")
	arena._physics_process(10.0)
	_check(arena.wave_index == 3 and not horde.commands_enabled, "final victory cannot open a fourth wave")
	await _capture(arena, "victory")
	arena.restart()
	await _frames(5)
	arena = current_scene
	_check(arena.wave_index == 1 and not arena.between_waves and not arena.battle_started and not arena.survivor.visual.crossbow.visible, "restart resets waves, equipment and start gating")
	_pilot.move(root, Vector2.RIGHT)
	_pilot.move(root, Vector2.ZERO)
	arena.survivor.health.take_damage(arena.survivor.health.current_health)
	for agent: HordeAgent in arena.horde.agents.duplicate():
		agent.health.take_damage(100)
	await _frames(10)
	_check(arena.battle_over and arena.hud.result_label.text == "Defeat" and arena.wave_index == 1, "permanent wipe during a break cancels progression")
	arena.restart()
	await _frames(5)
	arena = current_scene
	_pilot.move(root, Vector2.RIGHT)
	_pilot.move(root, Vector2.ZERO)
	arena.survivor.health.take_damage(arena.survivor.health.current_health)
	arena.toggle_pause()
	arena.restart()
	await _frames(5)
	_check(not paused and not current_scene.between_waves and current_scene.wave_index == 1, "restart from a paused intermission clears its timer")
	# A front permanent wipe must stop piercing before a farther temporary target.
	arena = current_scene
	arena.set_physics_process(false)
	arena.horde.set_physics_process(false)
	horde = arena.horde
	first = horde.agents[0]
	for agent: HordeAgent in horde.agents.duplicate():
		if agent != first:
			agent.health.take_damage(agent.health.current_health)
	horde.recruit(1, Vector3.ZERO)
	second = horde.agents.back()
	knight = arena.survivor
	origin = knight.global_position
	first.global_position = origin + Vector3.FORWARD * 3.0
	second.global_position = origin + Vector3.FORWARD * 6.0
	knight.bolt.launch(origin, Vector3.FORWARD, 16.0)
	knight.bolt.advance([second, first], 1.0)
	_check(arena.battle_over and not knight.bolt.flying and second.health.is_alive(), "last-permanent defeat cancels the bolt before farther targets even in the same tick")
	current_scene.battle_audio.stop_all()
	current_scene.queue_free()
	await _frames(10)
	print("Knight waves smoke: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)


func _frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame


func _capture_piercing(arena: Node3D, label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	var camera: Camera3D = arena.get_node("Camera")
	var previous: Transform3D = camera.transform
	var size: float = camera.size
	camera.set_process(false)
	var center: Vector3 = arena.survivor.position + Vector3.FORWARD * 7.0
	camera.position = center + Vector3(5, 10, 8)
	camera.look_at(center)
	camera.size = 15.0
	await _frames(5)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/survive_piercing_%s.png" % label)
	camera.transform = previous
	camera.size = size
	camera.set_process(true)


func _capture(arena: Node3D, label: String, close: bool = false) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	arena._update_status()
	var camera: Camera3D = arena.get_node("Camera")
	var previous: Transform3D = camera.transform
	var size: float = camera.size
	camera.set_process(false)
	if close:
		camera.position = arena.survivor.position + Vector3(4, 3.5, 5)
		camera.look_at(arena.survivor.position + Vector3.UP)
		camera.size = 5.5
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/survive_waves_%s.png" % label)
	camera.transform = previous
	camera.size = size
	camera.set_process(true)


func _check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		_failures += 1
