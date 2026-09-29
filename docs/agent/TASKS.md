# Tasks

## Active Work

None. The requested balance experiments and selected tuning are complete.

## Task: Tune Health, Knight Movement, And Sword Attacks

Status: complete; headless and rendered balance checks, combat and movement
regressions, and editor import passed
Priority: high

Scope: Experiment with both sides' HP, standing versus walking knight, and sword
sector area/damage. Select a harder fight with a demonstrated active win.

Result: Stationary knight, 1000 HP; zombies 30 HP; sword 15 damage, 2.2 radius,
160-degree sector; 1.3 s tell and 1.2 s recovery. Walking was tested and rejected
because it either only demanded retargeting or stalled late fights. Ordinary
viewport-click tests cover four approach directions and show passive losses
versus active wins. Detailed evidence is in [TESTING.md](TESTING.md).

## Task: Add Health And Reciprocal Melee Combat

Status: complete; headless and rendered combat checks passed
Priority: high

Scope: Zombies automatically bite the knight in range; the knight turns and
swings at nearby zombies. Both sides have health and death. Show knight health,
remaining zombies, a victory/defeat result, and R to restart. Preserve horde
commands and separation. No roaming AI, progression, or other gameplay systems.

Verification: Import/startup, movement smoke, character checks, and combat smoke
pass. Combat checks cover ranges, cooldowns, warned/locked swing, retreat,
death/removal, both outcomes, stopping and restart. The initial commanded battle
ended in about 20 seconds with 25 zombies remaining; later balance work above
supersedes those parameters. Rendered battle, HUD,
result, and close-up sword poses were inspected; no human playthrough.

## Task: Replace Arena Capsules With Animated Characters

Status: complete; headless and rendered smoke tests passed
Priority: high

Scope: Instance zombies for the horde and the knight for the survivor. Keep
existing steering and bounds; drive run/idle and visual facing from actual agent
movement. The stationary knight plays idle.

Verification: Character asset checks and the extended prototype smoke test pass.
Rendered initial, moving, gathered, corner, and survivor captures were inspected.
No attack animation or gameplay system was added.

## Task: Build And Animate The Two Character Concepts

Status: complete; source, export, and rendered checks passed
Priority: high

Scope: Create editable Blender zombie and medieval knight assets based on the
approved v4 concepts, with rigs and looping idle/run animations. Export GLB
assets and verify their animation playback in Godot. Keep arena gameplay intact.

Acceptance criteria: Both source files open, meshes are weighted to usable rigs,
both clips animate and loop, exported assets retain their materials and skinning,
and rendered poses have been inspected. No attack animation is requested.

## Adding A Requested Task

Record only user-authorized work with a short title, status, priority, scope,
observable acceptance criteria, and verification steps. Keep each task small
enough for one focused implementation pass. Current implementation and completed
verification belong in [PROJECT_STATE.md](PROJECT_STATE.md).
