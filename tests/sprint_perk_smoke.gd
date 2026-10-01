extends SceneTree

var _failures: int = 0
var _arena: Node3D
var _sprints: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	_arena = load("res://scenes/main.tscn").instantiate()
	root.add_child(_arena)
	current_scene = _arena
	_arena.set_physics_process(false)
	_arena.horde.set_physics_process(false)
	var horde: HordeController = _arena.horde
	horde.sprint_started.connect(func() -> void: _sprints += 1)
	_key(KEY_SPACE)
	_check(not horde.sprint_unlocked and horde.sprint_remaining == 0.0 and not _arena.battle_started, "fresh run has no sprint and Space cannot start it")
	_key(KEY_D)
	_key(KEY_SPACE)
	horde.command_sprint()
	_arena._update_status()
	_check(_arena.battle_started and horde.sprint_remaining == 0.0 and _sprints == 0, "movement, Space and direct calls cannot bypass the locked perk")
	_check(not _arena.hud.get_node("%Sprint").visible and _arena.hud.sprint_button.disabled, "locked sprint is absent from the HUD")
	_arena.toggle_pause()
	_check(not _arena.hud.result_stats.text.contains("Space"), "pause does not advertise an unowned action")
	_arena.toggle_pause()
	await _capture("locked")
	# Replay a known draw through the real death/reward path, without substituting cards.
	var selected_seed: int = 0
	for candidate: int in range(100):
		seed(candidate)
		if HordeAbility.Upgrade.SPRINT in horde.roll_rewards():
			selected_seed = candidate
			break
	seed(selected_seed)
	_arena.survivor.health.take_damage(10000)
	var choice: int = _arena.offered_rewards.find(HordeAbility.Upgrade.SPRINT)
	_check(choice >= 0 and _arena.awaiting_reward, "Sprint appears in the actual between-wave reward pool")
	var card: Button = _arena.hud.upgrades.cards.get_child(choice)
	_check(card.get_node("Content/Title").text == "Sprint" and card.get_node("Content/Description").text.begins_with("Space "), "sprint card describes the Space binding")
	await _capture("card")
	await _click(card)
	await _click(_arena.hud.upgrades.get_node("%StartButton"))
	_check(horde.sprint_unlocked and not _arena.awaiting_reward and _arena.between_waves, "confirming the card unlocks sprint and starts the countdown")
	_check(horde.ability.upgrade == HordeAbility.Upgrade.NONE and horde.abilities[1].upgrade == HordeAbility.Upgrade.NONE, "sprint leaves Q and E slots free")
	_check(not horde.grant_ability(HordeAbility.Upgrade.SPRINT), "sprint cannot be granted twice")
	for draw: int in range(20):
		_check(HordeAbility.Upgrade.SPRINT not in horde.roll_rewards(), "owned sprint is excluded from later draws")
	_key(KEY_SPACE)
	_check(_sprints == 0, "a selected perk cannot sprint during intermission")
	_arena._physics_process(_arena.wave_break_duration)
	horde.set_physics_process(false)
	_arena._update_status()
	_check(_arena.wave_index == 2 and _arena.hud.get_node("%Sprint").visible and not _arena.hud.sprint_button.disabled, "wave two reveals the acquired sprint control")
	_key(KEY_SPACE)
	_check(_sprints == 1 and horde.sprint_remaining == horde.sprint_duration and horde.sprint_cooldown_remaining == horde.sprint_cooldown, "Space activates the original duration and cooldown")
	_key(KEY_SPACE)
	_check(_sprints == 1, "cooldown rejects another Space press")
	_arena.toggle_pause()
	_check(_arena.hud.result_stats.text.contains("Space"), "pause advertises sprint after acquisition")
	var cooldown: float = horde.sprint_cooldown_remaining
	_key(KEY_SPACE)
	horde.command_sprint()
	await _frames(8)
	_check(_sprints == 1 and horde.sprint_cooldown_remaining == cooldown, "pause freezes and blocks sprint")
	_arena.toggle_pause()
	horde._physics_process(horde.sprint_cooldown + 0.1)
	_arena._update_status()
	await _click(_arena.hud.sprint_button)
	_check(_sprints == 2 and horde.sprint_remaining > 0.0, "HUD activates the same perk after cooldown")
	await _capture("unlocked")
	_arena.survivor.health.take_damage(10000)
	_check(HordeAbility.Upgrade.SPRINT not in _arena.offered_rewards, "second wave reward cannot offer sprint again")
	_arena.choose_reward(0)
	_check(horde.ability.upgrade != HordeAbility.Upgrade.NONE and horde.abilities[1].upgrade == HordeAbility.Upgrade.NONE, "a later active skill takes Q after sprint was chosen first")
	_arena._physics_process(_arena.wave_break_duration)
	horde.set_physics_process(false)
	_check(horde.sprint_unlocked and _arena.wave_index == 3, "sprint ownership survives later waves and another perk")
	_arena.restart()
	await _frames(4)
	_arena = current_scene
	_check(not _arena.horde.sprint_unlocked and not _arena.hud.get_node("%Sprint").visible, "restart removes sprint ownership and its control")
	_key(KEY_D)
	_key(KEY_SPACE)
	_check(_arena.horde.sprint_remaining == 0.0, "new run Space is locked again")
	_arena.set_physics_process(false)
	_arena.horde.set_physics_process(false)
	_arena.survivor.health.take_damage(10000)
	_arena.skip_reward()
	_check(not _arena.horde.sprint_unlocked and _arena.horde.permanent_count() == 50, "skipping grants zombies without a free sprint perk")
	_arena.battle_audio.stop_all()
	_arena.queue_free()
	await _frames(10)
	print("Sprint perk smoke: ", "PASS" if _failures == 0 else "FAIL")
	quit(0 if _failures == 0 else 1)


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventKey
	event.pressed = false
	root.push_input(event, true)


func _click(control: Control) -> void:
	var event := InputEventMouseButton.new()
	event.position = control.get_global_transform_with_canvas() * (control.size * 0.5)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventMouseButton
	event.pressed = false
	root.push_input(event, true)
	await _frames(2)


func _frames(count: int) -> void:
	for frame: int in range(count):
		await process_frame


func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	_arena._update_status()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/survive_sprint_perk_%s.png" % label)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failures += 1
