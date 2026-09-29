extends SceneTree

var _failures: int = 0
var _death_count: int = 0
const MAIN: PackedScene = preload("res://scenes/main.tscn")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	var health := Health.new()
	health.max_health = 20
	root.add_child(health)
	health.died.connect(func() -> void: _death_count += 1)
	health.take_damage(-10)
	_check(health.current_health == 20, "negative damage ignored")
	health.take_damage(7)
	_check(health.current_health == 13, "damage reduces health")
	health.take_damage(100)
	health.take_damage(100)
	_check(health.current_health == 0 and _death_count == 1, "death occurs once and health clamps to zero")
	health.free()

	var scene: Node3D = MAIN.instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	var knight: Survivor = scene.get_node("Survivor")
	var horde: HordeController = scene.get_node("Horde")
	var front: HordeAgent = horde.agents[0]
	var rear: HordeAgent = horde.agents[1]
	var distant: HordeAgent = horde.agents[2]
	front.global_position = knight.global_position + Vector3.FORWARD
	rear.global_position = knight.global_position + Vector3.BACK * 1.1
	distant.global_position = knight.global_position + Vector3.FORWARD * 4.0

	var starting_health: int = knight.health.max_health
	var zombie_health_max: int = front.health.max_health
	var cycle: float = knight.windup_time + knight.swing_time + knight.recovery_time
	distant.update_combat(knight, 1.0)
	_check(knight.health.current_health == starting_health, "out-of-range zombie cannot bite")
	front.update_combat(knight, 0.1)
	front.update_combat(knight, 0.1)
	_check(knight.health.current_health == starting_health - front.bite_damage, "bite damages once during cooldown")
	front.update_combat(knight, 0.8)
	_check(knight.health.current_health == starting_health - front.bite_damage * 2, "bite repeats after cooldown")

	knight.update_combat(horde.agents, 0.01)
	_check(knight.attack_area.visible and front.health.current_health == zombie_health_max, "swing warns before dealing damage")
	_check(knight.animation_player.current_animation == &"combat/swing", "knight plays the swing animation")
	knight.update_combat(horde.agents, knight.windup_time)
	_check(front.health.current_health == zombie_health_max - knight.attack_damage, "swing hits the zombie in front")
	_check(rear.health.current_health == zombie_health_max and distant.health.current_health == zombie_health_max, "swing respects direction and range")
	knight.update_combat(horde.agents, 0.01)
	_check(front.health.current_health == zombie_health_max - knight.attack_damage, "one swing deals damage only once")
	knight.update_combat(horde.agents, cycle)
	knight.update_combat(horde.agents, 0.01)
	# Retreat after the tell: the locked swing must miss.
	front.global_position += Vector3.FORWARD * 3.0
	knight.update_combat(horde.agents, knight.windup_time)
	_check(front.health.current_health == zombie_health_max - knight.attack_damage, "retreat during windup avoids damage")
	knight.update_combat(horde.agents, cycle)
	front.global_position = knight.global_position + Vector3.FORWARD
	knight.update_combat(horde.agents, 0.01)
	knight.update_combat(horde.agents, knight.windup_time)
	_check(not front.health.is_alive() and horde.agents.size() == 39, "fatal swing removes zombie from active horde immediately")
	var knight_health: int = knight.health.current_health
	front.update_combat(knight, 10.0)
	_check(knight.health.current_health == knight_health, "dead zombie cannot bite")
	await _frames(30)
	_check(not is_instance_valid(front), "dead zombie is freed after its death pose")
	scene.free()

	# Exercise an actual battle through the same mouse input as the player.
	scene = MAIN.instantiate()
	root.add_child(scene)
	current_scene = scene
	knight = scene.get_node("Survivor")
	horde = scene.get_node("Horde")
	await _frames(10)
	await _capture("start")
	var camera: Camera3D = scene.get_node("Camera")
	var click := InputEventMouseButton.new()
	click.position = camera.unproject_position(knight.global_position)
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	root.push_input(click, true)
	click = click.duplicate() as InputEventMouseButton
	click.pressed = false
	root.push_input(click, true)
	_check(horde.command_position.distance_to(knight.global_position) < 0.01, "click commands the horde into combat")
	var captured_attack: bool = false
	var battle_frames: int = 0
	while not scene.battle_over and battle_frames < 7200:
		await physics_frame
		battle_frames += 1
		if knight.attack_area.visible and not captured_attack:
			await _frames(12)
			await _capture("swing")
			captured_attack = true
		if battle_frames == 900:
			await _capture("fight")
	_check(scene.battle_over, "full battle reaches an outcome within two minutes")
	_check(knight.health.is_alive() and horde.agents.is_empty(), "single-click passive attack loses")
	_check(knight.health.current_health < knight.health.max_health, "zombies damage the knight in actual movement")
	_check(horde.agents.size() < 40, "knight kills zombies in the actual battle")
	print("Battle: %.1f seconds, knight HP %d, zombies %d" % [battle_frames / 60.0, knight.health.current_health, horde.agents.size()])
	_check(not horde.commands_enabled and not knight.attack_area.visible, "battle outcome stops commands and attacks")
	_check(scene.get_node("HUD/Result").visible, "outcome is visible")
	_check(scene.get_node("HUD/Status/KnightHealth").value == knight.health.current_health, "health bar follows combat")
	var final_health: int = knight.health.current_health
	var final_count: int = horde.agents.size()
	var final_target: Vector3 = horde.command_position
	horde.command_move(Vector3.ZERO)
	await _frames(90)
	_check(horde.command_position == final_target, "commands ignored after battle")
	_check(knight.health.current_health == final_health and horde.agents.size() == final_count, "combat stays stopped after outcome")
	await _capture("result")

	var restart := InputEventKey.new()
	restart.keycode = KEY_R
	restart.pressed = true
	root.push_input(restart, true)
	await _frames(5)
	scene = current_scene
	knight = scene.get_node("Survivor")
	horde = scene.get_node("Horde")
	_check(not scene.battle_over and horde.agents.size() == 40 and knight.health.current_health == starting_health, "R reloads a fresh battle")
	_check(horde.commands_enabled and not scene.get_node("HUD/Result").visible, "restart resets controls and outcome")
	# Force each terminal condition independently of balance tuning.
	for agent: HordeAgent in horde.agents.duplicate():
		agent.health.take_damage(100)
	_check(scene.battle_over and scene.get_node("HUD/Result").text.begins_with("Defeat"), "losing the entire horde shows defeat")
	await _frames(30)
	root.push_input(restart, true)
	await _frames(5)
	scene = current_scene
	knight = scene.get_node("Survivor")
	horde = scene.get_node("Horde")
	knight.health.take_damage(10000)
	_check(scene.battle_over and scene.get_node("HUD/Result").text.begins_with("Victory"), "knight death shows victory")
	var zombie_health: int = horde.agents[0].health.current_health
	knight.update_combat(horde.agents, 10.0)
	_check(horde.agents[0].health.current_health == zombie_health, "dead knight cannot attack")
	await _frames(30)
	print("Combat smoke: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)


func _frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame


func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/survive_combat_%s.png" % label)


func _check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		_failures += 1
