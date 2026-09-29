class_name Health
extends Node

signal changed(current: int, maximum: int)
signal died()

@export_range(1, 10000) var max_health: int = 20

var current_health: int


func _ready() -> void:
	current_health = max_health


func is_alive() -> bool:
	return current_health > 0


func take_damage(amount: int) -> void:
	if amount <= 0 or not is_alive():
		return
	current_health = maxi(0, current_health - amount)
	changed.emit(current_health, max_health)
	if current_health == 0:
		died.emit()
