extends SceneTree

const KNIGHT: PackedScene = preload("res://scenes/components/survivor.tscn")
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var knight: Survivor = KNIGHT.instantiate()
	root.add_child(knight)
	for kind: Survivor.Attack in [Survivor.Attack.SWEEP, Survivor.Attack.CHARGE, Survivor.Attack.SPIN]:
		knight.position = Vector3.ZERO
		knight._begin_attack(kind, Vector3(0, 0, -4))
		var visual: KnightVisual = knight.visual
		var animator: AnimationPlayer = visual.animation_player
		var animation: StringName = animator.current_animation
		var root_transform: Transform3D = knight.transform
		var facing: float = visual.rotation.y
		var windup: float = knight.current_windup()
		var duration: float = knight.current_strike()
		animator.play(animation, 0.0)
		animator.seek(windup - 0.12, true)
		visual.skeleton.force_update_all_bone_transforms()
		var hand_index: int = visual.skeleton.find_bone("Hand.R")
		var loaded_hand: Vector3 = visual.skeleton.get_bone_global_pose(hand_index).origin
		knight.update_combat([], windup + 0.001)
		visual.skeleton.force_update_all_bone_transforms()
		_check(knight.state == Survivor.State.STRIKE, "attack enters strike")
		_check(is_equal_approx(animator.current_animation_position, windup), "impact pose is synchronized with damage")
		var hand_travel: float = loaded_hand.distance_to(visual.skeleton.get_bone_global_pose(hand_index).origin)
		_check(hand_travel > (0.05 if kind == Survivor.Attack.CHARGE else 0.5), "anticipation releases into a distinct impact pose")
		_check(knight.transform == root_transform, "windup and pose do not move gameplay root")
		visual.flash()
		_check(animator.current_animation == animation, "hit reaction preserves the attack")
		knight.update_combat([], duration * 0.5)
		_check(animator.current_animation == animation, "strike never changes to idle or ordinary running")
		_check(is_equal_approx(visual.rotation.y, facing), "strike preserves the locked facing")
		knight.update_combat([], duration * 0.5 + 0.001)
		_check(knight.state == Survivor.State.RECOVERY, "attack enters recovery")
		_check(animator.current_animation == animation, "recovery keeps authored follow-through")
		_check(is_equal_approx(animator.current_animation_position, windup + duration), "recovery synchronizes to its authored pose")
		animator.seek(windup + duration + knight.current_recovery(), true)
		_check(visual.rig.position.length() < 0.001 and visual.rig.quaternion.angle_to(Quaternion.IDENTITY) < 0.001,
			"attack settles the visual rig back to rest")
		for bone: int in range(visual.skeleton.get_bone_count()):
			_check(visual.skeleton.get_bone_global_pose(bone).is_finite(), "finite authored bone transforms")
	knight._begin_attack(Survivor.Attack.SWEEP, knight.position + Vector3.FORWARD)
	await process_frame
	paused = true
	var frozen_time: float = knight.animation_player.current_animation_position
	for frame: int in range(8):
		await process_frame
	_check(is_equal_approx(knight.animation_player.current_animation_position, frozen_time), "tree pause freezes the clip")
	paused = false
	knight.health.take_damage(knight.health.max_health)
	var death_root: Transform3D = knight.transform
	for frame: int in range(45):
		await process_frame
	_check(knight.transform == death_root, "death leaves the gameplay root unchanged")
	_check(knight.visual.rig.rotation.z > 1.3 and not knight.animation_player.is_playing(), "death completes a visible fall")
	knight.queue_free()
	await process_frame
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await _capture_poses()
	print("Knight animation smoke: ", "PASS" if _failures == 0 else "FAIL")
	quit(0 if _failures == 0 else 1)


func _capture_poses() -> void:
	root.size = Vector2i(1200, 700)
	root.msaa_3d = Viewport.MSAA_4X
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.16, 0.19, 0.21)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.88, 0.91, 1.0)
	environment.environment.ambient_light_energy = 0.65
	stage.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -140, 0)
	light.light_energy = 1.1
	light.shadow_enabled = true
	stage.add_child(light)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.23, 0.27, 0.29)
	material.roughness = 1.0
	plane.material = material
	floor.mesh = plane
	floor.position.y = -0.015
	stage.add_child(floor)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 7.0
	stage.add_child(camera)
	camera.position = Vector3(1.5, 3.2, -9)
	camera.look_at(Vector3(0, 0.75, 0))
	for kind: Survivor.Attack in [Survivor.Attack.SWEEP, Survivor.Attack.CHARGE, Survivor.Attack.SPIN]:
		var knights: Array[Survivor] = []
		for column: int in range(3):
			var knight: Survivor = KNIGHT.instantiate()
			stage.add_child(knight)
			knight.position.x = float(1 - column) * 2.5
			knight._begin_attack(kind, knight.position + Vector3.FORWARD * 4.0)
			knight.attack_area.hide()
			knight.animation_player.play(knight.animation_player.current_animation, 0.0)
			var sample: float = [knight.current_windup() - 0.12, knight.current_windup(), knight.current_windup() + knight.current_strike()][column]
			knight.animation_player.seek(sample, true)
			knight.animation_player.pause()
			knights.append(knight)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/survive_knight_%s.png" % Survivor.Attack.keys()[kind].to_lower())
		for knight: Survivor in knights:
			knight.queue_free()
		await process_frame
	if "--motion" in OS.get_cmdline_user_args():
		await _capture_motion(stage)


func _capture_motion(stage: Node3D) -> void:
	var knights: Array[Survivor] = []
	for kind: Survivor.Attack in [Survivor.Attack.SWEEP, Survivor.Attack.CHARGE, Survivor.Attack.SPIN]:
		var knight: Survivor = KNIGHT.instantiate()
		stage.add_child(knight)
		knight.position.x = float(1 - kind) * 2.5
		knight._begin_attack(kind, knight.position + Vector3.FORWARD * 4.0)
		knight.attack_area.hide()
		knight.animation_player.play(knight.animation_player.current_animation, 0.0)
		knight.animation_player.pause()
		knights.append(knight)
	DirAccess.make_dir_recursive_absolute("/tmp/survive_knight_motion")
	for frame: int in range(150):
		for knight: Survivor in knights:
			var length: float = knight.current_windup() + knight.current_strike() + knight.current_recovery()
			knight.animation_player.seek(minf(float(frame) / 30.0, length), true)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/survive_knight_motion/%03d.png" % frame)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failures += 1
