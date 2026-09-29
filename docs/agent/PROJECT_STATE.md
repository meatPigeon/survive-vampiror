# Project State

## Current Stage

The first playable prototype is implemented. Godot 4.7 runs
`scenes/main.tscn` using the GL Compatibility renderer. The initial window is
1280 × 800. The requested Blender zombie and knight assets now replace the arena
capsules, including movement-driven idle/run playback for the horde. The
requested basic health and melee combat loop is now playable.

## Implemented

- A flat 44 × 32 floor, basic lighting, and a fixed angled orthographic camera.
- One stationary knight who faces nearby zombies, warns with an orange arc,
  and swings a held sword.
- 40 animated zombies, initially scattered around (-8, 0, 3).
- Left-click ground targeting, a yellow command marker, and mid-movement
  redirection of the whole horde.
- Individual planar movement, local separation, and floor-bound clamping.
- Shared Health components: zombies bite in range; knight swings damage agents
  inside a locked arc. Dead zombies leave the active crowd and fall/shrink away.
- Knight health bar, zombie count, victory/defeat result, and R to restart.
- Separate scripts own input, commands, agent movement/bites, knight melee,
  and arena combat/outcomes. Moving zombies turn and run; gathered zombies idle.

See [architecture](SPEC_ARCHITECTURE.md) for the code map and
[gameplay](SPEC_GAMEPLAY.md) for the behaviour contract.

## Current Limits

- The ground must remain horizontal, unrotated, and unscaled.
- Agents move directly as Node3D entities. There are no physics collisions,
  obstacles, pathfinding, or roaming survivor AI. A small radial clamp keeps
  living zombies out of the knight's body; melee uses distance/angle checks.
- Separation checks every other agent. It is intentionally sized for this
  small crowd; large-horde performance has not been validated.
- Arena geometry remains primitive; character visuals use the animated assets
  described below. These limits are not a feature backlog.

## Character Assets

- `art/characters/zombie.blend` and `medieval_knight.blend` are editable Blender
  5.2 sources based on the chubby, simplified v4 concept images.
- Each has one skinned mesh, 18 deform bones, and two foot IK controls.
  The zombie is 6,000 triangles; the knight is 7,804.
- Each includes cyclic `idle` (2 seconds) and `run` (0.8 seconds) Actions.
  Root motion is stationary. No source attack Action or facial rig was added.
  The game generates a basic knight arm swing and attaches a primitive sword.
- `assets/characters/` contains GLB exports with baked animation and import
  settings for looping playback in Godot.
- Blender and Godot checks pass for weights, controls, skin binding, clips,
  floor contact, loop closure and stationary roots. Blender stills and exported
  Godot motion captures were visually inspected. The original arena smoke test
  also passes. Scene integration checks cover model instances, idle/run
  transitions, movement-facing rotation, and stationary knight behaviour,
  with combat disabled in the movement fixture.
- See [the asset guide](../../art/characters/README.md) for files, editing,
  rebuilding, and preview videos.

## Verification

On 2026-09-29, the initial implementation passed editor import, headless startup,
and both headless and rendered smoke tests under Godot 4.7.2. Initial, gathered,
corner, and resized-window survivor captures were visually inspected. Automated
mouse events exercised commands; a human playthrough was not performed.

The smoke test checks a nearest-agent distance above 0.56 and every agent within
5 units of the target in its tested gathering scenarios. These checks do not
prove all possible crowd arrangements. Reproduction commands and manual checks
are in [TESTING.md](TESTING.md).

The combat addition also passes headless and rendered `combat_smoke.gd`, plus
movement and imported-character regression checks. The original single-click win was superseded by the balance pass below.
Range/angle checks, cooldowns, dodging during windup, one-time death, zombie
removal, both terminal outcomes, halted combat and R restart are covered.
Rendered combat/HUD/result captures and close-up sword poses were inspected.
Balance is an initial tuning pass; no human playthrough has been performed.


## Combat Balance Pass

Compared health on both sides, stationary versus retreating knight (0.8, 1.2,
1.5 units/s), attack radius/angle/damage, and warning/recovery duration in actual
Godot scene simulations. Retained the stationary knight: walking alone merely
required retargeting, and some combined variants stalled against the last zombie.
Experimental movement code was removed.

Selected knight HP 1000; zombie HP 30; sword damage 15, radius 2.2, sector 160
degrees, windup 1.3 s, recovery 1.2 s (swing remains 0.18 s). Zombie bite damage,
range and cooldown stay unchanged. The warning gives time to dodge; zombies
still survive one hit.

`combat_balance.gd` passes through actual viewport clicks from four starting
positions: all passive attacks lose, all active attacks win with 5–16 zombies.
From the normal start, passive loses in 38.8 s (knight 220 HP); responding after
0.37 s wins in 42.0 s with 14 zombies. Additional direct-command trials covered
three static target offsets and 0.22/0.37/0.5 s response delays from four starts;
all 12 passive trials lost and all 12 active trials won. These are scripted
experiments, not proof of an optimum or a human difficulty assessment.

Rendered balance runs also pass: the normal-start passive fight lost in 38.8 s
(knight 220 HP); active commands won in 42.7 s with 16 zombies. Warning, mid-fight,
and both result captures were visually inspected. Editor import, combat smoke,
and movement smoke pass after the tuning. Tests use scripted commands; human
playtesting remains separate.
