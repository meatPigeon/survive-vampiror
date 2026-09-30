# Architecture Spec

## Scene Composition

`project.godot` launches `scenes/main.tscn`:

```text
Main (Node3D / arena.gd)
├── Ground, WorldEnvironment, Sun, Camera
├── Survivor (components/survivor.tscn)
│   ├── Visual (knight GLB / KnightVisual)
│   │   └── skeleton + runtime hand-held sword
│   ├── Health
│   └── AttackArea (AttackPreview, top_level)
├── Horde (components/horde.tscn)
│   ├── TargetMarker
│   └── HordeAgent × living/spawning/death-feedback instances
│       ├── KindMarker (white permanent / blue temporary ring)
│       ├── Visual (zombie GLB)
│       └── Health
├── Reinforcements
│   └── West, South, East (components/reinforcement_site.tscn)
├── GroundCommand (always-process input)
└── HUD (plain labels and health bar)
```

No autoloads, services, event bus, plugins, navigation framework or dependencies.
Reusable scenes and typed GDScript follow the sibling's naming and explicit
signal-up/call-down composition conventions.

## Ownership And Data Flow

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
  idle/run/facing, bite cooldown/range, hit and death feedback. Kind is assigned
  before scene entry. Temporary lifetime is ticked explicitly; an expired flag
  distinguishes expiry from damage while reusing Health and the death signal.
  Sprint arrives as a speed multiplier. Dead agents stop participating before visual cleanup.
- `scripts/gameplay/survivor.gd` owns knight pursuit, health phases, three attack
  patterns and their damage. Before windup it scores sweep/charge directions by
  reachable living targets; pursuit still uses the nearest zombie. Scoring runs
  only at attack selection, with the same floor-clamped charge endpoint used
  for execution. A small local enum tracks hunt, windup, strike,
  recovery and stopped states; there is no general state-machine infrastructure.
  Position/direction are locked at windup. Attack loops copy the active list
  because damage can synchronously emit death and remove members.
- `scripts/visuals/knight_visual.gd` owns the imported knight's idle/run, facing,
  hand attachment, cached runtime attack clips, hit flash and death pose.
  `scripts/visuals/attack_preview.gd` draws an arc or rectangle from gameplay
  parameters. It uses world space so a charge does not move its warning.
- `scripts/gameplay/health.gd` holds current/max HP, clamps damage at zero, and
  emits `changed`/one-time `died`. It knows neither faction nor battle outcome.
- `scripts/gameplay/reinforcement_site.gd` owns activity, the current batch and
  occupation progress. Arena explicitly activates/deactivates it. Activation
  resets the batch; deactivation discards leftovers/progress. Recruitment calls
  the horde and subtracts only the actual added count; there is no local timer.
- `scripts/gameplay/arena.gd` starts on the first command, ticks lifetimes, combat and
  recruitment, handles results, pause/restart, and writes the technical HUD.
  It owns the exported site interval and derives the current window from run
  elapsed time, cycling the three scene children. The window number (not just
  site identity) ensures a fresh batch even when a time step skips a full cycle.
  Count changes synchronously lose the run when permanent count reaches zero.
  Physics priority 1 resolves combat after horde movement at priority 0. It
  stops further damage/recruitment as soon as either terminal condition occurs.

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
