extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for character: String in ["zombie", "medieval_knight"]:
		var model: Node3D = load("res://assets/characters/" + character + ".glb").instantiate()
		root.add_child(model)
		var skeleton: Skeleton3D = model.find_child("Skeleton3D", true, false) as Skeleton3D
		var animator: AnimationPlayer = model.get_node("AnimationPlayer") as AnimationPlayer
		_check(skeleton != null, character + ": skeleton exists")
		_check(skeleton.get_bone_count() == 18, character + ": 18 deform bones")
		_check(skeleton.find_bone("FootIK.L") == -1, character + ": IK controls stay in Blender")
		var meshes: Array[Node] = model.find_children("*", "MeshInstance3D", true, false)
		_check(meshes.size() == 1, character + ": one joined mesh")
		var body: MeshInstance3D = meshes[0] as MeshInstance3D
		_check(body.skin != null and body.skin.get_bind_count() == 18, character + ": skin is bound")
		_check(animator.get_animation_list().size() == 2, character + ": only idle and run exported")
		for clip: String in ["idle", "run"]:
			_check(animator.has_animation(clip), character + ": " + clip + " exists")
			var animation: Animation = animator.get_animation(clip)
			_check(animation.loop_mode == Animation.LOOP_LINEAR, character + ": " + clip + " loops")
			var expected_duration: float = 2.0 if clip == "idle" else 0.8
			_check(absf(animation.length - expected_duration) < 0.001, character + ": clip duration")
			animator.play(clip)
			animator.pause()
			var first_pose: Array[Transform3D] = []
			var max_foot_motion: float = 0.0
			var max_head_motion: float = 0.0
			var foot: int = skeleton.find_bone("Foot.L")
			var head: int = skeleton.find_bone("Head")
			for sample: int in range(61):
				animator.seek(animation.length * float(sample) / 60.0, true)
				skeleton.force_update_all_bone_transforms()
				_check(skeleton.get_bone_global_pose(skeleton.find_bone("Root")).origin.length() < 0.0001,
					character + ": root stays in place")
				for bone: int in range(skeleton.get_bone_count()):
					var pose: Transform3D = skeleton.get_bone_global_pose(bone)
					_check(pose.origin.is_finite() and pose.basis.is_finite(), character + ": finite pose")
					if sample == 0:
						first_pose.append(pose)
					if sample == 60:
						_check(pose.origin.distance_to(first_pose[bone].origin) < 0.002,
							character + ": loop position closes for " + skeleton.get_bone_name(bone))
						_check(pose.basis.get_rotation_quaternion().angle_to(first_pose[bone].basis.get_rotation_quaternion()) < 0.01,
							character + ": loop rotation closes for " + skeleton.get_bone_name(bone))
				max_foot_motion = maxf(max_foot_motion, skeleton.get_bone_global_pose(foot).origin.distance_to(first_pose[foot].origin))
				max_head_motion = maxf(max_head_motion, skeleton.get_bone_global_pose(head).origin.distance_to(first_pose[head].origin))
			_check(max_foot_motion > 0.25 if clip == "run" else max_foot_motion < 0.01,
				character + ": feet stride in run and stay planted in idle")
			_check(max_head_motion > 0.01, character + ": upper body is animated")
			print(character, " / ", clip, ": duration=", animation.length,
				" foot motion=", max_foot_motion, " head motion=", max_head_motion)
		model.queue_free()
		await process_frame
	print("Character asset checks: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failures += 1
