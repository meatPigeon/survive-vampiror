# Architecture Spec

## Scene Composition

`project.godot` launches `scenes/main.tscn`:

```text
Main (Node3D / arena.gd)
├── Ground (MeshInstance3D / PlaneMesh)
├── WorldEnvironment
├── Sun (DirectionalLight3D)
├── Camera (Camera3D)
├── Survivor (instance of components/survivor.tscn)
│   ├── Visual (medieval_knight.glb; runtime sword attachment)
│   ├── Health
│   └── AttackArea
├── Horde (instance of components/horde.tscn)
│   ├── TargetMarker
│   └── HordeAgent × 40 (runtime instances of components/horde_agent.tscn)
│       ├── Visual (zombie.glb)
│       └── Health
├── GroundCommand (Node)
└── HUD (CanvasLayer)
```

There are no autoloads or editor plugins. The main scene composes the runtime
and connects the input signal. Its small arena coordinator resolves combat
after movement, updates the HUD through entity signals, and handles outcomes
and scene restart.

## Ownership And Data Flow

```text
Left mouse press
  -> GroundCommand.move_requested(world_position)
  -> HordeController.command_move(world_position)
  -> HordeAgent.move_toward_command(target, neighbours, bounds, delta, survivor)
```

- `scripts/input/ground_command.gd` owns click filtering and camera-ray/ground
  intersection. It checks the floor mesh bounds and emits intent, without
  touching agents. Camera and ground references are exported and scene-wired.
- `scripts/gameplay/horde_controller.gd` owns agent instances, the shared
  command position, movement bounds, and marker placement. It creates the
  initial scatter in `_ready()` and ticks agents in `_physics_process()` after
  the first command. Death signals immediately remove agents from its active
  list and emit the remaining count. `stop()` disables commands and movement.
  The scene connects the input signal directly to it.
- `scripts/gameplay/horde_agent.gd` owns individual movement. Each call combines
  target attraction and neighbour repulsion, caps speed, and clamps X/Z to the
  floor inset by the body radius. Updates are sequential using live positions.
  After movement, actual displacement drives the child visual's yaw and
  idle/run playback. Small settling movements use a hysteresis threshold to
  avoid switching clips repeatedly; cycle offsets keep agents out of lockstep.
  It also owns the zombie bite cooldown/range, hit feedback and death cleanup.
- `scripts/gameplay/survivor.gd` owns the knight's nearest-target selection,
  locked attack direction, windup/swing/recovery timing, arc damage and visual
  feedback. A hand bone attachment holds `components/sword.tscn`. A runtime
  `combat/swing` clip rotates the arm bones while retaining their local rest
  orientations. Source GLB animation resources are not modified.
- `scripts/gameplay/health.gd` holds current/max HP and exposes `take_damage`,
  `is_alive`, `changed`, and `died`. It clamps HP and emits death only once.
- `scripts/gameplay/arena.gd` calls knight combat then zombie combat at physics
  priority 1, after movement at priority 0. It stops on knight death or zero
  agents, updates scene-owned HUD nodes, and reloads on R. No further damage
  ticks run after the result. Knight swings iterate a copy of the active list
  because death signals can synchronously remove agents.

## Constraints

The floor is horizontal, unrotated, and unscaled; movement is on the X/Z plane.
Agents are Node3D instances whose positions are updated directly, not physics
bodies. Separation is steering rather than collision resolution. Agents
are clamped outside the living knight's body radius. There are no other
obstacle or navigation contracts.

Spawn and movement tuning use component exports. Initial scatter is a fixed
radial distribution; it does not assign formation slots. The simple all-pairs
neighbour scan is appropriate for the current crowd size.

Code and file naming follow the applicable conventions from `sumdyq-sozdik`.
Its Control-based UI, global services, persistence, and rules engine are not
dependencies of this project. Rationale belongs in [DECISIONS.md](DECISIONS.md).

## Character Assets And Visual Integration

The requested animated zombie and knight have editable sources in
`art/characters/` and importable GLBs in `assets/characters/`. The source folder
is excluded from Godot import with `.gdignore`. Each GLB contains one skinned
mesh, `CharacterRig/Skeleton3D`, and an `AnimationPlayer` with `idle` and `run`.
Entity scenes instance those GLBs beneath `Visual`, scaled to 0.5 for zombies
and 0.75 for the knight. Only visuals rotate; root movement and separation keep
their existing world-space contract. In-place clips do not move entity roots.

`tools/build_characters.py` authors the meshes, rigs and Actions and exports GLB.
`tools/verify_characters.py` checks reopened Blender sources;
`tests/character_assets.gd` checks imported assets. The rendered preview tool is
development-only. The main game uses the imported scene instances directly.
See [the asset guide](../../art/characters/README.md).
