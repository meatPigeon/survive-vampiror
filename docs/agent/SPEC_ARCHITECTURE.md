# Architecture Spec

## Scene Composition

`project.godot` launches `scenes/main.tscn`:

```text
Main (Node3D / arena.gd)
├── Ground, GroundSurround (visual only), WorldEnvironment, Sun, Camera
├── ArenaEnvironment (environments/arena_environment.tscn)
│   └── authored ground patches, reusable rock/scrub clusters and low pebbles
├── Survivor (components/survivor.tscn)
│   ├── Visual (knight GLB / KnightVisual)
│   │   └── skeleton + WeaponHand attachment + flagged halberd
│   ├── Health
│   └── AttackArea (AttackPreview, top_level)
├── Horde (components/horde.tscn)
│   ├── TargetMarker
│   └── HordeAgent × living/spawning/death-feedback instances
│       ├── KindMarker (white permanent / blue temporary ring)
│       ├── Visual (zombie GLB / ZombieVisual)
│       └── Health
├── Reinforcements
│   └── West, South, East (components/reinforcement_site.tscn)
│       ├── Visual (ReinforcementVisual): crater + three animated gravestones
│       └── Label
├── GroundCommand (always-process input)
└── HUD (ui/battle_hud.tscn / BattleHUD)
    └── Frame: slim boss bar, grouped horde counts, contextual controls, modal overlay
```

No autoloads, services, event bus, plugins, navigation framework or dependencies.
Reusable scenes and typed GDScript follow the sibling's naming and explicit
signal-up/call-down composition conventions.

## Ownership And Data Flow

- `scripts/visuals/arena_camera.gd` fits the orthographic view to the current
  Ground bounds when the viewport resizes. The fixed tilt and a small margin
  keep the arena and character heads visible. Canvas stretch expands with the
  window aspect; a larger plain GroundSurround fills the background without
  participating in targeting or movement bounds.
- `scenes/environments/arena_environment.tscn` owns static prop placement and
  ground patches. Reusable rock/scrub scenes in `scenes/components/environment/`
  share baked flat-shaded meshes/materials. Large rocks sit outside the Ground
  AABB; walkable details are low and non-colliding. No runtime generation,
  obstacle steering or new presentation script is needed.
- `scripts/input/ground_command.gd` projects left clicks onto the floor and
  emits movement intent. Keyboard signals request sprint, pause or restart.
  It processes while paused so resume works; movement/sprint are rejected while
  paused. Inputs are marked handled before restart can remove the node.
- `scripts/gameplay/horde_controller.gd` owns the living agent list, shared
  target, bounds, initial scatter, recruitment cap/statistics and sprint timers.
  It creates permanent starters and temporary recruits, exposes counts by kind and the next expiry, and ticks
  agent lifetimes over a snapshot because deaths remove entries immediately.
  `stop()` prevents further movement, lifetimes, recruitment and sprint. It does not own knight attack decisions.
- `scripts/gameplay/horde_agent.gd` owns planar steering, local separation,
  bite cooldown/range, lifetime and visual-event dispatch. Kind is assigned
  before scene entry. Temporary lifetime is ticked explicitly; an expired flag
  distinguishes expiry from damage while reusing Health and the death signal.
  Sprint arrives as a speed multiplier. Dead agents stop participating before
  visual cleanup; the death tween completion frees the agent.
- `scripts/gameplay/survivor.gd` owns knight pursuit, health phases, three attack
  patterns and their damage. Before windup it scores sweep/charge directions by
  reachable living targets; pursuit still uses the nearest zombie. Scoring runs
  only at attack selection, with the same floor-clamped charge endpoint used
  for execution. A small local enum tracks hunt, windup, strike,
  recovery and stopped states; there is no general state-machine infrastructure.
  Position/direction are locked at windup. Attack loops copy the active list
  because damage can synchronously emit death and remove members.
- `scripts/visuals/zombie_visual.gd` owns imported locomotion/facing, speed lean,
  turn banking, stride compression/lift, cached skeletal bite, brief hit recoil
  and fall/expiry tweens. Secondary motion lives on CharacterRig; gameplay roots
  stay unchanged. Source animations are referenced, never modified.
- `scripts/visuals/knight_visual.gd` owns the imported knight's idle/run, facing,
  hand attachment, cached whole-body attack clips, throttled flash/recoil and
  death pose. The `Hand.R` bone carries `components/halberd.tscn`, a static
  low-poly weapon with a folded pennant; it adds no collision or cloth system.
  Survivor calls strike/recover at existing combat transitions,
  synchronizing clip time without altering damage timing. Charge legs reuse
  source running beneath a braced torso; spin rotates CharacterRig, not Visual.
  Source locomotion clips are duplicated locally to add rig-reset tracks.
  `scripts/visuals/attack_preview.gd` draws an arc or rectangle from gameplay
  parameters. It uses world space so a charge does not move its warning.
- `scripts/gameplay/health.gd` holds current/max HP, clamps damage at zero, and
  emits `changed`/one-time `died`. It knows neither faction nor battle outcome.
- `scripts/gameplay/reinforcement_site.gd` owns activity, the current batch and
  occupation progress. Arena explicitly activates/deactivates it. Activation
  resets the batch; deactivation discards leftovers/progress. Recruitment calls
  the horde and subtracts only the actual added count; there is no local timer.
- `scripts/visuals/reinforcement_visual.gd` receives availability from its site
  (`active && remaining > 0`). Reusable crater/tombstone meshes live under
  `scenes/components/environment/`. The crater persists; staggered, node-bound
  tweens raise/lower the stones without moving the site or blocking recruitment.
  Repeated state refreshes preserve a transition; reversal cancels its previous
  tween. Tree pause freezes motion and scene removal cleans it up. Props have
  no collision, terrain deformation or gameplay authority.
- `scripts/gameplay/arena.gd` starts on the first command, ticks lifetimes, combat and
  recruitment, handles results and pause/restart, and supplies state to BattleHUD.
  It owns the exported site interval and derives the current window from run
  elapsed time, cycling the three scene children. The window number (not just
  site identity) ensures a fresh batch even when a time step skips a full cycle.
  Count changes synchronously lose the run when permanent count reaches zero.
  Physics priority 1 resolves combat after horde movement at priority 0. It
  stops further damage/recruitment as soon as either terminal condition occurs.

- `scripts/ui/battle_hud.gd` formats the current knight/horde/site state into
  labels and progress bars. A delayed health trail eases presentation while
  authoritative health updates immediately; this pauses with gameplay. The HUD
  contains no combat or scheduling logic. The
  reusable scene owns shared styles and anchored/container layout. Explicit
  pause/restart/sprint signals call existing scene handlers. Always-process HUD
  buttons work while paused; noninteractive controls ignore mouse input, while
  the pause/result backdrop consumes it. Buttons have no keyboard focus so
  Space remains the horde sprint shortcut. Result views expose replay, not resume.

## Contracts And Limits

The floor must remain horizontal, unrotated and unscaled. Root positions are
updated directly as Node3D entities; no physics collision/pathfinding contract
exists. The knight and horde share floor bounds. Separation checks all other
living zombies and is intended for the capped 60-agent crowd.

No automatic combat begins before the first command. Tree pause freezes actors,
animations, cooldowns, recruitment, temporary lifetimes and elapsed time. The
always-process input node can call the paused arena's resume/restart methods. Restart unpauses and
reloads the scene, so all mutable gameplay state belongs to that run.

## Assets

Editable Blender sources/previews live in `art/characters/`, excluded from Godot
import by `.gdignore`. GLBs in `assets/characters/` include skinned meshes,
`CharacterRig/Skeleton3D` and AnimationPlayer idle/run clips. Only visuals rotate
for facing; in-place clips never move gameplay roots. Source assets are unchanged
by the jam implementation. See [the asset guide](../../art/characters/README.md).
