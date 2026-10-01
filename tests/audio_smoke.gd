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
	horde.command_sprint()
	_check(not sounds.command.playing, "sprint before the first command is silent")
	for player: AudioStreamPlayer in sounds.get_children():
		_check(player.max_polyphony == 1 and not player.autoplay, "each category has one voice and no autoplay")
		if player == sounds.music:
			_check(player.stream is AudioStreamOggVorbis and (player.stream as AudioStreamOggVorbis).loop, "selected music imports as a looping Ogg stream")
		elif player.stream != null:
			_check(player.stream.get_length() > 0.2 and (player.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_DISABLED, "audio asset is finite and imported")

	horde.command_direction(Vector3.RIGHT)
	_check(sounds.music.playing and sounds.music.stream.resource_path == "res://assets/audio/graveyard_groove.ogg", "first command starts Graveyard Groove")
	var music_playback: AudioStreamPlayback = sounds.music.get_stream_playback()
	_check(sounds.grave_rise.playing, "first command opens grave sound")
	_check(sounds.command.playing and sounds.command.stream == BattleAudio.COMMAND, "accepted movement direction gives feedback")
	var command_playback: AudioStreamPlayback = sounds.command.get_stream_playback()
	for index: int in range(20):
		horde.command_direction(Vector3.RIGHT)
	_check(sounds.command.get_stream_playback() == command_playback, "command spam cannot restart or stack the cue")
	_check(sounds.music.get_stream_playback() == music_playback, "repeated commands do not restart music")
	horde.command_sprint()
	_check(sounds.command.get_stream_playback() == command_playback, "sprint without its perk stays silent")
	horde.grant_ability(HordeAbility.Upgrade.SPRINT)
	horde.command_sprint()
	_check(sounds.command.stream == BattleAudio.SPRINT, "successful sprint has a distinct cue")
	command_playback = sounds.command.get_stream_playback()
	horde.command_sprint()
	horde.command_direction(Vector3.RIGHT)
	_check(sounds.command.get_stream_playback() == command_playback, "cooldown rejection and movement commands do not interrupt sprint cue")
	var playback: AudioStreamPlayback = sounds.grave_rise.get_stream_playback()
	west._update_visuals()
	west.set_active(true)
	_check(sounds.grave_rise.get_stream_playback() == playback, "repeated availability and fresh stock do not retrigger grave sound")
	await _wait(1.25)
	for frame: int in range(25):
		horde._physics_process(1.0 / 60.0)
		await physics_frame
	_check(sounds.footsteps.playing, "actual horde travel plays shared footsteps")
	paused = true
	await _wait(0.15)
	_check(sounds.footsteps.stream_paused, "pause freezes footstep playback")
	_check(sounds.music.stream_paused, "pause freezes music")
	paused = false
	await _wait(0.7)
	_check(not sounds.music.stream_paused and sounds.music.get_stream_playback() == music_playback, "resume preserves the music playback")
	sounds.music.seek(sounds.music.stream.get_length() - 0.15)
	await _wait(0.4)
	_check(sounds.music.playing and sounds.music.get_playback_position() < 1.5, "music wraps across the end without stopping")
	_check(not sounds.footsteps.playing, "stationary horde does not produce a footsteps loop")
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
		paused = true
		var cooldown: float = sounds._voice_cooldown
		await _wait(0.2)
		_check(sounds.warning.stream_paused and sounds._voice_cooldown == cooldown, "pause freezes playback and audio cooldowns")
		paused = false
		await _wait(knight.current_windup())
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
		await _wait_for_quiet(sounds)
		agent = horde.agents[2]
		agent.position = knight.position + Vector3.FORWARD

	# A crowd of bites cannot become a crowd of overlapping voices.
	knight.health.take_damage(4)
	_check(sounds.voice.playing, "zombie bite damage is audible")
	_check(sounds.bite.playing, "actual knight damage plays bite contact")
	var bite_playback: AudioStreamPlayback = sounds.bite.get_stream_playback()
	playback = sounds.voice.get_stream_playback()
	for index: int in range(30):
		knight.health.take_damage(4)
	_check(sounds.voice.get_stream_playback() == playback, "simultaneous bites do not restart or stack grunts")
	_check(sounds.bite.get_stream_playback() == bite_playback, "simultaneous bites share one contact voice")
	await _wait_for_quiet(sounds)
	horde.agents[0].health.take_damage(100)
	_check(sounds.voice.playing and sounds.voice.pitch_scale < 1.0, "combat loss uses a lower grunt")
	await _wait_for_quiet(sounds)
	horde.recruit(2, west.position)
	_check(sounds.voice.playing, "successful recruitment voices once per batch")
	_check(sounds.notice.playing and sounds.notice.stream == BattleAudio.RECRUITED, "recruitment has an ascending confirmation cue")
	await _wait_for_quiet(sounds)
	horde.agents.back().update_lifetime(100.0)
	_check(not sounds.voice.playing, "expiry does not sound like a combat casualty")
	_check(sounds.notice.playing and sounds.notice.stream == BattleAudio.EXPIRED, "temporary expiry has a separate soft cue")
	var notice_playback: AudioStreamPlayback = sounds.notice.get_stream_playback()
	horde.agents.back().update_lifetime(100.0)
	_check(sounds.notice.get_stream_playback() == notice_playback, "simultaneous expiry is one sound")

	var south: ReinforcementSite = scene.active_site
	horde.agents[0].position = south.position
	horde.command_direction(Vector3.RIGHT)
	south.update_recruitment(horde, south.summon_time)
	_check(south.remaining == 0 and sounds.grave_sink.playing, "exhausting actual recruitment stock plays closing sound")
	await _wait(1.3)
	knight._begin_attack(Survivor.Attack.SPIN, agent.position)
	scene.wave_count = scene.wave_index # This scenario checks the final outcome.
	knight.health.take_damage(knight.health.current_health)
	_check(scene.battle_over and _all_stopped(sounds, true), "victory immediately stops gameplay sounds")
	_check(sounds.result.playing and sounds.result.stream == BattleAudio.VICTORY, "victory plays its own ending cue")
	playback = sounds.result.get_stream_playback()
	scene._finish_battle(false)
	_check(sounds.result.get_stream_playback() == playback, "repeated terminal events cannot restart or replace the result cue")
	west.set_active(true)
	_check(_all_stopped(sounds, true), "late visual changes cannot sound after the outcome")
	await _wait(0.3)
	var old_audio: WeakRef = weakref(sounds)
	playback = null
	command_playback = null
	bite_playback = null
	notice_playback = null
	music_playback = null
	scene.restart()
	await _wait(0.1)
	scene = current_scene
	_check(old_audio.get_ref() == null and _all_stopped(scene.battle_audio), "restart frees old voices and begins silent")

	# Real scene ticks and WASD exercise the wiring in a running fight.
	if _record:
		var event := InputEventKey.new()
		event.physical_keycode = KEY_D
		event.pressed = true
		root.push_input(event, true)
		_check(scene.battle_started, "recorded fight starts from actual viewport input")
		await _wait(12.0)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/survive_audio_battle.png")
	for zombie: HordeAgent in scene.horde.agents.duplicate():
		zombie.health.take_damage(100)
	_check(scene.battle_over and _all_stopped(scene.battle_audio, true), "defeat stops gameplay voices")
	_check(scene.battle_audio.result.playing and scene.battle_audio.result.stream == BattleAudio.DEFEAT, "defeat has a different ending cue")
	await _wait(1.3)
	_check(_all_stopped(scene.battle_audio), "ending cues finish without looping")
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


func _all_stopped(sounds: BattleAudio, except_result: bool = false, except_music: bool = false) -> bool:
	for player: AudioStreamPlayer in sounds.get_children():
		if except_result and player == sounds.result:
			continue
		if except_music and player == sounds.music:
			continue
		if player.playing:
			return false
	return true


func _wait(seconds: float) -> void:
	# Run without --fixed-fps: the audio mixer advances in wall-clock time.
	await create_timer(seconds, true, false, true).timeout


func _wait_for_quiet(sounds: BattleAudio) -> void:
	# Render stalls can make a wall-clock timer outpace simulation cooldowns.
	var deadline: int = Time.get_ticks_msec() + 5000
	while not _all_stopped(sounds, false, true) or sounds._voice_cooldown > 0.0 or sounds._bite_cooldown > 0.0:
		if Time.get_ticks_msec() >= deadline:
			_check(false, "one-shot audio and cooldowns settle within five seconds")
			return
		await _wait(0.05)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failures += 1
