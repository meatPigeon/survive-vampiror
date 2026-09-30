class_name MainMenu
extends Control

@onready var audio_controls: AudioControls = %AudioControls
@onready var music: AudioStreamPlayer = $Music


func _ready() -> void:
	%PlayButton.pressed.connect(_play)
	%QuitButton.pressed.connect(_quit)
	%PlayButton.grab_focus()


func _play() -> void:
	music.stop()
	audio_controls.stop_preview()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _quit() -> void:
	%PlayButton.disabled = true
	%QuitButton.disabled = true
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
