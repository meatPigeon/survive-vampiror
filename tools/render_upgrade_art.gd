# Offline card illustrations made from the shipped character models.
# godot --path . --script res://tools/render_upgrade_art.gd
extends SceneTree

var stage: Node3D


func _initialize() -> void:
	_render.call_deferred()


func _render() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(768, 576)
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	for kind: String in ["mines", "sling", "feast", "sprint"]:
		stage = Node3D.new()
		viewport.add_child(stage)
		var tones: Dictionary[String, Color] = {
			"mines": Color("59462d"), "sling": Color("294b50"),
			"feast": Color("484051"), "sprint": Color("444e32")
		}
		var environment := WorldEnvironment.new()
		environment.environment = Environment.new()
		environment.environment.background_mode = Environment.BG_COLOR
		environment.environment.background_color = tones[kind]
		environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.environment.ambient_light_color = Color("e9dfc7")
		environment.environment.ambient_light_energy = 0.65
		stage.add_child(environment)
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-48, -35, 0)
		light.light_color = Color("fff1d5")
		light.light_energy = 1.25
		light.shadow_enabled = true
		stage.add_child(light)
		var fill := DirectionalLight3D.new()
		fill.rotation_degrees = Vector3(-20, 140, 0)
		fill.light_color = Color("b0c9c0")
		fill.light_energy = 0.45
		stage.add_child(fill)
		var ground := PlaneMesh.new()
		ground.size = Vector2(200, 200)
		_mesh(ground, Vector3(0, -0.05, 0), tones[kind])
		var camera := Camera3D.new()
		stage.add_child(camera)
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 4.1
		camera.position = Vector3(4.3, 4.0, 7)
		camera.look_at(Vector3(0, 1.2, 0))
		camera.current = true
		match kind:
			"mines":
				_zombie(Vector3(0, 0.08, 0), Vector3(0, 3.55, 0), 1.15)
				_ring(Vector3.ZERO, 1.35, Color("efaa55"))
				for i: int in range(9):
					var angle: float = TAU * float(i) / 9.0
					var cone := CylinderMesh.new()
					cone.top_radius = 0.0
					cone.bottom_radius = 0.27
					cone.height = 1.2 if i % 2 else 0.8
					cone.radial_segments = 5
					var shard: MeshInstance3D = _mesh(cone, Vector3(cos(angle) * 1.12, 0.35, sin(angle) * 1.12), Color("dd9448"))
					shard.rotation = Vector3(sin(angle) * 0.7, 0, -cos(angle) * 0.7)
					_stone(Vector3(cos(angle) * 1.7, 0.45 + 0.15 * (i % 3), sin(angle) * 1.7), 0.10 + 0.04 * (i % 2), Color("c2a274"))
			"sling":
				_zombie(Vector3(0.05, 1.0, 0), Vector3(-0.35, 3.9, -0.55), 1.05, true, "run", 0.17)
				_ring(Vector3(1.35, 0.0, -0.85), 0.7, Color("a4e0dc"))
				for i: int in range(6):
					var t: float = float(i) / 6.0
					_stone(Vector3(-2.1 + t * 1.75, 0.1 + sin(t * PI * 0.5) * 1.65, 0.15), 0.065, Color("b5dfdb"))
			"feast":
				_zombie(Vector3(0, 0.0, 0), Vector3(0, 3.5, 0), 1.18, false, "combat/bite", 0.06)
				_ring(Vector3.ZERO, 1.25, Color("bd99c8"))
				for i: int in range(3):
					var origin := Vector3(-1.3 + i * 1.3, 1.2 + (i % 2) * 1.5, -0.1)
					_box(origin, Vector3(0.48, 0.16, 0.16), Color("dbc7dc"))
					_box(origin, Vector3(0.16, 0.48, 0.16), Color("dbc7dc"))
			"sprint":
				_zombie(Vector3(0.15, 0.15, 0), Vector3(0, 4.0, -0.13), 1.15, false, "run", 0.17)
				for i: int in range(5):
					var streak := PrismMesh.new()
					streak.size = Vector3(1.0 + i * 0.12, 0.07, 0.10)
					var stroke: MeshInstance3D = _mesh(streak, Vector3(-1.3, 0.3 + i * 0.34, 0.2), Color("d3cd98"))
					stroke.rotation.z = 0.12
		for i: int in range(6):
			_stone(Vector3(-1.9 + i * 0.7, 0.04, 1.1 + (i % 2) * 0.5), 0.05 + 0.025 * (i % 3), tones[kind].lightened(0.16))
		for frame: int in range(8):
			await process_frame
		await RenderingServer.frame_post_draw
		var path: String = "res://assets/ui/upgrades/%s.png" % kind
		var result: Error = viewport.get_texture().get_image().save_png(path)
		if result != OK:
			push_error("Unable to save card art: " + path)
			quit(1)
			return
		print("Rendered ", path)
		stage.queue_free()
		await process_frame
	viewport.queue_free()
	await process_frame
	quit()


func _zombie(position: Vector3, rotation: Vector3, scale: float, temporary: bool = false, clip: String = "idle", time: float = 0.3) -> void:
	var zombie: HordeAgent = load("res://scenes/components/horde_agent.tscn").instantiate()
	zombie.kind = HordeAgent.Kind.TEMPORARY if temporary else HordeAgent.Kind.PERMANENT
	stage.add_child(zombie)
	zombie.get_node("KindMarker").hide()
	zombie.position = position
	zombie.rotation = rotation
	zombie.scale = Vector3.ONE * scale * 1.5
	zombie.visual.rotation.y = 0.0
	zombie.visual.animation_player.play(clip)
	zombie.visual.animation_player.seek(time, true)
	zombie.visual.animation_player.pause()
	zombie.process_mode = Node.PROCESS_MODE_DISABLED


func _mesh(mesh: Mesh, position: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	instance.material_override = material
	instance.position = position
	stage.add_child(instance)
	return instance


func _stone(position: Vector3, radius: float, color: Color) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 1.5
	sphere.radial_segments = 5
	sphere.rings = 2
	_mesh(sphere, position, color)


func _box(position: Vector3, size: Vector3, color: Color) -> void:
	var box := BoxMesh.new()
	box.size = size
	_mesh(box, position, color)


func _ring(position: Vector3, radius: float, color: Color) -> void:
	var ring := TorusMesh.new()
	ring.inner_radius = radius - 0.06
	ring.outer_radius = radius + 0.06
	ring.rings = 48
	ring.ring_segments = 4
	_mesh(ring, position, color)
