class_name BattleHUD
extends CanvasLayer

signal pause_requested()
signal restart_requested()
signal sprint_requested()
signal menu_requested()

const BONE := Color("eee5d2")
const MUTED := Color("aaa99d")
const GREEN := Color("b8ce99")
const CYAN := Color("9bcbd0")
const RED := Color("e89b88")
const GOLD := Color("e3c49b")

var _health_trail_delay: float = 0.0

@onready var knight_health: ProgressBar = %KnightHealth
@onready var health_trail: ProgressBar = %HealthTrail
@onready var knight_hp: Label = %KnightHP
@onready var phase: Label = %Phase
@onready var clock_label: Label = %Clock
@onready var threat: Label = %Threat
@onready var permanent_count: Label = %PermanentCount
@onready var permanent_hint: Label = %PermanentHint
@onready var temporary_count: Label = %TemporaryCount
@onready var expiry: Label = %Expiry
@onready var site_name: Label = %SiteName
@onready var site_hint: Label = %SiteHint
@onready var sprint_button: Button = %SprintButton
@onready var sprint_bar: ProgressBar = %SprintBar
@onready var overlay: ColorRect = %Overlay
@onready var result_label: Label = %Result
@onready var result_caption: Label = %ResultCaption
@onready var result_stats: Label = %ResultStats
@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var audio_controls: AudioControls = %AudioControls
@onready var overlay_card: PanelContainer = $Frame/Overlay/Card


func _ready() -> void:
	%PauseButton.pressed.connect(func() -> void: pause_requested.emit())
	resume_button.pressed.connect(func() -> void: pause_requested.emit())
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	sprint_button.pressed.connect(func() -> void: sprint_requested.emit())
	%MenuButton.pressed.connect(func() -> void: menu_requested.emit())


func _process(delta: float) -> void:
	# Only presentation eases; health and every displayed timer come from gameplay.
	if get_tree().paused or overlay.visible:
		return
	_health_trail_delay = maxf(0.0, _health_trail_delay - delta)
	if _health_trail_delay <= 0.0:
		health_trail.value = lerpf(health_trail.value, knight_health.value, 1.0 - exp(-delta * 9.0))


func set_knight_health(current: int, maximum: int) -> void:
	if current < knight_health.value and absf(health_trail.value - knight_health.value) < 0.5:
		_health_trail_delay = 0.16
	knight_health.max_value = maximum
	health_trail.max_value = maximum
	if current >= knight_health.value:
		health_trail.value = current
	knight_health.value = current
	knight_hp.text = "%d / %d" % [current, maximum]


func update_status(
	horde: HordeController, knight: Survivor, started: bool, elapsed: float,
	site: ReinforcementSite, site_time_left: float
) -> void:
	clock_label.text = "%02d:%02d" % [int(elapsed) / 60, int(elapsed) % 60]
	phase.text = "Phase %s" % ["I", "II", "III"][knight.phase - 1]
	var permanent: int = horde.permanent_count()
	permanent_count.text = str(permanent)
	var critical: bool = permanent <= maxi(1, horde.agent_count / 5)
	permanent_count.modulate = RED if critical else BONE
	permanent_hint.text = "Keep them alive" if critical else "permanent"
	permanent_hint.modulate = RED if critical else MUTED
	var temporary: int = horde.temporary_count()
	%TemporaryGroup.visible = temporary > 0
	%HordeDivider.visible = temporary > 0
	temporary_count.text = "+%d" % temporary
	expiry.text = "temporary · %ds" % ceili(horde.next_expiration()) if temporary > 0 else ""
	expiry.modulate = GOLD if temporary > 0 and horde.next_expiration() <= 10.0 else CYAN
	%Rally.visible = started and knight.state != Survivor.State.STOPPED
	if site != null:
		var remaining: int = ceili(site_time_left)
		site_name.text = "◇  +%d" % site.remaining
		site_hint.text = "Hold the ring · moves in %ds" % remaining
		if site.progress > 0.0:
			site_hint.text = "Summoning · moves in %ds" % remaining
		elif site.remaining == 0:
			site_name.text = "◇  —"
			site_hint.text = "Next site in %ds" % remaining
		elif horde.agents.size() >= horde.max_agents:
			site_hint.text = "Horde full · moves in %ds" % remaining
	else:
		site_name.text = "◇  —"
		site_hint.text = "Next site in %ds" % ceili(site_time_left)
	var sprint_ready: bool = started and horde.commands_enabled and horde.sprint_cooldown_remaining <= 0.0
	%Sprint.visible = started and knight.state != Survivor.State.STOPPED
	sprint_button.disabled = not sprint_ready
	sprint_bar.visible = horde.sprint_cooldown_remaining > 0.0
	sprint_bar.value = (1.0 - horde.sprint_cooldown_remaining / horde.sprint_cooldown) * 100.0
	sprint_button.text = "Sprint   Space" if sprint_ready else "Sprint   %.1fs" % horde.sprint_cooldown_remaining
	if horde.sprint_remaining > 0.0:
		sprint_button.text = "Sprinting"
	threat.visible = not started or knight.state in [Survivor.State.WINDUP, Survivor.State.STRIKE, Survivor.State.RECOVERY]
	threat.text = "Click the ground to lead your horde"
	threat.modulate = BONE
	if started:
		if knight.state == Survivor.State.RECOVERY:
			threat.text = "Exposed — attack!"
			threat.modulate = GREEN
		else:
			threat.text = ["Sweep — move sideways", "Charge — clear the lane", "Spin — get out of the circle"][knight.attack_kind]
			threat.modulate = GOLD


func set_paused(paused: bool) -> void:
	overlay.visible = paused
	if not paused:
		return
	result_label.text = "Paused"
	result_label.modulate = BONE
	result_caption.text = "The horde can wait."
	result_stats.text = "Click to move · Space to sprint\nKeep at least one permanent zombie alive."
	audio_controls.show()
	_set_card_height(520.0)
	resume_button.show()
	restart_button.text = "Restart   R"


func show_result(won: bool, elapsed: float, horde: HordeController) -> void:
	audio_controls.hide()
	_set_card_height(390.0)
	result_label.text = "Victory" if won else "Defeat"
	result_label.modulate = BONE if won else RED
	result_caption.text = "The last knight has fallen." if won else "Your permanent horde is gone."
	result_stats.text = "%02d:%02d   ·   %d permanent survivors\n%d killed   ·   %d expired   ·   %d recruited" % [
		int(elapsed) / 60, int(elapsed) % 60, horde.permanent_count(),
		horde.casualties, horde.expired_count, horde.recruited]
	resume_button.hide()
	restart_button.text = "Play again   R"
	overlay.show()


func _set_card_height(height: float) -> void:
	overlay_card.offset_top = -height * 0.5
	overlay_card.offset_bottom = height * 0.5
