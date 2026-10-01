class_name UpgradeCard
extends Button

const ART: Dictionary[int, Texture2D] = {
	HordeAbility.Upgrade.DETONATION: preload("res://assets/ui/upgrades/mines.png"),
	HordeAbility.Upgrade.SLING: preload("res://assets/ui/upgrades/sling.png"),
	HordeAbility.Upgrade.FEAST: preload("res://assets/ui/upgrades/feast.png"),
	HordeAbility.Upgrade.SPRINT: preload("res://assets/ui/upgrades/sprint.png")
}
const ACCENTS: Dictionary[int, Color] = {
	HordeAbility.Upgrade.DETONATION: Color("e4ad72"),
	HordeAbility.Upgrade.SLING: Color("95ccd1"),
	HordeAbility.Upgrade.FEAST: Color("c8a4d8"),
	HordeAbility.Upgrade.SPRINT: Color("c5cf91")
}
const ROLES: Dictionary[int, String] = {
	HordeAbility.Upgrade.DETONATION: "SACRIFICE",
	HordeAbility.Upgrade.SLING: "ARTILLERY",
	HordeAbility.Upgrade.FEAST: "SUSTAIN",
	HordeAbility.Upgrade.SPRINT: "MOBILITY"
}
const COSTS: Dictionary[int, String] = {
	HordeAbility.Upgrade.DETONATION: "Spends half your horde",
	HordeAbility.Upgrade.SLING: "Uses temporary zombies",
	HordeAbility.Upgrade.FEAST: "Bite to recover health",
	HordeAbility.Upgrade.SPRINT: "Keeps Q / E slots free"
}

var _accent := Color.WHITE
var _motion: Tween
var _entrance: Tween


func _ready() -> void:
	resized.connect(func() -> void: pivot_offset = size * 0.5)
	toggled.connect(func(_selected: bool) -> void: _refresh())
	mouse_entered.connect(_refresh)
	mouse_exited.connect(_refresh)
	focus_entered.connect(_refresh)
	focus_exited.connect(_refresh)


func configure(upgrade: int, description: String) -> void:
	_accent = ACCENTS[upgrade]
	$Content/Title.text = HordeAbility.TITLES[upgrade]
	$Content/Description.text = description
	$Content/Art/Picture.texture = ART[upgrade]
	$Content/Art/Role.text = ROLES[upgrade]
	$Content/Art/Binding/Key.text = description.get_slice(" ", 0)
	$Content/Footer/Cost.text = COSTS[upgrade]
	$Accent.color = _accent
	var selected: StyleBoxFlat = get_theme_stylebox("pressed").duplicate()
	selected.border_color = _accent
	add_theme_stylebox_override("pressed", selected)
	add_theme_stylebox_override("hover_pressed", selected)
	tooltip_text = HordeAbility.TITLES[upgrade] + "\n" + description
	set_pressed_no_signal(false)
	_refresh()


func reveal(delay: float) -> void:
	if _entrance != null:
		_entrance.kill()
	modulate.a = 0.0
	_entrance = create_tween()
	_entrance.tween_interval(delay)
	_entrance.tween_property(self, "modulate:a", 1.0, 0.22)


func _refresh() -> void:
	if not is_node_ready():
		return
	$Content/Footer/Choice.text = "✓ SELECTED" if button_pressed else "SELECT"
	$Content/Footer/Choice.modulate = _accent if button_pressed else Color("b4baaa")
	var highlighted: bool = button_pressed or is_hovered() or has_focus()
	pivot_offset = size * 0.5
	if _motion != null:
		_motion.kill()
	_motion = create_tween().set_parallel(true)
	_motion.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_motion.tween_property(self, "scale", Vector2.ONE * (1.015 if highlighted else 1.0), 0.14)
	_motion.tween_property($Content/Art/Picture, "self_modulate", Color.WHITE if highlighted else Color(0.88, 0.88, 0.88), 0.14)
