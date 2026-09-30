extends SceneTree

const MAIN: PackedScene = preload("res://scenes/main.tscn")
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	var scene: Node3D = MAIN.instantiate()
	root.add_child(scene)
	current_scene = scene
	await _frames(3)
	var hud: BattleHUD = scene.hud
	var horde: HordeController = scene.horde
	_check(hud.sprint_button.disabled and hud.permanent_count.text == "40", "ready HUD shows permanent count and disabled sprint")
	await _capture("ready")
	await _click_control(hud.get_node("%PauseButton"))
	_check(paused and hud.overlay.visible and not scene.battle_started, "pause button works before battle without issuing a ground command")
	var target: Vector3 = horde.command_position
	_click(scene.get_node("Camera").unproject_position(Vector3.ZERO))
	await _frames(2)
	_check(horde.command_position == target and not scene.battle_started, "modal backdrop blocks commands")
	await _click_control(hud.resume_button)
	_check(not paused and not hud.overlay.visible, "resume button works while tree is paused")
	_click(scene.get_node("Camera").unproject_position(Vector3(-10, 0, 3)))
	await _frames(2)
	_check(scene.battle_started and not hud.sprint_button.disabled, "HUD lets ground commands through and enables sprint")
	target = horde.command_position
	await _click_control(hud.sprint_button)
	_check(horde.sprint_remaining > 0.0 and horde.command_position == target, "sprint button boosts movement without changing destination")
	_check(hud.sprint_button.disabled and hud.sprint_bar.value < 100.0, "sprint shows its real cooldown")
	await _click_control(hud.get_node("%PauseButton"))
	var elapsed: float = scene.elapsed
	await _frames(10)
	_check(scene.elapsed == elapsed and paused, "pause freezes gameplay while HUD buttons remain usable")
	await _capture("pause")
	await _click_control(hud.restart_button)
	scene = current_scene
	hud = scene.hud
	horde = scene.horde
	_check(not paused and not scene.battle_started and horde.permanent_count() == 40, "restart button resets the run from pause")
	scene.survivor.health.take_damage(scene.survivor.health.current_health)
	await _frames(2)
	_check(scene.battle_over and hud.overlay.visible and not hud.resume_button.visible, "victory offers replay without resume")
	await _capture("victory")
	await _click_control(hud.restart_button)
	scene = current_scene
	hud = scene.hud
	horde = scene.horde
	_check(not scene.battle_over and not hud.overlay.visible, "play-again button resets the result screen")
	horde.command_move(Vector3.ZERO)
	horde.recruit(12, Vector3(-2, 0, 3))
	for index: int in range(34):
		horde.agents[0].health.take_damage(100)
	await _frames(2)
	_check(hud.permanent_hint.text == "PROTECT THE LAST 6" and hud.temporary_count.text == "12", "critical permanent count stays distinct from temporary recruits")
	await _capture("critical")
	for agent: HordeAgent in horde.agents.duplicate():
		if agent.kind == HordeAgent.Kind.PERMANENT:
			agent.health.take_damage(100)
	await _frames(22)
	_check(hud.result_label.text == "Defeat" and horde.temporary_count() == 12, "defeat screen reflects permanent wipe with temporary survivors")
	await _capture("defeat")
	await _click_control(hud.restart_button)
	scene = current_scene
	hud = scene.hud
	# The scene should also lay out without overlapping the top controls on a small window.
	root.size = Vector2i(960, 600)
	await _frames(4)
	var boss: Control = hud.get_node("Frame/Boss")
	var brand: Control = hud.get_node("Frame/Brand")
	var run: Control = hud.get_node("Frame/Run")
	_check(not boss.get_global_rect().intersects(brand.get_global_rect()) and not boss.get_global_rect().intersects(run.get_global_rect()), "top panels do not overlap at 960 by 600")
	await _capture("small")
	print("UI smoke: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)


func _click_control(control: Control) -> void:
	_click(control.get_global_transform_with_canvas() * (control.size * 0.5))
	await _frames(3)


func _click(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	root.push_input(motion, true)
	var event := InputEventMouseButton.new()
	event.position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventMouseButton
	event.pressed = false
	root.push_input(event, true)


func _frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame


func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/survive_ui_%s.png" % label)


func _check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		_failures += 1
