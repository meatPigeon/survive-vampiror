extends SceneTree

const MAIN: PackedScene = preload("res://scenes/main.tscn")
var _failures: int = 0
var _record: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_record = "--record" in OS.get_cmdline_user_args()
	var recorder: AudioEffectRecord
	if _record:
		recorder = AudioEffectRecord.new()
		AudioServer.add_bus_effect(0, recorder)
		recorder.set_recording_active(true)
	var scene: Node3D = _fixture()
	var sounds: BattleAudio = scene.battle_audio
	var knight: Survivor = scene.survivor
	var horde: HordeController = scene.horde
	var west: ReinforcementSite = scene.get_node("Reinforcements/West")
	_check(_all_stopped(sounds), "ready state is silent")
	for player: AudioStreamPlayer in sounds.get_children():
		_check(player.max_polyphony == 1 and not player.autoplay, "each category has one voice and no autoplay")
		if player.stream != null:
			_check(player.stream.get_length() > 0.2 and (player.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_DISABLED, "audio asset is finite and imported")

	horde.command_move(west.position)
	_check(sounds.grave_rise.playing, "first command opens grave sound")
	var playback: AudioStreamPlayback = sounds.grave_rise.get_stream_playback()
	west._update_label()
	west.set_active(true)
	_check(sounds.grave_rise.get_stream_playback() == playback, "repeated availability and fresh stock do not retrigger grave sound")
	await _wait(1.25)
	scene.elapsed = 30.0
	scene._update_site_schedule()
	_check(sounds.grave_sink.playing and sounds.grave_rise.playing, "rotation preserves outgoing and incoming grave sounds")
	await _wait(1.25)

	# Actual damage/attack transitions, including missed attacks and charge batches.
	var agent: HordeAgent = horde.agents[0]
	agent.position = knight.position + Vector3.FORWARD
	for kind: Survivor.Attack in [Survivor.Attack.SWEEP, Survivor.Attack.CHARGE, Survivor.Attack.SPIN]:
		knight._begin_attack(kind, agent.position)
		_check(sounds.warning.playing and sounds.warning.stream == BattleAudio.WARNINGS[kind], "windup selects its distinct audible warning")
		_check(not sounds.impact.playing, "windup has no premature impact")
		await _wait(0.12)
		paused = true
		var cooldown: float = sounds._voice_cooldown
		await _wait(0.2)
		_check(sounds.warning.stream_paused and sounds._voice_cooldown == cooldown, "pause freezes playback and audio cooldowns")
		paused = false
		await _wait(knight.current_windup() - 0.12)
		knight.update_combat([], knight.current_windup())
		_check(sounds.swish.playing and not sounds.warning.playing and not sounds.impact.playing, "strike swishes but a miss does not sound like a hit")
		# A later charge segment can make contact; only its first contact sounds.
		if kind == Survivor.Attack.CHARGE:
			knight._hit_charge([agent], knight.position, agent.position)
		else:
			knight._hit_area([agent])
		_check(sounds.impact.playing, "confirmed attack damage triggers contact sound")
		playback = sounds.impact.get_stream_playback()
		var second: HordeAgent = horde.agents[1]
		second.position = agent.position
		if kind == Survivor.Attack.CHARGE:
			knight._hit_charge([second], knight.position, second.position)
		else:
			knight._hit_area([second])
		_check(sounds.impact.get_stream_playback() == playback, "multiple victims share one impact per attack")
		await _wait(1.4)
		agent = horde.agents[2]
		agent.position = knight.position + Vector3.FORWARD

	# A crowd of bites cannot become a crowd of overlapping voices.
	knight.health.take_damage(4)
	_check(sounds.voice.playing, "zombie bite damage is audible")
	playback = sounds.voice.get_stream_playback()
	for index: int in range(30):
		knight.health.take_damage(4)
	_check(sounds.voice.get_stream_playback() == playback, "simultaneous bites do not restart or stack grunts")
	await _wait(1.4)
	horde.agents[0].health.take_damage(100)
	_check(sounds.voice.playing and sounds.voice.pitch_scale < 1.0, "combat loss uses a lower grunt")
	await _wait(1.4)
	horde.recruit(2, west.position)
	_check(sounds.voice.playing, "successful recruitment voices once per batch")
	await _wait(1.4)
	horde.agents.back().update_lifetime(100.0)
	_check(not sounds.voice.playing, "expiry does not sound like a combat casualty")

	var south: ReinforcementSite = scene.get_node("Reinforcements/South")
	horde.agents[0].position = south.position
	horde.command_move(south.position)
	south.update_recruitment(horde, south.summon_time)
	_check(south.remaining == 0 and sounds.grave_sink.playing, "exhausting actual recruitment stock plays closing sound")
	await _wait(1.3)
	knight._begin_attack(Survivor.Attack.SPIN, agent.position)
	knight.health.take_damage(knight.health.current_health)
	_check(scene.battle_over and _all_stopped(sounds), "victory immediately stops all gameplay sounds")
	west.set_active(true)
	_check(_all_stopped(sounds), "late visual changes cannot sound after the outcome")
	var old_audio: WeakRef = weakref(sounds)
	playback = null
	scene.restart()
	await _wait(0.1)
	scene = current_scene
	_check(old_audio.get_ref() == null and _all_stopped(scene.battle_audio), "restart frees old voices and begins silent")

	# Real scene ticks and a floor click exercise the wiring in a running fight.
	if _record:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = scene.get_node("Camera").unproject_position(scene.survivor.position)
		click.pressed = true
		root.push_input(click, true)
		click = click.duplicate() as InputEventMouseButton
		click.pressed = false
		root.push_input(click, true)
		_check(scene.battle_started, "recorded fight starts from actual viewport input")
		await _wait(12.0)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/survive_audio_battle.png")
	for zombie: HordeAgent in scene.horde.agents.duplicate():
		zombie.health.take_damage(100)
	_check(scene.battle_over and _all_stopped(scene.battle_audio), "defeat also stops all voices")
	await _wait(0.25)
	if _record:
		recorder.set_recording_active(false)
		var recording: AudioStreamWAV = recorder.get_recording()
		_check(recording != null and recording.get_length() > 10.0, "rendered run captured mixed audio")
		recording.save_to_wav("/tmp/survive_audio_check.wav")
		AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
		recorder = null
	print("Audio smoke: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)


func _fixture() -> Node3D:
	var scene: Node3D = MAIN.instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.set_physics_process(false)
	scene.horde.set_physics_process(false)
	scene.survivor.stop_combat()
	return scene


func _all_stopped(sounds: BattleAudio) -> bool:
	for player: AudioStreamPlayer in sounds.get_children():
		if player.playing:
			return false
	return true


func _wait(seconds: float) -> void:
	# Run without --fixed-fps: the audio mixer advances in wall-clock time.
	await create_timer(seconds, true, false, true).timeout


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failures += 1
