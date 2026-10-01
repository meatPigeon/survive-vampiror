# Architecture Spec

## Scene Composition

`project.godot` launches `scenes/ui/main_menu.tscn`. MainMenu owns Play/Quit,
the Undead March menu loop and an instance of `ui/audio_controls.tscn`, revealed
by its Audio button. A noninteractive SubViewport displays `menu_diorama.tscn`:
five imported character visuals with idle animation, a hand-attached halberd
and existing grave/rock/scrub props. It contains no gameplay entities or AI.
The menu's local ButtonGroup selects Newbie (default) or Normal. Play instances
`scenes/main.tscn`, sets its exported `normal_mode` before tree entry and hands
it to `SceneTree.change_scene_to_node`, with both ability slots empty.
The title music stops on departure. `ui/zombie_upgrades.tscn` belongs to the HUD;
its two reusable `components/upgrade_card.tscn` buttons share a local ButtonGroup.
Arena provides offered reward IDs and bound descriptions at intermediate knight defeats and
handles choice/skip signals through explicit HUD connections. Restart instances
a fresh arena, copying only the mode and clearing all rewards. Menu return also
passes the mode to a fresh title scene. Arena assigns `Survivor.lethal_attacks`
whenever it prepares a knight; only knight damage resolution reads this flag.
Crossbow lethality is unconditional. `UpgradeCard` owns art, accent colors, labels
and hover/focus/selected presentation; `ZombieUpgrades` owns the local selection
and emits choice/skip. Four static PNGs in `assets/ui/upgrades/` are authored
offline by `tools/render_upgrade_art.gd` using shipped models and native meshes.
The runtime UI has no 3D rendering scene. No singleton or disk persistence is used:

```text
Main (Node3D / arena.gd)
├── Ground, GroundSurround (visual only), WorldEnvironment, Sun, Camera
├── ArenaEnvironment (environments/arena_environment.tscn)
│   └── authored ground patches, reusable rock/scrub clusters and low pebbles
├── Survivor (components/survivor.tscn)
│   ├── Visual (knight GLB / KnightVisual)
│   │   └── skeleton + WeaponHand attachment + flagged halberd
│   ├── Health
│   ├── CrossbowBolt (scene-owned finite projectile)
│   └── AttackArea (AttackPreview, top_level)
├── Horde (components/horde.tscn)
│   ├── Ability, SecondAbility (HordeAbility): Q/E skill, fuse/flight/feast/cooldown
│   └── HordeAgent × living/spawning/death-feedback instances
│       ├── KindMarker (solid ivory permanent / broken cyan temporary ring)
│       ├── Visual (zombie GLB / ZombieVisual)
│       └── Health
├── Reinforcements
│   └── West, South, East (components/reinforcement_site.tscn)
│       └── Visual (ReinforcementVisual): crater, animated gravestones, progress ring/diamond
├── HordeInput (always-process input)
├── BattleAudio (components/battle_audio.tscn): thirteen effect players + looping music
└── HUD (ui/battle_hud.tscn / BattleHUD)
    └── Frame: battle readouts, ZombieUpgrades, modal overlay, pause AudioControls
```

No autoloads, services, event bus, plugins, navigation framework or dependencies.
Reusable scenes and typed GDScript follow the sibling's naming and explicit
signal-up/call-down composition conventions.

## Ownership And Data Flow

- `scripts/ui/main_menu.gd` starts the arena and quits the application. It stops
  its music/preview on departure; there is no arena running behind the title.
- `scripts/ui/audio_controls.gd` is reused in the title and pause screens. It
  reads/writes the authored Music and Effects buses in `default_bus_layout.tres`,
  including explicit mute at zero, and offers one short effect preview. Every
  gameplay effect routes to Effects and both menu/battle music route to Music.
  Native mixer state survives scene changes and restart for the session. There
  is no autoload, settings file, custom service or per-frame synchronization.
  Controls refresh when shown; hiding them stops previews and releases focus.

- `scripts/visuals/arena_camera.gd` fits the orthographic view to the current
  Ground bounds when the viewport resizes. A zoom multiplier (0.45–1.25)
  smoothly changes the view size; resize retains this multiplier and restart
  resets it to 1.0. An explicit HordeController scene reference supplies mobile
  agent positions. Below factor 1.0 the camera eases toward their mean, excluding
  ability-locked members; otherwise it returns to its cached overview position.
  Follow translates only X/Z, retaining authored height/rotation; no mobile agents
  means hold position. `follow_response` exports easing speed. Native tree pause
  freezes it. Camera processing precedes input projection in the authored scene,
  so sling aim uses the current view. `HordeInput.zoom_requested` routes through Arena's
  pause/outcome guard to `Camera.adjust_zoom`. The fixed tilt and a small margin
  keep the arena and character heads visible at default zoom. Canvas stretch expands with the
  window aspect; a larger plain GroundSurround fills the background without
  participating in targeting or movement bounds.
- `scenes/environments/arena_environment.tscn` owns static prop placement and
  ground patches. Reusable rock/scrub scenes in `scenes/components/environment/`
  share baked flat-shaded meshes/materials. Large rocks sit outside the Ground
  AABB; walkable details are low and non-colliding. No runtime generation,
  obstacle steering or new presentation script is needed.
- `scripts/input/horde_input.gd` tracks physical WASD presses/releases and emits
  a normalized camera-relative movement direction, including zero on release.
  Releases are observed before UI handling; pause and window focus loss clear
  held intent. Floor clicks have no movement handler. Keyboard signals request
  sprint, Q/E ability slot, pause or restart. It processes while paused so resume works; movement
  and sprint are rejected while paused. Restart marks input handled before removal.
  Mouse position is projected onto the existing flat y=0 floor, refreshed each
  frame so camera zoom also updates aim. Explicit aim/fire/cancel signals route
  through Arena guards to HordeAbility. LMB/RMB requests come from unhandled
  input, so UI controls consume their own clicks; focus loss cancels aim.
- `scripts/gameplay/horde_controller.gd` owns the living agent list, shared
  direction, bounds, initial scatter, recruitment cap/statistics and sprint timers.
  It rolls two unowned perks from three active skills plus Sprint. Active skills
  fill the first empty Q/E slot; Sprint sets scene-owned `sprint_unlocked` and
  retains the existing Space action/timers. `command_sprint` rejects unowned,
  paused, intermission and cooldown requests. Duplicate/invalid grants are
  rejected; fresh scene instances reset all ownership. Permanent rewards reuse agent spawning
  around the living crowd and intentionally bypass only the grave cap.
  It creates permanent starters and temporary recruits, exposes counts by kind and the next expiry, and ticks
  agent lifetimes over a snapshot because deaths remove entries immediately.
  `stop()` prevents further movement, lifetimes, recruitment and sprint. It does not own knight attack decisions.
  `sprint_started` emits only on accepted sprint; `moved` reports mean actual
  per-agent travel after movement for the shared footstep cadence. Movement
  samples the crowd center once per tick for cohesion. A zero direction stops
  every agent while battle, lifetime and cooldown timers continue.
- `scripts/gameplay/horde_agent.gd` owns planar steering, local separation,
  bite cooldown/range, lifetime and visual-event dispatch. Kind is assigned
  before scene entry. Temporary lifetime is ticked explicitly; an expired flag
  distinguishes expiry from damage while reusing Health and the death signal.
  Sprint arrives as a speed multiplier. Dead agents stop participating before
  visual cleanup; the death tween completion frees the agent.
- Two `scripts/gameplay/horde_ability.gd` instances under Horde each own a chosen
  enum, cooldown and current mine batch, sling projectile or feast duration.
  Arena guards activation by slot and ticks each during active combat, stopping
  immediately on wave/outcome transitions. HUD reads both independent statuses.
  Sling owns pending mouse aim, valid range/bounds, and a local RNG for a uniform
  disk landing sampled at launch. Its cached AttackPreview disk/ring moves under
  the pointer; no meshes are rebuilt per frame. Canceling aim preserves in-flight
  shots; outcomes cancel both. Pause/intermission clear only uncommitted aim.
  Mine selection excludes already locked agents; feast respects their markers. Movement skips
  ability-locked agents and excludes them from cohesion; death removes pending
  references immediately. Temporary lifetimes tick before abilities. Feast
  affects the agent's existing bite and uses bounded `Health.heal`. Reusable
  AttackPreview geometry supplies short-lived ground feedback; no ability
  framework, status registry or new knight behavior is added.
- `scripts/gameplay/survivor.gd` owns knight pursuit, health phases, five attack
  patterns and their damage. Before windup it scores sweep/charge directions by
  reachable living targets; pursuit still uses the nearest zombie. Scoring runs
  only at attack selection, with the same floor-clamped charge endpoint used
  for execution. A small local enum tracks hunt, windup, strike,
  recovery and stopped states; there is no general state-machine infrastructure.
  `configure_wave` configures each fresh knight's HP, crossbow and mount.
  Position/direction are locked at windup. Mounted stampede subsequently steers
  toward the living horde center with bounded speed/angular acceleration and
  turn speed. Survivor substeps the curved swept path, remembers hit IDs and
  enters ordinary recovery on timeout or floor contact. No navigation is added.
  Attack loops copy the active list
  because damage can synchronously emit death and remove members.
- `scripts/visuals/zombie_visual.gd` owns imported locomotion/facing, speed lean,
  turn banking, stride compression/lift, cached skeletal bite, brief hit recoil
  and fall/expiry tweens. Secondary motion lives on CharacterRig; gameplay roots
  stay unchanged. Source animations are referenced, never modified.
  `set_temporary` assigns shared, immutable recruit material overrides and a
  chest-attached `components/recruit_mantle.tscn`; imported resources stay intact.
- `scripts/visuals/zombie_kind_marker.gd` supplies shared solid/broken ring meshes
  and per-agent colors under the existing KindMarker node. Ability code retains
  its color/scale contract; reset reads the marker's kind-specific base color.
  Kind is configured once on scene entry. HUD legends use matching SVG shapes.
- `scenes/components/motion_air.tscn` and `scripts/visuals/motion_air.gd` are
  shared visual composition under knight/zombie Visual nodes. One ImmediateMesh
  draws tapered melee crescents or two side streaks with a shared built-in
  material. KnightVisual dispatches strike/charge/mounted movement; ZombieVisual
  receives the existing sprint multiplier as a visual flag. Actual displacement
  rejects stationary/teleported trails. Inherited pause freezes the mesh; visual
  stop/death clears it. It never owns damage, movement, gameplay timers or collision.
- `scripts/visuals/knight_visual.gd` owns the imported knight's idle/run, facing,
  hand attachment, cached whole-body attack clips, throttled flash/recoil and
  death pose. The `Hand.R` bone carries `components/halberd.tscn`, a static
  low-poly weapon with a folded pennant; it adds no collision or cloth system.
  Survivor calls strike/recover at existing combat transitions,
  synchronizing clip time without altering damage timing. Charge legs reuse
  source running beneath a braced torso; spin rotates CharacterRig, not Visual.
  Source locomotion clips are duplicated locally to add rig-reset tracks.
  `scripts/visuals/attack_preview.gd` draws an arc, ring or rectangle from gameplay
  parameters. It uses world space so a charge does not move its warning.
  Stampede uses two red chevrons whose transform follows its actual heading;
  the mesh is built once, not every steering tick. KnightVisual retains the
  braced charge pose, galloping horse, air trails and a small turn bank.
- `scripts/gameplay/crossbow_bolt.gd` owns a single finite bolt per knight.
  Survivor advances it in the combat tick; a swept segment collects all live
  hits and sorts them by entry distance before applying lethal current-HP
  damage. This separate list tolerates synchronous horde removals. The bolt
  continues to its range limit; outcome cancellation stops even same-tick hits.
  Pause, death and outcome follow
  existing combat ownership. No projectile pool or global service is added.
- `scripts/visuals/horse_visual.gd` animates native mesh legs and body bob.
  KnightVisual owns equipment visibility, crossbow poses and seated leg tracks;
  original GLBs stay unchanged.
- `scripts/gameplay/health.gd` holds current/max HP, clamps damage at zero, and
  emits `changed`/one-time `died`. It knows neither faction nor battle outcome.
- `scripts/gameplay/reinforcement_site.gd` owns activity, the current batch and
  occupation progress. Arena explicitly activates/deactivates it. Activation
  resets the batch; deactivation discards leftovers/progress. Recruitment calls
  the horde, closes the site after any successful addition and emits `summoned`.
  Excess stock is discarded; no site-local respawn timer is needed.
- `scripts/visuals/reinforcement_visual.gd` receives availability from its site
  (`active && remaining > 0`) and normalized occupation progress. It builds a
  shallow annular track/fill and diamond marker under Indicator. The clockwise
  fill updates only when progress changes; availability immediately hides or
  reveals the indicator. Built-in unshaded materials and explicit render priority
  keep it visible above the gathered horde without a custom shader. No labels
  or percentages are drawn in the world. Reusable crater/tombstone meshes live under
  `scenes/components/environment/`. The crater persists; staggered, node-bound
  tweens raise/lower the stones without moving the site or blocking recruitment.
  Repeated state refreshes preserve a transition; reversal cancels its previous
  tween. Tree pause freezes motion and scene removal cleans it up. Props have
  no collision, terrain deformation or gameplay authority.
- `scripts/gameplay/arena.gd` starts on the first command, ticks lifetimes, combat and
  recruitment, handles results and pause/restart, and supplies state to BattleHUD.
  It owns exported `site_interval` (unused-window length) and `site_respawn_delay`
  (post-summon gap), with one deadline in battle elapsed time. `summoned` clears
  `active_site` during the gap; the last location is retained to exclude immediate
  repeats. A dedicated RNG picks among other sites. First command opens West.
  `site_time_left()` supplies the actual countdown to the HUD and test pilot.
  Only the active site ticks each frame, so a switch cannot tick a second site
  with the same delta. Pause/outcome freeze elapsed time and both countdowns.
  Count changes synchronously lose the run when permanent count reaches zero.
  Arena owns `wave_index`, intermission and exported count/health/break tuning.
  Only the knight is replaced between waves; explicit horde and audio references
  bind to the fresh instance. Intermission temporarily disables horde processing
  and commands, while preserved battle elapsed time freezes recruitment/lifetimes.
  Final death ends the run; intermediate death sets `awaiting_reward` and opens
  two cards. Choice/skip validates state and consumes that flag once; only then
  does the wave countdown tick. Pause hides the picker beneath its overlay and
  resume restores it without rerolling. A terminal outcome cancels selection.
  Physics priority 1 resolves combat after horde movement at priority 0. It
  stops further damage/recruitment as soon as either terminal condition occurs.
  `return_to_menu()` stops battle/preview audio, clears tree pause and changes
  to the main menu. HUD emits `menu_requested` from pause and result screens.

- `scripts/audio/battle_audio.gd` is scene-owned presentation, initialized by
  Arena with explicit knight/horde/site references. Knight emits warning,
  strike and actual-contact signals. Existing health/count signals drive sparse
  zombie voices, and ReinforcementVisual emits availability transitions for
  stone sounds. Horde commands/accepted sprint/movement drive feedback and
  shared footsteps; count statistics distinguish recruitment from expiry.
  HordeAbility emits accepted `activated`, batched `impacted` and natural
  `feast_ended` signals. BattleAudio binds both ability slots at setup; one cast
  and one impact player handle six short perk cues. Aim/cancel/rejection stay
  silent, mine bursts coalesce, and early death/expiry cannot produce an impact.
  Thirteen single-voice effect players and one music player bound concurrency; no
  per-agent players, autoload, event bus or runtime network access. Pitch
  variation uses its own random generator. Arena stops gameplay voices at
  outcome and requests a single victory/defeat cue; restart removes that too.
  Inherited processing pauses playback and cooldowns with the tree.
  Arena calls `start_music()` only when the first command starts the battle.
  Graveyard Groove loops quietly; `stop_all()` includes music, so
  outcomes and restart leave no background playback behind.
- `scripts/ui/battle_hud.gd` formats the current knight/horde/site state into
  labels and progress bars. A delayed health trail eases presentation while
  authoritative health updates immediately; this pauses with gameplay. The HUD
  contains no combat or scheduling logic. The
  reusable scene owns shared styles and anchored/container layout. Explicit
  pause/restart/sprint signals call existing scene handlers. Always-process HUD
  buttons work while paused; noninteractive controls ignore mouse input, while
  the pause/result backdrop consumes it. Buttons have no keyboard focus so
  Space remains the shortcut for the acquired Sprint perk. Its control stays
  hidden until owned; pause hints describe only acquired actions. Result views expose replay, not resume.
  ZombieUpgrades animates its Wave cleared heading on presentation. Arena passes
  `awaiting_reward` with its existing timer to HUD: only a resolved choice shows
  the large countdown, which pulses on integer-second changes. These tweens use
  `TWEEN_PAUSE_STOP`; HUD owns no countdown time. Pause hides the readout, and
  leaving intermission or showing a result clears the tween and presentation.

## Contracts And Limits

The floor must remain horizontal, unrotated and unscaled. Root positions are
updated directly as Node3D entities; no physics collision/pathfinding contract
exists. The knight and horde share floor bounds. Separation checks all other
living zombies and is intended for the capped 60-agent crowd.

No automatic combat begins before the first command. Tree pause freezes actors,
animations, cooldowns, recruitment, temporary lifetimes and elapsed time. The
always-process input node can call the paused arena's resume/restart methods. Restart unpauses and
replaces the arena with a fresh instance retaining only its selected mode, so
all mutable combat/progression state belongs to that run.

## Assets

Editable Blender sources/previews live in `art/characters/`, excluded from Godot
import by `.gdignore`. GLBs in `assets/characters/` include skinned meshes,
`CharacterRig/Skeleton3D` and AnimationPlayer idle/run clips. Only visuals rotate
for facing; in-place clips never move gameplay roots. Source assets are unchanged
by the jam implementation. See [the asset guide](../../art/characters/README.md).

Sound source MP3s, prompts and credit receipts live in `art/audio/`, excluded
from Godot import. `assets/audio/` contains ready-to-play WAVs; their offline
build script and provenance are documented in [the audio guide](../../art/audio/README.md).
