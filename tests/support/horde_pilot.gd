extends RefCounted

var _held: Array[Key] = []


func move(viewport: Viewport, direction: Vector2) -> void:
	var wanted: Array[Key] = []
	if direction.x < 0.0:
		wanted.append(KEY_A)
	elif direction.x > 0.0:
		wanted.append(KEY_D)
	if direction.y < 0.0:
		wanted.append(KEY_W)
	elif direction.y > 0.0:
		wanted.append(KEY_S)
	for code: Key in _held:
		if code not in wanted:
			key(viewport, code, false)
	for code: Key in wanted:
		if code not in _held:
			key(viewport, code, true)
	_held = wanted


func steer(viewport: Viewport, horde: HordeController, target: Vector3, deadzone: float = 0.6) -> void:
	var offset: Vector3 = target - center(horde)
	move(viewport, Vector2(signf(offset.x) if absf(offset.x) > deadzone else 0.0,
		signf(offset.z) if absf(offset.z) > deadzone else 0.0))


func center(horde: HordeController) -> Vector3:
	var position := Vector3.ZERO
	for agent: HordeAgent in horde.agents:
		position += agent.global_position
	return position / maxf(1.0, horde.agents.size())


func key(viewport: Viewport, code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	viewport.push_input(event, true)
