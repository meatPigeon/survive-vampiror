class_name MainMenu
extends Control

var normal_mode: bool = false

@onready var audio_controls: AudioControls = %AudioControls
@onready var music: AudioStreamPlayer = $Music


func _ready() -> void:
	%QuitButton.visible = not OS.has_feature("web")
	%PlayButton.pressed.connect(_play)
	%QuitButton.pressed.connect(_quit)
	%SettingsButton.toggled.connect(_toggle_audio)
	%NewbieButton.pressed.connect(_select_mode.bind(false))
	%NormalButton.pressed.connect(_select_mode.bind(true))
	_select_mode(normal_mode)
	%PlayButton.grab_focus()


func _select_mode(normal: bool) -> void:
	normal_mode = normal
	%NewbieButton.set_pressed_no_signal(not normal)
	%NormalButton.set_pressed_no_signal(normal)
	%ModeHint.text = "Every knight hit kills a zombie." if normal else "Reduced damage. Crossbow bolts still kill."


func _toggle_audio(open: bool) -> void:
	%Settings.visible = open
	%SettingsButton.text = "Close audio" if open else "Audio"
	if not open:
		%SettingsButton.grab_focus()


func _play() -> void:
	var arena: Node3D = load("res://scenes/main.tscn").instantiate()
	arena.normal_mode = normal_mode
	music.stop()
	audio_controls.stop_preview()
	get_tree().change_scene_to_node(arena)


func _quit() -> void:
	%PlayButton.disabled = true
	%QuitButton.disabled = true
	%SettingsButton.disabled = true
	%NewbieButton.disabled = true
	%NormalButton.disabled = true
	audio_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	audio_controls.music_slider.editable = false
	audio_controls.effects_slider.editable = false
	music.stop()
	audio_controls.stop_preview()
	# Let the audio mixer release stopped voices before the engine shuts down.
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()


func _exit_tree() -> void:
	music.stop()
