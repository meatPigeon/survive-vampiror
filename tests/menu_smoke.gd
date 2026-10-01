extends SceneTree

var _failures: int = 0
var _pilot := preload("res://tests/support/horde_pilot.gd").new()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	var startup: PackedScene = load(ProjectSettings.get_setting("application/run/main_scene"))
	var menu: MainMenu = startup.instantiate()
	root.add_child(menu)
	current_scene = menu
	await _frames(4)
	# Apply after the desktop window manager has placed the new window.
	root.size = Vector2i(1280, 800)
	await _frames(4)
	var music_bus: int = AudioServer.get_bus_index(&"Music")
	var effects_bus: int = AudioServer.get_bus_index(&"Effects")
	_check(music_bus > 0 and effects_bus > 0 and music_bus != effects_bus, "separate authored audio buses load at startup")
	_check(menu.music.playing and menu.music.bus == &"Music", "main menu plays the selected march on the music bus")
	_check(menu.music.stream.resource_path == "res://assets/audio/undead_march.ogg", "Undead March stays on the title screen")
	_check(not menu.has_node("Horde"), "title screen has no active battle")
	_check(menu.get_node("Diorama/Viewport/Stage/Characters/Leader/AnimationPlayer").is_playing(), "title diorama animates its imported characters")
	_check(not menu.audio_controls.is_visible_in_tree(), "audio settings start tucked away")
	await _capture("main")
	await _click_control(menu.get_node("%SettingsButton"))
	_check(menu.audio_controls.is_visible_in_tree(), "Audio opens the existing volume controls")
	await _slider_at(menu.audio_controls.music_slider, 0.0)
	_check(AudioServer.is_bus_mute(music_bus) and not AudioServer.is_bus_mute(effects_bus), "zero music truly mutes only music")
	await _slider_at(menu.audio_controls.effects_slider, 0.35)
	var effects_level: float = AudioServer.get_bus_volume_linear(effects_bus)
	_check(absf(effects_level - 0.35) < 0.04 and AudioServer.is_bus_mute(music_bus), "effect slider changes its gain independently")
	_check(menu.audio_controls.preview.bus == &"Effects", "settings preview follows effect volume")
	await _slider_at(menu.audio_controls.music_slider, 0.6)
	var music_level: float = AudioServer.get_bus_volume_linear(music_bus)
	_check(not AudioServer.is_bus_mute(music_bus) and absf(music_level - 0.6) < 0.04, "raising music restores it from mute")
	root.size = Vector2i(960, 600)
	await _frames(4)
	_check_inside(menu.get_node("%PlayButton"))
	_check_inside(menu.audio_controls)
	_check(not menu.get_node("%PlayButton").get_global_rect().intersects(menu.audio_controls.get_global_rect()), "start and settings remain separate on a small window")
	await _capture("main_small")
	await _click_control(menu.get_node("%SettingsButton"))
	_check(not menu.audio_controls.is_visible_in_tree(), "Audio can close without leaving the menu")
	var old_menu: WeakRef = weakref(menu)
	await _click_control(menu.get_node("%PlayButton"))
	var arena: Node3D = current_scene
	_check(old_menu.get_ref() == null and not arena.battle_started and not paused, "Play opens a ready battle directly without leaking the click")
	_check(arena.horde.ability.upgrade == HordeAbility.Upgrade.NONE and not arena.hud.get_node("%AbilityButton").visible and not arena.hud.upgrades.visible, "the first wave begins unmodified with no reward screen")
	_check(arena.battle_audio.music.stream.resource_path == "res://assets/audio/graveyard_groove.ogg", "battle uses Graveyard Groove instead of menu music")
	_check(is_equal_approx(AudioServer.get_bus_volume_linear(music_bus), music_level) and is_equal_approx(AudioServer.get_bus_volume_linear(effects_bus), effects_level), "audio levels survive entry to battle")
	for player: AudioStreamPlayer in arena.battle_audio.get_children():
		_check(player.bus == (&"Music" if player == arena.battle_audio.music else &"Effects"), "every battle player routes to its correct volume bus")
	_pilot.move(root, Vector2.LEFT)
	await _frames(3)
	_check(arena.battle_started, "WASD starts battle after Play")
	await _click_control(arena.hud.get_node("%PauseButton"))
	var controls: AudioControls = arena.hud.audio_controls
	_check(paused and controls.is_visible_in_tree(), "pause exposes the reusable volume controls")
	_check(absf(controls.music_slider.value - music_level * 100.0) < 1.0, "pause reads the existing music level")
	var elapsed: float = arena.elapsed
	var target: Vector3 = arena.horde.move_direction
	await _slider_at(controls.music_slider, 0.4)
	await _slider_at(controls.effects_slider, 0.0)
	_check(AudioServer.is_bus_mute(effects_bus) and not AudioServer.is_bus_mute(music_bus), "effects mute independently while paused")
	_check(paused and arena.elapsed == elapsed and arena.horde.move_direction == target, "slider interaction cannot advance combat or move the horde")
	_check_inside(arena.hud.overlay_card)
	await _capture("pause_small")
	music_level = AudioServer.get_bus_volume_linear(music_bus)
	await _click_control(arena.hud.resume_button)
	arena.horde.grant_ability(HordeAbility.Upgrade.SPRINT) # Isolate post-slider keyboard focus with an owned perk.
	var sprint := InputEventKey.new()
	sprint.physical_keycode = KEY_SPACE
	sprint.pressed = true
	root.push_input(sprint, true)
	await _frames(2)
	_check(arena.horde.sprint_remaining > 0.0, "hidden sliders release focus so Space still sprints after resume")
	await _click_control(arena.hud.get_node("%PauseButton"))
	await _click_control(arena.hud.restart_button)
	arena = current_scene
	_check(not paused and not arena.battle_started and AudioServer.is_bus_mute(effects_bus), "restart clears pause but preserves mute")
	_check(is_equal_approx(AudioServer.get_bus_volume_linear(music_bus), music_level), "restart preserves music gain")
	await _click_control(arena.hud.get_node("%PauseButton"))
	var old_audio: WeakRef = weakref(arena.battle_audio)
	await _click_control(arena.hud.get_node("%MenuButton"))
	menu = current_scene
	_check(menu is MainMenu and not paused and old_audio.get_ref() == null, "Main menu from pause unpauses and frees battle audio")
	_check(menu.audio_controls.effects_slider.value == 0.0 and absf(menu.audio_controls.music_slider.value - music_level * 100.0) < 1.0, "returned menu shows the current levels")
	_check(menu.music.stream.resource_path == "res://assets/audio/undead_march.ogg" and menu.music.playing, "returning to the menu restores the march")
	await _click_control(menu.get_node("%SettingsButton"))
	await _slider_at(menu.audio_controls.effects_slider, 1.0)
	await _click_control(menu.get_node("%PlayButton"))
	arena = current_scene
	_check(arena.horde.ability.upgrade == HordeAbility.Upgrade.NONE, "a new run starts without the previous run's upgrades")
	arena.wave_count = arena.wave_index # This scenario checks the final outcome.
	arena.survivor.health.take_damage(arena.survivor.health.current_health)
	await _frames(3)
	_check(arena.battle_over and not arena.hud.audio_controls.visible, "result stays compact without pause settings")
	_check_inside(arena.hud.get_node("%MenuButton"))
	await _capture("result")
	await _click_control(arena.hud.get_node("%MenuButton"))
	menu = current_scene
	_check(menu is MainMenu and not paused, "result screen returns to menu")
	# Reset the session mixer so this script leaves the default levels behind.
	for bus: int in [music_bus, effects_bus]:
		AudioServer.set_bus_mute(bus, false)
		AudioServer.set_bus_volume_linear(bus, 1.0)
	print("Menu smoke: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	if _failures > 0:
		menu.music.stop()
		quit(1)
		return
	_click(menu.get_node("%QuitButton").get_global_transform_with_canvas() * (menu.get_node("%QuitButton").size * 0.5))
	await create_timer(0.5).timeout
	push_error("Quit button did not close the application")
	quit(1)


func _slider_at(slider: HSlider, ratio: float) -> void:
	var point: Vector2 = slider.get_global_transform_with_canvas() * Vector2(8.0 + (slider.size.x - 16.0) * ratio, slider.size.y * 0.5)
	_click(point)
	await _frames(3)


func _click_control(control: Control) -> void:
	_click(control.get_global_transform_with_canvas() * (control.size * 0.5))
	await _frames(4)


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
		await process_frame


func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/survive_menu_%s.png" % label)


func _check_inside(control: Control) -> void:
	_check(root.get_visible_rect().encloses(control.get_global_rect()), "control fits inside viewport: %s" % control.name)


func _check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		_failures += 1
