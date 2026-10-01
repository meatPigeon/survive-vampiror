extends SceneTree

var _failures: int = 0
var _pilot := preload("res://tests/support/horde_pilot.gd").new()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	var scene: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene._site_random.seed = 29
	await physics_frame
	# Isolate recruitment; movement, input, capacity, lifetimes and visuals run normally.
	scene.survivor.stop_combat()
	var horde: HordeController = scene.horde
	var first: ReinforcementSite = scene.get_node("Reinforcements/West")
	await _visit(horde, first.global_position, 12)
	_check(horde.recruited == 12 and horde.agents.size() == 52, "first WASD-driven visit summons a batch of twelve")
	_check(not first.active and first.remaining == 0 and not first.visual.indicator.visible, "successful visit immediately closes its ring and stock")
	_check(scene.active_site == null and scene.site_time_left() > 4.9, "successful visit starts the configured cooldown with no active site")
	await _capture(scene, "first_closed")
	scene.toggle_pause()
	var cooldown: float = scene.site_time_left()
	await _frames(60)
	_check(scene.active_site == null and scene.site_time_left() == cooldown, "pause freezes the delay between sites")
	scene.toggle_pause()
	await _wait_for_site(scene)
	var second: ReinforcementSite = scene.active_site
	_check(second != first and second.active and second.remaining == 12, "cooldown opens a random different site")
	_check(scene.site_time_left() > 29.0, "new site gets a full independent window")
	await _frames(55)
	await _capture(scene, "next_open")
	await _frames(180)
	_check(horde.recruited == 12, "waiting at the used site cannot summon again")
	await _visit(horde, second.global_position, 20)
	_check(horde.agents.size() == 60 and horde.recruited == 20, "second visit adds only eight at the sixty-zombie cap")
	_check(not second.active and second.remaining == 0 and not second.visual.indicator.visible, "partial batch also closes the site without four leftover recruits")
	_check(scene.active_site == null, "partial batch also starts the gap between sites")
	await _capture(scene, "partial_closed")
	horde.agents.back().health.take_damage(100)
	await _frames(180)
	_check(horde.agents.size() == 59 and horde.recruited == 20, "losing a zombie cannot refill it from the used site")
	_check(second.progress == 0.0 and not second.visual.indicator.visible, "used ring stays gone after capacity becomes available")
	await _wait_for_site(scene)
	var third: ReinforcementSite = scene.active_site
	_check(third != second and third.remaining == 12, "partial-batch cooldown opens a different fresh site")
	await _visit(horde, third.global_position, 21)
	_check(horde.agents.size() == 60 and horde.recruited == 21, "the next location supplies the single free slot after travelling there")
	_check(not third.active and third.remaining == 0, "even a one-zombie summon consumes its activation")
	await _capture(scene, "one_slot_closed")
	scene.wave_count = scene.wave_index # This scenario checks the final outcome.
	scene.survivor.health.take_damage(scene.survivor.health.current_health)
	cooldown = scene.site_time_left()
	await _frames(ceili(scene.site_respawn_delay * 60.0) + 5)
	_check(scene.battle_over and scene.active_site == null and scene.site_time_left() == cooldown, "outcome freezes a pending respawn instead of opening another site")
	scene.restart()
	await _frames(5)
	_check(current_scene.active_site == null and current_scene.site_time_left() == 0.0 and not current_scene.battle_started, "restart resets the pending cooldown and waits for input")
	scene = current_scene
	scene.free()
	await process_frame
	print("Recruitment flow: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)


func _visit(horde: HordeController, point: Vector3, target: int) -> void:
	for frame: int in range(1200):
		_pilot.steer(root, horde, point)
		await physics_frame
		if horde.recruited >= target:
			_pilot.move(root, Vector2.ZERO)
			return
	_check(false, "WASD-driven horde reaches and completes the next summon")


func _wait_for_site(scene: Node3D) -> void:
	for frame: int in range(ceili(scene.site_respawn_delay * 60.0) + 5):
		await physics_frame
		if scene.active_site != null:
			return
	_check(false, "a new site opens when the configured delay ends")


func _frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame


func _capture(scene: Node3D, label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	# Show the ordinary HUD while the isolated fixture's knight is stopped.
	scene.set_physics_process(false)
	scene.survivor.state = Survivor.State.HUNT
	scene._update_status()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/survive_recruitment_flow_%s.png" % label)
	scene.survivor.state = Survivor.State.STOPPED
	scene.set_physics_process(true)


func _check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		_failures += 1
