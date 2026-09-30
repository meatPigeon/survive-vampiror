extends SceneTree

const MAIN: PackedScene = preload("res://scenes/main.tscn")
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	var scene: Node3D = _fixture()
	var horde: HordeController = scene.get_node("Horde")
	var west: ReinforcementSite = scene.get_node("Reinforcements/West")
	var south: ReinforcementSite = scene.get_node("Reinforcements/South")
	var east: ReinforcementSite = scene.get_node("Reinforcements/East")
	_check(horde.permanent_count() == 40 and horde.temporary_count() == 0, "initial horde is entirely permanent")
	scene._physics_process(90.0)
	_check(scene.elapsed == 0.0 and scene.active_site == null, "schedule waits for first command")
	await _capture("ready")
	horde.command_move(west.position)
	_check(scene.active_site == west and west.remaining == 12 and not south.active, "first command opens only west")
	var permanent: HordeAgent = horde.agents[0]
	permanent.health.take_damage(13)
	permanent.position = south.position
	horde.command_move(south.position)
	south.update_recruitment(horde, 3.0)
	_check(horde.recruited == 0, "inactive site cannot recruit even when occupied")
	scene._physics_process(30.0)
	_check(scene.active_site == south and not west.active and west.remaining == 0, "unclaimed west stock is discarded at 30 seconds")
	_check(horde.temporary_count() == 12 and south.remaining == 0, "active site recruits temporary zombies")
	_check(permanent.health.current_health == 17 and horde.permanent_count() == 40, "site switch does not heal or replace permanent zombies")
	var temporary: HordeAgent = horde.agents.back()
	_check(temporary.lifetime_remaining == 45.0, "new recruits start with full lifetime")
	# Returning to an exhausted site neither replenishes it nor refreshes recruits.
	scene._physics_process(5.0)
	_check(temporary.lifetime_remaining == 40.0 and horde.recruited == 12, "lifetime runs while waiting on the recruitment site")
	temporary.health.take_damage(100)
	temporary.update_lifetime(100.0)
	_check(horde.casualties == 1 and horde.expired_count == 0 and not temporary.expired, "combat death cannot later count as expiration")
	permanent.position = Vector3(-8, 0, 3)
	horde.command_move(permanent.position)
	scene._physics_process(25.0)
	_check(scene.active_site == east and east.remaining == 12 and not south.active, "east opens at 60 seconds")
	_check(horde.next_expiration() == 15.0, "lifetimes persist across site switches")
	scene._physics_process(15.0)
	_check(horde.temporary_count() == 0 and horde.expired_count == 11 and not scene.battle_over, "all temporary zombies can expire without defeat")
	scene._physics_process(15.0)
	_check(scene.active_site == west and west.remaining == 12 and east.remaining == 0, "west returns with a fresh non-accumulated batch at 90 seconds")
	_check(permanent.health.current_health == 17 and horde.permanent_count() == 40, "permanent zombies have no lifetime or regeneration")
	# Interrupted and partial stock must also be discarded on rotation.
	west.remaining = 4
	west.progress = 1.0
	scene._physics_process(30.0)
	_check(west.remaining == 0 and west.progress == 0.0 and south.remaining == 12, "switch clears partial stock and occupation progress")
	scene._physics_process(90.0)
	_check(scene.active_site == south and south.remaining == 12, "skipping a full cycle still starts a fresh window")
	scene.free()

	scene = _fixture()
	horde = scene.get_node("Horde")
	west = scene.get_node("Reinforcements/West")
	horde.command_move(west.position)
	horde.agents[0].position = west.position
	horde.recruit(12, west.position)
	for agent: HordeAgent in horde.agents:
		if agent.kind == HordeAgent.Kind.TEMPORARY:
			agent.lifetime_remaining = 0.01
	horde.recruit(8, west.position)
	west.progress = 1.95
	scene._physics_process(0.1)
	_check(horde.expired_count == 12 and horde.agents.size() == 60 and west.remaining == 0, "expiration frees capacity before recruitment in the same tick")
	_check(is_equal_approx(horde.next_expiration(), 44.9) and horde.agents.back().lifetime_remaining == 45.0, "each recruited batch keeps an independent timer")
	horde.update_lifetimes(44.91)
	_check(horde.expired_count == 20 and horde.temporary_count() == 12 and horde.next_expiration() > 0.0, "older batch expires without removing newer recruits")
	scene.free()

	scene = _fixture()
	horde = scene.get_node("Horde")
	var knight: Survivor = scene.get_node("Survivor")
	horde.command_move(Vector3.ZERO)
	horde.recruit(12, Vector3(-2, 0, 3))
	scene._update_status()
	await _capture("mixed")
	# Expiration is resolved before bites, even if a recruit is already in range.
	for agent: HordeAgent in horde.agents:
		if agent.kind == HordeAgent.Kind.TEMPORARY:
			agent.position = knight.position + Vector3.FORWARD
			agent.lifetime_remaining = 0.01
	var knight_hp: int = knight.health.current_health
	scene._physics_process(0.02)
	_check(horde.expired_count == 12 and horde.agents.size() == 40, "simultaneous expiry removes every recruit without skipping")
	_check(knight.health.current_health == knight_hp and horde.casualties == 0, "expired recruits cannot bite and are not combat casualties")
	horde.recruit(2, Vector3.ZERO)
	for agent: HordeAgent in horde.agents.duplicate():
		if agent.kind == HordeAgent.Kind.PERMANENT and horde.permanent_count() > 1:
			agent.health.take_damage(100)
	permanent = horde.agents[0]
	permanent.position = knight.position + Vector3.FORWARD
	permanent.health.take_damage(15)
	temporary = horde.agents.back()
	for agent: HordeAgent in horde.agents:
		if agent.kind == HordeAgent.Kind.TEMPORARY:
			agent.position = permanent.position
	knight._begin_attack(Survivor.Attack.SWEEP, permanent.position)
	knight.update_combat(horde.agents, knight.windup_time)
	_check(scene.battle_over and horde.permanent_count() == 0 and horde.temporary_count() == 2, "last permanent death loses immediately with temporary survivors")
	_check(knight.state == Survivor.State.STOPPED and temporary.health.current_health == 30, "terminal death stops even the rest of the current knight hit loop")
	var lifetime: float = temporary.lifetime_remaining
	scene._physics_process(100.0)
	horde.update_lifetimes(100.0)
	_check(temporary.lifetime_remaining == lifetime and knight.health.current_health == knight_hp, "defeat stops lifetimes and temporary bites")
	_check(horde.recruit(12, Vector3.ZERO) == 0, "temporary survivors cannot recruit after defeat")
	await _capture("defeat")
	scene.free()

	# Use real physics frames to check pause and victory timer freezing.
	scene = MAIN.instantiate()
	root.add_child(scene)
	current_scene = scene
	horde = scene.get_node("Horde")
	knight = scene.get_node("Survivor")
	horde.set_physics_process(false)
	knight.stop_combat()
	horde.command_move(Vector3(-8, 0, 3))
	horde.recruit(1, Vector3(-8, 0, 3))
	temporary = horde.agents.back()
	scene.elapsed = 29.99
	lifetime = temporary.lifetime_remaining
	scene.toggle_pause()
	await _frames(20)
	_check(scene.elapsed == 29.99 and scene.active_site.name == "West" and temporary.lifetime_remaining == lifetime, "pause freezes schedule and lifetimes")
	await _capture("pause")
	scene.toggle_pause()
	await _frames(5)
	_check(scene.active_site.name == "South" and temporary.lifetime_remaining < lifetime, "resume continues both timers")
	knight.health.take_damage(knight.health.current_health)
	lifetime = temporary.lifetime_remaining
	var elapsed: float = scene.elapsed
	await _frames(20)
	_check(scene.battle_over and temporary.lifetime_remaining == lifetime and scene.elapsed == elapsed, "victory freezes lifetimes and site schedule")
	scene.restart()
	await _frames(5)
	scene = current_scene
	horde = scene.get_node("Horde")
	_check(horde.permanent_count() == 40 and horde.temporary_count() == 0 and horde.expired_count == 0 and horde.recruited == 0, "restart resets composition and statistics")
	_check(scene.elapsed == 0.0 and scene.active_site == null and not scene.battle_started, "restart resets schedule and waits for a command")
	print("Reinforcement smoke: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)


func _fixture() -> Node3D:
	var scene: Node3D = MAIN.instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.get_node("Horde").set_physics_process(false)
	scene.get_node("Survivor").stop_combat()
	return scene


func _frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame


func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/survive_reinforcement_%s.png" % label)


func _check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		_failures += 1
