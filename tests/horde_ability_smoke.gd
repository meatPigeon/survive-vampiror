extends SceneTree

var _failures: int = 0
var _arena: Node3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	await _fixture(HordeAbility.Upgrade.DETONATION)
	var horde: HordeController = _arena.horde
	var ability: HordeAbility = horde.ability
	_key(KEY_Q)
	_check(ability.armed.is_empty() and not _arena.battle_started, "ability cannot start the run")
	_start()
	horde.recruit(2, Vector3(-6, 0, 0))
	_key(KEY_Q)
	_check(ability.armed.size() == 4 and ability.armed.back().kind == HordeAgent.Kind.TEMPORARY, "mines select half the mixed horde, including permanent zombies")
	var bomb: HordeAgent = ability.armed[0]
	bomb.position = _arena.survivor.position + Vector3.LEFT
	var original_position: Vector3 = bomb.position
	var mobile: HordeAgent = horde.agents[1]
	var mobile_position: Vector3 = mobile.position
	horde.command_direction(Vector3.RIGHT)
	horde._physics_process(0.3)
	horde.command_direction(Vector3.ZERO)
	_check(bomb.position == original_position and mobile.position.distance_to(mobile_position) > 0.1, "planted half stays behind while the rest moves")
	_key(KEY_Q)
	_check(ability.armed.size() == 4, "repeated activation is blocked during cooldown")
	var before: int = _arena.survivor.health.current_health
	bomb.update_combat(_arena.survivor, 2.0)
	_check(_arena.survivor.health.current_health == before, "armed zombies cannot also bite")
	ability.tick(1.0)
	await _capture("mines_armed")
	_arena.toggle_pause()
	ability.tick(10.0)
	_key(KEY_Q)
	_check(ability.fuse_remaining == 1.0 and horde.agents.size() == 8, "pause freezes fuse and rejects Q")
	_arena.toggle_pause()
	# A zombie killed before its fuse expires must not explode later.
	ability.armed.back().position = _arena.survivor.position + Vector3.RIGHT
	ability.armed.back().health.take_damage(100)
	_check(ability.armed.size() == 3, "early death removes a pending mine")
	var expected_damage: int = 0
	for agent: HordeAgent in ability.armed:
		if agent.position.distance_to(_arena.survivor.position) <= ability.blast_radius:
			expected_damage += ability.blast_damage
	ability.tick(1.0)
	_check(horde.agents.size() == 4 and horde.casualties == 4, "mine sacrifices count once and leave the other half alive")
	for agent: HordeAgent in horde.agents:
		_check(agent.health.current_health == agent.health.max_health, "blast does not damage the retreating half")
	_check(_arena.survivor.health.current_health == before - expected_damage and expected_damage > 0, "only blasts in radius damage the knight")
	await _capture("mines_blast")
	_arena.restart()
	await _frames(4)
	_arena = current_scene
	_check(_arena.horde.ability.upgrade == HordeAbility.Upgrade.NONE and _arena.horde.ability.armed.is_empty() and _arena.horde.ability.cooldown_remaining == 0.0, "restart resets the run's upgrades and ability state")
	await _dispose()

	await _fixture(HordeAbility.Upgrade.SLING)
	_start()
	horde = _arena.horde
	ability = horde.ability
	ability.sling_spread = 0.0 # Isolate existing damage/expiry assertions; manual_sling_smoke checks scatter.
	_key(KEY_Q)
	_click_ground(_arena.survivor.global_position)
	_check(not is_instance_valid(ability.projectile) and ability.cooldown_remaining == 0.0, "no temporary ammo means no shot or cooldown")
	horde.recruit(2, Vector3(-4, 0, 0))
	var permanent: int = horde.permanent_count()
	_key(KEY_Q)
	_click_ground(_arena.survivor.global_position)
	_check(is_instance_valid(ability.projectile) and ability.projectile.kind == HordeAgent.Kind.TEMPORARY, "sling launches only a temporary zombie")
	before = _arena.survivor.health.current_health
	for step: int in range(24):
		ability.tick(1.0 / 60.0)
		await _frames(1)
	_check(ability.projectile.visual.position.y > 3.0 and ability.projectile.position.y == 0.0, "flight has a visible arc and a planar gameplay root")
	await _capture("sling_flight")
	_arena.toggle_pause()
	var flight_time: float = ability.flight_elapsed
	ability.tick(1.0)
	_check(ability.flight_elapsed == flight_time, "pause freezes flight")
	_arena.toggle_pause()
	_arena.survivor.position += Vector3.RIGHT * 5.0
	ability.tick(0.5)
	_check(_arena.survivor.health.current_health == before and horde.temporary_count() == 1, "a moving knight can dodge; a missed shot still spends its zombie")
	ability.tick(3.0)
	_key(KEY_Q)
	_click_ground(_arena.survivor.global_position)
	ability.tick(0.8)
	_check(_arena.survivor.health.current_health == before - ability.impact_damage and horde.temporary_count() == 0 and horde.permanent_count() == permanent, "landing hits once, consumes ammo and preserves permanent zombies")
	await _capture("sling_impact")
	ability.tick(3.0)
	horde.recruit(1, Vector3(-4, 0, 0))
	_key(KEY_Q)
	_click_ground(_arena.survivor.global_position)
	ability.projectile.lifetime_remaining = 0.01
	horde.update_lifetimes(0.02)
	ability.tick(1.0)
	_check(not is_instance_valid(ability.projectile) and horde.expired_count == 1 and _arena.survivor.health.current_health == before - ability.impact_damage, "ammo expiring mid-flight cancels impact and counts as expiry")
	await _dispose()

	await _fixture(HordeAbility.Upgrade.FEAST)
	_start()
	horde = _arena.horde
	ability = horde.ability
	var eater: HordeAgent = horde.agents[0]
	eater.position = _arena.survivor.position + Vector3.LEFT
	eater.health.take_damage(10)
	_press_ability_button()
	before = _arena.survivor.health.current_health
	eater.update_combat(_arena.survivor, 0.0)
	eater.update_combat(_arena.survivor, 0.41)
	_check(eater.health.current_health == 24 and _arena.survivor.health.current_health == before - eater.bite_damage * 2, "feast doubles bite cadence and heals the biting zombie")
	horde.recruit(1, Vector3(-4, 0, 0))
	ability.tick(0.1)
	_check(horde.agents.back().feasting, "new recruits join the active feast")
	await _capture("feast")
	ability.tick(5.0)
	_check(not eater.feasting and not horde.agents.back().feasting, "feast expires for starters and recruits")
	before = eater.health.current_health
	eater.update_combat(_arena.survivor, 1.0)
	_check(eater.health.current_health == before, "ordinary bites do not heal after feast")
	eater.health.heal(100)
	_check(eater.health.current_health == eater.health.max_health, "healing is capped")
	eater.health.take_damage(100)
	eater.health.heal(100)
	_check(not eater.health.is_alive(), "healing cannot resurrect")
	await _dispose()

	await _fixture(HordeAbility.Upgrade.DETONATION)
	_start()
	horde = _arena.horde
	ability = horde.ability
	_key(KEY_Q)
	var fuse: float = ability.fuse_remaining
	_arena.survivor.health.take_damage(10000)
	ability.tick(5.0)
	_check(_arena.between_waves and ability.fuse_remaining == fuse, "intermission freezes pending abilities")
	_arena.choose_reward(0)
	_arena._physics_process(_arena.wave_break_duration)
	_arena.horde.set_physics_process(false)
	_check(horde.ability.upgrade == HordeAbility.Upgrade.DETONATION and horde.survivor == _arena.survivor, "upgrade persists and targets the next knight")
	ability.tick(0.5)
	_check(ability.fuse_remaining < fuse, "pending fuse resumes after intermission")
	await _dispose()

	await _fixture(HordeAbility.Upgrade.DETONATION, 2)
	_start()
	horde = _arena.horde
	ability = horde.ability
	horde.agents[0].position = _arena.survivor.position + Vector3.LEFT
	_key(KEY_Q)
	horde.agents[1].health.take_damage(100)
	_arena.survivor.health.current_health = 1
	ability.tick(2.0)
	_check(_arena.battle_over and _arena.hud.result_label.text == "Defeat" and _arena.survivor.health.current_health == 1, "last permanent sacrifice loses even if the pending blast would kill the knight")
	_check(ability.armed.is_empty(), "outcome cancels pending ability state")
	await _dispose()

	# Exercise the real Arena tick, rather than only isolated mechanic calls.
	await _fixture(HordeAbility.Upgrade.DETONATION, 40)
	_start()
	_arena.survivor.stop_combat()
	_key(KEY_Q)
	_arena.set_physics_process(true)
	await _frames(140)
	_check(_arena.horde.agents.size() == 20 and _arena.horde.ability.armed.is_empty(), "ordinary gameplay ticks resolve a 40-zombie fuse after Q")
	await _dispose()
	print("Horde ability smoke: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)


func _fixture(upgrade: HordeAbility.Upgrade, count: int = 6) -> void:
	_arena = load("res://scenes/main.tscn").instantiate()
	_arena.get_node("Horde/Ability").upgrade = upgrade
	_arena.get_node("Horde").agent_count = count
	root.add_child(_arena)
	current_scene = _arena
	_arena.set_physics_process(false)
	_arena.horde.set_physics_process(false)
	await _frames(3)


func _start() -> void:
	_key(KEY_W)
	_arena.horde.command_direction(Vector3.ZERO)


func _key(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventKey
	event.pressed = false
	root.push_input(event, true)


func _dispose() -> void:
	_arena.battle_audio.stop_all()
	_arena.queue_free()
	await _frames(12)


func _click_ground(position: Vector3) -> void:
	var event := InputEventMouseButton.new()
	event.position = _arena.get_node("Camera").unproject_position(position)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventMouseButton
	event.pressed = false
	root.push_input(event, true)


func _press_ability_button() -> void:
	var button: Button = _arena.hud.get_node("%AbilityButton")
	var event := InputEventMouseButton.new()
	event.position = button.get_global_transform_with_canvas() * (button.size * 0.5)
	event.button_index = MOUSE_BUTTON_LEFT
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
	_arena._update_status()
	var camera: Camera3D = _arena.get_node("Camera")
	camera.set_process(false)
	camera.size = 25.0
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/survive_ability_%s.png" % label)


func _check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		_failures += 1
