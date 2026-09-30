class_name BattleHUD
extends CanvasLayer

signal pause_requested()
signal restart_requested()
signal sprint_requested()

const BONE := Color("e8e6d7")
const MUTED := Color("929b91")
const GREEN := Color("c7ee83")
const CYAN := Color("7edbe6")
const RED := Color("f38e7e")
const GOLD := Color("edcb86")

@onready var knight_health: ProgressBar = %KnightHealth
@onready var knight_hp: Label = %KnightHP
@onready var phase: Label = %Phase
@onready var clock_label: Label = %Clock
@onready var threat: Label = %Threat
@onready var permanent_count: Label = %PermanentCount
@onready var permanent_bar: ProgressBar = %PermanentBar
@onready var permanent_hint: Label = %PermanentHint
@onready var temporary_count: Label = %TemporaryCount
@onready var temporary_bar: ProgressBar = %TemporaryBar
@onready var expiry: Label = %Expiry
@onready var site_name: Label = %SiteName
@onready var site_hint: Label = %SiteHint
@onready var site_bar: ProgressBar = %SiteBar
@onready var capacity: Label = %Capacity
@onready var sprint_button: Button = %SprintButton
@onready var sprint_bar: ProgressBar = %SprintBar
@onready var sprint_hint: Label = %SprintHint
@onready var overlay: ColorRect = %Overlay
@onready var result_label: Label = %Result
@onready var result_caption: Label = %ResultCaption
@onready var result_stats: Label = %ResultStats
@onready var result_eyebrow: Label = %ResultEyebrow
@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton


func _ready() -> void:
	%PauseButton.pressed.connect(func() -> void: pause_requested.emit())
	resume_button.pressed.connect(func() -> void: pause_requested.emit())
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	sprint_button.pressed.connect(func() -> void: sprint_requested.emit())


func set_knight_health(current: int, maximum: int) -> void:
	knight_health.max_value = maximum
	knight_health.value = current
	knight_hp.text = "%d / %d" % [current, maximum]


func update_status(
	horde: HordeController, knight: Survivor, started: bool, elapsed: float,
	site: ReinforcementSite, site_interval: float
) -> void:
	clock_label.text = "%02d:%02d" % [int(elapsed) / 60, int(elapsed) % 60]
	phase.text = "PHASE %02d / 03" % knight.phase
	capacity.text = "HORDE  %d / %d" % [horde.agents.size(), horde.max_agents]
	var permanent: int = horde.permanent_count()
	permanent_count.text = "%02d" % permanent
	permanent_bar.max_value = horde.agent_count
	permanent_bar.value = permanent
	var critical: bool = permanent <= maxi(1, horde.agent_count / 5)
	permanent_count.modulate = RED if critical else BONE
	permanent_hint.text = "PROTECT THE LAST %d" % permanent if critical else "LOSE THEM ALL, LOSE THE RUN"
	permanent_hint.modulate = RED if critical else MUTED
	var temporary: int = horde.temporary_count()
	temporary_count.text = "%02d" % temporary
	temporary_bar.value = horde.next_expiration() / horde.temporary_lifetime * 100.0 if temporary > 0 else 0.0
	expiry.text = "NEXT EXPIRY  %ds" % ceili(horde.next_expiration()) if temporary > 0 else "RECRUIT AT THE GREEN ZONE"
	site_name.text = "STANDBY"
	site_hint.text = "OPENS WITH YOUR FIRST COMMAND"
	site_bar.value = 0.0
	if site != null:
		var remaining: float = site_interval - fmod(elapsed, site_interval)
		site_name.text = "%s  /  +%02d" % [str(site.name).to_upper(), site.remaining]
		site_hint.text = "ROTATES IN %ds  ·  HOLD ZONE %.0fs" % [ceili(remaining), site.summon_time]
		if site.progress > 0.0:
			site_hint.text = "SUMMONING %d%%  ·  ROTATES IN %ds" % [roundi(site.progress / site.summon_time * 100), ceili(remaining)]
		elif site.remaining == 0:
			site_hint.text = "EXHAUSTED  ·  NEXT ZONE IN %ds" % ceili(remaining)
		site_bar.value = remaining / site_interval * 100.0
	var sprint_ready: bool = started and horde.commands_enabled and horde.sprint_cooldown_remaining <= 0.0
	sprint_button.disabled = not sprint_ready
	sprint_bar.value = (1.0 - horde.sprint_cooldown_remaining / horde.sprint_cooldown) * 100.0
	sprint_button.text = "SPRINT  [SPACE]" if sprint_ready else ("%.1fs" % horde.sprint_cooldown_remaining if started else "SPRINT  [SPACE]")
	sprint_hint.text = "2× SPEED  /  %.1fs" % horde.sprint_duration if sprint_ready else "RECHARGING"
	if not started:
		sprint_hint.text = "AVAILABLE AFTER FIRST COMMAND"
	elif horde.sprint_remaining > 0.0:
		sprint_hint.text = "SPRINT ACTIVE"
	threat.text = "CLICK THE GROUND TO BEGIN  ·  BRING DOWN THE KNIGHT"
	threat.modulate = BONE
	if started:
		threat.text = knight.status_text().to_upper()
		threat.modulate = GREEN if knight.state == Survivor.State.RECOVERY else GOLD
		if knight.state == Survivor.State.HUNT:
			threat.modulate = MUTED
		elif knight.state == Survivor.State.STOPPED:
			threat.text = "ENCOUNTER COMPLETE"


func set_paused(paused: bool) -> void:
	overlay.visible = paused
	if not paused:
		return
	result_eyebrow.text = "TAKE A BREATH"
	result_label.text = "Paused"
	result_label.modulate = BONE
	result_caption.text = "Your horde is waiting."
	result_stats.text = "All combat and reinforcement timers are frozen."
	resume_button.show()
	restart_button.text = "RESTART  [R]"


func show_result(won: bool, elapsed: float, horde: HordeController) -> void:
	result_eyebrow.text = "ENCOUNTER COMPLETE"
	result_label.text = "Victory" if won else "Defeat"
	result_label.modulate = GREEN if won else RED
	result_caption.text = "The last knight has fallen." if won else "Your permanent horde is gone."
	result_stats.text = "%02d:%02d  SURVIVED     /     %d ORIGINALS LEFT\n\n%d KILLED     ·     %d EXPIRED     ·     %d RECRUITED" % [
		int(elapsed) / 60, int(elapsed) % 60, horde.permanent_count(),
		horde.casualties, horde.expired_count, horde.recruited]
	resume_button.hide()
	restart_button.text = "PLAY AGAIN  [R]"
	overlay.show()
