extends SceneTree

var _failures: int = 0
var _arena: Node3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	_arena = load("res://scenes/main.tscn").instantiate()
	root.add_child(_arena)
	current_scene = _arena
	_arena.set_physics_process(false)
	_arena.horde.set_physics_process(false)
	var horde: HordeController = _arena.horde
	horde.recruit(12, Vector3.ZERO)
	var permanent: HordeAgent = horde.agents[0]
	var temporary: HordeAgent = horde.agents.back()
	var skin: int = _surface(permanent.visual.body, "Olive skin")
	var original: Material = permanent.visual.body.mesh.surface_get_material(skin)
	var recruited: Material = temporary.visual.body.get_surface_override_material(skin)
	_check(recruited != null and recruited != original, "recruits have a distinct skin without modifying imported materials")
	_check(permanent.visual.body.get_active_material(skin) == original, "permanent skin stays original after recruits spawn")
	_check(temporary.visual.recruit_mantle != null and permanent.visual.recruit_mantle == null, "only recruits have the ragged silhouette")
	_check(permanent.kind_marker.mesh != temporary.kind_marker.mesh, "solid and broken rings differ by shape")
	_check(horde.agents[40].visual.body.get_active_material(skin) == recruited, "recruits share their immutable appearance materials")
	var ring: Mesh = temporary.kind_marker.mesh
	for color: Color in [Color("ef9b53"), Color("c894e8"), Color("72dbe6")]:
		permanent.set_ability_color(color)
		temporary.set_ability_color(color)
		_check(temporary.kind_marker.mesh == ring and temporary.visual.body.get_active_material(skin) == recruited,
			"ability colors preserve body and ring-shape identity")
	permanent.set_ability_color(Color.TRANSPARENT)
	temporary.set_ability_color(Color.TRANSPARENT)
	_check(temporary.kind_marker.material_override.albedo_color == ZombieKindMarker.TEMPORARY_COLOR, "ability cleanup restores the correct kind color")
	temporary.visual.hit()
	await _frames(15)
	_check(temporary.visual.body.material_overlay == null and temporary.visual.body.get_active_material(skin) == recruited, "hit flash restores the recruit appearance")
	horde.add_permanent_reward(10)
	_check(horde.agents.back().visual.recruit_mantle == null and horde.agents.back().visual.body.get_active_material(skin) == original,
		"permanent rewards do not inherit a recruit's shared material overrides")
	for index: int in range(horde.agents.size()):
		var agent: HordeAgent = horde.agents[index]
		agent.position = Vector3(-4 + index % 10, 0, -3 + index / 10)
		agent.visual.rotation.y = 0.4
	# Interleave recruits into the main mass instead of hiding them in a last row.
	for index: int in range(12):
		var target: HordeAgent = horde.agents[index * 3]
		var recruit: HordeAgent = horde.agents[40 + index]
		var position: Vector3 = target.position
		target.position = recruit.position
		recruit.position = position
	_arena._update_status()
	await _frames(5)
	await _capture("crowd")
	root.size = Vector2i(960, 600)
	await _frames(3)
	await _capture("small")
	root.size = Vector2i(1280, 800)
	await _frames(3)
	# Side-by-side close-up, keeping both the back cloth and face readable.
	for agent: HordeAgent in horde.agents:
		agent.visible = agent == permanent or agent == temporary
	permanent.position = Vector3(-0.9, 0, 0)
	temporary.position = Vector3(0.9, 0, 0)
	permanent.visual.rotation.y = -0.7
	temporary.visual.rotation.y = -0.7
	var camera: Camera3D = _arena.get_node("Camera")
	camera.set_process(false)
	camera.position = Vector3(0, 3.8, 6)
	camera.look_at(Vector3(0, 0.65, 0))
	camera.size = 4.5
	_arena.hud.hide()
	await _frames(3)
	await _capture("pair")
	permanent.visual.rotation.y = 2.5
	temporary.visual.rotation.y = 2.5
	await _frames(3)
	await _capture("front")
	permanent.set_ability_color(Color("ef9b53"))
	temporary.set_ability_color(Color("ef9b53"))
	await _capture("ability")
	temporary.visual.bite(Vector3(0.4, 0, 1))
	await _frames(6)
	await _capture("bite")
	paused = true
	var pose: Transform3D = temporary.visual.recruit_mantle.global_transform
	await _frames(6)
	_check(temporary.visual.recruit_mantle.global_transform == pose, "attached mantle pauses with the animated character")
	paused = false
	var expired_ref: WeakRef = weakref(temporary.visual.recruit_mantle)
	temporary.lifetime_remaining = 0.01
	temporary.update_lifetime(0.02)
	_check(not temporary.kind_marker.visible and not horde.agents.has(temporary), "expiry hides identity marker and removes the recruit normally")
	await _frames(45)
	_check(expired_ref.get_ref() == null, "expiry frees the attached cloth with the zombie")
	_arena.battle_audio.stop_all()
	_arena.queue_free()
	await _frames(4)
	print("Zombie identity smoke: ", "PASS" if _failures == 0 else "FAIL")
	quit(0 if _failures == 0 else 1)


func _surface(body: MeshInstance3D, name: String) -> int:
	for index: int in range(body.mesh.get_surface_count()):
		if body.mesh.surface_get_material(index).resource_name == name:
			return index
	return -1


func _frames(count: int) -> void:
	for frame: int in range(count):
		await process_frame


func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/survive_identity_%s.png" % label)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failures += 1
