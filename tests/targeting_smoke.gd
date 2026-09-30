extends SceneTree

const MAIN: PackedScene = preload("res://scenes/main.tscn")
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	for charge: bool in [false, true]:
		var scene: Node3D = _fixture()
		var knight: Survivor = scene.get_node("Survivor")
		var horde: HordeController = scene.get_node("Horde")
		var origin: Vector3 = knight.global_position
		horde.agents[0].global_position = origin + Vector3.FORWARD * (3.0 if charge else 0.9)
		for index: int in range(1, 4):
			horde.agents[index].global_position = origin + Vector3((index - 2) * 0.35, 0, (3.0 + index) if charge else 1.5)
		# A larger unreachable group must not pull the aim away from a valid hit.
		for index: int in range(4, 15):
			horde.agents[index].global_position = origin + Vector3.RIGHT * (10.0 if charge else 4.0)
		knight.update_combat(horde.agents, 0.01)
		_check(knight.attack_kind == (Survivor.Attack.CHARGE if charge else Survivor.Attack.SWEEP), "attack selection is preserved")
		_check((-knight.attack_area.global_basis.z).dot(Vector3.BACK) > 0.85, "attack faces the larger reachable group, not the nearest singleton")
		_check((-knight.visual.global_basis.z.normalized()).dot(-knight.attack_area.global_basis.z) > 0.99, "knight and warning face the same direction")
		await _capture("charge" if charge else "sweep")
		knight.update_combat(horde.agents, knight.current_windup())
		if charge:
			# Complete the actual charge, including the zombies furthest along its lane.
			for step: int in range(60):
				knight.update_combat(horde.agents, knight.charge_duration / 60.0)
		_check(horde.agents[0].health.current_health == 30, "isolated zombie outside the selected shape is not hit")
		for index: int in range(1, 4):
			_check(horde.agents[index].health.current_health < 30, "chosen group is actually hit")
		scene.free()

	var scene: Node3D = _fixture()
	var knight: Survivor = scene.get_node("Survivor")
	var horde: HordeController = scene.get_node("Horde")
	horde.agents[0].global_position = knight.global_position + Vector3.FORWARD * 0.9
	for index: int in range(1, 5):
		var angle: float = deg_to_rad(-75.0 if index <= 2 else 75.0)
		horde.agents[index].global_position = knight.global_position + Vector3.BACK.rotated(Vector3.UP, angle) * (1.8 + 0.1 * (index % 2))
	knight.update_combat(horde.agents, 0.01)
	knight.update_combat(horde.agents, knight.windup_time)
	for index: int in range(1, 5):
		_check(horde.agents[index].health.current_health == 15, "sector can aim between two groups instead of only directly at a zombie")
	scene.free()

	scene = _fixture()
	knight = scene.get_node("Survivor")
	horde = scene.get_node("Horde")
	horde.agents[0].global_position = knight.global_position + Vector3.FORWARD
	for index: int in range(1, 4):
		horde.agents[index].global_position = knight.global_position + Vector3((index - 2) * 0.3, 0, 1.5)
	knight.update_combat(horde.agents, 0.01)
	var warning_basis: Basis = knight.attack_area.global_basis
	for index: int in range(1, 4):
		horde.agents[index].global_position = knight.global_position + Vector3((index - 2) * 0.3, 0, -1.5)
	knight.update_combat(horde.agents, knight.windup_time * 0.5)
	_check(knight.attack_area.global_basis == warning_basis, "warning does not follow the crowd during windup")
	knight.update_combat(horde.agents, knight.windup_time * 0.5)
	for index: int in range(4):
		_check(horde.agents[index].health.current_health == 30, "moving out of the locked sector still dodges damage")
	var corner: Vector2 = horde.movement_bounds.end
	knight.global_position = Vector3(corner.x - 2.0, 0, corner.y - 2.0)
	knight._begin_attack(Survivor.Attack.CHARGE, Vector3(corner.x + 1.0, 0, corner.y + 1.0))
	_check(horde.movement_bounds.has_point(Vector2(knight._charge_end.x, knight._charge_end.z)),
		"charge endpoint remains inside the actual arena corner")
	_check((-knight.visual.global_basis.z.normalized()).dot(-knight.attack_area.global_basis.z) > 0.99,
		"knight faces the actual lane after its endpoint is clamped at a corner")
	scene.free()
	print("Targeting smoke: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)


func _fixture() -> Node3D:
	var scene: Node3D = MAIN.instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	var horde: HordeController = scene.get_node("Horde")
	horde.set_physics_process(false)
	for agent: HordeAgent in horde.agents:
		agent.global_position = Vector3(-100, 0, -100)
	return scene


func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/survive_targeting_%s.png" % label)


func _check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		_failures += 1
