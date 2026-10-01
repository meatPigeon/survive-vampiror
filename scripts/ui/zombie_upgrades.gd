class_name ZombieUpgrades
extends Control

signal chosen(index: int)
signal skipped()

var selected_index: int = -1
var _cleared_tween: Tween

@onready var cards: GridContainer = %Cards
@onready var selection_label: Label = %Selection
@onready var cleared_label: Label = %Heading


func _ready() -> void:
	cleared_label.resized.connect(func() -> void: cleared_label.pivot_offset = cleared_label.size * 0.5)
	var choices := ButtonGroup.new()
	for index: int in range(cards.get_child_count()):
		var card: UpgradeCard = cards.get_child(index)
		card.button_group = choices
		card.pressed.connect(_select.bind(index))
	%SkipButton.pressed.connect(func() -> void: skipped.emit())
	%StartButton.pressed.connect(_confirm)


func present(rewards: Array[int], descriptions: Array[String], next_wave: int) -> void:
	selected_index = -1
	selection_label.text = "Select your upgrade"
	%StartButton.disabled = true
	%Wave.text = "WAVE %d     /     NEXT: WAVE %d" % [next_wave - 1, next_wave]
	for index: int in range(cards.get_child_count()):
		var card: UpgradeCard = cards.get_child(index)
		card.configure(rewards[index], descriptions[index])
		card.reveal(index * 0.08)
	show()
	if _cleared_tween != null:
		_cleared_tween.kill()
	cleared_label.pivot_offset = cleared_label.size * 0.5
	cleared_label.scale = Vector2.ONE * 0.82
	cleared_label.modulate.a = 0.0
	# The HUD processes during pause; this announcement must still freeze.
	_cleared_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	_cleared_tween.tween_property(cleared_label, "modulate:a", 1.0, 0.2)
	_cleared_tween.parallel().tween_property(cleared_label, "scale", Vector2.ONE * 1.04, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_cleared_tween.tween_property(cleared_label, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	focus_choice()


func focus_choice() -> void:
	var focused_index: int = maxi(selected_index, 0)
	cards.get_child(focused_index).grab_focus()


func _select(index: int) -> void:
	selected_index = index
	selection_label.text = str(cards.get_child(index).get_node("Content/Title").text) + " selected"
	%StartButton.disabled = false


func _confirm() -> void:
	if selected_index >= 0:
		chosen.emit(selected_index)
