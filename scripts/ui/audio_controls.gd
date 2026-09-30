class_name AudioControls
extends VBoxContainer

@onready var music_slider: HSlider = %MusicSlider
@onready var effects_slider: HSlider = %EffectsSlider
@onready var preview: AudioStreamPlayer = $Preview


func _ready() -> void:
	refresh()
	music_slider.value_changed.connect(_on_music_changed)
	effects_slider.value_changed.connect(_on_effects_changed)
	visibility_changed.connect(_on_visibility_changed)


func refresh() -> void:
	_sync_slider(music_slider, %MusicValue, &"Music")
	_sync_slider(effects_slider, %EffectsValue, &"Effects")


func stop_preview() -> void:
	preview.stop()


func _exit_tree() -> void:
	stop_preview()


func _sync_slider(slider: HSlider, label: Label, bus_name: StringName) -> void:
	var bus: int = AudioServer.get_bus_index(bus_name)
	var value: float = 0.0 if AudioServer.is_bus_mute(bus) else AudioServer.get_bus_volume_linear(bus) * 100.0
	slider.set_value_no_signal(roundf(value))
	label.text = "%d%%" % roundi(value)


func _set_volume(bus_name: StringName, value: float, label: Label) -> void:
	var bus: int = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_linear(bus, maxf(value / 100.0, 0.0001))
	AudioServer.set_bus_mute(bus, value <= 0.0)
	label.text = "%d%%" % roundi(value)


func _on_music_changed(value: float) -> void:
	_set_volume(&"Music", value, %MusicValue)


func _on_effects_changed(value: float) -> void:
	_set_volume(&"Effects", value, %EffectsValue)
	if is_visible_in_tree() and not preview.playing:
		preview.play()


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		refresh()
	else:
		stop_preview()
