extends SceneTree

const OUTPUT_DIRECTORY: String = "/tmp/survive_character_frames"

var _animators: Array[AnimationPlayer] = []
var _skeletons: Array[Skeleton3D] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Rendered preview needs a graphical display.")
		quit(1)
		return
	root.size = Vector2i(1200, 800)
	root.msaa_3d = Viewport.MSAA_4X
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.8, 0.49, 0.18)
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
	material.albedo_color = Color(0.82, 0.54, 0.23)
	material.roughness = 1.0
	plane.material = material
	floor.mesh = plane
	floor.position.y = -0.015
	stage.add_child(floor)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.7
	stage.add_child(camera)
	camera.position = Vector3(2.7, 3.2, -8)
	camera.look_at(Vector3(0, 1.35, 0))
	var index: int = 0
	for character: String in ["zombie", "medieval_knight"]:
		var model: Node3D = load("res://assets/characters/" + character + ".glb").instantiate()
		stage.add_child(model)
		model.position.x = -1.25 if index == 0 else 1.25
		_animators.append(model.get_node("AnimationPlayer") as AnimationPlayer)
		_skeletons.append(model.find_child("Skeleton3D", true, false) as Skeleton3D)
		index += 1
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIRECTORY)
	for clip: String in ["idle", "run"]:
		for animator: AnimationPlayer in _animators:
			animator.play(clip)
			animator.pause()
		var frames: int = 60 if clip == "idle" else 72
		for frame: int in range(frames):
			for animator: AnimationPlayer in _animators:
				animator.seek(fmod(float(frame) / 30.0, animator.get_animation(clip).length), true)
			for skeleton: Skeleton3D in _skeletons:
				skeleton.force_update_all_bone_transforms()
			await process_frame
			await RenderingServer.frame_post_draw
			var error: Error = root.get_texture().get_image().save_png(
				"%s/%s_%03d.png" % [OUTPUT_DIRECTORY, clip, frame])
			if error != OK:
				push_error("Could not write preview frame.")
				quit(1)
				return
		print("Rendered preview: ", clip, " (", frames, " frames)")
	quit()
