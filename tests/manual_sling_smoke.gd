extends SceneTree

var _failures: int = 0
var _arena: Node3D
var _sling: HordeAbility


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	_arena = load("res://scenes/main.tscn").instantiate()
	root.add_child(_arena)
	current_scene = _arena
	_arena.set_physics_process(false)
	_arena.horde.set_physics_process(false)
	_arena.horde.grant_ability(HordeAbility.Upgrade.SLING)
	_arena.horde.grant_ability(HordeAbility.Upgrade.FEAST)
	_sling = _arena.horde.ability
	await _frames(3)
	_key(KEY_Q)
	_check(not _sling.aiming and not _arena.battle_started, "aim cannot start the run")
	_key(KEY_W)
	_key(KEY_Q)
	_check(not _sling.aiming and _sling.cooldown_remaining == 0.0, "no recruit means no aiming or cost")
	_arena.horde.recruit(1, Vector3(-5, 0, 0))
	_move_ground(_arena.survivor.global_position)
	_key(KEY_Q)
	_check(_sling.aiming and _sling.aim_valid and _sling.projectile == null and _sling.cooldown_remaining == 0.0, "Q opens manual aim without firing or spending ammo")
	_check(_sling._aim_preview.visible and _sling._aim_ring.visible, "scatter disk and outline are visible")
	await _capture("aim")
	_key(KEY_E)
	_check(_arena.horde.abilities[1].feast_remaining > 0.0 and _sling.aiming, "the other ability remains usable while aiming")
	_arena.horde.command_direction(Vector3.RIGHT)
	var previous: Vector3 = _arena.horde.agents[0].global_position
	_arena.horde._physics_process(0.2)
	_arena.horde.command_direction(Vector3.ZERO)
	_check(_arena.horde.agents[0].global_position != previous and _sling.aiming, "horde movement remains independent of manual aim")

	_move_ground(Vector3(23, 0, -8))
	_check(not _sling.aim_valid and _sling._aim_ring.material_override.albedo_color.r > 0.8, "out-of-range aim is visibly invalid")
	_click()
	_check(_sling.aiming and _sling.projectile == null and _sling.cooldown_remaining == 0.0, "invalid range does not spend a zombie or cooldown")
	await _capture("range")
	_move_ground(Vector3(29, 0, 0))
	_check(not _sling.aim_valid, "scatter circle cannot extend beyond the arena")
	_move_screen(Vector2(-50, -50))
	_check(not _sling.aim_valid and not _sling._aim_preview.visible, "pointer outside the viewport hides aim and cannot fire")
	_move_ground(Vector3.ZERO)
	_click(MOUSE_BUTTON_RIGHT)
	_check(not _sling.aiming and not _sling._aim_preview.visible and _arena.horde.temporary_count() == 1, "right-click cancels without spending ammo")
	_key(KEY_Q)
	_key(KEY_Q)
	_check(not _sling.aiming, "pressing the ability key again cancels aim")
	_key(KEY_Q)
	_arena.get_window().focus_exited.emit()
	_check(not _sling.aiming, "focus loss cancels pending aim")
	_key(KEY_Q)
	_key(KEY_ESCAPE)
	_click()
	_check(paused and not _sling.aiming and _sling.projectile == null, "pause cancels aim and blocks firing")
	_key(KEY_ESCAPE)
	_check(not _sling.aiming, "resume does not restore a stale shot")
	_arena._update_status()
	await _frames(3)

	# A HUD click begins aiming without also firing through the button.
	var button: Button = _arena.hud.get_node("%AbilityButton")
	_move_screen(button.get_global_transform_with_canvas() * (button.size * 0.5))
	_click()
	_check(_sling.aiming and _sling.projectile == null, "HUD activation does not leak a shot to the ground")
	var target := Vector3(0, 0, -7)
	_move_ground(target)
	_check(_sling.aim_valid and _sling.aim_position.distance_to(target) < 0.01, "mouse projection aims at the chosen ground point")
	_arena.zoom_camera(2)
	await _frames(25)
	_check(_sling.aim_position.distance_to(target) > 0.2, "reticle follows the ground under a stationary cursor while zooming")
	root.size = Vector2i(960, 600)
	await _frames(3)
	_move_ground(target)
	_check(_sling.aim_position.distance_to(target) < 0.01, "aim still projects correctly after zoom and resize")
	await _capture("small")
	_sling._sling_random.seed = 781
	var before: int = _arena.survivor.health.current_health
	_click()
	_check(_sling.projectile != null and not _sling.aiming and not _sling._aim_preview.visible, "left-click launches exactly one recruit and hides manual aim")
	_check(_sling._landing.distance_to(target) <= _sling.sling_spread and _sling._launch_origin.distance_to(_sling._landing) <= _sling.sling_range, "sampled landing stays inside the indicated disk and launch range")
	var landing: Vector3 = _sling._landing
	_move_ground(_arena.survivor.global_position)
	_click()
	_key(KEY_Q)
	_check(_sling._landing == landing and not _sling.aiming, "moving/clicking the cursor after firing cannot steer or refire")
	_sling.tick(0.4)
	await _capture("flight")
	_sling.tick(0.4)
	_check(_arena.survivor.health.current_health == before and _arena.horde.temporary_count() == 0, "aiming away from the knight misses and spends only the temporary zombie")

	# Exercise actual random landings and damage against a stationary target.
	# High fixture HP isolates scatter from wave transitions; no balance claim.
	_arena.survivor.health.max_health = 100000
	_arena.survivor.health.current_health = 100000
	var hits: int = 0
	var outer: int = 0
	var first_landing := Vector3.INF
	var varied: bool = false
	for shot: int in range(32):
		_sling.tick(3.0)
		_arena.horde.recruit(1, Vector3(-5, 0, 0))
		target = _arena.survivor.global_position
		_move_ground(target)
		_key(KEY_Q)
		_click()
		var distance: float = _sling._landing.distance_to(target)
		_check(distance <= _sling.sling_spread + 0.001, "every random landing lies inside the displayed scatter")
		if distance > _sling.sling_spread * 0.7:
			outer += 1
		if shot == 0:
			first_landing = _sling._landing
		else:
			varied = varied or _sling._landing.distance_to(first_landing) > 0.1
		before = _arena.survivor.health.current_health
		_sling.tick(0.8)
		var damage: int = before - _arena.survivor.health.current_health
		_check(damage == (_sling.impact_damage if distance <= _sling.impact_radius else 0), "damage uses actual landing distance, not an independent hit roll")
		if damage > 0:
			hits += 1
		await _frames(1)
	_check(varied and outer > 0 and hits > 0 and hits < 32, "scatter produces distinct landings, both hits and misses even with centered aim")
	print("Manual sling scatter: %d hits / 32 centered shots" % hits)

	_sling.tick(3.0)
	_arena.horde.recruit(1, Vector3(-5, 0, 0))
	_key(KEY_Q)
	_arena.horde.agents.back().lifetime_remaining = 0.01
	_arena.horde.update_lifetimes(0.02)
	_sling.tick(0.02)
	_check(not _sling.aiming and _sling.cooldown_remaining == 0.0, "losing the last ammo while aiming cancels without cooldown")
	_arena.horde.recruit(1, Vector3(-5, 0, 0))
	_key(KEY_Q)
	# Restore a legal one-skill intermission after the two-skill input fixture.
	_arena.horde.abilities[1].cancel()
	_arena.horde.abilities[1].upgrade = HordeAbility.Upgrade.NONE
	_arena.survivor.health.take_damage(100000)
	_check(_arena.awaiting_reward and not _sling.aiming and not _sling._aim_preview.visible, "round transition clears manual aim")
	_arena.restart()
	await _frames(4)
	_arena = current_scene
	_check(not _arena.horde.ability.aiming and _arena.horde.ability._aim_preview == null, "restart clears reticle state")
	_arena.battle_audio.stop_all()
	_arena.queue_free()
	await _frames(12)
	print("Manual sling smoke: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)


func _key(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventKey
	event.pressed = false
	root.push_input(event, true)


func _move_ground(position: Vector3) -> void:
	_move_screen(_arena.get_node("Camera").unproject_position(position))


func _move_screen(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	root.push_input(event, true)
	_arena.horde_input.refresh_aim()


func _click(button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.position = _arena.horde_input._pointer_position
	event.button_index = button
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventMouseButton
	event.pressed = false
	root.push_input(event, true)


func _frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame


func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await _frames(2)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/survive_sling_%s.png" % label)


func _check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		_failures += 1
