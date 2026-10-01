class_name HordeAbility
extends Node

enum Upgrade { DETONATION, SLING, FEAST, NONE, SPRINT }

signal activated(kind: Upgrade)
signal impacted(kind: Upgrade)
signal feast_ended()

const TITLES: Array[String] = ["Corpse mines", "Zombie sling", "Blood feast", "Unmodified", "Sprint"]
const DESCRIPTIONS: Array[String] = [
	"Q leaves half the horde behind. After 2 seconds they explode and die. Permanent zombies are spent too.",
	"Q aims the sling. Move the mouse, then left-click to launch a temporary zombie into the scatter circle. Right-click cancels.",
	"Q grants 5 seconds of faster bites that heal the biting zombie. Get close and feed to recover.",
	"Lead the ordinary horde with movement and automatic bites. Learn perks between waves.",
	"Space doubles movement speed for 1.4 seconds. Recharges in 7 seconds. Keeps Q/E free for other abilities."
]

@export var fuse_duration: float = 2.0
@export var blast_radius: float = 2.8
@export var blast_damage: int = 45
@export var mine_cooldown: float = 8.0
@export var sling_range: float = 22.0
@export var sling_spread: float = 2.5
@export var flight_duration: float = 0.8
@export var flight_height: float = 3.5
@export var impact_radius: float = 2.0
@export var impact_damage: int = 100
@export var sling_cooldown: float = 2.5
@export var feast_duration: float = 5.0
@export var feast_cooldown: float = 15.0

var upgrade: Upgrade = Upgrade.NONE
var cooldown_remaining: float = 0.0
var fuse_remaining: float = 0.0
var feast_remaining: float = 0.0
var armed: Array[HordeAgent] = []
var projectile: HordeAgent
var flight_elapsed: float = 0.0
var aiming: bool = false
var aim_position := Vector3.ZERO
var aim_valid: bool = false
var _launch_origin: Vector3
var _landing: Vector3
var _aim_preview: AttackPreview
var _aim_ring: AttackPreview
var _sling_random := RandomNumberGenerator.new()

@onready var horde: HordeController = get_parent()


func _ready() -> void:
	_sling_random.randomize()


func can_activate() -> bool:
	if get_tree().paused or not horde.commands_enabled or cooldown_remaining > 0.0:
		return false
	match upgrade:
		Upgrade.DETONATION:
			return horde.agents.size() >= 2 and armed.is_empty()
		Upgrade.SLING:
			return _sling_ammo() != null and not is_instance_valid(projectile)
		Upgrade.FEAST:
			return not horde.agents.is_empty() and feast_remaining <= 0.0
	return false


func activate() -> void:
	if not can_activate():
		return
	match upgrade:
		Upgrade.DETONATION:
			# Spread mines across the crowd without taking over a flying zombie.
			var available: Array[HordeAgent] = []
			for member: HordeAgent in horde.agents:
				if not member.ability_locked:
					available.append(member)
			var amount: int = mini(horde.agents.size() / 2, available.size())
			for index: int in range(amount):
				var agent: HordeAgent = available[index * available.size() / amount]
				agent.ability_locked = true
				agent.stop()
				agent.set_ability_color(Color("ef9b53"))
				armed.append(agent)
			fuse_remaining = fuse_duration
			cooldown_remaining = mine_cooldown
			if not armed.is_empty():
				activated.emit(upgrade)
		Upgrade.SLING:
			if aiming:
				cancel_aim()
			else:
				aiming = true
				aim_valid = false
		Upgrade.FEAST:
			feast_remaining = feast_duration
			cooldown_remaining = feast_cooldown
			_set_feast(true)
			activated.emit(upgrade)


func update_aim(position: Vector3, on_ground: bool) -> void:
	if not aiming:
		return
	aim_position = Vector3(position.x, 0.0, position.z)
	# Keep the whole scatter circle on the floor and within the recruit's range.
	aim_valid = on_ground and horde.movement_bounds.grow(-sling_spread).has_point(Vector2(position.x, position.z)) and _sling_ammo(aim_position) != null
	if not on_ground:
		if is_instance_valid(_aim_preview):
			_aim_preview.hide()
		return
	if not is_instance_valid(_aim_preview):
		_aim_preview = AttackPreview.new()
		add_child(_aim_preview)
		_aim_preview.show_arc(aim_position, Vector3.FORWARD, sling_spread, 360.0, Color.WHITE)
		_aim_ring = AttackPreview.new()
		_aim_preview.add_child(_aim_ring)
		_aim_ring.show_ring(aim_position, sling_spread, 0.09, Color.WHITE)
		_aim_ring.position.y = 0.01
	var color := Color("72dbe6") if aim_valid else Color("e89b88")
	_aim_preview.global_position = aim_position + Vector3.UP * 0.06
	_aim_preview.material_override.albedo_color = Color(color, 0.2)
	_aim_ring.material_override.albedo_color = Color(color, 0.9)
	_aim_preview.show()


func fire_sling() -> void:
	if not aiming or not aim_valid or not can_activate():
		return
	var ammo: HordeAgent = _sling_ammo(aim_position)
	if ammo == null:
		return
	projectile = ammo
	projectile.ability_locked = true
	projectile.stop()
	projectile.set_ability_color(Color("72dbe6"))
	_launch_origin = projectile.global_position
	# Square root distributes landings uniformly over the visible disk.
	var angle: float = _sling_random.randf_range(0.0, TAU)
	var radius: float = sling_spread * sqrt(_sling_random.randf())
	_landing = aim_position + Vector3(cos(angle), 0.0, sin(angle)) * radius
	flight_elapsed = 0.0
	cooldown_remaining = sling_cooldown
	cancel_aim()
	_pulse(_landing, impact_radius, Color(0.3, 0.85, 0.9, 0.22), flight_duration)
	activated.emit(upgrade)


func cancel_aim() -> void:
	aiming = false
	aim_valid = false
	if is_instance_valid(_aim_preview):
		_aim_preview.hide()


func tick(delta: float) -> void:
	if not horde.commands_enabled or get_tree().paused:
		return
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	if aiming and _sling_ammo() == null:
		cancel_aim()
	if feast_remaining > 0.0:
		feast_remaining = maxf(0.0, feast_remaining - delta)
		_set_feast(feast_remaining > 0.0)
		if feast_remaining <= 0.0:
			feast_ended.emit()
	if not armed.is_empty():
		fuse_remaining = maxf(0.0, fuse_remaining - delta)
		for agent: HordeAgent in armed:
			if is_instance_valid(agent) and agent.health.is_alive():
				agent.get_node("KindMarker").scale.x = 1.5 + 0.4 * sin(fuse_remaining * 18.0)
				agent.get_node("KindMarker").scale.z = agent.get_node("KindMarker").scale.x
		if fuse_remaining <= 0.0:
			_detonate()
	if not horde.commands_enabled:
		return
	if is_instance_valid(projectile):
		if not projectile.health.is_alive():
			_clear_projectile()
			return
		flight_elapsed += delta
		var progress: float = minf(1.0, flight_elapsed / flight_duration)
		# Keep the gameplay root planar; only the model follows the airborne arc.
		projectile.global_position = _launch_origin.lerp(_landing, progress)
		projectile.visual.position.y = sin(progress * PI) * flight_height
		projectile.visual.rotation.z = progress * TAU
		if progress >= 1.0:
			var spent: HordeAgent = projectile
			_clear_projectile()
			impacted.emit(upgrade)
			spent.health.take_damage(spent.health.current_health)
			_pulse(_landing, impact_radius, Color(0.3, 0.85, 0.9, 0.55), 0.3)
			if horde.commands_enabled and horde.survivor.health.is_alive() and horde.survivor.global_position.distance_to(_landing) <= impact_radius:
				horde.survivor.health.take_damage(impact_damage)


func _detonate() -> void:
	var batch: Array[HordeAgent] = armed.duplicate()
	armed.clear()
	var damage: int = 0
	var signaled: bool = false
	for agent: HordeAgent in batch:
		if not is_instance_valid(agent) or not agent.health.is_alive():
			continue
		if not horde.commands_enabled:
			break
		if not signaled:
			impacted.emit(upgrade)
			signaled = true
		if horde.survivor.health.is_alive() and agent.global_position.distance_to(horde.survivor.global_position) <= blast_radius:
			damage += blast_damage
		_pulse(agent.global_position, blast_radius, Color(1.0, 0.45, 0.15, 0.35), 0.3)
		agent.health.take_damage(agent.health.current_health)
	# Losing the last permanent zombie still loses, even with a lethal blast ready.
	if horde.commands_enabled and damage > 0:
		horde.survivor.health.take_damage(damage)


func _sling_ammo(target: Vector3 = Vector3.INF) -> HordeAgent:
	var nearest: HordeAgent
	var distance: float = sling_range
	for agent: HordeAgent in horde.agents:
		if agent.kind != HordeAgent.Kind.TEMPORARY or agent.ability_locked:
			continue
		if not target.is_finite():
			return agent
		var candidate_distance: float = agent.global_position.distance_to(target) + sling_spread
		if candidate_distance <= distance:
			nearest = agent
			distance = candidate_distance
	return nearest


func _set_feast(active: bool) -> void:
	for agent: HordeAgent in horde.agents:
		agent.feasting = active
		if not agent.ability_locked:
			agent.set_ability_color(Color("c894e8") if active else Color.TRANSPARENT)


func _clear_projectile() -> void:
	if is_instance_valid(projectile):
		projectile.visual.position.y = 0.0
		projectile.visual.rotation.z = 0.0
		projectile.ability_locked = false
		projectile.set_ability_color(Color.TRANSPARENT)
	projectile = null


func cancel() -> void:
	cancel_aim()
	for agent: HordeAgent in armed:
		if is_instance_valid(agent):
			agent.ability_locked = false
			agent.set_ability_color(Color.TRANSPARENT)
	armed.clear()
	fuse_remaining = 0.0
	feast_remaining = 0.0
	if upgrade == Upgrade.FEAST:
		_set_feast(false)
	_clear_projectile()
	for child: Node in get_children():
		child.queue_free()
	_aim_preview = null
	_aim_ring = null


func forget_agent(agent: HordeAgent) -> void:
	armed.erase(agent)
	if agent == projectile:
		_clear_projectile()


func status_text(key: String = "Q") -> String:
	if aiming:
		return "Sling · LMB fire · RMB cancel"
	if not armed.is_empty():
		return "Detonating · %.1fs" % fuse_remaining
	if feast_remaining > 0.0:
		return "Feasting · %.1fs" % feast_remaining
	if cooldown_remaining > 0.0:
		return "%s · %.1fs" % [TITLES[upgrade], cooldown_remaining]
	if upgrade == Upgrade.SLING and _sling_ammo() == null:
		return "Sling · need a recruit"
	if upgrade == Upgrade.DETONATION and horde.agents.size() < 2:
		return "Mines · need 2 zombies"
	return "%s · %s" % [TITLES[upgrade], key]


func _pulse(location: Vector3, radius: float, color: Color, duration: float) -> void:
	var pulse := AttackPreview.new()
	add_child(pulse)
	pulse.show_arc(location, Vector3.FORWARD, radius, 360.0, color)
	var fade: Tween = pulse.create_tween()
	fade.tween_property(pulse.material_override, "albedo_color:a", 0.0, duration)
	fade.tween_callback(pulse.queue_free)
