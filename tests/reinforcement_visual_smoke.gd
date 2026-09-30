extends SceneTree

const MAIN: PackedScene = preload("res://scenes/main.tscn")
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1200, 800)
	var scene: Node3D = _fixture()
	var west: ReinforcementSite = scene.get_node("Reinforcements/West")
	var south: ReinforcementSite = scene.get_node("Reinforcements/South")
	var root_transform: Transform3D = west.transform
	var grave: Node3D = west.visual.gravestones.get_child(0)
	var buried: Transform3D = grave.transform
	_check(west.visual.get_node("Crater").is_visible_in_tree() and _all_visible(west, false), "inactive crater remains but tombstones start hidden")
	await _capture("inactive")
	scene.horde.command_move(Vector3.ZERO)
	await _frames(10)
	_check(_all_visible(west, true) and grave.position.y > buried.origin.y, "opening raises tombstones from the ground")
	await _capture("rising")
	paused = true
	var frozen: Transform3D = grave.transform
	await _frames(12)
	_check(grave.transform == frozen, "pause freezes emergence")
	paused = false
	for frame: int in range(60):
		west._update_label()
		await physics_frame
	var risen: Transform3D = grave.transform
	await _frames(10)
	_check(grave.transform.is_equal_approx(risen) and risen.origin.y > buried.origin.y + 1.0, "repeated status updates allow emergence to settle")
	_check(west.transform == root_transform and west.remaining == 12, "visual motion preserves site root and reserves")
	await _capture("active")
	west.remaining = 4
	scene.elapsed = 90.0
	scene._update_site_schedule()
	await _frames(2)
	_check(west.remaining == 12 and grave.transform.is_equal_approx(risen), "skipped full cycle refills stock without restarting an available grave")
	scene.elapsed = 120.0
	scene._update_site_schedule()
	_check(not west.active and not west.label.visible and _all_visible(west, true), "deadline disables recruitment before sinking finishes")
	await _frames(14)
	_check(grave.position.y < risen.origin.y, "closed-window tombstones sink visibly")
	await _capture("sinking")
	paused = true
	frozen = grave.transform
	await _frames(12)
	_check(grave.transform == frozen, "pause freezes sinking")
	paused = false
	await _frames(45)
	_check(_all_visible(west, false) and west.visual.get_node("Crater").visible, "closing hides stones and preserves the crater")
	await _capture("closed")
	# A new opening must survive completion of an interrupted closing tween.
	south.set_active(false)
	await _frames(8)
	south.set_active(true)
	await _frames(55)
	_check(_all_visible(south, true), "reactivation cancels stale hide callbacks")
	scene.free()
	await process_frame
	scene = _fixture()
	west = scene.get_node("Reinforcements/West")
	scene.horde.agents[0].global_position = west.global_position
	scene.horde.command_move(west.global_position)
	west.update_recruitment(scene.horde, west.summon_time)
	_check(west.active and west.remaining == 0 and scene.horde.recruited == 12, "same-frame opening and exhaustion preserves actual recruitment")
	await _frames(55)
	_check(_all_visible(west, false), "immediate exhaustion cannot leave opening graves visible")
	west.set_active(true)
	scene.horde.recruit(8, Vector3.ZERO)
	west.update_recruitment(scene.horde, 3.0)
	await _frames(55)
	_check(west.remaining == 12 and _all_visible(west, true), "full crowd leaves unused graves available")
	west.set_active(false)
	await _frames(8)
	west.set_active(true)
	scene.survivor.health.take_damage(scene.survivor.health.current_health)
	await _frames(55)
	_check(scene.battle_over and west.remaining == 12 and _all_visible(west, true), "outcome lets visual motion settle without changing stock")
	west.set_active(false)
	var old_visual: WeakRef = weakref(west.visual)
	scene.restart()
	await _frames(5)
	west = current_scene.get_node("Reinforcements/West")
	_check(old_visual.get_ref() == null and _all_visible(west, false) and not west.active, "restart frees pending tweens and restores inactive graves")
	print("Reinforcement visual smoke: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)


func _fixture() -> Node3D:
	var scene: Node3D = MAIN.instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.set_physics_process(false)
	scene.horde.set_physics_process(false)
	scene.survivor.stop_combat()
	if "--capture" in OS.get_cmdline_user_args() and "--wide" not in OS.get_cmdline_user_args():
		var camera: Camera3D = scene.get_node("Camera")
		camera.set_script(null)
		var site: Node3D = scene.get_node("Reinforcements/West")
		camera.position = site.position + Vector3(0, 7.5, 8)
		camera.look_at(site.position + Vector3(0, 0.2, 0))
		camera.size = 8.0
		scene.get_node("HUD").hide()
	return scene


func _all_visible(site: ReinforcementSite, value: bool) -> bool:
	for grave: Node3D in site.visual.gravestones.get_children():
		if grave.visible != value:
			return false
	return true


func _frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame


func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var prefix: String = "survive_graves_wide" if "--wide" in OS.get_cmdline_user_args() else "survive_graves"
	root.get_texture().get_image().save_png("/tmp/%s_%s.png" % [prefix, label])


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failures += 1
