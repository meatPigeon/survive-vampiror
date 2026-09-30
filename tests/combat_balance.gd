extends SceneTree

const MAIN: PackedScene = preload("res://scenes/main.tscn")
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	await _battle("passive", 22)
	if "--capture" not in OS.get_cmdline_user_args():
		await _battle("chase", 22)
	await _battle("active", 22)
	if "--capture" not in OS.get_cmdline_user_args():
		await _battle("active", 30)
	print("Combat balance: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)


func _battle(strategy: String, reaction_frames: int) -> void:
	var scene: Node3D = MAIN.instantiate()
	root.add_child(scene)
	current_scene = scene
	var horde: HordeController = scene.get_node("Horde")
	var knight: Survivor = scene.get_node("Survivor")
	var camera: Camera3D = scene.get_node("Camera")
	await physics_frame
	await _capture(strategy + "_start")
	_click(camera, horde, knight.global_position)
	var warning_frames: int = 0
	var dodging: bool = false
	var camp: ReinforcementSite
	var frames: int = 0
	var attacks: Array[int] = [0, 0, 0]
	var phases: Array[bool] = [false, false, false]
	var captured: Array[bool] = [false, false, false]
	var recruited_before: int = 0
	while not scene.battle_over and frames < 18000:
		await physics_frame
		frames += 1
		# The tick can finish the battle; do not send ground clicks into its modal.
		if scene.battle_over:
			break
		phases[knight.phase - 1] = true
		if knight.attack_area.visible:
			warning_frames += 1
			if warning_frames == 1:
				attacks[knight.attack_kind] += 1
		else:
			warning_frames = 0
			dodging = false
		if strategy == "active":
			var center := Vector3.ZERO
			for agent: HordeAgent in horde.agents:
				center += agent.global_position
			center /= maxf(1, horde.agents.size())
			if camp != null and (not camp.active or camp.remaining == 0 or horde.agents.size() >= horde.max_agents):
				camp = null
			if camp == null and horde.temporary_count() < 8 and horde.agents.size() < horde.max_agents:
				var candidate: ReinforcementSite = scene.active_site
				var time_left: float = scene.site_interval - fmod(scene.elapsed, scene.site_interval)
				# Travel and occupation must fit inside the visible active window.
				if candidate != null and candidate.remaining > 0 and time_left > center.distance_to(candidate.global_position) / 3.6 + 5.0:
					camp = candidate
			# The pilot reacts to the visible warning and HUD attack type, with
			# a human-scale delay. All actions use mouse/keyboard viewport input.
			if warning_frames == reaction_frames:
				var forward: Vector3 = -knight.attack_area.global_basis.z
				var side: Vector3 = forward.rotated(Vector3.UP, PI * 0.5)
				if (center - knight.global_position).dot(side) < 0:
					side = -side
				var target: Vector3 = knight.global_position + side * 4.5
				if knight.attack_kind == Survivor.Attack.CHARGE:
					target = center + side * 4.5
				elif knight.attack_kind == Survivor.Attack.SPIN:
					target = knight.global_position + (center - knight.global_position).normalized() * 7.0
				_click(camera, horde, target)
				if knight.attack_kind != Survivor.Attack.SWEEP:
					_sprint()
				dodging = true
				if not captured[knight.attack_kind]:
					captured[knight.attack_kind] = true
					await _capture(strategy + "_" + Survivor.Attack.keys()[knight.attack_kind].to_lower())
			if not dodging and frames % 15 == 0:
				_click(camera, horde, camp.global_position if camp != null else knight.global_position)
		elif strategy == "chase" and frames % 30 == 0:
			_click(camera, horde, knight.global_position)
		if horde.recruited > recruited_before:
			recruited_before = horde.recruited
			await _capture(strategy + "_reinforcements")
		if frames % 3600 == 0:
			print("%s: %ds, phase %d, HP %d, zombies %d, recruited %d" % [strategy, frames / 60, knight.phase, knight.health.current_health, horde.agents.size(), horde.recruited])
	_check(scene.battle_over, strategy + ": fight ends within five minutes")
	if strategy == "active":
		_check(not knight.health.is_alive() and horde.permanent_count() > 0, "active commands can win while preserving permanent zombies")
		_check(phases.all(func(seen: bool) -> bool: return seen), "winning run visits all three phases")
		_check(attacks.all(func(count: int) -> bool: return count > 0), "winning run encounters every attack")
		_check(horde.recruited > 0, "winning run uses temporary reinforcements")
	else:
		_check(knight.health.is_alive() and horde.permanent_count() == 0, "passive or reckless chasing cannot win")
	print("%s reaction=%.2fs: %.1fs, knight=%d HP, permanent=%d, temporary=%d, recruits=%d, expired=%d, attacks=%s" % [
		strategy, reaction_frames / 60.0, frames / 60.0, knight.health.current_health,
		horde.permanent_count(), horde.temporary_count(), horde.recruited, horde.expired_count, attacks])
	for frame: int in range(40):
		await physics_frame
	await _capture(strategy + "_result")
	scene.free()
	await process_frame


func _click(camera: Camera3D, horde: HordeController, target: Vector3) -> void:
	var bounds: Rect2 = horde.movement_bounds.grow(-0.4)
	target.x = clampf(target.x, bounds.position.x, bounds.end.x)
	target.z = clampf(target.z, bounds.position.y, bounds.end.y)
	var click := InputEventMouseButton.new()
	click.position = camera.unproject_position(target)
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	root.push_input(click, true)
	click = click.duplicate() as InputEventMouseButton
	click.pressed = false
	root.push_input(click, true)


func _sprint() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventKey
	event.pressed = false
	root.push_input(event, true)


func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/survive_jam_%s.png" % label)


func _check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		_failures += 1
