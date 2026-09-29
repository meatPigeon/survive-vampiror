extends SceneTree

const MAIN: PackedScene = preload("res://scenes/main.tscn")
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	var starts: Array[Vector3] = [Vector3(-8, 0, 3), Vector3(-4, 0, -3), Vector3(6, 0, 7), Vector3(16, 0, -3)]
	# Render the normal start; headless runs cover the additional approaches.
	if "--capture" in OS.get_cmdline_user_args():
		starts.resize(1)
	for start: Vector3 in starts:
		for active: bool in [false, true]:
			await _battle(start, active)
	print("Combat balance: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)


func _battle(start: Vector3, active: bool) -> void:
	var scene: Node3D = MAIN.instantiate()
	var horde: HordeController = scene.get_node("Horde")
	horde.spawn_center = start
	root.add_child(scene)
	var knight: Survivor = scene.get_node("Survivor")
	var camera: Camera3D = scene.get_node("Camera")
	await physics_frame
	_click(camera, knight.global_position)
	var warning_frames: int = 0
	var dodging: bool = false
	var frames: int = 0
	var commands: int = 1
	var captured_warning: bool = false
	var label: String = "active" if active else "passive"
	while not scene.battle_over and frames < 5400:
		await physics_frame
		frames += 1
		if knight.attack_area.visible:
			warning_frames += 1
			# React to the visible tell after ~0.37 s, using ordinary ground clicks.
			# No direct agent movement, HP changes, or private attack state access.
			if warning_frames == 22:
				if active:
					var forward: Vector3 = -knight.attack_area.global_basis.z
					_click(camera, knight.global_position + forward.rotated(Vector3.UP, PI * 0.5) * 4.5)
					dodging = true
					commands += 1
				if not captured_warning:
					await _capture(label + "_warning")
					captured_warning = true
		else:
			warning_frames = 0
			if dodging:
				_click(camera, knight.global_position)
				dodging = false
				commands += 1
		if frames == 1500:
			await _capture(label + "_fight")
	_check(scene.battle_over, label + ": fight ends within 90 seconds")
	if active:
		_check(not knight.health.is_alive() and horde.agents.size() >= 5,
			"reacting to warned swings can win with some room for mistakes")
	else:
		_check(knight.health.is_alive() and horde.agents.is_empty(),
			"single-click passive swarm cannot win")
	print("%s start=%s: %.1fs, knight=%d/%d HP, zombies=%d, commands=%d" % [
		label, start, frames / 60.0, knight.health.current_health,
		knight.health.max_health, horde.agents.size(), commands])
	for frame: int in range(40):
		await physics_frame
	await _capture(label + "_result")
	scene.free()
	await process_frame


func _click(camera: Camera3D, target: Vector3) -> void:
	var click := InputEventMouseButton.new()
	click.position = camera.unproject_position(target)
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	root.push_input(click, true)
	click = click.duplicate() as InputEventMouseButton
	click.pressed = false
	root.push_input(click, true)


func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/survive_balance_%s.png" % label)


func _check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		_failures += 1
