extends SceneTree

const KNIGHT: PackedScene = preload("res://scenes/components/survivor.tscn")
const ZOMBIE: PackedScene = preload("res://scenes/components/horde_agent.tscn")

var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for normal: bool in [false, true]:
		for kind: Survivor.Attack in Survivor.Attack.values():
			_check_attack(normal, kind)
	var menu: MainMenu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await _frames(4)
	root.size = Vector2i(1280, 800)
	await _frames(4)
	_check(not menu.normal_mode and menu.get_node("%NewbieButton").button_pressed, "fresh menu defaults to current Newbie balance")
	await _capture("newbie")
	await _click(menu.get_node("%NormalButton"))
	_check(menu.normal_mode and not menu.get_node("%NewbieButton").button_pressed and menu.get_node("%NormalButton").button_pressed, "mouse switches exclusively to Normal")
	_check(menu.get_node("%ModeHint").text == "Every knight hit kills a zombie.", "Normal explains its lethal rule before starting")
	await _capture("normal")
	await _click(menu.get_node("%NormalButton"))
	_check(menu.normal_mode and menu.get_node("%NormalButton").button_pressed, "clicking the active mode cannot leave no selection")
	menu.get_node("%NewbieButton").grab_focus()
	_key(KEY_ENTER)
	await _frames(3)
	_check(not menu.normal_mode and menu.get_node("%NewbieButton").button_pressed, "keyboard can select Newbie")
	menu.get_node("%NormalButton").grab_focus()
	_key(KEY_ENTER)
	await _frames(3)
	_check(menu.normal_mode, "keyboard can select Normal")
	root.size = Vector2i(960, 600)
	await _frames(4)
	await _click(menu.get_node("%SettingsButton"))
	for node: String in ["%NewbieButton", "%NormalButton", "%ModeHint", "%PlayButton", "%AudioControls", "Margin/Center/Content/Title"]:
		var control: Control = menu.get_node(node)
		_check(root.get_visible_rect().encloses(control.get_global_rect()), "small menu fits %s" % node)
	await _capture("normal_small_audio")
	await _click(menu.get_node("%PlayButton"))
	var arena: Node3D = current_scene
	_check(arena.normal_mode and arena.survivor.lethal_attacks and not arena.battle_started, "Play transfers Normal before the battle starts")
	_check(arena.hud.phase.text.begins_with("Normal"), "HUD identifies the active mode")
	await _capture("normal_battle")
	arena.set_physics_process(false)
	arena.horde.set_physics_process(false)
	for expected_wave: int in [2, 3]:
		arena.survivor.health.take_damage(arena.survivor.health.current_health)
		arena.skip_reward()
		arena._start_next_wave()
		arena.horde.set_physics_process(false)
		_check(arena.wave_index == expected_wave and arena.survivor.lethal_attacks, "Normal applies to the new knight on wave %d" % expected_wave)
		await _frames(2)
	arena.toggle_pause()
	_key(KEY_R)
	await _frames(4)
	arena = current_scene
	_check(not paused and arena.normal_mode and arena.survivor.lethal_attacks, "keyboard restart from pause retains Normal")
	_check(arena.wave_index == 1 and arena.horde.permanent_count() == 40 and not arena.battle_started, "restart still resets progression and rewards")
	# A lethal area hit removes targets synchronously; the permanent wipe must stop it.
	arena.set_physics_process(false)
	arena.horde.set_physics_process(false)
	arena.horde.recruit(1, arena.horde.spawn_center)
	var temporary: HordeAgent = arena.horde.agents.back()
	for agent: HordeAgent in arena.horde.agents:
		agent.global_position = arena.survivor.global_position + Vector3.FORWARD
	arena.survivor._begin_attack(Survivor.Attack.SWEEP, temporary.global_position)
	arena.survivor.update_combat(arena.horde.agents, arena.survivor.current_windup())
	_check(arena.battle_over and arena.horde.permanent_count() == 0 and arena.survivor.state == Survivor.State.STOPPED, "Normal wipe resolves defeat without skipping targets or runtime errors")
	_check(temporary.health.is_alive(), "defeat stops further hits immediately, including surviving temporary targets")
	await _frames(3)
	await _click(arena.hud.restart_button)
	arena = current_scene
	_check(arena.normal_mode and arena.survivor.lethal_attacks and not arena.battle_over, "result Play again also retains Normal")
	arena.return_to_menu()
	await _frames(4)
	menu = current_scene
	_check(menu.normal_mode and menu.get_node("%NormalButton").button_pressed, "returning to menu remembers the selection without a singleton")
	await _click(menu.get_node("%NewbieButton"))
	await _click(menu.get_node("%PlayButton"))
	arena = current_scene
	_check(not arena.normal_mode and not arena.survivor.lethal_attacks and arena.hud.phase.text.begins_with("Newbie"), "changing to Newbie restores the original rules")
	arena.restart()
	await _frames(4)
	arena = current_scene
	_check(not arena.normal_mode and not arena.survivor.lethal_attacks, "Newbie restart retains its nonlethal melee")
	arena.battle_audio.stop_all()
	await create_timer(0.15).timeout
	print("Game modes smoke: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)


func _check_attack(normal: bool, kind: Survivor.Attack) -> void:
	var fixture := Node3D.new()
	root.add_child(fixture)
	var knight: Survivor = KNIGHT.instantiate()
	fixture.add_child(knight)
	knight.configure_wave(3, 1200)
	knight.lethal_attacks = normal
	var agents: Array[HordeAgent] = []
	for index: int in range(3):
		var agent: HordeAgent = ZOMBIE.instantiate()
		agent.kind = HordeAgent.Kind.TEMPORARY if index == 1 else HordeAgent.Kind.PERMANENT
		agent.get_node("Health").max_health = 120 if index == 1 else 30
		fixture.add_child(agent)
		agents.append(agent)
	var distance: float = 5.0 if kind == Survivor.Attack.CROSSBOW else 1.0
	agents[0].position = Vector3.FORWARD * distance
	agents[1].position = Vector3.FORWARD * (distance + 0.5)
	agents[2].position = Vector3.FORWARD * 20.0
	knight._begin_attack(kind, agents[0].position)
	knight.update_combat(agents, knight.current_windup() * 0.5)
	_check(agents[0].health.current_health == 30 and agents[1].health.current_health == 120, "mode %s attack %s preserves warning before damage" % [normal, kind])
	knight.update_combat(agents, knight.current_windup() * 0.5)
	var step: float = knight.charge_duration if kind == Survivor.Attack.CHARGE else 0.75
	knight.update_combat(agents, step)
	var lethal: bool = normal or kind == Survivor.Attack.CROSSBOW
	var damage: int = knight.attack_damage if kind == Survivor.Attack.SWEEP else 20
	_check(agents[0].health.current_health == (0 if lethal else 30 - damage), "mode %s attack %s correctly damages a permanent zombie" % [normal, kind])
	_check(agents[1].health.current_health == (0 if lethal else 120 - damage), "mode %s attack %s correctly damages a 120-HP temporary zombie" % [normal, kind])
	_check(agents[2].health.current_health == 30, "mode %s attack %s does not expand its hit area" % [normal, kind])
	fixture.free()


func _click(control: Control) -> void:
	var point: Vector2 = control.get_global_transform_with_canvas() * (control.size * 0.5)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventMouseButton
	event.pressed = false
	root.push_input(event, true)
	await _frames(4)


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventKey
	event.pressed = false
	root.push_input(event, true)


func _frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame


func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/survive_modes_%s.png" % label)


func _check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		_failures += 1
