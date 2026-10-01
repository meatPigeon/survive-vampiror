extends SceneTree

const MAIN: PackedScene = preload("res://scenes/main.tscn")
var _failures: int = 0
var _pilot := preload("res://tests/support/horde_pilot.gd").new()


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
	_check(not hud.get_node("%TemporaryGroup").visible and not hud.get_node("%Rally").visible, "ready view hides empty recruits and inactive reinforcement information")
	await _capture("ready")
	await _click_control(hud.get_node("%PauseButton"))
	_check(paused and hud.overlay.visible and not scene.battle_started, "pause button works before battle without issuing a ground command")
	var target: Vector3 = horde.move_direction
	_click(scene.get_node("Camera").unproject_position(Vector3.ZERO))
	await _frames(2)
	_check(horde.move_direction == target and not scene.battle_started, "modal backdrop blocks commands")
	await _click_control(hud.resume_button)
	_check(not paused and not hud.overlay.visible, "resume button works while tree is paused")
	_pilot.move(root, Vector2.LEFT)
	await _frames(2)
	_check(scene.battle_started and hud.sprint_button.disabled and not hud.get_node("%Sprint").visible, "starting the fight does not unlock sprint")
	horde.grant_ability(HordeAbility.Upgrade.SPRINT)
	await _frames(2)
	_check(hud.get_node("%Sprint").visible and not hud.sprint_button.disabled, "the sprint perk reveals its HUD control")
	target = horde.move_direction
	await _click_control(hud.sprint_button)
	_check(horde.sprint_remaining > 0.0 and horde.move_direction == target, "sprint button boosts movement without changing direction")
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
	scene.wave_count = scene.wave_index # This scenario checks the final outcome.
	scene.survivor.health.take_damage(scene.survivor.health.current_health)
	await _frames(2)
	_check(scene.battle_over and hud.overlay.visible and not hud.resume_button.visible, "victory offers replay without resume")
	await _capture("victory")
	await _click_control(hud.restart_button)
	scene = current_scene
	hud = scene.hud
	horde = scene.horde
	_check(not scene.battle_over and not hud.overlay.visible, "play-again button resets the result screen")
	horde.command_direction(Vector3.RIGHT)
	horde.recruit(12, Vector3(-2, 0, 3))
	for index: int in range(34):
		horde.agents[0].health.take_damage(100)
	await _frames(2)
	_check(hud.permanent_hint.text == "Keep them alive" and hud.temporary_count.text == "+12", "critical permanent count stays distinct from temporary recruits")
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
	scene.horde.grant_ability(HordeAbility.Upgrade.SPRINT)
	root.size = Vector2i(960, 600)
	await _frames(4)
	var boss: Control = hud.get_node("Frame/Boss")
	var pause_button: Control = hud.get_node("%PauseButton")
	_check(not boss.get_global_rect().intersects(pause_button.get_global_rect()), "boss and pause stay separate at 960 by 600")
	horde = scene.horde
	horde.command_direction(Vector3.RIGHT)
	horde.recruit(12, Vector3(-2, 0, 3))
	await _frames(3)
	var horde_display: Control = hud.get_node("Frame/Horde")
	var sprint: Control = hud.get_node("%Sprint")
	var rally: Control = hud.get_node("%Rally")
	_check(not horde_display.get_global_rect().intersects(sprint.get_global_rect()) and not sprint.get_global_rect().intersects(rally.get_global_rect()), "horde, sprint and recruitment do not overlap in the small mixed-crowd view")
	_check(hud.get_node("%TemporaryGroup").visible and rally.visible, "secondary information appears when relevant")
	# Keep recruitment feedback beside the active crater, with only stock/time in HUD.
	scene.set_physics_process(false)
	horde.set_physics_process(false)
	var site: ReinforcementSite = scene.active_site
	for index: int in range(horde.agents.size()):
		var angle: float = float(index) * 2.399963
		var distance: float = 0.5 * sqrt(float(index))
		horde.agents[index].global_position = site.global_position + Vector3(cos(angle), 0, sin(angle)) * distance
	horde.command_direction(Vector3.RIGHT)
	site.update_recruitment(horde, site.summon_time * 0.5)
	scene._update_status()
	_check(hud.site_name.text == "◇  +12" and not hud.site_hint.text.contains("%"), "recruitment HUD uses a marker and stock without compass names or percentages")
	await _frames(55)
	await _capture("recruitment_small")
	root.size = Vector2i(1280, 800)
	await _frames(4)
	await _capture("recruitment")
	scene.survivor.health.take_damage(100)
	await _click_control(hud.get_node("%PauseButton"))
	var trail_value: float = hud.health_trail.value
	await _frames(15)
	_check(hud.health_trail.value == trail_value, "health presentation freezes during pause")
	await _click_control(hud.resume_button)
	root.size = Vector2i(960, 600)
	await _frames(4)
	await _capture("small")
	scene.battle_audio.stop_all()
	hud.audio_controls.stop_preview()
	scene.queue_free()
	await _frames(3)
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
