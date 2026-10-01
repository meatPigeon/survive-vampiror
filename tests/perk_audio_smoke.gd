extends SceneTree

var _failures: int = 0
var _arena: Node3D
var _impacts: int = 0
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
	_fixture()
	var horde: HordeController = _arena.horde
	var sounds: BattleAudio = _arena.battle_audio
	horde.grant_ability(HordeAbility.Upgrade.DETONATION)
	horde.grant_ability(HordeAbility.Upgrade.SLING)
	var mines: HordeAbility = horde.abilities[0]
	var sling: HordeAbility = horde.abilities[1]
	mines.impacted.connect(func(_kind: int) -> void: _impacts += 1)
	sling.impacted.connect(func(_kind: int) -> void: _impacts += 1)
	for stream: AudioStream in BattleAudio.PERK_CASTS.values() + BattleAudio.PERK_IMPACTS.values() + [BattleAudio.FEAST_END]:
		_check(stream.get_length() > 0.2 and stream.get_length() < 1.0 and (stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_DISABLED, "perk assets are finite short one-shots")
	for player: AudioStreamPlayer in [sounds.perk_cast, sounds.perk_impact]:
		_check(player.bus == &"Effects" and player.max_polyphony == 1 and not player.autoplay, "perk voices share effect volume and have bounded playback")
	_key(KEY_Q)
	_check(not sounds.perk_cast.playing, "ability before battle is silent")
	_start()
	await _wait(1.3)
	_key(KEY_Q)
	_check(sounds.perk_cast.playing and sounds.perk_cast.stream == BattleAudio.PERK_CASTS[HordeAbility.Upgrade.DETONATION], "accepted mine placement plays arming cue")
	var playback: AudioStreamPlayback = sounds.perk_cast.get_stream_playback()
	_key(KEY_Q)
	_check(sounds.perk_cast.get_stream_playback() == playback, "cooldown rejection cannot restart the cue")
	_arena.toggle_pause()
	await _wait(0.15)
	_check(sounds.perk_cast.stream_paused, "pause freezes a perk cue")
	mines.tick(3.0)
	_check(_impacts == 0, "pause produces no late explosion")
	_arena.toggle_pause()
	await _wait(0.8)
	mines.tick(1.9)
	_check(not sounds.perk_impact.playing, "no blast before the fuse")
	mines.tick(0.11)
	_check(_impacts == 1 and sounds.perk_impact.playing and sounds.perk_impact.stream == BattleAudio.PERK_IMPACTS[HordeAbility.Upgrade.DETONATION], "whole batch produces one explosion at resolution")
	await _capture("mines")
	await _wait(1.0)
	mines.tick(8.0)
	_key(KEY_Q)
	for agent: HordeAgent in mines.armed.duplicate():
		agent.health.take_damage(100)
	await _wait(0.8)
	mines.tick(3.0)
	_check(_impacts == 1 and not sounds.perk_impact.playing, "mines killed before detonation make no phantom blast")

	_key(KEY_E)
	_check(not sounds.perk_cast.playing, "sling without ammo is silent")
	horde.recruit(3, Vector3(-4, 0, 0))
	await _wait(1.1)
	_key(KEY_E)
	sling.update_aim(Vector3(100, 0, 100), true)
	sling.fire_sling()
	_check(not sounds.perk_cast.playing, "aim and invalid shots do not play a launch")
	_key(KEY_E)
	_check(not sounds.perk_cast.playing and not sling.aiming, "cancelling aim is silent")
	sling.sling_spread = 0.0
	_key(KEY_E)
	sling.update_aim(_arena.survivor.position, true)
	sling.fire_sling()
	_check(sounds.perk_cast.stream == BattleAudio.PERK_CASTS[HordeAbility.Upgrade.SLING] and sounds.perk_cast.playing, "actual shot plays launch on the second ability slot")
	playback = sounds.perk_cast.get_stream_playback()
	sling.fire_sling()
	_check(sounds.perk_cast.get_stream_playback() == playback, "repeated fire does not restart launch")
	sling.tick(0.4)
	await _capture("sling")
	await _wait(0.8)
	sling.tick(0.4)
	_check(_impacts == 2 and sounds.perk_impact.stream == BattleAudio.PERK_IMPACTS[HordeAbility.Upgrade.SLING] and sounds.perk_impact.playing, "landing plays its thud after flight")
	await _wait(0.9)
	sling.tick(3.0)
	_key(KEY_E)
	sling.update_aim(Vector3(-5, 0, -8), true)
	sling.fire_sling()
	await _wait(0.8)
	var hp: int = _arena.survivor.health.current_health
	sling.tick(0.8)
	_check(_impacts == 3 and sounds.perk_impact.playing and hp == _arena.survivor.health.current_health, "ground miss still lands audibly without damage")
	await _wait(0.9)
	sling.tick(3.0)
	_key(KEY_E)
	sling.update_aim(Vector3(-5, 0, -8), true)
	sling.fire_sling()
	sling.projectile.update_lifetime(100.0)
	await _wait(0.8)
	sling.tick(1.0)
	_check(_impacts == 3 and not sounds.perk_impact.playing, "expired projectile makes no phantom landing")
	playback = null
	await _dispose()

	_fixture()
	horde = _arena.horde
	sounds = _arena.battle_audio
	horde.grant_ability(HordeAbility.Upgrade.FEAST)
	var feast: HordeAbility = horde.ability
	_start()
	await _wait(1.3)
	_key(KEY_Q)
	_check(sounds.perk_cast.playing and sounds.perk_cast.stream == BattleAudio.PERK_CASTS[HordeAbility.Upgrade.FEAST], "feast activation plays its own cue")
	await _capture("feast")
	await _wait(0.9)
	feast.tick(4.9)
	_check(not sounds.perk_cast.playing, "feast does not loop or end prematurely")
	feast.tick(0.11)
	_check(sounds.perk_cast.stream == BattleAudio.FEAST_END and sounds.perk_cast.playing, "natural feast expiry gives a quiet end cue")
	playback = sounds.perk_cast.get_stream_playback()
	feast.tick(1.0)
	_check(sounds.perk_cast.get_stream_playback() == playback, "feast expiry plays once")
	await _wait(0.6)
	feast.tick(15.0)
	_key(KEY_Q)
	_arena.survivor.health.take_damage(10000)
	_check(_arena.between_waves and not sounds.perk_cast.playing and not sounds.perk_impact.playing, "reward break stops perk voices")
	feast.activated.emit(feast.upgrade)
	_check(not sounds.perk_cast.playing, "late events cannot sound during a wave break")
	_arena.skip_reward()
	_arena._physics_process(_arena.wave_break_duration)
	horde.set_physics_process(false)
	feast.tick(5.1)
	_check(sounds.perk_cast.stream == BattleAudio.FEAST_END and sounds.perk_cast.playing, "preserved feast can finish audibly after the next wave starts")
	_arena.wave_count = _arena.wave_index
	_arena.survivor.health.take_damage(10000)
	_check(_arena.battle_over and not sounds.perk_cast.playing and not sounds.perk_impact.playing, "terminal outcome stops perk sounds immediately")
	feast.activated.emit(feast.upgrade)
	feast.feast_ended.emit()
	_check(not sounds.perk_cast.playing, "cancelled or late abilities cannot sound after the outcome")
	playback = null
	var old_audio: WeakRef = weakref(sounds)
	_arena.restart()
	await _wait(0.25)
	_arena = current_scene
	_check(old_audio.get_ref() == null and not _arena.battle_audio.perk_cast.playing and not _arena.battle_audio.perk_impact.playing, "restart frees old perk voices and begins silent")
	await _dispose()
	if _record:
		recorder.set_recording_active(false)
		recorder.get_recording().save_to_wav("/tmp/survive_perk_audio_check.wav")
		AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
		recorder = null
	print("Perk audio smoke: ", "PASS" if _failures == 0 else "FAIL")
	quit(0 if _failures == 0 else 1)


func _fixture() -> void:
	_arena = load("res://scenes/main.tscn").instantiate()
	_arena.get_node("Horde").agent_count = 12
	root.add_child(_arena)
	current_scene = _arena
	_arena.set_physics_process(false)
	_arena.horde.set_physics_process(false)


func _start() -> void:
	_key(KEY_W)
	_arena.horde.command_direction(Vector3.ZERO)


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventKey
	event.pressed = false
	root.push_input(event, true)


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _capture(label: String) -> void:
	if _record:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/survive_perk_audio_%s.png" % label)


func _dispose() -> void:
	_arena.battle_audio.stop_all()
	_arena.queue_free()
	await _wait(0.15)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failures += 1
