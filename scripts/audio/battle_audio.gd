class_name BattleAudio
extends Node

const WARNINGS: Array[AudioStream] = [
	preload("res://assets/audio/warning_sweep.wav"),
	preload("res://assets/audio/warning_charge.wav"),
	preload("res://assets/audio/warning_spin.wav"),
]
const COMMAND: AudioStream = preload("res://assets/audio/command.wav")
const SPRINT: AudioStream = preload("res://assets/audio/sprint.wav")
const RECRUITED: AudioStream = preload("res://assets/audio/recruited.wav")
const EXPIRED: AudioStream = preload("res://assets/audio/expired.wav")
const VICTORY: AudioStream = preload("res://assets/audio/victory.wav")
const DEFEAT: AudioStream = preload("res://assets/audio/defeat.wav")

@export var voice_interval: float = 0.9
@export var bite_interval: float = 0.35
@export var step_distance: float = 0.85
@export var command_interval: float = 0.12

var _enabled: bool = true
var _hit_heard: bool = false
var _voice_cooldown: float = 0.0
var _bite_cooldown: float = 0.0
var _command_cooldown: float = 0.0
var _step_travel: float = 0.0
var _knight_hp: int
var _casualties: int
var _recruited: int
var _expired: int
var _horde: HordeController
var _random := RandomNumberGenerator.new()

@onready var warning: AudioStreamPlayer = $Warning
@onready var swish: AudioStreamPlayer = $Swish
@onready var impact: AudioStreamPlayer = $Impact
@onready var voice: AudioStreamPlayer = $Voice
@onready var grave_rise: AudioStreamPlayer = $GraveRise
@onready var grave_sink: AudioStreamPlayer = $GraveSink
@onready var footsteps: AudioStreamPlayer = $Footsteps
@onready var bite: AudioStreamPlayer = $Bite
@onready var command: AudioStreamPlayer = $Command
@onready var notice: AudioStreamPlayer = $Notice
@onready var result: AudioStreamPlayer = $Result


func setup(knight: Survivor, horde: HordeController, sites: Node3D) -> void:
	_random.randomize()
	_horde = horde
	_knight_hp = knight.health.current_health
	_casualties = horde.casualties
	_recruited = horde.recruited
	_expired = horde.expired_count
	knight.attack_warned.connect(_on_attack_warned)
	knight.attack_struck.connect(_on_attack_struck)
	knight.attack_hit.connect(_on_attack_hit)
	knight.health.changed.connect(_on_knight_health_changed)
	horde.count_changed.connect(_on_horde_count_changed)
	horde.move_commanded.connect(_on_move_commanded)
	horde.sprint_started.connect(_on_sprint_started)
	horde.moved.connect(_on_horde_moved)
	for site: ReinforcementSite in sites.get_children():
		site.visual.availability_changed.connect(_on_grave_availability_changed)


func _process(delta: float) -> void:
	_voice_cooldown = maxf(0.0, _voice_cooldown - delta)
	_bite_cooldown = maxf(0.0, _bite_cooldown - delta)
	_command_cooldown = maxf(0.0, _command_cooldown - delta)


func _on_move_commanded() -> void:
	if not _enabled or not can_process() or _command_cooldown > 0.0:
		return
	if command.playing and command.stream == SPRINT:
		return
	command.stream = COMMAND
	command.play()
	_command_cooldown = command_interval


func _on_sprint_started() -> void:
	if not _enabled or not can_process():
		return
	command.stream = SPRINT
	command.play()


func _on_horde_moved(distance: float) -> void:
	if not _enabled or not can_process():
		return
	if distance < 0.001:
		_step_travel = 0.0
		return
	# One shared shuffle follows actual distance, not one player per zombie.
	_step_travel = minf(_step_travel + distance, step_distance)
	if _step_travel >= step_distance and not footsteps.playing:
		_step_travel = 0.0
		footsteps.pitch_scale = _random.randf_range(0.9, 1.15)
		footsteps.play()


func _on_attack_warned(kind: Survivor.Attack) -> void:
	if not _enabled or not can_process():
		return
	_hit_heard = false
	warning.stream = WARNINGS[kind]
	warning.play()


func _on_attack_struck(kind: Survivor.Attack) -> void:
	if not _enabled or not can_process():
		return
	warning.stop()
	swish.pitch_scale = 0.75 if kind == Survivor.Attack.SPIN else 1.0
	swish.play()


func _on_attack_hit() -> void:
	if not _enabled or not can_process() or _hit_heard:
		return
	# One contact sound per attack, even when a charge crosses many zombies.
	_hit_heard = true
	impact.pitch_scale = _random.randf_range(0.92, 1.06)
	impact.play()


func _on_grave_availability_changed(available: bool) -> void:
	if not _enabled or not can_process():
		return
	# Separate opening/closing voices preserve both sounds during site rotation.
	if available:
		grave_rise.play()
	else:
		grave_sink.play()


func _on_knight_health_changed(current: int, _maximum: int) -> void:
	if current < _knight_hp:
		_play_voice(1.08)
		if _enabled and can_process() and _bite_cooldown <= 0.0 and not bite.playing:
			bite.pitch_scale = _random.randf_range(0.9, 1.12)
			bite.play()
			_bite_cooldown = bite_interval
	_knight_hp = current


func _on_horde_count_changed(_remaining: int) -> void:
	if _horde.casualties > _casualties:
		_play_voice(0.86)
	elif _horde.recruited > _recruited:
		_play_voice(1.0)
		_play_notice(RECRUITED)
	elif _horde.expired_count > _expired:
		_play_notice(EXPIRED)
	_casualties = _horde.casualties
	_recruited = _horde.recruited
	_expired = _horde.expired_count


func _play_notice(stream: AudioStream) -> void:
	if not _enabled or not can_process():
		return
	# Coalesce a simultaneous expiry batch; recruitment takes precedence.
	if stream == EXPIRED and notice.playing:
		return
	notice.stream = stream
	notice.play()


func _play_voice(pitch: float) -> void:
	if not _enabled or not can_process() or _voice_cooldown > 0.0 or voice.playing:
		return
	voice.pitch_scale = pitch * _random.randf_range(0.93, 1.07)
	voice.play()
	_voice_cooldown = voice_interval


func stop_all() -> void:
	_enabled = false
	for player: AudioStreamPlayer in get_children():
		player.stop()
	_voice_cooldown = 0.0
	_bite_cooldown = 0.0
	_command_cooldown = 0.0
	_step_travel = 0.0


func finish(won: bool) -> void:
	if not _enabled:
		return
	stop_all()
	result.stream = VICTORY if won else DEFEAT
	result.play()
