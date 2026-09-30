extends SceneTree

const MAIN: PackedScene = preload("res://scenes/main.tscn")
var _failures: int = 0
var _frame: int = 0
var _caption: Label


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(960, 600)
	var scene: Node3D = MAIN.instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.horde.set_physics_process(false)
	scene.hud.hide()
	scene.survivor.hide()
	scene.get_node("Reinforcements").hide()
	var agent: HordeAgent = scene.horde.agents[0]
	for other: HordeAgent in scene.horde.agents:
		other.visible = other == agent
	agent.position = Vector3.ZERO
	agent.visual.rotation.y = 0.0
	var camera: Camera3D = scene.get_node("Camera")
	camera.position = Vector3(3.2, 2.5, -5)
	camera.look_at(Vector3(0, 0.7, 0))
	camera.size = 3.3
	var layer := CanvasLayer.new()
	root.add_child(layer)
	_caption = Label.new()
	_caption.position = Vector2(24, 24)
	_caption.add_theme_font_size_override(&"font_size", 22)
	layer.add_child(_caption)
	if "--capture" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("/tmp/survive_zombie_frames")
	_caption.text = "Zombie / idle"
	await _frames(45)
	var visual: ZombieVisual = agent.visual
	var original_root: Transform3D = agent.transform
	_caption.text = "Run / weight shift and stride"
	visual.move(Vector3.FORWARD * 3.6, 0.1, 3.6, 10.0, 0.15, 1.5)
	await _frames(60)
	var walk_lean: float = visual.rig.rotation.x
	_check(walk_lean < -0.08 and visual.animation_player.current_animation == &"run", "run visibly leans into movement")
	_caption.text = "Sprint / stronger lean and faster cadence"
	visual.move(Vector3.FORWARD * 7.2, 0.1, 3.6, 10.0, 0.15, 1.5)
	await _frames(55)
	_check(visual.rig.rotation.x < walk_lean - 0.07, "sprint has a distinct stronger lean")
	_check(visual.animation_player.speed_scale > 2.0, "sprint accelerates gait cadence")
	_caption.text = "Turn / body banks into direction"
	visual.move(Vector3.RIGHT * 3.6, 0.03, 3.6, 10.0, 0.15, 1.5)
	await _frames(20)
	_check(absf(visual.rig.rotation.z) > 0.05, "turning banks the rig while gameplay remains planar")
	_caption.text = "Stop / settle back to idle"
	visual.stop()
	await _frames(45)
	_check(visual.rig.rotation.length() < 0.01, "idle settles without residual lean")
	_check(agent.transform == original_root, "animation never changes the agent's gameplay transform")
	visual.rotation.y = 0.0
	var head: int = visual.skeleton.find_bone("Head")
	var idle_head: Vector3 = visual.skeleton.get_bone_global_pose(head).origin
	_caption.text = "Bite / contact, recoil, settle"
	visual.bite(Vector3.FORWARD)
	await _frames(5)
	visual.skeleton.force_update_all_bone_transforms()
	_check(visual.skeleton.get_bone_global_pose(head).origin.distance_to(idle_head) > 0.10, "bite moves the head and torso into contact")
	await _frames(30)
	_check(visual.animation_player.current_animation == &"idle", "bite completes and returns to idle")
	_caption.text = "Hit / brief flash and recoil"
	visual.hit()
	await _frames(4)
	_check(visual.rig.rotation.x > 0.04, "damage creates readable recoil")
	await _frames(25)
	_check(visual.body.material_overlay == null and visual.rig.rotation.length() < 0.01, "hit reaction settles and flash clears")
	_caption.text = "Pause / poses and reactions freeze"
	visual.hit()
	paused = true
	var pose: Transform3D = visual.rig.transform
	var playback: float = visual.animation_player.current_animation_position
	await _frames(15)
	_check(visual.rig.transform == pose and visual.animation_player.current_animation_position == playback, "pause freezes animation and recoil")
	paused = false
	await _frames(20)
	_caption.text = "Combat death / fall, impact, clear"
	agent.health.take_damage(100)
	_check(not scene.horde.agents.has(agent), "death removes gameplay entity before its visual fall")
	await _frames(12)
	_check(is_instance_valid(agent) and absf(visual.rig.rotation.z) > 0.5, "combat death visibly falls before cleanup")
	await _frames(35)
	_check(not is_instance_valid(agent), "death feedback frees the agent")
	# Fresh actor lets expiry be compared with the more forceful combat death.
	scene.horde._spawn_agent(Vector3.ZERO, HordeAgent.Kind.TEMPORARY)
	agent = scene.horde.agents.back()
	agent.visual.rotation.y = 0.0
	_caption.text = "Temporary expiry / deflate and disappear"
	await _frames(30)
	agent.lifetime_remaining = 0.01
	agent.update_lifetime(0.02)
	_check(agent.expired and agent.visual.body.material_overlay == null, "expiry does not masquerade as a damage flash")
	await _frames(40)
	_check(not is_instance_valid(agent), "expired visual also cleans up")
	print("Zombie animation smoke: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)


func _frames(count: int) -> void:
	for index: int in range(count):
		await physics_frame
		_frame += 1
		if "--capture" in OS.get_cmdline_user_args() and _frame % 3 == 0:
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/survive_zombie_frames/frame_%04d.png" % (_frame / 3 - 1))


func _check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		_failures += 1
