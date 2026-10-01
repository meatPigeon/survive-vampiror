extends Node3D


func _ready() -> void:
	$Camera.look_at(Vector3(0, 1.0, 0))
	# Only imported visuals run here: no health, horde controller or combat scene.
	for index: int in range($Characters.get_child_count()):
		var actor: Node3D = $Characters.get_child(index)
		var animation: AnimationPlayer = actor.get_node("AnimationPlayer")
		animation.play(&"idle")
		animation.seek(index * 0.37, true)
	var skeleton: Skeleton3D = $Characters/Knight.get_node("CharacterRig/Skeleton3D")
	var hand := BoneAttachment3D.new()
	hand.bone_name = "Hand.R"
	skeleton.add_child(hand)
	var halberd: Node3D = preload("res://scenes/components/halberd.tscn").instantiate()
	hand.add_child(halberd)
	halberd.position.y = 0.08
	var rest: Quaternion = skeleton.get_bone_global_rest(skeleton.find_bone("Hand.R")).basis.get_rotation_quaternion()
	halberd.quaternion = Quaternion(Vector3.UP, rest.inverse() * Vector3.FORWARD)
