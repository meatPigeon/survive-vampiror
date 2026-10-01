extends SceneTree

var _failures: int = 0
var _chosen: int = -1
var _skipped: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	var screen: ZombieUpgrades = load("res://scenes/ui/zombie_upgrades.tscn").instantiate()
	root.add_child(screen)
	screen.chosen.connect(func(index: int) -> void: _chosen = index)
	screen.skipped.connect(func() -> void: _skipped = true)
	var pairs: Array[Array] = [[HordeAbility.Upgrade.DETONATION, HordeAbility.Upgrade.SLING], [HordeAbility.Upgrade.FEAST, HordeAbility.Upgrade.SPRINT]]
	for pair: Array in pairs:
		var rewards: Array[int] = []
		var descriptions: Array[String] = []
		for reward: int in pair:
			rewards.append(reward)
			descriptions.append(HordeAbility.DESCRIPTIONS[reward])
		screen.present(rewards, descriptions, 2)
		await _frames(25)
		_check(screen.get_node("%StartButton").disabled, "fresh pair needs a selection")
		for index: int in range(2):
			var card: UpgradeCard = screen.cards.get_child(index)
			_check(card.get_node("Content/Art/Picture").texture == UpgradeCard.ART[rewards[index]], "each reward has its own correct illustration")
			_check(card.get_node("Content/Art/Binding/Key").text == descriptions[index].get_slice(" ", 0), "art key badge matches the actual ability binding")
			_check(root.get_visible_rect().encloses(card.get_global_rect()), "card stays inside the viewport")
			var description: Label = card.get_node("Content/Description")
			_check(description.get_global_rect().end.y <= card.get_node("Content/Divider").get_global_rect().position.y, "wrapped description does not cover the footer")
		await _capture("pair_%d" % rewards[0])
		_key(KEY_SPACE)
		_check(screen.selected_index == 0 and _chosen == -1, "keyboard selects the focused card without claiming it")
		screen.cards.get_child(1).grab_focus()
		_key(KEY_SPACE)
		_check(screen.selected_index == 1 and not screen.cards.get_child(0).button_pressed, "keyboard switches selection exclusively")
		_check(screen.cards.get_child(1).get_node("Content/Footer/Choice").text.contains("SELECTED"), "selected card has an explicit text marker")
		screen.get_node("%StartButton").grab_focus()
		_key(KEY_ENTER)
		_check(_chosen == 1, "keyboard confirmation emits the selected reward")
		_chosen = -1
	root.size = Vector2i(960, 600)
	await _frames(25)
	for card: Control in screen.cards.get_children():
		_check(root.get_visible_rect().encloses(card.get_global_rect()), "selected cards fit the small viewport")
	_check(root.get_visible_rect().encloses(screen.get_node("%SkipButton").get_global_rect()), "permanent-zombie alternative fits the small viewport")
	await _capture("selected_small")
	screen.get_node("%SkipButton").grab_focus()
	_key(KEY_ENTER)
	_check(_skipped, "keyboard can choose the permanent-zombie alternative")
	screen.queue_free()
	await _frames(3)
	print("Upgrade cards smoke: ", "PASS" if _failures == 0 else "FAIL")
	quit(0 if _failures == 0 else 1)


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventKey
	event.pressed = false
	root.push_input(event, true)


func _frames(count: int) -> void:
	for frame: int in range(count):
		await process_frame
		await physics_frame


func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/survive_cards_%s.png" % label)


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		_failures += 1
