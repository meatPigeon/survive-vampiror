extends SceneTree

var _failures: int = 0
var _arena: Node3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	await _fixture()
	var horde: HordeController = _arena.horde
	_check(horde.ability.upgrade == HordeAbility.Upgrade.NONE and not _arena.hud.upgrades.visible, "first wave starts with ordinary zombies")
	_start()
	horde.recruit(20, horde.spawn_center)
	var veteran: HordeAgent = horde.agents[0]
	veteran.health.take_damage(7)
	var recruit: HordeAgent = horde.agents.back()
	var lifetime: float = recruit.lifetime_remaining
	_arena.survivor.health.take_damage(10000)
	await _frames(3)
	var screen: ZombieUpgrades = _arena.hud.upgrades
	_check(_arena.awaiting_reward and screen.visible and screen.cards.get_child_count() == 2, "winning a non-final wave offers exactly two cards")
	_check(screen.cleared_label.text == "Wave cleared" and screen._cleared_tween.is_running(), "reward screen announces the cleared wave with a tween")
	_check(not _arena.hud.wave_countdown.visible, "countdown stays hidden until a reward is chosen")
	var offers: Array[int] = _arena.offered_rewards.duplicate()
	_check(offers.size() == 2 and offers[0] != offers[1] and HordeAbility.Upgrade.NONE not in offers, "rewards are two distinct owned-perk-free draws")
	_check(screen.get_node("%StartButton").disabled, "upgrade confirmation needs a selected card")
	var countdown: float = _arena.wave_time_left
	var time: float = _arena.elapsed
	var site_time: float = _arena.site_time_left()
	_key(KEY_D)
	_key(KEY_Q)
	_confirm_sling()
	_arena._physics_process(100.0)
	_arena.choose_reward(-1)
	_arena.choose_reward(2)
	_check(_arena.wave_index == 1 and _arena.wave_time_left == countdown and _arena.elapsed == time, "no timeout or invalid choice advances the reward screen")
	_check(recruit.lifetime_remaining == lifetime and _arena.site_time_left() == site_time and horde.move_direction.is_zero_approx(), "reward choice freezes lifetimes, sites and movement")
	await _capture("two_cards")
	await _click(screen.cards.get_child(0))
	await _click(screen.cards.get_child(1))
	_check(screen.selected_index == 1 and not screen.cards.get_child(0).button_pressed and screen.cards.get_child(1).button_pressed, "selection can change and stays exclusive")
	_key(KEY_ESCAPE)
	await _frames(2)
	_check(paused and not screen.visible and _arena.hud.overlay.visible, "Escape opens pause above rewards")
	var cleared_scale: Vector2 = screen.cleared_label.scale
	var cleared_alpha: float = screen.cleared_label.modulate.a
	await _frames(15)
	_check(screen.cleared_label.scale == cleared_scale and screen.cleared_label.modulate.a == cleared_alpha, "cleared announcement tween freezes on pause")
	_arena.choose_reward(0)
	_arena.skip_reward()
	_check(_arena.awaiting_reward and horde.permanent_count() == 40, "paused callbacks cannot grant rewards")
	_key(KEY_ESCAPE)
	await _frames(2)
	_check(screen.visible and screen.selected_index == 1 and _arena.offered_rewards == offers, "resume retains the same cards and selected card")
	await _frames(30)
	_check(screen.cleared_label.scale.is_equal_approx(Vector2.ONE) and is_equal_approx(screen.cleared_label.modulate.a, 1.0), "cleared announcement settles after resume without rerolling rewards")
	root.size = Vector2i(960, 600)
	await _frames(3)
	for card: Control in screen.cards.get_children():
		_check(root.get_visible_rect().encloses(card.get_global_rect()), "reward card fits the small viewport")
	_check(root.get_visible_rect().encloses(screen.get_node("%SkipButton").get_global_rect()), "skip button fits the small viewport")
	await _capture("selected_small")
	await _click(screen.get_node("%SkipButton"))
	_check(not _arena.awaiting_reward and not screen.visible and _arena.between_waves, "skip closes rewards and begins the intermission countdown")
	var hud: BattleHUD = _arena.hud
	_check(hud.wave_countdown.visible and hud.countdown_number.text == str(ceili(countdown)), "reward selection reveals the real countdown")
	_check(not hud.threat.visible, "small threat text does not duplicate the wave countdown")
	await _capture("countdown_small")
	_key(KEY_ESCAPE)
	var countdown_scale: Vector2 = hud.countdown_number.scale
	await _frames(15)
	_check(not hud.wave_countdown.visible and hud.countdown_number.scale == countdown_scale and _arena.wave_time_left == countdown, "pause hides and freezes countdown and its tween")
	_key(KEY_ESCAPE)
	_arena._physics_process(1.1)
	_check(hud.wave_countdown.visible and hud.countdown_number.text == "3", "countdown pulse follows actual remaining battle time")
	await _frames(20)
	_check(root.get_visible_rect().encloses(hud.wave_countdown.get_global_rect()), "large countdown fits the small viewport")
	root.size = Vector2i(1280, 800)
	await _frames(4)
	await _capture("countdown")
	_check(horde.permanent_count() == 50 and horde.agents.size() == 70 and horde.temporary_count() == 20, "skip grants exactly ten permanent zombies even at the recruitment cap")
	_check(veteran.health.current_health == 23 and recruit.lifetime_remaining == lifetime, "reward preserves surviving wounds and temporary lifetimes")
	for agent: HordeAgent in horde.agents.slice(60):
		_check(agent.kind == HordeAgent.Kind.PERMANENT and agent.lifetime_remaining == 0.0 and agent.health.current_health == 30, "bonus zombies are healthy permanent members")
	_arena.skip_reward()
	_arena.choose_reward(1)
	_check(horde.permanent_count() == 50 and horde.ability.upgrade == HordeAbility.Upgrade.NONE, "duplicate callbacks cannot grant twice or take a card after skipping")
	_arena._physics_process(_arena.wave_time_left)
	horde.set_physics_process(false)
	await _frames(3)
	_check(_arena.wave_index == 2 and not _arena.between_waves and horde.recruit(1, Vector3.ZERO) == 0, "next wave resumes and ordinary recruitment still obeys its cap")
	_check(not hud.wave_countdown.visible and hud._countdown_tween == null, "new wave clears the countdown and its tween")
	await _capture("bonus_horde")
	_arena.survivor.health.take_damage(10000)
	await _frames(3)
	_check(_arena.offered_rewards.size() == 2 and HordeAbility.Upgrade.NONE not in _arena.offered_rewards, "a skipped first reward still offers perks on the next round")
	var chosen: int = _arena.offered_rewards[0]
	await _click(screen.cards.get_child(0))
	await _click(screen.get_node("%StartButton"))
	_check(horde.has_upgrade(chosen) and horde.permanent_count() == 50, "a card grants its perk instead of bonus zombies")
	_arena._physics_process(_arena.wave_break_duration)
	horde.set_physics_process(false)
	_arena.survivor.health.take_damage(10000)
	_check(_arena.battle_over and not _arena.awaiting_reward and not screen.visible, "final victory does not offer another reward")
	_check(not hud.wave_countdown.visible, "final victory does not show a stale countdown")
	_arena.skip_reward()
	_check(horde.permanent_count() == 50, "no bonus can be claimed after victory")
	_arena.restart()
	await _frames(4)
	_arena = current_scene
	_check(_arena.wave_index == 1 and _arena.horde.permanent_count() == 40 and _arena.horde.ability.upgrade == HordeAbility.Upgrade.NONE, "restart resets upgrades and reward zombies")
	_check(not _arena.hud.wave_countdown.visible, "restart has no previous wave announcement")
	await _dispose()

	# The second reward adds a different skill; both remain usable independently.
	await _fixture()
	_start()
	horde = _arena.horde
	_arena.survivor.health.take_damage(10000)
	_arena.choose_reward(_active_choice())
	var ability: HordeAbility = horde.ability
	var skill: HordeAbility.Upgrade = ability.upgrade
	_arena._physics_process(_arena.wave_break_duration)
	horde.set_physics_process(false)
	_arena.survivor.health.take_damage(10000)
	await _frames(3)
	_check(_arena.offered_rewards.size() == 2 and skill not in _arena.offered_rewards and _arena.offered_rewards[0] != _arena.offered_rewards[1], "second round draws two unowned perks")
	for index: int in range(2):
		var card: Button = _arena.hud.upgrades.cards.get_child(index)
		var key: String = "Space " if _arena.offered_rewards[index] == HordeAbility.Upgrade.SPRINT else "E "
		_check(card.get_node("Content/Description").text.begins_with(key), "reward card explains its actual binding")
	await _capture("second_ability")
	chosen = _arena.offered_rewards[_active_choice()]
	_arena.choose_reward(_active_choice())
	var second: HordeAbility = horde.abilities[1]
	_check(ability.upgrade == skill and second.upgrade == chosen and horde.permanent_count() == 40, "second choice adds its ability and retains the first")
	_check(not horde.grant_ability(skill) and not horde.grant_ability(-1), "duplicate and invalid skills cannot be granted")
	_arena._physics_process(_arena.wave_break_duration)
	horde.set_physics_process(false)
	horde.recruit(1, _arena.survivor.global_position + Vector3.RIGHT)
	_arena._update_status()
	await _frames(3)
	var first_button: Button = _arena.hud.get_node("%AbilityButton")
	var second_button: Button = _arena.hud.get_node("%SecondAbilityButton")
	_check(first_button.visible and second_button.visible and first_button.text.ends_with("Q") and second_button.text.ends_with("E"), "HUD presents two separate ability bindings")
	_check(not first_button.get_global_rect().intersects(second_button.get_global_rect()), "two ability buttons do not overlap")
	await _capture("two_abilities_hud")
	_key(KEY_Q)
	_confirm_sling()
	var first_cooldown: float = ability.cooldown_remaining
	_check(first_cooldown > 0.0 and second.cooldown_remaining == 0.0, "Q only activates its own ability")
	_key(KEY_E)
	_confirm_sling()
	_check(second.cooldown_remaining > 0.0 and ability.cooldown_remaining == first_cooldown, "E activates independently while Q is on cooldown")
	_key(KEY_Q)
	_confirm_sling()
	_check(ability.cooldown_remaining == first_cooldown, "Q cannot bypass its cooldown")
	_arena.restart()
	await _frames(4)
	_arena = current_scene
	_check(_arena.horde.abilities[0].upgrade == HordeAbility.Upgrade.NONE and _arena.horde.abilities[1].upgrade == HordeAbility.Upgrade.NONE, "restart resets both ability slots")
	await _dispose()

	# A flying recruit keeps its owner when mines are armed afterwards.
	await _fixture()
	_start()
	horde = _arena.horde
	horde.grant_ability(HordeAbility.Upgrade.SLING)
	horde.grant_ability(HordeAbility.Upgrade.DETONATION)
	horde.recruit(1, _arena.survivor.global_position + Vector3.RIGHT)
	_key(KEY_Q)
	_confirm_sling()
	var flying: HordeAgent = horde.ability.projectile
	_key(KEY_E)
	_confirm_sling()
	second = horde.abilities[1]
	_check(is_instance_valid(flying) and flying not in second.armed and second.armed.size() == horde.agents.size() / 2, "mines arm half the total crowd without claiming a flying zombie")
	var fuse: float = second.fuse_remaining
	_arena.toggle_pause()
	horde.ability.tick(1.0)
	second.tick(1.0)
	_check(horde.ability.flight_elapsed == 0.0 and second.fuse_remaining == fuse, "pause freezes both active abilities")
	_arena.toggle_pause()
	horde.ability.tick(0.2)
	horde.ability.tick(1.0)
	_check(horde.ability.projectile == null and flying not in horde.agents and second.armed.size() == 20, "landing spends only the projectile and leaves the mine group armed")
	await _dispose()

	await _fixture()
	_start()
	horde = _arena.horde
	_arena.survivor.health.take_damage(10000)
	_arena.choose_reward(_active_choice())
	skill = horde.ability.upgrade
	_arena._physics_process(_arena.wave_break_duration)
	horde.set_physics_process(false)
	_arena.survivor.health.take_damage(10000)
	_arena.skip_reward()
	_check(horde.permanent_count() == 50 and horde.ability.upgrade == skill and horde.abilities[1].upgrade == HordeAbility.Upgrade.NONE, "skipping the second reward preserves the first ability and adds ten permanent zombies")
	await _dispose()

	# Feast changes bite behaviour while respecting the other ability's marker/lock.
	for other: HordeAbility.Upgrade in [HordeAbility.Upgrade.DETONATION, HordeAbility.Upgrade.SLING]:
		await _fixture()
		_start()
		horde = _arena.horde
		horde.grant_ability(other)
		horde.grant_ability(HordeAbility.Upgrade.FEAST)
		horde.recruit(1, _arena.survivor.global_position + Vector3.RIGHT)
		_key(KEY_Q)
		_confirm_sling()
		var locked: HordeAgent = horde.ability.armed[0] if other == HordeAbility.Upgrade.DETONATION else horde.ability.projectile
		var marker: StandardMaterial3D = locked.get_node("KindMarker").material_override
		var locked_color: Color = marker.albedo_color
		_key(KEY_E)
		_confirm_sling()
		horde.abilities[1].tick(0.1)
		_check(locked.ability_locked and locked.feasting and marker.albedo_color == locked_color, "feast preserves mine/projectile ownership and its marker")
		horde.ability.cancel()
		_check(not locked.ability_locked and locked.feasting and marker.albedo_color == Color("c894e8"), "canceling the other ability restores the active feast marker")
		horde.stop()
		_check(not locked.feasting and not locked.ability_locked, "stopping the horde cancels both abilities")
		await _dispose()

	await _fixture()
	_start()
	_arena.survivor.health.take_damage(10000)
	_arena.toggle_pause()
	_arena.restart()
	await _frames(4)
	_arena = current_scene
	_check(not paused and not _arena.awaiting_reward and not _arena.hud.upgrades.visible, "restart from paused rewards clears the choice")
	_start()
	_arena.survivor.health.take_damage(10000)
	for agent: HordeAgent in _arena.horde.agents.duplicate():
		agent.health.take_damage(100)
	_arena.skip_reward()
	_check(_arena.battle_over and _arena.horde.permanent_count() == 0 and not _arena.hud.upgrades.visible, "permanent wipe closes the reward screen and cannot be undone by skip")
	await _dispose()
	print("Round rewards smoke: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)


func _fixture() -> void:
	_arena = load("res://scenes/main.tscn").instantiate()
	root.add_child(_arena)
	current_scene = _arena
	_arena.set_physics_process(false)
	_arena.horde.set_physics_process(false)
	await _frames(3)


func _start() -> void:
	_key(KEY_W)


func _active_choice() -> int:
	return 1 if _arena.offered_rewards[0] == HordeAbility.Upgrade.SPRINT else 0


func _key(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventKey
	event.pressed = false
	root.push_input(event, true)


func _confirm_sling() -> void:
	for ability: HordeAbility in _arena.horde.abilities:
		if not ability.aiming:
			continue
		var event := InputEventMouseButton.new()
		event.position = _arena.get_node("Camera").unproject_position(_arena.survivor.global_position)
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		root.push_input(event, true)
		event = event.duplicate() as InputEventMouseButton
		event.pressed = false
		root.push_input(event, true)


func _click(control: Control) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = control.get_global_transform_with_canvas() * (control.size * 0.5)
	root.push_input(motion, true)
	var event := InputEventMouseButton.new()
	event.position = motion.position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventMouseButton
	event.pressed = false
	root.push_input(event, true)
	await _frames(3)


func _dispose() -> void:
	_arena.battle_audio.stop_all()
	_arena.queue_free()
	await _frames(12)


func _frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame


func _capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/survive_rewards_%s.png" % label)


func _check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		_failures += 1
