class_name BattleAudio
extends Node

const WARNINGS: Array[AudioStream] = [
	preload("res://assets/audio/warning_sweep.wav"),
	preload("res://assets/audio/warning_charge.wav"),
	preload("res://assets/audio/warning_spin.wav"),
]

@export var voice_interval: float = 0.9

var _enabled: bool = true
var _hit_heard: bool = false
var _voice_cooldown: float = 0.0
var _knight_hp: int
var _casualties: int
var _recruited: int
var _horde: HordeController
var _random := RandomNumberGenerator.new()

@onready var warning: AudioStreamPlayer = $Warning
@onready var swish: AudioStreamPlayer = $Swish
@onready var impact: AudioStreamPlayer = $Impact
@onready var voice: AudioStreamPlayer = $Voice
@onready var grave_rise: AudioStreamPlayer = $GraveRise
@onready var grave_sink: AudioStreamPlayer = $GraveSink


func setup(knight: Survivor, horde: HordeController, sites: Node3D) -> void:
	_random.randomize()
	_horde = horde
	_knight_hp = knight.health.current_health
	_casualties = horde.casualties
	_recruited = horde.recruited
	knight.attack_warned.connect(_on_attack_warned)
	knight.attack_struck.connect(_on_attack_struck)
	knight.attack_hit.connect(_on_attack_hit)
	knight.health.changed.connect(_on_knight_health_changed)
	horde.count_changed.connect(_on_horde_count_changed)
	for site: ReinforcementSite in sites.get_children():
		site.visual.availability_changed.connect(_on_grave_availability_changed)


func _process(delta: float) -> void:
	_voice_cooldown = maxf(0.0, _voice_cooldown - delta)


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
	_knight_hp = current


func _on_horde_count_changed(_remaining: int) -> void:
	if _horde.casualties > _casualties:
		_play_voice(0.86)
	elif _horde.recruited > _recruited:
		_play_voice(1.0)
	_casualties = _horde.casualties
	_recruited = _horde.recruited


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
