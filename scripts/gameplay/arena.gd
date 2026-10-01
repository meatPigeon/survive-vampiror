extends Node3D

const KNIGHT: PackedScene = preload("res://scenes/components/survivor.tscn")

@export var normal_mode: bool = false
@export_range(1.0, 300.0) var site_interval: float = 30.0
@export_range(0.0, 60.0, 0.5) var site_respawn_delay: float = 5.0
@export_range(1, 3) var wave_count: int = 3
@export_range(1, 10000) var wave_base_health: int = 800
@export_range(0, 5000) var wave_health_increase: int = 200
@export_range(1.0, 30.0, 0.5) var wave_break_duration: float = 4.0

var wave_index: int = 1
var between_waves: bool = false
var awaiting_reward: bool = false
var offered_rewards: Array[int] = []
var wave_time_left: float = 0.0
var battle_started: bool = false
var battle_over: bool = false
var elapsed: float = 0.0
var active_site: ReinforcementSite
var _last_site: ReinforcementSite
var _next_site_at: float = 0.0
var _site_random := RandomNumberGenerator.new()

@onready var horde: HordeController = $Horde
@onready var survivor: Survivor = $Survivor
@onready var sites: Node3D = $Reinforcements
@onready var hud: BattleHUD = $HUD
@onready var battle_audio: BattleAudio = $BattleAudio
@onready var horde_input: HordeInput = $HordeInput


func _ready() -> void:
	process_physics_priority = 1
	_site_random.randomize()
	for site: ReinforcementSite in sites.get_children():
		site.summoned.connect(_on_site_summoned.bind(site))
	_prepare_knight()
	horde.count_changed.connect(_update_horde_count)
	horde.move_commanded.connect(_begin_battle)
	_update_knight_health(survivor.health.current_health, survivor.health.max_health)
	_update_horde_count(horde.agents.size())
	_update_status()
	battle_audio.setup(survivor, horde, sites)


func _begin_battle() -> void:
	if not battle_over and not battle_started:
		battle_started = true
		battle_audio.start_music()
		_update_site_schedule()
		_update_status()


func _physics_process(delta: float) -> void:
	if not battle_started or battle_over:
		return
	if between_waves:
		if awaiting_reward:
			return
		wave_time_left = maxf(0.0, wave_time_left - delta)
		if wave_time_left <= 0.0:
			_start_next_wave()
		_update_status()
		return
	elapsed += delta
	horde.update_lifetimes(delta)
	if battle_over:
		return
	for ability: HordeAbility in horde.abilities:
		ability.tick(delta)
		if battle_over or between_waves:
			_update_status()
			return
	_update_site_schedule()
	survivor.update_combat(horde.agents, delta)
	for agent: HordeAgent in horde.agents:
		if battle_over or between_waves:
			break
		agent.update_combat(survivor, delta)
	if not battle_over and not between_waves and active_site != null:
		# A successful summon may switch sites synchronously; tick only this one.
		active_site.update_recruitment(horde, delta)
	_update_status()


func _prepare_knight() -> void:
	survivor.movement_bounds = horde.movement_bounds
	survivor.lethal_attacks = normal_mode
	survivor.configure_wave(wave_index, wave_base_health + (wave_index - 1) * wave_health_increase)
	survivor.health.changed.connect(_update_knight_health)
	survivor.health.died.connect(_on_knight_defeated)
	horde.survivor = survivor
	_update_knight_health(survivor.health.current_health, survivor.health.max_health)


func _on_knight_defeated() -> void:
	if battle_over or between_waves:
		return
	if wave_index >= wave_count:
		_finish_battle(true)
		return
	between_waves = true
	awaiting_reward = true
	wave_time_left = wave_break_duration
	horde_input.clear_movement()
	horde.command_direction(Vector3.ZERO)
	horde.commands_enabled = false
	cancel_sling_aim()
	for ability: HordeAbility in horde.abilities:
		ability.process_mode = Node.PROCESS_MODE_DISABLED
	horde.set_physics_process(false)
	for agent: HordeAgent in horde.agents:
		agent.stop()
	battle_audio.begin_wave_break()
	offered_rewards = horde.roll_rewards()
	var descriptions: Array[String] = []
	for reward: int in offered_rewards:
		var key: String = "Q" if horde.ability.upgrade == HordeAbility.Upgrade.NONE else "E"
		descriptions.append(HordeAbility.DESCRIPTIONS[reward].replace("Q ", key + " "))
	hud.upgrades.present(offered_rewards, descriptions, wave_index + 1)
	_update_status()


func choose_reward(index: int) -> void:
	if not _can_resolve_reward() or index < 0 or index >= offered_rewards.size():
		return
	if not horde.grant_ability(offered_rewards[index]):
		return
	awaiting_reward = false
	_finish_reward()


func skip_reward() -> void:
	if not _can_resolve_reward():
		return
	awaiting_reward = false
	horde.add_permanent_reward(10)
	_finish_reward()


func _can_resolve_reward() -> bool:
	return awaiting_reward and between_waves and not battle_over and not get_tree().paused


func _finish_reward() -> void:
	offered_rewards.clear()
	hud.upgrades.hide()
	var focus: Control = get_viewport().gui_get_focus_owner()
	if focus != null:
		focus.release_focus()
	horde_input.clear_movement()
	_update_status()


func _start_next_wave() -> void:
	if awaiting_reward or battle_over:
		return
	# Keep the same horde and its HP, lifetimes, upgrades and statistics.
	var spawn: Vector3 = _next_knight_position()
	remove_child(survivor)
	survivor.queue_free()
	survivor = KNIGHT.instantiate() as Survivor
	survivor.name = "Survivor"
	survivor.position = spawn
	add_child(survivor)
	wave_index += 1
	_prepare_knight()
	battle_audio.bind_knight(survivor)
	between_waves = false
	horde_input.clear_movement()
	horde.commands_enabled = true
	for ability: HordeAbility in horde.abilities:
		ability.process_mode = Node.PROCESS_MODE_INHERIT
	horde.set_physics_process(true)


func _next_knight_position() -> Vector3:
	var center := Vector3.ZERO
	for agent: HordeAgent in horde.agents:
		center += agent.global_position
	center /= maxf(1.0, horde.agents.size())
	var bounds: Rect2 = horde.movement_bounds.grow(-6.0)
	var best := Vector3.ZERO
	var distance: float = -1.0
	for x: float in [bounds.position.x, bounds.end.x]:
		for z: float in [bounds.position.y, bounds.end.y]:
			var candidate := Vector3(x, 0, z)
			if candidate.distance_squared_to(center) > distance:
				best = candidate
				distance = candidate.distance_squared_to(center)
	return best


func _update_site_schedule() -> void:
	if not battle_started or battle_over or between_waves:
		return
	if elapsed >= _next_site_at:
		_open_next_site()


func _open_next_site() -> void:
	var candidates: Array[ReinforcementSite] = []
	for site: ReinforcementSite in sites.get_children():
		if site != _last_site:
			candidates.append(site)
	if candidates.is_empty():
		return
	# Preserve the authored opening; later destinations cannot repeat immediately.
	active_site = candidates[0] if _last_site == null else candidates[_site_random.randi_range(0, candidates.size() - 1)]
	_last_site = active_site
	_next_site_at = elapsed + site_interval
	for site: ReinforcementSite in sites.get_children():
		site.set_active(site == active_site)


func _on_site_summoned(site: ReinforcementSite) -> void:
	if battle_started and not battle_over and site == active_site:
		active_site = null
		_next_site_at = elapsed + site_respawn_delay
		_update_site_schedule()
		_update_status()


func site_time_left() -> float:
	return maxf(0.0, _next_site_at - elapsed) if battle_started else 0.0


func zoom_camera(steps: float) -> void:
	if not battle_over and not get_tree().paused:
		$Camera.adjust_zoom(steps)


func command_ability(slot: int = 0) -> void:
	if slot < 0 or slot >= horde.abilities.size():
		return
	if battle_started and not battle_over and not between_waves and not get_tree().paused:
		horde.abilities[slot].activate()
		horde_input.refresh_aim()
		_update_status()


func aim_sling(position: Vector3, on_ground: bool) -> void:
	if not battle_started or battle_over or between_waves or get_tree().paused:
		return
	for ability: HordeAbility in horde.abilities:
		ability.update_aim(position, on_ground)


func fire_sling() -> void:
	if not battle_started or battle_over or between_waves or get_tree().paused:
		return
	for ability: HordeAbility in horde.abilities:
		ability.fire_sling()
	_update_status()


func cancel_sling_aim() -> void:
	for ability: HordeAbility in horde.abilities:
		ability.cancel_aim()
	_update_status()


func toggle_pause() -> void:
	if battle_over:
		return
	get_tree().paused = not get_tree().paused
	if get_tree().paused:
		horde_input.clear_movement()
		cancel_sling_aim()
	hud.set_paused(get_tree().paused)
	hud.upgrades.visible = awaiting_reward and not get_tree().paused
	if hud.upgrades.visible:
		hud.upgrades.focus_choice()


func restart() -> void:
	var next: Node3D = load("res://scenes/main.tscn").instantiate()
	next.normal_mode = normal_mode
	battle_audio.stop_all()
	hud.audio_controls.stop_preview()
	get_tree().paused = false
	get_tree().change_scene_to_node(next)


func return_to_menu() -> void:
	var menu: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
	menu.normal_mode = normal_mode
	battle_audio.stop_all()
	hud.audio_controls.stop_preview()
	get_tree().paused = false
	get_tree().change_scene_to_node(menu)


func _update_status() -> void:
	hud.update_status(horde, survivor, battle_started, elapsed, active_site, site_time_left(), wave_index, wave_count, between_waves, wave_time_left, awaiting_reward)
	hud.update_abilities(horde.abilities, battle_started and not battle_over and not between_waves)


func _update_knight_health(current: int, maximum: int) -> void:
	hud.set_knight_health(current, maximum)


func _update_horde_count(_remaining: int) -> void:
	if horde.permanent_count() == 0:
		_finish_battle(false)
	_update_status()


func _finish_battle(won: bool) -> void:
	if battle_over:
		return
	battle_over = true
	awaiting_reward = false
	offered_rewards.clear()
	hud.upgrades.hide()
	between_waves = false
	wave_time_left = 0.0
	battle_audio.finish(won)
	horde.stop()
	survivor.stop_combat()
	hud.show_result(won, elapsed, horde)
